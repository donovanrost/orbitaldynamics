defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.SelectedActivity.IntegrityRows do
  @moduledoc false

  alias __MODULE__.ReviewRows
  alias __MODULE__.Rows

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_source_report_values: 1]

  def review_count(report) do
    report
    |> rows()
    |> Enum.count(&ReviewRows.review?/1)
  end

  def issue_count(report) do
    report
    |> rows()
    |> Enum.map(&Rows.summary_integer(&1, "timeline_integrity_issue_count"))
    |> Enum.sum()
  end

  def issue_type_counts(report) do
    report
    |> rows()
    |> Enum.flat_map(&(Map.get(&1, "timeline_integrity_issue_types") |> List.wrap()))
    |> count_source_report_values()
  end

  def review_row?(row), do: ReviewRows.review?(row)

  defp rows(report), do: Rows.rows(report)
end
