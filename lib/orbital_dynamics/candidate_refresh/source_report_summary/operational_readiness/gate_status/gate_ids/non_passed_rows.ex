defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus.GateIds.NonPassedRows do
  @moduledoc false

  alias __MODULE__.GroupedIds
  alias __MODULE__.RowValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1]

  def ids(report) do
    report
    |> rows_with_status()
    |> Enum.map(& &1["id"])
    |> sorted_string_values()
  end

  def ids_by_status(report) do
    GroupedIds.by_status(report)
  end

  def ids_by_classification(report) do
    GroupedIds.by_classification(report)
  end

  def raw_ids(report) do
    report
    |> Map.get("non_passed_gates", [])
    |> List.wrap()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&Map.get(&1, "id"))
  end

  defp rows_with_status(report) do
    RowValues.rows_with_status(report)
  end
end
