defmodule OrbitalDynamics.Validation.ReferenceFixtures do
  @moduledoc false

  alias OrbitalDynamics.Validation.ReferenceFixtures.AcceptedPlanningState
  alias OrbitalDynamics.Validation.ReferenceFixtures.ActivityArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.BenchmarkArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshBase
  alias OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshCapacityFilter
  alias OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshContact
  alias OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshFilterRejection
  alias OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshFreshnessBudget
  alias OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshPlanningFeedback
  alias OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshReadiness
  alias OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshStationAllocation
  alias OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshTimeline
  alias OrbitalDynamics.Validation.ReferenceFixtures.CandidateStateArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.CandidateStrategyArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.CampaignArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.CampaignPlanning
  alias OrbitalDynamics.Validation.ReferenceFixtures.ContactAllocationArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.ContactContentionArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.ContactIntentArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.ContactWindowArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.CoreRunReports
  alias OrbitalDynamics.Validation.ReferenceFixtures.DecisionSupportArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.EnvironmentCapabilities
  alias OrbitalDynamics.Validation.ReferenceFixtures.LinkCapacityArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.ManifestArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.ModelAcceptanceArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.ObjectiveScoringArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.OperationalPlanningArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.OperationalReadinessArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.Orbital
  alias OrbitalDynamics.Validation.ReferenceFixtures.PolicyBundleArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.PolicyDecisions
  alias OrbitalDynamics.Validation.ReferenceFixtures.PolicyEvidenceArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.ProviderCapacityPackArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.QualityGateArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.ResourcePressureHandoffArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.ResourceProjectionArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.ResourceSafetyArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.ResourceSummaryArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.SchemaCompatibilityArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.StateManeuverArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.StationReservationArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.SubsystemModelCapabilities
  alias OrbitalDynamics.Validation.ReferenceFixtures.TimelineActivityStateArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.TimelineHandoffArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.TimelinePreservationArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.TimelineTransitionArtifacts

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
        "operations_capability_count" => 17,
        "validation_family_count" => 2,
        "artifact_contract_count" => 121,
        "artifact_contract_list_count" => 121,
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

  @all_fixtures Orbital.all()
                |> Map.merge(AcceptedPlanningState.all())
                |> Map.merge(ActivityArtifacts.all())
                |> Map.merge(BenchmarkArtifacts.all())
                |> Map.merge(CandidateRefreshBase.all())
                |> Map.merge(CandidateRefreshCapacityFilter.all())
                |> Map.merge(CandidateRefreshContact.all())
                |> Map.merge(CandidateRefreshFilterRejection.all())
                |> Map.merge(CandidateRefreshFreshnessBudget.all())
                |> Map.merge(CandidateRefreshPlanningFeedback.all())
                |> Map.merge(CandidateRefreshReadiness.all())
                |> Map.merge(CandidateRefreshStationAllocation.all())
                |> Map.merge(CandidateRefreshTimeline.all())
                |> Map.merge(CandidateStateArtifacts.all())
                |> Map.merge(CandidateStrategyArtifacts.all())
                |> Map.merge(CampaignArtifacts.all())
                |> Map.merge(CampaignPlanning.all())
                |> Map.merge(ContactAllocationArtifacts.all())
                |> Map.merge(ContactContentionArtifacts.all())
                |> Map.merge(ContactIntentArtifacts.all())
                |> Map.merge(ContactWindowArtifacts.all())
                |> Map.merge(CoreRunReports.all())
                |> Map.merge(DecisionSupportArtifacts.all())
                |> Map.merge(EnvironmentCapabilities.all())
                |> Map.merge(LinkCapacityArtifacts.all())
                |> Map.merge(ManifestArtifacts.all())
                |> Map.merge(ModelAcceptanceArtifacts.all())
                |> Map.merge(ObjectiveScoringArtifacts.all())
                |> Map.merge(OperationalPlanningArtifacts.all())
                |> Map.merge(OperationalReadinessArtifacts.all())
                |> Map.merge(PolicyBundleArtifacts.all())
                |> Map.merge(PolicyDecisions.all())
                |> Map.merge(PolicyEvidenceArtifacts.all())
                |> Map.merge(ProviderCapacityPackArtifacts.all())
                |> Map.merge(QualityGateArtifacts.all())
                |> Map.merge(ResourcePressureHandoffArtifacts.all())
                |> Map.merge(ResourceProjectionArtifacts.all())
                |> Map.merge(ResourceSafetyArtifacts.all())
                |> Map.merge(ResourceSummaryArtifacts.all())
                |> Map.merge(SchemaCompatibilityArtifacts.all())
                |> Map.merge(StateManeuverArtifacts.all())
                |> Map.merge(StationReservationArtifacts.all())
                |> Map.merge(SubsystemModelCapabilities.all())
                |> Map.merge(TimelineActivityStateArtifacts.all())
                |> Map.merge(TimelineHandoffArtifacts.all())
                |> Map.merge(TimelinePreservationArtifacts.all())
                |> Map.merge(TimelineTransitionArtifacts.all())
                |> Map.merge(@fixtures)

  def all, do: @all_fixtures

  def fetch(id) when is_binary(id), do: Map.fetch(@all_fixtures, id)
end
