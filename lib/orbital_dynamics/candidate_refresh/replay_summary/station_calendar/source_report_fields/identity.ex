defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Identity do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Aggregation

  def source_report_identity_fields(source_reports) do
    %{
      "source_report_station_calendar_contract" =>
        source_report_family_field(source_reports, "contract"),
      "source_report_station_calendar_count" =>
        source_report_family_identity_count(source_reports, "count"),
      "source_report_station_calendar_row_count" =>
        source_report_family_identity_count(source_reports, "row_count"),
      "source_report_station_calendar_paths" =>
        source_report_family_identity_field(source_reports, "paths")
    }
  end
end
