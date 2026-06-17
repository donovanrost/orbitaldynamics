defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.Candidate do
  @moduledoc false

  alias __MODULE__.Diff
  alias __MODULE__.Rejection

  def diff(refresh_or_artifact, callbacks) do
    Diff.replay(refresh_or_artifact, callbacks)
  end

  def diff(diff_summary, summary_source, replay_scope) do
    Diff.summary(diff_summary, summary_source, replay_scope)
  end

  def rejection(refresh_or_artifact, callbacks) do
    Rejection.replay(refresh_or_artifact, callbacks)
  end

  def rejection(rejection_summary, summary_source, replay_scope) do
    Rejection.summary(rejection_summary, summary_source, replay_scope)
  end

  def diff_source_report_fields(source_reports) do
    Diff.source_report_fields(source_reports)
  end

  def diff_source_report_summary_fields(source_reports) do
    Diff.source_report_summary_fields(source_reports)
  end

  def diff_source_report_detail_fields(source_reports) do
    Diff.source_report_detail_fields(source_reports)
  end

  def rejection_source_report_fields(source_reports) do
    Rejection.source_report_fields(source_reports)
  end

  def rejection_source_report_summary_fields(source_reports) do
    Rejection.source_report_summary_fields(source_reports)
  end

  def rejection_source_report_detail_fields(source_reports) do
    Rejection.source_report_detail_fields(source_reports)
  end
end
