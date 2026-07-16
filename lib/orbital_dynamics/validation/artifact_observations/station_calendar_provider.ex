defmodule OrbitalDynamics.Validation.ArtifactObservations.StationCalendarProvider do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    entries = map_rows(artifact, "entries")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "id" => Map.get(artifact, "id"),
      "provider_id" => Map.get(artifact, "provider_id"),
      "entry_count" => length(entries),
      "entry_id_order" =>
        entries
        |> Enum.map(&Map.get(&1, "id"))
        |> Enum.reject(&is_nil/1)
        |> Enum.join("|"),
      "ground_station_id_order" =>
        entries
        |> Enum.map(&(Map.get(&1, "ground_station_id") || Map.get(&1, "station_id")))
        |> Enum.reject(&is_nil/1)
        |> Enum.join("|"),
      "maintenance_entry_count" => Enum.count(entries, &availability_value?(&1, "maintenance")),
      "reserved_entry_count" => Enum.count(entries, &availability_value?(&1, "reserved")),
      "zero_capacity_entry_count" =>
        Enum.count(entries, &(Map.get(&1, "capacity_fraction") == 0)),
      "reservation_entry_count" =>
        Enum.count(entries, &(Map.has_key?(&1, "reservation_id") or Map.has_key?(&1, "hold_id"))),
      "reservation_id_order" =>
        entries
        |> Enum.map(&(Map.get(&1, "reservation_id") || Map.get(&1, "hold_id")))
        |> Enum.reject(&is_nil/1)
        |> Enum.join("|"),
      "reserved_by_order" =>
        entries
        |> Enum.map(&(Map.get(&1, "reserved_by") || Map.get(&1, "held_by")))
        |> Enum.reject(&is_nil/1)
        |> Enum.join("|"),
      "provenance_source" => get_in(artifact, ["provenance", "source"]),
      "trust_boundary" =>
        Map.get(artifact, "trust_boundary") || get_in(artifact, ["provenance", "trust_boundary"]),
      "assumption_boundary" => get_in(artifact, ["assumptions", "boundary"]),
      "network_access" => get_in(artifact, ["assumptions", "network_access"])
    }
  end

  defp map_rows(map, key) do
    case Map.get(map, key) do
      rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
      _rows -> []
    end
  end

  defp availability_value?(row, value) do
    Map.get(row, "availability") == value or Map.get(row, "status") == value
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), stringify_keys(value)}
      {key, value} when is_binary(key) -> {key, stringify_keys(value)}
      {key, value} -> {key, stringify_keys(value)}
    end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
