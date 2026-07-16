defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleStateMetrics.InvalidInputs do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.RowData

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_source_report_values: 1,
      sorted_string_values: 1
    ]

  def count(%{} = row), do: RowData.invalid_activity_input_count(row)

  def reason_counts(states) do
    states
    |> Enum.flat_map(&reasons/1)
    |> count_source_report_values()
  end

  def reasons(states) when is_list(states) do
    states
    |> Enum.flat_map(&reasons/1)
    |> sorted_string_values()
  end

  def reasons(%{} = row) do
    RowData.invalid_activity_input_reasons(row)
  end
end
