defmodule OrbitalDynamics.EventDetectors.Eclipses do
  @moduledoc """
  Cylindrical central-body eclipse detection.

  The detector treats `:sun_direction` as an inertial vector from the central
  body toward the Sun. A spacecraft sample is eclipsed when it is anti-sunward
  of the central body and inside the body's cylindrical shadow. Start and end
  times are linearly interpolated between adjacent samples when the event
  boundary is bracketed.
  """

  alias OrbitalDynamics.{CentralBody, Environment, EventTiming, StateVector, Trajectory, Vector3}

  @behaviour OrbitalDynamics.EventDetector

  @default_sun_direction {1.0, 0.0, 0.0}

  @doc """
  Declares the detector model, timing policy, and known limits.
  """
  @impl OrbitalDynamics.EventDetector
  def capabilities do
    %{
      detector: :eclipses,
      model: :cylindrical_central_body_shadow,
      validation_level: :analysis,
      timing_policy: :sampled_state_linear_boundary,
      interpolation: :linear_sample_crossing,
      boundary_refinement: :eclipse_linear_shadow_margin_interpolation,
      lighting_summary_model: :sampled_eclipse_overlap_fraction,
      known_limits: [
        :sample_cadence_limited,
        :refinement_not_root_solved,
        :fixed_sun_direction,
        :cylindrical_shadow,
        :no_penumbra_model
      ]
    }
  end

  @impl OrbitalDynamics.EventDetector
  def detect(%Trajectory{} = trajectory, opts \\ []) do
    case Keyword.fetch(opts, :sun_direction_provider) do
      :error -> detect_fixed_sun(trajectory, opts)
      {:ok, provider} -> detect_provider_sun(trajectory, provider, opts)
    end
  end

  defp detect_fixed_sun(%Trajectory{} = trajectory, opts) do
    central_body = Keyword.get(opts, :central_body, CentralBody.earth())
    sun_direction = Keyword.get(opts, :sun_direction, @default_sun_direction)

    with :ok <- validate_central_body(central_body),
         {:ok, sun_unit} <- normalize_sun_direction(sun_direction) do
      samples =
        trajectory.states
        |> Enum.with_index()
        |> Enum.map(fn {state, index} ->
          shadow = shadow_geometry(state.position_km, sun_unit, central_body.equatorial_radius_km)

          %{
            index: index,
            state: state,
            eclipsed: shadow.eclipsed,
            shadow_axis_distance_km: shadow.axis_distance_km,
            shadow_margin_km: shadow.margin_km,
            eclipse_margin_km: eclipse_margin_km(shadow)
          }
        end)

      {:ok,
       samples
       |> eclipsed_groups()
       |> Enum.map(&event_from_group(&1, samples, trajectory, central_body, sun_unit))
       |> Enum.map(&EventTiming.annotate_event(&1, trajectory, :eclipses))}
    end
  end

  defp detect_provider_sun(%Trajectory{} = trajectory, provider, opts) do
    central_body = Keyword.get(opts, :central_body, CentralBody.earth())

    with :ok <- validate_central_body(central_body),
         {:ok, provider_model} <- provider_sun_model(provider),
         {:ok, samples} <- provider_sun_samples(trajectory, central_body, provider_model) do
      {:ok,
       samples
       |> eclipsed_groups()
       |> Enum.map(
         &provider_event_from_group(&1, samples, trajectory, central_body, provider_model)
       )
       |> Enum.map(&EventTiming.annotate_event(&1, trajectory, :eclipses))}
    end
  end

  defp provider_sun_model(provider) when is_atom(provider), do: provider_sun_model({provider, []})

  defp provider_sun_model({provider, provider_opts})
       when is_atom(provider) and is_list(provider_opts) do
    with true <- Code.ensure_loaded?(provider),
         true <- function_exported?(provider, :fetch, 2),
         true <- function_exported?(provider, :capabilities, 0),
         true <- Keyword.keyword?(provider_opts),
         {:ok, capability} <- Environment.configured_provider_capability(provider, provider_opts),
         true <- "sun_direction" in capability["outputs"] do
      {:ok, %{provider: provider, provider_opts: provider_opts, capability: capability}}
    else
      _error -> {:error, {:invalid_option, :sun_direction_provider}}
    end
  end

  defp provider_sun_model(_provider),
    do: {:error, {:invalid_option, :sun_direction_provider}}

  defp provider_sun_samples(trajectory, central_body, provider_model) do
    trajectory.states
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {state, index}, {:ok, acc} ->
      case provider_sun_sample(state, index, central_body, provider_model) do
        {:ok, sample} -> {:cont, {:ok, [sample | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, samples} -> {:ok, Enum.reverse(samples)}
      error -> error
    end
  end

  defp provider_sun_sample(state, index, central_body, provider_model) do
    fetch_opts =
      provider_model.provider_opts
      |> Keyword.put(:seconds_since_j2000, state.epoch.seconds_since_j2000)
      |> Keyword.put(:body, central_body.name)
      |> Keyword.put(:frame, state.frame.name)
      |> Keyword.put(:time_scale, state.epoch.scale)

    case provider_model.provider.fetch(:sun_direction, fetch_opts) do
      {:ok, %{} = product} ->
        with :ok <- matching_provider_product?(product, provider_model.capability),
             {:ok, sun_unit} <-
               normalize_provider_sun_direction(product_value(product, "sun_direction")) do
          shadow =
            shadow_geometry(state.position_km, sun_unit, central_body.equatorial_radius_km)

          {:ok,
           %{
             index: index,
             state: state,
             eclipsed: shadow.eclipsed,
             shadow_axis_distance_km: shadow.axis_distance_km,
             shadow_margin_km: shadow.margin_km,
             eclipse_margin_km: eclipse_margin_km(shadow),
             sun_direction: sun_unit,
             sun_product: product
           }}
        end

      {:error, reason} ->
        {:error, reason}

      _other ->
        {:error, {:invalid_environment_product, :sun_direction}}
    end
  end

  defp matching_provider_product?(product, capability) do
    if product_value(product, "provider_id") == capability["id"] do
      :ok
    else
      {:error, {:invalid_environment_product, :provider_id}}
    end
  end

  defp product_value(product, key) do
    Map.get(product, key) || Map.get(product, String.to_existing_atom(key))
  rescue
    ArgumentError -> Map.get(product, key)
  end

  defp normalize_provider_sun_direction([x, y, z]),
    do: normalize_sun_direction({x, y, z})

  defp normalize_provider_sun_direction(direction), do: normalize_sun_direction(direction)

  @doc """
  Classifies a planned activity's sampled eclipse overlap.

  This is a coarse planning tag, not an illumination or penumbra model. The
  returned `lighting_condition` preserves the older three-state values while
  `lighting_condition_detail` exposes a deterministic overlap-fraction band for
  operator review and downstream scoring.
  """
  def lighting_summary(duration_s, eclipse_overlap_s)
      when is_number(duration_s) and is_number(eclipse_overlap_s) do
    fraction =
      cond do
        duration_s <= 0.0 -> nil
        true -> (eclipse_overlap_s / duration_s) |> max(0.0) |> min(1.0)
      end

    %{
      "lighting_condition" => lighting_condition(duration_s, eclipse_overlap_s),
      "lighting_condition_detail" => lighting_condition_detail(fraction),
      "lighting_condition_model" => "sampled_eclipse_overlap_tag",
      "lighting_detail_model" => "sampled_eclipse_overlap_fraction_tag",
      "eclipse_overlap_fraction" => fraction,
      "lighting_confidence" => "bounded_by_sampled_eclipse_overlap"
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  def lighting_summary(_duration_s, _eclipse_overlap_s) do
    %{
      "lighting_condition" => "unknown",
      "lighting_condition_detail" => "unknown",
      "lighting_condition_model" => "sampled_eclipse_overlap_tag",
      "lighting_detail_model" => "sampled_eclipse_overlap_fraction_tag",
      "lighting_confidence" => "invalid_duration_or_overlap"
    }
  end

  @doc """
  Refines one bracketed cylindrical eclipse boundary between two sampled states.

  The boundary is linearly interpolated over the same cylindrical shadow margin
  used by the detector. It is not a penumbra model or a root-solved event time.
  """
  def refine_eclipse_boundary(
        %StateVector{} = before_state,
        %StateVector{} = after_state,
        opts \\ []
      ) do
    central_body = Keyword.get(opts, :central_body, CentralBody.earth())
    sun_direction = Keyword.get(opts, :sun_direction, @default_sun_direction)

    with :ok <- validate_central_body(central_body),
         {:ok, sun_unit} <- normalize_sun_direction(sun_direction) do
      before_shadow =
        shadow_geometry(before_state.position_km, sun_unit, central_body.equatorial_radius_km)

      after_shadow =
        shadow_geometry(after_state.position_km, sun_unit, central_body.equatorial_radius_km)

      before_margin = eclipse_margin_km(before_shadow)
      after_margin = eclipse_margin_km(after_shadow)

      cond do
        not bracketed_boundary?(before_margin, after_margin) ->
          {:error, :not_bracketed}

        true ->
          fraction = interpolation_fraction(before_margin, after_margin)

          {:ok,
           %{
             boundary: eclipse_boundary_type(before_margin, after_margin),
             epoch: interpolate_epoch(before_state.epoch, after_state.epoch, fraction),
             interpolation: :linear_sample_crossing,
             interpolation_fraction: fraction,
             before_eclipsed: before_shadow.eclipsed,
             after_eclipsed: after_shadow.eclipsed,
             before_eclipse_margin_km: before_margin,
             after_eclipse_margin_km: after_margin,
             before_shadow_axis_distance_km: before_shadow.axis_distance_km,
             after_shadow_axis_distance_km: after_shadow.axis_distance_km,
             central_body_radius_km: central_body.equatorial_radius_km,
             sun_direction: sun_unit,
             assumptions:
               EventTiming.boundary_policy(before_state.epoch, after_state.epoch)
               |> Map.merge(%{
                 refinement_model: :eclipse_linear_shadow_margin_interpolation,
                 shadow_model: :cylindrical_central_body_shadow
               })
           }}
      end
    end
  end

  defp validate_central_body(%CentralBody{equatorial_radius_km: radius})
       when is_number(radius) and radius > 0.0 do
    :ok
  end

  defp validate_central_body(%CentralBody{}),
    do: {:error, {:invalid_central_body, :equatorial_radius_km}}

  defp validate_central_body(_central_body), do: {:error, {:invalid_option, :central_body}}

  defp normalize_sun_direction(sun_direction) do
    cond do
      not Vector3.valid?(sun_direction) ->
        {:error, {:invalid_option, :sun_direction}}

      Vector3.norm(sun_direction) <= 0.0 ->
        {:error, {:invalid_option, :sun_direction}}

      true ->
        {:ok, Vector3.scale(sun_direction, 1.0 / Vector3.norm(sun_direction))}
    end
  end

  defp shadow_geometry(position_km, sun_unit, radius_km) do
    sun_projection_km = Vector3.dot(position_km, sun_unit)
    radius_squared_km2 = Vector3.dot(position_km, position_km)

    axis_distance_squared_km2 =
      max(radius_squared_km2 - sun_projection_km * sun_projection_km, 0.0)

    axis_distance_km = :math.sqrt(axis_distance_squared_km2)
    shadow_margin_km = radius_km - axis_distance_km

    %{
      eclipsed: sun_projection_km < 0.0 and shadow_margin_km >= 0.0,
      sun_projection_km: sun_projection_km,
      axis_distance_km: axis_distance_km,
      margin_km: shadow_margin_km
    }
  end

  defp eclipse_margin_km(shadow), do: min(-shadow.sun_projection_km, shadow.margin_km)

  defp eclipsed_groups(samples) do
    {groups, current_group} =
      Enum.reduce(samples, {[], []}, fn sample, {groups, current_group} ->
        cond do
          sample.eclipsed ->
            {groups, current_group ++ [sample]}

          current_group == [] ->
            {groups, []}

          true ->
            {[current_group | groups], []}
        end
      end)

    groups =
      if current_group == [] do
        groups
      else
        [current_group | groups]
      end

    Enum.reverse(groups)
  end

  defp event_from_group(group, samples, trajectory, central_body, sun_unit) do
    first = List.first(group)
    last = List.last(group)

    {starts_at, start_boundary, start_boundary_detail} =
      start_boundary(first, samples, central_body, sun_unit)

    {ends_at, end_boundary, end_boundary_detail} =
      end_boundary(last, samples, central_body, sun_unit)

    %{
      type: :eclipse,
      starts_at: starts_at,
      ends_at: ends_at,
      metadata: %{
        scenario_id: trajectory.scenario_id,
        shadow_model: :cylindrical_central_body_shadow,
        central_body: central_body.name,
        central_body_radius_km: central_body.equatorial_radius_km,
        sun_direction: sun_unit,
        interpolation: :linear_sample_crossing,
        boundary_refinement: :eclipse_linear_shadow_margin_interpolation,
        start_boundary: start_boundary,
        end_boundary: end_boundary,
        start_boundary_detail: start_boundary_detail,
        end_boundary_detail: end_boundary_detail,
        sample_count: length(group),
        start_sample_index: first.index,
        end_sample_index: last.index,
        minimum_shadow_axis_distance_km:
          group |> Enum.map(& &1.shadow_axis_distance_km) |> Enum.min(),
        maximum_shadow_margin_km: group |> Enum.map(& &1.shadow_margin_km) |> Enum.max()
      }
    }
  end

  defp provider_event_from_group(group, samples, trajectory, central_body, provider_model) do
    first = List.first(group)
    last = List.last(group)
    provenance = product_value(first.sun_product, "provenance") || %{}

    {starts_at, start_boundary, start_boundary_detail} =
      provider_start_boundary(first, samples, central_body)

    {ends_at, end_boundary, end_boundary_detail} =
      provider_end_boundary(last, samples, central_body)

    %{
      type: :eclipse,
      starts_at: starts_at,
      ends_at: ends_at,
      metadata: %{
        scenario_id: trajectory.scenario_id,
        shadow_model: :cylindrical_central_body_shadow,
        central_body: central_body.name,
        central_body_radius_km: central_body.equatorial_radius_km,
        sun_direction: first.sun_direction,
        sun_direction_at_start_sample: first.sun_direction,
        sun_direction_at_end_sample: last.sun_direction,
        sun_direction_time_varying: true,
        sun_direction_provider_id: provider_model.capability["id"],
        sun_direction_provider_revision: provenance["provider_revision"],
        sun_direction_dataset_revision: provenance["dataset_revision"],
        sun_direction_content_sha256: provenance["content_sha256"],
        sun_direction_provider_coverage: provenance["coverage"],
        sun_direction_interpolation: provider_model.capability["interpolation"],
        campaign_environment: provenance,
        interpolation: :linear_sample_crossing,
        boundary_refinement: :eclipse_linear_shadow_margin_interpolation,
        start_boundary: start_boundary,
        end_boundary: end_boundary,
        start_boundary_detail: start_boundary_detail,
        end_boundary_detail: end_boundary_detail,
        sample_count: length(group),
        start_sample_index: first.index,
        end_sample_index: last.index,
        minimum_shadow_axis_distance_km:
          group |> Enum.map(& &1.shadow_axis_distance_km) |> Enum.min(),
        maximum_shadow_margin_km: group |> Enum.map(& &1.shadow_margin_km) |> Enum.max(),
        known_limits:
          capabilities().known_limits
          |> List.delete(:fixed_sun_direction)
          |> Kernel.++([:campaign_table_sun_direction, :daily_linear_sun_position_interpolation])
      }
    }
  end

  defp provider_start_boundary(first, samples, central_body) do
    if first.index == 0 do
      {first.state.epoch, :clipped_start, clipped_boundary_detail(:clipped_start, first)}
    else
      previous = Enum.at(samples, first.index - 1)

      {interpolate_epoch(previous, first), :interpolated,
       provider_boundary_detail(previous, first, central_body, :start)}
    end
  end

  defp provider_end_boundary(last, samples, central_body) do
    if last.index == length(samples) - 1 do
      {last.state.epoch, :clipped_end, clipped_boundary_detail(:clipped_end, last)}
    else
      next_sample = Enum.at(samples, last.index + 1)

      {interpolate_epoch(last, next_sample), :interpolated,
       provider_boundary_detail(last, next_sample, central_body, :end)}
    end
  end

  defp provider_boundary_detail(before_sample, after_sample, central_body, edge) do
    before_margin = before_sample.eclipse_margin_km
    after_margin = after_sample.eclipse_margin_km
    fraction = interpolation_fraction(before_margin, after_margin)

    before_sample.state.epoch
    |> EventTiming.boundary_policy(after_sample.state.epoch)
    |> Map.merge(%{
      edge: edge,
      boundary: eclipse_boundary_type(before_margin, after_margin),
      interpolation_fraction: fraction,
      before_sample_index: before_sample.index,
      after_sample_index: after_sample.index,
      before_eclipsed: before_sample.eclipsed,
      after_eclipsed: after_sample.eclipsed,
      before_eclipse_margin_km: before_margin,
      after_eclipse_margin_km: after_margin,
      before_shadow_axis_distance_km: before_sample.shadow_axis_distance_km,
      after_shadow_axis_distance_km: after_sample.shadow_axis_distance_km,
      central_body_radius_km: central_body.equatorial_radius_km,
      before_sun_direction: before_sample.sun_direction,
      after_sun_direction: after_sample.sun_direction,
      sun_direction_time_varying: true
    })
  end

  defp start_boundary(first, samples, central_body, sun_unit) do
    if first.index == 0 do
      {first.state.epoch, :clipped_start, clipped_boundary_detail(:clipped_start, first)}
    else
      previous = Enum.at(samples, first.index - 1)

      {interpolate_epoch(previous, first), :interpolated,
       boundary_detail(previous, first, central_body, sun_unit, :start)}
    end
  end

  defp end_boundary(last, samples, central_body, sun_unit) do
    if last.index == length(samples) - 1 do
      {last.state.epoch, :clipped_end, clipped_boundary_detail(:clipped_end, last)}
    else
      next_sample = Enum.at(samples, last.index + 1)

      {interpolate_epoch(last, next_sample), :interpolated,
       boundary_detail(last, next_sample, central_body, sun_unit, :end)}
    end
  end

  defp boundary_detail(before_sample, after_sample, central_body, sun_unit, edge) do
    before_margin = before_sample.eclipse_margin_km
    after_margin = after_sample.eclipse_margin_km
    fraction = interpolation_fraction(before_margin, after_margin)

    before_sample.state.epoch
    |> EventTiming.boundary_policy(after_sample.state.epoch)
    |> Map.merge(%{
      edge: edge,
      boundary: eclipse_boundary_type(before_margin, after_margin),
      interpolation_fraction: fraction,
      before_sample_index: before_sample.index,
      after_sample_index: after_sample.index,
      before_eclipsed: before_sample.eclipsed,
      after_eclipsed: after_sample.eclipsed,
      before_eclipse_margin_km: before_margin,
      after_eclipse_margin_km: after_margin,
      before_shadow_axis_distance_km: before_sample.shadow_axis_distance_km,
      after_shadow_axis_distance_km: after_sample.shadow_axis_distance_km,
      central_body_radius_km: central_body.equatorial_radius_km,
      sun_direction: sun_unit
    })
  end

  defp clipped_boundary_detail(boundary, sample) do
    %{
      boundary: boundary,
      interpolation: :clipped_to_sample,
      interpolation_fraction: 0.0,
      sample_index: sample.index,
      eclipsed: sample.eclipsed,
      eclipse_margin_km: sample.eclipse_margin_km,
      shadow_axis_distance_km: sample.shadow_axis_distance_km,
      root_solved: false,
      confidence: :bounded_by_sample_cadence
    }
  end

  defp interpolate_epoch(before_sample, after_sample) do
    before_margin = before_sample.eclipse_margin_km
    after_margin = after_sample.eclipse_margin_km

    interpolate_epoch(
      before_sample.state.epoch,
      after_sample.state.epoch,
      interpolation_fraction(before_margin, after_margin)
    )
  end

  defp interpolate_epoch(before_epoch, after_epoch, fraction) do
    duration_s = after_epoch.seconds_since_j2000 - before_epoch.seconds_since_j2000

    %{
      before_epoch
      | seconds_since_j2000: before_epoch.seconds_since_j2000 + fraction * duration_s
    }
  end

  defp interpolation_fraction(before_margin, after_margin) do
    denominator = after_margin - before_margin

    if denominator == 0.0 do
      0.0
    else
      max(0.0, min(1.0, -before_margin / denominator))
    end
  end

  defp bracketed_boundary?(before_margin, after_margin) do
    before_margin == 0.0 or after_margin == 0.0 or
      (before_margin < 0.0 and after_margin > 0.0) or
      (before_margin > 0.0 and after_margin < 0.0)
  end

  defp eclipse_boundary_type(before_margin, after_margin) do
    cond do
      before_margin < 0.0 and after_margin >= 0.0 -> :eclipse_entry
      before_margin >= 0.0 and after_margin < 0.0 -> :eclipse_exit
      before_margin == 0.0 -> :sampled_boundary
      after_margin == 0.0 -> :sampled_boundary
    end
  end

  defp lighting_condition(duration_s, eclipse_overlap_s) do
    cond do
      duration_s <= 0.0 -> "unknown"
      eclipse_overlap_s <= 0.0 -> "sunlit"
      eclipse_overlap_s >= duration_s -> "eclipsed"
      true -> "partial_eclipse"
    end
  end

  defp lighting_condition_detail(nil), do: "unknown"
  defp lighting_condition_detail(fraction) when fraction <= 0.0, do: "sunlit"
  defp lighting_condition_detail(fraction) when fraction < 0.25, do: "mostly_sunlit"
  defp lighting_condition_detail(fraction) when fraction < 0.75, do: "mixed_lighting"
  defp lighting_condition_detail(fraction) when fraction < 1.0, do: "mostly_eclipsed"
  defp lighting_condition_detail(_fraction), do: "eclipsed"
end
