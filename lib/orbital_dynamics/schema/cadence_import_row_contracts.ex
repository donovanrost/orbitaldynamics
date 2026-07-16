defmodule OrbitalDynamics.Schema.CadenceImportRowContracts do
  @moduledoc false

  @required_fields ["id", "rank", "import_action", "import_status"]

  @stable_id_fields [
    "id",
    "activity_id",
    "target_id",
    "source_target_id",
    "source_review_row_id",
    "cadence_import_id",
    "spacecraft_id",
    "policy_bundle_id",
    "rule_id",
    "ground_station_id",
    "station_calendar_entry_id",
    "station_calendar_provider_id",
    "station_calendar_provider_entry_id",
    "first_resource_pressure_activity_id",
    "first_resource_pressure_station_calendar_provider_id",
    "first_resource_pressure_station_calendar_provider_entry_id",
    "first_resource_pressure_source_window_id",
    "replacement_activity_id",
    "replacement_candidate_id",
    "source_window_id",
    "replacement_source_window_id"
  ]

  def validate_import_station_and_target_fields(issues, path, row, capability, callbacks)
      when is_list(callbacks) do
    issues
    |> call(callbacks, :require_fields, [path, row, @required_fields])
    |> call(callbacks, :validate_stable_ids, [path, row, @stable_id_fields])
    |> call(callbacks, :expect_optional_integer, [path, row, "rank"])
    |> call(callbacks, :expect_one_of, [path, row, "import_action", capability.import_actions])
    |> call(callbacks, :expect_one_of, [path, row, "import_status", capability.import_statuses])
    |> call(callbacks, :expect_optional_one_of, [
      path,
      row,
      "cadence_import_status",
      capability.cadence_import_statuses
    ])
    |> call(callbacks, :expect_optional_one_of, [
      path,
      row,
      "source_cadence_import_status",
      capability.cadence_import_statuses
    ])
    |> call(callbacks, :expect_optional_one_of, [
      path,
      row,
      "replacement_cadence_import_status",
      capability.cadence_import_statuses
    ])
    |> call(callbacks, :expect_optional_one_of, [
      path,
      row,
      "contact_intent_gate_status",
      ["auto_approvable", "operator_review_required", "blocked_by_policy"]
    ])
    |> validate_station_calendar_fields(path, row, callbacks)
    |> call(callbacks, :validate_station_calendar_handoff_count_lists, [path, row])
    |> call(callbacks, :validate_contact_allocation_capacity_pack_group, [path, row])
    |> call(callbacks, :validate_contact_allocation_capacity_pack_handoff_matches_source, [
      path,
      row
    ])
    |> call(callbacks, :validate_station_capacity_fraction_fields, [path, row])
    |> call(callbacks, :validate_suppression_duplicate_handoff_row_fields, [path, row])
    |> call(callbacks, :validate_scoped_downlink_context_fields, [path, row])
    |> call(callbacks, :validate_observation_quality_handoff_fields, [path, row])
    |> call(callbacks, :validate_feedback_maneuver_handoff_fields, [path, row])
    |> call(callbacks, :validate_link_handoff_fields, [path, row])
    |> call(callbacks, :validate_resource_availability_variance_fields, [path, row])
    |> call(callbacks, :validate_eclipse_lighting_handoff_fields, [path, row])
    |> call(callbacks, :validate_thermal_handoff_fields, [path, row])
    |> call(callbacks, :validate_branch_event_summary_fields, [path, row])
    |> validate_target_and_candidate_diff_fields(path, row, callbacks)
  end

  def validate_source_context_fields(issues, path, row, callbacks)
      when is_list(callbacks) do
    issues
    |> call(callbacks, :expect_optional_type, [path, row, "source_requirement", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_policy_decision", :map])
    |> call(callbacks, :validate_optional_policy_decision_evidence, [
      "#{path}.source_policy_decision",
      Map.get(row, "source_policy_decision")
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "source_policy_escalation", :map])
    |> call(callbacks, :validate_optional_policy_escalation, [
      path,
      row,
      "source_policy_escalation"
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "source_contact_suppression", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_resource_suppression", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_candidate_rejection", :map])
    |> call(callbacks, :validate_optional_candidate_rejection_source_row, [
      path <> ".source_candidate_rejection",
      Map.get(row, "source_candidate_rejection")
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "source_link_capacity", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_resource_projection", :map])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "source_resource_projection_flow_summary",
      :map
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "source_branch_comparison", :map])
    |> call(callbacks, :validate_optional_branch_comparison_source_row, [
      path <> ".source_branch_comparison",
      Map.get(row, "source_branch_comparison")
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "source_pareto_frontier", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_ranking_comparison", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_command_window", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_maneuver_review", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_timeline_diff", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_contention_group", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_invalid_contact_input", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_station_calendar_review", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_feedback", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_delta", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_quality_gate_row", :map])
    |> call(callbacks, :validate_source_evidence_fields, [path, row])
    |> call(callbacks, :validate_source_operational_readiness_report_handoff_matches, [path, row])
    |> call(callbacks, :validate_source_quality_gate_report_handoff_matches, [path, row])
    |> call(callbacks, :validate_freshness_source_status_matches, [path, row])
    |> call(callbacks, :validate_refresh_budget_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_schema_validation_source_status_matches, [path, row])
    |> call(callbacks, :validate_execution_source_status_matches, [path, row])
    |> validate_source_window_context_fields(path, row, callbacks)
    |> validate_activity_and_timeline_context_fields(path, row, callbacks)
    |> call(callbacks, :validate_cadence_source_review_row, [
      path <> ".source_review_row",
      Map.get(row, "source_review_row")
    ])
    |> call(callbacks, :validate_operational_readiness_resource_context, [path, row])
    |> call(callbacks, :validate_operational_readiness_cadence_import_context, [path, row])
  end

  def validate_handoff_and_timeline_source_fields(issues, path, row, callbacks)
      when is_list(callbacks) do
    issues
    |> call(callbacks, :validate_source_operational_readiness_gate_handoff_matches, [path, row])
    |> call(callbacks, :validate_source_quality_gate_row_handoff_matches, [path, row])
    |> call(callbacks, :validate_source_operational_readiness_report_handoff_matches, [path, row])
    |> call(callbacks, :validate_source_quality_gate_report_handoff_matches, [path, row])
    |> call(callbacks, :validate_resource_projection_battery_handoff_fields, [path, row])
    |> call(callbacks, :validate_resource_projection_remaining_handoff_fields, [path, row])
    |> call(callbacks, :validate_resource_projection_battery_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_resource_projection_count_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_resource_projection_flow_summary_context_matches_source, [
      path,
      row
    ])
    |> call(callbacks, :validate_cadence_source_review_battery_handoff_matches, [path, row])
    |> call(
      callbacks,
      :validate_cadence_source_review_resource_projection_count_handoff_matches,
      [
        path,
        row
      ]
    )
    |> call(
      callbacks,
      :validate_cadence_source_review_resource_projection_context_handoff_matches,
      [
        path,
        row
      ]
    )
    |> call(callbacks, :validate_cadence_source_review_suppression_duplicate_matches, [path, row])
    |> call(callbacks, :validate_suppression_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_contact_contention_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_cadence_source_review_contact_contention_handoff_matches, [
      path,
      row
    ])
    |> call(callbacks, :validate_link_capacity_handoff_count_lists, [path, row])
    |> call(callbacks, :validate_link_capacity_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_cadence_source_review_link_capacity_handoff_matches, [path, row])
    |> call(callbacks, :validate_contact_allocation_handoff_fields, [path, row])
    |> call(callbacks, :validate_contact_allocation_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_cadence_source_review_contact_allocation_handoff_matches, [
      path,
      row
    ])
    |> call(callbacks, :validate_command_window_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_cadence_source_review_command_window_handoff_matches, [path, row])
    |> call(callbacks, :validate_maneuver_review_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_cadence_source_review_maneuver_review_handoff_matches, [
      path,
      row
    ])
    |> call(callbacks, :validate_timeline_diff_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_cadence_source_review_timeline_diff_handoff_matches, [path, row])
    |> call(callbacks, :validate_timeline_transition_application_handoff_matches_source, [
      path,
      row
    ])
    |> call(
      callbacks,
      :validate_cadence_source_review_timeline_transition_application_handoff_matches,
      [
        path,
        row
      ]
    )
    |> call(callbacks, :validate_candidate_rejection_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_cadence_source_review_candidate_rejection_handoff_matches, [
      path,
      row
    ])
    |> call(callbacks, :validate_candidate_diff_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_cadence_source_review_candidate_diff_handoff_matches, [path, row])
    |> call(callbacks, :validate_constraint_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_cadence_source_review_constraint_handoff_matches, [path, row])
    |> call(callbacks, :validate_objective_satisfaction_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_cadence_source_review_objective_satisfaction_handoff_matches, [
      path,
      row
    ])
    |> call(callbacks, :validate_score_term_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_cadence_source_review_score_term_handoff_matches, [path, row])
    |> call(callbacks, :validate_objective_tradeoff_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_cadence_source_review_objective_tradeoff_handoff_matches, [
      path,
      row
    ])
    |> call(callbacks, :validate_approval_requirement_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_cadence_source_review_approval_requirement_handoff_matches, [
      path,
      row
    ])
    |> call(callbacks, :validate_plan_delta_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_cadence_source_review_plan_delta_handoff_matches, [path, row])
    |> call(callbacks, :validate_cadence_source_review_warning_handoff_matches, [path, row])
    |> call(
      callbacks,
      :validate_cadence_source_review_timeline_dependency_impact_handoff_matches,
      [
        path,
        row
      ]
    )
    |> call(callbacks, :validate_cadence_source_review_timeline_publication_handoff_matches, [
      path,
      row
    ])
    |> call(
      callbacks,
      :validate_cadence_source_review_timeline_activity_precondition_handoff_matches,
      [
        path,
        row
      ]
    )
    |> call(callbacks, :validate_cadence_source_review_timeline_lifecycle_state_handoff_matches, [
      path,
      row
    ])
    |> call(callbacks, :validate_cadence_source_review_timeline_preservation_handoff_matches, [
      path,
      row
    ])
    |> call(callbacks, :validate_cadence_source_review_timeline_protection_handoff_matches, [
      path,
      row
    ])
    |> call(callbacks, :validate_cadence_source_review_policy_escalation_handoff_matches, [
      path,
      row
    ])
    |> call(callbacks, :validate_cadence_source_review_freshness_handoff_matches, [path, row])
    |> call(callbacks, :validate_cadence_source_review_refresh_budget_handoff_matches, [path, row])
    |> call(callbacks, :validate_cadence_source_review_schema_validation_handoff_matches, [
      path,
      row
    ])
    |> call(callbacks, :validate_cadence_source_review_execution_handoff_matches, [path, row])
    |> call(callbacks, :validate_cadence_source_review_quality_gate_handoff_matches, [path, row])
    |> call(callbacks, :validate_cadence_source_review_operational_readiness_handoff_matches, [
      path,
      row
    ])
    |> call(callbacks, :validate_risk_explanation_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_cadence_source_review_risk_explanation_handoff_matches, [
      path,
      row
    ])
    |> call(callbacks, :validate_operational_timeline_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_cadence_source_review_operational_timeline_handoff_matches, [
      path,
      row
    ])
    |> call(callbacks, :validate_strategy_recommendation_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_cadence_source_review_strategy_recommendation_handoff_matches, [
      path,
      row
    ])
    |> call(callbacks, :validate_strategy_tradeoff_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_cadence_source_review_strategy_tradeoff_handoff_matches, [
      path,
      row
    ])
    |> call(callbacks, :validate_strategy_branch_comparison_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_ranking_comparison_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_cadence_source_review_ranking_comparison_handoff_matches, [
      path,
      row
    ])
    |> call(callbacks, :validate_pareto_frontier_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_cadence_source_review_pareto_frontier_handoff_matches, [
      path,
      row
    ])
    |> call(callbacks, :validate_realized_feedback_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_cadence_source_review_realized_feedback_handoff_matches, [
      path,
      row
    ])
    |> call(callbacks, :validate_provider_counteroffer_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_cadence_source_review_provider_counteroffer_handoff_matches, [
      path,
      row
    ])
    |> call(callbacks, :validate_contact_intent_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_cadence_source_review_contact_intent_handoff_matches, [path, row])
    |> call(callbacks, :validate_station_calendar_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_cadence_source_review_station_calendar_handoff_matches, [
      path,
      row
    ])
    |> call(callbacks, :validate_provider_calendar_contention_handoff_matches_source, [path, row])
    |> call(
      callbacks,
      :validate_cadence_source_review_provider_calendar_contention_handoff_matches,
      [
        path,
        row
      ]
    )
    |> call(callbacks, :validate_operator_review_row_links, [path, row])
    |> call(callbacks, :validate_contact_allocation_capacity_pack_group, [path, row])
    |> call(callbacks, :validate_contact_allocation_capacity_pack_handoff_matches_source, [
      path,
      row
    ])
    |> call(
      callbacks,
      :validate_cadence_source_review_contact_allocation_capacity_pack_handoff_matches,
      [
        path,
        row
      ]
    )
    |> call(callbacks, :validate_timeline_publication_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_selected_timeline_integrity_fields, [path, row])
    |> validate_timeline_source_fields(path, row, callbacks)
  end

  defp validate_source_window_context_fields(issues, path, row, callbacks) do
    issues
    |> call(callbacks, :expect_optional_type, [path, row, "source_window_id", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "source_window_type", :binary])
    |> call(callbacks, :validate_optional_source_window, [path, row, "source_window"])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "first_resource_pressure_source_window_id",
      :binary
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "first_resource_pressure_source_window_type",
      :binary
    ])
    |> call(callbacks, :validate_optional_source_window, [
      path,
      row,
      "first_resource_pressure_source_window"
    ])
    |> call(callbacks, :validate_nested_id_match, [
      path,
      row,
      "first_resource_pressure_source_window",
      "id",
      "first_resource_pressure_source_window_id",
      "must match first_resource_pressure_source_window_id"
    ])
    |> call(callbacks, :validate_optional_source_window_lineage, [
      path,
      row,
      "source_window_lineage"
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "replacement_candidate_id", :binary])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "replacement_source_window_id",
      :binary
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "replacement_source_window_type",
      :binary
    ])
    |> call(callbacks, :validate_optional_source_window, [
      path,
      row,
      "replacement_source_window"
    ])
    |> call(callbacks, :validate_optional_source_window_lineage, [
      path,
      row,
      "replacement_source_window_lineage"
    ])
  end

  defp validate_activity_and_timeline_context_fields(issues, path, row, callbacks) do
    issues
    |> call(callbacks, :expect_optional_type, [path, row, "source_review_row", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "import_activity_context", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_activity_context", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "realized_activity_context", :map])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "replacement_activity_context",
      :map
    ])
    |> call(callbacks, :validate_optional_activity_context, [
      path,
      row,
      "import_activity_context"
    ])
    |> call(callbacks, :validate_optional_activity_context, [
      path,
      row,
      "source_activity_context"
    ])
    |> call(callbacks, :validate_optional_activity_context, [
      path,
      row,
      "realized_activity_context"
    ])
    |> call(callbacks, :validate_optional_activity_context, [
      path,
      row,
      "replacement_activity_context"
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "timeline_link", :map])
    |> call(callbacks, :validate_optional_timeline_link, [path, row, "timeline_link"])
    |> call(callbacks, :expect_optional_type, [path, row, "source_timeline_identity", :map])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "replacement_timeline_identity",
      :map
    ])
    |> call(callbacks, :validate_optional_timeline_identity, [
      path,
      row,
      "source_timeline_identity"
    ])
    |> call(callbacks, :validate_optional_timeline_identity, [
      path,
      row,
      "replacement_timeline_identity"
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "import_side", :binary])
  end

  defp validate_timeline_source_fields(issues, path, row, callbacks) do
    issues
    |> call(callbacks, :expect_optional_type, [path, row, "source_timeline_diff_summary", :map])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "source_timeline_transition_application_summary",
      :map
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "source_timeline_application", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_timeline_integrity", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_timeline_protection", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_timeline_activity_state", :map])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "source_timeline_lifecycle_state",
      :map
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "source_timeline_activity_precondition_summary",
      :map
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "source_timeline_preservation", :map])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "source_timeline_dependency_impact",
      :map
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "source_timeline_publication_summary",
      :map
    ])
    |> call(callbacks, :validate_optional_timeline_diff_summary_source, [
      path <> ".source_timeline_diff_summary",
      Map.get(row, "source_timeline_diff_summary")
    ])
    |> call(callbacks, :validate_optional_timeline_transition_application_summary_source, [
      path <> ".source_timeline_transition_application_summary",
      Map.get(row, "source_timeline_transition_application_summary")
    ])
    |> call(callbacks, :validate_optional_timeline_transition_application_row, [
      path <> ".source_timeline_application",
      Map.get(row, "source_timeline_application")
    ])
    |> call(callbacks, :validate_optional_timeline_integrity_source_row, [
      path <> ".source_timeline_integrity",
      Map.get(row, "source_timeline_integrity")
    ])
    |> call(callbacks, :validate_optional_timeline_protection_summary, [
      path,
      row,
      "source_timeline_protection"
    ])
    |> call(callbacks, :validate_optional_timeline_activity_state_source, [
      path <> ".source_timeline_activity_state",
      Map.get(row, "source_timeline_activity_state")
    ])
    |> call(callbacks, :validate_optional_timeline_lifecycle_state_source_row, [
      path <> ".source_timeline_lifecycle_state",
      Map.get(row, "source_timeline_lifecycle_state")
    ])
    |> call(callbacks, :validate_optional_timeline_activity_precondition_summary_source, [
      path <> ".source_timeline_activity_precondition_summary",
      Map.get(row, "source_timeline_activity_precondition_summary")
    ])
    |> call(callbacks, :validate_optional_timeline_preservation_source_row, [
      path <> ".source_timeline_preservation",
      Map.get(row, "source_timeline_preservation")
    ])
    |> call(callbacks, :validate_optional_timeline_dependency_impact_source_row, [
      path <> ".source_timeline_dependency_impact",
      Map.get(row, "source_timeline_dependency_impact")
    ])
    |> call(callbacks, :validate_optional_timeline_publication_summary_source, [
      path <> ".source_timeline_publication_summary",
      Map.get(row, "source_timeline_publication_summary")
    ])
  end

  defp validate_station_calendar_fields(issues, path, row, callbacks) do
    issues
    |> call(callbacks, :expect_optional_type, [path, row, "station_calendar_directions", :list])
    |> call(callbacks, :validate_string_list_items, [path, row, "station_calendar_directions"])
    |> call(callbacks, :expect_optional_type, [path, row, "station_calendar_status", :binary])
    |> call(callbacks, :expect_optional_integer, [
      path,
      row,
      "station_calendar_overlap_count"
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "station_calendar_overlap_entry_ids",
      :list
    ])
    |> call(callbacks, :validate_optional_stable_id_list, [
      path,
      row,
      "station_calendar_overlap_entry_ids"
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "station_calendar_overlap_availabilities",
      :list
    ])
    |> call(callbacks, :validate_string_list_items, [
      path,
      row,
      "station_calendar_overlap_availabilities"
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "station_calendar_entry_ambiguous",
      :boolean
    ])
    |> call(callbacks, :expect_optional_integer, [
      path,
      row,
      "station_calendar_ambiguous_entry_count"
    ])
    |> call(callbacks, :expect_field_at_least, [
      path,
      row,
      "station_calendar_ambiguous_entry_count",
      0
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "station_calendar_ambiguous_entry_ids",
      :list
    ])
    |> call(callbacks, :validate_optional_stable_id_list, [
      path,
      row,
      "station_calendar_ambiguous_entry_ids"
    ])
    |> call(callbacks, :expect_optional_integer, [
      path,
      row,
      "station_calendar_reservation_overlap_count"
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "station_calendar_reservation_ids",
      :list
    ])
    |> call(callbacks, :validate_optional_stable_id_list, [
      path,
      row,
      "station_calendar_reservation_ids"
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "station_calendar_reserved_by", :list])
    |> call(callbacks, :validate_string_list_items, [
      path,
      row,
      "station_calendar_reserved_by"
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "station_calendar_reservation_statuses",
      :list
    ])
    |> call(callbacks, :validate_string_list_items, [
      path,
      row,
      "station_calendar_reservation_statuses"
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "station_calendar_reservation_expires_at_s",
      :list
    ])
    |> call(callbacks, :validate_number_list_items, [
      path,
      row,
      "station_calendar_reservation_expires_at_s"
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "station_calendar_trust_boundary_status",
      :binary
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "trust_boundary", :binary])
  end

  defp validate_target_and_candidate_diff_fields(issues, path, row, callbacks) do
    issues
    |> call(callbacks, :expect_optional_type, [path, row, "source_target", :map])
    |> call(callbacks, :expect_optional_number, [path, row, "target_latitude_deg"])
    |> call(callbacks, :expect_optional_number, [path, row, "target_longitude_deg"])
    |> call(callbacks, :expect_optional_number, [path, row, "target_minimum_elevation_deg"])
    |> call(callbacks, :expect_optional_number, [path, row, "target_priority"])
    |> call(callbacks, :expect_optional_type, [path, row, "target_priority_source", :binary])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "target_priority_objective_ids",
      :list
    ])
    |> call(callbacks, :validate_optional_stable_id_list, [
      path,
      row,
      "target_priority_objective_ids"
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "target_priority_objective_type",
      :binary
    ])
    |> call(callbacks, :validate_semantic_change_details, [path, row])
    |> call(callbacks, :validate_candidate_diff_changed_fields, [path, row])
  end

  defp call(issues, callbacks, name, args) do
    apply(require_callback(callbacks, name), [issues | args])
  end

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)
end
