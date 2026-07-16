defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.ReviewFields.RouteMap.Inputs.ActionInputs.Values do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.RowFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      merge_string_list_maps: 1
    ]

  def action_counts(summaries) do
    summaries
    |> Enum.map(&Map.get(&1, "required_operator_action_counts", %{}))
    |> merge_count_maps()
    |> empty_map_if_nil()
    |> Map.delete("none")
  end

  def timeline_ids_by_action(summaries) do
    summaries
    |> Enum.map(&Map.get(&1, "review_timeline_ids_by_required_operator_action", %{}))
    |> merge_string_list_maps()
    |> empty_map_if_nil()
  end

  def rows_by_action(summaries) do
    summaries
    |> Enum.flat_map(&RowFields.review_rows/1)
    |> Enum.group_by(&Map.get(&1, "required_operator_action"))
    |> Map.delete(nil)
    |> Map.delete("none")
  end

  defp empty_map_if_nil(%{} = map), do: map
  defp empty_map_if_nil(_map), do: %{}
end
