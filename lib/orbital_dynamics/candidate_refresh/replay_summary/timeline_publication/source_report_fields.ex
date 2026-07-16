defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePublication.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePublication.Summary
  alias __MODULE__.Flattened
  alias __MODULE__.Pressure

  def source_report_fields(source_reports) do
    summary =
      source_reports
      |> Map.get("timeline_publication_summary", %{})
      |> Summary.summary(
        "candidate_refresh.source_report_provenance.timeline_publication_summary",
        "timeline_publication_source_report_provenance_only"
      )

    summary
    |> Pressure.source_report_fields()
    |> Map.merge(Flattened.source_report_fields(source_reports))
  end
end
