defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.SelectedActivity.RowValues.SummaryValues do
  @moduledoc false

  alias __MODULE__.{ReportValues, SourceSelector, SummarySourceValues}

  def selected_activity_count(report) do
    SourceSelector.value(
      report,
      &SummarySourceValues.selected_activity_count/1,
      &ReportValues.selected_activity_count/1
    )
  end

  def selected_integrity_review_count(report) do
    SourceSelector.value(
      report,
      &SummarySourceValues.selected_integrity_review_count/1,
      &ReportValues.selected_integrity_review_count/1
    )
  end

  def selected_integrity_issue_count(report) do
    SourceSelector.value(
      report,
      &SummarySourceValues.selected_integrity_issue_count/1,
      &ReportValues.selected_integrity_issue_count/1
    )
  end

  def selected_integrity_issue_type_counts(report) do
    SourceSelector.value(
      report,
      &SummarySourceValues.selected_integrity_issue_type_counts/1,
      &ReportValues.selected_integrity_issue_type_counts/1
    )
  end
end
