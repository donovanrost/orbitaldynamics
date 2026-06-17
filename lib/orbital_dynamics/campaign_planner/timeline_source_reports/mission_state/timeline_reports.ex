defmodule OrbitalDynamics.CampaignPlanner.TimelineSourceReports.MissionState.TimelineReports do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineSourceReports.ResultArtifacts
  alias OrbitalDynamics.CampaignPlanner.TimelineSourceReports.SourceEntries

  def mission_state_timeline_lifecycle_state_summaries(mission_state, opts) do
    mission_state_source_timeline_lifecycle_state_summaries(mission_state, opts) ++
      mission_state_canonical_timeline_lifecycle_state_summaries(mission_state, opts) ++
      ResultArtifacts.timeline_lifecycle_state_summaries(mission_state, opts)
  end

  def mission_state_source_timeline_lifecycle_state_summaries(mission_state, opts) do
    SourceEntries.mission_state_lifecycle_state_summary_entries(
      mission_state,
      [
        {"source_timeline_lifecycle_state_summary",
         "mission_state.source_timeline_lifecycle_state_summary"}
      ],
      opts
    )
  end

  def mission_state_canonical_timeline_lifecycle_state_summaries(mission_state, opts) do
    SourceEntries.mission_state_lifecycle_state_summary_entries(
      mission_state,
      [{"timeline_lifecycle_state_summary", "mission_state.timeline_lifecycle_state_summary"}],
      opts
    )
  end

  def mission_state_timeline_integrity_reports(mission_state, opts) do
    mission_state_source_timeline_integrity_reports(mission_state, opts) ++
      mission_state_canonical_timeline_integrity_reports(mission_state, opts) ++
      ResultArtifacts.timeline_integrity_reports(mission_state, opts)
  end

  def mission_state_source_timeline_integrity_reports(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [{"source_timeline_integrity_report", "mission_state.source_timeline_integrity_report"}],
      opts
    )
  end

  def mission_state_canonical_timeline_integrity_reports(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [{"timeline_integrity_report", "mission_state.timeline_integrity_report"}],
      opts
    )
  end

  def mission_state_timeline_dependency_impact_summaries(mission_state, opts) do
    mission_state_source_timeline_dependency_impact_summaries(mission_state, opts) ++
      mission_state_canonical_timeline_dependency_impact_summaries(mission_state, opts) ++
      ResultArtifacts.timeline_dependency_impact_summaries(mission_state, opts)
  end

  def mission_state_source_timeline_dependency_impact_summaries(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [
        {"source_timeline_dependency_impact_summary",
         "mission_state.source_timeline_dependency_impact_summary"}
      ],
      opts
    )
  end

  def mission_state_canonical_timeline_dependency_impact_summaries(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [
        {"timeline_dependency_impact_summary", "mission_state.timeline_dependency_impact_summary"}
      ],
      opts
    )
  end

  def mission_state_timeline_publication_summaries(mission_state, opts) do
    mission_state_source_timeline_publication_summaries(mission_state, opts) ++
      mission_state_canonical_timeline_publication_summaries(mission_state, opts) ++
      ResultArtifacts.timeline_publication_summaries(mission_state, opts)
  end

  def mission_state_source_timeline_publication_summaries(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [
        {"source_timeline_publication_summary",
         "mission_state.source_timeline_publication_summary"}
      ],
      opts
    )
  end

  def mission_state_canonical_timeline_publication_summaries(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [{"timeline_publication_summary", "mission_state.timeline_publication_summary"}],
      opts
    )
  end

  def mission_state_timeline_activity_precondition_summaries(mission_state, opts) do
    mission_state_source_timeline_activity_precondition_summaries(mission_state, opts) ++
      mission_state_canonical_timeline_activity_precondition_summaries(mission_state, opts) ++
      ResultArtifacts.timeline_activity_precondition_summaries(mission_state, opts)
  end

  def mission_state_source_timeline_activity_precondition_summaries(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [
        {"source_timeline_activity_precondition_summary",
         "mission_state.source_timeline_activity_precondition_summary"}
      ],
      opts
    )
  end

  def mission_state_canonical_timeline_activity_precondition_summaries(mission_state, opts) do
    SourceEntries.mission_state_source_report_entries(
      mission_state,
      [
        {"timeline_activity_precondition_summary",
         "mission_state.timeline_activity_precondition_summary"}
      ],
      opts
    )
  end
end
