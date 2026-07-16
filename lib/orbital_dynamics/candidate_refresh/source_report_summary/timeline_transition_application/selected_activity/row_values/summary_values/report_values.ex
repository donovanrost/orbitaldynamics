defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.SelectedActivity.RowValues.SummaryValues.ReportValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.ReportShape

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.SelectedActivity.ActivityIds

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.SelectedActivity.IntegrityRows

  def selected_activity_count(report) do
    ReportShape.count_matching_application(
      report,
      "selected_activity_count",
      &ActivityIds.selected_row?/1
    )
  end

  def selected_integrity_review_count(report) do
    IntegrityRows.review_count(report)
  end

  def selected_integrity_issue_count(report) do
    IntegrityRows.issue_count(report)
  end

  def selected_integrity_issue_type_counts(report) do
    IntegrityRows.issue_type_counts(report)
  end
end
