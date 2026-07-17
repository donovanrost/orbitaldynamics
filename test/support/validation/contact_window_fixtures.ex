defmodule OrbitalDynamics.Validation.ContactWindowFixtures do
  @moduledoc false

  alias OrbitalDynamics.Validation

  def contact_intent_fixture_observations do
    "contact_intent.v1"
    |> Validation.artifact_observations(contact_intent_fixture())
  end

  def contact_intent_fixture do
    read_json!("study_results/contact_intent_v1.json")
  end

  def contact_intent_summary_fixture_observations do
    "contact_intent_summary.v1"
    |> Validation.artifact_observations(contact_intent_summary_fixture())
  end

  def contact_intent_summary_fixture do
    read_json!("study_results/contact_intent_summary_v1.json")
  end

  def refreshed_window_fixture_observations do
    "refreshed_window.v1"
    |> Validation.artifact_observations(refreshed_window_fixture())
  end

  def refreshed_window_fixture do
    read_json!("study_results/refreshed_window_v1.json")
  end

  def source_window_lineage_fixture_observations do
    "source_window_lineage.v1"
    |> Validation.artifact_observations(source_window_lineage_fixture())
  end

  def source_window_lineage_fixture do
    read_json!("study_results/source_window_lineage_v1.json")
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
