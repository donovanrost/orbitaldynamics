defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.OperationalTimeline.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.OperationalTimeline.Summary

  alias __MODULE__.Flattened
  alias __MODULE__.Pressure

  def source_report_summary_fields(source_reports) do
    source_reports
    |> Map.get("operational_timeline_report", %{})
    |> Summary.summary(
      "candidate_refresh.source_report_provenance.operational_timeline_report",
      "operational_timeline_source_report_provenance_only"
    )
    |> then(&source_report_fields(source_reports, &1))
  end

  def source_report_fields(source_reports, summary) do
    summary
    |> Pressure.source_report_fields()
    |> Map.merge(Flattened.fields(source_reports))
  end
end
