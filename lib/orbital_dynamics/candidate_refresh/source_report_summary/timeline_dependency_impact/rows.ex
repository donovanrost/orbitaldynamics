defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDependencyImpact.Rows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NormalizedToken

  def rows(report) do
    report
    |> Map.get("dependency_impact_rows", [])
    |> Enum.map(&stringify/1)
  end

  def stringify(row), do: EncodedValue.stringify_keys(row)

  def row_value(row, "scope"), do: Map.get(row, "scope") || row["dependency_impact_scope"]
  def row_value(row, field), do: Map.get(row, field)

  def row_scope(row) do
    row
    |> row_value("scope")
    |> NormalizedToken.value()
  end
end
