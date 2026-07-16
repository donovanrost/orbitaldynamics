defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.TimelineReports.Definitions.DefinitionGroups.StateDefinitions do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary

  def definitions do
    [
      %{
        key: "timeline_activity_state",
        source: :source_timeline_activity_states,
        summary: &SourceReportSummary.TimelineActivityState.report_input_summary/1
      },
      %{
        key: "timeline_activity_lifecycle_state",
        source: :source_timeline_activity_lifecycle_states,
        summary: &SourceReportSummary.TimelineActivityState.lifecycle_state_input_summary/1
      },
      %{
        key: "timeline_activity_precondition_summary",
        source: :source_timeline_activity_precondition_summaries,
        summary: &SourceReportSummary.TimelineActivityPrecondition.report_input_summary/1
      }
    ]
  end
end
