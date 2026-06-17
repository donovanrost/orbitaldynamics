defmodule OrbitalDynamics.CampaignPlanner.TimelineSourceReports.MissionState.Preservation do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineSourceReports.ResultArtifacts
  alias OrbitalDynamics.CampaignPlanner.TimelineSourceReports.SourceEntries

  def mission_state_timeline_preservation_reports(mission_state, opts) do
    mission_state_source_timeline_preservation_reports(mission_state, opts) ++
      mission_state_canonical_timeline_preservation_reports(mission_state, opts) ++
      ResultArtifacts.timeline_preservation_reports(mission_state, opts)
  end

  def mission_state_source_timeline_preservation_reports(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [
        {"source_timeline_preservation_report",
         "mission_state.source_timeline_preservation_report"}
      ],
      opts
    )
  end

  def mission_state_canonical_timeline_preservation_reports(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [{"timeline_preservation_report", "mission_state.timeline_preservation_report"}],
      opts
    )
  end

  def mission_state_timeline_preservation_statuses(mission_state, opts) do
    mission_state_source_timeline_preservation_statuses(mission_state, opts) ++
      mission_state_canonical_timeline_preservation_statuses(mission_state, opts) ++
      ResultArtifacts.timeline_preservation_statuses(mission_state, opts)
  end

  def mission_state_source_timeline_preservation_statuses(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [
        {"source_timeline_preservation_status",
         "mission_state.source_timeline_preservation_status"}
      ],
      opts
    )
  end

  def mission_state_canonical_timeline_preservation_statuses(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [{"timeline_preservation_status", "mission_state.timeline_preservation_status"}],
      opts
    )
  end
end
