defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivitySingleState do
  @moduledoc false

  alias __MODULE__.Selection
  alias __MODULE__.Summary

  @status %{
    family: "timeline_activity_status_state",
    contract: "timeline_activity_status_state.v1",
    source_model: "artifact_only_timeline_activity_status_state",
    application_boundary: "activity_status_state_application",
    authority_boundary: "not_granted_by_timeline_activity_status_state_replay_summary"
  }

  @approval %{
    family: "timeline_activity_approval_state",
    contract: "timeline_activity_approval_state.v1",
    source_model: "artifact_only_timeline_activity_approval_state",
    application_boundary: "activity_approval_state_application",
    authority_boundary: "not_granted_by_timeline_activity_approval_state_replay_summary"
  }

  def status(refresh_or_artifact) do
    replay(refresh_or_artifact, @status)
  end

  def approval(refresh_or_artifact) do
    replay(refresh_or_artifact, @approval)
  end

  def replay(refresh_or_artifact, config) when is_map(config) do
    replay(
      refresh_or_artifact,
      Map.fetch!(config, :family),
      Map.fetch!(config, :contract),
      Map.fetch!(config, :source_model),
      Map.fetch!(config, :application_boundary),
      Map.fetch!(config, :authority_boundary)
    )
  end

  def replay(
        refresh_or_artifact,
        family,
        contract,
        source_model,
        application_boundary,
        authority_boundary
      ) do
    {state_summary, summary_source, replay_scope} =
      Selection.summary_for_replay(
        refresh_or_artifact,
        family,
        contract,
        source_model
      )

    summary(
      state_summary,
      family,
      summary_source,
      replay_scope,
      application_boundary,
      authority_boundary
    )
  end

  def selected_source_report_summary(
        refresh_or_artifact,
        source_reports,
        contract,
        source_model
      ) do
    Selection.selected_source_report_summary(
      refresh_or_artifact,
      source_reports,
      contract,
      source_model
    )
  end

  def summary(
        state_summary,
        family,
        summary_source,
        replay_scope,
        application_boundary,
        authority_boundary
      ) do
    Summary.summary(
      state_summary,
      family,
      summary_source,
      replay_scope,
      application_boundary,
      authority_boundary
    )
  end
end
