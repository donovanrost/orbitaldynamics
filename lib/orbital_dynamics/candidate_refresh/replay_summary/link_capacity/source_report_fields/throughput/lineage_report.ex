defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Throughput.LineageReport do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Throughput.LineageReport.ContactFields

  def selected_contact_id_counts(report), do: ContactFields.selected_contact_id_counts(report)

  def selected_contact_ids(report), do: ContactFields.selected_contact_ids(report)

  def selected_source_window_ids(report), do: ContactFields.selected_source_window_ids(report)

  def selected_station_calendar_entry_ids(report),
    do: ContactFields.selected_station_calendar_entry_ids(report)

  def selected_station_calendar_provider_entry_ids(report),
    do: ContactFields.selected_station_calendar_provider_entry_ids(report)

  def actual_throughput_contact_id_counts(report),
    do: ContactFields.actual_throughput_contact_id_counts(report)

  def actual_throughput_contact_ids(report),
    do: ContactFields.actual_throughput_contact_ids(report)

  def actual_throughput_source_window_ids(report),
    do: ContactFields.actual_throughput_source_window_ids(report)

  def actual_throughput_station_calendar_entry_ids(report),
    do: ContactFields.actual_throughput_station_calendar_entry_ids(report)

  def actual_throughput_station_calendar_provider_entry_ids(report),
    do: ContactFields.actual_throughput_station_calendar_provider_entry_ids(report)
end
