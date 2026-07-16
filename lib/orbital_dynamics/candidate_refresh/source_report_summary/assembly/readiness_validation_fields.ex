defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Assembly.ReadinessValidationFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ModelAcceptance.SourceReportFields,
    as: ModelAcceptanceFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.OperationalReadiness.SourceReportFields,
    as: OperationalReadinessFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.QualityGate.SourceReportFields,
    as: QualityGateFields

  alias __MODULE__.ValidationFields

  def fields(refresh_or_artifact, source_reports) do
    ValidationFields.fields(refresh_or_artifact, source_reports)
    |> Map.merge(
      OperationalReadinessFields.source_report_summary_fields(
        refresh_or_artifact,
        source_reports
      )
    )
    |> Map.merge(
      QualityGateFields.source_report_summary_fields(
        refresh_or_artifact,
        source_reports
      )
    )
    |> Map.merge(
      ModelAcceptanceFields.source_report_summary_fields(
        refresh_or_artifact,
        source_reports
      )
    )
  end
end
