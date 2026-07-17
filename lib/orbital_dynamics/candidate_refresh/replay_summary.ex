defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary do
  @moduledoc false

  alias __MODULE__.Candidate
  alias __MODULE__.CommandWindow
  alias __MODULE__.Constraint
  alias __MODULE__.ContactAllocation
  alias __MODULE__.ContactContention
  alias __MODULE__.ContactContentionResolution
  alias __MODULE__.ContactFilter
  alias __MODULE__.ContactIntent
  alias __MODULE__.LinkCapacity
  alias __MODULE__.ManeuverReview
  alias __MODULE__.ModelAcceptance
  alias __MODULE__.ObjectiveGap
  alias __MODULE__.OperationalReadiness
  alias __MODULE__.OperationalTimeline
  alias __MODULE__.ProviderCounteroffer
  alias __MODULE__.QualityGate
  alias __MODULE__.ResourceFilter
  alias __MODULE__.ResourceProjection
  alias __MODULE__.StationCalendar
  alias __MODULE__.StationReservation
  alias __MODULE__.StorageDownlinkPressure
  alias __MODULE__.TimelineActivityLifecycleState
  alias __MODULE__.TimelineActivityPrecondition
  alias __MODULE__.TimelineActivitySingleState
  alias __MODULE__.TimelineActivityState
  alias __MODULE__.TimelineDependencyImpact
  alias __MODULE__.TimelineDiff
  alias __MODULE__.TimelineFeedback
  alias __MODULE__.TimelineIntegrity
  alias __MODULE__.TimelineLifecycleState
  alias __MODULE__.TimelinePreservation
  alias __MODULE__.TimelinePublication
  alias __MODULE__.TimelineTransitionApplication
  alias __MODULE__.Validation
  alias __MODULE__.ValidationSafetyCase

  def candidate_diff(refresh_or_artifact) do
    Candidate.diff(refresh_or_artifact)
  end

  def candidate_rejection(refresh_or_artifact) do
    Candidate.rejection(refresh_or_artifact)
  end

  def provider_counteroffer(refresh_or_artifact, source_report_summary) do
    ProviderCounteroffer.replay(refresh_or_artifact, source_report_summary)
  end

  def contact_contention(refresh_or_artifact, source_report_summary) do
    ContactContention.replay(refresh_or_artifact, source_report_summary)
  end

  def contact_contention_resolution(refresh_or_artifact, source_report_summary) do
    ContactContentionResolution.replay(refresh_or_artifact, source_report_summary)
  end

  def contact_allocation(refresh_or_artifact, source_report_summary) do
    ContactAllocation.replay(refresh_or_artifact, source_report_summary)
  end

  def link_capacity(refresh_or_artifact, source_report_summary) do
    LinkCapacity.replay(refresh_or_artifact, source_report_summary)
  end

  def contact_filter(refresh_or_artifact, source_report_summary) do
    ContactFilter.replay(refresh_or_artifact, source_report_summary)
  end

  def resource_filter(refresh_or_artifact) do
    ResourceFilter.replay(refresh_or_artifact)
  end

  def resource_projection(refresh_or_artifact) do
    ResourceProjection.replay(refresh_or_artifact)
  end

  def storage_downlink_pressure(refresh_or_artifact) do
    StorageDownlinkPressure.replay(refresh_or_artifact)
  end

  def station_calendar(refresh_or_artifact) do
    StationCalendar.replay(refresh_or_artifact)
  end

  def station_reservation(refresh_or_artifact) do
    StationReservation.replay(refresh_or_artifact)
  end

  def command_window(refresh_or_artifact, source_report_summary) do
    CommandWindow.replay(refresh_or_artifact, source_report_summary)
  end

  def maneuver_review(refresh_or_artifact, source_report_summary) do
    ManeuverReview.replay(refresh_or_artifact, source_report_summary)
  end

  def contact_intent(refresh_or_artifact, source_report_summary) do
    ContactIntent.replay(refresh_or_artifact, source_report_summary)
  end

  def timeline_activity_state(refresh_or_artifact, source_report_summary) do
    TimelineActivityState.replay(refresh_or_artifact, source_report_summary)
  end

  def timeline_activity_status_state(refresh_or_artifact, source_report_summary) do
    TimelineActivitySingleState.status(refresh_or_artifact, source_report_summary)
  end

  def timeline_activity_approval_state(refresh_or_artifact, source_report_summary) do
    TimelineActivitySingleState.approval(refresh_or_artifact, source_report_summary)
  end

  def timeline_activity_lifecycle_state(refresh_or_artifact, source_report_summary) do
    TimelineActivityLifecycleState.replay(refresh_or_artifact, source_report_summary)
  end

  def timeline_activity_precondition(refresh_or_artifact, source_report_summary) do
    TimelineActivityPrecondition.replay(refresh_or_artifact, source_report_summary)
  end

  def timeline_preservation(refresh_or_artifact) do
    TimelinePreservation.summary(refresh_or_artifact)
  end

  def timeline_diff(refresh_or_artifact, source_report_summary) do
    TimelineDiff.replay(refresh_or_artifact, source_report_summary)
  end

  def timeline_integrity(refresh_or_artifact, source_report_summary) do
    TimelineIntegrity.replay(refresh_or_artifact, source_report_summary)
  end

  def timeline_lifecycle_state(refresh_or_artifact, source_report_summary) do
    TimelineLifecycleState.replay(refresh_or_artifact, source_report_summary)
  end

  def timeline_dependency_impact(refresh_or_artifact, source_report_summary) do
    TimelineDependencyImpact.replay(refresh_or_artifact, source_report_summary)
  end

  def timeline_publication(refresh_or_artifact, source_report_summary) do
    TimelinePublication.replay(refresh_or_artifact, source_report_summary)
  end

  def timeline_transition_application(refresh_or_artifact, source_report_summary) do
    TimelineTransitionApplication.replay(refresh_or_artifact, source_report_summary)
  end

  def objective_gap(refresh_or_artifact) do
    ObjectiveGap.replay(refresh_or_artifact)
  end

  def constraint(refresh_or_artifact) do
    Constraint.replay(refresh_or_artifact)
  end

  def timeline_feedback(refresh_or_artifact, source_report_summary) do
    TimelineFeedback.replay(refresh_or_artifact, source_report_summary)
  end

  def operational_timeline(refresh_or_artifact, source_report_summary) do
    OperationalTimeline.replay(refresh_or_artifact, source_report_summary)
  end

  def operational_readiness(refresh_or_artifact, source_report_summary) do
    OperationalReadiness.replay(refresh_or_artifact, source_report_summary)
  end

  def quality_gate(refresh_or_artifact, source_report_summary) do
    QualityGate.replay(refresh_or_artifact, source_report_summary)
  end

  def model_acceptance(refresh_or_artifact, source_report_summary) do
    ModelAcceptance.replay(refresh_or_artifact, source_report_summary)
  end

  def validation_safety_case(refresh_or_artifact, source_report_summary) do
    ValidationSafetyCase.replay(refresh_or_artifact, source_report_summary)
  end

  def freshness(refresh_or_artifact) do
    Validation.freshness(refresh_or_artifact)
  end

  def refresh_budget(refresh_or_artifact) do
    Validation.refresh_budget(refresh_or_artifact)
  end

  def schema_validation(refresh_or_artifact) do
    Validation.schema_validation(refresh_or_artifact)
  end
end
