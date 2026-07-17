defmodule OrbitalDynamics.Validation.ObjectiveScoringFixtures do
  @moduledoc false

  alias OrbitalDynamics.Validation

  def objective_satisfaction_report_fixture_observations do
    "objective_satisfaction_report.v1"
    |> Validation.artifact_observations(objective_satisfaction_report_fixture())
  end

  def objective_satisfaction_report_fixture do
    read_json!("study_results/objective_satisfaction_report_v1.json")
  end

  def objective_tradeoff_report_fixture_observations do
    "objective_tradeoff_report.v1"
    |> Validation.artifact_observations(objective_tradeoff_report_fixture())
  end

  def objective_tradeoff_report_fixture do
    read_json!("study_results/objective_tradeoff_report_v1.json")
  end

  def score_term_report_fixture_observations do
    "score_term_report.v1"
    |> Validation.artifact_observations(score_term_report_fixture())
  end

  def score_term_report_fixture do
    read_json!("study_results/score_term_report_v1.json")
  end

  def campaign_plan_score_term_report_fixture do
    "study_results/leo_constellation_campaign.json"
    |> read_json!()
    |> get_in(["campaign_plan", "score_term_report"])
  end

  def ranking_comparison_report_fixture_observations do
    "ranking_comparison_report.v1"
    |> Validation.artifact_observations(ranking_comparison_report_fixture())
  end

  def ranking_comparison_report_fixture do
    read_json!("study_results/ranking_comparison_report_v1.json")
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
