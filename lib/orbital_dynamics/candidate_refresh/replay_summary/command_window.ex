defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.CommandWindow do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance

  alias __MODULE__.Summary

  def replay(refresh_or_artifact) do
    branch_command_summary = source_report_summary_branch_family(refresh_or_artifact)

    command_summary =
      branch_command_summary ||
        refresh_or_artifact
        |> SourceReportSummary.build()
        |> get_in(["source_reports", "command_window_report"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_command_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.command_window_report",
          "command_window_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.command_window_report",
          "command_window_source_report_provenance_only"
        }
      end

    summary(command_summary, summary_source, replay_scope)
  end

  def summary(command_summary, summary_source, replay_scope) do
    Summary.summary(command_summary, summary_source, replay_scope)
  end

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "command_window_report",
      &InputProvenance.build/1
    )
  end
end
