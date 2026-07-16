defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Evidence do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Aggregation

  def source_report_evidence_fields(source_reports) do
    %{
      "source_report_station_reservation_evidence_row_count" =>
        source_report_count(source_reports, "station_reservation_evidence_row_count"),
      "source_report_station_reservation_expiration_evidence_row_count" =>
        source_report_count(source_reports, "station_reservation_expiration_evidence_row_count"),
      "source_report_station_reservation_evidence_row_counts_by_family" =>
        source_report_counts_by_family(source_reports, "station_reservation_evidence_row_count"),
      "source_report_station_reservation_expiration_evidence_row_counts_by_family" =>
        source_report_counts_by_family(
          source_reports,
          "station_reservation_expiration_evidence_row_count"
        ),
      "source_report_station_reservation_affected_contact_count" =>
        source_report_family_count(source_reports, "affected_contact_count"),
      "source_report_station_reservation_reservation_review_count" =>
        source_report_family_count(source_reports, "reservation_review_count")
    }
  end
end
