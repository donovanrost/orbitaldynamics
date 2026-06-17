Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyOperationalFeedbackProvenanceTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy consumes operational feedback emitted by a prior repair artifact" do
    planned_contact =
      "planned_dl_1"
      |> downlink(200.0, 260.0)
      |> Map.put("type", "planned_contact")
      |> Map.put("direction", "downlink")

    prior_repair =
      base_plan(%{
        "schema_version" => 2,
        "planner" => "OrbitalDynamics.CampaignPlanner.V2",
        "activities" => [planned_contact],
        "source_candidate_activities" => [refreshed_downlink("candidate_dl_1", 300.0, 360.0)],
        "source_timeline_feedback_report" => %{
          "schema_contract" => "timeline_feedback_report.v1",
          "operational_feedback" => %{
            "contact_success_rate" => %{"equator_prime" => 0.4},
            "station_throughput_factor" => %{"equator_prime" => 0.5},
            "downlink_demand_mb" => %{"default" => 120.0}
          },
          "rows" => []
        }
      })

    artifact =
      strategy(prior_repair,
        branches: [%{id: "baseline"}, %{id: "review"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 0.4
           }

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 0.5
           }

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{
             "default" => 120.0
           }

    assert %{
             "model" =>
               "deterministic_merge_explicit_overrides_mission_state_overrides_prior_plan",
             "input_keys" => [
               "contact_success_rate",
               "downlink_demand_mb",
               "station_throughput_factor"
             ],
             "source_count" => 1,
             "sources" => [
               %{
                 "source" => "prior_plan.source_timeline_feedback_report.operational_feedback",
                 "input_keys" => [
                   "contact_success_rate",
                   "downlink_demand_mb",
                   "station_throughput_factor"
                 ],
                 "source_report_contract" => "timeline_feedback_report.v1",
                 "source_report_count" => 1,
                 "source_report_row_count" => 0
               }
             ],
             "explicit_request_override" => false
           } = artifact["operational_feedback_provenance"]

    review = branch(artifact, "review")

    assert review["feedback_adjustments"]["contact_success_factor"] == 0.4
    assert review["feedback_adjustments"]["station_throughput_factor"] == 0.5

    assert Enum.any?(
             review["risk_indicators"],
             &(&1["type"] == "contact_success_rate_low" and &1["value"] == 0.4)
           )

    selected_import =
      Enum.find(
        artifact["cadence_import_manifest"]["rows"],
        &(&1["import_action"] == "import_strategy_recommendation")
      )

    assert %{
             "operational_feedback_trust_boundary_status" => "missing",
             "operational_feedback_input_keys" => [
               "contact_success_rate",
               "downlink_demand_mb",
               "station_throughput_factor"
             ],
             "source_operational_feedback_provenance" => %{"source_count" => 1}
           } = selected_import

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy consumes timeline feedback embedded in prior result artifacts" do
    planned_contact =
      "planned_dl_result_feedback"
      |> downlink(200.0, 260.0)
      |> Map.put("type", "planned_contact")
      |> Map.put("direction", "downlink")

    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [planned_contact],
        "source_candidate_activities" => [refreshed_downlink("candidate_dl_1", 300.0, 360.0)],
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "metadata" => %{"trust_boundary" => "ops_timeline_result_artifact"},
          "timeline_feedback_report" => %{
            "schema_contract" => "timeline_feedback_report.v1",
            "operational_feedback" => %{
              "contact_success_rate" => %{"equator_prime" => 0.4},
              "station_throughput_factor" => %{"equator_prime" => 0.5},
              "downlink_demand_mb" => %{"equator_prime" => 120.0}
            },
            "rows" => []
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

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 0.4
           }

    assert %{
             "source" => "prior_plan.source_timeline_feedback_report.operational_feedback",
             "source_report_contract" => "timeline_feedback_report.v1",
             "source_report_count" => 1,
             "source_report_paths" => [
               "prior_plan.source_result_artifact.timeline_feedback_report"
             ],
             "source_report_row_count" => 0,
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["ops_timeline_result_artifact"],
             "feedback_trust_boundaries" => %{
               "contact_success_rate" => %{
                 "equator_prime" => ["ops_timeline_result_artifact"]
               },
               "downlink_demand_mb" => %{
                 "equator_prime" => ["ops_timeline_result_artifact"]
               },
               "station_throughput_factor" => %{
                 "equator_prime" => ["ops_timeline_result_artifact"]
               }
             }
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] ==
                   "prior_plan.source_timeline_feedback_report.operational_feedback")
             )

    contact_branch = branch(artifact, "derived_contact_success_feedback")

    assert %{
             "type" => "contact_success_feedback",
             "ground_station_id" => "equator_prime",
             "contact_success_factor" => 0.4,
             "feedback_source" => "operational_feedback.contact_success_rate",
             "trust_boundary" => "ops_timeline_result_artifact"
           } = List.first(contact_branch["events"])

    throughput_branch = branch(artifact, "derived_station_throughput_feedback")

    assert %{
             "type" => "station_throughput_feedback",
             "ground_station_id" => "equator_prime",
             "station_throughput_factor" => 0.5,
             "trust_boundary" => "ops_timeline_result_artifact"
           } = List.first(throughput_branch["events"])

    demand_branch = branch(artifact, "derived_downlink_demand_feedback")

    assert %{
             "type" => "downlink_demand_feedback",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 120.0,
             "trust_boundary" => "ops_timeline_result_artifact"
           } = List.first(demand_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy consumes timeline feedback from listed prior result artifacts with indexed provenance" do
    planned_contact =
      "planned_dl_result_feedback"
      |> downlink(200.0, 260.0)
      |> Map.put("type", "planned_contact")
      |> Map.put("direction", "downlink")

    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [planned_contact],
        "source_candidate_activities" => [refreshed_downlink("candidate_dl_1", 300.0, 360.0)],
        "source_result_artifact" => [
          %{
            "schema_contract" => "result_artifact.v1",
            "metadata" => %{"trust_boundary" => "ops_timeline_archive_a"},
            "timeline_feedback_report" => %{
              "schema_contract" => "timeline_feedback_report.v1",
              "operational_feedback" => %{
                "contact_success_rate" => %{"equator_prime" => 0.4}
              },
              "rows" => []
            }
          },
          "non_artifact_entry",
          %{
            "schema_contract" => "result_artifact.v1",
            "provenance" => %{"trust_boundary" => "ops_timeline_archive_b"},
            "timeline_feedback_report" => %{
              "schema_contract" => "timeline_feedback_report.v1",
              "operational_feedback" => %{
                "station_throughput_factor" => %{"equator_prime" => 0.5},
                "downlink_demand_mb" => %{"equator_prime" => 120.0}
              },
              "rows" => []
            }
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

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 0.4
           }

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 0.5
           }

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{
             "equator_prime" => 120.0
           }

    assert %{
             "source" => "prior_plan.source_timeline_feedback_report.operational_feedback",
             "source_report_contract" => "timeline_feedback_report.v1",
             "source_report_count" => 2,
             "source_report_paths" => [
               "prior_plan.source_result_artifact[0].timeline_feedback_report",
               "prior_plan.source_result_artifact[2].timeline_feedback_report"
             ],
             "source_report_row_count" => 0,
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["ops_timeline_archive_a", "ops_timeline_archive_b"],
             "feedback_trust_boundaries" => %{
               "contact_success_rate" => %{
                 "equator_prime" => ["ops_timeline_archive_a"]
               },
               "downlink_demand_mb" => %{
                 "equator_prime" => ["ops_timeline_archive_b"]
               },
               "station_throughput_factor" => %{
                 "equator_prime" => ["ops_timeline_archive_b"]
               }
             }
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] ==
                   "prior_plan.source_timeline_feedback_report.operational_feedback")
             )

    assert %{
             "trust_boundary" => "ops_timeline_archive_a"
           } = List.first(branch(artifact, "derived_contact_success_feedback")["events"])

    assert %{
             "trust_boundary" => "ops_timeline_archive_b"
           } = List.first(branch(artifact, "derived_station_throughput_feedback")["events"])

    assert %{
             "trust_boundary" => "ops_timeline_archive_b"
           } = List.first(branch(artifact, "derived_downlink_demand_feedback")["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives station feedback from result-artifact proposed contacts" do
    proposed_contact =
      "pc_from_result"
      |> refreshed_downlink(300.0, 360.0)
      |> Map.put("ground_station_id", "polar_station")

    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "metadata" => %{"trust_boundary" => "ops_proposed_contact_result_artifact"},
          "proposed_contacts" => [proposed_contact]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state([]),
        operational_feedback: %{
          contact_success_rate: %{"polar_station" => 0.25}
        },
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    contact_branch = branch(artifact, "derived_contact_success_feedback")

    assert %{
             "type" => "contact_success_feedback",
             "ground_station_id" => "polar_station",
             "contact_success_factor" => 0.25
           } = List.first(contact_branch["events"])

    assert Enum.any?(
             contact_branch["risk_indicators"],
             &(&1["type"] == "contact_success_rate_low" and
                 &1["ground_station_id"] == "polar_station")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy consumes operational feedback carried by result artifact wrappers" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "operational_feedback" => %{
            "trust_boundary" => "ops_feedback_result_artifact",
            "contact_success_rate" => %{"polar_station" => 0.25}
          }
        }
      })

    mission_state =
      mission_state([])
      |> Map.put(:ground_network, [
        %{ground_station_id: "polar_station", status: "available"}
      ])

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "polar_station" => 0.25
           }

    assert %{
             "source" => "prior_plan.operational_feedback",
             "source_report_paths" => ["prior_plan.source_result_artifact.operational_feedback"],
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["ops_feedback_result_artifact"]
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] == "prior_plan.operational_feedback")
             )

    contact_branch = branch(artifact, "derived_contact_success_feedback")

    assert %{
             "type" => "contact_success_feedback",
             "ground_station_id" => "polar_station",
             "contact_success_factor" => 0.25,
             "trust_boundary" => "ops_feedback_result_artifact"
           } = List.first(contact_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy consumes mission-state feedback from result artifact wrappers" do
    source_result_artifact = %{
      "schema_contract" => "result_artifact.v1",
      "metadata" => %{"trust_boundary" => "live_feedback_result_artifact"},
      "operational_feedback" => %{
        "trust_boundary" => "live_direct_feedback",
        "contact_success_rate" => %{"equator_prime" => 0.25}
      },
      "timeline_feedback_report" => %{
        "schema_contract" => "timeline_feedback_report.v1",
        "operational_feedback" => %{
          "station_throughput_factor" => %{"equator_prime" => 0.5},
          "downlink_demand_mb" => %{"equator_prime" => 120.0}
        },
        "rows" => []
      },
      "operational_timeline_report" => %{
        "schema_contract" => "operational_timeline_report.v1",
        "source" => "cadence.live_operational_timeline",
        "row_count" => 1,
        "rows" => [
          %{
            "id" => "timeline_row:cmd_live_result_timeline",
            "activity_id" => "cmd_live_result_timeline",
            "activity_type" => "command",
            "scenario_id" => "leo_1",
            "starts_at_s" => 100.0,
            "ends_at_s" => 130.0,
            "timeline_id" => "timeline:leo_1:command:cmd_live_result_timeline",
            "ground_station_id" => "equator_prime",
            "direction" => "uplink",
            "command_success_factor" => 0.3,
            "feedback_weight" => 2.0,
            "feedback_weight_source" => "cadence.live_sample_count"
          }
        ]
      }
    }

    artifact =
      strategy(
        base_plan(%{
          "planning_horizon" => %{"duration_s" => 2_000.0},
          "activities" => [
            command("cmd_live_result_timeline", "leo_1", 100.0, 130.0),
            downlink("dl_live_result_feedback", 300.0, 360.0)
          ],
          "source_candidate_activities" => [
            refreshed_downlink("candidate_dl_live_feedback", 420.0, 480.0)
          ]
        }),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_result_artifact, source_result_artifact),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 0.25
           }

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 0.5
           }

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{
             "equator_prime" => 120.0
           }

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_live_result_timeline" => 0.3
           }

    assert %{
             "source" => "mission_state.operational_feedback",
             "source_report_paths" => [
               "mission_state.source_result_artifact.operational_feedback"
             ],
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["live_direct_feedback"]
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] == "mission_state.operational_feedback")
             )

    assert %{
             "source" => "mission_state.timeline_feedback_report.operational_feedback",
             "source_report_paths" => [
               "mission_state.source_result_artifact.timeline_feedback_report"
             ],
             "trust_boundaries" => ["live_feedback_result_artifact"]
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] ==
                   "mission_state.timeline_feedback_report.operational_feedback")
             )

    assert %{
             "source" => "mission_state.operational_timeline_report.rows",
             "source_report_paths" => [
               "mission_state.source_result_artifact.operational_timeline_report"
             ],
             "source_report_row_count" => 1,
             "weighted_feedback_row_count" => 1,
             "trust_boundaries" => ["live_feedback_result_artifact"]
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] == "mission_state.operational_timeline_report.rows")
             )

    assert %{
             "type" => "contact_success_feedback",
             "ground_station_id" => "equator_prime",
             "contact_success_factor" => 0.25,
             "trust_boundary" => "live_direct_feedback"
           } = List.first(branch(artifact, "derived_contact_success_feedback")["events"])

    assert %{
             "type" => "station_throughput_feedback",
             "ground_station_id" => "equator_prime",
             "station_throughput_factor" => 0.5,
             "trust_boundary" => "live_feedback_result_artifact"
           } = List.first(branch(artifact, "derived_station_throughput_feedback")["events"])

    assert %{
             "type" => "downlink_demand_feedback",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 120.0,
             "trust_boundary" => "live_feedback_result_artifact"
           } = List.first(branch(artifact, "derived_downlink_demand_feedback")["events"])

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_live_result_timeline",
             "command_success_factor" => 0.3,
             "trust_boundary" => "live_feedback_result_artifact"
           } = List.first(branch(artifact, "derived_command_success_feedback")["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
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

  test "strategy consumes operational feedback emitted by a supplied candidate refresh artifact" do
    prior_plan =
      base_plan(%{
        "activities" => [downlink("dl_1", 100.0, 160.0)],
        "candidate_activities" => [downlink("dl_stale", 700.0, 760.0)]
      })

    candidate_refresh =
      [refreshed_downlink("candidate_dl_1", 300.0, 360.0)]
      |> candidate_refresh_artifact([])
      |> Map.put("operational_feedback", %{
        "trust_boundary" => "candidate_refresh_feedback",
        "station_throughput_factor" => %{"equator_prime" => 0.5}
      })
      |> put_in(["provenance", "operational_feedback"], %{
        "trust_boundary_status" => "declared",
        "trust_boundary" => "candidate_refresh_feedback",
        "input_keys" => ["station_throughput_factor"],
        "source_path" => "operational_feedback"
      })

    artifact =
      strategy(prior_plan,
        candidate_refresh: candidate_refresh,
        branches: [%{id: "baseline"}, %{id: "review"}],
        current_epoch_s: 0.0
      )

    review_branch = branch(artifact, "review")

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 0.5
           }

    assert artifact["operational_feedback_provenance"]["effective_sources"] == %{
             "station_throughput_factor" => "request.candidate_refresh.operational_feedback"
           }

    assert artifact["operational_feedback_provenance"]["overridden_sources"] == %{}

    assert review_branch["feedback_adjustments"]["station_throughput_factor"] == 0.5

    assert review_branch["feedback_adjustments"]["station_throughput_factor_source"] ==
             "operational_feedback.station_throughput_factor"

    assert %{
             "source" => "request.candidate_refresh.operational_feedback",
             "source_report_contract" => "candidate_refresh.v1",
             "source_refresh_id" => "candidate_refresh:test:abc",
             "source_candidate_count" => 1,
             "source_operational_feedback_provenance" => %{
               "input_keys" => ["station_throughput_factor"],
               "trust_boundary" => "candidate_refresh_feedback"
             }
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] == "request.candidate_refresh.operational_feedback")
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy explicit operational feedback overrides supplied candidate refresh feedback per key" do
    prior_plan =
      base_plan(%{
        "activities" => [downlink("dl_1", 100.0, 160.0)],
        "candidate_activities" => [downlink("dl_stale", 700.0, 760.0)]
      })

    candidate_refresh =
      [refreshed_downlink("candidate_dl_1", 300.0, 360.0)]
      |> candidate_refresh_artifact([])
      |> Map.put("operational_feedback", %{
        "station_throughput_factor" => %{"equator_prime" => 0.5}
      })

    artifact =
      strategy(prior_plan,
        candidate_refresh: candidate_refresh,
        operational_feedback: %{
          station_throughput_factor: %{equator_prime: 0.8}
        },
        branches: [%{id: "baseline"}, %{id: "review"}],
        current_epoch_s: 0.0
      )

    review_branch = branch(artifact, "review")

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 0.8
           }

    assert review_branch["feedback_adjustments"]["station_throughput_factor"] == 0.8

    assert artifact["operational_feedback_provenance"]["explicit_request_override"] ==
             true

    assert artifact["operational_feedback_provenance"]["effective_sources"] == %{
             "station_throughput_factor" => "request.operational_feedback"
           }

    assert artifact["operational_feedback_provenance"]["overridden_sources"] == %{
             "station_throughput_factor" => ["request.candidate_refresh.operational_feedback"]
           }

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp candidate_refresh_artifact(candidates, opts) do
    %{
      "schema_version" => 1,
      "schema_contract" => "candidate_refresh.v1",
      "artifact_type" => "candidate_refresh",
      "generated_at" => "2026-05-14T00:00:00Z",
      "planner" => "OrbitalDynamics.CandidateRefresh.V1",
      "refresh_id" => Keyword.get(opts, :refresh_id, "candidate_refresh:test:abc"),
      "study_id" => "candidate_refresh_test",
      "snapshot_id" => "ops-state-1",
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 1_000.0,
        "output_step_s" => 60.0
      },
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-1",
        "spacecraft_state_count" => 1
      },
      "refreshed_windows" => %{
        "access_windows" => [],
        "target_visibility_windows" => [],
        "eclipse_intervals" => []
      },
      "candidate_activities" => candidates,
      "contact_intents" => Keyword.get(opts, :contact_intents, []),
      "resource_summaries" => Keyword.get(opts, :resource_summaries, []),
      "contact_filter_report" => Keyword.get(opts, :contact_filter_report),
      "contact_allocation_report" => Keyword.get(opts, :contact_allocation_report),
      "resource_filter_report" => Keyword.get(opts, :resource_filter_report),
      "refresh_budget_report" => Keyword.get(opts, :refresh_budget_report),
      "candidate_diff_report" => Keyword.get(opts, :candidate_diff_report),
      "freshness_report" => Keyword.get(opts, :freshness_report),
      "invalidated_candidates" => [],
      "validation_records" => [],
      "warnings" => [],
      "assumptions" => %{},
      "provenance" => %{},
      "source_window_lineage" =>
        Enum.map(candidates, fn candidate ->
          %{
            "candidate_activity_id" => candidate["id"],
            "source_window_id" => candidate["source_window_id"],
            "source_window_type" => get_in(candidate, ["source_window", "type"]),
            "scenario_id" => candidate["scenario_id"]
          }
        end)
    }
  end

  test "strategy-derived operational feedback branches preserve explicit feedback trust boundary" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          health_check("cmd_health_1", "leo_1", 100.0, 130.0),
          %{
            "id" => "burn_impulsive",
            "type" => "impulsive_burn",
            "scenario_id" => "leo_1",
            "starts_at_s" => 140.0,
            "ends_at_s" => 140.0,
            "duration_s" => 0.0,
            "score" => 0.0
          },
          downlink("dl_1", 300.0, 360.0)
        ],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        operational_feedback: %{
          trust_boundary: "cadence_operational_feedback",
          contact_success_rate: %{"equator_prime" => 0.25},
          station_throughput_factor: %{"equator_prime" => 0.5},
          observation_success_rate: %{"target_a" => 0.5},
          maneuver_success_rate: %{"burn_impulsive" => 0.5},
          command_success_rate: %{"cmd_health_1" => 0.25},
          downlink_demand_mb: %{"equator_prime" => 240.0},
          target_priority_overrides: %{"target_a" => 12.0}
        },
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}, %{id: "review"}],
        current_epoch_s: 0.0
      )

    feedback_branch_ids = [
      "derived_station_throughput_feedback",
      "derived_contact_success_feedback",
      "derived_observation_success_feedback",
      "derived_maneuver_success_feedback",
      "derived_command_success_feedback",
      "derived_downlink_demand_feedback",
      "derived_target_priority_feedback"
    ]

    for branch_id <- feedback_branch_ids do
      assert %{"events" => [%{"trust_boundary" => "cadence_operational_feedback"} | _]} =
               branch(artifact, branch_id)

      row =
        Enum.find(
          artifact["branch_comparison_report"]["rows"],
          &(&1["branch_id"] == branch_id)
        )

      assert row["branch_event_trust_boundary_status_counts"] == %{
               "declared" => row["branch_event_count"]
             }
    end

    assert Enum.any?(
             artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "strategy_tradeoff" and
                 &1["branch_event_trust_boundary_status_counts"] == %{
                   "declared" => &1["branch_event_count"]
                 })
           )

    assert Enum.any?(
             artifact["cadence_import_manifest"]["rows"],
             &(&1["import_action"] in [
                 "review_strategy_branch_alternative",
                 "review_strategy_tradeoff"
               ] and
                 &1["branch_event_trust_boundary_status_counts"] == %{
                   "declared" => &1["branch_event_count"]
                 })
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy-derived operational feedback routes explicit field trust boundaries" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [downlink("dl_1", 300.0, 360.0)],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        operational_feedback: %{
          trust_boundaries: ["explicit_contact_archive", "explicit_throughput_archive"],
          feedback_trust_boundaries: %{
            contact_success_rate: %{
              equator_prime: ["explicit_contact_archive"]
            },
            station_throughput_factor: %{
              equator_prime: ["explicit_throughput_archive"]
            }
          },
          contact_success_rate: %{"equator_prime" => 0.25},
          station_throughput_factor: %{"equator_prime" => 0.5}
        },
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    source =
      Enum.find(
        artifact["operational_feedback_provenance"]["sources"],
        &(&1["source"] == "request.operational_feedback")
      )

    assert %{
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "explicit_contact_archive",
               "explicit_throughput_archive"
             ],
             "feedback_trust_boundaries" => %{
               "contact_success_rate" => %{
                 "equator_prime" => ["explicit_contact_archive"]
               },
               "station_throughput_factor" => %{
                 "equator_prime" => ["explicit_throughput_archive"]
               }
             }
           } = source

    assert %{
             "type" => "contact_success_feedback",
             "ground_station_id" => "equator_prime",
             "contact_success_factor" => 0.25,
             "trust_boundary" => "explicit_contact_archive"
           } = List.first(branch(artifact, "derived_contact_success_feedback")["events"])

    assert %{
             "type" => "station_throughput_feedback",
             "ground_station_id" => "equator_prime",
             "station_throughput_factor" => 0.5,
             "trust_boundary" => "explicit_throughput_archive"
           } = List.first(branch(artifact, "derived_station_throughput_feedback")["events"])

    recommendation_review =
      Enum.find(
        artifact["operator_review_package"]["rows"],
        &(&1["review_type"] == "strategy_recommendation")
      )

    selected_import =
      Enum.find(
        artifact["cadence_import_manifest"]["rows"],
        &(&1["import_action"] == "import_strategy_recommendation")
      )

    assert %{
             "operational_feedback_trust_boundary_status" => "declared",
             "operational_feedback_trust_boundaries" => [
               "explicit_contact_archive",
               "explicit_throughput_archive"
             ],
             "operational_feedback_field_trust_boundaries" => %{
               "contact_success_rate" => %{
                 "equator_prime" => ["explicit_contact_archive"]
               },
               "station_throughput_factor" => %{
                 "equator_prime" => ["explicit_throughput_archive"]
               }
             }
           } = recommendation_review

    refute Map.has_key?(recommendation_review, "operational_feedback_trust_boundary")

    assert %{
             "operational_feedback_trust_boundary_status" => "declared",
             "operational_feedback_trust_boundaries" => [
               "explicit_contact_archive",
               "explicit_throughput_archive"
             ],
             "operational_feedback_field_trust_boundaries" => %{
               "contact_success_rate" => %{
                 "equator_prime" => ["explicit_contact_archive"]
               },
               "station_throughput_factor" => %{
                 "equator_prime" => ["explicit_throughput_archive"]
               }
             }
           } = selected_import

    refute Map.has_key?(selected_import, "operational_feedback_trust_boundary")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy preserves malformed explicit operational feedback as provenance" do
    artifact =
      strategy(base_plan(%{}),
        operational_feedback: :bad_feedback,
        branches: [%{id: "baseline"}, %{id: "review"}],
        current_epoch_s: 0.0
      )

    assert %{
             "contact_success_rate" => %{},
             "observation_success_rate" => %{},
             "maneuver_success_rate" => %{},
             "command_success_rate" => %{},
             "station_throughput_factor" => %{}
           } = artifact["operational_feedback"]

    assert %{
             "input_keys" => [],
             "source_count" => 1,
             "explicit_request_override" => true,
             "sources" => [
               %{
                 "source" => "request.operational_feedback",
                 "input_keys" => ["invalid_operational_feedback_input"],
                 "invalid_operational_feedback_input" => true,
                 "invalid_operational_feedback_input_reason" =>
                   "strategy_operational_feedback_must_be_object",
                 "source_operational_feedback" => %{
                   "invalid_feedback_shape" => "bad_feedback"
                 }
               }
             ]
           } = artifact["operational_feedback_provenance"]

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
             "invalid_operational_feedback_input"
           ]) == true

    assert get_in(selected_import, [
             "source_operational_feedback_provenance",
             "sources",
             Access.at(0),
             "source_operational_feedback",
             "invalid_feedback_shape"
           ]) == "bad_feedback"

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy preserves malformed nested operational feedback sections as provenance" do
    artifact =
      strategy(base_plan(%{}),
        operational_feedback: %{
          contact_success_rate: %{"bad station" => 0.2},
          command_success_rate: %{cmd_health_1: :bad_factor},
          image_quality_source: %{"bad target" => "provider_quality"},
          downlink_demand_mb: %{
            equator_prime: -50.0,
            default: :bad_demand
          },
          target_priority_overrides: %{
            target_a: -2.0,
            target_b: :bad_priority
          },
          downlink_demand_sources: %{
            "bad station" => ["valid_source"],
            equator_prime: :bad_source_entry,
            default: ["valid_source", 42]
          },
          resource_margin_overrides: :bad_margins,
          resource_availability_overrides: %{
            "bad spacecraft" => %{payload_available?: false},
            "leo_1" => :bad_availability
          }
        },
        branches: [%{id: "baseline"}, %{id: "review"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{}
    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{}
    assert get_in(artifact, ["operational_feedback", "image_quality_source"]) == %{}
    assert get_in(artifact, ["operational_feedback", "resource_margin_overrides"]) == %{}
    assert get_in(artifact, ["operational_feedback", "resource_availability_overrides"]) == %{}
    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{}
    assert get_in(artifact, ["operational_feedback", "target_priority_overrides"]) == %{}
    assert get_in(artifact, ["operational_feedback", "downlink_demand_sources"]) == %{}

    assert %{
             "input_keys" => [],
             "source_count" => 1,
             "explicit_request_override" => true,
             "sources" => [
               %{
                 "source" => "request.operational_feedback",
                 "input_keys" => ["invalid_operational_feedback_input"],
                 "invalid_operational_feedback_input" => true,
                 "invalid_operational_feedback_input_reason" =>
                   "operational_feedback_sections_invalid",
                 "invalid_operational_feedback_sections" => invalid_sections,
                 "source_operational_feedback" => %{
                   "invalid_feedback_sections" => invalid_sections
                 }
               }
             ]
           } = artifact["operational_feedback_provenance"]

    assert %{
             "field" => "contact_success_rate",
             "key" => "bad station",
             "reason" => "key_must_be_stable_id"
           } in invalid_sections

    assert %{
             "field" => "command_success_rate",
             "key" => "cmd_health_1",
             "reason" => "entry_must_be_unit_interval_number",
             "invalid_feedback_shape" => "bad_factor"
           } in invalid_sections

    assert %{
             "field" => "image_quality_source",
             "key" => "bad target",
             "reason" => "key_must_be_stable_id"
           } in invalid_sections

    assert %{
             "field" => "downlink_demand_mb",
             "key" => "equator_prime",
             "reason" => "entry_must_be_nonnegative_number",
             "invalid_feedback_shape" => -50.0
           } in invalid_sections

    assert %{
             "field" => "downlink_demand_mb",
             "key" => "default",
             "reason" => "entry_must_be_number",
             "invalid_feedback_shape" => "bad_demand"
           } in invalid_sections

    assert %{
             "field" => "target_priority_overrides",
             "key" => "target_a",
             "reason" => "entry_must_be_nonnegative_number",
             "invalid_feedback_shape" => -2.0
           } in invalid_sections

    assert %{
             "field" => "target_priority_overrides",
             "key" => "target_b",
             "reason" => "entry_must_be_number",
             "invalid_feedback_shape" => "bad_priority"
           } in invalid_sections

    assert %{
             "field" => "downlink_demand_sources",
             "key" => "bad station",
             "reason" => "key_must_be_stable_id"
           } in invalid_sections

    assert %{
             "field" => "downlink_demand_sources",
             "key" => "equator_prime",
             "reason" => "entry_must_be_string_array",
             "invalid_feedback_shape" => "bad_source_entry"
           } in invalid_sections

    assert %{
             "field" => "downlink_demand_sources",
             "key" => "default",
             "reason" => "entry_must_be_string_array",
             "invalid_feedback_shape" => ["valid_source", 42]
           } in invalid_sections

    assert %{
             "field" => "resource_margin_overrides",
             "reason" => "field_must_be_object",
             "invalid_feedback_shape" => "bad_margins"
           } in invalid_sections

    assert %{
             "field" => "resource_availability_overrides",
             "key" => "bad spacecraft",
             "reason" => "key_must_be_stable_id"
           } in invalid_sections

    assert %{
             "field" => "resource_availability_overrides",
             "key" => "leo_1",
             "reason" => "entry_must_be_object",
             "invalid_feedback_shape" => "bad_availability"
           } in invalid_sections

    selected_import =
      artifact["cadence_import_manifest"]["rows"]
      |> Enum.find(&(&1["import_action"] == "import_strategy_recommendation"))

    assert get_in(selected_import, [
             "source_operational_feedback_provenance",
             "sources",
             Access.at(0),
             "invalid_operational_feedback_sections"
           ]) == invalid_sections

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy preserves malformed mission-state realized feedback identities as provenance" do
    prior_plan =
      base_plan(%{
        "activities" => [
          downlink("dl_bad_station", 100.0, 160.0),
          observe("obs_bad_target", "leo_1", "target_a", 170.0, 220.0, 5.0),
          command("cmd_good", "leo_1", 230.0, 245.0),
          command("cmd_bad_weight", "leo_1", 260.0, 280.0)
        ]
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: :dl_bad_station,
          status: :failed,
          type: :downlink,
          ground_station_id: "bad station",
          required_downlink_mb: 100.0,
          actual_throughput_mb: 0.0
        },
        %{
          id: :obs_bad_target,
          status: :partial,
          type: :observe,
          target: %{id: "bad target"},
          planned_data_volume_mb: 50.0,
          completed_fraction: 0.5,
          observation_success_factor: 0.25
        },
        %{
          id: :cmd_good,
          status: :completed,
          type: :command,
          command_success_factor: 0.8,
          feedback_weight: 2.0,
          feedback_weight_source: :provider_confidence
        },
        %{
          id: :cmd_bad_weight,
          status: :completed,
          type: :command,
          command_success_factor: 0.6,
          feedback_weight: -2.0,
          feedback_weight_source: :bad_provider_confidence
        }
      ])

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    refute Map.has_key?(
             get_in(artifact, ["operational_feedback", "contact_success_rate"]),
             "bad station"
           )

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{}
    assert get_in(artifact, ["operational_feedback", "observation_success_rate"]) == %{}
    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{}

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_good" => 1.0
           }

    realized_source =
      Enum.find(
        artifact["operational_feedback_provenance"]["sources"],
        &(&1["source"] == "mission_state.realized_activities")
      )

    assert %{
             "input_keys" => [
               "command_success_rate",
               "contact_success_rate",
               "invalid_operational_feedback_input"
             ],
             "realized_activity_count" => 4,
             "weighted_feedback_row_count" => 1,
             "feedback_weight_sources" => ["provider_confidence"],
             "invalid_operational_feedback_input" => true,
             "invalid_operational_feedback_input_reason" =>
               "operational_feedback_sections_invalid",
             "invalid_operational_feedback_sections" => invalid_sections
           } = realized_source

    assert %{
             "field" => "realized_activities.feedback_weight",
             "reason" => "entry_must_be_nonnegative_number",
             "invalid_feedback_shape" => -2.0,
             "row_id" => "cmd_bad_weight",
             "row_index" => 4
           } in invalid_sections

    assert %{
             "field" => "realized_activities.ground_station_id",
             "key" => "bad station",
             "reason" => "key_must_be_stable_id",
             "row_id" => "dl_bad_station",
             "row_index" => 1
           } in invalid_sections

    assert %{
             "field" => "realized_activities.target.id",
             "key" => "bad target",
             "reason" => "key_must_be_stable_id",
             "row_id" => "obs_bad_target",
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
end
