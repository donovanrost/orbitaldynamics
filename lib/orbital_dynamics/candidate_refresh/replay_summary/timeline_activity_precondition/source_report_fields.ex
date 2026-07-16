defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivityPrecondition.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivityPrecondition.Summary
  alias __MODULE__.Flattened
  alias __MODULE__.Pressure

  def source_report_fields(source_reports) do
    summary =
      source_reports
      |> Map.get("timeline_activity_precondition_summary", %{})
      |> Summary.summary(
        "candidate_refresh.source_report_provenance.timeline_activity_precondition_summary",
        "timeline_activity_precondition_summary_source_report_provenance_only"
      )

    summary
    |> Pressure.source_report_fields()
    |> Map.merge(Flattened.source_report_fields(source_reports))
  end
end
