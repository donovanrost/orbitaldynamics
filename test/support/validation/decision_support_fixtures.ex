defmodule OrbitalDynamics.Validation.DecisionSupportFixtures do
  @moduledoc false

  alias OrbitalDynamics.Validation

  def maneuver_review_report_fixture_observations do
    "maneuver_review_report.v1"
    |> Validation.artifact_observations(maneuver_review_report_fixture())
  end

  def maneuver_review_report_fixture do
    read_json!("study_results/maneuver_review_report_v1.json")
  end

  def monte_carlo_reproducibility_report_fixture_observations do
    "monte_carlo_reproducibility_report.v1"
    |> Validation.artifact_observations(monte_carlo_reproducibility_report_fixture())
  end

  def monte_carlo_reproducibility_report_fixture do
    read_json!("study_results/monte_carlo_reproducibility_report_v1.json")
  end

  def pareto_frontier_report_fixture_observations do
    "pareto_frontier_report.v1"
    |> Validation.artifact_observations(pareto_frontier_report_fixture())
  end

  def pareto_frontier_report_fixture do
    read_json!("study_results/pareto_frontier_report_v1.json")
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
