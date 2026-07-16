defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.TimelineReports.Definitions.DefinitionGroups.SummaryDefinitions do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary

  def definitions do
    [
      %{
        key: "timeline_lifecycle_state_summary",
        source: :source_timeline_lifecycle_state_summaries,
        summary: &SourceReportSummary.TimelineLifecycleState.report_input_summary/1
      },
      %{
        key: "timeline_dependency_impact_summary",
        source: :source_timeline_dependency_impact_summaries,
        summary: &SourceReportSummary.TimelineDependencyImpact.report_input_summary/1
      },
      %{
        key: "timeline_publication_summary",
        source: :source_timeline_publication_summaries,
        summary: &SourceReportSummary.TimelinePublication.report_input_summary/1
      },
      %{
        key: "timeline_transition_application_report",
        source: :source_timeline_transition_application_reports,
        summary: &SourceReportSummary.TimelineTransitionApplication.report_input_summary/1
      }
    ]
  end
end
