defmodule OrbitalDynamics.Validation.ArtifactObservations.PolicyBundle do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rules = map_rows(get_in(artifact, ["approval_policy"]) || %{}, "action_rules")
    model_limits = list_values(artifact, "model_limits")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "id" => Map.get(artifact, "id"),
      "action_rule_count" => length(rules),
      "blocked_risk_type_count" =>
        count(get_in(artifact, ["approval_policy"]) || %{}, "blocked_risk_types"),
      "auto_approvable_approval_count_limit" =>
        get_in(artifact, ["approval_policy", "auto_approvable_approval_count_limit"]),
      "auto_approvable_risk_limit" =>
        get_in(artifact, ["approval_policy", "auto_approvable_risk_limit"]),
      "operator_review_risk_limit" =>
        get_in(artifact, ["approval_policy", "operator_review_risk_limit"]),
      "classification_counts" => count_rows_by_value(rules, "classification"),
      "required_authority_counts" => count_rows_by_value(rules, "required_authority"),
      "escalation_queue_counts" => count_rows_by_value(rules, "escalation_queue"),
      "station_availability_rule_count" => count_rows_with_key(rules, "station_availabilities"),
      "reduced_capacity_rule_count" =>
        count_rows_with_list_value(rules, "station_availabilities", "reduced_capacity"),
      "unavailable_or_maintenance_rule_count" =>
        Enum.count(
          rules,
          &(list_value?(&1, "station_availabilities", "unavailable") or
              list_value?(&1, "station_availabilities", "maintenance"))
        ),
      "contention_rule_count" =>
        count_rows_with_list_value(rules, "activity_types", "contact_contention"),
      "contact_allocation_rule_count" =>
        count_rows_with_list_value(rules, "activity_types", "contact_allocation"),
      "required_operator_action_rule_count" =>
        count_rows_with_key(rules, "required_operator_actions"),
      "command_direction_rule_count" =>
        count_rows_with_list_value(rules, "station_calendar_directions", "command"),
      "missing_trust_rule_count" =>
        Enum.count(rules, &(Map.get(&1, "station_calendar_trust_boundary_status") == "missing")),
      "rule_ids_by_classification" =>
        rules
        |> group_row_ids_by_value("classification", "id")
        |> sort_grouped_values(),
      "boundary" => get_in(artifact, ["assumptions", "boundary"]),
      "workflow_execution" => get_in(artifact, ["assumptions", "workflow_execution"]),
      "provenance_source" => get_in(artifact, ["provenance", "source"]),
      "no_command_execution" => "no_command_execution" in model_limits,
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

  defp count_rows_by_value(rows, key) do
    rows
    |> Enum.map(&(Map.get(&1, key) || "unknown"))
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
  end

  defp count_rows_with_key(rows, key) do
    Enum.count(rows, &Map.has_key?(&1, key))
  end

  defp count_rows_with_list_value(rows, key, value) do
    Enum.count(rows, &list_value?(&1, key, value))
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

  defp list_value?(row, key, value) do
    case Map.get(row, key) do
      values when is_list(values) -> value in values
      _values -> false
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

  defp sort_grouped_values(grouped_values) do
    Map.new(grouped_values, fn {key, values} -> {key, Enum.sort(values)} end)
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
