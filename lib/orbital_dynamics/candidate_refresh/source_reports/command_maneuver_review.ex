defmodule OrbitalDynamics.CandidateRefresh.SourceReports.CommandManeuverReview do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.CommandManeuverReviewCollections
  alias OrbitalDynamics.CandidateRefresh.SourceReports.CommandWindow
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ManeuverReview

  def command_window_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    CommandManeuverReviewCollections.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      CommandWindow,
      "source_command_window_report",
      "command_window_report"
    )
  end

  def maneuver_review_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    CommandManeuverReviewCollections.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      ManeuverReview,
      "source_maneuver_review_report",
      "maneuver_review_report"
    )
  end
end
