defmodule OrbitalDynamics.Validation.ManifestFixtures do
  alias OrbitalDynamics.Validation

  def manifest_field_reference_fixture_observations do
    "manifest_field_reference.v1"
    |> Validation.artifact_observations(manifest_field_reference_fixture())
  end

  def manifest_field_reference_fixture do
    read_json!("study_results/manifest_field_reference.json")
  end

  def study_manifest_lint_fixture_observations do
    "study_manifest_lint.v1"
    |> Validation.artifact_observations(study_manifest_lint_fixture())
  end

  def study_manifest_lint_fixture do
    read_json!("study_results/study_manifest_lint_v1.json")
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
