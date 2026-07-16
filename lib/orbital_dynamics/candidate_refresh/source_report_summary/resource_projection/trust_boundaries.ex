defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.TrustBoundaries do
  @moduledoc false

  alias __MODULE__.NormalizedValues
  alias __MODULE__.ReportBoundaryValues

  def status(reports) do
    case values(reports) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  def values(reports) when is_list(reports) do
    reports
    |> Enum.flat_map(&values/1)
    |> NormalizedValues.sorted_unique()
  end

  def values(%{"projected_resources" => rows} = report) when is_list(rows) do
    ReportBoundaryValues.values(report)
  end

  def values(_report), do: []
end
