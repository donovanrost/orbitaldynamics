defmodule OrbitalDynamics.EventDetectors.Eclipses do
  @moduledoc """
  Cylindrical central-body eclipse detection.

  The detector treats `:sun_direction` as an inertial vector from the central
  body toward the Sun. A spacecraft sample is eclipsed when it is anti-sunward
  of the central body and inside the body's cylindrical shadow. Start and end
  times are linearly interpolated between adjacent samples when the event
  boundary is bracketed.
  """

  alias OrbitalDynamics.{
    CentralBody,
    Environment,
    Epoch,
    EventTiming,
    Frame,
    StateVector,
    Trajectory,
    Vector3
  }

  alias OrbitalDynamics.Environment.CampaignEnvironmentProvider.Dataset

  @behaviour OrbitalDynamics.EventDetector

  @default_sun_direction {1.0, 0.0, 0.0}
  @max_states 10_000
  @max_opts_length 64
  @max_container_depth 8
  @max_container_entries 2_048
  @max_list_length 1_024
  @max_map_size 128
  @safe_number_limit 1.0e15
  @allowed_options [:central_body, :sun_direction, :sun_direction_provider]
  @central_body_fields [:name, :mu_km3_s2, :equatorial_radius_km, :j2]
  @campaign_dataset_fields [
    :table_id,
    :provider_id,
    :provider_revision,
    :dataset_revision,
    :body,
    :source_inertial_frame,
    :provider_inertial_frame,
    :earth_fixed_frame,
    :time_scale,
    :interpolation,
    :sample_interval_s,
    :coverage,
    :samples,
    :sources,
    :known_limits,
    :content_verification
  ]

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
  def detect(trajectory, opts \\ [])

  def detect(%Trajectory{} = trajectory, opts) do
    with :ok <- validate_opts(opts),
         :ok <- validate_trajectory(trajectory) do
      case Keyword.fetch(opts, :sun_direction_provider) do
        :error -> detect_fixed_sun(trajectory, opts)
        {:ok, provider} -> detect_provider_sun(trajectory, provider, opts)
      end
    end
  end

  def detect(_trajectory, opts) do
    with :ok <- validate_opts(opts), do: {:error, {:invalid_option, :trajectory}}
  end

  defp detect_fixed_sun(%Trajectory{} = trajectory, opts) do
    central_body = Keyword.get(opts, :central_body, CentralBody.earth())
    sun_direction = Keyword.get(opts, :sun_direction, @default_sun_direction)

    with :ok <- validate_central_body(central_body),
         {:ok, sun_unit} <- normalize_sun_direction(sun_direction),
         {:ok, samples} <- fixed_sun_samples(trajectory.states, central_body, sun_unit),
         {:ok, events} <- fixed_sun_events(samples, trajectory, central_body, sun_unit),
         {:ok, annotated_events} <- annotate_events(events, trajectory) do
      {:ok, annotated_events}
    end
  end

  defp detect_provider_sun(%Trajectory{} = trajectory, provider, opts) do
    central_body = Keyword.get(opts, :central_body, CentralBody.earth())

    with :ok <- validate_central_body(central_body),
         {:ok, provider_model} <- provider_sun_model(provider),
         {:ok, samples} <- provider_sun_samples(trajectory, central_body, provider_model),
         {:ok, events} <- provider_sun_events(samples, trajectory, central_body, provider_model),
         {:ok, annotated_events} <- annotate_events(events, trajectory) do
      {:ok, annotated_events}
    end
  end

  defp provider_sun_model(provider) when is_atom(provider), do: provider_sun_model({provider, []})

  defp provider_sun_model({provider, provider_opts})
       when is_atom(provider) and is_list(provider_opts) do
    with true <- Code.ensure_loaded?(provider),
         true <- function_exported?(provider, :fetch, 2),
         true <- function_exported?(provider, :capabilities, 0),
         :ok <- validate_provider_opts(provider_opts),
         {:ok, capability} <- safe_configured_provider_capability(provider, provider_opts),
         true <- "sun_direction" in capability["outputs"] do
      {:ok, %{provider: provider, provider_opts: provider_opts, capability: capability}}
    else
      {:error, reason} -> {:error, reason}
      false -> {:error, {:invalid_option, :sun_direction_provider}}
      _error -> {:error, {:invalid_option, :sun_direction_provider}}
    end
  end

  defp provider_sun_model(_provider),
    do: {:error, {:invalid_option, :sun_direction_provider}}

  defp safe_configured_provider_capability(provider, provider_opts) do
    Environment.configured_provider_capability(provider, provider_opts)
  rescue
    _error in [
      ArgumentError,
      ArithmeticError,
      BadMapError,
      FunctionClauseError,
      KeyError,
      MatchError,
      RuntimeError,
      UndefinedFunctionError
    ] ->
      {:error, {:environment_provider_callback_failed, provider, :capabilities}}
  end

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

  defp fixed_sun_samples(states, central_body, sun_unit) do
    states
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {state, index}, {:ok, acc} ->
      shadow = shadow_geometry(state.position_km, sun_unit, central_body.equatorial_radius_km)

      if valid_shadow?(shadow) do
        sample = %{
          index: index,
          state: state,
          eclipsed: shadow.eclipsed,
          shadow_axis_distance_km: shadow.axis_distance_km,
          shadow_margin_km: shadow.margin_km,
          eclipse_margin_km: eclipse_margin_km(shadow)
        }

        {:cont, {:ok, [sample | acc]}}
      else
        {:halt, {:error, {:invalid_geometry_result, :shadow}}}
      end
    end)
    |> case do
      {:ok, samples} -> {:ok, Enum.reverse(samples)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp fixed_sun_events(samples, trajectory, central_body, sun_unit) do
    samples
    |> eclipsed_groups()
    |> Enum.reduce_while({:ok, []}, fn group, {:ok, events} ->
      event = event_from_group(group, samples, trajectory, central_body, sun_unit)
      {:cont, {:ok, [event | events]}}
    end)
    |> case do
      {:ok, events} -> {:ok, Enum.reverse(events)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp provider_sun_events(samples, trajectory, central_body, provider_model) do
    samples
    |> eclipsed_groups()
    |> Enum.reduce_while({:ok, []}, fn group, {:ok, events} ->
      event = provider_event_from_group(group, samples, trajectory, central_body, provider_model)
      {:cont, {:ok, [event | events]}}
    end)
    |> case do
      {:ok, events} -> {:ok, Enum.reverse(events)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp annotate_events(events, trajectory) do
    Enum.reduce_while(events, {:ok, []}, fn event, {:ok, acc} ->
      case EventTiming.annotate_event(event, trajectory, :eclipses) do
        %{} = annotated -> {:cont, {:ok, [annotated | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, annotated} -> {:ok, Enum.reverse(annotated)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp provider_sun_sample(state, index, central_body, provider_model) do
    fetch_opts =
      provider_model.provider_opts
      |> Keyword.put(:seconds_since_j2000, state.epoch.seconds_since_j2000)
      |> Keyword.put(:body, central_body.name)
      |> Keyword.put(:frame, state.frame.name)
      |> Keyword.put(:time_scale, state.epoch.scale)

    case safe_provider_fetch(provider_model.provider, :sun_direction, fetch_opts) do
      {:ok, %{} = product} ->
        with :ok <- validate_provider_product(product),
             :ok <- matching_provider_product?(product, provider_model.capability),
             {:ok, sun_unit} <-
               normalize_provider_sun_direction(provider_product_value(product, "sun_direction")) do
          shadow =
            shadow_geometry(state.position_km, sun_unit, central_body.equatorial_radius_km)

          if valid_shadow?(shadow) do
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
          else
            {:error, {:invalid_geometry_result, :shadow}}
          end
        end

      {:error, reason} ->
        {:error, reason}

      _other ->
        {:error, {:invalid_environment_product, :sun_direction}}
    end
  end

  defp safe_provider_fetch(provider, kind, fetch_opts) do
    provider.fetch(kind, fetch_opts)
  rescue
    _error in [
      ArgumentError,
      ArithmeticError,
      BadMapError,
      FunctionClauseError,
      KeyError,
      MatchError,
      RuntimeError,
      UndefinedFunctionError
    ] ->
      {:error, {:environment_provider_callback_failed, provider, :fetch}}
  end

  defp matching_provider_product?(product, capability) do
    if provider_product_value(product, "provider_id") == capability["id"] do
      :ok
    else
      {:error, {:invalid_environment_product, :provider_id}}
    end
  end

  defp validate_provider_product(product) do
    with :ok <- preflight_container(product, :environment_product),
         :ok <- reject_product_alias_collision(product, "provider_id"),
         :ok <- reject_product_alias_collision(product, "sun_direction"),
         :ok <- reject_product_alias_collision(product, "provenance"),
         :ok <- validate_optional_product_map(product, "provenance") do
      :ok
    end
  end

  defp validate_optional_product_map(product, key) do
    case provider_product_value(product, key) do
      nil -> :ok
      %{} -> :ok
      _value -> {:error, {:invalid_environment_product, key}}
    end
  end

  defp provider_product_value(product, key) do
    atom_key = product_atom_key(key)

    case Map.fetch(product, key) do
      {:ok, value} -> value
      :error -> Map.get(product, atom_key)
    end
  end

  defp reject_product_alias_collision(product, key) do
    atom_key = product_atom_key(key)

    if Map.has_key?(product, key) and Map.has_key?(product, atom_key) do
      {:error, {:atom_string_alias_collision, key}}
    else
      :ok
    end
  end

  defp product_atom_key("provider_id"), do: :provider_id
  defp product_atom_key("sun_direction"), do: :sun_direction
  defp product_atom_key("provenance"), do: :provenance

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
      when is_integer(duration_s) or is_float(duration_s) do
    lighting_summary_for_finite_inputs(duration_s, eclipse_overlap_s)
  end

  def lighting_summary(_duration_s, _eclipse_overlap_s) do
    {:error, {:invalid_option, :duration_s}}
  end

  defp lighting_summary_for_finite_inputs(duration_s, eclipse_overlap_s)
       when is_integer(eclipse_overlap_s) or is_float(eclipse_overlap_s) do
    with :ok <- validate_number(:duration_s, duration_s),
         :ok <- validate_number(:eclipse_overlap_s, eclipse_overlap_s) do
      lighting_summary_product(duration_s, eclipse_overlap_s)
    end
  end

  defp lighting_summary_for_finite_inputs(_duration_s, _eclipse_overlap_s),
    do: {:error, {:invalid_option, :eclipse_overlap_s}}

  defp lighting_summary_product(duration_s, eclipse_overlap_s) do
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

  @doc """
  Refines one bracketed cylindrical eclipse boundary between two sampled states.

  The boundary is linearly interpolated over the same cylindrical shadow margin
  used by the detector. It is not a penumbra model or a root-solved event time.
  """
  def refine_eclipse_boundary(before_state, after_state, opts \\ [])

  def refine_eclipse_boundary(
        %StateVector{} = before_state,
        %StateVector{} = after_state,
        opts
      ) do
    with :ok <- validate_opts(opts),
         central_body = Keyword.get(opts, :central_body, CentralBody.earth()),
         sun_direction = Keyword.get(opts, :sun_direction, @default_sun_direction),
         :ok <- validate_state_pair(before_state, after_state),
         :ok <- validate_central_body(central_body),
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

  def refine_eclipse_boundary(_before_state, _after_state, opts) do
    with :ok <- validate_opts(opts), do: {:error, {:invalid_option, :eclipse_boundary}}
  end

  defp validate_central_body(%CentralBody{name: name, equatorial_radius_km: radius}) do
    if is_atom(name) and finite_number?(radius) and radius > 0.0 do
      :ok
    else
      {:error, {:invalid_central_body, :equatorial_radius_km}}
    end
  end

  defp validate_central_body(_central_body), do: {:error, {:invalid_option, :central_body}}

  defp validate_trajectory(%Trajectory{states: states, assumptions: assumptions}) do
    with {:ok, states} <- bounded_list_items(states, :states, @max_states),
         true <- is_map(assumptions),
         :ok <- preflight_container(assumptions, :trajectory_assumptions),
         :ok <- validate_states(states) do
      :ok
    else
      false -> {:error, {:invalid_trajectory, :assumptions}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_states(states) do
    states
    |> Enum.reduce_while({:ok, nil}, fn
      %StateVector{} = state, {:ok, previous_s} ->
        with :ok <- validate_state(state, :state),
             {:ok, seconds} <- state_epoch_seconds(state, :state) do
          if is_number(previous_s) and seconds <= previous_s do
            {:halt, {:error, {:invalid_trajectory, :non_increasing_epochs}}}
          else
            {:cont, {:ok, seconds}}
          end
        else
          {:error, reason} -> {:halt, {:error, reason}}
        end

      _state, {:ok, _previous_s} ->
        {:halt, {:error, {:invalid_trajectory, :state}}}
    end)
    |> case do
      {:ok, _previous_s} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_state_pair(before_state, after_state) do
    with :ok <- validate_state(before_state, :before_state),
         :ok <- validate_state(after_state, :after_state) do
      cond do
        not Frame.compatible?(before_state.frame, after_state.frame) ->
          {:error, :incompatible_state_frames}

        before_state.epoch.scale != after_state.epoch.scale ->
          {:error, :incompatible_epoch_scales}

        after_state.epoch.seconds_since_j2000 <= before_state.epoch.seconds_since_j2000 ->
          {:error, :non_increasing_state_epochs}

        true ->
          :ok
      end
    end
  end

  defp validate_state(
         %StateVector{
           position_km: position_km,
           velocity_km_s: velocity_km_s,
           epoch: %Epoch{scale: scale, seconds_since_j2000: seconds_since_j2000},
           frame: %Frame{name: name, center: center, orientation: orientation}
         },
         field
       ) do
    cond do
      not finite_vector?(position_km) ->
        {:error, {:invalid_state, field}}

      not finite_vector?(velocity_km_s) ->
        {:error, {:invalid_state, field}}

      scale not in [:tdb, :tai, :utc] or not finite_number?(seconds_since_j2000) ->
        {:error, {:invalid_state, field}}

      not (is_atom(name) and is_atom(center) and is_atom(orientation)) ->
        {:error, {:invalid_state, field}}

      true ->
        :ok
    end
  end

  defp validate_state(_state, field), do: {:error, {:invalid_state, field}}

  defp state_epoch_seconds(%StateVector{epoch: %Epoch{seconds_since_j2000: seconds}}, field) do
    if finite_number?(seconds) do
      {:ok, seconds * 1.0}
    else
      {:error, {:invalid_state, field}}
    end
  end

  defp normalize_sun_direction(sun_direction) do
    cond do
      not finite_vector?(sun_direction) ->
        {:error, {:invalid_option, :sun_direction}}

      vector_norm(sun_direction) <= 0.0 ->
        {:error, {:invalid_option, :sun_direction}}

      true ->
        {:ok, Vector3.scale(sun_direction, 1.0 / vector_norm(sun_direction))}
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

  defp valid_shadow?(%{
         eclipsed: eclipsed,
         sun_projection_km: sun_projection_km,
         axis_distance_km: axis_distance_km,
         margin_km: margin_km
       }) do
    is_boolean(eclipsed) and finite_number?(sun_projection_km) and
      finite_number?(axis_distance_km) and finite_number?(margin_km)
  end

  defp vector_norm({x, y, z}), do: :math.sqrt(x * x + y * y + z * z)

  defp finite_vector?({x, y, z}),
    do: finite_number?(x) and finite_number?(y) and finite_number?(z)

  defp finite_vector?(_vector), do: false

  defp validate_number(field, value) when is_integer(value) or is_float(value) do
    if finite_number?(value) do
      :ok
    else
      {:error, {:invalid_option, field}}
    end
  end

  defp validate_number(field, _value), do: {:error, {:invalid_option, field}}

  defp validate_opts(opts) do
    with {:ok, items} <- bounded_list_items(opts, :opts, @max_opts_length),
         true <- Enum.all?(items, &keyword_entry?/1),
         true <- unique_keyword_keys?(items),
         :ok <- preflight_option_values(items),
         :ok <- reject_unsupported_options(items) do
      :ok
    else
      false -> {:error, {:invalid_option, :opts}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp keyword_entry?({key, _value}) when is_atom(key), do: true
  defp keyword_entry?(_entry), do: false

  defp unique_keyword_keys?(items) do
    keys = Enum.map(items, fn {key, _value} -> key end)
    length(keys) == length(Enum.uniq(keys))
  end

  defp preflight_option_values(items) do
    Enum.reduce_while(items, :ok, fn {key, value}, :ok ->
      case preflight_option_value(key, value) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp preflight_option_value(:central_body, %CentralBody{} = central_body),
    do:
      preflight_exact_struct(
        central_body,
        CentralBody,
        @central_body_fields,
        :opts,
        {:invalid_central_body, :equatorial_radius_km}
      )

  defp preflight_option_value(:sun_direction, {x, y, z}),
    do: preflight_vector_components([x, y, z], :sun_direction)

  defp preflight_option_value(:sun_direction, [x, y, z]),
    do: preflight_vector_components([x, y, z], :sun_direction)

  defp preflight_option_value(:sun_direction_provider, provider),
    do: preflight_provider_spec(provider, :sun_direction_provider)

  defp preflight_option_value(_key, value), do: preflight_container(value, :opts)

  defp validate_provider_opts(opts) do
    with {:ok, items} <- bounded_list_items(opts, :opts, @max_opts_length),
         true <- Enum.all?(items, &keyword_entry?/1),
         true <- unique_keyword_keys?(items),
         :ok <- preflight_provider_option_values(items) do
      :ok
    else
      false -> {:error, {:invalid_option, :opts}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp preflight_provider_option_values(items) do
    Enum.reduce_while(items, :ok, fn {key, value}, :ok ->
      case preflight_provider_option_value(key, value) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp preflight_provider_option_value(:dataset, %Dataset{} = dataset),
    do: preflight_exact_struct_shape(dataset, Dataset, @campaign_dataset_fields, :opts)

  defp preflight_provider_option_value(:sun_direction, {x, y, z}),
    do: preflight_vector_components([x, y, z], :sun_direction)

  defp preflight_provider_option_value(:sun_direction, [x, y, z]),
    do: preflight_vector_components([x, y, z], :sun_direction)

  defp preflight_provider_option_value(_key, value), do: preflight_container(value, :opts)

  defp preflight_provider_spec(provider, _field) when is_atom(provider), do: :ok

  defp preflight_provider_spec({provider, provider_opts}, _field)
       when is_atom(provider) and is_list(provider_opts),
       do: validate_provider_opts(provider_opts)

  defp preflight_provider_spec(_provider, field), do: {:error, {:invalid_option, field}}

  defp preflight_vector_components(components, field) do
    if Enum.all?(components, &finite_number?/1) do
      :ok
    else
      {:error, {:invalid_option, field}}
    end
  end

  defp preflight_exact_struct(struct, module, fields, field, numeric_error) do
    with :ok <- preflight_exact_struct_shape(struct, module, fields, field) do
      struct
      |> Map.take(fields)
      |> Map.values()
      |> preflight_struct_field_values(field, numeric_error)
    end
  end

  defp preflight_struct_field_values(values, field, numeric_error) do
    Enum.reduce_while(values, :ok, fn value, :ok ->
      case preflight_struct_field_value(value, field, numeric_error) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp preflight_struct_field_value(value, _field, _numeric_error)
       when is_nil(value) or is_boolean(value) or is_atom(value) or is_binary(value),
       do: :ok

  defp preflight_struct_field_value(value, _field, numeric_error)
       when is_integer(value) or is_float(value) do
    if finite_number?(value) do
      :ok
    else
      {:error, numeric_error}
    end
  end

  defp preflight_struct_field_value(_value, field, _numeric_error),
    do: {:error, {:invalid_container, field}}

  defp preflight_exact_struct_shape(struct, module, fields, field) do
    expected_keys = MapSet.new([:__struct__ | fields])

    cond do
      Map.get(struct, :__struct__) != module ->
        {:error, {:invalid_container, field}}

      MapSet.new(Map.keys(struct)) != expected_keys ->
        {:error, {:invalid_container, field}}

      true ->
        :ok
    end
  end

  defp reject_unsupported_options(items) do
    Enum.reduce_while(items, :ok, fn {key, _value}, :ok ->
      if key in @allowed_options do
        {:cont, :ok}
      else
        {:halt, {:error, {:unsupported_option, key}}}
      end
    end)
  end

  defp preflight_container(term, field) do
    preflight_container([{term, 0}], 0, field)
  end

  defp preflight_container([], _visited, _field), do: :ok

  defp preflight_container(_stack, visited, field) when visited > @max_container_entries,
    do: {:error, {:container_limit_exceeded, field}}

  defp preflight_container([{_term, depth} | _rest], _visited, field)
       when depth > @max_container_depth do
    {:error, {:container_depth_exceeded, field}}
  end

  defp preflight_container([{%{__struct__: _struct}, _depth} | _rest], _visited, field),
    do: {:error, {:invalid_container, field}}

  defp preflight_container([{tuple, _depth} | _rest], _visited, field) when is_tuple(tuple),
    do: {:error, {:invalid_container, field}}

  defp preflight_container([{%{} = map, depth} | rest], visited, field) do
    cond do
      map_size(map) > @max_map_size ->
        {:error, {:container_limit_exceeded, field}}

      invalid_map_key?(map) ->
        {:error, {:invalid_container, field}}

      true ->
        with :ok <- reject_generic_alias_collisions(map) do
          children = Enum.map(Map.values(map), &{&1, depth + 1})
          preflight_container(children ++ rest, visited + map_size(map), field)
        end
    end
  end

  defp preflight_container([{list, depth} | rest], visited, field) when is_list(list) do
    case bounded_list_items(list, field, @max_list_length) do
      {:ok, items} ->
        children = Enum.map(items, &{&1, depth + 1})
        preflight_container(children ++ rest, visited + length(items), field)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp preflight_container([{term, _depth} | rest], visited, field)
       when is_nil(term) or is_boolean(term) or is_atom(term) or is_binary(term),
       do: preflight_container(rest, visited + 1, field)

  defp preflight_container([{term, _depth} | rest], visited, field)
       when is_integer(term) or is_float(term) do
    if finite_number?(term) do
      preflight_container(rest, visited + 1, field)
    else
      {:error, {:invalid_container, field}}
    end
  end

  defp preflight_container([_term | _rest], _visited, field),
    do: {:error, {:invalid_container, field}}

  defp invalid_map_key?(map) do
    Enum.any?(Map.keys(map), fn key -> not (is_atom(key) or is_binary(key)) end)
  end

  defp reject_generic_alias_collisions(%{} = map) do
    atom_key_strings =
      map
      |> Map.keys()
      |> Enum.filter(&is_atom/1)
      |> Enum.map(&Atom.to_string/1)
      |> MapSet.new()

    case Enum.find(Map.keys(map), fn key ->
           is_binary(key) and MapSet.member?(atom_key_strings, key)
         end) do
      nil -> :ok
      key -> {:error, {:atom_string_alias_collision, key}}
    end
  end

  defp bounded_list_items(list, field, limit) when is_list(list) do
    bounded_list_items(list, [], 0, field, limit)
  end

  defp bounded_list_items(_not_list, field, _limit), do: {:error, {:invalid_container, field}}

  defp bounded_list_items(_list, _acc, count, field, limit) when count > limit,
    do: {:error, {:container_limit_exceeded, field}}

  defp bounded_list_items([], acc, _count, _field, _limit), do: {:ok, Enum.reverse(acc)}

  defp bounded_list_items([head | tail], acc, count, field, limit) do
    bounded_list_items(tail, [head | acc], count + 1, field, limit)
  end

  defp bounded_list_items(_improper_tail, _acc, _count, field, _limit),
    do: {:error, {:invalid_container, field}}

  defp finite_number?(value) when is_integer(value), do: abs(value) <= @safe_number_limit

  defp finite_number?(value) when is_float(value) do
    value == value and value - value == 0.0 and abs(value) <= @safe_number_limit
  end

  defp finite_number?(_value), do: false

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
    provenance = provider_product_value(first.sun_product, "provenance") || %{}

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
        sun_direction_dataset_semantic_sha256: provenance["dataset_semantic_sha256"],
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
