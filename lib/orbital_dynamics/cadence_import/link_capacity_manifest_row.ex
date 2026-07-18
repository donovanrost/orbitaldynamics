defmodule OrbitalDynamics.CadenceImport.LinkCapacityManifestRow do
  @moduledoc false

  def build(row, rank, callbacks) when is_list(callbacks) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")

    %{
      "id" => "cadence_import:link_capacity:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_link_capacity",
      "import_status" => adapter_import_status(callbacks, "present", approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(callbacks, row),
      "source" => row["source"],
      "subject_id" => row["subject_id"],
      "branch_id" => row["branch_id"],
      "contact_id" => row["contact_id"],
      "input_role" => row["input_role"],
      "ground_station_id" => row["ground_station_id"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "contact_count" => row["contact_count"],
      "ignored_contact_count" => row["ignored_contact_count"],
      "ignored_contact_ids" => row["ignored_contact_ids"],
      "ignored_contact_reason_counts" => row["ignored_contact_reason_counts"],
      "selected_contact_count" => row["selected_contact_count"],
      "ignored_selected_contact_count" => row["ignored_selected_contact_count"],
      "ignored_selected_contact_ids" => row["ignored_selected_contact_ids"],
      "ignored_selected_contact_reason_counts" => row["ignored_selected_contact_reason_counts"],
      "estimated_throughput_mb" => row["estimated_throughput_mb"],
      "selected_estimated_throughput_mb" => row["selected_estimated_throughput_mb"],
      "capacity_adjusted_throughput_mb" => row["capacity_adjusted_throughput_mb"],
      "selected_capacity_adjusted_throughput_mb" =>
        row["selected_capacity_adjusted_throughput_mb"],
      "unused_capacity_adjusted_throughput_mb" => row["unused_capacity_adjusted_throughput_mb"],
      "selected_capacity_utilization_fraction" => row["selected_capacity_utilization_fraction"],
      "selection_utilization_status" => row["selection_utilization_status"],
      "required_downlink_mb" => row["required_downlink_mb"],
      "required_downlink_contact_count" => row["required_downlink_contact_count"],
      "required_downlink_contact_ids" => row["required_downlink_contact_ids"],
      "downlink_completion_source" => row["downlink_completion_source"],
      "downlink_completion_sources" => row["downlink_completion_sources"],
      "selected_downlink_shortfall_mb" => row["selected_downlink_shortfall_mb"],
      "downlink_requirement_status" => row["downlink_requirement_status"],
      "actual_throughput_mb" => row["actual_throughput_mb"],
      "actual_throughput_contact_count" => row["actual_throughput_contact_count"],
      "actual_throughput_contact_ids" => row["actual_throughput_contact_ids"],
      "actual_data_rate_throughput_derivations" => row["actual_data_rate_throughput_derivations"],
      "actual_completion_fraction" => row["actual_completion_fraction"],
      "actual_completion_contact_count" => row["actual_completion_contact_count"],
      "actual_completion_contact_ids" => row["actual_completion_contact_ids"],
      "actual_downlink_completion_ratio" => row["actual_downlink_completion_ratio"],
      "unmatched_actual_throughput_contact_count" =>
        row["unmatched_actual_throughput_contact_count"],
      "unmatched_actual_throughput_contact_ids" => row["unmatched_actual_throughput_contact_ids"],
      "unmatched_actual_completion_contact_count" =>
        row["unmatched_actual_completion_contact_count"],
      "unmatched_actual_completion_contact_ids" => row["unmatched_actual_completion_contact_ids"],
      "ambiguous_actual_throughput_contact_count" =>
        row["ambiguous_actual_throughput_contact_count"],
      "ambiguous_actual_throughput_contact_ids" => row["ambiguous_actual_throughput_contact_ids"],
      "ambiguous_actual_completion_contact_count" =>
        row["ambiguous_actual_completion_contact_count"],
      "ambiguous_actual_completion_contact_ids" => row["ambiguous_actual_completion_contact_ids"],
      "actual_downlink_shortfall_mb" => row["actual_downlink_shortfall_mb"],
      "actual_downlink_requirement_status" => row["actual_downlink_requirement_status"],
      "contact_success" => row["contact_success"],
      "contact_success_factor" => row["contact_success_factor"],
      "contact_success_factor_source" => row["contact_success_factor_source"],
      "command_success" => row["command_success"],
      "contact_result" => provider_result_artifact_value(callbacks, row["contact_result"]),
      "command_result" => provider_result_artifact_value(callbacks, row["command_result"]),
      "command_success_factor" => row["command_success_factor"],
      "command_success_factor_source" => row["command_success_factor_source"],
      "station_calendar_entry_ids" => row["station_calendar_entry_ids"],
      "station_calendar_provider_ids" => row["station_calendar_provider_ids"],
      "station_calendar_provider_entry_ids" => row["station_calendar_provider_entry_ids"],
      "station_calendar_directions" => row["station_calendar_directions"],
      "station_reservation_ids" => row["station_reservation_ids"],
      "station_reservation_expires_at_s" => row["station_reservation_expires_at_s"],
      "station_reserved_bys" => row["station_reserved_bys"],
      "station_reservation_statuses" => row["station_reservation_statuses"],
      "station_reservation_match_statuses" => row["station_reservation_match_statuses"],
      "capacity_fraction_min" => row["capacity_fraction_min"],
      "capacity_fraction_max" => row["capacity_fraction_max"],
      "contact_ids" => row["contact_ids"],
      "selected_contact_ids" => row["selected_contact_ids"],
      "duplicate_contact_ids" => row["duplicate_contact_ids"],
      "duplicate_contact_candidate_count" => row["duplicate_contact_candidate_count"],
      "ambiguous_selected_contact_ids" => row["ambiguous_selected_contact_ids"],
      "ambiguous_selected_contact_id_count" => row["ambiguous_selected_contact_id_count"],
      "unmatched_selected_contact_ids" => row["unmatched_selected_contact_ids"],
      "unmatched_selected_contact_count" => row["unmatched_selected_contact_count"],
      "invalid_contact_input" => row["invalid_contact_input"],
      "invalid_contact_input_reason" => row["invalid_contact_input_reason"],
      "invalid_policy_required_downlink_station_count" =>
        row["invalid_policy_required_downlink_station_count"],
      "invalid_policy_required_downlink_station_ids" =>
        row["invalid_policy_required_downlink_station_ids"],
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
      "cadence_import_status" => "present",
      "has_cadence_import" => false,
      "source_contact_candidate" => row["source_contact_candidate"],
      "source_link_capacity" => row["source_link_capacity"],
      "source_policy_decision" => row["source_policy_decision"],
      "source_policy_escalation" => row["source_policy_escalation"],
      "source_review_row" => row
    }
    |> compact_map(callbacks)
  end

  defp source_review_action(callbacks, row),
    do: invoke(callbacks, :source_review_action, [row])

  defp adapter_import_status(callbacks, status, approval_status),
    do: invoke(callbacks, :adapter_import_status, [status, approval_status])

  defp provider_result_artifact_value(callbacks, value),
    do: invoke(callbacks, :provider_result_artifact_value, [value])

  defp compact_map(value, callbacks), do: invoke(callbacks, :compact_map, [value])

  defp invoke(callbacks, name, args), do: apply(Keyword.fetch!(callbacks, name), args)
end
