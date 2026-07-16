defmodule OrbitalDynamics.Validation.ArtifactObservations.ContactAllocationCapacityPackSummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "rows")
    capacity_rows = capacity_pack_rows(rows)
    reduced_groups = map_rows(artifact, "reduced_capacity_pack_groups")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source_artifact_type" => Map.get(artifact, "source_artifact_type"),
      "source" => Map.get(artifact, "source"),
      "input_contact_count" => Map.get(artifact, "input_contact_count"),
      "row_derived_input_contact_count" => length(rows),
      "capacity_pack_contact_count" => Map.get(artifact, "capacity_pack_contact_count"),
      "row_derived_capacity_pack_contact_count" => length(capacity_rows),
      "reduced_capacity_pack_group_count" =>
        Map.get(artifact, "reduced_capacity_pack_group_count"),
      "row_derived_reduced_capacity_pack_group_count" => length(reduced_groups),
      "capacity_pack_status_counts" => Map.get(artifact, "capacity_pack_status_counts"),
      "row_derived_capacity_pack_status_counts" =>
        row_value_counts(capacity_rows, "capacity_pack_status"),
      "reduced_capacity_pack_status_counts" =>
        Map.get(artifact, "reduced_capacity_pack_status_counts"),
      "row_derived_reduced_capacity_pack_status_counts" =>
        row_value_counts(reduced_groups, "pack_status"),
      "capacity_pack_contact_ids_by_status" =>
        Map.get(artifact, "capacity_pack_contact_ids_by_status"),
      "row_derived_capacity_pack_contact_ids_by_status" =>
        capacity_rows
        |> group_row_ids_by_value("capacity_pack_status", "contact_id")
        |> sort_grouped_values(),
      "reduced_capacity_packed_contact_ids" =>
        Map.get(artifact, "reduced_capacity_packed_contact_ids"),
      "reduced_capacity_packed_contact_keys" =>
        artifact
        |> list_values("reduced_capacity_packed_contact_ids")
        |> Enum.join("|"),
      "row_derived_reduced_capacity_packed_contact_ids" =>
        reduced_groups
        |> Enum.flat_map(&list_values(&1, "capacity_packed_contact_ids"))
        |> Enum.uniq()
        |> Enum.sort(),
      "row_derived_reduced_capacity_packed_contact_keys" =>
        reduced_groups
        |> Enum.flat_map(&list_values(&1, "capacity_packed_contact_ids"))
        |> Enum.uniq()
        |> Enum.sort()
        |> Enum.join("|"),
      "reduced_capacity_deferred_contact_ids" =>
        Map.get(artifact, "reduced_capacity_deferred_contact_ids"),
      "reduced_capacity_deferred_contact_keys" =>
        artifact
        |> list_values("reduced_capacity_deferred_contact_ids")
        |> Enum.join("|"),
      "row_derived_reduced_capacity_deferred_contact_ids" =>
        reduced_groups
        |> Enum.flat_map(&list_values(&1, "deferred_contact_ids"))
        |> Enum.uniq()
        |> Enum.sort(),
      "row_derived_reduced_capacity_deferred_contact_keys" =>
        reduced_groups
        |> Enum.flat_map(&list_values(&1, "deferred_contact_ids"))
        |> Enum.uniq()
        |> Enum.sort()
        |> Enum.join("|"),
      "row_derived_reduced_capacity_pack_group_ids_by_status" =>
        reduced_groups
        |> group_row_ids_by_value("pack_status", "contention_group_id")
        |> sort_grouped_values(),
      "row_derived_capacity_pack_contact_ids_by_direction_and_ground_station_id" =>
        contact_ids_by_direction_and_ground_station_id(capacity_rows),
      "model_limit_count" => count(artifact, "model_limits")
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp map_rows(map, key) do
    case Map.get(map, key) do
      rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
      _rows -> []
    end
  end

  defp list_values(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> values
      _values -> []
    end
  end

  defp group_row_ids_by_value(rows, value_key, id_key) do
    rows
    |> Enum.group_by(
      &(Map.get(&1, value_key) || "unknown"),
      &Map.get(&1, id_key)
    )
    |> Map.new(fn {value, ids} ->
      {to_string(value), Enum.reject(ids, &is_nil/1)}
    end)
  end

  defp contact_ids_by_direction_and_ground_station_id(rows) do
    rows
    |> Enum.reject(&(Map.get(&1, "direction") == nil or Map.get(&1, "ground_station_id") == nil))
    |> Enum.group_by(&Map.get(&1, "direction"))
    |> Map.new(fn {direction, direction_rows} ->
      ground_station_map =
        direction_rows
        |> group_row_ids_by_value("ground_station_id", "contact_id")
        |> sort_grouped_values()

      {to_string(direction), ground_station_map}
    end)
  end

  defp capacity_pack_rows(rows) do
    Enum.filter(rows, fn row ->
      Map.get(row, "capacity_pack_status") != nil or
        Map.get(row, "capacity_pack_group_id") != nil or
        Map.get(row, "capacity_pack_capacity_fraction") != nil
    end)
  end

  defp row_value_counts(rows, key) when is_list(rows) do
    rows
    |> Enum.map(&Map.get(&1, key))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
  end

  defp sort_grouped_values(grouped_values) do
    Map.new(grouped_values, fn {key, values} -> {key, Enum.sort(values)} end)
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
