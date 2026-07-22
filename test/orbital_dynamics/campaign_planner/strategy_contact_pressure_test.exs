Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyContactPressureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives branch refresh from blocked contact intent review rows" do
    prior_plan =
      base_plan(%{
        "activities" => [
          downlink("dl_intent_blocked", 700.0, 760.0),
          downlink("dl_intent_missing_import", 800.0, 860.0)
        ],
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "contact_intent.v1",
          "review_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_contact_intent_review"},
          "rows" => [
            %{
              "id" => "operator_review:contact_intent:blocked",
              "review_type" => "contact_intent_review",
              "approval_status" => "blocked_by_policy",
              "required_operator_action" => "review_contact_intent",
              "source_policy_decision" => %{
                "classification" => "blocked_by_policy",
                "policy_bundle_id" => "contact_command_review_v1"
              },
              "source_contact_intent" => %{
                "schema_contract" => "contact_intent.v1",
                "id" => "contact_intent:blocked",
                "activity_id" => "dl_intent_blocked",
                "activity_type" => "downlink",
                "type" => "downlink",
                "scenario_id" => "leo_1",
                "spacecraft_id" => "leo_1",
                "ground_station_id" => "equator_prime",
                "direction" => "downlink",
                "starts_at_s" => 700.0,
                "ends_at_s" => 760.0,
                "estimated_throughput_mb" => 36.0,
                "station_availability" => "reserved",
                "station_calendar_entry_id" => "intent_partner_reservation",
                "station_calendar_provider_id" => "partner_calendar",
                "station_calendar_provider_entry_id" => "partner_entry_42",
                "station_calendar_status" => "reserved",
                "station_calendar_trust_boundary_status" => "declared",
                "station_reservation_id" => "reservation_intent_partner",
                "station_reserved_by" => "partner_team",
                "station_reservation_status" => "confirmed",
                "station_reservation_match_status" => "unmatched_overlap",
                "source_window_id" =>
                  "window:leo_1:ground_station_access:equator_prime:intent_blocked"
              }
            }
          ]
        },
        "cadence_import_manifest" => %{
          "schema_contract" => "cadence_import_manifest.v1",
          "source_artifact_type" => "operator_review_package.v1",
          "row_count" => 1,
          "review_required_count" => 1,
          "provenance" => %{"trust_boundary" => "cadence_contact_intent_review"},
          "rows" => [
            %{
              "id" => "cadence_import:contact_intent:missing",
              "import_action" => "review_contact_intent",
              "source_review_type" => "contact_intent_review",
              "approval_status" => "operator_review_required",
              "cadence_import_status" => "missing",
              "required_operator_action" => "review_contact_intent",
              "source_contact_intent" => %{
                "schema_contract" => "contact_intent.v1",
                "id" => "contact_intent:missing_import",
                "activity_id" => "dl_intent_missing_import",
                "activity_type" => "downlink",
                "type" => "downlink",
                "scenario_id" => "leo_1",
                "spacecraft_id" => "leo_1",
                "ground_station_id" => "deep_space_net",
                "direction" => "downlink",
                "starts_at_s" => 800.0,
                "ends_at_s" => 860.0,
                "estimated_throughput_mb" => 41.0,
                "station_calendar_entry_id" => "intent_missing_calendar_entry",
                "station_calendar_provider_id" => "cadence_partner_calendar",
                "station_calendar_provider_entry_id" => "cadence_partner_entry_7",
                "station_calendar_status" => "maintenance",
                "station_calendar_trust_boundary_status" => "declared",
                "station_reservation_id" => "reservation_missing_import",
                "station_reserved_by" => "maintenance_team",
                "station_reservation_status" => "confirmed",
                "station_reservation_match_status" => "unmatched_overlap",
                "source_window_id" =>
                  "window:leo_1:ground_station_access:deep_space_net:intent_missing"
              }
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    blocked_branch =
      branch(artifact, "derived_contact_intent_pressure_blocked_by_policy_dl_intent_blocked")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "source_activity_id" => "dl_intent_blocked",
             "required_downlink_mb" => 36.0,
             "source_window_id" =>
               "window:leo_1:ground_station_access:equator_prime:intent_blocked",
             "approval_status" => "blocked_by_policy",
             "contact_intent_gate_status" => "blocked_by_policy",
             "policy_classification" => "blocked_by_policy",
             "station_availability" => "reserved",
             "station_calendar_entry_id" => "intent_partner_reservation",
             "station_calendar_provider_id" => "partner_calendar",
             "station_calendar_provider_entry_id" => "partner_entry_42",
             "station_calendar_status" => "reserved",
             "station_calendar_trust_boundary_status" => "declared",
             "station_reservation_id" => "reservation_intent_partner",
             "station_reserved_by" => "partner_team",
             "station_reservation_status" => "confirmed",
             "station_reservation_match_status" => "unmatched_overlap",
             "derivation_reasons" => [
               "contact_intent_blocked_by_policy",
               "review_contact_intent",
               "reserved",
               "unmatched_overlap",
               "blocked_by_policy"
             ],
             "feedback_source" => "prior_plan.operator_review_package.rows.source_contact_intent",
             "feedback_scope" => "contact_intent",
             "trust_boundary" => "ops_contact_intent_review"
           } = List.first(blocked_branch["events"])

    blocked_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] ==
            "derived_contact_intent_pressure_blocked_by_policy_dl_intent_blocked")
      )

    assert blocked_row["branch_station_availabilities"] == ["reserved"]
    assert blocked_row["branch_station_reservation_ids"] == ["reservation_intent_partner"]
    assert blocked_row["branch_station_reserved_by"] == ["partner_team"]
    assert blocked_row["branch_station_reservation_statuses"] == ["confirmed"]
    assert blocked_row["branch_station_reservation_match_statuses"] == ["unmatched_overlap"]

    assert_contact_intent_pressure_score_terms(blocked_branch, artifact)

    missing_branch =
      branch(
        artifact,
        "derived_contact_intent_pressure_cadence_import_missing_dl_intent_missing_import"
      )

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "deep_space_net",
             "source_activity_id" => "dl_intent_missing_import",
             "required_downlink_mb" => 41.0,
             "source_window_id" =>
               "window:leo_1:ground_station_access:deep_space_net:intent_missing",
             "cadence_import_status" => "missing",
             "contact_intent_gate_status" => "cadence_import_missing",
             "station_calendar_entry_id" => "intent_missing_calendar_entry",
             "station_calendar_provider_id" => "cadence_partner_calendar",
             "station_calendar_provider_entry_id" => "cadence_partner_entry_7",
             "station_calendar_status" => "maintenance",
             "station_reservation_id" => "reservation_missing_import",
             "station_reserved_by" => "maintenance_team",
             "station_reservation_status" => "confirmed",
             "station_reservation_match_status" => "unmatched_overlap",
             "feedback_source" => "prior_plan.cadence_import_manifest.rows.source_contact_intent",
             "trust_boundary" => "cadence_contact_intent_review"
           } = List.first(missing_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from direct contact intent rows" do
    prior_plan =
      base_plan(%{
        "activities" => [
          downlink("dl_intent_direct_blocked", 700.0, 760.0),
          downlink("dl_intent_direct_missing", 800.0, 860.0),
          downlink("dl_intent_direct_invalid", 870.0, 890.0),
          downlink("dl_intent_review_only", 900.0, 960.0)
        ],
        "contact_intent" => %{
          "schema_contract" => "contact_intent.v1",
          "id" => "contact_intent:direct_blocked",
          "activity_id" => "dl_intent_direct_blocked",
          "activity_type" => "downlink",
          "scenario_id" => "leo_1",
          "spacecraft_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "starts_at_s" => 700.0,
          "ends_at_s" => 760.0,
          "estimated_throughput_mb" => 37.0,
          "approval_status" => "blocked_by_policy",
          "policy_decision" => %{
            "classification" => "blocked_by_policy",
            "policy_bundle_id" => "contact_command_review_v1"
          },
          "station_availability" => "reserved",
          "station_calendar_entry_id" => "direct_intent_partner_reservation",
          "station_calendar_provider_id" => "partner_calendar",
          "station_calendar_provider_entry_id" => "partner_entry_43",
          "station_calendar_status" => "reserved",
          "station_calendar_trust_boundary_status" => "declared",
          "station_reservation_id" => "reservation_direct_intent_partner",
          "station_reserved_by" => "partner_team",
          "station_reservation_status" => "confirmed",
          "station_reservation_match_status" => "unmatched_overlap",
          "source_window_id" =>
            "window:leo_1:ground_station_access:equator_prime:direct_intent_blocked",
          "trust_boundary" => "direct_contact_intent_export"
        },
        "contact_intents" => [
          %{
            "schema_contract" => "contact_intent.v1",
            "id" => "contact_intent:direct_missing",
            "activity_id" => "dl_intent_direct_missing",
            "activity_type" => "downlink",
            "scenario_id" => "leo_1",
            "spacecraft_id" => "leo_1",
            "ground_station_id" => "deep_space_net",
            "direction" => "downlink",
            "starts_at_s" => 800.0,
            "ends_at_s" => 860.0,
            "estimated_throughput_mb" => 42.0,
            "approval_status" => "operator_review_required",
            "cadence_import" => %{"status" => "missing"},
            "station_calendar_entry_id" => "direct_intent_missing_calendar_entry",
            "station_calendar_provider_id" => "cadence_partner_calendar",
            "station_calendar_provider_entry_id" => "cadence_partner_entry_8",
            "station_calendar_status" => "maintenance",
            "station_reservation_id" => "reservation_direct_missing_import",
            "station_reserved_by" => "maintenance_team",
            "station_reservation_status" => "confirmed",
            "station_reservation_match_status" => "unmatched_overlap",
            "source_window_id" =>
              "window:leo_1:ground_station_access:deep_space_net:direct_intent_missing",
            "trust_boundary" => "direct_contact_intent_export"
          },
          %{
            "schema_contract" => "contact_intent.v1",
            "id" => "contact_intent:review_only",
            "activity_id" => "dl_intent_review_only",
            "activity_type" => "downlink",
            "scenario_id" => "leo_1",
            "spacecraft_id" => "leo_1",
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "starts_at_s" => 900.0,
            "ends_at_s" => 960.0,
            "estimated_throughput_mb" => 12.0,
            "approval_status" => "operator_review_required",
            "cadence_import" => %{"status" => "ready"},
            "source_window_id" => "window:leo_1:ground_station_access:equator_prime:review_only",
            "trust_boundary" => "direct_contact_intent_export"
          },
          %{
            "schema_contract" => "contact_intent.v1",
            "id" => "contact_intent:direct_invalid",
            "activity_id" => "dl_intent_direct_invalid",
            "activity_type" => "downlink",
            "scenario_id" => "leo_1",
            "spacecraft_id" => "leo_1",
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "starts_at_s" => 870.0,
            "ends_at_s" => 890.0,
            "estimated_throughput_mb" => 5.0,
            "approval_status" => "approved",
            "invalid_activity_input" => true,
            "invalid_activity_input_reason" => "missing_external_activity_id",
            "source_window_id" =>
              "window:leo_1:ground_station_access:equator_prime:direct_invalid",
            "trust_boundary" => "direct_contact_intent_export"
          }
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    blocked_branch =
      branch(
        artifact,
        "derived_contact_intent_pressure_blocked_by_policy_dl_intent_direct_blocked"
      )

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "source_activity_id" => "dl_intent_direct_blocked",
             "required_downlink_mb" => 37.0,
             "source_window_id" =>
               "window:leo_1:ground_station_access:equator_prime:direct_intent_blocked",
             "approval_status" => "blocked_by_policy",
             "contact_intent_gate_status" => "blocked_by_policy",
             "policy_classification" => "blocked_by_policy",
             "policy_bundle_id" => "contact_command_review_v1",
             "station_availability" => "reserved",
             "station_calendar_entry_id" => "direct_intent_partner_reservation",
             "station_calendar_provider_id" => "partner_calendar",
             "station_calendar_provider_entry_id" => "partner_entry_43",
             "station_calendar_status" => "reserved",
             "station_calendar_trust_boundary_status" => "declared",
             "station_reservation_id" => "reservation_direct_intent_partner",
             "station_reserved_by" => "partner_team",
             "station_reservation_status" => "confirmed",
             "station_reservation_match_status" => "unmatched_overlap",
             "feedback_source" => "prior_plan.contact_intent",
             "feedback_scope" => "contact_intent",
             "trust_boundary" => "direct_contact_intent_export"
           } = List.first(blocked_branch["events"])

    missing_branch =
      branch(
        artifact,
        "derived_contact_intent_pressure_cadence_import_missing_dl_intent_direct_missing"
      )

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "deep_space_net",
             "source_activity_id" => "dl_intent_direct_missing",
             "required_downlink_mb" => 42.0,
             "source_window_id" =>
               "window:leo_1:ground_station_access:deep_space_net:direct_intent_missing",
             "approval_status" => "operator_review_required",
             "cadence_import_status" => "missing",
             "contact_intent_gate_status" => "cadence_import_missing",
             "station_calendar_entry_id" => "direct_intent_missing_calendar_entry",
             "station_calendar_provider_id" => "cadence_partner_calendar",
             "station_calendar_provider_entry_id" => "cadence_partner_entry_8",
             "station_calendar_status" => "maintenance",
             "station_reservation_id" => "reservation_direct_missing_import",
             "station_reserved_by" => "maintenance_team",
             "station_reservation_status" => "confirmed",
             "station_reservation_match_status" => "unmatched_overlap",
             "feedback_source" => "prior_plan.contact_intents",
             "trust_boundary" => "direct_contact_intent_export"
           } = List.first(missing_branch["events"])

    invalid_branch =
      branch(
        artifact,
        "derived_contact_intent_pressure_invalid_activity_input_dl_intent_direct_invalid"
      )

    assert %{
             "type" => "downlink_completion_gap",
             "source_activity_id" => "dl_intent_direct_invalid",
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "missing_external_activity_id",
             "contact_intent_gate_status" => "invalid_activity_input",
             "derivation_reasons" => [
               "contact_intent_invalid_activity_input",
               "missing_external_activity_id"
             ],
             "feedback_source" => "prior_plan.contact_intents",
             "trust_boundary" => "direct_contact_intent_export"
           } = List.first(invalid_branch["events"])

    refute Enum.any?(artifact["branches"], fn branch ->
             branch["branch_id"] =~ "dl_intent_review_only"
           end)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from mission-state contact intent rows" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:source_contact_intent, %{
        "schema_contract" => "contact_intent.v1",
        "id" => "contact_intent:mission_blocked",
        "activity_id" => "dl_mission_intent_blocked",
        "activity_type" => "downlink",
        "scenario_id" => "leo_1",
        "spacecraft_id" => "leo_1",
        "ground_station_id" => "equator_prime",
        "direction" => "downlink",
        "starts_at_s" => 700.0,
        "ends_at_s" => 760.0,
        "estimated_throughput_mb" => 37.0,
        "approval_status" => "blocked_by_policy",
        "policy_decision" => %{
          "classification" => "blocked_by_policy",
          "policy_bundle_id" => "contact_command_review_v1"
        },
        "station_availability" => "reserved",
        "station_calendar_entry_id" => "mission_intent_partner_reservation",
        "station_calendar_provider_id" => "partner_calendar",
        "station_calendar_provider_entry_id" => "partner_entry_44",
        "station_calendar_status" => "reserved",
        "station_calendar_trust_boundary_status" => "declared",
        "station_reservation_id" => "reservation_mission_intent_partner",
        "station_reserved_by" => "partner_team",
        "station_reservation_status" => "confirmed",
        "station_reservation_match_status" => "unmatched_overlap",
        "source_window_id" =>
          "window:leo_1:ground_station_access:equator_prime:mission_intent_blocked",
        "trust_boundary" => "mission_contact_intent_export"
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    blocked_branch =
      branch(
        artifact,
        "derived_contact_intent_pressure_blocked_by_policy_dl_mission_intent_blocked"
      )

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             blocked_branch["assumptions"]["candidate_source"]

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "source_activity_id" => "dl_mission_intent_blocked",
             "required_downlink_mb" => 37.0,
             "source_window_id" =>
               "window:leo_1:ground_station_access:equator_prime:mission_intent_blocked",
             "approval_status" => "blocked_by_policy",
             "contact_intent_gate_status" => "blocked_by_policy",
             "policy_classification" => "blocked_by_policy",
             "policy_bundle_id" => "contact_command_review_v1",
             "station_availability" => "reserved",
             "station_calendar_entry_id" => "mission_intent_partner_reservation",
             "station_calendar_provider_id" => "partner_calendar",
             "station_calendar_provider_entry_id" => "partner_entry_44",
             "station_calendar_status" => "reserved",
             "station_calendar_trust_boundary_status" => "declared",
             "station_reservation_id" => "reservation_mission_intent_partner",
             "station_reserved_by" => "partner_team",
             "station_reservation_status" => "confirmed",
             "station_reservation_match_status" => "unmatched_overlap",
             "feedback_source" => "mission_state.source_contact_intent",
             "feedback_scope" => "contact_intent",
             "trust_boundary" => "mission_contact_intent_export"
           } = List.first(blocked_branch["events"])

    assert_candidate_source_report_path(blocked_branch, "mission_state.source_contact_intent")

    assert_candidate_refresh_request_report_path(
      blocked_branch,
      "mission_state.source_contact_intent"
    )

    assert %{
             "paths" => ["mission_state.source_contact_intent"],
             "contract" => "contact_intent.v1",
             "count" => 1,
             "row_count" => 1,
             "station_feedback_count" => 1,
             "station_calendar_status_counts" => %{"reserved" => 1},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["mission_contact_intent_export"]
           } =
             get_in(blocked_branch, [
               "assumptions",
               "candidate_source",
               "candidate_refresh_request_source_report_summary",
               "source_reports",
               "contact_intent"
             ])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from removed plan delta review rows" do
    prior_plan =
      base_plan(%{
        "activities" => [
          observe("obs_plan_delta", "leo_1", "target_a", 640.0, 700.0, 8.0),
          downlink("dl_plan_delta_import", 740.0, 800.0)
        ],
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "campaign_repair.v2",
          "review_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_plan_delta_review"},
          "rows" => [
            %{
              "id" => "operator_review:plan_delta:obs_plan_delta",
              "review_type" => "plan_delta_review",
              "activity_id" => "obs_plan_delta",
              "activity_type" => "observe",
              "repair_action" => "canceled",
              "source_timeline_id" => "timeline:obs_plan_delta",
              "required_operator_action" => "review_canceled_timeline_item",
              "source_delta" => %{
                "activity_id" => "obs_plan_delta",
                "activity_type" => "observe",
                "repair_action" => "canceled",
                "source_timeline_id" => "timeline:obs_plan_delta",
                "source_activity_context" => %{
                  "activity_id" => "obs_plan_delta",
                  "activity_type" => "observe",
                  "type" => "observe",
                  "scenario_id" => "leo_1",
                  "target_id" => "target_a",
                  "starts_at_s" => 640.0,
                  "ends_at_s" => 700.0
                }
              }
            }
          ]
        },
        "cadence_import_manifest" => %{
          "schema_contract" => "cadence_import_manifest.v1",
          "source_artifact_type" => "operator_review_package.v1",
          "row_count" => 1,
          "review_required_count" => 1,
          "provenance" => %{"trust_boundary" => "cadence_plan_delta_review"},
          "rows" => [
            %{
              "id" => "cadence_import:plan_delta:dl_plan_delta_import",
              "import_action" => "review_plan_delta",
              "source_review_type" => "plan_delta_review",
              "activity_id" => "dl_plan_delta_import",
              "activity_type" => "downlink",
              "repair_action" => "suppressed",
              "source_timeline_id" => "timeline:dl_plan_delta_import",
              "source_delta" => %{
                "activity_id" => "dl_plan_delta_import",
                "activity_type" => "downlink",
                "repair_action" => "suppressed",
                "source_timeline_id" => "timeline:dl_plan_delta_import",
                "source_activity_context" => %{
                  "activity_id" => "dl_plan_delta_import",
                  "activity_type" => "downlink",
                  "type" => "downlink",
                  "scenario_id" => "leo_1",
                  "ground_station_id" => "deep_space_net",
                  "direction" => "downlink",
                  "starts_at_s" => 740.0,
                  "ends_at_s" => 800.0,
                  "estimated_throughput_mb" => 52.0
                }
              }
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    observation_branch = branch(artifact, "derived_timeline_diff_removed_obs_plan_delta")

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_a",
             "source_activity_id" => "obs_plan_delta",
             "timeline_id" => "timeline:obs_plan_delta",
             "diff_status" => "removed",
             "required_operator_action" => "review_canceled_timeline_item",
             "feedback_source" => "prior_plan.operator_review_package.rows.source_delta",
             "feedback_scope" => "timeline_diff",
             "trust_boundary" => "ops_plan_delta_review"
           } = List.first(observation_branch["events"])

    downlink_branch = branch(artifact, "derived_timeline_diff_removed_dl_plan_delta_import")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "deep_space_net",
             "source_activity_id" => "dl_plan_delta_import",
             "timeline_id" => "timeline:dl_plan_delta_import",
             "required_downlink_mb" => 52.0,
             "feedback_source" => "prior_plan.cadence_import_manifest.rows.source_delta",
             "trust_boundary" => "cadence_plan_delta_review"
           } = List.first(downlink_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from prior contact contention resolution pressure" do
    prior_plan =
      base_plan(%{
        "source_contact_contention_resolution_report" => %{
          "schema_contract" => "contact_contention_resolution_report.v1",
          "model" => "deterministic_contact_contention_recommendation",
          "source" => "campaign_repair.contact_contention_resolution_report",
          "conflict_group_count" => 1,
          "recommendation_count" => 1,
          "trust_boundary" => "ops_contact_contention",
          "policy" => %{
            "selection_rule" => "highest_priority_highest_score",
            "priority_fields" => ["policy_contact_priority"],
            "priority_override_count" => 2,
            "priority_override_contact_ids" => ["dl_selected", "dl_deferred"]
          },
          "recommendations" => [
            %{
              "group_id" => "station:equator_prime:contention:1",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 500.0,
              "ends_at_s" => 580.0,
              "selected_contact_id" => "dl_selected",
              "selected_priority" => 10.0,
              "selected_priority_source" => "policy_contact_priority",
              "deferred_contact_ids" => ["dl_deferred"],
              "candidate_count" => 2,
              "selection_reason" => "highest_priority_highest_score",
              "resolution_selection_rule" => "highest_priority_highest_score",
              "resolution_priority_override_count" => 2,
              "resolution_priority_override_contact_ids" => ["dl_selected", "dl_deferred"],
              "action" => "recommend_preferred_contact_for_operator_review",
              "review_status" => "operator_review_required",
              "direction" => "downlink",
              "directions" => ["downlink"],
              "source_contact_candidates" => [
                downlink("dl_selected", 500.0, 560.0)
                |> Map.put("estimated_throughput_mb", 40.0),
                downlink("dl_deferred", 520.0, 580.0)
                |> Map.put("estimated_throughput_mb", 42.0)
                |> Map.put(
                  "source_window_id",
                  "window:leo_1:ground_station_access:equator_prime:deferred"
                )
                |> Map.put("downlink_demand_sources", [
                  "contention_resolution.required_downlink:dl_deferred"
                ])
              ]
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    pressure_branch = branch(artifact, "derived_contact_contention_pressure_deferred_dl_deferred")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             pressure_branch["assumptions"]["candidate_source"]

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "source_activity_id" => "dl_deferred",
             "source_window_id" => "window:leo_1:ground_station_access:equator_prime:deferred",
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 42.0,
             "selected_contact_id" => "dl_selected",
             "selected_priority_source" => "policy_contact_priority",
             "resolution_priority_override_count" => 2,
             "resolution_priority_override_contact_ids" => ["dl_selected", "dl_deferred"],
             "derivation_reasons" => [
               "contact_contention_deferred",
               "highest_priority_highest_score"
             ],
             "downlink_demand_sources" => [
               "contention_resolution.required_downlink:dl_deferred"
             ],
             "feedback_source" => "prior_plan.source_contact_contention_resolution_report",
             "feedback_scope" => "contact_contention_resolution",
             "trust_boundary" => "ops_contact_contention"
           } = List.first(pressure_branch["events"])

    assert get_in(pressure_branch, ["provenance", "branch_metadata", "selection_reason"]) ==
             "highest_priority_highest_score"

    assert_contact_contention_pressure_score_terms(pressure_branch, artifact)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from mission-state contact contention resolution pressure" do
    contact_contention_resolution_report = %{
      "schema_contract" => "contact_contention_resolution_report.v1",
      "model" => "deterministic_contact_contention_recommendation",
      "source" => "mission_state.contact_contention_resolution_report",
      "conflict_group_count" => 1,
      "recommendation_count" => 1,
      "trust_boundary" => "mission_contact_contention",
      "recommendations" => [
        %{
          "group_id" => "station:equator_prime:contention:live",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 500.0,
          "ends_at_s" => 580.0,
          "selected_contact_id" => "dl_live_selected",
          "selected_priority" => 10.0,
          "selected_priority_source" => "policy_contact_priority",
          "deferred_contact_ids" => ["dl_live_deferred"],
          "candidate_count" => 2,
          "selection_reason" => "highest_priority_highest_score",
          "resolution_selection_rule" => "highest_priority_highest_score",
          "review_status" => "operator_review_required",
          "direction" => "downlink",
          "source_contact_candidates" => [
            downlink("dl_live_selected", 500.0, 560.0)
            |> Map.put("estimated_throughput_mb", 40.0),
            downlink("dl_live_deferred", 520.0, 580.0)
            |> Map.put("estimated_throughput_mb", 42.0)
            |> Map.put(
              "source_window_id",
              "window:leo_1:ground_station_access:equator_prime:contention"
            )
            |> Map.put("downlink_demand_sources", [
              "mission_state.contention.required_downlink:dl_live_deferred"
            ])
          ]
        }
      ]
    }

    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(
            :source_contact_contention_resolution_report,
            contact_contention_resolution_report
          ),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    pressure_branch =
      branch(artifact, "derived_contact_contention_pressure_deferred_dl_live_deferred")

    assert %{
             "type" => "candidate_refresh.v1",
             "scope" => "branch_generated",
             "source_report_input_paths" => [
               "mission_state.source_contact_contention_resolution_report"
             ]
           } = pressure_branch["assumptions"]["candidate_source"]

    assert %{
             "type" => "downlink_completion_gap",
             "scenario_id" => "leo_1",
             "spacecraft_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "contact_id" => "dl_live_deferred",
             "source_activity_id" => "dl_live_deferred",
             "source_activity_ids" => ["dl_live_deferred"],
             "source_window_id" => "window:leo_1:ground_station_access:equator_prime:contention",
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 42.0,
             "planned_downlink_mb" => planned_downlink_mb,
             "selected_contact_id" => "dl_live_selected",
             "selected_priority_source" => "policy_contact_priority",
             "selection_reason" => "highest_priority_highest_score",
             "resolution_selection_rule" => "highest_priority_highest_score",
             "review_status" => "operator_review_required",
             "derivation_reasons" => [
               "contact_contention_deferred",
               "highest_priority_highest_score"
             ],
             "downlink_demand_sources" => [
               "mission_state.contention.required_downlink:dl_live_deferred"
             ],
             "feedback_source" => "mission_state.source_contact_contention_resolution_report",
             "feedback_scope" => "contact_contention_resolution",
             "trust_boundary" => "mission_contact_contention"
           } = List.first(pressure_branch["events"])

    assert planned_downlink_mb == 0.0

    assert_contact_contention_pressure_score_terms(pressure_branch, artifact)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from mission-state contact contention conflicts" do
    contact_contention_report = %{
      "schema_contract" => "contact_contention_report.v1",
      "model" => "single_station_interval_overlap",
      "input_contact_count" => 2,
      "conflicted_contact_count" => 2,
      "conflict_group_count" => 1,
      "provenance" => %{"trust_boundary" => "mission_contact_contention"},
      "conflict_groups" => [
        %{
          "id" => "station:equator_prime:contention:live",
          "resource_scope" => "ground_station",
          "ground_station_id" => "equator_prime",
          "ground_station_ids" => ["equator_prime"],
          "contact_count" => 2,
          "starts_at_s" => 500.0,
          "ends_at_s" => 580.0,
          "direction" => "downlink",
          "directions" => ["downlink"],
          "required_operator_action" => "review_contact_contention",
          "approval_status" => "operator_review_required",
          "operator_action_reason" => "same_station_overlapping_contact_windows",
          "contact_ids" => ["dl_live_a", "dl_live_b"],
          "source_window_ids" => [
            "window:leo_1:ground_station_access:equator_prime:contention_a",
            "window:leo_1:ground_station_access:equator_prime:contention_b"
          ],
          "scenario_ids" => ["leo_1"],
          "source_contact_candidates" => [
            downlink("dl_live_a", 500.0, 560.0)
            |> Map.put("estimated_throughput_mb", 40.0)
            |> Map.put(
              "source_window_id",
              "window:leo_1:ground_station_access:equator_prime:contention_a"
            ),
            downlink("dl_live_b", 520.0, 580.0)
            |> Map.put("estimated_throughput_mb", 42.0)
            |> Map.put(
              "source_window_id",
              "window:leo_1:ground_station_access:equator_prime:contention_b"
            )
            |> Map.put("downlink_demand_sources", [
              "mission_state.contention.required_downlink:dl_live_b"
            ])
          ]
        }
      ],
      "invalid_contact_inputs" => []
    }

    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_contact_contention_report, contact_contention_report),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    pressure_branch =
      branch(
        artifact,
        "derived_contact_contention_pressure_conflict_station:equator_prime:contention:live_dl_live_b"
      )

    assert %{
             "type" => "candidate_refresh.v1",
             "scope" => "branch_generated",
             "source_report_input_paths" => ["mission_state.source_contact_contention_report"]
           } = pressure_branch["assumptions"]["candidate_source"]

    assert %{
             "type" => "downlink_completion_gap",
             "scenario_id" => "leo_1",
             "spacecraft_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "contact_id" => "dl_live_b",
             "source_activity_id" => "dl_live_b",
             "source_activity_ids" => ["dl_live_b"],
             "source_window_id" =>
               "window:leo_1:ground_station_access:equator_prime:contention_b",
             "source_window_ids" => [
               "window:leo_1:ground_station_access:equator_prime:contention_a",
               "window:leo_1:ground_station_access:equator_prime:contention_b"
             ],
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 42.0,
             "planned_downlink_mb" => planned_downlink_mb,
             "contention_group_id" => "station:equator_prime:contention:live",
             "contention_resource_scope" => "ground_station",
             "contention_contact_ids" => ["dl_live_a", "dl_live_b"],
             "required_operator_action" => "review_contact_contention",
             "approval_status" => "operator_review_required",
             "operator_action_reason" => "same_station_overlapping_contact_windows",
             "derivation_reasons" => [
               "contact_contention_conflict",
               "same_station_overlapping_contact_windows",
               "ground_station",
               "operator_review_required"
             ],
             "downlink_demand_sources" => [
               "mission_state.contention.required_downlink:dl_live_b"
             ],
             "feedback_source" =>
               "mission_state.source_contact_contention_report.conflict_groups",
             "feedback_scope" => "contact_contention",
             "trust_boundary" => "mission_contact_contention"
           } = List.first(pressure_branch["events"])

    assert planned_downlink_mb == 0.0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives contact contention conflicts from mission-state result artifacts" do
    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_result_artifact, %{
            "schema_contract" => "result_artifact.v1",
            "artifact_type" => "mission_state_result_artifact",
            "study_id" => "live_contact_contention",
            "provenance" => %{"trust_boundary" => "live_contention_wrapper"},
            "contact_contention_report" => %{
              "schema_contract" => "contact_contention_report.v1",
              "model" => "single_station_interval_overlap",
              "input_contact_count" => 2,
              "conflicted_contact_count" => 2,
              "conflict_group_count" => 1,
              "conflict_groups" => [
                %{
                  "id" => "station:equator_prime:contention:wrapped",
                  "resource_scope" => "ground_station",
                  "ground_station_id" => "equator_prime",
                  "contact_count" => 2,
                  "starts_at_s" => 620.0,
                  "ends_at_s" => 700.0,
                  "direction" => "downlink",
                  "directions" => ["downlink"],
                  "required_operator_action" => "review_contact_contention",
                  "approval_status" => "operator_review_required",
                  "operator_action_reason" => "same_station_overlapping_contact_windows",
                  "contact_ids" => ["dl_wrapped_a", "dl_wrapped_b"],
                  "source_contact_candidates" => [
                    downlink("dl_wrapped_a", 620.0, 680.0)
                    |> Map.put("estimated_throughput_mb", 33.0),
                    downlink("dl_wrapped_b", 640.0, 700.0)
                    |> Map.put("estimated_throughput_mb", 37.0)
                    |> Map.put("source_window_id", "window:contention:wrapped_b")
                  ]
                }
              ],
              "invalid_contact_inputs" => []
            }
          }),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    pressure_branch =
      branch(
        artifact,
        "derived_contact_contention_pressure_conflict_station:equator_prime:contention:wrapped_dl_wrapped_b"
      )

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "contact_id" => "dl_wrapped_b",
             "source_activity_id" => "dl_wrapped_b",
             "source_window_id" => "window:contention:wrapped_b",
             "required_downlink_mb" => 37.0,
             "contention_group_id" => "station:equator_prime:contention:wrapped",
             "feedback_source" =>
               "mission_state.source_result_artifact.contact_contention_report.conflict_groups",
             "feedback_scope" => "contact_contention",
             "trust_boundary" => "live_contention_wrapper"
           } = List.first(pressure_branch["events"])

    assert "mission_state.source_result_artifact.contact_contention_report" in get_in(
             pressure_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives contact contention pressure from result artifact reports" do
    prior_plan =
      base_plan(%{
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "study_id" => "contact_contention_result_artifact",
          "provenance" => %{"trust_boundary" => "ops_result_artifact"},
          "contact_contention_resolution_report" => %{
            "schema_contract" => "contact_contention_resolution_report.v1",
            "model" => "deterministic_contact_contention_recommendation",
            "source" => "campaign_repair.contact_contention_resolution_report",
            "conflict_group_count" => 1,
            "recommendation_count" => 1,
            "recommendations" => [
              %{
                "group_id" => "station:equator_prime:contention:1",
                "ground_station_id" => "equator_prime",
                "starts_at_s" => 500.0,
                "ends_at_s" => 580.0,
                "selected_contact_id" => "dl_selected",
                "selected_priority" => 10.0,
                "selected_priority_source" => "policy_contact_priority",
                "deferred_contact_ids" => ["dl_result_deferred"],
                "candidate_count" => 2,
                "selection_reason" => "highest_priority_highest_score",
                "resolution_selection_rule" => "highest_priority_highest_score",
                "action" => "recommend_preferred_contact_for_operator_review",
                "review_status" => "operator_review_required",
                "direction" => "downlink",
                "directions" => ["downlink"],
                "source_contact_candidates" => [
                  downlink("dl_selected", 500.0, 560.0)
                  |> Map.put("estimated_throughput_mb", 40.0),
                  downlink("dl_result_deferred", 520.0, 580.0)
                  |> Map.put("estimated_throughput_mb", 42.0)
                  |> Map.put(
                    "source_window_id",
                    "window:leo_1:ground_station_access:equator_prime:deferred"
                  )
                  |> Map.put("downlink_demand_sources", [
                    "contention_resolution.required_downlink:dl_result_deferred"
                  ])
                ]
              }
            ]
          }
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    pressure_branch =
      branch(artifact, "derived_contact_contention_pressure_deferred_dl_result_deferred")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "source_activity_id" => "dl_result_deferred",
             "source_window_id" => "window:leo_1:ground_station_access:equator_prime:deferred",
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 42.0,
             "selected_contact_id" => "dl_selected",
             "selected_priority_source" => "policy_contact_priority",
             "downlink_demand_sources" => [
               "contention_resolution.required_downlink:dl_result_deferred"
             ],
             "feedback_source" =>
               "prior_plan.source_result_artifact.contact_contention_resolution_report",
             "feedback_scope" => "contact_contention_resolution",
             "trust_boundary" => "ops_result_artifact"
           } = List.first(pressure_branch["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             pressure_branch["assumptions"]["candidate_source"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy ignores resolution recommendations shadowed by a contention report contract" do
    prior_plan =
      base_plan(%{
        "source_contact_contention_resolution_report" => %{
          "schema_contract" => "contact_contention_report.v1",
          "model" => "single_station_interval_overlap",
          "input_contact_count" => 0,
          "conflicted_contact_count" => 0,
          "conflict_group_count" => 0,
          "conflict_groups" => [],
          "recommendations" => [
            %{
              "group_id" => "shadow_resolution_group",
              "ground_station_id" => "equator_prime",
              "selected_contact_id" => "dl_shadow_selected",
              "deferred_contact_ids" => ["dl_shadow_resolution"],
              "selection_reason" => "shadow_collection",
              "direction" => "downlink",
              "starts_at_s" => 500.0,
              "ends_at_s" => 560.0
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    refute Enum.any?(
             artifact["branches"],
             &(&1["branch_id"] ==
                 "derived_contact_contention_pressure_deferred_dl_shadow_resolution")
           )
  end

  test "strategy ignores conflict groups shadowed by a resolution report contract" do
    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_result_artifact, %{
            "schema_contract" => "result_artifact.v1",
            "artifact_type" => "mission_state_result_artifact",
            "contact_contention_report" => %{
              "schema_contract" => "contact_contention_resolution_report.v1",
              "model" => "deterministic_contact_contention_recommendation",
              "policy" => %{},
              "conflict_group_count" => 0,
              "recommendation_count" => 0,
              "recommendations" => [],
              "conflict_groups" => [
                %{
                  "id" => "shadow_conflict_group",
                  "ground_station_id" => "equator_prime",
                  "contact_ids" => ["dl_shadow_conflict"],
                  "direction" => "downlink",
                  "starts_at_s" => 600.0,
                  "ends_at_s" => 660.0
                }
              ]
            }
          }),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    refute Enum.any?(
             artifact["branches"],
             &String.starts_with?(
               &1["branch_id"],
               "derived_contact_contention_pressure_conflict_shadow_conflict_group"
             )
           )
  end

  test "strategy requires resolution decisions to match source candidate identities" do
    recommendation = fn prefix, selected_contact_id, deferred_contact_id, candidate_ids ->
      %{
        "group_id" => "#{prefix}_group",
        "ground_station_id" => "equator_prime",
        "selected_contact_id" => selected_contact_id,
        "deferred_contact_ids" => [deferred_contact_id],
        "candidate_count" => length(candidate_ids),
        "selection_reason" => "highest_score_earliest_start",
        "direction" => "downlink",
        "starts_at_s" => 700.0,
        "ends_at_s" => 760.0,
        "source_contact_candidates" =>
          Enum.map(candidate_ids, fn contact_id ->
            downlink(contact_id, 700.0, 760.0)
            |> Map.put("estimated_throughput_mb", 32.0)
          end)
      }
    end

    prior_plan =
      base_plan(%{
        "source_contact_contention_resolution_report" => %{
          "schema_contract" => "contact_contention_resolution_report.v1",
          "recommendations" => [
            recommendation.(
              "substituted_selected",
              "dl_phantom_selected",
              "dl_selected_substitution_deferred",
              ["dl_actual_selected", "dl_selected_substitution_deferred"]
            ),
            recommendation.(
              "substituted_deferred",
              "dl_deferred_substitution_selected",
              "dl_phantom_deferred",
              ["dl_deferred_substitution_selected", "dl_actual_deferred"]
            ),
            recommendation.(
              "selected_as_deferred",
              "dl_self_selected",
              "dl_self_selected",
              ["dl_self_selected", "dl_self_other"]
            ),
            recommendation.(
              "correlated",
              "dl_correlated_selected",
              "dl_correlated_deferred",
              ["dl_correlated_selected", "dl_correlated_deferred"]
            )
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    branch_ids = Enum.map(artifact["branches"], & &1["branch_id"])

    refute "derived_contact_contention_pressure_deferred_dl_selected_substitution_deferred" in branch_ids
    refute "derived_contact_contention_pressure_deferred_dl_phantom_deferred" in branch_ids
    refute "derived_contact_contention_pressure_deferred_dl_self_selected" in branch_ids
    assert "derived_contact_contention_pressure_deferred_dl_correlated_deferred" in branch_ids
  end

  test "strategy requires present conflict candidates to match group contact identities" do
    group = fn prefix, contact_ids, source_contact_candidates ->
      %{
        "id" => "#{prefix}_group",
        "ground_station_id" => "equator_prime",
        "contact_count" => length(contact_ids),
        "contact_ids" => contact_ids,
        "direction" => "downlink",
        "starts_at_s" => 800.0,
        "ends_at_s" => 860.0
      }
      |> then(fn group ->
        if source_contact_candidates == :omitted do
          group
        else
          Map.put(group, "source_contact_candidates", source_contact_candidates)
        end
      end)
    end

    source_candidate = fn contact_id ->
      downlink(contact_id, 800.0, 860.0)
      |> Map.put("estimated_throughput_mb", 34.0)
    end

    contention_report = %{
      "schema_contract" => "contact_contention_report.v1",
      "conflict_groups" => [
        group.(
          "substituted_candidate",
          ["dl_expected_conflict_a", "dl_expected_conflict_b"],
          [
            source_candidate.("dl_expected_conflict_a"),
            source_candidate.("dl_phantom_conflict_candidate")
          ]
        ),
        group.("empty_candidates", ["dl_explicit_empty_candidate"], []),
        group.("omitted_candidates", ["dl_legacy_fallback_candidate"], :omitted)
      ]
    }

    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_contact_contention_report, contention_report),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    branch_ids = Enum.map(artifact["branches"], & &1["branch_id"])

    refute Enum.any?(
             branch_ids,
             &String.starts_with?(
               &1,
               "derived_contact_contention_pressure_conflict_substituted_candidate_group"
             )
           )

    refute "derived_contact_contention_pressure_conflict_empty_candidates_group_dl_explicit_empty_candidate" in branch_ids

    assert "derived_contact_contention_pressure_conflict_omitted_candidates_group_dl_legacy_fallback_candidate" in branch_ids
  end

  test "strategy keeps independent contact contention pressures for the same deferred contact" do
    prior_plan =
      base_plan(%{
        "source_contact_contention_resolution_report" => %{
          "schema_contract" => "contact_contention_resolution_report.v1",
          "model" => "deterministic_contact_contention_recommendation",
          "source" => "campaign_repair.contact_contention_resolution_report",
          "conflict_group_count" => 1,
          "recommendation_count" => 1,
          "trust_boundary" => "ops_source_contention",
          "recommendations" => [
            %{
              "group_id" => "station:equator_prime:contention:source",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 500.0,
              "ends_at_s" => 580.0,
              "selected_contact_id" => "dl_source_selected",
              "deferred_contact_ids" => ["dl_shared_deferred"],
              "selection_reason" => "highest_priority_highest_score",
              "direction" => "downlink",
              "source_contact_candidates" => [
                downlink("dl_source_selected", 500.0, 560.0)
                |> Map.put("estimated_throughput_mb", 40.0),
                downlink("dl_shared_deferred", 520.0, 580.0)
                |> Map.put("estimated_throughput_mb", 42.0)
                |> Map.put("source_window_id", "window:contention:source")
              ]
            }
          ]
        },
        "contact_contention_resolution_report" => %{
          "schema_contract" => "contact_contention_resolution_report.v1",
          "model" => "deterministic_contact_contention_recommendation",
          "source" => "campaign_strategy.branch_repair.contact_contention_resolution_report",
          "conflict_group_count" => 1,
          "recommendation_count" => 1,
          "trust_boundary" => "ops_canonical_contention",
          "recommendations" => [
            %{
              "group_id" => "station:polar_aux:contention:canonical",
              "ground_station_id" => "polar_aux",
              "starts_at_s" => 620.0,
              "ends_at_s" => 700.0,
              "selected_contact_id" => "dl_canonical_selected",
              "deferred_contact_ids" => ["dl_shared_deferred"],
              "selection_reason" => "highest_score_earliest_start",
              "direction" => "downlink",
              "source_contact_candidates" => [
                downlink("dl_canonical_selected", 620.0, 680.0)
                |> Map.put("ground_station_id", "polar_aux")
                |> Map.put("estimated_throughput_mb", 36.0),
                downlink("dl_shared_deferred", 640.0, 700.0)
                |> Map.put("ground_station_id", "polar_aux")
                |> Map.put("estimated_throughput_mb", 31.0)
                |> Map.put("source_window_id", "window:contention:canonical")
              ]
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    branch_ids = Enum.map(artifact["branches"], & &1["branch_id"])

    refute "derived_contact_contention_pressure_deferred_dl_shared_deferred" in branch_ids

    source_branch_id =
      Enum.find(
        branch_ids,
        &String.starts_with?(
          &1,
          "derived_contact_contention_pressure_deferred_dl_shared_deferred_window:contention:source"
        )
      )

    canonical_branch_id =
      Enum.find(
        branch_ids,
        &String.starts_with?(
          &1,
          "derived_contact_contention_pressure_deferred_dl_shared_deferred_window:contention:canonical"
        )
      )

    assert source_branch_id
    assert canonical_branch_id

    source_branch = branch(artifact, source_branch_id)
    canonical_branch = branch(artifact, canonical_branch_id)

    assert %{
             "type" => "downlink_completion_gap",
             "contact_id" => "dl_shared_deferred",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 42.0,
             "source_window_id" => "window:contention:source",
             "selected_contact_id" => "dl_source_selected",
             "feedback_source" => "prior_plan.source_contact_contention_resolution_report",
             "trust_boundary" => "ops_source_contention"
           } = List.first(source_branch["events"])

    assert %{
             "type" => "downlink_completion_gap",
             "contact_id" => "dl_shared_deferred",
             "ground_station_id" => "polar_aux",
             "required_downlink_mb" => 31.0,
             "source_window_id" => "window:contention:canonical",
             "selected_contact_id" => "dl_canonical_selected",
             "feedback_source" => "prior_plan.contact_contention_resolution_report",
             "trust_boundary" => "ops_canonical_contention"
           } = List.first(canonical_branch["events"])

    comparison_branch_ids =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.map(& &1["branch_id"])

    assert source_branch_id in comparison_branch_ids
    assert canonical_branch_id in comparison_branch_ids

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp assert_candidate_refresh_request_report_path(branch, expected_path) do
    assert expected_path in get_in(branch, [
             "assumptions",
             "candidate_source",
             "candidate_refresh_request_source_report_input_paths"
           ])
  end

  defp assert_candidate_source_report_path(branch, expected_path) do
    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = branch["assumptions"]["candidate_source"]

    assert expected_path in candidate_source["source_report_input_paths"]
    candidate_source
  end

  defp assert_contact_intent_pressure_score_terms(branch, artifact) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    contact_intent_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] == "downlink_completion_gap" and &1["feedback_scope"] == "contact_intent")
      )

    assert contact_intent_pressure_count > 0

    assert branch["score_terms"]["contact_intent_pressure_penalty"] ==
             -contact_intent_pressure_count * risk_weight

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - contact_intent_pressure_count) * risk_weight

    assert "contact_intent_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "contact_intent_pressure_penalty" and &1["value"] < 0.0)
           )
  end

  defp assert_contact_contention_pressure_score_terms(branch, artifact) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    contact_contention_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] == "downlink_completion_gap" and
            &1["feedback_scope"] in ["contact_contention", "contact_contention_resolution"])
      )

    assert contact_contention_pressure_count > 0

    assert branch["score_terms"]["contact_contention_pressure_penalty"] ==
             -contact_contention_pressure_count * risk_weight

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - contact_contention_pressure_count) *
               risk_weight

    assert "contact_contention_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "contact_contention_pressure_penalty" and &1["value"] < 0.0)
           )
  end
end
