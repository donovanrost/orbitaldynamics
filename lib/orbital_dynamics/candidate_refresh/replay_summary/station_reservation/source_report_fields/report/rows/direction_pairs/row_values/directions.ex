defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows.DirectionPairs.RowValues.Directions do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows.DirectionPairs.Normalization

  def row_directions(row) do
    row = stringify_keys(row)

    [
      station_directions(row),
      row["contact_direction"],
      row["activity_direction"],
      row["contact_type"],
      row["type"],
      row["activity_type"],
      get_in(row, ["activity_context", "direction"]),
      get_in(row, ["activity_context", "type"]),
      get_in(row, ["activity_context", "activity_type"]),
      get_in(row, ["source_contact", "direction"]),
      get_in(row, ["source_contact", "type"]),
      get_in(row, ["source_contact", "activity_type"]),
      get_in(row, ["contact", "direction"]),
      get_in(row, ["contact", "type"]),
      get_in(row, ["contact", "activity_type"]),
      get_in(row, ["source_contact_candidate", "direction"]),
      get_in(row, ["source_contact_candidate", "type"]),
      get_in(row, ["source_contact_candidate", "activity_type"]),
      get_in(row, ["contact_candidate", "direction"]),
      get_in(row, ["contact_candidate", "type"]),
      get_in(row, ["contact_candidate", "activity_type"])
    ]
    |> List.flatten()
    |> Enum.map(&normalize_direction/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
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
