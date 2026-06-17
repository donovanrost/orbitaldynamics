Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.RepairMissedDownlinkReplacementTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema
  alias OrbitalDynamics.CampaignPlanner.RealizedActivity

  test "repair moves a missed downlink to the next viable access window" do
    missed_downlink =
      "dl_1"
      |> downlink(100.0, 160.0)
      |> Map.merge(%{
        "approval_status" => "approved",
        "dependencies" => ["obs_1"],
        "exclusivity_group" => "ground_station",
        "timeline_id" => "timeline:contact:leo_1:equator_prime:daily-pass",
        "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
        "provenance" => %{"source" => "mission_plan"}
      })

    artifact =
      repair(
        %{
          "activities" => [missed_downlink],
          "candidate_activities" => [
            missed_downlink,
            refreshed_downlink("dl_2", 700.0, 760.0)
          ]
        },
        realized_state: %{
          activities: [
            %RealizedActivity{
              id: "dl_1",
              status: "missed",
              reason: "station outage"
            }
          ]
        },
        current_epoch_s: 165.0,
        approval_policy: %{
          action_rules: [
            %{
              id: "contact_move_auto",
              action: "approve_moved_contact",
              classification: "auto_approvable",
              reason: "low risk contact move"
            },
            %{
              id: "transition_preserve_review",
              application_status: "source_preserved_pending_review",
              classification: "operator_review_required",
              reason: "preserved source transition application requires mission-planning review",
              escalation_queue: "mission_planning",
              required_authority: "mission_planning_authority",
              sla_s: 900
            }
          ]
        }
      )

    assert [%{"id" => "dl_2", "repair" => repair}] = artifact["activities"]
    assert repair["action"] == "moved"
    assert repair["source_activity_id"] == "dl_1"
    assert repair["source_activity_context"]["approval_status"] == "approved"
    assert repair["source_activity_context"]["dependencies"] == ["obs_1"]
    assert repair["source_timeline_id"] == "timeline:contact:leo_1:equator_prime:daily-pass"

    assert repair["replacement_timeline_id"] ==
             "timeline:leo_1:downlink:equator_prime:window:leo_1:ground_station_access:equator_prime:1"

    assert repair["timeline_link"]["source_activity_id"] == "dl_1"
    assert repair["timeline_link"]["replacement_activity_id"] == "dl_2"

    assert repair["source_activity_context"]["source_window_id"] ==
             "window:leo_1:ground_station_access:equator_prime:1"

    assert repair["source_activity_context"]["timeline_identity"] == %{
             "timeline_id" => "timeline:contact:leo_1:equator_prime:daily-pass",
             "activity_id" => "dl_1",
             "activity_type" => "downlink",
             "scenario_id" => "leo_1",
             "subject_id" => "equator_prime",
             "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1"
           }

    assert [
             %{
               "activity_id" => "dl_1",
               "repair_action" => "moved",
               "replacement_activity_id" => "dl_2",
               "source_timeline_id" => "timeline:contact:leo_1:equator_prime:daily-pass",
               "replacement_timeline_id" =>
                 "timeline:leo_1:downlink:equator_prime:window:leo_1:ground_station_access:equator_prime:1",
               "timeline_link" => %{
                 "source_activity_id" => "dl_1",
                 "replacement_activity_id" => "dl_2"
               },
               "source_activity_context" => %{
                 "timeline_identity" => %{
                   "timeline_id" => "timeline:contact:leo_1:equator_prime:daily-pass",
                   "activity_id" => "dl_1"
                 }
               },
               "replacement_activity_context" => %{
                 "cadence_import" => %{
                   "activity_type" => "contact",
                   "external_id" => "dl_2",
                   "schema_contract" => "proposed_contact.v1"
                 },
                 "timeline_identity" => %{
                   "timeline_id" =>
                     "timeline:leo_1:downlink:equator_prime:window:leo_1:ground_station_access:equator_prime:1",
                   "activity_id" => "dl_2"
                 }
               },
               "planned" => %{
                 "approval_status" => "approved",
                 "dependencies" => ["obs_1"],
                 "exclusivity_group" => "ground_station",
                 "timeline_identity" => %{
                   "timeline_id" => "timeline:contact:leo_1:equator_prime:daily-pass",
                   "activity_id" => "dl_1"
                 },
                 "provenance" => %{"source" => "mission_plan"}
               }
             }
           ] = artifact["deltas"]

    assert [
             %{
               "action" => "approve_moved_contact",
               "requirement_type" => "contact_schedule_change",
               "policy_classification" => "auto_approvable",
               "activity_context" => %{"source_window_id" => _replacement_source_window_id}
             }
           ] = artifact["approval_requirements"]

    assert artifact["approval_status"] == "auto_approvable"
    assert artifact["approval_policy"]["action_rules"] != []

    assert %{
             "schema_contract" => "policy_decision.v1",
             "classification" => "auto_approvable",
             "approval_requirement_count" => 0,
             "risk_count" => 0
           } = artifact["policy_decision"]

    assert [%{"rule_id" => "contact_move_auto"}] = artifact["approval_rule_matches"]

    assert %{
             "schema_contract" => "score_term_report.v1",
             "model" => "repair_score_terms",
             "source" => "campaign_repair.score_terms",
             "row_count" => 3,
             "score_term_keys" => [
               "activity_score",
               "schedule_churn_penalty",
               "schedule_move_penalty"
             ],
             "rows" => score_rows
           } = artifact["score_term_report"]

    assert Enum.map(score_rows, & &1["term_key"]) == [
             "activity_score",
             "schedule_churn_penalty",
             "schedule_move_penalty"
           ]

    assert Enum.all?(
             score_rows,
             &(&1["scenario_id"] == "campaign_plan:test:2026-05-13T00:00:00Z" and
                 &1["selected"])
           )

    assert %{
             "schema_contract" => "objective_tradeoff_report.v1",
             "model" => "repair_score_term_tradeoffs",
             "ranking_count" => 1,
             "tradeoffs" => [
               %{
                 "scenario_id" => "campaign_plan:test:2026-05-13T00:00:00Z",
                 "score" => objective_score,
                 "score_delta_from_selected" => objective_delta,
                 "activity_ids" => ["dl_2"]
               }
             ]
           } = artifact["objective_tradeoff_report"]

    assert objective_score == artifact["score"]
    assert objective_delta == 0.0

    assert {:ok, %{"schema_contract" => "score_term_report.v1"}} =
             Schema.validate_artifact(artifact["score_term_report"])

    assert {:ok, %{"schema_contract" => "objective_tradeoff_report.v1"}} =
             Schema.validate_artifact(artifact["objective_tradeoff_report"])

    assert %{
             "score_term_review_count" => 3,
             "objective_tradeoff_review_count" => 1
           } = artifact["operator_review_package"]

    assert %{
             "review_type" => "score_term_review",
             "source" => "campaign_repair.score_term_report.rows",
             "term_key" => "activity_score",
             "selected" => true,
             "source_score_term" => %{"term_key" => "activity_score"}
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "score_term_review" and
                   &1["term_key"] == "activity_score")
             )

    assert %{
             "review_type" => "objective_tradeoff_review",
             "source" => "campaign_repair.objective_tradeoff_report.tradeoffs",
             "score_delta_from_selected" => score_delta,
             "activity_ids" => ["dl_2"],
             "source_objective_tradeoff" => %{"activity_ids" => ["dl_2"]}
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "objective_tradeoff_review")
             )

    assert score_delta == 0.0

    assert %{
             "import_action" => "review_score_term",
             "source_review_type" => "score_term_review",
             "term_key" => "activity_score",
             "import_status" => "review_required_before_import",
             "source_score_term" => %{"term_key" => "activity_score"}
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["import_action"] == "review_score_term" and
                   &1["term_key"] == "activity_score")
             )

    assert %{
             "import_action" => "review_objective_tradeoff",
             "source_review_type" => "objective_tradeoff_review",
             "score_delta_from_selected" => import_score_delta,
             "activity_ids" => ["dl_2"],
             "import_status" => "review_required_before_import",
             "source_objective_tradeoff" => %{"activity_ids" => ["dl_2"]}
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["import_action"] == "review_objective_tradeoff")
             )

    assert import_score_delta == 0.0

    assert %{
             "schema_contract" => "link_capacity_report.v1",
             "source" => "campaign_repair.activities",
             "contact_count" => 1,
             "selected_contact_count" => 1,
             "estimated_throughput_mb" => 60.0,
             "selected_estimated_throughput_mb" => 60.0,
             "rows" => [
               %{
                 "ground_station_id" => "equator_prime",
                 "contact_ids" => ["dl_2"],
                 "selected_contact_ids" => ["dl_2"]
               }
             ]
           } = artifact["link_capacity_report"]

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(artifact["link_capacity_report"])

    assert %{
             "schema_contract" => "contact_allocation_report.v1",
             "source" => "campaign_repair.activities",
             "input_contact_count" => 1,
             "allocated_contact_count" => 1,
             "deferred_contact_count" => 0,
             "blocked_contact_count" => 0,
             "rows" => [
               %{
                 "contact_id" => "dl_2",
                 "allocation_status" => "allocated",
                 "allocation_reason" => "available",
                 "review_status" => "accepted_for_planning"
               }
             ]
           } = artifact["contact_allocation_report"]

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(artifact["contact_allocation_report"])

    assert %{
             "schema_contract" => "timeline_feedback_report.v1",
             "source" => "campaign_repair.realized_state_snapshot.activities",
             "status_counts" => %{"matched" => 1},
             "rows" => [
               %{
                 "activity_id" => "dl_1",
                 "status" => "matched",
                 "feedback_kind" => "contact",
                 "realized_status" => "missed",
                 "reason" => "station outage"
               }
             ]
           } = artifact["source_timeline_feedback_report"]

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(artifact["source_timeline_feedback_report"])

    assert %{
             "schema_contract" => "timeline_transition_application_report.v1",
             "source" => "campaign_repair.timeline_transition_application",
             "source_activity_count" => 1,
             "replacement_activity_count" => 1,
             "application_count" => 2,
             "selected_activity_count" => 1,
             "review_required_count" => 2,
             "preserved_source_count" => 1,
             "withheld_review_count" => 1,
             "selected_activities" => [
               %{
                 "activity_id" => "dl_1",
                 "timeline_id" => "timeline:contact:leo_1:equator_prime:daily-pass",
                 "protection_decision" => "preserve"
               }
             ],
             "applications" => transition_applications
           } = artifact["timeline_transition_application_report"]

    assert %{
             "timeline_id" => "timeline:contact:leo_1:equator_prime:daily-pass",
             "transition_decision" => "preserve_source",
             "application_status" => "source_preserved_pending_review",
             "selected_activity_source" => "source",
             "selected_activity" => %{"activity_id" => "dl_1"}
           } =
             Enum.find(
               transition_applications,
               &(&1["timeline_id"] == "timeline:contact:leo_1:equator_prime:daily-pass")
             )

    assert %{
             "activity_id" => "dl_1",
             "timeline_id" => "timeline:contact:leo_1:equator_prime:daily-pass"
           } =
             List.first(
               OrbitalDynamics.timeline_transition_selected_activities(
                 artifact["timeline_transition_application_report"]
               )
             )

    assert artifact["repair_metadata"]["transition_selected_activity_count"] == 1
    assert artifact["repair_metadata"]["transition_application_review_required_count"] == 2

    assert {:ok, %{"schema_contract" => "timeline_transition_application_report.v1"}} =
             Schema.validate_artifact(artifact["timeline_transition_application_report"])

    assert %{
             "schema_contract" => "operator_review_package.v1",
             "source_artifact_type" => "campaign_repair.v2",
             "review_count" => 13,
             "approval_requirement_count" => 1,
             "contact_allocation_review_count" => 1,
             "realized_feedback_count" => 1,
             "timeline_diff_count" => 2,
             "plan_delta_count" => 1,
             "timeline_protection_count" => 1,
             "warning_count" => 0,
             "risk_count" => 0,
             "recommendation_count" => 0,
             "rows" => review_rows
           } = artifact["operator_review_package"]

    assert %{
             "review_type" => "approval_requirement",
             "required_operator_action" => "approve_moved_contact",
             "approval_status" => "auto_approvable"
           } = Enum.find(review_rows, &(&1["review_type"] == "approval_requirement"))

    assert %{
             "review_type" => "realized_feedback",
             "source" => "campaign_repair.source_timeline_feedback_report.rows",
             "activity_id" => "dl_1",
             "feedback_kind" => "contact",
             "realized_status" => "missed",
             "required_operator_action" => "review_contact_exception",
             "approval_status" => "operator_review_required",
             "reason" => "station outage"
           } = Enum.find(review_rows, &(&1["review_type"] == "realized_feedback"))

    assert %{
             "review_type" => "plan_delta_review",
             "activity_id" => "dl_1",
             "replacement_activity_id" => "dl_2",
             "repair_action" => "moved",
             "required_operator_action" => "review_moved_timeline_item",
             "timeline_link" => %{
               "source_activity_id" => "dl_1",
               "replacement_activity_id" => "dl_2"
             },
             "source_timeline_identity" => %{
               "timeline_id" => "timeline:contact:leo_1:equator_prime:daily-pass"
             },
             "replacement_timeline_identity" => %{
               "timeline_id" =>
                 "timeline:leo_1:downlink:equator_prime:window:leo_1:ground_station_access:equator_prime:1"
             },
             "source_cadence_import_status" => "missing",
             "source_has_cadence_import" => false,
             "replacement_cadence_import_status" => "present",
             "replacement_cadence_import_type" => "contact",
             "replacement_cadence_import_id" => "dl_2",
             "replacement_cadence_import_contract" => "proposed_contact.v1",
             "replacement_has_cadence_import" => true
           } = Enum.find(review_rows, &(&1["review_type"] == "plan_delta_review"))

    assert %{
             "review_type" => "timeline_protection",
             "activity_id" => "dl_1",
             "protection_category" => "changed_locked_or_approved",
             "protection_decision" => "changed",
             "required_operator_action" => "review_changed_protected_timeline_item"
           } = Enum.find(review_rows, &(&1["review_type"] == "timeline_protection"))

    assert %{
             "review_type" => "contact_allocation_review",
             "source" => "campaign_repair.contact_allocation_report.rows",
             "contact_id" => "dl_2",
             "allocation_status" => "allocated",
             "allocation_reason" => "available",
             "required_operator_action" => "review_contact_allocation"
           } = Enum.find(review_rows, &(&1["review_type"] == "contact_allocation_review"))

    assert %{
             "review_type" => "link_capacity_review",
             "source" => "campaign_repair.link_capacity_report.rows",
             "ground_station_id" => "equator_prime",
             "selected_contact_ids" => ["dl_2"],
             "selected_estimated_throughput_mb" => 60.0,
             "required_operator_action" => "review_link_capacity_summary"
           } = Enum.find(review_rows, &(&1["review_type"] == "link_capacity_review"))

    transition_review_rows =
      Enum.filter(
        review_rows,
        &(&1["review_type"] == "timeline_diff_review" and
            &1["source"] == "campaign_repair.timeline_transition_application_report.applications")
      )

    assert length(transition_review_rows) == 2

    assert %{
             "review_type" => "timeline_diff_review",
             "source" => "campaign_repair.timeline_transition_application_report.applications",
             "timeline_id" => "timeline:contact:leo_1:equator_prime:daily-pass",
             "application_status" => "source_preserved_pending_review",
             "selected_activity_source" => "source",
             "selected_activity" => %{"activity_id" => "dl_1"},
             "policy_classification" => "operator_review_required",
             "approval_rule_matches" => [
               %{
                 "rule_id" => "transition_preserve_review",
                 "classification" => "operator_review_required",
                 "application_status" => "source_preserved_pending_review",
                 "escalation_queue" => "mission_planning",
                 "required_authority" => "mission_planning_authority"
               }
             ],
             "source_policy_decision" => %{
               "schema_contract" => "policy_decision.v1",
               "classification" => "operator_review_required"
             },
             "source_timeline_application" => %{
               "application_status" => "source_preserved_pending_review"
             }
           } =
             Enum.find(
               transition_review_rows,
               &(&1["application_status"] == "source_preserved_pending_review")
             )

    assert %{
             "review_type" => "timeline_diff_review",
             "source" => "campaign_repair.timeline_transition_application_report.applications",
             "application_status" => "operator_review_required",
             "required_operator_action" => "review_added_activity",
             "source_timeline_application" => %{
               "application_status" => "operator_review_required"
             }
           } =
             Enum.find(
               transition_review_rows,
               &(&1["application_status"] == "operator_review_required")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(artifact["operator_review_package"])

    assert %{
             "schema_contract" => "cadence_import_manifest.v1",
             "source_artifact_type" => "campaign_repair.v2",
             "source_artifact_id" => repair_id,
             "row_count" => 13,
             "ready_count" => 1,
             "review_required_count" => 11,
             "blocked_count" => 1,
             "missing_import_count" => 1,
             "rows" => import_rows
           } = artifact["cadence_import_manifest"]

    assert %{
             "import_action" => "review_approval_requirement",
             "import_status" => "ready_for_import",
             "activity_id" => "dl_2",
             "requirement_type" => "contact_schedule_change",
             "source_review_row" => %{"review_type" => "approval_requirement"}
           } = Enum.find(import_rows, &(&1["source_review_type"] == "approval_requirement"))

    assert %{
             "import_action" => "review_operational_timeline",
             "import_status" => "review_required_before_import",
             "activity_id" => "dl_2",
             "source_review_row" => %{"review_type" => "operational_timeline_review"}
           } =
             Enum.find(import_rows, &(&1["source_review_type"] == "operational_timeline_review"))

    assert %{
             "import_action" => "import_replacement_activity",
             "import_status" => "review_required_before_import",
             "import_side" => "replacement",
             "activity_id" => "dl_1",
             "replacement_activity_id" => "dl_2",
             "cadence_import_status" => "present",
             "cadence_import_type" => "contact",
             "cadence_import_id" => "dl_2",
             "cadence_import_contract" => "proposed_contact.v1"
           } = Enum.find(import_rows, &(&1["source_review_type"] == "plan_delta_review"))

    assert %{
             "import_action" => "review_timeline_protection",
             "import_status" => "review_required_before_import",
             "activity_id" => "dl_1",
             "source_review_row" => %{"review_type" => "timeline_protection"}
           } = Enum.find(import_rows, &(&1["source_review_type"] == "timeline_protection"))

    assert %{
             "import_action" => "review_realized_feedback",
             "import_status" => "blocked_missing_cadence_import",
             "activity_id" => "dl_1",
             "feedback_status" => "matched",
             "feedback_kind" => "contact",
             "realized_status" => "missed",
             "cadence_import_status" => "missing",
             "has_cadence_import" => false,
             "source_feedback" => %{"reason" => "station outage"}
           } = Enum.find(import_rows, &(&1["source_review_type"] == "realized_feedback"))

    assert %{
             "import_action" => "review_contact_allocation",
             "import_status" => "review_required_before_import",
             "contact_id" => "dl_2",
             "allocation_status" => "allocated",
             "source_review_type" => "contact_allocation_review"
           } = Enum.find(import_rows, &(&1["source_review_type"] == "contact_allocation_review"))

    assert %{
             "import_action" => "review_link_capacity",
             "import_status" => "review_required_before_import",
             "ground_station_id" => "equator_prime",
             "selected_contact_ids" => ["dl_2"],
             "selected_estimated_throughput_mb" => 60.0,
             "source_review_type" => "link_capacity_review"
           } = Enum.find(import_rows, &(&1["source_review_type"] == "link_capacity_review"))

    assert %{
             "import_action" => "review_score_term",
             "import_status" => "review_required_before_import",
             "term_key" => "activity_score",
             "source_review_type" => "score_term_review"
           } =
             Enum.find(
               import_rows,
               &(&1["source_review_type"] == "score_term_review" and
                   &1["term_key"] == "activity_score")
             )

    assert %{
             "import_action" => "review_objective_tradeoff",
             "import_status" => "review_required_before_import",
             "activity_ids" => ["dl_2"],
             "source_review_type" => "objective_tradeoff_review"
           } =
             Enum.find(import_rows, &(&1["source_review_type"] == "objective_tradeoff_review"))

    transition_import_rows =
      Enum.filter(
        import_rows,
        &(&1["source_review_type"] == "timeline_diff_review" and
            get_in(&1, ["source_review_row", "source"]) ==
              "campaign_repair.timeline_transition_application_report.applications")
      )

    assert length(transition_import_rows) == 2

    assert %{
             "import_action" => "review_timeline_diff",
             "import_status" => "review_required_before_import",
             "timeline_id" => "timeline:contact:leo_1:equator_prime:daily-pass",
             "application_status" => "source_preserved_pending_review",
             "selected_activity_source" => "source",
             "selected_activity" => %{"activity_id" => "dl_1"},
             "policy_classification" => "operator_review_required",
             "approval_rule_matches" => [
               %{
                 "rule_id" => "transition_preserve_review",
                 "classification" => "operator_review_required"
               }
             ],
             "source_policy_decision" => %{
               "schema_contract" => "policy_decision.v1",
               "classification" => "operator_review_required"
             },
             "source_timeline_application" => %{
               "application_status" => "source_preserved_pending_review"
             }
           } =
             Enum.find(
               transition_import_rows,
               &(&1["application_status"] == "source_preserved_pending_review")
             )

    assert repair_id == artifact["repair_metadata"]["repair_id"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(artifact["cadence_import_manifest"])

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    stale_timeline_protection =
      put_in(
        artifact,
        ["repair_metadata", "timeline_protection", "changed_locked_or_approved_count"],
        0
      )

    assert {:error, stale_timeline_protection_report} =
             Schema.validate_artifact(stale_timeline_protection)

    assert Enum.any?(
             stale_timeline_protection_report["errors"],
             &(&1["path"] ==
                 "$.repair_metadata.timeline_protection.changed_locked_or_approved_count" and
                 &1["message"] ==
                   "must equal row-derived repair timeline protection changed_locked_or_approved_count")
           )
  end
end
