defmodule OrbitalDynamics.OperationalReadiness.SourceIdentity do
  @moduledoc false

  def artifact_type(artifact, review_package, import_manifest) do
    cond do
      artifact["schema_contract"] == "cadence_import_manifest.v1" ->
        artifact["source_artifact_type"]

      artifact["schema_contract"] == "operator_review_package.v1" ->
        artifact["source_artifact_type"]

      is_map(import_manifest) ->
        import_manifest["source_artifact_type"] || artifact["schema_contract"]

      is_map(review_package) ->
        review_package["source_artifact_type"] || artifact["schema_contract"]

      true ->
        artifact["schema_contract"]
    end
  end

  def artifact_id(artifact, review_package, import_manifest) do
    cond do
      artifact["schema_contract"] == "cadence_import_manifest.v1" ->
        artifact["source_artifact_id"] || artifact["manifest_id"]

      artifact["schema_contract"] == "operator_review_package.v1" ->
        artifact["source_artifact_id"] || artifact["package_id"]

      is_map(import_manifest) ->
        import_manifest["source_artifact_id"] || artifact["id"] || artifact["report_id"]

      is_map(review_package) ->
        review_package["source_artifact_id"] || artifact["id"] || artifact["report_id"]

      true ->
        artifact["id"] || artifact["report_id"]
    end
  end

  def readiness_report_id(source_artifact_type, source_artifact_id) do
    ["operational_readiness", source_artifact_type, source_artifact_id || "unknown"]
    |> stable_id()
  end

  def quality_gate_report_id(source_artifact_type, source_artifact_id) do
    ["quality_gate", source_artifact_type, source_artifact_id || "unknown"]
    |> stable_id()
  end

  def quality_gate_row_id(source_artifact_type, source_artifact_id, gate_id, rank) do
    ["quality_gate", source_artifact_type, source_artifact_id || "unknown", gate_id, rank]
    |> stable_id()
  end

  defp stable_id(parts) do
    parts
    |> Enum.map(&stable_id_fragment/1)
    |> Enum.join(":")
  end

  defp stable_id_fragment(value) do
    value
    |> encode_value()
    |> to_string()
    |> String.replace(~r/[^A-Za-z0-9._:@-]/, "_")
    |> String.trim("_")
    |> case do
      "" -> "unknown"
      fragment -> fragment
    end
  end

  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(:null), do: nil
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
