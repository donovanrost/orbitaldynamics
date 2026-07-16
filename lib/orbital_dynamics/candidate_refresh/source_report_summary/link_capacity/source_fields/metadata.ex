defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.SourceFields.Metadata do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.SourceFields.TrustBoundaries

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_report_field_values: 2]

  def count_field_values(reports, field) do
    count_report_field_values(reports, field)
  end

  def contract(reports) do
    reports
    |> Enum.map(&contract_value/1)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> contract_result()
  end

  def trust_boundary_status(reports) do
    case TrustBoundaries.trust_boundaries(reports) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  defp contract_value(report) do
    Map.get(report, "source_summary_schema_contract") || Map.get(report, "schema_contract")
  end

  defp contract_result([contract]), do: contract
  defp contract_result([]), do: nil
  defp contract_result(_contracts), do: "link_capacity_report.v1"
end
