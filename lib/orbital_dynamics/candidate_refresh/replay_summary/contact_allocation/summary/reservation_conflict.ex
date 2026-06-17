defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.Summary.ReservationConflict do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields

  def fields(allocation_summary) do
    %{
      "reservation_conflict_contact_count" => contact_count(allocation_summary),
      "reservation_conflict_contact_ids" =>
        Map.get(allocation_summary, "reservation_conflict_contact_ids"),
      "reservation_conflict_match_status_counts" =>
        Map.get(allocation_summary, "reservation_conflict_match_status_counts"),
      "reservation_conflict_contact_ids_by_match_status" =>
        Map.get(allocation_summary, "reservation_conflict_contact_ids_by_match_status"),
      "reservation_conflict_reservation_ids_by_match_status" =>
        Map.get(allocation_summary, "reservation_conflict_reservation_ids_by_match_status"),
      "reservation_conflict_direction_counts" =>
        Map.get(allocation_summary, "reservation_conflict_direction_counts"),
      "reservation_conflict_contact_ids_by_direction" =>
        Map.get(allocation_summary, "reservation_conflict_contact_ids_by_direction"),
      "reservation_conflict_contact_ids_by_direction_and_ground_station" =>
        SourceReportFields.summary_nested_string_list_map_fields(allocation_summary, [
          "reservation_conflict_contact_ids_by_direction_and_ground_station",
          "reservation_conflict_contact_ids_by_direction_and_ground_station_id"
        ])
    }
  end

  def pressure?(replay) do
    (replay["reservation_conflict_contact_count"] || 0) > 0 or
      (replay["reservation_conflict_contact_ids"] || []) != [] or
      Enum.any?(
        [
          "reservation_conflict_match_status_counts",
          "reservation_conflict_contact_ids_by_match_status",
          "reservation_conflict_reservation_ids_by_match_status",
          "reservation_conflict_direction_counts",
          "reservation_conflict_contact_ids_by_direction",
          "reservation_conflict_contact_ids_by_direction_and_ground_station"
        ],
        &(map_size(replay[&1] || %{}) > 0)
      )
  end

  defp contact_count(allocation_summary) do
    case SourceReportFields.contact_allocation_reservation_conflict_contact_count(
           allocation_summary
         ) do
      count when is_number(count) and count <= 0 -> nil
      count -> count
    end
  end
end
