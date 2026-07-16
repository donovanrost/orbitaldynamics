defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.TimelineReports.ReportSources.InheritedSources.CollectionFunctions.ActivityCollections do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityLifecycleStateCollection,
    as: TimelineActivityLifecycleStateCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionCollection,
    as: TimelineActivityPreconditionCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityStateCollection,
    as: TimelineActivityStateCollectionSourceReports

  def function_for(:source_timeline_activity_states),
    do: &TimelineActivityStateCollectionSourceReports.reports/3

  def function_for(:source_timeline_activity_lifecycle_states),
    do: &TimelineActivityLifecycleStateCollectionSourceReports.reports/3

  def function_for(:source_timeline_activity_precondition_summaries),
    do: &TimelineActivityPreconditionCollectionSourceReports.reports/3
end
