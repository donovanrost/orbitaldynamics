defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.ProviderReservation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Aggregation

  import Aggregation

  def source_report_provider_reservation_fields(source_reports) do
    %{
      "source_report_contact_allocation_provider_reservation_candidate_contact_count" =>
        source_report_family_count(source_reports, "provider_reservation_candidate_contact_count"),
      "source_report_contact_allocation_provider_reservation_request_contact_count" =>
        source_report_family_count(source_reports, "provider_reservation_request_contact_count"),
      "source_report_contact_allocation_provider_reservation_review_contact_count" =>
        source_report_family_count(source_reports, "provider_reservation_review_contact_count"),
      "source_report_contact_allocation_provider_reservation_no_request_contact_count" =>
        source_report_family_count(
          source_reports,
          "provider_reservation_no_request_contact_count"
        ),
      "source_report_contact_allocation_provider_reservation_request_status_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "provider_reservation_request_status_counts"
        ),
      "source_report_contact_allocation_provider_reservation_request_contact_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "provider_reservation_request_contact_ids"
        ),
      "source_report_contact_allocation_provider_reservation_review_contact_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "provider_reservation_review_contact_ids"
        ),
      "source_report_contact_allocation_provider_reservation_no_request_contact_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "provider_reservation_no_request_contact_ids"
        ),
      "source_report_contact_allocation_provider_reservation_request_contact_ids_by_ground_station" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "provider_reservation_request_contact_ids_by_ground_station"
        ),
      "source_report_contact_allocation_provider_reservation_review_contact_ids_by_ground_station" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "provider_reservation_review_contact_ids_by_ground_station"
        ),
      "source_report_contact_allocation_provider_reservation_no_request_contact_ids_by_direction" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "provider_reservation_no_request_contact_ids_by_direction"
        ),
      "source_report_contact_allocation_provider_reservation_request_contact_ids_by_direction" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "provider_reservation_request_contact_ids_by_direction"
        ),
      "source_report_contact_allocation_provider_reservation_review_contact_ids_by_direction" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "provider_reservation_review_contact_ids_by_direction"
        ),
      "source_report_contact_allocation_provider_reservation_no_request_contact_ids_by_direction_and_ground_station" =>
        source_report_family_merge_nested_string_list_maps(
          source_reports,
          "provider_reservation_no_request_contact_ids_by_direction_and_ground_station"
        ),
      "source_report_contact_allocation_provider_reservation_request_contact_ids_by_direction_and_ground_station" =>
        source_report_family_merge_nested_string_list_maps(
          source_reports,
          "provider_reservation_request_contact_ids_by_direction_and_ground_station"
        ),
      "source_report_contact_allocation_provider_reservation_review_contact_ids_by_direction_and_ground_station" =>
        source_report_family_merge_nested_string_list_maps(
          source_reports,
          "provider_reservation_review_contact_ids_by_direction_and_ground_station"
        ),
      "source_report_contact_allocation_provider_reservation_request_contact_ids_by_match_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "provider_reservation_request_contact_ids_by_match_status"
        ),
      "source_report_contact_allocation_provider_reservation_review_contact_ids_by_match_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "provider_reservation_review_contact_ids_by_match_status"
        ),
      "source_report_contact_allocation_provider_reservation_request_ids_by_match_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "provider_reservation_request_ids_by_match_status"
        ),
      "source_report_contact_allocation_provider_reservation_review_ids_by_match_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "provider_reservation_review_ids_by_match_status"
        )
    }
  end
end
