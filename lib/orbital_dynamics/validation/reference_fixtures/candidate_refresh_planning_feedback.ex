defmodule OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshPlanningFeedback do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.candidate_refresh.objective_gap_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.objective_gap_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of objective-gap source-report provenance",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_objective_gap_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 3,
        "source_report_row_count" => 9,
        "source_objective_satisfaction_report_count" => 1,
        "source_objective_satisfaction_gap_row_count" => 3,
        "source_objective_satisfaction_downlink_gap_row_count" => 1,
        "source_objective_satisfaction_target_gap_row_count" => 1,
        "source_objective_satisfaction_collection_latency_gap_row_count" => 1,
        "source_objective_satisfaction_status_counts" => %{
          "partial" => 2,
          "unmet" => 1
        },
        "source_objective_satisfaction_objective_type_counts" => %{
          "collection_latency" => 1,
          "downlink_completion" => 1,
          "target_coverage" => 1
        },
        "source_objective_satisfaction_ground_station_counts" => %{
          "equator_prime" => 1
        },
        "source_objective_satisfaction_target_counts" => %{"target_a" => 1},
        "source_objective_satisfaction_collection_counts" => %{
          "collection_alpha" => 1
        },
        "source_objective_satisfaction_source_activity_id_counts" => %{
          "collection_latency_activity" => 1,
          "dl_gap_activity" => 1,
          "target_gap_activity" => 1
        },
        "source_objective_satisfaction_trust_boundary_status" => "declared",
        "source_objective_gap_branch_local_objective_gap_pressure" => true,
        "source_objective_gap_branch_local_downlink_gap_pressure" => true,
        "source_objective_gap_branch_local_target_gap_pressure" => true,
        "source_objective_gap_branch_local_collection_latency_gap_pressure" => true,
        "source_objective_gap_branch_local_objective_status_pressure" => true,
        "source_objective_gap_branch_local_score_term_pressure" => true,
        "source_objective_gap_branch_local_routing_pressure" => true,
        "source_objective_tradeoff_report_count" => 1,
        "source_objective_tradeoff_row_count" => 3,
        "source_objective_tradeoff_downlink_gap_row_count" => 1,
        "source_objective_tradeoff_target_gap_row_count" => 1,
        "source_objective_tradeoff_collection_latency_gap_row_count" => 2,
        "source_objective_tradeoff_ground_station_counts" => %{
          "equator_prime" => 1
        },
        "source_objective_tradeoff_target_counts" => %{"target_a" => 1},
        "source_objective_tradeoff_collection_counts" => %{
          "collection_alpha" => 1
        },
        "source_objective_tradeoff_source_activity_id_counts" => %{
          "tradeoff_downlink_activity" => 1,
          "tradeoff_latency_activity" => 1,
          "tradeoff_target_activity" => 1
        },
        "source_objective_tradeoff_trust_boundary_status" => "declared",
        "source_score_term_report_count" => 1,
        "source_score_term_row_count" => 3,
        "source_score_term_downlink_gap_row_count" => 1,
        "source_score_term_target_gap_row_count" => 1,
        "source_score_term_collection_latency_gap_row_count" => 1,
        "source_score_term_term_key_counts" => %{
          "collection_latency_gap_s" => 1,
          "downlink_shortfall_mb" => 1,
          "target_gap_count" => 1
        },
        "source_score_term_ground_station_counts" => %{"equator_prime" => 1},
        "source_score_term_target_counts" => %{"target_a" => 1},
        "source_score_term_collection_counts" => %{"collection_alpha" => 1},
        "source_score_term_source_activity_id_counts" => %{
          "score_collection_activity" => 1,
          "score_downlink_activity" => 1,
          "score_target_activity" => 1
        },
        "source_score_term_trust_boundary_status" => "declared",
        "source_score_term_branch_local_score_term_pressure" => true,
        "source_score_term_branch_local_downlink_gap_pressure" => true,
        "source_score_term_branch_local_target_gap_pressure" => true,
        "source_score_term_branch_local_collection_latency_gap_pressure" => true,
        "source_score_term_branch_local_routing_pressure" => true
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_objective_satisfaction_report_count" => 0,
        "source_objective_satisfaction_gap_row_count" => 0,
        "source_objective_satisfaction_downlink_gap_row_count" => 0,
        "source_objective_satisfaction_target_gap_row_count" => 0,
        "source_objective_satisfaction_collection_latency_gap_row_count" => 0,
        "source_objective_tradeoff_report_count" => 0,
        "source_objective_tradeoff_row_count" => 0,
        "source_objective_tradeoff_downlink_gap_row_count" => 0,
        "source_objective_tradeoff_target_gap_row_count" => 0,
        "source_objective_tradeoff_collection_latency_gap_row_count" => 0,
        "source_score_term_report_count" => 0,
        "source_score_term_row_count" => 0,
        "source_score_term_downlink_gap_row_count" => 0,
        "source_score_term_target_gap_row_count" => 0,
        "source_score_term_collection_latency_gap_row_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not objective or scoring validation",
        "checks candidate-refresh replay of objective-gap provenance without objective generation, score recalculation, candidate selection, import approval, or Cadence writes"
      ]
    },
    "fixture.artifact.candidate_refresh.constraint_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.constraint_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of constraint source-report provenance",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_constraint_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 1,
        "source_report_row_count" => 3,
        "source_constraint_report_count" => 1,
        "source_constraint_row_count" => 3,
        "source_constraint_downlink_gap_row_count" => 1,
        "source_constraint_resource_margin_row_count" => 2,
        "source_constraint_status_counts" => %{"fail" => 1, "warning" => 2},
        "source_constraint_ground_station_counts" => %{"equator_prime" => 1},
        "source_constraint_metric_counts" => %{
          "battery_margin" => 1,
          "selected_downlink_shortfall_mb" => 1,
          "storage_margin" => 1
        },
        "source_constraint_id_counts" => %{
          "battery_margin" => 1,
          "downlink_shortfall" => 1,
          "storage_margin" => 1
        },
        "source_constraint_source_activity_id_counts" => %{
          "constraint_battery_activity" => 1,
          "constraint_downlink_activity" => 1,
          "constraint_storage_activity" => 1
        },
        "source_constraint_resource_counts" => %{"battery_1" => 1, "storage_1" => 1},
        "source_constraint_spacecraft_counts" => %{"sat_1" => 2},
        "source_constraint_trust_boundary_status" => "declared",
        "source_constraint_branch_local_constraint_pressure" => true,
        "source_constraint_branch_local_downlink_gap_pressure" => true,
        "source_constraint_branch_local_resource_margin_pressure" => true,
        "source_constraint_branch_local_constraint_routing_pressure" => true
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_constraint_report_count" => 0,
        "source_constraint_row_count" => 0,
        "source_constraint_downlink_gap_row_count" => 0,
        "source_constraint_resource_margin_row_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not constraint or resource validation",
        "checks candidate-refresh replay of constraint provenance without objective generation, resource mutation, candidate selection, import approval, or Cadence writes"
      ]
    }
  }

  def all, do: @fixtures
end
