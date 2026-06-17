defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ManeuverReview do
  @moduledoc false

  alias __MODULE__.SourceReportFields
  alias __MODULE__.Summary

  def replay(refresh_or_artifact, callbacks) do
    source_report_summary = Keyword.fetch!(callbacks, :source_report_summary)

    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_maneuver_summary =
      source_report_summary_branch_family.(refresh_or_artifact, "maneuver_review_report")

    maneuver_summary =
      branch_maneuver_summary ||
        refresh_or_artifact
        |> source_report_summary.()
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

  def source_report_fields(source_reports) do
    summary =
      source_reports
      |> Map.get("maneuver_review_report", %{})
      |> summary(
        "candidate_refresh.source_report_provenance.maneuver_review_report",
        "maneuver_review_source_report_provenance_only"
      )

    SourceReportFields.source_report_fields(source_reports, summary)
  end

  def summary(maneuver_summary, summary_source, replay_scope) do
    Summary.summary(maneuver_summary, summary_source, replay_scope)
  end
end
