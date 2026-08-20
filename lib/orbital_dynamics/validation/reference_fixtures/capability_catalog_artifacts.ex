defmodule OrbitalDynamics.Validation.ReferenceFixtures.CapabilityCatalogArtifacts do
  @moduledoc false

  @candidate_refresh_source_report_input_order Enum.join(
                                                 [
                                                   "station_calendar_report",
                                                   "station_calendar_precedence_summary",
                                                   "contact_intent_summary",
                                                   "resource_projection_report",
                                                   "resource_projection_flow_summary",
                                                   "resource_filter_report",
                                                   "resource_filter_summary",
                                                   "contact_filter_report",
                                                   "link_capacity_summary",
                                                   "relay_data_path_summary",
                                                   "timeline_feedback_report",
                                                   "operational_timeline_report",
                                                   "timeline_integrity_report",
                                                   "timeline_activity_precondition_summary",
                                                   "timeline_preservation_report",
                                                   "timeline_diff_report",
                                                   "timeline_diff_summary",
                                                   "timeline_lifecycle_state_summary",
                                                   "timeline_dependency_impact_summary",
                                                   "timeline_publication_summary",
                                                   "timeline_transition_application_report",
                                                   "timeline_transition_application_summary",
                                                   "objective_satisfaction_report",
                                                   "objective_tradeoff_report",
                                                   "score_term_report",
                                                   "constraint_report",
                                                   "candidate_diff_report",
                                                   "candidate_rejection_report",
                                                   "freshness_report",
                                                   "refresh_budget_report",
                                                   "schema_validation_report",
                                                   "schema_validation_batch_report",
                                                   "operational_readiness_report",
                                                   "operational_import_eligibility_summary",
                                                   "operational_readiness_gate_summary",
                                                   "operational_execution_boundary_summary",
                                                   "command_window_report",
                                                   "maneuver_review_report",
                                                   "provider_counteroffer_report",
                                                   "provider_counteroffer_review_summary",
                                                   "provider_counteroffer_import_readiness_summary",
                                                   "provider_counteroffer_plan_impact_summary",
                                                   "contact_allocation_report",
                                                   "contact_allocation_summary",
                                                   "contact_allocation_station_pressure_summary",
                                                   "contact_allocation_reservation_conflict_summary",
                                                   "contact_allocation_capacity_pack_summary",
                                                   "contact_allocation_provider_reservation_request_summary",
                                                   "station_reservation_report",
                                                   "station_reservation_review_summary",
                                                   "station_reservation_hold_summary",
                                                   "station_reservation_hold_import_readiness_summary",
                                                   "contact_contention_report",
                                                   "contact_contention_resolution_report",
                                                   "contact_contention_resolution_summary",
                                                   "link_capacity_report",
                                                   "quality_gate_report",
                                                   "operational_quality_gate_summary",
                                                   "operational_quality_gate_unavailable_resource_summary",
                                                   "operational_quality_gate_operator_training_summary",
                                                   "operational_quality_gate_schema_validation_summary",
                                                   "operational_quality_gate_import_readiness_summary",
                                                   "model_acceptance_report",
                                                   "validation_safety_case_summary"
                                                 ],
                                                 "|"
                                               )

  @fixtures %{
    "fixture.artifact.capability_catalog.v1" => %{
      "id" => "fixture.artifact.capability_catalog.v1",
      "model_id" => "artifact.capability_catalog.v1",
      "reference_case" => "checked-in public capability catalog artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/capability_catalog_v1.json",
        "contract" => "capability_catalog.v1"
      },
      "expected" => %{
        "schema_contract" => "capability_catalog.v1",
        "schema_version" => 1,
        "model" => "public_capability_catalog",
        "top_level_family_count" => 7,
        "planning_capability_count" => 6,
        "operations_capability_count" => 19,
        "validation_family_count" => 2,
        "artifact_contract_count" => 127,
        "artifact_contract_list_count" => 127,
        "compatibility_policy_version" => 1,
        "identity_policy_version" => 1,
        "public_validation_facade_count" => 13,
        "optimizer_model" => "per_spacecraft_greedy_non_overlapping",
        "optimizer_contract" => "optimizer_contract.v1",
        "cadence_import_contract" => "cadence_import_manifest.v1",
        "operational_readiness_contract" => "operational_readiness_report.v1",
        "station_calendar_reservation_contract" => "station_reservation_report.v1",
        "candidate_refresh_input_count" => 81,
        "candidate_refresh_source_report_input_count" => 64,
        "candidate_refresh_source_report_input_order" =>
          @candidate_refresh_source_report_input_order,
        "candidate_refresh_source_report_helper_count" => 40
      },
      "tolerances" => %{
        "schema_version" => 0,
        "top_level_family_count" => 0,
        "planning_capability_count" => 0,
        "operations_capability_count" => 0,
        "validation_family_count" => 0,
        "artifact_contract_count" => 0,
        "artifact_contract_list_count" => 0,
        "compatibility_policy_version" => 0,
        "identity_policy_version" => 0,
        "public_validation_facade_count" => 0,
        "candidate_refresh_input_count" => 0,
        "candidate_refresh_source_report_input_count" => 0,
        "candidate_refresh_source_report_helper_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not full capability certification",
        "checks public catalog counts and key contract routing only"
      ]
    }
  }

  def all, do: @fixtures
end
