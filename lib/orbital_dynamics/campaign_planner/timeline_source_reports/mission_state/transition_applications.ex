defmodule OrbitalDynamics.CampaignPlanner.TimelineSourceReports.MissionState.TransitionApplications do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineSourceReports.ResultArtifacts
  alias OrbitalDynamics.CampaignPlanner.TimelineSourceReports.SourceEntries

  def mission_state_timeline_transition_application_reports(mission_state, opts) do
    mission_state_source_timeline_transition_application_reports(mission_state, opts) ++
      mission_state_canonical_timeline_transition_application_reports(mission_state, opts) ++
      ResultArtifacts.timeline_transition_application_reports(mission_state, opts)
  end

  def mission_state_source_timeline_transition_application_reports(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [
        {"source_timeline_transition_application_report",
         "mission_state.source_timeline_transition_application_report.applications"}
      ],
      opts
    )
  end

  def mission_state_canonical_timeline_transition_application_reports(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [
        {"timeline_transition_application_report",
         "mission_state.timeline_transition_application_report.applications"}
      ],
      opts
    )
  end

  def mission_state_source_timeline_transition_application_summaries(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [
        {"source_timeline_transition_application_summary",
         "mission_state.source_timeline_transition_application_summary"}
      ],
      opts
    )
  end

  def mission_state_canonical_timeline_transition_application_summaries(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [
        {"timeline_transition_application_summary",
         "mission_state.timeline_transition_application_summary"}
      ],
      opts
    )
  end
end
