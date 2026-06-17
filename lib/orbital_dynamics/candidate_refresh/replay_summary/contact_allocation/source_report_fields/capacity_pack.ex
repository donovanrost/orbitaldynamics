defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.CapacityPack do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Aggregation

  import Aggregation

  def source_report_capacity_pack_fields(source_reports) do
    %{
      "source_report_contact_allocation_capacity_pack_required_capacity_fraction" =>
        source_report_family_numeric_sum(
          source_reports,
          "capacity_pack_required_capacity_fraction"
        ),
      "source_report_contact_allocation_capacity_pack_selected_required_capacity_fraction" =>
        source_report_family_numeric_sum(
          source_reports,
          "capacity_pack_selected_required_capacity_fraction"
        ),
      "source_report_contact_allocation_capacity_pack_deferred_required_capacity_fraction" =>
        source_report_family_numeric_sum(
          source_reports,
          "capacity_pack_deferred_required_capacity_fraction"
        ),
      "source_report_contact_allocation_capacity_pack_required_capacity_fraction_by_status" =>
        source_report_family_merge_numeric_maps(
          source_reports,
          "capacity_pack_required_capacity_fraction_by_status"
        ),
      "source_report_contact_allocation_capacity_pack_required_capacity_fraction_by_ground_station" =>
        source_report_family_merge_numeric_maps(
          source_reports,
          "capacity_pack_required_capacity_fraction_by_ground_station"
        ),
      "source_report_contact_allocation_capacity_pack_required_capacity_fraction_by_direction" =>
        source_report_family_merge_numeric_maps(
          source_reports,
          "capacity_pack_required_capacity_fraction_by_direction"
        ),
      "source_report_contact_allocation_capacity_pack_selected_required_capacity_fraction_by_ground_station" =>
        source_report_family_merge_numeric_maps(
          source_reports,
          "capacity_pack_selected_required_capacity_fraction_by_ground_station"
        ),
      "source_report_contact_allocation_capacity_pack_selected_required_capacity_fraction_by_direction" =>
        source_report_family_merge_numeric_maps(
          source_reports,
          "capacity_pack_selected_required_capacity_fraction_by_direction"
        ),
      "source_report_contact_allocation_capacity_pack_deferred_required_capacity_fraction_by_ground_station" =>
        source_report_family_merge_numeric_maps(
          source_reports,
          "capacity_pack_deferred_required_capacity_fraction_by_ground_station"
        ),
      "source_report_contact_allocation_capacity_pack_deferred_required_capacity_fraction_by_direction" =>
        source_report_family_merge_numeric_maps(
          source_reports,
          "capacity_pack_deferred_required_capacity_fraction_by_direction"
        ),
      "source_report_contact_allocation_capacity_pack_selected_contact_ids_by_ground_station" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "capacity_pack_selected_contact_ids_by_ground_station"
        ),
      "source_report_contact_allocation_capacity_pack_selected_contact_ids_by_direction" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "capacity_pack_selected_contact_ids_by_direction"
        ),
      "source_report_contact_allocation_capacity_pack_deferred_contact_ids_by_ground_station" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "capacity_pack_deferred_contact_ids_by_ground_station"
        ),
      "source_report_contact_allocation_capacity_pack_deferred_contact_ids_by_direction" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "capacity_pack_deferred_contact_ids_by_direction"
        ),
      "source_report_contact_allocation_capacity_pack_contact_ids_by_ground_station" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "capacity_pack_contact_ids_by_ground_station"
        ),
      "source_report_contact_allocation_capacity_pack_contact_ids_by_direction" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "capacity_pack_contact_ids_by_direction"
        ),
      "source_report_contact_allocation_capacity_pack_contact_ids_by_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "capacity_pack_contact_ids_by_status"
        ),
      "source_report_contact_allocation_capacity_pack_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "capacity_pack_status_counts"),
      "source_report_contact_allocation_capacity_pack_contact_status_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "capacity_pack_contact_status_counts"
        ),
      "source_report_contact_allocation_capacity_pack_contact_count" =>
        source_report_capacity_pack_contact_count(source_reports),
      "source_report_contact_allocation_reduced_capacity_pack_group_count" =>
        source_report_family_count(source_reports, "reduced_capacity_pack_group_count"),
      "source_report_contact_allocation_reduced_capacity_pack_status_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "reduced_capacity_pack_status_counts"
        ),
      "source_report_contact_allocation_capacity_pack_group_ids" =>
        source_report_family_merge_string_lists(source_reports, "capacity_pack_group_ids"),
      "source_report_contact_allocation_capacity_pack_group_ids_by_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "capacity_pack_group_ids_by_status"
        ),
      "source_report_contact_allocation_required_capacity_fraction_source_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "required_capacity_fraction_source_counts"
        ),
      "source_report_contact_allocation_required_capacity_fraction_contact_ids_by_source" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "required_capacity_fraction_contact_ids_by_source"
        ),
      "source_report_contact_allocation_reduced_capacity_packed_contact_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "reduced_capacity_packed_contact_ids"
        ),
      "source_report_contact_allocation_reduced_capacity_deferred_contact_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "reduced_capacity_deferred_contact_ids"
        )
    }
  end
end
