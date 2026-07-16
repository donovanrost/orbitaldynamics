defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.Candidate do
  @moduledoc false

  alias __MODULE__.Diff
  alias __MODULE__.Rejection

  def diff(refresh_or_artifact, source_report_summary)
      when is_function(source_report_summary, 1) do
    Diff.replay(
      refresh_or_artifact,
      source_report_summary
    )
  end

  def diff(diff_summary, summary_source, replay_scope) do
    Diff.summary(diff_summary, summary_source, replay_scope)
  end

  def rejection(refresh_or_artifact, source_report_summary)
      when is_function(source_report_summary, 1) do
    Rejection.replay(
      refresh_or_artifact,
      source_report_summary
    )
  end

  def rejection(rejection_summary, summary_source, replay_scope) do
    Rejection.summary(rejection_summary, summary_source, replay_scope)
  end
end
