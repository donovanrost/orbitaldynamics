defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelinePublication.SourceFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      source_report_trust_boundaries: 1,
      source_report_trust_boundary_status: 1
    ]

  def fields(sources, summaries) do
    %{
      "paths" => Enum.map(sources, fn {path, _summary} -> path end),
      "contract" => "timeline_publication_summary.v1",
      "count" => length(sources),
      "row_count" => length(sources),
      "trust_boundary_status" => source_report_trust_boundary_status(summaries),
      "trust_boundaries" => source_report_trust_boundaries(summaries)
    }
  end
end
