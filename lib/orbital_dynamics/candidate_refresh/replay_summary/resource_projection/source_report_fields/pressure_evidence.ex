defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceProjection.SourceReportFields.PressureEvidence do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceProjection.SourceReportFields.Aggregation

  def fields(source_reports) do
    %{
      "source_report_resource_projection_resource_pressure_ground_station_ids_by_type" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "resource_pressure_ground_station_ids_by_type"
        ),
      "source_report_resource_projection_resource_pressure_source_window_ids_by_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "resource_pressure_source_window_ids_by_status"
        ),
      "source_report_resource_projection_resource_pressure_source_window_ids_by_type" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "resource_pressure_source_window_ids_by_type"
        ),
      "source_report_resource_projection_resource_pressure_station_calendar_entry_ids_by_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "resource_pressure_station_calendar_entry_ids_by_status"
        ),
      "source_report_resource_projection_resource_pressure_station_calendar_entry_ids_by_type" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "resource_pressure_station_calendar_entry_ids_by_type"
        ),
      "source_report_resource_projection_resource_pressure_station_calendar_provider_ids_by_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "resource_pressure_station_calendar_provider_ids_by_status"
        ),
      "source_report_resource_projection_resource_pressure_station_calendar_provider_ids_by_type" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "resource_pressure_station_calendar_provider_ids_by_type"
        ),
      "source_report_resource_projection_resource_pressure_station_calendar_provider_entry_ids_by_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "resource_pressure_station_calendar_provider_entry_ids_by_status"
        ),
      "source_report_resource_projection_resource_pressure_station_calendar_provider_entry_ids_by_type" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "resource_pressure_station_calendar_provider_entry_ids_by_type"
        )
    }
  end
end
