defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleStateMetrics.ValueCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.RowData

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_source_report_values: 1]

  def field_counts(%{} = state, field) do
    state
    |> Map.get(field)
    |> List.wrap()
    |> count_source_report_values()
  end

  def nested_field_counts(%{} = state, path) do
    state
    |> get_in(path)
    |> List.wrap()
    |> count_source_report_values()
  end

  def protection_counts(%{} = state, field) do
    [
      get_in(state, ["planned_protection_decision", field]),
      get_in(state, ["realized_protection_decision", field])
    ]
    |> count_source_report_values()
  end

  def id_counts(%{} = state, field) do
    state
    |> RowData.ids(field)
    |> count_source_report_values()
  end

  def non_zero_count(count) when is_integer(count) and count > 0, do: count
  def non_zero_count(_count), do: nil
end
