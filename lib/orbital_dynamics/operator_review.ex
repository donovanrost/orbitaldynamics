defmodule OrbitalDynamics.OperatorReview do
  @moduledoc """
  Builds artifact-only operator review packages.

  These packages collect contact-contention recommendations, realized feedback,
  plan-delta reviews, approval requirements, warnings, risk explanations, and strategy
  recommendations into a stable import-oriented surface. They do not approve
  work, reserve provider resources, mutate schedules, or execute commands.
  """

  alias OrbitalDynamics.OperatorReview.BranchComparison
  alias OrbitalDynamics.OperatorReview.CandidateDiff
  alias OrbitalDynamics.OperatorReview.CandidateRejection
  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.CommandWindow
  alias OrbitalDynamics.OperatorReview.CompositeArtifact
  alias OrbitalDynamics.OperatorReview.ContactAllocation
  alias OrbitalDynamics.OperatorReview.ContactContention
  alias OrbitalDynamics.OperatorReview.ContactIntent
  alias OrbitalDynamics.OperatorReview.ConstraintObjective
  alias OrbitalDynamics.OperatorReview.ExecutionReport
  alias OrbitalDynamics.OperatorReview.FilterReview
  alias OrbitalDynamics.OperatorReview.LinkCapacity
  alias OrbitalDynamics.OperatorReview.ManeuverExecutionDelta
  alias OrbitalDynamics.OperatorReview.ManeuverReview
  alias OrbitalDynamics.OperatorReview.ModelAcceptance
  alias OrbitalDynamics.OperatorReview.OperationalTimeline
  alias OrbitalDynamics.OperatorReview.OperationalReadiness
  alias OrbitalDynamics.OperatorReview.OptimizationReview
  alias OrbitalDynamics.OperatorReview.PolicyApproval
  alias OrbitalDynamics.OperatorReview.ProviderCounteroffer
  alias OrbitalDynamics.OperatorReview.QualityGate
  alias OrbitalDynamics.OperatorReview.RefreshState
  alias OrbitalDynamics.OperatorReview.RealizedActivity
  alias OrbitalDynamics.OperatorReview.RealizedStateSnapshot
  alias OrbitalDynamics.OperatorReview.ResultArtifact
  alias OrbitalDynamics.OperatorReview.ResourceProjection
  alias OrbitalDynamics.OperatorReview.SchemaValidation
  alias OrbitalDynamics.OperatorReview.StationCalendar
  alias OrbitalDynamics.OperatorReview.StationReservation
  alias OrbitalDynamics.OperatorReview.TimelineDiff
  alias OrbitalDynamics.OperatorReview.TimelineFeedback
  alias OrbitalDynamics.OperatorReview.TimelineIntegrity
  alias OrbitalDynamics.OperatorReview.TimelineLifecycleState
  alias OrbitalDynamics.OperatorReview.TimelinePrecondition
  alias OrbitalDynamics.OperatorReview.TimelinePreservation
  alias OrbitalDynamics.OperatorReview.TimelinePublication
  alias OrbitalDynamics.OperatorReview.TimelineTransitionApplication
  alias OrbitalDynamics.OperatorReview.ValidationSafetyCase

  @doc """
  Declares the operator-review package model and known limits.
  """
  def capabilities do
    Capabilities.capabilities()
  end

  @doc """
  Builds an `operator_review_package.v1` from a timeline feedback report.
  """
  def from_timeline_feedback_report(%{} = report) do
    TimelineFeedback.package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a standalone realized-activity row.
  """
  def from_realized_activity(%{} = activity) do
    RealizedActivity.package(activity)
  end

  @doc """
  Builds an `operator_review_package.v1` from a realized-state snapshot.
  """
  def from_realized_state_snapshot(%{} = snapshot) do
    RealizedStateSnapshot.package(snapshot)
  end

  @doc """
  Builds an `operator_review_package.v1` from a top-level study result artifact.
  """
  def from_result_artifact(%{} = artifact) do
    ResultArtifact.package(artifact)
  end

  @doc """
  Builds an `operator_review_package.v1` from a standalone maneuver execution delta.
  """
  def from_maneuver_execution_delta(%{} = delta) do
    ManeuverExecutionDelta.package(delta)
  end

  @doc """
  Builds an `operator_review_package.v1` from an operational timeline report.
  """
  def from_operational_timeline_report(%{} = report) do
    OperationalTimeline.report_package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a standalone planned-activity row.
  """
  def from_planned_activity(%{} = activity) do
    OperationalTimeline.planned_activity_package(activity)
  end

  @doc """
  Builds an `operator_review_package.v1` from a timeline diff report.
  """
  def from_timeline_diff_report(%{} = report) do
    TimelineDiff.report_package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a model-only timeline diff summary.
  """
  def from_timeline_diff_summary(%{} = summary) do
    TimelineDiff.summary_package(summary)
  end

  @doc """
  Builds an `operator_review_package.v1` from a timeline dependency-impact summary.
  """
  def from_timeline_dependency_impact_summary(%{} = summary) do
    TimelinePublication.dependency_impact_package(summary)
  end

  @doc """
  Builds an `operator_review_package.v1` from a timeline publication summary.
  """
  def from_timeline_publication_summary(%{} = summary) do
    TimelinePublication.publication_package(summary)
  end

  @doc """
  Builds an `operator_review_package.v1` from a timeline activity precondition summary.
  """
  def from_timeline_activity_precondition_summary(%{} = summary) do
    TimelinePrecondition.package(summary)
  end

  @doc """
  Builds an `operator_review_package.v1` from a timeline lifecycle-state summary.
  """
  def from_timeline_lifecycle_state_summary(%{} = summary) do
    TimelineLifecycleState.summary_package(summary)
  end

  @doc """
  Builds an `operator_review_package.v1` from a compact activity-state artifact.
  """
  def from_timeline_activity_state(%{} = state) do
    TimelineLifecycleState.activity_state_package(state)
  end

  @doc """
  Builds an `operator_review_package.v1` from a single activity status-state artifact.
  """
  def from_timeline_activity_status_state(%{} = state) do
    TimelineLifecycleState.activity_status_state_package(state)
  end

  @doc """
  Builds an `operator_review_package.v1` from a single activity approval-state artifact.
  """
  def from_timeline_activity_approval_state(%{} = state) do
    TimelineLifecycleState.activity_approval_state_package(state)
  end

  @doc """
  Builds an `operator_review_package.v1` from a single activity lifecycle-state artifact.
  """
  def from_timeline_activity_lifecycle_state(%{} = state) do
    TimelineLifecycleState.activity_lifecycle_state_package(state)
  end

  @doc """
  Builds an `operator_review_package.v1` from a timeline preservation report.
  """
  def from_timeline_preservation_report(%{} = report) do
    TimelinePreservation.report_package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a single timeline preservation status artifact.
  """
  def from_timeline_preservation_status(%{} = status) do
    TimelinePreservation.status_package(status)
  end

  @doc """
  Builds an `operator_review_package.v1` from a model-only timeline integrity report.
  """
  def from_timeline_integrity_report(%{} = report) do
    TimelineIntegrity.report_package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a model-only timeline transition-application summary.
  """
  def from_timeline_transition_application_summary(%{} = summary, opts \\ []) do
    TimelineTransitionApplication.summary_package(summary, opts)
  end

  @doc """
  Builds an `operator_review_package.v1` from a timeline transition application report.
  """
  def from_timeline_transition_application_report(%{} = report, opts \\ []) do
    TimelineTransitionApplication.report_package(report, opts)
  end

  @doc """
  Builds an `operator_review_package.v1` from a command-window report.
  """
  def from_command_window_report(%{} = report) do
    CommandWindow.package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a maneuver-review report.
  """
  def from_maneuver_review_report(%{} = report) do
    ManeuverReview.report_package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a standalone maneuver recommendation.
  """
  def from_maneuver_recommendation(%{} = recommendation) do
    ManeuverReview.recommendation_package(recommendation)
  end

  @doc """
  Builds an `operator_review_package.v1` from a station-calendar report.
  """
  def from_station_calendar_report(%{} = report) do
    StationCalendar.package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a station-reservation report.
  """
  def from_station_reservation_report(%{} = report) do
    StationReservation.package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a link-capacity report.
  """
  def from_link_capacity_report(%{} = report) do
    LinkCapacity.package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a contact-allocation report.
  """
  def from_contact_allocation_report(%{} = report) do
    ContactAllocation.report_package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a contact-allocation capacity-pack summary.
  """
  def from_contact_allocation_capacity_pack_summary(%{} = summary) do
    ContactAllocation.capacity_pack_summary_package(summary)
  end

  @doc """
  Builds an `operator_review_package.v1` from a contact-allocation reservation-conflict summary.
  """
  def from_contact_allocation_reservation_conflict_summary(%{} = summary) do
    ContactAllocation.reservation_conflict_summary_package(summary)
  end

  @doc """
  Builds an `operator_review_package.v1` from a standalone contact-intent row.
  """
  def from_contact_intent(%{} = intent) do
    ContactIntent.package(intent)
  end

  @doc """
  Builds an `operator_review_package.v1` from a contact-filter report.
  """
  def from_contact_filter_report(%{} = report) do
    FilterReview.contact_package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a candidate-diff report.
  """
  def from_candidate_diff_report(%{} = report) do
    CandidateDiff.report_package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a candidate-rejection report.
  """
  def from_candidate_rejection_report(%{} = report) do
    CandidateRejection.report_package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a provider-counteroffer report.
  """
  def from_provider_counteroffer_report(%{} = report) do
    ProviderCounteroffer.report_package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a standalone invalidated-candidate row.
  """
  def from_invalidated_candidate(%{} = candidate) do
    CandidateDiff.invalidated_candidate_package(candidate)
  end

  @doc """
  Builds an `operator_review_package.v1` from a resource-filter report.
  """
  def from_resource_filter_report(%{} = report) do
    FilterReview.resource_package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a freshness report.
  """
  def from_freshness_report(%{} = report) do
    RefreshState.freshness_package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a refresh-budget report.
  """
  def from_refresh_budget_report(%{} = report) do
    RefreshState.refresh_budget_package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a model-acceptance report.
  """
  def from_model_acceptance_report(%{} = report) do
    ModelAcceptance.package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a validation safety-case summary.
  """
  def from_validation_safety_case_summary(%{} = summary) do
    ValidationSafetyCase.package(summary)
  end

  @doc """
  Builds an `operator_review_package.v1` from a resource-projection report.
  """
  def from_resource_projection_report(%{} = report) do
    ResourceProjection.report_package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a resource-projection flow summary.
  """
  def from_resource_projection_flow_summary(%{} = summary) do
    ResourceProjection.flow_summary_package(summary)
  end

  @doc """
  Builds an `operator_review_package.v1` from a constraint report.
  """
  def from_constraint_report(%{} = report) do
    ConstraintObjective.constraint_package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from an objective-satisfaction report.
  """
  def from_objective_satisfaction_report(%{} = report) do
    ConstraintObjective.objective_satisfaction_package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a policy-decision artifact.
  """
  def from_policy_decision(%{} = decision) do
    PolicyApproval.policy_decision_package(decision)
  end

  @doc """
  Builds an `operator_review_package.v1` from a standalone approval requirement.
  """
  def from_approval_requirement(%{} = requirement) do
    PolicyApproval.approval_requirement_package(requirement)
  end

  @doc """
  Builds an `operator_review_package.v1` from a contact-contention report.
  """
  def from_contact_contention_report(%{} = report) do
    ContactContention.report_package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a contact-contention resolution report.
  """
  def from_contact_contention_resolution_report(%{} = report) do
    ContactContention.resolution_package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a branch-comparison report.
  """
  def from_branch_comparison_report(%{} = report) do
    BranchComparison.package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a ranking comparison report.
  """
  def from_ranking_comparison_report(%{} = report) do
    OptimizationReview.ranking_comparison_package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a score-term report.
  """
  def from_score_term_report(%{} = report) do
    OptimizationReview.score_term_package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from an objective-tradeoff report.
  """
  def from_objective_tradeoff_report(%{} = report) do
    OptimizationReview.objective_tradeoff_package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a Pareto-frontier report.
  """
  def from_pareto_frontier_report(%{} = report) do
    OptimizationReview.pareto_frontier_package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a schema-validation report.
  """
  def from_schema_validation_report(%{} = report) do
    SchemaValidation.report_package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a schema-validation batch report.
  """
  def from_schema_validation_batch_report(%{} = report) do
    SchemaValidation.batch_package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from an execution report.
  """
  def from_execution_report(%{} = report) do
    ExecutionReport.package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from an operational-readiness report.
  """
  def from_operational_readiness_report(%{} = report) do
    OperationalReadiness.package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a quality-gate report.
  """
  def from_quality_gate_report(%{} = report) do
    QualityGate.package(report)
  end

  @doc """
  Builds an `operator_review_package.v1` from a V1 campaign artifact.
  """
  def from_campaign_artifact(%{} = artifact) do
    CompositeArtifact.campaign_package(artifact)
  end

  @doc """
  Builds an `operator_review_package.v1` from a candidate refresh artifact.
  """
  def from_candidate_refresh_artifact(%{} = artifact) do
    CompositeArtifact.candidate_refresh_package(artifact)
  end

  @doc """
  Builds an `operator_review_package.v1` from a V2 repair artifact.
  """
  def from_repair_artifact(%{} = artifact) do
    CompositeArtifact.repair_package(artifact)
  end

  @doc """
  Builds an `operator_review_package.v1` from a V3 strategy artifact.
  """
  def from_strategy_artifact(%{} = artifact) do
    CompositeArtifact.strategy_package(artifact)
  end
end
