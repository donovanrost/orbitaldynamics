defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.ReadinessValidationReports.ReportSources do
  @moduledoc false

  alias __MODULE__.CollectionFunctions
  alias __MODULE__.InheritedReports

  @inherited_sources [
    :source_freshness_reports,
    :source_refresh_budget_reports,
    :source_operational_readiness_reports,
    :source_model_acceptance_reports,
    :source_validation_safety_case_summaries,
    :source_schema_validation_reports
  ]

  def reports(refresh, :source_quality_gate_reports) do
    InheritedReports.quality_gate_reports(
      refresh,
      CollectionFunctions.function_for(:source_quality_gate_reports)
    )
  end

  def reports(refresh, source) when source in @inherited_sources do
    inherited_reports(refresh, source)
  end

  defp inherited_reports(refresh, source) do
    InheritedReports.reports(refresh, CollectionFunctions.function_for(source))
  end
end
