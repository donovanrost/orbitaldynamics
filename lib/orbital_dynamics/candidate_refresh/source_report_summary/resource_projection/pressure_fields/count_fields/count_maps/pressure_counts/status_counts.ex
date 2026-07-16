defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.CountFields.CountMaps.PressureCounts.StatusCounts do
  @moduledoc false

  alias __MODULE__.StatusValues

  def from_report(report) do
    report
    |> projected_resource_rows()
    |> from_rows()
  end

  def from_rows(rows) do
    rows
    |> StatusValues.from_rows()
    |> Enum.frequencies()
  end

  defp projected_resource_rows(report), do: Map.get(report, "projected_resources", [])
end
