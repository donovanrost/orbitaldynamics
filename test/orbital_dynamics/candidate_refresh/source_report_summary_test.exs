defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CandidateRefresh, Validation}

  test "summarizes source report provenance without replaying refresh state" do
    refresh = %{
      "mission_state" => %{
        "source_candidate_rejection_report" => %{
          "schema_contract" => "candidate_rejection_report.v1",
          "rejected_count" => 1,
          "reviewable_count" => 1,
          "rows" => [
            %{
              "id" => "candidate_rejection:dl_reserved",
              "candidate_id" => "dl_reserved",
              "ground_station_id" => "unused_station",
              "required_operator_action" => "review_candidate_rejection",
              "trust_boundary" => "mission_state_candidate_rejection_rows"
            }
          ],
          "provenance" => %{"trust_boundary" => "mission_state_candidate_rejection_report"}
        },
        "source_provider_counteroffer_report" => %{
          "schema_contract" => "provider_counteroffer_report.v1",
          "counteroffer_count" => 1,
          "reviewable_count" => 1,
          "counteroffer_status_counts" => %{"proposed" => 1},
          "rows" => [
            %{
              "id" => "provider_counteroffer:dl_reserved",
              "provider_counteroffer_id" => "counteroffer_dl_reserved",
              "provider_counteroffer_status" => "proposed",
              "provider_counteroffer_lock_deadline_s" => 180.0,
              "provider_counteroffer_start_delta_s" => 20.0,
              "provider_counteroffer_end_delta_s" => 25.0,
              "provider_counteroffer_duration_delta_s" => 5.0,
              "reviewable" => true,
              "required_operator_action" => "review_provider_counteroffer",
              "trust_boundary" => "mission_state_provider_counteroffer_rows"
            }
          ],
          "provenance" => %{"trust_boundary" => "mission_state_provider_counteroffer_report"}
        },
        "source_contact_contention_report" => %{
          "schema_contract" => "contact_contention_report.v1",
          "input_contact_count" => 3,
          "conflict_group_count" => 1,
          "invalid_contact_input_count" => 1,
          "conflict_groups" => [
            %{
              "id" => "station:equator_prime:contention:1",
              "ground_station_id" => "equator_prime",
              "resource_scope" => "ground_station",
              "direction" => "mixed",
              "directions" => ["Down Link", "tracking_pass"],
              "contact_ids" => ["dl_primary", "dl_backup"],
              "source_contact_candidates" => [
                %{"id" => "dl_primary", "direction" => "Down Link"},
                %{"id" => "dl_backup", "direction" => "tracking_pass"}
              ],
              "required_operator_action" => "review_contact_contention",
              "trust_boundary" => "mission_state_contact_contention_group"
            }
          ],
          "invalid_contact_inputs" => [
            %{
              "contact_id" => "missing_station",
              "invalid_contact_input_reason" => "missing_ground_station_id",
              "required_operator_action" => "review_invalid_contact_contention_input"
            }
          ],
          "direction_counts" => %{"stale_direction" => 99},
          "contact_ids_by_direction" => %{"stale_direction" => ["stale_contact"]},
          "provenance" => %{"trust_boundary" => "mission_state_contact_contention_report"}
        },
        "source_contact_allocation_report" => %{
          "schema_contract" => "contact_allocation_report.v1",
          "rows" => [
            %{
              "contact_id" => "dl_reserved",
              "allocation_status" => "deferred",
              "effective_allocation_status" => "deferred",
              "allocation_reason" => "station_reserved",
              "ground_station_id" => "gs_equator",
              "station_availability" => "reserved",
              "station_calendar_overlap_count" => 1,
              "station_calendar_precedence_availability" => "reserved",
              "station_calendar_precedence_rank" => 1,
              "trust_boundary" => "mission_state_contact_allocation_rows"
            },
            %{
              "contact_id" => "dl_unavailable",
              "allocation_status" => "blocked",
              "effective_allocation_status" => "blocked",
              "allocation_reason" => "station_unavailable",
              "ground_station_id" => "gs_polar",
              "station_availability" => "unavailable",
              "station_calendar_overlap_count" => 1,
              "station_calendar_precedence_availability" => "unavailable",
              "station_calendar_precedence_rank" => 2,
              "trust_boundary" => "mission_state_contact_allocation_rows"
            }
          ],
          "station_pressure_contact_ids_by_ground_station_id" => %{
            "gs_equator" => ["dl_reserved"],
            "gs_polar" => ["dl_unavailable"]
          },
          "station_pressure_contact_ids_by_availability" => %{
            "reserved" => ["dl_reserved"],
            "unavailable" => ["dl_unavailable"]
          },
          "station_pressure_contact_ids_by_precedence_availability" => %{
            "reserved" => ["dl_reserved"],
            "unavailable" => ["dl_unavailable"]
          },
          "station_pressure_contact_ids_by_precedence_rank" => %{
            "1" => ["dl_reserved"],
            "2" => ["dl_unavailable"]
          },
          "provenance" => %{"trust_boundary" => "mission_state_contact_allocation_report"}
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
        "source_quality_gate_report" => %{
          "schema_contract" => "quality_gate_report.v1",
          "model" => "artifact_only_operational_quality_gate_report",
          "source_readiness_report_id" => "operational_readiness:planned_activity.v1:activity_1",
          "readiness_level" => "blocked",
          "import_classification" => "blocked",
          "status" => "blocked",
          "gate_count" => 99,
          "passed_gate_count" => 99,
          "review_gate_count" => 99,
          "analysis_gate_count" => 99,
          "blocked_gate_count" => 99,
          "gate_status_counts" => %{"stale_status" => 99},
          "gate_classification_counts" => %{"stale_classification" => 99},
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
              "id" => "quality_gate:activity_1:adapter_boundary:2",
              "rank" => 2,
              "gate_id" => "adapter_boundary",
              "status" => "blocked",
              "classification" => "blocked",
              "reason" => "adapter import context declares untrusted trust-boundary evidence",
              "adapter_context_count" => 1,
              "adapter_trust_boundary_declared_count" => 0,
              "adapter_trust_boundary_missing_count" => 0,
              "adapter_trust_boundary_untrusted_count" => 1,
              "adapter_boundary_status_counts" => %{"untrusted" => 1}
            },
            %{
              "id" => "quality_gate:activity_1:resource_availability:3",
              "rank" => 3,
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
              "id" => "quality_gate:activity_1:cadence_import:4",
              "rank" => 4,
              "gate_id" => "cadence_import",
              "status" => "review_required",
              "classification" => "review_only",
              "reason" => "source freshness evidence is stale or unknown",
              "ready_for_import_count" => 1,
              "stale_freshness_count" => 1,
              "freshness_status_counts" => %{"stale" => 1},
              "schema_validation_fail_count" => 1,
              "schema_validation_error_count" => 1,
              "schema_validation_status_counts" => %{"fail" => 1},
              "import_status_counts" => %{"ready_for_import" => 1},
              "cadence_import_status_counts" => %{"present" => 1}
            }
          ],
          "provenance" => %{
            "trust_boundary" => "mission_state_quality_gate_report"
          }
        }
      }
    }

    assert %{
             "model" => "artifact_only_candidate_refresh_source_report_summary",
             "source" => "candidate_refresh.source_report_provenance",
             "source_report_family_count" => 6,
             "source_report_contact_contention_direction_counts" => %{
               "downlink" => 1,
               "tracking" => 1
             },
             "source_report_contact_contention_contact_ids_by_direction" => %{
               "downlink" => ["dl_primary"],
               "tracking" => ["dl_backup"]
             },
             "source_report_contact_contention_direction_routing" => %{
               "downlink" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["dl_primary"]
               },
               "tracking" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["dl_backup"]
               }
             },
             "source_report_contact_contention_invalid_contact_input_ids" => [
               "missing_station"
             ],
             "source_report_contact_contention_branch_local_contact_contention_pressure" => true,
             "source_report_contact_contention_branch_local_conflict_pressure" => true,
             "source_report_contact_contention_branch_local_invalid_contact_input_pressure" =>
               true,
             "source_report_contact_contention_branch_local_review_pressure" => true,
             "source_report_count" => 6,
             "source_report_row_count" => 14,
             "source_report_counts_by_family" => %{
               "candidate_rejection_report" => 1,
               "contact_allocation_report" => 1,
               "contact_contention_report" => 1,
               "model_acceptance_report" => 1,
               "provider_counteroffer_report" => 1,
               "quality_gate_report" => 1
             },
             "source_report_row_counts_by_family" => %{
               "candidate_rejection_report" => 1,
               "contact_allocation_report" => 2,
               "contact_contention_report" => 2,
               "model_acceptance_report" => 4,
               "provider_counteroffer_report" => 1,
               "quality_gate_report" => 4
             },
             "source_report_counts_by_contract" => %{
               "candidate_rejection_report.v1" => 1,
               "contact_allocation_report.v1" => 1,
               "contact_contention_report.v1" => 1,
               "model_acceptance_report.v1" => 1,
               "provider_counteroffer_report.v1" => 1,
               "quality_gate_report.v1" => 1
             },
             "source_report_row_counts_by_contract" => %{
               "candidate_rejection_report.v1" => 1,
               "contact_allocation_report.v1" => 2,
               "contact_contention_report.v1" => 2,
               "model_acceptance_report.v1" => 4,
               "provider_counteroffer_report.v1" => 1,
               "quality_gate_report.v1" => 4
             },
             "source_report_counts_by_trust_boundary_status" => %{"declared" => 6},
             "source_report_row_counts_by_trust_boundary_status" => %{"declared" => 14},
             "source_report_contracts" => [
               "candidate_rejection_report.v1",
               "contact_allocation_report.v1",
               "contact_contention_report.v1",
               "model_acceptance_report.v1",
               "provider_counteroffer_report.v1",
               "quality_gate_report.v1"
             ],
             "source_report_families" => [
               "candidate_rejection_report",
               "contact_allocation_report",
               "contact_contention_report",
               "model_acceptance_report",
               "provider_counteroffer_report",
               "quality_gate_report"
             ],
             "source_report_paths" => [
               "mission_state.source_candidate_rejection_report",
               "mission_state.source_contact_allocation_report",
               "mission_state.source_contact_contention_report",
               "mission_state.source_model_acceptance_report",
               "mission_state.source_provider_counteroffer_report",
               "mission_state.source_quality_gate_report"
             ],
             "source_report_paths_by_family" => %{
               "candidate_rejection_report" => [
                 "mission_state.source_candidate_rejection_report"
               ],
               "contact_allocation_report" => [
                 "mission_state.source_contact_allocation_report"
               ],
               "contact_contention_report" => [
                 "mission_state.source_contact_contention_report"
               ],
               "model_acceptance_report" => [
                 "mission_state.source_model_acceptance_report"
               ],
               "provider_counteroffer_report" => [
                 "mission_state.source_provider_counteroffer_report"
               ],
               "quality_gate_report" => [
                 "mission_state.source_quality_gate_report"
               ]
             },
             "source_report_paths_by_contract" => %{
               "candidate_rejection_report.v1" => [
                 "mission_state.source_candidate_rejection_report"
               ],
               "contact_allocation_report.v1" => [
                 "mission_state.source_contact_allocation_report"
               ],
               "contact_contention_report.v1" => [
                 "mission_state.source_contact_contention_report"
               ],
               "model_acceptance_report.v1" => [
                 "mission_state.source_model_acceptance_report"
               ],
               "provider_counteroffer_report.v1" => [
                 "mission_state.source_provider_counteroffer_report"
               ],
               "quality_gate_report.v1" => [
                 "mission_state.source_quality_gate_report"
               ]
             },
             "source_report_paths_by_trust_boundary_status" => %{
               "declared" => [
                 "mission_state.source_candidate_rejection_report",
                 "mission_state.source_contact_allocation_report",
                 "mission_state.source_contact_contention_report",
                 "mission_state.source_model_acceptance_report",
                 "mission_state.source_provider_counteroffer_report",
                 "mission_state.source_quality_gate_report"
               ]
             },
             "trust_boundary_status_counts" => %{"declared" => 6},
             "source_reports" => source_reports,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
               "replay_scope" => "input_provenance_summary_only"
             }
           } = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "count" => 1,
             "row_count" => 1,
             "reviewable_count" => 1,
             "candidate_rejection_candidate_id_counts" => %{"dl_reserved" => 1},
             "candidate_rejection_ground_station_counts" => %{"unused_station" => 1},
             "trust_boundary_status" => "declared"
           } = source_reports["candidate_rejection_report"]

    assert %{
             "count" => 1,
             "row_count" => 1,
             "reviewable_count" => 1,
             "counteroffer_lock_deadline_count" => 1,
             "counteroffer_timing_shift_count" => 1,
             "counteroffer_start_delta_count" => 1,
             "counteroffer_end_delta_count" => 1,
             "counteroffer_duration_delta_count" => 1,
             "trust_boundary_status" => "declared"
           } = source_reports["provider_counteroffer_report"]

    assert %{
             "count" => 1,
             "row_count" => 2,
             "blocked_row_count" => 1,
             "deferred_row_count" => 1,
             "allocation_status_counts" => %{"blocked" => 1, "deferred" => 1},
             "allocation_reason_counts" => %{
               "station_reserved" => 1,
               "station_unavailable" => 1
             },
             "station_pressure_contact_count" => 2,
             "station_pressure_ground_station_counts" => %{
               "gs_equator" => 1,
               "gs_polar" => 1
             },
             "station_pressure_availability_counts" => %{
               "reserved" => 1,
               "unavailable" => 1
             },
             "station_pressure_precedence_availability_counts" => %{
               "reserved" => 1,
               "unavailable" => 1
             },
             "station_pressure_precedence_rank_counts" => %{"1" => 1, "2" => 1},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "mission_state_contact_allocation_report",
               "mission_state_contact_allocation_rows"
             ]
           } = source_reports["contact_allocation_report"]

    assert %{
             "count" => 1,
             "row_count" => 2,
             "conflict_group_count" => 1,
             "invalid_contact_input_count" => 1,
             "invalid_contact_input_ids" => ["missing_station"],
             "resource_scope_counts" => %{"ground_station" => 1},
             "contact_contention_ground_station_counts" => %{"equator_prime" => 1},
             "contact_contention_contact_id_counts" => %{"dl_backup" => 1, "dl_primary" => 1},
             "direction_counts" => %{"downlink" => 1, "tracking" => 1},
             "contact_ids_by_direction" => %{
               "downlink" => ["dl_primary"],
               "tracking" => ["dl_backup"]
             },
             "direction_routing" => %{
               "downlink" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["dl_primary"]
               },
               "tracking" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["dl_backup"]
               }
             },
             "required_operator_action_counts" => %{
               "review_contact_contention" => 1,
               "review_invalid_contact_contention_input" => 1
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "mission_state_contact_contention_group",
               "mission_state_contact_contention_report"
             ]
           } = source_reports["contact_contention_report"]

    contact_contention_replay_summary = %{
      "model" => "artifact_only_candidate_refresh_contact_contention_replay_summary",
      "source" => "candidate_refresh.source_report_provenance.contact_contention_report",
      "contract" => "contact_contention_report.v1",
      "source_report_count" => 1,
      "source_report_row_count" => 2,
      "source_report_paths" => ["mission_state.source_contact_contention_report"],
      "conflict_group_count" => 1,
      "invalid_contact_input_count" => 1,
      "invalid_contact_input_ids" => ["missing_station"],
      "resource_scope_counts" => %{"ground_station" => 1},
      "contact_contention_ground_station_counts" => %{"equator_prime" => 1},
      "contact_contention_contact_id_counts" => %{"dl_backup" => 1, "dl_primary" => 1},
      "direction_counts" => %{"downlink" => 1, "tracking" => 1},
      "contact_ids_by_direction" => %{
        "downlink" => ["dl_primary"],
        "tracking" => ["dl_backup"]
      },
      "direction_routing" => %{
        "downlink" => %{
          "contact_count" => 1,
          "contact_ids" => ["dl_primary"]
        },
        "tracking" => %{
          "contact_count" => 1,
          "contact_ids" => ["dl_backup"]
        }
      },
      "required_operator_action_counts" => %{
        "review_contact_contention" => 1,
        "review_invalid_contact_contention_input" => 1
      },
      "trust_boundary_status" => "declared",
      "trust_boundaries" => [
        "mission_state_contact_contention_group",
        "mission_state_contact_contention_report"
      ],
      "branch_local_contact_contention_pressure" => true,
      "branch_local_contact_contention_conflict_pressure" => true,
      "branch_local_invalid_contact_input_pressure" => true,
      "branch_local_contact_contention_review_pressure" => true,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => "contact_contention_source_report_provenance_only",
        "operator_authority" => "not_granted_by_contact_contention_replay_summary",
        "contact_allocation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_contact_contention_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }

    assert CandidateRefresh.contact_contention_replay_summary(refresh) ==
             contact_contention_replay_summary

    assert OrbitalDynamics.candidate_refresh_contact_contention_replay_summary(refresh) ==
             contact_contention_replay_summary

    assert %{
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
             "trust_boundary_status" => "declared"
           } = source_reports["model_acceptance_report"]

    assert %{
             "count" => 1,
             "row_count" => 4,
             "readiness_level_counts" => %{"blocked" => 1},
             "import_classification_counts" => %{"blocked" => 1},
             "status_counts" => %{"blocked" => 1},
             "gate_count" => 4,
             "passed_gate_count" => 1,
             "review_gate_count" => 2,
             "analysis_gate_count" => 0,
             "blocked_gate_count" => 1,
             "gate_status_counts" => %{"blocked" => 1, "passed" => 1, "review_required" => 2},
             "gate_classification_counts" => %{
               "blocked" => 1,
               "importable" => 1,
               "review_only" => 2
             },
             "ready_for_import_count" => 1,
             "stale_freshness_count" => 1,
             "freshness_status_counts" => %{"stale" => 1},
             "schema_validation_fail_count" => 1,
             "schema_validation_error_count" => 1,
             "schema_validation_status_counts" => %{"fail" => 1},
             "import_status_counts" => %{"ready_for_import" => 1},
             "cadence_import_status_counts" => %{"present" => 1},
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
             "source_readiness_report_count" => 1,
             "trust_boundary_status" => "declared"
           } = source_reports["quality_gate_report"]

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_reports}
    }

    assert OrbitalDynamics.candidate_refresh_source_report_summary(artifact) ==
             CandidateRefresh.source_report_summary(artifact)

    assert %{
             "source_report_contact_contention_branch_local_contact_contention_pressure" => true,
             "source_report_contact_contention_branch_local_conflict_pressure" => true,
             "source_report_contact_contention_branch_local_invalid_contact_input_pressure" =>
               true,
             "source_report_contact_contention_branch_local_review_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.contact_contention_replay_summary(artifact) ==
             contact_contention_replay_summary

    assert OrbitalDynamics.candidate_refresh_contact_contention_replay_summary(artifact) ==
             contact_contention_replay_summary
  end
end
