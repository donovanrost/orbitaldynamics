defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.CountFields.CountMaps.IdentityCounts.RowValues.ProjectedRows do
  @moduledoc false

  def values(report), do: Map.get(report, "projected_resources", [])
end
