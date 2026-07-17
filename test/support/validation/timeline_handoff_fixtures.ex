defmodule OrbitalDynamics.Validation.TimelineHandoffFixtures do
  @moduledoc false

  alias OrbitalDynamics.Validation

  def timeline_diff_report_fixture_observations do
    "timeline_diff_report.v1"
    |> Validation.artifact_observations(timeline_diff_report_fixture())
  end

  def timeline_diff_report_fixture do
    read_json!("study_results/timeline_diff_report_v1.json")
  end

  def timeline_feedback_report_fixture_observations do
    "timeline_feedback_report.v1"
    |> Validation.artifact_observations(timeline_feedback_report_fixture())
  end

  def timeline_feedback_report_fixture do
    read_json!("study_results/timeline_feedback_report_v1.json")
  end

  def cadence_import_manifest_fixture_observations do
    "cadence_import_manifest.v1"
    |> Validation.artifact_observations(cadence_import_manifest_fixture())
  end

  def cadence_import_manifest_fixture do
    read_json!("study_results/cadence_import_manifest_v1.json")
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
