defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.Constraint do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias __MODULE__.Summary

  def replay(refresh_or_artifact) do
    constraint_summary =
      refresh_or_artifact
      |> SourceReportSummary.build()
      |> get_in(["source_reports", "constraint_report"]) ||
        %{}

    summary(
      constraint_summary,
      "candidate_refresh.source_report_provenance.constraint_report",
      "constraint_source_report_provenance_only"
    )
  end

  def summary(constraint_summary, summary_source, replay_scope) do
    Summary.summary(constraint_summary, summary_source, replay_scope)
  end
end
