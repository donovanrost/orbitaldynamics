defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.ReadinessValidationReports.Definitions.DefinitionGroups.ReadinessDefinitions do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary

  def definitions do
    [
      %{
        key: "operational_readiness_report",
        source: :source_operational_readiness_reports,
        summary: &SourceReportSummary.OperationalReadiness.report_input_summary/1
      },
      %{
        key: "quality_gate_report",
        source: :source_quality_gate_reports,
        summary: &SourceReportSummary.QualityGate.report_input_summary/1
      }
    ]
  end
end
