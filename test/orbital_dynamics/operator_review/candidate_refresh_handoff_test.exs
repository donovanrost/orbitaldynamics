defmodule OrbitalDynamics.OperatorReview.CandidateRefreshHandoffTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "builds candidate refresh review package from contact and filter handoff rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "schema_version" => 1,
      "refresh_id" => "candidate_refresh:ops_state:001",
      "contact_intents" => [
        %{
          "schema_contract" => "contact_intent.v1",
          "id" => "refresh_downlink",
          "activity_id" => "refresh_downlink",
          "activity_type" => "downlink",
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "starts_at_s" => 100.0,
          "ends_at_s" => 160.0,
          "approval_status" => "operator_review_required",
          "approval_requirements" => [
            %{
              "schema_contract" => "approval_requirement.v1",
              "id" => "approval:refresh_downlink",
              "activity_id" => "refresh_downlink",
              "activity_type" => "downlink",
              "action" => "review_contact_intent",
              "requirement_type" => "contact_schedule_change",
              "reason" => "contact intent requires schedule authority"
            }
          ],
          "approval_rule_matches" => [
            %{
              "rule_id" => "downlink_schedule_authority_review",
              "required_authority" => "contact_schedule_authority"
            }
          ],
          "policy_decision" => %{
            "schema_contract" => "policy_decision.v1",
            "policy_bundle_id" => "command_contact_authority_v1",
            "classification" => "operator_review_required",
            "escalations" => [
              %{"rule_id" => "unmatched_contact_rule", "escalation_queue" => "ignore_queue"},
              %{
                "rule_id" => "downlink_schedule_authority_review",
                "escalation_level" => "ops_lead",
                "escalation_queue" => "contact_intent_review",
                "escalation_role" => "contact_scheduler",
                "required_authority" => "contact_schedule_authority",
                "sla_s" => 600
              }
            ]
          }
        }
      ],
      "contact_allocation_report" => %{
        "schema_contract" => "contact_allocation_report.v1",
        "rows" => [
          %{
            "contact_id" => "refresh_downlink_deferred",
            "type" => "downlink",
            "scenario_id" => "leo_2",
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "starts_at_s" => 110.0,
            "ends_at_s" => 170.0,
            "allocation_status" => "deferred",
            "allocation_reason" => "same_station_contention",
            "selected_contact_id" => "refresh_downlink",
            "review_status" => "operator_review_required",
            "approval_requirements" => [
              %{
                "activity_id" => "refresh_downlink_deferred",
                "activity_type" => "downlink",
                "action" => "review_contact_allocation",
                "requirement_type" => "contact_schedule_change"
              }
            ],
            "approval_rule_matches" => [
              %{
                "rule_id" => "contact_allocation_review",
                "classification" => "operator_review_required"
              }
            ],
            "policy_decision" => %{
              "schema_contract" => "policy_decision.v1",
              "policy_bundle_id" => "ground_network_allocation_v1",
              "classification" => "operator_review_required",
              "escalations" => [
                %{"rule_id" => "unmatched_allocation_rule", "escalation_queue" => "ignore_queue"},
                %{
                  "rule_id" => "contact_allocation_review",
                  "required_authority" => "contact_schedule_authority",
                  "escalation_level" => "ops_lead",
                  "escalation_queue" => "ground_network",
                  "escalation_role" => "network_scheduler",
                  "sla_s" => 600
                }
              ]
            }
          }
        ]
      },
      "contact_filter_report" => %{
        "schema_contract" => "contact_filter_report.v1",
        "suppressed_candidates" => [
          %{
            "id" => "refresh_contact_suppressed",
            "type" => "downlink",
            "scenario_id" => "leo_1",
            "ground_station_id" => "equator_prime",
            "starts_at_s" => 200.0,
            "ends_at_s" => 260.0,
            "suppressed_reason" => "ground_station_unavailable"
          }
        ]
      },
      "candidate_diff_report" => %{
        "schema_contract" => "candidate_diff_report.v1",
        "invalidated_candidates" => [
          %{
            "id" => "old_refresh_observe",
            "type" => "observe",
            "scenario_id" => "leo_1",
            "target_id" => "target_a",
            "source_target_id" => "target_a",
            "source_target" => %{
              "id" => "target_a",
              "name" => "Target A",
              "latitude_deg" => 12.5,
              "longitude_deg" => -45.25,
              "minimum_elevation_deg" => 17.5
            },
            "target_latitude_deg" => 12.5,
            "target_longitude_deg" => -45.25,
            "target_minimum_elevation_deg" => 17.5,
            "target_priority" => 4.5,
            "target_priority_source" => "candidate_refresh.objectives.observation_priority",
            "target_priority_objective_ids" => ["urgent:target_a"],
            "target_priority_objective_type" => "urgent_target",
            "collection_id" => "collection_alpha",
            "product_ids" => ["image_l0", "image_l1"],
            "payload_id" => "camera_a",
            "instrument_id" => "imager",
            "source_activity_ids" => ["refresh_observe"],
            "objective_id" => "latency:collection_alpha",
            "objective_type" => "collection_latency",
            "latency_objective" => true,
            "max_latency_s" => 900.0,
            "planned_latency_s" => 540.0,
            "required_downlink_mb" => 300.0,
            "candidate_downlink_mb" => 360.0,
            "downlink_completion_ratio" => 1.0,
            "selected_downlink_shortfall_mb" => +0.0,
            "downlink_requirement_status" => "satisfied",
            "downlink_completion_source" =>
              "candidate_refresh.downlink_demand.objectives_and_operational_feedback",
            "downlink_completion_sources" => [
              "candidate_refresh.objectives.collection_latency",
              "operational_feedback.downlink_demand_mb.station"
            ],
            "source_window_id" => "window:leo_1:target_visibility:target_a:old",
            "starts_at_s" => 90.0,
            "ends_at_s" => 150.0,
            "replacement_candidate_id" => "refresh_observe",
            "invalidated_reason" => "replaced_by_semantically_similar_candidate",
            "semantic_change_reasons" => ["starts_at_s_changed", "source_window_id_changed"],
            "semantic_change_details" => [
              %{
                "field" => "target_priority",
                "reason" => "target_priority_changed",
                "prior_path" => "target_priority",
                "refreshed_path" => "target_priority",
                "prior_value" => 2.0,
                "refreshed_value" => 4.5
              }
            ]
          }
        ]
      },
      "source_window_lineage" => [
        %{
          "schema_contract" => "source_window_lineage.v1",
          "candidate_activity_id" => "refresh_observe",
          "source_window_id" => "window:leo_1:target_visibility:target_a:1",
          "source_window_type" => "target_visibility",
          "scenario_id" => "leo_1",
          "source_window" => %{
            "schema_contract" => "refreshed_window.v1",
            "id" => "window:leo_1:target_visibility:target_a:1",
            "type" => "target_visibility",
            "scenario_id" => "leo_1",
            "target_id" => "target_a",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "duration_s" => 60.0,
            "boundary_refinement" => "target_visibility_linear_margin_interpolation"
          }
        }
      ],
      "candidate_rejection_report" => %{
        "schema_contract" => "candidate_rejection_report.v1",
        "model" => "artifact_only_candidate_rejection_explanation",
        "source" => "candidate_refresh.candidate_filter",
        "candidate_count" => 1,
        "row_count" => 1,
        "rejected_count" => 1,
        "not_rejected_count" => 0,
        "invalid_candidate_input_count" => 0,
        "reviewable_count" => 1,
        "rejection_reason_counts" => %{"station_reserved" => 1},
        "required_operator_action_counts" => %{"review_candidate_rejection" => 1},
        "rows" => [
          %{
            "id" => "candidate_rejection:1:refresh_downlink_reserved",
            "candidate_id" => "refresh_downlink_reserved",
            "activity_id" => "refresh_downlink_reserved",
            "timeline_id" => "candidate_timeline",
            "activity_type" => "downlink",
            "operational_kind" => "contact",
            "rejection_status" => "rejected",
            "primary_rejection_reason" => "station_reserved",
            "rejection_reasons" => ["station_reserved"],
            "reason_count" => 1,
            "reviewable" => true,
            "required_operator_action" => "review_candidate_rejection",
            "violated_constraint" => "station_calendar",
            "required_margin" => 10.0,
            "actual_margin" => 5.0,
            "activity_context" => %{"ground_station_id" => "dss_14"}
          }
        ],
        "assumptions" => %{"scope" => "test fixture"}
      },
      "freshness_report" => %{
        "schema_contract" => "freshness_report.v1",
        "model" => "accepted_snapshot_horizon_and_quality_freshness",
        "generated_at" => "2026-05-14T00:00:00Z",
        "accepted_at" => "2026-05-12T00:00:00Z",
        "accepted_state_quality_level" => "planning_accepted",
        "allowed_state_quality_levels" => ["accepted"],
        "state_quality_status" => "not_accepted",
        "current_epoch_s" => 0.0,
        "horizon_starts_at_s" => 30.0,
        "accepted_snapshot_age_s" => 172_800.0,
        "horizon_start_offset_s" => 30.0,
        "max_snapshot_age_s" => 86_400.0,
        "max_horizon_start_offset_s" => 1.0,
        "status" => "stale",
        "stale_reasons" => [
          "accepted_snapshot_older_than_policy",
          "remaining_horizon_does_not_start_at_current_epoch",
          "accepted_state_quality_below_policy"
        ],
        "unknown_reasons" => []
      },
      "refresh_budget_report" => %{
        "schema_contract" => "refresh_budget_report.v1",
        "model" => "deterministic_candidate_limit_after_filters",
        "input_candidate_count" => 3,
        "kept_candidate_count" => 2,
        "dropped_candidate_count" => 1,
        "max_candidate_activities" => 2,
        "selection_order" => "score_descending_then_start_then_id",
        "kept_candidate_ids" => ["refresh_downlink", "refresh_observe"],
        "dropped_candidate_ids" => ["old_refresh_downlink"]
      },
      "resource_filter_report" => %{
        "schema_contract" => "resource_filter_report.v1",
        "suppressed_candidates" => [
          %{
            "id" => "refresh_observe_suppressed",
            "type" => "observe",
            "scenario_id" => "leo_1",
            "target_id" => "target_a",
            "starts_at_s" => 300.0,
            "ends_at_s" => 360.0,
            "suppressed_reason" => "payload_unavailable"
          }
        ]
      },
      "warnings" => ["candidate refresh produced reviewable contact changes"],
      "provenance" => %{
        "source" => "candidate_refresh_test",
        "run_input_sources" => %{
          "accepted_planning_state" => ["candidate_refresh.mission_state.spacecraft_states"],
          "targets" => ["candidate_refresh.mission_state.objectives"],
          "ground_stations" => ["candidate_refresh.mission_state.ground_network"]
        },
        "source_reports" => %{
          "operational_readiness_report" => %{
            "paths" => ["mission_state.source_operational_readiness_report"],
            "contract" => "operational_readiness_report.v1",
            "count" => 1,
            "row_count" => 1,
            "readiness_level_counts" => %{"operator_review" => 1},
            "import_classification_counts" => %{"review_only" => 1},
            "status_counts" => %{"review_required" => 1},
            "gate_count" => 4,
            "passed_gate_count" => 2,
            "review_gate_count" => 2,
            "analysis_gate_count" => 0,
            "blocked_gate_count" => 0,
            "review_required_count" => 1,
            "schema_validation_fail_count" => 1,
            "resource_availability_pressure_count" => 3,
            "resource_availability_reason_counts" => %{
              "antenna_unavailable" => 1,
              "ground_station_reserved" => 1,
              "payload_unavailable" => 1
            },
            "resource_availability_reason_ids" => [
              "antenna_unavailable",
              "ground_station_reserved",
              "payload_unavailable"
            ],
            "station_availability_reason_ids" => ["ground_station_reserved"],
            "unavailable_resource_reason_ids" => [
              "antenna_unavailable",
              "payload_unavailable"
            ],
            "resource_blocking_dimension_counts" => %{"communications" => 1},
            "trust_boundary_status" => "declared",
            "trust_boundaries" => ["mission_state_operational_readiness_report"]
          }
        },
        "operational_feedback" => %{
          "trust_boundary_status" => "missing",
          "input_keys" => ["observation_success_rate"]
        }
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert OrbitalDynamics.operator_review_package(artifact) == package

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:ops_state:001",
             "review_count" => 10,
             "contact_intent_review_count" => 1,
             "contact_allocation_review_count" => 1,
             "candidate_rejection_review_count" => 1,
             "candidate_diff_review_count" => 1,
             "freshness_review_count" => 1,
             "refresh_budget_review_count" => 1,
             "operational_readiness_review_count" => 1,
             "contact_suppression_count" => 1,
             "resource_suppression_count" => 1,
             "warning_count" => 1
           } = package

    assert get_in(package, ["provenance", "run_input_sources"]) == %{
             "accepted_planning_state" => ["candidate_refresh.mission_state.spacecraft_states"],
             "targets" => ["candidate_refresh.mission_state.objectives"],
             "ground_stations" => ["candidate_refresh.mission_state.ground_network"]
           }

    assert %{
             "review_type" => "contact_intent_review",
             "source" => "candidate_refresh.contact_intents",
             "activity_id" => "refresh_downlink",
             "required_operator_action" => "review_contact_intent",
             "source_policy_decision" => %{"policy_bundle_id" => "command_contact_authority_v1"},
             "source_policy_escalation" => %{
               "rule_id" => "downlink_schedule_authority_review",
               "escalation_queue" => "contact_intent_review"
             },
             "escalation_level" => "ops_lead",
             "escalation_queue" => "contact_intent_review",
             "escalation_role" => "contact_scheduler",
             "sla_s" => 600,
             "source_contact_intent" => %{"schema_contract" => "contact_intent.v1"}
           } = Enum.find(package["rows"], &(&1["review_type"] == "contact_intent_review"))

    assert %{
             "review_type" => "contact_allocation_review",
             "source" => "candidate_refresh.contact_allocation_report.rows",
             "contact_id" => "refresh_downlink_deferred",
             "allocation_status" => "deferred",
             "requirement_type" => "contact_schedule_change",
             "required_authority" => "contact_schedule_authority",
             "policy_bundle_id" => "ground_network_allocation_v1",
             "rule_id" => "contact_allocation_review",
             "escalation_level" => "ops_lead",
             "escalation_queue" => "ground_network",
             "escalation_role" => "network_scheduler",
             "sla_s" => 600,
             "source_policy_decision" => %{"policy_bundle_id" => "ground_network_allocation_v1"},
             "source_policy_escalation" => %{
               "rule_id" => "contact_allocation_review",
               "escalation_queue" => "ground_network"
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "contact_allocation_review"))

    assert %{
             "review_type" => "candidate_diff_review",
             "source" => "candidate_refresh.candidate_diff_report.invalidated_candidates",
             "activity_id" => "old_refresh_observe",
             "target_id" => "target_a",
             "source_target_id" => "target_a",
             "source_target" => %{
               "id" => "target_a",
               "name" => "Target A",
               "latitude_deg" => 12.5,
               "longitude_deg" => -45.25,
               "minimum_elevation_deg" => 17.5
             },
             "target_latitude_deg" => 12.5,
             "target_longitude_deg" => -45.25,
             "target_minimum_elevation_deg" => 17.5,
             "target_priority" => 4.5,
             "target_priority_source" => "candidate_refresh.objectives.observation_priority",
             "target_priority_objective_ids" => ["urgent:target_a"],
             "target_priority_objective_type" => "urgent_target",
             "collection_id" => "collection_alpha",
             "product_ids" => ["image_l0", "image_l1"],
             "payload_id" => "camera_a",
             "instrument_id" => "imager",
             "source_activity_ids" => ["refresh_observe"],
             "objective_id" => "latency:collection_alpha",
             "objective_type" => "collection_latency",
             "latency_objective" => true,
             "max_latency_s" => 900.0,
             "planned_latency_s" => 540.0,
             "required_downlink_mb" => 300.0,
             "candidate_downlink_mb" => 360.0,
             "downlink_completion_ratio" => 1.0,
             "downlink_requirement_status" => "satisfied",
             "downlink_completion_source" =>
               "candidate_refresh.downlink_demand.objectives_and_operational_feedback",
             "downlink_completion_sources" => [
               "candidate_refresh.objectives.collection_latency",
               "operational_feedback.downlink_demand_mb.station"
             ],
             "required_operator_action" => "review_candidate_diff",
             "replacement_candidate_id" => "refresh_observe",
             "replacement_source_window_id" => "window:leo_1:target_visibility:target_a:1",
             "replacement_source_window_type" => "target_visibility",
             "replacement_source_window" => %{
               "id" => "window:leo_1:target_visibility:target_a:1",
               "boundary_refinement" => "target_visibility_linear_margin_interpolation"
             },
             "replacement_source_window_lineage" => %{
               "schema_contract" => "source_window_lineage.v1",
               "candidate_activity_id" => "refresh_observe"
             },
             "semantic_change_reasons" => ["target_priority_changed"],
             "changed_fields" => ["target_priority"],
             "candidate_diff_changed_fields" => ["target_priority"],
             "candidate_diff_changed_field_count" => 1,
             "semantic_change_details" => [
               %{
                 "field" => "target_priority",
                 "reason" => "target_priority_changed",
                 "prior_value" => 2.0,
                 "refreshed_value" => 4.5
               }
             ],
             "run_input_sources" => %{
               "accepted_planning_state" => [
                 "candidate_refresh.mission_state.spacecraft_states"
               ],
               "targets" => ["candidate_refresh.mission_state.objectives"],
               "ground_stations" => ["candidate_refresh.mission_state.ground_network"]
             },
             "source_candidate_diff" => %{"id" => "old_refresh_observe"}
           } = Enum.find(package["rows"], &(&1["review_type"] == "candidate_diff_review"))

    assert %{
             "review_type" => "candidate_rejection_review",
             "source" => "candidate_refresh.candidate_rejection_report.rows",
             "subject_id" => "refresh_downlink_reserved",
             "required_operator_action" => "review_candidate_rejection",
             "primary_rejection_reason" => "station_reserved",
             "source_candidate_rejection" => %{
               "candidate_id" => "refresh_downlink_reserved"
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "candidate_rejection_review"))

    assert %{
             "review_type" => "freshness_review",
             "source" => "candidate_refresh.freshness_report",
             "subject_id" => "freshness:stale",
             "required_operator_action" => "review_refresh_freshness",
             "freshness_status" => "stale",
             "stale_reasons" => [
               "accepted_snapshot_older_than_policy",
               "remaining_horizon_does_not_start_at_current_epoch",
               "accepted_state_quality_below_policy"
             ],
             "source_freshness_report" => %{"status" => "stale"}
           } = Enum.find(package["rows"], &(&1["review_type"] == "freshness_review"))

    assert %{
             "review_type" => "refresh_budget_review",
             "source" => "candidate_refresh.refresh_budget_report",
             "required_operator_action" => "review_refresh_budget",
             "dropped_candidate_count" => 1,
             "dropped_candidate_ids" => ["old_refresh_downlink"],
             "run_input_sources" => %{
               "targets" => ["candidate_refresh.mission_state.objectives"]
             },
             "source_refresh_budget_report" => %{"schema_contract" => "refresh_budget_report.v1"}
           } = Enum.find(package["rows"], &(&1["review_type"] == "refresh_budget_review"))

    assert %{
             "review_type" => "operational_readiness_review",
             "source" =>
               "candidate_refresh.provenance.source_reports.operational_readiness_report",
             "subject_id" => "candidate_refresh.operational_readiness_source_reports",
             "required_operator_action" => "review_operational_readiness",
             "approval_status" => "operator_review_required",
             "source_artifact_type" => "operational_readiness_report.v1",
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "operational_readiness_status" => "review_required",
             "gate_count" => 4,
             "review_gate_count" => 2,
             "resource_availability_pressure_count" => 3,
             "resource_availability_reason_counts" => %{
               "antenna_unavailable" => 1,
               "ground_station_reserved" => 1,
               "payload_unavailable" => 1
             },
             "resource_availability_reason_ids" => [
               "antenna_unavailable",
               "ground_station_reserved",
               "payload_unavailable"
             ],
             "station_availability_reason_ids" => ["ground_station_reserved"],
             "unavailable_resource_reason_ids" => [
               "antenna_unavailable",
               "payload_unavailable"
             ],
             "resource_blocking_dimension_counts" => %{"communications" => 1},
             "evidence" => %{
               "review_required_count" => 1,
               "schema_validation_fail_count" => 1,
               "resource_availability_pressure_count" => 3,
               "resource_availability_reason_counts" => %{
                 "antenna_unavailable" => 1,
                 "ground_station_reserved" => 1,
                 "payload_unavailable" => 1
               },
               "resource_availability_reason_ids" => [
                 "antenna_unavailable",
                 "ground_station_reserved",
                 "payload_unavailable"
               ],
               "station_availability_reason_ids" => ["ground_station_reserved"],
               "unavailable_resource_reason_ids" => [
                 "antenna_unavailable",
                 "payload_unavailable"
               ],
               "resource_blocking_dimension_counts" => %{"communications" => 1}
             },
             "source_operational_readiness_report" => %{
               "schema_contract" => "operational_readiness_report.v1",
               "paths" => ["mission_state.source_operational_readiness_report"],
               "trust_boundary_status" => "declared"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["review_type"] == "operational_readiness_review")
             )

    assert %{
             "review_type" => "warning",
             "source" => "candidate_refresh.warnings",
             "reason" => "candidate refresh produced reviewable contact changes",
             "operational_feedback_trust_boundary_status" => "missing",
             "operational_feedback_input_keys" => ["observation_success_rate"],
             "source_operational_feedback_provenance" => %{
               "trust_boundary_status" => "missing"
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "warning"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    candidate_diff_index =
      Enum.find_index(package["rows"], &(&1["review_type"] == "candidate_diff_review"))

    invalid_replacement_window =
      put_in(
        package,
        ["rows", Access.at(candidate_diff_index), "replacement_source_window", "id"],
        "window:leo_1:target_visibility:target_a:mismatch"
      )

    assert {:error, invalid_replacement_window_report} =
             Schema.validate_artifact(invalid_replacement_window)

    assert Enum.any?(
             invalid_replacement_window_report["errors"],
             &(&1["path"] ==
                 "$.rows[#{candidate_diff_index}].replacement_source_window.id" and
                 &1["message"] == "must match replacement_source_window_id")
           )
  end
end
