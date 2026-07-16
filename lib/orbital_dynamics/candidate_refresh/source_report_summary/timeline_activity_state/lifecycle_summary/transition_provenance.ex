defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleSummary.TransitionProvenance do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleStateMetrics.TransitionProvenance,
    as: ProvenanceValues

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleStateMetrics.ValueCounts

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1]

  def fields(states) do
    %{
      "transition_application_provenance_count" =>
        states
        |> Enum.map(&ProvenanceValues.count/1)
        |> Enum.sum()
        |> ValueCounts.non_zero_count(),
      "transition_application_provenance_helper_counts" => field_counts(states, "helper"),
      "transition_application_provenance_category_counts" =>
        field_counts(states, "transition_category"),
      "transition_application_provenance_operator_action_reason_counts" =>
        field_counts(states, "operator_action_reason")
    }
  end

  defp field_counts(states, field) do
    states
    |> Enum.map(&ProvenanceValues.field_counts(&1, field))
    |> merge_count_maps()
  end
end
