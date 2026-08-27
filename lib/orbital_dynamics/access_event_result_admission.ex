defmodule OrbitalDynamics.AccessEventResultAdmission do
  @moduledoc false

  alias OrbitalDynamics.Epoch

  @event_timing_keys [
    :interpolation,
    :boundary_refinement,
    :start_boundary,
    :end_boundary,
    :start_boundary_detail,
    :end_boundary_detail,
    :event_timing_policy,
    :event_detector,
    :event_time_tolerance_s,
    :max_sample_step_s,
    :confidence
  ]

  @precondition_keys [
    :spacecraft_available,
    :payload_available,
    :antenna_available,
    :degraded,
    :resource_blocking_dimension,
    :incompatible_activity_types,
    :suppressed_activity_types,
    :command_authorized,
    :command_authority_status,
    :authority_status,
    :required_authority,
    :required_escalation_authority,
    :command_safety_status,
    :safety_status,
    :command_safety_checked,
    :safety_checked,
    :activity_template,
    :activity_context
  ]

  @resource_projection_keys [
    :estimated_storage_mb,
    :planned_data_volume_mb,
    :data_volume_mb,
    :estimated_data_volume_mb,
    :estimated_energy_used_wh,
    :battery_energy_consumed_wh,
    :battery_energy_generated_wh
  ]

  @result_keys [:scenario_id, :event_type, :events, :source, :node]
  @event_keys [:type, :starts_at, :ends_at, :metadata]
  @target_source_keys [:target_id]
  @access_source_keys [:ground_station_id]
  @eclipse_source_keys [:shadow_model, :campaign_environment]
  @epoch_scales [:tdb, :tai, :utc]
  @geometry_metadata_keys [
    :geometry_model,
    :earth_rotation_rate_rad_s,
    :refraction,
    :terrain_mask
  ]
  @sample_metadata_keys [:scenario_id, :start_sample_index, :end_sample_index]
  @access_root_metadata_keys [
    :root_refinement_requested,
    :root_refined_boundary_count,
    :clipped_boundary_count,
    :requested_root_tolerance_s,
    :root_max_iterations,
    :root_scope,
    :validation_level,
    :root_refinement_model_limits
  ]
  @eclipse_provider_metadata_keys [
    :sun_direction_at_start_sample,
    :sun_direction_at_end_sample,
    :sun_direction_time_varying,
    :sun_direction_provider_id,
    :sun_direction_provider_revision,
    :sun_direction_dataset_revision,
    :sun_direction_dataset_semantic_sha256,
    :sun_direction_content_sha256,
    :sun_direction_provider_coverage,
    :sun_direction_interpolation,
    :campaign_environment,
    :known_limits
  ]

  @target_metadata_keys [
                          :target_id,
                          :target_priority,
                          :max_elevation_deg,
                          :minimum_elevation_deg,
                          :sample_count,
                          :max_sample_step_s,
                          :source_window_id,
                          :timeline_id
                        ] ++
                          @geometry_metadata_keys ++
                          @sample_metadata_keys ++
                          @event_timing_keys ++ @precondition_keys ++ @resource_projection_keys

  @access_metadata_keys [
                          :ground_station_id,
                          :max_elevation_deg,
                          :minimum_elevation_deg,
                          :sample_count,
                          :max_sample_step_s,
                          :source_window_id,
                          :timeline_id
                        ] ++
                          @geometry_metadata_keys ++
                          @sample_metadata_keys ++
                          @event_timing_keys ++
                          @access_root_metadata_keys ++
                          @precondition_keys ++ @resource_projection_keys

  @eclipse_metadata_keys [
                           :sample_count,
                           :max_sample_step_s,
                           :sun_direction,
                           :minimum_shadow_axis_distance_km,
                           :maximum_shadow_margin_km,
                           :shadow_model,
                           :central_body,
                           :central_body_radius_km,
                           :source_window_id,
                           :timeline_id
                         ] ++
                           @sample_metadata_keys ++
                           @eclipse_provider_metadata_keys ++ @event_timing_keys

  @metadata_id_keys [
    :scenario_id,
    :target_id,
    :ground_station_id,
    :source_window_id,
    :timeline_id,
    :sun_direction_provider_id,
    :sun_direction_provider_revision,
    :sun_direction_dataset_revision,
    :sun_direction_dataset_semantic_sha256,
    :sun_direction_content_sha256
  ]
  @metadata_numeric_keys [
    :target_priority,
    :max_elevation_deg,
    :minimum_elevation_deg,
    :sample_count,
    :max_sample_step_s,
    :earth_rotation_rate_rad_s,
    :start_sample_index,
    :end_sample_index,
    :event_time_tolerance_s,
    :minimum_shadow_axis_distance_km,
    :maximum_shadow_margin_km,
    :central_body_radius_km,
    :root_refined_boundary_count,
    :clipped_boundary_count,
    :requested_root_tolerance_s,
    :root_max_iterations,
    :estimated_storage_mb,
    :planned_data_volume_mb,
    :data_volume_mb,
    :estimated_data_volume_mb,
    :estimated_energy_used_wh,
    :battery_energy_consumed_wh,
    :battery_energy_generated_wh
  ]
  @metadata_boolean_keys [
    :spacecraft_available,
    :payload_available,
    :antenna_available,
    :degraded,
    :command_authorized,
    :command_safety_checked,
    :safety_checked,
    :root_refinement_requested,
    :sun_direction_time_varying
  ]
  @metadata_token_keys [
    :geometry_model,
    :refraction,
    :terrain_mask,
    :interpolation,
    :boundary_refinement,
    :start_boundary,
    :end_boundary,
    :event_timing_policy,
    :event_detector,
    :confidence,
    :resource_blocking_dimension,
    :command_authority_status,
    :authority_status,
    :required_authority,
    :required_escalation_authority,
    :command_safety_status,
    :safety_status,
    :activity_template,
    :shadow_model,
    :central_body,
    :root_scope,
    :validation_level,
    :sun_direction_interpolation
  ]
  @metadata_token_list_keys [
    :incompatible_activity_types,
    :suppressed_activity_types,
    :root_refinement_model_limits,
    :known_limits
  ]
  @metadata_json_map_keys [
    :activity_context,
    :campaign_environment,
    :sun_direction_provider_coverage
  ]
  @metadata_vector_keys [
    :sun_direction,
    :sun_direction_at_start_sample,
    :sun_direction_at_end_sample
  ]
  @metadata_boundary_detail_keys [:start_boundary_detail, :end_boundary_detail]
  @boundary_detail_keys [
    :boundary,
    :interpolation,
    :interpolation_fraction,
    :sample_index,
    :root_solved,
    :confidence,
    :edge,
    :event_timing_policy,
    :event_time_tolerance_s,
    :event_time_bracket_s,
    :before_epoch_s,
    :after_epoch_s,
    :before_sample_index,
    :after_sample_index,
    :elevation_deg,
    :before_elevation_deg,
    :after_elevation_deg,
    :minimum_elevation_deg,
    :before_eclipsed,
    :after_eclipsed,
    :eclipsed,
    :eclipse_margin_km,
    :before_eclipse_margin_km,
    :after_eclipse_margin_km,
    :shadow_axis_distance_km,
    :before_shadow_axis_distance_km,
    :after_shadow_axis_distance_km,
    :central_body_radius_km,
    :sun_direction,
    :before_sun_direction,
    :after_sun_direction,
    :sun_direction_time_varying,
    :refinement_model,
    :root_solver,
    :root_function,
    :root_scope,
    :validation_level,
    :convergence,
    :requested_root_tolerance_s,
    :input_event_time_bracket_s,
    :root_bracket_before_epoch_s,
    :root_bracket_after_epoch_s,
    :root_bracket_before_margin_deg,
    :root_bracket_after_margin_deg,
    :root_estimate_margin_deg,
    :root_iterations,
    :root_function_evaluations,
    :root_max_iterations,
    :model_limits
  ]
  @boundary_numeric_keys [
    :interpolation_fraction,
    :sample_index,
    :event_time_tolerance_s,
    :event_time_bracket_s,
    :before_epoch_s,
    :after_epoch_s,
    :before_sample_index,
    :after_sample_index,
    :elevation_deg,
    :before_elevation_deg,
    :after_elevation_deg,
    :minimum_elevation_deg,
    :eclipse_margin_km,
    :before_eclipse_margin_km,
    :after_eclipse_margin_km,
    :shadow_axis_distance_km,
    :before_shadow_axis_distance_km,
    :after_shadow_axis_distance_km,
    :central_body_radius_km,
    :requested_root_tolerance_s,
    :input_event_time_bracket_s,
    :root_bracket_before_epoch_s,
    :root_bracket_after_epoch_s,
    :root_bracket_before_margin_deg,
    :root_bracket_after_margin_deg,
    :root_estimate_margin_deg,
    :root_iterations,
    :root_function_evaluations,
    :root_max_iterations
  ]
  @boundary_boolean_keys [
    :root_solved,
    :before_eclipsed,
    :after_eclipsed,
    :eclipsed,
    :sun_direction_time_varying
  ]
  @boundary_token_keys [
    :boundary,
    :interpolation,
    :confidence,
    :edge,
    :event_timing_policy,
    :refinement_model,
    :root_solver,
    :root_function,
    :root_scope,
    :validation_level,
    :convergence
  ]
  @boundary_vector_keys [:sun_direction, :before_sun_direction, :after_sun_direction]
  @boundary_token_list_keys [:model_limits]

  @max_event_results 10_000
  @max_events 10_000
  @max_list_length 10_000
  @max_map_entries 128
  @max_container_depth 8
  @max_nodes 500_000
  @max_key_bytes 128
  @max_scalar_bytes 1_024
  @max_total_bytes 8_000_000
  @safe_number_limit 1.0e15
  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/

  def admit_event_results(event_results) do
    with {:ok, event_results} <-
           bounded_list_items(event_results, :event_results, @max_event_results) do
      {accepted, invalid_lighting} =
        Enum.reduce(event_results, {[], empty_invalid_observation_lighting()}, fn result,
                                                                                  {accepted,
                                                                                   invalid_lighting} ->
          case admit_event_result(result) do
            {:ok, result} ->
              {[result | accepted], invalid_lighting}

            {:drop, :observation_lighting, scenario_key} ->
              {accepted, mark_invalid_observation_lighting(invalid_lighting, scenario_key)}

            {:drop, :all_observation_lighting} ->
              {accepted, mark_all_observation_lighting(invalid_lighting)}

            :drop ->
              {accepted, invalid_lighting}
          end
        end)

      {:ok, Enum.reverse(accepted), invalid_lighting}
    else
      {:error, reason} -> {:error, {:invalid_observation_lighting, reason}}
    end
  end

  def admit_observation_input(result, event) do
    with {:ok, result} <- normalize_result_header(result),
         {:ok, _scenario_key} <- result_scenario_key(result),
         :ok <- require_event_type(result, :target_visibility),
         {:ok, source} <- normalize_source(result, :target_visibility),
         {:ok, event} <- normalize_event(event, :target_visibility) do
      {:ok, Map.put(result, :source, source), event}
    end
  end

  def empty_invalid_observation_lighting do
    %{all?: false, scenarios: MapSet.new()}
  end

  def all_invalid_observation_lighting do
    mark_all_observation_lighting(empty_invalid_observation_lighting())
  end

  def merge_invalid_observation_lighting(left, right) do
    %{
      all?: Map.get(left, :all?, false) or Map.get(right, :all?, false),
      scenarios:
        MapSet.union(
          Map.get(left, :scenarios, MapSet.new()),
          Map.get(right, :scenarios, MapSet.new())
        )
    }
  end

  def invalid_observation_lighting_scenario?(%{all?: true}, _scenario_id), do: true

  def invalid_observation_lighting_scenario?(%{scenarios: scenarios}, scenario_id) do
    case scenario_key(scenario_id) do
      {:ok, scenario_key} -> MapSet.member?(scenarios, scenario_key)
      {:error, _reason} -> true
    end
  end

  def invalid_observation_lighting_scenario?(_invalid_lighting, _scenario_id), do: false

  defp admit_event_result(%{} = result) do
    with {:ok, result} <- normalize_result_header(result),
         {:ok, event_type} <- fetch_required(result, :event_type, :event_type),
         {:ok, scenario_key} <- result_scenario_key(result) do
      case event_type do
        :target_visibility ->
          admit_known_result(result, :target_visibility, scenario_key, true)

        :eclipse ->
          admit_known_result(result, :eclipse, scenario_key, true)

        :ground_station_access ->
          admit_known_result(result, :ground_station_access, scenario_key, false)

        event_type when is_atom(event_type) ->
          admit_unrelated_result(result)

        _event_type ->
          {:drop, :all_observation_lighting}
      end
    else
      {:error, _reason} -> {:drop, :all_observation_lighting}
    end
  end

  defp admit_event_result(_result), do: {:drop, :all_observation_lighting}

  defp admit_known_result(result, event_type, scenario_key, invalidates_observations?) do
    with {:ok, source} <- normalize_source(result, event_type),
         {:ok, events} <- fetch_required(result, :events, :events),
         {:ok, events} <- bounded_list_items(events, :events, @max_events),
         {:ok, events} <- normalize_events(events, event_type) do
      {:ok, result |> Map.put(:source, source) |> Map.put(:events, events)}
    else
      {:error, _reason} ->
        if invalidates_observations? do
          {:drop, :observation_lighting, scenario_key}
        else
          :drop
        end
    end
  end

  defp admit_unrelated_result(result) do
    with {:ok, result} <- normalize_optional_source(result),
         {:ok, result} <- normalize_optional_events(result) do
      {:ok, result}
    else
      {:error, _reason} -> :drop
    end
  end

  defp normalize_result_header(result) do
    with {:ok, result} <- normalize_supported_map(result, :event_result, @result_keys, :shallow),
         :ok <- preflight_optional_value(result, :node, :event_result) do
      {:ok, result}
    end
  end

  defp result_scenario_key(result) do
    with {:ok, scenario_id} <- fetch_required(result, :scenario_id, :scenario_id) do
      scenario_key(scenario_id)
    end
  end

  defp require_event_type(result, expected_type) do
    case fetch_required(result, :event_type, :event_type) do
      {:ok, ^expected_type} -> :ok
      {:ok, _event_type} -> {:error, {:invalid_option, :event_type}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp normalize_source(result, :target_visibility) do
    with {:ok, source} <- fetch_required(result, :source, :source),
         {:ok, source} <-
           normalize_supported_map(
             source,
             :source,
             @target_source_keys,
             {:source, :target_visibility}
           ),
         :ok <- validate_id_field(source, :target_id, :source) do
      {:ok, source}
    end
  end

  defp normalize_source(result, :ground_station_access) do
    with {:ok, source} <- fetch_required(result, :source, :source),
         {:ok, source} <-
           normalize_supported_map(
             source,
             :source,
             @access_source_keys,
             {:source, :ground_station_access}
           ),
         :ok <- validate_id_field(source, :ground_station_id, :source) do
      {:ok, source}
    end
  end

  defp normalize_source(result, :eclipse) do
    case Map.fetch(result, :source) do
      {:ok, source} ->
        normalize_supported_map(source, :source, @eclipse_source_keys, {:source, :eclipse})

      :error ->
        {:ok, %{}}
    end
  end

  defp normalize_optional_source(result) do
    case Map.fetch(result, :source) do
      {:ok, source} ->
        with :ok <- preflight_value(source, :source) do
          {:ok, result}
        end

      :error ->
        {:ok, result}
    end
  end

  defp normalize_optional_events(result) do
    case Map.fetch(result, :events) do
      {:ok, events} ->
        with {:ok, events} <- bounded_list_items(events, :events, @max_events),
             :ok <- preflight_value(events, :events) do
          {:ok, Map.put(result, :events, events)}
        end

      :error ->
        {:ok, result}
    end
  end

  defp normalize_events(events, event_type) do
    Enum.reduce_while(events, {:ok, []}, fn event, {:ok, accepted} ->
      case normalize_event(event, event_type) do
        {:ok, event} -> {:cont, {:ok, [event | accepted]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, accepted} -> {:ok, Enum.reverse(accepted)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp normalize_event(event, event_type) do
    with {:ok, event} <- normalize_supported_map(event, :event, @event_keys, :shallow),
         {:ok, type} <- fetch_required(event, :type, :event_type),
         :ok <- validate_event_type(type, event_type),
         {:ok, starts_at} <- fetch_required(event, :starts_at, :starts_at_s),
         {:ok, starts_at, starts_at_s} <- normalize_epoch(starts_at, :starts_at_s),
         {:ok, ends_at} <- fetch_required(event, :ends_at, :ends_at_s),
         {:ok, ends_at, ends_at_s} <- normalize_epoch(ends_at, :ends_at_s),
         {:ok, metadata} <- fetch_required(event, :metadata, :metadata),
         {:ok, metadata} <- normalize_metadata(metadata, event_type),
         :ok <- validate_event_interval(starts_at_s, ends_at_s) do
      {:ok,
       event
       |> Map.put(:starts_at, starts_at)
       |> Map.put(:ends_at, ends_at)
       |> Map.put(:metadata, metadata)}
    end
  end

  defp validate_event_type(type, expected_type) when type == expected_type, do: :ok
  defp validate_event_type(_type, _expected_type), do: {:error, {:invalid_option, :event_type}}

  defp normalize_epoch(epoch, field) do
    with :ok <- validate_epoch_struct(epoch, field),
         {:ok, scale} <- fetch_required(epoch, :scale, field),
         :ok <- validate_epoch_scale(scale, field),
         {:ok, seconds} <- fetch_required(epoch, :seconds_since_j2000, field),
         :ok <- validate_number(field, seconds) do
      {:ok, epoch, seconds}
    end
  end

  defp validate_epoch_struct(%Epoch{} = epoch, field) do
    if map_size(epoch) == 3 and Map.has_key?(epoch, :scale) and
         Map.has_key?(epoch, :seconds_since_j2000) do
      :ok
    else
      {:error, {:invalid_option, field}}
    end
  end

  defp validate_epoch_struct(%{__struct__: _struct}, field),
    do: {:error, {:invalid_option, field}}

  defp validate_epoch_struct(_epoch, field),
    do: {:error, {:invalid_container, field}}

  defp validate_epoch_scale(scale, _field) when scale in @epoch_scales, do: :ok
  defp validate_epoch_scale(_scale, field), do: {:error, {:invalid_option, field}}

  defp normalize_metadata(metadata, :target_visibility) do
    with {:ok, metadata} <-
           normalize_supported_map(
             metadata,
             :metadata,
             @target_metadata_keys,
             {:metadata, :target_visibility}
           ),
         :ok <-
           require_keys(
             metadata,
             [:target_id, :target_priority, :max_elevation_deg, :minimum_elevation_deg],
             :metadata
           ),
         :ok <- validate_id_field(metadata, :target_id, :metadata) do
      {:ok, metadata}
    end
  end

  defp normalize_metadata(metadata, :ground_station_access) do
    with {:ok, metadata} <-
           normalize_supported_map(
             metadata,
             :metadata,
             @access_metadata_keys,
             {:metadata, :ground_station_access}
           ),
         :ok <- require_keys(metadata, [:max_elevation_deg, :minimum_elevation_deg], :metadata) do
      {:ok, metadata}
    end
  end

  defp normalize_metadata(metadata, :eclipse) do
    normalize_supported_map(metadata, :metadata, @eclipse_metadata_keys, {:metadata, :eclipse})
  end

  defp validate_event_interval(starts_at_s, ends_at_s) do
    duration_s = ends_at_s - starts_at_s

    cond do
      not finite_number?(duration_s) -> {:error, {:invalid_option, :duration_s}}
      duration_s < 0.0 -> {:error, {:invalid_timing, :negative_duration_s}}
      true -> :ok
    end
  end

  defp require_keys(map, keys, field) do
    if Enum.all?(keys, &Map.has_key?(map, &1)) do
      :ok
    else
      {:error, {:invalid_option, field}}
    end
  end

  defp validate_id_field(map, key, field) do
    with {:ok, value} <- fetch_required(map, key, field),
         {:ok, _id} <- scenario_key(value) do
      :ok
    end
  end

  defp scenario_key(value) when is_atom(value) and not is_nil(value) do
    value
    |> Atom.to_string()
    |> validate_id_string()
  end

  defp scenario_key(value) when is_binary(value), do: validate_id_string(value)

  defp scenario_key(value) when is_integer(value) do
    if finite_number?(value) do
      value
      |> Integer.to_string()
      |> validate_id_string()
    else
      {:error, {:invalid_option, :scenario_id}}
    end
  end

  defp scenario_key(_value), do: {:error, {:invalid_option, :scenario_id}}

  defp validate_id_string(value) do
    cond do
      byte_size(value) > @max_scalar_bytes ->
        {:error, {:container_limit_exceeded, :scenario_id}}

      Regex.match?(@stable_id_pattern, value) ->
        {:ok, value}

      true ->
        {:error, {:invalid_option, :scenario_id}}
    end
  end

  defp normalize_supported_map(%{__struct__: _struct}, field, _allowed_keys, _mode),
    do: {:error, {:invalid_container, field}}

  defp normalize_supported_map(map, field, allowed_keys, mode) when is_map(map) do
    with :ok <- validate_map_size(map, field),
         {:ok, context} <- add_node(new_context(), field) do
      initial = {:ok, %{}, MapSet.new(), context}

      map
      |> Enum.reduce_while(initial, fn {key, value}, {:ok, normalized, seen, context} ->
        with {:ok, normalized_key, collision_key, context} <-
               normalize_supported_key(key, allowed_keys, field, context),
             :ok <- reject_seen_key(seen, normalized_key, collision_key),
             {:ok, context} <-
               maybe_preflight_value(value, normalized_key, field, mode, context) do
          {:cont,
           {:ok, Map.put(normalized, normalized_key, value), MapSet.put(seen, normalized_key),
            context}}
        else
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
      |> case do
        {:ok, normalized, _seen, _context} -> {:ok, normalized}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp normalize_supported_map(_value, field, _allowed_keys, _mode),
    do: {:error, {:invalid_container, field}}

  defp normalize_supported_key(key, allowed_keys, field, context) when is_atom(key) do
    key_string = Atom.to_string(key)

    with :ok <- validate_key_bytes(key_string, field),
         {:ok, context} <- add_bytes(context, field, byte_size(key_string)) do
      if key in allowed_keys do
        {:ok, key, key_string, context}
      else
        {:error, {:unsupported_key, field}}
      end
    end
  end

  defp normalize_supported_key(key, allowed_keys, field, context) when is_binary(key) do
    with :ok <- validate_key_bytes(key, field),
         {:ok, context} <- add_bytes(context, field, byte_size(key)) do
      case Enum.find(allowed_keys, &(Atom.to_string(&1) == key)) do
        nil -> {:error, {:unsupported_key, field}}
        normalized_key -> {:ok, normalized_key, key, context}
      end
    end
  end

  defp normalize_supported_key(_key, _allowed_keys, field, _context),
    do: {:error, {:unsupported_key_type, field}}

  defp reject_seen_key(seen, normalized_key, collision_key) do
    if MapSet.member?(seen, normalized_key) do
      {:error, {:atom_string_alias_collision, collision_key}}
    else
      :ok
    end
  end

  defp maybe_preflight_value(_value, _key, _field, :shallow, context), do: {:ok, context}

  defp maybe_preflight_value(value, key, _field, {:source, event_type}, context),
    do: preflight_source_value(value, key, event_type, context)

  defp maybe_preflight_value(value, key, _field, {:metadata, event_type}, context),
    do: preflight_metadata_value(value, key, event_type, context)

  defp maybe_preflight_value(value, _key, field, :deep, context),
    do: preflight_value(value, field, context, 1)

  defp preflight_source_value(value, :target_id, :target_visibility, context),
    do: preflight_id_value(value, :source, context)

  defp preflight_source_value(value, :ground_station_id, :ground_station_access, context),
    do: preflight_id_value(value, :source, context)

  defp preflight_source_value(value, :shadow_model, :eclipse, context),
    do: preflight_token_value(value, :source, context)

  defp preflight_source_value(value, :campaign_environment, :eclipse, context),
    do: preflight_json_value(value, :source, context, 1)

  defp preflight_source_value(_value, _key, _event_type, _context),
    do: {:error, {:unsupported_key, :source}}

  defp preflight_metadata_value(value, key, _event_type, context)
       when key in @metadata_id_keys,
       do: preflight_id_value(value, :metadata, context)

  defp preflight_metadata_value(value, key, _event_type, context)
       when key in @metadata_numeric_keys,
       do: preflight_number_value(value, :metadata, context)

  defp preflight_metadata_value(value, key, _event_type, context)
       when key in @metadata_boolean_keys,
       do: preflight_boolean_value(value, :metadata, context)

  defp preflight_metadata_value(value, key, _event_type, context)
       when key in @metadata_token_keys,
       do: preflight_token_value(value, :metadata, context)

  defp preflight_metadata_value(value, key, _event_type, context)
       when key in @metadata_token_list_keys,
       do: preflight_token_list_value(value, :metadata, context, 1)

  defp preflight_metadata_value(value, key, _event_type, context)
       when key in @metadata_json_map_keys,
       do: preflight_json_value(value, :metadata, context, 1)

  defp preflight_metadata_value(value, key, _event_type, context)
       when key in @metadata_vector_keys,
       do: preflight_vector_value(value, :metadata, context)

  defp preflight_metadata_value(value, key, event_type, context)
       when key in @metadata_boundary_detail_keys,
       do: preflight_boundary_detail(value, event_type, context)

  defp preflight_metadata_value(_value, _key, _event_type, _context),
    do: {:error, {:unsupported_key, :metadata}}

  defp preflight_boundary_detail(value, event_type, context) do
    preflight_supported_value_map(
      value,
      :metadata,
      @boundary_detail_keys,
      {:boundary_detail, event_type},
      context,
      1
    )
  end

  defp preflight_boundary_detail_value(value, key, _event_type, context, _depth)
       when key in @boundary_numeric_keys,
       do: preflight_number_value(value, :metadata, context)

  defp preflight_boundary_detail_value(value, key, _event_type, context, _depth)
       when key in @boundary_boolean_keys,
       do: preflight_boolean_value(value, :metadata, context)

  defp preflight_boundary_detail_value(value, key, _event_type, context, _depth)
       when key in @boundary_token_keys,
       do: preflight_token_value(value, :metadata, context)

  defp preflight_boundary_detail_value(value, key, _event_type, context, _depth)
       when key in @boundary_vector_keys,
       do: preflight_vector_value(value, :metadata, context)

  defp preflight_boundary_detail_value(value, key, _event_type, context, depth)
       when key in @boundary_token_list_keys,
       do: preflight_token_list_value(value, :metadata, context, depth)

  defp preflight_boundary_detail_value(_value, _key, _event_type, _context, _depth),
    do: {:error, {:unsupported_key, :metadata}}

  defp preflight_supported_value_map(
         %{__struct__: _struct},
         field,
         _allowed_keys,
         _schema,
         _context,
         _depth
       ),
       do: {:error, {:invalid_container, field}}

  defp preflight_supported_value_map(map, field, allowed_keys, schema, context, depth)
       when is_map(map) do
    with :ok <- validate_depth(depth, field),
         :ok <- validate_map_size(map, field),
         {:ok, context} <- add_node(context, field) do
      initial = {:ok, MapSet.new(), context}

      map
      |> Enum.reduce_while(initial, fn {key, value}, {:ok, seen, context} ->
        with {:ok, normalized_key, collision_key, context} <-
               normalize_supported_key(key, allowed_keys, field, context),
             :ok <- reject_seen_key(seen, normalized_key, collision_key),
             {:ok, context} <-
               preflight_schema_value(value, normalized_key, schema, context, depth + 1) do
          {:cont, {:ok, MapSet.put(seen, normalized_key), context}}
        else
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
      |> case do
        {:ok, _seen, context} -> {:ok, context}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp preflight_supported_value_map(_value, field, _allowed_keys, _schema, _context, _depth),
    do: {:error, {:invalid_container, field}}

  defp preflight_schema_value(value, key, {:boundary_detail, event_type}, context, depth) do
    preflight_boundary_detail_value(value, key, event_type, context, depth)
  end

  defp preflight_id_value(value, field, context) when is_atom(value) and not is_nil(value) do
    value_string = Atom.to_string(value)

    with {:ok, context} <- add_node(context, field),
         :ok <- validate_scalar_bytes(value_string, field),
         {:ok, context} <- add_bytes(context, field, byte_size(value_string)),
         :ok <- validate_id_value(value, field) do
      {:ok, context}
    end
  end

  defp preflight_id_value(value, field, context) when is_binary(value) do
    with {:ok, context} <- add_node(context, field),
         :ok <- validate_scalar_bytes(value, field),
         {:ok, context} <- add_bytes(context, field, byte_size(value)),
         :ok <- validate_id_value(value, field) do
      {:ok, context}
    end
  end

  defp preflight_id_value(value, field, context) when is_integer(value) do
    with {:ok, context} <- add_node(context, field),
         :ok <- validate_number(field, value),
         :ok <- validate_id_value(value, field) do
      {:ok, context}
    end
  end

  defp preflight_id_value(_value, field, _context), do: {:error, {:invalid_option, field}}

  defp validate_id_value(value, field) do
    case scenario_key(value) do
      {:ok, _id} ->
        :ok

      {:error, {:container_limit_exceeded, :scenario_id}} ->
        {:error, {:container_limit_exceeded, field}}

      {:error, _reason} ->
        {:error, {:invalid_option, field}}
    end
  end

  defp preflight_number_value(value, field, context) when is_integer(value) or is_float(value) do
    with {:ok, context} <- add_node(context, field),
         :ok <- validate_number(field, value) do
      {:ok, context}
    end
  end

  defp preflight_number_value(_value, field, _context), do: {:error, {:invalid_option, field}}

  defp preflight_boolean_value(value, field, context) when is_boolean(value) do
    add_node(context, field)
  end

  defp preflight_boolean_value(_value, field, _context), do: {:error, {:invalid_option, field}}

  defp preflight_token_value(value, field, context) when is_atom(value) and not is_nil(value) do
    value_string = Atom.to_string(value)

    with {:ok, context} <- add_node(context, field),
         :ok <- validate_scalar_bytes(value_string, field),
         {:ok, context} <- add_bytes(context, field, byte_size(value_string)) do
      {:ok, context}
    end
  end

  defp preflight_token_value(value, field, context) when is_binary(value) do
    with {:ok, context} <- add_node(context, field),
         :ok <- validate_scalar_bytes(value, field),
         {:ok, context} <- add_bytes(context, field, byte_size(value)) do
      {:ok, context}
    end
  end

  defp preflight_token_value(_value, field, _context), do: {:error, {:invalid_option, field}}

  defp preflight_token_list_value(values, field, context, depth) when is_list(values) do
    with :ok <- validate_depth(depth, field),
         {:ok, context} <- add_node(context, field) do
      preflight_token_list_items(values, field, context, 0)
    end
  end

  defp preflight_token_list_value(_values, field, _context, _depth),
    do: {:error, {:invalid_container, field}}

  defp preflight_token_list_items(_values, field, _context, count) when count > @max_list_length,
    do: {:error, {:container_limit_exceeded, field}}

  defp preflight_token_list_items([], _field, context, _count), do: {:ok, context}

  defp preflight_token_list_items([head | tail], field, context, count) do
    with {:ok, context} <- preflight_token_value(head, field, context) do
      preflight_token_list_items(tail, field, context, count + 1)
    end
  end

  defp preflight_token_list_items(_improper_tail, field, _context, _count),
    do: {:error, {:invalid_container, field}}

  defp preflight_json_value(%{} = value, field, context, depth) do
    preflight_value(value, field, context, depth)
  end

  defp preflight_json_value(_value, field, _context, _depth),
    do: {:error, {:invalid_container, field}}

  defp preflight_vector_value({x, y, z}, field, context) do
    preflight_vector_components([x, y, z], field, context)
  end

  defp preflight_vector_value([x, y, z], field, context) do
    preflight_vector_components([x, y, z], field, context)
  end

  defp preflight_vector_value(value, field, _context) when is_tuple(value) or is_list(value),
    do: {:error, {:invalid_container, field}}

  defp preflight_vector_value(_value, field, _context), do: {:error, {:invalid_option, field}}

  defp preflight_vector_components(components, field, context) do
    with {:ok, context} <- add_node(context, field) do
      Enum.reduce_while(components, {:ok, context}, fn component, {:ok, context} ->
        case preflight_number_value(component, field, context) do
          {:ok, context} -> {:cont, {:ok, context}}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
    end
  end

  defp preflight_optional_value(map, key, field) do
    case Map.fetch(map, key) do
      {:ok, value} -> preflight_nested_value(value, field)
      :error -> :ok
    end
  end

  defp preflight_value(value, field) do
    case preflight_value(value, field, new_context(), 0) do
      {:ok, _context} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp preflight_nested_value(value, field) do
    case preflight_value(value, field, new_context(), 1) do
      {:ok, _context} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp preflight_value(%{__struct__: _struct}, field, _context, _depth),
    do: {:error, {:invalid_container, field}}

  defp preflight_value(%{} = map, field, context, depth) do
    with :ok <- validate_depth(depth, field),
         :ok <- validate_map_size(map, field),
         {:ok, context} <- add_node(context, field) do
      initial = {:ok, MapSet.new(), context}

      map
      |> Enum.reduce_while(initial, fn {key, value}, {:ok, seen, context} ->
        with {:ok, collision_key, context} <- normalize_generic_key(key, field, context),
             :ok <- reject_seen_generic_key(seen, collision_key),
             {:ok, context} <- preflight_value(value, field, context, depth + 1) do
          {:cont, {:ok, MapSet.put(seen, collision_key), context}}
        else
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
      |> case do
        {:ok, _seen, context} -> {:ok, context}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp preflight_value(values, field, context, depth) when is_list(values) do
    with :ok <- validate_depth(depth, field),
         {:ok, context} <- add_node(context, field) do
      preflight_list(values, field, context, depth, 0)
    end
  end

  defp preflight_value(value, field, _context, _depth) when is_tuple(value),
    do: {:error, {:invalid_container, field}}

  defp preflight_value(value, field, context, _depth) when is_integer(value) or is_float(value) do
    with {:ok, context} <- add_node(context, field),
         :ok <- validate_number(field, value) do
      {:ok, context}
    end
  end

  defp preflight_value(value, field, context, _depth) when is_binary(value) do
    with {:ok, context} <- add_node(context, field),
         :ok <- validate_scalar_bytes(value, field),
         {:ok, context} <- add_bytes(context, field, byte_size(value)) do
      {:ok, context}
    end
  end

  defp preflight_value(value, field, context, _depth) when is_atom(value) do
    value = Atom.to_string(value)

    with {:ok, context} <- add_node(context, field),
         :ok <- validate_scalar_bytes(value, field),
         {:ok, context} <- add_bytes(context, field, byte_size(value)) do
      {:ok, context}
    end
  end

  defp preflight_value(_value, field, _context, _depth),
    do: {:error, {:unsupported_value, field}}

  defp preflight_list(_values, field, _context, _depth, count) when count > @max_list_length,
    do: {:error, {:container_limit_exceeded, field}}

  defp preflight_list([], _field, context, _depth, _count), do: {:ok, context}

  defp preflight_list([head | tail], field, context, depth, count) do
    with {:ok, context} <- preflight_value(head, field, context, depth + 1) do
      preflight_list(tail, field, context, depth, count + 1)
    end
  end

  defp preflight_list(_improper_tail, field, _context, _depth, _count),
    do: {:error, {:invalid_container, field}}

  defp normalize_generic_key(key, field, context) when is_atom(key) do
    key_string = Atom.to_string(key)

    with :ok <- validate_key_bytes(key_string, field),
         {:ok, context} <- add_bytes(context, field, byte_size(key_string)) do
      {:ok, key_string, context}
    end
  end

  defp normalize_generic_key(key, field, context) when is_binary(key) do
    with :ok <- validate_key_bytes(key, field),
         {:ok, context} <- add_bytes(context, field, byte_size(key)) do
      {:ok, key, context}
    end
  end

  defp normalize_generic_key(_key, field, _context),
    do: {:error, {:unsupported_key_type, field}}

  defp reject_seen_generic_key(seen, collision_key) do
    if MapSet.member?(seen, collision_key) do
      {:error, {:atom_string_alias_collision, collision_key}}
    else
      :ok
    end
  end

  defp fetch_required(map, key, field) do
    case Map.fetch(map, key) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, {:invalid_option, field}}
    end
  end

  defp validate_map_size(map, field) do
    if map_size(map) <= @max_map_entries do
      :ok
    else
      {:error, {:container_limit_exceeded, field}}
    end
  end

  defp validate_depth(depth, field) do
    if depth <= @max_container_depth do
      :ok
    else
      {:error, {:container_limit_exceeded, field}}
    end
  end

  defp validate_key_bytes(key, field) do
    if byte_size(key) <= @max_key_bytes do
      :ok
    else
      {:error, {:container_limit_exceeded, field}}
    end
  end

  defp validate_scalar_bytes(value, field) do
    if byte_size(value) <= @max_scalar_bytes do
      :ok
    else
      {:error, {:container_limit_exceeded, field}}
    end
  end

  defp validate_number(field, value) when is_integer(value) or is_float(value) do
    if finite_number?(value) do
      :ok
    else
      {:error, {:invalid_option, field}}
    end
  end

  defp validate_number(field, _value), do: {:error, {:invalid_option, field}}

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

  defp new_context, do: %{nodes: 0, bytes: 0}

  defp add_node(%{nodes: nodes} = context, field) do
    nodes = nodes + 1

    if nodes <= @max_nodes do
      {:ok, %{context | nodes: nodes}}
    else
      {:error, {:container_limit_exceeded, field}}
    end
  end

  defp add_bytes(%{bytes: bytes} = context, field, extra_bytes) do
    bytes = bytes + extra_bytes

    if bytes <= @max_total_bytes do
      {:ok, %{context | bytes: bytes}}
    else
      {:error, {:container_limit_exceeded, field}}
    end
  end

  defp finite_number?(value) when is_integer(value), do: abs(value) <= @safe_number_limit

  defp finite_number?(value) when is_float(value) do
    value == value and value - value == 0.0 and abs(value) <= @safe_number_limit
  end

  defp mark_invalid_observation_lighting(invalid_lighting, scenario_key) do
    Map.update!(
      invalid_lighting,
      :scenarios,
      &MapSet.put(&1, scenario_key)
    )
  end

  defp mark_all_observation_lighting(invalid_lighting) do
    %{invalid_lighting | all?: true}
  end
end
