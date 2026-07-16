defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.ActivityStateMetrics.ActionRouting.RouteFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.RowData

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      sorted_string_values: 1
    ]

  def fields(action_rows) do
    %{
      "review_count" => length(action_rows),
      "activity_ids" => route_ids(action_rows, "activity_id"),
      "timeline_ids" => route_ids(action_rows, "timeline_id"),
      "status_transition_categories" => transition_categories(action_rows, "status_transition"),
      "approval_transition_categories" =>
        transition_categories(action_rows, "approval_transition")
    }
    |> compact_map()
  end

  defp route_ids(action_rows, field) do
    action_rows
    |> Enum.flat_map(&RowData.ids(&1, field))
    |> sorted_string_values()
  end

  defp transition_categories(action_rows, field) do
    action_rows
    |> Enum.map(&get_in(&1, [field, "transition_category"]))
    |> sorted_string_values()
  end
end
