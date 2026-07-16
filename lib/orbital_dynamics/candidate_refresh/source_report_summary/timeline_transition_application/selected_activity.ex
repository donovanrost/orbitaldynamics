defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.SelectedActivity do
  @moduledoc false

  alias __MODULE__.RowValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "selected_activity_count" =>
        sum_report_count(reports, &RowValues.selected_activity_count/1),
      "selected_activity_id_counts" =>
        reports
        |> Enum.map(&RowValues.selected_activity_id_counts/1)
        |> merge_count_maps(),
      "review_activity_id_counts" =>
        reports
        |> Enum.map(&RowValues.review_activity_id_counts/1)
        |> merge_count_maps(),
      "selected_timeline_integrity_review_count" =>
        sum_report_count(reports, &RowValues.selected_integrity_review_count/1),
      "selected_timeline_integrity_issue_count" =>
        sum_report_count(reports, &RowValues.selected_integrity_issue_count/1),
      "selected_timeline_integrity_issue_type_counts" =>
        reports
        |> Enum.map(&RowValues.selected_integrity_issue_type_counts/1)
        |> merge_count_maps()
    }
  end
end
