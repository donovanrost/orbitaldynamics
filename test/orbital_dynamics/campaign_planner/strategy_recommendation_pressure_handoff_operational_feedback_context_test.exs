Code.require_file("support.exs", __DIR__)

Code.require_file(
  "../../support/campaign_planner/strategy_recommendation_pressure_handoff_case.ex",
  __DIR__
)

defmodule OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffOperationalFeedbackContextTest do
  use OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffCase

  @operational_feedback_risk_types [
    "contact_success_rate_low",
    "observation_success_rate_low",
    "station_throughput_factor_low"
  ]
  @operational_feedback_context_contracts Enum.map(
                                            OrbitalDynamics.RecommendationRiskContext.OperationalFeedback.field_pairs(),
                                            fn {field, source_fields} ->
                                              legacy_mode =
                                                if field ==
                                                     "strategy_operational_feedback_risk_types",
                                                   do: :drop_risk,
                                                   else: :drop_field

                                              {field, source_fields, legacy_mode}
                                            end
                                          )

  for {field, source_fields, legacy_mode} <- @operational_feedback_context_contracts do
    test "operational-feedback #{field} remains source exact across handoffs", %{handoff: handoff} do
      artifact = handoff

      expected_value =
        artifact["operator_review_package"]["rows"]
        |> Enum.find(&(&1["review_type"] == "strategy_recommendation"))
        |> Map.fetch!(unquote(field))

      assert_risk_context_contract(
        artifact,
        unquote(field),
        {"type", unquote(@operational_feedback_risk_types)},
        unquote(Macro.escape(source_fields)),
        expected_value,
        stale_context_value(expected_value),
        unquote(legacy_mode)
      )
    end
  end
end
