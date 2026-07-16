defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineDependencyImpact.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineDependencyImpact.Summary
  alias __MODULE__.Flattened
  alias __MODULE__.Pressure

  def source_report_fields(source_reports) do
    summary =
      source_reports
      |> Map.get("timeline_dependency_impact_summary", %{})
      |> Summary.summary(
        "candidate_refresh.source_report_provenance.timeline_dependency_impact_summary",
        "timeline_dependency_impact_source_report_provenance_only"
      )

    summary
    |> Pressure.source_report_fields()
    |> Map.merge(Flattened.fields(source_reports))
  end
end
