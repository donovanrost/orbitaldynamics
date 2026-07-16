defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ManeuverReview.SourceReportFields.Pressure do
  @moduledoc false

  def source_report_fields(summary) do
    %{
      "source_report_maneuver_review_branch_local_maneuver_review_pressure" =>
        Map.get(summary, "branch_local_maneuver_review_pressure"),
      "source_report_maneuver_review_branch_local_maneuver_feedback_pressure" =>
        Map.get(summary, "branch_local_maneuver_feedback_pressure"),
      "source_report_maneuver_review_branch_local_maneuver_routing_pressure" =>
        Map.get(summary, "branch_local_maneuver_routing_pressure"),
      "source_report_maneuver_review_branch_local_maneuver_action_pressure" =>
        Map.get(summary, "branch_local_maneuver_action_pressure"),
      "source_report_maneuver_review_branch_local_execution_uncertainty_pressure" =>
        Map.get(summary, "branch_local_execution_uncertainty_pressure")
    }
  end
end
