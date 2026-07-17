defmodule OrbitalDynamics.Validation.ResourceSummaryFixtures do
  @moduledoc false

  alias OrbitalDynamics.Validation

  def resource_summary_fixture_observations do
    "resource_summary.v1"
    |> Validation.artifact_observations(resource_summary_fixture())
  end

  def resource_summary_fixture do
    read_json!("study_results/resource_summary_v1.json")
  end

  def resource_filter_report_fixture_observations do
    "resource_filter_report.v1"
    |> Validation.artifact_observations(resource_filter_report_fixture())
  end

  def resource_filter_report_fixture do
    read_json!("study_results/resource_filter_report_v1.json")
  end

  def resource_filter_summary_fixture_observations do
    "resource_filter_summary.v1"
    |> Validation.artifact_observations(resource_filter_summary_fixture())
  end

  def resource_filter_summary_fixture do
    read_json!("study_results/resource_filter_summary_v1.json")
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
