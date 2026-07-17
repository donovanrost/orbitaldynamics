defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineDependencyImpact do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance

  alias __MODULE__.Summary

  def replay(refresh_or_artifact) do
    branch_impact_summary = source_report_summary_branch_family(refresh_or_artifact)

    impact_summary =
      branch_impact_summary ||
        refresh_or_artifact
        |> SourceReportSummary.build()
        |> get_in(["source_reports", "timeline_dependency_impact_summary"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_impact_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_dependency_impact_summary",
          "timeline_dependency_impact_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.timeline_dependency_impact_summary",
          "timeline_dependency_impact_source_report_provenance_only"
        }
      end

    summary(impact_summary, summary_source, replay_scope)
  end

  def summary(impact_summary, summary_source, replay_scope) do
    Summary.summary(impact_summary, summary_source, replay_scope)
  end

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "timeline_dependency_impact_summary",
      &InputProvenance.build/1
    )
  end
end
