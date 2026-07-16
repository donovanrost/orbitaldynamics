defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleStateMetrics.TransitionProvenance do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_source_report_values: 1]

  def count(%{} = state) do
    state
    |> values()
    |> length()
  end

  def field_counts(%{} = state, field) do
    state
    |> values()
    |> Enum.map(&Map.get(&1, field))
    |> count_source_report_values()
  end

  defp values(%{} = state) do
    [
      Map.get(state, "transition_application_provenance"),
      get_in(state, ["activity_context", "transition_application_provenance"]),
      get_in(state, ["planned_activity_context", "transition_application_provenance"]),
      get_in(state, ["realized_activity_context", "transition_application_provenance"])
    ]
    |> Enum.filter(&is_map/1)
    |> Enum.uniq()
  end
end
