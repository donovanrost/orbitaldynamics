defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Assembly.ReadinessValidationFields.ValidationFields.ValidationReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.Validation.SchemaValidation,
    as: SchemaValidationFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ValidationSafetyCase.SourceReportFields,
    as: ValidationSafetyCaseFields

  def fields(refresh_or_artifact, source_reports) do
    ValidationSafetyCaseFields.source_report_summary_fields(
      refresh_or_artifact,
      source_reports
    )
    |> Map.merge(
      SchemaValidationFields.source_report_fields(
        refresh_or_artifact,
        source_reports
      )
    )
  end
end
