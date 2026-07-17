defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ManeuverReview do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance

  alias __MODULE__.Summary

  def replay(refresh_or_artifact) do
    branch_maneuver_summary = source_report_summary_branch_family(refresh_or_artifact)

    maneuver_summary =
      branch_maneuver_summary ||
        refresh_or_artifact
        |> SourceReportSummary.build()
        |> get_in(["source_reports", "maneuver_review_report"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_maneuver_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.maneuver_review_report",
          "maneuver_review_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.maneuver_review_report",
          "maneuver_review_source_report_provenance_only"
        }
      end

    summary(maneuver_summary, summary_source, replay_scope)
  end

  def summary(maneuver_summary, summary_source, replay_scope) do
    Summary.summary(maneuver_summary, summary_source, replay_scope)
  end

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "maneuver_review_report",
      &InputProvenance.build/1
    )
  end
end
