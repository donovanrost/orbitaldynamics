defmodule OrbitalDynamics.EventDetectors.TargetVisibility do
  @moduledoc """
  Surface-target visibility window detection.

  The detector evaluates each propagated sample against a target-local horizon
  and merges contiguous visible samples. Boundaries are linearly interpolated
  between adjacent samples when the horizon crossing is bracketed.
  """

  alias OrbitalDynamics.{
    AccessGeometry,
    CentralBody,
    EventTiming,
    StateVector,
    Target,
    Trajectory
  }

  @behaviour OrbitalDynamics.EventDetector

  @doc """
  Declares the detector model, timing policy, and known limits.
  """
  @impl OrbitalDynamics.EventDetector
  def capabilities do
    %{
      detector: :target_visibility,
      model: :sampled_surface_target_visibility,
      validation_level: :analysis,
      timing_policy: :sampled_state_linear_boundary,
      interpolation: :linear_sample_crossing,
      boundary_refinement: :target_visibility_linear_margin_interpolation,
      coordinate_model: :spherical_earth_access_geometry,
      known_limits: [
        :sample_cadence_limited,
        :refinement_not_root_solved,
        :no_terrain_mask,
        :no_refraction_model,
        :no_lighting_category_model,
        :no_sensor_specific_visibility_model
      ]
    }
  end

  @impl OrbitalDynamics.EventDetector
  def detect(%Trajectory{} = trajectory, opts \\ []) do
    target = Keyword.fetch!(opts, :target)
    central_body = Keyword.get(opts, :central_body, CentralBody.earth())

    with :ok <- validate_inputs(target, central_body) do
      samples =
        trajectory.states
        |> Enum.with_index()
        |> Enum.map(fn {state, index} ->
          elevation_deg = AccessGeometry.elevation_deg(state, target, central_body)

          %{
            index: index,
            state: state,
            visible: elevation_deg >= target.minimum_elevation_deg,
            elevation_deg: elevation_deg,
            elevation_margin_deg: elevation_deg - target.minimum_elevation_deg
          }
        end)

      {:ok,
       samples
       |> visible_groups()
       |> Enum.map(&event_from_group(&1, samples, target, trajectory))
       |> Enum.map(&EventTiming.annotate_event(&1, trajectory, :target_visibility))}
    end
  end

  @doc """
  Refines one bracketed target visibility boundary between two sampled states.

  The refinement is a linear interpolation over target elevation margin. It is
  not a root-solved event time and remains bounded by the input sample cadence.
  """
  def refine_visibility_boundary(
        %StateVector{} = before_state,
        %StateVector{} = after_state,
        %Target{} = target,
        opts \\ []
      ) do
    central_body = Keyword.get(opts, :central_body, CentralBody.earth())

    with :ok <- validate_inputs(target, central_body) do
      before_elevation_deg = AccessGeometry.elevation_deg(before_state, target, central_body)
      after_elevation_deg = AccessGeometry.elevation_deg(after_state, target, central_body)
      before_margin = before_elevation_deg - target.minimum_elevation_deg
      after_margin = after_elevation_deg - target.minimum_elevation_deg

      cond do
        not bracketed_boundary?(before_margin, after_margin) ->
          {:error, :not_bracketed}

        true ->
          fraction = interpolation_fraction(before_margin, after_margin)

          {:ok,
           %{
             boundary: boundary_type(before_margin, after_margin),
             epoch: interpolate_epoch(before_state.epoch, after_state.epoch, fraction),
             interpolation: :linear_sample_crossing,
             interpolation_fraction: fraction,
             before_elevation_deg: before_elevation_deg,
             after_elevation_deg: after_elevation_deg,
             minimum_elevation_deg: target.minimum_elevation_deg,
             assumptions:
               EventTiming.boundary_policy(before_state.epoch, after_state.epoch)
               |> Map.merge(%{
                 refinement_model: :target_visibility_linear_margin_interpolation
               })
           }}
      end
    end
  end

  defp validate_inputs(%Target{}, %CentralBody{equatorial_radius_km: radius})
       when is_number(radius) and radius > 0.0 do
    :ok
  end

  defp validate_inputs(%Target{}, %CentralBody{}),
    do: {:error, {:invalid_central_body, :equatorial_radius_km}}

  defp validate_inputs(_target, %CentralBody{}), do: {:error, {:invalid_option, :target}}

  defp visible_groups(samples) do
    {groups, current_group} =
      Enum.reduce(samples, {[], []}, fn sample, {groups, current_group} ->
        cond do
          sample.visible ->
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

  defp event_from_group(group, samples, target, trajectory) do
    first = List.first(group)
    last = List.last(group)
    max_elevation_deg = group |> Enum.map(& &1.elevation_deg) |> Enum.max()
    {starts_at, start_boundary, start_boundary_detail} = start_boundary(first, samples, target)
    {ends_at, end_boundary, end_boundary_detail} = end_boundary(last, samples, target)

    %{
      type: :target_visibility,
      starts_at: starts_at,
      ends_at: ends_at,
      metadata:
        Map.merge(AccessGeometry.assumptions(), %{
          scenario_id: trajectory.scenario_id,
          target_id: target.id,
          target_priority: target.priority,
          minimum_elevation_deg: target.minimum_elevation_deg,
          max_elevation_deg: max_elevation_deg,
          interpolation: :linear_sample_crossing,
          boundary_refinement: :target_visibility_linear_margin_interpolation,
          start_boundary: start_boundary,
          end_boundary: end_boundary,
          start_boundary_detail: start_boundary_detail,
          end_boundary_detail: end_boundary_detail,
          sample_count: length(group),
          start_sample_index: first.index,
          end_sample_index: last.index
        })
    }
  end

  defp start_boundary(first, samples, target) do
    if first.index == 0 do
      {first.state.epoch, :clipped_start, clipped_boundary_detail(:clipped_start, first)}
    else
      previous = Enum.at(samples, first.index - 1)

      {interpolate_epoch(previous, first), :interpolated,
       boundary_detail(previous, first, target, :start)}
    end
  end

  defp end_boundary(last, samples, target) do
    if last.index == length(samples) - 1 do
      {last.state.epoch, :clipped_end, clipped_boundary_detail(:clipped_end, last)}
    else
      next_sample = Enum.at(samples, last.index + 1)

      {interpolate_epoch(last, next_sample), :interpolated,
       boundary_detail(last, next_sample, target, :end)}
    end
  end

  defp boundary_detail(before_sample, after_sample, target, edge) do
    before_margin = before_sample.elevation_margin_deg
    after_margin = after_sample.elevation_margin_deg
    fraction = interpolation_fraction(before_margin, after_margin)

    before_sample.state.epoch
    |> EventTiming.boundary_policy(after_sample.state.epoch)
    |> Map.merge(%{
      edge: edge,
      boundary: boundary_type(before_margin, after_margin),
      interpolation_fraction: fraction,
      before_sample_index: before_sample.index,
      after_sample_index: after_sample.index,
      before_elevation_deg: before_sample.elevation_deg,
      after_elevation_deg: after_sample.elevation_deg,
      minimum_elevation_deg: target.minimum_elevation_deg
    })
  end

  defp clipped_boundary_detail(boundary, sample) do
    %{
      boundary: boundary,
      interpolation: :clipped_to_sample,
      interpolation_fraction: 0.0,
      sample_index: sample.index,
      elevation_deg: sample.elevation_deg,
      root_solved: false,
      confidence: :bounded_by_sample_cadence
    }
  end

  defp interpolate_epoch(before_sample, after_sample) do
    before_margin = before_sample.elevation_margin_deg
    after_margin = after_sample.elevation_margin_deg

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

  defp boundary_type(before_margin, after_margin) do
    cond do
      before_margin < 0.0 and after_margin >= 0.0 -> :visibility_start
      before_margin >= 0.0 and after_margin < 0.0 -> :visibility_end
      before_margin == 0.0 -> :sampled_boundary
      after_margin == 0.0 -> :sampled_boundary
    end
  end
end
