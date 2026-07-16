defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDependencyImpact.SourceFields.TrustBoundaryFields.Values do
  @moduledoc false

  alias __MODULE__.ReportValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      normalize_trust_boundaries: 1
    ]

  def from_reports(reports) when is_list(reports) do
    reports
    |> Enum.flat_map(&ReportValues.values/1)
    |> normalize_trust_boundaries()
  end
end
