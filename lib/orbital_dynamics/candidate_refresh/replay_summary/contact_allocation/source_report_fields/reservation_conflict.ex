defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.ReservationConflict do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Aggregation

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.ReservationConflictCorrelation

  import Aggregation

  def source_report_reservation_conflict_fields(source_reports) do
    conflict_fields =
      ReservationConflictCorrelation.fields(%{
        "reservation_conflict_contact_count" =>
          source_report_reservation_conflict_contact_count(source_reports),
        "reservation_conflict_contact_ids" =>
          source_report_family_merge_string_lists(
            source_reports,
            "reservation_conflict_contact_ids"
          ),
        "reservation_conflict_match_status_counts" =>
          source_report_family_merge_count_maps(
            source_reports,
            "reservation_conflict_match_status_counts"
          ),
        "reservation_conflict_contact_ids_by_match_status" =>
          source_report_family_merge_string_list_maps(
            source_reports,
            "reservation_conflict_contact_ids_by_match_status"
          ),
        "reservation_conflict_reservation_ids_by_match_status" =>
          source_report_family_merge_string_list_maps(
            source_reports,
            "reservation_conflict_reservation_ids_by_match_status"
          ),
        "reservation_conflict_direction_counts" =>
          source_report_family_merge_count_maps(
            source_reports,
            "reservation_conflict_direction_counts"
          ),
        "reservation_conflict_contact_ids_by_direction" =>
          source_report_family_merge_string_list_maps(
            source_reports,
            "reservation_conflict_contact_ids_by_direction"
          ),
        "reservation_conflict_contact_ids_by_direction_and_ground_station" =>
          source_report_family_merge_nested_string_list_map_fields(source_reports, [
            "reservation_conflict_contact_ids_by_direction_and_ground_station",
            "reservation_conflict_contact_ids_by_direction_and_ground_station_id"
          ])
      })

    %{
      "source_report_contact_allocation_reservation_conflict_contact_count" =>
        Map.get(conflict_fields, "reservation_conflict_contact_count"),
      "source_report_contact_allocation_reservation_conflict_contact_ids" =>
        Map.get(conflict_fields, "reservation_conflict_contact_ids"),
      "source_report_contact_allocation_reservation_conflict_match_status_counts" =>
        Map.get(conflict_fields, "reservation_conflict_match_status_counts"),
      "source_report_contact_allocation_reservation_conflict_contact_ids_by_match_status" =>
        Map.get(conflict_fields, "reservation_conflict_contact_ids_by_match_status"),
      "source_report_contact_allocation_reservation_conflict_reservation_ids_by_match_status" =>
        Map.get(conflict_fields, "reservation_conflict_reservation_ids_by_match_status"),
      "source_report_contact_allocation_reservation_conflict_direction_counts" =>
        Map.get(conflict_fields, "reservation_conflict_direction_counts"),
      "source_report_contact_allocation_reservation_conflict_contact_ids_by_direction" =>
        Map.get(conflict_fields, "reservation_conflict_contact_ids_by_direction"),
      "source_report_contact_allocation_reservation_conflict_contact_ids_by_direction_and_ground_station" =>
        Map.get(
          conflict_fields,
          "reservation_conflict_contact_ids_by_direction_and_ground_station"
        )
    }
  end
end
