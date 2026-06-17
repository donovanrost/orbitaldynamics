defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ManeuverReview.SourceReportFields do
  @moduledoc false

  alias __MODULE__.Flattened

  def source_report_fields(source_reports, summary) do
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
    |> Map.merge(Flattened.source_report_fields(source_reports))
  end
end
