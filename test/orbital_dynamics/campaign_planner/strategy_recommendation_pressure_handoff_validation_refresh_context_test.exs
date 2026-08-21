Code.require_file("support.exs", __DIR__)

Code.require_file(
  "../../support/campaign_planner/strategy_recommendation_pressure_handoff_case.ex",
  __DIR__
)

defmodule OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffValidationRefreshContextTest do
  use OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffCase

  @validation_refresh_unemitted_context_fields [
    "refresh_freshness_unknown_reason_ids"
  ]
  @validation_refresh_context_contracts OrbitalDynamics.RecommendationRiskContext.ValidationRefresh.field_specs()
                                        |> Enum.reject(fn {field, _source_fields, _feedback_scope} ->
                                          field in @validation_refresh_unemitted_context_fields
                                        end)

  for {field, source_fields, feedback_scope} <- @validation_refresh_context_contracts do
    test "validation-refresh #{field} remains source exact across handoffs", %{handoff: handoff} do
      artifact = handoff

      expected_value =
        artifact["operator_review_package"]["rows"]
        |> Enum.find(&(&1["review_type"] == "strategy_recommendation"))
        |> Map.fetch!(unquote(field))

      assert_risk_context_contract(
        artifact,
        unquote(field),
        {"feedback_scope", unquote(feedback_scope)},
        unquote(Macro.escape(source_fields)),
        expected_value,
        stale_context_value(expected_value)
      )
    end
  end
end
