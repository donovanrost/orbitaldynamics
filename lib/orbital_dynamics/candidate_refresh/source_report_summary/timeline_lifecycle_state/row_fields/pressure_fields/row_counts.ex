defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.RowFields.PressureFields.RowCounts do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_source_report_values: 1
    ]

  def decision_count(rows, decision) do
    Enum.count(rows, &(&1["transition_decision"] == decision))
  end

  def field_counts(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> count_source_report_values()
  end

  def nested_counts(rows, path) do
    rows
    |> Enum.map(&get_in(&1, path))
    |> count_source_report_values()
  end
end
