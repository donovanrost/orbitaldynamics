Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyFilterLinkPressureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives branch refresh from prior resource filter suppression pressure" do
    prior_plan =
      base_plan(%{
        "source_resource_filter_report" => %{
          "schema_contract" => "resource_filter_report.v1",
          "model" => "resource_summary_availability_and_margin_filter",
          "input_candidate_count" => 1,
          "kept_candidate_count" => 0,
          "suppressed_candidate_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_resource_filter"},
          "suppressed_candidates" => [
            %{
              "id" => "obs_suppressed_resource",
              "type" => "observe",
              "scenario_id" => "leo_1",
              "spacecraft_id" => "leo_1",
              "target_id" => "target_a",
              "starts_at_s" => 0.0,
              "ends_at_s" => 120.0,
              "suppressed_reason" => "payload_unavailable",
              "payload_available" => false,
              "resource_source_quality" => "operator_supplied",
              "resource_trust_boundary_status" => "declared"
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

    pressure_branch =
      branch(
        artifact,
        "derived_resource_filter_pressure_payload_unavailable_obs_suppressed_resource"
      )

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             pressure_branch["assumptions"]["candidate_source"]

    assert %{
             "type" => "resource_availability_constraint",
             "scenario_id" => "leo_1",
             "spacecraft_id" => "leo_1",
             "resource_field" => "payload_available",
             "available" => false,
             "source_activity_id" => "obs_suppressed_resource",
             "suppressed_reason" => "payload_unavailable",
             "source_quality" => "operator_supplied",
             "resource_trust_boundary_status" => "declared",
             "feedback_source" => "prior_plan.source_resource_filter_report",
             "feedback_scope" => "resource_filter",
             "trust_boundary" => "ops_resource_filter"
           } = List.first(pressure_branch["events"])

    assert Enum.any?(
             pressure_branch["repair_result"]["source_resource_summaries"],
             &(&1["spacecraft_id"] == "leo_1" and &1["payload_available"] == false and
                 get_in(&1, ["provenance", "event_type"]) ==
                   "resource_availability_constraint" and
                 get_in(&1, ["provenance", "trust_boundary"]) == "ops_resource_filter")
           )

    assert Enum.any?(
             pressure_branch["repair_result"]["source_resource_filter_report"][
               "suppressed_candidates"
             ],
             &(&1["type"] == "observe" and &1["suppressed_reason"] == "payload_unavailable")
           )

    refute Enum.any?(
             pressure_branch["repair_result"]["source_candidate_activities"],
             &(&1["type"] == "observe" and &1["scenario_id"] == "leo_1")
           )

    assert Enum.any?(
             pressure_branch["risk_indicators"],
             &(&1["type"] == "payload_unavailable" and &1["spacecraft_id"] == "leo_1")
           )

    assert_resource_filter_pressure_score_terms(pressure_branch, artifact)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from mission-state resource filter suppression pressure" do
    resource_filter_report = %{
      "schema_contract" => "resource_filter_report.v1",
      "model" => "resource_summary_availability_and_margin_filter",
      "input_candidate_count" => 1,
      "kept_candidate_count" => 0,
      "suppressed_candidate_count" => 1,
      "provenance" => %{"trust_boundary" => "live_resource_filter"},
      "suppressed_candidates" => [
        %{
          "id" => "obs_live_resource_filter",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "spacecraft_id" => "leo_1",
          "target_id" => "target_a",
          "starts_at_s" => 0.0,
          "ends_at_s" => 120.0,
          "suppressed_reason" => "payload_unavailable",
          "payload_available" => false,
          "resource_source_quality" => "operator_supplied",
          "resource_trust_boundary_status" => "declared"
        }
      ]
    }

    artifact =
      strategy(
        base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_resource_filter_report, resource_filter_report),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    pressure_branch =
      branch(
        artifact,
        "derived_resource_filter_pressure_payload_unavailable_obs_live_resource_filter"
      )

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             pressure_branch["assumptions"]["candidate_source"]

    assert %{
             "type" => "resource_availability_constraint",
             "spacecraft_id" => "leo_1",
             "resource_field" => "payload_available",
             "available" => false,
             "source_activity_id" => "obs_live_resource_filter",
             "suppressed_reason" => "payload_unavailable",
             "source_quality" => "operator_supplied",
             "feedback_source" => "mission_state.source_resource_filter_report",
             "feedback_scope" => "resource_filter",
             "trust_boundary" => "live_resource_filter"
           } = List.first(pressure_branch["events"])

    assert Enum.any?(
             pressure_branch["repair_result"]["source_resource_summaries"],
             &(&1["spacecraft_id"] == "leo_1" and &1["payload_available"] == false and
                 get_in(&1, ["provenance", "trust_boundary"]) == "live_resource_filter")
           )

    assert Enum.any?(
             pressure_branch["repair_result"]["source_resource_filter_report"][
               "suppressed_candidates"
             ],
             &(&1["id"] == "leo_1_observe_target_a_1" and
                 &1["suppressed_reason"] == "payload_unavailable")
           )

    assert "resource_availability_overrides" in get_in(
             pressure_branch,
             ["assumptions", "candidate_source", "operational_feedback_input_keys"]
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives resource filter pressure from result artifact reports" do
    prior_plan =
      base_plan(%{
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "study_id" => "resource_filter_result_artifact",
          "provenance" => %{"trust_boundary" => "ops_result_artifact"},
          "resource_filter_report" => %{
            "schema_contract" => "resource_filter_report.v1",
            "model" => "resource_summary_availability_and_margin_filter",
            "input_candidate_count" => 1,
            "kept_candidate_count" => 0,
            "suppressed_candidate_count" => 1,
            "suppressed_candidates" => [
              %{
                "id" => "obs_result_resource_filter",
                "type" => "observe",
                "scenario_id" => "leo_1",
                "spacecraft_id" => "leo_1",
                "target_id" => "target_a",
                "starts_at_s" => 0.0,
                "ends_at_s" => 120.0,
                "suppressed_reason" => "payload_unavailable",
                "payload_available" => false,
                "resource_source_quality" => "operator_supplied",
                "resource_trust_boundary_status" => "declared"
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
      branch(
        artifact,
        "derived_resource_filter_pressure_payload_unavailable_obs_result_resource_filter"
      )

    assert %{
             "type" => "resource_availability_constraint",
             "scenario_id" => "leo_1",
             "spacecraft_id" => "leo_1",
             "resource_field" => "payload_available",
             "available" => false,
             "source_activity_id" => "obs_result_resource_filter",
             "suppressed_reason" => "payload_unavailable",
             "source_quality" => "operator_supplied",
             "resource_trust_boundary_status" => "declared",
             "feedback_source" => "prior_plan.source_result_artifact.resource_filter_report",
             "feedback_scope" => "resource_filter",
             "trust_boundary" => "ops_result_artifact"
           } = List.first(pressure_branch["events"])

    assert Enum.any?(
             pressure_branch["repair_result"]["source_resource_summaries"],
             &(&1["spacecraft_id"] == "leo_1" and &1["payload_available"] == false and
                 get_in(&1, ["provenance", "trust_boundary"]) == "ops_result_artifact")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy keeps independent resource filter pressures for the same candidate" do
    prior_plan =
      base_plan(%{
        "source_resource_filter_report" => %{
          "schema_contract" => "resource_filter_report.v1",
          "model" => "resource_summary_availability_and_margin_filter",
          "input_candidate_count" => 1,
          "kept_candidate_count" => 0,
          "suppressed_candidate_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_source_resource_filter"},
          "suppressed_candidates" => [
            %{
              "id" => "obs_shared_resource",
              "type" => "observe",
              "scenario_id" => "leo_1",
              "spacecraft_id" => "leo_1",
              "target_id" => "target_a",
              "starts_at_s" => 100.0,
              "ends_at_s" => 160.0,
              "suppressed_reason" => "payload_unavailable",
              "payload_available" => false,
              "resource_source_quality" => "operator_supplied",
              "resource_trust_boundary_status" => "declared"
            }
          ]
        },
        "resource_filter_report" => %{
          "schema_contract" => "resource_filter_report.v1",
          "model" => "resource_summary_availability_and_margin_filter",
          "input_candidate_count" => 1,
          "kept_candidate_count" => 0,
          "suppressed_candidate_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_canonical_resource_filter"},
          "suppressed_candidates" => [
            %{
              "id" => "obs_shared_resource",
              "type" => "observe",
              "scenario_id" => "leo_1",
              "spacecraft_id" => "leo_1",
              "target_id" => "target_b",
              "starts_at_s" => 220.0,
              "ends_at_s" => 280.0,
              "suppressed_reason" => "payload_unavailable",
              "payload_available" => false,
              "resource_source_quality" => "repaired_plan",
              "resource_trust_boundary_status" => "declared"
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

    refute "derived_resource_filter_pressure_payload_unavailable_obs_shared_resource" in branch_ids

    source_branch_id =
      Enum.find(
        branch_ids,
        &String.starts_with?(
          &1,
          "derived_resource_filter_pressure_payload_unavailable_obs_shared_resource_prior_plan.source_resource_filter_report"
        )
      )

    canonical_branch_id =
      Enum.find(
        branch_ids,
        &String.starts_with?(
          &1,
          "derived_resource_filter_pressure_payload_unavailable_obs_shared_resource_prior_plan.resource_filter_report"
        )
      )

    assert source_branch_id
    assert canonical_branch_id

    source_branch = branch(artifact, source_branch_id)
    canonical_branch = branch(artifact, canonical_branch_id)

    assert %{
             "type" => "resource_availability_constraint",
             "source_activity_id" => "obs_shared_resource",
             "starts_at_s" => 100.0,
             "ends_at_s" => 160.0,
             "feedback_source" => "prior_plan.source_resource_filter_report",
             "trust_boundary" => "ops_source_resource_filter"
           } = List.first(source_branch["events"])

    assert %{
             "type" => "resource_availability_constraint",
             "source_activity_id" => "obs_shared_resource",
             "starts_at_s" => 220.0,
             "ends_at_s" => 280.0,
             "feedback_source" => "prior_plan.resource_filter_report",
             "trust_boundary" => "ops_canonical_resource_filter"
           } = List.first(canonical_branch["events"])

    comparison_branch_ids =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.map(& &1["branch_id"])

    assert source_branch_id in comparison_branch_ids
    assert canonical_branch_id in comparison_branch_ids

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from prior thermal resource filter pressure" do
    prior_plan =
      base_plan(%{
        "source_resource_filter_report" => %{
          "schema_contract" => "resource_filter_report.v1",
          "model" => "resource_summary_availability_and_margin_filter",
          "input_candidate_count" => 1,
          "kept_candidate_count" => 0,
          "suppressed_candidate_count" => 1,
          "policy" => %{"min_activity_thermal_margin_c" => 2.0},
          "provenance" => %{"trust_boundary" => "ops_resource_filter"},
          "suppressed_candidates" => [
            %{
              "id" => "obs_hot_resource",
              "type" => "observe",
              "scenario_id" => "leo_1",
              "spacecraft_id" => "leo_1",
              "target_id" => "target_a",
              "starts_at_s" => 0.0,
              "ends_at_s" => 120.0,
              "suppressed_reason" => "thermal_margin_below_policy",
              "resource_blocking_dimension" => "thermal",
              "thermal_margin_c" => 1.5,
              "resource_source_quality" => "operator_supplied",
              "resource_trust_boundary_status" => "declared"
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

    pressure_branch =
      branch(
        artifact,
        "derived_resource_filter_pressure_thermal_margin_below_policy_obs_hot_resource"
      )

    assert %{
             "type" => "resource_margin_pressure",
             "scenario_id" => "leo_1",
             "spacecraft_id" => "leo_1",
             "resource_field" => "thermal_margin_c",
             "thermal_margin_c" => 1.5,
             "thermal_margin_c_threshold" => 2.0,
             "source_activity_id" => "obs_hot_resource",
             "suppressed_reason" => "thermal_margin_below_policy",
             "source_quality" => "operator_supplied",
             "resource_trust_boundary_status" => "declared",
             "feedback_source" => "prior_plan.source_resource_filter_report",
             "feedback_scope" => "resource_filter",
             "trust_boundary" => "ops_resource_filter"
           } = List.first(pressure_branch["events"])

    assert Enum.any?(
             pressure_branch["repair_result"]["source_resource_summaries"],
             &(&1["spacecraft_id"] == "leo_1" and &1["thermal_margin_c"] == 1.5 and
                 get_in(&1, ["provenance", "event_type"]) == "resource_margin_pressure" and
                 get_in(&1, ["provenance", "trust_boundary"]) == "ops_resource_filter")
           )

    assert %{"min_activity_thermal_margin_c" => 2.0} =
             pressure_branch["repair_result"]["source_resource_filter_report"]["policy"]

    assert Enum.any?(
             pressure_branch["repair_result"]["source_resource_filter_report"][
               "suppressed_candidates"
             ],
             &(&1["type"] == "observe" and
                 &1["suppressed_reason"] == "thermal_margin_below_policy" and
                 &1["resource_blocking_dimension"] == "thermal" and
                 &1["thermal_margin_c"] == 1.5)
           )

    refute Enum.any?(
             pressure_branch["repair_result"]["source_candidate_activities"],
             &(&1["type"] == "observe" and &1["scenario_id"] == "leo_1")
           )

    assert Enum.any?(
             pressure_branch["risk_indicators"],
             &(&1["type"] == "thermal_margin_c_low" and &1["value"] == 1.5)
           )

    pressure_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] ==
            "derived_resource_filter_pressure_thermal_margin_below_policy_obs_hot_resource")
      )

    assert pressure_row["thermal_margin_c"] == 1.5
    assert "thermal_margin_low" in pressure_row["resource_risk_types"]

    assert_resource_filter_pressure_score_terms(pressure_branch, artifact)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from prior contact filter suppression pressure" do
    prior_plan =
      base_plan(%{
        "source_contact_filter_report" => %{
          "schema_contract" => "contact_filter_report.v1",
          "model" => "thin_ground_network_availability_filter",
          "input_candidate_count" => 1,
          "kept_candidate_count" => 0,
          "suppressed_candidate_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_contact_filter"},
          "suppressed_candidates" => [
            %{
              "id" => "dl_suppressed",
              "type" => "downlink",
              "scenario_id" => "leo_1",
              "spacecraft_id" => "leo_1",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 0.0,
              "ends_at_s" => 400.0,
              "estimated_throughput_mb" => 55.0,
              "suppressed_reason" => "ground_station_unavailable",
              "source_window_id" => "window:leo_1:ground_station_access:equator_prime:stale",
              "station_calendar_entry_status" => "unavailable",
              "downlink_demand_sources" => ["contact_filter.required_downlink:dl_suppressed"],
              "downlink_completion_sources" => [
                "contact_filter.suppressed_candidate:dl_suppressed"
              ]
            },
            %{
              "id" => "dl_nested_filter",
              "type" => "planned_contact",
              "direction" => "downlink",
              "scenario_id" => "leo_1",
              "spacecraft_id" => "leo_1",
              "ground_station" => %{"id" => "polar_filter"},
              "start_s" => "700.0",
              "end_s" => "760.0",
              "throughput_model" => %{"required_downlink_mb" => "34.0"},
              "suppressed_reason" => "ground_station_unavailable",
              "source_window" => %{
                "id" => "window:leo_1:ground_station_access:polar_filter:stale"
              },
              "station_calendar_entry_status" => "unavailable"
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

    pressure_branch =
      branch(artifact, "derived_contact_filter_pressure_ground_station_unavailable_dl_suppressed")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             pressure_branch["assumptions"]["candidate_source"]

    assert %{
             "type" => "downlink_completion_gap",
             "scenario_id" => "leo_1",
             "spacecraft_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "source_activity_id" => "dl_suppressed",
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 55.0,
             "planned_downlink_mb" => planned_downlink_mb,
             "suppressed_reason" => "ground_station_unavailable",
             "source_window_id" => "window:leo_1:ground_station_access:equator_prime:stale",
             "station_calendar_entry_status" => "unavailable",
             "downlink_demand_sources" => ["contact_filter.required_downlink:dl_suppressed"],
             "downlink_completion_sources" => [
               "contact_filter.suppressed_candidate:dl_suppressed"
             ],
             "feedback_source" => "prior_plan.source_contact_filter_report",
             "feedback_scope" => "contact_filter",
             "trust_boundary" => "ops_contact_filter"
           } = List.first(pressure_branch["events"])

    assert planned_downlink_mb == 0.0

    nested_pressure_branch =
      branch(
        artifact,
        "derived_contact_filter_pressure_ground_station_unavailable_dl_nested_filter"
      )

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "polar_filter",
             "starts_at_s" => 700.0,
             "ends_at_s" => 760.0,
             "required_downlink_mb" => 34.0,
             "source_window_id" => "window:leo_1:ground_station_access:polar_filter:stale",
             "feedback_source" => "prior_plan.source_contact_filter_report",
             "feedback_scope" => "contact_filter",
             "trust_boundary" => "ops_contact_filter"
           } = List.first(nested_pressure_branch["events"])

    assert Enum.any?(
             pressure_branch["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "downlink" and
                 &1["ground_station_id"] == "equator_prime" and
                 get_in(&1, ["repair", "reason"]) == "downlink_completion_candidate_inserted" and
                 get_in(&1, ["feasibility", "source_activity_id"]) == "dl_suppressed" and
                 get_in(&1, ["feasibility", "feedback_scope"]) == "contact_filter" and
                 get_in(&1, ["feasibility", "trust_boundary"]) == "ops_contact_filter")
           )

    assert Enum.any?(
             pressure_branch["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and
                 &1["ground_station_id"] == "equator_prime" and
                 &1["reason"] =~ "55.0 MB")
           )

    assert_contact_filter_pressure_score_terms(pressure_branch, artifact)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from mission-state contact filter suppression pressure" do
    contact_filter_report = %{
      "schema_contract" => "contact_filter_report.v1",
      "model" => "thin_ground_network_availability_filter",
      "input_candidate_count" => 1,
      "kept_candidate_count" => 0,
      "suppressed_candidate_count" => 1,
      "provenance" => %{"trust_boundary" => "mission_contact_filter"},
      "suppressed_candidates" => [
        %{
          "id" => "dl_live_filter",
          "type" => "planned_contact",
          "direction" => "downlink",
          "scenario_id" => "leo_1",
          "spacecraft_id" => "leo_1",
          "ground_station" => %{"id" => "equator_prime"},
          "start_s" => "300.0",
          "end_s" => "360.0",
          "throughput_model" => %{
            "required_downlink_mb" => "48.0",
            "downlink_demand_sources" => [
              "mission_state.contact_filter.required_downlink:dl_live_filter"
            ]
          },
          "suppressed_reason" => "ground_station_unavailable",
          "source_window" => %{
            "id" => "window:leo_1:ground_station_access:equator_prime:live"
          },
          "station_calendar_entry_status" => "unavailable"
        }
      ]
    }

    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_contact_filter_report, contact_filter_report),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    pressure_branch =
      branch(
        artifact,
        "derived_contact_filter_pressure_ground_station_unavailable_dl_live_filter"
      )

    assert %{
             "type" => "candidate_refresh.v1",
             "scope" => "branch_generated",
             "source_report_input_paths" => ["mission_state.source_contact_filter_report"]
           } = pressure_branch["assumptions"]["candidate_source"]

    assert %{
             "type" => "downlink_completion_gap",
             "scenario_id" => "leo_1",
             "spacecraft_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "contact_id" => "dl_live_filter",
             "source_activity_id" => "dl_live_filter",
             "source_activity_ids" => ["dl_live_filter"],
             "starts_at_s" => 300.0,
             "ends_at_s" => 360.0,
             "required_downlink_mb" => 48.0,
             "planned_downlink_mb" => planned_downlink_mb,
             "suppressed_reason" => "ground_station_unavailable",
             "source_window_id" => "window:leo_1:ground_station_access:equator_prime:live",
             "station_calendar_entry_status" => "unavailable",
             "downlink_demand_sources" => [
               "mission_state.contact_filter.required_downlink:dl_live_filter"
             ],
             "feedback_source" => "mission_state.source_contact_filter_report",
             "feedback_scope" => "contact_filter",
             "trust_boundary" => "mission_contact_filter"
           } = List.first(pressure_branch["events"])

    assert planned_downlink_mb == 0.0

    assert Enum.any?(
             pressure_branch["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and
                 &1["ground_station_id"] == "equator_prime" and
                 &1["reason"] =~ "48.0 MB")
           )

    assert_contact_filter_pressure_score_terms(pressure_branch, artifact)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy replays source-named reports from mission-state result artifacts" do
    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_result_artifact, %{
            "schema_contract" => "result_artifact.v1",
            "artifact_type" => "mission_state_result_artifact",
            "study_id" => "live_source_named_reports",
            "provenance" => %{"trust_boundary" => "live_source_named_report_wrapper"},
            "source_contact_filter_report" => %{
              "schema_contract" => "contact_filter_report.v1",
              "model" => "thin_ground_network_availability_filter",
              "input_candidate_count" => 1,
              "kept_candidate_count" => 0,
              "suppressed_candidate_count" => 1,
              "suppressed_candidates" => [
                %{
                  "id" => "dl_source_named_filter",
                  "type" => "planned_contact",
                  "direction" => "downlink",
                  "scenario_id" => "leo_1",
                  "spacecraft_id" => "leo_1",
                  "ground_station_id" => "equator_prime",
                  "starts_at_s" => 300.0,
                  "ends_at_s" => 360.0,
                  "required_downlink_mb" => 44.0,
                  "suppressed_reason" => "ground_station_unavailable",
                  "source_window_id" =>
                    "window:leo_1:ground_station_access:equator_prime:source_named",
                  "station_calendar_entry_status" => "unavailable"
                }
              ]
            }
          }),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    pressure_branch =
      branch(
        artifact,
        "derived_contact_filter_pressure_ground_station_unavailable_dl_source_named_filter"
      )

    assert %{
             "type" => "downlink_completion_gap",
             "contact_id" => "dl_source_named_filter",
             "required_downlink_mb" => 44.0,
             "feedback_source" =>
               "mission_state.source_result_artifact.source_contact_filter_report",
             "feedback_scope" => "contact_filter",
             "trust_boundary" => "live_source_named_report_wrapper"
           } = List.first(pressure_branch["events"])

    assert "mission_state.source_result_artifact.source_contact_filter_report" in get_in(
             pressure_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives contact filter pressure from result artifact reports" do
    prior_plan =
      base_plan(%{
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "study_id" => "contact_filter_result_artifact",
          "provenance" => %{"trust_boundary" => "ops_result_artifact"},
          "contact_filter_report" => %{
            "schema_contract" => "contact_filter_report.v1",
            "model" => "thin_ground_network_availability_filter",
            "input_candidate_count" => 1,
            "kept_candidate_count" => 0,
            "suppressed_candidate_count" => 1,
            "suppressed_candidates" => [
              %{
                "id" => "dl_result_contact_filter",
                "type" => "downlink",
                "scenario_id" => "leo_1",
                "spacecraft_id" => "leo_1",
                "ground_station_id" => "equator_prime",
                "starts_at_s" => 0.0,
                "ends_at_s" => 400.0,
                "estimated_throughput_mb" => 55.0,
                "suppressed_reason" => "ground_station_unavailable",
                "source_window_id" => "window:leo_1:ground_station_access:equator_prime:stale",
                "station_calendar_entry_status" => "unavailable",
                "downlink_demand_sources" => [
                  "contact_filter.required_downlink:dl_result_contact_filter"
                ],
                "downlink_completion_sources" => [
                  "contact_filter.suppressed_candidate:dl_result_contact_filter"
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
      branch(
        artifact,
        "derived_contact_filter_pressure_ground_station_unavailable_dl_result_contact_filter"
      )

    assert %{
             "type" => "downlink_completion_gap",
             "scenario_id" => "leo_1",
             "spacecraft_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "source_activity_id" => "dl_result_contact_filter",
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 55.0,
             "suppressed_reason" => "ground_station_unavailable",
             "source_window_id" => "window:leo_1:ground_station_access:equator_prime:stale",
             "station_calendar_entry_status" => "unavailable",
             "downlink_demand_sources" => [
               "contact_filter.required_downlink:dl_result_contact_filter"
             ],
             "downlink_completion_sources" => [
               "contact_filter.suppressed_candidate:dl_result_contact_filter"
             ],
             "feedback_source" => "prior_plan.source_result_artifact.contact_filter_report",
             "feedback_scope" => "contact_filter",
             "trust_boundary" => "ops_result_artifact"
           } = List.first(pressure_branch["events"])

    assert Enum.any?(
             pressure_branch["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "downlink" and
                 &1["ground_station_id"] == "equator_prime" and
                 get_in(&1, ["feasibility", "feedback_scope"]) == "contact_filter" and
                 get_in(&1, ["feasibility", "trust_boundary"]) == "ops_result_artifact")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy keeps independent contact filter pressures for the same contact" do
    prior_plan =
      base_plan(%{
        "source_contact_filter_report" => %{
          "schema_contract" => "contact_filter_report.v1",
          "model" => "thin_ground_network_availability_filter",
          "input_candidate_count" => 1,
          "kept_candidate_count" => 0,
          "suppressed_candidate_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_source_contact_filter"},
          "suppressed_candidates" => [
            %{
              "id" => "dl_shared_filter",
              "type" => "downlink",
              "scenario_id" => "leo_1",
              "spacecraft_id" => "leo_1",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 320.0,
              "ends_at_s" => 380.0,
              "estimated_throughput_mb" => 44.0,
              "suppressed_reason" => "ground_station_unavailable",
              "source_window_id" => "window:filter:source"
            }
          ]
        },
        "contact_filter_report" => %{
          "schema_contract" => "contact_filter_report.v1",
          "model" => "thin_ground_network_availability_filter",
          "input_candidate_count" => 1,
          "kept_candidate_count" => 0,
          "suppressed_candidate_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_canonical_contact_filter"},
          "suppressed_candidates" => [
            %{
              "id" => "dl_shared_filter",
              "type" => "downlink",
              "scenario_id" => "leo_1",
              "spacecraft_id" => "leo_1",
              "ground_station_id" => "polar_aux",
              "starts_at_s" => 420.0,
              "ends_at_s" => 480.0,
              "estimated_throughput_mb" => 35.0,
              "suppressed_reason" => "ground_station_unavailable",
              "source_window_id" => "window:filter:canonical"
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

    refute "derived_contact_filter_pressure_ground_station_unavailable_dl_shared_filter" in branch_ids

    source_branch_id =
      Enum.find(
        branch_ids,
        &String.starts_with?(
          &1,
          "derived_contact_filter_pressure_ground_station_unavailable_dl_shared_filter_window:filter:source"
        )
      )

    canonical_branch_id =
      Enum.find(
        branch_ids,
        &String.starts_with?(
          &1,
          "derived_contact_filter_pressure_ground_station_unavailable_dl_shared_filter_window:filter:canonical"
        )
      )

    assert source_branch_id
    assert canonical_branch_id

    source_branch = branch(artifact, source_branch_id)
    canonical_branch = branch(artifact, canonical_branch_id)

    assert %{
             "type" => "downlink_completion_gap",
             "contact_id" => "dl_shared_filter",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 44.0,
             "source_window_id" => "window:filter:source",
             "feedback_source" => "prior_plan.source_contact_filter_report",
             "trust_boundary" => "ops_source_contact_filter"
           } = List.first(source_branch["events"])

    assert %{
             "type" => "downlink_completion_gap",
             "contact_id" => "dl_shared_filter",
             "ground_station_id" => "polar_aux",
             "required_downlink_mb" => 35.0,
             "source_window_id" => "window:filter:canonical",
             "feedback_source" => "prior_plan.contact_filter_report",
             "trust_boundary" => "ops_canonical_contact_filter"
           } = List.first(canonical_branch["events"])

    comparison_branch_ids =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.map(& &1["branch_id"])

    assert source_branch_id in comparison_branch_ids
    assert canonical_branch_id in comparison_branch_ids

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from prior link capacity pressure" do
    prior_plan =
      base_plan(%{
        "source_link_capacity_report" => %{
          "schema_contract" => "link_capacity_report.v1",
          "model" => "fixed_rate_downlink_capacity_summary",
          "source" => "campaign_repair.activities",
          "contact_count" => 1,
          "selected_contact_count" => 0,
          "required_downlink_mb" => 30.0,
          "selected_capacity_adjusted_throughput_mb" => 0.0,
          "selected_downlink_shortfall_mb" => 30.0,
          "downlink_requirement_status" => "shortfall",
          "rows" => [
            %{
              "ground_station_id" => "deep_space_net",
              "contact_count" => 1,
              "selected_contact_count" => 0,
              "required_downlink_mb" => 30.0,
              "selected_capacity_adjusted_throughput_mb" => 0.0,
              "selected_downlink_shortfall_mb" => 30.0,
              "downlink_requirement_status" => "shortfall",
              "actual_throughput_mb" => 12.0,
              "actual_downlink_completion_ratio" => 0.4,
              "actual_downlink_shortfall_mb" => 18.0,
              "actual_downlink_requirement_status" => "shortfall",
              "downlink_completion_source" =>
                "link_capacity.policy.required_downlink_mb_by_ground_station:deep_space_net",
              "required_downlink_contact_ids" => ["dl_source_unselected"],
              "trust_boundary" => "ops_source_link_capacity"
            },
            %{
              "station" => %{"id" => "polar_link"},
              "contact_count" => 1,
              "selected_contact_count" => 0,
              "required_downlink_mb" => 22.0,
              "selected_capacity_adjusted_throughput_mb" => 0.0,
              "selected_downlink_shortfall_mb" => 22.0,
              "downlink_requirement_status" => "shortfall",
              "start_s" => "800.0",
              "end_s" => "860.0",
              "required_downlink_contacts" => [
                %{
                  "contact_id" => "dl_nested_link",
                  "source_window" => %{
                    "id" => "window:leo_1:ground_station_access:polar_link:nested"
                  },
                  "activity_context" => %{
                    "downlink_demand_source" =>
                      "link_capacity.policy.required_downlink_mb_by_ground_station:polar_link"
                  }
                }
              ],
              "trust_boundary" => "ops_source_link_capacity"
            }
          ]
        },
        "link_capacity_report" => %{
          "schema_contract" => "link_capacity_report.v1",
          "model" => "fixed_rate_downlink_capacity_summary",
          "source" => "campaign_repair.activities",
          "contact_count" => 2,
          "selected_contact_count" => 1,
          "required_downlink_mb" => 120.0,
          "selected_capacity_adjusted_throughput_mb" => 70.0,
          "selected_downlink_shortfall_mb" => 50.0,
          "downlink_requirement_status" => "shortfall",
          "rows" => [
            %{
              "ground_station_id" => "equator_prime",
              "contact_count" => 2,
              "required_downlink_mb" => 120.0,
              "selected_capacity_adjusted_throughput_mb" => 70.0,
              "selected_downlink_shortfall_mb" => 50.0,
              "downlink_requirement_status" => "shortfall",
              "actual_throughput_mb" => 60.0,
              "actual_downlink_completion_ratio" => 0.5,
              "actual_downlink_shortfall_mb" => 60.0,
              "actual_downlink_requirement_status" => "shortfall",
              "source_window_id" => "window:leo_1:ground_station_access:equator_prime:capacity",
              "downlink_completion_source" =>
                "link_capacity.policy.required_downlink_mb_by_ground_station:equator_prime",
              "downlink_demand_sources" => [
                "link_capacity.contact.required_downlink_mb:dl_unselected",
                "link_capacity.policy.required_downlink_mb_by_ground_station:equator_prime"
              ],
              "downlink_completion_sources" => [
                "link_capacity.contact.required_downlink_mb:dl_unselected",
                "link_capacity.policy.required_downlink_mb_by_ground_station:equator_prime"
              ],
              "selected_contacts" => [%{"id" => "dl_selected"}],
              "required_downlink_contact_ids" => ["dl_selected", "dl_unselected"],
              "source_contact" => %{"id" => "dl_source_object"},
              "trust_boundary" => "ops_link_capacity"
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

    pressure_branch = branch(artifact, "derived_link_capacity_pressure_equator_prime")

    source_pressure_branch = branch(artifact, "derived_link_capacity_pressure_deep_space_net")

    nested_source_pressure_branch = branch(artifact, "derived_link_capacity_pressure_polar_link")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "deep_space_net",
             "required_downlink_mb" => 30.0,
             "actual_downlink_completion_ratio" => 0.4,
             "source_activity_ids" => ["dl_source_unselected"],
             "feedback_source" => "prior_plan.source_link_capacity_report",
             "feedback_scope" => "link_capacity",
             "trust_boundary" => "ops_source_link_capacity"
           } = List.first(source_pressure_branch["events"])

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "polar_link",
             "starts_at_s" => 800.0,
             "ends_at_s" => 860.0,
             "required_downlink_mb" => 22.0,
             "source_activity_ids" => ["dl_nested_link"],
             "source_window_id" => "window:leo_1:ground_station_access:polar_link:nested",
             "source_window_ids" => ["window:leo_1:ground_station_access:polar_link:nested"],
             "downlink_demand_sources" => [
               "link_capacity.policy.required_downlink_mb_by_ground_station:polar_link"
             ],
             "feedback_source" => "prior_plan.source_link_capacity_report",
             "feedback_scope" => "link_capacity",
             "trust_boundary" => "ops_source_link_capacity"
           } = List.first(nested_source_pressure_branch["events"])

    assert Enum.any?(
             pressure_branch["candidate_plan"]["strategic_additions"],
             &(get_in(&1, ["feasibility", "source_window_id"]) ==
                 "window:leo_1:ground_station_access:equator_prime:capacity" and
                 get_in(&1, ["feasibility", "source_window_ids"]) == [
                   "window:leo_1:ground_station_access:equator_prime:capacity"
                 ])
           )

    assert Enum.any?(
             nested_source_pressure_branch["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and
                 &1["ground_station_id"] == "polar_link" and
                 &1["source_window_ids"] == [
                   "window:leo_1:ground_station_access:polar_link:nested"
                 ])
           )

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             pressure_branch["assumptions"]["candidate_source"]

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 50.0,
             "planned_contacts" => 1,
             "selected_capacity_adjusted_throughput_mb" => 70.0,
             "selected_downlink_shortfall_mb" => 50.0,
             "downlink_requirement_status" => "shortfall",
             "actual_downlink_completion_ratio" => 0.5,
             "source_activity_ids" => ["dl_selected", "dl_source_object", "dl_unselected"],
             "source_window_id" => "window:leo_1:ground_station_access:equator_prime:capacity",
             "source_window_ids" => [
               "window:leo_1:ground_station_access:equator_prime:capacity"
             ],
             "downlink_completion_source" =>
               "link_capacity.policy.required_downlink_mb_by_ground_station:equator_prime",
             "downlink_demand_sources" => [
               "link_capacity.contact.required_downlink_mb:dl_unselected",
               "link_capacity.policy.required_downlink_mb_by_ground_station:equator_prime"
             ],
             "downlink_completion_sources" => [
               "link_capacity.contact.required_downlink_mb:dl_unselected",
               "link_capacity.policy.required_downlink_mb_by_ground_station:equator_prime"
             ],
             "feedback_source" => "prior_plan.link_capacity_report",
             "feedback_scope" => "link_capacity",
             "trust_boundary" => "ops_link_capacity"
           } = List.first(pressure_branch["events"])

    assert List.first(pressure_branch["events"])["planned_downlink_mb"] == 0.0

    pressure_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_link_capacity_pressure_equator_prime"))

    source_pressure_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_link_capacity_pressure_deep_space_net"))

    assert pressure_row["branch_actual_downlink_completion_ratio"] == 0.5
    assert source_pressure_row["branch_actual_downlink_completion_ratio"] == 0.4

    assert Enum.any?(
             pressure_branch["repair_result"]["source_candidate_activities"],
             &(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime" and
                 get_in(&1, ["throughput_model", "required_downlink_mb"]) == 50.0 and
                 get_in(&1, ["throughput_model", "downlink_completion_sources"]) == [
                   "link_capacity.contact.required_downlink_mb:dl_unselected",
                   "link_capacity.policy.required_downlink_mb_by_ground_station:equator_prime"
                 ] and
                 get_in(&1, ["activity_context", "downlink_completion_sources"]) == [
                   "link_capacity.contact.required_downlink_mb:dl_unselected",
                   "link_capacity.policy.required_downlink_mb_by_ground_station:equator_prime"
                 ])
           )

    assert Enum.any?(
             pressure_branch["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and
                 &1["ground_station_id"] == "equator_prime" and
                 &1["reason"] =~ "50.0 MB")
           )

    assert_link_capacity_pressure_score_terms(pressure_branch, artifact)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from mission-state link capacity pressure" do
    link_capacity_report = %{
      "schema_contract" => "link_capacity_report.v1",
      "model" => "fixed_rate_downlink_capacity_summary",
      "source" => "mission_state.downlink_capacity",
      "contact_count" => 1,
      "selected_contact_count" => 0,
      "required_downlink_mb" => 30.0,
      "selected_capacity_adjusted_throughput_mb" => 0.0,
      "selected_downlink_shortfall_mb" => 30.0,
      "downlink_requirement_status" => "shortfall",
      "provenance" => %{"trust_boundary" => "mission_link_capacity_review"},
      "rows" => [
        %{
          "station" => %{"id" => "equator_prime"},
          "contact_count" => 1,
          "selected_contact_count" => 0,
          "required_downlink_mb" => 22.0,
          "selected_capacity_adjusted_throughput_mb" => 0.0,
          "selected_downlink_shortfall_mb" => 22.0,
          "downlink_requirement_status" => "shortfall",
          "start_s" => "300.0",
          "end_s" => "360.0",
          "required_downlink_contacts" => [
            %{
              "contact_id" => "dl_nested_link",
              "source_window" => %{
                "id" => "window:leo_1:ground_station_access:equator_prime:nested"
              },
              "activity_context" => %{
                "downlink_demand_source" =>
                  "link_capacity.policy.required_downlink_mb_by_ground_station:equator_prime"
              }
            }
          ],
          "trust_boundary" => "mission_link_capacity_row"
        }
      ]
    }

    artifact =
      strategy(
        base_plan(%{
          "candidate_activities" => [
            refreshed_downlink("dl_equator_prime_recovery", 300.0, 360.0)
            |> Map.put("ground_station_id", "equator_prime")
            |> Map.put(
              "source_window_id",
              "window:leo_1:ground_station_access:equator_prime:nested"
            )
            |> put_in(
              ["source_window", "id"],
              "window:leo_1:ground_station_access:equator_prime:nested"
            )
          ]
        }),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.update!(:ground_stations, fn stations ->
            [
              %{
                id: "equator_prime",
                latitude_deg: 0.0,
                longitude_deg: 0.0,
                minimum_elevation_deg: 5.0
              }
              | stations
            ]
          end)
          |> Map.put(:source_link_capacity_report, link_capacity_report),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    pressure_branch = branch(artifact, "derived_link_capacity_pressure_equator_prime")

    assert %{
             "type" => "candidate_refresh.v1",
             "scope" => "branch_generated",
             "source_report_input_paths" => ["mission_state.source_link_capacity_report"]
           } = pressure_branch["assumptions"]["candidate_source"]

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "starts_at_s" => 300.0,
             "ends_at_s" => 360.0,
             "required_downlink_mb" => 22.0,
             "planned_contacts" => 0,
             "selected_downlink_shortfall_mb" => 22.0,
             "downlink_requirement_status" => "shortfall",
             "source_activity_ids" => ["dl_nested_link"],
             "source_window_id" => "window:leo_1:ground_station_access:equator_prime:nested",
             "source_window_ids" => [
               "window:leo_1:ground_station_access:equator_prime:nested"
             ],
             "downlink_demand_sources" => [
               "link_capacity.policy.required_downlink_mb_by_ground_station:equator_prime"
             ],
             "feedback_source" => "mission_state.source_link_capacity_report",
             "feedback_scope" => "link_capacity",
             "trust_boundary" => "mission_link_capacity_row"
           } = List.first(pressure_branch["events"])

    assert List.first(pressure_branch["events"])["selected_capacity_adjusted_throughput_mb"] ==
             0.0

    assert Enum.any?(
             pressure_branch["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and
                 &1["ground_station_id"] == "equator_prime" and
                 &1["feedback_source"] == "mission_state.source_link_capacity_report" and
                 &1["source_window_ids"] == [
                   "window:leo_1:ground_station_access:equator_prime:nested"
                 ])
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives mission-state communications pressure from result artifact wrappers" do
    source_result_artifact = %{
      "schema_contract" => "result_artifact.v1",
      "study_id" => "live_comms_result_artifact",
      "metadata" => %{"trust_boundary" => "live_comms_result_review"},
      "contact_filter_report" => %{
        "schema_contract" => "contact_filter_report.v1",
        "model" => "thin_ground_network_availability_filter",
        "input_candidate_count" => 1,
        "kept_candidate_count" => 0,
        "suppressed_candidate_count" => 1,
        "suppressed_candidates" => [
          %{
            "id" => "dl_live_result_contact_filter",
            "type" => "downlink",
            "scenario_id" => "leo_1",
            "spacecraft_id" => "leo_1",
            "ground_station_id" => "equator_prime",
            "starts_at_s" => 320.0,
            "ends_at_s" => 380.0,
            "estimated_throughput_mb" => 44.0,
            "suppressed_reason" => "ground_station_unavailable",
            "source_window_id" => "window:live:result:contact-filter"
          }
        ]
      },
      "link_capacity_report" => %{
        "schema_contract" => "link_capacity_report.v1",
        "model" => "fixed_rate_downlink_capacity_summary",
        "source" => "mission_state.downlink_capacity",
        "contact_count" => 1,
        "selected_contact_count" => 0,
        "required_downlink_mb" => 30.0,
        "selected_capacity_adjusted_throughput_mb" => 0.0,
        "selected_downlink_shortfall_mb" => 30.0,
        "downlink_requirement_status" => "shortfall",
        "rows" => [
          %{
            "ground_station_id" => "deep_space_net",
            "contact_count" => 1,
            "selected_contact_count" => 0,
            "required_downlink_mb" => 30.0,
            "selected_capacity_adjusted_throughput_mb" => 0.0,
            "selected_downlink_shortfall_mb" => 30.0,
            "downlink_requirement_status" => "shortfall",
            "downlink_completion_source" =>
              "link_capacity.policy.required_downlink_mb_by_ground_station:deep_space_net",
            "required_downlink_contact_ids" => ["dl_live_result_link"]
          }
        ]
      }
    }

    artifact =
      strategy(
        base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_result_artifact, source_result_artifact),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    contact_branch =
      branch(
        artifact,
        "derived_contact_filter_pressure_ground_station_unavailable_dl_live_result_contact_filter"
      )

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 44.0,
             "source_activity_id" => "dl_live_result_contact_filter",
             "source_window_id" => "window:live:result:contact-filter",
             "feedback_source" => "mission_state.source_result_artifact.contact_filter_report",
             "feedback_scope" => "contact_filter",
             "trust_boundary" => "live_comms_result_review"
           } = List.first(contact_branch["events"])

    assert "mission_state.source_result_artifact.contact_filter_report" in get_in(
             contact_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    link_branch = branch(artifact, "derived_link_capacity_pressure_deep_space_net")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "deep_space_net",
             "required_downlink_mb" => 30.0,
             "source_activity_ids" => ["dl_live_result_link"],
             "feedback_source" => "mission_state.source_result_artifact.link_capacity_report",
             "feedback_scope" => "link_capacity",
             "trust_boundary" => "live_comms_result_review"
           } = List.first(link_branch["events"])

    assert "mission_state.source_result_artifact.link_capacity_report" in get_in(
             link_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives link capacity pressure from result artifact reports" do
    prior_plan =
      base_plan(%{
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "study_id" => "link_capacity_result_artifact",
          "provenance" => %{"trust_boundary" => "ops_result_artifact"},
          "link_capacity_report" => %{
            "schema_contract" => "link_capacity_report.v1",
            "model" => "fixed_rate_downlink_capacity_summary",
            "source" => "campaign_repair.activities",
            "contact_count" => 1,
            "selected_contact_count" => 0,
            "required_downlink_mb" => 30.0,
            "selected_capacity_adjusted_throughput_mb" => 0.0,
            "selected_downlink_shortfall_mb" => 30.0,
            "downlink_requirement_status" => "shortfall",
            "rows" => [
              %{
                "ground_station_id" => "deep_space_net",
                "contact_count" => 1,
                "selected_contact_count" => 0,
                "required_downlink_mb" => 30.0,
                "selected_capacity_adjusted_throughput_mb" => 0.0,
                "selected_downlink_shortfall_mb" => 30.0,
                "downlink_requirement_status" => "shortfall",
                "downlink_completion_source" =>
                  "link_capacity.policy.required_downlink_mb_by_ground_station:deep_space_net",
                "required_downlink_contact_ids" => ["dl_result_link"]
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

    pressure_branch = branch(artifact, "derived_link_capacity_pressure_deep_space_net")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "deep_space_net",
             "required_downlink_mb" => 30.0,
             "source_activity_ids" => ["dl_result_link"],
             "feedback_source" => "prior_plan.source_result_artifact.link_capacity_report",
             "feedback_scope" => "link_capacity",
             "trust_boundary" => "ops_result_artifact"
           } = List.first(pressure_branch["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             pressure_branch["assumptions"]["candidate_source"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy keeps independent link capacity shortfalls for the same station" do
    prior_plan =
      base_plan(%{
        "source_link_capacity_report" => %{
          "schema_contract" => "link_capacity_report.v1",
          "model" => "fixed_rate_downlink_capacity_summary",
          "source" => "campaign_repair.activities",
          "contact_count" => 2,
          "selected_contact_count" => 0,
          "required_downlink_mb" => 70.0,
          "selected_capacity_adjusted_throughput_mb" => 0.0,
          "selected_downlink_shortfall_mb" => 70.0,
          "downlink_requirement_status" => "shortfall",
          "rows" => [
            %{
              "ground_station_id" => "equator_prime",
              "contact_count" => 1,
              "selected_contact_count" => 0,
              "required_downlink_mb" => 30.0,
              "selected_capacity_adjusted_throughput_mb" => 0.0,
              "selected_downlink_shortfall_mb" => 30.0,
              "downlink_requirement_status" => "shortfall",
              "required_downlink_contact_ids" => ["dl_alpha"],
              "downlink_completion_source" => "link_capacity.required_downlink:alpha",
              "trust_boundary" => "ops_link_capacity"
            },
            %{
              "ground_station_id" => "equator_prime",
              "contact_count" => 1,
              "selected_contact_count" => 0,
              "required_downlink_mb" => 40.0,
              "selected_capacity_adjusted_throughput_mb" => 0.0,
              "selected_downlink_shortfall_mb" => 40.0,
              "downlink_requirement_status" => "shortfall",
              "required_downlink_contact_ids" => ["dl_beta"],
              "downlink_completion_source" => "link_capacity.required_downlink:beta",
              "trust_boundary" => "ops_link_capacity"
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

    alpha_branch = branch(artifact, "derived_link_capacity_pressure_equator_prime_dl_alpha")
    beta_branch = branch(artifact, "derived_link_capacity_pressure_equator_prime_dl_beta")

    refute branch(artifact, "derived_link_capacity_pressure_equator_prime")
    assert alpha_branch
    assert beta_branch

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 30.0,
             "source_activity_ids" => ["dl_alpha"],
             "feedback_source" => "prior_plan.source_link_capacity_report",
             "feedback_scope" => "link_capacity",
             "trust_boundary" => "ops_link_capacity"
           } = List.first(alpha_branch["events"])

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 40.0,
             "source_activity_ids" => ["dl_beta"],
             "feedback_source" => "prior_plan.source_link_capacity_report",
             "feedback_scope" => "link_capacity",
             "trust_boundary" => "ops_link_capacity"
           } = List.first(beta_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp assert_link_capacity_pressure_score_terms(branch, artifact) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    link_capacity_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] == "downlink_completion_gap" and &1["feedback_scope"] == "link_capacity")
      )

    assert link_capacity_pressure_count > 0

    assert branch["score_terms"]["link_capacity_pressure_penalty"] ==
             -link_capacity_pressure_count * risk_weight

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - link_capacity_pressure_count) * risk_weight

    assert "link_capacity_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "link_capacity_pressure_penalty" and &1["value"] < 0.0)
           )
  end

  defp assert_contact_filter_pressure_score_terms(branch, artifact) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    contact_filter_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] == "downlink_completion_gap" and &1["feedback_scope"] == "contact_filter")
      )

    assert contact_filter_pressure_count > 0

    assert branch["score_terms"]["contact_filter_pressure_penalty"] ==
             -contact_filter_pressure_count * risk_weight

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - contact_filter_pressure_count) *
               risk_weight

    assert "contact_filter_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "contact_filter_pressure_penalty" and &1["value"] < 0.0)
           )
  end

  defp assert_resource_filter_pressure_score_terms(branch, artifact) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    resource_filter_pressure_count =
      Enum.count(branch["risk_indicators"], &(&1["feedback_scope"] == "resource_filter"))

    assert resource_filter_pressure_count > 0

    assert branch["score_terms"]["resource_filter_pressure_penalty"] ==
             -resource_filter_pressure_count * risk_weight

    assert branch["score_terms"]["resource_availability_pressure_penalty"] == 0.0
    assert branch["score_terms"]["resource_margin_pressure_penalty"] == 0.0

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - resource_filter_pressure_count) * risk_weight

    assert "resource_filter_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "resource_filter_pressure_penalty" and &1["value"] < 0.0)
           )
  end
end
