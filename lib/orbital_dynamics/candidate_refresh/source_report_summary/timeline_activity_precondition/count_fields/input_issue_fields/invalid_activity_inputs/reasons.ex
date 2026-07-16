defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityPrecondition.CountFields.InputIssueFields.InvalidActivityInputs.Reasons do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1]

  def values(summaries) when is_list(summaries) do
    summaries
    |> Enum.flat_map(&values/1)
    |> sorted_string_values()
  end

  def values(%{} = summary) do
    (List.wrap(Map.get(summary, "invalid_activity_input_reasons")) ++
       List.wrap(Map.get(summary, "invalid_activity_input_reason")))
    |> sorted_string_values()
  end

  def values(_summary), do: []
end
