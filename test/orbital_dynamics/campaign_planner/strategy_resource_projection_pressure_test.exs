Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyResourceProjectionPressureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives branch refresh from prior resource projection pressure" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> put_in(
        [:candidate_refresh_defaults, :resource_filter_policy],
        %{
          min_storage_margin: 0.2,
          min_power_margin: 0.2,
          min_downlink_margin: 0.75
        }
      )

    prior_plan =
      base_plan(%{
        "activities" => [
          observe("obs_pressure", "leo_1", "target_a", 100.0, 160.0, 20.0)
          |> Map.put("estimated_storage_mb", 35.0),
          observe(
            "obs_canonical_pressure",
            "leo_projection_canonical",
            "target_a",
            180.0,
            240.0,
            15.0
          )
          |> Map.put("estimated_storage_mb", 12.0),
          downlink("dl_pressure", 500.0, 560.0)
          |> Map.put("estimated_throughput_mb", 60.0)
          |> Map.put("estimated_energy_used_wh", 15.0)
        ],
        "source_resource_projection_report" => %{
          "schema_contract" => "resource_projection_report.v1",
          "provenance" => %{"trust_boundary" => "ops_resource_projection"},
          "projected_resources" => [
            %{
              "spacecraft_id" => "leo_1",
              "resource_source_quality" => "operator_supplied",
              "resource_trust_boundary_status" => "declared",
              "projected_storage_overflow_mb" => 25.0,
              "projected_downlink_shortfall_mb" => 10.0,
              "projected_battery_overuse_wh" => 5.0,
              "activity_resource_flow" => [
                %{
                  "activity_id" => "obs_pressure",
                  "activity_type" => "observe",
                  "starts_at_s" => 100.0,
                  "ends_at_s" => 160.0,
                  "storage_overflow_mb" => 25.0,
                  "activity_context" => %{
                    "downlink_completion_sources" => [
                      "resource_projection.storage_overflow:obs_pressure"
                    ]
                  }
                },
                %{
                  "activity_id" => "dl_pressure",
                  "activity_type" => "downlink",
                  "station" => %{"id" => "equator_prime"},
                  "starts_at_s" => 500.0,
                  "ends_at_s" => 560.0,
                  "downlink_shortfall_mb" => 10.0,
                  "throughput_model" => %{"selected_downlink_mb" => 60.0},
                  "battery_overuse_wh" => 5.0
                }
              ]
            },
            %{
              "spacecraft_id" => "leo_payload_pressure",
              "resource_source_quality" => "operator_supplied",
              "resource_trust_boundary_status" => "declared",
              "payload_available" => false,
              "antenna_available" => false,
              "resource_pressure_status" => "resource_availability_pressure",
              "resource_pressure_types" => [
                "antenna_unavailable",
                "payload_unavailable",
                "spacecraft_degraded_payload_unavailable"
              ],
              "activity_resource_flow" => [
                %{
                  "activity_id" => "obs_payload_pressure",
                  "activity_type" => "observe",
                  "starts_at_s" => 210.0,
                  "resource_effect_status" => "ignored",
                  "resource_effect_reason" => "payload_unavailable"
                },
                %{
                  "activity_id" => "obs_degraded_payload_pressure",
                  "activity_type" => "observe",
                  "starts_at_s" => 225.0,
                  "resource_effect_status" => "ignored",
                  "resource_effect_reason" => "spacecraft_degraded_payload_unavailable"
                },
                %{
                  "activity_id" => "dl_antenna_pressure",
                  "activity_type" => "planned_contact",
                  "direction" => "downlink",
                  "ground_station_id" => "equator_prime",
                  "starts_at_s" => 240.0,
                  "resource_effect_status" => "ignored",
                  "resource_effect_reason" => "antenna_unavailable"
                }
              ]
            },
            %{
              "spacecraft_id" => "leo_thermal_pressure",
              "resource_source_quality" => "operator_supplied",
              "resource_trust_boundary_status" => "declared",
              "thermal_margin_c" => -1.5,
              "resource_pressure_status" => "resource_pressure",
              "resource_pressure_types" => ["thermal_margin_below_limit"]
            },
            %{
              "spacecraft_id" => "leo_activity_type_pressure",
              "resource_source_quality" => "operator_supplied",
              "resource_trust_boundary_status" => "declared",
              "resource_pressure_status" => "resource_availability_pressure",
              "resource_pressure_types" => [
                "activity_type_incompatible_with_resource_summary",
                "activity_type_suppressed_by_resource_summary"
              ],
              "suppressed_activity_types" => ["observe"],
              "incompatible_activity_types" => ["downlink"],
              "activity_resource_flow" => [
                %{
                  "activity_id" => "obs_activity_type_pressure",
                  "activity_type" => "observe",
                  "starts_at_s" => 260.0,
                  "resource_effect_status" => "ignored",
                  "resource_effect_reason" => "activity_type_suppressed_by_resource_summary"
                },
                %{
                  "activity_id" => "dl_activity_type_pressure",
                  "activity_type" => "downlink",
                  "starts_at_s" => 300.0,
                  "resource_effect_status" => "ignored",
                  "resource_effect_reason" => "activity_type_incompatible_with_resource_summary"
                }
              ]
            }
          ]
        },
        "resource_projection_report" => %{
          "schema_contract" => "resource_projection_report.v1",
          "trust_boundary" => "canonical_resource_projection",
          "projected_resources" => [
            %{
              "scenario_id" => "leo_projection_canonical",
              "resource_source_quality" => "repaired_plan",
              "resource_trust_boundary_status" => "declared",
              "projected_storage_overflow_mb" => 12.0,
              "activity_resource_flow" => [
                %{
                  "activity_id" => "obs_canonical_pressure",
                  "activity_type" => "observe",
                  "starts_at_s" => 180.0,
                  "ends_at_s" => 240.0,
                  "storage_overflow_mb" => 12.0,
                  "activity_context" => %{
                    "downlink_completion_source" =>
                      "resource_projection.storage_overflow:obs_canonical_pressure"
                  }
                }
              ]
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    pressure_branch = branch(artifact, "derived_projected_resource_pressure_leo_1")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             pressure_branch["assumptions"]["candidate_source"]

    canonical_pressure_branch =
      branch(artifact, "derived_projected_resource_pressure_leo_projection_canonical")

    availability_pressure_branch =
      branch(artifact, "derived_projected_resource_pressure_leo_payload_pressure")

    thermal_pressure_branch =
      branch(artifact, "derived_projected_resource_pressure_leo_thermal_pressure")

    activity_type_pressure_branch =
      branch(artifact, "derived_projected_resource_pressure_leo_activity_type_pressure")

    assert %{
             "type" => "downlink_completion_gap",
             "scenario_id" => "leo_projection_canonical",
             "required_downlink_mb" => 12.0,
             "source_activity_id" => "obs_canonical_pressure",
             "source_activity_ids" => ["obs_canonical_pressure"],
             "feedback_source" => "prior_plan.resource_projection_report",
             "trust_boundary" => "canonical_resource_projection"
           } =
             canonical_pressure_branch["events"]
             |> Enum.find(
               &("projected_storage_overflow" in Map.get(&1, "derivation_reasons", []))
             )

    assert storage_gap =
             %{
               "type" => "downlink_completion_gap",
               "required_downlink_mb" => 25.0,
               "source_activity_id" => "obs_pressure",
               "source_activity_ids" => ["obs_pressure"],
               "downlink_completion_sources" => [
                 "resource_projection.storage_overflow:obs_pressure"
               ],
               "downlink_demand_sources" => [
                 "resource_projection.storage_overflow:obs_pressure"
               ],
               "derivation_reasons" => ["projected_storage_overflow"],
               "feedback_source" => "prior_plan.source_resource_projection_report",
               "trust_boundary" => "ops_resource_projection"
             } =
             Enum.find(
               pressure_branch["events"],
               &("projected_storage_overflow" in Map.get(&1, "derivation_reasons", []))
             )

    assert storage_gap["planned_downlink_mb"] == 0.0

    assert %{
             "type" => "downlink_completion_gap",
             "required_downlink_mb" => 70.0,
             "planned_downlink_mb" => 60.0,
             "ground_station_id" => "equator_prime",
             "source_activity_id" => "dl_pressure",
             "source_activity_ids" => ["dl_pressure"],
             "downlink_completion_sources" => [
               "resource_projection.projected_downlink_shortfall:dl_pressure"
             ],
             "downlink_demand_sources" => [
               "resource_projection.projected_downlink_shortfall:dl_pressure"
             ],
             "derivation_reasons" => ["projected_downlink_shortfall"]
           } =
             Enum.find(
               pressure_branch["events"],
               &("projected_downlink_shortfall" in Map.get(&1, "derivation_reasons", []) and
                   &1["type"] == "downlink_completion_gap")
             )

    assert power_pressure =
             %{
               "type" => "resource_margin_pressure",
               "resource_field" => "power_margin",
               "projected_battery_overuse_wh" => 5.0,
               "source_activity_id" => "dl_pressure",
               "source_quality" => "operator_supplied"
             } =
             Enum.find(
               pressure_branch["events"],
               &(&1["type"] == "resource_margin_pressure" and
                   &1["resource_field"] == "power_margin")
             )

    assert power_pressure["power_margin"] == 0.0

    assert %{
             "type" => "resource_availability_constraint",
             "spacecraft_id" => "leo_payload_pressure",
             "resource_field" => "payload_available",
             "payload_available" => false,
             "available" => false,
             "source_quality" => "operator_supplied",
             "source_activity_id" => "obs_payload_pressure",
             "source_activity_ids" => ["obs_payload_pressure"],
             "derivation_reasons" => ["projected_payload_unavailable"],
             "feedback_source" => "prior_plan.source_resource_projection_report",
             "trust_boundary" => "ops_resource_projection"
           } =
             Enum.find(
               availability_pressure_branch["events"],
               &(&1["resource_field"] == "payload_available")
             )

    assert %{
             "type" => "resource_availability_constraint",
             "resource_field" => "antenna_available",
             "antenna_available" => false,
             "source_activity_id" => "dl_antenna_pressure",
             "source_activity_ids" => ["dl_antenna_pressure"],
             "derivation_reasons" => ["projected_antenna_unavailable"]
           } =
             Enum.find(
               availability_pressure_branch["events"],
               &(&1["resource_field"] == "antenna_available")
             )

    assert thermal_pressure =
             %{
               "type" => "resource_margin_pressure",
               "spacecraft_id" => "leo_thermal_pressure",
               "resource_field" => "thermal_margin_c",
               "thermal_margin_c" => -1.5,
               "derivation_reasons" => ["projected_thermal_margin_below_limit"],
               "feedback_source" => "prior_plan.source_resource_projection_report",
               "trust_boundary" => "ops_resource_projection",
               "source_quality" => "operator_supplied"
             } =
             Enum.find(
               thermal_pressure_branch["events"],
               &(&1["type"] == "resource_margin_pressure" and
                   &1["resource_field"] == "thermal_margin_c")
             )

    assert thermal_pressure["thermal_margin_c_threshold"] == 0.0

    assert %{
             "type" => "degraded_spacecraft",
             "spacecraft_id" => "leo_activity_type_pressure",
             "mode" => "resource_activity_type_constraint",
             "incompatible_activity_types" => ["downlink", "observe"],
             "source_quality" => "operator_supplied",
             "source_activity_id" => "obs_activity_type_pressure",
             "source_activity_ids" => ["obs_activity_type_pressure"],
             "derivation_reasons" => [
               "projected_activity_type_suppressed_by_resource_summary"
             ],
             "feedback_source" => "prior_plan.source_resource_projection_report",
             "trust_boundary" => "ops_resource_projection"
           } =
             Enum.find(
               activity_type_pressure_branch["events"],
               &("projected_activity_type_suppressed_by_resource_summary" in Map.get(
                   &1,
                   "derivation_reasons",
                   []
                 ))
             )

    assert %{
             "type" => "degraded_spacecraft",
             "source_activity_id" => "dl_activity_type_pressure",
             "source_activity_ids" => ["dl_activity_type_pressure"],
             "derivation_reasons" => [
               "projected_activity_type_incompatible_with_resource_summary"
             ]
           } =
             Enum.find(
               activity_type_pressure_branch["events"],
               &("projected_activity_type_incompatible_with_resource_summary" in Map.get(
                   &1,
                   "derivation_reasons",
                   []
                 ))
             )

    assert Enum.any?(
             availability_pressure_branch["risk_indicators"],
             &(&1["type"] == "payload_unavailable" and
                 &1["spacecraft_id"] == "leo_payload_pressure" and
                 &1["resource_availability_value"] == false and
                 &1["payload_available"] == false and
                 &1["source_quality"] == "operator_supplied")
           )

    assert Enum.any?(
             availability_pressure_branch["risk_indicators"],
             &(&1["type"] == "spacecraft_degraded_payload_unavailable" and
                 &1["spacecraft_id"] == "leo_payload_pressure")
           )

    assert Enum.any?(
             thermal_pressure_branch["risk_indicators"],
             &(&1["type"] == "thermal_margin_c_low" and &1["value"] == -1.5)
           )

    assert Enum.any?(
             thermal_pressure_branch["risk_indicators"],
             &(&1["type"] == "thermal_margin_below_limit" and
                 &1["thermal_margin_c"] == -1.5)
           )

    assert Enum.any?(
             activity_type_pressure_branch["risk_indicators"],
             &(&1["type"] == "activity_type_suppressed_by_resource_summary" and
                 &1["mode"] == "resource_activity_type_constraint" and
                 &1["incompatible_activity_types"] == ["downlink", "observe"] and
                 &1["source_quality"] == "operator_supplied" and
                 &1["derivation_reasons"] == [
                   "projected_activity_type_suppressed_by_resource_summary"
                 ])
           )

    assert Enum.any?(
             pressure_branch["risk_indicators"],
             &(&1["type"] == "power_margin_low" and
                 &1["resource_margin_value"] == 0.0 and
                 &1["resource_margin_threshold"] == 0.2 and
                 &1["projected_battery_overuse_wh"] == 5.0)
           )

    assert Enum.any?(
             activity_type_pressure_branch["risk_indicators"],
             &(&1["type"] == "activity_type_incompatible_with_resource_summary" and
                 &1["source_activity_id"] == "dl_activity_type_pressure")
           )

    assert Enum.any?(
             pressure_branch["repair_result"]["source_resource_summaries"],
             &(&1["spacecraft_id"] == "leo_1" and &1["storage_margin"] == 0.0 and
                 &1["downlink_margin"] == 0.0 and &1["power_margin"] == 0.0 and
                 get_in(&1, ["provenance", "trust_boundary"]) == "ops_resource_projection")
           )

    assert Enum.any?(
             pressure_branch["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and
                 &1["reason"] =~ "planned downlink volume 0.0 MB below required 25.0 MB")
           )

    pressure_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_projected_resource_pressure_leo_1"))

    assert pressure_row["storage_margin"] == 0.0
    assert pressure_row["downlink_capacity_margin"] == 0.0
    assert pressure_row["power_margin"] == 0.0
    assert "storage_margin_low" in pressure_row["resource_risk_types"]
    assert "downlink_capacity_low" in pressure_row["resource_risk_types"]
    assert "power_margin_low" in pressure_row["resource_risk_types"]

    thermal_pressure_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] == "derived_projected_resource_pressure_leo_thermal_pressure")
      )

    assert thermal_pressure_row["thermal_margin_c"] == -1.5
    assert "thermal_margin_low" in thermal_pressure_row["resource_risk_types"]

    activity_type_pressure_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] ==
            "derived_projected_resource_pressure_leo_activity_type_pressure")
      )

    assert "activity_type_suppressed_by_resource_summary" in activity_type_pressure_row[
             "risk_types"
           ]

    assert "activity_type_incompatible_with_resource_summary" in activity_type_pressure_row[
             "high_risk_types"
           ]

    assert_resource_availability_pressure_score_terms(availability_pressure_branch, artifact)
    assert_resource_availability_pressure_score_terms(activity_type_pressure_branch, artifact)
    assert_resource_margin_pressure_score_terms(thermal_pressure_branch, artifact)
    assert_resource_projection_pressure_score_terms(pressure_branch, artifact)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from mission-state resource projection pressure" do
    resource_projection_report = %{
      "schema_contract" => "resource_projection_report.v1",
      "provenance" => %{"trust_boundary" => "live_resource_projection"},
      "projected_resources" => [
        %{
          "spacecraft_id" => "leo_live_projection",
          "resource_source_quality" => "operator_supplied",
          "resource_trust_boundary_status" => "declared",
          "projected_storage_overflow_mb" => 18.0,
          "activity_resource_flow" => [
            %{
              "activity_id" => "obs_live_projection",
              "activity_type" => "observe",
              "starts_at_s" => 100.0,
              "ends_at_s" => 160.0,
              "storage_overflow_mb" => 18.0,
              "activity_context" => %{
                "downlink_completion_source" =>
                  "resource_projection.storage_overflow:obs_live_projection"
              }
            }
          ]
        }
      ]
    }

    artifact =
      strategy(
        base_plan(%{
          "activities" => [
            observe("obs_live_projection", "leo_live_projection", "target_a", 100.0, 160.0, 20.0)
            |> Map.put("estimated_storage_mb", 35.0)
          ]
        }),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_resource_projection_report, resource_projection_report),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    pressure_branch = branch(artifact, "derived_projected_resource_pressure_leo_live_projection")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             pressure_branch["assumptions"]["candidate_source"]

    assert %{
             "type" => "downlink_completion_gap",
             "scenario_id" => "leo_live_projection",
             "required_downlink_mb" => 18.0,
             "source_activity_id" => "obs_live_projection",
             "source_activity_ids" => ["obs_live_projection"],
             "feedback_source" => "mission_state.source_resource_projection_report",
             "trust_boundary" => "live_resource_projection"
           } =
             Enum.find(
               pressure_branch["events"],
               &("projected_storage_overflow" in Map.get(&1, "derivation_reasons", []))
             )

    assert Enum.any?(
             pressure_branch["repair_result"]["source_resource_summaries"],
             &(&1["spacecraft_id"] == "leo_live_projection" and &1["storage_margin"] == 0.0 and
                 get_in(&1, ["provenance", "trust_boundary"]) == "live_resource_projection")
           )

    assert "downlink_demand_mb" in get_in(
             pressure_branch,
             ["assumptions", "candidate_source", "operational_feedback_input_keys"]
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives mission-state resource pressure from result artifact wrappers" do
    source_result_artifact = %{
      "schema_contract" => "result_artifact.v1",
      "study_id" => "live_resource_result_artifact",
      "metadata" => %{"trust_boundary" => "live_result_resource_review"},
      "resource_projection_report" => %{
        "schema_contract" => "resource_projection_report.v1",
        "projected_resources" => [
          %{
            "spacecraft_id" => "leo_live_result_projection",
            "resource_source_quality" => "operator_supplied",
            "resource_trust_boundary_status" => "declared",
            "projected_storage_overflow_mb" => 22.0,
            "activity_resource_flow" => [
              %{
                "activity_id" => "obs_live_result_projection",
                "activity_type" => "observe",
                "starts_at_s" => 100.0,
                "ends_at_s" => 160.0,
                "storage_overflow_mb" => 22.0
              }
            ]
          }
        ]
      },
      "resource_filter_report" => %{
        "schema_contract" => "resource_filter_report.v1",
        "model" => "resource_summary_availability_and_margin_filter",
        "input_candidate_count" => 1,
        "kept_candidate_count" => 0,
        "suppressed_candidate_count" => 1,
        "suppressed_candidates" => [
          %{
            "id" => "obs_live_result_filter",
            "type" => "observe",
            "scenario_id" => "leo_live_filter",
            "spacecraft_id" => "leo_live_filter",
            "target_id" => "target_a",
            "starts_at_s" => 200.0,
            "ends_at_s" => 260.0,
            "suppressed_reason" => "payload_unavailable",
            "payload_available" => false,
            "resource_source_quality" => "operator_supplied",
            "resource_trust_boundary_status" => "declared"
          }
        ]
      }
    }

    artifact =
      strategy(
        base_plan(%{
          "activities" => [
            observe(
              "obs_live_result_projection",
              "leo_live_result_projection",
              "target_a",
              100.0,
              160.0,
              20.0
            )
            |> Map.put("estimated_storage_mb", 35.0)
          ]
        }),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_result_artifact, source_result_artifact),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    projection_branch =
      branch(artifact, "derived_projected_resource_pressure_leo_live_result_projection")

    assert %{
             "type" => "downlink_completion_gap",
             "scenario_id" => "leo_live_result_projection",
             "required_downlink_mb" => 22.0,
             "source_activity_id" => "obs_live_result_projection",
             "source_activity_ids" => ["obs_live_result_projection"],
             "feedback_source" =>
               "mission_state.source_result_artifact.resource_projection_report",
             "feedback_scope" => "resource_projection",
             "trust_boundary" => "live_result_resource_review"
           } =
             Enum.find(
               projection_branch["events"],
               &("projected_storage_overflow" in Map.get(&1, "derivation_reasons", []))
             )

    assert "mission_state.source_result_artifact.resource_projection_report" in get_in(
             projection_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    filter_branch =
      branch(
        artifact,
        "derived_resource_filter_pressure_payload_unavailable_obs_live_result_filter"
      )

    assert %{
             "type" => "resource_availability_constraint",
             "scenario_id" => "leo_live_filter",
             "spacecraft_id" => "leo_live_filter",
             "resource_field" => "payload_available",
             "available" => false,
             "source_activity_id" => "obs_live_result_filter",
             "feedback_source" => "mission_state.source_result_artifact.resource_filter_report",
             "feedback_scope" => "resource_filter",
             "trust_boundary" => "live_result_resource_review"
           } = List.first(filter_branch["events"])

    assert "mission_state.source_result_artifact.resource_filter_report" in get_in(
             filter_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives resource projection pressure from result artifact reports" do
    prior_plan =
      base_plan(%{
        "activities" => [
          observe("obs_result_resource_pressure", "leo_1", "target_a", 100.0, 160.0, 20.0)
          |> Map.put("estimated_storage_mb", 35.0)
        ],
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "study_id" => "resource_projection_result_artifact",
          "metadata" => %{"trust_boundary" => "ops_result_artifact"},
          "resource_projection_report" => %{
            "schema_contract" => "resource_projection_report.v1",
            "projected_resources" => [
              %{
                "spacecraft_id" => "leo_1",
                "resource_source_quality" => "operator_supplied",
                "resource_trust_boundary_status" => "declared",
                "projected_storage_overflow_mb" => 25.0,
                "activity_resource_flow" => [
                  %{
                    "activity_id" => "obs_result_resource_pressure",
                    "activity_type" => "observe",
                    "starts_at_s" => 100.0,
                    "ends_at_s" => 160.0,
                    "storage_overflow_mb" => 25.0,
                    "activity_context" => %{
                      "downlink_completion_sources" => [
                        "resource_projection.storage_overflow:obs_result_resource_pressure"
                      ]
                    }
                  }
                ]
              },
              %{
                "spacecraft_id" => "leo_result_thermal",
                "resource_source_quality" => "operator_supplied",
                "resource_trust_boundary_status" => "declared",
                "thermal_margin_c" => -2.25,
                "resource_pressure_status" => "resource_pressure",
                "resource_pressure_types" => ["thermal_margin_below_limit"]
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

    pressure_branch = branch(artifact, "derived_projected_resource_pressure_leo_1")

    thermal_pressure_branch =
      branch(artifact, "derived_projected_resource_pressure_leo_result_thermal")

    assert %{
             "type" => "downlink_completion_gap",
             "required_downlink_mb" => 25.0,
             "source_activity_id" => "obs_result_resource_pressure",
             "source_activity_ids" => ["obs_result_resource_pressure"],
             "downlink_completion_sources" => [
               "resource_projection.storage_overflow:obs_result_resource_pressure"
             ],
             "downlink_demand_sources" => [
               "resource_projection.storage_overflow:obs_result_resource_pressure"
             ],
             "derivation_reasons" => ["projected_storage_overflow"],
             "feedback_source" => "prior_plan.source_result_artifact.resource_projection_report",
             "trust_boundary" => "ops_result_artifact"
           } =
             Enum.find(
               pressure_branch["events"],
               &("projected_storage_overflow" in Map.get(&1, "derivation_reasons", []))
             )

    assert Enum.any?(
             pressure_branch["repair_result"]["source_resource_summaries"],
             &(&1["spacecraft_id"] == "leo_1" and &1["storage_margin"] == 0.0 and
                 get_in(&1, ["provenance", "trust_boundary"]) == "ops_result_artifact")
           )

    assert thermal_pressure =
             %{
               "type" => "resource_margin_pressure",
               "spacecraft_id" => "leo_result_thermal",
               "resource_field" => "thermal_margin_c",
               "thermal_margin_c" => -2.25,
               "derivation_reasons" => ["projected_thermal_margin_below_limit"],
               "feedback_source" =>
                 "prior_plan.source_result_artifact.resource_projection_report",
               "trust_boundary" => "ops_result_artifact"
             } =
             Enum.find(
               thermal_pressure_branch["events"],
               &(&1["type"] == "resource_margin_pressure" and
                   &1["resource_field"] == "thermal_margin_c")
             )

    assert thermal_pressure["thermal_margin_c_threshold"] == 0.0

    assert Enum.any?(
             thermal_pressure_branch["risk_indicators"],
             &(&1["type"] == "thermal_margin_below_limit" and
                 &1["thermal_margin_c"] == -2.25)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp assert_resource_projection_pressure_score_terms(branch, artifact) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    resource_projection_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] == "downlink_completion_gap" and
            &1["feedback_scope"] == "resource_projection")
      )

    assert resource_projection_pressure_count > 0

    assert branch["score_terms"]["resource_projection_pressure_penalty"] ==
             -resource_projection_pressure_count * risk_weight

    assert "resource_projection_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "resource_projection_pressure_penalty" and
                 &1["value"] < 0.0)
           )

    assert Enum.any?(
             artifact["recommendation"]["tradeoffs"],
             &(&1["dimension"] == "resource_projection_pressure")
           )
  end

  defp assert_resource_availability_pressure_score_terms(
         branch,
         artifact,
         extra_split_pressure_count \\ 0
       ) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    resource_availability_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] in [
            "resource_unavailable",
            "spacecraft_unavailable",
            "payload_unavailable",
            "spacecraft_degraded_payload_unavailable",
            "activity_type_suppressed_by_resource_summary",
            "activity_type_incompatible_with_resource_summary",
            "antenna_unavailable"
          ] or resource_availability_source_report_pressure?(&1))
      )

    assert resource_availability_pressure_count > 0

    assert branch["score_terms"]["resource_availability_pressure_penalty"] ==
             -resource_availability_pressure_count * risk_weight

    assert branch["score_terms"]["quality_gate_pressure_penalty"] == 0.0

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) -
                 resource_availability_pressure_count - extra_split_pressure_count) *
               risk_weight

    assert "resource_availability_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "resource_availability_pressure_penalty" and
                 &1["value"] < 0.0)
           )
  end

  defp resource_availability_source_report_pressure?(%{"type" => "quality_gate_pressure"} = risk) do
    risk["gate_id"] == "resource_availability" or
      is_map(risk["resource_availability_reason_counts"]) or
      is_map(risk["unavailable_resource_reason_counts"]) or
      is_map(risk["blocked_contact_ids_by_blocking_dimension"])
  end

  defp resource_availability_source_report_pressure?(
         %{"type" => "operational_readiness_pressure"} = risk
       ) do
    risk["readiness_gate_id"] == "resource_availability" or
      is_map(risk["resource_availability_reason_counts"]) or
      is_map(risk["unavailable_resource_reason_counts"]) or
      is_map(risk["blocked_contact_ids_by_blocking_dimension"])
  end

  defp resource_availability_source_report_pressure?(_risk), do: false

  defp assert_resource_margin_pressure_score_terms(branch, artifact) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    resource_margin_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] in [
            "fuel_margin_low",
            "power_margin_low",
            "thermal_margin_c_low"
          ])
      )

    assert resource_margin_pressure_count > 0

    assert branch["score_terms"]["resource_margin_pressure_penalty"] ==
             -resource_margin_pressure_count * risk_weight

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - resource_margin_pressure_count) *
               risk_weight

    assert "resource_margin_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "resource_margin_pressure_penalty" and
                 &1["value"] < 0.0)
           )
  end
end
