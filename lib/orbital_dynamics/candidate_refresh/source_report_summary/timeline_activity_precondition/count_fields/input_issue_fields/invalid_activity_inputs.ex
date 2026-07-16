defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityPrecondition.CountFields.InputIssueFields.InvalidActivityInputs do
  @moduledoc false

  alias __MODULE__.Reasons

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_source_report_values: 1,
      numeric_report_count: 2
    ]

  def count(%{} = summary) do
    case numeric_report_count(summary, "invalid_activity_input_count") do
      0 -> if Map.get(summary, "invalid_activity_input") == true, do: 1, else: 0
      count -> count
    end
  end

  def count(_summary), do: 0

  def reasons(summary), do: Reasons.values(summary)

  def reason_counts(%{} = summary) do
    summary
    |> reasons()
    |> count_source_report_values()
  end

  def reason_counts(_summary), do: %{}
end
