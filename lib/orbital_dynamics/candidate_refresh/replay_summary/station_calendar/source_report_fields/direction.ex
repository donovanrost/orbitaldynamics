defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Direction do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Aggregation

  def source_report_direction_fields(source_reports) do
    %{
      "source_report_station_calendar_affected_contact_ids" =>
        source_report_family_merge_string_lists(source_reports, "affected_contact_ids"),
      "source_report_station_calendar_affected_station_calendar_entry_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "affected_station_calendar_entry_ids"
        ),
      "source_report_station_calendar_affected_station_reservation_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "affected_station_reservation_ids"
        ),
      "source_report_station_calendar_direction_counts" =>
        source_report_family_merge_count_maps(source_reports, "direction_counts"),
      "source_report_station_calendar_contact_ids_by_direction" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "contact_ids_by_direction"
        ),
      "source_report_station_calendar_entry_ids_by_direction" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_calendar_entry_ids_by_direction"
        ),
      "source_report_station_calendar_reservation_ids_by_direction" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_reservation_ids_by_direction"
        ),
      "source_report_station_calendar_capacity_fractions_by_direction" =>
        source_report_family_merge_numeric_list_maps(
          source_reports,
          "station_capacity_fractions_by_direction"
        ),
      "source_report_station_calendar_direction_routing" =>
        source_report_family_field(source_reports, "direction_routing")
    }
  end
end
