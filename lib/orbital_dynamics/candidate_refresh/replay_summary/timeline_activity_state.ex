defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivityState do
  @moduledoc false

  alias __MODULE__.SourceReportFields
  alias __MODULE__.Summary

  def replay(refresh_or_artifact, callbacks) do
    source_report_summary = Keyword.fetch!(callbacks, :source_report_summary)

    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_state_summary =
      source_report_summary_branch_family.(
        refresh_or_artifact,
        "timeline_activity_state"
      )

    state_summary =
      branch_state_summary ||
        refresh_or_artifact
        |> source_report_summary.()
        |> get_in(["source_reports", "timeline_activity_state"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_state_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_activity_state",
          "timeline_activity_state_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.timeline_activity_state",
          "timeline_activity_state_source_report_provenance_only"
        }
      end

    summary(state_summary, summary_source, replay_scope)
  end

  def source_report_fields(source_reports) do
    summary =
      source_reports
      |> Map.get("timeline_activity_state", %{})
      |> summary(
        "candidate_refresh.source_report_provenance.timeline_activity_state",
        "timeline_activity_state_source_report_provenance_only"
      )

    SourceReportFields.source_report_fields(source_reports, summary)
  end

  def summary(state_summary, summary_source, replay_scope) do
    Summary.summary(state_summary, summary_source, replay_scope)
  end
end
