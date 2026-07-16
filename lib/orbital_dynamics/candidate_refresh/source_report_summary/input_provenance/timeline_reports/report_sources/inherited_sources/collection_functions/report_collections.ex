defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.TimelineReports.ReportSources.InheritedSources.CollectionFunctions.ReportCollections do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineCollection,
    as: OperationalTimelineCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffCollection,
    as: TimelineDiffCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineIntegrityCollection,
    as: TimelineIntegrityCollectionSourceReports

  def function_for(:source_operational_timeline_reports),
    do: &OperationalTimelineCollectionSourceReports.reports/3

  def function_for(:source_timeline_diff_reports),
    do: &TimelineDiffCollectionSourceReports.reports/3

  def function_for(:source_timeline_integrity_reports),
    do: &TimelineIntegrityCollectionSourceReports.reports/3
end
