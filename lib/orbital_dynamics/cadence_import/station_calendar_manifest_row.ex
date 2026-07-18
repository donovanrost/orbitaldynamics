defmodule OrbitalDynamics.CadenceImport.StationCalendarManifestRow do
  @moduledoc false

  def build(row, rank, callbacks) when is_list(callbacks) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")

    %{
      "id" => "cadence_import:station_calendar:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_station_calendar",
      "import_status" => adapter_import_status(callbacks, "present", approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(callbacks, row),
      "branch_id" => row["branch_id"],
      "subject_id" => row["subject_id"],
      "contact_id" => row["contact_id"],
      "scenario_id" => row["scenario_id"],
      "activity_type" => row["activity_type"],
      "direction" => row["direction"],
      "ground_station_id" => row["ground_station_id"],
      "starts_at_s" => row["starts_at_s"],
      "ends_at_s" => row["ends_at_s"],
      "contact_success" => row["contact_success"],
      "contact_success_factor" => row["contact_success_factor"],
      "contact_success_factor_source" => row["contact_success_factor_source"],
      "command_success" => row["command_success"],
      "contact_result" => provider_result_artifact_value(callbacks, row["contact_result"]),
      "command_result" => provider_result_artifact_value(callbacks, row["command_result"]),
      "command_success_factor" => row["command_success_factor"],
      "command_success_factor_source" => row["command_success_factor_source"],
      "station_calendar_entry_id" => row["station_calendar_entry_id"],
      "station_calendar_provider_id" => row["station_calendar_provider_id"],
      "station_calendar_provider_entry_id" => row["station_calendar_provider_entry_id"],
      "station_calendar_directions" => row["station_calendar_directions"],
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
      "station_calendar_trust_boundary_status" => row["station_calendar_trust_boundary_status"],
      "invalid_feedback_confidence" => row["invalid_feedback_confidence"],
      "invalid_feedback_confidence_reason" => row["invalid_feedback_confidence_reason"],
      "source_contact_candidate" => row["source_contact_candidate"],
      "trust_boundary" => row["trust_boundary"],
      "status" => row["status"],
      "station_availability" => row["station_availability"],
      "capacity_fraction" => row["capacity_fraction"],
      "station_contention_status" => row["station_contention_status"],
      "station_reservation_id" => row["station_reservation_id"],
      "station_reservation_expires_at_s" => row["station_reservation_expires_at_s"],
      "station_reserved_by" => row["station_reserved_by"],
      "station_reservation_status" => row["station_reservation_status"],
      "station_reservation_match_status" => row["station_reservation_match_status"],
      "station_reservation_hold_import_status" => row["station_reservation_hold_import_status"],
      "station_reservation_hold_import_readiness_summary_model" =>
        row["station_reservation_hold_import_readiness_summary_model"],
      "station_reservation_hold_import_readiness_source" =>
        row["station_reservation_hold_import_readiness_source"],
      "station_reservation_hold_import_readiness_source_artifact_type" =>
        row["station_reservation_hold_import_readiness_source_artifact_type"],
      "station_reservation_hold_import_readiness_status" =>
        row["station_reservation_hold_import_readiness_status"],
      "station_reservation_hold_import_classification" =>
        row["station_reservation_hold_import_classification"],
      "station_reservation_hold_count" => row["station_reservation_hold_count"],
      "station_reservation_hold_ids" => row["station_reservation_hold_ids"],
      "station_reservation_hold_ids_by_import_status" =>
        row["station_reservation_hold_ids_by_import_status"],
      "station_reservation_hold_ids_by_required_import_action" =>
        row["station_reservation_hold_ids_by_required_import_action"],
      "station_reservation_hold_ids_by_direction" =>
        row["station_reservation_hold_ids_by_direction"],
      "station_reservation_hold_ids_by_direction_and_ground_station_id" =>
        row["station_reservation_hold_ids_by_direction_and_ground_station_id"],
      "station_reservation_hold_contact_ids_by_import_status" =>
        row["station_reservation_hold_contact_ids_by_import_status"],
      "station_reservation_hold_contact_ids_by_expiration_status" =>
        row["station_reservation_hold_contact_ids_by_expiration_status"],
      "station_reservation_hold_contact_ids_by_direction" =>
        row["station_reservation_hold_contact_ids_by_direction"],
      "station_reservation_hold_contact_ids_by_direction_and_ground_station_id" =>
        row["station_reservation_hold_contact_ids_by_direction_and_ground_station_id"],
      "station_reservation_hold_import_status_counts" =>
        row["station_reservation_hold_import_status_counts"],
      "station_reservation_hold_required_import_action_counts" =>
        row["station_reservation_hold_required_import_action_counts"],
      "station_reservation_hold_import_execution_boundary" =>
        row["station_reservation_hold_import_execution_boundary"],
      "station_reservation_hold_provider_write" => row["station_reservation_hold_provider_write"],
      "station_reservation_hold_cadence_write" => row["station_reservation_hold_cadence_write"],
      "station_reservation_hold_reservation_acceptance" =>
        row["station_reservation_hold_reservation_acceptance"],
      "source_station_reservation_hold_import_readiness_summary" =>
        row["source_station_reservation_hold_import_readiness_summary"],
      "provider_calendar_contention_status" => row["provider_calendar_contention_status"],
      "provider_calendar_contention_group_id" => row["provider_calendar_contention_group_id"],
      "provider_calendar_contention_entry_count" =>
        row["provider_calendar_contention_entry_count"],
      "provider_calendar_contention_entry_ids" => row["provider_calendar_contention_entry_ids"],
      "provider_calendar_contention_provider_ids" =>
        row["provider_calendar_contention_provider_ids"],
      "provider_calendar_contention_provider_entry_ids" =>
        row["provider_calendar_contention_provider_entry_ids"],
      "provider_calendar_contention_availabilities" =>
        row["provider_calendar_contention_availabilities"],
      "provider_calendar_contention_directions" => row["provider_calendar_contention_directions"],
      "provider_calendar_contention_reservation_ids" =>
        row["provider_calendar_contention_reservation_ids"],
      "provider_calendar_contention_reserved_by" =>
        row["provider_calendar_contention_reserved_by"],
      "provider_calendar_contention_reservation_statuses" =>
        row["provider_calendar_contention_reservation_statuses"],
      "provider_calendar_contention_reservation_expires_at_s" =>
        row["provider_calendar_contention_reservation_expires_at_s"],
      "provider_calendar_contention_trust_boundary_statuses" =>
        row["provider_calendar_contention_trust_boundary_statuses"],
      "provider_calendar_contention_overlap_pairs" =>
        row["provider_calendar_contention_overlap_pairs"],
      "base_station_calendar_row_id" => row["base_station_calendar_row_id"],
      "duplicate_station_calendar_row_id_collision" =>
        row["duplicate_station_calendar_row_id_collision"],
      "duplicate_station_calendar_row_index" => row["duplicate_station_calendar_row_index"],
      "duplicate_station_calendar_row_count" => row["duplicate_station_calendar_row_count"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "operator_action_reason" => row["operator_action_reason"],
      "approval_requirements" => row["approval_requirements"],
      "approval_rule_matches" => row["approval_rule_matches"],
      "escalation_level" => row["escalation_level"],
      "escalation_queue" => row["escalation_queue"],
      "escalation_role" => row["escalation_role"],
      "required_authority" => row["required_authority"],
      "sla_s" => row["sla_s"],
      "source_policy_escalation" => row["source_policy_escalation"],
      "source_policy_decision" => row["source_policy_decision"],
      "cadence_import_status" => "not_applicable",
      "has_cadence_import" => false,
      "source_station_calendar_entry" => row["source_station_calendar_entry"],
      "source_station_calendar_overlaps" => row["source_station_calendar_overlaps"],
      "source_station_calendar_provider_contention" =>
        row["source_station_calendar_provider_contention"],
      "source_station_calendar_review" => row["source_station_calendar_review"],
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
