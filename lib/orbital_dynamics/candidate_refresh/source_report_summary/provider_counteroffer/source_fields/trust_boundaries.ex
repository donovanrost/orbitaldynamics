defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.SourceFields.TrustBoundaries do
  @moduledoc false

  alias __MODULE__.TrustBoundaryValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      normalize_trust_boundaries: 1,
      source_report_trust_boundaries: 1
    ]

  def status(reports) do
    case values(reports) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  def values(reports) do
    reports
    |> source_report_trust_boundaries()
    |> Kernel.++(row_trust_boundary_values(reports))
    |> normalize_trust_boundaries()
  end

  defp row_trust_boundary_values(reports) do
    reports
    |> Enum.flat_map(fn report ->
      report
      |> Map.get("rows", [])
      |> Enum.flat_map(&TrustBoundaryValues.from_row/1)
    end)
  end
end
