Code.require_file("support.exs", __DIR__)

Code.require_file(
  "../../support/campaign_planner/strategy_recommendation_pressure_handoff_case.ex",
  __DIR__
)

defmodule OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffTimelineStateContextTest do
  use OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffCase

  @timeline_activity_lifecycle_state_unemitted_context_fields [
    "timeline_activity_lifecycle_state_invalid_activity_input_reasons"
  ]
  @timeline_activity_lifecycle_state_context_contracts OrbitalDynamics.RecommendationRiskContext.TimelineActivityLifecycleState.field_pairs()
                                                       |> Enum.reject(fn {field, _source_fields} ->
                                                         field in @timeline_activity_lifecycle_state_unemitted_context_fields
                                                       end)

  for {field, source_fields} <- @timeline_activity_lifecycle_state_context_contracts do
    test "activity-lifecycle-state #{field} remains source exact across handoffs", %{
      handoff: handoff
    } do
      artifact = handoff

      expected_value =
        artifact["operator_review_package"]["rows"]
        |> Enum.find(&(&1["review_type"] == "strategy_recommendation"))
        |> Map.fetch!(unquote(field))

      assert_risk_context_contract(
        artifact,
        unquote(field),
        {"feedback_scope", "timeline_activity_lifecycle_state"},
        unquote(Macro.escape(source_fields)),
        expected_value,
        stale_context_value(expected_value)
      )
    end
  end

  @timeline_preservation_unemitted_context_fields [
    "timeline_preservation_invalid_activity_input_reasons"
  ]
  @timeline_preservation_context_contracts OrbitalDynamics.RecommendationRiskContext.TimelinePreservation.field_pairs()
                                           |> Enum.reject(fn {field, _source_fields} ->
                                             field in @timeline_preservation_unemitted_context_fields
                                           end)

  for {field, source_fields} <- @timeline_preservation_context_contracts do
    test "timeline-preservation #{field} remains source exact across handoffs", %{
      handoff: handoff
    } do
      artifact = handoff

      expected_value =
        artifact["operator_review_package"]["rows"]
        |> Enum.find(&(&1["review_type"] == "strategy_recommendation"))
        |> Map.fetch!(unquote(field))

      assert_risk_context_contract(
        artifact,
        unquote(field),
        {"feedback_scope", "timeline_preservation"},
        unquote(Macro.escape(source_fields)),
        expected_value,
        stale_context_value(expected_value)
      )
    end
  end

  @timeline_activity_precondition_unemitted_context_fields [
    "timeline_activity_precondition_invalid_activity_input_reasons"
  ]
  @timeline_activity_precondition_context_contracts OrbitalDynamics.RecommendationRiskContext.TimelineActivityPrecondition.field_pairs()
                                                    |> Enum.reject(fn {field, _source_fields} ->
                                                      field in @timeline_activity_precondition_unemitted_context_fields
                                                    end)

  for {field, source_fields} <- @timeline_activity_precondition_context_contracts do
    test "activity-precondition #{field} remains source exact across handoffs", %{
      handoff: handoff
    } do
      artifact = handoff

      expected_value =
        artifact["operator_review_package"]["rows"]
        |> Enum.find(&(&1["review_type"] == "strategy_recommendation"))
        |> Map.fetch!(unquote(field))

      assert_risk_context_contract(
        artifact,
        unquote(field),
        {"feedback_scope", "timeline_activity_precondition"},
        unquote(Macro.escape(source_fields)),
        expected_value,
        stale_context_value(expected_value)
      )
    end
  end

  @timeline_integrity_unemitted_context_fields [
    "timeline_integrity_missing_dependency_timeline_ids",
    "timeline_integrity_dependency_cycle_activity_ids",
    "timeline_integrity_dependency_cycle_timeline_ids",
    "timeline_integrity_dependency_order_violation_activity_ids",
    "timeline_integrity_dependency_order_violation_timeline_ids"
  ]
  @timeline_integrity_context_contracts OrbitalDynamics.RecommendationRiskContext.TimelineIntegrity.field_pairs()
                                        |> Enum.reject(fn {field, _source_fields} ->
                                          field in @timeline_integrity_unemitted_context_fields
                                        end)

  for {field, source_fields} <- @timeline_integrity_context_contracts do
    test "timeline-integrity #{field} remains source exact across handoffs", %{handoff: handoff} do
      artifact = handoff

      expected_value =
        artifact["operator_review_package"]["rows"]
        |> Enum.find(&(&1["review_type"] == "strategy_recommendation"))
        |> Map.fetch!(unquote(field))

      assert_risk_context_contract(
        artifact,
        unquote(field),
        {"feedback_scope", "timeline_integrity"},
        unquote(Macro.escape(source_fields)),
        expected_value,
        stale_context_value(expected_value)
      )
    end
  end
end
