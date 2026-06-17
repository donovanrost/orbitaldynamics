defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Aggregation

  import Aggregation

  def source_report_allocation_fields(source_reports) do
    %{
      "source_report_contact_allocation_blocked_row_count" =>
        source_report_family_count(source_reports, "blocked_row_count"),
      "source_report_contact_allocation_deferred_row_count" =>
        source_report_family_count(source_reports, "deferred_row_count"),
      "source_report_contact_allocation_allocation_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "allocation_status_counts"),
      "source_report_contact_allocation_effective_allocation_status_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "effective_allocation_status_counts"
        ),
      "source_report_contact_allocation_allocation_reason_counts" =>
        source_report_family_merge_count_maps(source_reports, "allocation_reason_counts"),
      "source_report_contact_allocation_direction_counts" =>
        source_report_family_merge_count_maps(source_reports, "direction_counts"),
      "source_report_contact_allocation_contact_ids_by_direction" =>
        source_report_family_merge_string_list_maps(source_reports, "contact_ids_by_direction"),
      "source_report_contact_allocation_direction_routing" =>
        source_report_family_field(source_reports, "direction_routing"),
      "source_report_contact_allocation_allocated_contact_count" =>
        source_report_family_count(source_reports, "allocated_contact_count"),
      "source_report_contact_allocation_allocated_contact_ids" =>
        source_report_family_merge_string_lists(source_reports, "allocated_contact_ids"),
      "source_report_contact_allocation_allocated_contact_ids_by_ground_station" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "allocated_contact_ids_by_ground_station"
        ),
      "source_report_contact_allocation_returned_allocated_contact_count" =>
        source_report_family_count(source_reports, "returned_allocated_contact_count"),
      "source_report_contact_allocation_returned_allocated_contact_ids" =>
        source_report_family_merge_string_lists(source_reports, "returned_allocated_contact_ids"),
      "source_report_contact_allocation_returned_allocated_contact_ids_by_ground_station" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "returned_allocated_contact_ids_by_ground_station"
        ),
      "source_report_contact_allocation_deferred_contact_count" =>
        source_report_family_count(source_reports, "deferred_contact_count"),
      "source_report_contact_allocation_deferred_contact_ids" =>
        source_report_family_merge_string_lists(source_reports, "deferred_contact_ids"),
      "source_report_contact_allocation_deferred_contact_ids_by_ground_station" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "deferred_contact_ids_by_ground_station"
        ),
      "source_report_contact_allocation_blocked_contact_count" =>
        source_report_family_count(source_reports, "blocked_contact_count"),
      "source_report_contact_allocation_blocked_contact_ids" =>
        source_report_family_merge_string_lists(source_reports, "blocked_contact_ids"),
      "source_report_contact_allocation_blocked_contact_ids_by_ground_station" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "blocked_contact_ids_by_ground_station"
        ),
      "source_report_contact_allocation_policy_blocked_allocated_contact_count" =>
        source_report_family_count(source_reports, "policy_blocked_allocated_contact_count"),
      "source_report_contact_allocation_policy_blocked_contact_ids" =>
        source_report_family_merge_string_lists(source_reports, "policy_blocked_contact_ids"),
      "source_report_contact_allocation_policy_blocked_contact_ids_by_ground_station" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "policy_blocked_contact_ids_by_ground_station"
        ),
      "source_report_contact_allocation_invalid_contact_input_count" =>
        source_report_family_count(source_reports, "invalid_contact_input_count"),
      "source_report_contact_allocation_duplicate_contact_id_count" =>
        source_report_family_count(source_reports, "duplicate_contact_id_count"),
      "source_report_contact_allocation_invalid_contact_input_ids" =>
        source_report_family_merge_string_lists(source_reports, "invalid_contact_input_ids"),
      "source_report_contact_allocation_status_blocked_contact_count" =>
        source_report_family_count(source_reports, "status_blocked_contact_count"),
      "source_report_contact_allocation_status_blocked_contact_ids" =>
        source_report_family_merge_string_lists(source_reports, "status_blocked_contact_ids"),
      "source_report_contact_allocation_resource_blocked_contact_count" =>
        source_report_family_count(source_reports, "resource_blocked_contact_count"),
      "source_report_contact_allocation_resource_blocked_contact_ids" =>
        source_report_family_merge_string_lists(source_reports, "resource_blocked_contact_ids"),
      "source_report_contact_allocation_resource_blocking_dimension_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "resource_blocking_dimension_counts"
        ),
      "source_report_contact_allocation_resource_blocked_contact_ids_by_blocking_dimension" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "resource_blocked_contact_ids_by_blocking_dimension"
        ),
      "source_report_contact_allocation_resource_blocked_contact_ids_by_spacecraft" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "resource_blocked_contact_ids_by_spacecraft"
        ),
      "source_report_contact_allocation_contact_ids_by_allocation_reason" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "contact_ids_by_allocation_reason"
        ),
      "source_report_contact_allocation_review_contact_ids" =>
        source_report_family_merge_string_lists(source_reports, "review_contact_ids")
    }
  end
end
