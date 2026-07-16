defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Metadata do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Aggregation

  def source_report_metadata_fields(source_reports) do
    %{
      "source_report_station_reservation_contract" =>
        source_report_family_field(source_reports, "contract"),
      "source_report_station_reservation_count" =>
        source_report_family_identity_count(source_reports, "count"),
      "source_report_station_reservation_row_count" =>
        source_report_family_identity_count(source_reports, "row_count"),
      "source_report_station_reservation_paths" =>
        source_report_family_identity_field(source_reports, "paths"),
      "source_report_station_reservation_source_summary_model_counts" =>
        source_report_family_merge_count_maps(source_reports, "source_summary_model_counts"),
      "source_report_station_reservation_source_summary_schema_contract_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "source_summary_schema_contract_counts"
        ),
      "source_report_station_reservation_source_artifact_type_counts" =>
        source_report_family_merge_count_maps(source_reports, "source_artifact_type_counts")
    }
  end
end
