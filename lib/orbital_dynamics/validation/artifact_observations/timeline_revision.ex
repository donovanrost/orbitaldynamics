defmodule OrbitalDynamics.Validation.ArtifactObservations.TimelineRevision do
  @moduledoc false

  @revision_prefix "timeline_revision.sha256:"
  @batch_prefix "timeline_transition_batch.sha256:"

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    prior_revision_id = Map.get(artifact, "prior_revision_id")
    transition_batch_id = Map.get(artifact, "transition_batch_id")
    replacement_revision_id = Map.get(artifact, "replacement_revision_id")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "identity_scheme" => Map.get(artifact, "identity_scheme"),
      "canonicalization" => Map.get(artifact, "canonicalization"),
      "prior_revision_id" => prior_revision_id,
      "transition_batch_id" => transition_batch_id,
      "replacement_revision_id" => replacement_revision_id,
      "valid_prior_revision_id" => valid_id?(prior_revision_id, @revision_prefix),
      "valid_transition_batch_id" => valid_id?(transition_batch_id, @batch_prefix),
      "valid_replacement_revision_id" => valid_id?(replacement_revision_id, @revision_prefix),
      "replacement_differs_from_prior" => replacement_revision_id != prior_revision_id
    }
  end

  defp valid_id?(value, prefix) when is_binary(value) do
    String.starts_with?(value, prefix) and byte_size(value) == byte_size(prefix) + 64 and
      value
      |> binary_part(byte_size(prefix), 64)
      |> String.match?(~r/^[0-9a-f]{64}$/)
  end

  defp valid_id?(_value, _prefix), do: false

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
