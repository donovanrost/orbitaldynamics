defmodule OrbitalDynamics.Validation.ArtifactObservations.RelayDataPathSummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "rows")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source" => Map.get(artifact, "source"),
      "route_count" => Map.get(artifact, "route_count"),
      "row_derived_route_count" => length(rows),
      "relay_route_count" => Map.get(artifact, "relay_route_count"),
      "row_derived_relay_route_count" =>
        Enum.count(rows, &(Map.get(&1, "relay_hop_count", 0) > 0)),
      "direct_downlink_route_count" => Map.get(artifact, "direct_downlink_route_count"),
      "row_derived_direct_downlink_route_count" =>
        Enum.count(rows, &(Map.get(&1, "relay_hop_count", 0) == 0)),
      "custody_status_counts" => Map.get(artifact, "custody_status_counts"),
      "row_derived_custody_status_counts" => count_rows_by_value(rows, "custody_status"),
      "latency_status_counts" => Map.get(artifact, "latency_status_counts"),
      "row_derived_latency_status_counts" => count_rows_by_value(rows, "latency_status"),
      "risk_status_counts" => Map.get(artifact, "risk_status_counts"),
      "row_derived_risk_status_counts" => count_rows_by_value(rows, "risk_status"),
      "route_ids" => stable_id_keys(list_values(artifact, "route_ids")),
      "row_derived_route_ids" => stable_row_id_keys(rows, "route_id"),
      "source_spacecraft_ids" => stable_id_keys(list_values(artifact, "source_spacecraft_ids")),
      "row_derived_source_spacecraft_ids" => stable_row_id_keys(rows, "source_spacecraft_id"),
      "relay_spacecraft_ids" => stable_id_keys(list_values(artifact, "relay_spacecraft_ids")),
      "row_derived_relay_spacecraft_ids" =>
        stable_row_list_id_keys(rows, "relay_chain_spacecraft_ids"),
      "ground_station_ids" => stable_id_keys(list_values(artifact, "ground_station_ids")),
      "row_derived_ground_station_ids" => stable_row_id_keys(rows, "ground_station_id"),
      "ground_downlink_contact_ids" =>
        stable_id_keys(list_values(artifact, "ground_downlink_contact_ids")),
      "row_derived_ground_downlink_contact_ids" =>
        stable_row_id_keys(rows, "ground_downlink_contact_id"),
      "route_ids_by_custody_status" =>
        artifact
        |> map_field("route_ids_by_custody_status")
        |> sort_grouped_values(),
      "row_derived_route_ids_by_custody_status" =>
        rows
        |> group_row_ids_by_value("custody_status", "route_id")
        |> sort_grouped_values(),
      "route_ids_by_latency_status" =>
        artifact
        |> map_field("route_ids_by_latency_status")
        |> sort_grouped_values(),
      "row_derived_route_ids_by_latency_status" =>
        rows
        |> group_row_ids_by_value("latency_status", "route_id")
        |> sort_grouped_values(),
      "route_ids_by_risk_status" =>
        artifact
        |> map_field("route_ids_by_risk_status")
        |> sort_grouped_values(),
      "row_derived_route_ids_by_risk_status" =>
        rows
        |> group_row_ids_by_value("risk_status", "route_id")
        |> sort_grouped_values(),
      "route_ids_by_ground_station_id" =>
        artifact
        |> map_field("route_ids_by_ground_station_id")
        |> sort_grouped_values(),
      "row_derived_route_ids_by_ground_station_id" =>
        rows
        |> group_row_ids_by_value("ground_station_id", "route_id")
        |> sort_grouped_values(),
      "maximum_latency_s" => Map.get(artifact, "maximum_latency_s"),
      "row_derived_maximum_latency_s" => max_numeric(rows, "latency_s"),
      "maximum_latency_limit_s" => Map.get(artifact, "maximum_latency_limit_s"),
      "row_derived_maximum_latency_limit_s" => max_numeric(rows, "latency_limit_s"),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "custody_acknowledgement_delivery" =>
        get_in(artifact, ["assumptions", "custody_acknowledgement_delivery"]),
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

  defp map_field(map, key) do
    case Map.get(map, key) do
      value when is_map(value) -> value
      _value -> %{}
    end
  end

  defp list_values(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> values
      _values -> []
    end
  end

  defp stable_id_keys(values) when is_list(values) do
    values
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.join("|")
  end

  defp stable_row_id_keys(rows, key) do
    rows
    |> Enum.map(&Map.get(&1, key))
    |> Enum.reject(&is_nil/1)
    |> stable_id_keys()
  end

  defp stable_row_list_id_keys(rows, key) do
    rows
    |> Enum.flat_map(&List.wrap(Map.get(&1, key)))
    |> Enum.reject(&is_nil/1)
    |> stable_id_keys()
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

  defp sort_grouped_values(grouped_values) do
    Map.new(grouped_values, fn {key, values} -> {key, Enum.sort(values)} end)
  end

  defp count_rows_by_value(rows, key) do
    rows
    |> Enum.map(&(Map.get(&1, key) || "unknown"))
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
  end

  defp max_numeric(rows, key) do
    rows
    |> Enum.map(&Map.get(&1, key))
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> 0.0
      values -> Enum.max(values)
    end
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
