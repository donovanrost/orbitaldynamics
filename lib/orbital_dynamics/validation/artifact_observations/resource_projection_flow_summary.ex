defmodule OrbitalDynamics.Validation.ArtifactObservations.ResourceProjectionFlowSummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    projected_resources = map_rows(artifact, "projected_resources")
    flow_rows = map_rows(artifact, "activity_resource_flow")
    ignored_flow_rows = Enum.filter(flow_rows, &(&1["resource_effect_status"] == "ignored"))

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source" => Map.get(artifact, "source"),
      "activity_count" => Map.get(artifact, "activity_count"),
      "valid_activity_count" => Map.get(artifact, "valid_activity_count"),
      "invalid_activity_input_count" => count(artifact, "invalid_activity_inputs"),
      "input_resource_summary_count" => Map.get(artifact, "input_resource_summary_count"),
      "valid_resource_summary_count" => Map.get(artifact, "valid_resource_summary_count"),
      "invalid_resource_summary_input_count" =>
        count(artifact, "invalid_resource_summary_inputs"),
      "projected_resource_count" => length(projected_resources),
      "flow_row_count" => length(flow_rows),
      "resource_flow_status" => Map.get(artifact, "resource_flow_status"),
      "resource_pressure_status" => Map.get(artifact, "resource_pressure_status"),
      "resource_pressure_count" => count(artifact, "resource_pressure_types"),
      "total_storage_produced_mb" => sum_numeric(flow_rows, "storage_produced_mb"),
      "total_storage_limited_downlinked_mb" => sum_numeric(flow_rows, "downlinked_mb"),
      "total_downlink_shortfall_mb" => sum_numeric(flow_rows, "downlink_shortfall_mb"),
      "total_unused_downlink_capacity_mb" =>
        sum_numeric(projected_resources, "unused_downlink_capacity_mb"),
      "total_battery_energy_consumed_wh" => sum_numeric(flow_rows, "battery_energy_consumed_wh"),
      "total_battery_energy_generated_wh" =>
        sum_numeric(flow_rows, "battery_energy_generated_wh"),
      "net_battery_energy_delta_wh" => sum_numeric(flow_rows, "battery_energy_delta_wh"),
      "peak_battery_overuse_wh" => max_numeric(flow_rows, "battery_overuse_wh"),
      "total_projected_storage_remaining_mb" =>
        sum_numeric(projected_resources, "projected_storage_remaining_mb"),
      "minimum_projected_storage_remaining_mb" =>
        min_numeric(projected_resources, "projected_storage_remaining_mb"),
      "total_projected_downlink_remaining_mb" =>
        sum_numeric(projected_resources, "projected_downlink_remaining_mb"),
      "minimum_projected_downlink_remaining_mb" =>
        min_numeric(projected_resources, "projected_downlink_remaining_mb"),
      "ignored_activity_count" => length(ignored_flow_rows),
      "ignored_activity_reason_counts" =>
        count_rows_by_value(ignored_flow_rows, "resource_effect_reason"),
      "resource_pressure_types" => list_values(artifact, "resource_pressure_types"),
      "model_limit_count" => count(artifact, "model_limits"),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"])
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

  defp count_rows_by_value(rows, key) do
    rows
    |> Enum.map(&(Map.get(&1, key) || "unknown"))
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
  end

  defp sum_numeric(rows, key) do
    rows
    |> Enum.map(&Map.get(&1, key))
    |> Enum.filter(&is_number/1)
    |> Enum.sum()
  end

  defp min_numeric(rows, key) do
    rows
    |> Enum.map(&Map.get(&1, key))
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.min(values)
    end
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
