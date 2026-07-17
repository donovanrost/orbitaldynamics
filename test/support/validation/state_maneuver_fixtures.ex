defmodule OrbitalDynamics.Validation.StateManeuverFixtures do
  @moduledoc false

  alias OrbitalDynamics.Validation

  def spacecraft_state_estimate_fixture_observations do
    "spacecraft_state_estimate.v1"
    |> Validation.artifact_observations(spacecraft_state_estimate_fixture())
  end

  def spacecraft_state_estimate_fixture do
    read_json!("study_results/spacecraft_state_estimate_v1.json")
  end

  def realized_state_snapshot_fixture_observations do
    "realized_state_snapshot.v1"
    |> Validation.artifact_observations(realized_state_snapshot_fixture())
  end

  def realized_state_snapshot_fixture do
    read_json!("study_results/realized_state_snapshot_v1.json")
  end

  def remaining_horizon_fixture_observations do
    "remaining_horizon.v1"
    |> Validation.artifact_observations(remaining_horizon_fixture())
  end

  def remaining_horizon_fixture do
    read_json!("study_results/remaining_horizon_v1.json")
  end

  def maneuver_execution_delta_fixture_observations do
    "maneuver_execution_delta.v1"
    |> Validation.artifact_observations(maneuver_execution_delta_fixture())
  end

  def maneuver_execution_delta_fixture do
    read_json!("study_results/maneuver_execution_delta_v1.json")
  end

  def maneuver_recommendation_fixture_observations do
    "maneuver_recommendation.v1"
    |> Validation.artifact_observations(maneuver_recommendation_fixture())
  end

  def maneuver_recommendation_fixture do
    read_json!("study_results/maneuver_recommendation_v1.json")
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
