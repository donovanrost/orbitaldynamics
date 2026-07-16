defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.RowFields.ReviewRows.TimelineIdGroups do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.RowFields.PressureFields

  def by_required_operator_action(rows) do
    timeline_ids_by(rows, &Map.get(&1, "required_operator_action"))
  end

  def by_status_transition_category(rows) do
    timeline_ids_by(rows, &get_in(&1, ["status_transition", "transition_category"]))
  end

  def by_approval_transition_category(rows) do
    timeline_ids_by(rows, &get_in(&1, ["approval_transition", "transition_category"]))
  end

  defp timeline_ids_by(rows, classifier) do
    rows
    |> Enum.group_by(classifier)
    |> Enum.reject(fn {key, _rows} -> key in [nil, ""] end)
    |> Map.new(fn {key, grouped_rows} ->
      {to_string(key), PressureFields.timeline_ids(grouped_rows, fn _row -> true end)}
    end)
    |> non_empty_map()
  end

  defp non_empty_map(map) do
    case map do
      %{} when map_size(map) == 0 -> nil
      _map -> map
    end
  end
end
