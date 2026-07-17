defmodule OrbitalDynamics.Validation.ResourcePressureHandoffFixtures do
  alias OrbitalDynamics.Validation

  import OrbitalDynamics.Validation.CandidateRefreshReadinessReplayFixtures,
    only: [
      operational_readiness_resource_pressure_fixture: 0,
      quality_gate_resource_pressure_fixture: 0
    ]

  def cadence_import_resource_pressure_fixture_observations do
    "cadence_import_manifest.v1"
    |> Validation.artifact_observations(cadence_import_resource_pressure_fixture())
  end

  def cadence_import_resource_pressure_fixture do
    read_json!("study_results/cadence_import_resource_pressure_v1.json")
  end

  def operator_review_resource_pressure_fixture_observations do
    "operator_review_package.v1"
    |> Validation.artifact_observations(operator_review_resource_pressure_fixture())
  end

  def operator_review_resource_pressure_fixture do
    read_json!("study_results/operator_review_resource_pressure_v1.json")
  end

  def operational_readiness_resource_pressure_fixture_observations do
    "operational_readiness_report.v1"
    |> Validation.artifact_observations(operational_readiness_resource_pressure_fixture())
  end

  def quality_gate_resource_pressure_fixture_observations do
    "quality_gate_report.v1"
    |> Validation.artifact_observations(quality_gate_resource_pressure_fixture())
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
