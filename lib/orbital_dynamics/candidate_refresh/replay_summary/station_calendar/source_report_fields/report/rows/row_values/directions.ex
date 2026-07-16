defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report.Rows.RowValues.Directions do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report.Rows.RowValues.Normalization

  def affected_contact_rows_with_directions(report) do
    report
    |> Map.get("affected_contacts", [])
    |> Enum.map(fn row ->
      row = stringify_keys(row)
      Map.put(row, "station_calendar_direction", row_directions(row))
    end)
  end

  def row_directions(row) do
    row
    |> stringify_keys()
    |> station_directions()
  end

  defp station_directions(station) do
    station = stringify_keys(station)

    [
      Map.get(station, "directions"),
      Map.get(station, "station_calendar_directions"),
      Map.get(station, "direction"),
      get_in(station, ["source_station_calendar_entry", "directions"]),
      get_in(station, ["source_station_calendar_entry", "station_calendar_directions"]),
      get_in(station, ["source_station_calendar_entry", "direction"])
    ]
    |> List.flatten()
    |> Enum.map(&encode_value/1)
    |> Enum.map(&normalize_direction/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp normalize_direction(direction), do: Normalization.normalize_direction(direction)
  defp stringify_keys(value), do: Normalization.stringify_keys(value)
  defp encode_value(value), do: Normalization.encode_value(value)
end
