defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus.GateIds.NonPassedRows.GroupedIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus.GateIds.NonPassedRows.RowValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1]

  def by_status(report) do
    grouped_ids(report, "status")
  end

  def by_classification(report) do
    grouped_ids(report, "classification")
  end

  defp grouped_ids(report, field) do
    report
    |> RowValues.rows_with_status()
    |> Enum.group_by(& &1[field], & &1["id"])
    |> sorted_string_list_map()
  end

  defp sorted_string_list_map(list_map) when is_map(list_map) do
    list_map
    |> Enum.map(fn {key, values} -> {key, sorted_string_values(values)} end)
    |> Map.new()
  end

  defp sorted_string_list_map(_list_map), do: %{}
end
