defmodule OrbitalDynamics.Communications.ContactIntent.CapacityEvidence do
  @moduledoc false

  @station_capacity_fraction_paths [
    ["availability"],
    ["capacity_pack_capacity_fraction"],
    ["station_capacity_fraction"],
    ["capacity_fraction"],
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
    ["station_capacity_percent"],
    ["capacity_percent"],
    ["throughput_model", "station_capacity_percent"],
    ["throughput_model", "capacity_percent"],
    ["capacity_model", "station_capacity_percent"],
    ["capacity_model", "capacity_percent"],
    ["activity_context", "station_capacity_percent"],
    ["activity_context", "capacity_percent"]
  ]
  @station_capacity_value_paths [
    {:fraction, ["availability"]},
    {:fraction, ["capacity_pack_capacity_fraction"]},
    {:fraction, ["station_capacity_fraction"]},
    {:fraction, ["capacity_fraction"]},
    {:percent, ["station_capacity_percent"]},
    {:percent, ["capacity_percent"]},
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
    {:percent, ["activity_context", "capacity_percent"]}
  ]
  @required_capacity_fraction_paths [
    ["required_capacity_fraction"],
    ["required_station_capacity_fraction"],
    ["station_capacity_requirement"],
    ["throughput_model", "required_capacity_fraction"],
    ["throughput_model", "required_station_capacity_fraction"],
    ["throughput_model", "station_capacity_requirement"],
    ["capacity_model", "required_capacity_fraction"],
    ["capacity_model", "required_station_capacity_fraction"],
    ["capacity_model", "station_capacity_requirement"],
    ["activity_context", "required_capacity_fraction"],
    ["activity_context", "required_station_capacity_fraction"],
    ["activity_context", "station_capacity_requirement"]
  ]
  @required_capacity_percent_paths [
    ["required_capacity_percent"],
    ["required_station_capacity_percent"],
    ["station_capacity_requirement_percent"],
    ["throughput_model", "required_capacity_percent"],
    ["throughput_model", "required_station_capacity_percent"],
    ["throughput_model", "station_capacity_requirement_percent"],
    ["capacity_model", "required_capacity_percent"],
    ["capacity_model", "required_station_capacity_percent"],
    ["capacity_model", "station_capacity_requirement_percent"],
    ["activity_context", "required_capacity_percent"],
    ["activity_context", "required_station_capacity_percent"],
    ["activity_context", "station_capacity_requirement_percent"]
  ]
  @required_capacity_value_paths [
    {:fraction, ["required_capacity_fraction"]},
    {:fraction, ["required_station_capacity_fraction"]},
    {:fraction, ["station_capacity_requirement"]},
    {:percent, ["required_capacity_percent"]},
    {:percent, ["required_station_capacity_percent"]},
    {:percent, ["station_capacity_requirement_percent"]},
    {:fraction, ["throughput_model", "required_capacity_fraction"]},
    {:fraction, ["throughput_model", "required_station_capacity_fraction"]},
    {:fraction, ["throughput_model", "station_capacity_requirement"]},
    {:percent, ["throughput_model", "required_capacity_percent"]},
    {:percent, ["throughput_model", "required_station_capacity_percent"]},
    {:percent, ["throughput_model", "station_capacity_requirement_percent"]},
    {:fraction, ["capacity_model", "required_capacity_fraction"]},
    {:fraction, ["capacity_model", "required_station_capacity_fraction"]},
    {:fraction, ["capacity_model", "station_capacity_requirement"]},
    {:percent, ["capacity_model", "required_capacity_percent"]},
    {:percent, ["capacity_model", "required_station_capacity_percent"]},
    {:percent, ["capacity_model", "station_capacity_requirement_percent"]},
    {:fraction, ["activity_context", "required_capacity_fraction"]},
    {:fraction, ["activity_context", "required_station_capacity_fraction"]},
    {:fraction, ["activity_context", "station_capacity_requirement"]},
    {:percent, ["activity_context", "required_capacity_percent"]},
    {:percent, ["activity_context", "required_station_capacity_percent"]},
    {:percent, ["activity_context", "station_capacity_requirement_percent"]}
  ]
  @required_capacity_fraction_source_values ~w(
    contact_required_capacity_fraction
    throughput_model
    capacity_model
    activity_context
  )

  def station_fraction_paths, do: @station_capacity_fraction_paths
  def station_percent_paths, do: @station_capacity_percent_paths
  def required_fraction_paths, do: @required_capacity_fraction_paths
  def required_percent_paths, do: @required_capacity_percent_paths
  def required_source_values, do: @required_capacity_fraction_source_values

  def station_value_path_metadata, do: path_metadata(@station_capacity_value_paths)
  def required_value_path_metadata, do: path_metadata(@required_capacity_value_paths)

  def assumptions do
    %{
      "station_capacity_value_paths" => path_assumptions(@station_capacity_value_paths),
      "required_capacity_value_paths" => path_assumptions(@required_capacity_value_paths),
      "required_capacity_fraction_source_values" => @required_capacity_fraction_source_values
    }
  end

  def station_context(activity) do
    case station_capacity_fractions(activity) do
      [] ->
        %{}

      fractions ->
        %{
          "capacity_fraction" => Enum.min(fractions),
          "capacity_fraction_min" => Enum.min(fractions),
          "capacity_fraction_max" => Enum.max(fractions)
        }
    end
  end

  defp station_capacity_fractions(activity) do
    activity
    |> station_capacity_fraction_candidates()
    |> Enum.map(&unit_interval_number/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp station_capacity_fraction_candidates(activity) do
    capacity_value_candidates(activity, @station_capacity_value_paths) ++
      source_station_capacity_fraction_candidates(activity["source_station_calendar_entry"]) ++
      source_station_capacity_fraction_candidates(activity["source_station_calendar_overlaps"])
  end

  def required_context(activity) do
    case required_capacity_fraction(activity) do
      nil ->
        %{}

      required_capacity_fraction ->
        compact_map(%{
          "required_capacity_fraction" => required_capacity_fraction,
          "required_capacity_fraction_source" => required_capacity_fraction_source(activity)
        })
    end
  end

  defp required_capacity_fraction(activity) do
    activity
    |> capacity_value_candidates(@required_capacity_value_paths)
    |> Enum.find_value(&unit_interval_number/1)
  end

  defp required_capacity_fraction_source(activity) do
    cond do
      valid_capacity_value_declared?(activity["required_capacity_fraction"]) or
        valid_capacity_value_declared?(activity["required_station_capacity_fraction"]) or
        valid_capacity_value_declared?(activity["station_capacity_requirement"]) or
        valid_capacity_percent_declared?(activity["required_capacity_percent"]) or
        valid_capacity_percent_declared?(activity["required_station_capacity_percent"]) or
          valid_capacity_percent_declared?(activity["station_capacity_requirement_percent"]) ->
        "contact_required_capacity_fraction"

      nested_required_capacity_declared?(activity, "throughput_model") ->
        "throughput_model"

      nested_required_capacity_declared?(activity, "capacity_model") ->
        "capacity_model"

      nested_required_capacity_declared?(activity, "activity_context") ->
        "activity_context"

      true ->
        nil
    end
  end

  defp nested_required_capacity_declared?(activity, key) do
    valid_capacity_value_declared?(get_in(activity, [key, "required_capacity_fraction"])) or
      valid_capacity_value_declared?(
        get_in(activity, [key, "required_station_capacity_fraction"])
      ) or
      valid_capacity_value_declared?(get_in(activity, [key, "station_capacity_requirement"])) or
      valid_capacity_percent_declared?(get_in(activity, [key, "required_capacity_percent"])) or
      valid_capacity_percent_declared?(
        get_in(activity, [key, "required_station_capacity_percent"])
      ) or
      valid_capacity_percent_declared?(
        get_in(activity, [key, "station_capacity_requirement_percent"])
      )
  end

  defp valid_capacity_value_declared?(value), do: is_number(unit_interval_number(value))

  defp valid_capacity_percent_declared?(value), do: is_number(capacity_percent_fraction(value))

  defp source_station_capacity_fraction_candidates(sources) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_capacity_fraction_candidates/1)

  defp source_station_capacity_fraction_candidates(%{} = source) do
    capacity_value_candidates(source, @station_capacity_value_paths)
  end

  defp source_station_capacity_fraction_candidates(_source), do: []

  defp capacity_value_candidates(value, paths) do
    Enum.map(paths, fn
      {:fraction, path} ->
        path_value(value, path)

      {:percent, path} ->
        capacity_percent_fraction(path_value(value, path))
    end)
  end

  defp path_value(value, [field]), do: Map.get(value, field)
  defp path_value(value, path), do: get_in(value, path)

  defp capacity_percent_fraction(value) do
    case numeric_value(value) do
      value when is_number(value) and value >= 0.0 and value <= 100.0 -> value / 100.0
      _value -> nil
    end
  end

  defp unit_interval_number(value) do
    case numeric_value(value) do
      value when is_number(value) and value >= 0.0 and value <= 1.0 -> value
      _value -> nil
    end
  end

  defp path_metadata(paths) do
    Enum.map(paths, fn {unit, path} -> %{unit: unit, path: path} end)
  end

  defp path_assumptions(paths) do
    Enum.map(paths, fn {unit, path} -> %{"unit" => Atom.to_string(unit), "path" => path} end)
  end

  defp numeric_value(value) when is_integer(value) or is_float(value), do: value

  defp numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _other -> nil
    end
  end

  defp numeric_value(_value), do: nil

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
