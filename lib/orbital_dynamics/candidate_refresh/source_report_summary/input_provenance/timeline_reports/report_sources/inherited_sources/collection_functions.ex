defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.TimelineReports.ReportSources.InheritedSources.CollectionFunctions do
  @moduledoc false

  alias __MODULE__.{ActivityCollections, ReportCollections, TimelineSummaries}

  def function_for(:source_operational_timeline_reports),
    do: ReportCollections.function_for(:source_operational_timeline_reports)

  def function_for(:source_timeline_diff_reports),
    do: ReportCollections.function_for(:source_timeline_diff_reports)

  def function_for(:source_timeline_integrity_reports),
    do: ReportCollections.function_for(:source_timeline_integrity_reports)

  def function_for(:source_timeline_activity_states),
    do: ActivityCollections.function_for(:source_timeline_activity_states)

  def function_for(:source_timeline_activity_lifecycle_states),
    do: ActivityCollections.function_for(:source_timeline_activity_lifecycle_states)

  def function_for(:source_timeline_activity_precondition_summaries),
    do: ActivityCollections.function_for(:source_timeline_activity_precondition_summaries)

  def function_for(:source_timeline_lifecycle_state_summaries),
    do: TimelineSummaries.function_for(:source_timeline_lifecycle_state_summaries)

  def function_for(:source_timeline_dependency_impact_summaries),
    do: TimelineSummaries.function_for(:source_timeline_dependency_impact_summaries)

  def function_for(:source_timeline_publication_summaries),
    do: TimelineSummaries.function_for(:source_timeline_publication_summaries)

  def function_for(:source_timeline_transition_application_reports),
    do: TimelineSummaries.function_for(:source_timeline_transition_application_reports)
end
