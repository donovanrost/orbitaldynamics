defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.IdentityStatusFields.Expiration do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows,
    only: [
      normalize_number_list: 1,
      report_rows: 1,
      row_values: 2,
      stringify_keys: 1
    ]

  @expiration_fields [
    "station_reservation_expires_at_s",
    "station_calendar_reservation_expires_at_s",
    "reservation_expires_at_s",
    "reservation_expires_at"
  ]

  def expires_at_s(reports) do
    reports
    |> Enum.flat_map(fn report ->
      report
      |> report_rows()
      |> Enum.flat_map(fn row ->
        row
        |> stringify_keys()
        |> row_values(@expiration_fields)
      end)
    end)
    |> normalize_number_list()
  end
end
