defmodule OrbitalDynamics.Validation.PolicyDecisionFixtures do
  alias OrbitalDynamics.Validation

  def approval_requirement_fixture_observations do
    "approval_requirement.v1"
    |> Validation.artifact_observations(approval_requirement_fixture())
  end

  def approval_requirement_fixture do
    read_json!("study_results/approval_requirement_v1.json")
  end

  def policy_decision_fixture_observations do
    "policy_decision.v1"
    |> Validation.artifact_observations(policy_decision_fixture())
  end

  def policy_decision_fixture do
    read_json!("study_results/policy_decision_v1.json")
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
