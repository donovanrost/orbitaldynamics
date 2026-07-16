defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.ReviewFields.RouteMap.Inputs do
  @moduledoc false

  alias __MODULE__.ActionInputs

  def build(summaries) do
    action_counts = ActionInputs.action_counts(summaries)
    timeline_ids_by_action = ActionInputs.timeline_ids_by_action(summaries)
    rows_by_action = ActionInputs.rows_by_action(summaries)

    %{
      action_counts: action_counts,
      timeline_ids_by_action: timeline_ids_by_action,
      rows_by_action: rows_by_action,
      actions: route_actions(action_counts, timeline_ids_by_action, rows_by_action)
    }
  end

  defp route_actions(action_counts, timeline_ids_by_action, rows_by_action) do
    [
      Map.keys(action_counts),
      Map.keys(timeline_ids_by_action),
      Map.keys(rows_by_action)
    ]
    |> List.flatten()
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
  end
end
