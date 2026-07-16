defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityPrecondition.CountFields.InputIssueFields.AllowOverlapInputs do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_source_report_values: 1]

  def counts(%{} = summary) do
    summary
    |> values()
    |> count_source_report_values()
  end

  def counts(_summary), do: %{}

  defp values(summary) do
    case Map.get(summary, "allow_overlap") do
      value when is_boolean(value) -> [to_string(value)]
      value when is_binary(value) and value != "" -> [value]
      _value -> []
    end
  end
end
