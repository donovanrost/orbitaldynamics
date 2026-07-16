defmodule OrbitalDynamics.Validation.ArtifactObservations.RealizedStateSnapshot do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    activities = map_rows(artifact, "activities")
    model_limits = list_values(artifact, "model_limits")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "activity_count" => length(activities),
      "spacecraft_state_count" => count(artifact, "spacecraft_states"),
      "status_counts" => count_rows_by_value(activities, "status"),
      "type_counts" => count_rows_by_value(activities, "type"),
      "degraded_count" => Enum.count(activities, &(Map.get(&1, "degraded") == true)),
      "contact_failure_count" =>
        Enum.count(activities, &(Map.get(&1, "contact_success") == false)),
      "total_planned_data_volume_mb" => sum_numeric(activities, "planned_data_volume_mb"),
      "total_actual_data_volume_mb" => sum_numeric(activities, "actual_data_volume_mb"),
      "snapshot_id" => get_in(artifact, ["metadata", "snapshot_id"]),
      "feedback_boundary" => get_in(artifact, ["metadata", "feedback_boundary"]),
      "provider" => get_in(artifact, ["metadata", "provider"]),
      "adapter" => get_in(artifact, ["metadata", "adapter"]),
      "adapter_version" => get_in(artifact, ["metadata", "adapter_version"]),
      "trust_boundary" => get_in(artifact, ["metadata", "trust_boundary"]),
      "no_schedule_mutation" => "no_schedule_mutation" in model_limits,
      "model_limit_count" => length(model_limits)
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp list_values(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> values
      _values -> []
    end
  end

  defp map_rows(map, key) do
    case Map.get(map, key) do
      rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
      _rows -> []
    end
  end

  defp count_rows_by_value(rows, key) when is_list(rows) do
    rows
    |> Enum.map(&Map.get(&1, key))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
  end

  defp sum_numeric(rows, key) when is_list(rows) do
    rows
    |> Enum.map(&Map.get(&1, key))
    |> Enum.filter(&is_number/1)
    |> Enum.sum()
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
