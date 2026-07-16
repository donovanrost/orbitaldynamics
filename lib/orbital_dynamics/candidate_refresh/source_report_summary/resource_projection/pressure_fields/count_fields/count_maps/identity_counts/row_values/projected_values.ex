defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.CountFields.CountMaps.IdentityCounts.RowValues.ProjectedValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.CountFields.CountMaps.IdentityCounts.RowValues.ProjectedRows

  def map(report, value_fun) when is_function(value_fun, 1) do
    report
    |> ProjectedRows.values()
    |> Enum.map(value_fun)
  end

  def flat_map(report, values_fun) when is_function(values_fun, 1) do
    report
    |> ProjectedRows.values()
    |> Enum.flat_map(values_fun)
  end
end
