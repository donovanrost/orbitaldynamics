defmodule OrbitalDynamics.GoldenArtifactTest do
  use ExUnit.Case, async: false

  test "checked-in campaign artifact preserves the V1 planning surface" do
    campaign =
      "study_results/leo_constellation_campaign.json"
      |> read_json!()
      |> Map.fetch!("campaign_plan")

    assert %{
             "schema_version" => 1,
             "planner" => "OrbitalDynamics.CampaignPlanner.V1",
             "plan_id" => "campaign_plan:leo_constellation_campaign:2026-05-14T00:00:00Z",
             "study_id" => "leo_constellation_campaign",
             "candidate_activity_ids" => [
               "leo_1_downlink_equator_prime_1",
               "leo_1_observe_target_a_1"
             ],
             "planned_activity_ids" => ["leo_1_observe_target_a_1"],
             "contact_intent_ids" => ["leo_1_downlink_equator_prime_1"],
             "affected_contact_ids" => ["leo_1_downlink_equator_prime_1"],
             "ranked_timeline_activity_ids" => [["leo_1_observe_target_a_1"]],
             "ranked_timeline_scores" => [1417.273183]
           } == campaign_golden_surface(campaign)
  end

  test "checked-in campaign artifact preserves the V1 embedded report surfaces" do
    campaign =
      "study_results/leo_constellation_campaign.json"
      |> read_json!()
      |> Map.fetch!("campaign_plan")

    assert %{
             "resource_projection_report" => %{
               "schema_contract" => "resource_projection_report.v1",
               "model" => "thin_campaign_selected_activity_resource_projection",
               "input_resource_summary_count" => 1,
               "activity_count" => 1,
               "spacecraft_ids" => ["leo_1"],
               "observation_counts" => [1],
               "downlink_counts" => [0],
               "projected_storage_margins" => [0.75],
               "projected_downlink_margins" => [1.0],
               "warnings" => []
             },
             "operational_timeline_report" => %{
               "schema_contract" => "operational_timeline_report.v1",
               "model" => "selected_activity_operational_context_summary",
               "activity_count" => 1,
               "row_count" => 1,
               "contact_count" => 0,
               "command_count" => 0,
               "locked_count" => 0,
               "approved_count" => 0,
               "executed_count" => 0,
               "source_window_lineage_count" => 1,
               "row_activity_ids" => ["leo_1_observe_target_a_1"],
               "row_statuses" => ["planned"],
               "row_approval_statuses" => ["not_evaluated"],
               "row_operational_kinds" => ["observation"],
               "row_required_operator_actions" => ["review_activity_approval"],
               "row_operator_action_reasons" => ["approval_status_not_evaluated"],
               "row_cadence_import_statuses" => ["present"],
               "row_execution_boundaries" => ["planned_not_commanded"],
               "row_source_window_types" => ["target_visibility"],
               "row_timeline_ids" => [
                 "timeline:leo_1:observe:target_a:window:leo_1:target_visibility:target_a:1"
               ]
             },
             "link_capacity_report" => %{
               "schema_contract" => "link_capacity_report.v1",
               "model" => "fixed_rate_downlink_capacity_summary",
               "contact_count" => 1,
               "selected_contact_count" => 0,
               "estimated_throughput_mb" => 345.424242,
               "selected_estimated_throughput_mb" => 0.0,
               "ground_station_ids" => ["equator_prime"],
               "contact_ids" => [["leo_1_downlink_equator_prime_1"]]
             },
             "contact_allocation_report" => %{
               "schema_contract" => "contact_allocation_report.v1",
               "model" => "deterministic_station_contact_allocation",
               "input_contact_count" => 1,
               "allocated_contact_count" => 1,
               "deferred_contact_count" => 0,
               "blocked_contact_count" => 0,
               "row_contact_ids" => ["leo_1_downlink_equator_prime_1"],
               "row_allocation_statuses" => ["allocated"],
               "row_allocation_reasons" => ["available"]
             },
             "objective_satisfaction_report" => %{
               "schema_contract" => "objective_satisfaction_report.v1",
               "model" => "campaign_v1_selected_activity_objective_summary",
               "objective_count" => 4,
               "rows" => [
                 ["objective:target_coverage", "partial", 1, 1],
                 ["objective:downlink_completion", "no_requirement", 0, 0],
                 ["objective:target_commitment:target_a", "selected", 1, 1],
                 ["objective:target_commitment:target_b", "no_candidate_window", 0, 0]
               ]
             },
             "constraint_report" => %{
               "schema_contract" => "constraint_report.v1",
               "model" => "campaign_planner_local_constraint_summary",
               "constraint_count" => 3,
               "row_count" => 4,
               "status" => "pass",
               "row_constraint_ids" => [
                 "campaign:max_timeline_activities",
                 "campaign:min_activity_duration_s",
                 "campaign:min_activity_duration_s",
                 "campaign:avoid_eclipse"
               ],
               "row_metrics" => [
                 "activity_count",
                 "duration_s",
                 "duration_s",
                 "eclipse_overlap_s"
               ],
               "row_statuses" => ["pass", "pass", "pass", "pass"]
             },
             "operator_review_package" => %{
               "schema_contract" => "operator_review_package.v1",
               "source_artifact_type" => "campaign_plan.v1",
               "review_count" => 17,
               "approval_requirement_count" => 0,
               "contention_recommendation_count" => 0,
               "contact_allocation_review_count" => 1,
               "operational_timeline_count" => 1,
               "plan_delta_count" => 0,
               "timeline_protection_count" => 0,
               "realized_feedback_count" => 0,
               "warning_count" => 0,
               "risk_count" => 0,
               "recommendation_count" => 0,
               "ranking_comparison_count" => 0,
               "pareto_frontier_count" => 0,
               "tradeoff_count" => 0,
               "score_term_review_count" => 7,
               "objective_tradeoff_review_count" => 1,
               "row_review_types" => [
                 "operational_timeline_review",
                 "timeline_activity_precondition_review",
                 "contact_allocation_review"
               ],
               "row_actions" => [
                 "review_activity_approval",
                 "record_activity_precondition",
                 "review_contact_allocation"
               ]
             },
             "cadence_import_manifest" => %{
               "schema_contract" => "cadence_import_manifest.v1",
               "source_artifact_type" => "campaign_plan.v1",
               "row_count" => 18,
               "ready_count" => 2,
               "review_required_count" => 16,
               "blocked_count" => 0,
               "missing_import_count" => 0,
               "contact_allocation_import_count" => 1,
               "row_actions" => [
                 "import_proposed_contact",
                 "review_operational_timeline",
                 "review_timeline_precondition",
                 "review_contact_allocation",
                 "review_station_calendar",
                 "review_link_capacity",
                 "review_resource_projection",
                 "review_resource_projection",
                 "review_objective_satisfaction",
                 "review_objective_satisfaction",
                 "review_score_term",
                 "review_score_term",
                 "review_score_term",
                 "review_score_term",
                 "review_score_term",
                 "review_score_term",
                 "review_score_term",
                 "review_objective_tradeoff"
               ],
               "row_statuses" => [
                 "ready_for_import",
                 "review_required_before_import",
                 "ready_for_import",
                 "review_required_before_import",
                 "review_required_before_import",
                 "review_required_before_import",
                 "review_required_before_import",
                 "review_required_before_import",
                 "review_required_before_import",
                 "review_required_before_import",
                 "review_required_before_import",
                 "review_required_before_import",
                 "review_required_before_import",
                 "review_required_before_import",
                 "review_required_before_import",
                 "review_required_before_import",
                 "review_required_before_import",
                 "review_required_before_import"
               ]
             },
             "command_window_report" => %{
               "schema_contract" => "command_window_report.v1",
               "source" => "campaign_plan.activities",
               "window_count" => 0,
               "command_count" => 0,
               "tracking_count" => 0,
               "uplink_count" => 0,
               "health_check_count" => 0,
               "review_required_count" => 0,
               "row_activity_ids" => []
             }
           } == campaign_report_golden_surface(campaign)
  end

  test "checked-in relay data path summary preserves the Cadence-facing link handoff surface" do
    summary = read_json!("study_results/relay_data_path_summary_v1.json")

    assert {:ok, %{"schema_contract" => "relay_data_path_summary.v1", "status" => "pass"}} =
             OrbitalDynamics.Schema.validate_artifact(summary)

    assert %{
             "schema_contract" => "relay_data_path_summary.v1",
             "model" => "artifact_only_relay_data_path_summary",
             "source" => "relay_ops",
             "route_count" => 2,
             "relay_route_count" => 1,
             "direct_downlink_route_count" => 1,
             "source_spacecraft_ids" => ["sat_a", "sat_b"],
             "ground_station_ids" => ["dss_14", "dss_35"],
             "ground_downlink_contact_ids" => ["downlink_1", "downlink_2"],
             "relay_spacecraft_ids" => ["relay_1", "relay_2"],
             "custody_status_counts" => %{"confirmed" => 1, "missing_ack" => 1},
             "latency_status_counts" => %{"exceeds_limit" => 1, "within_limit" => 1},
             "risk_status_counts" => %{"high" => 1, "nominal" => 1},
             "maximum_latency_s" => 500.0,
             "maximum_latency_limit_s" => 300.0,
             "route_ids" => [
               "relay_data_path:sat_a:downlink_1:54b7e7ff594c",
               "route_direct"
             ],
             "route_ids_by_risk_status" => %{
               "high" => ["route_direct"],
               "nominal" => ["relay_data_path:sat_a:downlink_1:54b7e7ff594c"]
             },
             "row_route_ids" => [
               "relay_data_path:sat_a:downlink_1:54b7e7ff594c",
               "route_direct"
             ],
             "row_custody_statuses" => ["confirmed", "missing_ack"],
             "row_latency_statuses" => ["within_limit", "exceeds_limit"],
             "row_risk_statuses" => ["nominal", "high"],
             "row_risk_reasons" => [
               [],
               ["custody_missing_ack", "latency_exceeds_limit", "operator review queued"]
             ],
             "model_limits" => [
               "artifact_level_relay_data_path_summary",
               "no_crosslink_visibility_model",
               "no_relay_scheduling",
               "no_custody_acknowledgement_delivery",
               "no_provider_reservation",
               "no_schedule_mutation"
             ],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_relay_scheduling_or_schedule_mutation",
               "operator_authority" => "not_granted_by_summary",
               "provider_reservation" => "not_performed",
               "custody_acknowledgement_delivery" => "not_performed",
               "crosslink_visibility_model" => "not_evaluated"
             }
           } == relay_data_path_summary_surface(summary)
  end

  test "checked-in campaign plan matches the deterministic study run path" do
    campaign = read_json!("study_results/leo_constellation_campaign.json")

    output_path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_campaign_golden_#{System.unique_integer([:positive])}.json"
      )

    on_exit(fn -> File.rm(output_path) end)

    {:ok, generated_at, _offset} = DateTime.from_iso8601("2026-05-14T00:00:00Z")

    {:ok, manifest} =
      OrbitalDynamics.Study.Manifest.from_file("studies/leo_constellation_campaign.json")

    run_opts =
      Keyword.put(manifest.run_opts, :run_id, "leo_constellation_campaign-1778976392512956")

    {:ok, result_set} = OrbitalDynamics.run_study(manifest.study, run_opts)

    result_set
    |> OrbitalDynamics.ResultSet.Artifact.build(generated_at: generated_at)
    |> OrbitalDynamics.ResultSet.Artifact.write_json!(output_path)

    generated_campaign =
      output_path
      |> File.read!()
      |> :json.decode()

    assert normalize_campaign_artifact_for_exact_match(campaign) ==
             normalize_campaign_artifact_for_exact_match(generated_campaign)

    assert normalize_git_revisions(campaign["campaign_plan"]) ==
             normalize_git_revisions(generated_campaign["campaign_plan"])
  end

  test "checked-in repair artifact preserves the V2 repair surface" do
    repair = read_json!("study_results/leo_constellation_campaign_repair_v2.json")

    assert %{
             "schema_version" => 2,
             "planner" => "OrbitalDynamics.CampaignPlanner.V2",
             "source_plan_id" => "campaign_plan:leo_constellation_campaign:2026-05-14T00:00:00Z",
             "repair_id" => "2861de04a1feea9da43cee52e2ad6cdc7e6fcedf91dad323b67517b8cac87a0a",
             "transition_selected_activity_count" => 0,
             "transition_application_review_required_count" => 1,
             "approval_status" => "operator_review_required",
             "change_summary" => %{"canceled" => 1},
             "delta_actions" => ["canceled"],
             "delta_reasons" => ["failed_observation_no_viable_replacement_window"],
             "delta_has_source_context" => [true],
             "delta_has_replacement_context" => [false],
             "review_delta_has_source_identity" => [true],
             "source_candidate_rejection_report" => %{
               "schema_contract" => "candidate_rejection_report.v1",
               "source" => "mission_state_candidate_rejections",
               "candidate_count" => 1,
               "row_count" => 1,
               "rejected_count" => 1,
               "reviewable_count" => 1,
               "row_candidate_ids" => ["leo_1_observe_target_a_1"],
               "row_primary_rejection_reasons" => ["payload_unavailable"],
               "row_required_operator_actions" => ["review_candidate_rejection"]
             },
             "approval_actions" => ["cancel"],
             "approval_classifications" => ["operator_review_required"],
             "operational_timeline_report" => %{
               "schema_contract" => "operational_timeline_report.v1",
               "source" => "campaign_repair.activities",
               "activity_count" => 0,
               "row_count" => 0,
               "contact_count" => 0,
               "command_count" => 0,
               "rows" => []
             },
             "score_term_report" => %{
               "schema_contract" => "score_term_report.v1",
               "model" => "repair_score_terms",
               "source" => "campaign_repair.score_terms",
               "row_count" => 4,
               "score_term_keys" => [
                 "activity_score",
                 "candidate_rejection_pressure_penalty",
                 "schedule_churn_penalty",
                 "schedule_move_penalty"
               ],
               "row_term_keys" => [
                 "activity_score",
                 "candidate_rejection_pressure_penalty",
                 "schedule_churn_penalty",
                 "schedule_move_penalty"
               ],
               "row_selected" => [true, true, true, true]
             },
             "objective_tradeoff_report" => %{
               "schema_contract" => "objective_tradeoff_report.v1",
               "model" => "repair_score_term_tradeoffs",
               "ranking_count" => 1,
               "scenario_ids" => [
                 "campaign_plan:leo_constellation_campaign:2026-05-14T00:00:00Z"
               ],
               "scores" => [-101.0],
               "score_deltas" => [0.0],
               "activity_counts" => [0],
               "activity_ids" => [[]]
             },
             "constraint_report" => %{
               "schema_contract" => "constraint_report.v1",
               "model" => "campaign_repair_local_constraint_summary",
               "constraint_count" => 3,
               "row_count" => 1,
               "status" => "pass",
               "row_constraint_ids" => ["campaign:max_timeline_activities"],
               "row_metrics" => ["activity_count"],
               "row_statuses" => ["pass"]
             },
             "link_capacity_report" => %{
               "schema_contract" => "link_capacity_report.v1",
               "source" => "campaign_repair.activities",
               "contact_count" => 0,
               "selected_contact_count" => 0,
               "estimated_throughput_mb" => 0,
               "selected_estimated_throughput_mb" => 0,
               "rows" => []
             },
             "timeline_transition_application_report" => %{
               "schema_contract" => "timeline_transition_application_report.v1",
               "source" => "campaign_repair.timeline_transition_application",
               "source_activity_count" => 1,
               "replacement_activity_count" => 0,
               "application_count" => 1,
               "selected_activity_count" => 0,
               "review_required_count" => 1,
               "preserved_source_count" => 0,
               "recorded_replacement_count" => 0,
               "withheld_review_count" => 1,
               "selected_timeline_integrity_issue_count" => 0,
               "application_status_counts" => %{"operator_review_required" => 1},
               "transition_decision_counts" => %{"review" => 1},
               "required_operator_action_counts" => %{"review_removed_activity" => 1},
               "status_transition_counts" => %{"removed" => 1},
               "approval_transition_counts" => %{"removed" => 1},
               "row_activity_ids" => ["leo_1_observe_target_a_1"],
               "row_statuses" => ["operator_review_required"],
               "row_decisions" => ["review"],
               "selected_activity_ids" => []
             },
             "operator_review_package" => %{
               "schema_contract" => "operator_review_package.v1",
               "source_artifact_type" => "campaign_repair.v2",
               "review_count" => 15,
               "approval_requirement_count" => 1,
               "contention_recommendation_count" => 0,
               "candidate_rejection_review_count" => 1,
               "contact_allocation_review_count" => 0,
               "operational_timeline_count" => 0,
               "plan_delta_count" => 1,
               "timeline_protection_count" => 0,
               "realized_feedback_count" => 2,
               "warning_count" => 3,
               "risk_count" => 0,
               "recommendation_count" => 0,
               "ranking_comparison_count" => 0,
               "pareto_frontier_count" => 0,
               "tradeoff_count" => 0,
               "score_term_review_count" => 4,
               "objective_tradeoff_review_count" => 1,
               "row_review_types" => [
                 "approval_requirement",
                 "realized_feedback",
                 "realized_feedback"
               ],
               "row_actions" => [
                 "cancel",
                 "review_unplanned_realization",
                 "review_realized_exception"
               ]
             },
             "cadence_import_manifest" => %{
               "schema_contract" => "cadence_import_manifest.v1",
               "source_artifact_type" => "campaign_repair.v2",
               "row_count" => 15,
               "review_required_count" => 15,
               "candidate_rejection_import_count" => 1,
               "candidate_rejection_row_actions" => ["review_candidate_rejection"],
               "candidate_rejection_row_activity_ids" => ["leo_1_observe_target_a_1"]
             }
           } == repair_golden_surface(repair)
  end

  test "checked-in repair artifact matches the public V2 repair facade" do
    repair = read_json!("study_results/leo_constellation_campaign_repair_v2.json")

    output_path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_repair_golden_#{System.unique_integer([:positive])}.json"
      )

    on_exit(fn -> File.rm(output_path) end)

    "studies/leo_constellation_campaign_repair_v2.json"
    |> OrbitalDynamics.campaign_repair_from_file!()
    |> OrbitalDynamics.ResultSet.Artifact.write_json!(output_path)

    generated_repair =
      output_path
      |> File.read!()
      |> :json.decode()

    assert repair == generated_repair
  end

  test "checked-in strategy artifact preserves the V3 strategy surface" do
    strategy = read_json!("study_results/leo_constellation_campaign_strategy_v3.json")
    surface = strategy_golden_surface(strategy)

    assert %{
             "schema_version" => 3,
             "planner" => "OrbitalDynamics.CampaignPlanner.V3",
             "source_plan_id" => "campaign_plan:leo_constellation_campaign:2026-05-14T00:00:00Z",
             "strategy_id" => "31c90e98cfdbd83f118c18ccd9e3461980c0a84c8749726633bf98f50b315d69",
             "recommended_branch_id" => "derived_urgent_target_target_hot",
             "approval_status" => "operator_review_required",
             "recommendation_status" => "pass"
           } = surface

    assert length(surface["branch_ids"]) == 27

    assert [
             "derived_urgent_target_target_hot",
             "derived_operational_readiness_pressure_cadence_import",
             "derived_quality_gate_pressure_operator_review",
             "derived_combined_mission_state"
           ]
           |> Enum.all?(&(&1 in surface["branch_ids"]))

    assert Enum.take(surface["branch_scores"], 6) == [
             2550.398183,
             2024.598183,
             895.06485,
             895.06485,
             895.06485,
             389.398183
           ]

    assert surface["comparison_resource_fields"]
           |> Map.take([
             "first_repair_score",
             "first_repair_score_term_count",
             "first_repair_score_term_keys"
           ]) == %{
             "first_repair_score" => 1415.273183,
             "first_repair_score_term_count" => 5,
             "first_repair_score_term_keys" => [
               "activity_score",
               "candidate_diff_pressure_penalty",
               "resource_filter_pressure_penalty",
               "schedule_churn_penalty",
               "schedule_move_penalty"
             ]
           }

    assert surface["ranked_branch_ids"] ==
             Enum.take(surface["branch_ids"], 5) ++
               ["operator_placeholder_urgent", "derived_combined_mission_state"]

    assert surface["ranking_comparison_report"]["row_count"] == 27

    assert surface["pareto_frontier_report"]
           |> Map.take(["alternative_count", "frontier_count", "dominated_count"]) == %{
             "alternative_count" => 27,
             "frontier_count" => 20,
             "dominated_count" => 7
           }

    assert surface["score_term_report"]
           |> Map.take([
             "row_count",
             "score_term_keys",
             "pressure_row_count",
             "selected_pressure_row_count"
           ]) == %{
             "row_count" => 1674,
             "score_term_keys" => [
               "approval_boundary_pressure_penalty",
               "approval_load_penalty",
               "asset_balance_score",
               "battery_depletion_pressure_penalty",
               "branch_probability",
               "candidate_diff_pressure_penalty",
               "candidate_rejection_pressure_penalty",
               "command_window_pressure_penalty",
               "contact_allocation_pressure_penalty",
               "contact_contention_pressure_penalty",
               "contact_filter_pressure_penalty",
               "contact_intent_pressure_penalty",
               "coverage_score",
               "downlink_completion_score",
               "execution_feedback_pressure_penalty",
               "expected_score",
               "feedback_adjustment_score",
               "fuel_preservation_score",
               "import_readiness_pressure_penalty",
               "latency_penalty",
               "link_capacity_pressure_penalty",
               "maneuver_review_pressure_penalty",
               "mission_value_score",
               "model_acceptance_pressure_penalty",
               "objective_gap_pressure_penalty",
               "operational_readiness_pressure_penalty",
               "operational_timeline_pressure_penalty",
               "operator_training_pressure_penalty",
               "priority_commitment_score",
               "provider_counteroffer_pressure_penalty",
               "provider_reservation_request_pressure_penalty",
               "quality_gate_pressure_penalty",
               "raw_score",
               "refresh_budget_pressure_penalty",
               "refresh_freshness_pressure_penalty",
               "relay_data_path_pressure_penalty",
               "resource_availability_pressure_penalty",
               "resource_filter_pressure_penalty",
               "resource_margin_pressure_penalty",
               "resource_projection_pressure_penalty",
               "resource_score",
               "revisit_score",
               "risk_penalty",
               "schedule_stability_penalty",
               "schema_validation_pressure_penalty",
               "station_calendar_pressure_penalty",
               "station_reservation_conflict_pressure_penalty",
               "station_reservation_expiration_pressure_penalty",
               "storage_downlink_pressure_penalty",
               "timeline_activity_state_pressure_penalty",
               "timeline_dependency_impact_pressure_penalty",
               "timeline_diff_pressure_penalty",
               "timeline_feedback_pressure_penalty",
               "timeline_integrity_pressure_penalty",
               "timeline_lifecycle_pressure_penalty",
               "timeline_precondition_pressure_penalty",
               "timeline_preservation_pressure_penalty",
               "timeline_pressure_penalty",
               "timeline_publication_pressure_penalty",
               "timeline_transition_application_pressure_penalty",
               "validation_refresh_pressure_penalty",
               "validation_safety_case_pressure_penalty"
             ],
             "pressure_row_count" => 1242,
             "selected_pressure_row_count" => 46
           }

    assert surface["objective_tradeoff_report"]["ranking_count"] == 27

    assert surface["operator_review_package"]
           |> Map.take([
             "review_count",
             "contact_allocation_review_count",
             "score_term_review_count",
             "objective_tradeoff_review_count"
           ]) == %{
             "review_count" => 2359,
             "contact_allocation_review_count" => 25,
             "score_term_review_count" => 1805,
             "objective_tradeoff_review_count" => 54
           }

    assert surface["cadence_import_manifest"]
           |> Map.take([
             "row_count",
             "review_required_count",
             "contact_allocation_import_count"
           ]) == %{
             "row_count" => 2385,
             "review_required_count" => 2359,
             "contact_allocation_import_count" => 25
           }
  end

  test "checked-in strategy artifact matches the public V3 strategy facade" do
    strategy = read_json!("study_results/leo_constellation_campaign_strategy_v3.json")

    output_path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_strategy_golden_#{System.unique_integer([:positive])}.json"
      )

    on_exit(fn -> File.rm(output_path) end)

    "studies/leo_constellation_campaign_strategy_v3.json"
    |> OrbitalDynamics.campaign_strategy_from_file!()
    |> OrbitalDynamics.ResultSet.Artifact.write_json!(output_path)

    generated_strategy =
      output_path
      |> File.read!()
      |> :json.decode()

    assert_artifacts_equal(strategy, generated_strategy)
  end

  test "checked-in strategy artifact exposes current dedicated pressure score terms" do
    score_term_keys =
      "study_results/leo_constellation_campaign_strategy_v3.json"
      |> read_json!()
      |> get_in(["score_term_report", "score_term_keys"])

    assert [
             "approval_boundary_pressure_penalty",
             "candidate_diff_pressure_penalty",
             "execution_feedback_pressure_penalty",
             "maneuver_review_pressure_penalty",
             "model_acceptance_pressure_penalty",
             "objective_gap_pressure_penalty",
             "operational_timeline_pressure_penalty",
             "provider_reservation_request_pressure_penalty",
             "refresh_budget_pressure_penalty",
             "refresh_freshness_pressure_penalty",
             "resource_availability_pressure_penalty",
             "resource_filter_pressure_penalty",
             "resource_margin_pressure_penalty",
             "schema_validation_pressure_penalty",
             "station_calendar_pressure_penalty",
             "station_reservation_conflict_pressure_penalty",
             "station_reservation_expiration_pressure_penalty",
             "timeline_activity_state_pressure_penalty",
             "timeline_diff_pressure_penalty",
             "timeline_feedback_pressure_penalty",
             "timeline_lifecycle_pressure_penalty",
             "timeline_precondition_pressure_penalty",
             "validation_safety_case_pressure_penalty"
           ]
           |> Enum.all?(&(&1 in score_term_keys))
  end

  test "checked-in Monte Carlo artifact preserves the reproducibility report surface" do
    artifact = read_json!("study_results/leo_dispersion_monte_carlo.json")

    assert %{
             "study_id" => "leo_dispersion_monte_carlo",
             "schema_version" => 1,
             "report" => %{
               "schema_contract" => "monte_carlo_reproducibility_report.v1",
               "model" => "seeded_independent_normal_cartesian_dispersion",
               "generator" => "state_vector_dispersion",
               "rng" => "rand_exsss",
               "sampling_method" => "box_muller_transform",
               "seed" => 12345,
               "deterministic_seed" => true,
               "requested_count" => 20,
               "generated_scenario_count" => 20,
               "id_prefix" => "dispersion",
               "first_generated_scenario_ids" => ["dispersion_1", "dispersion_2", "dispersion_3"],
               "last_generated_scenario_ids" => [
                 "dispersion_18",
                 "dispersion_19",
                 "dispersion_20"
               ],
               "position_sigma_km" => [0.1, 0.1, 0.05],
               "velocity_sigma_km_s" => [0.0001, 0.0001, 0.00005],
               "known_limits" => [
                 "independent_axis_dispersion",
                 "no_covariance_matrix",
                 "no_truncated_distribution",
                 "not_a_statistical_validation"
               ]
             }
           } == monte_carlo_golden_surface(artifact)
  end

  test "checked-in study result artifacts do not stringify JSON null values" do
    paths = Path.wildcard("study_results/*.json")

    assert paths != []

    Enum.each(paths, fn path ->
      refute File.read!(path) =~ ~s("null"), path
    end)
  end

  test "checked-in campaign import manifests preserve embedded source review row joins" do
    rows =
      [
        read_json!("study_results/leo_constellation_campaign.json")["campaign_plan"],
        read_json!("study_results/leo_constellation_campaign_repair_v2.json"),
        read_json!("study_results/leo_constellation_campaign_strategy_v3.json")
      ]
      |> Enum.flat_map(fn artifact ->
        artifact
        |> get_in(["cadence_import_manifest", "rows"])
        |> Enum.filter(&is_map(&1["source_review_row"]))
      end)

    assert length(rows) > 0

    assert [] ==
             rows
             |> Enum.flat_map(&source_review_join_issues/1)
             |> Enum.sort()
  end

  defp campaign_golden_surface(campaign) do
    %{
      "schema_version" => campaign["schema_version"],
      "planner" => campaign["planner"],
      "plan_id" => campaign["plan_id"],
      "study_id" => campaign["study_id"],
      "candidate_activity_ids" => ids(campaign["candidate_activities"]),
      "planned_activity_ids" => ids(campaign["activities"]),
      "contact_intent_ids" => ids(campaign["contact_intents"]),
      "affected_contact_ids" =>
        values(campaign["station_calendar_report"]["affected_contacts"], "contact_id"),
      "ranked_timeline_activity_ids" =>
        Enum.map(campaign["ranked_timelines"], fn timeline ->
          ids(timeline["activities"])
        end),
      "ranked_timeline_scores" => rounded_values(campaign["ranked_timelines"], "score")
    }
  end

  defp campaign_report_golden_surface(campaign) do
    resource_report = campaign["resource_projection_report"]
    resource_rows = resource_report["projected_resources"]

    timeline_report = campaign["operational_timeline_report"]
    timeline_rows = timeline_report["rows"]

    link_report = campaign["link_capacity_report"]
    link_rows = link_report["rows"]

    allocation_report = campaign["contact_allocation_report"]
    allocation_rows = allocation_report["rows"]

    command_window_report = campaign["command_window_report"]
    command_window_rows = command_window_report["rows"]

    objective_report = campaign["objective_satisfaction_report"]
    constraint_report = campaign["constraint_report"]
    review_package = campaign["operator_review_package"]
    cadence_import_manifest = campaign["cadence_import_manifest"]
    manifest_rows = cadence_import_manifest["rows"] || []

    %{
      "resource_projection_report" => %{
        "schema_contract" => resource_report["schema_contract"],
        "model" => resource_report["model"],
        "input_resource_summary_count" => resource_report["input_resource_summary_count"],
        "activity_count" => resource_report["activity_count"],
        "spacecraft_ids" => values(resource_rows, "spacecraft_id"),
        "observation_counts" => values(resource_rows, "observation_count"),
        "downlink_counts" => values(resource_rows, "downlink_count"),
        "projected_storage_margins" => rounded_values(resource_rows, "projected_storage_margin"),
        "projected_downlink_margins" =>
          rounded_values(resource_rows, "projected_downlink_margin"),
        "warnings" => resource_report["warnings"]
      },
      "operational_timeline_report" => %{
        "schema_contract" => timeline_report["schema_contract"],
        "model" => timeline_report["model"],
        "activity_count" => timeline_report["activity_count"],
        "row_count" => timeline_report["row_count"],
        "contact_count" => timeline_report["contact_count"],
        "command_count" => timeline_report["command_count"],
        "locked_count" => timeline_report["locked_count"],
        "approved_count" => timeline_report["approved_count"],
        "executed_count" => timeline_report["executed_count"],
        "source_window_lineage_count" => timeline_report["source_window_lineage_count"],
        "row_activity_ids" => values(timeline_rows, "activity_id"),
        "row_statuses" => values(timeline_rows, "status"),
        "row_approval_statuses" => values(timeline_rows, "approval_status"),
        "row_operational_kinds" => values(timeline_rows, "operational_kind"),
        "row_required_operator_actions" => values(timeline_rows, "required_operator_action"),
        "row_operator_action_reasons" => values(timeline_rows, "operator_action_reason"),
        "row_cadence_import_statuses" => values(timeline_rows, "cadence_import_status"),
        "row_execution_boundaries" => values(timeline_rows, "execution_boundary"),
        "row_source_window_types" => values(timeline_rows, "source_window_type"),
        "row_timeline_ids" => values(timeline_rows, "timeline_id")
      },
      "link_capacity_report" => %{
        "schema_contract" => link_report["schema_contract"],
        "model" => link_report["model"],
        "contact_count" => link_report["contact_count"],
        "selected_contact_count" => link_report["selected_contact_count"],
        "estimated_throughput_mb" => Float.round(link_report["estimated_throughput_mb"], 6),
        "selected_estimated_throughput_mb" =>
          Float.round(link_report["selected_estimated_throughput_mb"] * 1.0, 6),
        "ground_station_ids" => values(link_rows, "ground_station_id"),
        "contact_ids" => values(link_rows, "contact_ids")
      },
      "contact_allocation_report" => %{
        "schema_contract" => allocation_report["schema_contract"],
        "model" => allocation_report["model"],
        "input_contact_count" => allocation_report["input_contact_count"],
        "allocated_contact_count" => allocation_report["allocated_contact_count"],
        "deferred_contact_count" => allocation_report["deferred_contact_count"],
        "blocked_contact_count" => allocation_report["blocked_contact_count"],
        "row_contact_ids" => values(allocation_rows, "contact_id"),
        "row_allocation_statuses" => values(allocation_rows, "allocation_status"),
        "row_allocation_reasons" => values(allocation_rows, "allocation_reason")
      },
      "objective_satisfaction_report" => %{
        "schema_contract" => objective_report["schema_contract"],
        "model" => objective_report["model"],
        "objective_count" => objective_report["objective_count"],
        "rows" =>
          Enum.map(objective_report["rows"], fn row ->
            [
              row["id"],
              row["status"],
              row["selected_count"],
              row["satisfied_count"]
            ]
          end)
      },
      "constraint_report" => %{
        "schema_contract" => constraint_report["schema_contract"],
        "model" => constraint_report["model"],
        "constraint_count" => constraint_report["constraint_count"],
        "row_count" => constraint_report["row_count"],
        "status" => constraint_report["status"],
        "row_constraint_ids" => values(constraint_report["rows"], "constraint_id"),
        "row_metrics" => values(constraint_report["rows"], "metric"),
        "row_statuses" => values(constraint_report["rows"], "status")
      },
      "operator_review_package" => review_package_surface(review_package),
      "cadence_import_manifest" => %{
        "schema_contract" => cadence_import_manifest["schema_contract"],
        "source_artifact_type" => cadence_import_manifest["source_artifact_type"],
        "row_count" => cadence_import_manifest["row_count"],
        "ready_count" => cadence_import_manifest["ready_count"],
        "review_required_count" => cadence_import_manifest["review_required_count"],
        "blocked_count" => cadence_import_manifest["blocked_count"],
        "missing_import_count" => cadence_import_manifest["missing_import_count"],
        "contact_allocation_import_count" =>
          Enum.count(manifest_rows, &(&1["import_action"] == "review_contact_allocation")),
        "row_actions" => values(manifest_rows, "import_action"),
        "row_statuses" => values(manifest_rows, "import_status")
      },
      "command_window_report" => %{
        "schema_contract" => command_window_report["schema_contract"],
        "source" => command_window_report["source"],
        "window_count" => command_window_report["window_count"],
        "command_count" => command_window_report["command_count"],
        "tracking_count" => command_window_report["tracking_count"],
        "uplink_count" => command_window_report["uplink_count"],
        "health_check_count" => command_window_report["health_check_count"],
        "review_required_count" => command_window_report["review_required_count"],
        "row_activity_ids" => values(command_window_rows, "activity_id")
      }
    }
  end

  defp repair_golden_surface(repair) do
    candidate_rejection_report = repair["source_candidate_rejection_report"] || %{}
    candidate_rejection_rows = candidate_rejection_report["rows"] || []
    review_package = Map.fetch!(repair, "operator_review_package")
    cadence_import_manifest = Map.fetch!(repair, "cadence_import_manifest")
    manifest_rows = cadence_import_manifest["rows"] || []

    candidate_rejection_import_rows =
      Enum.filter(manifest_rows, &(&1["source_review_type"] == "candidate_rejection_review"))

    %{
      "schema_version" => repair["schema_version"],
      "planner" => repair["planner"],
      "source_plan_id" => repair["source_plan_id"],
      "repair_id" => repair["repair_metadata"]["repair_id"],
      "transition_selected_activity_count" =>
        repair["repair_metadata"]["transition_selected_activity_count"],
      "transition_application_review_required_count" =>
        repair["repair_metadata"]["transition_application_review_required_count"],
      "approval_status" => repair["approval_status"],
      "change_summary" => repair["change_summary"],
      "delta_actions" => Enum.map(repair["deltas"], & &1["repair_action"]),
      "delta_reasons" => Enum.map(repair["deltas"], & &1["reason"]),
      "delta_has_source_context" =>
        Enum.map(repair["deltas"], &is_map(&1["source_activity_context"])),
      "delta_has_replacement_context" =>
        Enum.map(repair["deltas"], &is_map(&1["replacement_activity_context"])),
      "review_delta_has_source_identity" =>
        repair
        |> Map.fetch!("operator_review_package")
        |> Map.fetch!("rows")
        |> Enum.filter(&(&1["review_type"] == "plan_delta_review"))
        |> Enum.map(&is_map(&1["source_timeline_identity"])),
      "source_candidate_rejection_report" => %{
        "schema_contract" => candidate_rejection_report["schema_contract"],
        "source" => candidate_rejection_report["source"],
        "candidate_count" => candidate_rejection_report["candidate_count"],
        "row_count" => candidate_rejection_report["row_count"],
        "rejected_count" => candidate_rejection_report["rejected_count"],
        "reviewable_count" => candidate_rejection_report["reviewable_count"],
        "row_candidate_ids" => values(candidate_rejection_rows, "candidate_id"),
        "row_primary_rejection_reasons" =>
          values(candidate_rejection_rows, "primary_rejection_reason"),
        "row_required_operator_actions" =>
          values(candidate_rejection_rows, "required_operator_action")
      },
      "approval_actions" => Enum.map(repair["approval_requirements"], & &1["action"]),
      "approval_classifications" =>
        Enum.map(repair["approval_requirements"], & &1["policy_classification"]),
      "operational_timeline_report" =>
        repair
        |> Map.fetch!("operational_timeline_report")
        |> timeline_report_surface(),
      "score_term_report" =>
        repair
        |> Map.fetch!("score_term_report")
        |> score_term_report_surface(),
      "objective_tradeoff_report" =>
        repair
        |> Map.fetch!("objective_tradeoff_report")
        |> objective_tradeoff_report_surface(),
      "constraint_report" =>
        repair
        |> Map.fetch!("constraint_report")
        |> constraint_report_surface(),
      "link_capacity_report" =>
        repair
        |> Map.fetch!("link_capacity_report")
        |> link_capacity_report_surface(),
      "timeline_transition_application_report" =>
        repair
        |> Map.fetch!("timeline_transition_application_report")
        |> timeline_transition_application_report_surface(),
      "operator_review_package" =>
        review_package
        |> review_package_surface()
        |> Map.put(
          "candidate_rejection_review_count",
          review_package["candidate_rejection_review_count"]
        ),
      "cadence_import_manifest" => %{
        "schema_contract" => cadence_import_manifest["schema_contract"],
        "source_artifact_type" => cadence_import_manifest["source_artifact_type"],
        "row_count" => cadence_import_manifest["row_count"],
        "review_required_count" => cadence_import_manifest["review_required_count"],
        "candidate_rejection_import_count" => length(candidate_rejection_import_rows),
        "candidate_rejection_row_actions" =>
          values(candidate_rejection_import_rows, "import_action"),
        "candidate_rejection_row_activity_ids" =>
          values(candidate_rejection_import_rows, "activity_id")
      }
    }
  end

  defp timeline_transition_application_report_surface(report) do
    application_rows = report["applications"]
    selected_activities = report["selected_activities"]

    %{
      "schema_contract" => report["schema_contract"],
      "source" => report["source"],
      "source_activity_count" => report["source_activity_count"],
      "replacement_activity_count" => report["replacement_activity_count"],
      "application_count" => report["application_count"],
      "selected_activity_count" => report["selected_activity_count"],
      "review_required_count" => report["review_required_count"],
      "preserved_source_count" => report["preserved_source_count"],
      "recorded_replacement_count" => report["recorded_replacement_count"],
      "withheld_review_count" => report["withheld_review_count"],
      "selected_timeline_integrity_issue_count" =>
        report["selected_timeline_integrity_issue_count"],
      "application_status_counts" => report["application_status_counts"],
      "transition_decision_counts" => report["transition_decision_counts"],
      "required_operator_action_counts" => report["required_operator_action_counts"],
      "status_transition_counts" => report["status_transition_counts"],
      "approval_transition_counts" => report["approval_transition_counts"],
      "row_activity_ids" => values(application_rows, "source_activity_id"),
      "row_statuses" => values(application_rows, "application_status"),
      "row_decisions" => values(application_rows, "transition_decision"),
      "selected_activity_ids" => values(selected_activities, "id")
    }
  end

  defp timeline_report_surface(report) do
    %{
      "schema_contract" => report["schema_contract"],
      "source" => report["source"],
      "activity_count" => report["activity_count"],
      "row_count" => report["row_count"],
      "contact_count" => report["contact_count"],
      "command_count" => report["command_count"],
      "rows" => report["rows"]
    }
  end

  defp score_term_report_surface(report) do
    %{
      "schema_contract" => report["schema_contract"],
      "model" => report["model"],
      "source" => report["source"],
      "row_count" => report["row_count"],
      "score_term_keys" => report["score_term_keys"],
      "row_term_keys" => Enum.map(report["rows"], & &1["term_key"]),
      "row_selected" => Enum.map(report["rows"], & &1["selected"])
    }
  end

  defp objective_tradeoff_report_surface(report) do
    tradeoffs = report["tradeoffs"]

    %{
      "schema_contract" => report["schema_contract"],
      "model" => report["model"],
      "ranking_count" => report["ranking_count"],
      "scenario_ids" => Enum.map(tradeoffs, & &1["scenario_id"]),
      "scores" => Enum.map(tradeoffs, & &1["score"]),
      "score_deltas" => Enum.map(tradeoffs, & &1["score_delta_from_selected"]),
      "activity_counts" => Enum.map(tradeoffs, & &1["activity_count"]),
      "activity_ids" => Enum.map(tradeoffs, & &1["activity_ids"])
    }
  end

  defp constraint_report_surface(report) do
    %{
      "schema_contract" => report["schema_contract"],
      "model" => report["model"],
      "constraint_count" => report["constraint_count"],
      "row_count" => report["row_count"],
      "status" => report["status"],
      "row_constraint_ids" => values(report["rows"], "constraint_id"),
      "row_metrics" => values(report["rows"], "metric"),
      "row_statuses" => values(report["rows"], "status")
    }
  end

  defp link_capacity_report_surface(report) do
    %{
      "schema_contract" => report["schema_contract"],
      "source" => report["source"],
      "contact_count" => report["contact_count"],
      "selected_contact_count" => report["selected_contact_count"],
      "estimated_throughput_mb" => report["estimated_throughput_mb"],
      "selected_estimated_throughput_mb" => report["selected_estimated_throughput_mb"],
      "rows" => report["rows"]
    }
  end

  defp relay_data_path_summary_surface(summary) do
    rows = summary["rows"] || []

    %{
      "schema_contract" => summary["schema_contract"],
      "model" => summary["model"],
      "source" => summary["source"],
      "route_count" => summary["route_count"],
      "relay_route_count" => summary["relay_route_count"],
      "direct_downlink_route_count" => summary["direct_downlink_route_count"],
      "source_spacecraft_ids" => summary["source_spacecraft_ids"],
      "ground_station_ids" => summary["ground_station_ids"],
      "ground_downlink_contact_ids" => summary["ground_downlink_contact_ids"],
      "relay_spacecraft_ids" => summary["relay_spacecraft_ids"],
      "custody_status_counts" => summary["custody_status_counts"],
      "latency_status_counts" => summary["latency_status_counts"],
      "risk_status_counts" => summary["risk_status_counts"],
      "maximum_latency_s" => summary["maximum_latency_s"],
      "maximum_latency_limit_s" => summary["maximum_latency_limit_s"],
      "route_ids" => summary["route_ids"],
      "route_ids_by_risk_status" => summary["route_ids_by_risk_status"],
      "row_route_ids" => values(rows, "route_id"),
      "row_custody_statuses" => values(rows, "custody_status"),
      "row_latency_statuses" => values(rows, "latency_status"),
      "row_risk_statuses" => values(rows, "risk_status"),
      "row_risk_reasons" => values(rows, "risk_reasons"),
      "model_limits" => summary["model_limits"],
      "assumptions" =>
        Map.take(summary["assumptions"] || %{}, [
          "execution_boundary",
          "operator_authority",
          "provider_reservation",
          "custody_acknowledgement_delivery",
          "crosslink_visibility_model"
        ])
    }
  end

  defp strategy_golden_surface(strategy) do
    comparison_rows = get_in(strategy, ["branch_comparison_report", "rows"]) || []
    first_comparison_row = List.first(comparison_rows) || %{}
    ranking_comparison_report = Map.fetch!(strategy, "ranking_comparison_report")
    pareto_frontier_report = Map.fetch!(strategy, "pareto_frontier_report")
    score_term_report = Map.fetch!(strategy, "score_term_report")
    objective_tradeoff_report = Map.fetch!(strategy, "objective_tradeoff_report")
    cadence_import_manifest = Map.fetch!(strategy, "cadence_import_manifest")
    manifest_rows = cadence_import_manifest["rows"] || []
    selected_manifest_row = Enum.find(manifest_rows, &(&1["selected"] == true)) || %{}

    operational_feedback_provenance =
      Map.get(strategy, "operational_feedback_provenance", %{})

    operational_feedback_sources =
      Map.get(operational_feedback_provenance, "sources", [])

    downlink_constrained =
      Enum.find(strategy["branches"], &(&1["branch_id"] == "derived_downlink_constrained")) || %{}

    downlink_gap_event =
      downlink_constrained
      |> Map.get("events", [])
      |> Enum.find(&(&1["type"] == "downlink_completion_gap")) || %{}

    %{
      "schema_version" => strategy["schema_version"],
      "planner" => strategy["planner"],
      "source_plan_id" => strategy["source_plan_id"],
      "strategy_id" => strategy["strategy_metadata"]["strategy_id"],
      "branch_ids" => Enum.map(strategy["branches"], & &1["branch_id"]),
      "branch_scores" => rounded_values(strategy["branches"], "score"),
      "repair_reason_counts" => repair_reason_counts(strategy),
      "strategic_addition_explanation_reasons" =>
        (get_in(strategy, ["recommendation", "explanation"]) || [])
        |> Enum.filter(&(&1["type"] == "strategic_addition"))
        |> values("reason"),
      "downlink_constrained_gap_reasons" => downlink_gap_event["derivation_reasons"],
      "recommended_branch_id" => strategy["recommendation"]["recommended_branch_id"],
      "ranked_branch_ids" => strategy["recommendation"]["ranked_branch_ids"],
      "approval_status" => strategy["recommendation"]["approval_status"],
      "recommendation_status" => strategy["recommendation"]["status"],
      "tradeoff_dimensions" =>
        strategy["recommendation"]["tradeoffs"]
        |> Enum.map(& &1["dimension"]),
      "comparison_resource_fields" => %{
        "row_count" => length(comparison_rows),
        "resource_projection_branch_ids" =>
          strategy["branches"]
          |> Enum.filter(&Map.has_key?(&1, "resource_projection_report"))
          |> Enum.map(& &1["branch_id"]),
        "comparison_projection_branch_ids" =>
          comparison_rows
          |> Enum.filter(&Map.has_key?(&1, "resource_projection_spacecraft_count"))
          |> Enum.map(& &1["branch_id"]),
        "first_fuel_margin" => first_comparison_row["fuel_margin"],
        "first_storage_margin" => first_comparison_row["storage_margin"],
        "first_downlink_capacity_margin" => first_comparison_row["downlink_capacity_margin"],
        "first_spacecraft_availability" => first_comparison_row["spacecraft_availability"],
        "first_payload_availability" => first_comparison_row["payload_availability"],
        "first_resource_score_adjustment" => first_comparison_row["resource_score_adjustment"],
        "first_storage_limited_downlinked_mb" =>
          first_comparison_row["storage_limited_downlinked_mb"],
        "first_unused_downlink_capacity_mb" =>
          first_comparison_row["unused_downlink_capacity_mb"],
        "first_resource_risk_types" => first_comparison_row["resource_risk_types"],
        "first_repair_score" => Float.round(first_comparison_row["repair_score"] * 1.0, 6),
        "first_repair_score_term_count" => first_comparison_row["repair_score_term_count"],
        "first_repair_score_term_keys" => first_comparison_row["repair_score_term_keys"],
        "first_repair_link_contact_count" => first_comparison_row["repair_link_contact_count"],
        "first_repair_link_selected_contact_count" =>
          first_comparison_row["repair_link_selected_contact_count"],
        "first_repair_constraint_count" => first_comparison_row["repair_constraint_count"],
        "first_repair_constraint_row_count" =>
          first_comparison_row["repair_constraint_row_count"],
        "first_repair_constraint_status" => first_comparison_row["repair_constraint_status"],
        "first_repair_constraint_pass_count" =>
          first_comparison_row["repair_constraint_pass_count"],
        "first_repair_constraint_warning_count" =>
          first_comparison_row["repair_constraint_warning_count"],
        "first_repair_constraint_fail_count" =>
          first_comparison_row["repair_constraint_fail_count"],
        "first_repair_constraint_failed_ids" =>
          first_comparison_row["repair_constraint_failed_ids"],
        "first_repair_constraint_warning_ids" =>
          first_comparison_row["repair_constraint_warning_ids"]
      },
      "comparison_feedback_fields" => %{
        "row_count" => length(comparison_rows),
        "feedback_branch_ids" =>
          comparison_rows
          |> Enum.filter(&Map.has_key?(&1, "feedback_score_adjustment"))
          |> Enum.map(& &1["branch_id"]),
        "first_feedback_score_adjustment" =>
          first_comparison_row["feedback_score_adjustment"] |> Kernel.*(1.0) |> Float.round(6),
        "first_observation_success_factor" =>
          first_comparison_row["observation_success_factor"] |> Kernel.*(1.0) |> Float.round(6),
        "first_feedback_risk_types" => first_comparison_row["feedback_risk_types"]
      },
      "operational_feedback_provenance" => %{
        "source_count" => operational_feedback_provenance["source_count"],
        "input_keys" => operational_feedback_provenance["input_keys"],
        "explicit_request_override" =>
          operational_feedback_provenance["explicit_request_override"],
        "effective_sources" => operational_feedback_provenance["effective_sources"],
        "overridden_sources" => operational_feedback_provenance["overridden_sources"],
        "source_statuses" =>
          Enum.map(operational_feedback_sources, & &1["trust_boundary_status"]),
        "source_names" => Enum.map(operational_feedback_sources, & &1["source"])
      },
      "ranking_comparison_report" => %{
        "schema_contract" => ranking_comparison_report["schema_contract"],
        "source" => ranking_comparison_report["source"],
        "objective" => ranking_comparison_report["objective"],
        "left_label" => ranking_comparison_report["left_label"],
        "right_label" => ranking_comparison_report["right_label"],
        "row_count" => ranking_comparison_report["row_count"],
        "model_limits" => ranking_comparison_report["model_limits"],
        "winner" => ranking_comparison_report["winner"]
      },
      "pareto_frontier_report" => %{
        "schema_contract" => pareto_frontier_report["schema_contract"],
        "source" => pareto_frontier_report["source"],
        "alternative_count" => pareto_frontier_report["alternative_count"],
        "objective_count" => pareto_frontier_report["objective_count"],
        "frontier_count" => pareto_frontier_report["frontier_count"],
        "dominated_count" => pareto_frontier_report["dominated_count"],
        "frontier_ids" => pareto_frontier_report["frontier_ids"],
        "dominated_ids" => pareto_frontier_report["dominated_ids"],
        "model_limits" => pareto_frontier_report["model_limits"]
      },
      "score_term_report" => strategy_score_term_report_surface(score_term_report),
      "objective_tradeoff_report" =>
        strategy_objective_tradeoff_report_surface(objective_tradeoff_report),
      "operator_review_package" =>
        strategy
        |> Map.fetch!("operator_review_package")
        |> review_package_surface(),
      "cadence_import_manifest" => %{
        "schema_contract" => cadence_import_manifest["schema_contract"],
        "source_artifact_type" => cadence_import_manifest["source_artifact_type"],
        "row_count" => cadence_import_manifest["row_count"],
        "ready_count" => cadence_import_manifest["ready_count"],
        "review_required_count" => cadence_import_manifest["review_required_count"],
        "blocked_count" => cadence_import_manifest["blocked_count"],
        "missing_import_count" => cadence_import_manifest["missing_import_count"],
        "contact_allocation_import_count" =>
          Enum.count(manifest_rows, &(&1["import_action"] == "review_contact_allocation")),
        "row_actions" => manifest_rows |> values("import_action") |> Enum.take(3),
        "row_statuses" => manifest_rows |> values("import_status") |> Enum.take(3),
        "selected_branch_id" => selected_manifest_row["branch_id"],
        "selected_import_status" => selected_manifest_row["import_status"],
        "selected_operational_feedback_input_keys" =>
          selected_manifest_row["operational_feedback_input_keys"],
        "selected_operational_feedback_trust_boundary_status" =>
          selected_manifest_row["operational_feedback_trust_boundary_status"],
        "selected_operational_feedback_source_count" =>
          get_in(selected_manifest_row, [
            "source_operational_feedback_provenance",
            "source_count"
          ]),
        "selected_risk_types" => selected_manifest_row["risk_types"],
        "selected_target_ids" => selected_manifest_row["target_ids"]
      }
    }
  end

  defp review_package_surface(package) do
    rows = package["rows"] || []
    first_row = List.first(rows) || %{}

    surface = %{
      "schema_contract" => package["schema_contract"],
      "source_artifact_type" => package["source_artifact_type"],
      "review_count" => package["review_count"],
      "approval_requirement_count" => package["approval_requirement_count"],
      "contention_recommendation_count" => package["contention_recommendation_count"],
      "contact_allocation_review_count" => Map.get(package, "contact_allocation_review_count", 0),
      "operational_timeline_count" => Map.get(package, "operational_timeline_count", 0),
      "plan_delta_count" => Map.get(package, "plan_delta_count", 0),
      "timeline_protection_count" => Map.get(package, "timeline_protection_count", 0),
      "realized_feedback_count" => package["realized_feedback_count"],
      "warning_count" => package["warning_count"],
      "risk_count" => package["risk_count"],
      "recommendation_count" => package["recommendation_count"],
      "ranking_comparison_count" => Map.get(package, "ranking_comparison_count", 0),
      "pareto_frontier_count" => Map.get(package, "pareto_frontier_count", 0),
      "tradeoff_count" => Map.get(package, "tradeoff_count", 0),
      "row_review_types" => rows |> values("review_type") |> Enum.take(3),
      "row_actions" => rows |> values("action") |> Enum.take(3)
    }

    case Map.get(package, "score_term_review_count", 0) do
      count when count > 0 -> Map.put(surface, "score_term_review_count", count)
      _count -> surface
    end
    |> then(fn surface ->
      case Map.get(package, "objective_tradeoff_review_count", 0) do
        count when count > 0 -> Map.put(surface, "objective_tradeoff_review_count", count)
        _count -> surface
      end
    end)
    |> then(fn surface ->
      if Map.has_key?(first_row, "operational_feedback_input_keys") do
        Map.merge(surface, %{
          "first_row_operational_feedback_input_keys" =>
            first_row["operational_feedback_input_keys"],
          "first_row_operational_feedback_trust_boundary_status" =>
            first_row["operational_feedback_trust_boundary_status"],
          "first_row_operational_feedback_source_count" =>
            get_in(first_row, ["source_operational_feedback_provenance", "source_count"]),
          "first_row_risk_types" => first_row["risk_types"],
          "first_row_target_ids" => first_row["target_ids"]
        })
      else
        surface
      end
    end)
  end

  defp strategy_score_term_report_surface(report) do
    rows = report["rows"] || []
    first_row = List.first(rows) || %{}

    pressure_rows =
      Enum.filter(rows, &String.ends_with?(&1["term_key"] || "", "_pressure_penalty"))

    %{
      "schema_contract" => report["schema_contract"],
      "model" => report["model"],
      "source" => report["source"],
      "row_count" => report["row_count"],
      "score_term_keys" => report["score_term_keys"],
      "selected_branch_ids" =>
        rows
        |> Enum.filter(&(&1["selected"] == true))
        |> Enum.map(& &1["branch_id"])
        |> Enum.uniq(),
      "pressure_row_count" => length(pressure_rows),
      "selected_pressure_row_count" => Enum.count(pressure_rows, &(&1["selected"] == true)),
      "first_row_branch_id" => first_row["branch_id"],
      "first_row_term_key" => first_row["term_key"],
      "first_row_selected" => first_row["selected"]
    }
  end

  defp strategy_objective_tradeoff_report_surface(report) do
    rows = report["tradeoffs"] || []
    first_row = List.first(rows) || %{}

    %{
      "schema_contract" => report["schema_contract"],
      "model" => report["model"],
      "ranking_count" => report["ranking_count"],
      "selected_branch_ids" =>
        rows
        |> Enum.filter(&(&1["selected"] == true))
        |> Enum.map(& &1["branch_id"])
        |> Enum.uniq(),
      "first_row_branch_id" => first_row["branch_id"],
      "first_row_score_delta" => first_row["score_delta_from_selected"],
      "first_row_selected" => first_row["selected"]
    }
  end

  defp monte_carlo_golden_surface(artifact) do
    report = artifact["monte_carlo_reproducibility_report"]
    scenario_ids = report["generated_scenario_ids"]

    %{
      "study_id" => artifact["study_id"],
      "schema_version" => artifact["schema_version"],
      "report" => %{
        "schema_contract" => report["schema_contract"],
        "model" => report["model"],
        "generator" => report["generator"],
        "rng" => report["rng"],
        "sampling_method" => report["sampling_method"],
        "seed" => report["seed"],
        "deterministic_seed" => report["deterministic_seed"],
        "requested_count" => report["requested_count"],
        "generated_scenario_count" => report["generated_scenario_count"],
        "id_prefix" => report["id_prefix"],
        "first_generated_scenario_ids" => Enum.take(scenario_ids, 3),
        "last_generated_scenario_ids" => Enum.take(scenario_ids, -3),
        "position_sigma_km" => report["position_sigma_km"],
        "velocity_sigma_km_s" => report["velocity_sigma_km_s"],
        "known_limits" => report["known_limits"]
      }
    }
  end

  defp ids(rows), do: Enum.map(rows || [], & &1["id"])

  defp values(rows, key), do: Enum.map(rows || [], & &1[key])

  defp rounded_values(rows, key) do
    Enum.map(rows || [], fn row -> Float.round(row[key] * 1.0, 6) end)
  end

  defp normalize_campaign_artifact_for_exact_match(artifact) do
    artifact
    |> Map.drop(["execution_report", "run"])
    |> normalize_git_revisions()
    |> normalize_dropped_runtime_payload_metrics()
  end

  defp normalize_dropped_runtime_payload_metrics(%{"payload_metrics" => %{} = metrics} = artifact) do
    metrics =
      metrics
      |> Map.put("artifact_body_bytes", "__runtime_sections_normalized__")
      |> update_in(["sections"], fn
        %{} = sections ->
          sections
          |> normalize_payload_section_bytes("campaign_plan")
          |> normalize_payload_section_bytes("execution_report")
          |> normalize_payload_section_bytes("run")

        sections ->
          sections
      end)

    Map.put(artifact, "payload_metrics", metrics)
  end

  defp normalize_dropped_runtime_payload_metrics(artifact), do: artifact

  defp normalize_payload_section_bytes(sections, section) do
    update_in(sections, [section], fn
      %{} = payload_section -> Map.put(payload_section, "bytes", "__runtime_section_normalized__")
      payload_section -> payload_section
    end)
  end

  defp normalize_git_revisions(%{} = map) do
    Map.new(map, fn
      {"git_revision", value} when is_binary(value) -> {"git_revision", "__normalized__"}
      {key, value} -> {key, normalize_git_revisions(value)}
    end)
  end

  defp normalize_git_revisions(values) when is_list(values),
    do: Enum.map(values, &normalize_git_revisions/1)

  defp normalize_git_revisions(value), do: value

  defp source_review_join_issues(row) do
    source_review_row = row["source_review_row"]

    [
      source_review_join_issue(row, source_review_row, "source_review_row_id", "id"),
      source_review_join_issue(row, source_review_row, "source_review_type", "review_type"),
      source_review_join_issue(row, source_review_row, "source_review_action", "action"),
      source_review_join_issue(
        row,
        source_review_row,
        "source_branch_comparison",
        "source_branch_comparison"
      )
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp source_review_join_issue(row, source_review_row, row_field, source_field) do
    if row[row_field] == source_review_row[source_field] do
      nil
    else
      "#{row["id"]}: #{row_field} must match source_review_row.#{source_field}"
    end
  end

  defp repair_reason_counts(term) do
    term
    |> repair_reasons()
    |> Enum.frequencies()
    |> Enum.sort_by(fn {reason, _count} -> reason end)
    |> Enum.map(fn {reason, count} -> %{"reason" => reason, "count" => count} end)
  end

  defp repair_reasons(%{"repair" => %{"reason" => reason}} = map) when is_binary(reason) do
    [reason | map |> Map.delete("repair") |> repair_reasons()]
  end

  defp repair_reasons(map) when is_map(map) do
    map
    |> Map.values()
    |> Enum.flat_map(&repair_reasons/1)
  end

  defp repair_reasons(list) when is_list(list), do: Enum.flat_map(list, &repair_reasons/1)
  defp repair_reasons(_term), do: []

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end

  defp assert_artifacts_equal(expected, actual) do
    diffs = artifact_diffs(expected, actual)

    assert diffs == []
  end

  defp artifact_diffs(left, right, path \\ "$")

  defp artifact_diffs(left, right, path) when is_map(left) and is_map(right) do
    left
    |> Map.keys()
    |> Kernel.++(Map.keys(right))
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.flat_map(fn key ->
      artifact_diffs(Map.get(left, key, :__missing__), Map.get(right, key, :__missing__), [
        path,
        ".",
        to_string(key)
      ])
    end)
  end

  defp artifact_diffs(left, right, path) when is_list(left) and is_list(right) do
    left_count = length(left)
    right_count = length(right)

    0..(max(left_count, right_count) - 1)//1
    |> Enum.flat_map(fn index ->
      artifact_diffs(Enum.at(left, index, :__missing__), Enum.at(right, index, :__missing__), [
        path,
        "[",
        to_string(index),
        "]"
      ])
    end)
  end

  defp artifact_diffs(left, right, _path) when left == right, do: []

  defp artifact_diffs(left, right, path) do
    [
      %{
        path: IO.iodata_to_binary(path),
        expected: left,
        actual: right
      }
    ]
  end
end
