defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.SelectedActivity.RowValues.ActivityIdCounts.RowActivityIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.SelectedActivity.ActivityIds

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.SelectedActivity.IntegrityRows

  def selected(rows) do
    Enum.flat_map(rows, &(ActivityIds.selected_ids(&1) || []))
  end

  def review(rows) do
    rows
    |> Enum.filter(&IntegrityRows.review_row?/1)
    |> Enum.flat_map(&ActivityIds.review_ids/1)
  end
end
