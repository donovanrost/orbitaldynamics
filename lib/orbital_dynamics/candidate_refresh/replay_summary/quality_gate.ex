defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.QualityGate do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance
  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.QualityGate.Summary
  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePublicationContext

  def replay(refresh_or_artifact) do
    branch_quality_gate_summary = source_report_summary_branch_family(refresh_or_artifact)

    quality_gate_summary =
      branch_quality_gate_summary ||
        refresh_or_artifact
        |> SourceReportSummary.build()
        |> get_in(["source_reports", "quality_gate_report"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_quality_gate_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.quality_gate_report",
          "quality_gate_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.quality_gate_report",
          "quality_gate_source_report_provenance_only"
        }
      end

    timeline_publication_context = TimelinePublicationContext.fields(quality_gate_summary, false)

    summary(
      quality_gate_summary,
      summary_source,
      replay_scope,
      timeline_publication_context
    )
  end

  def pressure_fields(quality_gate_summary) do
    Summary.pressure_fields(quality_gate_summary)
  end

  def summary(
        quality_gate_summary,
        summary_source,
        replay_scope,
        timeline_publication_context
      ) do
    Summary.summary(
      quality_gate_summary,
      summary_source,
      replay_scope,
      timeline_publication_context
    )
  end

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "quality_gate_report",
      &InputProvenance.build/1
    )
  end
end
