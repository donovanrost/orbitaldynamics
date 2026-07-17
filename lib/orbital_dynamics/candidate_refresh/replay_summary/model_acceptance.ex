defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ModelAcceptance do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance

  alias __MODULE__.Summary

  def replay(refresh_or_artifact) do
    branch_model_acceptance_summary = source_report_summary_branch_family(refresh_or_artifact)

    model_acceptance_summary =
      branch_model_acceptance_summary ||
        refresh_or_artifact
        |> SourceReportSummary.build()
        |> get_in(["source_reports", "model_acceptance_report"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_model_acceptance_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.model_acceptance_report",
          "model_acceptance_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.model_acceptance_report",
          "model_acceptance_source_report_provenance_only"
        }
      end

    summary(model_acceptance_summary, summary_source, replay_scope)
  end

  def pressure_fields(model_acceptance_summary) do
    Summary.pressure_fields(model_acceptance_summary)
  end

  def summary(model_acceptance_summary, summary_source, replay_scope) do
    Summary.summary(model_acceptance_summary, summary_source, replay_scope)
  end

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "model_acceptance_report",
      &InputProvenance.build/1
    )
  end
end
