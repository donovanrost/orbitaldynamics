defmodule OrbitalDynamics.Validation.CampaignArtifactFixtures do
  @moduledoc false

  alias OrbitalDynamics.Validation

  def campaign_plan_fixture_observations do
    artifact =
      "study_results/leo_constellation_campaign.json"
      |> read_json!()
      |> Map.fetch!("campaign_plan")

    Validation.artifact_observations("campaign_plan.v1", artifact)
  end

  def result_artifact_fixture_observations do
    "result_artifact.v1"
    |> Validation.artifact_observations(result_artifact_fixture())
  end

  def result_artifact_fixture do
    read_json!("study_results/leo_constellation_campaign.json")
  end

  def leo_access_result_artifact_fixture_observations do
    "result_artifact.v1"
    |> Validation.artifact_observations(leo_access_result_artifact_fixture())
  end

  def leo_access_result_artifact_fixture do
    read_json!("study_results/leo_access_demo.json")
  end

  def leo_access_manifest_result_artifact_fixture_observations do
    "result_artifact.v1"
    |> Validation.artifact_observations(leo_access_manifest_result_artifact_fixture())
  end

  def leo_access_manifest_result_artifact_fixture do
    read_json!("study_results/leo_access_demo_manifest.json")
  end

  def ground_track_result_artifact_fixture_observations do
    "result_artifact.v1"
    |> Validation.artifact_observations(ground_track_result_artifact_fixture())
  end

  def ground_track_result_artifact_fixture do
    read_json!("study_results/ground_track_crossings.json")
  end

  def raise_apogee_result_artifact_fixture_observations do
    "result_artifact.v1"
    |> Validation.artifact_observations(raise_apogee_result_artifact_fixture())
  end

  def raise_apogee_result_artifact_fixture do
    read_json!("study_results/raise_apogee_search.json")
  end

  def candidate_refresh_result_artifact_fixture_observations do
    "result_artifact.v1"
    |> Validation.artifact_observations(candidate_refresh_result_artifact_fixture())
  end

  def candidate_refresh_result_artifact_fixture do
    read_json!("study_results/candidate_refresh_v1.json")
  end

  def candidate_refresh_orbit_data_result_artifact_fixture_observations do
    "result_artifact.v1"
    |> Validation.artifact_observations(candidate_refresh_orbit_data_result_artifact_fixture())
  end

  def candidate_refresh_orbit_data_result_artifact_fixture do
    read_json!("study_results/candidate_refresh_orbit_data_v1.json")
  end

  def monte_carlo_result_artifact_fixture_observations do
    "result_artifact.v1"
    |> Validation.artifact_observations(monte_carlo_result_artifact_fixture())
  end

  def monte_carlo_result_artifact_fixture do
    read_json!("study_results/leo_dispersion_monte_carlo.json")
  end

  def mission_plan_checkout_result_artifact_fixture_observations do
    "result_artifact.v1"
    |> Validation.artifact_observations(mission_plan_checkout_result_artifact_fixture())
  end

  def mission_plan_checkout_result_artifact_fixture do
    read_json!("study_results/mission_plan_checkout.json")
  end

  def campaign_repair_fixture_observations do
    "study_results/leo_constellation_campaign_repair_v2.json"
    |> read_json!()
    |> then(&Validation.artifact_observations("campaign_repair.v2", &1))
  end

  def campaign_strategy_fixture_observations do
    "study_results/leo_constellation_campaign_strategy_v3.json"
    |> read_json!()
    |> then(&Validation.artifact_observations("campaign_strategy.v3", &1))
  end

  def read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
