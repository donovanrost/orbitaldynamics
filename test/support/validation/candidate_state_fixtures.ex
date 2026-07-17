defmodule OrbitalDynamics.Validation.CandidateStateFixtures do
  alias OrbitalDynamics.Validation

  def candidate_rejection_report_fixture_observations do
    "candidate_rejection_report.v1"
    |> Validation.artifact_observations(candidate_rejection_report_fixture())
  end

  def candidate_rejection_report_fixture do
    read_json!("study_results/candidate_rejection_report_v1.json")
  end

  def candidate_diff_row_fixture_observations do
    "candidate_diff_row.v1"
    |> Validation.artifact_observations(candidate_diff_row_fixture())
  end

  def candidate_diff_row_fixture do
    read_json!("study_results/candidate_diff_row_v1.json")
  end

  def accepted_planning_state_fixture_observations do
    "accepted_planning_state.v1"
    |> Validation.artifact_observations(accepted_planning_state_fixture())
  end

  def accepted_planning_state_fixture do
    read_json!("study_results/accepted_planning_state_simple.json")
  end

  def accepted_planning_state_opm_fixture_observations do
    "accepted_planning_state.v1"
    |> Validation.artifact_observations(accepted_planning_state_opm_fixture())
  end

  def accepted_planning_state_opm_fixture do
    read_json!("study_results/accepted_planning_state_opm.json")
  end

  def accepted_planning_state_oem_fixture_observations do
    "accepted_planning_state.v1"
    |> Validation.artifact_observations(accepted_planning_state_oem_fixture())
  end

  def accepted_planning_state_oem_fixture do
    read_json!("study_results/accepted_planning_state_oem.json")
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
