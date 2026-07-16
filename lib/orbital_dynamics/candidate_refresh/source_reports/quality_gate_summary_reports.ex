defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSummaryReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateImportReadinessSummaryReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateOperationalSummaryReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSchemaValidationSummaryReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSummaryDirectReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSummaryRecognition

  def summary?(summary), do: QualityGateSummaryRecognition.summary?(summary)

  def unavailable_resource_summary?(summary),
    do: QualityGateOperationalSummaryReports.unavailable_resource_summary?(summary)

  def operator_training_summary?(summary),
    do: QualityGateOperationalSummaryReports.operator_training_summary?(summary)

  def schema_validation_summary?(summary),
    do: QualityGateSchemaValidationSummaryReports.schema_validation_summary?(summary)

  def import_readiness_summary?(summary),
    do: QualityGateImportReadinessSummaryReports.import_readiness_summary?(summary)

  def report_from_summary(%{} = summary) do
    QualityGateSummaryDirectReports.report_from_summary(summary)
  end

  def report_from_unavailable_resource_summary(%{} = summary) do
    QualityGateOperationalSummaryReports.report_from_unavailable_resource_summary(summary)
  end

  def report_from_operator_training_summary(%{} = summary) do
    QualityGateOperationalSummaryReports.report_from_operator_training_summary(summary)
  end

  def report_from_schema_validation_summary(%{} = summary) do
    QualityGateSchemaValidationSummaryReports.report_from_schema_validation_summary(summary)
  end

  def report_from_import_readiness_summary(%{} = summary) do
    QualityGateImportReadinessSummaryReports.report_from_import_readiness_summary(summary)
  end
end
