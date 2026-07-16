defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report.Rows.RowValues.ReservationExpirations do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report.Rows.RowValues.Normalization

  def row_reservation_expires_at_s(row) do
    row = stringify_keys(row)
    source_entry = source_station_calendar_entry(row)

    [
      row["station_reservation_expires_at_s"],
      row["station_calendar_reservation_expires_at_s"],
      row["reservation_expires_at_s"],
      row["reservation_expires_at"],
      source_entry["station_reservation_expires_at_s"],
      source_entry["station_calendar_reservation_expires_at_s"],
      source_entry["reservation_expires_at_s"],
      source_entry["reservation_expires_at"]
    ]
    |> List.flatten()
    |> normalize_number_list()
    |> case do
      nil -> []
      expires_at_s -> expires_at_s
    end
  end

  defp source_station_calendar_entry(%{} = row) do
    case row["source_station_calendar_entry"] do
      %{} = entry -> stringify_keys(entry)
      _entry -> %{}
    end
  end

  defp normalize_number_list(value), do: Normalization.normalize_number_list(value)

  defp stringify_keys(value), do: Normalization.stringify_keys(value)
end
