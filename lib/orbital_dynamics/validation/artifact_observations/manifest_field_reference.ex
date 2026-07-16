defmodule OrbitalDynamics.Validation.ArtifactObservations.ManifestFieldReference do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    fields = map_rows(artifact, "fields")
    sections = fields |> Enum.map(&Map.get(&1, "section")) |> Enum.reject(&is_nil/1)

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "schema_version" => Map.get(artifact, "schema_version"),
      "reference_mode" => Map.get(artifact, "reference_mode"),
      "compatibility_policy_version" => Map.get(artifact, "compatibility_policy_version"),
      "identity_policy_version" => Map.get(artifact, "identity_policy_version"),
      "field_count" => Map.get(artifact, "field_count"),
      "field_row_count" => length(fields),
      "required_field_count" => Enum.count(fields, &(Map.get(&1, "required") == true)),
      "array_item_count" => Enum.count(fields, &(Map.get(&1, "array_item") == true)),
      "section_count" => sections |> Enum.uniq() |> length(),
      "top_level_required_count" => count(artifact, "top_level_required"),
      "activation_section_count" => count(artifact, "activation_sections"),
      "supported_output_count" => count(get_in(artifact, ["supported"]) || %{}, "outputs"),
      "supported_propagator_count" =>
        count(get_in(artifact, ["supported"]) || %{}, "propagators"),
      "supported_lint_error_code_count" =>
        count(get_in(artifact, ["supported"]) || %{}, "lint_error_codes"),
      "supported_search_objective_count" =>
        count(get_in(artifact, ["supported"]) || %{}, "search_objectives"),
      "generated_id_scope_count" =>
        count(get_in(artifact, ["identity_policy"]) || %{}, "generated_id_scopes"),
      "semantic_invariant_count" =>
        count(get_in(artifact, ["identity_policy"]) || %{}, "semantic_invariants"),
      "first_field_path" => first_map_value(fields, "path"),
      "last_field_path" =>
        fields
        |> List.last(%{})
        |> Map.get("path"),
      "stable_id_pattern" => get_in(artifact, ["identity_policy", "stable_id_pattern"])
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp first_map_value(rows, key) when is_list(rows) do
    rows
    |> Enum.find(&is_map/1)
    |> then(&if(is_map(&1), do: Map.get(&1, key)))
  end

  defp map_rows(map, key) do
    case Map.get(map, key) do
      rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
      _rows -> []
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
