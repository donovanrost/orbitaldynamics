defmodule OrbitalDynamics.CandidateRefresh.OperationalFeedback.SourceReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ResultArtifactTrustBoundary

  alias OrbitalDynamics.CandidateRefresh.SourceReports.CommandManeuverReview,
    as: CommandManeuverReviewSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollection,
    as: ContactReviewCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkConstraintCollection,
    as: LinkConstraintCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineCollection,
    as: OperationalTimelineCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceCollection,
    as: ResourceCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResultArtifactCollection,
    as: ResultArtifactCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffCollection,
    as: TimelineDiffCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineFeedbackCollection,
    as: TimelineFeedbackCollectionSourceReports

  def reports(refresh, :source_operational_timeline_reports) do
    inherited_result_artifact_source_reports(
      refresh,
      &OperationalTimelineCollectionSourceReports.reports/3
    )
  end

  def reports(refresh, :source_timeline_feedback_reports) do
    result_artifact_source_reports(
      refresh,
      &TimelineFeedbackCollectionSourceReports.reports/2
    )
  end

  def reports(refresh, :source_timeline_diff_reports) do
    inherited_result_artifact_source_reports(
      refresh,
      &TimelineDiffCollectionSourceReports.reports/3
    )
  end

  def reports(refresh, :source_command_window_reports) do
    inherited_result_artifact_source_reports(
      refresh,
      &CommandManeuverReviewSourceReports.command_window_reports/3
    )
  end

  def reports(refresh, :source_maneuver_review_reports) do
    inherited_result_artifact_source_reports(
      refresh,
      &CommandManeuverReviewSourceReports.maneuver_review_reports/3
    )
  end

  def reports(refresh, :source_resource_projection_reports) do
    inherited_result_artifact_source_reports(
      refresh,
      &ResourceCollectionSourceReports.resource_projection_reports/3
    )
  end

  def reports(refresh, :source_resource_filter_reports) do
    inherited_result_artifact_source_reports(
      refresh,
      &ResourceCollectionSourceReports.resource_filter_reports/3
    )
  end

  def reports(refresh, :source_link_capacity_reports) do
    inherited_result_artifact_source_reports(
      refresh,
      &LinkConstraintCollectionSourceReports.link_capacity_reports/3
    )
  end

  def reports(refresh, :source_contact_filter_reports) do
    inherited_result_artifact_source_reports(
      refresh,
      &ContactReviewCollectionSourceReports.contact_filter_reports/3
    )
  end

  defp inherited_result_artifact_source_reports(refresh, reports_fun) do
    reports_fun.(
      refresh,
      &ResultArtifactCollectionSourceReports.reports/1,
      &ResultArtifactTrustBoundary.inherit/2
    )
  end

  defp result_artifact_source_reports(refresh, reports_fun) do
    reports_fun.(refresh, &ResultArtifactCollectionSourceReports.reports/1)
  end
end
