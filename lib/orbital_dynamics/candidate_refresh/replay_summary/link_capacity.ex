defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.Summary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance

  def replay(refresh_or_artifact, source_report_summary)
      when is_function(source_report_summary, 1) do
    branch_link_summary = source_report_summary_branch_family(refresh_or_artifact)

    link_summary =
      branch_link_summary ||
        refresh_or_artifact
        |> source_report_summary.()
        |> get_in(["source_reports", "link_capacity_report"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_link_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.link_capacity_report",
          "link_capacity_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.link_capacity_report",
          "link_capacity_source_report_provenance_only"
        }
      end

    summary(link_summary, summary_source, replay_scope)
  end

  def summary(link_summary, summary_source, replay_scope),
    do: Summary.summary(link_summary, summary_source, replay_scope)

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "link_capacity_report",
      &InputProvenance.build/1
    )
  end
end
