defmodule OrbitalDynamics.Schema.StrategyRecommendationRiskContextCoverageTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema.StrategyHandoffContracts

  test "every declared recommendation risk context is registered or explicitly non-emitted" do
    coverage = StrategyHandoffContracts.strategy_recommendation_risk_context_coverage()

    assert %{
             family_count: 30,
             declared_field_count: 962,
             registered_field_count: 953,
             intentionally_unemitted_field_count: 9,
             duplicate_declared_fields: [],
             duplicate_registered_fields: [],
             missing_fields: [],
             unexpected_fields: [],
             stale_unemitted_fields: [],
             registered_unemitted_fields: []
           } = coverage

    assert coverage.intentionally_unemitted_fields == [
             "refresh_freshness_unknown_reason_ids",
             "timeline_activity_lifecycle_state_invalid_activity_input_reasons",
             "timeline_activity_precondition_invalid_activity_input_reasons",
             "timeline_integrity_dependency_cycle_activity_ids",
             "timeline_integrity_dependency_cycle_timeline_ids",
             "timeline_integrity_dependency_order_violation_activity_ids",
             "timeline_integrity_dependency_order_violation_timeline_ids",
             "timeline_integrity_missing_dependency_timeline_ids",
             "timeline_preservation_invalid_activity_input_reasons"
           ]

    assert coverage.declared_field_count ==
             coverage.registered_field_count + coverage.intentionally_unemitted_field_count
  end
end
