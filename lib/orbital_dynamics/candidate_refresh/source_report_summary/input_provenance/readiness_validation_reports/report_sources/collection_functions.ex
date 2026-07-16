defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.ReadinessValidationReports.ReportSources.CollectionFunctions do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.FreshnessBudget,
    as: FreshnessBudgetSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ModelValidation,
    as: ModelValidationSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGate,
    as: ReadinessQualityGateSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationCollection,
    as: SchemaValidationCollectionSourceReports

  def function_for(:source_freshness_reports),
    do: &FreshnessBudgetSourceReports.freshness_reports/3

  def function_for(:source_refresh_budget_reports),
    do: &FreshnessBudgetSourceReports.refresh_budget_reports/3

  def function_for(:source_operational_readiness_reports),
    do: &ReadinessQualityGateSourceReports.operational_readiness_reports/3

  def function_for(:source_quality_gate_reports),
    do: &ReadinessQualityGateSourceReports.quality_gate_reports/3

  def function_for(:source_model_acceptance_reports),
    do: &ModelValidationSourceReports.model_acceptance_reports/3

  def function_for(:source_validation_safety_case_summaries),
    do: &ModelValidationSourceReports.validation_safety_case_summaries/3

  def function_for(:source_schema_validation_reports),
    do: &SchemaValidationCollectionSourceReports.reports/3
end
