defmodule OrbitalDynamics.Validation.ArtifactObservations.AuthorityContext do
  @moduledoc false

  alias OrbitalDynamics.AuthorityContext

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "authority_context_id" => Map.get(artifact, "authority_context_id"),
      "authority_source" => Map.get(artifact, "authority_source"),
      "source_revision" => Map.get(artifact, "source_revision"),
      "effective_from" => Map.get(artifact, "effective_from"),
      "valid_until" => Map.get(artifact, "valid_until"),
      "evaluation_time" => Map.get(artifact, "evaluation_time"),
      "identity_matches_content" =>
        Map.get(artifact, "authority_context_id") == AuthorityContext.identity(artifact),
      "validation_status" => validation_status(artifact)
    }
  end

  defp validation_status(artifact) do
    case AuthorityContext.validate(artifact) do
      {:ok, _context} -> "valid"
      {:error, _failure} -> "invalid"
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
