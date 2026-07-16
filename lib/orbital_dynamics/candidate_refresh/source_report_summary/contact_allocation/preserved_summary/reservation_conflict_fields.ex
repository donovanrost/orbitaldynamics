defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.ReservationConflictFields do
  @moduledoc false

  alias __MODULE__.SummaryValues
  alias __MODULE__.ValueMaps

  def fields(summary) do
    %{
      "reservation_conflict_contact_count" => SummaryValues.contact_count(summary),
      "reservation_conflict_contact_ids" =>
        SummaryValues.sorted_strings(summary, "reservation_conflict_contact_ids"),
      "reservation_conflict_match_status_counts" =>
        Map.get(summary, "reservation_conflict_match_status_counts"),
      "reservation_conflict_contact_ids_by_match_status" =>
        ValueMaps.string_list_map(
          summary,
          "reservation_conflict_contact_ids_by_match_status"
        ),
      "reservation_conflict_reservation_ids_by_match_status" =>
        ValueMaps.string_list_map(
          summary,
          "reservation_conflict_reservation_ids_by_match_status"
        ),
      "reservation_conflict_contact_ids_by_direction" =>
        ValueMaps.string_list_map(
          summary,
          "reservation_conflict_contact_ids_by_direction"
        ),
      "reservation_conflict_contact_ids_by_direction_and_ground_station" =>
        ValueMaps.nested_string_list_map_fields(summary, [
          "reservation_conflict_contact_ids_by_direction_and_ground_station",
          "reservation_conflict_contact_ids_by_direction_and_ground_station_id"
        ])
    }
  end
end
