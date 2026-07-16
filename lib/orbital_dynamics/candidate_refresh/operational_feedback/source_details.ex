defmodule OrbitalDynamics.CandidateRefresh.OperationalFeedback.SourceDetails do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResultArtifactCollection,
    as: ResultArtifactCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineFeedbackCollection,
    as: TimelineFeedbackCollectionSourceReports

  def timeline_feedback_report_paths(refresh) do
    timeline_feedback_report_paths(
      refresh,
      &source_timeline_feedback_reports/1
    )
  end

  def timeline_feedback_report_paths(refresh, source_timeline_feedback_reports_fun) do
    refresh
    |> source_timeline_feedback_reports_fun.()
    |> paths()
  end

  def timeline_diff_report_paths(refresh, source_timeline_diff_reports_fun) do
    refresh
    |> source_timeline_diff_reports_fun.()
    |> paths()
  end

  def operational_timeline_report_paths(refresh, source_operational_timeline_reports_fun) do
    refresh
    |> source_operational_timeline_reports_fun.()
    |> paths()
  end

  def command_window_report_paths(refresh, source_command_window_reports_fun) do
    refresh
    |> source_command_window_reports_fun.()
    |> paths()
  end

  def maneuver_review_report_paths(refresh, source_maneuver_review_reports_fun) do
    refresh
    |> source_maneuver_review_reports_fun.()
    |> paths()
  end

  def timeline_feedback_report_sources(refresh) do
    timeline_feedback_report_sources(
      refresh,
      &source_timeline_feedback_reports/1
    )
  end

  def timeline_feedback_report_sources(refresh, source_timeline_feedback_reports_fun) do
    refresh
    |> source_timeline_feedback_reports_fun.()
    |> Enum.map(fn {path, report} ->
      report
      |> SourceReportSummary.TimelineFeedback.timeline_feedback_report_source()
      |> Map.put("source_path", path)
    end)
  end

  def timeline_diff_report_sources(refresh, source_timeline_diff_reports_fun) do
    refresh
    |> source_timeline_diff_reports_fun.()
    |> Enum.map(fn {path, report} ->
      report
      |> SourceReportSummary.TimelineDiffIntegrity.timeline_diff_report_source()
      |> Map.put("source_path", path)
    end)
    |> Enum.reject(&(Map.get(&1, "input_keys", []) == []))
  end

  def operational_timeline_report_sources(refresh, source_operational_timeline_reports_fun) do
    refresh
    |> source_operational_timeline_reports_fun.()
    |> Enum.map(fn {path, report} ->
      report
      |> SourceReportSummary.OperationalTimeline.operational_timeline_report_source()
      |> Map.put("source_path", path)
    end)
    |> Enum.reject(fn source ->
      Map.get(source, "input_keys", []) == [] and
        Map.get(source, "source_timeline_integrity_issue_count", 0) == 0
    end)
  end

  def command_window_report_sources(refresh, source_command_window_reports_fun) do
    refresh
    |> source_command_window_reports_fun.()
    |> Enum.map(fn {path, report} ->
      report
      |> SourceReportSummary.CommandManeuverReview.command_window_report_source()
      |> Map.put("source_path", path)
    end)
    |> Enum.reject(&(Map.get(&1, "input_keys", []) == []))
  end

  def maneuver_review_report_sources(refresh, source_maneuver_review_reports_fun) do
    refresh
    |> source_maneuver_review_reports_fun.()
    |> Enum.map(fn {path, report} ->
      report
      |> SourceReportSummary.CommandManeuverReview.maneuver_review_report_source()
      |> Map.put("source_path", path)
    end)
    |> Enum.reject(&(Map.get(&1, "input_keys", []) == []))
  end

  defp paths(reports) do
    Enum.map(reports, fn {path, _report} -> path end)
  end

  defp source_timeline_feedback_reports(refresh) do
    TimelineFeedbackCollectionSourceReports.reports(
      refresh,
      &ResultArtifactCollectionSourceReports.reports/1
    )
  end
end
