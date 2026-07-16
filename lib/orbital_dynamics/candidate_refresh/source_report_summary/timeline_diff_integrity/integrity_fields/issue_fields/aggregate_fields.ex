defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.IssueFields.AggregateFields do
  @moduledoc false

  alias __MODULE__.{ClassCounts, CountSpecs, IssueTypeCounts}

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "timeline_integrity_issue_count" => sum_report_count(reports, &issue_count/1),
      CountSpecs.dependency_field() => sum_report_count(reports, &dependency_issue_count/1),
      CountSpecs.exclusivity_field() => sum_report_count(reports, &exclusivity_issue_count/1),
      CountSpecs.issue_type_counts_field() =>
        reports
        |> Enum.map(&issue_type_counts/1)
        |> merge_count_maps()
    }
  end

  defp issue_count(report) do
    IssueTypeCounts.total_count(report)
  end

  defp dependency_issue_count(report) do
    ClassCounts.dependency_count(report)
  end

  defp exclusivity_issue_count(report) do
    ClassCounts.exclusivity_count(report)
  end

  defp issue_type_counts(report) do
    IssueTypeCounts.counts(report)
  end
end
