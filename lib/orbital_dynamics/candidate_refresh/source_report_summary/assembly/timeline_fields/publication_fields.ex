defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Assembly.TimelineFields.PublicationFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePublication.SourceReportFields,
    as: TimelinePublicationFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePublication.SourceReportFields.Flattened,
    as: TimelinePublicationFlattenedFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePublicationContext.SourceReportFields,
    as: TimelinePublicationContextFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineTransitionApplication.SourceReportFields,
    as: TimelineTransitionApplicationFields

  def source_report_fields(source_reports) do
    TimelinePublicationFlattenedFields.dependency_id_fields(source_reports)
    |> Map.merge(TimelinePublicationFields.source_report_fields(source_reports))
    |> Map.merge(TimelineTransitionApplicationFields.source_report_fields(source_reports))
    |> Map.merge(
      publication_context_fields(
        source_reports,
        "operational_readiness_report",
        "source_report_operational_readiness"
      )
    )
    |> Map.merge(
      publication_context_fields(
        source_reports,
        "quality_gate_report",
        "source_report_quality_gate"
      )
    )
  end

  defp publication_context_fields(source_reports, family, prefix) do
    TimelinePublicationContextFields.source_report_fields(source_reports, family, prefix)
  end
end
