defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleStateMetrics.RequiredActions.Routing do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleStateMetrics.RequiredActions.ActionValues

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleStateMetrics.RequiredActions.RouteFields

  def fields(states) do
    states
    |> Enum.flat_map(&action_state_pairs/1)
    |> Enum.group_by(fn {action, _state} -> action end, fn {_action, state} -> state end)
    |> Enum.map(fn {action, action_states} ->
      {action, RouteFields.fields(action_states)}
    end)
    |> Map.new()
    |> non_empty_map()
  end

  defp action_state_pairs(state) do
    state
    |> ActionValues.actions()
    |> Enum.reject(&(&1 in [nil, "", "none"]))
    |> Enum.map(&{&1, state})
  end

  defp non_empty_map(map) do
    case map do
      %{} when map_size(map) == 0 -> nil
      _map -> map
    end
  end
end
