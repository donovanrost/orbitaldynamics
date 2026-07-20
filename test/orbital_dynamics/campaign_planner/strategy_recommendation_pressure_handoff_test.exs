Code.require_file("support.exs", __DIR__)

Code.require_file(
  "../../support/campaign_planner/strategy_recommendation_pressure_events_fixture.ex",
  __DIR__
)

Code.require_file(
  "../../support/campaign_planner/strategy_recommendation_pressure_expected_handoff_fixture.ex",
  __DIR__
)

defmodule OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureEventsFixture
  alias OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureExpectedHandoffFixture
  alias OrbitalDynamics.Schema

  test "strategy recommendation pressure fields propagate through review and import handoffs" do
    artifact = StrategyRecommendationPressureEventsFixture.artifact()

    expected_handoff = StrategyRecommendationPressureExpectedHandoffFixture.expected_handoff()

    recommendation_review_row =
      artifact["operator_review_package"]["rows"]
      |> Enum.find(&(&1["review_type"] == "strategy_recommendation"))

    emitted_expected_handoff = Map.take(expected_handoff, Map.keys(recommendation_review_row))

    assert Map.take(recommendation_review_row, Map.keys(emitted_expected_handoff)) ==
             emitted_expected_handoff

    selected_import_row =
      artifact["cadence_import_manifest"]["rows"]
      |> Enum.find(
        &(&1["import_action"] == "import_strategy_recommendation" and &1["selected"] == true)
      )

    assert Map.take(selected_import_row, Map.keys(emitted_expected_handoff)) ==
             emitted_expected_handoff

    review_import =
      OrbitalDynamics.cadence_import_manifest(artifact["operator_review_package"])

    review_import_row =
      review_import["rows"]
      |> Enum.find(&(&1["source_review_type"] == "strategy_recommendation"))

    assert Map.take(review_import_row, Map.keys(emitted_expected_handoff)) ==
             emitted_expected_handoff

    assert Map.take(review_import_row["source_review_row"], Map.keys(emitted_expected_handoff)) ==
             emitted_expected_handoff

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1", "status" => "pass"}} =
             Schema.validate_artifact(review_import)
  end
end
