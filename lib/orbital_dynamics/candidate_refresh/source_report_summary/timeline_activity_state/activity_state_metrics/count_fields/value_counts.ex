defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.ActivityStateMetrics.CountFields.ValueCounts do
  @moduledoc false

  alias __MODULE__.RowValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_source_report_values: 1,
      merge_count_maps: 1
    ]

  def field(states, field) do
    count_map(states, &RowValues.field(&1, field))
  end

  def nested(states, path) do
    count_map(states, &RowValues.nested(&1, path))
  end

  defp count_map(states, row_values) do
    states
    |> Enum.map(fn state ->
      state
      |> row_values.()
      |> count_source_report_values()
    end)
    |> merge_count_maps()
  end
end
