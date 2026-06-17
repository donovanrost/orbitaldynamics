Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyScoringPolicyTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy branch scoring normalizes numeric-string selected activity scores" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_000.0},
        "activities" => [
          observe("obs_scored", "leo_1", "target_a", 100.0, 160.0, "100.0")
        ],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        branches: [%{id: "baseline"}, %{id: "noop", probability: 0.0}],
        current_epoch_s: 0.0
      )

    baseline = branch(artifact, "baseline")

    assert baseline["score_terms"]["mission_value_score"] == 100.0
    assert baseline["score"] == baseline["score_terms"]["expected_score"]

    assert %{
             "term_key" => "mission_value_score",
             "value" => 100.0
           } =
             Enum.find(
               artifact["score_term_report"]["rows"],
               &(&1["branch_id"] == "baseline" and &1["term_key"] == "mission_value_score")
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy rejects non-numeric scoring policy weights before branch evaluation" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [observe("obs_1", "leo_1", "target_a", 100.0, 160.0, 100.0)],
        "candidate_activities" => []
      })

    assert_raise ArgumentError, ~r/strategy_policy.risk_weight must be numeric/, fn ->
      strategy(prior_plan,
        strategy_policy: %{"risk_weight" => "high"},
        branches: [
          %{id: "baseline", label: "Nominal"},
          %{id: "noop", probability: 0.0}
        ],
        current_epoch_s: 0.0
      )
    end
  end
end
