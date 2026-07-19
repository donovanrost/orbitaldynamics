defmodule OrbitalDynamics.TimelineFeedback.ReconciliationStationCalendarEvidence do
  @moduledoc false

  @fields ~w(
    station_availability
    station_contention_status
    capacity_fraction
    capacity_fraction_min
    capacity_fraction_max
    station_calendar_entry_id
    station_calendar_provider_id
    station_calendar_provider_entry_id
    station_calendar_directions
    station_calendar_status
    station_calendar_overlap_count
    station_calendar_overlap_entry_ids
    station_calendar_overlap_availabilities
    station_calendar_entry_ambiguous
    station_calendar_ambiguous_entry_count
    station_calendar_ambiguous_entry_ids
    station_calendar_reservation_overlap_count
    station_calendar_reservation_ids
    station_calendar_reservation_expires_at_s
    station_calendar_reserved_by
    station_calendar_reservation_statuses
    station_calendar_trust_boundary_status
    source_station_calendar_entry
    source_station_calendar_overlaps
    station_reservation_id
    station_reservation_expires_at_s
    station_reserved_by
    station_reservation_status
    station_reservation_match_status
  )

  def context(planned, realized) do
    Map.new(@fields, fn field ->
      {field, realized_or_planned(realized, planned, field)}
    end)
  end

  defp realized_or_planned(realized, planned, field) do
    case value(realized, field) do
      nil -> value(planned, field)
      value -> value
    end
  end

  defp value(nil, _key), do: nil
  defp value(map, key), do: Map.get(map, key)
end
