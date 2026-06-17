defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Aggregation

  def source_report_routing_fields(source_reports) do
    %{
      "source_report_link_capacity_contact_ids_by_direction" =>
        source_report_family_merge_string_list_maps(source_reports, "contact_ids_by_direction"),
      "source_report_link_capacity_source_window_ids_by_direction" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "source_window_ids_by_direction"
        ),
      "source_report_link_capacity_station_calendar_entry_ids_by_direction" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_calendar_entry_ids_by_direction"
        ),
      "source_report_link_capacity_station_calendar_provider_entry_ids_by_direction" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_calendar_provider_entry_ids_by_direction"
        ),
      "source_report_link_capacity_direction_routing" =>
        source_report_family_field(source_reports, "direction_routing"),
      "source_report_link_capacity_contact_ids_by_ground_station" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "contact_ids_by_ground_station"
        ),
      "source_report_link_capacity_source_window_ids_by_ground_station" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "source_window_ids_by_ground_station"
        ),
      "source_report_link_capacity_station_calendar_entry_ids_by_ground_station" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_calendar_entry_ids_by_ground_station"
        ),
      "source_report_link_capacity_station_calendar_provider_entry_ids_by_ground_station" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_calendar_provider_entry_ids_by_ground_station"
        ),
      "source_report_link_capacity_contact_ids_by_spacecraft" =>
        source_report_family_merge_string_list_maps(source_reports, "contact_ids_by_spacecraft"),
      "source_report_link_capacity_source_window_ids_by_spacecraft" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "source_window_ids_by_spacecraft"
        ),
      "source_report_link_capacity_station_calendar_entry_ids_by_spacecraft" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_calendar_entry_ids_by_spacecraft"
        ),
      "source_report_link_capacity_station_calendar_provider_entry_ids_by_spacecraft" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_calendar_provider_entry_ids_by_spacecraft"
        ),
      "source_report_link_capacity_selected_contact_id_counts" =>
        source_report_family_merge_count_maps(source_reports, "selected_contact_id_counts"),
      "source_report_link_capacity_selected_contact_ids" =>
        source_report_family_merge_string_lists(source_reports, "selected_contact_ids"),
      "source_report_link_capacity_selected_source_window_ids" =>
        source_report_family_merge_string_lists(source_reports, "selected_source_window_ids"),
      "source_report_link_capacity_selected_station_calendar_entry_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "selected_station_calendar_entry_ids"
        ),
      "source_report_link_capacity_selected_station_calendar_provider_entry_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "selected_station_calendar_provider_entry_ids"
        ),
      "source_report_link_capacity_actual_throughput_contact_id_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "actual_throughput_contact_id_counts"
        ),
      "source_report_link_capacity_actual_throughput_contact_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "actual_throughput_contact_ids"
        ),
      "source_report_link_capacity_actual_throughput_source_window_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "actual_throughput_source_window_ids"
        ),
      "source_report_link_capacity_actual_throughput_station_calendar_entry_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "actual_throughput_station_calendar_entry_ids"
        ),
      "source_report_link_capacity_actual_throughput_station_calendar_provider_entry_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "actual_throughput_station_calendar_provider_entry_ids"
        ),
      "source_report_link_capacity_downlink_requirement_status_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "downlink_requirement_status_counts"
        ),
      "source_report_link_capacity_contact_ids_by_requirement_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "contact_ids_by_requirement_status"
        ),
      "source_report_link_capacity_source_window_ids_by_requirement_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "source_window_ids_by_requirement_status"
        ),
      "source_report_link_capacity_station_calendar_entry_ids_by_requirement_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_calendar_entry_ids_by_requirement_status"
        ),
      "source_report_link_capacity_station_calendar_provider_entry_ids_by_requirement_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_calendar_provider_entry_ids_by_requirement_status"
        )
    }
  end
end
