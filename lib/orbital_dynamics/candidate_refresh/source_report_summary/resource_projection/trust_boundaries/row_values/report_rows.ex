defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.TrustBoundaries.RowValues.ReportRows do
  @moduledoc false

  def values(report) do
    report
    |> Map.get("projected_resources", [])
    |> Kernel.++(Map.get(report, "invalid_activity_inputs", []))
    |> Kernel.++(Map.get(report, "invalid_resource_summary_inputs", []))
  end
end
