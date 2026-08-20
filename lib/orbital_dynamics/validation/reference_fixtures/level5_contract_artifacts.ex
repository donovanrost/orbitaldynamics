defmodule OrbitalDynamics.Validation.ReferenceFixtures.Level5ContractArtifacts do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.authority_context.v1" => %{
      "id" => "fixture.artifact.authority_context.v1",
      "model_id" => "artifact.authority_context.v1",
      "reference_case" => "effective immutable mission-operations authority context",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "producer" => "OrbitalDynamics.AuthorityContext.new!/1",
        "authority_source" => "mission-operations-authority-registry",
        "source_revision" => "authority-revision-17",
        "evaluation_time" => "2026-05-14T12:00:00Z"
      },
      "expected" => %{
        "schema_contract" => "authority_context.v1",
        "authority_context_id" =>
          "authority_context:b558e497b2879009d0b400b04173519ccff07f599bb4c8646f6daa485ac4d70a",
        "authority_source" => "mission-operations-authority-registry",
        "source_revision" => "authority-revision-17",
        "effective_from" => "2026-05-14T00:00:00.000000Z",
        "valid_until" => "2026-05-15T00:00:00.000000Z",
        "evaluation_time" => "2026-05-14T12:00:00.000000Z",
        "identity_matches_content" => true,
        "validation_status" => "valid"
      },
      "tolerances" => %{},
      "evidence" => [
        "generated through OrbitalDynamics.AuthorityContext.new!/1",
        "content identity and deterministic effective-time validation are re-evaluated by the observation builder",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2"
      ],
      "known_limits" => [
        "internal authority-boundary regression, not authorization or approval",
        "uses caller-supplied immutable evidence and evaluation time only"
      ]
    },
    "fixture.artifact.campaign_plan_search_trace.v1" => %{
      "id" => "fixture.artifact.campaign_plan_search_trace.v1",
      "model_id" => "artifact.campaign_plan_search_trace.v1",
      "reference_case" =>
        "bounded local search selects the feasible seed over a higher-scoring infeasible alternative",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "producer" => "OrbitalDynamics.campaign_plan_with_local_search/2",
        "alternative_count" => 3,
        "hard_feasibility" => true,
        "selection_contract" => "v1_outer_local_search_inner_greedy"
      },
      "expected" => %{
        "schema_contract" => "campaign_plan_search_trace.v1",
        "status" => "selected_plan",
        "selection_contract" => "v1_outer_local_search_inner_greedy",
        "selected_alternative_id" => "campaign_policy:seed",
        "selected_activity_count" => 1,
        "selected_timeline_scenario_id" => "leo_1",
        "selected_timeline_score" => 100.0,
        "selected_alternative_eligible" => true,
        "search_objective" => "maximize first ranked timeline aggregate score",
        "alternative_count" => 3,
        "eligible_count" => 2,
        "infeasible_count" => 1,
        "rejected_move_count" => 0,
        "source_evidence_registry_id" =>
          "local_search_source_evidence_registry:4f500aaf7c9b9ff5c57a02b29363fd13e0f64bd90662bc7d298ecaefe51d80bf",
        "source_evidence_registry_entry_count" => 3,
        "source_candidate_evidence_count" => 3
      },
      "tolerances" => %{
        "selected_activity_count" => 0,
        "selected_timeline_score" => 0.0,
        "alternative_count" => 0,
        "eligible_count" => 0,
        "infeasible_count" => 0,
        "rejected_move_count" => 0,
        "source_evidence_registry_entry_count" => 0,
        "source_candidate_evidence_count" => 0
      },
      "evidence" => [
        "generated through OrbitalDynamics.campaign_plan_with_local_search/2",
        "pins feasibility-aware selection and content-addressed source-evidence registry identity",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2"
      ],
      "known_limits" => [
        "internal deterministic local-search regression, not global optimality evidence",
        "covers one bounded three-alternative planning neighborhood"
      ]
    },
    "fixture.artifact.candidate_refresh_execution.v1" => %{
      "id" => "fixture.artifact.candidate_refresh_execution.v1",
      "model_id" => "artifact.candidate_refresh_execution.v1",
      "reference_case" =>
        "offline deterministic Earth J2-drag access and eclipse candidate refresh execution",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "producer" => "OrbitalDynamics.CandidateRefresh.run/2",
        "generated_at" => "2026-05-14T00:00:00Z",
        "snapshot_id" => "snapshot_a",
        "scenario_id" => "scenario_a"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh_execution.v1",
        "bundle_id" => "candidate_refresh.earth_j2_drag_access_eclipse.v1",
        "execution_mode" => "offline_deterministic",
        "policy_fingerprint" =>
          "fd5b00bbd6163ce8acb45053e70c9f48bbcde6e9825f7edf78d8c9868ce4738e",
        "refresh_id" => "candidate_refresh:scenario_a:31c1487694c2fff8",
        "study_id" => "scenario_a",
        "snapshot_id" => "snapshot_a",
        "spacecraft_id" => "sat_a",
        "scenario_id" => "scenario_a",
        "ground_station_id" => "station_a",
        "trajectory_sample_count" => 61,
        "access_window_count" => 1,
        "eclipse_interval_count" => 0,
        "candidate_activity_count" => 1,
        "downlink_candidate_count" => 1,
        "access_windows_sha256" =>
          "b9c0a7bb58af006d8da5aaffa358c5d0ad91b597bbf75584fb0fcd9094f237f3",
        "eclipse_intervals_sha256" =>
          "df071894cd939bc2281c5ca0325b880152b9717dd0fc0a3ce971847e02fb76e2",
        "candidate_source_windows_sha256" =>
          "5113bee9ada1793f4868eb59c5077d2d8567f0530376457e16452e7d17207198",
        "propagation_max_step_s" => 10.0,
        "access_boundary_refinement" => "bracketed_bisection",
        "external_validation_case_id" => "orekit_13_1_7_leo_j2_drag_access_eclipse",
        "external_validation_status" => "referenced_not_evaluated_by_runner",
        "model_limit_count" => 14
      },
      "tolerances" => %{
        "trajectory_sample_count" => 0,
        "access_window_count" => 0,
        "eclipse_interval_count" => 0,
        "candidate_activity_count" => 0,
        "downlink_candidate_count" => 0,
        "propagation_max_step_s" => 0.0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "generated through OrbitalDynamics.CandidateRefresh.run/2",
        "pins executable policy identity and access, eclipse, and source-window evidence digests",
        "external validation is referenced but explicitly not evaluated by the runner",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2"
      ],
      "known_limits" => [
        "internal exact-case execution regression, not generalized external validation",
        "offline deterministic policy bundle only"
      ]
    },
    "fixture.artifact.downlink_link_budget.v1" => %{
      "id" => "fixture.artifact.downlink_link_budget.v1",
      "model_id" => "artifact.downlink_link_budget.v1",
      "reference_case" =>
        "fixed single-carrier S-band downlink with positive geometry and RF margin",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "producer" => "OrbitalDynamics.downlink_link_budget/2",
        "contact_id" => "dl_1",
        "source_window_revision" => "window-r7",
        "rf_source_revision" => "rf-config-r4"
      },
      "expected" => %{
        "schema_contract" => "downlink_link_budget.v1",
        "id" =>
          "downlink_link_budget:a1f6eacc37216700be642b47f040c7b5e70fbef9a067bf0b6156a0134980cec8",
        "model" => "deterministic_point_one_way_downlink_budget",
        "status" => "supported",
        "pass" => true,
        "contact_id" => "dl_1",
        "source_window_id" => "access_1",
        "source_window_revision" => "window-r7",
        "received_power_dbw" => -109.28593688168769,
        "c_n0_db_hz" => 92.32353024816979,
        "eb_n0_db" => 35.3338302048096,
        "supported_data_rate_bps" => 500_000.0,
        "supported_volume_mb" => 7.5,
        "pass_fail_margin_db" => 30.3338302048096,
        "geometry_margin_deg" => 20.0,
        "source_revision" => "rf-config-r4",
        "identity_matches_content" => true,
        "model_limit_count" => 10
      },
      "tolerances" => %{
        "received_power_dbw" => 1.0e-12,
        "c_n0_db_hz" => 1.0e-12,
        "eb_n0_db" => 1.0e-12,
        "supported_data_rate_bps" => 1.0e-9,
        "supported_volume_mb" => 1.0e-12,
        "pass_fail_margin_db" => 1.0e-12,
        "geometry_margin_deg" => 1.0e-12,
        "model_limit_count" => 0
      },
      "evidence" => [
        "generated through OrbitalDynamics.downlink_link_budget/2",
        "pins contact and access-window identity plus derived FSPL-based link evidence",
        "content identity is recomputed by the observation builder",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2"
      ],
      "known_limits" => [
        "internal bounded engineering-screen regression, not calibrated network truth",
        "single supplied point geometry and fixed carrier mode only"
      ]
    },
    "fixture.artifact.resource_state_trace.v1" => %{
      "id" => "fixture.artifact.resource_state_trace.v1",
      "model_id" => "artifact.resource_state_trace.v1",
      "reference_case" =>
        "declared activity crosses battery depletion and recorder overflow bounds with retained evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "producer" => "OrbitalDynamics.resource_state_trace/3",
        "spacecraft_id" => "sc_1",
        "initial_battery_energy_remaining_wh" => 10.0,
        "initial_recorder_used_mb" => 90.0
      },
      "expected" => %{
        "schema_contract" => "resource_state_trace.v1",
        "id" =>
          "resource_state_trace:5eeb3bde733763915a1c97f2ba8e86317f8243cd3a0960dbedc556ffc52ae93b",
        "model" => "tier_1_declared_activity_resource_state_trace",
        "spacecraft_id" => "sc_1",
        "status" => "limit_exceeded",
        "input_activity_count" => 1,
        "applied_activity_count" => 1,
        "ignored_activity_count" => 0,
        "invalid_activity_count" => 0,
        "violation_count" => 1,
        "violation_type_order" => "battery_depletion|recorder_overflow",
        "trace_row_count" => 1,
        "first_activity_id" => "limit_crossing",
        "first_state_status" => "overflow_and_depletion",
        "final_battery_energy_remaining_wh" => 0.0,
        "final_recorder_used_mb" => 100.0,
        "battery_depletion_wh" => 15.0,
        "recorder_overflow_mb" => 20.0,
        "source" => "selected_timeline_revision:7",
        "identity_matches_content" => true,
        "model_limit_count" => 10
      },
      "tolerances" => %{
        "input_activity_count" => 0,
        "applied_activity_count" => 0,
        "ignored_activity_count" => 0,
        "invalid_activity_count" => 0,
        "violation_count" => 0,
        "trace_row_count" => 0,
        "final_battery_energy_remaining_wh" => 0.0,
        "final_recorder_used_mb" => 0.0,
        "battery_depletion_wh" => 0.0,
        "recorder_overflow_mb" => 0.0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "generated through OrbitalDynamics.resource_state_trace/3",
        "pins bounded state plus retained depletion and overflow evidence",
        "content identity is recomputed by the observation builder",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2"
      ],
      "known_limits" => [
        "internal declared-effect regression, not continuous resource dynamics",
        "one activity and battery plus recorder dimensions only"
      ]
    },
    "fixture.artifact.timeline_revision.v1" => %{
      "id" => "fixture.artifact.timeline_revision.v1",
      "model_id" => "artifact.timeline_revision.v1",
      "reference_case" =>
        "content-addressed timeline revision for one changed and one added activity",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "producer" => "OrbitalDynamics.Timeline.transition_application_report/3",
        "source_activity_count" => 2,
        "replacement_activity_count" => 3,
        "timeline_revision" => true
      },
      "expected" => %{
        "schema_contract" => "timeline_revision.v1",
        "identity_scheme" => "sha256_canonical_json",
        "canonicalization" => "timeline_revision_content.v1",
        "prior_revision_id" =>
          "timeline_revision.sha256:dffaa44b60b3cea3bc84fe66b23c4a76bc0c0ad75456c79ea8e5d1845cc57564",
        "transition_batch_id" =>
          "timeline_transition_batch.sha256:44edfa804fb45922d8fbb11a6d9bab4a857e348b477f35c73eead04f4be725b8",
        "replacement_revision_id" =>
          "timeline_revision.sha256:618664e4dd48fb75607d00f3efc81264e81e92369e5141078355dd93a4c07464",
        "valid_prior_revision_id" => true,
        "valid_transition_batch_id" => true,
        "valid_replacement_revision_id" => true,
        "replacement_differs_from_prior" => true
      },
      "tolerances" => %{},
      "evidence" => [
        "generated through OrbitalDynamics.Timeline.transition_application_report/3",
        "pins canonical prior, transition-batch, and replacement content identities",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2"
      ],
      "known_limits" => [
        "internal pure artifact replay evidence without revision store or locking",
        "does not mutate or publish a schedule"
      ]
    }
  }

  def all, do: @fixtures
end
