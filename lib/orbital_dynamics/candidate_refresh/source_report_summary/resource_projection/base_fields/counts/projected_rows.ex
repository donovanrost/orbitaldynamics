defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.BaseFields.Counts.ProjectedRows do
  @moduledoc false

  def values(report), do: Map.get(report, "projected_resources", [])
end
