defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.Summary.StationReservation do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.Summary.Normalization,
    only: [numeric_value: 1, summary_integer: 2]

  def fields(allocation_summary) do
    %{
      "station_reservation_match_status_counts" =>
        Map.get(allocation_summary, "station_reservation_match_status_counts"),
      "station_reservation_contact_ids_by_match_status" =>
        Map.get(allocation_summary, "station_reservation_contact_ids_by_match_status"),
      "station_reservation_ids_by_match_status" =>
        Map.get(allocation_summary, "station_reservation_ids_by_match_status"),
      "station_reservation_status_counts" =>
        Map.get(allocation_summary, "station_reservation_status_counts"),
      "station_reserved_by_counts" => Map.get(allocation_summary, "station_reserved_by_counts"),
      "station_reservation_ids" => Map.get(allocation_summary, "station_reservation_ids"),
      "station_reservation_contact_ids_by_status" =>
        Map.get(allocation_summary, "station_reservation_contact_ids_by_status"),
      "station_reservation_contact_ids_by_reserved_by" =>
        Map.get(allocation_summary, "station_reservation_contact_ids_by_reserved_by"),
      "station_reservation_ids_by_status" =>
        Map.get(allocation_summary, "station_reservation_ids_by_status"),
      "station_reservation_ids_by_reserved_by" =>
        Map.get(allocation_summary, "station_reservation_ids_by_reserved_by"),
      "station_reservation_expires_at_s" =>
        Map.get(allocation_summary, "station_reservation_expires_at_s"),
      "station_reservation_expiration_now_s" =>
        numeric_value(Map.get(allocation_summary, "station_reservation_expiration_now_s")),
      "station_reservation_expiration_status_counts" =>
        Map.get(allocation_summary, "station_reservation_expiration_status_counts"),
      "station_reservation_active_contact_count" =>
        contact_count(allocation_summary, "station_reservation_active_contact_count"),
      "station_reservation_expired_contact_count" =>
        contact_count(allocation_summary, "station_reservation_expired_contact_count"),
      "station_reservation_declared_expiration_contact_count" =>
        contact_count(allocation_summary, "station_reservation_declared_expiration_contact_count"),
      "station_reservation_missing_expiration_contact_count" =>
        contact_count(allocation_summary, "station_reservation_missing_expiration_contact_count"),
      "earliest_station_reservation_expires_at_s" =>
        numeric_value(Map.get(allocation_summary, "earliest_station_reservation_expires_at_s")),
      "station_reservation_contact_ids_by_expiration_status" =>
        Map.get(allocation_summary, "station_reservation_contact_ids_by_expiration_status"),
      "station_reservation_ids_by_expiration_status" =>
        Map.get(allocation_summary, "station_reservation_ids_by_expiration_status")
    }
  end

  def pressure?(replay) do
    (replay["station_reservation_ids"] || []) != [] or
      (replay["station_reservation_expires_at_s"] || []) != [] or
      not is_nil(replay["station_reservation_expiration_now_s"]) or
      (replay["station_reservation_active_contact_count"] || 0) > 0 or
      (replay["station_reservation_expired_contact_count"] || 0) > 0 or
      (replay["station_reservation_declared_expiration_contact_count"] || 0) > 0 or
      (replay["station_reservation_missing_expiration_contact_count"] || 0) > 0 or
      not is_nil(replay["earliest_station_reservation_expires_at_s"]) or
      Enum.any?(
        [
          "station_reservation_match_status_counts",
          "station_reservation_contact_ids_by_match_status",
          "station_reservation_ids_by_match_status",
          "station_reservation_status_counts",
          "station_reserved_by_counts",
          "station_reservation_contact_ids_by_status",
          "station_reservation_contact_ids_by_reserved_by",
          "station_reservation_ids_by_status",
          "station_reservation_ids_by_reserved_by",
          "station_reservation_expiration_status_counts",
          "station_reservation_contact_ids_by_expiration_status",
          "station_reservation_ids_by_expiration_status"
        ],
        &(map_size(replay[&1] || %{}) > 0)
      )
  end

  defp contact_count(allocation_summary, field) do
    case summary_integer(allocation_summary, field) do
      0 -> nil
      count -> count
    end
  end
end
