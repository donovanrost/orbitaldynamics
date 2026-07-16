defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.ReservationFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report
  alias __MODULE__.IdMaps

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "affected_contact_count" => sum_report_count(reports, &Report.affected_contact_count/1),
      "station_reservation_evidence_row_count" =>
        sum_report_count(reports, &Report.evidence_count/1),
      "station_reservation_expiration_evidence_row_count" =>
        sum_report_count(reports, &Report.expiration_evidence_count/1),
      "reservation_expires_at_s" => Report.expires_at_s(reports),
      "earliest_reservation_expires_at_s" =>
        reports
        |> Report.expires_at_s()
        |> List.wrap()
        |> Enum.min(fn -> nil end),
      "station_reservation_match_status_counts" =>
        reports
        |> Enum.map(&Report.match_status_counts/1)
        |> merge_count_maps(),
      "reservation_status_counts" =>
        reports
        |> Enum.map(&Report.status_counts/1)
        |> merge_count_maps()
    }
    |> Map.merge(IdMaps.fields(reports))
  end
end
