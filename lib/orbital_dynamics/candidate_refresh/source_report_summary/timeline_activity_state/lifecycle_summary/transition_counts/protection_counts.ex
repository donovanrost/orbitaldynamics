defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleSummary.TransitionCounts.ProtectionCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleStateMetrics.ValueCounts

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1]

  def fields(states) do
    %{
      "protection_decision_counts" => protection_count_map(states, "protection_decision"),
      "protection_category_counts" => protection_count_map(states, "protection_category")
    }
  end

  defp protection_count_map(states, field) do
    states
    |> Enum.map(&ValueCounts.protection_counts(&1, field))
    |> merge_count_maps()
  end
end
