defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.CapacityPack do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Aggregation

  def fields(source_reports) do
    %{
      "source_report_contact_contention_capacity_pack_required_capacity_fraction" =>
        source_report_family_numeric_sum(
          source_reports,
          "capacity_pack_required_capacity_fraction"
        ),
      "source_report_contact_contention_capacity_pack_selected_required_capacity_fraction" =>
        source_report_family_numeric_sum(
          source_reports,
          "capacity_pack_selected_required_capacity_fraction"
        ),
      "source_report_contact_contention_capacity_pack_deferred_required_capacity_fraction" =>
        source_report_family_numeric_sum(
          source_reports,
          "capacity_pack_deferred_required_capacity_fraction"
        ),
      "source_report_contact_contention_capacity_pack_required_capacity_fraction_by_ground_station" =>
        source_report_family_merge_numeric_maps(
          source_reports,
          "capacity_pack_required_capacity_fraction_by_ground_station"
        ),
      "source_report_contact_contention_capacity_pack_selected_required_capacity_fraction_by_ground_station" =>
        source_report_family_merge_numeric_maps(
          source_reports,
          "capacity_pack_selected_required_capacity_fraction_by_ground_station"
        ),
      "source_report_contact_contention_capacity_pack_deferred_required_capacity_fraction_by_ground_station" =>
        source_report_family_merge_numeric_maps(
          source_reports,
          "capacity_pack_deferred_required_capacity_fraction_by_ground_station"
        ),
      "source_report_contact_contention_capacity_pack_required_capacity_fraction_by_status" =>
        source_report_family_merge_numeric_maps(
          source_reports,
          "capacity_pack_required_capacity_fraction_by_status"
        ),
      "source_report_contact_contention_capacity_pack_required_capacity_fraction_source_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "required_capacity_fraction_source_counts"
        ),
      "source_report_contact_contention_capacity_pack_required_capacity_fraction_contact_ids_by_source" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "required_capacity_fraction_contact_ids_by_source"
        )
    }
  end
end
