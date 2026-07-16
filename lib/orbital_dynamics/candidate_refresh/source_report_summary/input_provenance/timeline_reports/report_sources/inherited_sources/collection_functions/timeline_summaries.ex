defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.TimelineReports.ReportSources.InheritedSources.CollectionFunctions.TimelineSummaries do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactCollection,
    as: TimelineDependencyImpactCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineLifecycleStateCollection,
    as: TimelineLifecycleStateCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationCollection,
    as: TimelinePublicationCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationCollection,
    as: TimelineTransitionApplicationCollectionSourceReports

  def function_for(:source_timeline_lifecycle_state_summaries),
    do: &TimelineLifecycleStateCollectionSourceReports.reports/3

  def function_for(:source_timeline_dependency_impact_summaries),
    do: &TimelineDependencyImpactCollectionSourceReports.reports/3

  def function_for(:source_timeline_publication_summaries),
    do: &TimelinePublicationCollectionSourceReports.reports/3

  def function_for(:source_timeline_transition_application_reports),
    do: &TimelineTransitionApplicationCollectionSourceReports.reports/3
end
