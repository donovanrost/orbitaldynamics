defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.ContactNetworkReports.ReportSources.CollectionFunctions do
  @moduledoc false

  alias __MODULE__.{ContactFunctions, StationFunctions}

  def function_for(:source_provider_counteroffer_reports),
    do: StationFunctions.function_for(:source_provider_counteroffer_reports)

  def function_for(:source_station_calendar_reports),
    do: StationFunctions.function_for(:source_station_calendar_reports)

  def function_for(:source_station_reservation_reports),
    do: StationFunctions.function_for(:source_station_reservation_reports)

  def function_for(:source_contact_intents),
    do: ContactFunctions.function_for(:source_contact_intents)

  def function_for(:source_contact_filter_reports),
    do: ContactFunctions.function_for(:source_contact_filter_reports)

  def function_for(:source_link_capacity_reports),
    do: ContactFunctions.function_for(:source_link_capacity_reports)

  def function_for(:source_contact_allocation_reports),
    do: ContactFunctions.function_for(:source_contact_allocation_reports)

  def function_for(:source_contact_contention_reports),
    do: ContactFunctions.function_for(:source_contact_contention_reports)

  def function_for(:source_contact_contention_resolution_reports),
    do: ContactFunctions.function_for(:source_contact_contention_resolution_reports)
end
