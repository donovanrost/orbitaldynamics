defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report.Rows.ValueMaps.RowValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.StationCapacity

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report.Rows.ValueMaps.Normalization

  def row_entry_ids(row) do
    row = stringify_keys(row)
    source_entry = source_station_calendar_entry(row)

    [
      row["station_calendar_entry_id"],
      row["source_station_calendar_entry_id"],
      source_entry["station_calendar_entry_id"],
      source_entry["id"]
    ]
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def row_capacity_fractions(row) do
    numeric_value = &numeric_value/1

    row
    |> stringify_keys()
    |> StationCapacity.candidates(numeric_value)
    |> Enum.map(&StationCapacity.unit_interval(&1, numeric_value))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def row_reserved_by_values(row) do
    row = stringify_keys(row)
    source_entry = source_station_calendar_entry(row)

    [
      row["station_reserved_by"],
      row["station_calendar_reserved_by"],
      row["reserved_by"],
      row["reserved_bys"],
      source_entry["station_reserved_by"],
      source_entry["station_calendar_reserved_by"],
      source_entry["reserved_by"],
      source_entry["reserved_bys"]
    ]
    |> List.flatten()
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def row_reservation_ids(row) do
    row = stringify_keys(row)
    source_entry = source_station_calendar_entry(row)

    [
      row["station_reservation_id"],
      row["station_calendar_reservation_id"],
      row["station_calendar_reservation_ids"],
      row["reservation_id"],
      row["reservation_ids"],
      source_entry["station_reservation_id"],
      source_entry["station_calendar_reservation_id"],
      source_entry["station_calendar_reservation_ids"],
      source_entry["reservation_id"],
      source_entry["reservation_ids"]
    ]
    |> List.flatten()
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp source_station_calendar_entry(%{} = row) do
    case row["source_station_calendar_entry"] do
      %{} = entry -> stringify_keys(entry)
      _entry -> %{}
    end
  end

  defp numeric_value(value), do: Normalization.numeric_value(value)
  defp stable_id_or_nil(value), do: Normalization.stable_id_or_nil(value)
  defp stringify_keys(value), do: Normalization.stringify_keys(value)
end
