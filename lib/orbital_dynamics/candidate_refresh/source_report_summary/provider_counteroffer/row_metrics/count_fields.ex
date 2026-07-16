defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics.CountFields do
  @moduledoc false

  alias __MODULE__.ReportValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      merge_string_list_maps: 1,
      sorted_string_values: 1,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "row_count" => sum_report_count(reports, &ReportValues.row_count/1),
      "reviewable_count" => sum_report_count(reports, &ReportValues.reviewable_count/1),
      "counteroffer_status_counts" =>
        reports
        |> Enum.map(&ReportValues.status_counts/1)
        |> merge_count_maps(),
      "required_operator_action_counts" =>
        reports
        |> Enum.map(&ReportValues.required_action_counts/1)
        |> merge_count_maps(),
      "counteroffer_lock_deadline_status_counts" =>
        reports
        |> Enum.map(&ReportValues.lock_deadline_status_counts/1)
        |> merge_count_maps(),
      "counteroffer_ids_by_lock_deadline_status" =>
        reports
        |> Enum.map(&ReportValues.ids_by_lock_deadline_status/1)
        |> merge_string_list_maps(),
      "review_counteroffer_ids" =>
        reports
        |> Enum.flat_map(&Map.get(&1, "review_counteroffer_ids", []))
        |> sorted_string_values()
    }
  end
end
