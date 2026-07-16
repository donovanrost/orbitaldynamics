defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.ActivityStateMetrics.CountFields.ValueCounts.RowValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.RowData

  def field(%{} = state, field) do
    state
    |> RowData.rows_for_summary()
    |> Enum.map(&Map.get(&1, field))
  end

  def nested(%{} = state, path) do
    state
    |> RowData.rows_for_summary()
    |> Enum.map(&get_in(&1, path))
  end
end
