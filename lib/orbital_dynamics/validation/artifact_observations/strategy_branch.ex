defmodule OrbitalDynamics.Validation.ArtifactObservations.StrategyBranch do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    events = map_rows(artifact, "events")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "branch_id" => Map.get(artifact, "branch_id"),
      "label" => Map.get(artifact, "label"),
      "probability" => Map.get(artifact, "probability"),
      "event_count" => length(events),
      "event_type_counts" => count_rows_by_value(events, "type"),
      "candidate_activity_count" =>
        count(get_in(artifact, ["candidate_plan"]) || %{}, "activities"),
      "strategic_addition_count" =>
        count(get_in(artifact, ["candidate_plan"]) || %{}, "strategic_additions"),
      "capacity_adjustment_count" =>
        count(get_in(artifact, ["candidate_plan"]) || %{}, "capacity_adjustments"),
      "repair_delta_count" => count(get_in(artifact, ["repair_result"]) || %{}, "deltas"),
      "approval_requirement_count" => count(artifact, "approval_requirements"),
      "policy_classification" => get_in(artifact, ["policy_decision", "classification"]),
      "policy_risk_count" => get_in(artifact, ["policy_decision", "risk_count"]),
      "score" => Map.get(artifact, "score"),
      "score_term_count" => count_collection(artifact, "score_terms"),
      "warning_count" => count(artifact, "warnings"),
      "risk_count" => count(artifact, "risk_indicators"),
      "approval_status" => Map.get(artifact, "approval_status"),
      "derived_source" => Map.get(artifact, "derived_source"),
      "tradeoff_count" => count(artifact, "tradeoffs"),
      "downlink_capacity_margin" =>
        get_in(artifact, ["resource_impacts", "downlink_capacity_margin"])
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp count_collection(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      values when is_map(values) -> map_size(values)
      _value -> 0
    end
  end

  defp map_rows(map, key) do
    case Map.get(map, key) do
      rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
      _rows -> []
    end
  end

  defp count_rows_by_value(rows, key) do
    rows
    |> Enum.map(&(Map.get(&1, key) || "unknown"))
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
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
