defmodule OrbitalDynamics.Validation.ReferenceFixtures.CoreRunReports do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.candidate_diff_report.v1" => %{
      "id" => "fixture.artifact.candidate_diff_report.v1",
      "model_id" => "artifact.candidate_diff_report.v1",
      "reference_case" => "checked-in candidate diff artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/candidate_diff_report_v1.json",
        "contract" => "candidate_diff_report.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_diff_report.v1",
        "model" => "candidate_id_set_diff_with_semantic_change_reasons",
        "prior_candidate_count" => 1,
        "refreshed_candidate_count" => 2,
        "retained_candidate_count" => 0,
        "retained_candidate_row_count" => 0,
        "new_candidate_count" => 2,
        "new_candidate_row_count" => 2,
        "invalidated_candidate_count" => 1,
        "invalidated_candidate_row_count" => 1,
        "source_window_lineage_count" => 1,
        "new_reason_counts" => %{
          "not_present_in_prior_candidate_set" => 1,
          "semantically_similar_prior_candidate_changed" => 1
        },
        "invalidated_reason_counts" => %{"replaced_by_semantically_similar_candidate" => 1},
        "semantic_change_reason_counts" => %{
          "ends_at_s_changed" => 2,
          "source_window_id_changed" => 2,
          "starts_at_s_changed" => 2
        },
        "changed_field_counts" => %{
          "ends_at_s" => 1,
          "source_window_id" => 1,
          "starts_at_s" => 1
        },
        "new_candidate_ids_by_reason" => %{
          "not_present_in_prior_candidate_set" => ["leo_1_downlink_equator_prime_1"],
          "semantically_similar_prior_candidate_changed" => ["leo_1_observe_target_a_1"]
        },
        "invalidated_candidate_ids_by_reason" => %{
          "replaced_by_semantically_similar_candidate" => ["old_candidate"]
        },
        "replacement_candidate_ids_by_invalidated_reason" => %{
          "replaced_by_semantically_similar_candidate" => ["leo_1_observe_target_a_1"]
        },
        "model_limit_count" => 6
      },
      "tolerances" => %{
        "prior_candidate_count" => 0,
        "refreshed_candidate_count" => 0,
        "retained_candidate_count" => 0,
        "retained_candidate_row_count" => 0,
        "new_candidate_count" => 0,
        "new_candidate_row_count" => 0,
        "invalidated_candidate_count" => 0,
        "invalidated_candidate_row_count" => 0,
        "source_window_lineage_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external candidate-refresh validation",
        "checks candidate diff counts, semantic change reasons, replacement routing, and model-limit boundary only"
      ]
    },
    "fixture.artifact.refresh_budget_report.v1" => %{
      "id" => "fixture.artifact.refresh_budget_report.v1",
      "model_id" => "artifact.refresh_budget_report.v1",
      "reference_case" => "checked-in refresh budget artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/refresh_budget_report_v1.json",
        "contract" => "refresh_budget_report.v1"
      },
      "expected" => %{
        "schema_contract" => "refresh_budget_report.v1",
        "model" => "deterministic_candidate_limit_after_filters",
        "input_candidate_count" => 2,
        "kept_candidate_count" => 1,
        "dropped_candidate_count" => 1,
        "max_candidate_activities" => 1,
        "kept_candidate_id_count" => 1,
        "dropped_candidate_id_count" => 1,
        "first_kept_candidate_id" => "leo_1_observe_target_a_1",
        "first_dropped_candidate_id" => "leo_1_downlink_equator_prime_1",
        "budget_stage" => "after_contact_resource_and_allocation_filters",
        "optimizer_search_performed" => false,
        "selection_policy" => "highest_score_candidates_are_kept_then_artifact_order_is_restored",
        "model_limit_count" => 6
      },
      "tolerances" => %{
        "input_candidate_count" => 0,
        "kept_candidate_count" => 0,
        "dropped_candidate_count" => 0,
        "max_candidate_activities" => 0,
        "kept_candidate_id_count" => 0,
        "dropped_candidate_id_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external optimizer validation",
        "checks deterministic refresh budget counts, keep/drop IDs, and model-limit boundary only"
      ]
    },
    "fixture.artifact.execution_report.v1" => %{
      "id" => "fixture.artifact.execution_report.v1",
      "model_id" => "artifact.execution_report.v1",
      "reference_case" => "checked-in distributed execution report artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/execution_report_v1.json",
        "contract" => "execution_report.v1"
      },
      "expected" => %{
        "schema_contract" => "execution_report.v1",
        "status" => "completed_with_errors",
        "study_id" => "large_monte_carlo",
        "run_id" => "large_monte_carlo-2026-05-14T00:00:00Z",
        "backend" => "Elixir.OrbitalDynamics.Propagators.TwoBody",
        "execution_mode" => "distributed_task_supervisors",
        "scenario_count" => 2000,
        "completed_scenario_count" => 1999,
        "failed_scenario_count" => 1,
        "event_result_count" => 5997,
        "task_chunk_size" => 50,
        "effective_task_concurrency" => 16,
        "timeout" => 30_000,
        "failed_scenario_row_count" => 1,
        "first_failed_scenario_id" => "trial_1842",
        "first_failed_scenario_stage" => "propagation",
        "first_failed_scenario_resumability" => "manual_rerun_only",
        "first_failed_scenario_retry_recommendation" =>
          "rerun_failed_scenario_from_source_manifest",
        "node_distribution_counts" => %{
          "mission_ops@node_a" => 1000,
          "mission_ops@node_b" => 1000
        },
        "node_distribution_total" => 2000,
        "task_supervisor_node_count" => 2,
        "execution_plan_distribution_mode" => "distributed_task_supervisors",
        "execution_plan_task_batch_count" => 40,
        "execution_plan_wave_count" => 2,
        "execution_plan_supervisor_count" => 2,
        "execution_plan_batch_propagation" => false,
        "adaptive_chunking_policy" => "explicit",
        "adaptive_chunking_reason" => "operator_supplied_task_chunk_size",
        "backend_acceptance_tier" => "reference_default",
        "reference_backend" => true,
        "requires_benchmark_artifact" => false,
        "requires_reference_match" => true,
        "failure_isolation" =>
          "failed scenario is reported without dropping completed scenario counts",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "scenario_count" => 0,
        "completed_scenario_count" => 0,
        "failed_scenario_count" => 0,
        "event_result_count" => 0,
        "task_chunk_size" => 0,
        "effective_task_concurrency" => 0,
        "timeout" => 0,
        "failed_scenario_row_count" => 0,
        "node_distribution_total" => 0,
        "task_supervisor_node_count" => 0,
        "execution_plan_task_batch_count" => 0,
        "execution_plan_wave_count" => 0,
        "execution_plan_supervisor_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external execution validation",
        "checks distributed execution counts, failed-scenario isolation, backend acceptance evidence, and model-limit boundary only"
      ]
    },
    "fixture.artifact.freshness_report.v1" => %{
      "id" => "fixture.artifact.freshness_report.v1",
      "model_id" => "artifact.freshness_report.v1",
      "reference_case" => "checked-in accepted-state freshness artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/freshness_report_v1.json",
        "contract" => "freshness_report.v1"
      },
      "expected" => %{
        "schema_contract" => "freshness_report.v1",
        "model" => "accepted_snapshot_horizon_and_quality_freshness",
        "status" => "current",
        "state_quality_status" => "accepted",
        "accepted_state_quality_level" => "accepted",
        "allowed_state_quality_level_count" => 2,
        "first_allowed_state_quality_level" => "accepted",
        "last_allowed_state_quality_level" => "planning_accepted",
        "stale_reason_count" => 0,
        "unknown_reason_count" => 0,
        "freshness_reason_total" => 0,
        "accepted_snapshot_age_s" => 0,
        "horizon_start_offset_s" => 0,
        "current_epoch_s" => 0,
        "horizon_starts_at_s" => 0,
        "max_horizon_start_offset_s" => 1,
        "max_snapshot_age_s" => 86_400,
        "artifact_only_no_schedule_mutation" => true,
        "model_limit_count" => 6
      },
      "tolerances" => %{
        "allowed_state_quality_level_count" => 0,
        "stale_reason_count" => 0,
        "unknown_reason_count" => 0,
        "freshness_reason_total" => 0,
        "accepted_snapshot_age_s" => 0,
        "horizon_start_offset_s" => 0,
        "current_epoch_s" => 0,
        "horizon_starts_at_s" => 0,
        "max_horizon_start_offset_s" => 0,
        "max_snapshot_age_s" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external freshness validation",
        "checks accepted snapshot freshness counts, horizon offsets, state-quality routing, and no-schedule-mutation boundary only"
      ]
    },
    "fixture.artifact.validation_reference_report.v1" => %{
      "id" => "fixture.artifact.validation_reference_report.v1",
      "model_id" => "artifact.validation_reference_report.v1",
      "reference_case" => "checked-in standalone validation reference report artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/validation_reference_report_v1.json",
        "contract" => "validation_reference_report.v1"
      },
      "expected" => %{
        "schema_contract" => "validation_reference_report.v1",
        "fixture_id" => "fixture.artifact.campaign_plan.leo_constellation_v1",
        "model_id" => "artifact.campaign_plan.v1",
        "validation_level" => "artifact_contract",
        "status" => "pass",
        "status_counts" => %{"pass" => 3},
        "check_count" => 3,
        "pass_check_count" => 3,
        "fail_check_count" => 0,
        "check_field_order" => "activity_count|candidate_activity_count|planner"
      },
      "tolerances" => %{
        "check_count" => 0,
        "pass_check_count" => 0,
        "fail_check_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external validation evidence",
        "checks standalone reference report status and check routing only"
      ]
    }
  }

  def all, do: @fixtures
end
