defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.Summary.ReservationConflict do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.ReservationConflictCorrelation

  def fields(allocation_summary) do
    conflict_fields =
      allocation_summary
      |> Map.put(
        "reservation_conflict_contact_ids_by_direction_and_ground_station",
        SourceReportFields.summary_nested_string_list_map_fields(allocation_summary, [
          "reservation_conflict_contact_ids_by_direction_and_ground_station",
          "reservation_conflict_contact_ids_by_direction_and_ground_station_id"
        ])
      )
      |> ReservationConflictCorrelation.fields()

    %{
      "reservation_conflict_contact_count" =>
        compact_count(Map.get(conflict_fields, "reservation_conflict_contact_count")),
      "reservation_conflict_contact_ids" =>
        Map.get(conflict_fields, "reservation_conflict_contact_ids"),
      "reservation_conflict_match_status_counts" =>
        Map.get(conflict_fields, "reservation_conflict_match_status_counts"),
      "reservation_conflict_contact_ids_by_match_status" =>
        Map.get(conflict_fields, "reservation_conflict_contact_ids_by_match_status"),
      "reservation_conflict_reservation_ids_by_match_status" =>
        Map.get(conflict_fields, "reservation_conflict_reservation_ids_by_match_status"),
      "reservation_conflict_direction_counts" =>
        Map.get(conflict_fields, "reservation_conflict_direction_counts"),
      "reservation_conflict_contact_ids_by_direction" =>
        Map.get(conflict_fields, "reservation_conflict_contact_ids_by_direction"),
      "reservation_conflict_contact_ids_by_direction_and_ground_station" =>
        Map.get(
          conflict_fields,
          "reservation_conflict_contact_ids_by_direction_and_ground_station"
        )
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

  defp compact_count(count) when is_number(count) and count <= 0, do: nil
  defp compact_count(count), do: count
end
