defmodule OrbitalDynamics.CadenceImport do
  @moduledoc """
  Builds artifact-only Cadence import manifests.

  The manifest is an adapter boundary: it names the repaired timeline changes
  that are ready, blocked, or still waiting on review before a downstream
  Cadence-side importer decides what to schedule. This module does not call
  Cadence APIs or mutate schedules.
  """

  alias OrbitalDynamics.CadenceImport.{
    ActivityResultImport,
    CampaignArtifactImport,
    CampaignReviewPackageImport,
    CampaignRowBuilder,
    Capability,
    CandidateEvaluationImport,
    ContactContentionImport,
    ContactPlanningImport,
    ConsumerConformance,
    ConstraintObjectiveImport,
    ManeuverReviewImport,
    ManifestContractDiagnostics,
    ManifestBuilder,
    ManifestRouter,
    OperationalTimelineImport,
    ProposedContactImport,
    ResourceProjectionImport,
    ReviewRowBuilder,
    ReviewPackageImport,
    StationOperationsImport,
    StrategyArtifactImport,
    StrategyDecisionImport,
    TimelineReviewImport,
    ValidationReadinessImport
  }

  @doc """
  Declares the artifact-only import-manifest model and known limits.
  """
  def capability, do: Capability.describe()

  @doc """
  Returns the import-manifest capability metadata using the common plural API.
  """
  def capabilities, do: capability()

  @doc """
  Builds a `cadence_import_manifest.v1` from a supported artifact.
  """
  def manifest(artifact, opts \\ []) do
    ManifestRouter.route(artifact, opts, &dispatch_manifest/3, &manifest_diagnostic/2)
  end

  @doc """
  Validates a V3 campaign strategy handoff and asks an explicit adapter to
  evaluate it without writing or mutating Cadence state.

  The input may be a complete `campaign_strategy.v3` artifact with an embedded
  Cadence import manifest or the bound `cadence_import_manifest.v1` itself.
  A fixed whole-input admission pass runs before schema inference, manifest
  extraction, or delegation. Adapter options are normalized to a bounded
  string-key map before delegation.

  Returns a typed, deterministic conformance map or a typed error tuple. Adapter
  errors, exceptions, throws, exits, and malformed returns are contained and do
  not escape this boundary.
  """
  @spec dry_run(term(), module(), keyword()) :: {:ok, map()} | {:error, map()}
  def dry_run(artifact_or_manifest, adapter, opts \\ []) do
    ConsumerConformance.run(artifact_or_manifest, adapter, opts)
  end

  @doc """
  Builds an import manifest from a V1 campaign plan artifact.
  """
  def from_campaign_artifact(%{} = artifact, opts \\ []) do
    CampaignArtifactImport.build(
      artifact,
      opts,
      proposed_contact_row: &proposed_contact_manifest_row/2,
      review_row: &review_manifest_row/2,
      build_manifest: &build_manifest/3
    )
  end

  @doc """
  Builds an import manifest from a standalone proposed-contact row.
  """
  def from_proposed_contact(%{} = contact, opts \\ []) do
    ProposedContactImport.build(
      contact,
      opts,
      row: &proposed_contact_manifest_row/2,
      build_manifest: &build_manifest/3
    )
  end

  @doc """
  Builds an import manifest from a standalone planned-activity row.
  """
  def from_planned_activity(%{} = activity, opts \\ []) do
    ActivityResultImport.from_planned_activity(activity, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a standalone realized-activity row.
  """
  def from_realized_activity(%{} = activity, opts \\ []) do
    ActivityResultImport.from_realized_activity(activity, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a realized-state snapshot.
  """
  def from_realized_state_snapshot(%{} = snapshot, opts \\ []) do
    ActivityResultImport.from_realized_state_snapshot(
      snapshot,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from a top-level study result artifact.
  """
  def from_result_artifact(%{} = artifact, opts \\ []) do
    ActivityResultImport.from_result_artifact(artifact, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a candidate refresh artifact.
  """
  def from_candidate_refresh_artifact(%{} = artifact, opts \\ []) do
    CampaignReviewPackageImport.from_candidate_refresh_artifact(
      artifact,
      opts,
      &from_operator_review_package/2
    )
  end

  @doc """
  Builds an import manifest from a V3 strategy artifact.
  """
  def from_strategy_artifact(%{} = artifact, opts \\ []) do
    StrategyArtifactImport.build(
      artifact,
      opts,
      strategy_row: &strategy_manifest_row/4,
      review_row: &review_manifest_row/2,
      feedback_context: &operational_feedback_manifest_context/1,
      build_manifest: &build_manifest/3
    )
  end

  @doc """
  Builds an import manifest from a V2 repair artifact.
  """
  def from_repair_artifact(%{} = artifact, opts \\ []) do
    CampaignReviewPackageImport.from_repair_artifact(
      artifact,
      opts,
      &from_operator_review_package/2
    )
  end

  @doc """
  Builds an import manifest from a realized timeline feedback report.
  """
  def from_timeline_feedback_report(%{} = report, opts \\ []) do
    OperationalTimelineImport.from_timeline_feedback_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from an operational timeline report.
  """
  def from_operational_timeline_report(%{} = report, opts \\ []) do
    OperationalTimelineImport.from_operational_timeline_report(
      report,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from a contact-contention report.
  """
  def from_contact_contention_report(%{} = report, opts \\ []) do
    ContactContentionImport.from_contact_contention_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a contact-contention resolution report.
  """
  def from_contact_contention_resolution_report(%{} = report, opts \\ []) do
    ContactContentionImport.from_contact_contention_resolution_report(
      report,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from a command-window report.
  """
  def from_command_window_report(%{} = report, opts \\ []) do
    StationOperationsImport.from_command_window_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a station-calendar report.
  """
  def from_station_calendar_report(%{} = report, opts \\ []) do
    StationOperationsImport.from_station_calendar_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a station-reservation report.
  """
  def from_station_reservation_report(%{} = report, opts \\ []) do
    StationOperationsImport.from_station_reservation_report(
      report,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from a link-capacity report.
  """
  def from_link_capacity_report(%{} = report, opts \\ []) do
    ContactPlanningImport.from_link_capacity_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a contact-allocation report.
  """
  def from_contact_allocation_report(%{} = report, opts \\ []) do
    ContactPlanningImport.from_contact_allocation_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a contact-allocation capacity-pack summary.
  """
  def from_contact_allocation_capacity_pack_summary(%{} = summary, opts \\ []) do
    ContactPlanningImport.from_contact_allocation_capacity_pack_summary(
      summary,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from a contact-allocation reservation-conflict summary.
  """
  def from_contact_allocation_reservation_conflict_summary(%{} = summary, opts \\ []) do
    ContactPlanningImport.from_contact_allocation_reservation_conflict_summary(
      summary,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from a standalone contact-intent row.
  """
  def from_contact_intent(%{} = intent, opts \\ []) do
    ContactPlanningImport.from_contact_intent(intent, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a resource-projection report.
  """
  def from_resource_projection_report(%{} = report, opts \\ []) do
    ResourceProjectionImport.from_resource_projection_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a resource-projection flow summary.
  """
  def from_resource_projection_flow_summary(%{} = summary, opts \\ []) do
    ResourceProjectionImport.from_resource_projection_flow_summary(
      summary,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from a contact-filter report.
  """
  def from_contact_filter_report(%{} = report, opts \\ []) do
    CandidateEvaluationImport.from_contact_filter_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a candidate-diff report.
  """
  def from_candidate_diff_report(%{} = report, opts \\ []) do
    CandidateEvaluationImport.from_candidate_diff_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a candidate-rejection report.
  """
  def from_candidate_rejection_report(%{} = report, opts \\ []) do
    CandidateEvaluationImport.from_candidate_rejection_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a provider-counteroffer report.
  """
  def from_provider_counteroffer_report(%{} = report, opts \\ []) do
    CandidateEvaluationImport.from_provider_counteroffer_report(
      report,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from a standalone invalidated-candidate row.
  """
  def from_invalidated_candidate(%{} = candidate, opts \\ []) do
    CandidateEvaluationImport.from_invalidated_candidate(candidate, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a resource-filter report.
  """
  def from_resource_filter_report(%{} = report, opts \\ []) do
    CandidateEvaluationImport.from_resource_filter_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a freshness report.
  """
  def from_freshness_report(%{} = report, opts \\ []) do
    CandidateEvaluationImport.from_freshness_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a refresh-budget report.
  """
  def from_refresh_budget_report(%{} = report, opts \\ []) do
    CandidateEvaluationImport.from_refresh_budget_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a constraint report.
  """
  def from_constraint_report(%{} = report, opts \\ []) do
    ConstraintObjectiveImport.from_constraint_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from an objective-satisfaction report.
  """
  def from_objective_satisfaction_report(%{} = report, opts \\ []) do
    ConstraintObjectiveImport.from_objective_satisfaction_report(
      report,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from a standalone maneuver recommendation.
  """
  def from_maneuver_recommendation(%{} = recommendation, opts \\ []) do
    ManeuverReviewImport.from_maneuver_recommendation(
      recommendation,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from a standalone maneuver execution delta.
  """
  def from_maneuver_execution_delta(%{} = delta, opts \\ []) do
    ManeuverReviewImport.from_maneuver_execution_delta(delta, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a maneuver-review report.
  """
  def from_maneuver_review_report(%{} = report, opts \\ []) do
    ManeuverReviewImport.from_maneuver_review_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a timeline-diff report.
  """
  def from_timeline_diff_report(%{} = report, opts \\ []) do
    TimelineReviewImport.from_timeline_diff_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a model-only timeline diff summary.
  """
  def from_timeline_diff_summary(%{} = summary, opts \\ []) do
    TimelineReviewImport.from_timeline_diff_summary(summary, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a timeline dependency-impact summary.
  """
  def from_timeline_dependency_impact_summary(%{} = summary, opts \\ []) do
    TimelineReviewImport.from_timeline_dependency_impact_summary(
      summary,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from a timeline publication summary.
  """
  def from_timeline_publication_summary(%{} = summary, opts \\ []) do
    TimelineReviewImport.from_timeline_publication_summary(summary, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a timeline activity precondition summary.
  """
  def from_timeline_activity_precondition_summary(%{} = summary, opts \\ []) do
    TimelineReviewImport.from_timeline_activity_precondition_summary(
      summary,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from a timeline lifecycle-state summary.
  """
  def from_timeline_lifecycle_state_summary(%{} = summary, opts \\ []) do
    TimelineReviewImport.from_timeline_lifecycle_state_summary(
      summary,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from a compact activity-state artifact.
  """
  def from_timeline_activity_state(%{} = state, opts \\ []) do
    TimelineReviewImport.from_timeline_activity_state(state, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a single activity status-state artifact.
  """
  def from_timeline_activity_status_state(%{} = state, opts \\ []) do
    TimelineReviewImport.from_timeline_activity_status_state(state, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a single activity approval-state artifact.
  """
  def from_timeline_activity_approval_state(%{} = state, opts \\ []) do
    TimelineReviewImport.from_timeline_activity_approval_state(state, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a single activity lifecycle-state artifact.
  """
  def from_timeline_activity_lifecycle_state(%{} = state, opts \\ []) do
    TimelineReviewImport.from_timeline_activity_lifecycle_state(
      state,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from a timeline preservation report.
  """
  def from_timeline_preservation_report(%{} = report, opts \\ []) do
    TimelineReviewImport.from_timeline_preservation_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a single timeline preservation status artifact.
  """
  def from_timeline_preservation_status(%{} = status, opts \\ []) do
    TimelineReviewImport.from_timeline_preservation_status(status, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a model-only timeline integrity report.
  """
  def from_timeline_integrity_report(%{} = report, opts \\ []) do
    TimelineReviewImport.from_timeline_integrity_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a model-only timeline transition-application summary.
  """
  def from_timeline_transition_application_summary(%{} = summary, opts \\ []) do
    TimelineReviewImport.from_timeline_transition_application_summary(
      summary,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from a timeline transition application report.
  """
  def from_timeline_transition_application_report(%{} = report, opts \\ []) do
    TimelineReviewImport.from_timeline_transition_application_report(
      report,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from a standalone approval requirement.
  """
  def from_approval_requirement(%{} = requirement, opts \\ []) do
    StrategyDecisionImport.from_approval_requirement(requirement, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a policy-decision artifact.
  """
  def from_policy_decision(%{} = decision, opts \\ []) do
    StrategyDecisionImport.from_policy_decision(decision, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a branch-comparison report.
  """
  def from_branch_comparison_report(%{} = report, opts \\ []) do
    StrategyDecisionImport.from_branch_comparison_report(
      report,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from a ranking-comparison report.
  """
  def from_ranking_comparison_report(%{} = report, opts \\ []) do
    StrategyDecisionImport.from_ranking_comparison_report(
      report,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from a score-term report.
  """
  def from_score_term_report(%{} = report, opts \\ []) do
    StrategyDecisionImport.from_score_term_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from an objective-tradeoff report.
  """
  def from_objective_tradeoff_report(%{} = report, opts \\ []) do
    StrategyDecisionImport.from_objective_tradeoff_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a Pareto-frontier report.
  """
  def from_pareto_frontier_report(%{} = report, opts \\ []) do
    StrategyDecisionImport.from_pareto_frontier_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a schema-validation report.
  """
  def from_schema_validation_report(%{} = report, opts \\ []) do
    ValidationReadinessImport.from_schema_validation_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from a schema-validation batch report.
  """
  def from_schema_validation_batch_report(%{} = report, opts \\ []) do
    ValidationReadinessImport.from_schema_validation_batch_report(
      report,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from an execution report.
  """
  def from_execution_report(%{} = report, opts \\ []) do
    ValidationReadinessImport.from_execution_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from an operational-readiness report.
  """
  def from_operational_readiness_report(%{} = report, opts \\ []) do
    ValidationReadinessImport.from_operational_readiness_report(
      report,
      opts,
      &from_review_report/4
    )
  end

  @doc """
  Builds an import manifest from a quality-gate report.
  """
  def from_quality_gate_report(%{} = report, opts \\ []) do
    ValidationReadinessImport.from_quality_gate_report(report, opts, &from_review_report/4)
  end

  @doc """
  Builds an import manifest from an operator-review package.
  """
  def from_operator_review_package(%{} = package, opts \\ []) do
    ReviewPackageImport.build(
      package,
      opts,
      &review_manifest_row/2,
      schema_contract: Capability.schema_contract(),
      schema_version: Capability.schema_version(),
      accepted_statuses: Capability.accepted_statuses(),
      capability: capability()
    )
  end

  defp from_review_report(review_package, opts, source_artifact_type, source_artifact_id) do
    from_operator_review_package(
      review_package,
      Keyword.merge(opts,
        source_artifact_type: source_artifact_type,
        source_artifact_id: source_artifact_id
      )
    )
  end

  defp dispatch_manifest(function, artifact, opts),
    do: apply(__MODULE__, function, [artifact, opts])

  defp manifest_diagnostic(:contract, artifact),
    do: unsupported_manifest_contract(artifact)

  defp manifest_diagnostic(:supported, _artifact),
    do: supported_manifest_contracts()

  defp build_manifest(rows, provenance, context) do
    ManifestBuilder.build(rows, provenance, context,
      schema_contract: Capability.schema_contract(),
      schema_version: Capability.schema_version(),
      accepted_statuses: Capability.accepted_statuses(),
      capability: capability()
    )
  end

  defp proposed_contact_manifest_row(contact, rank) do
    CampaignRowBuilder.proposed_contact(contact, rank)
  end

  defp strategy_manifest_row(row, recommendation, rank, operational_feedback_context) do
    CampaignRowBuilder.strategy(row, recommendation, rank, operational_feedback_context)
  end

  defp operational_feedback_manifest_context(provenance) do
    CampaignRowBuilder.operational_feedback_context(provenance)
  end

  defp review_manifest_row(row, rank), do: ReviewRowBuilder.build(row, rank)

  defp unsupported_manifest_contract(artifact),
    do: ManifestContractDiagnostics.unsupported_contract(artifact)

  defp supported_manifest_contracts,
    do: capability() |> ManifestContractDiagnostics.supported_contracts()
end
