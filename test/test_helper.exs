profile_path = System.get_env("ORBITAL_DYNAMICS_TEST_PROFILE_PATH")

if profile_path do
  ExUnit.start(
    formatters: [ExUnit.CLIFormatter, OrbitalDynamics.TestSuite.ProfileFormatter],
    orbital_dynamics_test_profile_path: profile_path
  )
else
  ExUnit.start()
end

Code.require_file("support/validation/orbital_reference_fixtures.ex", __DIR__)
Code.require_file("support/validation/campaign_artifact_fixtures.ex", __DIR__)
Code.require_file("support/validation/policy_bundle_fixtures.ex", __DIR__)
Code.require_file("support/validation/activity_artifact_fixtures.ex", __DIR__)
Code.require_file("support/validation/contact_window_fixtures.ex", __DIR__)
Code.require_file("support/validation/state_maneuver_fixtures.ex", __DIR__)
Code.require_file("support/validation/policy_evidence_fixtures.ex", __DIR__)
Code.require_file("support/validation/timeline_activity_state_fixtures.ex", __DIR__)
Code.require_file("support/validation/timeline_preservation_fixtures.ex", __DIR__)
Code.require_file("support/validation/timeline_transition_fixtures.ex", __DIR__)
Code.require_file("support/validation/timeline_handoff_fixtures.ex", __DIR__)
Code.require_file("support/validation/operational_planning_fixtures.ex", __DIR__)
Code.require_file("support/validation/provider_capacity_pack_fixtures.ex", __DIR__)
Code.require_file("support/validation/contact_contention_fixtures.ex", __DIR__)
Code.require_file("support/validation/link_capacity_fixtures.ex", __DIR__)
Code.require_file("support/validation/decision_support_fixtures.ex", __DIR__)
Code.require_file("support/validation/resource_projection_fixtures.ex", __DIR__)
Code.require_file("support/validation/resource_safety_fixtures.ex", __DIR__)
Code.require_file("support/validation/resource_summary_fixtures.ex", __DIR__)
Code.require_file("support/validation/objective_scoring_fixtures.ex", __DIR__)
Code.require_file("support/validation/schema_compatibility_fixtures.ex", __DIR__)
Code.require_file("support/validation/station_reservation_fixtures.ex", __DIR__)
Code.require_file("support/validation/model_acceptance_fixtures.ex", __DIR__)
Code.require_file("support/validation/candidate_refresh_base_fixtures.ex", __DIR__)
Code.require_file("support/validation/candidate_refresh_contact_replay_fixtures.ex", __DIR__)
Code.require_file("support/validation/operational_readiness_fixtures.ex", __DIR__)
Code.require_file("support/validation/quality_gate_fixtures.ex", __DIR__)
Code.require_file("support/validation/candidate_refresh_readiness_replay_fixtures.ex", __DIR__)
Code.require_file("support/validation/candidate_refresh_timeline_replay_fixtures.ex", __DIR__)

Code.require_file(
  "support/validation/candidate_refresh_planning_feedback_replay_fixtures.ex",
  __DIR__
)

Code.require_file(
  "support/validation/candidate_refresh_capacity_filter_replay_fixtures.ex",
  __DIR__
)

Code.require_file(
  "support/validation/candidate_refresh_filter_rejection_replay_fixtures.ex",
  __DIR__
)

Code.require_file(
  "support/validation/candidate_refresh_freshness_budget_replay_fixtures.ex",
  __DIR__
)

Code.require_file(
  "support/validation/candidate_refresh_station_allocation_replay_fixtures.ex",
  __DIR__
)

Code.require_file("support/validation/candidate_state_fixtures.ex", __DIR__)
Code.require_file("support/validation/planning_input_fixtures.ex", __DIR__)
Code.require_file("support/validation/candidate_strategy_fixtures.ex", __DIR__)
Code.require_file("support/validation/benchmark_fixtures.ex", __DIR__)
Code.require_file("support/validation/core_run_report_fixtures.ex", __DIR__)
Code.require_file("support/validation/manifest_fixtures.ex", __DIR__)
Code.require_file("support/validation/policy_decision_fixtures.ex", __DIR__)
Code.require_file("support/validation/resource_pressure_handoff_fixtures.ex", __DIR__)
Code.require_file("support/validation/contact_allocation_fixtures.ex", __DIR__)
Code.require_file("orbital_dynamics/campaign_planner/local_search_support.exs", __DIR__)
Code.require_file("support/validation/level5_contract_fixtures.ex", __DIR__)
Code.require_file("support/validation/deterministic_reference_fixture_report.ex", __DIR__)
