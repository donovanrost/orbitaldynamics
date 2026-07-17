defmodule OrbitalDynamics.Validation.PolicyEvidenceFixtures do
  @moduledoc false

  alias OrbitalDynamics.Validation

  def backend_acceptance_policy_fixture_observations do
    "backend_acceptance_policy.v1"
    |> Validation.artifact_observations(backend_acceptance_policy_fixture())
  end

  def backend_acceptance_policy_fixture do
    read_json!("study_results/backend_acceptance_policy_v1.json")
  end

  def validation_tolerance_policy_fixture_observations do
    "validation_tolerance_policy.v1"
    |> Validation.artifact_observations(validation_tolerance_policy_fixture())
  end

  def validation_tolerance_policy_fixture do
    read_json!("study_results/validation_tolerance_policy_v1.json")
  end

  def validation_record_fixture_observations do
    "validation_record.v1"
    |> Validation.artifact_observations(validation_record_fixture())
  end

  def validation_record_fixture do
    read_json!("study_results/validation_record_v1.json")
  end

  def validation_check_fixture_observations do
    "validation_check.v1"
    |> Validation.artifact_observations(validation_check_fixture())
  end

  def validation_check_fixture do
    read_json!("study_results/validation_check_v1.json")
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
