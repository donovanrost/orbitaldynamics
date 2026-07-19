defmodule OrbitalDynamics.CadenceImport.SourceIdentifierPolicy do
  @moduledoc false

  def schema_validation_report(report) do
    [
      "schema_validation",
      report["validated_contract"],
      report["validation_mode"],
      report["status"]
    ]
    |> compact_identifier()
  end

  def schema_validation_batch_report(report) do
    [
      "schema_validation_batch",
      report["validation_mode"],
      report["status"]
    ]
    |> compact_identifier()
  end

  def execution_report(report) do
    [
      "execution",
      report["study_id"],
      report["run_id"] || report["status"]
    ]
    |> compact_identifier()
  end

  def result_artifact(artifact) do
    [
      "result_artifact",
      artifact["study_id"],
      get_in(artifact, ["run", "id"]) || get_in(artifact, ["execution_report", "run_id"])
    ]
    |> compact_identifier()
  end

  def manifest(source_artifact_id)
      when is_binary(source_artifact_id) and source_artifact_id != "",
      do: "cadence_import_manifest:#{source_artifact_id}"

  def manifest(_source_artifact_id), do: "cadence_import_manifest:unknown_source"

  def timeline_state(state, source_artifact_id, fallback) do
    source_artifact_id || state["id"] || state["source"] || state["timeline_id"] ||
      state["activity_id"] || fallback
  end

  defp compact_identifier(parts) do
    parts
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(":")
  end
end
