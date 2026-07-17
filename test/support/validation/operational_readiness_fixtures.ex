defmodule OrbitalDynamics.Validation.OperationalReadinessFixtures do
  alias OrbitalDynamics.Validation

  def operator_review_package_fixture_observations do
    operator_review_package_fixture()
    |> then(&Validation.artifact_observations("operator_review_package.v1", &1))
  end

  def operator_review_package_fixture do
    read_json!("study_results/operator_review_package_v1.json")
  end

  def operational_readiness_report_fixture_observations do
    "operational_readiness_report.v1"
    |> Validation.artifact_observations(operational_readiness_report_fixture())
  end

  def operational_readiness_report_fixture do
    read_json!("study_results/operational_readiness_report_v1.json")
  end

  def operational_execution_boundary_summary_fixture_observations do
    "operational_execution_boundary_summary.v1"
    |> Validation.artifact_observations(operational_execution_boundary_summary_fixture())
  end

  def operational_execution_boundary_summary_fixture do
    read_json!("study_results/operational_execution_boundary_summary_v1.json")
  end

  def operational_import_eligibility_summary_fixture_observations do
    "operational_import_eligibility_summary.v1"
    |> Validation.artifact_observations(operational_import_eligibility_summary_fixture())
  end

  def operational_import_eligibility_summary_fixture do
    read_json!("study_results/operational_import_eligibility_summary_v1.json")
  end

  def operational_readiness_gate_summary_fixture_observations do
    "operational_readiness_gate_summary.v1"
    |> Validation.artifact_observations(operational_readiness_gate_summary_fixture())
  end

  def operational_readiness_gate_summary_fixture do
    read_json!("study_results/operational_readiness_gate_summary_v1.json")
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
