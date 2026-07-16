defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleSummary.IdentityFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleStateMetrics.RequiredActions

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleStateMetrics.ValueCounts

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1]

  def fields(states) do
    %{
      "activity_id_counts" => id_counts(states, "activity_id"),
      "timeline_id_counts" => id_counts(states, "timeline_id"),
      "review_activity_id_counts" =>
        states
        |> Enum.filter(&RequiredActions.review_required?/1)
        |> id_counts("activity_id")
    }
  end

  defp id_counts(states, field) do
    states
    |> Enum.map(&ValueCounts.id_counts(&1, field))
    |> merge_count_maps()
  end
end
