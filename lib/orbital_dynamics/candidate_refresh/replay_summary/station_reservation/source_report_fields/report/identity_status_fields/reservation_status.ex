defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.IdentityStatusFields.ReservationStatus do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows,
    only: [
      contact_ids_by_values: 2,
      count_values: 1,
      ids_by_values: 2,
      report_rows: 1,
      row_values: 2,
      stringify_keys: 1
    ]

  @reservation_status_fields [
    "station_reservation_status",
    "station_calendar_reservation_statuses",
    "reservation_status",
    "reservation_statuses"
  ]

  def status_counts(report) do
    report
    |> report_rows()
    |> Enum.flat_map(fn row ->
      row
      |> stringify_keys()
      |> row_values(@reservation_status_fields)
    end)
    |> count_values()
  end

  def contact_ids_by_status(report) do
    report
    |> Map.get("affected_contacts", [])
    |> contact_ids_by_values(@reservation_status_fields)
  end

  def ids_by_status(report) do
    report
    |> report_rows()
    |> ids_by_values(@reservation_status_fields)
  end
end
