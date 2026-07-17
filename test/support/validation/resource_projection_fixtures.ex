defmodule OrbitalDynamics.Validation.ResourceProjectionFixtures do
  @moduledoc false

  alias OrbitalDynamics.Validation

  def resource_projection_report_fixture_observations do
    "resource_projection_report.v1"
    |> Validation.artifact_observations(resource_projection_report_fixture())
  end

  def resource_projection_report_fixture do
    read_json!("study_results/resource_projection_report_v1.json")
  end

  def resource_projection_flow_summary_fixture_observations do
    "resource_projection_flow_summary.v1"
    |> Validation.artifact_observations(resource_projection_flow_summary_fixture())
  end

  def resource_projection_flow_summary_fixture do
    read_json!("study_results/resource_projection_flow_summary_v1.json")
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
