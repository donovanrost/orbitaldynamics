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
    Epoch,
    EventTiming,
    Frame,
    StateVector,
    Target,
    Trajectory
  }

  @behaviour OrbitalDynamics.EventDetector
  @max_states 10_000
  @max_opts_length 64
  @max_container_depth 8
  @max_container_entries 2_048
  @max_list_length 1_024
  @max_map_size 128
  @safe_number_limit 1.0e15
  @allowed_options [:target, :central_body]
  @central_body_fields [:name, :mu_km3_s2, :equatorial_radius_km, :j2]
  @target_fields [
    :id,
    :latitude_deg,
    :longitude_deg,
    :altitude_km,
    :minimum_elevation_deg,
    :priority
  ]

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
  def detect(trajectory, opts \\ [])

  def detect(%Trajectory{} = trajectory, opts) do
    with :ok <- validate_opts(opts),
         {:ok, target} <- required_option(opts, :target),
         central_body = Keyword.get(opts, :central_body, CentralBody.earth()),
         :ok <- validate_trajectory(trajectory),
         :ok <- validate_inputs(target, central_body),
         {:ok, samples} <- visibility_samples(trajectory.states, target, central_body),
         {:ok, events} <- events_from_groups(samples, target, trajectory),
         {:ok, annotated_events} <- annotate_events(events, trajectory) do
      {:ok, annotated_events}
    end
  end

  def detect(_trajectory, opts) do
    with :ok <- validate_opts(opts), do: {:error, {:invalid_option, :trajectory}}
  end

  @doc """
  Refines one bracketed target visibility boundary between two sampled states.

  The refinement is a linear interpolation over target elevation margin. It is
  not a root-solved event time and remains bounded by the input sample cadence.
  """
  def refine_visibility_boundary(before_state, after_state, target, opts \\ [])

  def refine_visibility_boundary(
        %StateVector{} = before_state,
        %StateVector{} = after_state,
        %Target{} = target,
        opts
      ) do
    with :ok <- validate_opts(opts),
         central_body = Keyword.get(opts, :central_body, CentralBody.earth()),
         :ok <- validate_state_pair(before_state, after_state),
         :ok <- validate_inputs(target, central_body) do
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

  def refine_visibility_boundary(_before_state, _after_state, _target, opts) do
    with :ok <- validate_opts(opts), do: {:error, {:invalid_option, :visibility_boundary}}
  end

  defp validate_inputs(%Target{} = target, %CentralBody{} = central_body) do
    cond do
      not valid_target?(target) ->
        {:error, {:invalid_option, :target}}

      not valid_central_body?(central_body) ->
        {:error, {:invalid_central_body, :equatorial_radius_km}}

      true ->
        :ok
    end
  end

  defp validate_inputs(_target, %CentralBody{}), do: {:error, {:invalid_option, :target}}
  defp validate_inputs(%Target{}, _central_body), do: {:error, {:invalid_option, :central_body}}
  defp validate_inputs(_target, _central_body), do: {:error, {:invalid_option, :target}}

  defp visibility_samples(states, target, central_body) do
    states
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {state, index}, {:ok, acc} ->
      elevation_deg = AccessGeometry.elevation_deg(state, target, central_body)

      if finite_number?(elevation_deg) do
        sample = %{
          index: index,
          state: state,
          visible: elevation_deg >= target.minimum_elevation_deg,
          elevation_deg: elevation_deg,
          elevation_margin_deg: elevation_deg - target.minimum_elevation_deg
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

  defp events_from_groups(samples, target, trajectory) do
    samples
    |> visible_groups()
    |> Enum.reduce_while({:ok, []}, fn group, {:ok, events} ->
      {:cont, {:ok, [event_from_group(group, samples, target, trajectory) | events]}}
    end)
    |> case do
      {:ok, events} -> {:ok, Enum.reverse(events)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp annotate_events(events, trajectory) do
    Enum.reduce_while(events, {:ok, []}, fn event, {:ok, acc} ->
      case EventTiming.annotate_event(event, trajectory, :target_visibility) do
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

  defp valid_target?(%Target{
         id: id,
         latitude_deg: latitude_deg,
         longitude_deg: longitude_deg,
         altitude_km: altitude_km,
         minimum_elevation_deg: minimum_elevation_deg,
         priority: priority
       }) do
    id not in [nil, ""] and finite_number?(latitude_deg) and latitude_deg >= -90.0 and
      latitude_deg <= 90.0 and finite_number?(longitude_deg) and longitude_deg >= -180.0 and
      longitude_deg <= 180.0 and finite_number?(altitude_km) and
      finite_number?(minimum_elevation_deg) and minimum_elevation_deg >= -90.0 and
      minimum_elevation_deg <= 90.0 and finite_number?(priority) and priority >= 0.0
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

  defp preflight_option_value(:target, %Target{} = target),
    do:
      preflight_exact_struct(
        target,
        Target,
        @target_fields,
        :opts,
        {:invalid_option, :target}
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

  defp preflight_option_value(_key, value), do: preflight_container(value, :opts)

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
