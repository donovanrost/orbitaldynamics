defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleStateMetrics.RequiredActions.RouteFields.Values do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.RowData

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      sorted_string_values: 1
    ]

  def route_ids(action_states, field) do
    action_states
    |> Enum.flat_map(&RowData.ids(&1, field))
    |> sorted_string_values()
  end

  def transition_categories(action_states, field) do
    action_states
    |> Enum.map(&get_in(&1, [field, "transition_category"]))
    |> sorted_string_values()
  end

  def protection_categories(action_states) do
    action_states
    |> Enum.flat_map(fn state ->
      [
        get_in(state, ["planned_protection_decision", "protection_category"]),
        get_in(state, ["realized_protection_decision", "protection_category"])
      ]
    end)
    |> sorted_string_values()
  end
end
