Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyScoreTermDownlinkContactRefreshTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives branch refresh from routed score-term downlink gaps" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 600.0, "output_step_s" => 60.0},
        "activities" => [downlink("dl_short", 100.0, 160.0)],
        "source_score_term_report" => %{
          "schema_contract" => "score_term_report.v1",
          "model" => "score_term_pressure_fixture",
          "source" => "fixture.score_terms",
          "row_count" => 1,
          "score_term_keys" => ["downlink_shortfall_mb"],
          "assumptions" => %{"score_term_source" => "fixture"},
          "rows" => [
            %{
              "id" => "score_gap:downlink",
              "rank" => 1,
              "scenario_id" => "leo_1",
              "term_key" => "downlink shortfall mb",
              "value" => "42.0",
              "timeline_score" => 12.0,
              "selected" => true,
              "ground_station_id" => "equator_prime",
              "planned_downlink_mb" => 8.0,
              "selected_contact_ids" => ["dl_short"]
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

    score_branch = branch(artifact, "derived_score_term_pressure_score_gap:downlink")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 50.0,
             "planned_downlink_mb" => 8.0,
             "score_term_key" => "downlink_shortfall_mb",
             "score_term_value" => 42.0,
             "source_activity_ids" => ["dl_short"],
             "downlink_demand_sources" => [
               "score_term:score_gap:downlink:downlink_shortfall_mb"
             ],
             "feedback_source" => "prior_plan.source_score_term_report",
             "feedback_scope" => "score_term",
             "derivation_reasons" => [
               "score_term_downlink_volume_gap",
               "score_term_downlink_shortfall_mb"
             ]
           } = List.first(score_branch["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             score_branch["assumptions"]["candidate_source"]

    downlink =
      score_branch
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime"))

    assert downlink["required_downlink_mb"] == 50.0

    assert downlink["downlink_completion_sources"] == [
             "score_term:score_gap:downlink:downlink_shortfall_mb"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from mission-state score-term downlink gaps" do
    score_term_report = %{
      "schema_contract" => "score_term_report.v1",
      "model" => "mission_state_score_term_pressure_fixture",
      "source" => "mission_state.score_terms",
      "row_count" => 1,
      "score_term_keys" => ["downlink_shortfall_mb"],
      "provenance" => %{"trust_boundary" => "mission_score_review"},
      "rows" => [
        %{
          "id" => "score_gap:downlink",
          "rank" => 1,
          "scenario_id" => "leo_1",
          "term_key" => "downlink shortfall mb",
          "value" => "42.0",
          "timeline_score" => 12.0,
          "selected" => true,
          "ground_station_id" => "equator_prime",
          "planned_downlink_mb" => 8.0,
          "selected_contact_ids" => ["dl_short"]
        }
      ]
    }

    artifact =
      strategy(
        base_plan(%{
          "planning_horizon" => %{"duration_s" => 600.0, "output_step_s" => 60.0},
          "activities" => [downlink("dl_short", 100.0, 160.0)]
        }),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_score_term_report, score_term_report),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    score_branch = branch(artifact, "derived_score_term_pressure_score_gap:downlink")

    assert_candidate_source_report_path(score_branch, "mission_state.source_score_term_report")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 50.0,
             "planned_downlink_mb" => 8.0,
             "score_term_key" => "downlink_shortfall_mb",
             "score_term_value" => 42.0,
             "source_activity_ids" => ["dl_short"],
             "downlink_demand_sources" => [
               "score_term:score_gap:downlink:downlink_shortfall_mb"
             ],
             "feedback_source" => "mission_state.source_score_term_report",
             "feedback_scope" => "score_term",
             "trust_boundary" => "mission_score_review"
           } = List.first(score_branch["events"])

    downlink =
      score_branch
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime"))

    assert downlink["required_downlink_mb"] == 50.0

    assert downlink["downlink_completion_sources"] == [
             "score_term:score_gap:downlink:downlink_shortfall_mb"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from result artifact score-term reports" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 600.0, "output_step_s" => 60.0},
        "activities" => [downlink("dl_result_artifact_score", 100.0, 160.0)],
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "study_id" => "score_term_result_artifact",
          "metadata" => %{"trust_boundary" => "ops_result_artifact"},
          "score_term_report" => %{
            "schema_contract" => "score_term_report.v1",
            "model" => "score_term_pressure_fixture",
            "source" => "fixture.score_terms",
            "row_count" => 1,
            "score_term_keys" => ["downlink_shortfall_mb"],
            "rows" => [
              %{
                "id" => "score_gap:result_artifact_downlink",
                "rank" => 1,
                "scenario_id" => "leo_1",
                "term_key" => "downlink shortfall mb",
                "value" => "42.0",
                "timeline_score" => 12.0,
                "selected" => true,
                "ground_station_id" => "equator_prime",
                "planned_downlink_mb" => 8.0,
                "selected_contact_ids" => ["dl_result_artifact_score"]
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

    score_branch =
      branch(artifact, "derived_score_term_pressure_score_gap:result_artifact_downlink")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 50.0,
             "planned_downlink_mb" => 8.0,
             "score_term_key" => "downlink_shortfall_mb",
             "score_term_value" => 42.0,
             "source_activity_ids" => ["dl_result_artifact_score"],
             "feedback_source" => "prior_plan.source_result_artifact.score_term_report",
             "feedback_scope" => "score_term",
             "trust_boundary" => "ops_result_artifact"
           } = List.first(score_branch["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             score_branch["assumptions"]["candidate_source"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy keeps independent score-term pressures for the same row identity" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 600.0, "output_step_s" => 60.0},
        "activities" => [
          downlink("dl_score_a", 100.0, 160.0),
          downlink("dl_score_b", 220.0, 280.0)
        ],
        "source_score_term_report" => %{
          "schema_contract" => "score_term_report.v1",
          "model" => "score_term_pressure_fixture",
          "source" => "fixture.source_score_terms",
          "row_count" => 1,
          "score_term_keys" => ["downlink_shortfall_mb"],
          "rows" => [
            %{
              "id" => "score_gap:shared_downlink",
              "rank" => 1,
              "scenario_id" => "leo_1",
              "term_key" => "downlink_shortfall_mb",
              "value" => 42.0,
              "ground_station_id" => "equator_prime",
              "planned_downlink_mb" => 8.0,
              "selected_contact_ids" => ["dl_score_a"]
            }
          ]
        },
        "score_term_report" => %{
          "schema_contract" => "score_term_report.v1",
          "model" => "score_term_pressure_fixture",
          "source" => "fixture.canonical_score_terms",
          "row_count" => 1,
          "score_term_keys" => ["downlink_shortfall_mb"],
          "rows" => [
            %{
              "id" => "score_gap:shared_downlink",
              "rank" => 1,
              "scenario_id" => "leo_1",
              "term_key" => "downlink_shortfall_mb",
              "value" => 15.0,
              "ground_station_id" => "polar_prime",
              "planned_downlink_mb" => 5.0,
              "selected_contact_ids" => ["dl_score_b"]
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

    base_id = "derived_score_term_pressure_score_gap:shared_downlink"
    refute branch(artifact, base_id)

    score_branches =
      Enum.filter(artifact["branches"], &String.starts_with?(&1["branch_id"], "#{base_id}_"))

    assert length(score_branches) == 2

    assert MapSet.new(Enum.map(score_branches, & &1["derived_source"])) ==
             MapSet.new(["prior_plan.source_score_term_report", "prior_plan.score_term_report"])

    assert MapSet.new(
             Enum.map(score_branches, &get_in(&1, ["events", Access.at(0), "ground_station_id"]))
           ) ==
             MapSet.new(["equator_prime", "polar_prime"])

    assert MapSet.new(
             Enum.map(
               score_branches,
               &get_in(&1, ["events", Access.at(0), "source_activity_ids"])
             )
           ) == MapSet.new([["dl_score_a"], ["dl_score_b"]])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from score-term station object aliases" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 600.0, "output_step_s" => 60.0},
        "activities" => [downlink("dl_station_alias", 100.0, 160.0)],
        "source_score_term_report" => %{
          "schema_contract" => "score_term_report.v1",
          "model" => "score_term_pressure_fixture",
          "source" => "fixture.score_terms",
          "row_count" => 1,
          "score_term_keys" => ["downlink_shortfall_mb"],
          "rows" => [
            %{
              "id" => "score_gap:station_object",
              "rank" => 1,
              "scenario_id" => "leo_1",
              "term_key" => "downlink-shortfall-mb",
              "value" => 25.0,
              "station" => %{"id" => "equator_prime", "provider" => "fixture_network"},
              "planned_downlink_mb" => 5.0,
              "selected_contact_ids" => ["dl_station_alias"]
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

    score_branch = branch(artifact, "derived_score_term_pressure_score_gap:station_object")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 30.0,
             "planned_downlink_mb" => 5.0,
             "score_term_key" => "downlink_shortfall_mb",
             "source_activity_ids" => ["dl_station_alias"],
             "feedback_source" => "prior_plan.source_score_term_report"
           } = List.first(score_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from routed score-term contact-count gaps" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 600.0, "output_step_s" => 60.0},
        "source_score_term_report" => %{
          "schema_contract" => "score_term_report.v1",
          "model" => "score_term_pressure_fixture",
          "source" => "fixture.score_terms",
          "row_count" => 1,
          "score_term_keys" => ["contact_count_gap"],
          "assumptions" => %{"score_term_source" => "fixture"},
          "rows" => [
            %{
              "id" => "score_gap:contact_count",
              "rank" => 1,
              "scenario_id" => "leo_1",
              "term_key" => "contact-count-gap",
              "value" => 2.0,
              "timeline_score" => 10.0,
              "selected" => true,
              "ground_station_id" => "equator_prime",
              "planned_contacts" => 0
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

    score_branch = branch(artifact, "derived_score_term_pressure_score_gap:contact_count")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "required_contacts" => 2.0,
             "planned_contacts" => 0,
             "score_term_key" => "contact_count_gap",
             "score_term_value" => 2.0,
             "derivation_reasons" => ["score_term_contact_count_gap"]
           } = List.first(score_branch["events"])

    refute Map.has_key?(List.first(score_branch["events"]), "required_downlink_mb")

    assert Enum.any?(
             score_branch["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "downlink" and
                 get_in(&1, ["feasibility", "required_contacts"]) == 2.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives collection-latency refresh from routed score-term gaps" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 600.0, "output_step_s" => 60.0},
        "activities" => [observe("obs_latency", "leo_1", "target_a", 60.0, 120.0, 10.0)],
        "source_score_term_report" => %{
          "schema_contract" => "score_term_report.v1",
          "model" => "score_term_pressure_fixture",
          "source" => "fixture.score_terms",
          "row_count" => 1,
          "score_term_keys" => ["collection_latency_gap_s"],
          "provenance" => %{"trust_boundary" => "declared_latency_score_terms"},
          "rows" => [
            %{
              "id" => "score_gap:collection_latency",
              "rank" => 1,
              "objective" => "collection-latency",
              "term_key" => "collection latency gap s",
              "value" => "120.0",
              "source_observation" => %{
                "activity_id" => "obs_latency",
                "scenario_id" => "leo_1",
                "ground_station" => %{"id" => "equator_prime"},
                "target_id" => "target_a",
                "collection_id" => "collection_alpha",
                "collections" => [
                  %{"id" => "collection_alpha"},
                  %{"collection_id" => "collection_beta"}
                ],
                "product_id" => "product_alpha",
                "products" => [%{"id" => "product_alpha"}, %{"product_id" => "product_beta"}],
                "payload_id" => "camera_a",
                "payloads" => [%{"id" => "camera_a"}, %{"payload_id" => "camera_b"}],
                "instrument_id" => "instrument_a",
                "instruments" => [
                  %{"id" => "instrument_a"},
                  %{"instrument_id" => "instrument_b"}
                ],
                "collection_end_s" => 120.0,
                "delivery_deadline_s" => 420.0,
                "target_latency_s" => 300.0,
                "actual_delivery_latency_s" => 420.0,
                "min_downlink_mb" => 30.0,
                "selected_data_volume_mb" => 5.0
              },
              "selected_contact" => %{"downlink_activity_id" => "dl_score_latency"}
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

    score_branch = branch(artifact, "derived_score_term_pressure_score_gap:collection_latency")

    assert %{
             "type" => "downlink_completion_gap",
             "objective_type" => "collection_latency",
             "latency_objective" => true,
             "target_id" => "target_a",
             "scenario_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "collection_id" => "collection_alpha",
             "collection_ids" => ["collection_alpha", "collection_beta"],
             "product_id" => "product_alpha",
             "product_ids" => ["product_alpha", "product_beta"],
             "payload_id" => "camera_a",
             "payload_ids" => ["camera_a", "camera_b"],
             "instrument_id" => "instrument_a",
             "instrument_ids" => ["instrument_a", "instrument_b"],
             "starts_at_s" => 120.0,
             "ends_at_s" => 420.0,
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 30.0,
             "planned_downlink_mb" => 5.0,
             "max_latency_s" => 300.0,
             "planned_latency_s" => 420.0,
             "source_activity_id" => "obs_latency",
             "source_activity_ids" => ["dl_score_latency", "obs_latency"],
             "score_term_key" => "collection_latency_gap_s",
             "score_term_value" => 120.0,
             "feedback_source" => "prior_plan.source_score_term_report",
             "feedback_scope" => "score_term",
             "trust_boundary" => "declared_latency_score_terms",
             "derivation_reasons" => [
               "collection_latency_gap",
               "score_term_collection_latency_gap",
               "score_term_latency_gap",
               "score_term_collection_latency_gap_s"
             ]
           } = List.first(score_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp assert_candidate_source_report_path(branch, expected_path) do
    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = branch["assumptions"]["candidate_source"]

    assert expected_path in candidate_source["source_report_input_paths"]
    candidate_source
  end
end
