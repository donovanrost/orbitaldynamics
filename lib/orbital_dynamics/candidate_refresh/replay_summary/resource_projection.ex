defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceProjection do
  @moduledoc false

  alias __MODULE__.Summary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance

  def replay(refresh_or_artifact, source_report_summary)
      when is_function(source_report_summary, 1) do
    branch_projection_summary = source_report_summary_branch_family(refresh_or_artifact)

    projection_summary =
      branch_projection_summary ||
        refresh_or_artifact
        |> source_report_summary.()
        |> get_in(["source_reports", "resource_projection_report"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_projection_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.resource_projection_report",
          "resource_projection_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.resource_projection_report",
          "resource_projection_source_report_provenance_only"
        }
      end

    summary(projection_summary, summary_source, replay_scope)
  end

  def summary(projection_summary, summary_source, replay_scope) do
    Summary.summary(projection_summary, summary_source, replay_scope)
  end

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "resource_projection_report",
      &InputProvenance.build/1
    )
  end
end
