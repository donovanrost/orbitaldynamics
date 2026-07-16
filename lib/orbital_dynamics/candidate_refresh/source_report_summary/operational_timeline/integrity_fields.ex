defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.IntegrityFields do
  @moduledoc false

  alias __MODULE__.RowIssues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "timeline_integrity_issue_count" => sum_report_count(reports, &integrity_issue_count/1),
      "dependency_integrity_issue_count" => sum_report_count(reports, &dependency_issue_count/1),
      "exclusivity_integrity_issue_count" =>
        sum_report_count(reports, &exclusivity_issue_count/1),
      "timeline_integrity_issue_type_counts" =>
        reports
        |> Enum.map(&RowIssues.issue_type_counts/1)
        |> merge_count_maps()
    }
  end

  def integrity_issue_count(report) do
    RowIssues.integrity_issue_count(report)
  end

  def dependency_issue_count(report) do
    RowIssues.dependency_issue_count(report)
  end

  def exclusivity_issue_count(report) do
    RowIssues.exclusivity_issue_count(report)
  end
end
