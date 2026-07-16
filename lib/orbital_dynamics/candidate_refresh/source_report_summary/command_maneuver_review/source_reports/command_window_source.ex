defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.SourceReports.CommandWindowSource do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.FeedbackMetrics

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def source(%{} = report) do
    rows = Map.get(report, "rows", [])
    trust_boundaries = OperationalFeedback.source_command_window_trust_boundaries([report])

    %{
      "source" => "command_window_report.rows",
      "source_report_contract" => Map.get(report, "schema_contract", "command_window_report.v1"),
      "source_report_count" => 1,
      "source_report_row_count" => length(rows),
      "source_command_feedback_count" => FeedbackMetrics.command_feedback_count(report),
      "input_keys" => FeedbackMetrics.command_window_input_keys([report]),
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
