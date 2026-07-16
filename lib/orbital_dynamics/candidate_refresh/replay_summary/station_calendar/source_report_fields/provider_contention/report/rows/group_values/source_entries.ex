defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.ProviderContention.Report.Rows.GroupValues.SourceEntries do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.ProviderContention.Report.Rows.GroupValues.Normalization

  def source_entries(%{} = group) do
    [
      group["source_station_calendar_entries"],
      group["source_station_calendar_overlaps"]
    ]
    |> List.flatten()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&stringify_keys/1)
  end

  def source_entries(_group), do: []

  def source_entry_ids(group) do
    group
    |> stringify_keys()
    |> source_entries()
    |> Enum.flat_map(fn entry ->
      [
        entry["station_calendar_provider_entry_id"],
        entry["provider_entry_id"],
        entry["station_calendar_entry_id"],
        entry["id"]
      ]
    end)
    |> Enum.map(&Normalization.stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def provider_entry_ids(group) do
    group
    |> source_entries()
    |> Enum.flat_map(fn entry ->
      [
        entry["station_calendar_provider_entry_id"],
        entry["provider_entry_id"],
        entry["provider_entry_ids"]
      ]
    end)
  end

  def capacity_fraction(group) do
    candidates =
      [group["capacity_fraction"], group["capacity_pack_capacity_fraction"]] ++
        (group["capacity_fractions"] |> List.wrap()) ++
        (group["capacity_pack_capacity_fractions"] |> List.wrap()) ++
        (group
         |> source_entries()
         |> Enum.map(&station_capacity_fraction/1))

    candidates
    |> Enum.map(&Normalization.numeric_value/1)
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      fractions -> Enum.min(fractions)
    end
  end

  def station_directions(station) do
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
    |> Enum.map(&Normalization.encode_value/1)
    |> Enum.map(&Normalization.normalize_direction/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def nested_station_id(candidate) do
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

  defp station_capacity_fraction(%{} = station) do
    station = stringify_keys(station)

    [
      station["capacity_fraction"],
      station["capacity_pack_capacity_fraction"],
      station["available_capacity_fraction"],
      station["station_capacity_fraction"],
      get_in(station, ["source_station_calendar_entry", "capacity_fraction"]),
      get_in(station, ["source_station_calendar_entry", "capacity_pack_capacity_fraction"])
    ]
    |> Enum.find_value(&unit_interval_capacity_fraction/1)
  end

  defp station_capacity_fraction(_station), do: nil

  defp unit_interval_capacity_fraction(value) do
    case Normalization.numeric_value(value) do
      value when is_number(value) and value >= 0.0 and value <= 1.0 -> value
      _value -> nil
    end
  end

  defp stringify_keys(value), do: Normalization.stringify_keys(value)
end
