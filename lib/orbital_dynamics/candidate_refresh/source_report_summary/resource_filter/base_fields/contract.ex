defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.BaseFields.Contract do
  @moduledoc false

  def value(reports) do
    reports
    |> Enum.map(&report_contract/1)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> contract_value()
  end

  defp report_contract(report) do
    Map.get(report, "source_summary_schema_contract") || Map.get(report, "schema_contract")
  end

  defp contract_value([contract]), do: contract
  defp contract_value([]), do: nil
  defp contract_value(_contracts), do: "resource_filter_report.v1"
end
