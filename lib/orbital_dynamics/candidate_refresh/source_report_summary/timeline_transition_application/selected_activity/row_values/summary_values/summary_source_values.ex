defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.SelectedActivity.RowValues.SummaryValues.SummarySourceValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_source_report_values: 1,
      numeric_report_count: 2
    ]

  def selected_activity_count(report) do
    numeric_report_count(report, "selected_activity_count")
  end

  def selected_integrity_review_count(report) do
    numeric_report_count(report, "selected_timeline_integrity_review_count")
  end

  def selected_integrity_issue_count(report) do
    numeric_report_count(report, "selected_timeline_integrity_issue_count")
  end

  def selected_integrity_issue_type_counts(report) do
    report
    |> Map.get("selected_timeline_integrity_issue_types", [])
    |> count_source_report_values()
  end
end
