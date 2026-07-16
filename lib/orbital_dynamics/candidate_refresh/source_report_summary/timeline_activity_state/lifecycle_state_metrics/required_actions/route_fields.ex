defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleStateMetrics.RequiredActions.RouteFields do
  @moduledoc false

  alias __MODULE__.Values

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1
    ]

  def fields(action_states) do
    %{
      "review_count" => length(action_states),
      "activity_ids" => Values.route_ids(action_states, "activity_id"),
      "timeline_ids" => Values.route_ids(action_states, "timeline_id"),
      "status_transition_categories" =>
        Values.transition_categories(action_states, "status_transition"),
      "approval_transition_categories" =>
        Values.transition_categories(action_states, "approval_transition"),
      "protection_categories" => Values.protection_categories(action_states)
    }
    |> compact_map()
  end
end
