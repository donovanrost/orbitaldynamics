defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.Summary.Pressure do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.Summary.ProviderContention
  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.Summary.ReservationHold

  def fields(reservation_fields, provider_contention_replay, reservation_hold_replay, counts) do
    affected_contact_ids = Map.get(reservation_fields, "affected_contact_ids", [])

    contact_ids_by_match_status =
      Map.get(reservation_fields, "contact_ids_by_match_status", %{})

    contact_ids_by_status = Map.get(reservation_fields, "contact_ids_by_status", %{})
    direction_counts = Map.get(reservation_fields, "direction_counts", %{})
    contact_ids_by_direction = Map.get(reservation_fields, "contact_ids_by_direction", %{})
    direction_routing = Map.get(reservation_fields, "direction_routing", %{})
    reservation_expires_at_s = Map.get(reservation_fields, "reservation_expires_at_s", [])

    earliest_reservation_expires_at_s =
      Map.get(reservation_fields, "earliest_reservation_expires_at_s")

    match_status_counts =
      Map.get(reservation_fields, "station_reservation_match_status_counts", %{})

    reservation_status_counts = Map.get(reservation_fields, "reservation_status_counts", %{})
    reservation_ids = Map.get(reservation_fields, "reservation_ids", [])

    reservation_ids_by_match_status =
      Map.get(reservation_fields, "reservation_ids_by_match_status", %{})

    reservation_ids_by_status = Map.get(reservation_fields, "reservation_ids_by_status", %{})
    reserved_by_counts = Map.get(reservation_fields, "reserved_by_counts", %{})
    contact_ids_by_reserved_by = Map.get(reservation_fields, "contact_ids_by_reserved_by", %{})

    reservation_ids_by_reserved_by =
      Map.get(reservation_fields, "reservation_ids_by_reserved_by", %{})

    reservation_expiration_pressure =
      counts.expiration_evidence_count > 0 or reservation_expires_at_s != [] or
        not is_nil(earliest_reservation_expires_at_s)

    reservation_hold_pressure = ReservationHold.pressure?(reservation_hold_replay)

    reservation_hold_import_readiness_pressure =
      ReservationHold.import_readiness_pressure?(reservation_hold_replay)

    %{
      "branch_local_station_reservation_pressure" =>
        counts.reservation_evidence_count > 0 or counts.affected_contact_count > 0 or
          affected_contact_ids != [] or map_size(contact_ids_by_match_status) > 0 or
          map_size(contact_ids_by_status) > 0 or map_size(direction_counts) > 0 or
          map_size(contact_ids_by_direction) > 0 or map_size(direction_routing) > 0 or
          counts.reservation_review_count > 0 or
          ProviderContention.station_reservation_pressure?(provider_contention_replay) or
          reservation_ids != [] or map_size(match_status_counts) > 0 or
          map_size(reservation_status_counts) > 0 or
          map_size(reservation_ids_by_match_status) > 0 or
          map_size(reservation_ids_by_status) > 0 or map_size(reserved_by_counts) > 0 or
          map_size(contact_ids_by_reserved_by) > 0 or
          map_size(reservation_ids_by_reserved_by) > 0 or reservation_expiration_pressure or
          ReservationHold.station_reservation_pressure?(reservation_hold_replay),
      "branch_local_reservation_review_pressure" =>
        counts.reservation_review_count > 0 or map_size(match_status_counts) > 0 or
          map_size(reservation_ids_by_match_status) > 0 or
          map_size(contact_ids_by_match_status) > 0 or map_size(contact_ids_by_status) > 0 or
          map_size(direction_counts) > 0 or map_size(contact_ids_by_direction) > 0 or
          map_size(direction_routing) > 0,
      "branch_local_reservation_owner_pressure" =>
        map_size(reserved_by_counts) > 0 or map_size(contact_ids_by_reserved_by) > 0 or
          map_size(reservation_ids_by_reserved_by) > 0,
      "branch_local_reservation_expiration_pressure" => reservation_expiration_pressure,
      "branch_local_reservation_hold_pressure" => if(reservation_hold_pressure, do: true),
      "branch_local_provider_contention_pressure" =>
        ProviderContention.pressure?(provider_contention_replay),
      "branch_local_reservation_hold_import_readiness_pressure" =>
        if(reservation_hold_import_readiness_pressure, do: true)
    }
  end
end
