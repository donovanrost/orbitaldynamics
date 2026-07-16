defmodule OrbitalDynamics.Validation.ArtifactObservations.StudyManifestLint do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    outputs = list_values(artifact, "outputs")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "schema_version" => Map.get(artifact, "schema_version"),
      "manifest_schema_contract" => Map.get(artifact, "manifest_schema_contract"),
      "status" => Map.get(artifact, "status"),
      "study_id" => Map.get(artifact, "study_id"),
      "validation_mode" => Map.get(artifact, "validation_mode"),
      "error_count" => Map.get(artifact, "error_count"),
      "warning_count" => Map.get(artifact, "warning_count"),
      "scenario_count" => Map.get(artifact, "scenario_count"),
      "output_count" => length(outputs),
      "first_output" => List.first(outputs),
      "last_output" => List.last(outputs),
      "supported_output_count" => count(get_in(artifact, ["supported"]) || %{}, "outputs"),
      "supported_propagator_count" =>
        count(get_in(artifact, ["supported"]) || %{}, "propagators"),
      "supported_lint_error_code_count" =>
        count(get_in(artifact, ["supported"]) || %{}, "lint_error_codes"),
      "supported_search_objective_count" =>
        count(get_in(artifact, ["supported"]) || %{}, "search_objectives"),
      "manifest_path" => get_in(artifact, ["manifest", "path"]),
      "lint_task" => Map.get(artifact, "lint_task"),
      "semantic_validator" => Map.get(artifact, "semantic_validator")
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
      _value -> []
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
