defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.SourceReports.ManeuverReviewSource do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.FeedbackMetrics

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def source(%{} = report) do
    rows = Map.get(report, "rows", [])
    trust_boundaries = OperationalFeedback.source_maneuver_review_trust_boundaries([report])

    %{
      "source" => "maneuver_review_report.rows",
      "source_report_contract" => Map.get(report, "schema_contract", "maneuver_review_report.v1"),
      "source_report_count" => 1,
      "source_report_row_count" => length(rows),
      "source_maneuver_success_feedback_count" =>
        FeedbackMetrics.maneuver_success_feedback_count(report),
      "source_execution_uncertainty_declared_count" =>
        FeedbackMetrics.maneuver_execution_uncertainty_declared_count(report),
      "source_execution_uncertainty_missing_count" =>
        FeedbackMetrics.maneuver_execution_uncertainty_missing_count(report),
      "input_keys" => FeedbackMetrics.maneuver_review_input_keys([report]),
      "trust_boundary_status" => trust_boundary_status(trust_boundaries),
      "trust_boundaries" => trust_boundaries,
      "source_required_operator_action_counts" => required_operator_action_counts(report)
    }
    |> compact_map()
  end

  def required_operator_action_counts(report) do
    FeedbackMetrics.required_operator_action_counts(report)
  end

  defp trust_boundary_status([]), do: "missing"
  defp trust_boundary_status(_trust_boundaries), do: "declared"
end
