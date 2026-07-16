defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.ActivityStateMetrics.RowFields do
  @moduledoc false

  alias __MODULE__.InvalidInputs
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.RowData

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      sum_report_count: 2
    ]

  def fields(states) do
    %{
      "row_count" => sum_report_count(states, &activity_row_count/1),
      "review_required_count" => sum_report_count(states, &activity_review_required_count/1),
      "invalid_activity_input_count" => InvalidInputs.count(states),
      "invalid_activity_input_reason_counts" => InvalidInputs.reason_counts(states),
      "invalid_activity_input_reasons" => InvalidInputs.reasons(states)
    }
  end

  defp activity_row_count(%{"rows" => rows}) when is_list(rows), do: length(rows)
  defp activity_row_count(%{}), do: 1
  defp activity_row_count(_state), do: 0

  defp activity_review_required_count(%{} = state) do
    state
    |> RowData.rows_for_summary()
    |> Enum.count(&RowData.review_required?/1)
  end
end
