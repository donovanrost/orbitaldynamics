defmodule OrbitalDynamics.CadenceImport.CommandWindowManifestRow do
  @moduledoc false

  def build(row, rank, callbacks) when is_list(callbacks) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "not_applicable")

    %{
      "id" => "cadence_import:command_window:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_command_window",
      "import_status" => adapter_import_status(callbacks, import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(callbacks, row),
      "subject_id" => row["subject_id"],
      "branch_id" => row["branch_id"],
      "activity_id" => row["activity_id"],
      "activity_type" => row["activity_type"],
      "timeline_id" => row["timeline_id"],
      "scenario_id" => row["scenario_id"],
      "window_type" => row["window_type"],
      "direction" => row["direction"],
      "ground_station_id" => row["ground_station_id"],
      "starts_at_s" => row["starts_at_s"],
      "ends_at_s" => row["ends_at_s"],
      "status" => row["status"],
      "approval_status" => approval_status,
      "locked" => row["locked"],
      "contact_success" => row["contact_success"],
      "command_success" => row["command_success"],
      "contact_result" => provider_result_artifact_value(callbacks, row["contact_result"]),
      "command_result" => provider_result_artifact_value(callbacks, row["command_result"]),
      "command_success_factor" => row["command_success_factor"],
      "command_success_factor_source" => row["command_success_factor_source"],
      "station_availability" => row["station_availability"],
      "capacity_fraction" => row["capacity_fraction"],
      "station_contention_status" => row["station_contention_status"],
      "station_calendar_entry_id" => row["station_calendar_entry_id"],
      "station_calendar_provider_id" => row["station_calendar_provider_id"],
      "station_calendar_provider_entry_id" => row["station_calendar_provider_entry_id"],
      "station_calendar_directions" => row["station_calendar_directions"],
      "station_calendar_status" => row["station_calendar_status"],
      "station_calendar_trust_boundary_status" => row["station_calendar_trust_boundary_status"],
      "trust_boundary" => row["trust_boundary"],
      "provenance" => row["provenance"],
      "source_station_calendar_entry" => row["source_station_calendar_entry"],
      "source_station_calendar_overlaps" => row["source_station_calendar_overlaps"],
      "station_calendar_reservation_overlap_count" =>
        row["station_calendar_reservation_overlap_count"],
      "station_calendar_reservation_ids" => row["station_calendar_reservation_ids"],
      "station_calendar_reserved_by" => row["station_calendar_reserved_by"],
      "station_calendar_reservation_statuses" => row["station_calendar_reservation_statuses"],
      "station_calendar_reservation_expires_at_s" =>
        row["station_calendar_reservation_expires_at_s"],
      "station_reservation_id" => row["station_reservation_id"],
      "station_reservation_expires_at_s" => row["station_reservation_expires_at_s"],
      "station_reserved_by" => row["station_reserved_by"],
      "station_reservation_status" => row["station_reservation_status"],
      "station_reservation_match_status" => row["station_reservation_match_status"],
      "required_operator_action" => row["required_operator_action"],
      "operator_action_reason" => row["operator_action_reason"],
      "superseded_required_operator_action" => row["superseded_required_operator_action"],
      "superseded_operator_action_reason" => row["superseded_operator_action_reason"],
      "timeline_integrity_status" => row["timeline_integrity_status"],
      "timeline_integrity_issue_count" => row["timeline_integrity_issue_count"],
      "timeline_integrity_issue_types" => row["timeline_integrity_issue_types"],
      "timeline_integrity_issues" => row["timeline_integrity_issues"],
      "missing_dependency_activity_ids" => row["missing_dependency_activity_ids"],
      "missing_dependency_timeline_ids" => row["missing_dependency_timeline_ids"],
      "self_dependency_activity_ids" => row["self_dependency_activity_ids"],
      "self_dependency_timeline_ids" => row["self_dependency_timeline_ids"],
      "dependency_cycle_activity_ids" => row["dependency_cycle_activity_ids"],
      "dependency_cycle_timeline_ids" => row["dependency_cycle_timeline_ids"],
      "dependency_order_violation_activity_ids" => row["dependency_order_violation_activity_ids"],
      "dependency_order_violation_timeline_ids" => row["dependency_order_violation_timeline_ids"],
      "exclusivity_violation_activity_ids" => row["exclusivity_violation_activity_ids"],
      "exclusivity_violation_timeline_ids" => row["exclusivity_violation_timeline_ids"],
      "exclusivity_violation_group" => row["exclusivity_violation_group"],
      "execution_boundary" => row["execution_boundary"],
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
      "cadence_import_status" => import_status,
      "cadence_import_type" => row["cadence_import_type"] || "command_window",
      "dependency_activity_ids" => row["dependency_activity_ids"],
      "dependency_timeline_ids" => row["dependency_timeline_ids"],
      "exclusive_with_activity_ids" => row["exclusive_with_activity_ids"],
      "exclusive_with_timeline_ids" => row["exclusive_with_timeline_ids"],
      "has_source_window" => row["has_source_window"],
      "has_cadence_import" => row["has_cadence_import"],
      "source_window_id" => row["source_window_id"],
      "source_window_type" => row["source_window_type"],
      "timeline_identity" => row["timeline_identity"],
      "invalid_activity_input" => row["invalid_activity_input"],
      "invalid_activity_input_reason" => row["invalid_activity_input_reason"],
      "source_activity" => row["source_activity"],
      "import_activity_context" =>
        normalize_provider_result_artifact_fields(
          callbacks,
          row["source_activity_context"] || row["activity_context"]
        ),
      "source_activity_context" =>
        normalize_provider_result_artifact_fields(
          callbacks,
          row["source_activity_context"] || row["activity_context"]
        ),
      "source_command_window" => row["source_command_window"],
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

  defp normalize_provider_result_artifact_fields(callbacks, value),
    do: invoke(callbacks, :normalize_provider_result_artifact_fields, [value])

  defp compact_map(value, callbacks), do: invoke(callbacks, :compact_map, [value])

  defp invoke(callbacks, name, args), do: apply(Keyword.fetch!(callbacks, name), args)
end
