defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report.Rows.RowValues.Annotations do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.StationAvailability

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report.Rows.RowValues.Normalization

  def rows_with_ground_station_id(rows) do
    Enum.map(rows, fn row ->
      row = stringify_keys(row)

      Map.put(
        row,
        "ground_station_id",
        stable_id_or_nil(row["ground_station_id"] || nested_station_id(row))
      )
    end)
  end

  def rows_with_availability(rows) do
    Enum.map(rows, fn row ->
      row = stringify_keys(row)
      Map.put(row, "affected_contact_availability", row_availability(row))
    end)
  end

  defp row_availability(row) do
    [
      row["station_availability"],
      row["station_calendar_status"],
      row["availability"],
      row["status"]
    ]
    |> Enum.find_value(fn value ->
      value = value |> encode_value() |> StationAvailability.normalized_token()
      if value in ["unavailable", "maintenance", "reserved", "reduced_capacity"], do: value
    end)
  end

  defp nested_station_id(candidate) do
    Enum.find_value(["ground_station", "station"], fn station_key ->
      case Map.get(candidate, station_key) do
        %{} = station ->
          Enum.find_value(["ground_station_id", "station_id", "id"], fn identity_key ->
            Map.get(station, identity_key)
          end)

        _station ->
          nil
      end
    end)
  end

  defp stable_id_or_nil(value), do: Normalization.stable_id_or_nil(value)

  defp stringify_keys(value), do: Normalization.stringify_keys(value)

  defp encode_value(value), do: Normalization.encode_value(value)
end
