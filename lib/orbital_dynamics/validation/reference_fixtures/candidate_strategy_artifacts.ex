defmodule OrbitalDynamics.Validation.ReferenceFixtures.CandidateStrategyArtifacts do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.branch_comparison_report.v1" => %{
      "id" => "fixture.artifact.branch_comparison_report.v1",
      "model_id" => "artifact.branch_comparison_report.v1",
      "reference_case" => "checked-in branch comparison artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/branch_comparison_report_v1.json",
        "contract" => "branch_comparison_report.v1"
      },
      "expected" => %{
        "schema_contract" => "branch_comparison_report.v1",
        "model" => "deterministic_strategy_branch_score_comparison",
        "source" => "campaign_strategy.branches",
        "branch_count" => 13,
        "row_count" => 13,
        "recommended_branch_id" => "derived_urgent_target_target_hot",
        "selected_count" => 1,
        "selected_branch_score" => 2835.3981832107565,
        "max_rank" => 13,
        "risk_count_total" => 106,
        "approval_requirement_count_total" => 6,
        "candidate_activity_count_total" => 6,
        "approval_status_counts" => %{"blocked_by_policy" => 9, "operator_review_required" => 4},
        "selected_branch_ids_by_status" => %{
          "false" => [
            "baseline",
            "derived_combined_mission_state",
            "derived_contact_success_feedback",
            "derived_degraded_leo_2",
            "derived_downlink_constrained",
            "derived_fuel_preservation",
            "derived_observation_success_feedback",
            "derived_station_capacity_equator_prime",
            "derived_station_throughput_feedback",
            "derived_target_revisit_target_hot",
            "operator_placeholder_urgent",
            "operator_station_outage"
          ],
          "true" => ["derived_urgent_target_target_hot"]
        },
        "branch_ids_by_approval_status" => %{
          "blocked_by_policy" => [
            "baseline",
            "derived_contact_success_feedback",
            "derived_degraded_leo_2",
            "derived_downlink_constrained",
            "derived_fuel_preservation",
            "derived_observation_success_feedback",
            "derived_station_capacity_equator_prime",
            "derived_station_throughput_feedback",
            "operator_station_outage"
          ],
          "operator_review_required" => [
            "derived_combined_mission_state",
            "derived_target_revisit_target_hot",
            "derived_urgent_target_target_hot",
            "operator_placeholder_urgent"
          ]
        },
        "row_derived_branch_count" => 13,
        "row_derived_selected_count" => 1,
        "row_derived_risk_count_total" => 106,
        "row_derived_approval_requirement_count_total" => 6,
        "row_derived_candidate_activity_count_total" => 6,
        "row_derived_approval_status_counts" => %{
          "blocked_by_policy" => 9,
          "operator_review_required" => 4
        },
        "row_derived_branch_ids_by_approval_status" => %{
          "blocked_by_policy" => [
            "baseline",
            "derived_contact_success_feedback",
            "derived_degraded_leo_2",
            "derived_downlink_constrained",
            "derived_fuel_preservation",
            "derived_observation_success_feedback",
            "derived_station_capacity_equator_prime",
            "derived_station_throughput_feedback",
            "operator_station_outage"
          ],
          "operator_review_required" => [
            "derived_combined_mission_state",
            "derived_target_revisit_target_hot",
            "derived_urgent_target_target_hot",
            "operator_placeholder_urgent"
          ]
        },
        "resource_risk_type_counts" => %{
          "downlink_capacity_low" => 13,
          "fuel_margin_low" => 13,
          "payload_availability_low" => 13,
          "spacecraft_availability_low" => 13,
          "storage_margin_low" => 13
        },
        "row_derived_resource_risk_type_counts" => %{
          "downlink_capacity_low" => 13,
          "fuel_margin_low" => 13,
          "payload_availability_low" => 13,
          "spacecraft_availability_low" => 13,
          "storage_margin_low" => 13
        },
        "branch_order" => "score_descending_then_branch_id",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "branch_count" => 0,
        "row_count" => 0,
        "selected_count" => 0,
        "selected_branch_score" => 0.0,
        "max_rank" => 0,
        "risk_count_total" => 0,
        "approval_requirement_count_total" => 0,
        "candidate_activity_count_total" => 0,
        "row_derived_branch_count" => 0,
        "row_derived_selected_count" => 0,
        "row_derived_risk_count_total" => 0,
        "row_derived_approval_requirement_count_total" => 0,
        "row_derived_candidate_activity_count_total" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external optimizer validation",
        "checks branch comparison counts, ranking maps, and no-execution model boundary only"
      ]
    },
    "fixture.artifact.optimizer_contract.v1" => %{
      "id" => "fixture.artifact.optimizer_contract.v1",
      "model_id" => "artifact.optimizer_contract.v1",
      "reference_case" => "checked-in optimizer contract artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/optimizer_contract_v1.json",
        "contract" => "optimizer_contract.v1"
      },
      "expected" => %{
        "schema_contract" => "optimizer_contract.v1",
        "id" =>
          "optimizer_contract:campaign_plan:leo_constellation_campaign:2026-05-14T00:00:00Z",
        "optimizer" => "per_spacecraft_greedy_non_overlapping",
        "objective" => "maximize weighted observation value and contact value",
        "selection_policy" => "highest_scored_non_overlapping_timeline",
        "selected_activity_count" => 1,
        "candidate_count" => 2,
        "candidate_activity_id_count" => 2,
        "ranked_scenario_count" => 1,
        "ranked_timeline_count" => 1,
        "constraint_count" => 3,
        "score_term_key_count" => 7,
        "deterministic_ordering_count" => 5,
        "known_limit_count" => 6,
        "preserved_lineage_field_count" => 5,
        "external_solver" => false,
        "optimizer_family" => "deterministic_greedy_selector",
        "selection_scope" => "per_scenario_then_ranked_plan",
        "selected_activity_id_order" => "leo_1_observe_target_a_1",
        "candidate_activity_id_order" => "leo_1_downlink_equator_prime_1|leo_1_observe_target_a_1"
      },
      "tolerances" => %{
        "selected_activity_count" => 0,
        "candidate_count" => 0,
        "candidate_activity_id_count" => 0,
        "ranked_scenario_count" => 0,
        "ranked_timeline_count" => 0,
        "constraint_count" => 0,
        "score_term_key_count" => 0,
        "deterministic_ordering_count" => 0,
        "known_limit_count" => 0,
        "preserved_lineage_field_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external optimizer validation",
        "checks deterministic greedy optimizer contract shape and routing only"
      ]
    },
    "fixture.artifact.invalidated_candidate.v1" => %{
      "id" => "fixture.artifact.invalidated_candidate.v1",
      "model_id" => "artifact.invalidated_candidate.v1",
      "reference_case" => "checked-in invalidated candidate artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/invalidated_candidate_v1.json",
        "contract" => "invalidated_candidate.v1"
      },
      "expected" => %{
        "schema_contract" => "invalidated_candidate.v1",
        "id" => "old_candidate",
        "scenario_id" => "leo_1",
        "type" => "observe",
        "invalidated_reason" => "replaced_by_semantically_similar_candidate",
        "replacement_candidate_id" => "leo_1_observe_target_a_1",
        "source_window_id" => "window:leo_1:target_visibility:target_a:old",
        "target_id" => "target_a",
        "target_priority" => 12,
        "target_priority_objective_type" => "urgent_target",
        "changed_field_count" => 3,
        "candidate_diff_changed_field_count" => 3,
        "semantic_change_reason_count" => 3,
        "semantic_change_detail_count" => 3,
        "changed_field_order" => "ends_at_s|source_window_id|starts_at_s",
        "semantic_change_reason_order" =>
          "starts_at_s_changed|ends_at_s_changed|source_window_id_changed",
        "target_priority_objective_count" => 1,
        "duration_s" => 60
      },
      "tolerances" => %{
        "target_priority" => 0,
        "changed_field_count" => 0,
        "candidate_diff_changed_field_count" => 0,
        "semantic_change_reason_count" => 0,
        "semantic_change_detail_count" => 0,
        "target_priority_objective_count" => 0,
        "duration_s" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not candidate refresh validation",
        "checks invalidation reason, replacement routing, target metadata, and semantic-change details only"
      ]
    },
    "fixture.artifact.proposed_contact.v1" => %{
      "id" => "fixture.artifact.proposed_contact.v1",
      "model_id" => "artifact.proposed_contact.v1",
      "reference_case" => "checked-in proposed contact artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/proposed_contact_v1.json",
        "contract" => "proposed_contact.v1"
      },
      "expected" => %{
        "id" => "leo_1_downlink_equator_prime_1",
        "scenario_id" => "leo_1",
        "type" => "downlink",
        "direction" => "downlink",
        "ground_station_id" => "equator_prime",
        "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
        "source_window_type" => "ground_station_access",
        "event_detector" => "access_windows",
        "event_timing_policy" => "sampled_state_linear_boundary",
        "event_time_tolerance_s" => 60,
        "station_availability" => "available",
        "schedule_conflict_status" => "not_evaluated",
        "timeline_identity_activity_type" => "downlink",
        "cadence_import_contract" => "proposed_contact.v1",
        "model_limit_count" => 3,
        "duration_s" => 345.1793094813298,
        "estimated_throughput_mb" => 690.3586189626596
      },
      "tolerances" => %{
        "event_time_tolerance_s" => 0,
        "model_limit_count" => 0,
        "duration_s" => 1.0e-9,
        "estimated_throughput_mb" => 1.0e-9
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not station-provider validation",
        "checks proposed contact identity, timing, source-window, and artifact-only boundary only"
      ]
    },
    "fixture.artifact.strategy_branch.v1" => %{
      "id" => "fixture.artifact.strategy_branch.v1",
      "model_id" => "artifact.strategy_branch.v1",
      "reference_case" => "checked-in standalone V3 strategy branch artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/strategy_branch_v1.json",
        "contract" => "strategy_branch.v1"
      },
      "expected" => %{
        "schema_contract" => "strategy_branch.v1",
        "branch_id" => "derived_urgent_target_target_hot",
        "label" => "Derived urgent target target_hot",
        "probability" => 1.0,
        "event_count" => 2,
        "event_type_counts" => %{"downlink_completion_gap" => 1, "urgent_target" => 1},
        "candidate_activity_count" => 0,
        "strategic_addition_count" => 0,
        "capacity_adjustment_count" => 0,
        "repair_delta_count" => 0,
        "approval_requirement_count" => 0,
        "policy_classification" => "operator_review_required",
        "policy_risk_count" => 1,
        "score" => 2835.3981832107565,
        "score_term_count" => 4,
        "warning_count" => 1,
        "risk_count" => 1,
        "approval_status" => "operator_review_required",
        "derived_source" => "mission_state.objectives",
        "tradeoff_count" => 1,
        "downlink_capacity_margin" => 0.62
      },
      "tolerances" => %{
        "probability" => 0.0,
        "event_count" => 0,
        "candidate_activity_count" => 0,
        "strategic_addition_count" => 0,
        "capacity_adjustment_count" => 0,
        "repair_delta_count" => 0,
        "approval_requirement_count" => 0,
        "policy_risk_count" => 0,
        "score" => 0.0,
        "score_term_count" => 0,
        "warning_count" => 0,
        "risk_count" => 0,
        "tradeoff_count" => 0,
        "downlink_capacity_margin" => 0.0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external strategy validation",
        "checks standalone branch event/risk/score routing only"
      ]
    },
    "fixture.artifact.strategy_recommendation.v1" => %{
      "id" => "fixture.artifact.strategy_recommendation.v1",
      "model_id" => "artifact.strategy_recommendation.v1",
      "reference_case" => "checked-in standalone V3 strategy recommendation artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/strategy_recommendation_v1.json",
        "contract" => "strategy_recommendation.v1"
      },
      "expected" => %{
        "schema_contract" => "strategy_recommendation.v1",
        "status" => "pass",
        "recommended_branch_id" => "derived_urgent_target_target_hot",
        "approval_status" => "operator_review_required",
        "reason" => "best_expected_score_requiring_operator_review",
        "ranked_branch_count" => 4,
        "ranked_branch_id_order" =>
          "derived_urgent_target_target_hot|derived_target_revisit_target_hot|derived_combined_mission_state|operator_placeholder_urgent",
        "tradeoff_count" => 3,
        "explanation_count" => 4,
        "risk_count" => 2,
        "approval_requirement_count" => 1,
        "requires_operator_review_count" => 1,
        "branch_event_summary_count" => 1,
        "branch_event_type_counts" => %{"urgent_target" => 1},
        "branch_requires_operator_review" => true
      },
      "tolerances" => %{
        "ranked_branch_count" => 0,
        "tradeoff_count" => 0,
        "explanation_count" => 0,
        "risk_count" => 0,
        "approval_requirement_count" => 0,
        "requires_operator_review_count" => 0,
        "branch_event_summary_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external strategy validation",
        "checks standalone recommendation ranking/review routing only"
      ]
    }
  }

  def all, do: @fixtures
end
