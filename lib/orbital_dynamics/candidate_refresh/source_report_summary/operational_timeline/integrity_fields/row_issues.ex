defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.IntegrityFields.RowIssues do
  @moduledoc false

  alias __MODULE__.Counts
  alias __MODULE__.Rows

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_source_report_values: 1
    ]

  def integrity_issue_count(report) do
    issue_count(report, "timeline_integrity_issue_count", :any)
  end

  def dependency_issue_count(report) do
    issue_count(report, "dependency_issue_count", :dependency)
  end

  def exclusivity_issue_count(report) do
    issue_count(report, "exclusivity_issue_count", :exclusivity)
  end

  def issue_type_counts(report) do
    report
    |> rows()
    |> Enum.flat_map(&(Map.get(&1, "timeline_integrity_issue_types") |> List.wrap()))
    |> count_source_report_values()
  end

  defp issue_count(report, row_count_field, issue_type) do
    Counts.issue_count(rows(report), row_count_field, issue_type)
  end

  defp rows(report) do
    Rows.normalized(report)
  end
end
