defmodule OrbitalDynamics.Schema.CampaignPlanCadenceImportContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation

  def validate(issues, artifact) when is_map(artifact) do
    validate_manifest(issues, artifact, Map.get(artifact, "cadence_import_manifest"))
  end

  defp validate_manifest(issues, _artifact, nil), do: issues
  defp validate_manifest(issues, _artifact, :null), do: issues

  defp validate_manifest(issues, artifact, manifest) when is_map(manifest) do
    issues
    |> validate_equal(
      "$.cadence_import_manifest.source_artifact_type",
      Map.get(manifest, "source_artifact_type"),
      "campaign_plan.v1",
      "must identify campaign_plan.v1"
    )
    |> validate_source_artifact_id(artifact, manifest)
  end

  defp validate_manifest(issues, _artifact, _manifest), do: issues

  defp validate_source_artifact_id(issues, %{"plan_id" => plan_id}, manifest)
       when is_binary(plan_id) and plan_id != "" do
    validate_equal(
      issues,
      "$.cadence_import_manifest.source_artifact_id",
      Map.get(manifest, "source_artifact_id"),
      plan_id,
      "must match the containing campaign plan ID"
    )
  end

  defp validate_source_artifact_id(issues, _artifact, _manifest), do: issues

  defp validate_equal(issues, _path, actual, expected, _message) when actual == expected,
    do: issues

  defp validate_equal(issues, path, _actual, _expected, message),
    do: [PrimitiveValidation.error(path, message) | issues]
end
