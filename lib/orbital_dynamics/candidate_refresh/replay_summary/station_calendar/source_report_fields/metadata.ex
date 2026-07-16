defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Metadata do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Aggregation

  def source_report_metadata_fields(source_reports) do
    %{
      "source_report_station_calendar_affected_contact_count" =>
        source_report_family_count(source_reports, "affected_contact_count"),
      "source_report_station_calendar_source_summary_model_counts" =>
        source_report_family_merge_count_maps(source_reports, "source_summary_model_counts"),
      "source_report_station_calendar_source_summary_schema_contract_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "source_summary_schema_contract_counts"
        ),
      "source_report_station_calendar_source_artifact_type_counts" =>
        source_report_family_merge_count_maps(source_reports, "source_artifact_type_counts")
    }
  end
end
