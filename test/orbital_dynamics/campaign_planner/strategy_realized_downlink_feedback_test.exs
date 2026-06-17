Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyRealizedDownlinkFeedbackTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy routes direct realized activity trust boundaries by feedback field" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "planned_dl_1",
          type: "downlink",
          status: "partial",
          completed_fraction: 0.35,
          actual_throughput_mb: 70.0,
          trust_boundary: "ops_contact_direct"
        },
        %{
          id: "cmd_health_1",
          type: "command",
          status: "partial",
          completed_fraction: 0.25,
          trust_boundary: "ops_command_direct"
        }
      ])

    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          downlink("planned_dl_1", 100.0, 160.0)
          |> Map.put("required_downlink_mb", 200.0),
          health_check("cmd_health_1", "leo_1", 170.0, 190.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    assert %{
             "source" => "mission_state.realized_activities",
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["ops_command_direct", "ops_contact_direct"],
             "feedback_trust_boundaries" => %{
               "contact_success_rate" => %{"equator_prime" => ["ops_contact_direct"]},
               "station_throughput_factor" => %{"equator_prime" => ["ops_contact_direct"]},
               "downlink_demand_mb" => %{"equator_prime" => ["ops_contact_direct"]},
               "command_success_rate" => %{"cmd_health_1" => ["ops_command_direct"]}
             }
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] == "mission_state.realized_activities")
             )

    assert %{
             "type" => "contact_success_feedback",
             "ground_station_id" => "equator_prime",
             "contact_success_factor" => 0.35,
             "trust_boundary" => "ops_contact_direct"
           } = List.first(branch(artifact, "derived_contact_success_feedback")["events"])

    assert %{
             "type" => "station_throughput_feedback",
             "ground_station_id" => "equator_prime",
             "station_throughput_factor" => 0.35,
             "trust_boundary" => "ops_contact_direct"
           } = List.first(branch(artifact, "derived_station_throughput_feedback")["events"])

    assert %{
             "type" => "downlink_demand_feedback",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 130.0,
             "trust_boundary" => "ops_contact_direct"
           } = List.first(branch(artifact, "derived_downlink_demand_feedback")["events"])

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_health_1",
             "command_success_factor" => 0.25,
             "trust_boundary" => "ops_command_direct"
           } = List.first(branch(artifact, "derived_command_success_feedback")["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives downlink demand from provider contact result failure aliases" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "planned_dl_provider",
          type: "contact",
          status: "completed",
          contact_result: "no-contact"
        }
      ])

    prior_plan =
      base_plan(%{
        "activities" => [
          downlink("planned_dl_provider", 100.0, 160.0)
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
             "equator_prime" => 360.0
           }

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 0.0
           }

    demand_branch = branch(artifact, "derived_downlink_demand_feedback")

    assert %{
             "type" => "downlink_demand_feedback",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 360.0,
             "feedback_source" => "operational_feedback.downlink_demand_mb"
           } = List.first(demand_branch["events"])

    downlink =
      demand_branch
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime"))

    assert downlink["required_downlink_mb"] == 360.0

    assert downlink["downlink_completion_source"] ==
             "operational_feedback.downlink_demand_mb.station"

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy weights provider-derived downlink demand by feedback confidence" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "planned_dl_provider",
          type: "contact",
          status: "completed",
          contact_result: "no-contact",
          confidence_weight: 0.5,
          confidence_weight_source: "provider_confidence"
        }
      ])

    prior_plan =
      base_plan(%{
        "activities" => [
          downlink("planned_dl_provider", 100.0, 160.0)
          |> Map.put("required_downlink_mb", 360.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{
             "equator_prime" => 180.0
           }

    demand_branch = branch(artifact, "derived_downlink_demand_feedback")

    assert %{
             "type" => "downlink_demand_feedback",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 180.0
           } = List.first(demand_branch["events"])

    assert %{
             "source" => "mission_state.realized_activities",
             "weighted_feedback_row_count" => 1,
             "feedback_weight_sources" => ["provider_confidence"]
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] == "mission_state.realized_activities")
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy does not derive downlink demand when provider contact result is successful" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "planned_dl_provider",
          type: "contact",
          status: "failed",
          contact_result: "delivered"
        }
      ])

    prior_plan =
      base_plan(%{
        "activities" => [
          downlink("planned_dl_provider", 100.0, 160.0)
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

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 1.0
           }

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{}
    refute branch(artifact, "derived_downlink_demand_feedback")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives contact throughput feedback from realized downlink aliases" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "planned_dl_alias",
          type: "downlink",
          status: "partial",
          delivered_data_mb: 90.0
        }
      ])

    prior_plan =
      base_plan(%{
        "activities" => [
          downlink("planned_dl_alias", 100.0, 160.0)
          |> Map.put("required_downlink_mb", 360.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{
             "equator_prime" => 270.0
           }

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 0.25
           }

    demand_branch = branch(artifact, "derived_downlink_demand_feedback")
    throughput_branch = branch(artifact, "derived_station_throughput_feedback")

    assert %{
             "type" => "downlink_demand_feedback",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 270.0
           } = List.first(demand_branch["events"])

    assert %{
             "type" => "station_throughput_feedback",
             "ground_station_id" => "equator_prime",
             "station_throughput_factor" => 0.25
           } = List.first(throughput_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy normalizes numeric-string realized telemetry before branch refresh" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "planned_dl_string",
          type: "downlink",
          status: "partial",
          actual_throughput_mb: "90.0",
          completed_fraction: "0.25"
        },
        %{
          id: "obs_actual_string",
          type: "observe",
          target_id: "target_a",
          status: "completed",
          actual_data_volume_mb: "180.0"
        },
        %{
          id: "obs_partial_string",
          type: "observe",
          target_id: "target_a",
          status: "partial",
          planned_data_volume_mb: "80.0",
          completed_fraction: "0.5"
        }
      ])

    prior_plan =
      base_plan(%{
        "activities" => [
          downlink("planned_dl_string", 100.0, 160.0)
          |> Map.put("required_downlink_mb", "360.0")
          |> Map.put("estimated_throughput_mb", "360.0")
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 0.25
           }

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 0.25
           }

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{
             "default" => 220.0,
             "equator_prime" => 270.0
           }

    assert get_in(artifact, ["operational_feedback", "observation_success_rate"]) == %{
             "target_a" => 0.75
           }

    demand_branch = branch(artifact, "derived_downlink_demand_feedback")

    assert Enum.any?(
             demand_branch["events"],
             &(&1["feedback_scope"] == "default" and &1["required_downlink_mb"] == 220.0)
           )

    assert Enum.any?(
             demand_branch["events"],
             &(&1["ground_station_id"] == "equator_prime" and
                 &1["required_downlink_mb"] == 270.0)
           )

    assert %{
             "type" => "station_throughput_feedback",
             "ground_station_id" => "equator_prime",
             "station_throughput_factor" => 0.25
           } = List.first(branch(artifact, "derived_station_throughput_feedback")["events"])

    assert %{
             "type" => "contact_success_feedback",
             "ground_station_id" => "equator_prime",
             "contact_success_factor" => 0.25
           } = List.first(branch(artifact, "derived_contact_success_feedback")["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives station throughput from delayed telemetry without contact success" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "planned_dl_delayed",
          type: "downlink",
          status: "delayed",
          actual_throughput_mb: 120.0
        }
      ])

    prior_plan =
      base_plan(%{
        "activities" => [
          downlink("planned_dl_delayed", 100.0, 160.0)
          |> Map.put("required_downlink_mb", 360.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{}

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 120.0 / 360.0
           }

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{
             "equator_prime" => 240.0
           }

    assert branch(artifact, "derived_station_throughput_feedback")
    assert branch(artifact, "derived_downlink_demand_feedback")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
