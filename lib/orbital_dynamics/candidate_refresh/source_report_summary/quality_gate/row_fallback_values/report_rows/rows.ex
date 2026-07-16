defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.RowFallbackValues.ReportRows.Rows do
  @moduledoc false

  def values(report) do
    report
    |> Map.get("rows", [])
    |> Enum.filter(&is_map/1)
  end
end
