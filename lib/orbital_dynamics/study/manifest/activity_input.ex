defmodule OrbitalDynamics.Study.Manifest.ActivityInput do
  @moduledoc false

  import OrbitalDynamics.Study.Manifest.SchemaProperty, only: [enum_property: 1]

  alias OrbitalDynamics.Frame
  alias OrbitalDynamics.MissionPlan.Activity
  alias OrbitalDynamics.Study.Manifest.InputField

  def activities(spec) do
    spec
    |> Map.get("activities", [])
    |> case do
      activities when is_list(activities) ->
        activities
        |> Enum.reduce_while({:ok, []}, fn activity_spec, {:ok, activities} ->
          case activity(activity_spec) do
            {:ok, activity} -> {:cont, {:ok, activities ++ [activity]}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)

      _other ->
        {:error, {:invalid_field, "activities"}}
    end
  end

  def scoped_activities(activities, scenario_id, spacecraft_id) do
    activities
    |> Enum.reduce_while({:ok, []}, fn %Activity{} = activity, {:ok, scoped} ->
      cond do
        not scope_matches?(activity.scenario_id, scenario_id) ->
          {:halt, {:error, {:invalid_field, "activities.scenario_id"}}}

        not scope_matches?(activity.spacecraft_id, spacecraft_id) ->
          {:halt, {:error, {:invalid_field, "activities.spacecraft_id"}}}

        true ->
          {:cont,
           {:ok,
            scoped ++
              [
                %Activity{
                  activity
                  | scenario_id: activity.scenario_id || scenario_id,
                    spacecraft_id: activity.spacecraft_id || spacecraft_id
                }
              ]}}
      end
    end)
  end

  defp scope_matches?(nil, _expected), do: true
  defp scope_matches?(value, expected), do: to_string(value) == to_string(expected)

  defp activity(%{"type" => type} = spec) when type in [nil, ""] do
    spec
    |> Map.delete("type")
    |> activity()
  end

  defp activity(%{"type" => "coast"} = spec) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, start_s} <- required_number(spec, "start_s"),
         {:ok, end_s} <- required_number(spec, "end_s"),
         {:ok, opts} <- activity_opts(spec) do
      {:ok, Activity.coast!(id, start_s, end_s, opts)}
    end
  end

  defp activity(%{"type" => "observe"} = spec) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, start_s} <- required_number(spec, "start_s"),
         {:ok, end_s} <- required_number(spec, "end_s"),
         {:ok, target_id} <- required_target_id(spec),
         {:ok, opts} <- activity_opts(spec) do
      {:ok, Activity.observe!(id, start_s, end_s, target_id, opts)}
    end
  end

  defp activity(%{"type" => "downlink"} = spec) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, start_s} <- required_number(spec, "start_s"),
         {:ok, end_s} <- required_number(spec, "end_s"),
         {:ok, ground_station_id} <- required_activity_ground_station_id(spec),
         {:ok, opts} <- activity_opts(spec) do
      {:ok, Activity.downlink!(id, start_s, end_s, ground_station_id, opts)}
    end
  end

  defp activity(%{"type" => "attitude"} = spec) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, start_s} <- required_number(spec, "start_s"),
         {:ok, end_s} <- required_number(spec, "end_s"),
         {:ok, opts} <- activity_opts(spec) do
      {:ok, Activity.attitude!(id, start_s, end_s, opts)}
    end
  end

  defp activity(%{"type" => "command"} = spec) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, start_s} <- required_number(spec, "start_s"),
         {:ok, end_s} <- required_number(spec, "end_s"),
         {:ok, opts} <- activity_opts(spec) do
      {:ok, Activity.command!(id, start_s, end_s, opts)}
    end
  end

  defp activity(%{"type" => "tracking"} = spec) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, start_s} <- required_number(spec, "start_s"),
         {:ok, end_s} <- required_number(spec, "end_s"),
         {:ok, ground_station_id} <- required_activity_ground_station_id(spec),
         {:ok, opts} <- activity_opts(spec) do
      {:ok, Activity.tracking!(id, start_s, end_s, ground_station_id, opts)}
    end
  end

  defp activity(%{"type" => "health_check"} = spec) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, start_s} <- required_number(spec, "start_s"),
         {:ok, end_s} <- required_number(spec, "end_s"),
         {:ok, opts} <- activity_opts(spec),
         :ok <- ensure_health_check_direction(opts) do
      {:ok, Activity.health_check!(id, start_s, end_s, opts)}
    end
  end

  defp activity(%{"type" => "planned_contact"} = spec) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, start_s} <- required_number(spec, "start_s"),
         {:ok, end_s} <- required_number(spec, "end_s"),
         {:ok, ground_station_id} <- required_activity_ground_station_id(spec),
         {:ok, direction} <- required_contact_direction(spec),
         {:ok, opts} <- activity_opts(spec) do
      activity =
        if direction == :health_check do
          opts =
            opts
            |> Keyword.put(:ground_station_id, ground_station_id)
            |> Keyword.put(:direction, :health_check)

          Activity.health_check!(id, start_s, end_s, opts)
        else
          Activity.planned_contact!(id, start_s, end_s, ground_station_id, direction, opts)
        end

      {:ok, activity}
    end
  end

  defp activity(%{"type" => "slew"} = spec) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, start_s} <- required_number(spec, "start_s"),
         {:ok, end_s} <- required_number(spec, "end_s"),
         {:ok, opts} <- activity_opts(spec) do
      {:ok, Activity.slew!(id, start_s, end_s, opts)}
    end
  end

  defp activity(%{"type" => "impulsive_burn"} = spec) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, epoch_s} <- required_number(spec, "epoch_s"),
         {:ok, delta_v_km_s} <- required_vector(spec, "delta_v_km_s"),
         {:ok, frame} <- optional_frame(spec),
         {:ok, opts} <- activity_opts(spec) do
      opts = if is_nil(frame), do: opts, else: Keyword.put(opts, :frame, frame)
      {:ok, Activity.impulsive_burn!(id, epoch_s, delta_v_km_s, opts)}
    end
  end

  defp activity(%{"type" => type}), do: {:error, {:unsupported_activity_type, type}}

  defp activity(%{"activity_type" => type} = spec) when type not in [nil, ""] do
    activity(Map.put(spec, "type", type))
  end

  defp activity(_spec), do: {:error, {:invalid_field, "activities"}}

  defp activity_opts(spec) do
    with {:ok, metadata} <- metadata(spec),
         {:ok, allow_overlap?} <- optional_activity_overlap(spec),
         {:ok, status} <- optional_activity_status(spec),
         {:ok, approval_status} <- optional_approval_status(spec),
         {:ok, locked?} <- optional_boolean(spec, "locked", false),
         {:ok, timeline_id} <- optional_identifier(spec, "timeline_id"),
         {:ok, scenario_id} <- optional_identifier(spec, "scenario_id"),
         {:ok, spacecraft_id} <- optional_spacecraft_id(spec),
         {:ok, resource_id} <- optional_identifier(spec, "resource_id"),
         {:ok, resource_source_quality} <- optional_identifier(spec, "resource_source_quality"),
         {:ok, resource_trust_boundary} <- optional_identifier(spec, "resource_trust_boundary"),
         {:ok, resource_trust_boundary_status} <-
           optional_identifier(spec, "resource_trust_boundary_status"),
         {:ok, resource_provenance} <- optional_map_or_nil(spec, "resource_provenance"),
         {:ok, resource_blocking_dimension} <-
           optional_identifier(spec, "resource_blocking_dimension"),
         {:ok, fuel_margin} <- optional_number(spec, "fuel_margin"),
         {:ok, power_margin} <- optional_number(spec, "power_margin"),
         {:ok, storage_margin} <- optional_number(spec, "storage_margin"),
         {:ok, downlink_margin} <- optional_number(spec, "downlink_margin"),
         {:ok, battery_capacity_wh} <- optional_number(spec, "battery_capacity_wh"),
         {:ok, battery_energy_used_wh} <- optional_number(spec, "battery_energy_used_wh"),
         {:ok, battery_energy_generated_wh} <-
           optional_number(spec, "battery_energy_generated_wh"),
         {:ok, battery_state_of_charge} <- optional_number(spec, "battery_state_of_charge"),
         {:ok, spacecraft_available} <- optional_boolean_or_nil(spec, "spacecraft_available"),
         {:ok, payload_available} <- optional_boolean_or_nil(spec, "payload_available"),
         {:ok, antenna_available} <- optional_boolean_or_nil(spec, "antenna_available"),
         {:ok, degraded} <- optional_boolean_or_nil(spec, "degraded"),
         {:ok, mode} <- optional_identifier(spec, "mode"),
         {:ok, incompatible_activity_types} <-
           optional_identifier_list(spec, "incompatible_activity_types"),
         {:ok, suppressed_activity_types} <-
           optional_identifier_list(spec, "suppressed_activity_types"),
         {:ok, collection_id} <- optional_identifier(spec, "collection_id"),
         {:ok, product_id} <- optional_identifier(spec, "product_id"),
         {:ok, product_ids} <- optional_identifier_list(spec, "product_ids"),
         {:ok, payload_id} <- optional_identifier(spec, "payload_id"),
         {:ok, instrument_id} <- optional_identifier(spec, "instrument_id"),
         {:ok, target_priority} <- optional_number(spec, "target_priority"),
         {:ok, target_priority_source} <- optional_identifier(spec, "target_priority_source"),
         {:ok, target_priority_objective_ids} <-
           optional_identifier_list(spec, "target_priority_objective_ids"),
         {:ok, target_priority_objective_type} <-
           optional_identifier(spec, "target_priority_objective_type"),
         {:ok, contact_success} <- optional_boolean_or_nil(spec, "contact_success"),
         {:ok, contact_result} <- optional_identifier(spec, "contact_result"),
         {:ok, contact_success_factor} <- optional_number(spec, "contact_success_factor"),
         {:ok, contact_success_factor_source} <-
           optional_identifier(spec, "contact_success_factor_source"),
         {:ok, command_success} <- optional_boolean_or_nil(spec, "command_success"),
         {:ok, command_result} <- optional_identifier(spec, "command_result"),
         {:ok, command_success_factor} <- optional_number(spec, "command_success_factor"),
         {:ok, command_success_factor_source} <-
           optional_identifier(spec, "command_success_factor_source"),
         {:ok, observation_success} <- optional_boolean_or_nil(spec, "observation_success"),
         {:ok, observation_result} <- optional_identifier(spec, "observation_result"),
         {:ok, observation_success_factor} <- optional_number(spec, "observation_success_factor"),
         {:ok, observation_success_factor_source} <-
           optional_identifier(spec, "observation_success_factor_source"),
         {:ok, image_quality_score} <- optional_number(spec, "image_quality_score"),
         {:ok, image_quality_status} <- optional_identifier(spec, "image_quality_status"),
         {:ok, image_quality_source} <- optional_string(spec, "image_quality_source"),
         {:ok, cloud_cover_fraction} <- optional_number(spec, "cloud_cover_fraction"),
         {:ok, blur_score} <- optional_number(spec, "blur_score"),
         {:ok, maneuver_success} <- optional_boolean_or_nil(spec, "maneuver_success"),
         {:ok, maneuver_result} <- optional_identifier(spec, "maneuver_result"),
         {:ok, maneuver_success_factor} <- optional_number(spec, "maneuver_success_factor"),
         {:ok, maneuver_success_factor_source} <-
           optional_identifier(spec, "maneuver_success_factor_source"),
         {:ok, feedback_weight} <- optional_number(spec, "feedback_weight"),
         {:ok, feedback_weight_source} <- optional_identifier(spec, "feedback_weight_source"),
         {:ok, data_volume_mb} <- optional_number(spec, "data_volume_mb"),
         {:ok, planned_data_volume_mb} <- optional_number(spec, "planned_data_volume_mb"),
         {:ok, actual_data_volume_mb} <- optional_number(spec, "actual_data_volume_mb"),
         {:ok, estimated_data_volume_mb} <- optional_number(spec, "estimated_data_volume_mb"),
         {:ok, estimated_storage_mb} <- optional_number(spec, "estimated_storage_mb"),
         {:ok, estimated_downlink_mb} <- optional_number(spec, "estimated_downlink_mb"),
         {:ok, required_downlink_mb} <- optional_number(spec, "required_downlink_mb"),
         {:ok, collection_ends_at_s} <- optional_number(spec, "collection_ends_at_s"),
         {:ok, planned_delivery_at_s} <- optional_number(spec, "planned_delivery_at_s"),
         {:ok, actual_delivery_at_s} <- optional_number(spec, "actual_delivery_at_s"),
         {:ok, max_latency_s} <- optional_number(spec, "max_latency_s"),
         {:ok, planned_latency_s} <- optional_number(spec, "planned_latency_s"),
         {:ok, actual_latency_s} <- optional_number(spec, "actual_latency_s"),
         {:ok, planned_estimated_throughput_mb} <-
           optional_number(spec, "planned_estimated_throughput_mb"),
         {:ok, actual_throughput_mb} <- optional_number(spec, "actual_throughput_mb"),
         {:ok, link_protocol} <- optional_identifier(spec, "link_protocol"),
         {:ok, frequency_band} <- optional_identifier(spec, "frequency_band"),
         {:ok, modulation} <- optional_identifier(spec, "modulation"),
         {:ok, coding_scheme} <- optional_identifier(spec, "coding_scheme"),
         {:ok, polarization} <- optional_identifier(spec, "polarization"),
         {:ok, data_rate_mbps} <- optional_number(spec, "data_rate_mbps"),
         {:ok, downlink_rate_mbps} <- optional_number(spec, "downlink_rate_mbps"),
         {:ok, data_rate_mb_s} <- optional_number(spec, "data_rate_mb_s"),
         {:ok, downlink_rate_mb_s} <- optional_number(spec, "downlink_rate_mb_s"),
         {:ok, actual_data_rate_mbps} <- optional_number(spec, "actual_data_rate_mbps"),
         {:ok, actual_downlink_rate_mbps} <-
           optional_number(spec, "actual_downlink_rate_mbps"),
         {:ok, actual_data_rate_mb_s} <- optional_number(spec, "actual_data_rate_mb_s"),
         {:ok, actual_downlink_rate_mb_s} <-
           optional_number(spec, "actual_downlink_rate_mb_s"),
         {:ok, delivered_rate_mbps} <- optional_number(spec, "delivered_rate_mbps"),
         {:ok, received_rate_mbps} <- optional_number(spec, "received_rate_mbps"),
         {:ok, delivered_rate_mb_s} <- optional_number(spec, "delivered_rate_mb_s"),
         {:ok, received_rate_mb_s} <- optional_number(spec, "received_rate_mb_s"),
         {:ok, actual_duration_s} <- optional_number(spec, "actual_duration_s"),
         {:ok, actual_contact_duration_s} <- optional_number(spec, "actual_contact_duration_s"),
         {:ok, contact_duration_s} <- optional_number(spec, "contact_duration_s"),
         {:ok, link_margin_db} <- optional_number(spec, "link_margin_db"),
         {:ok, snr_db} <- optional_number(spec, "snr_db"),
         {:ok, eb_no_db} <- optional_number(spec, "eb_no_db"),
         {:ok, bit_error_rate} <- optional_number(spec, "bit_error_rate"),
         {:ok, packet_loss_rate} <- optional_number(spec, "packet_loss_rate"),
         {:ok, frame_loss_rate} <- optional_number(spec, "frame_loss_rate"),
         {:ok, carrier_lock} <- optional_boolean_or_nil(spec, "carrier_lock"),
         {:ok, symbol_lock} <- optional_boolean_or_nil(spec, "symbol_lock"),
         {:ok, link_quality_status} <- optional_identifier(spec, "link_quality_status"),
         {:ok, pointing_mode} <- optional_identifier(spec, "pointing_mode"),
         {:ok, pointing_target_id} <- optional_identifier(spec, "pointing_target_id"),
         {:ok, boresight_axis} <- optional_string(spec, "boresight_axis"),
         {:ok, off_nadir_angle_deg} <- optional_number(spec, "off_nadir_angle_deg"),
         {:ok, slew_angle_deg} <- optional_number(spec, "slew_angle_deg"),
         {:ok, slew_rate_deg_s} <- optional_number(spec, "slew_rate_deg_s"),
         {:ok, pointing_error_deg} <- optional_number(spec, "pointing_error_deg"),
         {:ok, pointing_status} <- optional_identifier(spec, "pointing_status"),
         {:ok, pointing_model} <- optional_identifier(spec, "pointing_model"),
         {:ok, pointing_source} <- optional_string(spec, "pointing_source"),
         {:ok, pointing_confidence} <- optional_number(spec, "pointing_confidence"),
         {:ok, attitude_mode} <- optional_identifier(spec, "attitude_mode"),
         {:ok, attitude_target_id} <- optional_identifier(spec, "attitude_target_id"),
         {:ok, roll_deg} <- optional_number(spec, "roll_deg"),
         {:ok, pitch_deg} <- optional_number(spec, "pitch_deg"),
         {:ok, yaw_deg} <- optional_number(spec, "yaw_deg"),
         {:ok, attitude_error_deg} <- optional_number(spec, "attitude_error_deg"),
         {:ok, attitude_status} <- optional_identifier(spec, "attitude_status"),
         {:ok, attitude_model} <- optional_identifier(spec, "attitude_model"),
         {:ok, attitude_source} <- optional_string(spec, "attitude_source"),
         {:ok, attitude_confidence} <- optional_number(spec, "attitude_confidence"),
         {:ok, thermal_zone_id} <- optional_identifier(spec, "thermal_zone_id"),
         {:ok, temperature_c} <- optional_number(spec, "temperature_c"),
         {:ok, planned_temperature_c} <- optional_number(spec, "planned_temperature_c"),
         {:ok, actual_temperature_c} <- optional_number(spec, "actual_temperature_c"),
         {:ok, min_operating_temperature_c} <-
           optional_number(spec, "min_operating_temperature_c"),
         {:ok, max_operating_temperature_c} <-
           optional_number(spec, "max_operating_temperature_c"),
         {:ok, thermal_margin_c} <- optional_number(spec, "thermal_margin_c"),
         {:ok, thermal_status} <- optional_identifier(spec, "thermal_status"),
         {:ok, thermal_model} <- optional_identifier(spec, "thermal_model"),
         {:ok, thermal_source} <- optional_string(spec, "thermal_source"),
         {:ok, thermal_confidence} <- optional_number(spec, "thermal_confidence"),
         {:ok, eclipse_overlap_fraction} <- optional_number(spec, "eclipse_overlap_fraction"),
         {:ok, eclipse_overlap_s} <- optional_number(spec, "eclipse_overlap_s"),
         {:ok, lighting_condition} <- optional_identifier(spec, "lighting_condition"),
         {:ok, lighting_condition_detail} <-
           optional_identifier(spec, "lighting_condition_detail"),
         {:ok, lighting_condition_model} <- optional_identifier(spec, "lighting_condition_model"),
         {:ok, lighting_detail_model} <- optional_identifier(spec, "lighting_detail_model"),
         {:ok, lighting_confidence} <- optional_number_or_identifier(spec, "lighting_confidence"),
         {:ok, command_window_id} <- optional_command_window_id(spec),
         {:ok, command_window_type} <- optional_command_window_type(spec),
         {:ok, command_window} <- optional_map_or_nil(spec, "command_window"),
         {:ok, dependencies} <- optional_identifier_list(spec, "dependencies"),
         {:ok, dependency_activity_ids} <-
           optional_identifier_list_or_nil(spec, "dependency_activity_ids"),
         {:ok, dependency_timeline_ids} <-
           optional_identifier_list_or_nil(spec, "dependency_timeline_ids"),
         {:ok, exclusive_with_activity_ids} <-
           optional_identifier_list_or_nil(spec, "exclusive_with_activity_ids"),
         {:ok, exclusive_with_timeline_ids} <-
           optional_identifier_list_or_nil(spec, "exclusive_with_timeline_ids"),
         {:ok, exclusivity_group} <- optional_identifier(spec, "exclusivity_group"),
         {:ok, source_window_id} <- optional_identifier(spec, "source_window_id"),
         {:ok, source_window_type} <- optional_identifier(spec, "source_window_type"),
         {:ok, source_window} <- optional_map_or_nil(spec, "source_window"),
         {:ok, cadence_import} <- optional_map_or_nil(spec, "cadence_import"),
         {:ok, provenance} <- optional_map(spec, "provenance"),
         {:ok, direction} <- optional_contact_direction(spec),
         {:ok, ground_station_id} <- optional_ground_station_id(spec) do
      {:ok,
       compact_keyword(
         metadata: metadata,
         allow_overlap?: allow_overlap?,
         status: status,
         approval_status: approval_status,
         locked?: locked?,
         timeline_id: timeline_id,
         scenario_id: scenario_id,
         spacecraft_id: spacecraft_id,
         resource_id: resource_id,
         resource_source_quality: resource_source_quality,
         resource_trust_boundary: resource_trust_boundary,
         resource_trust_boundary_status: resource_trust_boundary_status,
         resource_provenance: resource_provenance,
         resource_blocking_dimension: resource_blocking_dimension,
         fuel_margin: fuel_margin,
         power_margin: power_margin,
         storage_margin: storage_margin,
         downlink_margin: downlink_margin,
         battery_capacity_wh: battery_capacity_wh,
         battery_energy_used_wh: battery_energy_used_wh,
         battery_energy_generated_wh: battery_energy_generated_wh,
         battery_state_of_charge: battery_state_of_charge,
         spacecraft_available: spacecraft_available,
         payload_available: payload_available,
         antenna_available: antenna_available,
         degraded: degraded,
         mode: mode,
         incompatible_activity_types: incompatible_activity_types,
         suppressed_activity_types: suppressed_activity_types,
         collection_id: collection_id,
         product_id: product_id,
         product_ids: product_ids,
         payload_id: payload_id,
         instrument_id: instrument_id,
         target_priority: target_priority,
         target_priority_source: target_priority_source,
         target_priority_objective_ids: target_priority_objective_ids,
         target_priority_objective_type: target_priority_objective_type,
         contact_success: contact_success,
         contact_result: contact_result,
         contact_success_factor: contact_success_factor,
         contact_success_factor_source: contact_success_factor_source,
         command_success: command_success,
         command_result: command_result,
         command_success_factor: command_success_factor,
         command_success_factor_source: command_success_factor_source,
         observation_success: observation_success,
         observation_result: observation_result,
         observation_success_factor: observation_success_factor,
         observation_success_factor_source: observation_success_factor_source,
         image_quality_score: image_quality_score,
         image_quality_status: image_quality_status,
         image_quality_source: image_quality_source,
         cloud_cover_fraction: cloud_cover_fraction,
         blur_score: blur_score,
         maneuver_success: maneuver_success,
         maneuver_result: maneuver_result,
         maneuver_success_factor: maneuver_success_factor,
         maneuver_success_factor_source: maneuver_success_factor_source,
         feedback_weight: feedback_weight,
         feedback_weight_source: feedback_weight_source,
         data_volume_mb: data_volume_mb,
         planned_data_volume_mb: planned_data_volume_mb,
         actual_data_volume_mb: actual_data_volume_mb,
         estimated_data_volume_mb: estimated_data_volume_mb,
         estimated_storage_mb: estimated_storage_mb,
         estimated_downlink_mb: estimated_downlink_mb,
         required_downlink_mb: required_downlink_mb,
         collection_ends_at_s: collection_ends_at_s,
         planned_delivery_at_s: planned_delivery_at_s,
         actual_delivery_at_s: actual_delivery_at_s,
         max_latency_s: max_latency_s,
         planned_latency_s: planned_latency_s,
         actual_latency_s: actual_latency_s,
         planned_estimated_throughput_mb: planned_estimated_throughput_mb,
         actual_throughput_mb: actual_throughput_mb,
         link_protocol: link_protocol,
         frequency_band: frequency_band,
         modulation: modulation,
         coding_scheme: coding_scheme,
         polarization: polarization,
         data_rate_mbps: data_rate_mbps,
         downlink_rate_mbps: downlink_rate_mbps,
         data_rate_mb_s: data_rate_mb_s,
         downlink_rate_mb_s: downlink_rate_mb_s,
         actual_data_rate_mbps: actual_data_rate_mbps,
         actual_downlink_rate_mbps: actual_downlink_rate_mbps,
         actual_data_rate_mb_s: actual_data_rate_mb_s,
         actual_downlink_rate_mb_s: actual_downlink_rate_mb_s,
         delivered_rate_mbps: delivered_rate_mbps,
         received_rate_mbps: received_rate_mbps,
         delivered_rate_mb_s: delivered_rate_mb_s,
         received_rate_mb_s: received_rate_mb_s,
         actual_duration_s: actual_duration_s,
         actual_contact_duration_s: actual_contact_duration_s,
         contact_duration_s: contact_duration_s,
         link_margin_db: link_margin_db,
         snr_db: snr_db,
         eb_no_db: eb_no_db,
         bit_error_rate: bit_error_rate,
         packet_loss_rate: packet_loss_rate,
         frame_loss_rate: frame_loss_rate,
         carrier_lock: carrier_lock,
         symbol_lock: symbol_lock,
         link_quality_status: link_quality_status,
         pointing_mode: pointing_mode,
         pointing_target_id: pointing_target_id,
         boresight_axis: boresight_axis,
         off_nadir_angle_deg: off_nadir_angle_deg,
         slew_angle_deg: slew_angle_deg,
         slew_rate_deg_s: slew_rate_deg_s,
         pointing_error_deg: pointing_error_deg,
         pointing_status: pointing_status,
         pointing_model: pointing_model,
         pointing_source: pointing_source,
         pointing_confidence: pointing_confidence,
         attitude_mode: attitude_mode,
         attitude_target_id: attitude_target_id,
         roll_deg: roll_deg,
         pitch_deg: pitch_deg,
         yaw_deg: yaw_deg,
         attitude_error_deg: attitude_error_deg,
         attitude_status: attitude_status,
         attitude_model: attitude_model,
         attitude_source: attitude_source,
         attitude_confidence: attitude_confidence,
         thermal_zone_id: thermal_zone_id,
         temperature_c: temperature_c,
         planned_temperature_c: planned_temperature_c,
         actual_temperature_c: actual_temperature_c,
         min_operating_temperature_c: min_operating_temperature_c,
         max_operating_temperature_c: max_operating_temperature_c,
         thermal_margin_c: thermal_margin_c,
         thermal_status: thermal_status,
         thermal_model: thermal_model,
         thermal_source: thermal_source,
         thermal_confidence: thermal_confidence,
         eclipse_overlap_fraction: eclipse_overlap_fraction,
         eclipse_overlap_s: eclipse_overlap_s,
         lighting_condition: lighting_condition,
         lighting_condition_detail: lighting_condition_detail,
         lighting_condition_model: lighting_condition_model,
         lighting_detail_model: lighting_detail_model,
         lighting_confidence: lighting_confidence,
         command_window_id: command_window_id,
         command_window_type: command_window_type,
         command_window: command_window,
         dependencies: dependencies,
         dependency_activity_ids: dependency_activity_ids,
         dependency_timeline_ids: dependency_timeline_ids,
         exclusive_with_activity_ids: exclusive_with_activity_ids,
         exclusive_with_timeline_ids: exclusive_with_timeline_ids,
         exclusivity_group: exclusivity_group,
         source_window_id: source_window_id,
         source_window_type: source_window_type,
         source_window: source_window,
         cadence_import: cadence_import,
         provenance: provenance,
         direction: direction,
         ground_station_id: ground_station_id
       )}
    end
  end

  defp optional_ground_station_id(spec) do
    case optional_identifier(spec, "ground_station_id") do
      {:ok, nil} ->
        case optional_identifier(spec, "station_id") do
          {:ok, nil} ->
            optional_nested_identifier(spec, ["ground_station", "station"], [
              "ground_station_id",
              "station_id",
              "id"
            ])

          other ->
            other
        end

      other ->
        other
    end
  end

  defp optional_spacecraft_id(spec) do
    case optional_identifier(spec, "spacecraft_id") do
      {:ok, nil} ->
        case optional_identifier(spec, "satellite_id") do
          {:ok, nil} ->
            optional_nested_identifier(spec, ["spacecraft", "satellite"], [
              "spacecraft_id",
              "satellite_id",
              "id"
            ])

          other ->
            other
        end

      other ->
        other
    end
  end

  defp required_target_id(spec) do
    case optional_identifier(spec, "target_id") do
      {:ok, nil} ->
        case optional_nested_identifier(spec, ["target"], ["target_id", "id"]) do
          {:ok, nil} -> {:error, {:missing_field, "target_id"}}
          other -> other
        end

      other ->
        other
    end
  end

  defp optional_command_window_id(spec) do
    case optional_identifier(spec, "command_window_id") do
      {:ok, nil} ->
        case optional_identifier(spec, "command_window_ref") do
          {:ok, nil} ->
            optional_nested_identifier(spec, ["command_window"], [
              "id",
              "window_id",
              "command_window_id"
            ])

          other ->
            other
        end

      other ->
        other
    end
  end

  defp optional_command_window_type(spec) do
    case optional_identifier(spec, "command_window_type") do
      {:ok, nil} ->
        case optional_identifier(spec, "window_type") do
          {:ok, nil} ->
            case optional_identifier(spec, "command_window_kind") do
              {:ok, nil} ->
                optional_nested_identifier(spec, ["command_window"], [
                  "type",
                  "window_type",
                  "command_window_type"
                ])

              other ->
                other
            end

          other ->
            other
        end

      other ->
        other
    end
  end

  defp required_activity_ground_station_id(spec) do
    case optional_ground_station_id(spec) do
      {:ok, nil} -> {:error, {:missing_field, "ground_station_id"}}
      other -> other
    end
  end

  defp optional_nested_identifier(spec, object_keys, identity_keys) do
    Enum.reduce_while(object_keys, {:ok, nil}, fn object_key, {:ok, nil} ->
      case Map.fetch(spec, object_key) do
        {:ok, %{} = object} ->
          case first_nested_identifier(object, identity_keys) do
            {:ok, nil} -> {:cont, {:ok, nil}}
            other -> {:halt, other}
          end

        {:ok, nil} ->
          {:cont, {:ok, nil}}

        {:ok, _value} ->
          {:halt, {:error, {:invalid_field, object_key}}}

        :error ->
          {:cont, {:ok, nil}}
      end
    end)
  end

  defp first_nested_identifier(object, identity_keys) do
    Enum.reduce_while(identity_keys, {:ok, nil}, fn identity_key, {:ok, nil} ->
      case optional_identifier(object, identity_key) do
        {:ok, nil} -> {:cont, {:ok, nil}}
        other -> {:halt, other}
      end
    end)
  end

  defp optional_activity_overlap(%{"allow_overlap" => _value, "allow_overlap?" => _legacy_value}),
    do: {:error, {:invalid_field, "activities.allow_overlap"}}

  defp optional_activity_overlap(%{"allow_overlap?" => _value} = spec),
    do: optional_boolean(spec, "allow_overlap?", false)

  defp optional_activity_overlap(spec), do: optional_boolean(spec, "allow_overlap", false)

  defp optional_activity_status(spec) do
    optional_atom(spec, "status", :planned, activity_status_values())
  end

  defp optional_approval_status(spec) do
    optional_atom(spec, "approval_status", :not_required, activity_approval_status_values())
  end

  defp activity_status_values do
    Activity.capabilities().activity_statuses
    |> Enum.map(&Atom.to_string/1)
  end

  defp activity_approval_status_values do
    Activity.capabilities().approval_statuses
    |> Enum.map(&Atom.to_string/1)
  end

  defp required_contact_direction(spec) do
    case optional_contact_direction(spec) do
      {:ok, nil} -> {:error, {:missing_field, "activities.direction"}}
      result -> result
    end
  end

  defp optional_contact_direction(spec) do
    case Map.fetch(spec, "direction") do
      :error -> {:ok, nil}
      {:ok, nil} -> {:ok, nil}
      {:ok, value} -> contact_direction_value(value)
    end
  end

  defp contact_direction_value(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> contact_direction_value()
  end

  defp contact_direction_value(value) when is_binary(value) do
    normalized =
      value
      |> String.trim()
      |> String.downcase()
      |> String.replace(~r/[\s-]+/, "_")

    alias_map =
      Activity.capabilities().contact_direction_aliases
      |> Map.new(fn {alias, direction} -> {alias, direction} end)

    direction =
      Map.get_lazy(alias_map, normalized, fn ->
        Enum.find(Activity.capabilities().contact_directions, &(Atom.to_string(&1) == normalized))
      end)

    if is_nil(direction) do
      {:error, {:invalid_field, "activities.direction"}}
    else
      {:ok, direction}
    end
  end

  defp contact_direction_value(_value), do: {:error, {:invalid_field, "activities.direction"}}

  defp ensure_health_check_direction(opts) do
    case Keyword.get(opts, :direction) do
      nil -> :ok
      :health_check -> :ok
      _direction -> {:error, {:invalid_field, "activities.direction"}}
    end
  end

  defp activity_contact_direction_values do
    Activity.capabilities().contact_directions
    |> Enum.map(&Atom.to_string/1)
  end

  def contact_direction_property do
    enum_property(activity_contact_direction_schema_values())
    |> Map.put(
      "description",
      "Canonical contact directions plus provider aliases accepted by the manifest loader."
    )
    |> Map.put("x-orbital-dynamics", %{
      "canonical_values" => activity_contact_direction_values(),
      "provider_aliases" =>
        Activity.capabilities().contact_direction_aliases
        |> Map.new(fn {alias, direction} -> {alias, Atom.to_string(direction)} end)
    })
  end

  defp activity_contact_direction_schema_values do
    (activity_contact_direction_values() ++
       (Activity.capabilities().contact_direction_aliases |> Map.keys()) ++
       [
         "Down Link",
         "Health Check",
         "Health Check Window",
         "Track-ing",
         "Up Link",
         "up-link"
       ])
    |> Enum.uniq()
  end

  defp frame(source) do
    case Map.get(source, "frame", "earth_inertial_j2000") do
      "earth_inertial_j2000" -> {:ok, Frame.earth_inertial_j2000()}
      other -> {:error, {:unsupported_frame, other}}
    end
  end

  defp optional_frame(source) do
    case Map.fetch(source, "frame") do
      {:ok, _frame} -> frame(source)
      :error -> {:ok, nil}
    end
  end

  defp metadata(source) do
    case Map.get(source, "metadata", %{}) do
      metadata when is_map(metadata) -> {:ok, metadata}
      _metadata -> {:error, {:invalid_field, "metadata"}}
    end
  end

  defp required(map, key), do: InputField.required(map, key)
  defp required_number(map, key), do: InputField.required_number(map, key)
  defp required_vector(map, key), do: InputField.required_vector(map, key)
  defp optional_number(map, key), do: InputField.optional_number(map, key)

  defp optional_number_or_identifier(map, key),
    do: InputField.optional_number_or_identifier(map, key)

  defp optional_boolean(map, key, default),
    do: InputField.optional_boolean(map, key, default)

  defp optional_boolean_or_nil(map, key), do: InputField.optional_boolean_or_nil(map, key)
  defp optional_string(map, key), do: InputField.optional_string(map, key)
  defp optional_identifier(map, key), do: InputField.optional_identifier(map, key)
  defp optional_identifier_list(map, key), do: InputField.optional_identifier_list(map, key)

  defp optional_identifier_list_or_nil(map, key),
    do: InputField.optional_identifier_list_or_nil(map, key)

  defp optional_map(map, key), do: InputField.optional_map(map, key)
  defp optional_map_or_nil(map, key), do: InputField.optional_map_or_nil(map, key)

  defp optional_atom(map, key, default, allowed),
    do: InputField.optional_atom(map, key, default, allowed)

  defp compact_keyword(keyword) do
    Enum.reject(keyword, fn {_key, value} -> is_nil(value) end)
  end
end
