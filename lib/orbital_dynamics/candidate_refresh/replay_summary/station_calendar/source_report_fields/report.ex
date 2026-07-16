defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report do
  @moduledoc false

  alias __MODULE__.AggregateFields
  alias __MODULE__.DirectionFields
  alias __MODULE__.Rows
  alias __MODULE__.StatusAvailabilityFields

  import Rows,
    only: [
      summary_integer: 2
    ]

  def row_count(report),
    do: affected_contact_count(report) + provider_calendar_contention_group_count(report)

  def affected_contact_count(report) do
    case Map.get(report, "affected_contacts") do
      rows when is_list(rows) and rows != [] -> length(rows)
      _rows -> summary_integer(report, "affected_contact_count")
    end
  end

  def provider_calendar_contention_group_count(report),
    do: length(Map.get(report, "provider_calendar_contention_groups", []))

  def affected_contact_ids(reports) do
    AggregateFields.affected_contact_ids(reports)
  end

  def affected_station_calendar_entry_ids(reports) do
    AggregateFields.affected_station_calendar_entry_ids(reports)
  end

  def affected_station_reservation_ids(reports) do
    AggregateFields.affected_station_reservation_ids(reports)
  end

  def direction_counts(report) do
    DirectionFields.direction_counts(report)
  end

  def contact_ids_by_direction(report) do
    DirectionFields.contact_ids_by_direction(report)
  end

  def entry_ids_by_direction(report) do
    DirectionFields.entry_ids_by_direction(report)
  end

  def reservation_ids_by_direction(report) do
    DirectionFields.reservation_ids_by_direction(report)
  end

  def capacity_fractions_by_direction(report) do
    DirectionFields.capacity_fractions_by_direction(report)
  end

  def reserved_by_counts(report) do
    AggregateFields.reserved_by_counts(report)
  end

  def contact_ids_by_reserved_by(report) do
    AggregateFields.contact_ids_by_reserved_by(report)
  end

  def entry_ids_by_reserved_by(report) do
    AggregateFields.entry_ids_by_reserved_by(report)
  end

  def reservation_ids_by_reserved_by(report) do
    AggregateFields.reservation_ids_by_reserved_by(report)
  end

  def reservation_expires_at_s(reports) do
    AggregateFields.reservation_expires_at_s(reports)
  end

  def capacity_fractions(reports) do
    AggregateFields.capacity_fractions(reports)
  end

  def capacity_fractions_by_status(report) do
    StatusAvailabilityFields.capacity_fractions_by_status(report)
  end

  def capacity_fractions_by_ground_station(report) do
    StatusAvailabilityFields.capacity_fractions_by_ground_station(report)
  end

  def capacity_fractions_by_availability(report) do
    StatusAvailabilityFields.capacity_fractions_by_availability(report)
  end

  def contact_ids_by_status(report) do
    StatusAvailabilityFields.contact_ids_by_status(report)
  end

  def contact_ids_by_ground_station(report) do
    StatusAvailabilityFields.contact_ids_by_ground_station(report)
  end

  def contact_ids_by_availability(report) do
    StatusAvailabilityFields.contact_ids_by_availability(report)
  end

  def entry_ids_by_status(report) do
    StatusAvailabilityFields.entry_ids_by_status(report)
  end

  def entry_ids_by_ground_station(report) do
    StatusAvailabilityFields.entry_ids_by_ground_station(report)
  end

  def entry_ids_by_availability(report) do
    StatusAvailabilityFields.entry_ids_by_availability(report)
  end

  def reservation_ids_by_status(report) do
    StatusAvailabilityFields.reservation_ids_by_status(report)
  end

  def reservation_ids_by_ground_station(report) do
    StatusAvailabilityFields.reservation_ids_by_ground_station(report)
  end

  def reservation_ids_by_availability(report) do
    StatusAvailabilityFields.reservation_ids_by_availability(report)
  end

  def status_counts(report) do
    StatusAvailabilityFields.status_counts(report)
  end

  def affected_contact_ground_station_counts(report) do
    StatusAvailabilityFields.affected_contact_ground_station_counts(report)
  end

  def affected_contact_availability_counts(report) do
    StatusAvailabilityFields.affected_contact_availability_counts(report)
  end
end
