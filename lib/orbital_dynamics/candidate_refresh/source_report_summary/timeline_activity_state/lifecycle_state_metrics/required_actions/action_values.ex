defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleStateMetrics.RequiredActions.ActionValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1]

  def review_required?(%{} = state) do
    Map.get(state, "review_required") == true or
      Map.get(state, "requires_operator_review") == true or
      Enum.any?(
        actions(state),
        &(is_binary(&1) and String.starts_with?(&1, "review"))
      )
  end

  def actions(%{} = state) do
    (List.wrap(Map.get(state, "required_operator_actions")) ++
       List.wrap(Map.get(state, "required_operator_action")))
    |> sorted_string_values()
  end
end
