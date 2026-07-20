Code.require_file(
  "../../support/candidate_refresh/source_report_input_provenance_fixture.ex",
  __DIR__
)

defmodule OrbitalDynamics.CandidateRefresh.SourceReportInputProvenanceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CandidateRefresh,
    Schema,
    Timeline,
    TimelineFeedback,
    Validation
  }

  alias OrbitalDynamics.Communications.CommandWindow
  import OrbitalDynamics.CandidateRefresh.SourceReportInputProvenanceFixture

  test "preserves candidate refresh source report input provenance" do
    timeline_feedback_report =
      TimelineFeedback.reconcile(
        [
          %{
            "id" => "dl_feedback_planned",
            "type" => "downlink",
            "ground_station_id" => "unused_station",
            "starts_at_s" => 10.0,
            "ends_at_s" => 70.0,
            "estimated_throughput_mb" => 50.0,
            "station_reservation_id" => "reservation_feedback",
            "station_reservation_expires_at_s" => 240.0,
            "station_calendar_reservation_ids" => ["reservation_feedback"],
            "station_calendar_reservation_expires_at_s" => [240.0]
          }
        ],
        [
          %{
            "id" => "dl_feedback_planned",
            "type" => "downlink",
            "ground_station_id" => "unused_station",
            "starts_at_s" => 10.0,
            "ends_at_s" => 70.0,
            "status" => "partial",
            "actual_throughput_mb" => 25.0,
            "station_reservation_id" => "reservation_feedback",
            "station_reservation_expires_at_s" => 240.0,
            "station_calendar_reservation_ids" => ["reservation_feedback"],
            "station_calendar_reservation_expires_at_s" => [240.0],
            "trust_boundary" => "mission_state_timeline_feedback_rows"
          }
        ]
      )
      |> Map.put("trust_boundary", "mission_state_timeline_feedback_report")

    operational_timeline_report =
      Timeline.operational_report(
        [
          %{
            id: :ops_contact_feedback,
            type: :downlink,
            ground_station_id: :unused_station,
            starts_at_s: 10.0,
            ends_at_s: 70.0,
            contact_success_factor: 0.5,
            actual_throughput_mb: 25.0,
            planned_estimated_throughput_mb: 50.0,
            station_reservation_id: :reservation_ops,
            station_reservation_expires_at_s: 360.0,
            station_calendar_reservation_ids: [:reservation_ops],
            station_calendar_reservation_expires_at_s: [360.0],
            provenance: %{trust_boundary: :mission_state_operational_timeline_rows}
          }
        ],
        source: "mission_state.operational_timeline"
      )
      |> Map.put("trust_boundary", "mission_state_operational_timeline_report")

    command_window_report =
      CommandWindow.report([
        %{
          id: :cmd_feedback,
          type: :command,
          direction: :uplink,
          starts_at_s: 100.0,
          ends_at_s: 130.0,
          command_success_factor: 0.25,
          provenance: %{trust_boundary: :mission_state_command_window_rows}
        }
      ])
      |> Map.put("trust_boundary", "mission_state_command_window_report")

    maneuver_review_report =
      maneuver_feedback_report(
        "burn_source_report",
        maneuver_success_factor: 0.4,
        execution_uncertainty: %{
          timing_3sigma_s: 10.0,
          source: :mission_review
        }
      )
      |> Map.put("trust_boundary", "mission_state_maneuver_review_report")

    candidate_rejection_report =
      Timeline.candidate_rejection_report(
        [
          %{
            id: :dl_reserved,
            type: :downlink,
            ground_station_id: :unused_station,
            station_availability: "Reservation Hold",
            starts_at_s: 80.0,
            ends_at_s: 85.0,
            min_duration_s: 10.0
          }
        ],
        source: :mission_state_candidate_rejections
      )
      |> Map.put("trust_boundary", "mission_state_candidate_rejection_report")

    refresh =
      refresh_request()
      |> Map.put("mission_state", %{
        "source_timeline_feedback_report" => timeline_feedback_report,
        "source_operational_timeline_report" => operational_timeline_report,
        "source_command_window_report" => command_window_report,
        "source_maneuver_review_report" => maneuver_review_report,
        "source_candidate_rejection_report" => candidate_rejection_report,
        "source_schema_validation_report" => %{
          "schema_contract" => "schema_validation_report.v1",
          "validation_mode" => "artifact",
          "validated_contract" => "candidate_refresh.v1",
          "status" => "fail",
          "error_count" => 2,
          "warning_count" => 1,
          "remediation_count" => 2,
          "errors" => [
            %{"path" => "$.candidate_activities[0].id", "message" => "is required"},
            %{"path" => "$.candidate_activities[0].type", "message" => "is required"}
          ],
          "warnings" => [%{"path" => "$.metadata", "message" => "unknown field"}],
          "remediation" => [
            %{"path" => "$.candidate_activities[0].id", "action" => "populate id"},
            %{"path" => "$.candidate_activities[0].type", "action" => "populate type"}
          ],
          "provenance" => %{"trust_boundary" => "mission_state_schema_validation_report"}
        },
        "source_candidate_diff_report" => %{
          "schema_contract" => "candidate_diff_report.v1",
          "retained_candidates" => [],
          "new_candidates" => [
            %{
              "id" => "dl_new",
              "type" => "downlink",
              "provenance" => %{"trust_boundary" => "mission_state_diff_rows"}
            }
          ],
          "invalidated_candidates" => [
            %{
              "id" => "dl_stale",
              "replacement_candidate_id" => "dl_new",
              "trust_boundary" => "mission_state_diff_rows"
            }
          ],
          "provenance" => %{"trust_boundary" => "mission_state_diff_report"}
        },
        "source_freshness_report" => %{
          "schema_contract" => "freshness_report.v1",
          "status" => "stale",
          "stale_reasons" => ["accepted_snapshot_older_than_policy"],
          "unknown_reasons" => [],
          "provenance" => %{"trust_boundary" => "mission_state_freshness_report"}
        },
        "source_refresh_budget_report" => %{
          "schema_contract" => "refresh_budget_report.v1",
          "input_candidate_count" => 3,
          "kept_candidate_count" => 2,
          "dropped_candidate_count" => 1,
          "max_candidate_activities" => 2,
          "dropped_candidate_ids" => ["dl_dropped"],
          "provenance" => %{"trust_boundary" => "mission_state_budget_report"}
        },
        "source_operational_readiness_report" => %{
          "schema_contract" => "operational_readiness_report.v1",
          "schema_version" => 1,
          "model" => "OrbitalDynamics.OperationalReadiness.V1",
          "report_id" => "operational_readiness:planned_activity.v1:activity_1",
          "source_artifact_type" => "planned_activity.v1",
          "source_artifact_id" => "activity_1",
          "readiness_level" => "operator_review",
          "import_classification" => "review_only",
          "status" => "review_required",
          "gate_count" => 4,
          "passed_gate_count" => 2,
          "review_gate_count" => 2,
          "analysis_gate_count" => 0,
          "blocked_gate_count" => 0,
          "gates" => [
            %{
              "id" => "resource_availability",
              "status" => "review_required",
              "classification" => "review_only",
              "reason" => "resource availability requires review",
              "resource_availability_pressure_count" => 2,
              "resource_availability_reason_counts" => %{
                "antenna_unavailable" => 1,
                "payload_unavailable" => 1
              },
              "resource_blocking_dimension_counts" => %{"communications" => 1}
            }
          ],
          "evidence" => %{
            "ready_for_import_count" => 0,
            "manifest_review_required_count" => 1,
            "blocked_import_count" => 0,
            "missing_import_count" => 1,
            "invalid_cadence_import_count" => 0,
            "review_required_count" => 1,
            "current_freshness_count" => 0,
            "schema_validation_fail_count" => 1,
            "schema_validation_error_count" => 1,
            "schema_validation_warning_count" => 0,
            "schema_validation_remediation_count" => 1,
            "stale_freshness_count" => 2,
            "unknown_freshness_count" => 0,
            "freshness_status_counts" => %{"stale" => 2},
            "schema_validation_status_counts" => %{"fail" => 1},
            "import_status_counts" => %{"review_required_before_import" => 1},
            "cadence_import_status_counts" => %{"missing" => 1},
            "source_model_limit_count" => 1,
            "adapter_context_count" => 1,
            "adapter_trust_boundary_declared_count" => 0,
            "adapter_trust_boundary_missing_count" => 0,
            "adapter_trust_boundary_untrusted_count" => 1,
            "adapter_boundary_status_counts" => %{"untrusted" => 1},
            "resource_availability_pressure_count" => 2,
            "resource_availability_reason_counts" => %{
              "antenna_unavailable" => 1,
              "payload_unavailable" => 1
            },
            "resource_blocking_dimension_counts" => %{"communications" => 1},
            "review_type_counts" => %{"contact_allocation_review" => 1},
            "import_action_counts" => %{"review_contact_allocation" => 1},
            "source_review_type_counts" => %{"contact_allocation_review" => 1}
          },
          "assumptions" => %{"source" => "test_readiness_source"},
          "model_limits" => ["artifact_only"],
          "provenance" => %{
            "trust_boundary" => "mission_state_operational_readiness_report"
          }
        },
        "source_quality_gate_report" => %{
          "schema_contract" => "quality_gate_report.v1",
          "model" => "artifact_only_operational_quality_gate_report",
          "source_readiness_report_id" => "operational_readiness:planned_activity.v1:activity_1",
          "readiness_level" => "operator_review",
          "import_classification" => "review_only",
          "status" => "review_required",
          "gate_count" => 4,
          "passed_gate_count" => 2,
          "review_gate_count" => 2,
          "analysis_gate_count" => 0,
          "blocked_gate_count" => 0,
          "gate_status_counts" => %{"passed" => 2, "review_required" => 2},
          "gate_classification_counts" => %{"importable" => 2, "review_only" => 2},
          "rows" => [
            %{
              "id" => "quality_gate:activity_1:source_contract:1",
              "rank" => 1,
              "gate_id" => "source_contract",
              "status" => "passed",
              "classification" => "importable",
              "reason" => "source artifact type is declared"
            },
            %{
              "id" => "quality_gate:activity_1:resource_availability:2",
              "rank" => 2,
              "gate_id" => "resource_availability",
              "status" => "review_required",
              "classification" => "review_only",
              "reason" => "resource availability requires review",
              "resource_availability_pressure_count" => 2,
              "resource_availability_reason_counts" => %{
                "antenna_unavailable" => 1,
                "payload_unavailable" => 1
              },
              "resource_availability_reason_ids" => [
                "antenna_unavailable",
                "payload_unavailable"
              ],
              "unavailable_resource_reason_ids" => [
                "antenna_unavailable",
                "payload_unavailable"
              ],
              "resource_blocking_dimension_counts" => %{"communications" => 1}
            },
            %{
              "id" => "quality_gate:activity_1:cadence_import:3",
              "rank" => 3,
              "gate_id" => "cadence_import",
              "status" => "review_required",
              "classification" => "review_only",
              "reason" => "source freshness evidence is stale or unknown",
              "ready_for_import_count" => 0,
              "manifest_review_required_count" => 1,
              "missing_import_count" => 1,
              "stale_freshness_count" => 2,
              "freshness_status_counts" => %{"stale" => 2},
              "schema_validation_fail_count" => 1,
              "schema_validation_error_count" => 1,
              "schema_validation_remediation_count" => 1,
              "schema_validation_status_counts" => %{"fail" => 1},
              "import_status_counts" => %{"review_required_before_import" => 1},
              "cadence_import_status_counts" => %{"missing" => 1}
            }
          ],
          "provenance" => %{"trust_boundary" => "mission_state_quality_gate_report"}
        },
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "rows" => [
            %{
              "diff_status" => "removed",
              "source_activity_id" => "prior_removed_downlink",
              "source_activity_type" => "downlink",
              "source_ground_station_id" => "unused_station",
              "source_required_downlink_mb" => 25.0,
              "trust_boundary" => "mission_state_timeline_diff_rows"
            },
            %{
              "diff_status" => "removed",
              "source_activity_id" => "prior_removed_observation",
              "source_activity_type" => "observe",
              "source_target_id" => "unused_target",
              "trust_boundary" => "mission_state_timeline_diff_rows"
            },
            %{
              "diff_status" => "changed",
              "source_activity_id" => "prior_changed_downlink",
              "source_activity_type" => "downlink",
              "source_ground_station_id" => "unused_station",
              "selected_downlink_shortfall_mb" => 12.0,
              "trust_boundary" => "mission_state_timeline_diff_rows"
            }
          ],
          "provenance" => %{"trust_boundary" => "mission_state_timeline_diff_report"}
        },
        "source_station_calendar_report" => %{
          "schema_contract" => "station_calendar_report.v1",
          "affected_contacts" => [
            %{
              "id" => "prior_reserved_station",
              "ground_station_id" => "unused_station",
              "starts_at_s" => 10.0,
              "ends_at_s" => 20.0,
              "station_calendar_status" => "reserved",
              "trust_boundary" => "mission_state_station_calendar_rows"
            }
          ],
          "provenance" => %{"trust_boundary" => "mission_state_station_calendar_report"}
        },
        "source_provider_counteroffer_report" => %{
          "schema_contract" => "provider_counteroffer_report.v1",
          "source" => "station_calendar_report.affected_contacts",
          "source_artifact_type" => "station_calendar_report.v1",
          "source_artifact_id" => "station_calendar_report",
          "counteroffer_count" => 1,
          "reviewable_count" => 1,
          "counteroffer_cost_delta_count" => 1,
          "counteroffer_cost_delta_total" => 125.5,
          "counteroffer_lock_deadline_count" => 1,
          "earliest_counteroffer_lock_deadline_s" => 150.0,
          "counteroffer_status_counts" => %{"proposed" => 1},
          "required_operator_action_counts" => %{"review_provider_counteroffer" => 1},
          "rows" => [
            %{
              "id" => "provider_counteroffer:1:provider_offer_1",
              "provider_counteroffer_id" => "provider_offer_1",
              "provider_counteroffer_status" => "proposed",
              "provider_counteroffer_cost_delta" => 125.5,
              "provider_counteroffer_lock_deadline_s" => 150.0,
              "provider_counteroffer_start_delta_s" => 30.0,
              "provider_counteroffer_end_delta_s" => 30.0,
              "provider_counteroffer_duration_delta_s" => 0.0,
              "reviewable" => true,
              "required_operator_action" => "review_provider_counteroffer",
              "trust_boundary" => "mission_state_provider_counteroffer_rows"
            }
          ],
          "provenance" => %{"trust_boundary" => "mission_state_provider_counteroffer_report"}
        },
        "source_model_acceptance_report" =>
          [
            "orbit_data.simple_json",
            "event.access_windows",
            "propagator.two_body",
            "missing.model"
          ]
          |> Validation.model_acceptance_report(intended_use: :operational_import)
          |> Map.put("provenance", %{
            "trust_boundary" => "mission_state_model_acceptance_report"
          }),
        "source_contact_intent" => %{
          "schema_contract" => "contact_intent.v1",
          "id" => "prior_contact_intent_missing_import",
          "activity_id" => "prior_contact_intent_missing_import",
          "ground_station_id" => "unused_station",
          "starts_at_s" => 15.0,
          "ends_at_s" => 25.0,
          "station_calendar_status" => "reserved",
          "cadence_import_status" => "missing",
          "policy_classification" => "blocked_by_policy",
          "provenance" => %{"trust_boundary" => "mission_state_contact_intent"}
        },
        "source_constraint_report" => %{
          "schema_contract" => "constraint_report.v1",
          "rows" => [
            %{
              "constraint_id" => "downlink_shortfall",
              "metric" => "selected_downlink_shortfall_mb",
              "scenario_id" => "unused_scenario",
              "status" => "warning",
              "value" => 40.0,
              "ground_station_id" => "unused_station",
              "trust_boundary" => "mission_state_constraint_rows"
            },
            %{
              "constraint_id" => "battery_margin",
              "metric" => "battery_margin",
              "scenario_id" => "unused_scenario",
              "spacecraft_id" => "unused_spacecraft",
              "status" => "fail",
              "resource_id" => "battery_1",
              "value" => -0.2,
              "trust_boundary" => "mission_state_constraint_rows"
            }
          ],
          "provenance" => %{"trust_boundary" => "mission_state_constraint_report"}
        },
        "source_objective_satisfaction_report" => %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "rows" => [
            %{
              "objective" => "downlink_completion",
              "status" => "partial",
              "required_downlink_mb" => 30.0,
              "ground_station_id" => "unused_station",
              "trust_boundary" => "mission_state_objective_rows"
            },
            %{
              "objective" => "target_coverage",
              "status" => "unmet",
              "target_id" => "unused_target",
              "required_revisits" => 1.0,
              "trust_boundary" => "mission_state_objective_rows"
            },
            %{
              "objective" => "collection_latency",
              "status" => "partial",
              "collection_id" => "unused_collection",
              "max_latency_s" => 600.0,
              "trust_boundary" => "mission_state_objective_rows"
            }
          ],
          "provenance" => %{"trust_boundary" => "mission_state_objective_report"}
        },
        "source_objective_tradeoff_report" => %{
          "schema_contract" => "objective_tradeoff_report.v1",
          "tradeoffs" => [
            %{
              "tradeoff_id" => "tradeoff_downlink",
              "required_downlink_mb" => 20.0,
              "ground_station_id" => "unused_station",
              "trust_boundary" => "mission_state_tradeoff_rows"
            },
            %{
              "tradeoff_id" => "tradeoff_target",
              "target_id" => "unused_target",
              "required_revisits" => 1.0,
              "trust_boundary" => "mission_state_tradeoff_rows"
            },
            %{
              "tradeoff_id" => "tradeoff_latency",
              "collection_id" => "unused_collection",
              "collection_latency_gap_s" => 300.0,
              "trust_boundary" => "mission_state_tradeoff_rows"
            }
          ],
          "provenance" => %{"trust_boundary" => "mission_state_tradeoff_report"}
        },
        "source_score_term_report" => %{
          "schema_contract" => "score_term_report.v1",
          "rows" => [
            %{
              "term_key" => "downlink_shortfall_mb",
              "value" => 20.0,
              "ground_station_id" => "unused_station",
              "trust_boundary" => "mission_state_score_rows"
            },
            %{
              "term_key" => "target_gap_count",
              "value" => 1.0,
              "target_id" => "unused_target",
              "trust_boundary" => "mission_state_score_rows"
            },
            %{
              "term_key" => "collection_latency_gap_s",
              "value" => 300.0,
              "collection_id" => "unused_collection",
              "trust_boundary" => "mission_state_score_rows"
            }
          ],
          "provenance" => %{"trust_boundary" => "mission_state_score_report"}
        },
        "source_link_capacity_report" => %{
          "schema_contract" => "link_capacity_report.v1",
          "rows" => [
            %{
              "ground_station_id" => "unused_station",
              "selected_downlink_shortfall_mb" => 40.0,
              "capacity_adjusted_throughput_mb" => 65.0,
              "selected_capacity_adjusted_throughput_mb" => 25.0,
              "unused_capacity_adjusted_throughput_mb" => 40.0,
              "actual_throughput_mb" => 20.0,
              "actual_downlink_shortfall_mb" => 60.0,
              "actual_downlink_requirement_status" => "shortfall",
              "selected_contact_ids" => ["dl_prior"],
              "actual_throughput_contact_ids" => ["dl_actual"],
              "trust_boundary" => "mission_state_link_capacity_rows"
            }
          ],
          "provenance" => %{"trust_boundary" => "mission_state_link_capacity_report"}
        },
        "source_contact_allocation_report" => %{
          "schema_contract" => "contact_allocation_report.v1",
          "rows" => [
            %{
              "contact_id" => "prior_deferred_contact",
              "type" => "downlink",
              "ground_station_id" => "unused_station",
              "allocation_status" => "deferred",
              "allocation_reason" => "capacity_pack",
              "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
              "required_capacity_fraction" => 0.35,
              "trust_boundary" => "mission_state_allocation_rows"
            }
          ],
          "capacity_pack_required_capacity_fraction" => 99.0,
          "capacity_pack_deferred_required_capacity_fraction" => 99.0,
          "capacity_pack_required_capacity_fraction_by_status" => %{
            "stale_status" => 99.0
          },
          "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" => %{
            "stale_station" => 99.0
          },
          "capacity_pack_contact_ids_by_status" => %{
            "deferred_by_reduced_station_capacity_pack" => ["prior_deferred_contact"]
          },
          "provenance" => %{"trust_boundary" => "mission_state_allocation_report"}
        },
        "source_contact_contention_resolution_report" => %{
          "schema_contract" => "contact_contention_resolution_report.v1",
          "recommendations" => [
            %{
              "group_id" => "unused_station:prior_contention",
              "ground_station_id" => "unused_station",
              "selected_contact_id" => "prior_selected_contact",
              "deferred_contact_ids" => ["prior_deferred_contact"],
              "resolution_status" => "deferred",
              "selection_reason" => "highest_score",
              "source_contact_candidates" => [
                %{
                  "id" => "prior_selected_contact",
                  "type" => "downlink",
                  "ground_station_id" => "unused_station",
                  "required_capacity_percent" => "20",
                  "trust_boundary" => "mission_state_contention_rows"
                },
                %{
                  "id" => "prior_deferred_contact",
                  "type" => "downlink",
                  "ground_station_id" => "unused_station",
                  "required_capacity_fraction" => 0.35,
                  "trust_boundary" => "mission_state_contention_rows"
                }
              ],
              "trust_boundary" => "mission_state_contention_rows"
            }
          ],
          "capacity_pack_required_capacity_fraction" => 99.0,
          "capacity_pack_selected_required_capacity_fraction" => 99.0,
          "capacity_pack_deferred_required_capacity_fraction" => 99.0,
          "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" => %{
            "stale_station" => 99.0
          },
          "provenance" => %{"trust_boundary" => "mission_state_contention_report"}
        }
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "paths" => ["mission_state.source_timeline_feedback_report"],
             "contract" => "timeline_feedback_report.v1",
             "count" => 1,
             "row_count" => 1,
             "input_keys" => ["contact_success_rate", "station_throughput_factor"],
             "status_counts" => %{"matched" => 1},
             "feedback_kind_counts" => %{"contact" => 1},
             "match_strategy_counts" => %{"activity_id" => 1},
             "station_reservation_evidence_row_count" => 1,
             "station_reservation_expiration_evidence_row_count" => 1,
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "mission_state_timeline_feedback_report",
               "mission_state_timeline_feedback_rows"
             ]
           } = get_in(artifact, ["provenance", "source_reports", "timeline_feedback_report"])

    assert %{
             "paths" => ["mission_state.source_operational_timeline_report"],
             "contract" => "operational_timeline_report.v1",
             "count" => 1,
             "row_count" => 1,
             "contact_feedback_count" => 1,
             "command_feedback_count" => 0,
             "maneuver_feedback_count" => 0,
             "observation_feedback_count" => 0,
             "station_throughput_feedback_count" => 1,
             "station_reservation_evidence_row_count" => 1,
             "station_reservation_expiration_evidence_row_count" => 1,
             "input_keys" => ["contact_success_rate", "station_throughput_factor"],
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "mission_state_operational_timeline_report",
               "mission_state_operational_timeline_rows"
             ]
           } =
             get_in(artifact, [
               "provenance",
               "source_reports",
               "operational_timeline_report"
             ])

    source_report_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_report_summary["source_report_station_reservation_evidence_row_count"] == 2

    assert source_report_summary[
             "source_report_station_reservation_expiration_evidence_row_count"
           ] == 2

    assert source_report_summary[
             "source_report_station_reservation_evidence_row_counts_by_family"
           ] == %{
             "operational_timeline_report" => 1,
             "timeline_feedback_report" => 1
           }

    assert source_report_summary[
             "source_report_station_reservation_expiration_evidence_row_counts_by_family"
           ] == %{
             "operational_timeline_report" => 1,
             "timeline_feedback_report" => 1
           }

    assert %{
             "paths" => ["mission_state.source_candidate_diff_report"],
             "contract" => "candidate_diff_report.v1",
             "count" => 1,
             "row_count" => 2,
             "new_candidate_count" => 1,
             "invalidated_candidate_count" => 1,
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "mission_state_diff_report",
               "mission_state_diff_rows"
             ]
           } = get_in(artifact, ["provenance", "source_reports", "candidate_diff_report"])

    assert %{
             "paths" => ["mission_state.source_candidate_rejection_report"],
             "contract" => "candidate_rejection_report.v1",
             "count" => 1,
             "row_count" => 1,
             "rejected_count" => 1,
             "reviewable_count" => 1,
             "invalid_candidate_input_count" => 0,
             "candidate_rejection_candidate_id_counts" => %{"dl_reserved" => 1},
             "candidate_rejection_ground_station_counts" => %{"unused_station" => 1},
             "rejection_reason_counts" => %{
               "contact_too_short" => 1,
               "station_reserved" => 1
             },
             "required_operator_action_counts" => %{"review_candidate_rejection" => 1},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["mission_state_candidate_rejection_report"]
           } = get_in(artifact, ["provenance", "source_reports", "candidate_rejection_report"])

    assert %{
             "paths" => ["mission_state.source_schema_validation_report"],
             "contract" => "schema_validation_report.v1",
             "count" => 1,
             "row_count" => 1,
             "status_counts" => %{"fail" => 1},
             "validated_contract_counts" => %{"candidate_refresh.v1" => 1},
             "validation_mode_counts" => %{"artifact" => 1},
             "error_count" => 2,
             "warning_count" => 1,
             "remediation_count" => 2,
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["mission_state_schema_validation_report"]
           } = get_in(artifact, ["provenance", "source_reports", "schema_validation_report"])

    assert %{
             "paths" => ["mission_state.source_freshness_report"],
             "contract" => "freshness_report.v1",
             "count" => 1,
             "row_count" => 1,
             "status_counts" => %{"stale" => 1},
             "stale_reason_count" => 1,
             "unknown_reason_count" => 0,
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["mission_state_freshness_report"]
           } = get_in(artifact, ["provenance", "source_reports", "freshness_report"])

    assert %{
             "paths" => ["mission_state.source_refresh_budget_report"],
             "contract" => "refresh_budget_report.v1",
             "count" => 1,
             "row_count" => 1,
             "input_candidate_count" => 3,
             "kept_candidate_count" => 2,
             "dropped_candidate_count" => 1,
             "invalid_candidate_limit_policy_count" => 0,
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["mission_state_budget_report"]
           } = get_in(artifact, ["provenance", "source_reports", "refresh_budget_report"])

    assert %{
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
             "ready_for_import_count" => 0,
             "manifest_review_required_count" => 1,
             "blocked_import_count" => 0,
             "missing_import_count" => 1,
             "invalid_cadence_import_count" => 0,
             "review_required_count" => 1,
             "current_freshness_count" => 0,
             "schema_validation_fail_count" => 1,
             "schema_validation_error_count" => 1,
             "schema_validation_warning_count" => 0,
             "schema_validation_remediation_count" => 1,
             "stale_freshness_count" => 2,
             "unknown_freshness_count" => 0,
             "freshness_status_counts" => %{"stale" => 2},
             "schema_validation_status_counts" => %{"fail" => 1},
             "import_status_counts" => %{"review_required_before_import" => 1},
             "cadence_import_status_counts" => %{"missing" => 1},
             "source_model_limit_count" => 1,
             "adapter_context_count" => 1,
             "adapter_trust_boundary_declared_count" => 0,
             "adapter_trust_boundary_missing_count" => 0,
             "adapter_trust_boundary_untrusted_count" => 1,
             "adapter_boundary_status_counts" => %{"untrusted" => 1},
             "resource_availability_pressure_count" => 2,
             "resource_availability_reason_counts" => %{
               "antenna_unavailable" => 1,
               "payload_unavailable" => 1
             },
             "resource_availability_reason_ids" => [
               "antenna_unavailable",
               "payload_unavailable"
             ],
             "unavailable_resource_reason_ids" => [
               "antenna_unavailable",
               "payload_unavailable"
             ],
             "resource_blocking_dimension_counts" => %{"communications" => 1},
             "review_type_counts" => %{"contact_allocation_review" => 1},
             "import_action_counts" => %{"review_contact_allocation" => 1},
             "source_review_type_counts" => %{"contact_allocation_review" => 1},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["mission_state_operational_readiness_report"]
           } =
             get_in(artifact, [
               "provenance",
               "source_reports",
               "operational_readiness_report"
             ])

    assert %{
             "paths" => ["mission_state.source_quality_gate_report"],
             "contract" => "quality_gate_report.v1",
             "count" => 1,
             "row_count" => 3,
             "readiness_level_counts" => %{"operator_review" => 1},
             "import_classification_counts" => %{"review_only" => 1},
             "status_counts" => %{"review_required" => 1},
             "gate_count" => 3,
             "passed_gate_count" => 1,
             "review_gate_count" => 2,
             "analysis_gate_count" => 0,
             "blocked_gate_count" => 0,
             "gate_status_counts" => %{"passed" => 1, "review_required" => 2},
             "gate_classification_counts" => %{"importable" => 1, "review_only" => 2},
             "ready_for_import_count" => 0,
             "manifest_review_required_count" => 1,
             "missing_import_count" => 1,
             "stale_freshness_count" => 2,
             "freshness_status_counts" => %{"stale" => 2},
             "schema_validation_fail_count" => 1,
             "schema_validation_error_count" => 1,
             "schema_validation_remediation_count" => 1,
             "schema_validation_status_counts" => %{"fail" => 1},
             "import_status_counts" => %{"review_required_before_import" => 1},
             "cadence_import_status_counts" => %{"missing" => 1},
             "resource_availability_pressure_count" => 2,
             "resource_availability_reason_counts" => %{
               "antenna_unavailable" => 1,
               "payload_unavailable" => 1
             },
             "resource_availability_reason_ids" => [
               "antenna_unavailable",
               "payload_unavailable"
             ],
             "unavailable_resource_reason_ids" => [
               "antenna_unavailable",
               "payload_unavailable"
             ],
             "resource_blocking_dimension_counts" => %{"communications" => 1},
             "source_readiness_report_count" => 1,
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["mission_state_quality_gate_report"]
           } = get_in(artifact, ["provenance", "source_reports", "quality_gate_report"])

    assert %{
             "paths" => ["mission_state.source_timeline_diff_report"],
             "contract" => "timeline_diff_report.v1",
             "count" => 1,
             "row_count" => 3,
             "removed_downlink_count" => 1,
             "removed_observation_count" => 1,
             "changed_downlink_shortfall_count" => 1,
             "changed_contact_feedback_count" => 0,
             "changed_observation_count" => 0,
             "changed_command_feedback_count" => 0,
             "changed_maneuver_feedback_count" => 0,
             "diff_status_counts" => %{"changed" => 1, "removed" => 2},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "mission_state_timeline_diff_report",
               "mission_state_timeline_diff_rows"
             ]
           } = get_in(artifact, ["provenance", "source_reports", "timeline_diff_report"])

    assert %{
             "paths" => ["mission_state.source_command_window_report"],
             "contract" => "command_window_report.v1",
             "count" => 1,
             "row_count" => 1,
             "command_feedback_count" => 1,
             "input_keys" => ["command_success_rate"],
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "mission_state_command_window_report",
               "mission_state_command_window_rows"
             ]
           } = get_in(artifact, ["provenance", "source_reports", "command_window_report"])

    assert %{
             "paths" => ["mission_state.source_maneuver_review_report"],
             "contract" => "maneuver_review_report.v1",
             "count" => 1,
             "row_count" => 1,
             "maneuver_success_feedback_count" => 1,
             "execution_uncertainty_declared_count" => 1,
             "execution_uncertainty_missing_count" => 0,
             "input_keys" => ["maneuver_execution_uncertainty", "maneuver_success_rate"],
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["mission_state_maneuver_review_report"]
           } = get_in(artifact, ["provenance", "source_reports", "maneuver_review_report"])

    assert %{
             "paths" => ["mission_state.source_station_calendar_report"],
             "contract" => "station_calendar_report.v1",
             "count" => 1,
             "row_count" => 1,
             "affected_contact_count" => 1,
             "provider_calendar_contention_group_count" => 0,
             "station_calendar_status_counts" => %{"reserved" => 1},
             "affected_contact_ground_station_counts" => %{"unused_station" => 1},
             "affected_contact_availability_counts" => %{"reserved" => 1},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "mission_state_station_calendar_report",
               "mission_state_station_calendar_rows"
             ]
           } = get_in(artifact, ["provenance", "source_reports", "station_calendar_report"])

    assert %{
             "paths" => ["mission_state.source_provider_counteroffer_report"],
             "contract" => "provider_counteroffer_report.v1",
             "count" => 1,
             "row_count" => 1,
             "reviewable_count" => 1,
             "counteroffer_cost_delta_count" => 1,
             "counteroffer_cost_delta_total" => 125.5,
             "counteroffer_timing_shift_count" => 1,
             "counteroffer_start_delta_count" => 1,
             "counteroffer_end_delta_count" => 1,
             "counteroffer_duration_delta_count" => 1,
             "counteroffer_lock_deadline_count" => 1,
             "earliest_counteroffer_lock_deadline_s" => 150.0,
             "counteroffer_status_counts" => %{"proposed" => 1},
             "required_operator_action_counts" => %{"review_provider_counteroffer" => 1},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "mission_state_provider_counteroffer_report",
               "mission_state_provider_counteroffer_rows"
             ]
           } =
             get_in(artifact, [
               "provenance",
               "source_reports",
               "provider_counteroffer_report"
             ])

    assert %{
             "paths" => ["mission_state.source_model_acceptance_report"],
             "contract" => "model_acceptance_report.v1",
             "count" => 1,
             "row_count" => 4,
             "record_count" => 3,
             "intended_use_counts" => %{"operational_import" => 1},
             "status_counts" => %{"blocked" => 1},
             "model_count" => 4,
             "accepted_count" => 1,
             "review_required_count" => 1,
             "blocked_count" => 2,
             "unknown_model_count" => 1,
             "validation_level_counts" => %{
               "artifact_contract" => 1,
               "analysis" => 1,
               "educational" => 1,
               "unknown" => 1
             },
             "model_ids_by_status" => %{
               "accepted" => ["orbit_data.simple_json"],
               "blocked" => ["propagator.two_body", "missing.model"],
               "review_required" => ["event.access_windows"]
             },
             "model_ids_by_validation_level" => %{
               "analysis" => ["event.access_windows"],
               "artifact_contract" => ["orbit_data.simple_json"],
               "educational" => ["propagator.two_body"],
               "unknown" => ["missing.model"]
             },
             "model_ids_by_intended_use" => %{
               "operational_import" => [
                 "orbit_data.simple_json",
                 "event.access_windows",
                 "propagator.two_body",
                 "missing.model"
               ]
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["mission_state_model_acceptance_report"]
           } =
             get_in(artifact, [
               "provenance",
               "source_reports",
               "model_acceptance_report"
             ])

    assert %{
             "paths" => ["mission_state.source_contact_intent"],
             "contract" => "contact_intent.v1",
             "count" => 1,
             "row_count" => 1,
             "station_feedback_count" => 1,
             "station_calendar_status_counts" => %{"reserved" => 1},
             "cadence_import_status_counts" => %{"missing" => 1},
             "policy_classification_counts" => %{"blocked_by_policy" => 1},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["mission_state_contact_intent"]
           } = get_in(artifact, ["provenance", "source_reports", "contact_intent"])

    assert %{
             "paths" => ["mission_state.source_constraint_report"],
             "contract" => "constraint_report.v1",
             "count" => 1,
             "row_count" => 2,
             "downlink_gap_row_count" => 1,
             "resource_margin_row_count" => 1,
             "status_counts" => %{"fail" => 1, "warning" => 1},
             "ground_station_counts" => %{"unused_station" => 1},
             "constraint_metric_counts" => %{
               "battery_margin" => 1,
               "selected_downlink_shortfall_mb" => 1
             },
             "constraint_resource_counts" => %{"battery_1" => 1},
             "constraint_spacecraft_counts" => %{"unused_spacecraft" => 1},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "mission_state_constraint_report",
               "mission_state_constraint_rows"
             ]
           } = get_in(artifact, ["provenance", "source_reports", "constraint_report"])

    assert %{
             "paths" => ["mission_state.source_objective_satisfaction_report"],
             "contract" => "objective_satisfaction_report.v1",
             "count" => 1,
             "row_count" => 3,
             "gap_row_count" => 3,
             "downlink_gap_row_count" => 1,
             "target_gap_row_count" => 1,
             "collection_latency_gap_row_count" => 1,
             "status_counts" => %{"partial" => 2, "unmet" => 1},
             "objective_type_counts" => %{
               "collection_latency" => 1,
               "downlink_completion" => 1,
               "target_coverage" => 1
             },
             "ground_station_counts" => %{"unused_station" => 1},
             "target_counts" => %{"unused_target" => 1},
             "collection_counts" => %{"unused_collection" => 1},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "mission_state_objective_report",
               "mission_state_objective_rows"
             ]
           } =
             get_in(artifact, [
               "provenance",
               "source_reports",
               "objective_satisfaction_report"
             ])

    assert %{
             "paths" => ["mission_state.source_objective_tradeoff_report"],
             "contract" => "objective_tradeoff_report.v1",
             "count" => 1,
             "row_count" => 3,
             "downlink_gap_row_count" => 1,
             "target_gap_row_count" => 1,
             "collection_latency_gap_row_count" => 2,
             "ground_station_counts" => %{"unused_station" => 1},
             "target_counts" => %{"unused_target" => 1},
             "collection_counts" => %{"unused_collection" => 1},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "mission_state_tradeoff_report",
               "mission_state_tradeoff_rows"
             ]
           } =
             get_in(artifact, [
               "provenance",
               "source_reports",
               "objective_tradeoff_report"
             ])

    assert %{
             "paths" => ["mission_state.source_score_term_report"],
             "contract" => "score_term_report.v1",
             "count" => 1,
             "row_count" => 3,
             "downlink_gap_row_count" => 1,
             "target_gap_row_count" => 1,
             "collection_latency_gap_row_count" => 1,
             "term_key_counts" => %{
               "collection_latency_gap_s" => 1,
               "downlink_shortfall_mb" => 1,
               "target_gap_count" => 1
             },
             "ground_station_counts" => %{"unused_station" => 1},
             "target_counts" => %{"unused_target" => 1},
             "collection_counts" => %{"unused_collection" => 1},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "mission_state_score_report",
               "mission_state_score_rows"
             ]
           } = get_in(artifact, ["provenance", "source_reports", "score_term_report"])

    assert %{
             "paths" => ["mission_state.source_link_capacity_report"],
             "contract" => "link_capacity_report.v1",
             "count" => 1,
             "row_count" => 1,
             "selected_shortfall_row_count" => 1,
             "actual_shortfall_row_count" => 1,
             "actual_throughput_row_count" => 1,
             "capacity_adjusted_throughput_row_count" => 1,
             "capacity_adjusted_throughput_mb_total" => 65.0,
             "selected_capacity_adjusted_throughput_mb_total" => 25.0,
             "unused_capacity_adjusted_throughput_mb_total" => 40.0,
             "ground_station_counts" => %{"unused_station" => 1},
             "capacity_adjusted_throughput_mb_by_ground_station" => %{
               "unused_station" => 65.0
             },
             "selected_capacity_adjusted_throughput_mb_by_ground_station" => %{
               "unused_station" => 25.0
             },
             "unused_capacity_adjusted_throughput_mb_by_ground_station" => %{
               "unused_station" => 40.0
             },
             "selected_contact_id_counts" => %{"dl_prior" => 1},
             "actual_throughput_contact_id_counts" => %{"dl_actual" => 1},
             "downlink_requirement_status_counts" => %{"shortfall" => 1},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "mission_state_link_capacity_report",
               "mission_state_link_capacity_rows"
             ]
           } = get_in(artifact, ["provenance", "source_reports", "link_capacity_report"])

    assert %{
             "paths" => ["mission_state.source_contact_allocation_report"],
             "contract" => "contact_allocation_report.v1",
             "count" => 1,
             "row_count" => 1,
             "blocked_row_count" => 0,
             "deferred_row_count" => 1,
             "allocation_status_counts" => %{"deferred" => 1},
             "allocation_reason_counts" => %{"capacity_pack" => 1},
             "capacity_pack_status_counts" => %{
               "deferred_by_reduced_station_capacity_pack" => 1
             },
             "capacity_pack_contact_status_counts" => %{
               "deferred_by_reduced_station_capacity_pack" => 1
             },
             "capacity_pack_required_capacity_fraction" => 0.35,
             "capacity_pack_deferred_required_capacity_fraction" => 0.35,
             "capacity_pack_required_capacity_fraction_by_status" => %{
               "deferred_by_reduced_station_capacity_pack" => 0.35
             },
             "capacity_pack_required_capacity_fraction_by_ground_station" => %{
               "unused_station" => 0.35
             },
             "capacity_pack_deferred_required_capacity_fraction_by_ground_station" => %{
               "unused_station" => 0.35
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "mission_state_allocation_report",
               "mission_state_allocation_rows"
             ]
           } = get_in(artifact, ["provenance", "source_reports", "contact_allocation_report"])

    assert %{
             "paths" => ["mission_state.source_contact_contention_resolution_report"],
             "contract" => "contact_contention_resolution_report.v1",
             "count" => 1,
             "row_count" => 1,
             "recommendation_count" => 1,
             "deferred_contact_count" => 1,
             "resolution_status_counts" => %{"deferred" => 1},
             "selection_reason_counts" => %{"highest_score" => 1},
             "capacity_pack_required_capacity_fraction" => 0.55,
             "capacity_pack_selected_required_capacity_fraction" => 0.2,
             "capacity_pack_deferred_required_capacity_fraction" => 0.35,
             "capacity_pack_required_capacity_fraction_by_ground_station" => %{
               "unused_station" => 0.55
             },
             "capacity_pack_selected_required_capacity_fraction_by_ground_station" => %{
               "unused_station" => 0.2
             },
             "capacity_pack_deferred_required_capacity_fraction_by_ground_station" => %{
               "unused_station" => 0.35
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "mission_state_contention_report",
               "mission_state_contention_rows"
             ]
           } =
             get_in(artifact, [
               "provenance",
               "source_reports",
               "contact_contention_resolution_report"
             ])

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    invalid_model_acceptance_model_ids =
      put_in(
        artifact,
        [
          "provenance",
          "source_reports",
          "model_acceptance_report",
          "model_ids_by_status",
          "blocked"
        ],
        ["propagator.two_body", 42]
      )

    assert {:error, invalid_model_acceptance_model_ids_report} =
             Schema.validate_artifact(invalid_model_acceptance_model_ids)

    assert Enum.any?(
             invalid_model_acceptance_model_ids_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.model_acceptance_report.model_ids_by_status.blocked" and
                 &1["message"] == "must contain only strings")
           )

    invalid_validation_safety_case_summary =
      put_in(
        artifact,
        [
          "provenance",
          "source_reports",
          "validation_safety_case_summary"
        ],
        %{
          "contract" => "validation_safety_case_summary.v1",
          "paths" => ["mission_state.source_validation_safety_case_summary"],
          "count" => 1,
          "row_count" => 2,
          "blocked_evidence_count" => -1,
          "evidence_status_counts" => %{"blocked" => -1},
          "evidence_refs_by_status" => %{"blocked" => ["safety_case.blocked", 42]},
          "schema_warning_count" => -1
        }
      )

    assert {:error, invalid_validation_safety_case_summary_report} =
             Schema.validate_artifact(invalid_validation_safety_case_summary)

    invalid_validation_safety_case_errors =
      invalid_validation_safety_case_summary_report["errors"]

    assert Enum.any?(
             invalid_validation_safety_case_errors,
             &(&1["path"] ==
                 "$.provenance.source_reports.validation_safety_case_summary.blocked_evidence_count" and
                 &1["message"] == "must be a non-negative integer")
           )

    assert Enum.any?(
             invalid_validation_safety_case_errors,
             &(&1["path"] ==
                 "$.provenance.source_reports.validation_safety_case_summary.evidence_status_counts.blocked" and
                 &1["message"] == "must be a non-negative integer")
           )

    assert Enum.any?(
             invalid_validation_safety_case_errors,
             &(&1["path"] ==
                 "$.provenance.source_reports.validation_safety_case_summary.evidence_refs_by_status.blocked" and
                 &1["message"] == "must contain only strings")
           )

    assert Enum.any?(
             invalid_validation_safety_case_errors,
             &(&1["path"] ==
                 "$.provenance.source_reports.validation_safety_case_summary.schema_warning_count" and
                 &1["message"] == "must be a non-negative integer")
           )
  end
end
