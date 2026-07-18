defmodule OrbitalDynamics.CadenceImport.ContactContentionManifestRow do
  @moduledoc false

  def build(row, rank, callbacks) when is_list(callbacks) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")

    %{
      "id" => "cadence_import:contact_contention:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => contact_contention_import_action(row),
      "import_status" => adapter_import_status(callbacks, "present", approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(callbacks, row),
      "source" => row["source"],
      "subject_id" => row["subject_id"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "resource_scope" => row["resource_scope"],
      "ground_station_id" => row["ground_station_id"],
      "ground_station_ids" => row["ground_station_ids"],
      "spacecraft_id" => row["spacecraft_id"],
      "spacecraft_ids" => row["spacecraft_ids"],
      "starts_at_s" => row["starts_at_s"],
      "ends_at_s" => row["ends_at_s"],
      "direction" => row["direction"],
      "directions" => row["directions"],
      "contact_count" => row["contact_count"],
      "contention_window_s" => row["contention_window_s"],
      "total_contact_duration_s" => row["total_contact_duration_s"],
      "overlap_duration_s" => row["overlap_duration_s"],
      "max_concurrent_contacts" => row["max_concurrent_contacts"],
      "overlap_contact_pair_count" => row["overlap_contact_pair_count"],
      "contact_id" => row["contact_id"],
      "contact_ids" => row["contact_ids"],
      "duplicate_contact_ids" => row["duplicate_contact_ids"],
      "duplicate_contact_id_count" => row["duplicate_contact_id_count"],
      "duplicate_contact_candidate_count" => row["duplicate_contact_candidate_count"],
      "source_contact_candidates" => row["source_contact_candidates"],
      "contact_success" => row["contact_success"],
      "contact_success_factor" => row["contact_success_factor"],
      "contact_success_factor_source" => row["contact_success_factor_source"],
      "command_success" => row["command_success"],
      "contact_result" => provider_result_artifact_value(callbacks, row["contact_result"]),
      "command_result" => provider_result_artifact_value(callbacks, row["command_result"]),
      "command_success_factor" => row["command_success_factor"],
      "command_success_factor_source" => row["command_success_factor_source"],
      "actual_throughput_mb" => row["actual_throughput_mb"],
      "actual_data_rate_throughput_derivations" => row["actual_data_rate_throughput_derivations"],
      "source_window_ids" => row["source_window_ids"],
      "scenario_ids" => row["scenario_ids"],
      "selected_contact_id" => row["selected_contact_id"],
      "selected_contact_ids" => row["selected_contact_ids"],
      "selected_priority" => row["selected_priority"],
      "selected_priority_source" => row["selected_priority_source"],
      "deferred_contact_ids" => row["deferred_contact_ids"],
      "review_contact_ids" => row["review_contact_ids"],
      "deferred_contact_priorities" => row["deferred_contact_priorities"],
      "candidate_count" => row["candidate_count"],
      "selection_reason" => row["selection_reason"],
      "resolution_selection_rule" => row["resolution_selection_rule"],
      "resolution_priority_fields" => row["resolution_priority_fields"],
      "requested_priority_fields" => row["requested_priority_fields"],
      "priority_field_evidence_counts" => row["priority_field_evidence_counts"],
      "priority_fields_without_numeric_evidence_count" =>
        row["priority_fields_without_numeric_evidence_count"],
      "priority_fields_without_numeric_evidence" =>
        row["priority_fields_without_numeric_evidence"],
      "resolution_priority_override_count" => row["resolution_priority_override_count"],
      "resolution_priority_override_contact_ids" =>
        row["resolution_priority_override_contact_ids"],
      "ignored_priority_override_count" => row["ignored_priority_override_count"],
      "ignored_priority_override_keys" => row["ignored_priority_override_keys"],
      "ignored_priority_override_contact_ids" => row["ignored_priority_override_contact_ids"],
      "ignored_priority_override_input" => row["ignored_priority_override_input"],
      "resolution_tie_breakers" => row["resolution_tie_breakers"],
      "requested_selection_rule" => row["requested_selection_rule"],
      "ignored_tie_breakers" => row["ignored_tie_breakers"],
      "ignored_policy_input" => row["ignored_policy_input"],
      "policy_warnings" => row["policy_warnings"],
      "resolution_status" => row["resolution_status"],
      "resolution_issue" => row["resolution_issue"],
      "capacity_pack_required_capacity_fraction" =>
        row["capacity_pack_required_capacity_fraction"],
      "capacity_pack_selected_required_capacity_fraction" =>
        row["capacity_pack_selected_required_capacity_fraction"],
      "capacity_pack_deferred_required_capacity_fraction" =>
        row["capacity_pack_deferred_required_capacity_fraction"],
      "capacity_pack_required_capacity_fraction_by_status" =>
        row["capacity_pack_required_capacity_fraction_by_status"],
      "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
        row["capacity_pack_required_capacity_fraction_by_ground_station_id"],
      "required_capacity_fraction_source_counts" =>
        row["required_capacity_fraction_source_counts"],
      "source_summary_model" => row["source_summary_model"],
      "source_summary_schema_contract" => row["source_summary_schema_contract"],
      "source_summary_source" => row["source_summary_source"],
      "source_artifact_type" => row["source_artifact_type"],
      "schema_contract" => row["schema_contract"],
      "duplicate_contact_candidates" => row["duplicate_contact_candidates"],
      "operator_action_reason" => row["operator_action_reason"],
      "invalid_contact_input" => row["invalid_contact_input"],
      "invalid_contact_input_reason" => row["invalid_contact_input_reason"],
      "requirement_type" => row["requirement_type"],
      "required_authority" => row["required_authority"],
      "policy_bundle_id" => row["policy_bundle_id"],
      "rule_id" => row["rule_id"],
      "escalation_level" => row["escalation_level"],
      "escalation_queue" => row["escalation_queue"],
      "escalation_role" => row["escalation_role"],
      "sla_s" => row["sla_s"],
      "approval_requirements" => row["approval_requirements"],
      "approval_rule_matches" => row["approval_rule_matches"],
      "source_policy_decision" => row["source_policy_decision"],
      "source_policy_escalation" => row["source_policy_escalation"],
      "cadence_import_status" => "not_applicable",
      "has_cadence_import" => false,
      "source_contention_group" => row["source_contention_group"],
      "source_invalid_contact_input" => row["source_invalid_contact_input"],
      "source_contact_contention_resolution_summary" =>
        row["source_contact_contention_resolution_summary"],
      "source_recommendation" => row["source_recommendation"],
      "source_review_row" => row
    }
    |> Map.merge(Map.take(row, station_calendar_context_fields(callbacks)))
    |> compact_map(callbacks)
  end

  defp contact_contention_import_action(%{"review_type" => "contact_contention_recommendation"}),
    do: "review_contact_contention_resolution"

  defp contact_contention_import_action(_row), do: "review_contact_contention"

  defp source_review_action(callbacks, row),
    do: invoke(callbacks, :source_review_action, [row])

  defp adapter_import_status(callbacks, status, approval_status),
    do: invoke(callbacks, :adapter_import_status, [status, approval_status])

  defp provider_result_artifact_value(callbacks, value),
    do: invoke(callbacks, :provider_result_artifact_value, [value])

  defp station_calendar_context_fields(callbacks),
    do: invoke(callbacks, :station_calendar_context_fields, [])

  defp compact_map(value, callbacks), do: invoke(callbacks, :compact_map, [value])

  defp invoke(callbacks, name, args), do: apply(Keyword.fetch!(callbacks, name), args)
end
