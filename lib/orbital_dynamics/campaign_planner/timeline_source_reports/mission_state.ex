defmodule OrbitalDynamics.CampaignPlanner.TimelineSourceReports.MissionState do
  @moduledoc false

  alias __MODULE__.{
    ActivityStates,
    Preservation,
    TimelineDiff,
    TimelineReports,
    TransitionApplications
  }

  def mission_state_timeline_diff_reports(mission_state, opts) do
    TimelineDiff.mission_state_timeline_diff_reports(mission_state, opts)
  end

  def mission_state_source_timeline_diff_reports(mission_state, opts) do
    TimelineDiff.mission_state_source_timeline_diff_reports(mission_state, opts)
  end

  def mission_state_canonical_timeline_diff_reports(mission_state, opts) do
    TimelineDiff.mission_state_canonical_timeline_diff_reports(mission_state, opts)
  end

  def mission_state_source_timeline_diff_summaries(mission_state, opts) do
    TimelineDiff.mission_state_source_timeline_diff_summaries(mission_state, opts)
  end

  def mission_state_canonical_timeline_diff_summaries(mission_state, opts) do
    TimelineDiff.mission_state_canonical_timeline_diff_summaries(mission_state, opts)
  end

  def mission_state_timeline_transition_application_reports(mission_state, opts) do
    TransitionApplications.mission_state_timeline_transition_application_reports(
      mission_state,
      opts
    )
  end

  def mission_state_source_timeline_transition_application_reports(mission_state, opts) do
    TransitionApplications.mission_state_source_timeline_transition_application_reports(
      mission_state,
      opts
    )
  end

  def mission_state_canonical_timeline_transition_application_reports(mission_state, opts) do
    TransitionApplications.mission_state_canonical_timeline_transition_application_reports(
      mission_state,
      opts
    )
  end

  def mission_state_timeline_lifecycle_state_summaries(mission_state, opts) do
    TimelineReports.mission_state_timeline_lifecycle_state_summaries(mission_state, opts)
  end

  def mission_state_source_timeline_lifecycle_state_summaries(mission_state, opts) do
    TimelineReports.mission_state_source_timeline_lifecycle_state_summaries(mission_state, opts)
  end

  def mission_state_canonical_timeline_lifecycle_state_summaries(mission_state, opts) do
    TimelineReports.mission_state_canonical_timeline_lifecycle_state_summaries(
      mission_state,
      opts
    )
  end

  def mission_state_timeline_integrity_reports(mission_state, opts) do
    TimelineReports.mission_state_timeline_integrity_reports(mission_state, opts)
  end

  def mission_state_source_timeline_integrity_reports(mission_state, opts) do
    TimelineReports.mission_state_source_timeline_integrity_reports(mission_state, opts)
  end

  def mission_state_canonical_timeline_integrity_reports(mission_state, opts) do
    TimelineReports.mission_state_canonical_timeline_integrity_reports(mission_state, opts)
  end

  def mission_state_timeline_dependency_impact_summaries(mission_state, opts) do
    TimelineReports.mission_state_timeline_dependency_impact_summaries(mission_state, opts)
  end

  def mission_state_source_timeline_dependency_impact_summaries(mission_state, opts) do
    TimelineReports.mission_state_source_timeline_dependency_impact_summaries(mission_state, opts)
  end

  def mission_state_canonical_timeline_dependency_impact_summaries(mission_state, opts) do
    TimelineReports.mission_state_canonical_timeline_dependency_impact_summaries(
      mission_state,
      opts
    )
  end

  def mission_state_timeline_publication_summaries(mission_state, opts) do
    TimelineReports.mission_state_timeline_publication_summaries(mission_state, opts)
  end

  def mission_state_source_timeline_publication_summaries(mission_state, opts) do
    TimelineReports.mission_state_source_timeline_publication_summaries(mission_state, opts)
  end

  def mission_state_canonical_timeline_publication_summaries(mission_state, opts) do
    TimelineReports.mission_state_canonical_timeline_publication_summaries(mission_state, opts)
  end

  def mission_state_source_timeline_transition_application_summaries(mission_state, opts) do
    TransitionApplications.mission_state_source_timeline_transition_application_summaries(
      mission_state,
      opts
    )
  end

  def mission_state_canonical_timeline_transition_application_summaries(mission_state, opts) do
    TransitionApplications.mission_state_canonical_timeline_transition_application_summaries(
      mission_state,
      opts
    )
  end

  def mission_state_timeline_activity_precondition_summaries(mission_state, opts) do
    TimelineReports.mission_state_timeline_activity_precondition_summaries(mission_state, opts)
  end

  def mission_state_source_timeline_activity_precondition_summaries(mission_state, opts) do
    TimelineReports.mission_state_source_timeline_activity_precondition_summaries(
      mission_state,
      opts
    )
  end

  def mission_state_canonical_timeline_activity_precondition_summaries(mission_state, opts) do
    TimelineReports.mission_state_canonical_timeline_activity_precondition_summaries(
      mission_state,
      opts
    )
  end

  def mission_state_timeline_preservation_reports(mission_state, opts) do
    Preservation.mission_state_timeline_preservation_reports(mission_state, opts)
  end

  def mission_state_source_timeline_preservation_reports(mission_state, opts) do
    Preservation.mission_state_source_timeline_preservation_reports(mission_state, opts)
  end

  def mission_state_canonical_timeline_preservation_reports(mission_state, opts) do
    Preservation.mission_state_canonical_timeline_preservation_reports(mission_state, opts)
  end

  def mission_state_timeline_preservation_statuses(mission_state, opts) do
    Preservation.mission_state_timeline_preservation_statuses(mission_state, opts)
  end

  def mission_state_source_timeline_preservation_statuses(mission_state, opts) do
    Preservation.mission_state_source_timeline_preservation_statuses(mission_state, opts)
  end

  def mission_state_canonical_timeline_preservation_statuses(mission_state, opts) do
    Preservation.mission_state_canonical_timeline_preservation_statuses(mission_state, opts)
  end

  def mission_state_timeline_activity_lifecycle_states(mission_state, opts) do
    ActivityStates.mission_state_timeline_activity_lifecycle_states(mission_state, opts)
  end

  def mission_state_source_timeline_activity_lifecycle_states(mission_state, opts) do
    ActivityStates.mission_state_source_timeline_activity_lifecycle_states(mission_state, opts)
  end

  def mission_state_canonical_timeline_activity_lifecycle_states(mission_state, opts) do
    ActivityStates.mission_state_canonical_timeline_activity_lifecycle_states(mission_state, opts)
  end

  def mission_state_source_timeline_activity_states(mission_state, opts) do
    ActivityStates.mission_state_source_timeline_activity_states(mission_state, opts)
  end

  def mission_state_canonical_timeline_activity_states(mission_state, opts) do
    ActivityStates.mission_state_canonical_timeline_activity_states(mission_state, opts)
  end

  def mission_state_source_timeline_activity_status_states(mission_state, opts) do
    ActivityStates.mission_state_source_timeline_activity_status_states(mission_state, opts)
  end

  def mission_state_canonical_timeline_activity_status_states(mission_state, opts) do
    ActivityStates.mission_state_canonical_timeline_activity_status_states(mission_state, opts)
  end

  def mission_state_source_timeline_activity_approval_states(mission_state, opts) do
    ActivityStates.mission_state_source_timeline_activity_approval_states(mission_state, opts)
  end

  def mission_state_canonical_timeline_activity_approval_states(mission_state, opts) do
    ActivityStates.mission_state_canonical_timeline_activity_approval_states(mission_state, opts)
  end
end
