defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.SchemaValidation.SourceFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      source_report_trust_boundaries: 1,
      source_report_trust_boundary_status: 1
    ]

  def fields(sources, reports) do
    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "schema_validation_report.v1",
      "count" => length(sources),
      "row_count" => length(sources),
      "trust_boundary_status" => source_report_trust_boundary_status(reports),
      "trust_boundaries" => source_report_trust_boundaries(reports)
    }
  end
end
