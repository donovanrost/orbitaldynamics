defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.SourceFields.Metadata.Contract do
  @moduledoc false

  def timeline_diff(reports) do
    reports
    |> Enum.map(&report_contract/1)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> timeline_diff_result()
  end

  defp report_contract(report) do
    Map.get(report, "source_summary_schema_contract") || Map.get(report, "schema_contract")
  end

  defp timeline_diff_result([contract]), do: contract
  defp timeline_diff_result([]), do: nil
  defp timeline_diff_result(_contracts), do: "timeline_diff_report.v1"
end
