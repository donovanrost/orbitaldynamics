defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.ActivityStateMetrics.RowFields.InvalidInputs do
  @moduledoc false

  alias __MODULE__.StateValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      sorted_string_values: 1,
      sum_report_count: 2
    ]

  def count(states) do
    sum_report_count(states, &StateValues.count/1)
  end

  def reason_counts(states) do
    states
    |> Enum.map(&StateValues.reason_counts/1)
    |> merge_count_maps()
  end

  def reasons(states) when is_list(states) do
    states
    |> Enum.flat_map(&reasons/1)
    |> sorted_string_values()
  end

  def reasons(%{} = state) do
    StateValues.reasons(state)
  end
end
