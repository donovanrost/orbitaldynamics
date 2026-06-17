Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyOperationalFeedbackTelemetryRefreshTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.{CandidateRefresh, Schema, TimelineFeedback}

  test "strategy derives resource margin branch from source timeline feedback report" do
    feedback_report =
      TimelineFeedback.reconcile(
        [],
        [
          %{
            id: :resource_snapshot_1,
            type: :resource_snapshot,
            status: :completed,
            spacecraft_id: :leo_1,
            battery_capacity_wh: 100.0,
            battery_energy_used_wh: 95.0,
            battery_state_of_charge: 0.05,
            trust_boundary: :ops_telemetry
          }
        ]
      )

    prior_plan =
      base_plan(%{
        "activities" => [
          observe("obs_storage", "leo_1", "target_a", 100.0, 160.0, 20.0)
          |> Map.put("estimated_storage_mb", 25.0)
        ],
        "source_timeline_feedback_report" => feedback_report
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    resource_branch = branch(artifact, "derived_resource_margin_feedback")

    assert %{
             "type" => "resource_margin_pressure",
             "spacecraft_id" => "leo_1",
             "resource_field" => "power_margin",
             "power_margin" => 0.05,
             "feedback_source" => "operational_feedback.resource_margin_overrides"
           } = Enum.find(resource_branch["events"], &(&1["resource_field"] == "power_margin"))

    assert get_in(artifact, ["operational_feedback", "resource_margin_overrides"]) == %{
             "leo_1" => %{
               "battery_capacity_wh" => 100.0,
               "battery_energy_used_wh" => 95.0,
               "battery_state_of_charge" => 0.05,
               "power_margin" => 0.05
             }
           }

    assert Enum.any?(
             resource_branch["repair_result"]["source_resource_summaries"],
             &(&1["spacecraft_id"] == "leo_1" and &1["battery_state_of_charge"] == 0.05 and
                 &1["power_margin"] == 0.05)
           )

    assert %{
             "source" => "prior_plan.source_timeline_feedback_report.operational_feedback",
             "input_keys" => ["resource_margin_overrides"],
             "source_report_contract" => "timeline_feedback_report.v1",
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["ops_telemetry"]
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] ==
                   "prior_plan.source_timeline_feedback_report.operational_feedback")
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives thermal margin branch from source timeline feedback report" do
    feedback_report =
      TimelineFeedback.reconcile(
        [],
        [
          %{
            id: :thermal_snapshot_1,
            type: :resource_snapshot,
            status: :completed,
            spacecraft_id: :leo_1,
            thermal_margin_c: "1.5",
            trust_boundary: :ops_thermal_telemetry
          }
        ]
      )

    prior_plan =
      base_plan(%{
        "activities" => [
          observe("obs_thermal", "leo_1", "target_a", 100.0, 160.0, 20.0)
        ],
        "source_timeline_feedback_report" => feedback_report
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        branch_generation_policy: %{thermal_margin_c_threshold: "2.0"},
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    resource_branch = branch(artifact, "derived_resource_margin_feedback")

    assert %{
             "type" => "resource_margin_pressure",
             "spacecraft_id" => "leo_1",
             "resource_field" => "thermal_margin_c",
             "thermal_margin_c" => 1.5,
             "thermal_margin_c_threshold" => 2.0,
             "feedback_source" => "operational_feedback.resource_margin_overrides"
           } = List.first(resource_branch["events"])

    assert get_in(artifact, ["operational_feedback", "resource_margin_overrides"]) == %{
             "leo_1" => %{"thermal_margin_c" => 1.5}
           }

    assert Enum.any?(
             resource_branch["repair_result"]["source_resource_filter_report"][
               "suppressed_candidates"
             ],
             &(&1["suppressed_reason"] == "thermal_margin_below_policy" and
                 &1["thermal_margin_c"] == 1.5)
           )

    assert %{
             "source" => "prior_plan.source_timeline_feedback_report.operational_feedback",
             "input_keys" => ["resource_margin_overrides"],
             "source_report_contract" => "timeline_feedback_report.v1",
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["ops_thermal_telemetry"]
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] ==
                   "prior_plan.source_timeline_feedback_report.operational_feedback")
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives resource availability refresh branch from operational feedback" do
    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state_with_refresh_inputs(),
        operational_feedback: %{
          resource_availability_overrides: %{"leo_1" => %{antenna_status: "Maintenance"}}
        },
        approval_policy: %{policy_bundle_id: "degraded_payload_guard_v1"},
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    availability_branch = branch(artifact, "derived_resource_availability_feedback")

    assert %{
             "type" => "resource_availability_constraint",
             "spacecraft_id" => "leo_1",
             "resource_field" => "antenna_available",
             "available" => false,
             "derivation_reasons" => ["antenna_availability_feedback_false"],
             "feedback_source" => "operational_feedback.resource_availability_overrides"
           } = List.first(availability_branch["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             availability_branch["assumptions"]["candidate_source"]

    assert Enum.any?(
             availability_branch["repair_result"]["source_resource_summaries"],
             &(&1["spacecraft_id"] == "leo_1" and &1["antenna_available"] == false and
                 get_in(&1, ["provenance", "event_type"]) == "resource_availability_constraint")
           )

    assert %{
             "schema_contract" => "resource_filter_report.v1",
             "suppressed_candidate_count" => suppressed_count,
             "suppressed_candidates" => suppressed
           } = availability_branch["repair_result"]["source_resource_filter_report"]

    assert suppressed_count > 0

    assert Enum.any?(suppressed, fn row ->
             row["suppressed_reason"] == "antenna_unavailable" and
               row["approval_status"] == "blocked_by_policy" and
               get_in(row, ["policy_decision", "policy_bundle_id"]) == "degraded_payload_guard_v1" and
               Enum.any?(
                 row["approval_rule_matches"],
                 &(&1["rule_id"] == "antenna_unavailable_contact_block" and
                     &1["antenna_available"] == false)
               )
           end)

    refute Enum.any?(
             availability_branch["repair_result"]["source_candidate_activities"],
             &(&1["type"] == "downlink" and &1["scenario_id"] == "leo_1")
           )

    assert Enum.any?(
             availability_branch["risk_indicators"],
             &(&1["type"] == "antenna_unavailable" and &1["value"] == false)
           )

    availability_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_resource_availability_feedback"))

    assert availability_row["antenna_availability"] == 0.0
    assert "antenna_availability_low" in availability_row["resource_risk_types"]

    assert "resource summary filters suppressed refreshed candidates" in availability_branch[
             "warnings"
           ]

    assert_resource_availability_pressure_score_terms(availability_branch, artifact)

    assert Enum.any?(
             artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "resource_suppression" and
                 &1["branch_id"] == "derived_resource_availability_feedback" and
                 &1["source"] ==
                   "campaign_strategy.branches.repair_result.source_resource_filter_report.suppressed_candidates" and
                 &1["required_operator_action"] == "review_suppressed_contact" and
                 &1["source_policy_decision"]["policy_bundle_id"] ==
                   "degraded_payload_guard_v1")
           )

    assert Enum.any?(
             artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "warning" and
                 &1["branch_id"] == "derived_resource_availability_feedback" and
                 &1["source"] == "campaign_strategy.branches.warnings" and
                 &1["reason"] == "resource summary filters suppressed refreshed candidates")
           )

    assert Enum.any?(
             artifact["cadence_import_manifest"]["rows"],
             &(&1["import_action"] == "review_resource_suppression" and
                 &1["source_review_type"] == "resource_suppression" and
                 &1["branch_id"] == "derived_resource_availability_feedback" and
                 get_in(&1, ["source_review_row", "branch_id"]) ==
                   &1["branch_id"])
           )

    assert Enum.any?(
             artifact["cadence_import_manifest"]["rows"],
             &(&1["import_action"] == "review_warning" and
                 &1["source_review_type"] == "warning" and
                 get_in(&1, ["source_review_row", "branch_id"]) ==
                   "derived_resource_availability_feedback" and
                 &1["reason"] == "resource summary filters suppressed refreshed candidates")
           )

    assert get_in(artifact, ["operational_feedback", "resource_availability_overrides"]) == %{
             "leo_1" => %{"antenna_available" => false, "antenna_status" => "Maintenance"}
           }

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives resource availability refresh branch from realized resource telemetry" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "resource_snapshot_1",
          type: "resource_snapshot",
          status: "completed",
          scenario_id: "leo_1",
          payload_available?: false,
          antenna_available: false
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    availability_branch = branch(artifact, "derived_resource_availability_feedback")

    assert %{
             "type" => "resource_availability_constraint",
             "spacecraft_id" => "leo_1",
             "resource_field" => "antenna_available",
             "available" => false,
             "feedback_source" => "operational_feedback.resource_availability_overrides"
           } =
             Enum.find(
               availability_branch["events"],
               &(&1["resource_field"] == "antenna_available")
             )

    assert %{
             "type" => "resource_availability_constraint",
             "spacecraft_id" => "leo_1",
             "resource_field" => "payload_available",
             "available" => false,
             "feedback_source" => "operational_feedback.resource_availability_overrides"
           } =
             Enum.find(
               availability_branch["events"],
               &(&1["resource_field"] == "payload_available")
             )

    assert get_in(artifact, ["operational_feedback", "resource_availability_overrides"]) == %{
             "leo_1" => %{"antenna_available" => false, "payload_available" => false}
           }

    assert %{
             "source" => "mission_state.realized_activities",
             "input_keys" => ["resource_availability_overrides"]
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] == "mission_state.realized_activities")
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy conservatively merges repeated realized resource telemetry" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "resource_snapshot_1",
          type: "resource_snapshot",
          status: "completed",
          spacecraft_id: "leo_1",
          storage_margin: 0.4,
          battery_capacity_wh: 100.0,
          battery_energy_used_wh: 40.0,
          battery_state_of_charge: 0.4,
          payload_available: true,
          incompatible_activity_types: ["observe"]
        },
        %{
          id: "resource_snapshot_2",
          type: "resource_snapshot",
          status: "completed",
          spacecraft_id: "leo_1",
          storage_margin: 0.05,
          battery_energy_used_wh: 95.0,
          battery_state_of_charge: 0.05,
          payload_available: false,
          incompatible_activity_types: ["downlink"]
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "resource_margin_overrides"]) == %{
             "leo_1" => %{
               "battery_capacity_wh" => 100.0,
               "battery_energy_used_wh" => 95.0,
               "battery_state_of_charge" => 0.05,
               "power_margin" => 0.05,
               "storage_margin" => 0.05
             }
           }

    assert get_in(artifact, ["operational_feedback", "resource_availability_overrides"]) == %{
             "leo_1" => %{
               "payload_available" => false,
               "incompatible_activity_types" => ["downlink", "observe"]
             }
           }

    resource_branch = branch(artifact, "derived_resource_margin_feedback")
    availability_branch = branch(artifact, "derived_resource_availability_feedback")

    assert %{"storage_margin" => 0.05} =
             Enum.find(resource_branch["events"], &(&1["resource_field"] == "storage_margin"))

    assert %{"power_margin" => 0.05} =
             Enum.find(resource_branch["events"], &(&1["resource_field"] == "power_margin"))

    assert %{"available" => false} =
             Enum.find(
               availability_branch["events"],
               &(&1["resource_field"] == "payload_available")
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives degraded spacecraft refresh branch from operational availability feedback" do
    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state_with_refresh_inputs(),
        operational_feedback: %{
          resource_availability_overrides: %{
            "leo_1" => %{
              spacecraft_availability: false,
              incompatible_activity_types: ["observe", "downlink", "planned_contact"]
            }
          }
        },
        approval_policy: %{policy_bundle_id: "degraded_payload_guard_v1"},
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    availability_branch = branch(artifact, "derived_resource_availability_feedback")

    assert %{
             "type" => "degraded_spacecraft",
             "scenario_id" => "leo_1",
             "spacecraft_id" => "leo_1",
             "incompatible_activity_types" => ["downlink", "observe", "planned_contact"],
             "derivation_reasons" => ["spacecraft_available_feedback_false"],
             "feedback_source" => "operational_feedback.resource_availability_overrides",
             "feedback_scope" => "spacecraft"
           } = List.first(availability_branch["events"])

    assert Enum.any?(
             availability_branch["repair_result"]["source_resource_summaries"],
             &(&1["spacecraft_id"] == "leo_1" and &1["degraded"] == true and
                 &1["spacecraft_available"] == false and
                 &1["payload_available"] == false and &1["antenna_available"] == false and
                 get_in(&1, ["provenance", "event_type"]) == "degraded_spacecraft" and
                 get_in(&1, ["assumptions", "feedback_source"]) ==
                   "operational_feedback.resource_availability_overrides")
           )

    assert %{
             "schema_contract" => "resource_filter_report.v1",
             "suppressed_candidate_count" => suppressed_count,
             "suppressed_candidates" => suppressed_candidates
           } = availability_branch["repair_result"]["source_resource_filter_report"]

    assert suppressed_count > 0

    assert Enum.any?(
             suppressed_candidates,
             &(&1["suppressed_reason"] == "spacecraft_unavailable" and
                 &1["resource_blocking_dimension"] == "spacecraft_health" and
                 &1["spacecraft_available"] == false)
           )

    refute Enum.any?(
             availability_branch["repair_result"]["source_candidate_activities"],
             &(&1["scenario_id"] == "leo_1" and &1["type"] in ["observe", "downlink"])
           )

    assert Enum.any?(
             availability_branch["risk_indicators"],
             &(&1["type"] == "spacecraft_degraded" and &1["spacecraft_id"] == "leo_1")
           )

    assert %{
             "schema_contract" => "resource_projection_report.v1",
             "projected_resources" => [
               %{
                 "spacecraft_id" => "leo_1",
                 "spacecraft_available" => false,
                 "resource_pressure_status" => "spacecraft_unavailable",
                 "resource_pressure_types" => ["spacecraft_unavailable"],
                 "effective_activity_count" => 0
               }
             ]
           } = availability_branch["resource_projection_report"]

    assert Enum.any?(
             availability_branch["risk_indicators"],
             &(&1["type"] == "spacecraft_unavailable" and &1["spacecraft_id"] == "leo_1" and
                 &1["resource_pressure_status"] == "spacecraft_unavailable")
           )

    assert availability_branch["resource_impacts"]["spacecraft_availability"] == 0.0
    assert availability_branch["resource_impacts"]["payload_availability"] == 0.0
    assert availability_branch["resource_impacts"]["antenna_availability"] == 0.0

    availability_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_resource_availability_feedback"))

    assert availability_row["spacecraft_availability"] == 0.0
    assert availability_row["payload_availability"] == 0.0
    assert availability_row["antenna_availability"] == 0.0
    assert "spacecraft_availability_low" in availability_row["resource_risk_types"]
    assert availability_row["resource_projection_unavailable_spacecraft_count"] == 1
    assert availability_row["resource_projection_unavailable_spacecraft_ids"] == ["leo_1"]

    assert get_in(artifact, ["operational_feedback", "resource_availability_overrides"]) == %{
             "leo_1" => %{
               "spacecraft_available" => false,
               "incompatible_activity_types" => ["observe", "downlink", "planned_contact"]
             }
           }

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives station throughput feedback from realized contact telemetry" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "prior_contact",
          type: "downlink",
          ground_station_id: "equator_prime",
          status: "completed",
          actual_throughput_mb: 50.0,
          estimated_throughput_mb: 100.0
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    downlink =
      artifact
      |> branch("urgent")
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime"))

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 0.5
           }

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 1.0
           }

    assert get_in(downlink, ["throughput_model", "station_capacity_fraction"]) == 0.5
    assert downlink["station_availability"] == "reduced_capacity"
  end

  test "strategy derives station throughput feedback from realized contact data rate telemetry" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "prior_contact",
          type: "downlink",
          ground_station_id: "equator_prime",
          status: "partial",
          actual_data_rate_mbps: 8.0,
          actual_duration_s: 60.0,
          estimated_throughput_mb: 120.0,
          required_downlink_mb: 120.0
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    downlink =
      artifact
      |> branch("urgent")
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime"))

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 0.5
           }

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{
             "equator_prime" => 60.0
           }

    assert get_in(downlink, ["throughput_model", "station_capacity_fraction"]) == 0.5
  end

  test "strategy derives contact feedback by joining sparse realized rows to planned contacts" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "prior_contact",
          status: "completed",
          actual_throughput_mb: 50.0
        }
      ])

    prior_contact =
      downlink("prior_contact", 100.0, 160.0)
      |> Map.put("estimated_throughput_mb", 100.0)

    artifact =
      strategy(base_plan(%{"activities" => [prior_contact]}),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    downlink =
      artifact
      |> branch("urgent")
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime"))

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 0.5
           }

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 1.0
           }

    assert get_in(downlink, ["throughput_model", "station_capacity_fraction"]) == 0.5
  end

  test "strategy treats executed and rejected contact telemetry as success-rate evidence" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{id: "executed_contact", status: "executed"},
        %{id: "rejected_contact", status: "rejected"}
      ])

    artifact =
      strategy(
        base_plan(%{
          "activities" => [
            downlink("executed_contact", 100.0, 160.0),
            downlink("rejected_contact", 220.0, 280.0)
          ]
        }),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 0.5
           }

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy weights direct realized contact feedback by provider confidence" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "executed_contact",
          status: "executed",
          actual_throughput_mb: 100.0,
          confidence_weight: 1.0,
          confidence_weight_source: "provider_confidence"
        },
        %{
          id: "rejected_contact",
          status: "executed",
          contact_success: " FALSE ",
          actual_throughput_mb: 0.0,
          confidence_weight: 3.0,
          confidence_weight_source: "provider_confidence"
        }
      ])

    artifact =
      strategy(
        base_plan(%{
          "activities" => [
            downlink("executed_contact", 100.0, 160.0)
            |> Map.put("estimated_throughput_mb", 100.0),
            downlink("rejected_contact", 220.0, 280.0)
            |> Map.put("estimated_throughput_mb", 100.0)
          ]
        }),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    downlink =
      artifact
      |> branch("urgent")
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime"))

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 0.25
           }

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 0.25
           }

    assert get_in(downlink, ["throughput_model", "station_capacity_fraction"]) == 0.25
    assert get_in(downlink, ["throughput_model", "contact_success_factor"]) == 0.25

    assert %{
             "source" => "mission_state.realized_activities",
             "weighted_feedback_row_count" => 2,
             "feedback_weight_sources" => ["provider_confidence"]
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] == "mission_state.realized_activities")
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives contact success feedback from provider contact result aliases" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{id: "provider_contact", type: "contact", status: "completed", contact_result: "dropped"}
      ])

    artifact =
      strategy(
        base_plan(%{
          "activities" => [downlink("provider_contact", 100.0, 160.0)]
        }),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    downlink =
      artifact
      |> branch("urgent")
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime"))

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 0.0
           }

    assert get_in(downlink, ["throughput_model", "contact_success_factor"]) == 0.0

    assert Enum.any?(
             branch(artifact, "urgent")["risk_indicators"],
             &(&1["type"] == "contact_success_rate_low" and &1["value"] == 0.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy uses partial completed fraction for contact success feedback" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{id: "partial_contact", status: "partial", completed_fraction: 0.35}
      ])

    artifact =
      strategy(
        base_plan(%{
          "activities" => [downlink("partial_contact", 100.0, 160.0)]
        }),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    downlink =
      artifact
      |> branch("urgent")
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime"))

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 0.35
           }

    assert get_in(downlink, ["throughput_model", "contact_success_factor"]) == 0.35

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy review-gates out-of-range direct realized unit-interval telemetry" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{id: "partial_contact", status: "partial", completed_fraction: 1.4},
        %{
          id: "obs_quality",
          type: "observe",
          status: "completed",
          target_id: "target_a",
          completed_fraction: -0.2,
          image_quality_score: 1.5,
          cloud_cover_fraction: -0.25,
          blur_score: "bad"
        }
      ])

    artifact =
      strategy(
        base_plan(%{
          "activities" => [
            downlink("partial_contact", 100.0, 160.0),
            observe("obs_quality", "leo_1", "target_a", 180.0, 240.0, 10.0)
          ]
        }),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{}
    assert get_in(artifact, ["operational_feedback", "observation_success_rate"]) == %{}
    assert get_in(artifact, ["operational_feedback", "image_quality_score"]) == %{}
    assert get_in(artifact, ["operational_feedback", "cloud_cover_fraction"]) == %{}
    assert get_in(artifact, ["operational_feedback", "blur_score"]) == %{}

    realized_source =
      Enum.find(
        artifact["operational_feedback_provenance"]["sources"],
        &(&1["source"] == "mission_state.realized_activities")
      )

    assert %{
             "input_keys" => ["invalid_operational_feedback_input"],
             "invalid_operational_feedback_input" => true,
             "invalid_operational_feedback_input_reason" =>
               "operational_feedback_sections_invalid",
             "invalid_operational_feedback_sections" => invalid_sections
           } = realized_source

    assert %{
             "field" => "realized_activities.completed_fraction",
             "reason" => "value_must_be_between_0_and_1",
             "invalid_feedback_value" => 1.4,
             "row_id" => "partial_contact",
             "row_index" => 1
           } in invalid_sections

    assert %{
             "field" => "realized_activities.completed_fraction",
             "reason" => "value_must_be_between_0_and_1",
             "invalid_feedback_value" => -0.2,
             "row_id" => "obs_quality",
             "row_index" => 2
           } in invalid_sections

    assert %{
             "field" => "realized_activities.image_quality_score",
             "reason" => "value_must_be_between_0_and_1",
             "invalid_feedback_value" => 1.5,
             "row_id" => "obs_quality",
             "row_index" => 2
           } in invalid_sections

    assert %{
             "field" => "realized_activities.cloud_cover_fraction",
             "reason" => "value_must_be_between_0_and_1",
             "invalid_feedback_value" => -0.25,
             "row_id" => "obs_quality",
             "row_index" => 2
           } in invalid_sections

    assert %{
             "field" => "realized_activities.blur_score",
             "reason" => "entry_must_be_unit_interval_number",
             "invalid_feedback_shape" => "bad",
             "row_id" => "obs_quality",
             "row_index" => 2
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

  test "strategy derives contact feedback from station-id planned-contact context" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "prior_contact",
          status: "completed",
          actual_throughput_mb: 50.0
        }
      ])

    prior_contact = %{
      "id" => "prior_contact",
      "type" => "planned_contact",
      "direction" => "Down-Link",
      "station_id" => "equator_prime",
      "scenario_id" => "leo_1",
      "starts_at_s" => 100.0,
      "ends_at_s" => 160.0,
      "estimated_throughput_mb" => 100.0
    }

    artifact =
      strategy(base_plan(%{"activities" => [prior_contact]}),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    downlink =
      artifact
      |> branch("urgent")
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime"))

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 0.5
           }

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 1.0
           }

    assert get_in(downlink, ["throughput_model", "station_capacity_fraction"]) == 0.5
  end

  test "strategy does not derive sparse contact feedback from duplicate planned activity ids" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "duplicate_activity",
          status: "completed",
          actual_throughput_mb: 50.0
        }
      ])

    artifact =
      strategy(
        base_plan(%{
          "activities" => [
            observe("duplicate_activity", "leo_1", "target_a", 120.0, 240.0, 42.0),
            downlink("duplicate_activity", 100.0, 160.0)
            |> Map.put("estimated_throughput_mb", 100.0)
          ]
        }),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{}
    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{}
  end

  test "explicit operational feedback overrides mission-state derived contact telemetry" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "prior_contact",
          type: "downlink",
          ground_station_id: "equator_prime",
          status: "completed",
          actual_throughput_mb: 50.0,
          estimated_throughput_mb: 100.0
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        operational_feedback: %{
          station_throughput_factor: %{"equator_prime" => 0.8}
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

    downlink =
      artifact
      |> branch("urgent")
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime"))

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 0.8
           }

    assert get_in(downlink, ["throughput_model", "station_capacity_fraction"]) == 0.8
  end

  test "strategy-derived refresh applies contact success feedback to generated contacts" do
    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state_with_refresh_inputs(),
        operational_feedback: %{
          contact_success_rate: %{"equator_prime" => 0.4}
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

    downlink =
      artifact
      |> branch("urgent")
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime"))

    assert downlink["contact_success_factor"] == 0.4

    assert downlink["contact_success_factor_source"] ==
             "operational_feedback.contact_success_rate.station"

    assert get_in(downlink, ["throughput_model", "contact_success_factor"]) == 0.4

    assert get_in(downlink, ["throughput_model", "confidence_source"]) ==
             "operational_feedback.contact_success_rate.station"

    assert downlink["score_terms"]["contact_success_adjustment"] < 0.0

    assert_in_delta downlink["score"],
                    downlink["score_terms"]["contact_value"] +
                      downlink["score_terms"]["contact_success_adjustment"],
                    1.0e-9
  end

  test "strategy-derived refresh applies branch-local feedback events to generated contacts" do
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
                station_throughput_factor: 0.25
              },
              %{
                type: "contact_success_feedback",
                ground_station_id: "equator_prime",
                contact_success_factor: 0.4
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    feedback_branch = branch(artifact, "branch_feedback")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             feedback_branch["assumptions"]["candidate_source"]

    downlink =
      feedback_branch
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime"))

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{}
    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{}
    assert get_in(downlink, ["throughput_model", "station_capacity_fraction"]) == 0.25
    assert get_in(downlink, ["throughput_model", "contact_success_factor"]) == 0.4

    assert feedback_branch["feedback_adjustments"]["station_throughput_factor"] == 0.25
    assert feedback_branch["feedback_adjustments"]["contact_success_factor"] == 0.4
    assert feedback_branch["score_terms"]["feedback_adjustment_score"] < 0.0

    assert downlink["contact_success_factor_source"] ==
             "operational_feedback.contact_success_rate.station"

    assert downlink["score_terms"]["contact_success_adjustment"] < 0.0

    feedback_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "branch_feedback"))

    assert feedback_row["station_throughput_factor"] == 0.25
    assert feedback_row["contact_success_factor"] == 0.4
    assert "station_throughput_factor_low" in feedback_row["feedback_risk_types"]
    assert "contact_success_rate_low" in feedback_row["feedback_risk_types"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy-derived refresh keeps mission-state timeline feedback report provenance" do
    feedback_report =
      TimelineFeedback.reconcile(
        [
          %{
            id: :selected_dl,
            type: :downlink,
            ground_station_id: :equator_prime,
            direction: :downlink,
            starts_at_s: 100.0,
            ends_at_s: 160.0,
            required_downlink_mb: 360.0
          }
        ],
        [
          %{
            id: :selected_dl,
            type: :downlink,
            status: :partial,
            actual_throughput_mb: 120.0,
            trust_boundary: :ops_timeline_review
          }
        ]
      )

    artifact =
      strategy(base_plan(%{"activities" => [downlink("selected_dl", 100.0, 160.0)]}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_timeline_feedback_report, feedback_report),
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

    assert %{
             "type" => "candidate_refresh.v1",
             "scope" => "branch_generated"
           } = candidate_source = urgent_branch["assumptions"]["candidate_source"]

    assert get_in(urgent_branch, [
             "assumptions",
             "candidate_source",
             "source_operational_feedback_provenance",
             "derived_from_source_timeline_feedback_report"
           ])

    assert get_in(urgent_branch, [
             "assumptions",
             "candidate_source",
             "source_operational_feedback_provenance",
             "source_timeline_feedback_report_paths"
           ]) == ["source_timeline_feedback_report"]

    assert get_in(urgent_branch, [
             "assumptions",
             "candidate_source",
             "source_operational_feedback_provenance",
             "source_timeline_feedback_report_row_count"
           ]) == 1

    assert "downlink_demand_mb" in get_in(
             urgent_branch,
             ["assumptions", "candidate_source", "operational_feedback_input_keys"]
           )

    timeline_feedback_replay_summary =
      CandidateRefresh.timeline_feedback_replay_summary(candidate_source)

    assert %{
             "source" =>
               "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_feedback_report",
             "contract" => "timeline_feedback_report.v1",
             "source_report_count" => 1,
             "source_report_row_count" => 1,
             "source_report_paths" => ["source_timeline_feedback_report"],
             "input_keys" => timeline_feedback_input_keys,
             "status_counts" => %{"matched" => 1},
             "feedback_kind_counts" => %{"contact" => 1},
             "match_strategy_counts" => %{"activity_id" => 1},
             "station_reservation_evidence_row_count" => 0,
             "station_reservation_expiration_evidence_row_count" => 0,
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["ops_timeline_review"],
             "branch_local_timeline_feedback_pressure" => true,
             "branch_local_feedback_input_pressure" => true,
             "branch_local_match_review_pressure" => true,
             "branch_local_station_reservation_pressure" => false,
             "assumptions" => %{
               "replay_scope" => "timeline_feedback_candidate_source_report_summary_only"
             }
           } = timeline_feedback_replay_summary

    assert "downlink_demand_mb" in timeline_feedback_input_keys
    assert "station_throughput_factor" in timeline_feedback_input_keys

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
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
end
