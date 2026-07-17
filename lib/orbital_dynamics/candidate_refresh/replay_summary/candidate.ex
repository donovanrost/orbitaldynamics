defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.Candidate do
  @moduledoc false

  alias __MODULE__.Diff
  alias __MODULE__.Rejection

  def diff(refresh_or_artifact) do
    Diff.replay(refresh_or_artifact)
  end

  def diff(diff_summary, summary_source, replay_scope) do
    Diff.summary(diff_summary, summary_source, replay_scope)
  end

  def rejection(refresh_or_artifact) do
    Rejection.replay(refresh_or_artifact)
  end

  def rejection(rejection_summary, summary_source, replay_scope) do
    Rejection.summary(rejection_summary, summary_source, replay_scope)
  end
end
