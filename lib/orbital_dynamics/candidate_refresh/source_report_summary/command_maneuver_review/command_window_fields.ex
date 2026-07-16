defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.CommandWindowFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.DirectionRouting

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.FeedbackMetrics
  alias __MODULE__.SourceValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      sum_report_count: 2
    ]

  def fields(sources) do
    reports = SourceValues.reports(sources)
    trust_boundaries = OperationalFeedback.source_command_window_trust_boundaries(reports)

    %{
      "paths" => SourceValues.paths(sources),
      "contract" => "command_window_report.v1",
      "count" => length(sources),
      "row_count" => sum_report_count(reports, &FeedbackMetrics.report_rows_count/1),
      "command_feedback_count" =>
        sum_report_count(reports, &FeedbackMetrics.command_feedback_count/1),
      "input_keys" => FeedbackMetrics.command_window_input_keys(reports),
      "required_operator_action_counts" =>
        FeedbackMetrics.required_operator_action_counts(reports),
      "trust_boundary_status" => SourceValues.trust_boundary_status(trust_boundaries),
      "trust_boundaries" => trust_boundaries
    }
    |> Map.merge(DirectionRouting.fields(reports))
    |> compact_map()
  end
end
