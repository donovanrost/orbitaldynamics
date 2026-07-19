defmodule OrbitalDynamics.CadenceImportWrappedSuppressionReportsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, Schema}

  test "candidate refresh import preserves wrapped resource filter reports" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_resource_filter_import:001",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "resource_filter_report" => %{
            "schema_contract" => "resource_filter_report.v1",
            "model" => "resource_summary_availability_and_margin_filter",
            "invalid_resource_summary_inputs" => [
              %{
                "resource_summary_id" => "resource_summary:wrapped_stale_sat",
                "spacecraft_id" => "sat_1",
                "invalid_resource_summary_input_reason" => "missing_resource_summary_epoch",
                "approval_status" => "operator_review_required",
                "approval_requirements" => [
                  %{
                    "activity_id" => "resource_summary:wrapped_stale_sat",
                    "activity_type" => "resource_summary",
                    "action" => "review_invalid_resource_filter_summary",
                    "requirement_type" => "resource_filter_input_validation"
                  }
                ],
                "policy_decision" => %{
                  "schema_contract" => "policy_decision.v1",
                  "policy_bundle_id" => "resource_filter_input_guard_v1"
                },
                "source_resource_summary" => %{
                  "resource_summary_id" => "resource_summary:wrapped_stale_sat"
                }
              }
            ],
            "suppressed_candidates" => [
              %{
                "id" => "obs_wrapped_payload_blocked",
                "type" => "observe",
                "scenario_id" => "leo_1",
                "spacecraft_id" => "sat_1",
                "target_id" => "target_a",
                "starts_at_s" => 60.0,
                "ends_at_s" => 180.0,
                "suppressed_reason" => "payload_unavailable",
                "source_window_id" => "window:leo_1:target_visibility:target_a:1",
                "payload_available" => false,
                "resource_blocking_dimension" => "payload",
                "resource_trust_boundary_status" => "declared",
                "resource_trust_boundary" => "wrapped_resource_filter_report",
                "approval_status" => "blocked_by_policy",
                "approval_requirements" => [
                  %{
                    "activity_id" => "obs_wrapped_payload_blocked",
                    "activity_type" => "observe",
                    "action" => "review_suppressed_observation",
                    "requirement_type" => "observation_reassignment"
                  }
                ],
                "approval_rule_matches" => [
                  %{
                    "rule_id" => "payload_unavailable_observation_block",
                    "classification" => "blocked_by_policy"
                  }
                ],
                "policy_decision" => %{
                  "schema_contract" => "policy_decision.v1",
                  "policy_bundle_id" => "degraded_payload_guard_v1",
                  "escalations" => [
                    %{
                      "rule_id" => "payload_unavailable_observation_block",
                      "required_authority" => "payload_operations_authority",
                      "escalation_level" => "payload_lead",
                      "escalation_queue" => "payload_ops",
                      "escalation_role" => "payload_scheduler",
                      "sla_s" => 900
                    }
                  ]
                },
                "source_resource_summary" => %{"spacecraft_id" => "sat_1"}
              }
            ]
          }
        }
      ]
    }

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_resource_filter_import:001",
             "row_count" => 2,
             "review_required_count" => 2,
             "blocked_count" => 0,
             "import_action_counts" => %{"review_resource_suppression" => 2},
             "source_review_type_counts" => %{"resource_suppression" => 2}
           } = manifest

    assert %{
             "import_action" => "review_resource_suppression",
             "source_review_type" => "resource_suppression",
             "source_review_action" => "review_invalid_resource_filter_summary",
             "import_status" => "review_required_before_import",
             "approval_status" => "operator_review_required",
             "subject_id" => "resource_summary:wrapped_stale_sat",
             "spacecraft_id" => "sat_1",
             "required_operator_action" => "review_invalid_resource_filter_summary",
             "invalid_resource_summary_input" => true,
             "invalid_resource_summary_input_reason" => "missing_resource_summary_epoch",
             "suppressed_reason" => "invalid_resource_summary_input",
             "resource_blocking_dimension" => "spacecraft_health",
             "policy_bundle_id" => "resource_filter_input_guard_v1",
             "has_cadence_import" => false,
             "source_resource_summary" => %{
               "resource_summary_id" => "resource_summary:wrapped_stale_sat"
             },
             "source_resource_suppression" => %{
               "resource_summary_id" => "resource_summary:wrapped_stale_sat",
               "invalid_resource_summary_input_reason" => "missing_resource_summary_epoch"
             },
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.source_result_artifact[0].resource_filter_report.invalid_resource_summary_inputs",
               "review_type" => "resource_suppression",
               "source_resource_suppression" => %{
                 "resource_summary_id" => "resource_summary:wrapped_stale_sat"
               },
               "source_policy_decision" => %{
                 "policy_bundle_id" => "resource_filter_input_guard_v1"
               }
             }
           } =
             Enum.find(
               manifest["rows"],
               &(&1["required_operator_action"] == "review_invalid_resource_filter_summary")
             )

    assert %{
             "import_action" => "review_resource_suppression",
             "source_review_type" => "resource_suppression",
             "source_review_action" => "review_suppressed_observation",
             "import_status" => "review_required_before_import",
             "approval_status" => "blocked_by_policy",
             "subject_id" => "obs_wrapped_payload_blocked",
             "activity_id" => "obs_wrapped_payload_blocked",
             "activity_type" => "observe",
             "spacecraft_id" => "sat_1",
             "target_id" => "target_a",
             "source_window_id" => "window:leo_1:target_visibility:target_a:1",
             "required_operator_action" => "review_suppressed_observation",
             "suppressed_reason" => "payload_unavailable",
             "payload_available" => false,
             "resource_blocking_dimension" => "payload",
             "resource_trust_boundary_status" => "declared",
             "resource_trust_boundary" => "wrapped_resource_filter_report",
             "requirement_type" => "observation_reassignment",
             "required_authority" => "payload_operations_authority",
             "policy_bundle_id" => "degraded_payload_guard_v1",
             "rule_id" => "payload_unavailable_observation_block",
             "escalation_queue" => "payload_ops",
             "has_cadence_import" => false,
             "source_resource_summary" => %{"spacecraft_id" => "sat_1"},
             "source_resource_suppression" => %{
               "id" => "obs_wrapped_payload_blocked",
               "suppressed_reason" => "payload_unavailable",
               "payload_available" => false
             },
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.source_result_artifact[0].resource_filter_report.suppressed_candidates",
               "review_type" => "resource_suppression",
               "source_resource_suppression" => %{
                 "id" => "obs_wrapped_payload_blocked",
                 "resource_blocking_dimension" => "payload"
               },
               "source_policy_decision" => %{
                 "policy_bundle_id" => "degraded_payload_guard_v1"
               }
             }
           } =
             Enum.find(
               manifest["rows"],
               &(&1["required_operator_action"] == "review_suppressed_observation")
             )

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh import preserves wrapped contact filter reports" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_contact_filter_import:001",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "source_contact_filter_report" => %{
            "schema_contract" => "contact_filter_report.v1",
            "model" => "thin_ground_network_availability_filter",
            "suppressed_candidates" => [
              %{
                "id" => "dl_wrapped_reserved",
                "base_candidate_id" => "dl_wrapped",
                "type" => "downlink",
                "scenario_id" => "leo_1",
                "starts_at_s" => 100.0,
                "ends_at_s" => 160.0,
                "ground_station_id" => "equator_prime",
                "direction" => "downlink",
                "station_availability" => "reserved",
                "station_contention_status" => "reserved_overlap",
                "station_reservation_id" => "reservation:equator_prime:dl_wrapped",
                "station_reserved_by" => "network_partner",
                "station_reservation_status" => "confirmed",
                "station_reservation_match_status" => "overlap",
                "approval_status" => "operator_review_required",
                "approval_requirements" => [
                  %{
                    "activity_id" => "dl_wrapped_reserved",
                    "activity_type" => "downlink",
                    "action" => "review_suppressed_contact",
                    "requirement_type" => "contact_schedule_change",
                    "reason" => "ground_station_reserved"
                  }
                ],
                "approval_rule_matches" => [
                  %{"rule_id" => "reserved_station_contact_review"}
                ],
                "policy_decision" => %{
                  "schema_contract" => "policy_decision.v1",
                  "policy_bundle_id" => "ground_network_allocation_v1",
                  "escalations" => [
                    %{
                      "rule_id" => "reserved_station_contact_review",
                      "required_authority" => "contact_schedule_authority",
                      "escalation_level" => "ops_lead",
                      "escalation_queue" => "ground_network",
                      "escalation_role" => "network_scheduler",
                      "sla_s" => 600
                    }
                  ]
                },
                "suppressed_reason" => "ground_station_reserved",
                "duplicate_suppressed_candidate_id_collision" => true,
                "duplicate_suppressed_candidate_index" => 1,
                "duplicate_suppressed_candidate_count" => 1,
                "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
                "source_contact_candidate" => %{"id" => "dl_wrapped_reserved"}
              }
            ]
          }
        }
      ]
    }

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_contact_filter_import:001",
             "row_count" => 1,
             "review_required_count" => 1,
             "import_action_counts" => %{"review_contact_suppression" => 1},
             "source_review_type_counts" => %{"contact_suppression" => 1}
           } = manifest

    assert [row] = manifest["rows"]

    assert Map.take(row, [
             "import_action",
             "source_review_type",
             "source_review_action",
             "import_status",
             "approval_status",
             "subject_id",
             "activity_id",
             "base_candidate_id",
             "activity_type",
             "ground_station_id",
             "direction",
             "station_availability",
             "station_contention_status",
             "station_reservation_id",
             "station_reserved_by",
             "station_reservation_status",
             "station_reservation_match_status",
             "required_operator_action",
             "requirement_type",
             "required_authority",
             "policy_bundle_id",
             "rule_id",
             "escalation_queue",
             "duplicate_suppressed_candidate_id_collision",
             "duplicate_suppressed_candidate_index",
             "duplicate_suppressed_candidate_count",
             "source_window_id",
             "has_cadence_import"
           ]) == %{
             "import_action" => "review_contact_suppression",
             "source_review_type" => "contact_suppression",
             "source_review_action" => "review_suppressed_contact",
             "import_status" => "review_required_before_import",
             "approval_status" => "operator_review_required",
             "subject_id" => "dl_wrapped_reserved",
             "activity_id" => "dl_wrapped_reserved",
             "base_candidate_id" => "dl_wrapped",
             "activity_type" => "downlink",
             "ground_station_id" => "equator_prime",
             "direction" => "downlink",
             "station_availability" => "reserved",
             "station_contention_status" => "reserved_overlap",
             "station_reservation_id" => "reservation:equator_prime:dl_wrapped",
             "station_reserved_by" => "network_partner",
             "station_reservation_status" => "confirmed",
             "station_reservation_match_status" => "overlap",
             "required_operator_action" => "review_suppressed_contact",
             "requirement_type" => "contact_schedule_change",
             "required_authority" => "contact_schedule_authority",
             "policy_bundle_id" => "ground_network_allocation_v1",
             "rule_id" => "reserved_station_contact_review",
             "escalation_queue" => "ground_network",
             "duplicate_suppressed_candidate_id_collision" => true,
             "duplicate_suppressed_candidate_index" => 1,
             "duplicate_suppressed_candidate_count" => 1,
             "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
             "has_cadence_import" => false
           }

    assert row["source_contact_candidate"] == %{"id" => "dl_wrapped_reserved"}

    assert %{
             "id" => "dl_wrapped_reserved",
             "suppressed_reason" => "ground_station_reserved",
             "station_reservation_id" => "reservation:equator_prime:dl_wrapped"
           } = row["source_contact_suppression"]

    assert get_in(row, ["source_review_row", "source"]) ==
             "candidate_refresh.source_result_artifact[0].source_contact_filter_report.suppressed_candidates"

    assert get_in(row, ["source_review_row", "review_type"]) == "contact_suppression"

    assert get_in(row, [
             "source_review_row",
             "source_contact_suppression",
             "station_reservation_match_status"
           ]) == "overlap"

    assert get_in(row, [
             "source_review_row",
             "source_policy_decision",
             "policy_bundle_id"
           ]) == "ground_network_allocation_v1"

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end
end
