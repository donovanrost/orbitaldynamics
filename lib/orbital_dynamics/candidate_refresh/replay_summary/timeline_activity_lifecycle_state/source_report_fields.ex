defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivityLifecycleState.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivityLifecycleState.Summary
  alias __MODULE__.Flattened
  alias __MODULE__.Pressure

  def source_report_fields(source_reports) do
    summary =
      source_reports
      |> Map.get("timeline_activity_lifecycle_state", %{})
      |> Summary.summary(
        "candidate_refresh.source_report_provenance.timeline_activity_lifecycle_state",
        "timeline_activity_lifecycle_state_source_report_provenance_only"
      )

    summary
    |> Pressure.source_report_fields()
    |> Map.merge(Flattened.source_report_fields(source_reports))
  end
end
