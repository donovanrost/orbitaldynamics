defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.ReviewFields.RouteMap.Fields.FieldValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.RowFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1]

  def activity_ids(rows) do
    rows
    |> Enum.flat_map(&RowFields.activity_ids/1)
    |> sorted_string_values()
  end

  def timeline_ids(action, timeline_ids_by_action, rows) do
    (Map.get(timeline_ids_by_action, action, []) ++ Enum.map(rows, & &1["timeline_id"]))
    |> sorted_string_values()
  end

  def transition_categories(rows, field) do
    rows
    |> Enum.map(&get_in(&1, [field, "transition_category"]))
    |> sorted_string_values()
  end
end
