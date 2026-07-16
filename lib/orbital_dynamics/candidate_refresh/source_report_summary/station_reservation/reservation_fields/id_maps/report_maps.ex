defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.ReservationFields.IdMaps.ReportMaps do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      merge_string_list_maps: 1
    ]

  def string_list(reports, report_values) do
    reports
    |> Enum.map(report_values)
    |> merge_string_list_maps()
  end

  def counts(reports, report_values) do
    reports
    |> Enum.map(report_values)
    |> merge_count_maps()
  end
end
