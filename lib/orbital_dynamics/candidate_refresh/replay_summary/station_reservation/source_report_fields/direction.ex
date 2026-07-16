defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Direction do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Aggregation

  def source_report_direction_fields(source_reports) do
    %{
      "source_report_station_reservation_direction_counts" =>
        source_report_family_merge_count_maps(source_reports, "direction_counts"),
      "source_report_station_reservation_contact_ids_by_direction" =>
        source_report_family_merge_string_list_maps(source_reports, "contact_ids_by_direction"),
      "source_report_station_reservation_direction_routing" =>
        source_report_family_field(source_reports, "direction_routing")
    }
  end
end
