defmodule OrbitalDynamics.Validation.ActivityArtifactFixtures do
  @moduledoc false

  alias OrbitalDynamics.Validation

  def planned_activity_fixture_observations do
    "planned_activity.v1"
    |> Validation.artifact_observations(planned_activity_fixture())
  end

  def planned_activity_fixture do
    read_json!("study_results/planned_activity_v1.json")
  end

  def activity_template_fixture_observations do
    "activity_template.v1"
    |> Validation.artifact_observations(activity_template_fixture())
  end

  def activity_template_fixture do
    read_json!("study_results/activity_template_v1.json")
  end

  def subsystem_model_capability_fixture_observations do
    "subsystem_model_capability.v1"
    |> Validation.artifact_observations(subsystem_model_capability_fixture())
  end

  def subsystem_model_capability_fixture do
    read_json!("study_results/subsystem_model_capability_v1.json")
  end

  def subsystem_model_capability_storage_fixture_observations do
    "subsystem_model_capability.v1"
    |> Validation.artifact_observations(subsystem_model_capability_storage_fixture())
  end

  def subsystem_model_capability_storage_fixture do
    read_json!("study_results/subsystem_model_capability_storage_v1.json")
  end

  def realized_activity_fixture_observations do
    "realized_activity.v1"
    |> Validation.artifact_observations(realized_activity_fixture())
  end

  def realized_activity_fixture do
    read_json!("study_results/realized_activity_v1.json")
  end

  def plan_delta_fixture_observations do
    "plan_delta.v1"
    |> Validation.artifact_observations(plan_delta_fixture())
  end

  def plan_delta_fixture do
    read_json!("study_results/plan_delta_v1.json")
  end

  def candidate_activity_fixture_observations do
    "candidate_activity.v1"
    |> Validation.artifact_observations(candidate_activity_fixture())
  end

  def candidate_activity_fixture do
    read_json!("study_results/candidate_activity_v1.json")
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
