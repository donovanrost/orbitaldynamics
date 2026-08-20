defmodule OrbitalDynamics.ValidationTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Validation

  import OrbitalDynamics.Validation.OrbitalReferenceFixtures,
    only: [
      access_fixture_observations: 0,
      atmospheric_drag_fixture_observations: 0,
      eclipse_fixture_observations: 0,
      ground_track_crossing_fixture_observations: 0,
      j2_fixture_observations: 0,
      j2_drag_convergence_fixture_observations: 0,
      target_visibility_fixture_observations: 0,
      two_body_drag_fixture_observations: 0,
      two_body_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.CampaignArtifactFixtures,
    only: [
      campaign_plan_fixture_observations: 0,
      campaign_repair_fixture_observations: 0,
      campaign_strategy_fixture_observations: 0,
      candidate_refresh_orbit_data_result_artifact_fixture_observations: 0,
      candidate_refresh_result_artifact_fixture_observations: 0,
      ground_track_result_artifact_fixture_observations: 0,
      leo_access_manifest_result_artifact_fixture_observations: 0,
      leo_access_result_artifact_fixture_observations: 0,
      mission_plan_checkout_result_artifact_fixture_observations: 0,
      monte_carlo_result_artifact_fixture_observations: 0,
      raise_apogee_result_artifact_fixture_observations: 0,
      result_artifact_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.PolicyBundleFixtures,
    only: [
      command_contact_policy_bundle_fixture_observations: 0,
      conservative_policy_bundle_fixture_observations: 0,
      contact_command_review_policy_bundle_fixture_observations: 0,
      default_policy_bundle_fixture_observations: 0,
      degraded_payload_guard_policy_bundle_fixture_observations: 0,
      ground_network_policy_bundle_fixture_observations: 0,
      maneuver_authority_policy_bundle_fixture_observations: 0,
      operator_review_queue_policy_bundle_fixture_observations: 0,
      organization_adapter_policy_bundle_fixture_observations: 0,
      policy_bundle_fixture_observations: 0,
      resource_projection_authority_policy_bundle_fixture_observations: 0,
      timeline_protection_policy_bundle_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.ActivityArtifactFixtures,
    only: [
      activity_template_fixture_observations: 0,
      candidate_activity_fixture_observations: 0,
      plan_delta_fixture_observations: 0,
      planned_activity_fixture_observations: 0,
      realized_activity_fixture_observations: 0,
      subsystem_model_capability_fixture_observations: 0,
      subsystem_model_capability_storage_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.ContactWindowFixtures,
    only: [
      contact_intent_fixture_observations: 0,
      contact_intent_summary_fixture_observations: 0,
      refreshed_window_fixture_observations: 0,
      source_window_lineage_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.StateManeuverFixtures,
    only: [
      maneuver_execution_delta_fixture_observations: 0,
      maneuver_recommendation_fixture_observations: 0,
      realized_state_snapshot_fixture_observations: 0,
      remaining_horizon_fixture_observations: 0,
      spacecraft_state_estimate_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.PolicyEvidenceFixtures,
    only: [
      backend_acceptance_policy_fixture_observations: 0,
      validation_check_fixture_observations: 0,
      validation_record_fixture_observations: 0,
      validation_tolerance_policy_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.TimelineActivityStateFixtures,
    only: [
      timeline_activity_approval_state_fixture_observations: 0,
      timeline_activity_lifecycle_state_fixture_observations: 0,
      timeline_activity_precondition_summary_fixture_observations: 0,
      timeline_activity_state_fixture_observations: 0,
      timeline_activity_status_state_fixture_observations: 0,
      timeline_lifecycle_state_summary_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.TimelinePreservationFixtures,
    only: [
      timeline_dependency_impact_summary_fixture_observations: 0,
      timeline_diff_summary_fixture_observations: 0,
      timeline_integrity_report_fixture_observations: 0,
      timeline_preservation_report_fixture_observations: 0,
      timeline_preservation_status_fixture_observations: 0,
      timeline_publication_summary_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.TimelineTransitionFixtures,
    only: [
      timeline_transition_application_report_fixture_observations: 0,
      timeline_transition_application_selected_integrity_fixture_observations: 0,
      timeline_transition_application_selected_integrity_summary_fixture_observations: 0,
      timeline_transition_application_summary_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.TimelineHandoffFixtures,
    only: [
      cadence_import_manifest_fixture_observations: 0,
      timeline_diff_report_fixture_observations: 0,
      timeline_feedback_report_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.OperationalPlanningFixtures,
    only: [
      command_window_report_fixture_observations: 0,
      constraint_report_fixture_observations: 0,
      operational_timeline_report_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.ProviderCapacityPackFixtures,
    only: [
      contact_allocation_capacity_pack_report_fixture_observations: 0,
      contact_allocation_provider_reservation_request_summary_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.ContactContentionFixtures,
    only: [
      contact_contention_cross_station_fixture_observations: 0,
      contact_contention_report_fixture_observations: 0,
      contact_contention_resolution_report_fixture_observations: 0,
      contact_contention_resolution_summary_fixture_observations: 0,
      contact_filter_report_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.LinkCapacityFixtures,
    only: [
      link_capacity_report_fixture_observations: 0,
      link_capacity_summary_fixture_observations: 0,
      relay_data_path_summary_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.DecisionSupportFixtures,
    only: [
      maneuver_review_report_fixture_observations: 0,
      monte_carlo_reproducibility_report_fixture_observations: 0,
      pareto_frontier_report_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.ResourceProjectionFixtures,
    only: [
      resource_projection_flow_summary_fixture_observations: 0,
      resource_projection_report_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.ResourceSafetyFixtures,
    only: [
      cadence_import_resource_projection_battery_handoff_fixture_observations: 0,
      operator_review_resource_projection_battery_handoff_fixture_observations: 0,
      resource_filter_stale_margin_fixture_observations: 0,
      resource_projection_battery_handoff_fixture_observations: 0,
      resource_projection_stale_margin_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.ResourceSummaryFixtures,
    only: [
      resource_filter_report_fixture_observations: 0,
      resource_filter_summary_fixture_observations: 0,
      resource_summary_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.ObjectiveScoringFixtures,
    only: [
      objective_satisfaction_report_fixture_observations: 0,
      objective_tradeoff_report_fixture_observations: 0,
      ranking_comparison_report_fixture_observations: 0,
      score_term_report_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.SchemaCompatibilityFixtures,
    only: [
      schema_migration_future_contract_fixture_observations: 0,
      schema_migration_report_fixture_observations: 0,
      schema_validation_batch_report_fixture_observations: 0,
      schema_validation_report_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.StationReservationFixtures,
    only: [
      checked_in_station_calendar_report_fixture_observations: 0,
      provider_counteroffer_import_readiness_summary_fixture_observations: 0,
      provider_counteroffer_plan_impact_summary_fixture_observations: 0,
      provider_counteroffer_report_fixture_observations: 0,
      provider_counteroffer_review_summary_fixture_observations: 0,
      station_calendar_precedence_summary_fixture_observations: 0,
      station_calendar_provider_fixture_observations: 0,
      station_calendar_report_fixture_observations: 0,
      station_reservation_hold_import_readiness_summary_fixture_observations: 0,
      station_reservation_hold_summary_fixture_observations: 0,
      station_reservation_report_fixture_observations: 0,
      station_reservation_review_summary_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.ModelAcceptanceFixtures,
    only: [
      model_acceptance_report_fixture_observations: 0,
      validation_safety_case_summary_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.CandidateRefreshBaseFixtures,
    only: [
      candidate_refresh_fixture_observations: 0,
      candidate_refresh_resource_provenance_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.CandidateRefreshContactReplayFixtures,
    only: [
      candidate_refresh_contact_contention_challenge_fixture_observations: 0,
      candidate_refresh_contact_intent_direction_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.CandidateRefreshReadinessReplayFixtures,
    only: [
      candidate_refresh_candidate_scoped_quality_gate_selection_challenge_fixture_observations: 0,
      candidate_refresh_candidate_scoped_readiness_selection_challenge_fixture_observations: 0,
      candidate_refresh_operational_readiness_fixture_observations: 0,
      candidate_refresh_operational_readiness_selection_challenge_fixture_observations: 0,
      candidate_refresh_quality_gate_fixture_observations: 0,
      candidate_refresh_quality_gate_unavailable_resource_selection_challenge_fixture_observations:
        0,
      candidate_refresh_resource_projection_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.CandidateRefreshTimelineReplayFixtures,
    only: [
      candidate_refresh_timeline_activity_lifecycle_fixture_observations: 0,
      candidate_refresh_timeline_activity_precondition_fixture_observations: 0,
      candidate_refresh_timeline_lifecycle_state_fixture_observations: 0,
      candidate_refresh_timeline_transition_application_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.CandidateRefreshPlanningFeedbackReplayFixtures,
    only: [
      candidate_refresh_constraint_fixture_observations: 0,
      candidate_refresh_objective_gap_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.CandidateRefreshCapacityFilterReplayFixtures,
    only: [
      candidate_refresh_link_capacity_fixture_observations: 0,
      candidate_refresh_resource_filter_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.CandidateRefreshFilterRejectionReplayFixtures,
    only: [
      candidate_refresh_candidate_rejection_fixture_observations: 0,
      candidate_refresh_contact_filter_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.CandidateRefreshFreshnessBudgetReplayFixtures,
    only: [
      candidate_refresh_freshness_fixture_observations: 0,
      candidate_refresh_refresh_budget_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.CandidateRefreshStationAllocationReplayFixtures,
    only: [
      candidate_refresh_contact_allocation_contradiction_fixture_observations: 0,
      candidate_refresh_contact_allocation_resource_selection_challenge_fixture_observations: 0,
      candidate_refresh_station_calendar_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.CandidateStateFixtures,
    only: [
      accepted_planning_state_fixture_observations: 0,
      accepted_planning_state_oem_fixture_observations: 0,
      accepted_planning_state_opm_fixture_observations: 0,
      candidate_diff_row_fixture_observations: 0,
      candidate_rejection_report_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.PlanningInputFixtures,
    only: [
      campaign_request_lint_fixture_observations: 0,
      capability_catalog_fixture_observations: 0,
      environment_model_capability_constant_earth_rotation_fixture_observations: 0,
      environment_model_capability_fixed_sun_fixture_observations: 0,
      environment_provider_capability_constant_earth_rotation_fixture_observations: 0,
      environment_provider_capability_exponential_atmosphere_fixture_observations: 0,
      environment_provider_capability_fixed_sun_fixture_observations: 0,
      environment_provider_capability_tabular_earth_orientation_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.CandidateStrategyFixtures,
    only: [
      branch_comparison_report_fixture_observations: 0,
      invalidated_candidate_fixture_observations: 0,
      optimizer_contract_fixture_observations: 0,
      proposed_contact_fixture_observations: 0,
      strategy_branch_fixture_observations: 0,
      strategy_recommendation_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.BenchmarkFixtures,
    only: [
      distributed_chunk_benchmark_fixture_observations: 0,
      distributed_concurrency_benchmark_fixture_observations: 0,
      distributed_diagnostic_benchmark_fixture_observations: 0,
      distributed_monte_carlo_chunked_benchmark_fixture_observations: 0,
      distributed_monte_carlo_scaling_benchmark_fixture_observations: 0,
      monte_carlo_scaling_benchmark_fixture_observations: 0,
      nx_study_benchmark_fixture_observations: 0,
      study_benchmark_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.CoreRunReportFixtures,
    only: [
      candidate_diff_report_fixture_observations: 0,
      execution_report_fixture_observations: 0,
      freshness_report_fixture_observations: 0,
      refresh_budget_report_fixture_observations: 0,
      validation_reference_report_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.ManifestFixtures,
    only: [
      manifest_field_reference_fixture_observations: 0,
      study_manifest_lint_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.PolicyDecisionFixtures,
    only: [
      approval_requirement_fixture_observations: 0,
      policy_decision_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.ResourcePressureHandoffFixtures,
    only: [
      cadence_import_resource_pressure_fixture_observations: 0,
      operational_readiness_resource_pressure_fixture_observations: 0,
      operator_review_resource_pressure_fixture_observations: 0,
      quality_gate_resource_pressure_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.ContactAllocationFixtures,
    only: [
      contact_allocation_capacity_pack_summary_fixture_observations: 0,
      contact_allocation_report_fixture_observations: 0,
      contact_allocation_reservation_conflict_summary_fixture_observations: 0,
      contact_allocation_station_pressure_summary_fixture_observations: 0,
      contact_allocation_summary_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.OperationalReadinessFixtures,
    only: [
      operational_execution_boundary_summary_fixture_observations: 0,
      operational_import_eligibility_summary_fixture_observations: 0,
      operational_readiness_gate_summary_fixture_observations: 0,
      operational_readiness_report_fixture_observations: 0,
      operator_review_package_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.QualityGateFixtures,
    only: [
      operational_quality_gate_import_readiness_summary_fixture_observations: 0,
      operational_quality_gate_operator_training_summary_fixture_observations: 0,
      operational_quality_gate_schema_validation_summary_fixture_observations: 0,
      operational_quality_gate_summary_fixture_observations: 0,
      operational_quality_gate_unavailable_resource_summary_checked_in_observations: 0,
      operational_quality_gate_unavailable_resource_summary_fixture_observations: 0,
      quality_gate_report_fixture_observations: 0
    ]

  test "fails reference fixture verification outside declared tolerances" do
    observations =
      two_body_fixture_observations()
      |> Map.update!("final_position_km", fn [x, y, z] -> [x + 0.01, y, z] end)

    assert {:ok, %{"status" => "fail", "checks" => checks}} =
             Validation.verify_reference_fixture(
               "fixture.two_body.circular_leo_600s",
               observations
             )

    assert %{"status" => "fail", "max_abs_error" => error, "tolerance" => tolerance} =
             Enum.find(checks, &(&1["field"] == "final_position_km"))

    assert error > tolerance
  end

  test "builds deterministic reference fixture reports" do
    report =
      Validation.reference_fixture_report(%{
        "fixture.event.access.equator_overhead_120s" => access_fixture_observations(),
        "fixture.event.eclipse.cylindrical_shadow_120s" => eclipse_fixture_observations(),
        "fixture.event.target_visibility.equator_overhead_120s" =>
          target_visibility_fixture_observations(),
        "fixture.event.ground_track.latitude_equator_60s" =>
          ground_track_crossing_fixture_observations(),
        "fixture.artifact.accepted_planning_state.oem" =>
          accepted_planning_state_oem_fixture_observations(),
        "fixture.artifact.accepted_planning_state.opm" =>
          accepted_planning_state_opm_fixture_observations(),
        "fixture.artifact.accepted_planning_state.simple" =>
          accepted_planning_state_fixture_observations(),
        "fixture.artifact.activity_template.v1" => activity_template_fixture_observations(),
        "fixture.artifact.approval_requirement.v1" => approval_requirement_fixture_observations(),
        "fixture.artifact.backend_acceptance_policy.v1" =>
          backend_acceptance_policy_fixture_observations(),
        "fixture.artifact.branch_comparison_report.v1" =>
          branch_comparison_report_fixture_observations(),
        "fixture.artifact.cadence_import_manifest.v1" =>
          cadence_import_manifest_fixture_observations(),
        "fixture.artifact.cadence_import_manifest.resource_pressure_v1" =>
          cadence_import_resource_pressure_fixture_observations(),
        "fixture.artifact.cadence_import_manifest.resource_projection_battery_handoff_v1" =>
          cadence_import_resource_projection_battery_handoff_fixture_observations(),
        "fixture.artifact.campaign_plan.leo_constellation_v1" =>
          campaign_plan_fixture_observations(),
        "fixture.artifact.campaign_repair.leo_constellation_v2" =>
          campaign_repair_fixture_observations(),
        "fixture.artifact.campaign_request_lint.v1" =>
          campaign_request_lint_fixture_observations(),
        "fixture.artifact.campaign_strategy.leo_constellation_v3" =>
          campaign_strategy_fixture_observations(),
        "fixture.artifact.capability_catalog.v1" => capability_catalog_fixture_observations(),
        "fixture.artifact.candidate_activity.v1" => candidate_activity_fixture_observations(),
        "fixture.artifact.candidate_diff_report.v1" =>
          candidate_diff_report_fixture_observations(),
        "fixture.artifact.candidate_diff_row.v1" => candidate_diff_row_fixture_observations(),
        "fixture.artifact.candidate_refresh.v1" => candidate_refresh_fixture_observations(),
        "fixture.artifact.candidate_refresh.candidate_rejection_replay" =>
          candidate_refresh_candidate_rejection_fixture_observations(),
        "fixture.artifact.candidate_refresh.candidate_scoped_quality_gate_selection_challenge" =>
          candidate_refresh_candidate_scoped_quality_gate_selection_challenge_fixture_observations(),
        "fixture.artifact.candidate_refresh.candidate_scoped_operational_readiness_selection_challenge" =>
          candidate_refresh_candidate_scoped_readiness_selection_challenge_fixture_observations(),
        "fixture.artifact.candidate_refresh.contact_contention_cross_station_replay" =>
          candidate_refresh_contact_contention_challenge_fixture_observations(),
        "fixture.artifact.candidate_refresh.contact_allocation_contradiction_replay" =>
          candidate_refresh_contact_allocation_contradiction_fixture_observations(),
        "fixture.artifact.candidate_refresh.contact_allocation_resource_selection_challenge" =>
          candidate_refresh_contact_allocation_resource_selection_challenge_fixture_observations(),
        "fixture.artifact.candidate_refresh.contact_filter_replay" =>
          candidate_refresh_contact_filter_fixture_observations(),
        "fixture.artifact.candidate_refresh.contact_intent_direction_replay" =>
          candidate_refresh_contact_intent_direction_fixture_observations(),
        "fixture.artifact.candidate_refresh.constraint_replay" =>
          candidate_refresh_constraint_fixture_observations(),
        "fixture.artifact.candidate_refresh.freshness_replay" =>
          candidate_refresh_freshness_fixture_observations(),
        "fixture.artifact.candidate_refresh.link_capacity_replay" =>
          candidate_refresh_link_capacity_fixture_observations(),
        "fixture.artifact.candidate_refresh.operational_readiness_replay" =>
          candidate_refresh_operational_readiness_fixture_observations(),
        "fixture.artifact.candidate_refresh.operational_readiness_selection_challenge" =>
          candidate_refresh_operational_readiness_selection_challenge_fixture_observations(),
        "fixture.artifact.candidate_refresh.timeline_activity_precondition_replay" =>
          candidate_refresh_timeline_activity_precondition_fixture_observations(),
        "fixture.artifact.candidate_refresh.timeline_activity_lifecycle_replay" =>
          candidate_refresh_timeline_activity_lifecycle_fixture_observations(),
        "fixture.artifact.candidate_refresh.timeline_lifecycle_state_replay" =>
          candidate_refresh_timeline_lifecycle_state_fixture_observations(),
        "fixture.artifact.candidate_refresh.resource_projection_replay" =>
          candidate_refresh_resource_projection_fixture_observations(),
        "fixture.artifact.candidate_refresh.timeline_transition_application_replay" =>
          candidate_refresh_timeline_transition_application_fixture_observations(),
        "fixture.artifact.candidate_refresh.objective_gap_replay" =>
          candidate_refresh_objective_gap_fixture_observations(),
        "fixture.artifact.candidate_refresh.quality_gate_replay" =>
          candidate_refresh_quality_gate_fixture_observations(),
        "fixture.artifact.candidate_refresh.quality_gate_unavailable_resource_selection_challenge" =>
          candidate_refresh_quality_gate_unavailable_resource_selection_challenge_fixture_observations(),
        "fixture.artifact.candidate_refresh.refresh_budget_replay" =>
          candidate_refresh_refresh_budget_fixture_observations(),
        "fixture.artifact.candidate_refresh.resource_filter_replay" =>
          candidate_refresh_resource_filter_fixture_observations(),
        "fixture.artifact.candidate_refresh.station_calendar_replay" =>
          candidate_refresh_station_calendar_fixture_observations(),
        "fixture.artifact.candidate_refresh.resource_provenance_v1" =>
          candidate_refresh_resource_provenance_fixture_observations(),
        "fixture.artifact.candidate_rejection_report.v1" =>
          candidate_rejection_report_fixture_observations(),
        "fixture.artifact.command_window_report.v1" =>
          command_window_report_fixture_observations(),
        "fixture.artifact.constraint_report.v1" => constraint_report_fixture_observations(),
        "fixture.artifact.contact_allocation_report.reduced_capacity_pack" =>
          contact_allocation_capacity_pack_report_fixture_observations(),
        "fixture.artifact.contact_allocation_capacity_pack_summary.v1" =>
          contact_allocation_capacity_pack_summary_fixture_observations(),
        "fixture.artifact.contact_allocation_summary.v1" =>
          contact_allocation_summary_fixture_observations(),
        "fixture.artifact.contact_allocation_report.v1" =>
          contact_allocation_report_fixture_observations(),
        "fixture.artifact.contact_allocation_reservation_conflict_summary.v1" =>
          contact_allocation_reservation_conflict_summary_fixture_observations(),
        "fixture.artifact.contact_allocation_station_pressure_summary.v1" =>
          contact_allocation_station_pressure_summary_fixture_observations(),
        "fixture.artifact.contact_allocation_provider_reservation_request_summary.v1" =>
          contact_allocation_provider_reservation_request_summary_fixture_observations(),
        "fixture.artifact.contact_contention_report.v1" =>
          contact_contention_report_fixture_observations(),
        "fixture.artifact.contact_contention_report.cross_station_spacecraft" =>
          contact_contention_cross_station_fixture_observations(),
        "fixture.artifact.contact_contention_resolution_report.v1" =>
          contact_contention_resolution_report_fixture_observations(),
        "fixture.artifact.contact_contention_resolution_summary.v1" =>
          contact_contention_resolution_summary_fixture_observations(),
        "fixture.artifact.contact_filter_report.v1" =>
          contact_filter_report_fixture_observations(),
        "fixture.artifact.contact_intent.v1" => contact_intent_fixture_observations(),
        "fixture.artifact.contact_intent_summary.v1" =>
          contact_intent_summary_fixture_observations(),
        "fixture.artifact.environment_model_capability.constant_earth_rotation" =>
          environment_model_capability_constant_earth_rotation_fixture_observations(),
        "fixture.artifact.environment_model_capability.fixed_sun" =>
          environment_model_capability_fixed_sun_fixture_observations(),
        "fixture.artifact.environment_provider_capability.constant_earth_rotation" =>
          environment_provider_capability_constant_earth_rotation_fixture_observations(),
        "fixture.artifact.environment_provider_capability.exponential_atmosphere" =>
          environment_provider_capability_exponential_atmosphere_fixture_observations(),
        "fixture.artifact.environment_provider_capability.fixed_sun" =>
          environment_provider_capability_fixed_sun_fixture_observations(),
        "fixture.artifact.environment_provider_capability.tabular_earth_orientation" =>
          environment_provider_capability_tabular_earth_orientation_fixture_observations(),
        "fixture.artifact.execution_report.v1" => execution_report_fixture_observations(),
        "fixture.artifact.freshness_report.v1" => freshness_report_fixture_observations(),
        "fixture.artifact.invalidated_candidate.v1" =>
          invalidated_candidate_fixture_observations(),
        "fixture.artifact.link_capacity_report.v1" => link_capacity_report_fixture_observations(),
        "fixture.artifact.link_capacity_summary.v1" =>
          link_capacity_summary_fixture_observations(),
        "fixture.artifact.relay_data_path_summary.v1" =>
          relay_data_path_summary_fixture_observations(),
        "fixture.artifact.maneuver_execution_delta.v1" =>
          maneuver_execution_delta_fixture_observations(),
        "fixture.artifact.maneuver_review_report.v1" =>
          maneuver_review_report_fixture_observations(),
        "fixture.artifact.maneuver_recommendation.v1" =>
          maneuver_recommendation_fixture_observations(),
        "fixture.artifact.manifest_field_reference.v1" =>
          manifest_field_reference_fixture_observations(),
        "fixture.artifact.model_acceptance_report.operational_import" =>
          model_acceptance_report_fixture_observations(),
        "fixture.artifact.monte_carlo_reproducibility_report.v1" =>
          monte_carlo_reproducibility_report_fixture_observations(),
        "fixture.artifact.objective_satisfaction_report.v1" =>
          objective_satisfaction_report_fixture_observations(),
        "fixture.artifact.objective_tradeoff_report.v1" =>
          objective_tradeoff_report_fixture_observations(),
        "fixture.artifact.ranking_comparison_report.v1" =>
          ranking_comparison_report_fixture_observations(),
        "fixture.artifact.realized_activity.v1" => realized_activity_fixture_observations(),
        "fixture.artifact.realized_state_snapshot.v1" =>
          realized_state_snapshot_fixture_observations(),
        "fixture.artifact.refresh_budget_report.v1" =>
          refresh_budget_report_fixture_observations(),
        "fixture.artifact.refreshed_window.v1" => refreshed_window_fixture_observations(),
        "fixture.artifact.remaining_horizon.v1" => remaining_horizon_fixture_observations(),
        "fixture.artifact.pareto_frontier_report.v1" =>
          pareto_frontier_report_fixture_observations(),
        "fixture.artifact.plan_delta.v1" => plan_delta_fixture_observations(),
        "fixture.artifact.planned_activity.v1" => planned_activity_fixture_observations(),
        "fixture.artifact.policy_bundle.command_contact_authority" =>
          command_contact_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.conservative_ops" =>
          conservative_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.contact_command_review" =>
          contact_command_review_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.default" => default_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.degraded_payload_guard" =>
          degraded_payload_guard_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.ground_network_allocation" =>
          ground_network_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.maneuver_authority" =>
          maneuver_authority_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.operator_review_queue_authority" =>
          operator_review_queue_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.organization_adapter" =>
          organization_adapter_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.resource_projection_authority" =>
          resource_projection_authority_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.timeline_protection" =>
          timeline_protection_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.v1" => policy_bundle_fixture_observations(),
        "fixture.artifact.policy_decision.v1" => policy_decision_fixture_observations(),
        "fixture.artifact.proposed_contact.v1" => proposed_contact_fixture_observations(),
        "fixture.artifact.validation_safety_case_summary.v1" =>
          validation_safety_case_summary_fixture_observations(),
        "fixture.artifact.operator_review_package.v1" =>
          operator_review_package_fixture_observations(),
        "fixture.artifact.operator_review_package.resource_pressure_v1" =>
          operator_review_resource_pressure_fixture_observations(),
        "fixture.artifact.operator_review_package.resource_projection_battery_handoff_v1" =>
          operator_review_resource_projection_battery_handoff_fixture_observations(),
        "fixture.artifact.operational_execution_boundary_summary.v1" =>
          operational_execution_boundary_summary_fixture_observations(),
        "fixture.artifact.operational_import_eligibility_summary.v1" =>
          operational_import_eligibility_summary_fixture_observations(),
        "fixture.artifact.operational_readiness_report.v1" =>
          operational_readiness_report_fixture_observations(),
        "fixture.artifact.operational_readiness_report.resource_pressure_v1" =>
          operational_readiness_resource_pressure_fixture_observations(),
        "fixture.artifact.operational_readiness_gate_summary.v1" =>
          operational_readiness_gate_summary_fixture_observations(),
        "fixture.artifact.operational_quality_gate_summary.v1" =>
          operational_quality_gate_summary_fixture_observations(),
        "fixture.artifact.operational_quality_gate_import_readiness_summary.v1" =>
          operational_quality_gate_import_readiness_summary_fixture_observations(),
        "fixture.artifact.operational_quality_gate_unavailable_resource_summary.v1" =>
          operational_quality_gate_unavailable_resource_summary_fixture_observations(),
        "fixture.artifact.operational_quality_gate_unavailable_resource_summary.resource_projection_v1" =>
          operational_quality_gate_unavailable_resource_summary_checked_in_observations(),
        "fixture.artifact.operational_quality_gate_operator_training_summary.v1" =>
          operational_quality_gate_operator_training_summary_fixture_observations(),
        "fixture.artifact.operational_quality_gate_schema_validation_summary.v1" =>
          operational_quality_gate_schema_validation_summary_fixture_observations(),
        "fixture.artifact.operational_timeline_report.v1" =>
          operational_timeline_report_fixture_observations(),
        "fixture.artifact.optimizer_contract.v1" => optimizer_contract_fixture_observations(),
        "fixture.artifact.provider_counteroffer_import_readiness_summary.v1" =>
          provider_counteroffer_import_readiness_summary_fixture_observations(),
        "fixture.artifact.provider_counteroffer_plan_impact_summary.v1" =>
          provider_counteroffer_plan_impact_summary_fixture_observations(),
        "fixture.artifact.provider_counteroffer_report.v1" =>
          provider_counteroffer_report_fixture_observations(),
        "fixture.artifact.provider_counteroffer_review_summary.v1" =>
          provider_counteroffer_review_summary_fixture_observations(),
        "fixture.artifact.quality_gate_report.v1" => quality_gate_report_fixture_observations(),
        "fixture.artifact.quality_gate_report.resource_pressure_v1" =>
          quality_gate_resource_pressure_fixture_observations(),
        "fixture.artifact.resource_filter_report.v1" =>
          resource_filter_report_fixture_observations(),
        "fixture.artifact.resource_filter_summary.v1" =>
          resource_filter_summary_fixture_observations(),
        "fixture.artifact.resource_filter_report.stale_resource_summary_margins" =>
          resource_filter_stale_margin_fixture_observations(),
        "fixture.artifact.resource_projection_report.v1" =>
          resource_projection_report_fixture_observations(),
        "fixture.artifact.resource_projection_flow_summary.v1" =>
          resource_projection_flow_summary_fixture_observations(),
        "fixture.artifact.resource_projection_report.battery_handoff_v1" =>
          resource_projection_battery_handoff_fixture_observations(),
        "fixture.artifact.resource_projection_report.stale_resource_summary_margins" =>
          resource_projection_stale_margin_fixture_observations(),
        "fixture.artifact.resource_summary.v1" => resource_summary_fixture_observations(),
        "fixture.artifact.result_artifact.candidate_refresh_v1" =>
          candidate_refresh_result_artifact_fixture_observations(),
        "fixture.artifact.result_artifact.candidate_refresh_orbit_data_v1" =>
          candidate_refresh_orbit_data_result_artifact_fixture_observations(),
        "fixture.artifact.result_artifact.ground_track_crossings" =>
          ground_track_result_artifact_fixture_observations(),
        "fixture.artifact.result_artifact.leo_access_demo" =>
          leo_access_result_artifact_fixture_observations(),
        "fixture.artifact.result_artifact.leo_access_demo_manifest" =>
          leo_access_manifest_result_artifact_fixture_observations(),
        "fixture.artifact.result_artifact.leo_constellation_campaign" =>
          result_artifact_fixture_observations(),
        "fixture.artifact.result_artifact.leo_dispersion_monte_carlo" =>
          monte_carlo_result_artifact_fixture_observations(),
        "fixture.artifact.result_artifact.mission_plan_checkout" =>
          mission_plan_checkout_result_artifact_fixture_observations(),
        "fixture.artifact.result_artifact.raise_apogee_search" =>
          raise_apogee_result_artifact_fixture_observations(),
        "fixture.artifact.score_term_report.v1" => score_term_report_fixture_observations(),
        "fixture.artifact.schema_validation_batch_report.v1" =>
          schema_validation_batch_report_fixture_observations(),
        "fixture.artifact.schema_validation_report.v1" =>
          schema_validation_report_fixture_observations(),
        "fixture.artifact.schema_migration_report.deprecated_campaign_plan" =>
          schema_migration_report_fixture_observations(),
        "fixture.artifact.schema_migration_report.future_campaign_plan" =>
          schema_migration_future_contract_fixture_observations(),
        "fixture.artifact.source_window_lineage.v1" =>
          source_window_lineage_fixture_observations(),
        "fixture.artifact.spacecraft_state_estimate.v1" =>
          spacecraft_state_estimate_fixture_observations(),
        "fixture.artifact.station_calendar_precedence_summary.v1" =>
          station_calendar_precedence_summary_fixture_observations(),
        "fixture.artifact.station_calendar_provider.v1" =>
          station_calendar_provider_fixture_observations(),
        "fixture.artifact.station_calendar_report.stale_provider_reservation_hold" =>
          station_calendar_report_fixture_observations(),
        "fixture.artifact.station_reservation_review_summary.v1" =>
          station_reservation_review_summary_fixture_observations(),
        "fixture.artifact.station_reservation_hold_summary.v1" =>
          station_reservation_hold_summary_fixture_observations(),
        "fixture.artifact.station_reservation_hold_import_readiness_summary.v1" =>
          station_reservation_hold_import_readiness_summary_fixture_observations(),
        "fixture.artifact.station_reservation_report.stale_provider_reservation_hold" =>
          station_reservation_report_fixture_observations(),
        "fixture.artifact.station_calendar_report.v1" =>
          checked_in_station_calendar_report_fixture_observations(),
        "fixture.artifact.strategy_branch.v1" => strategy_branch_fixture_observations(),
        "fixture.artifact.strategy_recommendation.v1" =>
          strategy_recommendation_fixture_observations(),
        "fixture.artifact.study_benchmark.distributed_concurrency_sweep" =>
          distributed_concurrency_benchmark_fixture_observations(),
        "fixture.artifact.study_benchmark.distributed_chunk_sweep" =>
          distributed_chunk_benchmark_fixture_observations(),
        "fixture.artifact.study_benchmark.distributed_diagnostic_sweep" =>
          distributed_diagnostic_benchmark_fixture_observations(),
        "fixture.artifact.study_benchmark.distributed_monte_carlo_chunked" =>
          distributed_monte_carlo_chunked_benchmark_fixture_observations(),
        "fixture.artifact.study_benchmark.distributed_monte_carlo_scaling" =>
          distributed_monte_carlo_scaling_benchmark_fixture_observations(),
        "fixture.artifact.study_benchmark.monte_carlo_scaling" =>
          monte_carlo_scaling_benchmark_fixture_observations(),
        "fixture.artifact.study_benchmark.nx_study_benchmark" =>
          nx_study_benchmark_fixture_observations(),
        "fixture.artifact.study_benchmark.v1" => study_benchmark_fixture_observations(),
        "fixture.artifact.study_manifest_lint.v1" => study_manifest_lint_fixture_observations(),
        "fixture.artifact.subsystem_model_capability.battery" =>
          subsystem_model_capability_fixture_observations(),
        "fixture.artifact.subsystem_model_capability.storage" =>
          subsystem_model_capability_storage_fixture_observations(),
        "fixture.artifact.timeline_activity_approval_state.v1" =>
          timeline_activity_approval_state_fixture_observations(),
        "fixture.artifact.timeline_activity_lifecycle_state.v1" =>
          timeline_activity_lifecycle_state_fixture_observations(),
        "fixture.artifact.timeline_activity_precondition_summary.v1" =>
          timeline_activity_precondition_summary_fixture_observations(),
        "fixture.artifact.timeline_activity_state.v1" =>
          timeline_activity_state_fixture_observations(),
        "fixture.artifact.timeline_activity_status_state.v1" =>
          timeline_activity_status_state_fixture_observations(),
        "fixture.artifact.timeline_dependency_impact_summary.v1" =>
          timeline_dependency_impact_summary_fixture_observations(),
        "fixture.artifact.timeline_diff_report.v1" => timeline_diff_report_fixture_observations(),
        "fixture.artifact.timeline_diff_summary.v1" =>
          timeline_diff_summary_fixture_observations(),
        "fixture.artifact.timeline_feedback_report.v1" =>
          timeline_feedback_report_fixture_observations(),
        "fixture.artifact.timeline_integrity_report.v1" =>
          timeline_integrity_report_fixture_observations(),
        "fixture.artifact.timeline_lifecycle_state_summary.v1" =>
          timeline_lifecycle_state_summary_fixture_observations(),
        "fixture.artifact.timeline_preservation_report.v1" =>
          timeline_preservation_report_fixture_observations(),
        "fixture.artifact.timeline_preservation_status.v1" =>
          timeline_preservation_status_fixture_observations(),
        "fixture.artifact.timeline_publication_summary.v1" =>
          timeline_publication_summary_fixture_observations(),
        "fixture.artifact.timeline_transition_application_report.v1" =>
          timeline_transition_application_report_fixture_observations(),
        "fixture.artifact.timeline_transition_application_selected_integrity.v1" =>
          timeline_transition_application_selected_integrity_fixture_observations(),
        "fixture.artifact.timeline_transition_application_selected_integrity_summary.v1" =>
          timeline_transition_application_selected_integrity_summary_fixture_observations(),
        "fixture.artifact.timeline_transition_application_summary.v1" =>
          timeline_transition_application_summary_fixture_observations(),
        "fixture.artifact.validation_check.v1" => validation_check_fixture_observations(),
        "fixture.artifact.validation_record.v1" => validation_record_fixture_observations(),
        "fixture.artifact.validation_reference_report.v1" =>
          validation_reference_report_fixture_observations(),
        "fixture.artifact.validation_tolerance_policy.v1" =>
          validation_tolerance_policy_fixture_observations(),
        "fixture.force_model.atmospheric_drag.earth_400km" =>
          atmospheric_drag_fixture_observations(),
        "fixture.j2.circular_leo_600s" => j2_fixture_observations(),
        "fixture.propagator.j2_drag.earth_400km_24h_step_convergence" =>
          j2_drag_convergence_fixture_observations(),
        "fixture.propagator.two_body_drag.earth_400km_600s" =>
          two_body_drag_fixture_observations(),
        "fixture.two_body.circular_leo_600s" => two_body_fixture_observations()
      })

    assert %{
             "schema_contract" => "validation_reference_fixture_report.v1",
             "status" => "pass",
             "fixture_count" => 203,
             "status_counts" => %{"pass" => 203},
             "reports" => reports
           } = report

    checked_in_report = read_json!("study_results/validation_reference_fixtures.json")

    assert checked_in_report == report

    stale_checked_in_report =
      checked_in_report
      |> Map.update!("fixture_count", &(&1 - 1))

    refute stale_checked_in_report == report

    assert Enum.map(reports, & &1["fixture_id"]) == [
             "fixture.artifact.accepted_planning_state.oem",
             "fixture.artifact.accepted_planning_state.opm",
             "fixture.artifact.accepted_planning_state.simple",
             "fixture.artifact.activity_template.v1",
             "fixture.artifact.approval_requirement.v1",
             "fixture.artifact.backend_acceptance_policy.v1",
             "fixture.artifact.branch_comparison_report.v1",
             "fixture.artifact.cadence_import_manifest.resource_pressure_v1",
             "fixture.artifact.cadence_import_manifest.resource_projection_battery_handoff_v1",
             "fixture.artifact.cadence_import_manifest.v1",
             "fixture.artifact.campaign_plan.leo_constellation_v1",
             "fixture.artifact.campaign_repair.leo_constellation_v2",
             "fixture.artifact.campaign_request_lint.v1",
             "fixture.artifact.campaign_strategy.leo_constellation_v3",
             "fixture.artifact.candidate_activity.v1",
             "fixture.artifact.candidate_diff_report.v1",
             "fixture.artifact.candidate_diff_row.v1",
             "fixture.artifact.candidate_refresh.candidate_rejection_replay",
             "fixture.artifact.candidate_refresh.candidate_scoped_operational_readiness_selection_challenge",
             "fixture.artifact.candidate_refresh.candidate_scoped_quality_gate_selection_challenge",
             "fixture.artifact.candidate_refresh.constraint_replay",
             "fixture.artifact.candidate_refresh.contact_allocation_contradiction_replay",
             "fixture.artifact.candidate_refresh.contact_allocation_resource_selection_challenge",
             "fixture.artifact.candidate_refresh.contact_contention_cross_station_replay",
             "fixture.artifact.candidate_refresh.contact_filter_replay",
             "fixture.artifact.candidate_refresh.contact_intent_direction_replay",
             "fixture.artifact.candidate_refresh.freshness_replay",
             "fixture.artifact.candidate_refresh.link_capacity_replay",
             "fixture.artifact.candidate_refresh.objective_gap_replay",
             "fixture.artifact.candidate_refresh.operational_readiness_replay",
             "fixture.artifact.candidate_refresh.operational_readiness_selection_challenge",
             "fixture.artifact.candidate_refresh.quality_gate_replay",
             "fixture.artifact.candidate_refresh.quality_gate_unavailable_resource_selection_challenge",
             "fixture.artifact.candidate_refresh.refresh_budget_replay",
             "fixture.artifact.candidate_refresh.resource_filter_replay",
             "fixture.artifact.candidate_refresh.resource_projection_replay",
             "fixture.artifact.candidate_refresh.resource_provenance_v1",
             "fixture.artifact.candidate_refresh.station_calendar_replay",
             "fixture.artifact.candidate_refresh.timeline_activity_lifecycle_replay",
             "fixture.artifact.candidate_refresh.timeline_activity_precondition_replay",
             "fixture.artifact.candidate_refresh.timeline_lifecycle_state_replay",
             "fixture.artifact.candidate_refresh.timeline_transition_application_replay",
             "fixture.artifact.candidate_refresh.v1",
             "fixture.artifact.candidate_rejection_report.v1",
             "fixture.artifact.capability_catalog.v1",
             "fixture.artifact.command_window_report.v1",
             "fixture.artifact.constraint_report.v1",
             "fixture.artifact.contact_allocation_capacity_pack_summary.v1",
             "fixture.artifact.contact_allocation_provider_reservation_request_summary.v1",
             "fixture.artifact.contact_allocation_report.reduced_capacity_pack",
             "fixture.artifact.contact_allocation_report.v1",
             "fixture.artifact.contact_allocation_reservation_conflict_summary.v1",
             "fixture.artifact.contact_allocation_station_pressure_summary.v1",
             "fixture.artifact.contact_allocation_summary.v1",
             "fixture.artifact.contact_contention_report.cross_station_spacecraft",
             "fixture.artifact.contact_contention_report.v1",
             "fixture.artifact.contact_contention_resolution_report.v1",
             "fixture.artifact.contact_contention_resolution_summary.v1",
             "fixture.artifact.contact_filter_report.v1",
             "fixture.artifact.contact_intent.v1",
             "fixture.artifact.contact_intent_summary.v1",
             "fixture.artifact.environment_model_capability.constant_earth_rotation",
             "fixture.artifact.environment_model_capability.fixed_sun",
             "fixture.artifact.environment_provider_capability.constant_earth_rotation",
             "fixture.artifact.environment_provider_capability.exponential_atmosphere",
             "fixture.artifact.environment_provider_capability.fixed_sun",
             "fixture.artifact.environment_provider_capability.tabular_earth_orientation",
             "fixture.artifact.execution_report.v1",
             "fixture.artifact.freshness_report.v1",
             "fixture.artifact.invalidated_candidate.v1",
             "fixture.artifact.link_capacity_report.v1",
             "fixture.artifact.link_capacity_summary.v1",
             "fixture.artifact.maneuver_execution_delta.v1",
             "fixture.artifact.maneuver_recommendation.v1",
             "fixture.artifact.maneuver_review_report.v1",
             "fixture.artifact.manifest_field_reference.v1",
             "fixture.artifact.model_acceptance_report.operational_import",
             "fixture.artifact.monte_carlo_reproducibility_report.v1",
             "fixture.artifact.objective_satisfaction_report.v1",
             "fixture.artifact.objective_tradeoff_report.v1",
             "fixture.artifact.operational_execution_boundary_summary.v1",
             "fixture.artifact.operational_import_eligibility_summary.v1",
             "fixture.artifact.operational_quality_gate_import_readiness_summary.v1",
             "fixture.artifact.operational_quality_gate_operator_training_summary.v1",
             "fixture.artifact.operational_quality_gate_schema_validation_summary.v1",
             "fixture.artifact.operational_quality_gate_summary.v1",
             "fixture.artifact.operational_quality_gate_unavailable_resource_summary.resource_projection_v1",
             "fixture.artifact.operational_quality_gate_unavailable_resource_summary.v1",
             "fixture.artifact.operational_readiness_gate_summary.v1",
             "fixture.artifact.operational_readiness_report.resource_pressure_v1",
             "fixture.artifact.operational_readiness_report.v1",
             "fixture.artifact.operational_timeline_report.v1",
             "fixture.artifact.operator_review_package.resource_pressure_v1",
             "fixture.artifact.operator_review_package.resource_projection_battery_handoff_v1",
             "fixture.artifact.operator_review_package.v1",
             "fixture.artifact.optimizer_contract.v1",
             "fixture.artifact.pareto_frontier_report.v1",
             "fixture.artifact.plan_delta.v1",
             "fixture.artifact.planned_activity.v1",
             "fixture.artifact.policy_bundle.command_contact_authority",
             "fixture.artifact.policy_bundle.conservative_ops",
             "fixture.artifact.policy_bundle.contact_command_review",
             "fixture.artifact.policy_bundle.default",
             "fixture.artifact.policy_bundle.degraded_payload_guard",
             "fixture.artifact.policy_bundle.ground_network_allocation",
             "fixture.artifact.policy_bundle.maneuver_authority",
             "fixture.artifact.policy_bundle.operator_review_queue_authority",
             "fixture.artifact.policy_bundle.organization_adapter",
             "fixture.artifact.policy_bundle.resource_projection_authority",
             "fixture.artifact.policy_bundle.timeline_protection",
             "fixture.artifact.policy_bundle.v1",
             "fixture.artifact.policy_decision.v1",
             "fixture.artifact.proposed_contact.v1",
             "fixture.artifact.provider_counteroffer_import_readiness_summary.v1",
             "fixture.artifact.provider_counteroffer_plan_impact_summary.v1",
             "fixture.artifact.provider_counteroffer_report.v1",
             "fixture.artifact.provider_counteroffer_review_summary.v1",
             "fixture.artifact.quality_gate_report.resource_pressure_v1",
             "fixture.artifact.quality_gate_report.v1",
             "fixture.artifact.ranking_comparison_report.v1",
             "fixture.artifact.realized_activity.v1",
             "fixture.artifact.realized_state_snapshot.v1",
             "fixture.artifact.refresh_budget_report.v1",
             "fixture.artifact.refreshed_window.v1",
             "fixture.artifact.relay_data_path_summary.v1",
             "fixture.artifact.remaining_horizon.v1",
             "fixture.artifact.resource_filter_report.stale_resource_summary_margins",
             "fixture.artifact.resource_filter_report.v1",
             "fixture.artifact.resource_filter_summary.v1",
             "fixture.artifact.resource_projection_flow_summary.v1",
             "fixture.artifact.resource_projection_report.battery_handoff_v1",
             "fixture.artifact.resource_projection_report.stale_resource_summary_margins",
             "fixture.artifact.resource_projection_report.v1",
             "fixture.artifact.resource_summary.v1",
             "fixture.artifact.result_artifact.candidate_refresh_orbit_data_v1",
             "fixture.artifact.result_artifact.candidate_refresh_v1",
             "fixture.artifact.result_artifact.ground_track_crossings",
             "fixture.artifact.result_artifact.leo_access_demo",
             "fixture.artifact.result_artifact.leo_access_demo_manifest",
             "fixture.artifact.result_artifact.leo_constellation_campaign",
             "fixture.artifact.result_artifact.leo_dispersion_monte_carlo",
             "fixture.artifact.result_artifact.mission_plan_checkout",
             "fixture.artifact.result_artifact.raise_apogee_search",
             "fixture.artifact.schema_migration_report.deprecated_campaign_plan",
             "fixture.artifact.schema_migration_report.future_campaign_plan",
             "fixture.artifact.schema_validation_batch_report.v1",
             "fixture.artifact.schema_validation_report.v1",
             "fixture.artifact.score_term_report.v1",
             "fixture.artifact.source_window_lineage.v1",
             "fixture.artifact.spacecraft_state_estimate.v1",
             "fixture.artifact.station_calendar_precedence_summary.v1",
             "fixture.artifact.station_calendar_provider.v1",
             "fixture.artifact.station_calendar_report.stale_provider_reservation_hold",
             "fixture.artifact.station_calendar_report.v1",
             "fixture.artifact.station_reservation_hold_import_readiness_summary.v1",
             "fixture.artifact.station_reservation_hold_summary.v1",
             "fixture.artifact.station_reservation_report.stale_provider_reservation_hold",
             "fixture.artifact.station_reservation_review_summary.v1",
             "fixture.artifact.strategy_branch.v1",
             "fixture.artifact.strategy_recommendation.v1",
             "fixture.artifact.study_benchmark.distributed_chunk_sweep",
             "fixture.artifact.study_benchmark.distributed_concurrency_sweep",
             "fixture.artifact.study_benchmark.distributed_diagnostic_sweep",
             "fixture.artifact.study_benchmark.distributed_monte_carlo_chunked",
             "fixture.artifact.study_benchmark.distributed_monte_carlo_scaling",
             "fixture.artifact.study_benchmark.monte_carlo_scaling",
             "fixture.artifact.study_benchmark.nx_study_benchmark",
             "fixture.artifact.study_benchmark.v1",
             "fixture.artifact.study_manifest_lint.v1",
             "fixture.artifact.subsystem_model_capability.battery",
             "fixture.artifact.subsystem_model_capability.storage",
             "fixture.artifact.timeline_activity_approval_state.v1",
             "fixture.artifact.timeline_activity_lifecycle_state.v1",
             "fixture.artifact.timeline_activity_precondition_summary.v1",
             "fixture.artifact.timeline_activity_state.v1",
             "fixture.artifact.timeline_activity_status_state.v1",
             "fixture.artifact.timeline_dependency_impact_summary.v1",
             "fixture.artifact.timeline_diff_report.v1",
             "fixture.artifact.timeline_diff_summary.v1",
             "fixture.artifact.timeline_feedback_report.v1",
             "fixture.artifact.timeline_integrity_report.v1",
             "fixture.artifact.timeline_lifecycle_state_summary.v1",
             "fixture.artifact.timeline_preservation_report.v1",
             "fixture.artifact.timeline_preservation_status.v1",
             "fixture.artifact.timeline_publication_summary.v1",
             "fixture.artifact.timeline_transition_application_report.v1",
             "fixture.artifact.timeline_transition_application_selected_integrity.v1",
             "fixture.artifact.timeline_transition_application_selected_integrity_summary.v1",
             "fixture.artifact.timeline_transition_application_summary.v1",
             "fixture.artifact.validation_check.v1",
             "fixture.artifact.validation_record.v1",
             "fixture.artifact.validation_reference_report.v1",
             "fixture.artifact.validation_safety_case_summary.v1",
             "fixture.artifact.validation_tolerance_policy.v1",
             "fixture.event.access.equator_overhead_120s",
             "fixture.event.eclipse.cylindrical_shadow_120s",
             "fixture.event.ground_track.latitude_equator_60s",
             "fixture.event.target_visibility.equator_overhead_120s",
             "fixture.force_model.atmospheric_drag.earth_400km",
             "fixture.j2.circular_leo_600s",
             "fixture.propagator.j2_drag.earth_400km_24h_step_convergence",
             "fixture.propagator.two_body_drag.earth_400km_600s",
             "fixture.two_body.circular_leo_600s"
           ]

    assert {:ok, %{"schema_contract" => "validation_reference_fixture_report.v1"}} =
             OrbitalDynamics.Schema.validate_artifact(report)

    invalid_observation_report =
      Validation.reference_fixture_report(%{
        "fixture.two_body.circular_leo_600s" => :not_an_observation_map
      })

    assert %{
             "status" => "fail",
             "status_counts" => %{"fail" => 202},
             "reports" => invalid_observation_reports
           } = invalid_observation_report

    assert %{
             "schema_contract" => "validation_reference_report.v1",
             "fixture_id" => "fixture.two_body.circular_leo_600s",
             "status" => "fail",
             "checks" => [
               %{
                 "field" => "observations",
                 "status" => "fail",
                 "expected" => "valid observations map"
               }
             ]
           } =
             Enum.find(
               invalid_observation_reports,
               &(&1["fixture_id"] == "fixture.two_body.circular_leo_600s")
             )

    assert {:ok, %{"schema_contract" => "validation_reference_fixture_report.v1"}} =
             OrbitalDynamics.Schema.validate_artifact(invalid_observation_report)

    invalid_fixture_count = Map.put(report, "fixture_count", 99)

    assert {:error, fixture_count_report} =
             OrbitalDynamics.Schema.validate_artifact(invalid_fixture_count)

    assert Enum.any?(
             fixture_count_report["errors"],
             &(&1["path"] == "$.fixture_count")
           )

    inconsistent_status_report =
      report
      |> put_in(["reports", Access.at(0), "status"], "fail")
      |> Map.put("status", "pass")

    assert {:error, inconsistent_status_errors} =
             OrbitalDynamics.Schema.validate_artifact(inconsistent_status_report)

    assert Enum.any?(
             inconsistent_status_errors["errors"],
             &(&1["path"] == "$.status" and
                 &1["message"] == "must equal nested report statuses")
           )

    invalid_negative_fixture_count = Map.put(report, "fixture_count", -1)

    assert {:error, negative_fixture_count_report} =
             OrbitalDynamics.Schema.validate_artifact(invalid_negative_fixture_count)

    assert Enum.any?(
             negative_fixture_count_report["errors"],
             &(&1["path"] == "$.fixture_count")
           )

    stale_status_counts = put_in(report, ["status_counts", "pass"], 123)

    assert {:error, stale_status_counts_report} =
             OrbitalDynamics.Schema.validate_artifact(stale_status_counts)

    assert Enum.any?(
             stale_status_counts_report["errors"],
             &(&1["path"] == "$.status_counts" and
                 &1["message"] == "must equal nested report status counts")
           )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
