defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.CountFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2,
      sorted_string_values: 1,
      sum_report_count: 2
    ]

  def fields(summaries) do
    %{
      "row_count" => sum_report_count(summaries, &numeric_report_count(&1, "row_count")),
      "planned_activity_count" =>
        sum_report_count(summaries, &numeric_report_count(&1, "planned_activity_count")),
      "realized_activity_count" =>
        sum_report_count(summaries, &numeric_report_count(&1, "realized_activity_count")),
      "recordable_count" =>
        sum_report_count(summaries, &numeric_report_count(&1, "recordable_count")),
      "preserved_count" =>
        sum_report_count(summaries, &numeric_report_count(&1, "preserved_count")),
      "review_required_count" =>
        sum_report_count(summaries, &numeric_report_count(&1, "review_required_count")),
      "duplicate_timeline_identity_count" =>
        sum_report_count(
          summaries,
          &numeric_report_count(&1, "duplicate_timeline_identity_count")
        ),
      "invalid_activity_input_count" =>
        sum_report_count(summaries, &numeric_report_count(&1, "invalid_activity_input_count")),
      "invalid_activity_input_ids" =>
        summaries
        |> Enum.flat_map(&Map.get(&1, "invalid_activity_input_ids", []))
        |> sorted_string_values()
    }
  end
end
