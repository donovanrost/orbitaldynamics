defmodule OrbitalDynamics.Communications.LinkCapacity.StationCapacity do
  @moduledoc false

  @fraction_paths [
    ["availability"],
    ["capacity_pack_capacity_fraction"],
    ["throughput_model", "availability"],
    ["throughput_model", "station_capacity_fraction"],
    ["throughput_model", "capacity_fraction"],
    ["capacity_model", "availability"],
    ["capacity_model", "station_capacity_fraction"],
    ["capacity_model", "capacity_fraction"],
    ["activity_context", "availability"],
    ["activity_context", "station_capacity_fraction"],
    ["activity_context", "capacity_fraction"],
    ["station_capacity_fraction"],
    ["capacity_fraction"]
  ]

  @percent_paths [
    ["throughput_model", "station_capacity_percent"],
    ["throughput_model", "capacity_percent"],
    ["capacity_model", "station_capacity_percent"],
    ["capacity_model", "capacity_percent"],
    ["activity_context", "station_capacity_percent"],
    ["activity_context", "capacity_percent"],
    ["station_capacity_percent"],
    ["capacity_percent"]
  ]

  @value_paths [
    {:fraction, ["availability"]},
    {:fraction, ["capacity_pack_capacity_fraction"]},
    {:fraction, ["throughput_model", "availability"]},
    {:fraction, ["throughput_model", "station_capacity_fraction"]},
    {:fraction, ["throughput_model", "capacity_fraction"]},
    {:percent, ["throughput_model", "station_capacity_percent"]},
    {:percent, ["throughput_model", "capacity_percent"]},
    {:fraction, ["capacity_model", "availability"]},
    {:fraction, ["capacity_model", "station_capacity_fraction"]},
    {:fraction, ["capacity_model", "capacity_fraction"]},
    {:percent, ["capacity_model", "station_capacity_percent"]},
    {:percent, ["capacity_model", "capacity_percent"]},
    {:fraction, ["activity_context", "availability"]},
    {:fraction, ["activity_context", "station_capacity_fraction"]},
    {:fraction, ["activity_context", "capacity_fraction"]},
    {:percent, ["activity_context", "station_capacity_percent"]},
    {:percent, ["activity_context", "capacity_percent"]},
    {:fraction, ["station_capacity_fraction"]},
    {:fraction, ["capacity_fraction"]},
    {:percent, ["station_capacity_percent"]},
    {:percent, ["capacity_percent"]}
  ]

  def fraction_paths, do: @fraction_paths
  def percent_paths, do: @percent_paths

  def value_path_metadata do
    Enum.map(@value_paths, fn {unit, path} -> %{unit: unit, path: path} end)
  end

  def assumptions do
    @value_paths
    |> Enum.map(fn {unit, path} ->
      %{"unit" => Atom.to_string(unit), "path" => path}
    end)
  end

  def value(contact) do
    (capacity_fraction_from_paths(contact) ||
       source_station_capacity_fraction(contact["source_station_calendar_entry"]) ||
       source_station_capacity_fraction(contact["source_station_calendar_overlaps"]))
    |> case do
      value when is_number(value) -> value
      _value -> 1.0
    end
  end

  defp source_station_capacity_fraction(sources) when is_list(sources) do
    sources
    |> Enum.map(&source_station_capacity_fraction/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> case do
      [capacity_fraction] -> capacity_fraction
      _ambiguous_or_missing -> nil
    end
  end

  defp source_station_capacity_fraction(%{} = source),
    do: capacity_fraction_from_paths(source)

  defp source_station_capacity_fraction(_source), do: nil

  defp capacity_fraction_from_paths(value) do
    Enum.find_value(@value_paths, fn
      {:fraction, path} ->
        value |> path_value(path) |> numeric_value()

      {:percent, path} ->
        case numeric_value(path_value(value, path)) do
          value when is_number(value) -> value / 100.0
          _value -> nil
        end
    end)
  end

  defp path_value(value, [field]), do: Map.get(value, field)
  defp path_value(value, path), do: get_in(value, path)

  defp numeric_value(value) when is_integer(value) or is_float(value), do: value * 1.0

  defp numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _parse_error -> nil
    end
  end

  defp numeric_value(_value), do: nil
end
