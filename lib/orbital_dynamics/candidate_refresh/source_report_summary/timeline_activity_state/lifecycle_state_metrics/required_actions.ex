defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleStateMetrics.RequiredActions do
  @moduledoc false

  alias __MODULE__.ActionValues
  alias __MODULE__.Routing

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_source_report_values: 1
    ]

  def counts(%{} = state) do
    state
    |> actions()
    |> count_source_report_values()
  end

  def review_required?(%{} = state) do
    ActionValues.review_required?(state)
  end

  def routing(states) do
    Routing.fields(states)
  end

  def actions(%{} = state) do
    ActionValues.actions(state)
  end
end
