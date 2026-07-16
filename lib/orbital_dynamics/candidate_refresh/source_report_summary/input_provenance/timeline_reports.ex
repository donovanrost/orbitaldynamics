defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.TimelineReports do
  @moduledoc false

  alias __MODULE__.Definitions
  alias __MODULE__.ReportSources
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.Summary

  @sources [
    :source_timeline_feedback_reports,
    :source_operational_timeline_reports,
    :source_timeline_diff_reports,
    :source_timeline_integrity_reports,
    :source_timeline_activity_states,
    :source_timeline_activity_lifecycle_states,
    :source_timeline_activity_precondition_summaries,
    :source_timeline_lifecycle_state_summaries,
    :source_timeline_dependency_impact_summaries,
    :source_timeline_publication_summaries,
    :source_timeline_transition_application_reports
  ]

  def build(refresh) do
    Summary.from_definitions(refresh, Definitions.definitions())
  end

  def source?(source), do: source in @sources

  def reports(refresh, source), do: ReportSources.reports(refresh, source)
end
