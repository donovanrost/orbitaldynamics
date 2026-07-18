defmodule OrbitalDynamics.CadenceImport.ContactIntentManifestRow do
  @moduledoc false

  def build(row, rank, callbacks) when is_list(callbacks) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")
    has_cadence_import = cadence_import_present?(callbacks, row, import_status)
    requirement = first_approval_requirement(callbacks, row)
    rule_match = first_approval_rule_match(callbacks, row)
    policy_decision = stringify_keys(row["source_policy_decision"] || %{}, callbacks)

    policy_escalation =
      (row["source_policy_escalation"] ||
         preferred_approval_escalation(policy_decision["escalations"], row, %{}, callbacks))
      |> stringify_keys(callbacks)

    %{
      "id" => "cadence_import:contact_intent:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_contact_intent",
      "import_status" => adapter_import_status(callbacks, import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(callbacks, row),
      "subject_id" => row["subject_id"],
      "branch_id" => row["branch_id"],
      "activity_id" => row["activity_id"],
      "contact_id" => row["contact_id"],
      "timeline_id" => row["timeline_id"],
      "scenario_id" => row["scenario_id"],
      "spacecraft_id" => row["spacecraft_id"],
      "activity_type" => row["activity_type"],
      "direction" => row["direction"],
      "ground_station_id" => row["ground_station_id"],
      "starts_at_s" => row["starts_at_s"],
      "ends_at_s" => row["ends_at_s"],
      "estimated_throughput_mb" => row["estimated_throughput_mb"],
      "station_availability" => row["station_availability"],
      "capacity_fraction" => row["capacity_fraction"],
      "capacity_fraction_min" => row["capacity_fraction_min"],
      "capacity_fraction_max" => row["capacity_fraction_max"],
      "required_capacity_fraction" => row["required_capacity_fraction"],
      "required_capacity_fraction_source" => row["required_capacity_fraction_source"],
      "capacity_pack_required_capacity_fraction" =>
        row["capacity_pack_required_capacity_fraction"],
      "capacity_pack_contact_ids" => row["capacity_pack_contact_ids"],
      "contact_ids" => row["contact_ids"],
      "source_summary_model" => row["source_summary_model"],
      "source_summary_schema_contract" => row["source_summary_schema_contract"],
      "source_summary_source" => row["source_summary_source"],
      "source_artifact_type" => row["source_artifact_type"],
      "schema_contract" => row["schema_contract"],
      "station_contention_status" => row["station_contention_status"],
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
      "station_calendar_trust_boundary_status" => row["station_calendar_trust_boundary_status"],
      "trust_boundary" => row["trust_boundary"],
      "provenance" => row["provenance"],
      "source_station_calendar_entry" => row["source_station_calendar_entry"],
      "source_station_calendar_overlaps" => row["source_station_calendar_overlaps"],
      "station_reservation_id" => row["station_reservation_id"],
      "station_reservation_expires_at_s" => row["station_reservation_expires_at_s"],
      "station_reserved_by" => row["station_reserved_by"],
      "station_reservation_status" => row["station_reservation_status"],
      "station_reservation_match_status" => row["station_reservation_match_status"],
      "schedule_conflict_status" => row["schedule_conflict_status"],
      "contact_success" => row["contact_success"],
      "contact_result" => provider_result_artifact_value(callbacks, row["contact_result"]),
      "contact_success_factor" => row["contact_success_factor"],
      "contact_success_factor_source" => row["contact_success_factor_source"],
      "command_success" => row["command_success"],
      "command_result" => provider_result_artifact_value(callbacks, row["command_result"]),
      "command_success_factor" => row["command_success_factor"],
      "command_success_factor_source" => row["command_success_factor_source"],
      "dependency_activity_ids" => row["dependency_activity_ids"],
      "dependency_timeline_ids" => row["dependency_timeline_ids"],
      "exclusive_with_activity_ids" => row["exclusive_with_activity_ids"],
      "exclusive_with_timeline_ids" => row["exclusive_with_timeline_ids"],
      "source_window_id" => row["source_window_id"],
      "invalid_activity_input" => row["invalid_activity_input"],
      "invalid_activity_input_reason" => row["invalid_activity_input_reason"],
      "source_activity" => row["source_activity"],
      "cadence_import_status" => import_status,
      "cadence_import_type" => row["cadence_import_type"],
      "cadence_import_id" => row["cadence_import_id"],
      "cadence_import_contract" => row["cadence_import_contract"],
      "has_cadence_import" => has_cadence_import,
      "contact_intent_gate" => "contact_intent_policy",
      "contact_intent_gate_status" => approval_status,
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "requirement_type" => row["requirement_type"] || requirement["requirement_type"],
      "required_authority" =>
        row["required_authority"] || requirement["required_authority"] ||
          rule_match["required_authority"] || policy_escalation["required_authority"],
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
      "timeline_identity" => row["timeline_identity"],
      "import_activity_context" =>
        normalize_provider_result_artifact_fields(
          callbacks,
          generic_review_activity_context(callbacks, row)
        ),
      "source_policy_decision" => row["source_policy_decision"],
      "source_policy_escalation" => non_empty_map(callbacks, policy_escalation),
      "source_contact_intent_summary" => row["source_contact_intent_summary"],
      "source_contact_intent" => row["source_contact_intent"],
      "source_review_row" => row
    }
    |> compact_map(callbacks)
  end

  defp cadence_import_present?(callbacks, row, status),
    do: invoke(callbacks, :cadence_import_present?, [row, status])

  defp first_approval_requirement(callbacks, row),
    do: invoke(callbacks, :first_approval_requirement, [row])

  defp first_approval_rule_match(callbacks, row),
    do: invoke(callbacks, :first_approval_rule_match, [row])

  defp stringify_keys(value, callbacks), do: invoke(callbacks, :stringify_keys, [value])

  defp preferred_approval_escalation(escalations, row, requirement, callbacks),
    do: invoke(callbacks, :preferred_approval_escalation, [escalations, row, requirement])

  defp source_review_action(callbacks, row), do: invoke(callbacks, :source_review_action, [row])

  defp adapter_import_status(callbacks, status, approval_status),
    do: invoke(callbacks, :adapter_import_status, [status, approval_status])

  defp provider_result_artifact_value(callbacks, value),
    do: invoke(callbacks, :provider_result_artifact_value, [value])

  defp generic_review_activity_context(callbacks, row),
    do: invoke(callbacks, :generic_review_activity_context, [row])

  defp normalize_provider_result_artifact_fields(callbacks, value),
    do: invoke(callbacks, :normalize_provider_result_artifact_fields, [value])

  defp non_empty_map(callbacks, value), do: invoke(callbacks, :non_empty_map, [value])
  defp compact_map(value, callbacks), do: invoke(callbacks, :compact_map, [value])
  defp invoke(callbacks, name, args), do: apply(Keyword.fetch!(callbacks, name), args)
end
