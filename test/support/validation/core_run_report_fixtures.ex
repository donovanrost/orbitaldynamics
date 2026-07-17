defmodule OrbitalDynamics.Validation.CoreRunReportFixtures do
  alias OrbitalDynamics.Validation

  def validation_reference_report_fixture_observations do
    "validation_reference_report.v1"
    |> Validation.artifact_observations(validation_reference_report_fixture())
  end

  def validation_reference_report_fixture do
    read_json!("study_results/validation_reference_report_v1.json")
  end

  def candidate_diff_report_fixture_observations do
    "candidate_diff_report.v1"
    |> Validation.artifact_observations(candidate_diff_report_fixture())
  end

  def candidate_diff_report_fixture do
    read_json!("study_results/candidate_diff_report_v1.json")
  end

  def refresh_budget_report_fixture_observations do
    "refresh_budget_report.v1"
    |> Validation.artifact_observations(refresh_budget_report_fixture())
  end

  def refresh_budget_report_fixture do
    read_json!("study_results/refresh_budget_report_v1.json")
  end

  def execution_report_fixture_observations do
    "execution_report.v1"
    |> Validation.artifact_observations(execution_report_fixture())
  end

  def execution_report_fixture do
    read_json!("study_results/execution_report_v1.json")
  end

  def freshness_report_fixture_observations do
    "freshness_report.v1"
    |> Validation.artifact_observations(freshness_report_fixture())
  end

  def freshness_report_fixture do
    read_json!("study_results/freshness_report_v1.json")
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
