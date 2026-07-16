defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.TimelineReports.Definitions.DefinitionGroups.ReportDefinitions do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary

  def definitions do
    [
      %{
        key: "timeline_feedback_report",
        source: :source_timeline_feedback_reports,
        summary: &SourceReportSummary.TimelineFeedback.report_input_summary/1
      },
      %{
        key: "operational_timeline_report",
        source: :source_operational_timeline_reports,
        summary: &SourceReportSummary.OperationalTimeline.report_input_summary/1
      },
      %{
        key: "timeline_diff_report",
        mode: :deduplicated,
        source: :source_timeline_diff_reports,
        summary: &SourceReportSummary.TimelineDiffIntegrity.timeline_diff_report_input_summary/1
      },
      %{
        key: "timeline_integrity_report",
        source: :source_timeline_integrity_reports,
        summary: &SourceReportSummary.TimelineDiffIntegrity.integrity_report_input_summary/1
      }
    ]
  end
end
