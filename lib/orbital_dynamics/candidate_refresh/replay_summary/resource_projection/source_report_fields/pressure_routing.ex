defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceProjection.SourceReportFields.PressureRouting do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceProjection.SourceReportFields.Aggregation

  def fields(source_reports) do
    %{
      "source_report_resource_projection_resource_pressure_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "resource_pressure_status_counts"),
      "source_report_resource_projection_ground_station_counts" =>
        source_report_family_merge_count_maps(source_reports, "ground_station_counts"),
      "source_report_resource_projection_spacecraft_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "resource_projection_spacecraft_counts"
        ),
      "source_report_resource_projection_resource_pressure_type_counts" =>
        source_report_family_merge_count_maps(source_reports, "resource_pressure_type_counts"),
      "source_report_resource_projection_resource_pressure_activity_id_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "resource_pressure_activity_id_counts"
        ),
      "source_report_resource_projection_resource_pressure_activity_ids_by_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "resource_pressure_activity_ids_by_status"
        ),
      "source_report_resource_projection_resource_pressure_activity_ids_by_type" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "resource_pressure_activity_ids_by_type"
        ),
      "source_report_resource_projection_resource_pressure_activity_ids_by_ground_station" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "resource_pressure_activity_ids_by_ground_station"
        ),
      "source_report_resource_projection_resource_pressure_activity_ids_by_spacecraft" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "resource_pressure_activity_ids_by_spacecraft"
        ),
      "source_report_resource_projection_resource_pressure_direction_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "resource_pressure_direction_counts"
        ),
      "source_report_resource_projection_resource_pressure_directions" =>
        source_report_family_field(source_reports, "resource_pressure_directions"),
      "source_report_resource_projection_resource_pressure_activity_ids_by_direction" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "resource_pressure_activity_ids_by_direction"
        ),
      "source_report_resource_projection_resource_pressure_direction_routing" =>
        source_report_family_field(source_reports, "resource_pressure_direction_routing")
    }
  end
end
