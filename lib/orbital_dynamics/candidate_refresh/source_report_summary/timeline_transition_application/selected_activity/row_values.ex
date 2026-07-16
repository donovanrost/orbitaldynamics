defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.SelectedActivity.RowValues do
  @moduledoc false

  alias __MODULE__.{ActivityIdCounts, SummaryValues}

  def selected_activity_count(report) do
    SummaryValues.selected_activity_count(report)
  end

  def selected_activity_id_counts(report) do
    ActivityIdCounts.selected(report)
  end

  def review_activity_id_counts(report) do
    ActivityIdCounts.review(report)
  end

  def selected_integrity_review_count(report) do
    SummaryValues.selected_integrity_review_count(report)
  end

  def selected_integrity_issue_count(report) do
    SummaryValues.selected_integrity_issue_count(report)
  end

  def selected_integrity_issue_type_counts(report) do
    SummaryValues.selected_integrity_issue_type_counts(report)
  end
end
