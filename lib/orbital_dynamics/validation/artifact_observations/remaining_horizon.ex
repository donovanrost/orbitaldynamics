defmodule OrbitalDynamics.Validation.ArtifactObservations.RemainingHorizon do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "starts_at_s" => Map.get(artifact, "starts_at_s"),
      "ends_at_s" => Map.get(artifact, "ends_at_s"),
      "duration_s" =>
        numeric_delta(Map.get(artifact, "ends_at_s"), Map.get(artifact, "starts_at_s")),
      "output_step_s" => Map.get(artifact, "output_step_s")
    }
  end

  defp numeric_delta(left, right) when is_number(left) and is_number(right), do: left - right
  defp numeric_delta(_left, _right), do: nil

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
