defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.BaseFields.ReportValues do
  @moduledoc false

  alias __MODULE__.CountFields

  def count_fields(reports) do
    CountFields.fields(reports)
  end

  def input_summary_contract(reports) do
    reports
    |> Enum.map(fn report ->
      Map.get(report, "source_summary_schema_contract") || Map.get(report, "schema_contract")
    end)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> case do
      [contract] -> contract
      [] -> nil
      _contracts -> "operational_readiness_report.v1"
    end
  end
end
