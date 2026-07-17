defmodule OrbitalDynamics.Validation.LinkCapacityFixtures do
  @moduledoc false

  alias OrbitalDynamics.Validation

  def link_capacity_report_fixture_observations do
    "link_capacity_report.v1"
    |> Validation.artifact_observations(link_capacity_report_fixture())
  end

  def link_capacity_report_fixture do
    read_json!("study_results/link_capacity_report_v1.json")
  end

  def link_capacity_summary_fixture_observations do
    "link_capacity_summary.v1"
    |> Validation.artifact_observations(link_capacity_summary_fixture())
  end

  def link_capacity_summary_fixture do
    read_json!("study_results/link_capacity_summary_v1.json")
  end

  def relay_data_path_summary_fixture_observations do
    "relay_data_path_summary.v1"
    |> Validation.artifact_observations(relay_data_path_summary_fixture())
  end

  def relay_data_path_summary_fixture do
    read_json!("study_results/relay_data_path_summary_v1.json")
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
