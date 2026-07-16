defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.ReadinessValidationReports do
  @moduledoc false

  alias __MODULE__.Definitions
  alias __MODULE__.ReportSources
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.Summary

  @sources [
    :source_freshness_reports,
    :source_refresh_budget_reports,
    :source_operational_readiness_reports,
    :source_quality_gate_reports,
    :source_model_acceptance_reports,
    :source_validation_safety_case_summaries,
    :source_schema_validation_reports
  ]

  def build(refresh) do
    Summary.from_definitions(refresh, Definitions.definitions())
  end

  def source?(source), do: source in @sources

  def reports(refresh, source), do: ReportSources.reports(refresh, source)
end
