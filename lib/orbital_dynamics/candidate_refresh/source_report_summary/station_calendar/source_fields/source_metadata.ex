defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.SourceFields.SourceMetadata do
  @moduledoc false

  alias __MODULE__.TrustBoundaries

  @fallback_contract "station_calendar_report.v1"

  def contract(reports) do
    reports
    |> Enum.map(&contract_value/1)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> contract_from_values()
  end

  def trust_boundary_fields(reports) do
    TrustBoundaries.fields(reports)
  end

  defp contract_value(report) do
    Map.get(report, "source_summary_schema_contract") || Map.get(report, "schema_contract")
  end

  defp contract_from_values([contract]), do: contract
  defp contract_from_values([]), do: nil
  defp contract_from_values(_contracts), do: @fallback_contract
end
