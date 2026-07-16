defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.CandidateCommandReports.ReportSources.CollectionFunctions do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.CandidateOutcomeCollection,
    as: CandidateOutcomeCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.CommandManeuverReview,
    as: CommandManeuverReviewSourceReports

  @sources [
    :source_candidate_diff_reports,
    :source_candidate_rejection_reports,
    :source_command_window_reports,
    :source_maneuver_review_reports
  ]

  def source?(source), do: source in @sources

  def function_for(:source_candidate_diff_reports),
    do: &CandidateOutcomeCollectionSourceReports.candidate_diff_reports/3

  def function_for(:source_candidate_rejection_reports),
    do: &CandidateOutcomeCollectionSourceReports.candidate_rejection_reports/3

  def function_for(:source_command_window_reports),
    do: &CommandManeuverReviewSourceReports.command_window_reports/3

  def function_for(:source_maneuver_review_reports),
    do: &CommandManeuverReviewSourceReports.maneuver_review_reports/3
end
