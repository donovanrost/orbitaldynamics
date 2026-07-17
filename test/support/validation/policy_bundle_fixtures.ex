defmodule OrbitalDynamics.Validation.PolicyBundleFixtures do
  @moduledoc false

  alias OrbitalDynamics.Validation

  def policy_bundle_fixture_observations do
    "policy_bundle.v1"
    |> Validation.artifact_observations(policy_bundle_fixture())
  end

  def policy_bundle_fixture do
    read_json!("study_results/policy_bundle_v1.json")
  end

  def ground_network_policy_bundle_fixture_observations do
    "policy_bundle.v1"
    |> Validation.artifact_observations(ground_network_policy_bundle_fixture())
  end

  def ground_network_policy_bundle_fixture do
    read_json!("study_results/policy_bundle_ground_network_allocation_v1.json")
  end

  def operator_review_queue_policy_bundle_fixture_observations do
    "policy_bundle.v1"
    |> Validation.artifact_observations(operator_review_queue_policy_bundle_fixture())
  end

  def operator_review_queue_policy_bundle_fixture do
    read_json!("study_results/policy_bundle_operator_review_queue_authority_v1.json")
  end

  def command_contact_policy_bundle_fixture_observations do
    "policy_bundle.v1"
    |> Validation.artifact_observations(command_contact_policy_bundle_fixture())
  end

  def command_contact_policy_bundle_fixture do
    read_json!("study_results/policy_bundle_command_contact_authority_v1.json")
  end

  def conservative_policy_bundle_fixture_observations do
    "policy_bundle.v1"
    |> Validation.artifact_observations(conservative_policy_bundle_fixture())
  end

  def conservative_policy_bundle_fixture do
    read_json!("study_results/policy_bundle_conservative_ops_v1.json")
  end

  def contact_command_review_policy_bundle_fixture_observations do
    "policy_bundle.v1"
    |> Validation.artifact_observations(contact_command_review_policy_bundle_fixture())
  end

  def contact_command_review_policy_bundle_fixture do
    read_json!("study_results/policy_bundle_contact_command_review_v1.json")
  end

  def default_policy_bundle_fixture_observations do
    "policy_bundle.v1"
    |> Validation.artifact_observations(default_policy_bundle_fixture())
  end

  def default_policy_bundle_fixture do
    read_json!("study_results/policy_bundle_default_v1.json")
  end

  def degraded_payload_guard_policy_bundle_fixture_observations do
    "policy_bundle.v1"
    |> Validation.artifact_observations(degraded_payload_guard_policy_bundle_fixture())
  end

  def degraded_payload_guard_policy_bundle_fixture do
    read_json!("study_results/policy_bundle_degraded_payload_guard_v1.json")
  end

  def maneuver_authority_policy_bundle_fixture_observations do
    "policy_bundle.v1"
    |> Validation.artifact_observations(maneuver_authority_policy_bundle_fixture())
  end

  def maneuver_authority_policy_bundle_fixture do
    read_json!("study_results/policy_bundle_maneuver_authority_v1.json")
  end

  def resource_projection_authority_policy_bundle_fixture_observations do
    "policy_bundle.v1"
    |> Validation.artifact_observations(resource_projection_authority_policy_bundle_fixture())
  end

  def resource_projection_authority_policy_bundle_fixture do
    read_json!("study_results/policy_bundle_resource_projection_authority_v1.json")
  end

  def timeline_protection_policy_bundle_fixture_observations do
    "policy_bundle.v1"
    |> Validation.artifact_observations(timeline_protection_policy_bundle_fixture())
  end

  def timeline_protection_policy_bundle_fixture do
    read_json!("study_results/policy_bundle_timeline_protection_v1.json")
  end

  def organization_adapter_policy_bundle_fixture_observations do
    "policy_bundle.v1"
    |> Validation.artifact_observations(organization_adapter_policy_bundle_fixture())
  end

  def organization_adapter_policy_bundle_fixture do
    read_json!("study_results/policy_bundle_organization_adapter_v1.json")
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
