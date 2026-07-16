defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.ActivityStateMetrics.RowFields.InvalidInputs.StateValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.RowData

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_source_report_values: 1,
      sorted_string_values: 1
    ]

  def count(%{} = state) do
    state
    |> RowData.rows_for_summary()
    |> Enum.map(&RowData.invalid_activity_input_count/1)
    |> Enum.sum()
  end

  def reasons(%{} = state) do
    state
    |> RowData.rows_for_summary()
    |> Enum.flat_map(&RowData.invalid_activity_input_reasons/1)
    |> sorted_string_values()
  end

  def reason_counts(%{} = state) do
    state
    |> reasons()
    |> count_source_report_values()
  end
end
