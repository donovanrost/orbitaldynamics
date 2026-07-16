defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.IssueFields.AggregateFields.ClassCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.IssueFields.AggregateFields.CountSpecs

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.IssueFields.IssueTypes

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [numeric_report_count: 2]

  def dependency_count(report) do
    count_by(report, CountSpecs.dependency())
  end

  def exclusivity_count(report) do
    count_by(report, CountSpecs.exclusivity())
  end

  defp count_by(report, {fallback_field, predicate}) do
    report
    |> IssueTypes.values()
    |> Enum.count(predicate)
    |> case do
      0 -> numeric_report_count(report, fallback_field)
      count -> count
    end
  end
end
