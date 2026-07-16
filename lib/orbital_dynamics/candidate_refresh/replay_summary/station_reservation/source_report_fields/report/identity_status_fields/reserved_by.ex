defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.IdentityStatusFields.ReservedBy do
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

  @reserved_by_fields [
    "station_reserved_by",
    "station_calendar_reserved_by",
    "reserved_by",
    "reserved_bys"
  ]

  def reserved_by_counts(report) do
    report
    |> report_rows()
    |> Enum.flat_map(fn row ->
      row
      |> stringify_keys()
      |> row_values(@reserved_by_fields)
    end)
    |> count_values()
  end

  def contact_ids_by_reserved_by(report) do
    report
    |> Map.get("affected_contacts", [])
    |> contact_ids_by_values(@reserved_by_fields)
  end

  def ids_by_reserved_by(report) do
    report
    |> report_rows()
    |> ids_by_values(@reserved_by_fields)
  end
end
