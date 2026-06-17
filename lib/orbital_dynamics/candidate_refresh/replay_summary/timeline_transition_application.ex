defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineTransitionApplication do
  @moduledoc false

  alias __MODULE__.SourceReportFields
  alias __MODULE__.Summary

  def replay(refresh_or_artifact, callbacks) do
    source_report_summary = Keyword.fetch!(callbacks, :source_report_summary)

    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_transition_summary =
      source_report_summary_branch_family.(
        refresh_or_artifact,
        "timeline_transition_application_report"
      )

    transition_summary =
      branch_transition_summary ||
        refresh_or_artifact
        |> source_report_summary.()
        |> get_in(["source_reports", "timeline_transition_application_report"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_transition_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_transition_application_report",
          "timeline_transition_application_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.timeline_transition_application_report",
          "timeline_transition_application_source_report_provenance_only"
        }
      end

    summary(transition_summary, summary_source, replay_scope)
  end

  def source_report_fields(source_reports) do
    SourceReportFields.source_report_fields(source_reports)
  end

  def summary(transition_summary, summary_source, replay_scope) do
    Summary.summary(transition_summary, summary_source, replay_scope)
  end
end
