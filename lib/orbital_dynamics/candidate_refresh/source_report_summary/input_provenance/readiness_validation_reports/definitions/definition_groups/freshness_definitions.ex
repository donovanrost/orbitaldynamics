defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.ReadinessValidationReports.Definitions.DefinitionGroups.FreshnessDefinitions do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary

  def definitions do
    [
      %{
        key: "freshness_report",
        source: :source_freshness_reports,
        summary: &SourceReportSummary.FreshnessBudget.freshness_report_input_summary/1
      },
      %{
        key: "refresh_budget_report",
        source: :source_refresh_budget_reports,
        summary: &SourceReportSummary.FreshnessBudget.refresh_budget_report_input_summary/1
      }
    ]
  end
end
