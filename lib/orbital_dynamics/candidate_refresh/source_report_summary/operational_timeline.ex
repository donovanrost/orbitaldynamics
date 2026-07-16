defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.InputSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.IntegrityFields
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.SourceReport

  def report_input_summary([]), do: nil

  def report_input_summary(sources), do: InputSummary.report_input_summary(sources)

  def operational_timeline_report_source(report),
    do: SourceReport.fields(report)

  def operational_timeline_report_integrity_issue_count(report),
    do: IntegrityFields.integrity_issue_count(report)

  def operational_timeline_report_dependency_issue_count(report),
    do: IntegrityFields.dependency_issue_count(report)

  def operational_timeline_report_exclusivity_issue_count(report),
    do: IntegrityFields.exclusivity_issue_count(report)
end
