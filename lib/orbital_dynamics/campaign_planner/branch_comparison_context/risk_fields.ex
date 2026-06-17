defmodule OrbitalDynamics.CampaignPlanner.BranchComparisonContext.RiskFields do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.StrategyPressureRisk

  import OrbitalDynamics.CampaignPlanner.BranchComparisonContext.FieldValues

  def fields(risk_indicators) do
    station_reservation_conflict_risks =
      Enum.filter(risk_indicators, fn risk ->
        risk["type"] in ["downlink_completion_gap", "provider_reservation_request_review"] and
          not is_nil(risk["station_reservation_match_status"])
      end)

    station_reservation_expiration_risks =
      Enum.filter(
        risk_indicators,
        &StrategyPressureRisk.station_reservation_expiration_pressure_risk?/1
      )

    operational_readiness_risks =
      Enum.filter(risk_indicators, fn risk ->
        risk["type"] == "operational_readiness_pressure"
      end)

    quality_gate_risks =
      Enum.filter(risk_indicators, fn risk ->
        risk["type"] == "quality_gate_pressure"
      end)

    command_window_risks =
      Enum.filter(risk_indicators, fn risk ->
        risk["type"] == "command_window_pressure"
      end)

    candidate_diff_risks =
      Enum.filter(risk_indicators, fn risk ->
        risk["type"] == "candidate_diff_pressure"
      end)

    timeline_diff_risks =
      Enum.filter(risk_indicators, fn risk ->
        risk["type"] == "timeline_diff_pressure"
      end)

    objective_gap_risks =
      Enum.filter(risk_indicators, fn risk ->
        risk["type"] == "objective_gap_pressure"
      end)

    timeline_feedback_risks =
      Enum.filter(risk_indicators, fn risk ->
        risk["type"] == "timeline_feedback_pressure"
      end)

    operational_timeline_risks =
      Enum.filter(risk_indicators, fn risk ->
        risk["type"] == "operational_timeline_pressure"
      end)

    maneuver_review_risks =
      Enum.filter(risk_indicators, fn risk ->
        risk["type"] == "maneuver_review_pressure"
      end)

    timeline_lifecycle_state_risks =
      Enum.filter(risk_indicators, fn risk ->
        risk["type"] == "timeline_lifecycle_state_review"
      end)

    timeline_activity_lifecycle_state_risks =
      Enum.filter(risk_indicators, fn risk ->
        risk["type"] == "timeline_activity_lifecycle_state_review"
      end)

    timeline_publication_risks =
      Enum.filter(risk_indicators, fn risk ->
        risk["type"] == "timeline_publication_pressure"
      end)

    %{
      "branch_station_reservation_conflict_contact_ids" =>
        branch_event_unique_values(station_reservation_conflict_risks, [
          "contact_id",
          "source_activity_id",
          "source_activity_ids"
        ]),
      "branch_station_reservation_conflict_reservation_ids" =>
        branch_event_unique_values(station_reservation_conflict_risks, [
          "station_reservation_id",
          "reservation_id"
        ]),
      "branch_station_reservation_conflict_match_statuses" =>
        branch_event_unique_values(station_reservation_conflict_risks, [
          "station_reservation_match_status",
          "reservation_match_status"
        ]),
      "branch_station_reservation_expiration_statuses" =>
        branch_event_unique_values(station_reservation_expiration_risks, [
          "station_reservation_expiration_status",
          "station_reservation_expiration_statuses"
        ]),
      "branch_operational_readiness_levels" =>
        branch_event_unique_values(operational_readiness_risks, [
          "readiness_level",
          "readiness_levels"
        ]),
      "branch_operational_readiness_import_classifications" =>
        branch_event_unique_values(operational_readiness_risks, [
          "import_classification",
          "import_classifications"
        ]),
      "branch_operational_readiness_statuses" =>
        branch_event_unique_values(operational_readiness_risks, [
          "operational_readiness_status",
          "operational_readiness_statuses"
        ]),
      "branch_operational_readiness_source_report_paths" =>
        branch_event_unique_values(operational_readiness_risks, "source_report_paths"),
      "branch_operational_readiness_gate_statuses" =>
        branch_event_unique_values(operational_readiness_risks, [
          "readiness_gate_status",
          "gate_statuses"
        ]),
      "branch_operational_readiness_gate_classifications" =>
        branch_event_unique_values(operational_readiness_risks, [
          "readiness_gate_classification",
          "gate_classifications"
        ]),
      "branch_operational_readiness_review_required_gate_ids" =>
        branch_event_unique_values(operational_readiness_risks, "review_required_gate_ids"),
      "branch_operational_readiness_analysis_only_gate_ids" =>
        branch_event_unique_values(operational_readiness_risks, "analysis_only_gate_ids"),
      "branch_operational_readiness_blocked_gate_ids" =>
        branch_event_unique_values(operational_readiness_risks, "blocked_gate_ids"),
      "branch_operational_readiness_non_passed_gate_ids" =>
        branch_event_unique_values(operational_readiness_risks, "non_passed_gate_ids"),
      "branch_quality_gate_readiness_levels" =>
        branch_event_unique_values(quality_gate_risks, [
          "readiness_level",
          "readiness_levels"
        ]),
      "branch_quality_gate_import_classifications" =>
        branch_event_unique_values(quality_gate_risks, [
          "import_classification",
          "import_classifications"
        ]),
      "branch_quality_gate_statuses" =>
        branch_event_unique_values(quality_gate_risks, [
          "quality_gate_status",
          "quality_gate_statuses"
        ]),
      "branch_quality_gate_source_report_paths" =>
        branch_event_unique_values(quality_gate_risks, "source_report_paths"),
      "branch_quality_gate_gate_classifications" =>
        branch_event_unique_values(quality_gate_risks, [
          "gate_classification",
          "gate_classifications"
        ]),
      "branch_quality_gate_review_required_gate_ids" =>
        branch_event_unique_values(quality_gate_risks, "review_required_gate_ids"),
      "branch_quality_gate_analysis_only_gate_ids" =>
        branch_event_unique_values(quality_gate_risks, "analysis_only_gate_ids"),
      "branch_quality_gate_blocked_gate_ids" =>
        branch_event_unique_values(quality_gate_risks, "blocked_gate_ids"),
      "branch_quality_gate_non_passed_gate_ids" =>
        branch_event_unique_values(quality_gate_risks, "non_passed_gate_ids"),
      "branch_quality_gate_review_required_row_ids" =>
        branch_event_unique_values(quality_gate_risks, "review_required_quality_gate_row_ids"),
      "branch_quality_gate_analysis_only_row_ids" =>
        branch_event_unique_values(quality_gate_risks, "analysis_only_quality_gate_row_ids"),
      "branch_quality_gate_blocked_row_ids" =>
        branch_event_unique_values(quality_gate_risks, "blocked_quality_gate_row_ids"),
      "branch_quality_gate_non_passed_row_ids" =>
        branch_event_unique_values(quality_gate_risks, "non_passed_quality_gate_row_ids"),
      "branch_command_window_source_report_paths" =>
        branch_event_unique_values(command_window_risks, "source_report_paths"),
      "branch_command_window_input_keys" =>
        branch_event_unique_values(command_window_risks, "input_keys"),
      "branch_command_window_directions" =>
        branch_event_map_keys(command_window_risks, "direction_counts"),
      "branch_command_window_activity_ids" =>
        branch_event_merged_maps(command_window_risks, "activity_ids_by_direction"),
      "branch_command_window_window_ids" =>
        branch_event_merged_maps(command_window_risks, "window_ids_by_direction"),
      "branch_command_window_required_operator_actions" =>
        branch_event_map_keys(command_window_risks, "required_operator_action_counts"),
      "branch_command_window_trust_boundaries" =>
        branch_event_unique_values(command_window_risks, "trust_boundaries"),
      "branch_candidate_diff_source_report_paths" =>
        branch_event_unique_values(candidate_diff_risks, "source_report_paths"),
      "branch_candidate_diff_reasons" =>
        branch_event_map_keys(candidate_diff_risks, "diff_reason_counts"),
      "branch_candidate_diff_invalidated_reasons" =>
        branch_event_map_keys(candidate_diff_risks, "invalidated_reason_counts"),
      "branch_candidate_diff_semantic_change_reasons" =>
        branch_event_map_keys(candidate_diff_risks, "semantic_change_reason_counts"),
      "branch_candidate_diff_changed_fields" =>
        branch_event_map_keys(candidate_diff_risks, "candidate_diff_changed_field_counts"),
      "branch_candidate_diff_candidate_ids" =>
        branch_event_map_keys(candidate_diff_risks, "candidate_diff_candidate_id_counts"),
      "branch_candidate_diff_ground_station_ids" =>
        branch_event_map_keys(candidate_diff_risks, "candidate_diff_ground_station_counts"),
      "branch_candidate_diff_trust_boundaries" =>
        branch_event_unique_values(candidate_diff_risks, "trust_boundaries"),
      "branch_timeline_diff_source_report_paths" =>
        branch_event_unique_values(timeline_diff_risks, "source_report_paths"),
      "branch_timeline_diff_statuses" =>
        branch_event_map_keys(timeline_diff_risks, "diff_status_counts"),
      "branch_timeline_diff_required_operator_actions" =>
        branch_event_map_keys(timeline_diff_risks, "required_operator_action_counts"),
      "branch_timeline_diff_duplicate_identity_scopes" =>
        branch_event_map_keys(timeline_diff_risks, "duplicate_timeline_identity_scope_counts"),
      "branch_timeline_diff_source_activity_ids" =>
        branch_event_map_keys(timeline_diff_risks, "source_activity_id_counts"),
      "branch_timeline_diff_replacement_activity_ids" =>
        branch_event_map_keys(timeline_diff_risks, "replacement_activity_id_counts"),
      "branch_timeline_diff_trust_boundaries" =>
        branch_event_unique_values(timeline_diff_risks, "trust_boundaries"),
      "branch_objective_gap_contracts" =>
        branch_event_unique_values(objective_gap_risks, "contracts"),
      "branch_objective_gap_source_report_paths" =>
        branch_event_unique_values(objective_gap_risks, "source_report_paths"),
      "branch_objective_gap_score_term_keys" =>
        branch_event_map_keys(objective_gap_risks, "score_term_key_counts"),
      "branch_objective_gap_statuses" =>
        branch_event_map_keys(objective_gap_risks, "objective_satisfaction_status_counts"),
      "branch_objective_gap_objective_types" =>
        branch_event_map_keys(
          objective_gap_risks,
          "objective_satisfaction_objective_type_counts"
        ),
      "branch_objective_gap_ground_station_ids" =>
        branch_event_map_keys(objective_gap_risks, "ground_station_counts"),
      "branch_objective_gap_target_ids" =>
        branch_event_map_keys(objective_gap_risks, "target_counts"),
      "branch_objective_gap_collection_ids" =>
        branch_event_map_keys(objective_gap_risks, "collection_counts"),
      "branch_objective_gap_source_activity_ids" =>
        branch_event_map_keys(objective_gap_risks, "source_activity_id_counts"),
      "branch_objective_gap_trust_boundaries" =>
        branch_event_unique_values(objective_gap_risks, "trust_boundaries"),
      "branch_timeline_feedback_source_report_paths" =>
        branch_event_unique_values(timeline_feedback_risks, "source_report_paths"),
      "branch_timeline_feedback_input_keys" =>
        branch_event_unique_values(timeline_feedback_risks, "input_keys"),
      "branch_timeline_feedback_statuses" =>
        branch_event_map_keys(timeline_feedback_risks, "status_counts"),
      "branch_timeline_feedback_kinds" =>
        branch_event_map_keys(timeline_feedback_risks, "feedback_kind_counts"),
      "branch_timeline_feedback_match_strategies" =>
        branch_event_map_keys(timeline_feedback_risks, "match_strategy_counts"),
      "branch_timeline_feedback_activity_ids" =>
        branch_event_map_keys(timeline_feedback_risks, "activity_id_counts"),
      "branch_timeline_feedback_import_statuses" =>
        branch_event_map_keys(timeline_feedback_risks, "cadence_import_status_counts"),
      "branch_timeline_feedback_trust_boundaries" =>
        branch_event_unique_values(timeline_feedback_risks, "trust_boundaries"),
      "branch_operational_timeline_source_report_paths" =>
        branch_event_unique_values(operational_timeline_risks, "source_report_paths"),
      "branch_operational_timeline_input_keys" =>
        branch_event_unique_values(operational_timeline_risks, "input_keys"),
      "branch_operational_timeline_kinds" =>
        branch_event_map_keys(operational_timeline_risks, "operational_kind_counts"),
      "branch_operational_timeline_activity_ids" =>
        branch_event_map_keys(operational_timeline_risks, "activity_id_counts"),
      "branch_operational_timeline_activity_statuses" =>
        branch_event_map_keys(operational_timeline_risks, "activity_status_counts"),
      "branch_operational_timeline_approval_statuses" =>
        branch_event_map_keys(operational_timeline_risks, "approval_status_counts"),
      "branch_operational_timeline_required_operator_actions" =>
        branch_event_map_keys(operational_timeline_risks, "required_operator_action_counts"),
      "branch_operational_timeline_import_statuses" =>
        branch_event_map_keys(operational_timeline_risks, "cadence_import_status_counts"),
      "branch_operational_timeline_integrity_issue_types" =>
        branch_event_map_keys(operational_timeline_risks, "timeline_integrity_issue_type_counts"),
      "branch_operational_timeline_trust_boundaries" =>
        branch_event_unique_values(operational_timeline_risks, "trust_boundaries"),
      "branch_maneuver_review_source_report_paths" =>
        branch_event_unique_values(maneuver_review_risks, "source_report_paths"),
      "branch_maneuver_review_input_keys" =>
        branch_event_unique_values(maneuver_review_risks, "input_keys"),
      "branch_maneuver_review_maneuver_ids" =>
        branch_event_map_keys(maneuver_review_risks, "maneuver_id_counts"),
      "branch_maneuver_review_required_operator_actions" =>
        branch_event_map_keys(maneuver_review_risks, "required_operator_action_counts"),
      "branch_maneuver_review_trust_boundaries" =>
        branch_event_unique_values(maneuver_review_risks, "trust_boundaries"),
      "branch_timeline_lifecycle_state_review_timeline_ids" =>
        branch_event_unique_values(timeline_lifecycle_state_risks, "review_timeline_ids"),
      "branch_timeline_lifecycle_state_review_activity_ids" =>
        branch_event_unique_values(timeline_lifecycle_state_risks, "review_activity_ids"),
      "branch_timeline_lifecycle_state_invalid_activity_input_ids" =>
        branch_event_unique_values(timeline_lifecycle_state_risks, "invalid_activity_input_ids"),
      "branch_timeline_activity_lifecycle_state_activity_ids" =>
        branch_event_unique_values(timeline_activity_lifecycle_state_risks, [
          "activity_id",
          "activity_ids",
          "action_routing_activity_ids",
          "review_activity_ids"
        ]),
      "branch_timeline_activity_lifecycle_state_timeline_ids" =>
        branch_event_unique_values(timeline_activity_lifecycle_state_risks, [
          "timeline_id",
          "timeline_ids",
          "action_routing_timeline_ids"
        ]),
      "branch_timeline_activity_lifecycle_state_transition_decisions" =>
        branch_event_unique_values(timeline_activity_lifecycle_state_risks, [
          "transition_decision",
          "transition_decisions"
        ]),
      "branch_timeline_activity_lifecycle_state_required_operator_actions" =>
        branch_event_unique_values(timeline_activity_lifecycle_state_risks, [
          "required_operator_action",
          "required_operator_actions",
          "required_operator_action_counts"
        ]),
      "branch_timeline_activity_lifecycle_state_import_actions" =>
        branch_event_unique_values(timeline_activity_lifecycle_state_risks, [
          "import_action",
          "import_actions",
          "import_action_counts"
        ]),
      "branch_timeline_activity_lifecycle_state_status_transition_categories" =>
        branch_event_unique_values(
          timeline_activity_lifecycle_state_risks,
          "status_transition_categories"
        ),
      "branch_timeline_activity_lifecycle_state_approval_transition_categories" =>
        branch_event_unique_values(
          timeline_activity_lifecycle_state_risks,
          "approval_transition_categories"
        ),
      "branch_timeline_publication_ids" =>
        branch_event_unique_values(timeline_publication_risks, "publication_ids"),
      "branch_timeline_publication_source_artifact_ids" =>
        branch_event_unique_values(timeline_publication_risks, "source_artifact_ids"),
      "branch_timeline_publication_invalidated_downstream_product_ids" =>
        branch_event_unique_values(
          timeline_publication_risks,
          "invalidated_downstream_product_ids"
        ),
      "branch_timeline_publication_downstream_invalidation_reasons" =>
        branch_event_unique_values(timeline_publication_risks, "downstream_invalidation_reasons"),
      "branch_timeline_publication_impacted_source_activity_ids" =>
        branch_event_unique_values(timeline_publication_risks, "impacted_source_activity_ids"),
      "branch_timeline_publication_impacted_source_timeline_ids" =>
        branch_event_unique_values(timeline_publication_risks, "impacted_source_timeline_ids"),
      "branch_timeline_publication_dependent_activity_ids" =>
        branch_event_unique_values(timeline_publication_risks, "dependent_activity_ids"),
      "branch_timeline_publication_dependent_timeline_ids" =>
        branch_event_unique_values(timeline_publication_risks, "dependent_timeline_ids"),
      "branch_timeline_publication_changed_fields" =>
        branch_event_unique_values(timeline_publication_risks, "changed_fields"),
      "branch_timeline_publication_changed_timeline_ids" =>
        branch_event_unique_values(timeline_publication_risks, "changed_timeline_ids"),
      "branch_timeline_publication_review_timeline_ids" =>
        branch_event_unique_values(timeline_publication_risks, "review_timeline_ids")
    }
    |> maybe_put_nonempty("branch_station_reservation_conflict_contact_ids")
    |> maybe_put_nonempty("branch_station_reservation_conflict_reservation_ids")
    |> maybe_put_nonempty("branch_station_reservation_conflict_match_statuses")
    |> maybe_put_nonempty("branch_station_reservation_expiration_statuses")
    |> maybe_put_nonempty("branch_operational_readiness_levels")
    |> maybe_put_nonempty("branch_operational_readiness_import_classifications")
    |> maybe_put_nonempty("branch_operational_readiness_statuses")
    |> maybe_put_nonempty("branch_operational_readiness_source_report_paths")
    |> maybe_put_nonempty("branch_operational_readiness_gate_statuses")
    |> maybe_put_nonempty("branch_operational_readiness_gate_classifications")
    |> maybe_put_nonempty("branch_operational_readiness_review_required_gate_ids")
    |> maybe_put_nonempty("branch_operational_readiness_analysis_only_gate_ids")
    |> maybe_put_nonempty("branch_operational_readiness_blocked_gate_ids")
    |> maybe_put_nonempty("branch_operational_readiness_non_passed_gate_ids")
    |> maybe_put_nonempty("branch_quality_gate_readiness_levels")
    |> maybe_put_nonempty("branch_quality_gate_import_classifications")
    |> maybe_put_nonempty("branch_quality_gate_statuses")
    |> maybe_put_nonempty("branch_quality_gate_source_report_paths")
    |> maybe_put_nonempty("branch_quality_gate_gate_classifications")
    |> maybe_put_nonempty("branch_quality_gate_review_required_gate_ids")
    |> maybe_put_nonempty("branch_quality_gate_analysis_only_gate_ids")
    |> maybe_put_nonempty("branch_quality_gate_blocked_gate_ids")
    |> maybe_put_nonempty("branch_quality_gate_non_passed_gate_ids")
    |> maybe_put_nonempty("branch_quality_gate_review_required_row_ids")
    |> maybe_put_nonempty("branch_quality_gate_analysis_only_row_ids")
    |> maybe_put_nonempty("branch_quality_gate_blocked_row_ids")
    |> maybe_put_nonempty("branch_quality_gate_non_passed_row_ids")
    |> maybe_put_nonempty("branch_command_window_source_report_paths")
    |> maybe_put_nonempty("branch_command_window_input_keys")
    |> maybe_put_nonempty("branch_command_window_directions")
    |> maybe_put_nonempty("branch_command_window_activity_ids")
    |> maybe_put_nonempty("branch_command_window_window_ids")
    |> maybe_put_nonempty("branch_command_window_required_operator_actions")
    |> maybe_put_nonempty("branch_command_window_trust_boundaries")
    |> maybe_put_nonempty("branch_candidate_diff_source_report_paths")
    |> maybe_put_nonempty("branch_candidate_diff_reasons")
    |> maybe_put_nonempty("branch_candidate_diff_invalidated_reasons")
    |> maybe_put_nonempty("branch_candidate_diff_semantic_change_reasons")
    |> maybe_put_nonempty("branch_candidate_diff_changed_fields")
    |> maybe_put_nonempty("branch_candidate_diff_candidate_ids")
    |> maybe_put_nonempty("branch_candidate_diff_ground_station_ids")
    |> maybe_put_nonempty("branch_candidate_diff_trust_boundaries")
    |> maybe_put_nonempty("branch_timeline_diff_source_report_paths")
    |> maybe_put_nonempty("branch_timeline_diff_statuses")
    |> maybe_put_nonempty("branch_timeline_diff_required_operator_actions")
    |> maybe_put_nonempty("branch_timeline_diff_duplicate_identity_scopes")
    |> maybe_put_nonempty("branch_timeline_diff_source_activity_ids")
    |> maybe_put_nonempty("branch_timeline_diff_replacement_activity_ids")
    |> maybe_put_nonempty("branch_timeline_diff_trust_boundaries")
    |> maybe_put_nonempty("branch_objective_gap_contracts")
    |> maybe_put_nonempty("branch_objective_gap_source_report_paths")
    |> maybe_put_nonempty("branch_objective_gap_score_term_keys")
    |> maybe_put_nonempty("branch_objective_gap_statuses")
    |> maybe_put_nonempty("branch_objective_gap_objective_types")
    |> maybe_put_nonempty("branch_objective_gap_ground_station_ids")
    |> maybe_put_nonempty("branch_objective_gap_target_ids")
    |> maybe_put_nonempty("branch_objective_gap_collection_ids")
    |> maybe_put_nonempty("branch_objective_gap_source_activity_ids")
    |> maybe_put_nonempty("branch_objective_gap_trust_boundaries")
    |> maybe_put_nonempty("branch_timeline_feedback_source_report_paths")
    |> maybe_put_nonempty("branch_timeline_feedback_input_keys")
    |> maybe_put_nonempty("branch_timeline_feedback_statuses")
    |> maybe_put_nonempty("branch_timeline_feedback_kinds")
    |> maybe_put_nonempty("branch_timeline_feedback_match_strategies")
    |> maybe_put_nonempty("branch_timeline_feedback_activity_ids")
    |> maybe_put_nonempty("branch_timeline_feedback_import_statuses")
    |> maybe_put_nonempty("branch_timeline_feedback_trust_boundaries")
    |> maybe_put_nonempty("branch_operational_timeline_source_report_paths")
    |> maybe_put_nonempty("branch_operational_timeline_input_keys")
    |> maybe_put_nonempty("branch_operational_timeline_kinds")
    |> maybe_put_nonempty("branch_operational_timeline_activity_ids")
    |> maybe_put_nonempty("branch_operational_timeline_activity_statuses")
    |> maybe_put_nonempty("branch_operational_timeline_approval_statuses")
    |> maybe_put_nonempty("branch_operational_timeline_required_operator_actions")
    |> maybe_put_nonempty("branch_operational_timeline_import_statuses")
    |> maybe_put_nonempty("branch_operational_timeline_integrity_issue_types")
    |> maybe_put_nonempty("branch_operational_timeline_trust_boundaries")
    |> maybe_put_nonempty("branch_maneuver_review_source_report_paths")
    |> maybe_put_nonempty("branch_maneuver_review_input_keys")
    |> maybe_put_nonempty("branch_maneuver_review_maneuver_ids")
    |> maybe_put_nonempty("branch_maneuver_review_required_operator_actions")
    |> maybe_put_nonempty("branch_maneuver_review_trust_boundaries")
    |> maybe_put_nonempty("branch_timeline_lifecycle_state_review_timeline_ids")
    |> maybe_put_nonempty("branch_timeline_lifecycle_state_review_activity_ids")
    |> maybe_put_nonempty("branch_timeline_lifecycle_state_invalid_activity_input_ids")
    |> maybe_put_nonempty("branch_timeline_activity_lifecycle_state_activity_ids")
    |> maybe_put_nonempty("branch_timeline_activity_lifecycle_state_timeline_ids")
    |> maybe_put_nonempty("branch_timeline_activity_lifecycle_state_transition_decisions")
    |> maybe_put_nonempty("branch_timeline_activity_lifecycle_state_required_operator_actions")
    |> maybe_put_nonempty("branch_timeline_activity_lifecycle_state_import_actions")
    |> maybe_put_nonempty("branch_timeline_activity_lifecycle_state_status_transition_categories")
    |> maybe_put_nonempty(
      "branch_timeline_activity_lifecycle_state_approval_transition_categories"
    )
    |> maybe_put_nonempty("branch_timeline_publication_ids")
    |> maybe_put_nonempty("branch_timeline_publication_source_artifact_ids")
    |> maybe_put_nonempty("branch_timeline_publication_invalidated_downstream_product_ids")
    |> maybe_put_nonempty("branch_timeline_publication_downstream_invalidation_reasons")
    |> maybe_put_nonempty("branch_timeline_publication_impacted_source_activity_ids")
    |> maybe_put_nonempty("branch_timeline_publication_impacted_source_timeline_ids")
    |> maybe_put_nonempty("branch_timeline_publication_dependent_activity_ids")
    |> maybe_put_nonempty("branch_timeline_publication_dependent_timeline_ids")
    |> maybe_put_nonempty("branch_timeline_publication_changed_fields")
    |> maybe_put_nonempty("branch_timeline_publication_changed_timeline_ids")
    |> maybe_put_nonempty("branch_timeline_publication_review_timeline_ids")
  end
end
