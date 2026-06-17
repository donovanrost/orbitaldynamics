defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.QualityGate do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.QualityGate.SourceReportFields
  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.QualityGate.Summary
  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePublicationContext

  def replay(refresh_or_artifact, callbacks) do
    source_report_summary = Keyword.fetch!(callbacks, :source_report_summary)

    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_quality_gate_summary =
      source_report_summary_branch_family.(refresh_or_artifact, "quality_gate_report")

    quality_gate_summary =
      branch_quality_gate_summary ||
        refresh_or_artifact
        |> source_report_summary.()
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

  def source_report_fields(refresh_or_artifact, source_reports, callbacks) do
    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_quality_gate_summary =
      source_report_summary_branch_family.(refresh_or_artifact, "quality_gate_report")

    quality_gate_summary =
      branch_quality_gate_summary || Map.get(source_reports, "quality_gate_report", %{})

    pressure_fields = pressure_fields(quality_gate_summary)
    timeline_fields = TimelinePublicationContext.fields(quality_gate_summary, false)

    %{
      "source_report_quality_gate_branch_local_review_pressure" =>
        Map.get(pressure_fields, "branch_local_review_pressure"),
      "source_report_quality_gate_branch_local_import_pressure" =>
        Map.get(pressure_fields, "branch_local_import_pressure"),
      "source_report_quality_gate_branch_local_resource_pressure" =>
        Map.get(pressure_fields, "branch_local_resource_pressure"),
      "source_report_quality_gate_branch_local_timeline_publication_pressure" =>
        Map.get(timeline_fields, "branch_local_timeline_publication_pressure"),
      "source_report_quality_gate_branch_local_timeline_publication_dependency_pressure" =>
        Map.get(timeline_fields, "branch_local_timeline_publication_dependency_pressure"),
      "source_report_quality_gate_branch_local_timeline_publication_changed_field_pressure" =>
        Map.get(timeline_fields, "branch_local_timeline_publication_changed_field_pressure"),
      "source_report_quality_gate_branch_local_timeline_publication_invalidation_pressure" =>
        Map.get(timeline_fields, "branch_local_timeline_publication_invalidation_pressure"),
      "source_report_quality_gate_branch_local_timeline_publication_review_pressure" =>
        Map.get(timeline_fields, "branch_local_timeline_publication_review_pressure")
    }
    |> Map.merge(SourceReportFields.source_report_fields(source_reports))
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
end
