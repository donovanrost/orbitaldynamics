defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.ActivityStateMetrics.ActionRouting do
  @moduledoc false

  alias __MODULE__.RouteFields

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.RowData

  def fields(states) do
    states
    |> rows_with_action()
    |> Enum.group_by(&Map.get(&1, "required_operator_action"))
    |> Map.delete(nil)
    |> Map.delete("none")
    |> Enum.map(fn {action, action_rows} ->
      {action, RouteFields.fields(action_rows)}
    end)
    |> Map.new()
    |> non_empty_map()
  end

  defp rows_with_action(states) do
    states
    |> Enum.flat_map(&RowData.rows_for_summary/1)
    |> Enum.filter(&RowData.present_action?/1)
  end

  defp non_empty_map(map) do
    case map do
      %{} when map_size(map) == 0 -> nil
      _map -> map
    end
  end
end
