defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.Evidence.Values.EvidenceMap do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [numeric_report_count: 2]

  def count(report, field) do
    report
    |> evidence()
    |> numeric_report_count(field)
  end

  def count_map(report, field) do
    case report |> evidence() |> Map.get(field) do
      %{} = count_map -> count_map
      _value -> %{}
    end
  end

  def string_list(report, field) do
    report
    |> evidence()
    |> Map.get(field)
    |> list_value()
  end

  def string_list_map(report, field) do
    case report |> evidence() |> Map.get(field) do
      %{} = list_map -> list_map
      _value -> %{}
    end
  end

  defp evidence(report), do: Map.get(report, "evidence", %{})

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []
end
