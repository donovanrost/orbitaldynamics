defmodule OrbitalDynamics.Validation.TimelineTransitionFixtures do
  @moduledoc false

  alias OrbitalDynamics.Validation

  def timeline_transition_application_summary_fixture_observations do
    "timeline_transition_application_summary.v1"
    |> Validation.artifact_observations(timeline_transition_application_summary_fixture())
  end

  def timeline_transition_application_summary_fixture do
    read_json!("study_results/timeline_transition_application_summary_v1.json")
  end

  def timeline_transition_application_selected_integrity_summary_fixture_observations do
    "timeline_transition_application_summary.v1"
    |> Validation.artifact_observations(
      timeline_transition_application_selected_integrity_summary_fixture()
    )
  end

  def timeline_transition_application_selected_integrity_summary_fixture do
    read_json!("study_results/timeline_transition_application_selected_integrity_summary_v1.json")
  end

  def timeline_transition_application_report_fixture_observations do
    "timeline_transition_application_report.v1"
    |> Validation.artifact_observations(timeline_transition_application_report_fixture())
  end

  def timeline_transition_application_report_fixture do
    read_json!("study_results/timeline_transition_application_report_v1.json")
  end

  def timeline_transition_application_selected_integrity_fixture_observations do
    "timeline_transition_application_report.v1"
    |> Validation.artifact_observations(
      timeline_transition_application_selected_integrity_fixture()
    )
  end

  def timeline_transition_application_selected_integrity_fixture do
    read_json!("study_results/timeline_transition_application_selected_integrity_v1.json")
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
