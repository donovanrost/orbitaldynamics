defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.StationReservationFields.StringListMaps do
  @moduledoc false

  alias __MODULE__.ValueMaps

  def fields(summary) do
    %{
      "station_reservation_ids" => ValueMaps.string_list(summary, "station_reservation_ids"),
      "station_reservation_contact_ids_by_match_status" =>
        ValueMaps.string_list_map(summary, "station_reservation_contact_ids_by_match_status"),
      "station_reservation_contact_ids_by_status" =>
        ValueMaps.string_list_map(summary, "station_reservation_contact_ids_by_status"),
      "station_reservation_contact_ids_by_reserved_by" =>
        ValueMaps.string_list_map(summary, "station_reservation_contact_ids_by_reserved_by"),
      "station_reservation_ids_by_status" =>
        ValueMaps.string_list_map(summary, "station_reservation_ids_by_status"),
      "station_reservation_ids_by_reserved_by" =>
        ValueMaps.string_list_map(summary, "station_reservation_ids_by_reserved_by")
    }
  end
end
