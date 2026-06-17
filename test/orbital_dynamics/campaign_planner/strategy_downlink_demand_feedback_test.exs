Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyDownlinkDemandFeedbackTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.{Schema, TimelineFeedback}
  alias OrbitalDynamics.CampaignPlanner.MissionState

  test "strategy derives downlink demand refresh branch from operational feedback" do
    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state_with_refresh_inputs(),
        operational_feedback: %{
          downlink_demand_mb: %{"equator_prime" => 240.0},
          downlink_demand_sources: %{
            "equator_prime" => ["ops.downlink.backlog:equator_prime"]
          }
        },
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    demand_branch = branch(artifact, "derived_downlink_demand_feedback")

    assert %{
             "type" => "downlink_demand_feedback",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 240.0,
             "feedback_source" => "operational_feedback.downlink_demand_mb",
             "downlink_demand_sources" => ["ops.downlink.backlog:equator_prime"]
           } = List.first(demand_branch["events"])

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{
             "equator_prime" => 240.0
           }

    assert get_in(artifact, ["operational_feedback", "downlink_demand_sources"]) == %{
             "equator_prime" => ["ops.downlink.backlog:equator_prime"]
           }

    downlink =
      demand_branch
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime"))

    assert downlink["required_downlink_mb"] == 240.0
    assert downlink["candidate_downlink_mb"] == downlink["estimated_throughput_mb"]

    assert downlink["downlink_completion_source"] ==
             "operational_feedback.downlink_demand_mb.station"

    assert downlink["downlink_completion_sources"] == ["ops.downlink.backlog:equator_prime"]

    assert downlink["score_terms"]["downlink_completion_value"] > 0.0

    assert Enum.any?(
             demand_branch["risk_indicators"],
             &(&1["type"] == "downlink_demand_declared" and &1["value"] == 240.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives downlink demand branch from prior repair timeline feedback" do
    feedback_report =
      TimelineFeedback.reconcile(
        [
          %{
            id: :dl_feedback,
            type: :downlink,
            direction: :downlink,
            ground_station_id: :equator_prime,
            starts_at_s: 10.0,
            ends_at_s: 40.0,
            required_downlink_mb: 360.0
          }
        ],
        [
          %{
            id: :dl_feedback,
            type: :downlink,
            status: :partial,
            actual_throughput_mb: 120.0
          }
        ]
      )

    prior_repair =
      base_plan(%{
        "schema_version" => 2,
        "planner" => "OrbitalDynamics.CampaignPlanner.V2",
        "source_candidate_activities" => [refreshed_downlink("candidate_dl_1", 300.0, 360.0)],
        "source_timeline_feedback_report" => feedback_report
      })

    artifact =
      strategy(prior_repair,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{
             "equator_prime" => 240.0
           }

    assert get_in(artifact, ["operational_feedback", "downlink_demand_sources"]) == %{
             "equator_prime" => [
               "timeline_feedback.contact.required_downlink_mb:dl_feedback",
               "timeline_feedback.realized_activity:dl_feedback"
             ]
           }

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 120.0 / 360.0
           }

    demand_branch = branch(artifact, "derived_downlink_demand_feedback")
    throughput_branch = branch(artifact, "derived_station_throughput_feedback")

    assert %{
             "type" => "downlink_demand_feedback",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 240.0,
             "feedback_source" => "operational_feedback.downlink_demand_mb",
             "downlink_demand_sources" => [
               "timeline_feedback.contact.required_downlink_mb:dl_feedback",
               "timeline_feedback.realized_activity:dl_feedback"
             ]
           } = List.first(demand_branch["events"])

    downlink =
      demand_branch
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime"))

    assert downlink["required_downlink_mb"] == 240.0
    assert downlink["downlink_requirement_status"] == "shortfall"
    assert downlink["downlink_shortfall_mb"] > 0.0
    assert get_in(downlink, ["throughput_model", "station_capacity_fraction"]) == 120.0 / 360.0

    assert downlink["downlink_completion_source"] ==
             "operational_feedback.downlink_demand_mb.station"

    assert downlink["downlink_completion_sources"] == [
             "timeline_feedback.contact.required_downlink_mb:dl_feedback",
             "timeline_feedback.realized_activity:dl_feedback"
           ]

    assert %{
             "type" => "station_throughput_feedback",
             "ground_station_id" => "equator_prime",
             "station_throughput_factor" => station_throughput,
             "feedback_source" => "operational_feedback.station_throughput_factor"
           } = List.first(throughput_branch["events"])

    assert_in_delta station_throughput, 120.0 / 360.0, 1.0e-12

    assert %{
             "input_keys" => [
               "contact_success_rate",
               "downlink_demand_mb",
               "downlink_demand_sources",
               "station_throughput_factor"
             ],
             "sources" => [
               %{
                 "source" => "prior_plan.source_timeline_feedback_report.operational_feedback",
                 "input_keys" => [
                   "contact_success_rate",
                   "downlink_demand_mb",
                   "downlink_demand_sources",
                   "station_throughput_factor"
                 ],
                 "source_report_contract" => "timeline_feedback_report.v1",
                 "source_report_row_count" => 1,
                 "source_report_status_counts" => %{"matched" => 1},
                 "source_feedback_kind_counts" => %{"contact" => 1},
                 "source_match_strategy_counts" => %{"activity_id" => 1},
                 "source_cadence_import_status_counts" => %{"missing" => 1},
                 "source_planned_protection_decision_counts" => %{"preserve" => 1},
                 "trust_boundary_status" => "missing"
               }
             ]
           } = artifact["operational_feedback_provenance"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy replays completed-fraction command and contact feedback from prior timeline feedback" do
    feedback_report =
      TimelineFeedback.reconcile(
        [
          %{
            id: :dl_completed_partial,
            type: :downlink,
            direction: :downlink,
            ground_station_id: :equator_prime,
            starts_at_s: 10.0,
            ends_at_s: 40.0,
            required_downlink_mb: 200.0
          },
          %{
            id: :cmd_completed_partial,
            type: :command,
            direction: :command,
            scenario_id: :leo_1,
            starts_at_s: 50.0,
            ends_at_s: 70.0
          }
        ],
        [
          %{
            id: :dl_completed_partial,
            type: :downlink,
            status: :completed,
            completed_fraction: 0.4,
            actual_throughput_mb: 80.0,
            trust_boundary: :ops_contact_feedback
          },
          %{
            id: :cmd_completed_partial,
            type: :command,
            status: :completed,
            completed_fraction: 0.25,
            trust_boundary: :ops_command_feedback
          }
        ]
      )

    prior_repair =
      base_plan(%{
        "schema_version" => 2,
        "planner" => "OrbitalDynamics.CampaignPlanner.V2",
        "activities" => [
          downlink("dl_completed_partial", 10.0, 40.0)
          |> Map.put("required_downlink_mb", 200.0),
          health_check("cmd_completed_partial", "leo_1", 50.0, 70.0)
        ],
        "source_candidate_activities" => [refreshed_downlink("candidate_dl_1", 300.0, 360.0)],
        "source_timeline_feedback_report" => feedback_report
      })

    artifact =
      strategy(prior_repair,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 0.4
           }

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_completed_partial" => 0.25
           }

    contact_branch = branch(artifact, "derived_contact_success_feedback")

    assert %{
             "type" => "contact_success_feedback",
             "ground_station_id" => "equator_prime",
             "contact_success_factor" => 0.4,
             "feedback_source" => "operational_feedback.contact_success_rate",
             "trust_boundary" => "ops_contact_feedback"
           } = List.first(contact_branch["events"])

    command_branch = branch(artifact, "derived_command_success_feedback")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_completed_partial",
             "command_success_factor" => 0.25,
             "feedback_source" => "operational_feedback.command_success_rate",
             "trust_boundary" => "ops_command_feedback"
           } = List.first(command_branch["events"])

    assert %{
             "type" => "downlink_demand_feedback",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 120.0,
             "feedback_source" => "operational_feedback.downlink_demand_mb",
             "trust_boundary" => "ops_contact_feedback"
           } = List.first(branch(artifact, "derived_downlink_demand_feedback")["events"])

    assert %{
             "source" => "prior_plan.source_timeline_feedback_report.operational_feedback",
             "input_keys" => [
               "command_success_rate",
               "contact_success_rate",
               "downlink_demand_mb",
               "downlink_demand_sources",
               "station_throughput_factor"
             ],
             "source_report_contract" => "timeline_feedback_report.v1",
             "source_report_row_count" => 2,
             "source_operational_feedback_provenance" => %{
               "source_count" => 1,
               "sources" => [
                 %{
                   "feedback_trust_boundaries" => %{
                     "command_success_rate" => %{
                       "cmd_completed_partial" => ["ops_command_feedback"]
                     },
                     "contact_success_rate" => %{
                       "equator_prime" => ["ops_contact_feedback"]
                     },
                     "downlink_demand_mb" => %{
                       "equator_prime" => ["ops_contact_feedback"]
                     },
                     "downlink_demand_sources" => %{
                       "equator_prime" => ["ops_contact_feedback"]
                     },
                     "station_throughput_factor" => %{
                       "equator_prime" => ["ops_contact_feedback"]
                     }
                   },
                   "source" => "timeline_feedback_report.rows",
                   "trust_boundary_status" => "declared",
                   "trust_boundaries" => ["ops_command_feedback", "ops_contact_feedback"]
                 }
               ]
             }
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] ==
                   "prior_plan.source_timeline_feedback_report.operational_feedback")
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy preserves direct timeline feedback provenance trust boundaries" do
    feedback_report =
      TimelineFeedback.reconcile(
        [
          %{
            id: :dl_direct_trust,
            type: :downlink,
            direction: :downlink,
            ground_station_id: :equator_prime,
            starts_at_s: 10.0,
            ends_at_s: 40.0,
            required_downlink_mb: 200.0
          }
        ],
        [
          %{
            id: :dl_direct_trust,
            type: :downlink,
            status: :completed,
            completed_fraction: 0.35,
            actual_throughput_mb: 70.0
          }
        ]
      )
      |> Map.put("operational_feedback_provenance", %{
        "source" => "adapter.timeline_feedback_report",
        "trust_boundaries" => [
          "timeline_feedback_contact_archive",
          "timeline_feedback_throughput_archive"
        ],
        "feedback_trust_boundaries" => %{
          "contact_success_rate" => %{
            "equator_prime" => ["timeline_feedback_contact_archive"]
          },
          "station_throughput_factor" => %{
            "equator_prime" => ["timeline_feedback_throughput_archive"]
          }
        }
      })

    prior_repair =
      base_plan(%{
        "schema_version" => 2,
        "planner" => "OrbitalDynamics.CampaignPlanner.V2",
        "activities" => [
          downlink("dl_direct_trust", 10.0, 40.0)
          |> Map.put("required_downlink_mb", 200.0)
        ],
        "source_candidate_activities" => [refreshed_downlink("candidate_dl_1", 300.0, 360.0)],
        "source_timeline_feedback_report" => feedback_report
      })

    artifact =
      strategy(prior_repair,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    source =
      Enum.find(
        artifact["operational_feedback_provenance"]["sources"],
        &(&1["source"] ==
            "prior_plan.source_timeline_feedback_report.operational_feedback")
      )

    assert %{
             "source_operational_feedback_provenance" => %{
               "source" => "adapter.timeline_feedback_report",
               "trust_boundaries" => [
                 "timeline_feedback_contact_archive",
                 "timeline_feedback_throughput_archive"
               ]
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "timeline_feedback_contact_archive",
               "timeline_feedback_throughput_archive"
             ]
           } = source

    assert %{
             "type" => "contact_success_feedback",
             "ground_station_id" => "equator_prime",
             "contact_success_factor" => 0.35,
             "trust_boundary" => "timeline_feedback_contact_archive"
           } = List.first(branch(artifact, "derived_contact_success_feedback")["events"])

    assert %{
             "type" => "station_throughput_feedback",
             "station_throughput_factor" => 0.35,
             "trust_boundary" => "timeline_feedback_throughput_archive"
           } = List.first(branch(artifact, "derived_station_throughput_feedback")["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives refresh branches from mission-state timeline feedback report" do
    feedback_report =
      TimelineFeedback.reconcile(
        [
          %{
            id: :dl_feedback,
            type: :downlink,
            direction: :downlink,
            ground_station_id: :equator_prime,
            starts_at_s: 10.0,
            ends_at_s: 40.0,
            required_downlink_mb: 360.0
          }
        ],
        [
          %{
            id: :dl_feedback,
            type: :downlink,
            status: :partial,
            actual_throughput_mb: 120.0,
            trust_boundary: :operator_supplied
          }
        ]
      )

    mission_state =
      MissionState
      |> struct!(mission_state_with_refresh_inputs())
      |> Map.put(:timeline_feedback_report, feedback_report)

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{
             "equator_prime" => 240.0
           }

    assert get_in(artifact, ["operational_feedback", "downlink_demand_sources"]) == %{
             "equator_prime" => [
               "timeline_feedback.contact.required_downlink_mb:dl_feedback",
               "timeline_feedback.realized_activity:dl_feedback"
             ]
           }

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 120.0 / 360.0
           }

    demand_branch = branch(artifact, "derived_downlink_demand_feedback")

    assert %{
             "type" => "downlink_demand_feedback",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 240.0,
             "feedback_source" => "operational_feedback.downlink_demand_mb",
             "downlink_demand_sources" => [
               "timeline_feedback.contact.required_downlink_mb:dl_feedback",
               "timeline_feedback.realized_activity:dl_feedback"
             ]
           } = List.first(demand_branch["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             demand_branch["assumptions"]["candidate_source"]

    assert %{
             "source" => "mission_state.timeline_feedback_report.operational_feedback",
             "input_keys" => [
               "contact_success_rate",
               "downlink_demand_mb",
               "downlink_demand_sources",
               "station_throughput_factor"
             ],
             "source_report_contract" => "timeline_feedback_report.v1",
             "source_report_row_count" => 1,
             "source_report_status_counts" => %{"matched" => 1},
             "source_feedback_kind_counts" => %{"contact" => 1},
             "source_match_strategy_counts" => %{"activity_id" => 1},
             "source_cadence_import_status_counts" => %{"missing" => 1},
             "source_planned_protection_decision_counts" => %{"preserve" => 1},
             "source_operational_feedback_provenance" => %{
               "source_count" => 1,
               "sources" => [
                 %{
                   "source" => "timeline_feedback_report.rows",
                   "trust_boundary_status" => "declared",
                   "trust_boundaries" => ["operator_supplied"]
                 }
               ]
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["operator_supplied"]
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] == "mission_state.timeline_feedback_report.operational_feedback")
             )

    assert "mission_state.timeline_feedback_report.operational_feedback" in artifact[
             "operational_feedback_provenance"
           ]["merge_order"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives downlink demand refresh branch from mission-state partial downlink telemetry" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "planned_dl_1",
          type: "downlink",
          status: "partial",
          actual_throughput_mb: 120.0
        }
      ])

    prior_plan =
      base_plan(%{
        "activities" => [
          downlink("planned_dl_1", 100.0, 160.0)
          |> Map.put("required_downlink_mb", 360.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [
          %{id: "baseline"},
          %{id: "manual", events: [%{type: "fuel_preservation_mode"}]}
        ],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{
             "equator_prime" => 240.0
           }

    assert get_in(artifact, ["operational_feedback", "downlink_demand_sources"]) == %{
             "equator_prime" => [
               "mission_state.realized_activities.contact.required_downlink_mb:planned_dl_1"
             ]
           }

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 120.0 / 360.0
           }

    demand_branch = branch(artifact, "derived_downlink_demand_feedback")
    throughput_branch = branch(artifact, "derived_station_throughput_feedback")

    assert %{
             "type" => "downlink_demand_feedback",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 240.0,
             "feedback_source" => "operational_feedback.downlink_demand_mb",
             "downlink_demand_sources" => [
               "mission_state.realized_activities.contact.required_downlink_mb:planned_dl_1"
             ]
           } = List.first(demand_branch["events"])

    downlink =
      demand_branch
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime"))

    assert downlink["required_downlink_mb"] == 240.0

    assert downlink["downlink_completion_source"] ==
             "operational_feedback.downlink_demand_mb.station"

    assert downlink["downlink_completion_sources"] == [
             "mission_state.realized_activities.contact.required_downlink_mb:planned_dl_1"
           ]

    assert "downlink_demand_mb" in artifact["operational_feedback_provenance"][
             "input_keys"
           ]

    assert "downlink_demand_sources" in artifact["operational_feedback_provenance"][
             "input_keys"
           ]

    assert %{
             "source" => "mission_state.realized_activities",
             "input_keys" => [
               "contact_success_rate",
               "downlink_demand_mb",
               "downlink_demand_sources",
               "station_throughput_factor"
             ],
             "realized_activity_count" => 1
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] == "mission_state.realized_activities")
             )

    assert %{
             "type" => "station_throughput_feedback",
             "ground_station_id" => "equator_prime",
             "station_throughput_factor" => station_throughput,
             "feedback_source" => "operational_feedback.station_throughput_factor"
           } = List.first(throughput_branch["events"])

    assert_in_delta station_throughput, 120.0 / 360.0, 1.0e-12

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
