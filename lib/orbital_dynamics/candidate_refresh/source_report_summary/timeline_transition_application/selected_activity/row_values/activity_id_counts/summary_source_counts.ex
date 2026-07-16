defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.SelectedActivity.RowValues.ActivityIdCounts.SummarySourceCounts do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_source_report_values: 1]

  def selected(report) do
    activity_id_counts(report, "selected_activity_ids")
  end

  def review(report) do
    activity_id_counts(report, "review_activity_ids")
  end

  defp activity_id_counts(report, field) do
    report
    |> Map.get(field)
    |> List.wrap()
    |> count_source_report_values()
  end
end
