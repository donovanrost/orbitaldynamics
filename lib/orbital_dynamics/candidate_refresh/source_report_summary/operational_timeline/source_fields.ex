defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.SourceFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      report_station_reservation_evidence_count: 1,
      report_station_reservation_expiration_evidence_count: 1,
      sum_report_count: 2
    ]

  def fields(sources, reports) do
    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "operational_timeline_report.v1",
      "count" => length(sources),
      "station_reservation_evidence_row_count" =>
        sum_report_count(reports, &report_station_reservation_evidence_count/1),
      "station_reservation_expiration_evidence_row_count" =>
        sum_report_count(reports, &report_station_reservation_expiration_evidence_count/1)
    }
  end
end
