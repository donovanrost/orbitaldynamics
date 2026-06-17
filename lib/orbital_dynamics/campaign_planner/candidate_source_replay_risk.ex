defmodule OrbitalDynamics.CampaignPlanner.CandidateSourceReplayRisk do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh

  alias OrbitalDynamics.CampaignPlanner.{
    CandidateSourceContactAllocationReplayRisk,
    CandidateSourceDiffReplayRisk,
    CandidateSourceLinkCapacityReplayRisk,
    CandidateSourceOperationalReadinessReplayRisk,
    CandidateSourceProviderCounterofferReplayRisk,
    CandidateSourceRejectionFilterReplayRisk,
    CandidateSourceReportReplayRisk,
    CandidateSourceStationCalendarReplayRisk,
    CandidateSourceTimelineReplayRisk,
    CandidateSourceValidationReplayRisk,
    StrategyPressureRisk
  }

  def indicators(%{"scope" => scope} = candidate_source, event_risks)
      when scope in ["branch", "branch_generated"] do
    replays = replay_summaries(candidate_source)

    []
    |> maybe_add(
      replays.contact_allocation,
      event_risks,
      &StrategyPressureRisk.contact_allocation_pressure_risk?/1,
      fn replay_summary ->
        CandidateSourceContactAllocationReplayRisk.reservation_conflict(replay_summary) ++
          CandidateSourceContactAllocationReplayRisk.provider_reservation(replay_summary)
      end
    )
    |> maybe_add(
      replays.candidate_diff,
      event_risks,
      &StrategyPressureRisk.candidate_diff_event_pressure_risk?/1,
      &CandidateSourceDiffReplayRisk.candidate_diff/1
    )
    |> maybe_add(
      replays.timeline_diff,
      event_risks,
      &StrategyPressureRisk.timeline_diff_event_pressure_risk?/1,
      &CandidateSourceDiffReplayRisk.timeline_diff/1
    )
    |> maybe_add(
      replays.candidate_rejection,
      event_risks,
      &StrategyPressureRisk.candidate_rejection_pressure_risk?/1,
      &CandidateSourceRejectionFilterReplayRisk.candidate_rejection/1
    )
    |> maybe_add(
      replays.contact_filter,
      event_risks,
      &StrategyPressureRisk.contact_filter_pressure_risk?/1,
      &CandidateSourceRejectionFilterReplayRisk.contact_filter/1
    )
    |> maybe_add(
      replays.command_window,
      event_risks,
      &(&1["feedback_scope"] == "command_window"),
      &CandidateSourceReportReplayRisk.command_window/1
    )
    |> maybe_add(
      replays.objective_gap,
      event_risks,
      &StrategyPressureRisk.objective_gap_event_pressure_risk?/1,
      &CandidateSourceReportReplayRisk.objective_gap/1
    )
    |> maybe_add(
      replays.timeline_feedback,
      event_risks,
      &StrategyPressureRisk.timeline_feedback_event_pressure_risk?/1,
      &CandidateSourceReportReplayRisk.timeline_feedback/1
    )
    |> maybe_add(
      replays.operational_timeline,
      event_risks,
      &StrategyPressureRisk.operational_timeline_event_pressure_risk?/1,
      &CandidateSourceReportReplayRisk.operational_timeline/1
    )
    |> maybe_add(
      replays.maneuver_review,
      event_risks,
      &(&1["feedback_scope"] == "maneuver_review"),
      &CandidateSourceReportReplayRisk.maneuver_review/1
    )
    |> maybe_add(
      replays.link_capacity,
      event_risks,
      &StrategyPressureRisk.link_capacity_pressure_risk?/1,
      &CandidateSourceLinkCapacityReplayRisk.link_capacity/1
    )
    |> maybe_add(
      replays.station_calendar,
      event_risks,
      &StrategyPressureRisk.station_calendar_pressure_risk?/1,
      &CandidateSourceStationCalendarReplayRisk.station_calendar/1
    )
    |> maybe_add(
      replays.operational_readiness,
      event_risks,
      &StrategyPressureRisk.operational_readiness_pressure_event_risk?/1,
      &CandidateSourceOperationalReadinessReplayRisk.operational_readiness/1
    )
    |> maybe_add(
      replays.provider_counteroffer,
      event_risks,
      &StrategyPressureRisk.provider_counteroffer_pressure_risk?/1,
      &CandidateSourceProviderCounterofferReplayRisk.provider_counteroffer/1
    )
    |> maybe_add(
      replays.quality_gate,
      event_risks,
      &StrategyPressureRisk.quality_gate_pressure_event_risk?/1,
      &CandidateSourceValidationReplayRisk.quality_gate/1
    )
    |> maybe_add(
      replays.schema_validation,
      event_risks,
      &StrategyPressureRisk.schema_validation_pressure_risk?/1,
      &CandidateSourceValidationReplayRisk.schema_validation/1
    )
    |> maybe_add(
      replays.freshness,
      event_risks,
      &StrategyPressureRisk.refresh_freshness_pressure_risk?/1,
      &CandidateSourceValidationReplayRisk.freshness/1
    )
    |> maybe_add(
      replays.refresh_budget,
      event_risks,
      &StrategyPressureRisk.refresh_budget_pressure_risk?/1,
      &CandidateSourceValidationReplayRisk.refresh_budget/1
    )
    |> maybe_add(
      replays.validation_safety_case,
      event_risks,
      &StrategyPressureRisk.validation_safety_case_pressure_risk?/1,
      &CandidateSourceValidationReplayRisk.validation_safety_case/1
    )
    |> maybe_add(
      replays.model_acceptance,
      event_risks,
      &StrategyPressureRisk.model_acceptance_pressure_risk?/1,
      &CandidateSourceValidationReplayRisk.model_acceptance/1
    )
    |> maybe_add(
      replays.activity_state,
      event_risks,
      &StrategyPressureRisk.timeline_activity_lifecycle_state_review_risk?/1,
      &CandidateSourceTimelineReplayRisk.activity_state/1
    )
    |> maybe_add(
      replays.dependency_impact,
      event_risks,
      &StrategyPressureRisk.timeline_dependency_impact_pressure_risk?/1,
      &CandidateSourceTimelineReplayRisk.dependency_impact/1
    )
    |> maybe_add(
      replays.precondition,
      event_risks,
      &StrategyPressureRisk.timeline_precondition_pressure_risk?/1,
      &CandidateSourceTimelineReplayRisk.precondition/1
    )
    |> maybe_add(
      replays.integrity,
      event_risks,
      &StrategyPressureRisk.timeline_integrity_pressure_risk?/1,
      &CandidateSourceTimelineReplayRisk.integrity/1
    )
    |> maybe_add(
      replays.lifecycle,
      event_risks,
      &StrategyPressureRisk.timeline_lifecycle_state_review_risk?/1,
      &CandidateSourceTimelineReplayRisk.lifecycle/1
    )
    |> maybe_add(
      replays.publication,
      event_risks,
      &StrategyPressureRisk.timeline_publication_pressure_risk?/1,
      &CandidateSourceTimelineReplayRisk.publication/1
    )
    |> maybe_add(
      replays.transition_application,
      event_risks,
      &StrategyPressureRisk.timeline_transition_application_pressure_risk?/1,
      &CandidateSourceTimelineReplayRisk.transition_application/1
    )
  end

  def indicators(_candidate_source, _event_risks), do: []

  defp replay_summaries(candidate_source) do
    %{
      contact_allocation: CandidateRefresh.contact_allocation_replay_summary(candidate_source),
      candidate_diff: CandidateRefresh.candidate_diff_replay_summary(candidate_source),
      timeline_diff: CandidateRefresh.timeline_diff_replay_summary(candidate_source),
      candidate_rejection: CandidateRefresh.candidate_rejection_replay_summary(candidate_source),
      contact_filter: CandidateRefresh.contact_filter_replay_summary(candidate_source),
      command_window: CandidateRefresh.command_window_replay_summary(candidate_source),
      objective_gap: CandidateRefresh.objective_gap_replay_summary(candidate_source),
      timeline_feedback: CandidateRefresh.timeline_feedback_replay_summary(candidate_source),
      operational_timeline:
        CandidateRefresh.operational_timeline_replay_summary(candidate_source),
      maneuver_review: CandidateRefresh.maneuver_review_replay_summary(candidate_source),
      link_capacity: CandidateRefresh.link_capacity_replay_summary(candidate_source),
      station_calendar: CandidateRefresh.station_calendar_replay_summary(candidate_source),
      operational_readiness:
        CandidateRefresh.operational_readiness_replay_summary(candidate_source),
      provider_counteroffer:
        CandidateRefresh.provider_counteroffer_replay_summary(candidate_source),
      quality_gate: CandidateRefresh.quality_gate_replay_summary(candidate_source),
      schema_validation: CandidateRefresh.schema_validation_replay_summary(candidate_source),
      freshness: CandidateRefresh.freshness_replay_summary(candidate_source),
      refresh_budget: CandidateRefresh.refresh_budget_replay_summary(candidate_source),
      validation_safety_case:
        CandidateRefresh.validation_safety_case_replay_summary(candidate_source),
      model_acceptance: CandidateRefresh.model_acceptance_replay_summary(candidate_source),
      lifecycle: CandidateRefresh.timeline_lifecycle_state_replay_summary(candidate_source),
      dependency_impact:
        CandidateRefresh.timeline_dependency_impact_replay_summary(candidate_source),
      precondition:
        CandidateRefresh.timeline_activity_precondition_replay_summary(candidate_source),
      integrity: CandidateRefresh.timeline_integrity_replay_summary(candidate_source),
      activity_state: CandidateRefresh.timeline_activity_state_replay_summary(candidate_source),
      publication: CandidateRefresh.timeline_publication_replay_summary(candidate_source),
      transition_application:
        CandidateRefresh.timeline_transition_application_replay_summary(candidate_source)
    }
  end

  defp maybe_add(risks, replay_summary, event_risks, event_risk?, replay_risks) do
    if Enum.any?(event_risks, event_risk?) do
      risks
    else
      risks ++ replay_risks.(replay_summary)
    end
  end
end
