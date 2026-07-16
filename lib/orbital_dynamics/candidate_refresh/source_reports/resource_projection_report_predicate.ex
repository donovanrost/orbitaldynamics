defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionReportPredicate do
  @moduledoc false

  def report?(%{} = report) do
    rows = Map.get(report, "projected_resources") || Map.get(report, :projected_resources)
    schema_contract = Map.get(report, "schema_contract") || Map.get(report, :schema_contract)

    is_list(rows) and schema_contract in [nil, "resource_projection_report.v1"]
  end

  def report?(_report), do: false
end
