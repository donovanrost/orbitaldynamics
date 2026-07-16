defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.ReviewFields.RouteMap.Fields do
  @moduledoc false

  alias __MODULE__.FieldValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def for_action(action, route_inputs) do
    rows = Map.get(route_inputs.rows_by_action, action, [])

    %{
      "review_count" => Map.get(route_inputs.action_counts, action, length(rows)),
      "activity_ids" => FieldValues.activity_ids(rows),
      "timeline_ids" =>
        FieldValues.timeline_ids(action, route_inputs.timeline_ids_by_action, rows),
      "status_transition_categories" =>
        FieldValues.transition_categories(rows, "status_transition"),
      "approval_transition_categories" =>
        FieldValues.transition_categories(rows, "approval_transition")
    }
    |> compact_map()
  end
end
