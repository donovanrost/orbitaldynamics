defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleSummary.MetricFields do
  @moduledoc false

  alias __MODULE__.BaseFields
  alias __MODULE__.CategoryCounts

  def fields(states) do
    states
    |> BaseFields.fields()
    |> Map.merge(CategoryCounts.fields(states))
  end
end
