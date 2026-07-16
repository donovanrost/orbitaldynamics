defmodule OrbitalDynamics.OperatorReview.CapabilitiesTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}
  alias OrbitalDynamics.OperatorReview.Capabilities

  test "declares artifact-only operator review capabilities" do
    assert %{
             artifact_contract: "operator_review_package.v1",
             validation_level: :artifact_contract,
             review_types: review_types,
             source_artifact_types: source_artifact_types,
             provider_result_map_value_keys: provider_result_map_value_keys,
             handoff_row_semantics: handoff_row_semantics,
             known_limits: known_limits
           } = OperatorReview.capabilities()

    assert "result_artifact.v1" in source_artifact_types
    assert "operator_review_package.v1" in source_artifact_types
    assert "campaign_repair.v2" in source_artifact_types
    assert "contact_contention_recommendation" in review_types
    assert "contact_contention_review" in review_types
    assert "operational_timeline_review" in review_types
    assert "command_window_review" in review_types
    assert "station_calendar_review" in review_types
    assert "station_reservation_review" in review_types
    assert "link_capacity_review" in review_types
    assert "contact_intent_review" in review_types
    assert "candidate_rejection_review" in review_types
    assert "candidate_diff_review" in review_types
    assert "freshness_review" in review_types
    assert "refresh_budget_review" in review_types
    assert "model_acceptance_review" in review_types
    assert "validation_safety_case_review" in review_types
    assert "realized_feedback" in review_types
    assert "plan_delta_review" in review_types
    assert "approval_requirement" in review_types
    assert "policy_escalation" in review_types
    assert "resource_projection_review" in review_types
    assert "contact_suppression" in review_types
    assert "resource_suppression" in review_types
    assert "timeline_diff_review" in review_types
    assert "timeline_dependency_impact_review" in review_types
    assert "timeline_publication_review" in review_types
    assert "timeline_activity_precondition_review" in review_types
    assert "timeline_lifecycle_state_review" in review_types
    assert "timeline_activity_state.v1" in source_artifact_types
    assert "maneuver_review" in review_types
    assert "risk_explanation" in review_types
    assert "strategy_tradeoff" in review_types
    assert "score_term_review" in review_types
    assert "objective_tradeoff_review" in review_types
    assert "ranking_comparison_review" in review_types
    assert "pareto_frontier_review" in review_types
    assert "constraint_review" in review_types
    assert "objective_satisfaction_review" in review_types
    assert "schema_validation_review" in review_types
    assert "execution_review" in review_types
    assert "operational_readiness_review" in review_types
    assert "quality_gate_review" in review_types
    assert "resource_projection_flow_summary.v1" in source_artifact_types
    assert "contact_allocation_capacity_pack_summary.v1" in source_artifact_types
    assert "contact_allocation_reservation_conflict_summary.v1" in source_artifact_types
    assert "result" in provider_result_map_value_keys
    assert "provider_status" in provider_result_map_value_keys
    assert "provider_outcome" in provider_result_map_value_keys
    assert "diagnostics" in provider_result_map_value_keys
    assert :schema_validation_review_rows in handoff_row_semantics
    assert :schema_validation_issue_context in handoff_row_semantics
    assert :schema_validation_batch_nested_report_context in handoff_row_semantics
    assert :operational_readiness_summary_rows in handoff_row_semantics
    assert :operational_readiness_gate_rows in handoff_row_semantics
    assert :operational_readiness_resource_summary_context in handoff_row_semantics
    assert :operational_readiness_resource_gate_context in handoff_row_semantics
    assert :operational_readiness_adapter_boundary_context in handoff_row_semantics
    assert :operational_readiness_cadence_import_gate_context in handoff_row_semantics
    assert :quality_gate_review_rows in handoff_row_semantics
    assert :quality_gate_resource_row_context in handoff_row_semantics
    assert :link_capacity_count_handoff_consistency in handoff_row_semantics
    assert :contact_allocation_handoff_consistency in handoff_row_semantics
    assert :command_window_source_handoff_consistency in handoff_row_semantics
    assert :provider_counteroffer_source_handoff_consistency in handoff_row_semantics
    assert :contact_intent_source_handoff_consistency in handoff_row_semantics
    assert :station_calendar_source_handoff_consistency in handoff_row_semantics
    assert :provider_calendar_contention_source_handoff_consistency in handoff_row_semantics
    assert :link_capacity_source_handoff_consistency in handoff_row_semantics
    assert :contact_allocation_source_handoff_consistency in handoff_row_semantics
    assert :contact_allocation_capacity_pack_source_handoff_consistency in handoff_row_semantics
    assert :contact_contention_source_handoff_consistency in handoff_row_semantics
    assert :suppression_source_handoff_consistency in handoff_row_semantics
    assert "candidate_rejection_report.v1" in source_artifact_types
    assert "station_reservation_report.v1" in source_artifact_types
    assert "operational_readiness_report.v1" in source_artifact_types
    assert "quality_gate_report.v1" in source_artifact_types
    assert "timeline_diff_summary.v1" in source_artifact_types
    assert "timeline_dependency_impact_summary.v1" in source_artifact_types
    assert "timeline_publication_summary.v1" in source_artifact_types
    assert "timeline_activity_precondition_summary.v1" in source_artifact_types
    assert "timeline_activity_status_state.v1" in source_artifact_types
    assert "timeline_activity_approval_state.v1" in source_artifact_types
    assert "timeline_activity_lifecycle_state.v1" in source_artifact_types
    assert "timeline_lifecycle_state_summary.v1" in source_artifact_types
    assert "timeline_preservation_report.v1" in source_artifact_types
    assert "timeline_preservation_status.v1" in source_artifact_types
    assert "timeline_integrity_report.v1" in source_artifact_types
    assert "timeline_transition_application_summary.v1" in source_artifact_types
    assert "timeline_integrity_review" in review_types
    assert :timeline_diff_summary_review_rows in handoff_row_semantics
    assert :timeline_diff_summary_source_handoff_consistency in handoff_row_semantics
    assert :timeline_dependency_impact_review_rows in handoff_row_semantics
    assert :timeline_dependency_impact_source_handoff_consistency in handoff_row_semantics
    assert :timeline_publication_review_rows in handoff_row_semantics
    assert :timeline_publication_source_handoff_consistency in handoff_row_semantics
    assert :timeline_activity_precondition_review_rows in handoff_row_semantics
    assert :timeline_activity_precondition_source_handoff_consistency in handoff_row_semantics
    assert :timeline_lifecycle_state_review_rows in handoff_row_semantics
    assert :timeline_lifecycle_state_source_handoff_consistency in handoff_row_semantics
    assert :timeline_preservation_review_rows in handoff_row_semantics
    assert :timeline_preservation_source_handoff_consistency in handoff_row_semantics
    assert :timeline_integrity_review_rows in handoff_row_semantics
    assert :timeline_integrity_source_handoff_consistency in handoff_row_semantics
    assert :timeline_transition_application_summary_review_rows in handoff_row_semantics

    assert :timeline_transition_application_summary_source_handoff_consistency in handoff_row_semantics

    assert :no_command_execution in known_limits
    assert :no_external_import in known_limits
    assert Capabilities.model_limits() == Enum.map(known_limits, &Atom.to_string/1)

    assert {:ok, schema} = Schema.json_schema("operator_review_package.v1")

    schema_review_types =
      get_in(schema, ["properties", "rows", "items", "properties", "review_type", "enum"])

    assert MapSet.new(review_types) == MapSet.new(schema_review_types)

    schema_source_artifact_types =
      get_in(schema, ["properties", "source_artifact_type", "enum"])

    assert MapSet.new(source_artifact_types) == MapSet.new(schema_source_artifact_types)

    assert get_in(schema, ["properties", "model", "const"]) ==
             "artifact_only_operator_review_package"
  end
end
