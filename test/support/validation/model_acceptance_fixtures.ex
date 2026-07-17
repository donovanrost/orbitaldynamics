defmodule OrbitalDynamics.Validation.ModelAcceptanceFixtures do
  alias OrbitalDynamics.Validation

  def model_acceptance_report_fixture_observations do
    "model_acceptance_report.v1"
    |> Validation.artifact_observations(model_acceptance_report_fixture())
  end

  def model_acceptance_report_fixture do
    Validation.model_acceptance_report(
      [
        "orbit_data.simple_json",
        "event.access_windows",
        "propagator.two_body",
        "missing.model"
      ],
      intended_use: :operational_import
    )
  end

  def validation_safety_case_summary_fixture_observations do
    "validation_safety_case_summary.v1"
    |> Validation.artifact_observations(validation_safety_case_summary_fixture())
  end

  def validation_safety_case_summary_fixture do
    read_json!("study_results/validation_safety_case_summary_v1.json")
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
