defmodule OrbitalDynamics.Validation.CandidateRefreshBaseFixtures do
  alias OrbitalDynamics.Validation

  def candidate_refresh_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_fixture())
  end

  def candidate_refresh_fixture do
    "study_results/candidate_refresh_v1.json"
    |> read_json!()
    |> Map.fetch!("candidate_refresh")
  end

  def candidate_refresh_resource_provenance_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_resource_provenance_fixture())
  end

  def candidate_refresh_resource_provenance_fixture do
    read_json!("study_results/candidate_refresh_resource_provenance_v1.json")
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
