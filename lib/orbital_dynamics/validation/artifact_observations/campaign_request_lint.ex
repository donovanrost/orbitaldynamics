defmodule OrbitalDynamics.Validation.ArtifactObservations.CampaignRequestLint do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "status" => Map.get(artifact, "status"),
      "validation_mode" => Map.get(artifact, "validation_mode"),
      "request_type" => Map.get(artifact, "type"),
      "lint_task" => Map.get(artifact, "lint_task"),
      "semantic_validator" => Map.get(artifact, "semantic_validator"),
      "error_count" => Map.get(artifact, "error_count"),
      "error_row_count" => count(artifact, "errors"),
      "source_plan_status" => get_in(artifact, ["source_plan", "status"]),
      "source_plan_contract" => get_in(artifact, ["source_plan", "schema_contract"])
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
