defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContentionResolution.SourceFields.Contracts do
  @moduledoc false

  def value(reports) do
    reports
    |> Enum.map(&report_contract/1)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> case do
      [contract] -> contract
      [] -> nil
      _contracts -> "contact_contention_resolution_report.v1"
    end
  end

  defp report_contract(report) do
    Map.get(report, "source_summary_schema_contract") || Map.get(report, "schema_contract")
  end
end
