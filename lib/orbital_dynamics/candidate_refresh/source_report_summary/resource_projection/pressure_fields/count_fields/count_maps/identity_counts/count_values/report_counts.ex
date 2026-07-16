defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.CountFields.CountMaps.IdentityCounts.CountValues.ReportCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.CountFields.CountMaps.IdentityCounts.CountValues.ValueCounts

  def from_report(report, row_values_fun) when is_function(row_values_fun, 1) do
    report
    |> row_values_fun.()
    |> ValueCounts.from_values()
  end
end
