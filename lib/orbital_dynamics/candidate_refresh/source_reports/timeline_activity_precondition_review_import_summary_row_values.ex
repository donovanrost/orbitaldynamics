defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportSummaryRowValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      sorted_string_values: 1
    ]

  def unique_row_value(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> sorted_string_values()
    |> case do
      [value] -> value
      _values -> nil
    end
  end

  def sorted_row_values(rows, field) do
    rows
    |> Enum.flat_map(&Map.get(&1, field, []))
    |> sorted_string_values()
  end

  def invalid_activity_input_reasons(rows) do
    rows
    |> Enum.flat_map(&row_invalid_activity_input_reasons/1)
    |> sorted_string_values()
  end

  defp row_invalid_activity_input_reasons(%{} = summary) do
    List.wrap(Map.get(summary, "invalid_activity_input_reasons")) ++
      List.wrap(Map.get(summary, "invalid_activity_input_reason"))
  end
end
