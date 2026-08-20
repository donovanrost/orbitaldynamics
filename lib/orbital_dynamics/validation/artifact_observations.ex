defmodule OrbitalDynamics.Validation.ArtifactObservations do
  @moduledoc false

  @builders %{
    "accepted_planning_state.v1" => {__MODULE__.AcceptedPlanningState, :build},
    "authority_context.v1" => {__MODULE__.AuthorityContext, :build},
    "campaign_plan.v1" => {__MODULE__.CampaignPlan, :build},
    "campaign_plan_search_trace.v1" => {__MODULE__.CampaignPlanSearchTrace, :build},
    "result_artifact.v1" => {__MODULE__.ResultArtifact, :build},
    "campaign_repair.v2" => {__MODULE__.CampaignRepair, :build},
    "campaign_request_lint.v1" => {__MODULE__.CampaignRequestLint, :build},
    "campaign_strategy.v3" => {__MODULE__.CampaignStrategy, :build},
    "capability_catalog.v1" => {__MODULE__.CapabilityCatalog, :build},
    "candidate_refresh.v1" => {__MODULE__.CandidateRefresh, :build},
    "candidate_refresh_execution.v1" => {__MODULE__.CandidateRefreshExecution, :build},
    "candidate_rejection_report.v1" => {__MODULE__.CandidateRejectionReport, :build},
    "candidate_diff_row.v1" => {__MODULE__.CandidateDiffRow, :build},
    "environment_model_capability.v1" => {__MODULE__.EnvironmentCapability, :build_model},
    "environment_provider_capability.v1" => {__MODULE__.EnvironmentCapability, :build_provider},
    "downlink_link_budget.v1" => {__MODULE__.DownlinkLinkBudget, :build},
    "branch_comparison_report.v1" => {__MODULE__.BranchComparisonReport, :build},
    "optimizer_contract.v1" => {__MODULE__.OptimizerContract, :build},
    "invalidated_candidate.v1" => {__MODULE__.InvalidatedCandidate, :build},
    "candidate_diff_report.v1" => {__MODULE__.CandidateDiffReport, :build},
    "refresh_budget_report.v1" => {__MODULE__.RefreshBudgetReport, :build},
    "execution_report.v1" => {__MODULE__.ExecutionReport, :build},
    "freshness_report.v1" => {__MODULE__.FreshnessReport, :build},
    "manifest_field_reference.v1" => {__MODULE__.ManifestFieldReference, :build},
    "study_manifest_lint.v1" => {__MODULE__.StudyManifestLint, :build},
    "approval_requirement.v1" => {__MODULE__.ApprovalRequirement, :build},
    "policy_decision.v1" => {__MODULE__.PolicyDecision, :build},
    "proposed_contact.v1" => {__MODULE__.ProposedContact, :build},
    "policy_bundle.v1" => {__MODULE__.PolicyBundle, :build},
    "activity_template.v1" => {__MODULE__.ActivityTemplate, :build},
    "subsystem_model_capability.v1" => {__MODULE__.SubsystemModelCapability, :build},
    "planned_activity.v1" => {__MODULE__.PlannedActivity, :build},
    "realized_activity.v1" => {__MODULE__.RealizedActivity, :build},
    "plan_delta.v1" => {__MODULE__.PlanDelta, :build},
    "candidate_activity.v1" => {__MODULE__.CandidateActivity, :build},
    "contact_intent.v1" => {__MODULE__.ContactIntent, :build},
    "contact_intent_summary.v1" => {__MODULE__.ContactIntentSummary, :build},
    "link_capacity_summary.v1" => {__MODULE__.LinkCapacitySummary, :build},
    "refreshed_window.v1" => {__MODULE__.RefreshedWindow, :build},
    "source_window_lineage.v1" => {__MODULE__.SourceWindowLineage, :build},
    "spacecraft_state_estimate.v1" => {__MODULE__.SpacecraftStateEstimate, :build},
    "realized_state_snapshot.v1" => {__MODULE__.RealizedStateSnapshot, :build},
    "remaining_horizon.v1" => {__MODULE__.RemainingHorizon, :build},
    "maneuver_execution_delta.v1" => {__MODULE__.ManeuverExecutionDelta, :build},
    "maneuver_recommendation.v1" => {__MODULE__.ManeuverRecommendation, :build},
    "backend_acceptance_policy.v1" => {__MODULE__.BackendAcceptancePolicy, :build},
    "validation_tolerance_policy.v1" => {__MODULE__.ValidationTolerancePolicy, :build},
    "validation_record.v1" => {__MODULE__.ValidationRecord, :build},
    "validation_reference_report.v1" => {__MODULE__.ValidationReferenceReport, :build},
    "validation_check.v1" => {__MODULE__.ValidationCheck, :build},
    "timeline_diff_report.v1" => {__MODULE__.TimelineDiffReport, :build},
    "timeline_diff_summary.v1" => {__MODULE__.TimelineDiffSummary, :build},
    "timeline_publication_summary.v1" => {__MODULE__.TimelinePublicationSummary, :build},
    "timeline_revision.v1" => {__MODULE__.TimelineRevision, :build},
    "cadence_import_manifest.v1" => {__MODULE__.CadenceImportManifest, :build},
    "command_window_report.v1" => {__MODULE__.CommandWindowReport, :build},
    "constraint_report.v1" => {__MODULE__.ConstraintReport, :build},
    "operational_timeline_report.v1" => {__MODULE__.OperationalTimelineReport, :build},
    "timeline_activity_precondition_summary.v1" =>
      {__MODULE__.TimelineActivityPreconditionSummary, :build},
    "timeline_integrity_report.v1" => {__MODULE__.TimelineIntegrityReport, :build},
    "timeline_dependency_impact_summary.v1" =>
      {__MODULE__.TimelineDependencyImpactSummary, :build},
    "schema_validation_report.v1" => {__MODULE__.SchemaValidationReport, :build},
    "schema_validation_batch_report.v1" => {__MODULE__.SchemaValidationBatchReport, :build},
    "schema_migration_report.v1" => {__MODULE__.SchemaMigrationReport, :build},
    "operator_review_package.v1" => {__MODULE__.OperatorReviewPackage, :build},
    "timeline_transition_application_report.v1" =>
      {__MODULE__.TimelineTransitionApplicationReport, :build},
    "timeline_transition_application_summary.v1" =>
      {__MODULE__.TimelineTransitionApplicationSummary, :build},
    "timeline_activity_state.v1" => {__MODULE__.TimelineActivityState, :build},
    "timeline_activity_lifecycle_state.v1" => {__MODULE__.TimelineActivityLifecycleState, :build},
    "timeline_activity_status_state.v1" => {__MODULE__.TimelineActivityStatusState, :build},
    "timeline_activity_approval_state.v1" => {__MODULE__.TimelineActivityApprovalState, :build},
    "timeline_lifecycle_state_summary.v1" => {__MODULE__.TimelineLifecycleStateSummary, :build},
    "timeline_preservation_report.v1" => {__MODULE__.TimelinePreservationReport, :build},
    "timeline_preservation_status.v1" => {__MODULE__.TimelinePreservationStatus, :build},
    "timeline_feedback_report.v1" => {__MODULE__.TimelineFeedbackReport, :build},
    "contact_allocation_report.v1" => {__MODULE__.ContactAllocationReport, :build},
    "contact_allocation_reservation_conflict_summary.v1" =>
      {__MODULE__.ContactAllocationReservationConflictSummary, :build},
    "contact_allocation_station_pressure_summary.v1" =>
      {__MODULE__.ContactAllocationStationPressureSummary, :build},
    "contact_allocation_capacity_pack_summary.v1" =>
      {__MODULE__.ContactAllocationCapacityPackSummary, :build},
    "contact_allocation_summary.v1" => {__MODULE__.ContactAllocationSummary, :build},
    "contact_allocation_provider_reservation_request_summary.v1" =>
      {__MODULE__.ContactAllocationProviderReservationRequestSummary, :build},
    "contact_filter_report.v1" => {__MODULE__.ContactFilterReport, :build},
    "contact_contention_report.v1" => {__MODULE__.ContactContentionReport, :build},
    "contact_contention_resolution_report.v1" =>
      {__MODULE__.ContactContentionResolutionReport, :build},
    "contact_contention_resolution_summary.v1" =>
      {__MODULE__.ContactContentionResolutionSummary, :build},
    "link_capacity_report.v1" => {__MODULE__.LinkCapacityReport, :build},
    "relay_data_path_summary.v1" => {__MODULE__.RelayDataPathSummary, :build},
    "maneuver_review_report.v1" => {__MODULE__.ManeuverReviewReport, :build},
    "monte_carlo_reproducibility_report.v1" =>
      {__MODULE__.MonteCarloReproducibilityReport, :build},
    "pareto_frontier_report.v1" => {__MODULE__.ParetoFrontierReport, :build},
    "resource_projection_report.v1" => {__MODULE__.ResourceProjectionReport, :build},
    "resource_projection_flow_summary.v1" => {__MODULE__.ResourceProjectionFlowSummary, :build},
    "resource_state_trace.v1" => {__MODULE__.ResourceStateTrace, :build},
    "resource_summary.v1" => {__MODULE__.ResourceSummary, :build},
    "station_calendar_provider.v1" => {__MODULE__.StationCalendarProvider, :build},
    "resource_filter_report.v1" => {__MODULE__.ResourceFilterReport, :build},
    "resource_filter_summary.v1" => {__MODULE__.ResourceFilterSummary, :build},
    "station_calendar_precedence_summary.v1" =>
      {__MODULE__.StationCalendarPrecedenceSummary, :build},
    "objective_satisfaction_report.v1" => {__MODULE__.ObjectiveSatisfactionReport, :build},
    "objective_tradeoff_report.v1" => {__MODULE__.ObjectiveTradeoffReport, :build},
    "score_term_report.v1" => {__MODULE__.ScoreTermReport, :build},
    "ranking_comparison_report.v1" => {__MODULE__.RankingComparisonReport, :build},
    "strategy_branch.v1" => {__MODULE__.StrategyBranch, :build},
    "strategy_recommendation.v1" => {__MODULE__.StrategyRecommendation, :build},
    "study_benchmark.v1" => {__MODULE__.StudyBenchmark, :build},
    "operational_readiness_report.v1" => {__MODULE__.OperationalReadinessReport, :build},
    "operational_execution_boundary_summary.v1" =>
      {__MODULE__.OperationalExecutionBoundarySummary, :build},
    "operational_import_eligibility_summary.v1" =>
      {__MODULE__.OperationalImportEligibilitySummary, :build},
    "operational_readiness_gate_summary.v1" =>
      {__MODULE__.OperationalReadinessGateSummary, :build},
    "quality_gate_report.v1" => {__MODULE__.QualityGateReport, :build},
    "operational_quality_gate_summary.v1" => {__MODULE__.OperationalQualityGateSummary, :build},
    "operational_quality_gate_import_readiness_summary.v1" =>
      {__MODULE__.OperationalQualityGateImportReadinessSummary, :build},
    "operational_quality_gate_unavailable_resource_summary.v1" =>
      {__MODULE__.OperationalQualityGateUnavailableResourceSummary, :build},
    "operational_quality_gate_operator_training_summary.v1" =>
      {__MODULE__.OperationalQualityGateOperatorTrainingSummary, :build},
    "operational_quality_gate_schema_validation_summary.v1" =>
      {__MODULE__.OperationalQualityGateSchemaValidationSummary, :build},
    "provider_counteroffer_report.v1" => {__MODULE__.ProviderCounterofferReport, :build},
    "provider_counteroffer_review_summary.v1" =>
      {__MODULE__.ProviderCounterofferReviewSummary, :build},
    "provider_counteroffer_import_readiness_summary.v1" =>
      {__MODULE__.ProviderCounterofferImportReadinessSummary, :build},
    "provider_counteroffer_plan_impact_summary.v1" =>
      {__MODULE__.ProviderCounterofferPlanImpactSummary, :build},
    "station_calendar_report.v1" => {__MODULE__.StationCalendarReport, :build},
    "station_reservation_report.v1" => {__MODULE__.StationReservationReport, :build},
    "station_reservation_review_summary.v1" =>
      {__MODULE__.StationReservationReviewSummary, :build},
    "station_reservation_hold_summary.v1" => {__MODULE__.StationReservationHoldSummary, :build},
    "station_reservation_hold_import_readiness_summary.v1" =>
      {__MODULE__.StationReservationHoldImportReadinessSummary, :build},
    "model_acceptance_report.v1" => {__MODULE__.ModelAcceptanceReport, :build},
    "validation_safety_case_summary.v1" => {__MODULE__.ValidationSafetyCaseSummary, :build}
  }

  def build(contract, artifact) when is_map(artifact) do
    case Map.fetch(@builders, contract) do
      {:ok, {module, function}} -> apply(module, function, [artifact])
      :error -> unsupported_contract(contract)
    end
  end

  def build(contract, _artifact), do: unsupported_contract(contract)

  defp unsupported_contract(contract) do
    raise ArgumentError, "unsupported artifact observation contract: #{inspect(contract)}"
  end
end
