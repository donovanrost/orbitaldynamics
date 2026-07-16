defmodule OrbitalDynamics.OperatorReview.RepairArtifactTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema}

  test "builds repair review package from approval requirements and warnings" do
    artifact = %{
      "schema_version" => 2,
      "repair_metadata" => %{
        "repair_id" => "repair:1",
        "timeline_protection" => %{
          "preserved_locked_or_approved_count" => 1,
          "preserved_executed_count" => 0,
          "changed_locked_or_approved_count" => 0,
          "changed_executed_count" => 0,
          "preserved_locked_or_approved_activity_ids" => ["locked_dl"],
          "preserved_executed_activity_ids" => [],
          "changed_locked_or_approved_activity_ids" => [],
          "changed_executed_activity_ids" => []
        }
      },
      "approval_requirements" => [
        %{
          "schema_contract" => "approval_requirement.v1",
          "activity_id" => "dl_2",
          "activity_type" => "downlink",
          "action" => "approve_moved_contact",
          "requirement_type" => "contact_schedule_change",
          "reason" => "missed_contact_rescheduled"
        }
      ],
      "policy_decision" => %{
        "schema_contract" => "policy_decision.v1",
        "classification" => "operator_review_required",
        "policy_bundle_id" => "mission_ops_escalation_v1",
        "approval_requirement_count" => 1,
        "risk_count" => 0,
        "rule_matches" => [],
        "escalations" => [
          %{
            "rule_id" => "contact_execution_coordination",
            "classification" => "operator_review_required",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network",
            "escalation_role" => "contact_scheduler",
            "required_authority" => "contact_schedule_authority",
            "sla_s" => 1800
          }
        ],
        "assumptions" => %{"boundary" => "artifact_only_no_authority_lookup"}
      },
      "deltas" => [
        %{
          "schema_contract" => "plan_delta.v1",
          "activity_id" => "dl_1",
          "activity_type" => "downlink",
          "status" => "missed",
          "repair_action" => "moved",
          "reason" => "missed_contact_rescheduled",
          "replacement_activity_id" => "dl_2",
          "source_timeline_id" => "timeline:dl_1",
          "replacement_timeline_id" => "timeline:dl_2",
          "timeline_link" => %{
            "source_activity_id" => "dl_1",
            "replacement_activity_id" => "dl_2",
            "source_timeline_id" => "timeline:dl_1",
            "replacement_timeline_id" => "timeline:dl_2"
          },
          "source_activity_context" => %{
            "cadence_import" => %{
              "activity_type" => "contact",
              "external_id" => "dl_1",
              "schema_contract" => "proposed_contact.v1"
            },
            "timeline_identity" => %{
              "timeline_id" => "timeline:dl_1",
              "activity_id" => "dl_1",
              "activity_type" => "downlink"
            }
          },
          "replacement_activity_context" => %{
            "cadence_import" => %{
              "activity_type" => "contact",
              "external_id" => "dl_2",
              "schema_contract" => "proposed_contact.v1"
            },
            "timeline_identity" => %{
              "timeline_id" => "timeline:dl_2",
              "activity_id" => "dl_2",
              "activity_type" => "downlink"
            }
          },
          "requires_approval" => true
        }
      ],
      "operational_timeline_report" => %{
        "schema_contract" => "operational_timeline_report.v1",
        "rows" => [
          %{
            "id" => "timeline_row:1:cmd_repair",
            "activity_id" => "cmd_repair",
            "timeline_id" => "timeline:cmd_repair",
            "scenario_id" => "leo_1",
            "activity_type" => "command",
            "operational_kind" => "command",
            "direction" => "command",
            "ground_station_id" => "equator_prime",
            "starts_at_s" => 410.0,
            "ends_at_s" => 430.0,
            "status" => "planned",
            "approval_status" => "pending",
            "locked" => false,
            "required_operator_action" => "review_command_contact",
            "operator_action_reason" => "command_boundary_requires_review",
            "execution_boundary" => "planned_not_commanded",
            "cadence_import_status" => "present",
            "has_cadence_import" => true,
            "has_source_window" => false,
            "timeline_identity" => %{
              "timeline_id" => "timeline:cmd_repair",
              "activity_id" => "cmd_repair",
              "activity_type" => "command",
              "scenario_id" => "leo_1"
            }
          }
        ]
      },
      "source_resource_filter_report" => %{
        "schema_contract" => "resource_filter_report.v1",
        "model" => "resource_summary_availability_and_margin_filter",
        "input_candidate_count" => 2,
        "kept_candidate_count" => 1,
        "suppressed_candidate_count" => 1,
        "suppressed_candidates" => [
          %{
            "id" => "obs_resource_blocked",
            "type" => "observe",
            "scenario_id" => "leo_1",
            "starts_at_s" => 320.0,
            "ends_at_s" => 420.0,
            "suppressed_reason" => "storage_margin_below_observe_policy",
            "source_window_id" => "window:leo_1:target_visibility:target_b:1"
          }
        ]
      },
      "source_contact_filter_report" => %{
        "schema_contract" => "contact_filter_report.v1",
        "model" => "ground_station_availability_filter",
        "input_contact_count" => 2,
        "kept_candidate_count" => 1,
        "suppressed_candidate_count" => 1,
        "suppressed_candidates" => [
          %{
            "id" => "dl_contact_reserved",
            "type" => "downlink",
            "scenario_id" => "leo_1",
            "starts_at_s" => 220.0,
            "ends_at_s" => 280.0,
            "ground_station_id" => "equator_prime",
            "station_availability" => "reserved",
            "station_contention_status" => "reserved_overlap",
            "station_reservation_id" => "reservation_equator_prime_1",
            "station_reserved_by" => "mission_partner",
            "station_reservation_status" => "confirmed",
            "suppressed_reason" => "ground_station_reserved",
            "source_window_id" => "window:leo_1:ground_station_access:equator_prime:2"
          }
        ]
      },
      "warnings" => ["missed downlink repaired"],
      "provenance" => %{"source_plan_id" => "campaign_plan:test"}
    }

    package = OperatorReview.from_repair_artifact(artifact)

    assert OrbitalDynamics.operator_review_package(artifact) == package

    assert %{
             "schema_contract" => "operator_review_package.v1",
             "source_artifact_type" => "campaign_repair.v2",
             "source_artifact_id" => "repair:1",
             "review_count" => 8,
             "approval_requirement_count" => 1,
             "policy_escalation_count" => 1,
             "operational_timeline_count" => 1,
             "contact_suppression_count" => 1,
             "resource_suppression_count" => 1,
             "contention_recommendation_count" => 0,
             "realized_feedback_count" => 0,
             "plan_delta_count" => 1,
             "timeline_protection_count" => 1,
             "warning_count" => 1,
             "risk_count" => 0,
             "recommendation_count" => 0
           } = package

    assert %{
             "review_type" => "approval_requirement",
             "subject_id" => "dl_2",
             "required_operator_action" => "approve_moved_contact",
             "source_requirement" => %{"schema_contract" => "approval_requirement.v1"}
           } = Enum.find(package["rows"], &(&1["review_type"] == "approval_requirement"))

    assert %{
             "review_type" => "policy_escalation",
             "subject_id" => "contact_execution_coordination",
             "required_operator_action" => "review_policy_escalation",
             "approval_status" => "operator_review_required",
             "policy_bundle_id" => "mission_ops_escalation_v1",
             "required_authority" => "contact_schedule_authority",
             "sla_s" => 1800,
             "source_policy_decision" => %{"schema_contract" => "policy_decision.v1"},
             "source_policy_escalation" => %{"rule_id" => "contact_execution_coordination"}
           } = Enum.find(package["rows"], &(&1["review_type"] == "policy_escalation"))

    assert %{
             "review_type" => "operational_timeline_review",
             "activity_id" => "cmd_repair",
             "timeline_id" => "timeline:cmd_repair",
             "required_operator_action" => "review_command_contact",
             "approval_status" => "operator_review_required",
             "source_approval_status" => "pending",
             "source_operational_timeline" => %{"activity_id" => "cmd_repair"}
           } = Enum.find(package["rows"], &(&1["review_type"] == "operational_timeline_review"))

    assert %{
             "review_type" => "plan_delta_review",
             "activity_id" => "dl_1",
             "replacement_activity_id" => "dl_2",
             "required_operator_action" => "review_moved_timeline_item",
             "approval_status" => "operator_review_required",
             "repair_action" => "moved",
             "timeline_link" => %{
               "source_activity_id" => "dl_1",
               "replacement_activity_id" => "dl_2"
             },
             "source_timeline_identity" => %{"timeline_id" => "timeline:dl_1"},
             "replacement_timeline_identity" => %{"timeline_id" => "timeline:dl_2"},
             "source_cadence_import_status" => "present",
             "source_cadence_import_type" => "contact",
             "source_cadence_import_id" => "dl_1",
             "source_cadence_import_contract" => "proposed_contact.v1",
             "source_has_cadence_import" => true,
             "replacement_cadence_import_status" => "present",
             "replacement_cadence_import_type" => "contact",
             "replacement_cadence_import_id" => "dl_2",
             "replacement_cadence_import_contract" => "proposed_contact.v1",
             "replacement_has_cadence_import" => true,
             "source_delta" => %{"schema_contract" => "plan_delta.v1"}
           } = Enum.find(package["rows"], &(&1["review_type"] == "plan_delta_review"))

    assert %{
             "review_type" => "timeline_protection",
             "activity_id" => "locked_dl",
             "required_operator_action" => "record_protected_timeline_preservation",
             "approval_status" => "not_required",
             "protection_category" => "preserved_locked_or_approved",
             "protection_decision" => "preserved",
             "source_timeline_protection" => %{
               "preserved_locked_or_approved_activity_ids" => ["locked_dl"]
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "timeline_protection"))

    assert %{
             "review_type" => "contact_suppression",
             "source" => "campaign_repair.source_contact_filter_report.suppressed_candidates",
             "activity_id" => "dl_contact_reserved",
             "activity_type" => "downlink",
             "required_operator_action" => "review_suppressed_contact",
             "ground_station_id" => "equator_prime",
             "station_contention_status" => "reserved_overlap",
             "station_reservation_id" => "reservation_equator_prime_1",
             "station_reserved_by" => "mission_partner",
             "station_reservation_status" => "confirmed",
             "source_contact_suppression" => %{
               "suppressed_reason" => "ground_station_reserved"
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "contact_suppression"))

    assert %{
             "review_type" => "resource_suppression",
             "source" => "campaign_repair.source_resource_filter_report.suppressed_candidates",
             "activity_id" => "obs_resource_blocked",
             "activity_type" => "observe",
             "required_operator_action" => "review_suppressed_observation",
             "source_window_id" => "window:leo_1:target_visibility:target_b:1",
             "source_resource_suppression" => %{
               "suppressed_reason" => "storage_margin_below_observe_policy"
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "resource_suppression"))

    assert %{
             "review_type" => "warning",
             "required_operator_action" => "review_warning",
             "reason" => "missed downlink repaired"
           } = Enum.find(package["rows"], &(&1["review_type"] == "warning"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    stale_source_delta =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"review_type" => "plan_delta_review", "source_delta" => %{}} = row ->
            row
            |> put_in(["source_delta", "activity_id"], "stale_dl")
            |> put_in(["source_delta", "repair_action"], "suppressed")

          row ->
            row
        end)
      end)

    assert {:error, stale_source_delta_report} = Schema.validate_artifact(stale_source_delta)

    assert Enum.any?(
             stale_source_delta_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.activity_id$/ and
                 &1["message"] == "must match source_delta.activity_id")
           )

    assert Enum.any?(
             stale_source_delta_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.repair_action$/ and
                 &1["message"] == "must match source_delta.repair_action")
           )
  end

  test "preserves malformed plan-delta cadence import contexts for review" do
    artifact = %{
      "schema_contract" => "campaign_repair.v2",
      "repair_metadata" => %{"repair_id" => "repair_bad_delta_import"},
      "deltas" => [
        %{
          "schema_contract" => "plan_delta.v1",
          "activity_id" => "dl_1",
          "activity_type" => "downlink",
          "repair_action" => "moved",
          "replacement_activity_id" => "dl_2",
          "source_activity_context" => %{
            "cadence_import" => :bad_source_import,
            "timeline_identity" => %{
              "timeline_id" => "timeline:dl_1",
              "activity_type" => "downlink"
            }
          },
          "replacement_activity_context" => %{
            "cadence_import" => :bad_replacement_import,
            "timeline_identity" => %{
              "timeline_id" => "timeline:dl_2",
              "activity_type" => "downlink"
            }
          }
        }
      ]
    }

    package = OperatorReview.from_repair_artifact(artifact)
    row = List.first(package["rows"])

    assert %{
             "review_type" => "plan_delta_review",
             "activity_id" => "dl_1",
             "source_cadence_import_status" => "invalid",
             "replacement_cadence_import_status" => "invalid",
             "invalid_cadence_import" => true,
             "invalid_cadence_import_reason" => "cadence_import_must_be_object",
             "source_cadence_import" => %{
               "source" => %{"invalid_import_shape" => "bad_source_import"},
               "replacement" => %{"invalid_import_shape" => "bad_replacement_import"}
             },
             "source_activity_context" => %{
               "invalid_cadence_import" => true,
               "source_cadence_import" => %{"invalid_import_shape" => "bad_source_import"}
             },
             "replacement_activity_context" => %{
               "invalid_cadence_import" => true,
               "source_cadence_import" => %{
                 "invalid_import_shape" => "bad_replacement_import"
               }
             }
           } = row

    refute Map.has_key?(row["source_activity_context"], "cadence_import")
    refute Map.has_key?(row["replacement_activity_context"], "cadence_import")

    manifest = CadenceImport.from_operator_review_package(package)
    import_row = List.first(manifest["rows"])

    assert %{
             "import_status" => "review_required_before_import",
             "cadence_import_status" => "invalid",
             "invalid_cadence_import" => true,
             "invalid_cadence_import_reason" => "cadence_import_must_be_object",
             "source_cadence_import" => %{
               "source" => %{"invalid_import_shape" => "bad_source_import"},
               "replacement" => %{"invalid_import_shape" => "bad_replacement_import"}
             },
             "import_activity_context" => %{
               "invalid_cadence_import" => true,
               "source_cadence_import" => %{
                 "invalid_import_shape" => "bad_replacement_import"
               }
             }
           } = import_row

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end
end
