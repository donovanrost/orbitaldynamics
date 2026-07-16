defmodule OrbitalDynamics.CandidateRefresh.StationCapacity do
  @moduledoc false

  @station_capacity_fraction_paths [
    ["availability"],
    ["capacity_fraction"],
    ["station_capacity_fraction"],
    ["capacity_pack_capacity_fraction"],
    ["throughput_model", "availability"],
    ["throughput_model", "station_capacity_fraction"],
    ["throughput_model", "capacity_fraction"],
    ["capacity_model", "availability"],
    ["capacity_model", "station_capacity_fraction"],
    ["capacity_model", "capacity_fraction"],
    ["activity_context", "availability"],
    ["activity_context", "station_capacity_fraction"],
    ["activity_context", "capacity_fraction"]
  ]
  @station_capacity_percent_paths [
    ["capacity_percent"],
    ["station_capacity_percent"],
    ["throughput_model", "capacity_percent"],
    ["throughput_model", "station_capacity_percent"],
    ["capacity_model", "capacity_percent"],
    ["capacity_model", "station_capacity_percent"],
    ["activity_context", "capacity_percent"],
    ["activity_context", "station_capacity_percent"]
  ]

  def fraction(station, numeric_value) do
    station
    |> candidates(numeric_value)
    |> Enum.find_value(&unit_interval(&1, numeric_value))
    |> case do
      nil -> 1.0
      capacity_fraction -> capacity_fraction
    end
  end

  def candidates(station, numeric_value) do
    capacity_path_candidates(station, numeric_value) ++
      station_source_capacity_fraction_candidates(station, numeric_value)
  end

  def unit_interval(value, numeric_value) do
    case numeric_value.(value) do
      value when is_number(value) and value >= 0.0 and value <= 1.0 -> value
      value when is_number(value) -> value |> max(0.0) |> min(1.0)
      _value -> nil
    end
  end

  defp station_source_capacity_fraction_candidates(
         %{"station_calendar_entry_ambiguous" => true},
         _numeric_value
       ),
       do: []

  defp station_source_capacity_fraction_candidates(station, numeric_value) do
    source_capacity_fraction_candidates(
      Map.get(station, "source_station_calendar_entry"),
      numeric_value
    ) ++
      source_capacity_fraction_candidates(
        Map.get(station, "source_station_calendar_overlaps"),
        numeric_value
      )
  end

  defp source_capacity_fraction_candidates(sources, numeric_value) when is_list(sources),
    do: Enum.flat_map(sources, &source_capacity_fraction_candidates(&1, numeric_value))

  defp source_capacity_fraction_candidates(%{} = source, numeric_value) do
    capacity_path_candidates(source, numeric_value)
  end

  defp source_capacity_fraction_candidates(_source, _numeric_value), do: []

  defp capacity_path_candidates(%{} = station, numeric_value) do
    Enum.map(@station_capacity_fraction_paths, &path_value(station, &1)) ++
      [capacity_percent_fraction(station, numeric_value)]
  end

  defp capacity_path_candidates(_station, _numeric_value), do: []

  defp capacity_percent_fraction(%{} = station, numeric_value) do
    @station_capacity_percent_paths
    |> Enum.map(&path_value(station, &1))
    |> Enum.find_value(fn value ->
      case numeric_value.(value) do
        value when is_number(value) and value >= 0.0 and value <= 100.0 -> value / 100.0
        _value -> nil
      end
    end)
  end

  defp path_value(%{} = map, path), do: get_in(map, path)
end
