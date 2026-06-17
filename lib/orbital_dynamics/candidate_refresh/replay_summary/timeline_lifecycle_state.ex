defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineLifecycleState do
  @moduledoc false

  alias __MODULE__.SourceReportFields
  alias __MODULE__.Summary

  def replay(refresh_or_artifact, callbacks) do
    source_report_summary = Keyword.fetch!(callbacks, :source_report_summary)

    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_lifecycle_summary =
      source_report_summary_branch_family.(
        refresh_or_artifact,
        "timeline_lifecycle_state_summary"
      )

    lifecycle_summary =
      branch_lifecycle_summary ||
        refresh_or_artifact
        |> source_report_summary.()
        |> get_in(["source_reports", "timeline_lifecycle_state_summary"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_lifecycle_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_lifecycle_state_summary",
          "timeline_lifecycle_state_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.timeline_lifecycle_state_summary",
          "timeline_lifecycle_state_source_report_provenance_only"
        }
      end

    summary(lifecycle_summary, summary_source, replay_scope)
  end

  def summary(lifecycle_summary, summary_source, replay_scope) do
    Summary.summary(lifecycle_summary, summary_source, replay_scope)
  end

  def source_report_fields(source_reports) do
    SourceReportFields.source_report_fields(source_reports)
  end
end
