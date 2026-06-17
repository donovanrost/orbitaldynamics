defmodule OrbitalDynamics.CampaignPlanner.TimelineSourceReports.MissionState.ActivityStates do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineSourceReports.ResultArtifacts
  alias OrbitalDynamics.CampaignPlanner.TimelineSourceReports.SourceEntries

  def mission_state_timeline_activity_lifecycle_states(mission_state, opts) do
    mission_state_source_timeline_activity_lifecycle_states(mission_state, opts) ++
      mission_state_canonical_timeline_activity_lifecycle_states(mission_state, opts) ++
      ResultArtifacts.timeline_activity_lifecycle_states(mission_state, opts)
  end

  def mission_state_source_timeline_activity_lifecycle_states(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [
        {"source_timeline_activity_lifecycle_state",
         "mission_state.source_timeline_activity_lifecycle_state"}
      ],
      opts
    )
  end

  def mission_state_canonical_timeline_activity_lifecycle_states(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [{"timeline_activity_lifecycle_state", "mission_state.timeline_activity_lifecycle_state"}],
      opts
    )
  end

  def mission_state_source_timeline_activity_states(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [{"source_timeline_activity_state", "mission_state.source_timeline_activity_state"}],
      opts
    )
  end

  def mission_state_canonical_timeline_activity_states(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [{"timeline_activity_state", "mission_state.timeline_activity_state"}],
      opts
    )
  end

  def mission_state_source_timeline_activity_status_states(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [
        {"source_timeline_activity_status_state",
         "mission_state.source_timeline_activity_status_state"}
      ],
      opts
    )
  end

  def mission_state_canonical_timeline_activity_status_states(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [{"timeline_activity_status_state", "mission_state.timeline_activity_status_state"}],
      opts
    )
  end

  def mission_state_source_timeline_activity_approval_states(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [
        {"source_timeline_activity_approval_state",
         "mission_state.source_timeline_activity_approval_state"}
      ],
      opts
    )
  end

  def mission_state_canonical_timeline_activity_approval_states(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [{"timeline_activity_approval_state", "mission_state.timeline_activity_approval_state"}],
      opts
    )
  end
end
