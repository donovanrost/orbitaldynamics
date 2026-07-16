defmodule OrbitalDynamics.Validation.ArtifactObservations.ResourceProjectionReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    projected_resources = map_rows(artifact, "projected_resources")
    flow_rows = Enum.flat_map(projected_resources, &map_rows(&1, "activity_resource_flow"))
    invalid_summary_rows = map_rows(artifact, "invalid_resource_summary_inputs")

    invalid_summary_reason_counts =
      count_rows_by_value(invalid_summary_rows, "invalid_resource_summary_input_reason")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "activity_count" => Map.get(artifact, "activity_count"),
      "input_resource_summary_count" => Map.get(artifact, "input_resource_summary_count"),
      "valid_resource_summary_count" => Map.get(artifact, "valid_resource_summary_count"),
      "invalid_resource_summary_input_count" =>
        Map.get(artifact, "invalid_resource_summary_input_count"),
      "invalid_resource_summary_input_ids" =>
        artifact
        |> list_values("invalid_resource_summary_input_ids")
        |> Enum.join("|"),
      "invalid_resource_summary_input_reasons" =>
        invalid_summary_rows
        |> Enum.map(&Map.get(&1, "invalid_resource_summary_input_reason"))
        |> Enum.reject(&is_nil/1)
        |> Enum.join("|"),
      "stale_battery_state_of_charge_count" =>
        Map.get(invalid_summary_reason_counts, "stale_battery_state_of_charge", 0),
      "stale_storage_margin_count" =>
        Map.get(invalid_summary_reason_counts, "stale_storage_margin", 0),
      "valid_activity_count" => Map.get(artifact, "valid_activity_count"),
      "invalid_activity_input_count" => Map.get(artifact, "invalid_activity_input_count"),
      "projected_resource_count" => length(projected_resources),
      "activity_resource_flow_count" => length(flow_rows),
      "resource_pressure_row_count" =>
        Enum.count(projected_resources, &resource_projection_pressure_row?/1),
      "storage_overflow_row_count" =>
        Enum.count(flow_rows, &positive_number?(&1["storage_overflow_mb"])),
      "downlink_shortfall_row_count" =>
        Enum.count(flow_rows, &positive_number?(&1["downlink_shortfall_mb"])),
      "projected_storage_overflow_mb_total" =>
        sum_numeric(projected_resources, "projected_storage_overflow_mb"),
      "projected_downlink_shortfall_mb_total" =>
        sum_numeric(projected_resources, "projected_downlink_shortfall_mb"),
      "total_battery_energy_consumed_wh" => sum_numeric(flow_rows, "battery_energy_consumed_wh"),
      "total_battery_energy_generated_wh" =>
        sum_numeric(flow_rows, "battery_energy_generated_wh"),
      "net_battery_energy_delta_wh" => sum_numeric(flow_rows, "battery_energy_delta_wh"),
      "peak_battery_overuse_wh" => max_numeric(flow_rows, "battery_overuse_wh"),
      "warning_count" => count(artifact, "warnings"),
      "model_limit_count" => count(artifact, "model_limits"),
      "resource_source_quality_counts" => Map.get(artifact, "resource_source_quality_counts"),
      "resource_trust_boundary_status_counts" =>
        Map.get(artifact, "resource_trust_boundary_status_counts")
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

  defp resource_projection_pressure_row?(row) do
    case Map.get(row, "resource_pressure_types") do
      types when is_list(types) -> types != []
      _types -> false
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

  defp max_numeric(rows, key) do
    rows
    |> Enum.map(&Map.get(&1, key))
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> 0.0
      values -> Enum.max(values)
    end
  end

  defp positive_number?(value), do: is_number(value) and value > 0.0

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
