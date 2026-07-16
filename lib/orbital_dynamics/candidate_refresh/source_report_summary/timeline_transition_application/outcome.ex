defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.Outcome do
  @moduledoc false

  alias __MODULE__.ReportValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "review_required_count" => sum_report_count(reports, &ReportValues.review_required_count/1),
      "preserved_source_count" =>
        sum_report_count(reports, &ReportValues.preserved_source_count/1),
      "recorded_replacement_count" =>
        sum_report_count(reports, &ReportValues.recorded_replacement_count/1),
      "withheld_review_count" => sum_report_count(reports, &ReportValues.withheld_review_count/1),
      "application_status_counts" =>
        reports
        |> Enum.map(&ReportValues.application_status_counts/1)
        |> merge_count_maps(),
      "transition_decision_counts" =>
        reports
        |> Enum.map(&ReportValues.transition_decision_counts/1)
        |> merge_count_maps(),
      "required_operator_action_counts" =>
        reports
        |> Enum.map(&ReportValues.required_operator_action_counts/1)
        |> merge_count_maps()
    }
  end
end
