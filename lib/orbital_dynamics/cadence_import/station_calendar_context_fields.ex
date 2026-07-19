defmodule OrbitalDynamics.CadenceImport.StationCalendarContextFields do
  @moduledoc false

  def all do
    [
      "station_availability",
      "station_calendar_status",
      "capacity_fraction",
      "capacity_fraction_min",
      "capacity_fraction_max",
      "station_calendar_entry_ids",
      "station_calendar_provider_ids",
      "station_calendar_provider_entry_ids",
      "station_calendar_overlap_entry_ids",
      "station_calendar_directions",
      "station_calendar_reservation_ids",
      "station_calendar_reserved_by",
      "station_calendar_reservation_statuses",
      "station_calendar_reservation_expires_at_s",
      "station_calendar_trust_boundary_statuses",
      "station_reservation_ids",
      "station_reservation_expires_at_s",
      "station_reserved_bys",
      "station_reservation_statuses",
      "station_reservation_match_statuses"
    ]
  end
end
