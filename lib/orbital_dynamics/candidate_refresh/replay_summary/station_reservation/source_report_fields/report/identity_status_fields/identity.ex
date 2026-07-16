defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.IdentityStatusFields.Identity do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows,
    only: [
      report_rows: 1,
      row_values: 2,
      sorted_string_values: 1,
      stable_id_or_nil: 1,
      stringify_keys: 1
    ]

  @reservation_id_fields [
    "station_reservation_id",
    "station_calendar_reservation_ids",
    "reservation_id",
    "reservation_ids"
  ]

  @contact_id_fields ["contact_id", "source_contact_id", "candidate_id"]

  def ids(reports) do
    reports
    |> Enum.flat_map(fn report ->
      report
      |> report_rows()
      |> Enum.flat_map(fn row ->
        row
        |> stringify_keys()
        |> row_values(@reservation_id_fields)
      end)
    end)
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  def affected_contact_ids(reports) do
    reports
    |> Enum.flat_map(fn report ->
      report
      |> Map.get("affected_contacts", [])
      |> Enum.flat_map(fn row ->
        row
        |> stringify_keys()
        |> row_values(@contact_id_fields)
      end)
    end)
    |> sorted_string_values()
  end
end
