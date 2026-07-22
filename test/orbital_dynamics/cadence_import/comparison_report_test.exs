defmodule OrbitalDynamics.CadenceImport.ComparisonReportTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.Schema

  test "builds import rows from Pareto frontier report review rows" do
    report = %{
      "schema_contract" => "pareto_frontier_report.v1",
      "model" => "objective_vector_pareto_frontier",
      "source" => "campaign_strategy.branch_comparison_report",
      "alternative_count" => 2,
      "objective_count" => 2,
      "frontier_count" => 1,
      "dominated_count" => 1,
      "frontier_ids" => ["baseline"],
      "dominated_ids" => ["risky"],
      "objective_directions" => %{"score" => "maximize", "risk_count" => "minimize"},
      "rows" => [
        %{
          "id" => "baseline",
          "scenario_id" => "baseline",
          "objective_values" => %{"score" => 95.0, "risk_count" => 0},
          "objective_keys" => ["risk_count", "score"],
          "frontier" => true,
          "dominated_by_ids" => [],
          "dominates_ids" => ["risky"]
        },
        %{
          "id" => "risky",
          "scenario_id" => "risky",
          "objective_values" => %{"score" => 80.0, "risk_count" => 1},
          "objective_keys" => ["risk_count", "score"],
          "frontier" => false,
          "dominated_by_ids" => ["baseline"],
          "dominates_ids" => []
        }
      ],
      "assumptions" => %{"external_solver" => false}
    }

    manifest = CadenceImport.from_pareto_frontier_report(report)

    assert %{
             "schema_contract" => "cadence_import_manifest.v1",
             "source_artifact_type" => "pareto_frontier_report.v1",
             "source_artifact_id" => "campaign_strategy.branch_comparison_report",
             "row_count" => 2,
             "review_required_count" => 2,
             "import_action_counts" => %{"review_pareto_frontier" => 2},
             "import_status_counts" => %{"review_required_before_import" => 2},
             "cadence_import_status_counts" => %{"present" => 2}
           } = manifest

    assert %{
             "import_action" => "review_pareto_frontier",
             "source_review_type" => "pareto_frontier_review",
             "source" => "pareto_frontier_report.rows",
             "subject_id" => "risky",
             "branch_id" => "risky",
             "reason" => "review dominated branch risky: dominated by baseline",
             "frontier" => false,
             "dominated_by_ids" => ["baseline"],
             "source_pareto_frontier" => %{"scenario_id" => "risky"}
           } = Enum.find(manifest["rows"], &(&1["subject_id"] == "risky"))

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    stale_source_review =
      update_in(manifest, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"scenario_id" => "risky", "source_pareto_frontier" => %{}} = row ->
            row
            |> Map.put("dominated_by_ids", [])
            |> put_in(["source_pareto_frontier", "dominated_by_ids"], [])

          row ->
            row
        end)
      end)

    assert {:error, stale_source_review_report} = Schema.validate_artifact(stale_source_review)

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.source_review_row\.dominated_by_ids$/ and
                 &1["message"] == "must match dominated_by_ids on Cadence import row")
           )

    invalid_manifest = Map.put(manifest, "import_action_counts", %{"review_pareto_frontier" => 1})

    assert {:error, validation_report} = Schema.validate_artifact(invalid_manifest)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.import_action_counts")
           )
  end

  test "builds branch and ranking comparison import rows with typed evidence" do
    branch_manifest =
      CadenceImport.from_branch_comparison_report(%{
        "schema_contract" => "branch_comparison_report.v1",
        "source" => "campaign_strategy.branches",
        "recommended_branch_id" => "urgent",
        "row_count" => 1,
        "rows" => [
          %{
            "branch_id" => "baseline",
            "selected" => false,
            "score" => 72.0,
            "score_delta_from_recommended" => -8.0,
            "risk_count" => 2,
            "risk_types" => [
              "activity_type_suppressed_by_resource_summary",
              "activity_type_incompatible_with_resource_summary"
            ],
            "high_risk_types" => ["activity_type_incompatible_with_resource_summary"],
            "priority_commitment_required_target_count" => 2,
            "priority_commitment_satisfied_target_count" => 1,
            "priority_commitment_missed_target_count" => 1,
            "priority_commitment_required_target_ids" => ["target_alpha", "target_beta"],
            "priority_commitment_satisfied_target_ids" => ["target_alpha"],
            "priority_commitment_missed_target_ids" => ["target_beta"],
            "downlink_completion_required_contacts" => 2,
            "downlink_completion_planned_contacts" => 1,
            "downlink_completion_required_downlink_mb" => 120.0,
            "downlink_completion_planned_downlink_mb" => 70.0,
            "downlink_completion_ratio" => 0.58,
            "branch_actual_downlink_completion_ratio" => 0.5,
            "branch_timeline_publication_ids" => [
              "timeline_publication:review:published:v2:v1"
            ],
            "branch_timeline_publication_statuses" => [
              "published_with_downstream_invalidations"
            ],
            "branch_timeline_publication_downstream_invalidation_statuses" => [
              "invalidated"
            ],
            "branch_timeline_publication_invalidated_downstream_product_ids" => [
              "cadence_import:review:v1",
              "operator_review:review:v1"
            ],
            "branch_timeline_publication_changed_fields" => ["timeline_presence"],
            "branch_timeline_publication_review_timeline_ids" => [
              "timeline:review:health:0.0",
              "timeline:review:health:5.0"
            ],
            "branch_timeline_dependency_impact_activity_ids" => ["cmd_combo"],
            "branch_timeline_dependency_impact_timeline_ids" => [
              "timeline:command:20.0"
            ],
            "branch_timeline_dependency_impact_scopes" => ["source"],
            "branch_impacted_dependency_timeline_ids" => [
              "timeline:health_check:0.0"
            ],
            "branch_impacted_exclusive_with_activity_ids" => ["health_gate"],
            "branch_timeline_lifecycle_state_statuses" => ["review_required"],
            "branch_timeline_lifecycle_state_review_timeline_ids" => [
              "timeline:command:20.0"
            ],
            "branch_timeline_lifecycle_state_review_activity_ids" => ["cmd_combo"],
            "branch_timeline_lifecycle_state_required_operator_actions" => [
              "review_timeline_lifecycle_state"
            ],
            "branch_timeline_lifecycle_state_import_actions" => [
              "review_timeline_lifecycle_state"
            ],
            "branch_timeline_activity_lifecycle_state_activity_ids" => ["cmd_combo"],
            "branch_timeline_activity_lifecycle_state_timeline_ids" => [
              "timeline:command:20.0"
            ],
            "branch_timeline_activity_lifecycle_state_transition_decisions" => [
              "review_required"
            ],
            "branch_timeline_activity_lifecycle_state_required_operator_actions" => [
              "review_timeline_lifecycle_state"
            ],
            "branch_timeline_activity_lifecycle_state_import_actions" => [
              "review_timeline_lifecycle_state"
            ],
            "branch_timeline_activity_lifecycle_state_status_transition_categories" => [
              "terminal_regression"
            ],
            "branch_timeline_activity_lifecycle_state_approval_transition_categories" => [
              "operator_authority_required"
            ],
            "branch_timeline_activity_precondition_activity_ids" => ["cmd_combo"],
            "branch_timeline_activity_precondition_timeline_ids" => [
              "timeline:command:20.0"
            ],
            "branch_timeline_activity_precondition_statuses" => ["blocked"],
            "branch_timeline_activity_precondition_blocked_types" => [
              "missing_dependency"
            ],
            "branch_timeline_activity_precondition_dependency_timeline_ids" => [
              "timeline:health_check:0.0"
            ],
            "branch_timeline_activity_precondition_duplicate_dependency_activity_ids" => [
              "health_gate"
            ],
            "branch_timeline_activity_precondition_invalid_activity_input_reasons" => [
              "missing_activity_id"
            ],
            "branch_timeline_preservation_activity_ids" => ["cmd_combo"],
            "branch_timeline_preservation_timeline_ids" => [
              "timeline:command:20.0"
            ],
            "branch_timeline_preservation_statuses" => ["preservation_required"],
            "branch_timeline_preservation_protection_decisions" => ["preserve"],
            "branch_timeline_preservation_protection_categories" => [
              "locked_or_approved"
            ],
            "branch_timeline_preservation_preserve_timeline_ids" => [
              "timeline:command:20.0"
            ],
            "branch_timeline_preservation_review_change_activity_ids" => [
              "cmd_combo"
            ],
            "branch_operational_readiness_levels" => ["operator_review"],
            "branch_operational_readiness_import_classifications" => ["review_only"],
            "branch_operational_readiness_statuses" => ["review_required"],
            "branch_operational_readiness_source_report_paths" => [
              "mission_state.operational_readiness_report"
            ],
            "branch_operational_readiness_gate_ids" => ["readiness:cadence_import"],
            "branch_operational_readiness_gate_statuses" => ["review_required"],
            "branch_operational_readiness_gate_classifications" => ["review_only"],
            "branch_operational_readiness_review_required_gate_ids" => [
              "readiness:cadence_import"
            ],
            "branch_quality_gate_readiness_levels" => ["blocked"],
            "branch_quality_gate_import_classifications" => ["blocked"],
            "branch_quality_gate_statuses" => ["blocked"],
            "branch_quality_gate_source_report_paths" => [
              "mission_state.quality_gate_report"
            ],
            "branch_quality_gate_gate_classifications" => ["blocked"],
            "branch_quality_gate_blocked_gate_ids" => ["schema_validation"],
            "branch_quality_gate_blocked_row_ids" => ["quality_gate:schema_validation:1"],
            "branch_contact_allocation_statuses" => ["blocked"],
            "branch_contact_allocation_effective_statuses" => ["policy_blocked"],
            "branch_contact_allocation_reasons" => ["policy_blocked", "station_reserved"],
            "branch_contact_allocation_review_statuses" => ["review_required"],
            "branch_contact_allocation_approval_statuses" => ["blocked_by_policy"],
            "branch_contact_allocation_policy_classifications" => ["blocked_by_policy"],
            "branch_station_reservation_conflict_contact_ids" => ["review_dl_overflow"],
            "branch_station_reservation_conflict_reservation_ids" => ["reservation_partner"],
            "branch_station_reservation_conflict_match_statuses" => ["unmatched_overlap"],
            "branch_station_reservation_expiration_statuses" => ["expired", "missing"],
            "capacity_pack_group_ids" => ["station:equator_prime:pack:review"],
            "capacity_pack_statuses" => ["deferred_by_reduced_station_capacity_pack"],
            "capacity_pack_min_capacity_fraction" => 0.5,
            "capacity_pack_max_used_fraction" => 0.5,
            "capacity_pack_max_required_capacity_fraction" => 0.25,
            "capacity_pack_total_required_capacity_fraction" => 0.25,
            "capacity_pack_required_capacity_sources" => ["contact_required_capacity_fraction"],
            "capacity_pack_contact_ids_by_direction" => %{
              "downlink" => ["review_dl_primary", "review_dl_overflow"]
            },
            "capacity_pack_selected_contact_ids_by_direction" => %{
              "downlink" => ["review_dl_primary"]
            },
            "capacity_pack_deferred_contact_ids_by_direction" => %{
              "downlink" => ["review_dl_overflow"]
            },
            "capacity_pack_required_capacity_fraction_by_direction" => %{
              "downlink" => 0.75
            },
            "capacity_pack_selected_required_capacity_fraction_by_direction" => %{
              "downlink" => 0.5
            },
            "capacity_pack_deferred_required_capacity_fraction_by_direction" => %{
              "downlink" => 0.25
            },
            "coverage_observed_target_count" => 3,
            "revisit_count" => 2,
            "collection_latency_ratio" => 0.5,
            "collection_latency_objective_count" => 1,
            "collection_latency_observation_count" => 2,
            "collection_latency_satisfied_observation_count" => 1,
            "collection_latency_unsatisfied_observation_count" => 1,
            "feedback_score_adjustment" => -62.5,
            "contact_success_factor" => 0.4,
            "contact_success_factor_source" => "operational_feedback.contact_success_rate",
            "observation_success_factor" => 0.75,
            "observation_success_factor_source" =>
              "operational_feedback.observation_success_rate",
            "maneuver_success_factor" => 0.9,
            "maneuver_success_factor_source" => "operational_feedback.maneuver_success_rate",
            "command_success_factor" => 0.25,
            "command_success_factor_source" => "operational_feedback.command_success_rate",
            "station_throughput_factor" => 0.5,
            "station_throughput_factor_source" =>
              "operational_feedback.station_throughput_factor",
            "feedback_risk_types" => [
              "command_success_rate_low",
              "contact_success_rate_low",
              "station_throughput_factor_low"
            ],
            "fuel_margin" => 0.18,
            "power_margin" => 0.12,
            "storage_margin" => 0.2,
            "downlink_capacity_margin" => 0.3,
            "spacecraft_availability" => 0.5,
            "payload_availability" => 1.0,
            "antenna_availability" => 0.1,
            "resource_score_adjustment" => -48.0,
            "fuel_preservation_mode" => true,
            "resource_risk_types" => [
              "antenna_availability_low",
              "fuel_margin_low",
              "power_margin_low"
            ],
            "resource_pressure_statuses" => ["downlink_shortfall"],
            "resource_pressure_types" => ["downlink_shortfall", "storage_overflow"],
            "first_resource_pressure_kinds" => ["downlink_shortfall"],
            "first_resource_pressure_activity_id" => "dl_pressure",
            "first_resource_pressure_activity_type" => "downlink",
            "first_resource_pressure_kind" => "downlink_shortfall",
            "first_resource_pressure_starts_at_s" => 120.0,
            "first_resource_pressure_direction" => "downlink",
            "first_resource_pressure_ground_station_id" => "equator_prime",
            "first_resource_pressure_station_calendar_entry_id" => "station_calendar_entry_1",
            "first_resource_pressure_station_calendar_provider_id" => "ops_calendar",
            "first_resource_pressure_station_calendar_provider_entry_id" =>
              "ops_calendar_window_1",
            "first_resource_pressure_station_calendar_directions" => ["downlink"],
            "first_resource_pressure_source_window_id" =>
              "window:leo_1:ground_station_access:equator_prime:1",
            "first_resource_pressure_source_window_type" => "ground_station_access",
            "first_resource_pressure_source_window" => %{
              "id" => "window:leo_1:ground_station_access:equator_prime:1",
              "type" => "ground_station_access",
              "ground_station_id" => "equator_prime"
            },
            "repair_score" => 68.0,
            "repair_activity_score" => 80.0,
            "repair_schedule_churn_penalty" => -12.0,
            "repair_schedule_move_penalty" => -3.0,
            "repair_score_term_keys" => [
              "activity_score",
              "schedule_churn_penalty",
              "schedule_move_penalty"
            ],
            "repair_link_selected_estimated_throughput_mb" => 120.0,
            "repair_link_selected_capacity_adjusted_throughput_mb" => 96.0,
            "repair_link_required_downlink_mb" => 140.0,
            "repair_link_selected_downlink_shortfall_mb" => 44.0,
            "repair_link_downlink_requirement_status" => "shortfall",
            "repair_link_actual_throughput_mb" => 70.0,
            "repair_link_actual_downlink_completion_ratio" => 0.5,
            "repair_link_actual_downlink_shortfall_mb" => 70.0,
            "repair_link_actual_downlink_requirement_status" => "shortfall",
            "repair_constraint_count" => 2,
            "repair_constraint_row_count" => 3,
            "repair_constraint_status" => "fail",
            "repair_constraint_pass_count" => 1,
            "repair_constraint_warning_count" => 1,
            "repair_constraint_fail_count" => 1,
            "repair_constraint_failed_ids" => ["campaign:max_timeline_activities"],
            "repair_constraint_warning_ids" => ["campaign:avoid_eclipse"]
          }
        ]
      })

    assert %{
             "source_artifact_type" => "branch_comparison_report.v1",
             "import_action_counts" => %{"review_strategy_tradeoff" => 1},
             "rows" => [
               %{
                 "import_action" => "review_strategy_tradeoff",
                 "source_review_type" => "strategy_tradeoff",
                 "source_review_action" => "review_branch_comparison",
                 "source" => "branch_comparison_report.rows",
                 "subject_id" => "baseline",
                 "branch_id" => "baseline",
                 "reason" => "branch baseline score delta from recommended -8.0",
                 "dimension" => "branch_score",
                 "baseline" => 72.0,
                 "recommended" => 80.0,
                 "delta" => -8.0,
                 "risk_count" => 2,
                 "risk_types" => [
                   "activity_type_suppressed_by_resource_summary",
                   "activity_type_incompatible_with_resource_summary"
                 ],
                 "high_risk_types" => ["activity_type_incompatible_with_resource_summary"],
                 "priority_commitment_required_target_count" => 2,
                 "priority_commitment_satisfied_target_count" => 1,
                 "priority_commitment_missed_target_count" => 1,
                 "priority_commitment_required_target_ids" => ["target_alpha", "target_beta"],
                 "priority_commitment_satisfied_target_ids" => ["target_alpha"],
                 "priority_commitment_missed_target_ids" => ["target_beta"],
                 "downlink_completion_required_contacts" => 2,
                 "downlink_completion_planned_contacts" => 1,
                 "downlink_completion_required_downlink_mb" => 120.0,
                 "downlink_completion_planned_downlink_mb" => 70.0,
                 "downlink_completion_ratio" => 0.58,
                 "branch_actual_downlink_completion_ratio" => 0.5,
                 "branch_timeline_publication_ids" => [
                   "timeline_publication:review:published:v2:v1"
                 ],
                 "branch_timeline_publication_statuses" => [
                   "published_with_downstream_invalidations"
                 ],
                 "branch_timeline_publication_downstream_invalidation_statuses" => [
                   "invalidated"
                 ],
                 "branch_timeline_publication_invalidated_downstream_product_ids" => [
                   "cadence_import:review:v1",
                   "operator_review:review:v1"
                 ],
                 "branch_timeline_publication_changed_fields" => ["timeline_presence"],
                 "branch_timeline_publication_review_timeline_ids" => [
                   "timeline:review:health:0.0",
                   "timeline:review:health:5.0"
                 ],
                 "branch_timeline_dependency_impact_activity_ids" => ["cmd_combo"],
                 "branch_timeline_dependency_impact_scopes" => ["source"],
                 "branch_impacted_dependency_timeline_ids" => [
                   "timeline:health_check:0.0"
                 ],
                 "branch_timeline_lifecycle_state_statuses" => ["review_required"],
                 "branch_timeline_lifecycle_state_review_activity_ids" => ["cmd_combo"],
                 "branch_timeline_activity_lifecycle_state_transition_decisions" => [
                   "review_required"
                 ],
                 "branch_timeline_activity_lifecycle_state_status_transition_categories" => [
                   "terminal_regression"
                 ],
                 "branch_timeline_activity_precondition_statuses" => ["blocked"],
                 "branch_timeline_activity_precondition_dependency_timeline_ids" => [
                   "timeline:health_check:0.0"
                 ],
                 "branch_timeline_preservation_statuses" => ["preservation_required"],
                 "branch_timeline_preservation_protection_decisions" => ["preserve"],
                 "branch_operational_readiness_levels" => ["operator_review"],
                 "branch_operational_readiness_source_report_paths" => [
                   "mission_state.operational_readiness_report"
                 ],
                 "branch_operational_readiness_review_required_gate_ids" => [
                   "readiness:cadence_import"
                 ],
                 "branch_quality_gate_readiness_levels" => ["blocked"],
                 "branch_quality_gate_blocked_gate_ids" => ["schema_validation"],
                 "branch_quality_gate_blocked_row_ids" => [
                   "quality_gate:schema_validation:1"
                 ],
                 "branch_contact_allocation_statuses" => ["blocked"],
                 "branch_contact_allocation_effective_statuses" => ["policy_blocked"],
                 "branch_contact_allocation_reasons" => ["policy_blocked", "station_reserved"],
                 "branch_station_reservation_conflict_contact_ids" => ["review_dl_overflow"],
                 "branch_station_reservation_conflict_reservation_ids" => [
                   "reservation_partner"
                 ],
                 "branch_station_reservation_conflict_match_statuses" => ["unmatched_overlap"],
                 "branch_station_reservation_expiration_statuses" => ["expired", "missing"],
                 "capacity_pack_group_ids" => ["station:equator_prime:pack:review"],
                 "capacity_pack_statuses" => ["deferred_by_reduced_station_capacity_pack"],
                 "capacity_pack_min_capacity_fraction" => 0.5,
                 "capacity_pack_max_used_fraction" => 0.5,
                 "capacity_pack_max_required_capacity_fraction" => 0.25,
                 "capacity_pack_total_required_capacity_fraction" => 0.25,
                 "capacity_pack_required_capacity_sources" => [
                   "contact_required_capacity_fraction"
                 ],
                 "capacity_pack_contact_ids_by_direction" => %{
                   "downlink" => ["review_dl_primary", "review_dl_overflow"]
                 },
                 "capacity_pack_selected_contact_ids_by_direction" => %{
                   "downlink" => ["review_dl_primary"]
                 },
                 "capacity_pack_deferred_contact_ids_by_direction" => %{
                   "downlink" => ["review_dl_overflow"]
                 },
                 "capacity_pack_required_capacity_fraction_by_direction" => %{
                   "downlink" => 0.75
                 },
                 "capacity_pack_selected_required_capacity_fraction_by_direction" => %{
                   "downlink" => 0.5
                 },
                 "capacity_pack_deferred_required_capacity_fraction_by_direction" => %{
                   "downlink" => 0.25
                 },
                 "coverage_observed_target_count" => 3,
                 "revisit_count" => 2,
                 "collection_latency_ratio" => 0.5,
                 "collection_latency_objective_count" => 1,
                 "collection_latency_observation_count" => 2,
                 "collection_latency_satisfied_observation_count" => 1,
                 "collection_latency_unsatisfied_observation_count" => 1,
                 "feedback_score_adjustment" => -62.5,
                 "contact_success_factor" => 0.4,
                 "contact_success_factor_source" => "operational_feedback.contact_success_rate",
                 "observation_success_factor" => 0.75,
                 "observation_success_factor_source" =>
                   "operational_feedback.observation_success_rate",
                 "maneuver_success_factor" => 0.9,
                 "maneuver_success_factor_source" => "operational_feedback.maneuver_success_rate",
                 "command_success_factor" => 0.25,
                 "command_success_factor_source" => "operational_feedback.command_success_rate",
                 "station_throughput_factor" => 0.5,
                 "station_throughput_factor_source" =>
                   "operational_feedback.station_throughput_factor",
                 "feedback_risk_types" => [
                   "command_success_rate_low",
                   "contact_success_rate_low",
                   "station_throughput_factor_low"
                 ],
                 "fuel_margin" => 0.18,
                 "power_margin" => 0.12,
                 "storage_margin" => 0.2,
                 "downlink_capacity_margin" => 0.3,
                 "spacecraft_availability" => 0.5,
                 "payload_availability" => 1.0,
                 "antenna_availability" => 0.1,
                 "resource_score_adjustment" => -48.0,
                 "fuel_preservation_mode" => true,
                 "resource_risk_types" => [
                   "antenna_availability_low",
                   "fuel_margin_low",
                   "power_margin_low"
                 ],
                 "resource_pressure_statuses" => ["downlink_shortfall"],
                 "resource_pressure_types" => ["downlink_shortfall", "storage_overflow"],
                 "first_resource_pressure_kinds" => ["downlink_shortfall"],
                 "first_resource_pressure_activity_id" => "dl_pressure",
                 "first_resource_pressure_activity_type" => "downlink",
                 "first_resource_pressure_kind" => "downlink_shortfall",
                 "first_resource_pressure_starts_at_s" => 120.0,
                 "first_resource_pressure_direction" => "downlink",
                 "first_resource_pressure_ground_station_id" => "equator_prime",
                 "first_resource_pressure_station_calendar_entry_id" =>
                   "station_calendar_entry_1",
                 "first_resource_pressure_station_calendar_provider_id" => "ops_calendar",
                 "first_resource_pressure_station_calendar_provider_entry_id" =>
                   "ops_calendar_window_1",
                 "first_resource_pressure_station_calendar_directions" => ["downlink"],
                 "first_resource_pressure_source_window_id" =>
                   "window:leo_1:ground_station_access:equator_prime:1",
                 "first_resource_pressure_source_window_type" => "ground_station_access",
                 "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
                 "source_window" => %{
                   "id" => "window:leo_1:ground_station_access:equator_prime:1",
                   "type" => "ground_station_access",
                   "ground_station_id" => "equator_prime"
                 },
                 "repair_score" => 68.0,
                 "repair_link_selected_capacity_adjusted_throughput_mb" => 96.0,
                 "repair_link_required_downlink_mb" => 140.0,
                 "repair_link_selected_downlink_shortfall_mb" => 44.0,
                 "repair_link_downlink_requirement_status" => "shortfall",
                 "repair_link_actual_throughput_mb" => 70.0,
                 "repair_link_actual_downlink_completion_ratio" => 0.5,
                 "repair_link_actual_downlink_shortfall_mb" => 70.0,
                 "repair_link_actual_downlink_requirement_status" => "shortfall",
                 "repair_constraint_count" => 2,
                 "repair_constraint_row_count" => 3,
                 "repair_constraint_status" => "fail",
                 "repair_constraint_warning_count" => 1,
                 "repair_constraint_fail_count" => 1,
                 "repair_constraint_failed_ids" => ["campaign:max_timeline_activities"],
                 "repair_constraint_warning_ids" => ["campaign:avoid_eclipse"],
                 "source_tradeoff" => %{"branch_id" => "baseline"},
                 "source_branch_comparison" => %{
                   "branch_id" => "baseline",
                   "capacity_pack_max_required_capacity_fraction" => 0.25,
                   "capacity_pack_total_required_capacity_fraction" => 0.25,
                   "capacity_pack_required_capacity_sources" => [
                     "contact_required_capacity_fraction"
                   ],
                   "capacity_pack_selected_contact_ids_by_direction" => %{
                     "downlink" => ["review_dl_primary"]
                   },
                   "capacity_pack_deferred_required_capacity_fraction_by_direction" => %{
                     "downlink" => 0.25
                   },
                   "branch_timeline_publication_review_timeline_ids" => [
                     "timeline:review:health:0.0",
                     "timeline:review:health:5.0"
                   ],
                   "branch_timeline_dependency_impact_scopes" => ["source"],
                   "branch_timeline_activity_precondition_statuses" => ["blocked"],
                   "branch_timeline_preservation_statuses" => ["preservation_required"],
                   "branch_operational_readiness_source_report_paths" => [
                     "mission_state.operational_readiness_report"
                   ],
                   "branch_quality_gate_blocked_row_ids" => [
                     "quality_gate:schema_validation:1"
                   ],
                   "branch_contact_allocation_reasons" => [
                     "policy_blocked",
                     "station_reserved"
                   ],
                   "branch_station_reservation_conflict_reservation_ids" => [
                     "reservation_partner"
                   ],
                   "repair_link_actual_downlink_completion_ratio" => 0.5,
                   "first_resource_pressure_activity_id" => "dl_pressure",
                   "first_resource_pressure_ground_station_id" => "equator_prime",
                   "first_resource_pressure_station_calendar_provider_id" => "ops_calendar",
                   "first_resource_pressure_station_calendar_provider_entry_id" =>
                     "ops_calendar_window_1",
                   "first_resource_pressure_source_window_id" =>
                     "window:leo_1:ground_station_access:equator_prime:1"
                 }
               }
             ]
           } = branch_manifest

    stale_branch_source_review =
      update_in(branch_manifest, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"branch_id" => "baseline", "source_branch_comparison" => %{}} = row ->
            row
            |> Map.put("risk_count", 3)
            |> put_in(["source_branch_comparison", "risk_count"], 3)

          row ->
            row
        end)
      end)

    assert {:error, stale_branch_source_review_report} =
             Schema.validate_artifact(stale_branch_source_review)

    assert Enum.any?(
             stale_branch_source_review_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.source_review_row\.risk_count$/ and
                 &1["message"] == "must match risk_count on Cadence import row")
           )

    ranking_manifest =
      CadenceImport.from_ranking_comparison_report(%{
        "schema_contract" => "ranking_comparison_report.v1",
        "model" => "scenario_ranking_pairwise_delta",
        "source" => "optimizer.compare_rankings",
        "objective" => "expected_score",
        "objective_direction" => "maximize",
        "left_label" => "baseline",
        "right_label" => "repair",
        "left_count" => 1,
        "right_count" => 1,
        "matched_count" => 1,
        "left_only_count" => 0,
        "right_only_count" => 0,
        "row_count" => 1,
        "rows" => [
          %{
            "scenario_id" => "burn_b",
            "status" => "matched",
            "left_rank" => 2,
            "right_rank" => 1,
            "rank_delta" => 1,
            "left_value" => 84.0,
            "right_value" => 99.0,
            "value_delta" => 15.0
          }
        ]
      })

    assert %{
             "source_artifact_type" => "ranking_comparison_report.v1",
             "import_action_counts" => %{"review_ranking_comparison" => 1},
             "rows" => [
               %{
                 "import_action" => "review_ranking_comparison",
                 "source_review_type" => "ranking_comparison_review",
                 "source" => "ranking_comparison_report.rows",
                 "subject_id" => "burn_b",
                 "scenario_id" => "burn_b",
                 "reason" =>
                   "review ranking comparison for burn_b: matched, rank delta 1, value delta 15.0",
                 "left_rank" => 2,
                 "right_rank" => 1,
                 "rank_delta" => 1,
                 "left_value" => 84.0,
                 "right_value" => 99.0,
                 "value_delta" => 15.0,
                 "source_ranking_comparison" => %{"scenario_id" => "burn_b"}
               }
             ]
           } = ranking_manifest

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(branch_manifest)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(ranking_manifest)

    stale_ranking_source_review =
      update_in(ranking_manifest, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"scenario_id" => "burn_b", "source_ranking_comparison" => %{}} = row ->
            row
            |> Map.put("value_delta", 12.0)
            |> put_in(["source_ranking_comparison", "value_delta"], 12.0)

          row ->
            row
        end)
      end)

    assert {:error, stale_ranking_source_review_report} =
             Schema.validate_artifact(stale_ranking_source_review)

    assert Enum.any?(
             stale_ranking_source_review_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.source_review_row\.value_delta$/ and
                 &1["message"] == "must match value_delta on Cadence import row")
           )
  end
end
