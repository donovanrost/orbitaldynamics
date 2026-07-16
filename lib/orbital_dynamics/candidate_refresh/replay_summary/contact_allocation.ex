defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.Summary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance

  def replay(refresh_or_artifact, source_report_summary)
      when is_function(source_report_summary, 1) do
    branch_allocation_summary = source_report_summary_branch_family(refresh_or_artifact)

    allocation_summary =
      branch_allocation_summary ||
        refresh_or_artifact
        |> source_report_summary.()
        |> get_in(["source_reports", "contact_allocation_report"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_allocation_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_allocation_report",
          "contact_allocation_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.contact_allocation_report",
          "contact_allocation_source_report_provenance_only"
        }
      end

    summary(allocation_summary, summary_source, replay_scope)
  end

  def summary(allocation_summary, summary_source, replay_scope) do
    Summary.summary(allocation_summary, summary_source, replay_scope)
  end

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "contact_allocation_report",
      &InputProvenance.build/1
    )
  end
end
