defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.ActivityStateMetrics.CountFields.ActivityIdentities.IdentityValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.RowData

  def ids(%{} = state, field) do
    state
    |> RowData.rows_for_summary()
    |> Enum.flat_map(&RowData.ids(&1, field))
  end

  def review_activity_ids(%{} = state) do
    state
    |> RowData.rows_for_summary()
    |> Enum.filter(&RowData.review_required?/1)
    |> Enum.flat_map(&RowData.ids(&1, "activity_id"))
  end
end
