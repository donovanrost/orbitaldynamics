Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyTimelineDiffDownlinkPressureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema, Timeline}
  alias OrbitalDynamics.MissionPlan.Activity

  test "strategy derives timeline diff refresh from nested station and target objects" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe("obs_object_recovery", "leo_1", "target_object", 360.0, 420.0, 12.0),
          refreshed_downlink("dl_object_recovery", 360.0, 420.0)
          |> Map.put("estimated_throughput_mb", 50.0)
        ],
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 4,
          "removed_count" => 2,
          "changed_count" => 2,
          "provenance" => %{"trust_boundary" => "ops_timeline_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:obs_removed_object",
              "rank" => 1,
              "timeline_id" => "timeline:obs_removed_object",
              "diff_status" => "removed",
              "source_activity_id" => "obs_removed_object",
              "source_activity_type" => "observe",
              "source_status" => "planned",
              "source_activity_context" => %{
                "scenario_id" => "leo_1",
                "target" => %{"id" => "target_object", "provider" => "fixture"}
              },
              "required_operator_action" => "review_removed_activity"
            },
            %{
              "id" => "timeline_diff:timeline:dl_removed_object",
              "rank" => 2,
              "timeline_id" => "timeline:dl_removed_object",
              "diff_status" => "removed",
              "source_activity_id" => "dl_removed_object",
              "source_activity_type" => "downlink",
              "source_status" => "planned",
              "source_activity_context" => %{
                "scenario_id" => "leo_1",
                "station" => %{"id" => "equator_prime", "provider" => "fixture_network"},
                "estimated_throughput_mb" => 50.0
              },
              "required_operator_action" => "review_removed_activity"
            },
            %{
              "id" => "timeline_diff:timeline:obs_changed_object",
              "rank" => 3,
              "timeline_id" => "timeline:obs_changed_object",
              "diff_status" => "changed",
              "changed_fields" => ["observation_result"],
              "source_activity_id" => "obs_changed_object_source",
              "replacement_activity_id" => "obs_changed_object",
              "source_activity_type" => "observe",
              "replacement_activity_type" => "observe",
              "source_status" => "planned",
              "scenario_id" => "leo_1",
              "replacement_activity_context" => %{
                "target" => %{"id" => "target_object", "provider" => "fixture"},
                "observation_result" => "failed"
              },
              "required_operator_action" => "review_timeline_change"
            },
            %{
              "id" => "timeline_diff:timeline:dl_changed_object",
              "rank" => 4,
              "timeline_id" => "timeline:dl_changed_object",
              "diff_status" => "changed",
              "changed_fields" => ["required_downlink_mb", "actual_downlink_mb"],
              "source_activity_id" => "dl_changed_object_source",
              "replacement_activity_id" => "dl_changed_object",
              "source_activity_type" => "downlink",
              "replacement_activity_type" => "downlink",
              "source_status" => "planned",
              "scenario_id" => "leo_1",
              "replacement_activity_context" => %{
                "station" => %{"id" => "equator_prime", "provider" => "fixture_network"},
                "required_downlink_mb" => 90.0,
                "actual_downlink_mb" => 40.0
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

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_object",
             "source_activity_id" => "obs_removed_object"
           } =
             artifact
             |> branch("derived_timeline_diff_removed_obs_removed_object")
             |> get_in(["events"])
             |> List.first()

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 50.0,
             "source_activity_id" => "dl_removed_object"
           } =
             artifact
             |> branch("derived_timeline_diff_removed_dl_removed_object")
             |> get_in(["events"])
             |> List.first()

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_object",
             "replacement_activity_id" => "obs_changed_object"
           } =
             artifact
             |> branch("derived_timeline_diff_changed_obs_changed_object_source")
             |> get_in(["events"])
             |> List.first()

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 90.0,
             "planned_downlink_mb" => 40.0,
             "replacement_activity_id" => "dl_changed_object"
           } =
             artifact
             |> branch("derived_timeline_diff_changed_dl_changed_object_source")
             |> get_in(["events"])
             |> List.first()

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives timeline diff refresh from result artifact reports" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe(
            "obs_result_artifact_timeline_recovery",
            "leo_1",
            "target_result_artifact_timeline",
            360.0,
            420.0,
            12.0
          )
        ],
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "study_id" => "timeline_diff_result_artifact",
          "provenance" => %{"trust_boundary" => "ops_result_artifact"},
          "timeline_diff_report" => %{
            "schema_contract" => "timeline_diff_report.v1",
            "model" => "timeline_identity_activity_diff",
            "source" => "repair.activities",
            "row_count" => 1,
            "removed_count" => 1,
            "rows" => [
              %{
                "id" => "timeline_diff:timeline:obs_result_artifact_removed",
                "rank" => 1,
                "timeline_id" => "timeline:obs_result_artifact_removed",
                "diff_status" => "removed",
                "source_activity_id" => "obs_result_artifact_removed",
                "source_activity_type" => "observe",
                "source_status" => "planned",
                "source_activity_context" => %{
                  "scenario_id" => "leo_1",
                  "target" => %{
                    "id" => "target_result_artifact_timeline",
                    "provider" => "fixture"
                  }
                },
                "required_operator_action" => "review_removed_activity"
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

    branch = branch(artifact, "derived_timeline_diff_removed_obs_result_artifact_removed")

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_result_artifact_timeline",
             "source_activity_id" => "obs_result_artifact_removed",
             "timeline_id" => "timeline:obs_result_artifact_removed",
             "feedback_source" => "prior_plan.source_result_artifact.timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "trust_boundary" => "ops_result_artifact"
           } = List.first(branch["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             branch["assumptions"]["candidate_source"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives refresh from changed timeline diff downlink shortfall rows" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          refreshed_downlink("dl_changed_recovery", 600.0, 660.0)
          |> Map.put("estimated_throughput_mb", 60.0)
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
              "id" => "timeline_diff:timeline:dl_changed",
              "rank" => 1,
              "timeline_id" => "timeline:dl_changed",
              "diff_status" => "Changed",
              "changed_fields" => [
                "Required Downlink MB",
                "actual-downlink-mb",
                "Selected Downlink Shortfall MB"
              ],
              "source_activity_id" => "dl_source",
              "replacement_activity_id" => "dl_changed",
              "source_activity_type" => "Downlink",
              "replacement_activity_type" => "Downlink",
              "source_ground_station_id" => "equator_prime",
              "replacement_ground_station_id" => "equator_prime",
              "scenario_id" => "leo_1",
              "source_status" => "Planned",
              "replacement_activity_context" => %{
                "required_downlink_mb" => 100.0,
                "actual_downlink_mb" => 40.0,
                "selected_downlink_shortfall_mb" => 60.0,
                "required_contacts" => 1,
                "planned_contacts" => 0
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

    branch = branch(artifact, "derived_timeline_diff_changed_dl_source")

    assert %{
             "type" => "downlink_completion_gap",
             "scenario_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 100.0,
             "planned_downlink_mb" => 40.0,
             "downlink_shortfall_mb" => 60.0,
             "source_activity_id" => "dl_source",
             "replacement_activity_id" => "dl_changed",
             "source_activity_ids" => ["dl_changed", "dl_source"],
             "timeline_id" => "timeline:dl_changed",
             "changed_fields" => [
               "required_downlink_mb",
               "actual_downlink_mb",
               "selected_downlink_shortfall_mb"
             ],
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "trust_boundary" => "ops_timeline_review"
           } = List.first(branch["events"])

    assert [
             %{
               "type" => "downlink",
               "feasibility" => %{
                 "feedback_source" => "prior_plan.source_timeline_diff_report",
                 "feedback_scope" => "timeline_diff",
                 "trust_boundary" => "ops_timeline_review",
                 "source_event_type" => "downlink_completion_gap",
                 "source_activity_id" => "dl_source",
                 "source_activity_ids" => ["dl_changed", "dl_source"],
                 "source_timeline_id" => "timeline:dl_changed",
                 "required_contacts" => 1,
                 "planned_contacts" => 0,
                 "required_downlink_mb" => 100.0,
                 "planned_downlink_mb" => 40.0,
                 "derivation_reasons" => [
                   "timeline_diff_changed_activity",
                   "timeline_diff_changed_downlink_completion"
                 ]
               }
             }
           ] = branch["candidate_plan"]["strategic_additions"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy keeps independent timeline diff pressures for the same activity identity" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          refreshed_downlink("dl_shared_timeline_a_recovery", 600.0, 660.0)
          |> Map.put("estimated_throughput_mb", 100.0),
          refreshed_downlink("dl_shared_timeline_b_recovery", 720.0, 780.0)
          |> Map.put("ground_station_id", "polar_prime")
          |> Map.put("estimated_throughput_mb", 70.0)
        ],
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.source_activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "source_timeline_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:dl_shared",
              "rank" => 1,
              "timeline_id" => "timeline:dl_shared_source",
              "diff_status" => "changed",
              "changed_fields" => ["required_downlink_mb", "actual_downlink_mb"],
              "source_activity_id" => "dl_shared_source",
              "replacement_activity_id" => "dl_shared_source_replacement",
              "source_activity_type" => "downlink",
              "replacement_activity_type" => "downlink",
              "source_ground_station_id" => "equator_prime",
              "replacement_ground_station_id" => "equator_prime",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "replacement_activity_context" => %{
                "required_downlink_mb" => 100.0,
                "actual_downlink_mb" => 40.0,
                "selected_downlink_shortfall_mb" => 60.0,
                "required_contacts" => 1,
                "planned_contacts" => 0
              },
              "required_operator_action" => "review_timeline_change"
            }
          ]
        },
        "timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.canonical_activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "canonical_timeline_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:dl_shared",
              "rank" => 1,
              "timeline_id" => "timeline:dl_shared_canonical",
              "diff_status" => "changed",
              "changed_fields" => ["required_downlink_mb", "actual_downlink_mb"],
              "source_activity_id" => "dl_shared_source",
              "replacement_activity_id" => "dl_shared_canonical_replacement",
              "source_activity_type" => "downlink",
              "replacement_activity_type" => "downlink",
              "source_ground_station_id" => "polar_prime",
              "replacement_ground_station_id" => "polar_prime",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "replacement_activity_context" => %{
                "required_downlink_mb" => 70.0,
                "actual_downlink_mb" => 20.0,
                "selected_downlink_shortfall_mb" => 50.0,
                "required_contacts" => 1,
                "planned_contacts" => 0
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

    base_id = "derived_timeline_diff_changed_dl_shared_source"
    refute branch(artifact, base_id)

    timeline_branches =
      Enum.filter(artifact["branches"], &String.starts_with?(&1["branch_id"], "#{base_id}_"))

    assert length(timeline_branches) == 2

    assert MapSet.new(Enum.map(timeline_branches, & &1["derived_source"])) ==
             MapSet.new([
               "prior_plan.source_timeline_diff_report",
               "prior_plan.timeline_diff_report"
             ])

    assert MapSet.new(
             Enum.map(timeline_branches, &get_in(&1, ["events", Access.at(0), "timeline_id"]))
           ) == MapSet.new(["timeline:dl_shared_source", "timeline:dl_shared_canonical"])

    assert MapSet.new(
             Enum.map(
               timeline_branches,
               &get_in(&1, ["events", Access.at(0), "ground_station_id"])
             )
           ) == MapSet.new(["equator_prime", "polar_prime"])

    assert MapSet.new(
             Enum.map(
               timeline_branches,
               &get_in(&1, ["events", Access.at(0), "required_downlink_mb"])
             )
           ) == MapSet.new([100.0, 70.0])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives changed timeline diff downlink refresh from provider data-volume aliases" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          refreshed_downlink("dl_data_volume_recovery", 600.0, 660.0)
          |> Map.put("estimated_throughput_mb", 80.0)
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
              "id" => "timeline_diff:timeline:dl_data_volume_changed",
              "rank" => 1,
              "timeline_id" => "timeline:dl_data_volume_changed",
              "diff_status" => "changed",
              "changed_fields" => [
                "Target Data Volume MB",
                "selected-data-volume-mb",
                "selected_data_volume_shortfall_mb"
              ],
              "source_activity_id" => "dl_data_volume_source",
              "replacement_activity_id" => "dl_data_volume_changed",
              "source_activity_type" => "contact",
              "replacement_activity_type" => "contact",
              "source_direction" => "downlink",
              "replacement_direction" => "downlink",
              "source_ground_station_id" => "equator_prime",
              "replacement_ground_station_id" => "equator_prime",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "replacement_activity_context" => %{
                "throughput_model" => %{
                  "target_data_volume_mb" => 125.0,
                  "selected_data_volume_mb" => 45.0,
                  "selected_data_volume_shortfall_mb" => 80.0,
                  "downlink_demand_sources" => ["provider.demand:scene_data_volume"],
                  "downlink_completion_sources" => ["provider.collection:scene_data_volume"]
                },
                "required_contact_count" => 1,
                "planned_contact_count" => 0
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

    branch = branch(artifact, "derived_timeline_diff_changed_dl_data_volume_source")

    assert %{
             "type" => "downlink_completion_gap",
             "scenario_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 125.0,
             "planned_downlink_mb" => 45.0,
             "downlink_shortfall_mb" => 80.0,
             "downlink_demand_sources" => ["provider.demand:scene_data_volume"],
             "downlink_completion_sources" => ["provider.collection:scene_data_volume"],
             "source_activity_id" => "dl_data_volume_source",
             "replacement_activity_id" => "dl_data_volume_changed",
             "source_activity_ids" => ["dl_data_volume_changed", "dl_data_volume_source"],
             "timeline_id" => "timeline:dl_data_volume_changed",
             "changed_fields" => [
               "target_data_volume_mb",
               "selected_data_volume_mb",
               "selected_data_volume_shortfall_mb"
             ],
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "trust_boundary" => "ops_timeline_review"
           } = List.first(branch["events"])

    assert [
             %{
               "type" => "downlink",
               "feasibility" => %{
                 "source_event_type" => "downlink_completion_gap",
                 "source_activity_id" => "dl_data_volume_source",
                 "source_activity_ids" => ["dl_data_volume_changed", "dl_data_volume_source"],
                 "source_timeline_id" => "timeline:dl_data_volume_changed",
                 "required_downlink_mb" => 125.0,
                 "planned_downlink_mb" => 45.0,
                 "downlink_demand_sources" => ["provider.demand:scene_data_volume"],
                 "downlink_completion_sources" => ["provider.collection:scene_data_volume"],
                 "derivation_reasons" => [
                   "timeline_diff_changed_activity",
                   "timeline_diff_changed_downlink_completion"
                 ]
               }
             }
           ] = branch["candidate_plan"]["strategic_additions"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives provider data-volume refresh from typed activity timeline diffs" do
    source_activity =
      Activity.from_map!(%{
        "id" => "dl_typed_provider",
        "type" => "planned_contact",
        "scenario_id" => "leo_1",
        "ground_station_id" => "equator_prime",
        "direction" => "downlink",
        "starts_at_s" => 300.0,
        "ends_at_s" => 360.0,
        "target_data_volume_mb" => "140.0",
        "selected_data_volume_mb" => "140.0",
        "selected_data_volume_shortfall_mb" => "0.0",
        "downlink_requirement_status" => "satisfied",
        "downlink_completion_sources" => ["provider.collection:scene_42"],
        "timeline_id" => "timeline:dl_typed_provider"
      })

    replacement_activity =
      Activity.from_map!(%{
        "id" => "dl_typed_provider_replacement",
        "type" => "planned_contact",
        "scenario_id" => "leo_1",
        "ground_station_id" => "equator_prime",
        "direction" => "downlink",
        "starts_at_s" => 300.0,
        "ends_at_s" => 360.0,
        "target_data_volume_mb" => "140.0",
        "selected_data_volume_mb" => "55.0",
        "selected_data_volume_shortfall_mb" => "85.0",
        "downlink_requirement_status" => "shortfall",
        "downlink_completion_sources" => ["provider.collection:scene_42"],
        "timeline_id" => "timeline:dl_typed_provider"
      })

    timeline_diff_report = Timeline.diff_report([source_activity], [replacement_activity])

    assert %{
             "changed_count" => 1,
             "rows" => [
               %{
                 "diff_status" => "changed",
                 "source_activity_id" => "dl_typed_provider",
                 "replacement_activity_id" => "dl_typed_provider_replacement",
                 "source_activity_type" => "planned_contact",
                 "replacement_activity_type" => "planned_contact",
                 "source_activity_context" => source_context,
                 "replacement_activity_context" => %{
                   "target_data_volume_mb" => 140.0,
                   "selected_data_volume_mb" => 55.0,
                   "selected_data_volume_shortfall_mb" => 85.0,
                   "downlink_requirement_status" => "shortfall"
                 }
               }
             ]
           } = timeline_diff_report

    assert source_context["target_data_volume_mb"] == 140.0
    assert source_context["selected_data_volume_mb"] == 140.0
    assert source_context["selected_data_volume_shortfall_mb"] == 0.0

    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          refreshed_downlink("dl_typed_provider_recovery", 600.0, 660.0)
          |> Map.put("estimated_throughput_mb", 85.0)
        ],
        "source_timeline_diff_report" => timeline_diff_report
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    branch = branch(artifact, "derived_timeline_diff_changed_dl_typed_provider")

    assert %{
             "type" => "downlink_completion_gap",
             "scenario_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "starts_at_s" => 300.0,
             "ends_at_s" => 360.0,
             "required_downlink_mb" => 140.0,
             "planned_downlink_mb" => 55.0,
             "downlink_shortfall_mb" => 85.0,
             "source_activity_id" => "dl_typed_provider",
             "replacement_activity_id" => "dl_typed_provider_replacement",
             "source_activity_ids" => [
               "dl_typed_provider",
               "dl_typed_provider_replacement"
             ],
             "timeline_id" => "timeline:dl_typed_provider",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff"
           } = List.first(branch["events"])

    assert [
             %{
               "type" => "downlink",
               "feasibility" => %{
                 "source_event_type" => "downlink_completion_gap",
                 "source_activity_id" => "dl_typed_provider",
                 "source_activity_ids" => [
                   "dl_typed_provider",
                   "dl_typed_provider_replacement"
                 ],
                 "source_timeline_id" => "timeline:dl_typed_provider",
                 "required_downlink_mb" => 140.0,
                 "planned_downlink_mb" => 55.0,
                 "derivation_reasons" => [
                   "timeline_diff_changed_activity",
                   "timeline_diff_changed_downlink_completion"
                 ]
               }
             }
           ] = branch["candidate_plan"]["strategic_additions"]

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1", "status" => "pass"}} =
             Schema.validate_artifact(timeline_diff_report)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy replays typed provider data-volume timeline diffs from Cadence import review rows" do
    source_activity =
      Activity.from_map!(%{
        "id" => "dl_import_provider",
        "type" => "planned_contact",
        "scenario_id" => "leo_1",
        "ground_station_id" => "equator_prime",
        "direction" => "downlink",
        "starts_at_s" => 300.0,
        "ends_at_s" => 360.0,
        "target_data_volume_mb" => "160.0",
        "selected_data_volume_mb" => "160.0",
        "selected_data_volume_shortfall_mb" => "0.0",
        "downlink_requirement_status" => "satisfied",
        "downlink_completion_sources" => ["provider.collection:scene_77"],
        "timeline_id" => "timeline:dl_import_provider"
      })

    replacement_activity =
      Activity.from_map!(%{
        "id" => "dl_import_provider_replacement",
        "type" => "planned_contact",
        "scenario_id" => "leo_1",
        "ground_station_id" => "equator_prime",
        "direction" => "downlink",
        "starts_at_s" => 300.0,
        "ends_at_s" => 360.0,
        "target_data_volume_mb" => "160.0",
        "selected_data_volume_mb" => "70.0",
        "selected_data_volume_shortfall_mb" => "90.0",
        "downlink_requirement_status" => "shortfall",
        "downlink_completion_sources" => ["provider.collection:scene_77"],
        "timeline_id" => "timeline:dl_import_provider"
      })

    timeline_diff_report = Timeline.diff_report([source_activity], [replacement_activity])
    review_package = OperatorReview.from_timeline_diff_report(timeline_diff_report)
    import_manifest = CadenceImport.from_operator_review_package(review_package)

    assert %{
             "review_type" => "timeline_diff_review",
             "source_timeline_diff" => %{
               "replacement_activity_context" => %{
                 "target_data_volume_mb" => 160.0,
                 "selected_data_volume_mb" => 70.0,
                 "selected_data_volume_shortfall_mb" => 90.0
               }
             }
           } = List.first(review_package["rows"])

    assert %{
             "import_action" => "review_timeline_diff",
             "source_review_row" => %{
               "source_timeline_diff" => %{
                 "replacement_activity_context" => %{
                   "target_data_volume_mb" => 160.0,
                   "selected_data_volume_mb" => 70.0,
                   "selected_data_volume_shortfall_mb" => 90.0
                 }
               }
             }
           } = List.first(import_manifest["rows"])

    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          refreshed_downlink("dl_import_provider_recovery", 700.0, 760.0)
          |> Map.put("estimated_throughput_mb", 90.0)
        ],
        "cadence_import_manifest" => import_manifest
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    branch = branch(artifact, "derived_timeline_diff_changed_dl_import_provider")

    assert %{
             "type" => "downlink_completion_gap",
             "required_downlink_mb" => 160.0,
             "planned_downlink_mb" => 70.0,
             "downlink_shortfall_mb" => 90.0,
             "source_activity_id" => "dl_import_provider",
             "replacement_activity_id" => "dl_import_provider_replacement",
             "timeline_id" => "timeline:dl_import_provider",
             "feedback_source" =>
               "prior_plan.cadence_import_manifest.rows.source_review_row.source_timeline_diff",
             "feedback_scope" => "timeline_diff"
           } = List.first(branch["events"])

    assert [
             %{
               "type" => "downlink",
               "starts_at_s" => staged_start_s,
               "ends_at_s" => staged_end_s,
               "feasibility" => %{
                 "source_event_type" => "downlink_completion_gap",
                 "source_activity_id" => "dl_import_provider",
                 "source_timeline_id" => "timeline:dl_import_provider",
                 "required_downlink_mb" => 160.0,
                 "planned_downlink_mb" => 70.0,
                 "feedback_source" =>
                   "prior_plan.cadence_import_manifest.rows.source_review_row.source_timeline_diff",
                 "feedback_scope" => "timeline_diff"
               }
             }
           ] = branch["candidate_plan"]["strategic_additions"]

    assert is_number(staged_start_s)
    assert is_number(staged_end_s)
    assert staged_start_s < 300.0 or staged_end_s > 360.0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1", "status" => "pass"}} =
             Schema.validate_artifact(review_package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1", "status" => "pass"}} =
             Schema.validate_artifact(import_manifest)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives changed timeline diff downlink refresh from operator review rows" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          refreshed_downlink("dl_review_changed_recovery", 600.0, 660.0)
          |> Map.put("estimated_throughput_mb", 60.0)
        ],
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "timeline_diff_report.v1",
          "review_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_timeline_review_queue"},
          "rows" => [
            %{
              "id" => "operator_review:timeline_diff:dl_review_changed",
              "review_type" => "timeline_diff_review",
              "source" => "timeline_diff_report.rows",
              "subject_id" => "timeline:dl_review_changed",
              "approval_status" => "operator_review_required",
              "source_timeline_diff" => %{
                "id" => "timeline_diff:timeline:dl_review_changed",
                "rank" => 1,
                "timeline_id" => "timeline:dl_review_changed",
                "diff_status" => "changed",
                "changed_fields" => [
                  "required_downlink_mb",
                  "actual_downlink_mb",
                  "selected_downlink_shortfall_mb"
                ],
                "source_activity_id" => "dl_review_source",
                "replacement_activity_id" => "dl_review_changed",
                "source_activity_type" => "downlink",
                "replacement_activity_type" => "downlink",
                "source_ground_station_id" => "equator_prime",
                "replacement_ground_station_id" => "equator_prime",
                "scenario_id" => "leo_1",
                "source_status" => "planned",
                "replacement_activity_context" => %{
                  "required_downlink_mb" => 100.0,
                  "actual_downlink_mb" => 40.0,
                  "selected_downlink_shortfall_mb" => 60.0
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

    branch = branch(artifact, "derived_timeline_diff_changed_dl_review_source")

    assert %{
             "type" => "downlink_completion_gap",
             "required_downlink_mb" => 100.0,
             "planned_downlink_mb" => 40.0,
             "downlink_shortfall_mb" => 60.0,
             "source_activity_id" => "dl_review_source",
             "replacement_activity_id" => "dl_review_changed",
             "source_activity_ids" => ["dl_review_changed", "dl_review_source"],
             "feedback_source" => "prior_plan.operator_review_package.rows.source_timeline_diff",
             "feedback_scope" => "timeline_diff",
             "trust_boundary" => "ops_timeline_review_queue"
           } = List.first(branch["events"])

    assert [
             %{
               "type" => "downlink",
               "feasibility" => %{
                 "feedback_source" =>
                   "prior_plan.operator_review_package.rows.source_timeline_diff",
                 "feedback_scope" => "timeline_diff",
                 "trust_boundary" => "ops_timeline_review_queue",
                 "source_event_type" => "downlink_completion_gap",
                 "source_activity_id" => "dl_review_source",
                 "source_activity_ids" => ["dl_review_changed", "dl_review_source"],
                 "source_timeline_id" => "timeline:dl_review_changed",
                 "derivation_reasons" => [
                   "timeline_diff_changed_activity",
                   "timeline_diff_changed_downlink_completion"
                 ]
               }
             }
           ] = branch["candidate_plan"]["strategic_additions"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy ignores changed timeline diff downlink rows without unmet volume" do
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
              "id" => "timeline_diff:timeline:dl_satisfied",
              "rank" => 1,
              "timeline_id" => "timeline:dl_satisfied",
              "diff_status" => "changed",
              "changed_fields" => ["required_downlink_mb", "actual_downlink_mb"],
              "source_activity_id" => "dl_satisfied_source",
              "replacement_activity_id" => "dl_satisfied",
              "source_activity_type" => "downlink",
              "replacement_activity_type" => "downlink",
              "source_ground_station_id" => "equator_prime",
              "replacement_ground_station_id" => "equator_prime",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "replacement_activity_context" => %{
                "required_downlink_mb" => 40.0,
                "actual_downlink_mb" => 60.0
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

    refute branch(artifact, "derived_timeline_diff_changed_dl_satisfied_source")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
