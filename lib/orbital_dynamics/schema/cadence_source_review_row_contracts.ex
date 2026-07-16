defmodule OrbitalDynamics.Schema.CadenceSourceReviewRowContracts do
  @moduledoc false

  @stable_id_fields [
    "spacecraft_id",
    "policy_bundle_id",
    "rule_id",
    "first_resource_pressure_activity_id",
    "source_target_id",
    "source_window_id",
    "replacement_candidate_id",
    "replacement_source_window_id"
  ]

  def validate(issues, _path, nil, _callbacks), do: issues

  def validate(issues, path, %{} = row, callbacks) when is_list(callbacks) do
    capability = OrbitalDynamics.OperationalReadiness.capabilities()

    issues
    |> call(callbacks, :expect_optional_one_of, [
      path,
      row,
      "analysis_mode",
      capability.analysis_modes
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "analysis_mode_source", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "source_quality_gate_row", :map])
    |> call(callbacks, :validate_source_operational_readiness_gate_handoff_matches, [path, row])
    |> call(callbacks, :validate_source_quality_gate_row_handoff_matches, [path, row])
    |> call(callbacks, :validate_source_operational_readiness_report_handoff_matches, [
      path,
      row
    ])
    |> call(callbacks, :validate_source_quality_gate_report_handoff_matches, [path, row])
    |> call(callbacks, :validate_branch_event_summary_fields, [path, row])
    |> call(callbacks, :validate_observation_quality_handoff_fields, [path, row])
    |> call(callbacks, :validate_feedback_maneuver_handoff_fields, [path, row])
    |> call(callbacks, :validate_link_handoff_fields, [path, row])
    |> call(callbacks, :validate_resource_availability_variance_fields, [path, row])
    |> call(callbacks, :validate_completion_fraction_fields, [path, row])
    |> call(callbacks, :validate_eclipse_lighting_handoff_fields, [path, row])
    |> call(callbacks, :validate_thermal_handoff_fields, [path, row])
    |> call(callbacks, :expect_optional_probability, [path, row, "attitude_confidence"])
    |> call(callbacks, :validate_selected_timeline_integrity_fields, [path, row])
    |> call(callbacks, :validate_stable_ids, [path, row, @stable_id_fields])
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
    |> call(callbacks, :validate_optional_timeline_dependency_impact_source_row, [
      path <> ".source_timeline_dependency_impact",
      Map.get(row, "source_timeline_dependency_impact")
    ])
    |> call(callbacks, :validate_optional_timeline_publication_summary_source, [
      path <> ".source_timeline_publication_summary",
      Map.get(row, "source_timeline_publication_summary")
    ])
    |> call(callbacks, :validate_timeline_publication_handoff_matches_source, [path, row])
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
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "source_station_calendar_review",
      :map
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "source_feedback", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_delta", :map])
    |> call(callbacks, :validate_source_evidence_fields, [path, row])
    |> call(callbacks, :validate_freshness_source_status_matches, [path, row])
    |> call(callbacks, :validate_refresh_budget_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_schema_validation_source_status_matches, [path, row])
    |> call(callbacks, :validate_execution_source_status_matches, [path, row])
    |> call(callbacks, :validate_operational_readiness_resource_context, [path, row])
    |> call(callbacks, :validate_resource_projection_battery_handoff_fields, [path, row])
    |> call(callbacks, :validate_resource_projection_remaining_handoff_fields, [path, row])
    |> call(callbacks, :validate_resource_projection_battery_handoff_matches_source, [
      path,
      row
    ])
    |> call(callbacks, :validate_resource_projection_count_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_resource_projection_flow_summary_context_matches_source, [
      path,
      row
    ])
    |> call(callbacks, :validate_link_capacity_handoff_count_lists, [path, row])
    |> call(callbacks, :validate_link_capacity_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_contact_allocation_handoff_fields, [path, row])
    |> call(callbacks, :validate_contact_allocation_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_command_window_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_maneuver_review_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_timeline_diff_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_timeline_transition_application_handoff_matches_source, [
      path,
      row
    ])
    |> call(callbacks, :validate_candidate_rejection_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_candidate_diff_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_constraint_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_objective_satisfaction_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_score_term_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_objective_tradeoff_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_approval_requirement_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_plan_delta_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_risk_explanation_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_operational_timeline_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_strategy_recommendation_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_strategy_tradeoff_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_ranking_comparison_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_pareto_frontier_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_realized_feedback_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_provider_counteroffer_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_contact_intent_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_station_calendar_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_provider_calendar_contention_handoff_matches_source, [
      path,
      row
    ])
    |> call(callbacks, :validate_station_calendar_handoff_count_lists, [path, row])
    |> call(callbacks, :validate_suppression_duplicate_handoff_row_fields, [path, row])
    |> call(callbacks, :validate_suppression_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_contact_contention_handoff_matches_source, [path, row])
    |> call(callbacks, :expect_optional_type, [path, row, "source_window_id", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "source_window_type", :binary])
    |> call(callbacks, :validate_optional_source_window, [path, row, "source_window"])
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
    |> call(callbacks, :validate_optional_source_window, [path, row, "replacement_source_window"])
    |> call(callbacks, :validate_optional_source_window_lineage, [
      path,
      row,
      "replacement_source_window_lineage"
    ])
    |> call(callbacks, :validate_operator_review_row_links, [path, row])
    |> call(callbacks, :validate_contact_allocation_capacity_pack_group, [path, row])
    |> call(callbacks, :validate_contact_allocation_capacity_pack_handoff_matches_source, [
      path,
      row
    ])
    |> call(callbacks, :validate_station_capacity_fraction_fields, [path, row])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "source_timeline_diff_summary",
      :map
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "source_timeline_transition_application_summary",
      :map
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "source_timeline_application", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_timeline_integrity", :map])
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
    |> call(callbacks, :expect_optional_type, [path, row, "source_timeline_protection", :map])
    |> call(callbacks, :validate_optional_timeline_protection_summary, [
      path,
      row,
      "source_timeline_protection"
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "source_timeline_activity_state",
      :map
    ])
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
    |> call(callbacks, :expect_optional_type, [path, row, "source_timeline_preservation", :map])
    |> call(callbacks, :validate_optional_timeline_preservation_source_row, [
      path <> ".source_timeline_preservation",
      Map.get(row, "source_timeline_preservation")
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "import_activity_context", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_activity_context", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "realized_activity_context", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "replacement_activity_context", :map])
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
  end

  def validate(issues, path, _row, callbacks) when is_list(callbacks) do
    [error(callbacks, path, "must be an object") | issues]
  end

  defp call(issues, callbacks, name, args) do
    apply(require_callback(callbacks, name), [issues | args])
  end

  defp error(callbacks, path, message),
    do: apply(require_callback(callbacks, :error), [path, message])

  defp require_callback(callbacks, name) do
    Keyword.fetch!(callbacks, name)
  end
end
