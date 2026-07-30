Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyBranchLocalOperationalFeedbackTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy-derived refresh canonicalizes branch-local resource aliases" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> put_in(
        [:candidate_refresh_defaults, :resource_filter_policy],
        %{min_downlink_margin: 0.75}
      )

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "branch_resource_aliases",
            events: [
              %{
                type: "resource_margin_pressure",
                spacecraft_id: "leo_1",
                downlink_capacity_margin: "0.4",
                downlink_capacity_margin_threshold: "0.75"
              },
              %{
                type: "resource_margin_pressure",
                spacecraft_id: "leo_1",
                storage_capacity_margin: "0.05",
                storage_capacity_margin_threshold: "0.2"
              },
              %{
                type: "resource_margin_pressure",
                spacecraft_id: "leo_1",
                battery_soc: "0.05",
                battery_soc_threshold: "0.2"
              },
              %{
                type: "resource_margin_pressure",
                spacecraft_id: "leo_1",
                resource_field: "thermal_margin_c",
                thermal_margin_c: "1.5"
              },
              %{
                type: "resource_availability_constraint",
                spacecraft_id: "leo_1",
                resource_field: "payload_available?",
                payload_available?: false,
                trust_boundary: "ops_branch_event"
              },
              %{
                type: "resource_availability_constraint",
                spacecraft_id: "leo_1",
                resource_field: "antenna_available",
                available: " unavailable ",
                trust_boundary: "ops_branch_event"
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    alias_branch = branch(artifact, "branch_resource_aliases")

    assert %{
             "type" => "candidate_refresh.v1",
             "scope" => "branch_generated"
           } = alias_branch["assumptions"]["candidate_source"]

    assert %{
             "type" => "resource_margin_pressure",
             "resource_field" => "downlink_margin",
             "downlink_margin" => 0.4,
             "downlink_margin_threshold" => 0.75
           } = Enum.find(alias_branch["events"], &(&1["type"] == "resource_margin_pressure"))

    assert %{
             "type" => "resource_margin_pressure",
             "resource_field" => "storage_margin",
             "storage_margin" => 0.05,
             "storage_margin_threshold" => 0.2
           } =
             Enum.find(
               alias_branch["events"],
               &(&1["type"] == "resource_margin_pressure" and
                   &1["resource_field"] == "storage_margin")
             )

    assert %{
             "type" => "resource_margin_pressure",
             "resource_field" => "power_margin",
             "power_margin" => 0.05,
             "battery_state_of_charge" => 0.05,
             "power_margin_threshold" => 0.2
           } =
             Enum.find(
               alias_branch["events"],
               &(&1["type"] == "resource_margin_pressure" and
                   &1["resource_field"] == "power_margin")
             )

    assert %{
             "type" => "resource_margin_pressure",
             "resource_field" => "thermal_margin_c",
             "thermal_margin_c" => 1.5
           } =
             Enum.find(
               alias_branch["events"],
               &(&1["type"] == "resource_margin_pressure" and
                   &1["resource_field"] == "thermal_margin_c")
             )

    assert %{
             "type" => "resource_availability_constraint",
             "resource_field" => "payload_available",
             "payload_available" => false,
             "available" => false
           } =
             Enum.find(
               alias_branch["events"],
               &(&1["type"] == "resource_availability_constraint")
             )

    assert %{
             "type" => "resource_availability_constraint",
             "resource_field" => "antenna_available",
             "available" => false
           } =
             Enum.find(
               alias_branch["events"],
               &(&1["type"] == "resource_availability_constraint" and
                   &1["resource_field"] == "antenna_available")
             )

    assert Enum.any?(
             alias_branch["repair_result"]["source_resource_summaries"],
             &(&1["spacecraft_id"] == "leo_1" and &1["downlink_margin"] == 0.4 and
                 &1["storage_margin"] == 0.05 and
                 &1["power_margin"] == 0.05 and
                 &1["thermal_margin_c"] == 1.5 and &1["payload_available"] == false and
                 &1["antenna_available"] == false and
                 get_in(&1, ["provenance", "trust_boundary"]) == "ops_branch_event")
           )

    assert "resource_margin_overrides" in get_in(
             alias_branch,
             ["assumptions", "candidate_source", "operational_feedback_input_keys"]
           )

    assert Enum.any?(
             alias_branch["repair_result"]["source_resource_filter_report"][
               "suppressed_candidates"
             ],
             &(&1["suppressed_reason"] == "payload_unavailable" and
                 &1["resource_trust_boundary"] == "ops_branch_event" and
                 &1["resource_trust_boundary_status"] == "declared")
           )

    assert Enum.any?(
             alias_branch["repair_result"]["source_resource_filter_report"][
               "suppressed_candidates"
             ],
             &(&1["suppressed_reason"] == "antenna_unavailable" and
                 &1["resource_trust_boundary"] == "ops_branch_event")
           )

    assert Enum.any?(
             alias_branch["risk_indicators"],
             &(&1["type"] == "downlink_margin_low" and &1["value"] == 0.4)
           )

    assert Enum.any?(
             alias_branch["risk_indicators"],
             &(&1["type"] == "storage_margin_low" and &1["value"] == 0.05)
           )

    assert Enum.any?(
             alias_branch["risk_indicators"],
             &(&1["type"] == "power_margin_low" and &1["value"] == 0.05)
           )

    assert Enum.any?(
             alias_branch["risk_indicators"],
             &(&1["type"] == "payload_unavailable" and &1["value"] == false)
           )

    assert Enum.any?(
             alias_branch["risk_indicators"],
             &(&1["type"] == "antenna_unavailable" and &1["value"] == false)
           )

    alias_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "branch_resource_aliases"))

    assert alias_row["downlink_capacity_margin"] == 0.4
    assert alias_row["storage_margin"] == 0.05
    assert alias_row["power_margin"] == 0.05
    assert alias_row["payload_availability"] == 0.0
    assert alias_row["antenna_availability"] == 0.0
    assert "downlink_capacity_low" in alias_row["resource_risk_types"]
    assert "storage_margin_low" in alias_row["resource_risk_types"]
    assert "power_margin_low" in alias_row["resource_risk_types"]
    assert "payload_availability_low" in alias_row["resource_risk_types"]
    assert "antenna_availability_low" in alias_row["resource_risk_types"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy recommendation explains selected operational feedback drivers" do
    artifact =
      strategy(
        base_plan(%{
          "activities" => [
            downlink("selected_dl", 100.0, 160.0),
            observe("selected_obs", "leo_1", "target_a", 170.0, 230.0, 10.0)
          ]
        }),
        mission_state: mission_state_with_refresh_inputs(),
        branches: [
          %{
            id: "baseline",
            events: [
              %{
                type: "station_throughput_feedback",
                ground_station_id: "equator_prime",
                station_throughput_factor: 0.8,
                confidence_weight: 0.5,
                confidence_weight_source: "baseline_station_confidence"
              },
              %{
                type: "contact_success_feedback",
                ground_station_id: "equator_prime",
                contact_success_factor: 0.8,
                feedback_weight: 0.25,
                feedback_weight_source: "baseline_contact_weight"
              },
              %{
                type: "observation_success_feedback",
                target_id: "target_a",
                image_quality_score: 0.7,
                image_quality_status: :marginal,
                image_quality_source: :provider_image_assessment,
                cloud_cover_fraction: 0.4,
                blur_score: 0.2
              }
            ]
          },
          %{
            id: "station_outage",
            events: [
              %{
                type: "ground_station_outage",
                ground_station_id: "equator_prime",
                starts_at_s: 90.0,
                ends_at_s: 200.0
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    assert artifact["recommendation"]["recommended_branch_id"] == "baseline"

    assert Enum.any?(
             artifact["recommendation"]["explanation"],
             &(&1["type"] == "operational_feedback_driver" and
                 &1["recommended_branch_id"] == "baseline" and
                 &1["station_throughput_factor"] == 0.9 and
                 &1["station_throughput_factor_source"] ==
                   "operational_feedback.station_throughput_factor" and
                 &1["contact_success_factor"] == 0.95 and
                 &1["contact_success_factor_source"] ==
                   "operational_feedback.contact_success_rate" and
                 &1["observation_success_factor"] == 0.7 and
                 &1["observation_success_factor_source"] ==
                   "operational_feedback.observation_success_rate" and
                 &1["image_quality_score"] == 0.7 and
                 &1["image_quality_score_source"] ==
                   "operational_feedback.image_quality_score" and
                 &1["image_quality_statuses"] == ["marginal"] and
                 &1["image_quality_sources"] == ["provider_image_assessment"] and
                 &1["cloud_cover_fraction"] == 0.4 and
                 &1["cloud_cover_fraction_source"] ==
                   "operational_feedback.cloud_cover_fraction" and
                 &1["blur_score"] == 0.2 and
                 &1["blur_score_source"] == "operational_feedback.blur_score" and
                 &1["feedback_weight_sources"] == [
                   "baseline_contact_weight",
                   "baseline_station_confidence"
                 ] and
                 &1["feedback_score_adjustment"] < 0.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy recommendation preserves command feedback risk identity" do
    artifact =
      strategy(
        base_plan(%{
          "planning_horizon" => %{"duration_s" => 2_000.0},
          "activities" => [command("cmd_health_1", "leo_1", 100.0, 130.0)]
        }),
        mission_state: mission_state_with_refresh_inputs(),
        strategy_policy: %{
          "mission_value_weight" => 100.0,
          "risk_weight" => 0.0,
          "approval_load_weight" => 0.0
        },
        branches: [
          %{
            id: "baseline",
            events: [
              %{
                type: "urgent_target",
                target_id: "target_hot",
                starts_at_s: 500.0,
                ends_at_s: 560.0,
                priority: 200.0,
                candidate_windows: [
                  observe("candidate_obs_hot", "leo_1", "target_hot", 500.0, 560.0, 200.0)
                ]
              },
              %{
                type: "command_success_feedback",
                activity_id: "cmd_health_1",
                scenario_id: "leo_1",
                command_success_factor: 0.25,
                starts_at_s: 0.0,
                ends_at_s: 2_000.0
              }
            ]
          },
          %{id: "noop", probability: 0.0}
        ],
        current_epoch_s: 0.0
      )

    assert artifact["recommendation"]["recommended_branch_id"] == "baseline"

    assert Enum.any?(
             artifact["recommendation"]["risks_remaining"],
             &(&1["type"] == "command_success_rate_low" and
                 &1["activity_id"] == "cmd_health_1" and &1["scenario_id"] == "leo_1" and
                 &1["value"] == 0.25)
           )

    assert Enum.any?(
             artifact["recommendation"]["explanation"],
             &(&1["type"] == "risk_driver" and &1["risk_type"] == "command_success_rate_low" and
                 &1["activity_id"] == "cmd_health_1" and &1["scenario_id"] == "leo_1" and
                 &1["value"] == 0.25)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy review-gates out-of-range branch-local feedback before scoring" do
    artifact =
      strategy(base_plan(%{"activities" => [downlink("selected_dl", 100.0, 160.0)]}),
        mission_state: mission_state_with_refresh_inputs(),
        branches: [
          %{id: "baseline"},
          %{
            id: "branch_feedback",
            events: [
              %{
                type: "station_throughput_feedback",
                ground_station_id: "equator_prime",
                station_throughput_factor: 1.5
              },
              %{
                type: "contact_success_feedback",
                ground_station_id: "equator_prime",
                contact_success_factor: -0.25,
                feedback_weight: -2.0,
                feedback_weight_source: "bad_sample_weight"
              },
              %{
                type: "reduced_downlink_capacity",
                ground_station_id: "equator_prime",
                capacity_fraction: 1.25,
                starts_at_s: 0.0,
                ends_at_s: 2_000.0
              },
              %{
                type: "target_priority_feedback",
                target_id: "target_a",
                priority: -5.0
              },
              %{
                type: "downlink_demand_feedback",
                ground_station_id: "equator_prime",
                required_downlink_mb: -50.0
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    feedback_branch = branch(artifact, "branch_feedback")

    station_event =
      Enum.find(
        feedback_branch["events"],
        &(&1["type"] == "station_throughput_feedback")
      )

    contact_event =
      Enum.find(feedback_branch["events"], &(&1["type"] == "contact_success_feedback"))

    priority_event =
      Enum.find(feedback_branch["events"], &(&1["type"] == "target_priority_feedback"))

    capacity_event =
      Enum.find(feedback_branch["events"], &(&1["type"] == "reduced_downlink_capacity"))

    demand_event =
      Enum.find(feedback_branch["events"], &(&1["type"] == "downlink_demand_feedback"))

    assert %{
             "invalid_branch_event_input" => true,
             "invalid_branch_event_input_reasons" => ["invalid_station_throughput_factor"],
             "invalid_branch_event_fields" => ["station_throughput_factor"],
             "invalid_branch_event_values" => %{"station_throughput_factor" => 1.5},
             "source_branch_event" => %{"station_throughput_factor" => 1.5}
           } = station_event

    refute Map.has_key?(station_event, "station_throughput_factor")

    assert %{
             "invalid_branch_event_input" => true,
             "invalid_branch_event_input_reasons" => [
               "invalid_contact_success_factor",
               "invalid_feedback_weight"
             ],
             "invalid_branch_event_fields" => ["contact_success_factor", "feedback_weight"],
             "invalid_branch_event_values" => %{
               "contact_success_factor" => -0.25,
               "feedback_weight" => -2.0
             },
             "source_branch_event" => %{
               "contact_success_factor" => -0.25,
               "feedback_weight" => -2.0,
               "feedback_weight_source" => "bad_sample_weight"
             }
           } = contact_event

    refute Map.has_key?(contact_event, "contact_success_factor")
    refute Map.has_key?(contact_event, "feedback_weight")
    assert contact_event["feedback_weight_source"] == "bad_sample_weight"

    assert %{
             "invalid_branch_event_input" => true,
             "invalid_branch_event_input_reasons" => ["invalid_capacity_fraction"],
             "invalid_branch_event_fields" => ["capacity_fraction"],
             "invalid_branch_event_values" => %{"capacity_fraction" => 1.25},
             "source_branch_event" => %{"capacity_fraction" => 1.25}
           } = capacity_event

    refute Map.has_key?(capacity_event, "capacity_fraction")

    assert %{
             "invalid_branch_event_input" => true,
             "invalid_branch_event_input_reasons" => ["invalid_priority"],
             "invalid_branch_event_fields" => ["priority"],
             "invalid_branch_event_values" => %{"priority" => -5.0},
             "source_branch_event" => %{"priority" => -5.0}
           } = priority_event

    refute Map.has_key?(priority_event, "priority")

    assert %{
             "invalid_branch_event_input" => true,
             "invalid_branch_event_input_reasons" => ["invalid_required_downlink_mb"],
             "invalid_branch_event_fields" => ["required_downlink_mb"],
             "invalid_branch_event_values" => %{"required_downlink_mb" => -50.0},
             "source_branch_event" => %{"required_downlink_mb" => -50.0}
           } = demand_event

    refute Map.has_key?(demand_event, "required_downlink_mb")

    downlink =
      feedback_branch
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime"))

    assert get_in(downlink, ["throughput_model", "station_capacity_fraction"]) == 1.0
    assert get_in(downlink, ["throughput_model", "contact_success_factor"]) == 1.0
    assert feedback_branch["feedback_adjustments"]["station_throughput_factor"] == 1.0
    assert feedback_branch["feedback_adjustments"]["contact_success_factor"] == 1.0
    assert feedback_branch["candidate_plan"]["capacity_adjustments"] == []

    assert "branch branch_feedback contact_success_feedback ignored invalid contact_success_factor -0.25" in feedback_branch[
             "warnings"
           ]

    assert "branch branch_feedback contact_success_feedback ignored invalid feedback_weight -2.0" in feedback_branch[
             "warnings"
           ]

    assert "branch branch_feedback station_throughput_feedback ignored invalid station_throughput_factor 1.5" in feedback_branch[
             "warnings"
           ]

    assert "branch branch_feedback reduced_downlink_capacity ignored invalid capacity_fraction 1.25" in feedback_branch[
             "warnings"
           ]

    assert "branch branch_feedback target_priority_feedback ignored invalid priority -5.0" in feedback_branch[
             "warnings"
           ]

    assert "branch branch_feedback downlink_demand_feedback ignored invalid required_downlink_mb -50.0" in feedback_branch[
             "warnings"
           ]

    feedback_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "branch_feedback"))

    assert feedback_row["station_throughput_factor"] == 1.0
    assert feedback_row["contact_success_factor"] == 1.0

    review_rows = get_in(artifact, ["operator_review_package", "rows"])

    assert Enum.any?(
             review_rows,
             &(&1["source"] == "campaign_strategy.branches.warnings" and
                 &1["branch_id"] == "branch_feedback" and
                 &1["reason"] ==
                   "branch branch_feedback contact_success_feedback ignored invalid contact_success_factor -0.25")
           )

    assert Enum.any?(
             review_rows,
             &(&1["source"] == "campaign_strategy.branches.warnings" and
                 &1["branch_id"] == "branch_feedback" and
                 &1["reason"] ==
                   "branch branch_feedback contact_success_feedback ignored invalid feedback_weight -2.0")
           )

    assert Enum.any?(
             review_rows,
             &(&1["source"] == "campaign_strategy.branches.warnings" and
                 &1["branch_id"] == "branch_feedback" and
                 &1["reason"] ==
                   "branch branch_feedback downlink_demand_feedback ignored invalid required_downlink_mb -50.0")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy damps branch-authored success feedback by confidence weight" do
    artifact =
      strategy(base_plan(%{"activities" => [downlink("selected_dl", 100.0, 160.0)]}),
        mission_state: mission_state_with_refresh_inputs(),
        strategy_policy: %{
          "mission_value_weight" => 100.0,
          "risk_weight" => 0.0,
          "approval_load_weight" => 0.0
        },
        branches: [
          %{id: "baseline"},
          %{
            id: "branch_feedback_weighted",
            events: [
              %{
                type: "urgent_target",
                target_id: "target_a",
                priority: 500.0,
                candidate_windows: [
                  observe("candidate_weighted_obs", "leo_1", "target_a", 200.0, 260.0, 500.0)
                ]
              },
              %{
                type: "station_throughput_feedback",
                ground_station_id: "equator_prime",
                station_throughput_factor: 0.4,
                confidence_weight: 0.5,
                confidence_weight_source: "operator_confidence"
              },
              %{
                type: "contact_success_feedback",
                ground_station_id: "equator_prime",
                contact_success_factor: 0.2,
                feedback_weight: 0.25,
                feedback_weight_source: "operator_sample_weight"
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    feedback_branch = branch(artifact, "branch_feedback_weighted")

    assert %{
             "station_throughput_factor" => 0.4,
             "confidence_weight" => 0.5,
             "confidence_weight_source" => "operator_confidence"
           } =
             Enum.find(
               feedback_branch["events"],
               &(&1["type"] == "station_throughput_feedback")
             )

    assert %{
             "contact_success_factor" => 0.2,
             "feedback_weight" => 0.25,
             "feedback_weight_source" => "operator_sample_weight"
           } =
             Enum.find(feedback_branch["events"], &(&1["type"] == "contact_success_feedback"))

    downlink =
      feedback_branch
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime"))

    assert_in_delta get_in(downlink, ["throughput_model", "station_capacity_fraction"]),
                    0.7,
                    1.0e-12

    assert_in_delta get_in(downlink, ["throughput_model", "contact_success_factor"]), 0.8, 1.0e-12

    assert_in_delta feedback_branch["feedback_adjustments"]["station_throughput_factor"],
                    0.7,
                    1.0e-12

    assert_in_delta feedback_branch["feedback_adjustments"]["contact_success_factor"],
                    0.8,
                    1.0e-12

    assert feedback_branch["feedback_adjustments"]["feedback_weight_sources"] == [
             "operator_confidence",
             "operator_sample_weight"
           ]

    feedback_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "branch_feedback_weighted"))

    assert_in_delta feedback_row["station_throughput_factor"], 0.7, 1.0e-12
    assert_in_delta feedback_row["contact_success_factor"], 0.8, 1.0e-12

    assert feedback_row["feedback_weight_sources"] == [
             "operator_confidence",
             "operator_sample_weight"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy review-gates out-of-range top-level success feedback before refresh and scoring" do
    artifact =
      strategy(base_plan(%{"activities" => [downlink("selected_dl", 100.0, 160.0)]}),
        mission_state: mission_state_with_refresh_inputs(),
        operational_feedback: %{
          station_throughput_factor: %{"equator_prime" => 1.5},
          contact_success_rate: %{"equator_prime" => -0.25}
        },
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    urgent_branch = branch(artifact, "urgent")

    downlink =
      urgent_branch
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime"))

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{}
    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{}

    assert get_in(downlink, ["throughput_model", "station_capacity_fraction"]) == 1.0
    assert get_in(downlink, ["throughput_model", "contact_success_factor"]) == 1.0
    assert urgent_branch["feedback_adjustments"]["station_throughput_factor"] == 1.0
    assert urgent_branch["feedback_adjustments"]["contact_success_factor"] == 1.0

    request_source =
      Enum.find(
        artifact["operational_feedback_provenance"]["sources"],
        &(&1["source"] == "request.operational_feedback")
      )

    assert %{
             "input_keys" => ["invalid_operational_feedback_input"],
             "invalid_operational_feedback_input" => true,
             "invalid_operational_feedback_input_reason" =>
               "operational_feedback_sections_invalid",
             "invalid_operational_feedback_sections" => invalid_sections,
             "source_operational_feedback" => %{
               "invalid_feedback_sections" => invalid_sections
             }
           } = request_source

    assert %{
             "field" => "station_throughput_factor",
             "key" => "equator_prime",
             "reason" => "value_must_be_between_0_and_1",
             "invalid_feedback_value" => 1.5
           } in invalid_sections

    assert %{
             "field" => "contact_success_rate",
             "key" => "equator_prime",
             "reason" => "value_must_be_between_0_and_1",
             "invalid_feedback_value" => -0.25
           } in invalid_sections

    recommendation_review =
      artifact["operator_review_package"]["rows"]
      |> Enum.find(&(&1["review_type"] == "strategy_recommendation"))

    selected_import =
      artifact["cadence_import_manifest"]["rows"]
      |> Enum.find(&(&1["import_action"] == "import_strategy_recommendation"))

    assert get_in(recommendation_review, [
             "source_operational_feedback_provenance",
             "sources",
             Access.at(0),
             "invalid_operational_feedback_sections"
           ]) == invalid_sections

    assert get_in(selected_import, [
             "source_operational_feedback_provenance",
             "sources",
             Access.at(0),
             "invalid_operational_feedback_sections"
           ]) == invalid_sections

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives contact success refresh branch from operational feedback" do
    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state_with_refresh_inputs(),
        operational_feedback: %{
          contact_success_rate: %{"equator_prime" => 0.4}
        },
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    contact_branch = branch(artifact, "derived_contact_success_feedback")

    assert %{
             "type" => "contact_success_feedback",
             "ground_station_id" => "equator_prime",
             "contact_success_factor" => 0.4,
             "feedback_source" => "operational_feedback.contact_success_rate"
           } = List.first(contact_branch["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             contact_branch["assumptions"]["candidate_source"]

    downlink =
      contact_branch
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime"))

    assert downlink["contact_success_factor"] == 0.4

    assert downlink["contact_success_factor_source"] ==
             "operational_feedback.contact_success_rate.station"

    assert get_in(downlink, ["throughput_model", "contact_success_factor"]) == 0.4
    assert downlink["score_terms"]["contact_success_adjustment"] < 0.0

    assert Enum.any?(
             contact_branch["risk_indicators"],
             &(&1["type"] == "contact_success_rate_low" and &1["value"] == 0.4)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch-local refresh from review package command maneuver and realized feedback rows" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          command("cmd_review", "leo_1", 100.0, 130.0),
          command("cmd_import", "leo_1", 140.0, 170.0),
          command("cmd_flat_import", "leo_1", 180.0, 210.0),
          maneuver("trim_burn", 220.0),
          maneuver("trim_import", 260.0),
          observe("obs_import_feedback", "leo_1", "target_a", 270.0, 300.0, 8.0),
          observe("obs_quality_feedback", "leo_1", "target_a", 275.0, 305.0, 8.0),
          downlink("dl_feedback", 300.0, 360.0)
          |> Map.put("estimated_throughput_mb", 100.0)
        ],
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "campaign_strategy.v3",
          "review_count" => 4,
          "provenance" => %{"trust_boundary" => "ops_review_queue"},
          "rows" => [
            %{
              "id" => "operator_review:command_window:cmd_review",
              "review_type" => "command_window_review",
              "activity_id" => "cmd_review",
              "activity_type" => "command",
              "scenario_id" => "leo_1",
              "approval_status" => "operator_review_required",
              "source_command_window" => %{
                "activity_id" => "cmd_review",
                "type" => "command",
                "scenario_id" => "leo_1",
                "starts_at_s" => 100.0,
                "ends_at_s" => 130.0,
                "direction" => "uplink",
                "ground_station_id" => "equator_prime",
                "station_availability" => "reserved",
                "station_contention_status" => "reserved_overlap",
                "station_calendar_entry_id" => "cmd_partner_reservation",
                "station_calendar_provider_id" => "partner_calendar",
                "station_calendar_provider_entry_id" => "partner_cmd_entry_1",
                "station_calendar_directions" => ["uplink"],
                "station_calendar_status" => "reserved",
                "station_calendar_trust_boundary_status" => "declared",
                "station_reservation_id" => "reservation_cmd_partner",
                "station_reserved_by" => "partner_team",
                "station_reservation_status" => "confirmed",
                "station_reservation_match_status" => "unmatched_overlap",
                "command_success_factor" => 0.25,
                "command_result" => ["accepted", "rejected"]
              }
            },
            %{
              "id" => "operator_review:maneuver:trim_burn",
              "review_type" => "maneuver_review",
              "maneuver_id" => "trim_burn",
              "scenario_id" => "leo_1",
              "approval_status" => "operator_review_required",
              "source_maneuver_review" => %{
                "maneuver_id" => "trim_burn",
                "maneuver_type" => "maneuver",
                "scenario_id" => "leo_1",
                "epoch_s" => 220.0,
                "maneuver_success_factor" => 0.4,
                "maneuver_result" => ["accepted", "partial"],
                "execution_uncertainty" => %{
                  "timing_3sigma_s" => 72.0,
                  "delta_v_3sigma_km_s" => [0.0, 0.0018, 0.0],
                  "source" => "maneuver_review_covariance"
                }
              }
            },
            %{
              "id" => "operator_review:realized_feedback:dl_feedback",
              "review_type" => "realized_feedback",
              "activity_id" => "dl_feedback",
              "activity_type" => "downlink",
              "feedback_status" => "matched",
              "realized_status" => "partial",
              "approval_status" => "operator_review_required",
              "source_feedback" => %{
                "activity_id" => "dl_feedback",
                "type" => "downlink",
                "scenario_id" => "leo_1",
                "ground_station_id" => "equator_prime",
                "starts_at_s" => 300.0,
                "ends_at_s" => 360.0,
                "contact_success" => false,
                "contact_result" => ["accepted", "dropped"],
                "actual_throughput_mb" => 20.0,
                "estimated_throughput_mb" => 100.0
              }
            },
            %{
              "id" => "operator_review:realized_feedback:obs_quality_feedback",
              "review_type" => "realized_feedback",
              "activity_id" => "obs_quality_feedback",
              "activity_type" => "observe",
              "feedback_status" => "matched",
              "realized_status" => "completed",
              "approval_status" => "operator_review_required",
              "source_feedback" => %{
                "activity_id" => "obs_quality_feedback",
                "type" => "observe",
                "target_id" => "target_a",
                "scenario_id" => "leo_1",
                "starts_at_s" => 275.0,
                "ends_at_s" => 305.0,
                "image_quality_score" => 0.35,
                "image_quality_status" => "marginal",
                "image_quality_source" => "provider_image_assessment",
                "cloud_cover_fraction" => 0.65,
                "blur_score" => 0.25
              }
            }
          ]
        },
        "cadence_import_manifest" => %{
          "schema_contract" => "cadence_import_manifest.v1",
          "source_artifact_type" => "operator_review_package.v1",
          "row_count" => 4,
          "review_required_count" => 4,
          "provenance" => %{"trust_boundary" => "cadence_review_queue"},
          "rows" => [
            %{
              "id" => "cadence_import:command_window:cmd_import",
              "import_action" => "review_command_window",
              "source_review_type" => "command_window_review",
              "approval_status" => "operator_review_required",
              "source_review_row" => %{
                "review_type" => "command_window_review",
                "activity_id" => "cmd_import",
                "activity_type" => "command",
                "scenario_id" => "leo_1",
                "source_command_window" => %{
                  "activity_id" => "cmd_import",
                  "type" => "command",
                  "scenario_id" => "leo_1",
                  "starts_at_s" => 140.0,
                  "ends_at_s" => 170.0,
                  "direction" => "uplink",
                  "ground_station_id" => "equator_prime",
                  "station_availability" => "reserved",
                  "station_calendar_entry_id" => "cmd_import_provider_reservation",
                  "station_calendar_provider_id" => "partner_calendar",
                  "station_calendar_provider_entry_id" => "partner_cmd_entry_2",
                  "station_calendar_status" => "reserved",
                  "station_reservation_id" => "reservation_cmd_import_partner",
                  "station_reserved_by" => "partner_team",
                  "station_reservation_status" => "confirmed",
                  "command_success_factor" => 0.3,
                  "command_result" => ["accepted", "missed"]
                }
              }
            },
            %{
              "id" => "cadence_import:command_window:cmd_flat_import",
              "import_action" => "review_command_window",
              "source_review_type" => "command_window_review",
              "activity_id" => "cmd_flat_import",
              "activity_type" => "command",
              "scenario_id" => "leo_1",
              "approval_status" => "operator_review_required",
              "source_command_window" => %{
                "activity_id" => "cmd_flat_import",
                "type" => "command",
                "scenario_id" => "leo_1",
                "starts_at_s" => 180.0,
                "ends_at_s" => 210.0,
                "command_success_factor" => 0.35,
                "command_result" => [:accepted, :rejected]
              }
            },
            %{
              "id" => "cadence_import:maneuver:trim_import",
              "import_action" => "review_maneuver",
              "source_review_type" => "maneuver_review",
              "approval_status" => "operator_review_required",
              "source_maneuver_review" => %{
                "maneuver_id" => "trim_import",
                "maneuver_type" => "maneuver",
                "scenario_id" => "leo_1",
                "epoch_s" => 260.0,
                "maneuver_success_factor" => 0.2,
                "maneuver_result" => ["accepted", "missed"],
                "execution_uncertainty" => %{
                  "timing_3sigma_s" => 88.0,
                  "delta_v_3sigma_km_s" => [0.0, 0.0028, 0.0],
                  "source" => "cadence_maneuver_review_covariance"
                }
              }
            },
            %{
              "id" => "cadence_import:realized_feedback:obs_import_feedback",
              "import_action" => "review_realized_feedback",
              "source_review_type" => "realized_feedback",
              "activity_id" => "obs_import_feedback",
              "activity_type" => "observe",
              "feedback_status" => "matched",
              "realized_status" => "failed",
              "approval_status" => "operator_review_required",
              "source_feedback" => %{
                "activity_id" => "obs_import_feedback",
                "type" => "observe",
                "target_id" => "target_a",
                "scenario_id" => "leo_1",
                "starts_at_s" => 270.0,
                "ends_at_s" => 300.0,
                "observation_success" => false,
                "observation_result" => ["accepted", "failed"]
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

    command_branch = branch(artifact, "derived_command_window_feedback_cmd_review")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_review",
             "command_success_factor" => 0.25,
             "command_result" => "accepted,rejected",
             "direction" => "uplink",
             "ground_station_id" => "equator_prime",
             "station_availability" => "reserved",
             "station_contention_status" => "reserved_overlap",
             "station_calendar_entry_id" => "cmd_partner_reservation",
             "station_calendar_provider_id" => "partner_calendar",
             "station_calendar_provider_entry_id" => "partner_cmd_entry_1",
             "station_calendar_directions" => ["uplink"],
             "station_calendar_status" => "reserved",
             "station_calendar_trust_boundary_status" => "declared",
             "station_reservation_id" => "reservation_cmd_partner",
             "station_reserved_by" => "partner_team",
             "station_reservation_status" => "confirmed",
             "station_reservation_match_status" => "unmatched_overlap",
             "feedback_source" => "prior_plan.operator_review_package.rows.source_command_window",
             "feedback_scope" => "command_window",
             "trust_boundary" => "ops_review_queue"
           } = command_event = List.first(command_branch["events"])

    assert command_event["derivation_reasons"] == [
             "command_window_review_feedback",
             "accepted",
             "rejected",
             "reserved",
             "unmatched_overlap"
           ]

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             command_branch["assumptions"]["candidate_source"]

    command_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_command_window_feedback_cmd_review"))

    assert command_row["branch_station_availabilities"] == ["reserved"]
    assert command_row["branch_station_contention_statuses"] == ["reserved_overlap"]
    assert command_row["branch_ground_station_ids"] == ["equator_prime"]
    assert command_row["branch_directions"] == ["uplink"]
    assert command_row["branch_station_calendar_entry_ids"] == ["cmd_partner_reservation"]
    assert command_row["branch_station_calendar_provider_ids"] == ["partner_calendar"]
    assert command_row["branch_station_calendar_provider_entry_ids"] == ["partner_cmd_entry_1"]
    assert command_row["branch_station_calendar_directions"] == ["uplink"]
    assert command_row["branch_station_calendar_statuses"] == ["reserved"]
    assert command_row["branch_station_calendar_trust_boundary_statuses"] == ["declared"]
    assert command_row["branch_station_reservation_ids"] == ["reservation_cmd_partner"]
    assert command_row["branch_station_reserved_by"] == ["partner_team"]
    assert command_row["branch_station_reservation_statuses"] == ["confirmed"]
    assert command_row["branch_station_reservation_match_statuses"] == ["unmatched_overlap"]

    assert %{
             "branch_ground_station_ids" => ["equator_prime"],
             "branch_station_calendar_provider_ids" => ["partner_calendar"],
             "branch_station_calendar_provider_entry_ids" => ["partner_cmd_entry_1"],
             "branch_station_reservation_ids" => ["reservation_cmd_partner"],
             "branch_station_reservation_match_statuses" => ["unmatched_overlap"],
             "source_branch_comparison" => %{
               "branch_station_calendar_provider_ids" => ["partner_calendar"],
               "branch_station_reservation_ids" => ["reservation_cmd_partner"]
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "strategy_tradeoff" and
                   &1["branch_id"] == "derived_command_window_feedback_cmd_review" and
                   &1["required_operator_action"] == "review_branch_comparison")
             )

    assert %{
             "source_review_type" => "strategy_branch_comparison",
             "branch_ground_station_ids" => ["equator_prime"],
             "branch_station_calendar_provider_ids" => ["partner_calendar"],
             "branch_station_calendar_provider_entry_ids" => ["partner_cmd_entry_1"],
             "branch_station_reservation_ids" => ["reservation_cmd_partner"],
             "branch_station_reservation_match_statuses" => ["unmatched_overlap"],
             "source_branch_comparison" => %{
               "branch_station_calendar_provider_ids" => ["partner_calendar"],
               "branch_station_reservation_ids" => ["reservation_cmd_partner"]
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source_review_type"] == "strategy_branch_comparison" and
                   &1["branch_id"] == "derived_command_window_feedback_cmd_review")
             )

    maneuver_branch = branch(artifact, "derived_maneuver_review_feedback_trim_burn")

    assert %{
             "type" => "maneuver_success_feedback",
             "activity_id" => "trim_burn",
             "maneuver_success_factor" => 0.4,
             "maneuver_result" => "accepted,partial",
             "feedback_source" =>
               "prior_plan.operator_review_package.rows.source_maneuver_review",
             "feedback_scope" => "maneuver_review",
             "trust_boundary" => "ops_review_queue"
           } = Enum.find(maneuver_branch["events"], &(&1["type"] == "maneuver_success_feedback"))

    assert Enum.any?(
             maneuver_branch["events"],
             &(&1["type"] == "maneuver_execution_uncertainty_feedback" and
                 &1["activity_id"] == "trim_burn" and
                 &1["timing_3sigma_s"] == 72.0 and
                 &1["execution_uncertainty_source"] == "maneuver_review_covariance" and
                 &1["feedback_source"] ==
                   "prior_plan.operator_review_package.rows.source_maneuver_review" and
                 &1["derivation_reasons"] == ["maneuver_review_uncertainty"])
           )

    realized_branch = branch(artifact, "derived_realized_feedback_dl_feedback")

    assert Enum.any?(
             realized_branch["events"],
             &(&1["type"] == "contact_success_feedback" and
                 &1["contact_success_factor"] == 0.0 and
                 &1["contact_result"] == "accepted,dropped" and
                 &1["feedback_source"] ==
                   "prior_plan.operator_review_package.rows.source_feedback" and
                 &1["feedback_scope"] == "realized_feedback" and
                 &1["trust_boundary"] == "ops_review_queue")
           )

    assert Enum.any?(
             realized_branch["events"],
             &(&1["type"] == "station_throughput_feedback" and
                 &1["station_throughput_factor"] == 0.2 and
                 &1["feedback_source"] ==
                   "prior_plan.operator_review_package.rows.source_feedback" and
                 &1["trust_boundary"] == "ops_review_queue")
           )

    assert get_in(artifact, ["operational_feedback", "image_quality_score"]) == %{
             "target_a" => 0.35
           }

    assert get_in(artifact, ["operational_feedback", "image_quality_status"]) == %{
             "target_a" => "marginal"
           }

    assert get_in(artifact, ["operational_feedback", "image_quality_source"]) == %{
             "target_a" => "provider_image_assessment"
           }

    assert get_in(artifact, ["operational_feedback", "cloud_cover_fraction"]) == %{
             "target_a" => 0.65
           }

    assert get_in(artifact, ["operational_feedback", "blur_score"]) == %{
             "target_a" => 0.25
           }

    quality_branch = branch(artifact, "derived_observation_quality_feedback")

    assert %{
             "type" => "observation_success_feedback",
             "target_id" => "target_a",
             "observation_success_factor" => 0.35,
             "image_quality_score" => 0.35,
             "image_quality_status" => "marginal",
             "image_quality_source" => "provider_image_assessment",
             "cloud_cover_fraction" => 0.65,
             "blur_score" => 0.25,
             "feedback_source" => "operational_feedback.image_quality_score"
           } = List.first(quality_branch["events"])

    cadence_command_branch = branch(artifact, "derived_command_window_feedback_cmd_import")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_import",
             "command_success_factor" => 0.3,
             "command_result" => "accepted,missed",
             "station_calendar_entry_id" => "cmd_import_provider_reservation",
             "station_calendar_provider_id" => "partner_calendar",
             "station_calendar_provider_entry_id" => "partner_cmd_entry_2",
             "station_reservation_id" => "reservation_cmd_import_partner",
             "feedback_source" =>
               "prior_plan.cadence_import_manifest.rows.source_review_row.source_command_window",
             "trust_boundary" => "cadence_review_queue"
           } = List.first(cadence_command_branch["events"])

    flat_cadence_command_branch =
      branch(artifact, "derived_command_window_feedback_cmd_flat_import")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_flat_import",
             "command_success_factor" => 0.35,
             "command_result" => "accepted,rejected",
             "feedback_source" => "prior_plan.cadence_import_manifest.rows.source_command_window",
             "trust_boundary" => "cadence_review_queue"
           } = List.first(flat_cadence_command_branch["events"])

    cadence_maneuver_branch = branch(artifact, "derived_maneuver_review_feedback_trim_import")

    assert %{
             "type" => "maneuver_success_feedback",
             "activity_id" => "trim_import",
             "maneuver_success_factor" => 0.2,
             "maneuver_result" => "accepted,missed",
             "feedback_source" =>
               "prior_plan.cadence_import_manifest.rows.source_maneuver_review",
             "trust_boundary" => "cadence_review_queue"
           } =
             Enum.find(
               cadence_maneuver_branch["events"],
               &(&1["type"] == "maneuver_success_feedback")
             )

    assert Enum.any?(
             cadence_maneuver_branch["events"],
             &(&1["type"] == "maneuver_execution_uncertainty_feedback" and
                 &1["activity_id"] == "trim_import" and
                 &1["timing_3sigma_s"] == 88.0 and
                 &1["execution_uncertainty_source"] == "cadence_maneuver_review_covariance" and
                 &1["feedback_source"] ==
                   "prior_plan.cadence_import_manifest.rows.source_maneuver_review" and
                 &1["derivation_reasons"] == ["maneuver_review_uncertainty"])
           )

    cadence_realized_branch = branch(artifact, "derived_realized_feedback_obs_import_feedback")

    assert %{
             "type" => "observation_success_feedback",
             "activity_id" => "obs_import_feedback",
             "target_id" => "target_a",
             "observation_success_factor" => cadence_observation_success_factor,
             "observation_result" => "accepted,failed",
             "feedback_source" => "prior_plan.cadence_import_manifest.rows.source_feedback",
             "trust_boundary" => "cadence_review_queue"
           } = List.first(cadence_realized_branch["events"])

    assert cadence_observation_success_factor == 0.0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    command_row_index =
      Enum.find_index(
        artifact["branch_comparison_report"]["rows"],
        &(&1["branch_id"] == "derived_command_window_feedback_cmd_review")
      )

    routing_context_invalid =
      put_in(
        artifact,
        [
          "branch_comparison_report",
          "rows",
          Access.at(command_row_index),
          "branch_directions"
        ],
        ["downlink"]
      )

    assert {:error, routing_validation_report} =
             Schema.validate_artifact(routing_context_invalid)

    assert Enum.any?(
             routing_validation_report["errors"],
             &(&1["path"] ==
                 "$.branch_comparison_report.rows[#{command_row_index}].branch_directions")
           )

    calendar_context_invalid =
      put_in(
        artifact,
        [
          "branch_comparison_report",
          "rows",
          Access.at(command_row_index),
          "branch_station_calendar_provider_ids"
        ],
        ["drift_provider"]
      )

    assert {:error, calendar_validation_report} =
             Schema.validate_artifact(calendar_context_invalid)

    assert Enum.any?(
             calendar_validation_report["errors"],
             &(&1["path"] ==
                 "$.branch_comparison_report.rows[#{command_row_index}].branch_station_calendar_provider_ids")
           )
  end

  defp command(id, scenario_id, starts_at_s, ends_at_s) do
    %{
      "id" => id,
      "type" => "command",
      "scenario_id" => scenario_id,
      "direction" => "uplink",
      "ground_station_id" => "equator_prime",
      "starts_at_s" => starts_at_s,
      "ends_at_s" => ends_at_s,
      "duration_s" => ends_at_s - starts_at_s,
      "score" => 1.0
    }
  end
end
