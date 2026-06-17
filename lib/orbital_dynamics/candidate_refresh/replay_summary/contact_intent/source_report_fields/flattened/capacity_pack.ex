defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactIntent.SourceReportFields.Flattened.CapacityPack do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactIntent.SourceReportFields.Flattened.Aggregation

  def fields(source_reports) do
    %{
      "source_report_contact_intent_capacity_pack_required_contact_count" =>
        source_report_family_count(source_reports, "capacity_pack_required_contact_count"),
      "source_report_contact_intent_capacity_pack_required_capacity_fraction" =>
        source_report_family_numeric_sum(
          source_reports,
          "capacity_pack_required_capacity_fraction"
        ),
      "source_report_contact_intent_capacity_pack_required_capacity_fraction_by_ground_station" =>
        source_report_family_merge_numeric_maps(
          source_reports,
          "capacity_pack_required_capacity_fraction_by_ground_station"
        ),
      "source_report_contact_intent_capacity_pack_required_capacity_fraction_by_direction" =>
        source_report_family_merge_numeric_maps(
          source_reports,
          "capacity_pack_required_capacity_fraction_by_direction"
        ),
      "source_report_contact_intent_capacity_pack_required_capacity_fraction_by_direction_and_ground_station" =>
        source_report_family_merge_nested_numeric_maps(
          source_reports,
          "capacity_pack_required_capacity_fraction_by_direction_and_ground_station"
        ),
      "source_report_contact_intent_required_capacity_fraction_source_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "required_capacity_fraction_source_counts"
        ),
      "source_report_contact_intent_required_capacity_fraction_contact_ids_by_source" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "required_capacity_fraction_contact_ids_by_source"
        ),
      "source_report_contact_intent_capacity_pack_contact_ids_by_ground_station" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "capacity_pack_contact_ids_by_ground_station"
        ),
      "source_report_contact_intent_capacity_pack_contact_ids_by_direction" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "capacity_pack_contact_ids_by_direction"
        ),
      "source_report_contact_intent_capacity_pack_contact_ids_by_direction_and_ground_station" =>
        source_report_family_merge_nested_string_list_maps(
          source_reports,
          "capacity_pack_contact_ids_by_direction_and_ground_station"
        )
    }
  end
end
