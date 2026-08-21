Code.require_file(
  "../../support/schema/campaign_strategy_produced_surface_case.ex",
  __DIR__
)

defmodule OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceDownstreamPackagesTest do
  use OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceCase,
    async: true,
    group: :campaign_strategy_produced_surface

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.OperatorReview
  alias OrbitalDynamics.Schema

  test "rejects CampaignStrategy operator-review package source drift", %{
    strategy: strategy
  } do
    shadow_strategies = [
      {put_in(strategy, ["recommendation", "reason"], "schema_valid_drift"),
       "campaign_strategy.recommendation"},
      {update_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(0), "score"],
         &(&1 + 1)
       ), "campaign_strategy.branch_comparison_report.rows"},
      {update_in(
         strategy,
         ["ranking_comparison_report", "rows", Access.at(0), "right_value"],
         &(&1 + 1)
       ), "campaign_strategy.ranking_comparison_report.rows"},
      {update_in(
         strategy,
         ["pareto_frontier_report", "rows", Access.at(0), "objective_values", "score"],
         &(&1 + 1)
       ), "campaign_strategy.pareto_frontier_report.rows"},
      {update_in(
         strategy,
         ["score_term_report", "rows", Access.at(0), "value"],
         &(&1 + 1)
       ), "campaign_strategy.score_term_report.rows"},
      {update_in(
         strategy,
         ["objective_tradeoff_report", "tradeoffs", Access.at(0), "score"],
         &(&1 + 1)
       ), "campaign_strategy.objective_tradeoff_report.tradeoffs"},
      {update_in(
         strategy,
         ["branches", Access.at(0), "warnings"],
         &(&1 ++ ["schema valid drift"])
       ), "campaign_strategy.branches.warnings"}
    ]

    for {shadow, source} <- shadow_strategies do
      invalid =
        Map.put(
          strategy,
          "operator_review_package",
          OperatorReview.from_strategy_artifact(shadow)
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(validation_report["errors"], fn issue ->
               String.starts_with?(issue["path"], "$.operator_review_package.rows") and
                 String.contains?(issue["message"], source)
             end)
    end
  end

  test "rejects CampaignStrategy Cadence import manifest source drift", %{
    strategy: strategy
  } do
    shadow_strategies = [
      {put_in(strategy, ["recommendation", "reason"], "schema_valid_drift"),
       "CampaignStrategy recommendation"},
      {update_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(0), "score"],
         &(&1 + 1)
       ), "CampaignStrategy branch comparison"},
      {update_in(
         strategy,
         ["ranking_comparison_report", "rows", Access.at(0), "right_value"],
         &(&1 + 1)
       ), "CampaignStrategy operator-review"},
      {update_in(
         strategy,
         ["pareto_frontier_report", "rows", Access.at(0), "objective_values", "score"],
         &(&1 + 1)
       ), "CampaignStrategy operator-review"},
      {update_in(
         strategy,
         ["score_term_report", "rows", Access.at(0), "value"],
         &(&1 + 1)
       ), "CampaignStrategy operator-review"},
      {update_in(
         strategy,
         ["objective_tradeoff_report", "tradeoffs", Access.at(0), "score"],
         &(&1 + 1)
       ), "CampaignStrategy operator-review"},
      {update_in(
         strategy,
         ["branches", Access.at(0), "warnings"],
         &(&1 ++ ["schema valid drift"])
       ), "CampaignStrategy operator-review"}
    ]

    for {shadow, source} <- shadow_strategies do
      shadow =
        Map.put(
          shadow,
          "operator_review_package",
          OperatorReview.from_strategy_artifact(shadow)
        )

      invalid =
        Map.put(
          strategy,
          "cadence_import_manifest",
          CadenceImport.from_strategy_artifact(shadow)
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(validation_report["errors"], fn issue ->
               issue["path"] == "$.cadence_import_manifest.rows" and
                 String.contains?(issue["message"], source)
             end)
    end
  end
end
