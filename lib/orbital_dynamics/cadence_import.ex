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
    CandidateEvaluationImport,
    ContactContentionImport,
    ContactPlanningImport,
    ConstraintObjectiveImport,
    ManeuverReviewImport,
    ManifestContractDiagnostics,
    ManifestBuilder,
    ManifestRouter,
    OperationalTimelineImport,
    ProposedContactImport,
    ProviderResultNormalization,
    ResourceProjectionImport,
    ReviewRowBuilder,
    ReviewPackageImport,
    StationOperationsImport,
    StrategyArtifactImport,
    StrategyDecisionImport,
    TimelineReviewImport,
    ValidationReadinessImport
  }

  alias OrbitalDynamics.OperatorReview

  @schema_contract "cadence_import_manifest.v1"
  @schema_version 1
  @import_statuses ~w(
    blocked_missing_cadence_import
    not_applicable
    ready_for_import
    review_required_before_import
  )
  @cadence_import_statuses ~w(invalid missing not_applicable present)
  @doc """
  Declares the artifact-only import-manifest model and known limits.
  """
  def capability do
    %{
      artifact_contract: @schema_contract,
      model: :artifact_only_cadence_import_manifest,
      supported_sources: [
        "campaign_plan.v1",
        "campaign_repair.v2",
        "campaign_strategy.v3",
        "candidate_refresh.v1",
        "proposed_contact.v1",
        "planned_activity.v1",
        "realized_activity.v1",
        "realized_state_snapshot.v1",
        "result_artifact.v1",
        "timeline_feedback_report.v1",
        "operational_timeline_report.v1",
        "contact_contention_report.v1",
        "contact_contention_resolution_report.v1",
        "command_window_report.v1",
        "station_calendar_report.v1",
        "station_reservation_report.v1",
        "link_capacity_report.v1",
        "contact_allocation_report.v1",
        "contact_allocation_capacity_pack_summary.v1",
        "contact_allocation_reservation_conflict_summary.v1",
        "resource_projection_report.v1",
        "resource_projection_flow_summary.v1",
        "contact_intent.v1",
        "contact_filter_report.v1",
        "candidate_rejection_report.v1",
        "provider_counteroffer_report.v1",
        "candidate_diff_report.v1",
        "invalidated_candidate.v1",
        "resource_filter_report.v1",
        "freshness_report.v1",
        "refresh_budget_report.v1",
        "constraint_report.v1",
        "objective_satisfaction_report.v1",
        "maneuver_recommendation.v1",
        "maneuver_execution_delta.v1",
        "maneuver_review_report.v1",
        "timeline_diff_report.v1",
        "timeline_diff_summary.v1",
        "timeline_dependency_impact_summary.v1",
        "timeline_publication_summary.v1",
        "timeline_activity_precondition_summary.v1",
        "timeline_activity_state.v1",
        "timeline_activity_status_state.v1",
        "timeline_activity_approval_state.v1",
        "timeline_activity_lifecycle_state.v1",
        "timeline_lifecycle_state_summary.v1",
        "timeline_preservation_report.v1",
        "timeline_preservation_status.v1",
        "timeline_integrity_report.v1",
        "timeline_transition_application_summary.v1",
        "timeline_transition_application_report.v1",
        "approval_requirement.v1",
        "policy_decision.v1",
        "branch_comparison_report.v1",
        "ranking_comparison_report.v1",
        "score_term_report.v1",
        "objective_tradeoff_report.v1",
        "pareto_frontier_report.v1",
        "schema_validation_report.v1",
        "schema_validation_batch_report.v1",
        "execution_report.v1",
        "operational_readiness_report.v1",
        "quality_gate_report.v1",
        "operator_review_package.v1"
      ],
      import_actions: [
        "import_proposed_contact",
        "import_strategy_recommendation",
        "review_strategy_branch_alternative",
        "record_realized_feedback",
        "review_realized_feedback",
        "review_operational_timeline",
        "review_contact_contention",
        "review_contact_contention_resolution",
        "review_command_window",
        "review_station_calendar",
        "review_station_reservation",
        "review_link_capacity",
        "review_contact_allocation",
        "review_contact_allocation_capacity_pack",
        "review_provider_reservation_request",
        "review_contact_intent",
        "review_candidate_rejection",
        "review_provider_counteroffer",
        "review_candidate_diff",
        "review_refresh_freshness",
        "review_refresh_budget",
        "review_constraint",
        "review_objective_satisfaction",
        "review_resource_projection",
        "review_contact_suppression",
        "review_resource_suppression",
        "review_maneuver",
        "review_timeline_diff",
        "review_timeline_dependency_impact",
        "review_timeline_publication",
        "review_timeline_precondition",
        "review_timeline_lifecycle_state",
        "review_timeline_preservation",
        "review_timeline_integrity",
        "review_approval_requirement",
        "review_policy_escalation",
        "review_timeline_protection",
        "review_warning",
        "review_risk",
        "review_strategy_recommendation",
        "review_strategy_tradeoff",
        "review_score_term",
        "review_objective_tradeoff",
        "review_ranking_comparison",
        "review_pareto_frontier",
        "review_schema_validation",
        "review_execution",
        "review_operational_readiness",
        "review_quality_gate",
        "review_operator_row",
        "import_replacement_activity",
        "cancel_source_activity",
        "suppress_source_activity",
        "record_preserved_executed_activity",
        "record_preserved_activity",
        "review_plan_delta"
      ],
      source_review_types: source_review_types(),
      import_statuses: @import_statuses,
      cadence_import_statuses: @cadence_import_statuses,
      provider_result_map_value_keys: ProviderResultNormalization.map_value_keys(),
      handoff_row_semantics: [
        :schema_validation_import_rows,
        :schema_validation_issue_context,
        :schema_validation_batch_nested_report_context,
        :operational_readiness_import_rows,
        :operational_readiness_gate_rows,
        :operational_readiness_resource_summary_context,
        :operational_readiness_resource_gate_context,
        :operational_readiness_adapter_boundary_context,
        :operational_readiness_cadence_import_gate_context,
        :quality_gate_import_rows,
        :quality_gate_resource_row_context,
        :timeline_diff_summary_import_rows,
        :timeline_diff_summary_source_handoff_consistency,
        :timeline_dependency_impact_import_rows,
        :timeline_dependency_impact_source_handoff_consistency,
        :timeline_publication_import_rows,
        :timeline_publication_source_handoff_consistency,
        :timeline_lifecycle_state_import_rows,
        :timeline_lifecycle_state_source_handoff_consistency,
        :timeline_activity_precondition_import_rows,
        :timeline_activity_precondition_source_handoff_consistency,
        :timeline_preservation_import_rows,
        :timeline_preservation_source_handoff_consistency,
        :timeline_integrity_import_rows,
        :timeline_integrity_source_handoff_consistency,
        :timeline_transition_application_summary_import_rows,
        :timeline_transition_application_summary_source_handoff_consistency,
        :resource_projection_count_handoff_consistency,
        :station_calendar_count_handoff_consistency,
        :link_capacity_count_handoff_consistency,
        :link_capacity_source_handoff_consistency,
        :contact_allocation_handoff_consistency,
        :contact_allocation_source_handoff_consistency,
        :contact_allocation_capacity_pack_source_handoff_consistency,
        :contact_contention_source_handoff_consistency,
        :command_window_source_handoff_consistency,
        :provider_counteroffer_source_handoff_consistency,
        :contact_intent_source_handoff_consistency,
        :station_calendar_source_handoff_consistency,
        :provider_calendar_contention_source_handoff_consistency,
        :suppression_duplicate_handoff_consistency,
        :suppression_source_handoff_consistency,
        :review_package_passthrough_rows
      ],
      known_limits: [
        :does_not_write_cadence,
        :does_not_approve_operator_actions,
        :does_not_resolve_schedule_conflicts,
        :review_rows_are_adapter_handoff_not_operator_approval
      ]
    }
  end

  @doc """
  Returns the import-manifest capability metadata using the common plural API.
  """
  def capabilities, do: capability()

  defp source_review_types do
    OperatorReview.capabilities().review_types ++
      [
        "proposed_contact",
        "strategy_branch_comparison"
      ]
  end

  @doc """
  Builds a `cadence_import_manifest.v1` from a supported artifact.
  """
  def manifest(artifact, opts \\ []) do
    ManifestRouter.route(artifact, opts, &dispatch_manifest/3, &manifest_diagnostic/2)
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
      schema_contract: @schema_contract,
      schema_version: @schema_version,
      accepted_statuses: @cadence_import_statuses,
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
      schema_contract: @schema_contract,
      schema_version: @schema_version,
      accepted_statuses: @cadence_import_statuses,
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
