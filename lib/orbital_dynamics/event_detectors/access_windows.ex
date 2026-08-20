defmodule OrbitalDynamics.EventDetectors.AccessWindows do
  @moduledoc """
  Ground-station access window detection.

  This detector evaluates each trajectory state independently and merges
  contiguous visible samples. Start and end times are linearly interpolated
  between adjacent samples when the event boundary is bracketed.

  Callers may opt into `:bracketed_bisection` boundary refinement. That path
  solves elevation margin on a cubic-Hermite state interpolant built only from
  the two bracketing samples. It narrows numerical placement inside the sample
  bracket; it is not dense propagator output or an externally validated physical
  event time.
  """

  alias OrbitalDynamics.{
    AccessGeometry,
    CentralBody,
    EventTiming,
    Frame,
    GroundStation,
    StateVector,
    Trajectory,
    Vector3
  }

  @behaviour OrbitalDynamics.EventDetector

  @default_root_tolerance_s 1.0e-3
  @default_root_max_iterations 64
  @maximum_root_iterations 100

  @doc """
  Declares the detector model, timing policy, and known limits.
  """
  @impl OrbitalDynamics.EventDetector
  def capabilities do
    %{
      detector: :access_windows,
      model: :sampled_ground_station_access,
      validation_level: :analysis,
      timing_policy: :sampled_state_linear_boundary,
      interpolation: :linear_sample_crossing,
      boundary_refinement: :aos_los_linear_margin_interpolation,
      supported_boundary_refinements: [:linear_sample_crossing, :bracketed_bisection],
      root_refinement_defaults: %{
        root_tolerance_s: @default_root_tolerance_s,
        root_max_iterations: @default_root_max_iterations
      },
      coordinate_model: :spherical_earth_access_geometry,
      known_limits: [
        :sample_cadence_limited,
        :refinement_not_root_solved,
        :root_refinement_interpolated_state_only,
        :root_refinement_not_externally_validated,
        :multiple_crossings_within_sample_not_resolved,
        :no_terrain_mask,
        :no_refraction_model,
        :constant_earth_rotation_access_geometry
      ]
    }
  end

  @impl OrbitalDynamics.EventDetector
  def detect(%Trajectory{} = trajectory, opts \\ []) do
    station = Keyword.fetch!(opts, :ground_station)
    central_body = Keyword.get(opts, :central_body, CentralBody.earth())

    with :ok <- validate_inputs(station, central_body),
         {:ok, refinement} <- boundary_refinement_options(opts) do
      samples =
        trajectory.states
        |> Enum.with_index()
        |> Enum.map(fn {state, index} ->
          elevation_deg = AccessGeometry.elevation_deg(state, station, central_body)

          %{
            index: index,
            state: state,
            visible: elevation_deg >= station.minimum_elevation_deg,
            elevation_deg: elevation_deg,
            elevation_margin_deg: elevation_deg - station.minimum_elevation_deg
          }
        end)

      with {:ok, events} <- events_from_groups(samples, station, trajectory, refinement) do
        {:ok,
         Enum.map(events, fn event ->
           EventTiming.annotate_event(event, trajectory, :access_windows)
         end)}
      end
    end
  end

  @doc """
  Refines one bracketed AOS/LOS boundary between two sampled states.

  The default refinement remains linear interpolation over elevation margin.
  Pass `boundary_refinement: :bracketed_bisection` to solve the elevation-margin
  root on a cubic-Hermite interpolant of the two states. The opt-in solver uses
  `root_tolerance_s: 1.0e-3` and `root_max_iterations: 64` by default.

  Root-refined results are bounded with respect to that interpolated-state
  model only. They do not claim dense propagation, authoritative Earth
  orientation, atmospheric refraction, terrain masking, external validation,
  or flight fidelity.
  """
  def refine_aos_los_boundary(
        %StateVector{} = before_state,
        %StateVector{} = after_state,
        %GroundStation{} = station,
        opts \\ []
      ) do
    central_body = Keyword.get(opts, :central_body, CentralBody.earth())

    with :ok <- validate_inputs(station, central_body),
         {:ok, refinement} <- boundary_refinement_options(opts) do
      before_elevation_deg = AccessGeometry.elevation_deg(before_state, station, central_body)
      after_elevation_deg = AccessGeometry.elevation_deg(after_state, station, central_body)
      before_margin = before_elevation_deg - station.minimum_elevation_deg
      after_margin = after_elevation_deg - station.minimum_elevation_deg

      cond do
        not bracketed_boundary?(before_margin, after_margin) ->
          {:error, :not_bracketed}

        refinement.mode == :linear_sample_crossing ->
          linear_boundary_result(
            before_state,
            after_state,
            station,
            before_elevation_deg,
            after_elevation_deg,
            before_margin,
            after_margin
          )

        refinement.mode == :bracketed_bisection ->
          root_refined_boundary_result(
            before_state,
            after_state,
            station,
            central_body,
            before_elevation_deg,
            after_elevation_deg,
            before_margin,
            after_margin,
            refinement
          )
      end
    end
  end

  defp linear_boundary_result(
         before_state,
         after_state,
         station,
         before_elevation_deg,
         after_elevation_deg,
         before_margin,
         after_margin
       ) do
    fraction = interpolation_fraction(before_margin, after_margin)

    {:ok,
     %{
       boundary: boundary_type(before_margin, after_margin),
       epoch: interpolate_epoch(before_state.epoch, after_state.epoch, fraction),
       interpolation: :linear_sample_crossing,
       interpolation_fraction: fraction,
       before_elevation_deg: before_elevation_deg,
       after_elevation_deg: after_elevation_deg,
       minimum_elevation_deg: station.minimum_elevation_deg,
       assumptions:
         EventTiming.boundary_policy(before_state.epoch, after_state.epoch)
         |> Map.merge(%{
           refinement_model: :aos_los_linear_margin_interpolation
         })
     }}
  end

  defp root_refined_boundary_result(
         before_state,
         after_state,
         station,
         central_body,
         before_elevation_deg,
         after_elevation_deg,
         before_margin,
         after_margin,
         refinement
       ) do
    with :ok <- validate_root_states(before_state, after_state),
         {:ok, root} <-
           solve_elevation_margin_root(
             before_state,
             after_state,
             station,
             central_body,
             before_margin,
             after_margin,
             refinement
           ) do
      epoch = interpolate_epoch(before_state.epoch, after_state.epoch, root.fraction)
      input_bracket_s = epoch_delta_s(before_state.epoch, after_state.epoch)
      root_bracket_s = (root.after_fraction - root.before_fraction) * input_bracket_s

      {:ok,
       %{
         boundary: boundary_type(before_margin, after_margin),
         epoch: epoch,
         interpolation: :cubic_hermite_state,
         interpolation_fraction: root.fraction,
         before_elevation_deg: before_elevation_deg,
         after_elevation_deg: after_elevation_deg,
         minimum_elevation_deg: station.minimum_elevation_deg,
         assumptions: %{
           event_timing_policy: :sampled_state_bracketed_root_refinement,
           interpolation: :cubic_hermite_state,
           refinement_model: :aos_los_bracketed_bisection,
           root_solver: :bisection,
           root_function: :elevation_margin_deg,
           root_scope: :cubic_hermite_interpolated_state_geometry,
           root_solved: true,
           validation_level: :analysis,
           confidence: :bounded_root_in_interpolated_state,
           convergence: root.convergence,
           requested_root_tolerance_s: refinement.root_tolerance_s,
           event_time_tolerance_s: root_bracket_s / 2.0,
           event_time_bracket_s: root_bracket_s,
           input_event_time_bracket_s: input_bracket_s,
           before_epoch_s: epoch_seconds(before_state.epoch),
           after_epoch_s: epoch_seconds(after_state.epoch),
           root_bracket_before_epoch_s:
             fraction_epoch_seconds(before_state.epoch, after_state.epoch, root.before_fraction),
           root_bracket_after_epoch_s:
             fraction_epoch_seconds(before_state.epoch, after_state.epoch, root.after_fraction),
           root_bracket_before_margin_deg: root.before_margin_deg,
           root_bracket_after_margin_deg: root.after_margin_deg,
           root_estimate_margin_deg: root.margin_deg,
           root_iterations: root.iterations,
           root_function_evaluations: root.function_evaluations,
           root_max_iterations: refinement.root_max_iterations,
           model_limits: [
             :cubic_hermite_state_interpolation_between_samples,
             :not_dense_propagator_output,
             :single_bracketed_crossing_selected,
             :constant_earth_rotation_access_geometry,
             :not_externally_validated,
             :not_flight_fidelity
           ]
         }
       }}
    end
  end

  defp boundary_refinement_options(opts) do
    case Keyword.get(opts, :boundary_refinement, :linear_sample_crossing) do
      mode when mode in [:linear_sample_crossing, :aos_los_linear_margin_interpolation] ->
        {:ok, %{mode: :linear_sample_crossing}}

      mode when mode in [:bracketed_bisection, :aos_los_bracketed_bisection] ->
        root_tolerance_s = Keyword.get(opts, :root_tolerance_s, @default_root_tolerance_s)

        root_max_iterations =
          Keyword.get(opts, :root_max_iterations, @default_root_max_iterations)

        with :ok <- validate_root_tolerance(root_tolerance_s),
             :ok <- validate_root_max_iterations(root_max_iterations) do
          {:ok,
           %{
             mode: :bracketed_bisection,
             central_body: Keyword.get(opts, :central_body, CentralBody.earth()),
             root_tolerance_s: root_tolerance_s * 1.0,
             root_max_iterations: root_max_iterations
           }}
        end

      mode ->
        {:error, {:unsupported_boundary_refinement, mode}}
    end
  end

  defp validate_root_tolerance(value) when is_number(value) and value > 0.0, do: :ok
  defp validate_root_tolerance(_value), do: {:error, {:invalid_option, :root_tolerance_s}}

  defp validate_root_max_iterations(value)
       when is_integer(value) and value > 0 and value <= @maximum_root_iterations,
       do: :ok

  defp validate_root_max_iterations(_value),
    do: {:error, {:invalid_option, :root_max_iterations}}

  defp validate_root_states(before_state, after_state) do
    cond do
      not Frame.compatible?(before_state.frame, after_state.frame) ->
        {:error, :incompatible_state_frames}

      before_state.epoch.scale != after_state.epoch.scale ->
        {:error, :incompatible_epoch_scales}

      epoch_seconds(after_state.epoch) <= epoch_seconds(before_state.epoch) ->
        {:error, :non_increasing_state_epochs}

      true ->
        :ok
    end
  end

  defp solve_elevation_margin_root(
         before_state,
         after_state,
         station,
         central_body,
         before_margin,
         after_margin,
         refinement
       ) do
    cond do
      before_margin == 0.0 ->
        {:ok, exact_root(0.0, before_margin, after_margin)}

      after_margin == 0.0 ->
        {:ok, exact_root(1.0, before_margin, after_margin)}

      true ->
        duration_s = epoch_delta_s(before_state.epoch, after_state.epoch)

        bisect_root(
          before_state,
          after_state,
          station,
          central_body,
          0.0,
          before_margin,
          1.0,
          after_margin,
          duration_s,
          refinement,
          0,
          2
        )
    end
  end

  defp exact_root(fraction, before_margin, after_margin) do
    margin = if fraction == 0.0, do: before_margin, else: after_margin

    %{
      fraction: fraction,
      margin_deg: margin,
      before_fraction: fraction,
      after_fraction: fraction,
      before_margin_deg: margin,
      after_margin_deg: margin,
      iterations: 0,
      function_evaluations: 2,
      convergence: :exact_sample
    }
  end

  defp bisect_root(
         before_state,
         after_state,
         station,
         central_body,
         before_fraction,
         before_margin,
         after_fraction,
         after_margin,
         duration_s,
         refinement,
         iterations,
         function_evaluations
       ) do
    half_bracket_s = (after_fraction - before_fraction) * duration_s / 2.0

    cond do
      half_bracket_s <= refinement.root_tolerance_s ->
        fraction = (before_fraction + after_fraction) / 2.0

        margin =
          interpolated_elevation_margin(
            before_state,
            after_state,
            station,
            central_body,
            fraction
          )

        {:ok,
         %{
           fraction: fraction,
           margin_deg: margin,
           before_fraction: before_fraction,
           after_fraction: after_fraction,
           before_margin_deg: before_margin,
           after_margin_deg: after_margin,
           iterations: iterations,
           function_evaluations: function_evaluations + 1,
           convergence: :time_bracket
         }}

      iterations >= refinement.root_max_iterations ->
        {:error,
         {:root_refinement_not_converged,
          %{
            root_iterations: iterations,
            root_max_iterations: refinement.root_max_iterations,
            requested_root_tolerance_s: refinement.root_tolerance_s,
            remaining_event_time_bracket_s: half_bracket_s * 2.0
          }}}

      true ->
        fraction = (before_fraction + after_fraction) / 2.0

        margin =
          interpolated_elevation_margin(
            before_state,
            after_state,
            station,
            central_body,
            fraction
          )

        cond do
          margin == 0.0 ->
            {:ok,
             %{
               fraction: fraction,
               margin_deg: margin,
               before_fraction: fraction,
               after_fraction: fraction,
               before_margin_deg: margin,
               after_margin_deg: margin,
               iterations: iterations + 1,
               function_evaluations: function_evaluations + 1,
               convergence: :exact_interpolated_root
             }}

          same_sign?(before_margin, margin) ->
            bisect_root(
              before_state,
              after_state,
              station,
              central_body,
              fraction,
              margin,
              after_fraction,
              after_margin,
              duration_s,
              refinement,
              iterations + 1,
              function_evaluations + 1
            )

          true ->
            bisect_root(
              before_state,
              after_state,
              station,
              central_body,
              before_fraction,
              before_margin,
              fraction,
              margin,
              duration_s,
              refinement,
              iterations + 1,
              function_evaluations + 1
            )
        end
    end
  end

  defp interpolated_elevation_margin(
         before_state,
         after_state,
         station,
         central_body,
         fraction
       ) do
    before_state
    |> cubic_hermite_state(after_state, fraction)
    |> AccessGeometry.elevation_deg(station, central_body)
    |> Kernel.-(station.minimum_elevation_deg)
  end

  defp cubic_hermite_state(before_state, after_state, fraction) do
    duration_s = epoch_seconds(after_state.epoch) - epoch_seconds(before_state.epoch)
    fraction_squared = fraction * fraction
    fraction_cubed = fraction_squared * fraction

    position_km =
      vector_sum([
        {before_state.position_km, 2.0 * fraction_cubed - 3.0 * fraction_squared + 1.0},
        {before_state.velocity_km_s,
         (fraction_cubed - 2.0 * fraction_squared + fraction) * duration_s},
        {after_state.position_km, -2.0 * fraction_cubed + 3.0 * fraction_squared},
        {after_state.velocity_km_s, (fraction_cubed - fraction_squared) * duration_s}
      ])

    velocity_km_s =
      vector_sum([
        {before_state.position_km, (6.0 * fraction_squared - 6.0 * fraction) / duration_s},
        {before_state.velocity_km_s, 3.0 * fraction_squared - 4.0 * fraction + 1.0},
        {after_state.position_km, (-6.0 * fraction_squared + 6.0 * fraction) / duration_s},
        {after_state.velocity_km_s, 3.0 * fraction_squared - 2.0 * fraction}
      ])

    %StateVector{
      position_km: position_km,
      velocity_km_s: velocity_km_s,
      epoch: interpolate_epoch(before_state.epoch, after_state.epoch, fraction),
      frame: before_state.frame
    }
  end

  defp vector_sum(terms) do
    Enum.reduce(terms, {0.0, 0.0, 0.0}, fn {vector, coefficient}, sum ->
      Vector3.add(sum, Vector3.scale(vector, coefficient))
    end)
  end

  defp same_sign?(left, right) do
    (left < 0.0 and right < 0.0) or (left > 0.0 and right > 0.0)
  end

  defp validate_inputs(%GroundStation{}, %CentralBody{equatorial_radius_km: radius})
       when is_number(radius) and radius > 0.0 do
    :ok
  end

  defp validate_inputs(%GroundStation{}, %CentralBody{}),
    do: {:error, {:invalid_central_body, :equatorial_radius_km}}

  defp validate_inputs(_station, %CentralBody{}), do: {:error, {:invalid_option, :ground_station}}

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

  defp events_from_groups(samples, station, trajectory, refinement) do
    samples
    |> visible_groups()
    |> Enum.reduce_while({:ok, []}, fn group, {:ok, events} ->
      case event_from_group(group, samples, station, trajectory, refinement) do
        {:ok, event} -> {:cont, {:ok, [event | events]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, events} -> {:ok, Enum.reverse(events)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp event_from_group(group, samples, station, trajectory, refinement) do
    first = List.first(group)
    last = List.last(group)
    max_elevation_deg = group |> Enum.map(& &1.elevation_deg) |> Enum.max()

    with {:ok, {starts_at, start_boundary, start_boundary_detail}} <-
           start_boundary(first, samples, station, refinement),
         {:ok, {ends_at, end_boundary, end_boundary_detail}} <-
           end_boundary(last, samples, station, refinement) do
      refinement_metadata = event_refinement_metadata(refinement)

      {:ok,
       %{
         type: :ground_station_access,
         starts_at: starts_at,
         ends_at: ends_at,
         metadata:
           AccessGeometry.assumptions()
           |> Map.merge(%{
             scenario_id: trajectory.scenario_id,
             ground_station_id: station.id,
             minimum_elevation_deg: station.minimum_elevation_deg,
             max_elevation_deg: max_elevation_deg,
             interpolation: refinement_metadata.interpolation,
             boundary_refinement: refinement_metadata.boundary_refinement,
             start_boundary: start_boundary,
             end_boundary: end_boundary,
             start_boundary_detail: start_boundary_detail,
             end_boundary_detail: end_boundary_detail,
             sample_count: length(group),
             start_sample_index: first.index,
             end_sample_index: last.index
           })
           |> Map.merge(
             root_event_metadata(refinement, start_boundary_detail, end_boundary_detail)
           )
       }}
    end
  end

  defp start_boundary(first, samples, station, refinement) do
    if first.index == 0 do
      {:ok, {first.state.epoch, :clipped_start, clipped_boundary_detail(:clipped_start, first)}}
    else
      previous = Enum.at(samples, first.index - 1)

      refined_boundary(previous, first, station, :start, refinement)
    end
  end

  defp end_boundary(last, samples, station, refinement) do
    if last.index == length(samples) - 1 do
      {:ok, {last.state.epoch, :clipped_end, clipped_boundary_detail(:clipped_end, last)}}
    else
      next_sample = Enum.at(samples, last.index + 1)

      refined_boundary(last, next_sample, station, :end, refinement)
    end
  end

  defp refined_boundary(before_sample, after_sample, station, edge, %{
         mode: :linear_sample_crossing
       }) do
    {:ok,
     {interpolate_epoch(before_sample, after_sample), :interpolated,
      boundary_detail(before_sample, after_sample, station, edge)}}
  end

  defp refined_boundary(before_sample, after_sample, station, edge, refinement) do
    opts = [
      central_body: refinement.central_body,
      boundary_refinement: :bracketed_bisection,
      root_tolerance_s: refinement.root_tolerance_s,
      root_max_iterations: refinement.root_max_iterations
    ]

    case refine_aos_los_boundary(before_sample.state, after_sample.state, station, opts) do
      {:ok, result} ->
        detail =
          result.assumptions
          |> Map.merge(%{
            edge: edge,
            boundary: result.boundary,
            interpolation: result.interpolation,
            interpolation_fraction: result.interpolation_fraction,
            before_sample_index: before_sample.index,
            after_sample_index: after_sample.index,
            before_elevation_deg: result.before_elevation_deg,
            after_elevation_deg: result.after_elevation_deg,
            minimum_elevation_deg: result.minimum_elevation_deg
          })

        {:ok, {result.epoch, :root_refined, detail}}

      {:error, reason} ->
        {:error, {:boundary_refinement_failed, edge, reason}}
    end
  end

  defp event_refinement_metadata(%{mode: :linear_sample_crossing}) do
    %{
      interpolation: :linear_sample_crossing,
      boundary_refinement: :aos_los_linear_margin_interpolation
    }
  end

  defp event_refinement_metadata(%{mode: :bracketed_bisection}) do
    %{
      interpolation: :cubic_hermite_state,
      boundary_refinement: :aos_los_bracketed_bisection
    }
  end

  defp root_event_metadata(%{mode: :linear_sample_crossing}, _start_detail, _end_detail),
    do: %{}

  defp root_event_metadata(refinement, start_detail, end_detail) do
    details = [start_detail, end_detail]
    root_details = Enum.filter(details, &Map.get(&1, :root_solved, false))
    root_count = length(root_details)
    clipped_count = Enum.count(details, &(Map.get(&1, :interpolation) == :clipped_to_sample))

    confidence =
      cond do
        root_count == 2 -> :bounded_root_in_interpolated_state
        root_count > 0 -> :mixed_root_refined_and_sample_clipped
        true -> :sampled_clipped_no_root
      end

    metadata = %{
      event_timing_policy: :sampled_state_bracketed_root_refinement,
      confidence: confidence,
      root_refinement_requested: true,
      root_refined_boundary_count: root_count,
      clipped_boundary_count: clipped_count,
      requested_root_tolerance_s: refinement.root_tolerance_s,
      root_max_iterations: refinement.root_max_iterations,
      root_scope: :cubic_hermite_interpolated_state_geometry,
      validation_level: :analysis,
      root_refinement_model_limits: [
        :not_dense_propagator_output,
        :single_bracketed_crossing_selected,
        :constant_earth_rotation_access_geometry,
        :not_externally_validated,
        :not_flight_fidelity
      ]
    }

    if root_count == 2 do
      Map.put(
        metadata,
        :event_time_tolerance_s,
        root_details
        |> Enum.map(&Map.fetch!(&1, :event_time_tolerance_s))
        |> Enum.max()
      )
    else
      metadata
    end
  end

  defp boundary_detail(before_sample, after_sample, station, edge) do
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
      minimum_elevation_deg: station.minimum_elevation_deg
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

  defp fraction_epoch_seconds(before_epoch, after_epoch, fraction) do
    before_s = epoch_seconds(before_epoch)
    before_s + fraction * (epoch_seconds(after_epoch) - before_s)
  end

  defp epoch_delta_s(before_epoch, after_epoch) do
    epoch_seconds(after_epoch) - epoch_seconds(before_epoch)
  end

  defp epoch_seconds(%{seconds_since_j2000: seconds}), do: seconds * 1.0

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
      before_margin < 0.0 and after_margin >= 0.0 -> :aos
      before_margin >= 0.0 and after_margin < 0.0 -> :los
      before_margin == 0.0 -> :sampled_boundary
      after_margin == 0.0 -> :sampled_boundary
    end
  end
end
