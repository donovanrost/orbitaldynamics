defmodule OrbitalDynamics.Schema.CampaignPlanProvenanceContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [error: 2, expect_optional_type: 5, require_fields: 4]

  @required_fields ["run_id", "manifest", "git_revision", "propagator", "propagator_opts"]
  @string_fields ["run_id", "git_revision", "propagator"]
  @sha256_regex ~r/^[0-9a-f]{64}$/

  def validate(issues, artifact) when is_map(artifact) do
    case Map.get(artifact, "provenance") do
      %{} = provenance -> validate_provenance(issues, provenance)
      _provenance -> issues
    end
  end

  defp validate_provenance(issues, provenance) do
    issues
    |> require_fields("$.provenance", provenance, @required_fields)
    |> validate_string_fields(provenance)
    |> expect_optional_type("$.provenance", provenance, "manifest", :map)
    |> expect_optional_type("$.provenance", provenance, "propagator_opts", :map)
    |> validate_manifest(Map.get(provenance, "manifest"))
  end

  defp validate_string_fields(issues, provenance) do
    Enum.reduce(@string_fields, issues, fn field, acc ->
      acc
      |> expect_optional_type("$.provenance", provenance, field, :binary)
      |> validate_non_empty("$.provenance.#{field}", Map.get(provenance, field))
    end)
  end

  defp validate_manifest(issues, %{} = manifest) do
    issues
    |> expect_optional_type("$.provenance.manifest", manifest, "path", :binary)
    |> expect_optional_type("$.provenance.manifest", manifest, "sha256", :binary)
    |> validate_non_empty("$.provenance.manifest.path", Map.get(manifest, "path"))
    |> validate_sha256(Map.get(manifest, "sha256"))
  end

  defp validate_manifest(issues, _manifest), do: issues

  defp validate_non_empty(issues, path, value) when is_binary(value) do
    if String.trim(value) == "",
      do: [error(path, "must be a non-empty string") | issues],
      else: issues
  end

  defp validate_non_empty(issues, _path, _value), do: issues

  defp validate_sha256(issues, sha256) when is_binary(sha256) do
    if Regex.match?(@sha256_regex, sha256) do
      issues
    else
      [error("$.provenance.manifest.sha256", "must be a lowercase SHA-256 digest") | issues]
    end
  end

  defp validate_sha256(issues, _sha256), do: issues
end
