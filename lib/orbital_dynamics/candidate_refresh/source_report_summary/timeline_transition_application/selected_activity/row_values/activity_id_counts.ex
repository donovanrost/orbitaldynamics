defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.SelectedActivity.RowValues.ActivityIdCounts do
  @moduledoc false

  alias __MODULE__.RowCounts
  alias __MODULE__.RowActivityIds
  alias __MODULE__.SummarySourceCounts

  def selected(report) do
    RowCounts.summary_source_value(report, &selected/2)
  end

  def review(report) do
    RowCounts.summary_source_value(report, &review/2)
  end

  defp selected(report, true) do
    SummarySourceCounts.selected(report)
  end

  defp selected(report, false) do
    RowCounts.values(report, "selected_activity_id_counts", fn rows ->
      RowActivityIds.selected(rows)
    end)
  end

  defp review(report, true) do
    SummarySourceCounts.review(report)
  end

  defp review(report, false) do
    RowCounts.values(report, "review_activity_id_counts", fn rows ->
      RowActivityIds.review(rows)
    end)
  end
end
