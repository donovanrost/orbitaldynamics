defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleSummary.TransitionCounts.CountMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleStateMetrics.ValueCounts

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1]

  def field(states, field) do
    states
    |> Enum.map(&ValueCounts.field_counts(&1, field))
    |> merge_count_maps()
  end

  def nested(states, path) do
    states
    |> Enum.map(&ValueCounts.nested_field_counts(&1, path))
    |> merge_count_maps()
  end
end
