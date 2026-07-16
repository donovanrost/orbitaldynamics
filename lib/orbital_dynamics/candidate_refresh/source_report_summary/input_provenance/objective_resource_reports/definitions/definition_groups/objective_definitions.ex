defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.ObjectiveResourceReports.Definitions.DefinitionGroups.ObjectiveDefinitions do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary

  def definitions do
    [
      %{
        key: "constraint_report",
        source: :source_constraint_reports,
        summary: &SourceReportSummary.Constraint.report_input_summary/1
      },
      %{
        key: "objective_satisfaction_report",
        source: :source_objective_satisfaction_reports,
        summary: &SourceReportSummary.ObjectiveGap.objective_satisfaction_report_input_summary/1
      },
      %{
        key: "objective_tradeoff_report",
        source: :source_objective_tradeoff_reports,
        summary: &SourceReportSummary.ObjectiveGap.objective_tradeoff_report_input_summary/1
      },
      %{
        key: "score_term_report",
        source: :source_score_term_reports,
        summary: &SourceReportSummary.ObjectiveGap.score_term_report_input_summary/1
      }
    ]
  end
end
