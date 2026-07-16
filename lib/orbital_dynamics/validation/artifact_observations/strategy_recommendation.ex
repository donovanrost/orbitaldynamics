defmodule OrbitalDynamics.Validation.ArtifactObservations.StrategyRecommendation do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    explanation_rows = map_rows(artifact, "explanation")

    branch_summary_rows =
      Enum.filter(explanation_rows, &(Map.get(&1, "type") == "branch_event_summary"))

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "status" => Map.get(artifact, "status"),
      "recommended_branch_id" => Map.get(artifact, "recommended_branch_id"),
      "approval_status" => Map.get(artifact, "approval_status"),
      "reason" => Map.get(artifact, "reason"),
      "ranked_branch_count" => count(artifact, "ranked_branch_ids"),
      "ranked_branch_id_order" =>
        artifact
        |> list_values("ranked_branch_ids")
        |> Enum.join("|"),
      "tradeoff_count" => count(artifact, "tradeoffs"),
      "explanation_count" => length(explanation_rows),
      "risk_count" => count(artifact, "risks_remaining"),
      "approval_requirement_count" => count(artifact, "requires_approval"),
      "requires_operator_review_count" =>
        artifact
        |> map_rows("requires_approval")
        |> Enum.count(&(Map.get(&1, "policy_classification") == "operator_review_required")),
      "branch_event_summary_count" => length(branch_summary_rows),
      "branch_event_type_counts" =>
        branch_summary_rows
        |> Enum.flat_map(&list_values(&1, "branch_event_types"))
        |> list_value_counts(),
      "branch_requires_operator_review" =>
        branch_summary_rows
        |> List.first(%{})
        |> Map.get("branch_requires_operator_review")
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

  defp list_value_counts(values) when is_list(values) do
    values
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
  end

  defp list_value_counts(_values), do: %{}

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
