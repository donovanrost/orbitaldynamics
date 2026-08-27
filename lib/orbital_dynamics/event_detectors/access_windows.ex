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
    Epoch,
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
  @max_states 10_000
  @max_opts_length 64
  @max_container_depth 8
  @max_container_entries 2_048
  @max_list_length 1_024
  @max_map_size 128
  @safe_number_limit 1.0e15
  @allowed_options [
    :ground_station,
    :central_body,
    :boundary_refinement,
    :root_tolerance_s,
    :root_max_iterations
  ]
  @central_body_fields [:name, :mu_km3_s2, :equatorial_radius_km, :j2]
  @ground_station_fields [
    :id,
    :latitude_deg,
    :longitude_deg,
    :altitude_km,
    :minimum_elevation_deg
  ]
  @default_model_limits [
    :sample_cadence_limited,
    :refinement_not_root_solved,
    :no_terrain_mask,
    :no_refraction_model,
    :constant_earth_rotation_access_geometry
  ]
  @root_refinement_model_limits [
    :sample_cadence_limited,
    :root_refinement_interpolated_state_only,
    :root_refinement_not_externally_validated,
    :multiple_crossings_within_sample_not_resolved,
    :no_terrain_mask,
    :no_refraction_model,
    :constant_earth_rotation_access_geometry
  ]
  @capability_known_limits [
    :sample_cadence_limited,
    :refinement_not_root_solved,
    :root_refinement_interpolated_state_only,
    :root_refinement_not_externally_validated,
    :multiple_crossings_within_sample_not_resolved,
    :no_terrain_mask,
    :no_refraction_model,
    :constant_earth_rotation_access_geometry
  ]

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
      known_limits: @capability_known_limits
    }
  end

  @doc "Returns the model limits for one explicit access-boundary mode."
  def model_limits(:linear_sample_crossing), do: @default_model_limits
  def model_limits(:bracketed_bisection), do: @root_refinement_model_limits
  def model_limits(mode), do: {:error, {:unsupported_boundary_refinement, mode}}

  @impl OrbitalDynamics.EventDetector
  def detect(trajectory, opts \\ [])

  def detect(%Trajectory{} = trajectory, opts) do
    with :ok <- validate_opts(opts),
         {:ok, station} <- required_option(opts, :ground_station),
         central_body = Keyword.get(opts, :central_body, CentralBody.earth()),
         :ok <- validate_trajectory(trajectory),
         :ok <- validate_inputs(station, central_body),
         {:ok, refinement} <- boundary_refinement_options(opts),
         {:ok, samples} <- access_samples(trajectory.states, station, central_body),
         {:ok, events} <- events_from_groups(samples, station, trajectory, refinement),
         {:ok, annotated_events} <- annotate_events(events, trajectory) do
      {:ok, annotated_events}
    end
  end

  def detect(_trajectory, opts) do
    with :ok <- validate_opts(opts), do: {:error, {:invalid_option, :trajectory}}
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
  def refine_aos_los_boundary(before_state, after_state, station, opts \\ [])

  def refine_aos_los_boundary(
        %StateVector{} = before_state,
        %StateVector{} = after_state,
        %GroundStation{} = station,
        opts
      ) do
    with :ok <- validate_opts(opts),
         central_body = Keyword.get(opts, :central_body, CentralBody.earth()),
         :ok <- validate_state_pair(before_state, after_state),
         :ok <- validate_inputs(station, central_body),
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

  def refine_aos_los_boundary(_before_state, _after_state, _station, opts) do
    with :ok <- validate_opts(opts), do: {:error, {:invalid_option, :access_boundary}}
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

  defp validate_root_tolerance(value) when is_integer(value) or is_float(value) do
    if finite_number?(value) and value > 0.0 do
      :ok
    else
      {:error, {:invalid_option, :root_tolerance_s}}
    end
  end

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

  defp validate_inputs(%GroundStation{} = station, %CentralBody{} = central_body) do
    cond do
      not valid_ground_station?(station) ->
        {:error, {:invalid_option, :ground_station}}

      not valid_central_body?(central_body) ->
        {:error, {:invalid_central_body, :equatorial_radius_km}}

      true ->
        :ok
    end
  end

  defp validate_inputs(_station, %CentralBody{}), do: {:error, {:invalid_option, :ground_station}}

  defp validate_inputs(%GroundStation{}, _central_body),
    do: {:error, {:invalid_option, :central_body}}

  defp validate_inputs(_station, _central_body), do: {:error, {:invalid_option, :ground_station}}

  defp access_samples(states, station, central_body) do
    states
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {state, index}, {:ok, acc} ->
      elevation_deg = AccessGeometry.elevation_deg(state, station, central_body)

      if finite_number?(elevation_deg) do
        sample = %{
          index: index,
          state: state,
          visible: elevation_deg >= station.minimum_elevation_deg,
          elevation_deg: elevation_deg,
          elevation_margin_deg: elevation_deg - station.minimum_elevation_deg
        }

        {:cont, {:ok, [sample | acc]}}
      else
        {:halt, {:error, {:invalid_geometry_result, :elevation_deg}}}
      end
    end)
    |> case do
      {:ok, samples} -> {:ok, Enum.reverse(samples)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp annotate_events(events, trajectory) do
    Enum.reduce_while(events, {:ok, []}, fn event, {:ok, acc} ->
      case EventTiming.annotate_event(event, trajectory, :access_windows) do
        %{} = annotated -> {:cont, {:ok, [annotated | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, annotated} -> {:ok, Enum.reverse(annotated)}
      {:error, reason} -> {:error, reason}
    end
  end

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
      validate_root_states(before_state, after_state)
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

  defp valid_ground_station?(%GroundStation{
         id: id,
         latitude_deg: latitude_deg,
         longitude_deg: longitude_deg,
         altitude_km: altitude_km,
         minimum_elevation_deg: minimum_elevation_deg
       }) do
    id not in [nil, ""] and finite_number?(latitude_deg) and latitude_deg >= -90.0 and
      latitude_deg <= 90.0 and finite_number?(longitude_deg) and longitude_deg >= -180.0 and
      longitude_deg <= 180.0 and finite_number?(altitude_km) and
      finite_number?(minimum_elevation_deg) and minimum_elevation_deg >= -90.0 and
      minimum_elevation_deg <= 90.0
  end

  defp valid_central_body?(%CentralBody{name: name, equatorial_radius_km: radius}) do
    is_atom(name) and finite_number?(radius) and radius > 0.0
  end

  defp finite_vector?({x, y, z}),
    do: finite_number?(x) and finite_number?(y) and finite_number?(z)

  defp finite_vector?(_vector), do: false

  defp required_option(opts, key) do
    case Keyword.fetch(opts, key) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, {:missing_option, key}}
    end
  end

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

  defp preflight_option_value(:ground_station, %GroundStation{} = station),
    do:
      preflight_exact_struct(
        station,
        GroundStation,
        @ground_station_fields,
        :opts,
        {:invalid_option, :ground_station}
      )

  defp preflight_option_value(:central_body, %CentralBody{} = central_body),
    do:
      preflight_exact_struct(
        central_body,
        CentralBody,
        @central_body_fields,
        :opts,
        {:invalid_central_body, :equatorial_radius_km}
      )

  defp preflight_option_value(key, value) when key in [:root_tolerance_s, :root_max_iterations],
    do: preflight_numeric_option(key, value)

  defp preflight_option_value(_key, value), do: preflight_container(value, :opts)

  defp preflight_numeric_option(key, value) when is_integer(value) or is_float(value) do
    if finite_number?(value), do: :ok, else: {:error, {:invalid_option, key}}
  end

  defp preflight_numeric_option(_key, value), do: preflight_container(value, :opts)

  defp preflight_exact_struct(struct, module, fields, field, numeric_error) do
    expected_keys = MapSet.new([:__struct__ | fields])

    cond do
      Map.get(struct, :__struct__) != module ->
        {:error, {:invalid_container, field}}

      MapSet.new(Map.keys(struct)) != expected_keys ->
        {:error, {:invalid_container, field}}

      true ->
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
    root_details = Enum.filter(details, &Map.fetch!(&1, :root_solved))
    root_count = length(root_details)
    clipped_count = Enum.count(details, &(Map.fetch!(&1, :interpolation) == :clipped_to_sample))

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
