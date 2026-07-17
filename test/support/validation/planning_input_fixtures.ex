defmodule OrbitalDynamics.Validation.PlanningInputFixtures do
  alias OrbitalDynamics.{Environment, Validation}

  def campaign_request_lint_fixture_observations do
    "campaign_request_lint.v1"
    |> Validation.artifact_observations(campaign_request_lint_fixture())
  end

  def campaign_request_lint_fixture do
    read_json!("study_results/campaign_request_lint_v1.json")
  end

  def capability_catalog_fixture_observations do
    "capability_catalog.v1"
    |> Validation.artifact_observations(capability_catalog_fixture())
  end

  def capability_catalog_fixture do
    read_json!("study_results/capability_catalog_v1.json")
  end

  def environment_model_capability_fixed_sun_fixture_observations do
    "environment_model_capability.v1"
    |> Validation.artifact_observations(
      environment_model_capability_fixture("environment.solar.fixed_inertial_direction")
    )
  end

  def environment_model_capability_constant_earth_rotation_fixture_observations do
    "environment_model_capability.v1"
    |> Validation.artifact_observations(
      environment_model_capability_fixture("environment.earth_rotation.constant_rate")
    )
  end

  def environment_model_capability_fixture(id) do
    Environment.model_capabilities()
    |> Enum.find(&(Map.get(&1, "id") == id))
  end

  def environment_provider_capability_fixed_sun_fixture_observations do
    "environment_provider_capability.v1"
    |> Validation.artifact_observations(
      environment_provider_capability_fixture(
        "environment.provider.solar.fixed_inertial_direction"
      )
    )
  end

  def environment_provider_capability_constant_earth_rotation_fixture_observations do
    "environment_provider_capability.v1"
    |> Validation.artifact_observations(
      environment_provider_capability_fixture("environment.provider.earth_rotation.constant_rate")
    )
  end

  def environment_provider_capability_tabular_earth_orientation_fixture_observations do
    "environment_provider_capability.v1"
    |> Validation.artifact_observations(
      environment_provider_capability_fixture(
        "environment.provider.earth_orientation.tabular_rotation"
      )
    )
  end

  def environment_provider_capability_exponential_atmosphere_fixture_observations do
    "environment_provider_capability.v1"
    |> Validation.artifact_observations(
      environment_provider_capability_fixture(
        "environment.provider.atmosphere.exponential_reference"
      )
    )
  end

  def environment_provider_capability_fixture(id) do
    Environment.provider_capabilities()
    |> Enum.find(&(Map.get(&1, "id") == id))
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
