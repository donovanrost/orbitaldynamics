defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivitySingleState do
  @moduledoc false

  alias __MODULE__.Selection
  alias __MODULE__.SourceReportFields
  alias __MODULE__.Summary

  def replay(
        refresh_or_artifact,
        family,
        contract,
        source_model,
        application_boundary,
        authority_boundary,
        callbacks
      ) do
    {state_summary, summary_source, replay_scope} =
      Selection.summary_for_replay(refresh_or_artifact, family, contract, source_model, callbacks)

    summary(
      state_summary,
      family,
      summary_source,
      replay_scope,
      application_boundary,
      authority_boundary
    )
  end

  def source_report_fields(
        refresh_or_artifact,
        source_reports,
        family,
        contract,
        source_model,
        callbacks
      ) do
    summary =
      selected_source_report_summary(
        refresh_or_artifact,
        source_reports,
        contract,
        source_model,
        callbacks
      )

    SourceReportFields.source_report_fields(family, summary || %{})
  end

  def source_report_pressure_fields(
        refresh_or_artifact,
        source_reports,
        family,
        contract,
        source_model,
        application_boundary,
        authority_boundary,
        callbacks
      ) do
    selected_summary =
      refresh_or_artifact
      |> selected_source_report_summary(source_reports, contract, source_model, callbacks)

    summary =
      (selected_summary || %{})
      |> summary(
        family,
        "candidate_refresh.source_report_provenance.#{family}",
        "#{family}_source_report_provenance_only",
        application_boundary,
        authority_boundary
      )

    %{
      "source_report_#{family}_branch_local_#{family}_pressure" =>
        Map.get(summary, "branch_local_#{family}_pressure"),
      "source_report_#{family}_branch_local_review_pressure" =>
        Map.get(summary, "branch_local_#{family}_review_pressure"),
      "source_report_#{family}_branch_local_action_pressure" =>
        Map.get(summary, "branch_local_#{family}_action_pressure"),
      "source_report_#{family}_branch_local_routing_pressure" =>
        Map.get(summary, "branch_local_#{family}_routing_pressure")
    }
  end

  def selected_source_report_summary(
        refresh_or_artifact,
        source_reports,
        contract,
        source_model,
        callbacks
      ) do
    Selection.selected_source_report_summary(
      refresh_or_artifact,
      source_reports,
      contract,
      source_model,
      callbacks
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
