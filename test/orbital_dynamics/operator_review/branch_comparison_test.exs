defmodule OrbitalDynamics.OperatorReview.BranchComparisonTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "branch comparison report source ids fall back through defaults" do
    assert %{"source_artifact_id" => "branch-comparison:report"} =
             OperatorReview.from_branch_comparison_report(%{
               id: :"branch-comparison:report"
             })

    assert %{"source_artifact_id" => "branch-comparison:source"} =
             OperatorReview.from_branch_comparison_report(%{
               source: :"branch-comparison:source"
             })

    assert %{"source_artifact_id" => "branch_comparison_report"} =
             OperatorReview.from_branch_comparison_report(%{})
  end

  test "builds review package from standalone branch comparison report rows" do
    report = %{
      "schema_contract" => "branch_comparison_report.v1",
      "model" => "deterministic_strategy_branch_score_comparison",
      "source" => "campaign_strategy.branches",
      "branch_count" => 2,
      "recommended_branch_id" => "urgent",
      "rows" => [
        %{
          "id" => "branch_comparison:urgent",
          "rank" => 1,
          "branch_id" => "urgent",
          "score" => 80.0,
          "score_delta_from_recommended" => 0.0,
          "selected" => true,
          "approval_status" => "operator_review_required",
          "risk_count" => 1,
          "risk_types" => [
            "activity_type_suppressed_by_resource_summary",
            "activity_type_incompatible_with_resource_summary"
          ],
          "high_risk_types" => ["activity_type_incompatible_with_resource_summary"],
          "approval_requirement_count" => 1,
          "repair_delta_count" => 0,
          "score_terms" => %{"expected_score" => 80.0},
          "repair_score" => 70.0,
          "repair_activity_score" => 90.0,
          "repair_schedule_churn_penalty" => -20.0,
          "repair_schedule_move_penalty" => 0.0,
          "repair_score_term_keys" => [
            "activity_score",
            "schedule_churn_penalty",
            "schedule_move_penalty"
          ],
          "repair_link_selected_estimated_throughput_mb" => 120.0,
          "repair_link_selected_capacity_adjusted_throughput_mb" => 80.0,
          "repair_link_required_downlink_mb" => 100.0,
          "repair_link_selected_downlink_shortfall_mb" => 20.0,
          "repair_link_downlink_requirement_status" => "shortfall",
          "repair_link_actual_throughput_mb" => 65.0,
          "repair_link_actual_downlink_completion_ratio" => 0.65,
          "repair_link_actual_downlink_shortfall_mb" => 35.0,
          "repair_link_actual_downlink_requirement_status" => "shortfall",
          "repair_constraint_count" => 2,
          "repair_constraint_row_count" => 3,
          "repair_constraint_status" => "fail",
          "repair_constraint_pass_count" => 1,
          "repair_constraint_warning_count" => 1,
          "repair_constraint_fail_count" => 1,
          "repair_constraint_failed_ids" => ["campaign:max_timeline_activities"],
          "repair_constraint_warning_ids" => ["campaign:avoid_eclipse"],
          "contact_success_factor" => 0.4,
          "contact_success_factor_source" => "operational_feedback.contact_success_rate",
          "observation_success_factor" => 0.6,
          "observation_success_factor_source" => "operational_feedback.observation_success_rate",
          "maneuver_success_factor" => 0.8,
          "maneuver_success_factor_source" => "operational_feedback.maneuver_success_rate",
          "command_success_factor" => 0.5,
          "command_success_factor_source" => "operational_feedback.command_success_rate",
          "station_throughput_factor" => 0.75,
          "station_throughput_factor_source" => "operational_feedback.station_throughput_factor",
          "branch_scenario_ids" => ["leo_1"],
          "branch_target_ids" => ["target_hot"],
          "branch_collection_ids" => ["collection_hot"],
          "branch_product_ids" => ["product_hot"],
          "branch_payload_ids" => ["payload_hot"],
          "branch_instrument_ids" => ["instrument_hot"],
          "branch_objective_ids" => ["objective:latency_hot"],
          "branch_objective_types" => ["collection_latency"],
          "branch_feedback_sources" => ["prior_plan.source_objective_satisfaction_report"],
          "branch_feedback_scopes" => ["objective_satisfaction"],
          "branch_source_activity_ids" => ["obs_hot"],
          "branch_max_latency_s" => 180.0,
          "branch_planned_latency_s" => 420.0,
          "branch_required_downlink_mb" => 30.0,
          "branch_planned_downlink_mb" => 0.0,
          "branch_actual_downlink_completion_ratio" => 0.65,
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
          "resource_pressure_statuses" => ["downlink_shortfall"],
          "resource_pressure_types" => ["downlink_shortfall", "storage_overflow"],
          "first_resource_pressure_kinds" => ["downlink_shortfall"],
          "first_resource_pressure_activity_id" => "urgent_downlink",
          "first_resource_pressure_activity_type" => "downlink",
          "first_resource_pressure_kind" => "downlink_shortfall",
          "first_resource_pressure_starts_at_s" => 600.0,
          "first_resource_pressure_direction" => "downlink",
          "first_resource_pressure_ground_station_id" => "equator_prime",
          "first_resource_pressure_station_calendar_entry_id" => "station_calendar_entry_1",
          "first_resource_pressure_station_calendar_provider_id" => "ops_calendar",
          "first_resource_pressure_station_calendar_provider_entry_id" => "ops_calendar_window_1",
          "first_resource_pressure_station_calendar_directions" => ["downlink"],
          "first_resource_pressure_source_window_id" =>
            "window:leo_1:ground_station_access:equator_prime:1",
          "first_resource_pressure_source_window_type" => "ground_station_access",
          "first_resource_pressure_source_window" => %{
            "id" => "window:leo_1:ground_station_access:equator_prime:1",
            "type" => "ground_station_access",
            "ground_station_id" => "equator_prime"
          }
        },
        %{
          "id" => "branch_comparison:baseline",
          "rank" => 2,
          "branch_id" => "baseline",
          "score" => 50.0,
          "score_delta_from_recommended" => -30.0,
          "selected" => false,
          "approval_status" => "auto_approvable",
          "risk_count" => 0,
          "approval_requirement_count" => 0,
          "repair_delta_count" => 0,
          "score_terms" => %{"expected_score" => 50.0}
        }
      ],
      "assumptions" => %{"score_delta_from_recommended" => "row_minus_recommended"}
    }

    package = OperatorReview.from_branch_comparison_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "branch_comparison_report.v1",
             "source_artifact_id" => "campaign_strategy.branches",
             "review_count" => 2,
             "tradeoff_count" => 2
           } = package

    first_row = List.first(package["rows"])

    assert %{
             "review_type" => "strategy_tradeoff",
             "source" => "branch_comparison_report.rows",
             "subject_id" => "urgent",
             "branch_id" => "urgent",
             "required_operator_action" => "review_branch_comparison",
             "dimension" => "branch_score",
             "baseline" => 80.0,
             "recommended" => 80.0,
             "risk_count" => 1,
             "risk_types" => [
               "activity_type_suppressed_by_resource_summary",
               "activity_type_incompatible_with_resource_summary"
             ],
             "high_risk_types" => ["activity_type_incompatible_with_resource_summary"],
             "repair_score" => 70.0,
             "repair_activity_score" => 90.0,
             "repair_schedule_churn_penalty" => -20.0,
             "repair_score_term_keys" => [
               "activity_score",
               "schedule_churn_penalty",
               "schedule_move_penalty"
             ],
             "repair_link_selected_capacity_adjusted_throughput_mb" => 80.0,
             "repair_link_required_downlink_mb" => 100.0,
             "repair_link_selected_downlink_shortfall_mb" => 20.0,
             "repair_link_downlink_requirement_status" => "shortfall",
             "repair_link_actual_throughput_mb" => 65.0,
             "repair_link_actual_downlink_completion_ratio" => 0.65,
             "repair_link_actual_downlink_shortfall_mb" => 35.0,
             "repair_link_actual_downlink_requirement_status" => "shortfall",
             "repair_constraint_count" => 2,
             "repair_constraint_row_count" => 3,
             "repair_constraint_status" => "fail",
             "repair_constraint_warning_count" => 1,
             "repair_constraint_fail_count" => 1,
             "repair_constraint_failed_ids" => ["campaign:max_timeline_activities"],
             "repair_constraint_warning_ids" => ["campaign:avoid_eclipse"],
             "contact_success_factor_source" => "operational_feedback.contact_success_rate",
             "observation_success_factor_source" =>
               "operational_feedback.observation_success_rate",
             "maneuver_success_factor_source" => "operational_feedback.maneuver_success_rate",
             "command_success_factor_source" => "operational_feedback.command_success_rate",
             "station_throughput_factor_source" =>
               "operational_feedback.station_throughput_factor",
             "branch_target_ids" => ["target_hot"],
             "branch_collection_ids" => ["collection_hot"],
             "branch_product_ids" => ["product_hot"],
             "branch_payload_ids" => ["payload_hot"],
             "branch_instrument_ids" => ["instrument_hot"],
             "branch_objective_ids" => ["objective:latency_hot"],
             "branch_objective_types" => ["collection_latency"],
             "branch_feedback_sources" => ["prior_plan.source_objective_satisfaction_report"],
             "branch_feedback_scopes" => ["objective_satisfaction"],
             "branch_source_activity_ids" => ["obs_hot"],
             "branch_max_latency_s" => 180.0,
             "branch_planned_latency_s" => 420.0,
             "branch_required_downlink_mb" => 30.0,
             "branch_actual_downlink_completion_ratio" => 0.65,
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
             "branch_quality_gate_blocked_row_ids" => ["quality_gate:schema_validation:1"],
             "branch_contact_allocation_statuses" => ["blocked"],
             "branch_contact_allocation_effective_statuses" => ["policy_blocked"],
             "branch_contact_allocation_reasons" => ["policy_blocked", "station_reserved"],
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
             "resource_pressure_statuses" => ["downlink_shortfall"],
             "resource_pressure_types" => ["downlink_shortfall", "storage_overflow"],
             "first_resource_pressure_kinds" => ["downlink_shortfall"],
             "first_resource_pressure_activity_id" => "urgent_downlink",
             "first_resource_pressure_activity_type" => "downlink",
             "first_resource_pressure_kind" => "downlink_shortfall",
             "first_resource_pressure_starts_at_s" => 600.0,
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
             "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
             "source_branch_comparison" => %{
               "branch_id" => "urgent",
               "branch_collection_ids" => ["collection_hot"],
               "branch_actual_downlink_completion_ratio" => 0.65,
               "capacity_pack_max_required_capacity_fraction" => 0.25,
               "capacity_pack_total_required_capacity_fraction" => 0.25,
               "capacity_pack_required_capacity_sources" => ["contact_required_capacity_fraction"],
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
               "branch_quality_gate_blocked_row_ids" => ["quality_gate:schema_validation:1"],
               "branch_contact_allocation_reasons" => ["policy_blocked", "station_reserved"],
               "branch_station_reservation_conflict_reservation_ids" => [
                 "reservation_partner"
               ],
               "repair_link_actual_downlink_completion_ratio" => 0.65,
               "first_resource_pressure_activity_id" => "urgent_downlink",
               "first_resource_pressure_ground_station_id" => "equator_prime",
               "first_resource_pressure_station_calendar_provider_id" => "ops_calendar",
               "first_resource_pressure_station_calendar_provider_entry_id" =>
                 "ops_calendar_window_1",
               "first_resource_pressure_source_window_id" =>
                 "window:leo_1:ground_station_access:equator_prime:1"
             }
           } = first_row

    assert first_row["delta"] == 0.0
    assert first_row["branch_planned_downlink_mb"] == 0.0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    stale_source_evidence =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"branch_id" => "urgent", "source_branch_comparison" => %{}} = row ->
            put_in(row, ["source_branch_comparison", "risk_count"], 2)

          row ->
            row
        end)
      end)

    assert {:error, stale_source_report} = Schema.validate_artifact(stale_source_evidence)

    assert Enum.any?(
             stale_source_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.risk_count$/ and
                 &1["message"] == "must match source_branch_comparison.risk_count")
           )
  end
end
