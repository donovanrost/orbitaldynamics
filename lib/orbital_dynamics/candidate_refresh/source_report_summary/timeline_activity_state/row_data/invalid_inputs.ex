defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.RowData.InvalidInputs do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      sorted_string_values: 1
    ]

  def count(%{} = row) do
    case Map.get(row, "invalid_activity_input_count") do
      count when is_integer(count) and count >= 0 -> count
      count when is_float(count) and count >= 0 -> trunc(count)
      _count -> if Map.get(row, "invalid_activity_input") == true, do: 1, else: 0
    end
  end

  def count(_row), do: 0

  def reasons(%{} = row) do
    (List.wrap(Map.get(row, "invalid_activity_input_reasons")) ++
       List.wrap(Map.get(row, "invalid_activity_input_reason")))
    |> sorted_string_values()
  end

  def reasons(_row), do: []
end
