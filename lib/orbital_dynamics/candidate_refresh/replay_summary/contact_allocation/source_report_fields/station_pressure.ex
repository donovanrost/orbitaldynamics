defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.StationPressure do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Aggregation

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.{
    StationPressureReviewCorrelation,
    StationPressureRoutingCorrelation
  }

  import Aggregation

  def source_report_station_pressure_fields(source_reports) do
    review_fields =
      StationPressureReviewCorrelation.fields(%{
        "station_pressure_review_contact_count" =>
          source_report_station_pressure_review_contact_count(source_reports),
        "station_pressure_review_contact_ids" =>
          source_report_family_merge_string_lists(
            source_reports,
            "station_pressure_review_contact_ids"
          )
      })

    routing_fields =
      StationPressureRoutingCorrelation.fields(%{
        "station_pressure_ground_station_counts" =>
          source_report_family_merge_count_maps(
            source_reports,
            "station_pressure_ground_station_counts"
          ),
        "station_pressure_contact_ids_by_ground_station" =>
          source_report_family_merge_string_list_map_fields(source_reports, [
            "station_pressure_contact_ids_by_ground_station_id",
            "station_pressure_contact_ids_by_ground_station"
          ]),
        "station_pressure_direction_counts" =>
          source_report_family_merge_count_maps(
            source_reports,
            "station_pressure_direction_counts"
          ),
        "station_pressure_contact_ids_by_direction" =>
          source_report_family_merge_string_list_maps(
            source_reports,
            "station_pressure_contact_ids_by_direction"
          ),
        "station_pressure_contact_ids_by_direction_and_ground_station" =>
          source_report_family_merge_nested_string_list_map_fields(source_reports, [
            "station_pressure_contact_ids_by_direction_and_ground_station",
            "station_pressure_contact_ids_by_direction_and_ground_station_id"
          ])
      })

    %{
      "source_report_contact_allocation_station_pressure_contact_count" =>
        source_report_station_pressure_contact_count(source_reports),
      "source_report_contact_allocation_station_pressure_ground_station_counts" =>
        Map.get(routing_fields, "station_pressure_ground_station_counts"),
      "source_report_contact_allocation_station_pressure_contact_ids_by_ground_station" =>
        Map.get(routing_fields, "station_pressure_contact_ids_by_ground_station"),
      "source_report_contact_allocation_station_pressure_availability_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "station_pressure_availability_counts"
        ),
      "source_report_contact_allocation_station_pressure_contact_ids_by_availability" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_pressure_contact_ids_by_availability"
        ),
      "source_report_contact_allocation_station_pressure_precedence_availability_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "station_pressure_precedence_availability_counts"
        ),
      "source_report_contact_allocation_station_pressure_contact_ids_by_precedence_availability" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_pressure_contact_ids_by_precedence_availability"
        ),
      "source_report_contact_allocation_station_pressure_precedence_rank_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "station_pressure_precedence_rank_counts"
        ),
      "source_report_contact_allocation_station_pressure_contact_ids_by_precedence_rank" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_pressure_contact_ids_by_precedence_rank"
        ),
      "source_report_contact_allocation_station_pressure_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "station_pressure_status_counts"),
      "source_report_contact_allocation_station_pressure_contact_ids_by_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_pressure_contact_ids_by_status"
        ),
      "source_report_contact_allocation_station_pressure_direction_counts" =>
        Map.get(routing_fields, "station_pressure_direction_counts"),
      "source_report_contact_allocation_station_pressure_contact_ids_by_direction" =>
        Map.get(routing_fields, "station_pressure_contact_ids_by_direction"),
      "source_report_contact_allocation_station_pressure_contact_ids_by_direction_and_ground_station" =>
        Map.get(
          routing_fields,
          "station_pressure_contact_ids_by_direction_and_ground_station"
        ),
      "source_report_contact_allocation_station_pressure_review_contact_count" =>
        Map.get(review_fields, "station_pressure_review_contact_count"),
      "source_report_contact_allocation_station_pressure_review_contact_ids" =>
        Map.get(review_fields, "station_pressure_review_contact_ids")
    }
  end
end
