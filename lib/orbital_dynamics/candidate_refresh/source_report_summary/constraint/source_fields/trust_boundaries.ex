defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Constraint.SourceFields.TrustBoundaries do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Constraint.RowFields

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

  def values(reports) when is_list(reports) do
    reports
    |> Enum.flat_map(&report_trust_boundaries/1)
    |> normalize_trust_boundaries()
  end

  defp report_trust_boundaries(%{"rows" => rows} = report) when is_list(rows) do
    rows
    |> RowFields.row_trust_boundaries(report)
    |> Kernel.++(source_report_trust_boundaries([report]))
  end

  defp report_trust_boundaries(%{} = report) do
    source_report_trust_boundaries([report])
  end
end
