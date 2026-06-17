Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyTimelineDiffResourceManeuverPressureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives changed timeline diff resource availability feedback" do
    prior_plan =
      base_plan(%{
        "activities" => [observe("obs_payload_source", "leo_1", "target_a", 100.0, 160.0, 5.0)],
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_timeline_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:obs_payload",
              "rank" => 1,
              "timeline_id" => "timeline:obs_payload",
              "diff_status" => "changed",
              "changed_fields" => ["payload_available?"],
              "source_activity_id" => "obs_payload_source",
              "replacement_activity_id" => "obs_payload_replacement",
              "source_activity_type" => "observe",
              "replacement_activity_type" => "observe",
              "scenario_id" => "leo_1",
              "replacement_activity_context" => %{
                "starts_at_s" => 100.0,
                "ends_at_s" => 160.0,
                "spacecraft_id" => "leo_1",
                "payload_available?" => "false",
                "degraded?" => "true",
                "mode" => "safe"
              },
              "required_operator_action" => "review_resource_availability"
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        approval_policy: %{policy_bundle_id: "degraded_payload_guard_v1"},
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    branch = branch(artifact, "derived_timeline_diff_changed_obs_payload_source")

    assert %{
             "type" => "resource_availability_constraint",
             "scenario_id" => "leo_1",
             "spacecraft_id" => "leo_1",
             "resource_field" => "payload_available",
             "payload_available" => false,
             "available" => false,
             "degraded" => true,
             "mode" => "safe",
             "source_activity_id" => "obs_payload_source",
             "replacement_activity_id" => "obs_payload_replacement",
             "source_activity_ids" => ["obs_payload_replacement", "obs_payload_source"],
             "timeline_id" => "timeline:obs_payload",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "feedback_key" => "leo_1",
             "trust_boundary" => "ops_timeline_review",
             "derivation_reasons" => [
               "timeline_diff_changed_activity",
               "timeline_diff_changed_resource_availability",
               "payload_available_timeline_diff_false"
             ]
           } = List.first(branch["events"])

    assert Enum.any?(
             branch["repair_result"]["source_resource_summaries"],
             &(&1["spacecraft_id"] == "leo_1" and &1["payload_available"] == false and
                 get_in(&1, ["provenance", "event_type"]) == "resource_availability_constraint")
           )

    assert Enum.any?(
             branch["repair_result"]["source_resource_filter_report"]["suppressed_candidates"],
             &(&1["suppressed_reason"] == "payload_unavailable" and
                 &1["approval_status"] == "blocked_by_policy" and
                 get_in(&1, ["policy_decision", "policy_bundle_id"]) ==
                   "degraded_payload_guard_v1")
           )

    assert Enum.any?(
             branch["risk_indicators"],
             &(&1["type"] == "payload_unavailable" and &1["spacecraft_id"] == "leo_1" and
                 &1["value"] == false)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives changed timeline diff resource identity mismatch feedback" do
    prior_plan =
      base_plan(%{
        "activities" => [
          observe("obs_resource_source", "leo_1", "target_a", 100.0, 160.0, 5.0)
        ],
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_timeline_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:obs_resource",
              "rank" => 1,
              "timeline_id" => "timeline:obs_resource",
              "diff_status" => "changed",
              "changed_fields" => ["resource_id"],
              "source_activity_id" => "obs_resource_source",
              "replacement_activity_id" => "obs_resource_replacement",
              "source_activity_type" => "observe",
              "replacement_activity_type" => "observe",
              "scenario_id" => "leo_1",
              "planned_resource_id" => "payload_power_bus_a",
              "realized_resource_id" => "payload_power_bus_b",
              "resource_match_status" => "mismatch",
              "source_activity_context" => %{
                "starts_at_s" => 100.0,
                "ends_at_s" => 160.0,
                "spacecraft_id" => "leo_1",
                "resource_id" => "payload_power_bus_a"
              },
              "replacement_activity_context" => %{
                "starts_at_s" => 100.0,
                "ends_at_s" => 160.0,
                "spacecraft_id" => "leo_1",
                "resource_id" => "payload_power_bus_b"
              },
              "required_operator_action" => "review_realized_variance"
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        approval_policy: %{policy_bundle_id: "degraded_payload_guard_v1"},
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    branch = branch(artifact, "derived_timeline_diff_changed_obs_resource_source")

    assert %{
             "type" => "resource_availability_constraint",
             "scenario_id" => "leo_1",
             "spacecraft_id" => "leo_1",
             "resource_field" => "payload_available",
             "payload_available" => false,
             "available" => false,
             "resource_id" => "payload_power_bus_a",
             "planned_resource_id" => "payload_power_bus_a",
             "realized_resource_id" => "payload_power_bus_b",
             "resource_match_status" => "mismatch",
             "resource_identity_mismatch_fields" => ["resource"],
             "source_activity_id" => "obs_resource_source",
             "replacement_activity_id" => "obs_resource_replacement",
             "source_activity_ids" => ["obs_resource_replacement", "obs_resource_source"],
             "timeline_id" => "timeline:obs_resource",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "feedback_key" => "leo_1",
             "trust_boundary" => "ops_timeline_review",
             "derivation_reasons" => [
               "timeline_diff_changed_activity",
               "timeline_diff_changed_resource_identity",
               "resource_mismatch",
               "payload_available_timeline_diff_resource_mismatch"
             ]
           } = List.first(branch["events"])

    assert Enum.any?(
             branch["repair_result"]["source_resource_summaries"],
             &(&1["spacecraft_id"] == "leo_1" and &1["payload_available"] == false and
                 get_in(&1, ["assumptions", "planned_resource_id"]) == "payload_power_bus_a" and
                 get_in(&1, ["provenance", "event_type"]) == "resource_availability_constraint")
           )

    assert Enum.any?(
             branch["repair_result"]["source_resource_filter_report"]["suppressed_candidates"],
             &(&1["suppressed_reason"] == "payload_unavailable" and
                 &1["approval_status"] == "blocked_by_policy" and
                 get_in(&1, ["policy_decision", "policy_bundle_id"]) ==
                   "degraded_payload_guard_v1")
           )

    assert Enum.any?(
             branch["risk_indicators"],
             &(&1["type"] == "payload_unavailable" and
                 &1["planned_resource_id"] == "payload_power_bus_a" and
                 &1["realized_resource_id"] == "payload_power_bus_b" and
                 &1["resource_match_status"] == "mismatch")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives changed timeline diff resource margin feedback" do
    prior_plan =
      base_plan(%{
        "activities" => [observe("obs_power_source", "leo_1", "target_a", 100.0, 160.0, 5.0)],
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_timeline_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:obs_power",
              "rank" => 1,
              "timeline_id" => "timeline:obs_power",
              "diff_status" => "changed",
              "changed_fields" => ["battery_state_of_charge"],
              "source_activity_id" => "obs_power_source",
              "replacement_activity_id" => "obs_power_replacement",
              "source_activity_type" => "observe",
              "replacement_activity_type" => "observe",
              "scenario_id" => "leo_1",
              "replacement_activity_context" => %{
                "starts_at_s" => 100.0,
                "ends_at_s" => 160.0,
                "spacecraft_id" => "leo_1",
                "battery_state_of_charge" => "0.05"
              },
              "required_operator_action" => "review_resource_margin"
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

    branch = branch(artifact, "derived_timeline_diff_changed_obs_power_source")

    assert %{
             "type" => "resource_margin_pressure",
             "scenario_id" => "leo_1",
             "spacecraft_id" => "leo_1",
             "resource_field" => "power_margin",
             "power_margin" => 0.05,
             "power_margin_threshold" => 0.2,
             "source_activity_id" => "obs_power_source",
             "replacement_activity_id" => "obs_power_replacement",
             "source_activity_ids" => ["obs_power_replacement", "obs_power_source"],
             "timeline_id" => "timeline:obs_power",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "feedback_key" => "leo_1",
             "trust_boundary" => "ops_timeline_review",
             "derivation_reasons" => [
               "timeline_diff_changed_activity",
               "timeline_diff_changed_resource_margin",
               "power_margin_timeline_diff_low"
             ]
           } = List.first(branch["events"])

    assert Enum.any?(
             branch["repair_result"]["source_resource_summaries"],
             &(&1["spacecraft_id"] == "leo_1" and &1["power_margin"] == 0.05 and
                 get_in(&1, ["provenance", "event_type"]) == "resource_margin_pressure")
           )

    assert Enum.any?(
             branch["risk_indicators"],
             &(&1["type"] == "power_margin_low" and &1["spacecraft_id"] == "leo_1" and
                 &1["value"] == 0.05)
           )

    comparison_row =
      Enum.find(
        artifact["branch_comparison_report"]["rows"],
        &(&1["branch_id"] == "derived_timeline_diff_changed_obs_power_source")
      )

    assert comparison_row["power_margin"] == 0.05
    assert "power_margin_low" in comparison_row["resource_risk_types"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives changed timeline diff thermal margin feedback from temperature bounds" do
    prior_plan =
      base_plan(%{
        "activities" => [observe("obs_thermal_source", "leo_1", "target_a", 100.0, 160.0, 5.0)],
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_timeline_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:obs_thermal",
              "rank" => 1,
              "timeline_id" => "timeline:obs_thermal",
              "diff_status" => "changed",
              "changed_fields" => ["actual_temperature_c", "thermal_status"],
              "source_activity_id" => "obs_thermal_source",
              "replacement_activity_id" => "obs_thermal_replacement",
              "source_activity_type" => "observe",
              "replacement_activity_type" => "observe",
              "scenario_id" => "leo_1",
              "replacement_activity_context" => %{
                "starts_at_s" => 100.0,
                "ends_at_s" => 160.0,
                "spacecraft_id" => "leo_1",
                "actual_temperature_c" => "83.0",
                "min_operating_temperature_c" => "-20.0",
                "max_operating_temperature_c" => "80.0",
                "thermal_status" => "over limit",
                "thermal_model" => "provider_thermal_limits",
                "thermal_source" => "payload_thermal_telemetry",
                "thermal_confidence" => "0.9"
              },
              "required_operator_action" => "review_resource_margin"
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        branch_generation_policy: %{thermal_margin_c_threshold: "0.0"},
        current_epoch_s: 0.0
      )

    branch = branch(artifact, "derived_timeline_diff_changed_obs_thermal_source")

    event = List.first(branch["events"])

    assert %{
             "type" => "resource_margin_pressure",
             "scenario_id" => "leo_1",
             "spacecraft_id" => "leo_1",
             "resource_field" => "thermal_margin_c",
             "thermal_margin_c" => -3.0,
             "temperature_c" => 83.0,
             "actual_temperature_c" => 83.0,
             "min_operating_temperature_c" => -20.0,
             "max_operating_temperature_c" => 80.0,
             "thermal_status" => "over limit",
             "thermal_model" => "provider_thermal_limits",
             "thermal_source" => "payload_thermal_telemetry",
             "thermal_confidence" => 0.9,
             "source_activity_id" => "obs_thermal_source",
             "replacement_activity_id" => "obs_thermal_replacement",
             "source_activity_ids" => ["obs_thermal_replacement", "obs_thermal_source"],
             "timeline_id" => "timeline:obs_thermal",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "feedback_key" => "leo_1",
             "trust_boundary" => "ops_timeline_review",
             "derivation_reasons" => [
               "timeline_diff_changed_activity",
               "timeline_diff_changed_resource_margin",
               "thermal_margin_c_timeline_diff_low"
             ]
           } = event

    assert event["thermal_margin_c_threshold"] == 0.0

    assert Enum.any?(
             branch["repair_result"]["source_resource_summaries"],
             &(&1["spacecraft_id"] == "leo_1" and &1["thermal_margin_c"] == -3.0 and
                 get_in(&1, ["provenance", "event_type"]) == "resource_margin_pressure")
           )

    assert Enum.any?(
             branch["risk_indicators"],
             &(&1["type"] == "thermal_margin_c_low" and &1["spacecraft_id"] == "leo_1" and
                 &1["value"] == -3.0)
           )

    comparison_row =
      Enum.find(
        artifact["branch_comparison_report"]["rows"],
        &(&1["branch_id"] == "derived_timeline_diff_changed_obs_thermal_source")
      )

    assert comparison_row["thermal_margin_c"] == -3.0
    assert "thermal_margin_low" in comparison_row["resource_risk_types"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy ignores healthy changed timeline diff resource margins" do
    prior_plan =
      base_plan(%{
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_timeline_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:obs_power_healthy",
              "rank" => 1,
              "timeline_id" => "timeline:obs_power_healthy",
              "diff_status" => "changed",
              "changed_fields" => ["battery_state_of_charge"],
              "source_activity_id" => "obs_power_healthy_source",
              "replacement_activity_id" => "obs_power_healthy_replacement",
              "source_activity_type" => "observe",
              "replacement_activity_type" => "observe",
              "scenario_id" => "leo_1",
              "replacement_activity_context" => %{
                "starts_at_s" => 100.0,
                "ends_at_s" => 160.0,
                "spacecraft_id" => "leo_1",
                "battery_state_of_charge" => "0.85"
              },
              "required_operator_action" => "review_resource_margin"
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

    refute branch(artifact, "derived_timeline_diff_changed_obs_power_healthy_source")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy ignores healthy changed timeline diff thermal bound rows" do
    prior_plan =
      base_plan(%{
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_timeline_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:obs_thermal_healthy",
              "rank" => 1,
              "timeline_id" => "timeline:obs_thermal_healthy",
              "diff_status" => "changed",
              "changed_fields" => ["actual_temperature_c"],
              "source_activity_id" => "obs_thermal_healthy_source",
              "replacement_activity_id" => "obs_thermal_healthy_replacement",
              "source_activity_type" => "observe",
              "replacement_activity_type" => "observe",
              "scenario_id" => "leo_1",
              "replacement_activity_context" => %{
                "starts_at_s" => 100.0,
                "ends_at_s" => 160.0,
                "spacecraft_id" => "leo_1",
                "actual_temperature_c" => "20.0",
                "min_operating_temperature_c" => "-20.0",
                "max_operating_temperature_c" => "80.0"
              },
              "required_operator_action" => "review_resource_margin"
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        branch_generation_policy: %{thermal_margin_c_threshold: "0.0"},
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_timeline_diff_changed_obs_thermal_healthy_source")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives changed timeline diff maneuver feedback from typed impulsive burns" do
    prior_plan =
      base_plan(%{
        "activities" => [maneuver("typed_burn_source", 100.0)],
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_typed_burn_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:typed_burn_changed",
              "rank" => 1,
              "timeline_id" => "timeline:typed_burn_changed",
              "diff_status" => "changed",
              "changed_fields" => ["maneuver_result", "maneuver_success_factor"],
              "source_activity_id" => "typed_burn_source",
              "replacement_activity_id" => "typed_burn_changed",
              "source_activity_type" => "impulsive_burn",
              "replacement_activity_type" => "impulsive_burn",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "replacement_activity_context" => %{
                "starts_at_s" => 100.0,
                "ends_at_s" => 100.0,
                "operational_kind" => "maneuver",
                "maneuver_result" => "accepted, failed"
              },
              "required_operator_action" => "review_timeline_change"
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

    branch = branch(artifact, "derived_timeline_diff_changed_typed_burn_source")

    assert %{
             "type" => "maneuver_success_feedback",
             "activity_id" => "typed_burn_source",
             "scenario_id" => "leo_1",
             "source_activity_id" => "typed_burn_source",
             "replacement_activity_id" => "typed_burn_changed",
             "source_activity_ids" => ["typed_burn_changed", "typed_burn_source"],
             "timeline_id" => "timeline:typed_burn_changed",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "trust_boundary" => "ops_typed_burn_review",
             "derivation_reasons" => [
               "timeline_diff_changed_activity",
               "timeline_diff_changed_maneuver"
             ]
           } = List.first(branch["events"])

    assert List.first(branch["events"])["maneuver_success_factor"] == 0.0
    assert branch["feedback_adjustments"]["maneuver_success_factor"] == 0.0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy ignores successful changed timeline diff maneuver rows" do
    prior_plan =
      base_plan(%{
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_timeline_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:burn_success",
              "rank" => 1,
              "timeline_id" => "timeline:burn_success",
              "diff_status" => "changed",
              "changed_fields" => ["maneuver_result"],
              "source_activity_id" => "burn_success_source",
              "replacement_activity_id" => "burn_success",
              "source_activity_type" => "maneuver",
              "replacement_activity_type" => "maneuver",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "replacement_activity_context" => %{"maneuver_result" => "accepted, executed"},
              "required_operator_action" => "review_timeline_change"
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

    refute branch(artifact, "derived_timeline_diff_changed_burn_success_source")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives changed timeline diff maneuver feedback from operator review rows" do
    prior_plan =
      base_plan(%{
        "activities" => [maneuver("burn_review_source", 100.0)],
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "timeline_diff_report.v1",
          "review_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_timeline_review_queue"},
          "rows" => [
            %{
              "id" => "operator_review:timeline_diff:burn_review_changed",
              "review_type" => "timeline_diff_review",
              "source" => "timeline_diff_report.rows",
              "subject_id" => "timeline:burn_review_changed",
              "approval_status" => "operator_review_required",
              "source_timeline_diff" => %{
                "id" => "timeline_diff:timeline:burn_review_changed",
                "rank" => 1,
                "timeline_id" => "timeline:burn_review_changed",
                "diff_status" => "changed",
                "changed_fields" => ["maneuver_result", "maneuver_success_factor"],
                "source_activity_id" => "burn_review_source",
                "replacement_activity_id" => "burn_review_changed",
                "source_activity_type" => "maneuver",
                "replacement_activity_type" => "maneuver",
                "scenario_id" => "leo_1",
                "source_status" => "planned",
                "replacement_activity_context" => %{
                  "starts_at_s" => 100.0,
                  "ends_at_s" => 100.0,
                  "maneuver_result" => "failed"
                },
                "required_operator_action" => "review_timeline_change"
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

    branch = branch(artifact, "derived_timeline_diff_changed_burn_review_source")

    assert %{
             "type" => "maneuver_success_feedback",
             "activity_id" => "burn_review_source",
             "source_activity_id" => "burn_review_source",
             "replacement_activity_id" => "burn_review_changed",
             "source_activity_ids" => ["burn_review_changed", "burn_review_source"],
             "timeline_id" => "timeline:burn_review_changed",
             "feedback_source" => "prior_plan.operator_review_package.rows.source_timeline_diff",
             "feedback_scope" => "timeline_diff",
             "trust_boundary" => "ops_timeline_review_queue",
             "derivation_reasons" => [
               "timeline_diff_changed_activity",
               "timeline_diff_changed_maneuver"
             ]
           } = List.first(branch["events"])

    assert List.first(branch["events"])["maneuver_success_factor"] == 0.0
    assert branch["feedback_adjustments"]["maneuver_success_factor"] == 0.0

    assert Enum.any?(
             branch["risk_indicators"],
             &(&1["type"] == "maneuver_success_rate_low" and &1["value"] == 0.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
