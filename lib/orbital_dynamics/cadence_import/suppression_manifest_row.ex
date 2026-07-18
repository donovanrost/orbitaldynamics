defmodule OrbitalDynamics.CadenceImport.SuppressionManifestRow do
  @moduledoc false

  def build(row, rank, suppression_type, callbacks) when is_list(callbacks) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")
    requirement = first_approval_requirement(callbacks, row)
    rule_match = first_approval_rule_match(callbacks, row)
    policy_decision = stringify_keys(row["source_policy_decision"] || %{}, callbacks)

    policy_escalation =
      (row["source_policy_escalation"] ||
         preferred_approval_escalation(policy_decision["escalations"], row, %{}, callbacks))
      |> stringify_keys(callbacks)

    %{
      "id" => "cadence_import:#{suppression_type}_suppression:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_#{suppression_type}_suppression",
      "import_status" => adapter_import_status(callbacks, import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(callbacks, row),
      "subject_id" => row["subject_id"],
      "branch_id" => row["branch_id"],
      "activity_id" => row["activity_id"],
      "base_candidate_id" => row["base_candidate_id"],
      "activity_type" => row["activity_type"],
      "scenario_id" => row["scenario_id"],
      "spacecraft_id" => row["spacecraft_id"],
      "target_id" => row["target_id"],
      "ground_station_id" => row["ground_station_id"],
      "direction" => row["direction"],
      "starts_at_s" => row["starts_at_s"],
      "ends_at_s" => row["ends_at_s"],
      "source_window_id" => row["source_window_id"],
      "contact_success" => row["contact_success"],
      "contact_success_factor" => row["contact_success_factor"],
      "contact_success_factor_source" => row["contact_success_factor_source"],
      "command_success" => row["command_success"],
      "contact_result" => provider_result_artifact_value(callbacks, row["contact_result"]),
      "command_result" => provider_result_artifact_value(callbacks, row["command_result"]),
      "command_success_factor" => row["command_success_factor"],
      "command_success_factor_source" => row["command_success_factor_source"],
      "station_availability" => row["station_availability"],
      "station_calendar_entry_id" => row["station_calendar_entry_id"],
      "station_calendar_directions" => row["station_calendar_directions"],
      "station_calendar_status" => row["station_calendar_status"],
      "station_calendar_overlap_count" => row["station_calendar_overlap_count"],
      "station_calendar_overlap_entry_ids" => row["station_calendar_overlap_entry_ids"],
      "station_calendar_overlap_availabilities" => row["station_calendar_overlap_availabilities"],
      "station_calendar_entry_ambiguous" => row["station_calendar_entry_ambiguous"],
      "station_calendar_ambiguous_entry_count" => row["station_calendar_ambiguous_entry_count"],
      "station_calendar_ambiguous_entry_ids" => row["station_calendar_ambiguous_entry_ids"],
      "station_calendar_reservation_overlap_count" =>
        row["station_calendar_reservation_overlap_count"],
      "station_calendar_reservation_ids" => row["station_calendar_reservation_ids"],
      "station_calendar_reserved_by" => row["station_calendar_reserved_by"],
      "station_calendar_reservation_statuses" => row["station_calendar_reservation_statuses"],
      "station_calendar_reservation_expires_at_s" =>
        row["station_calendar_reservation_expires_at_s"],
      "provider_counteroffer_id" => row["provider_counteroffer_id"],
      "provider_counteroffer_status" => row["provider_counteroffer_status"],
      "provider_counteroffer_negotiation_state" => row["provider_counteroffer_negotiation_state"],
      "provider_counteroffer_reason_code" => row["provider_counteroffer_reason_code"],
      "provider_counteroffer_cost_delta" => row["provider_counteroffer_cost_delta"],
      "provider_counteroffer_lock_deadline_s" => row["provider_counteroffer_lock_deadline_s"],
      "provider_counteroffer_starts_at_s" => row["provider_counteroffer_starts_at_s"],
      "provider_counteroffer_ends_at_s" => row["provider_counteroffer_ends_at_s"],
      "provider_counteroffer_start_delta_s" => row["provider_counteroffer_start_delta_s"],
      "provider_counteroffer_end_delta_s" => row["provider_counteroffer_end_delta_s"],
      "provider_counteroffer_duration_delta_s" => row["provider_counteroffer_duration_delta_s"],
      "station_contention_status" => row["station_contention_status"],
      "station_reservation_id" => row["station_reservation_id"],
      "station_reservation_expires_at_s" => row["station_reservation_expires_at_s"],
      "station_reserved_by" => row["station_reserved_by"],
      "station_reservation_status" => row["station_reservation_status"],
      "station_reservation_match_status" => row["station_reservation_match_status"],
      "duplicate_suppressed_candidate_id_collision" =>
        row["duplicate_suppressed_candidate_id_collision"],
      "duplicate_suppressed_candidate_index" => row["duplicate_suppressed_candidate_index"],
      "duplicate_suppressed_candidate_count" => row["duplicate_suppressed_candidate_count"],
      "invalid_candidate_input" => row["invalid_candidate_input"],
      "invalid_candidate_input_reason" => row["invalid_candidate_input_reason"],
      "source_candidate" => row["source_candidate"],
      "invalid_contact_input" => row["invalid_contact_input"],
      "invalid_contact_input_reason" => row["invalid_contact_input_reason"],
      "invalid_resource_summary_input" => row["invalid_resource_summary_input"],
      "invalid_resource_summary_input_reason" => row["invalid_resource_summary_input_reason"],
      "resource_source_quality" => row["resource_source_quality"],
      "resource_trust_boundary" => row["resource_trust_boundary"],
      "resource_trust_boundary_status" => row["resource_trust_boundary_status"],
      "resource_provenance" => row["resource_provenance"],
      "resource_blocking_dimension" => row["resource_blocking_dimension"],
      "fuel_margin" => row["fuel_margin"],
      "thermal_margin_c" => row["thermal_margin_c"],
      "power_margin" => row["power_margin"],
      "storage_margin" => row["storage_margin"],
      "downlink_margin" => row["downlink_margin"],
      "spacecraft_available" => row["spacecraft_available"],
      "payload_available" => row["payload_available"],
      "antenna_available" => row["antenna_available"],
      "degraded" => row["degraded"],
      "mode" => row["mode"],
      "incompatible_activity_types" => row["incompatible_activity_types"],
      "suppressed_activity_types" => row["suppressed_activity_types"],
      "suppressed_reason" => row["suppressed_reason"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "requirement_type" => row["requirement_type"] || requirement["requirement_type"],
      "required_authority" =>
        row["required_authority"] || requirement["required_authority"] ||
          policy_escalation["required_authority"],
      "policy_bundle_id" =>
        row["policy_bundle_id"] || requirement["policy_bundle_id"] ||
          policy_decision["policy_bundle_id"],
      "rule_id" =>
        row["rule_id"] || requirement["rule_id"] || rule_match["rule_id"] ||
          policy_escalation["rule_id"],
      "escalation_level" =>
        row["escalation_level"] || rule_match["escalation_level"] ||
          policy_escalation["escalation_level"],
      "escalation_queue" =>
        row["escalation_queue"] || rule_match["escalation_queue"] ||
          policy_escalation["escalation_queue"],
      "escalation_role" =>
        row["escalation_role"] || rule_match["escalation_role"] ||
          policy_escalation["escalation_role"],
      "sla_s" => row["sla_s"] || rule_match["sla_s"] || policy_escalation["sla_s"],
      "reason" => row["reason"],
      "approval_requirements" => row["approval_requirements"],
      "approval_rule_matches" => row["approval_rule_matches"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "source_contact_candidate" => row["source_contact_candidate"],
      "source_contact_suppression" => row["source_contact_suppression"],
      "source_resource_suppression" => row["source_resource_suppression"],
      "source_resource_summary" => row["source_resource_summary"],
      "source_station_calendar_entry" => row["source_station_calendar_entry"],
      "source_station_calendar_overlaps" => row["source_station_calendar_overlaps"],
      "source_policy_decision" => row["source_policy_decision"],
      "source_policy_escalation" => non_empty_map(callbacks, policy_escalation),
      "source_review_row" => row
    }
    |> compact_map(callbacks)
  end

  defp first_approval_requirement(callbacks, row),
    do: invoke(callbacks, :first_approval_requirement, [row])

  defp first_approval_rule_match(callbacks, row),
    do: invoke(callbacks, :first_approval_rule_match, [row])

  defp stringify_keys(value, callbacks), do: invoke(callbacks, :stringify_keys, [value])

  defp preferred_approval_escalation(escalations, row, requirement, callbacks),
    do: invoke(callbacks, :preferred_approval_escalation, [escalations, row, requirement])

  defp source_review_action(callbacks, row),
    do: invoke(callbacks, :source_review_action, [row])

  defp adapter_import_status(callbacks, status, approval_status),
    do: invoke(callbacks, :adapter_import_status, [status, approval_status])

  defp provider_result_artifact_value(callbacks, value),
    do: invoke(callbacks, :provider_result_artifact_value, [value])

  defp non_empty_map(callbacks, value), do: invoke(callbacks, :non_empty_map, [value])

  defp compact_map(value, callbacks), do: invoke(callbacks, :compact_map, [value])

  defp invoke(callbacks, name, args), do: apply(Keyword.fetch!(callbacks, name), args)
end
