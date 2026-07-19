defmodule OrbitalDynamics.ResourceProjection.StationCapacityEvidence do
  @moduledoc false

  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/

  @station_capacity_fraction_paths [
    ["throughput_model", "station_capacity_fraction"],
    ["throughput_model", "capacity_fraction"],
    ["capacity_model", "station_capacity_fraction"],
    ["capacity_model", "capacity_fraction"],
    ["activity_context", "station_capacity_fraction"],
    ["activity_context", "capacity_fraction"],
    ["capacity_pack_capacity_fraction"],
    ["station_capacity_fraction"],
    ["capacity_fraction"]
  ]
  @station_capacity_percent_paths [
    ["throughput_model", "station_capacity_percent"],
    ["throughput_model", "capacity_percent"],
    ["capacity_model", "station_capacity_percent"],
    ["capacity_model", "capacity_percent"],
    ["activity_context", "station_capacity_percent"],
    ["activity_context", "capacity_percent"],
    ["station_capacity_percent"],
    ["capacity_percent"]
  ]
  @source_station_capacity_fraction_paths [
    ["station_capacity_fraction"],
    ["capacity_fraction"],
    ["capacity_pack_capacity_fraction"],
    ["throughput_model", "station_capacity_fraction"],
    ["throughput_model", "capacity_fraction"],
    ["capacity_model", "station_capacity_fraction"],
    ["capacity_model", "capacity_fraction"],
    ["activity_context", "station_capacity_fraction"],
    ["activity_context", "capacity_fraction"]
  ]
  @source_station_capacity_percent_paths [
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
    {:fraction, ["throughput_model", "station_capacity_fraction"]},
    {:fraction, ["throughput_model", "capacity_fraction"]},
    {:percent, ["throughput_model", "station_capacity_percent"]},
    {:percent, ["throughput_model", "capacity_percent"]},
    {:fraction, ["capacity_model", "station_capacity_fraction"]},
    {:fraction, ["capacity_model", "capacity_fraction"]},
    {:percent, ["capacity_model", "station_capacity_percent"]},
    {:percent, ["capacity_model", "capacity_percent"]},
    {:fraction, ["activity_context", "station_capacity_fraction"]},
    {:fraction, ["activity_context", "capacity_fraction"]},
    {:percent, ["activity_context", "station_capacity_percent"]},
    {:percent, ["activity_context", "capacity_percent"]},
    {:fraction, ["capacity_pack_capacity_fraction"]},
    {:fraction, ["station_capacity_fraction"]},
    {:fraction, ["capacity_fraction"]},
    {:percent, ["station_capacity_percent"]},
    {:percent, ["capacity_percent"]}
  ]
  @source_station_capacity_value_paths [
    {:fraction, ["station_capacity_fraction"]},
    {:fraction, ["capacity_fraction"]},
    {:fraction, ["capacity_pack_capacity_fraction"]},
    {:percent, ["station_capacity_percent"]},
    {:percent, ["capacity_percent"]},
    {:fraction, ["throughput_model", "station_capacity_fraction"]},
    {:fraction, ["throughput_model", "capacity_fraction"]},
    {:percent, ["throughput_model", "station_capacity_percent"]},
    {:percent, ["throughput_model", "capacity_percent"]},
    {:fraction, ["capacity_model", "station_capacity_fraction"]},
    {:fraction, ["capacity_model", "capacity_fraction"]},
    {:percent, ["capacity_model", "station_capacity_percent"]},
    {:percent, ["capacity_model", "capacity_percent"]},
    {:fraction, ["activity_context", "station_capacity_fraction"]},
    {:fraction, ["activity_context", "capacity_fraction"]},
    {:percent, ["activity_context", "station_capacity_percent"]},
    {:percent, ["activity_context", "capacity_percent"]}
  ]

  def station_capacity_fraction_paths, do: @station_capacity_fraction_paths
  def station_capacity_percent_paths, do: @station_capacity_percent_paths
  def source_station_capacity_fraction_paths, do: @source_station_capacity_fraction_paths
  def source_station_capacity_percent_paths, do: @source_station_capacity_percent_paths

  def station_capacity_value_path_metadata,
    do: capacity_value_path_metadata(@station_capacity_value_paths)

  def source_station_capacity_value_path_metadata,
    do: capacity_value_path_metadata(@source_station_capacity_value_paths)

  def capacity_fraction(contact) do
    contact
    |> contact_capacity_fraction_candidates()
    |> Enum.find_value(&numeric_or_nil/1)
    |> case do
      nil -> 1.0
      value -> value |> max(0.0) |> min(1.0)
    end
  end

  def station_calendar_entry_id(activity) do
    stable_id_or_nil(activity["station_calendar_entry_id"]) ||
      stable_id_or_nil(
        get_in(activity, ["source_station_calendar_entry", "station_calendar_entry_id"])
      ) ||
      stable_id_or_nil(get_in(activity, ["source_station_calendar_entry", "id"])) ||
      source_station_calendar_overlap_stable_id(activity, [
        "station_calendar_entry_id",
        "entry_id",
        "id"
      ])
  end

  def station_calendar_provider_id(activity) do
    stable_id_or_nil(activity["station_calendar_provider_id"]) ||
      stable_id_or_nil(get_in(activity, ["source_station_calendar_entry", "provider_id"])) ||
      stable_id_or_nil(
        get_in(activity, ["source_station_calendar_entry", "station_calendar_provider_id"])
      ) ||
      source_station_calendar_overlap_stable_id(activity, [
        "provider_id",
        "station_calendar_provider_id"
      ])
  end

  def station_calendar_provider_entry_id(activity) do
    stable_id_or_nil(activity["station_calendar_provider_entry_id"]) ||
      stable_id_or_nil(get_in(activity, ["source_station_calendar_entry", "provider_entry_id"])) ||
      stable_id_or_nil(
        get_in(activity, ["source_station_calendar_entry", "station_calendar_provider_entry_id"])
      ) ||
      source_station_calendar_overlap_stable_id(activity, [
        "provider_entry_id",
        "station_calendar_provider_entry_id"
      ])
  end

  defp capacity_value_path_metadata(paths) do
    Enum.map(paths, fn {unit, path} -> %{unit: unit, path: path} end)
  end

  defp contact_capacity_fraction_candidates(contact) do
    capacity_value_candidates(contact, @station_capacity_value_paths) ++
      capacity_value_candidates(
        contact["source_contact_allocation"],
        @source_station_capacity_value_paths
      ) ++
      source_station_capacity_fraction_candidates(contact["source_station_calendar_entry"]) ++
      source_station_capacity_fraction_candidates(contact["source_station_calendar_overlaps"])
  end

  defp source_station_capacity_fraction_candidates(sources) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_capacity_fraction_candidates/1)

  defp source_station_capacity_fraction_candidates(%{} = source) do
    capacity_value_candidates(source, @source_station_capacity_value_paths) ++
      capacity_value_candidates(
        source["source_contact_allocation"],
        @source_station_capacity_value_paths
      )
  end

  defp source_station_capacity_fraction_candidates(_source), do: []

  defp capacity_value_candidates(%{} = source, paths) do
    Enum.map(paths, fn
      {:fraction, path} -> path_value(source, path)
      {:percent, path} -> capacity_percent_fraction(path_value(source, path))
    end)
  end

  defp capacity_value_candidates(_source, _paths), do: []

  defp path_value(source, [field]), do: Map.get(source, field)
  defp path_value(source, path), do: get_in(source, path)

  defp capacity_percent_fraction(value) do
    case numeric_or_nil(value) do
      value when is_number(value) and value >= 0.0 and value <= 100.0 -> value / 100.0
      _value -> nil
    end
  end

  defp source_station_calendar_overlap_stable_id(activity, fields) do
    activity
    |> Map.get("source_station_calendar_overlaps")
    |> source_station_calendar_capacity_source()
    |> source_station_calendar_stable_id(fields)
  end

  defp source_station_calendar_capacity_source(sources) when is_list(sources) do
    Enum.find(sources, &source_station_calendar_has_capacity?/1) ||
      Enum.find(sources, &is_map/1)
  end

  defp source_station_calendar_capacity_source(%{} = source), do: source
  defp source_station_calendar_capacity_source(_source), do: nil

  defp source_station_calendar_has_capacity?(%{} = source) do
    source
    |> source_station_capacity_fraction_candidates()
    |> Enum.any?(&(not is_nil(numeric_or_nil(&1))))
  end

  defp source_station_calendar_has_capacity?(_source), do: false

  defp source_station_calendar_stable_id(%{} = source, fields) do
    Enum.find_value(fields, fn field -> stable_id_or_nil(Map.get(source, field)) end)
  end

  defp source_station_calendar_stable_id(_source, _fields), do: nil

  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value * 1.0

  defp numeric_or_nil(value) when is_binary(value) do
    value = String.trim(value)

    case Float.parse(value) do
      {number, ""} -> number
      _result -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp stable_id?(value) when is_atom(value) and not is_nil(value) do
    value
    |> Atom.to_string()
    |> stable_id?()
  end

  defp stable_id?("nil"), do: false
  defp stable_id?(value) when is_binary(value), do: Regex.match?(@stable_id_pattern, value)
  defp stable_id?(value) when is_integer(value), do: value |> Integer.to_string() |> stable_id?()
  defp stable_id?(_value), do: false

  defp stable_id_or_nil(nil), do: nil
  defp stable_id_or_nil("nil"), do: nil
  defp stable_id_or_nil(value) when is_binary(value), do: if(stable_id?(value), do: value)

  defp stable_id_or_nil(value) when is_atom(value),
    do: value |> Atom.to_string() |> stable_id_or_nil()

  defp stable_id_or_nil(value) when is_integer(value),
    do: value |> Integer.to_string() |> stable_id_or_nil()

  defp stable_id_or_nil(_value), do: nil
end
