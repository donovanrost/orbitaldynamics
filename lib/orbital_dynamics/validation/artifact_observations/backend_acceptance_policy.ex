defmodule OrbitalDynamics.Validation.ArtifactObservations.BackendAcceptancePolicy do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "tier_count" => map_size(Map.get(artifact, "acceptance_tiers", %{})),
      "implementation_count" => map_size(Map.get(artifact, "implementation_tiers", %{})),
      "benchmark_case_count" => count(artifact, "benchmark_reference_cases"),
      "reference_backend_count" =>
        count(get_in(artifact, ["reference_backend"]) || %{}, "implementations"),
      "known_limit_count" => count(artifact, "known_limits"),
      "numeric_tolerance_policy" =>
        get_in(artifact, ["comparison_requirements", "numeric_tolerance_policy"]),
      "reference_backend_tier" => get_in(artifact, ["reference_backend", "tier"]),
      "two_body_tier" =>
        get_in(artifact, ["implementation_tiers", "OrbitalDynamics.Propagators.TwoBody"]),
      "two_body_nx_tier" =>
        get_in(artifact, ["implementation_tiers", "OrbitalDynamics.Propagators.TwoBodyNx"]),
      "external_service_requires_provider_policy" =>
        get_in(artifact, [
          "acceptance_tiers",
          "external_service_adapter",
          "requires_provider_policy"
        ])
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
