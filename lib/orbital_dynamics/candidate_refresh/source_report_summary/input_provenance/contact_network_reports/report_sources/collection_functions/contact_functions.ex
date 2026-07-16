defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.ContactNetworkReports.ReportSources.CollectionFunctions.ContactFunctions do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactIntentCollection,
    as: ContactIntentCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollection,
    as: ContactReviewCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkConstraintCollection,
    as: LinkConstraintCollectionSourceReports

  def function_for(:source_contact_intents),
    do: &ContactIntentCollectionSourceReports.reports/3

  def function_for(:source_contact_filter_reports),
    do: &ContactReviewCollectionSourceReports.contact_filter_reports/3

  def function_for(:source_link_capacity_reports),
    do: &LinkConstraintCollectionSourceReports.link_capacity_reports/3

  def function_for(:source_contact_allocation_reports),
    do: &ContactReviewCollectionSourceReports.contact_allocation_reports/3

  def function_for(:source_contact_contention_reports),
    do: &ContactReviewCollectionSourceReports.contact_contention_reports/3

  def function_for(:source_contact_contention_resolution_reports),
    do: &ContactReviewCollectionSourceReports.contact_contention_resolution_reports/3
end
