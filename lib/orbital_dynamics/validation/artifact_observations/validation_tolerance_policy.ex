defmodule OrbitalDynamics.Validation.ArtifactObservations.ValidationTolerancePolicy do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "validation_level_count" => map_size(Map.get(artifact, "validation_levels", %{})),
      "comparison_model_count" => map_size(Map.get(artifact, "comparison_model", %{})),
      "event_timing_key_count" => map_size(Map.get(artifact, "event_timing", %{})),
      "artifact_regression_limit" => get_in(artifact, ["artifact_regressions", "limit"]),
      "artifact_regression_scope" => get_in(artifact, ["artifact_regressions", "scope"]),
      "current_event_timing_policy" => get_in(artifact, ["event_timing", "current_policy"]),
      "validated_level_description" => get_in(artifact, ["validation_levels", "validated"])
    }
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
