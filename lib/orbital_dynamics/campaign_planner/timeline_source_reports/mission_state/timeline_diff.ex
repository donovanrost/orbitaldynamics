defmodule OrbitalDynamics.CampaignPlanner.TimelineSourceReports.MissionState.TimelineDiff do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineSourceReports.ResultArtifacts
  alias OrbitalDynamics.CampaignPlanner.TimelineSourceReports.SourceEntries

  def mission_state_timeline_diff_reports(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [
        {"source_timeline_diff_report", "mission_state.source_timeline_diff_report"},
        {"timeline_diff_report", "mission_state.timeline_diff_report"}
      ],
      opts
    ) ++
      ResultArtifacts.timeline_diff_reports(mission_state, opts)
  end

  def mission_state_source_timeline_diff_reports(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [{"source_timeline_diff_report", "mission_state.source_timeline_diff_report"}],
      opts
    )
  end

  def mission_state_canonical_timeline_diff_reports(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [{"timeline_diff_report", "mission_state.timeline_diff_report"}],
      opts
    )
  end

  def mission_state_source_timeline_diff_summaries(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [{"source_timeline_diff_summary", "mission_state.source_timeline_diff_summary"}],
      opts
    )
  end

  def mission_state_canonical_timeline_diff_summaries(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [{"timeline_diff_summary", "mission_state.timeline_diff_summary"}],
      opts
    )
  end
end
