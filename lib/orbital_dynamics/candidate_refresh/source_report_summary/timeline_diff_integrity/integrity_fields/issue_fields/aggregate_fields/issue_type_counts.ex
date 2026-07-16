defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.IssueFields.AggregateFields.IssueTypeCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.IssueFields.AggregateFields.CountSpecs

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.IssueFields.IssueTypes

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_source_report_values: 1,
      numeric_report_count: 2
    ]

  def total_count(report) do
    with_issue_types_or_fallback(
      report,
      &numeric_report_count(&1, CountSpecs.total_issue_field()),
      &length/1
    )
  end

  def counts(report) do
    with_issue_types_or_fallback(
      report,
      &Map.get(&1, CountSpecs.issue_type_counts_field()),
      &count_source_report_values/1
    )
  end

  defp with_issue_types_or_fallback(report, fallback_fun, issue_types_fun) do
    case IssueTypes.values(report) do
      [] -> fallback_fun.(report)
      issue_types -> issue_types_fun.(issue_types)
    end
  end
end
