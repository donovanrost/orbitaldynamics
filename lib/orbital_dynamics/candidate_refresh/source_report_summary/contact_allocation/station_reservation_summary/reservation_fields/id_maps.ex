defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.StationReservationSummary.ReservationFields.IdMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.StationReservation

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.StationReservationSummary.ReservationFields.Aggregates

  def fields(reports) do
    %{
      "station_reservation_contact_ids_by_match_status" =>
        Aggregates.string_list_map_merge(
          reports,
          &StationReservation.contact_ids_by_match_status/1
        ),
      "station_reservation_ids_by_match_status" =>
        Aggregates.string_list_map_merge(reports, &StationReservation.ids_by_match_status/1),
      "station_reservation_contact_ids_by_status" =>
        Aggregates.string_list_map_merge(reports, &StationReservation.contact_ids_by_status/1),
      "station_reservation_contact_ids_by_reserved_by" =>
        Aggregates.string_list_map_merge(
          reports,
          &StationReservation.contact_ids_by_reserved_by/1
        ),
      "station_reservation_ids_by_status" =>
        Aggregates.string_list_map_merge(reports, &StationReservation.ids_by_status/1),
      "station_reservation_ids_by_reserved_by" =>
        Aggregates.string_list_map_merge(reports, &StationReservation.ids_by_reserved_by/1)
    }
  end
end
