defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.CountFields.CountMaps.PressureCounts.StatusCounts.StatusValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NormalizedToken

  def from_rows(rows) do
    rows
    |> Enum.map(&NormalizedToken.value(Map.get(&1, "resource_pressure_status")))
    |> Enum.reject(&(&1 in [nil, ""]))
  end
end
