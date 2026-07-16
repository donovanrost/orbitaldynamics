defmodule OrbitalDynamics.CandidateRefresh.OperationalFeedback.Assembly do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.CandidateDiffReport
  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback
  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.Input
  alias OrbitalDynamics.CandidateRefresh.ResultArtifactTrustBoundary

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.ResultArtifactSources,
    as: ResultArtifactOperationalFeedbackSources

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.RealizedActivitySourceRows,
    as: RealizedActivitySourceRowsOperationalFeedback

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.ResourceReportSources,
    as: ResourceReportOperationalFeedbackSources

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.SourceReports

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.TimelineReportSources,
    as: TimelineReportOperationalFeedbackSources

  alias OrbitalDynamics.TimelineFeedback

  def build(refresh) do
    case Input.normalized(refresh) do
      feedback when is_map(feedback) ->
        normalize(feedback, refresh)

      _feedback ->
        %{}
    end
  end

  def normalize(feedback, refresh) when is_map(feedback) do
    refresh
    |> source_operational_timeline_report_operational_feedback()
    |> OperationalFeedback.merge(source_timeline_feedback_report_operational_feedback(refresh))
    |> OperationalFeedback.merge(source_timeline_diff_report_operational_feedback(refresh))
    |> OperationalFeedback.merge(source_command_window_report_operational_feedback(refresh))
    |> OperationalFeedback.merge(source_maneuver_review_report_operational_feedback(refresh))
    |> OperationalFeedback.merge(source_result_artifact_operational_feedback(refresh))
    |> OperationalFeedback.merge(source_resource_projection_report_operational_feedback(refresh))
    |> OperationalFeedback.merge(source_resource_filter_report_operational_feedback(refresh))
    |> OperationalFeedback.merge(source_link_capacity_report_operational_feedback(refresh))
    |> OperationalFeedback.merge(source_realized_activity_operational_feedback(refresh))
    |> OperationalFeedback.merge(
      OperationalFeedback.realized_activity_feedback(
        feedback,
        prior_candidate_activities(refresh)
      )
    )
    |> OperationalFeedback.merge(OperationalFeedback.normalize_explicit(feedback))
    |> OperationalFeedback.compact()
  end

  defp source_realized_activity_operational_feedback(refresh) do
    rows =
      refresh
      |> RealizedActivitySourceRowsOperationalFeedback.rows_for_refresh(
        &ResultArtifactTrustBoundary.inherit/2,
        &ResultArtifactTrustBoundary.boundary/1
      )
      |> Enum.map(fn {_path, row} -> row end)

    case OperationalFeedback.realized_activity_report_for_rows(
           rows,
           prior_candidate_activities(refresh)
         ) do
      %{} = report -> TimelineFeedback.operational_feedback(report)
      _report -> %{}
    end
  end

  defp source_result_artifact_operational_feedback(refresh) do
    refresh
    |> ResultArtifactOperationalFeedbackSources.sources_for_refresh(
      &ResultArtifactTrustBoundary.boundary/1
    )
    |> OperationalFeedback.source_result_artifact_feedback()
  end

  defp source_operational_timeline_report_operational_feedback(refresh) do
    source_report_operational_feedback(
      refresh,
      :source_operational_timeline_reports,
      &TimelineReportOperationalFeedbackSources.operational_timeline_feedback/1
    )
  end

  defp source_timeline_feedback_report_operational_feedback(refresh) do
    source_report_operational_feedback(
      refresh,
      :source_timeline_feedback_reports,
      &TimelineReportOperationalFeedbackSources.timeline_feedback/1
    )
  end

  defp source_timeline_diff_report_operational_feedback(refresh) do
    source_report_operational_feedback(
      refresh,
      :source_timeline_diff_reports,
      &TimelineReportOperationalFeedbackSources.timeline_diff_feedback/1
    )
  end

  defp source_command_window_report_operational_feedback(refresh) do
    source_report_operational_feedback(
      refresh,
      :source_command_window_reports,
      &TimelineReportOperationalFeedbackSources.command_window_feedback/1
    )
  end

  defp source_maneuver_review_report_operational_feedback(refresh) do
    source_report_operational_feedback(
      refresh,
      :source_maneuver_review_reports,
      &TimelineReportOperationalFeedbackSources.maneuver_review_feedback/1
    )
  end

  defp source_resource_projection_report_operational_feedback(refresh) do
    source_report_operational_feedback(
      refresh,
      :source_resource_projection_reports,
      &ResourceReportOperationalFeedbackSources.resource_projection_feedback/1
    )
  end

  defp source_resource_filter_report_operational_feedback(refresh) do
    source_report_operational_feedback(
      refresh,
      :source_resource_filter_reports,
      &ResourceReportOperationalFeedbackSources.resource_filter_feedback/1
    )
  end

  defp source_link_capacity_report_operational_feedback(refresh) do
    source_report_operational_feedback(
      refresh,
      :source_link_capacity_reports,
      &ResourceReportOperationalFeedbackSources.link_capacity_feedback/1
    )
  end

  defp source_report_operational_feedback(refresh, source_key, feedback_fun) do
    refresh
    |> SourceReports.reports(source_key)
    |> then(feedback_fun)
  end

  defp prior_candidate_activities(refresh) do
    CandidateDiffReport.valid_prior_candidate_activities(refresh)
  end
end
