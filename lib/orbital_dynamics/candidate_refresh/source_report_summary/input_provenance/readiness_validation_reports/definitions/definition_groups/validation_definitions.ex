defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.ReadinessValidationReports.Definitions.DefinitionGroups.ValidationDefinitions do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary

  def definitions do
    [
      %{
        key: "model_acceptance_report",
        source: :source_model_acceptance_reports,
        summary: &SourceReportSummary.ModelAcceptance.report_input_summary/1
      },
      %{
        key: "validation_safety_case_summary",
        source: :source_validation_safety_case_summaries,
        summary: &SourceReportSummary.ValidationSafetyCase.summary_input_summary/1
      },
      %{
        key: "schema_validation_report",
        source: :source_schema_validation_reports,
        summary: &SourceReportSummary.SchemaValidation.report_input_summary/1
      }
    ]
  end
end
