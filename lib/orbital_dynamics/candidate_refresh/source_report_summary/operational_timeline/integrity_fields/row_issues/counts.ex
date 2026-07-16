defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.IntegrityFields.RowIssues.Counts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.IntegrityFields.RowIssues.Predicates

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [numeric_report_count: 2]

  def issue_count(rows, row_count_field, issue_type) do
    row_issue_count(rows, row_count_field, Predicates.row_predicate(issue_type))
  end

  defp row_issue_count(rows, row_count_field, row_predicate) do
    row_total =
      rows
      |> Enum.map(&numeric_report_count(&1, row_count_field))
      |> Enum.sum()

    if row_total > 0, do: row_total, else: Enum.count(rows, row_predicate)
  end
end
