defmodule OrbitalDynamics.CampaignPlanner.EventRiskIndicator.StationDownlinkPressure do
  @moduledoc false

  def indicators(%{"type" => "ground_station_outage"} = event) do
    station = event_ground_station_id(event)

    [
      %{
        "type" => "ground_station_outage",
        "severity" => "high",
        "reason" => "station #{station} unavailable during branch window",
        "ground_station_id" => station,
        "station_availability" => "unavailable",
        "station_calendar_entry_id" => event["station_calendar_entry_id"],
        "station_calendar_provider_id" => event["station_calendar_provider_id"],
        "station_calendar_provider_entry_id" => event["station_calendar_provider_entry_id"],
        "station_calendar_directions" => event["station_calendar_directions"],
        "station_calendar_status" => event["station_calendar_status"],
        "station_calendar_trust_boundary_status" =>
          event["station_calendar_trust_boundary_status"]
      }
      |> compact_map()
    ]
  end

  def indicators(%{"type" => "ground_station_reserved"} = event) do
    station = event_ground_station_id(event)
    reservation_id = event["station_reservation_id"] || event["reservation_id"]
    reserved_by = event["station_reserved_by"] || event["reserved_by"]
    reservation_status = event["station_reservation_status"] || event["reservation_status"]

    reservation_match_status =
      event["station_reservation_match_status"] || event["reservation_match_status"]

    [
      %{
        "type" => "ground_station_reserved",
        "severity" => "high",
        "reason" => "station #{station} reserved during branch window",
        "ground_station_id" => station,
        "starts_at_s" => event["starts_at_s"],
        "ends_at_s" => event["ends_at_s"],
        "capacity_fraction" => event["capacity_fraction"],
        "station_availability" => "reserved",
        "station_contention_status" => "reserved_overlap",
        "station_calendar_entry_id" => event["station_calendar_entry_id"],
        "station_calendar_provider_id" => event["station_calendar_provider_id"],
        "station_calendar_provider_entry_id" => event["station_calendar_provider_entry_id"],
        "station_calendar_directions" => event["station_calendar_directions"],
        "station_calendar_status" => event["station_calendar_status"],
        "station_calendar_overlap_count" => event["station_calendar_overlap_count"],
        "station_calendar_overlap_entry_ids" => event["station_calendar_overlap_entry_ids"],
        "station_calendar_overlap_availabilities" =>
          event["station_calendar_overlap_availabilities"],
        "station_calendar_entry_ambiguous" => event["station_calendar_entry_ambiguous"],
        "station_calendar_ambiguous_entry_count" =>
          event["station_calendar_ambiguous_entry_count"],
        "station_calendar_ambiguous_entry_ids" => event["station_calendar_ambiguous_entry_ids"],
        "station_calendar_reservation_overlap_count" =>
          event["station_calendar_reservation_overlap_count"],
        "station_calendar_reservation_ids" => event["station_calendar_reservation_ids"],
        "station_calendar_reserved_by" => event["station_calendar_reserved_by"],
        "station_calendar_reservation_statuses" => event["station_calendar_reservation_statuses"],
        "station_calendar_trust_boundary_status" =>
          event["station_calendar_trust_boundary_status"],
        "provider_calendar_contention_group_id" => event["provider_calendar_contention_group_id"],
        "provider_calendar_contention_status" => event["provider_calendar_contention_status"],
        "provider_calendar_contention_entry_ids" =>
          event["provider_calendar_contention_entry_ids"],
        "provider_calendar_contention_provider_ids" =>
          event["provider_calendar_contention_provider_ids"],
        "provider_calendar_contention_provider_entry_ids" =>
          event["provider_calendar_contention_provider_entry_ids"],
        "provider_calendar_contention_availabilities" =>
          event["provider_calendar_contention_availabilities"],
        "provider_calendar_contention_directions" =>
          event["provider_calendar_contention_directions"],
        "provider_calendar_contention_reservation_ids" =>
          event["provider_calendar_contention_reservation_ids"],
        "provider_calendar_contention_reserved_by" =>
          event["provider_calendar_contention_reserved_by"],
        "provider_calendar_contention_reservation_statuses" =>
          event["provider_calendar_contention_reservation_statuses"],
        "provider_calendar_contention_trust_boundary_statuses" =>
          event["provider_calendar_contention_trust_boundary_statuses"],
        "provider_calendar_contention_overlap_pairs" =>
          event["provider_calendar_contention_overlap_pairs"],
        "station_reservation_id" => reservation_id,
        "station_reserved_by" => reserved_by,
        "station_reservation_status" => reservation_status,
        "station_reservation_match_status" => reservation_match_status,
        "station_reservation_expires_at_s" => event["station_reservation_expires_at_s"],
        "station_reservation_expiration_status" => event["station_reservation_expiration_status"],
        "required_operator_action" => event["required_operator_action"],
        "station_reservation_hold_summary_model" =>
          event["station_reservation_hold_summary_model"],
        "station_reservation_hold_summary_source" =>
          event["station_reservation_hold_summary_source"],
        "station_reservation_hold_summary_source_artifact_type" =>
          event["station_reservation_hold_summary_source_artifact_type"],
        "station_reservation_hold_review_status" =>
          event["station_reservation_hold_review_status"],
        "station_reservation_hold_import_status" =>
          event["station_reservation_hold_import_status"],
        "station_reservation_hold_import_readiness_summary_model" =>
          event["station_reservation_hold_import_readiness_summary_model"],
        "station_reservation_hold_import_readiness_source" =>
          event["station_reservation_hold_import_readiness_source"],
        "station_reservation_hold_import_readiness_source_artifact_type" =>
          event["station_reservation_hold_import_readiness_source_artifact_type"],
        "station_reservation_hold_import_readiness_status" =>
          event["station_reservation_hold_import_readiness_status"],
        "station_reservation_hold_import_classification" =>
          event["station_reservation_hold_import_classification"],
        "station_reservation_hold_count" => event["station_reservation_hold_count"],
        "station_reservation_hold_ids" => event["station_reservation_hold_ids"],
        "station_reservation_hold_ids_by_import_status" =>
          event["station_reservation_hold_ids_by_import_status"],
        "station_reservation_hold_ids_by_required_import_action" =>
          event["station_reservation_hold_ids_by_required_import_action"],
        "station_reservation_hold_ids_by_direction" =>
          event["station_reservation_hold_ids_by_direction"],
        "station_reservation_hold_ids_by_direction_and_ground_station_id" =>
          event["station_reservation_hold_ids_by_direction_and_ground_station_id"],
        "station_reservation_hold_contact_ids_by_import_status" =>
          event["station_reservation_hold_contact_ids_by_import_status"],
        "station_reservation_hold_contact_ids_by_expiration_status" =>
          event["station_reservation_hold_contact_ids_by_expiration_status"],
        "station_reservation_hold_contact_ids_by_direction" =>
          event["station_reservation_hold_contact_ids_by_direction"],
        "station_reservation_hold_contact_ids_by_direction_and_ground_station_id" =>
          event["station_reservation_hold_contact_ids_by_direction_and_ground_station_id"],
        "station_reservation_hold_import_status_counts" =>
          event["station_reservation_hold_import_status_counts"],
        "station_reservation_hold_required_import_action_counts" =>
          event["station_reservation_hold_required_import_action_counts"],
        "station_reservation_hold_import_execution_boundary" =>
          event["station_reservation_hold_import_execution_boundary"],
        "station_reservation_hold_provider_write" =>
          event["station_reservation_hold_provider_write"],
        "station_reservation_hold_cadence_write" =>
          event["station_reservation_hold_cadence_write"],
        "station_reservation_hold_reservation_acceptance" =>
          event["station_reservation_hold_reservation_acceptance"],
        "source_station_reservation_hold_summary" =>
          event["source_station_reservation_hold_summary"],
        "source_station_reservation_hold_import_readiness_summary" =>
          event["source_station_reservation_hold_import_readiness_summary"],
        "feedback_source" => event["feedback_source"],
        "feedback_scope" => event["feedback_scope"],
        "trust_boundary" => event["trust_boundary"],
        "derivation_reasons" => event["derivation_reasons"]
      }
      |> compact_map()
    ]
  end

  def indicators(%{"type" => "reduced_downlink_capacity"} = event) do
    [
      %{
        "type" => "reduced_downlink_capacity",
        "severity" => "medium",
        "reason" => "downlink capacity reduced to #{event["capacity_fraction"] || 1.0}",
        "ground_station_id" => event_ground_station_id(event)
      }
      |> compact_map()
    ]
  end

  def indicators(%{"type" => "downlink_completion_gap"} = event) do
    reason = downlink_completion_gap_reason(event)

    [
      %{
        "type" => "downlink_completion_gap",
        "severity" => "medium",
        "reason" => reason,
        "ground_station_id" => event_ground_station_id(event),
        "station_availability" => event["station_availability"],
        "station_contention_status" => event["station_contention_status"],
        "station_calendar_entry_id" => event["station_calendar_entry_id"],
        "station_calendar_entry_status" => event["station_calendar_entry_status"],
        "station_calendar_provider_id" => event["station_calendar_provider_id"],
        "station_calendar_provider_entry_id" => event["station_calendar_provider_entry_id"],
        "station_calendar_directions" => event["station_calendar_directions"],
        "station_calendar_status" => event["station_calendar_status"],
        "station_calendar_trust_boundary_status" =>
          event["station_calendar_trust_boundary_status"],
        "starts_at_s" => event["starts_at_s"],
        "ends_at_s" => event["ends_at_s"],
        "direction" => event["direction"],
        "scenario_id" => event["scenario_id"],
        "spacecraft_id" => event["spacecraft_id"],
        "target_id" => event["target_id"],
        "collection_id" => event["collection_id"],
        "collection_ids" => event["collection_ids"],
        "product_id" => event["product_id"],
        "product_ids" => event["product_ids"],
        "payload_id" => event["payload_id"],
        "payload_ids" => event["payload_ids"],
        "instrument_id" => event["instrument_id"],
        "instrument_ids" => event["instrument_ids"],
        "objective_id" => event["objective_id"],
        "objective_type" => event["objective_type"],
        "objective_status" => event["objective_status"],
        "source_objective_status" => event["source_objective_status"],
        "latency_objective" => event["latency_objective"],
        "max_latency_s" => event["max_latency_s"],
        "planned_latency_s" => event["planned_latency_s"],
        "required_contacts" => event["required_contacts"],
        "planned_contacts" => event["planned_contacts"],
        "required_downlink_mb" => event["required_downlink_mb"],
        "planned_downlink_mb" => event["planned_downlink_mb"],
        "downlink_demand_sources" => event["downlink_demand_sources"],
        "downlink_completion_sources" => event["downlink_completion_sources"],
        "link_capacity_status" => event["link_capacity_status"],
        "downlink_requirement_status" => event["downlink_requirement_status"],
        "actual_downlink_requirement_status" => event["actual_downlink_requirement_status"],
        "resource_projection_status" => event["resource_projection_status"],
        "projected_resource_status" => event["projected_resource_status"],
        "contact_filter_status" => event["contact_filter_status"],
        "suppression_status" => event["suppression_status"],
        "contact_id" => event["contact_id"],
        "selected_contact_id" => event["selected_contact_id"],
        "selected_priority_source" => event["selected_priority_source"],
        "selection_reason" => event["selection_reason"],
        "resolution_selection_rule" => event["resolution_selection_rule"],
        "resolution_priority_override_count" => event["resolution_priority_override_count"],
        "resolution_priority_override_contact_ids" =>
          event["resolution_priority_override_contact_ids"],
        "contention_group_id" => event["contention_group_id"],
        "contention_resource_scope" => event["contention_resource_scope"],
        "contention_contact_ids" => event["contention_contact_ids"],
        "operator_action_reason" => event["operator_action_reason"],
        "contact_result" => event["contact_result"],
        "realized_status" => event["realized_status"],
        "allocation_status" => event["allocation_status"],
        "effective_allocation_status" => event["effective_allocation_status"],
        "allocation_reason" => event["allocation_reason"],
        "review_status" => event["review_status"],
        "approval_status" => event["approval_status"],
        "required_operator_action" => event["required_operator_action"],
        "cadence_import_status" => event["cadence_import_status"],
        "invalid_cadence_import" => event["invalid_cadence_import"],
        "invalid_cadence_import_reason" => event["invalid_cadence_import_reason"],
        "invalid_activity_input" => event["invalid_activity_input"],
        "invalid_activity_input_reason" => event["invalid_activity_input_reason"],
        "contact_intent_gate_status" => event["contact_intent_gate_status"],
        "policy_classification" => event["policy_classification"],
        "policy_bundle_id" => event["policy_bundle_id"],
        "source_activity_id" => event["source_activity_id"],
        "source_activity_ids" => event["source_activity_ids"],
        "missed_downlink_activity_id" => event["missed_downlink_activity_id"],
        "missed_downlink_activity_ids" => event["missed_downlink_activity_ids"],
        "source_window_id" => event["source_window_id"],
        "source_window_ids" => event["source_window_ids"],
        "timeline_id" => event["timeline_id"],
        "station_reservation_id" => event["station_reservation_id"],
        "station_reserved_by" => event["station_reserved_by"],
        "station_reservation_status" => event["station_reservation_status"],
        "station_reservation_match_status" => event["station_reservation_match_status"],
        "station_reservation_expires_at_s" => event["station_reservation_expires_at_s"],
        "station_reservation_expiration_status" => event["station_reservation_expiration_status"],
        "station_reservation_expiration_statuses" =>
          event["station_reservation_expiration_statuses"],
        "station_reservation_hold_expiration_status" =>
          event["station_reservation_hold_expiration_status"],
        "station_reservation_hold_expiration_statuses" =>
          event["station_reservation_hold_expiration_statuses"],
        "station_reservation_hold_import_status" =>
          event["station_reservation_hold_import_status"],
        "station_reservation_hold_import_readiness_summary_model" =>
          event["station_reservation_hold_import_readiness_summary_model"],
        "station_reservation_hold_import_readiness_source" =>
          event["station_reservation_hold_import_readiness_source"],
        "station_reservation_hold_import_readiness_source_artifact_type" =>
          event["station_reservation_hold_import_readiness_source_artifact_type"],
        "station_reservation_hold_import_readiness_status" =>
          event["station_reservation_hold_import_readiness_status"],
        "station_reservation_hold_import_classification" =>
          event["station_reservation_hold_import_classification"],
        "station_reservation_hold_count" => event["station_reservation_hold_count"],
        "station_reservation_hold_ids" => event["station_reservation_hold_ids"],
        "station_reservation_hold_ids_by_import_status" =>
          event["station_reservation_hold_ids_by_import_status"],
        "station_reservation_hold_ids_by_required_import_action" =>
          event["station_reservation_hold_ids_by_required_import_action"],
        "station_reservation_hold_ids_by_direction" =>
          event["station_reservation_hold_ids_by_direction"],
        "station_reservation_hold_ids_by_direction_and_ground_station_id" =>
          event["station_reservation_hold_ids_by_direction_and_ground_station_id"],
        "station_reservation_hold_contact_ids_by_import_status" =>
          event["station_reservation_hold_contact_ids_by_import_status"],
        "station_reservation_hold_contact_ids_by_expiration_status" =>
          event["station_reservation_hold_contact_ids_by_expiration_status"],
        "station_reservation_hold_contact_ids_by_direction" =>
          event["station_reservation_hold_contact_ids_by_direction"],
        "station_reservation_hold_contact_ids_by_direction_and_ground_station_id" =>
          event["station_reservation_hold_contact_ids_by_direction_and_ground_station_id"],
        "station_reservation_hold_import_status_counts" =>
          event["station_reservation_hold_import_status_counts"],
        "station_reservation_hold_required_import_action_counts" =>
          event["station_reservation_hold_required_import_action_counts"],
        "station_reservation_hold_import_execution_boundary" =>
          event["station_reservation_hold_import_execution_boundary"],
        "station_reservation_hold_provider_write" =>
          event["station_reservation_hold_provider_write"],
        "station_reservation_hold_cadence_write" =>
          event["station_reservation_hold_cadence_write"],
        "station_reservation_hold_reservation_acceptance" =>
          event["station_reservation_hold_reservation_acceptance"],
        "source_station_reservation_hold_import_readiness_summary" =>
          event["source_station_reservation_hold_import_readiness_summary"],
        "feedback_source" => event["feedback_source"],
        "feedback_scope" => event["feedback_scope"],
        "trust_boundary" => event["trust_boundary"],
        "derivation_reasons" => event["derivation_reasons"],
        "capacity_pack_group_id" => event["capacity_pack_group_id"],
        "capacity_pack_status" => event["capacity_pack_status"],
        "capacity_pack_capacity_fraction" => event["capacity_pack_capacity_fraction"],
        "capacity_pack_used_fraction" => event["capacity_pack_used_fraction"],
        "capacity_pack_unused_fraction" => event["capacity_pack_unused_fraction"],
        "required_capacity_fraction" => event["required_capacity_fraction"],
        "required_capacity_fraction_source" => event["required_capacity_fraction_source"],
        "capacity_pack_contact_ids_by_direction" =>
          event["capacity_pack_contact_ids_by_direction"],
        "capacity_pack_selected_contact_ids_by_direction" =>
          event["capacity_pack_selected_contact_ids_by_direction"],
        "capacity_pack_deferred_contact_ids_by_direction" =>
          event["capacity_pack_deferred_contact_ids_by_direction"],
        "capacity_pack_required_capacity_fraction_by_direction" =>
          event["capacity_pack_required_capacity_fraction_by_direction"],
        "capacity_pack_selected_required_capacity_fraction_by_direction" =>
          event["capacity_pack_selected_required_capacity_fraction_by_direction"],
        "capacity_pack_deferred_required_capacity_fraction_by_direction" =>
          event["capacity_pack_deferred_required_capacity_fraction_by_direction"]
      }
      |> compact_map()
    ]
  end

  def indicators(_event), do: []

  defp downlink_completion_gap_reason(event) do
    reason =
      [
        if(downlink_contact_gap?(event), do: downlink_contact_gap_reason(event)),
        if(downlink_volume_gap?(event), do: downlink_volume_gap_reason(event))
      ]
      |> Enum.reject(&is_nil/1)
      |> case do
        [] -> [downlink_contact_gap_reason(event)]
        reasons -> reasons
      end
      |> Enum.join("; ")

    if "storage_margin_low" in Map.get(event, "derivation_reasons", []) do
      "storage margin #{event["storage_margin"]} below threshold #{event["storage_margin_threshold"]}; " <>
        reason
    else
      reason
    end
  end

  defp downlink_contact_gap?(event) do
    is_number(event["required_contacts"]) and is_number(event["planned_contacts"]) and
      event["planned_contacts"] < event["required_contacts"]
  end

  defp downlink_volume_gap?(event) do
    is_number(event["required_downlink_mb"]) and is_number(event["planned_downlink_mb"]) and
      event["planned_downlink_mb"] < event["required_downlink_mb"]
  end

  defp downlink_volume_gap_reason(event) do
    "planned downlink volume #{event["planned_downlink_mb"]} MB below required #{event["required_downlink_mb"]} MB"
  end

  defp downlink_contact_gap_reason(event) do
    "planned downlinks #{event["planned_contacts"] || 0} below required #{event["required_contacts"] || 0}"
  end

  defp event_ground_station_id(event) do
    case encode_value(
           Map.get(event, "ground_station_id") || Map.get(event, "station_id") ||
             nested_ground_station_id(event)
         ) do
      value when is_binary(value) and value != "" -> value
      _value -> nil
    end
  end

  defp nested_ground_station_id(activity) do
    Enum.find_value(["ground_station", "station", :ground_station, :station], fn station_key ->
      case Map.get(activity, station_key) do
        %{} = station ->
          Enum.find_value(
            ["ground_station_id", "station_id", "id", :ground_station_id, :station_id, :id],
            fn identity_key -> Map.get(station, identity_key) end
          )

        _station ->
          nil
      end
    end)
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
