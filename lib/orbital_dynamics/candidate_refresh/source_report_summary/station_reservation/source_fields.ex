defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.SourceFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report
  alias __MODULE__.TrustBoundaries

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_report_field_values: 2,
      sum_report_count: 2
    ]

  def fields(sources, reports) do
    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "station_reservation_report.v1",
      "count" => length(sources),
      "row_count" => sum_report_count(reports, &Report.row_count/1),
      "source_summary_model_counts" =>
        reports
        |> count_report_field_values("source_summary_model"),
      "source_summary_schema_contract_counts" =>
        reports
        |> count_report_field_values("source_summary_schema_contract"),
      "source_artifact_type_counts" =>
        reports
        |> count_report_field_values("source_artifact_type"),
      "trust_boundary_status" => TrustBoundaries.status(reports),
      "trust_boundaries" => TrustBoundaries.values(reports)
    }
  end
end
