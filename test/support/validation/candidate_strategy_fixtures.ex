defmodule OrbitalDynamics.Validation.CandidateStrategyFixtures do
  alias OrbitalDynamics.Validation

  def proposed_contact_fixture_observations do
    "proposed_contact.v1"
    |> Validation.artifact_observations(proposed_contact_fixture())
  end

  def proposed_contact_fixture do
    read_json!("study_results/proposed_contact_v1.json")
  end

  def branch_comparison_report_fixture_observations do
    "branch_comparison_report.v1"
    |> Validation.artifact_observations(branch_comparison_report_fixture())
  end

  def branch_comparison_report_fixture do
    read_json!("study_results/branch_comparison_report_v1.json")
  end

  def optimizer_contract_fixture_observations do
    "optimizer_contract.v1"
    |> Validation.artifact_observations(optimizer_contract_fixture())
  end

  def optimizer_contract_fixture do
    read_json!("study_results/optimizer_contract_v1.json")
  end

  def invalidated_candidate_fixture_observations do
    "invalidated_candidate.v1"
    |> Validation.artifact_observations(invalidated_candidate_fixture())
  end

  def invalidated_candidate_fixture do
    read_json!("study_results/invalidated_candidate_v1.json")
  end

  def strategy_branch_fixture_observations do
    "strategy_branch.v1"
    |> Validation.artifact_observations(strategy_branch_fixture())
  end

  def strategy_branch_fixture do
    read_json!("study_results/strategy_branch_v1.json")
  end

  def strategy_recommendation_fixture_observations do
    "strategy_recommendation.v1"
    |> Validation.artifact_observations(strategy_recommendation_fixture())
  end

  def strategy_recommendation_fixture do
    read_json!("study_results/strategy_recommendation_v1.json")
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
