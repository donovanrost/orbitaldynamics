defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineLifecycleState.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineLifecycleState.Summary
  alias __MODULE__.Flattened
  alias __MODULE__.Pressure

  def source_report_fields(source_reports) do
    summary =
      source_reports
      |> Map.get("timeline_lifecycle_state_summary", %{})
      |> Summary.summary(
        "candidate_refresh.source_report_provenance.timeline_lifecycle_state_summary",
        "timeline_lifecycle_state_source_report_provenance_only"
      )

    summary
    |> Pressure.source_report_fields()
    |> Map.merge(Flattened.source_report_fields(source_reports))
  end
end
