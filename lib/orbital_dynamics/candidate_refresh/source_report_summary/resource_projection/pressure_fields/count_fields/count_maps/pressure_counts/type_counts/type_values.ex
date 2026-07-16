defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.CountFields.CountMaps.PressureCounts.TypeCounts.TypeValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureIdRouting

  def from_report(report) do
    report
    |> PressureIdRouting.normalized_projected_resource_rows()
    |> Enum.flat_map(&(PressureIdRouting.pressure_types(&1) || []))
  end
end
