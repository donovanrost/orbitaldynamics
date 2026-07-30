Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyObservationFeedbackRefreshTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema
  alias OrbitalDynamics.CampaignPlanner.OperationalFeedback

  test "strategy replays mission-state review and import timeline-diff handoffs" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "candidate_activities" => [
          refreshed_downlink("dl_live_timeline_recovery_a", 600.0, 660.0)
          |> Map.put("estimated_throughput_mb", 60.0),
          refreshed_downlink("dl_live_timeline_recovery_b", 720.0, 780.0)
          |> Map.put("estimated_throughput_mb", 50.0)
        ]
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:operator_review_package, %{
        "schema_contract" => "operator_review_package.v1",
        "source_artifact_type" => "timeline_diff_report.v1",
        "review_count" => 1,
        "provenance" => %{"trust_boundary" => "live_timeline_review_queue"},
        "rows" => [
          %{
            "id" => "operator_review:timeline_diff:dl_live_timeline",
            "review_type" => "timeline_diff_review",
            "source" => "timeline_diff_report.rows",
            "subject_id" => "timeline:dl_live_timeline",
            "approval_status" => "operator_review_required",
            "source_timeline_diff" => %{
              "id" => "timeline_diff:timeline:dl_live_timeline",
              "rank" => 1,
              "timeline_id" => "timeline:dl_live_timeline",
              "diff_status" => "changed",
              "changed_fields" => [
                "required_downlink_mb",
                "actual_downlink_mb",
                "selected_downlink_shortfall_mb"
              ],
              "source_activity_id" => "dl_live_source",
              "replacement_activity_id" => "dl_live_review_replacement",
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
      })
      |> Map.put(:cadence_import_manifest, %{
        "schema_contract" => "cadence_import_manifest.v1",
        "source_artifact_type" => "operator_review_package.v1",
        "row_count" => 1,
        "review_required_count" => 1,
        "provenance" => %{"trust_boundary" => "live_timeline_import_queue"},
        "rows" => [
          %{
            "id" => "cadence_import:timeline_diff:dl_live_timeline",
            "import_action" => "review_timeline_diff",
            "source_review_type" => "timeline_diff_review",
            "approval_status" => "operator_review_required",
            "source_review_row" => %{
              "review_type" => "timeline_diff_review",
              "source" => "timeline_diff_report.rows",
              "subject_id" => "timeline:dl_live_timeline",
              "source_timeline_diff" => %{
                "id" => "timeline_diff:timeline:dl_live_timeline",
                "rank" => 1,
                "timeline_id" => "timeline:dl_live_timeline",
                "diff_status" => "changed",
                "changed_fields" => [
                  "required_downlink_mb",
                  "actual_downlink_mb",
                  "selected_downlink_shortfall_mb"
                ],
                "source_activity_id" => "dl_live_source",
                "replacement_activity_id" => "dl_live_import_replacement",
                "source_activity_type" => "downlink",
                "replacement_activity_type" => "downlink",
                "source_ground_station_id" => "equator_prime",
                "replacement_ground_station_id" => "equator_prime",
                "scenario_id" => "leo_1",
                "source_status" => "planned",
                "replacement_activity_context" => %{
                  "required_downlink_mb" => 80.0,
                  "actual_downlink_mb" => 30.0,
                  "selected_downlink_shortfall_mb" => 50.0
                },
                "required_operator_action" => "review_timeline_change"
              }
            }
          }
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    base_id = "derived_timeline_diff_changed_dl_live_source"
    refute branch(artifact, base_id)

    timeline_branches =
      Enum.filter(artifact["branches"], &String.starts_with?(&1["branch_id"], "#{base_id}_"))

    assert length(timeline_branches) == 2

    assert MapSet.new(Enum.map(timeline_branches, & &1["derived_source"])) ==
             MapSet.new([
               "mission_state.operator_review_package.rows.source_timeline_diff",
               "mission_state.cadence_import_manifest.rows.source_review_row.source_timeline_diff"
             ])

    assert MapSet.new(
             Enum.map(
               timeline_branches,
               &get_in(&1, ["events", Access.at(0), "downlink_shortfall_mb"])
             )
           ) == MapSet.new([60.0, 50.0])

    assert Enum.all?(timeline_branches, fn branch ->
             %{
               "type" => "downlink_completion_gap",
               "source_activity_id" => "dl_live_source",
               "feedback_scope" => "timeline_diff"
             } = List.first(branch["events"])

             branch
             |> get_in(["candidate_plan", "strategic_additions"])
             |> Enum.any?(&(&1["type"] == "downlink"))
           end)

    assert MapSet.new(
             Enum.map(timeline_branches, &get_in(&1, ["events", Access.at(0), "trust_boundary"]))
           ) == MapSet.new(["live_timeline_review_queue", "live_timeline_import_queue"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy applies default station feedback to branch-generated refresh candidates" do
    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state_with_refresh_inputs(),
        operational_feedback: %{
          station_throughput_factor: %{"default" => 0.5},
          contact_success_rate: %{"default" => 0.4}
        },
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    throughput_branch = branch(artifact, "derived_station_throughput_feedback")
    contact_branch = branch(artifact, "derived_contact_success_feedback")

    assert %{
             "type" => "station_throughput_feedback",
             "feedback_scope" => "default",
             "station_throughput_factor" => 0.5
           } = List.first(throughput_branch["events"])

    refute Map.has_key?(List.first(throughput_branch["events"]), "ground_station_id")

    assert %{
             "type" => "contact_success_feedback",
             "feedback_scope" => "default",
             "contact_success_factor" => 0.4
           } = List.first(contact_branch["events"])

    refute Map.has_key?(List.first(contact_branch["events"]), "ground_station_id")

    throughput_downlink =
      throughput_branch
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "downlink"))

    assert get_in(throughput_downlink, ["throughput_model", "station_capacity_fraction"]) == 0.5
    assert throughput_downlink["station_availability"] == "reduced_capacity"

    contact_downlink =
      contact_branch
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "downlink"))

    assert contact_downlink["contact_success_factor"] == 0.4
    assert get_in(contact_downlink, ["throughput_model", "contact_success_factor"]) == 0.4

    assert contact_branch["feedback_adjustments"]["contact_success_factor"] == 0.4
    assert throughput_branch["feedback_adjustments"]["station_throughput_factor"] == 0.5

    assert contact_branch["feedback_adjustments"]["contact_success_factor_activity_source"] ==
             "branch_generated_source_candidates"

    assert throughput_branch["feedback_adjustments"]["station_throughput_factor_activity_source"] ==
             "branch_generated_source_candidates"

    contact_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_contact_success_feedback"))

    throughput_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_station_throughput_feedback"))

    assert contact_row["contact_success_factor_activity_source"] ==
             "branch_generated_source_candidates"

    assert throughput_row["station_throughput_factor_activity_source"] ==
             "branch_generated_source_candidates"

    assert Enum.any?(
             artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "strategy_tradeoff" and
                 &1["branch_id"] == "derived_contact_success_feedback" and
                 &1["contact_success_factor_activity_source"] ==
                   "branch_generated_source_candidates")
           )

    assert Enum.any?(
             artifact["cadence_import_manifest"]["rows"],
             &(&1["source_review_type"] == "strategy_tradeoff" and
                 &1["branch_id"] == "derived_station_throughput_feedback" and
                 &1["station_throughput_factor_activity_source"] ==
                   "branch_generated_source_candidates")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy-derived refresh applies observation success feedback to generated observations" do
    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state_with_refresh_inputs(),
        operational_feedback: %{
          observation_success_rate: %{"target_a" => 0.5}
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

    observation =
      artifact
      |> branch("urgent")
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "observe" and &1["target_id"] == "target_a"))

    assert_in_delta observation["score_terms"]["target_value"],
                    observation["duration_s"],
                    1.0e-9
  end

  test "strategy derives observation success refresh branch from operational feedback" do
    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state_with_refresh_inputs(),
        operational_feedback: %{
          observation_success_rate: %{"target_a" => 0.5}
        },
        approval_policy: %{
          "action_rules" => [
            %{
              "id" => "target_a_observation_feedback_review",
              "risk_types" => ["observation_success_rate_low"],
              "target_id" => "target_a",
              "classification" => "operator_review_required",
              "reason" => "target_a observation feedback requires review"
            }
          ]
        },
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    observation_branch = branch(artifact, "derived_observation_success_feedback")

    assert %{
             "type" => "observation_success_feedback",
             "target_id" => "target_a",
             "observation_success_factor" => 0.5,
             "feedback_source" => "operational_feedback.observation_success_rate"
           } = List.first(observation_branch["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             observation_branch["assumptions"]["candidate_source"]

    assert [
             %{
               "type" => "observe",
               "target_id" => "target_a",
               "repair" => %{"reason" => "observation_success_feedback_candidate_inserted"},
               "feasibility" => %{
                 "status" => "validated_candidate_window",
                 "target_id" => "target_a",
                 "source_window" => %{"type" => "target_visibility"}
               }
             }
           ] = observation_branch["candidate_plan"]["strategic_additions"]

    assert [
             %{
               "action" => "approve_strategic_addition",
               "activity_context" => %{
                 "target_id" => "target_a",
                 "source_window" => %{"type" => "target_visibility"},
                 "feasibility_status" => "validated_candidate_window",
                 "repair_reason" => "observation_success_feedback_candidate_inserted"
               }
             }
           ] = observation_branch["approval_requirements"]

    assert Enum.any?(
             observation_branch["risk_indicators"],
             &(&1["type"] == "observation_success_rate_low" and &1["value"] == 0.5 and
                 &1["target_id"] == "target_a")
           )

    assert Enum.any?(
             observation_branch["approval_rule_matches"],
             &(&1["rule_id"] == "target_a_observation_feedback_review" and
                 &1["risk_type"] == "observation_success_rate_low" and
                 &1["target_id"] == "target_a")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives observation feedback from result-artifact candidate context" do
    result_candidate =
      "obs_result_candidate"
      |> observe("leo_1", "target_result", 300.0, 360.0, 12.0)
      |> Map.merge(%{
        "priority" => 8.0,
        "score_terms" => %{"target_value" => 12.0},
        "source_window_id" => "window:leo_1:target_visibility:target_result:1",
        "source_window" => %{
          "id" => "window:leo_1:target_visibility:target_result:1",
          "type" => "target_visibility"
        }
      })

    prior_plan =
      base_plan(%{
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "metadata" => %{"trust_boundary" => "ops_candidate_result_artifact"},
          "candidate_activities" => [result_candidate]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state([]),
        operational_feedback: %{
          observation_success_rate: %{"target_result" => 0.4}
        },
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    observation_branch = branch(artifact, "derived_observation_success_feedback")

    assert %{
             "type" => "observation_success_feedback",
             "target_id" => "target_result",
             "observation_success_factor" => 0.4,
             "priority" => 8.0
           } = List.first(observation_branch["events"])

    assert [
             %{
               "target_id" => "target_result",
               "trust_boundary" => "ops_candidate_result_artifact",
               "repair" => %{"reason" => "observation_success_feedback_candidate_inserted"},
               "feasibility" => %{"source_window" => %{"type" => "target_visibility"}}
             }
           ] = observation_branch["candidate_plan"]["strategic_additions"]

    assert observation_branch["repair_result"]["assumptions"]["candidate_source"][
             "candidate_count"
           ] == 1

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy maps branch-authored image quality evidence to observation success feedback" do
    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state_with_refresh_inputs(),
        approval_policy: %{
          "action_rules" => [
            %{
              "id" => "target_a_quality_review",
              "risk_types" => ["observation_success_rate_low"],
              "target_id" => "target_a",
              "classification" => "operator_review_required",
              "reason" => "target_a provider quality feedback requires review"
            }
          ]
        },
        branches: [
          %{id: "baseline"},
          %{
            id: "quality_feedback",
            events: [
              %{
                type: "observation_success_feedback",
                target_id: "target_a",
                product_quality_score: "0.4",
                product_quality_status: :marginal,
                product_quality_source: :provider_image_assessment,
                cloud_fraction: "0.6",
                image_blur_score: "0.2",
                direction: "uplink",
                ground_station_id: "equator_prime",
                station_availability: "reserved",
                station_contention_status: "reserved_overlap",
                station_calendar_entry_id: "quality_cmd_reservation",
                station_calendar_provider_id: "partner_calendar",
                station_calendar_provider_entry_id: "quality_cmd_entry_1",
                station_calendar_directions: ["uplink"],
                station_calendar_status: "reserved",
                station_calendar_trust_boundary_status: "declared",
                station_reservation_id: "reservation_quality_partner",
                station_reserved_by: "partner_team",
                station_reservation_status: "confirmed",
                station_reservation_match_status: "unmatched_overlap",
                feedback_weight: "1.0"
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    quality_branch = branch(artifact, "quality_feedback")

    assert %{
             "type" => "observation_success_feedback",
             "target_id" => "target_a",
             "observation_success_factor" => 0.4,
             "image_quality_score" => 0.4,
             "image_quality_status" => "marginal",
             "image_quality_source" => "provider_image_assessment",
             "cloud_cover_fraction" => 0.6,
             "blur_score" => 0.2,
             "feedback_source" => "branch_event.image_quality_score",
             "feedback_weight" => 1.0
           } = List.first(quality_branch["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             quality_branch["assumptions"]["candidate_source"]

    assert Enum.sort(
             quality_branch["assumptions"]["candidate_source"][
               "operational_feedback_input_keys"
             ]
           ) == [
             "blur_score",
             "cloud_cover_fraction",
             "image_quality_score",
             "image_quality_source",
             "image_quality_status",
             "observation_success_rate"
           ]

    assert [
             %{
               "type" => "observe",
               "target_id" => "target_a",
               "repair" => %{"reason" => "observation_success_feedback_candidate_inserted"}
             }
           ] = quality_branch["candidate_plan"]["strategic_additions"]

    quality_observation = List.first(quality_branch["candidate_plan"]["strategic_additions"])

    assert quality_observation["image_quality_score"] == 0.4
    assert quality_observation["image_quality_status"] == "marginal"
    assert quality_observation["image_quality_source"] == "provider_image_assessment"
    assert quality_observation["cloud_cover_fraction"] == 0.6
    assert_in_delta quality_observation["blur_score"], 0.2, 1.0e-12

    assert Enum.any?(
             quality_branch["risk_indicators"],
             &(&1["type"] == "observation_success_rate_low" and &1["value"] == 0.4 and
                 &1["target_id"] == "target_a")
           )

    assert Enum.any?(
             quality_branch["approval_rule_matches"],
             &(&1["rule_id"] == "target_a_quality_review" and
                 &1["risk_type"] == "observation_success_rate_low" and
                 &1["target_id"] == "target_a")
           )

    assert %{
             "branch_image_quality_min_score" => 0.4,
             "branch_image_quality_statuses" => ["marginal"],
             "branch_image_quality_sources" => ["provider_image_assessment"],
             "branch_cloud_cover_max_fraction" => 0.6,
             "branch_blur_max_score" => 0.2,
             "branch_ground_station_ids" => ["equator_prime"],
             "branch_station_calendar_provider_ids" => ["partner_calendar"],
             "branch_station_calendar_provider_entry_ids" => ["quality_cmd_entry_1"],
             "branch_station_reservation_ids" => ["reservation_quality_partner"],
             "branch_station_reservation_match_statuses" => ["unmatched_overlap"]
           } =
             Enum.find(
               artifact["branch_comparison_report"]["rows"],
               &(&1["branch_id"] == "quality_feedback")
             )

    assert %{
             "branch_image_quality_min_score" => 0.4,
             "branch_image_quality_statuses" => ["marginal"],
             "branch_image_quality_sources" => ["provider_image_assessment"],
             "branch_cloud_cover_max_fraction" => 0.6,
             "branch_blur_max_score" => 0.2,
             "branch_ground_station_ids" => ["equator_prime"],
             "branch_station_calendar_provider_ids" => ["partner_calendar"],
             "branch_station_calendar_provider_entry_ids" => ["quality_cmd_entry_1"],
             "branch_station_reservation_ids" => ["reservation_quality_partner"],
             "branch_station_reservation_match_statuses" => ["unmatched_overlap"]
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "strategy_tradeoff" and
                   &1["action"] == "review_branch_comparison" and
                   &1["branch_id"] == "quality_feedback")
             )

    assert %{
             "branch_image_quality_min_score" => 0.4,
             "branch_image_quality_statuses" => ["marginal"],
             "branch_image_quality_sources" => ["provider_image_assessment"],
             "branch_cloud_cover_max_fraction" => 0.6,
             "branch_blur_max_score" => 0.2,
             "branch_ground_station_ids" => ["equator_prime"],
             "branch_station_calendar_provider_ids" => ["partner_calendar"],
             "branch_station_calendar_provider_entry_ids" => ["quality_cmd_entry_1"],
             "branch_station_reservation_ids" => ["reservation_quality_partner"],
             "branch_station_reservation_match_statuses" => ["unmatched_overlap"]
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source_review_type"] == "strategy_branch_comparison" and
                   &1["branch_id"] == "quality_feedback")
             )

    assert %{
             "branch_event_count" => 1,
             "branch_event_types" => ["observation_success_feedback"],
             "branch_image_quality_min_score" => 0.4,
             "branch_image_quality_statuses" => ["marginal"],
             "branch_image_quality_sources" => ["provider_image_assessment"],
             "branch_cloud_cover_max_fraction" => 0.6,
             "branch_blur_max_score" => 0.2,
             "branch_ground_station_ids" => ["equator_prime"],
             "branch_station_calendar_provider_ids" => ["partner_calendar"],
             "branch_station_calendar_provider_entry_ids" => ["quality_cmd_entry_1"],
             "branch_station_reservation_ids" => ["reservation_quality_partner"],
             "branch_station_reservation_match_statuses" => ["unmatched_overlap"]
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "strategy_recommendation" and
                   &1["branch_id"] == "quality_feedback")
             )

    review_import = OrbitalDynamics.cadence_import_manifest(artifact["operator_review_package"])

    assert %{
             "branch_event_count" => 1,
             "branch_event_types" => ["observation_success_feedback"],
             "branch_image_quality_min_score" => 0.4,
             "branch_image_quality_statuses" => ["marginal"],
             "branch_image_quality_sources" => ["provider_image_assessment"],
             "branch_cloud_cover_max_fraction" => 0.6,
             "branch_blur_max_score" => 0.2,
             "branch_ground_station_ids" => ["equator_prime"],
             "branch_station_calendar_provider_ids" => ["partner_calendar"],
             "branch_station_calendar_provider_entry_ids" => ["quality_cmd_entry_1"],
             "branch_station_reservation_ids" => ["reservation_quality_partner"],
             "branch_station_reservation_match_statuses" => ["unmatched_overlap"]
           } =
             Enum.find(
               review_import["rows"],
               &(&1["source_review_type"] == "strategy_recommendation" and
                   &1["branch_id"] == "quality_feedback")
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    quality_row_index =
      Enum.find_index(
        artifact["branch_comparison_report"]["rows"],
        &(&1["branch_id"] == "quality_feedback")
      )

    quality_context_invalid =
      put_in(
        artifact,
        [
          "branch_comparison_report",
          "rows",
          Access.at(quality_row_index),
          "branch_blur_max_score"
        ],
        0.7
      )

    assert {:error, quality_context_report} =
             Schema.validate_artifact(quality_context_invalid)

    assert Enum.any?(
             quality_context_report["errors"],
             &(&1["path"] ==
                 "$.branch_comparison_report.rows[#{quality_row_index}].branch_blur_max_score")
           )
  end

  test "strategy derives branch-local refresh from operational image quality feedback" do
    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        operational_feedback: %{
          image_quality_score: %{target_a: "0.35"},
          image_quality_status: %{target_a: :marginal},
          image_quality_source: %{target_a: :provider_image_assessment},
          cloud_cover_fraction: %{target_a: "0.65"},
          blur_score: %{target_a: "0.25"}
        },
        current_epoch_s: 0.0
      )

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

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             quality_branch["assumptions"]["candidate_source"]

    assert Enum.sort(
             quality_branch["assumptions"]["candidate_source"][
               "operational_feedback_input_keys"
             ]
           ) == [
             "blur_score",
             "cloud_cover_fraction",
             "image_quality_score",
             "image_quality_source",
             "image_quality_status",
             "observation_success_rate"
           ]

    quality_observation =
      quality_branch["candidate_plan"]["strategic_additions"]
      |> Enum.find(&(&1["type"] == "observe" and &1["target_id"] == "target_a"))

    assert quality_observation["repair"]["reason"] ==
             "observation_success_feedback_candidate_inserted"

    assert quality_observation["image_quality_score"] == 0.35
    assert quality_observation["image_quality_status"] == "marginal"
    assert quality_observation["image_quality_source"] == "provider_image_assessment"
    assert quality_observation["cloud_cover_fraction"] == 0.65
    assert quality_observation["blur_score"] == 0.25

    assert Enum.any?(
             quality_branch["risk_indicators"],
             &(&1["type"] == "observation_success_rate_low" and &1["value"] == 0.35 and
                 &1["target_id"] == "target_a")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy accepts image quality feedback through the public OperationalFeedback struct" do
    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        operational_feedback: %OperationalFeedback{
          image_quality_score: %{target_a: 0.4},
          image_quality_status: %{target_a: :marginal},
          image_quality_source: %{target_a: :provider_image_assessment},
          cloud_cover_fraction: %{target_a: 0.55},
          blur_score: %{target_a: 0.1}
        },
        current_epoch_s: 0.0
      )

    quality_branch = branch(artifact, "derived_observation_quality_feedback")

    assert %{
             "type" => "observation_success_feedback",
             "target_id" => "target_a",
             "observation_success_factor" => 0.4,
             "image_quality_score" => 0.4,
             "image_quality_status" => "marginal",
             "image_quality_source" => "provider_image_assessment",
             "cloud_cover_fraction" => 0.55,
             "blur_score" => 0.1,
             "feedback_source" => "operational_feedback.image_quality_score"
           } = List.first(quality_branch["events"])

    assert get_in(artifact, ["operational_feedback", "image_quality_score"]) == %{
             "target_a" => 0.4
           }

    assert get_in(artifact, ["operational_feedback", "image_quality_status"]) == %{
             "target_a" => "marginal"
           }

    assert Enum.sort(
             quality_branch["assumptions"]["candidate_source"][
               "operational_feedback_input_keys"
             ]
           ) == [
             "blur_score",
             "cloud_cover_fraction",
             "image_quality_score",
             "image_quality_source",
             "image_quality_status",
             "observation_success_rate"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch-local refresh from cloud and blur quality feedback" do
    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        operational_feedback: %{
          cloud_cover_fraction: %{target_a: "0.8"},
          blur_score: %{target_a: "0.3"}
        },
        current_epoch_s: 0.0
      )

    quality_branch = branch(artifact, "derived_observation_quality_feedback")

    assert %{
             "type" => "observation_success_feedback",
             "target_id" => "target_a",
             "observation_success_factor" => 0.19999999999999996,
             "cloud_cover_fraction" => 0.8,
             "blur_score" => 0.3,
             "feedback_source" => "operational_feedback.cloud_cover_fraction"
           } = List.first(quality_branch["events"])

    assert Enum.sort(
             quality_branch["assumptions"]["candidate_source"][
               "operational_feedback_input_keys"
             ]
           ) == [
             "blur_score",
             "cloud_cover_fraction",
             "observation_success_rate"
           ]

    quality_observation =
      quality_branch["candidate_plan"]["strategic_additions"]
      |> Enum.find(&(&1["type"] == "observe" and &1["target_id"] == "target_a"))

    assert quality_observation["repair"]["reason"] ==
             "observation_success_feedback_candidate_inserted"

    assert quality_observation["cloud_cover_fraction"] == 0.8
    assert quality_observation["blur_score"] == 0.3
    refute Map.has_key?(quality_observation, "image_quality_score")

    assert Enum.any?(
             quality_branch["risk_indicators"],
             &(&1["type"] == "observation_success_rate_low" and
                 &1["target_id"] == "target_a" and
                 abs(&1["value"] - 0.2) < 1.0e-12)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch-local refresh from terminal image quality status feedback" do
    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        operational_feedback: %{
          image_quality_status: %{target_a: "no image"}
        },
        current_epoch_s: 0.0
      )

    quality_branch = branch(artifact, "derived_observation_quality_feedback")

    event = List.first(quality_branch["events"])

    assert %{
             "type" => "observation_success_feedback",
             "target_id" => "target_a",
             "image_quality_status" => "no image",
             "feedback_source" => "operational_feedback.image_quality_status"
           } = event

    assert event["observation_success_factor"] == 0.0

    assert Enum.sort(
             quality_branch["assumptions"]["candidate_source"][
               "operational_feedback_input_keys"
             ]
           ) == [
             "image_quality_status",
             "observation_success_rate"
           ]

    quality_observation =
      quality_branch["candidate_plan"]["strategic_additions"]
      |> Enum.find(&(&1["type"] == "observe" and &1["target_id"] == "target_a"))

    assert quality_observation["image_quality_status"] == "no image"

    assert Enum.any?(
             quality_branch["risk_indicators"],
             &(&1["type"] == "observation_success_rate_low" and
                 &1["target_id"] == "target_a" and &1["value"] == 0.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch-local refresh from provider-shaped result maps" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "provider_observation_map",
          type: "observe",
          target_id: "target_a",
          status: "completed",
          observation_result: %{
            status: "failed",
            details: %{reason: "clouded out"}
          }
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    observation_branch = branch(artifact, "derived_observation_success_feedback")

    assert get_in(artifact, ["operational_feedback", "observation_success_rate"]) == %{
             "target_a" => 0.0
           }

    assert %{
             "type" => "observation_success_feedback",
             "target_id" => "target_a"
           } = event = List.first(observation_branch["events"])

    assert event["observation_success_factor"] == 0.0

    observation =
      observation_branch
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "observe" and &1["target_id"] == "target_a"))

    assert observation["score_terms"]["target_value"] == 0.0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives observation success feedback from realized observation telemetry" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "prior_observation",
          type: "observe",
          target_id: "target_a",
          status: "completed",
          observation_result: "accepted, failed",
          image_quality_score: 0.42,
          image_quality_status: :marginal,
          image_quality_source: :provider_image_assessment,
          cloud_cover_fraction: 0.55,
          blur_score: 0.15
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

    observation =
      artifact
      |> branch("urgent")
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "observe" and &1["target_id"] == "target_a"))

    assert get_in(artifact, ["operational_feedback", "observation_success_rate"]) == %{
             "target_a" => 0.0
           }

    assert get_in(artifact, ["operational_feedback", "image_quality_score"]) == %{
             "target_a" => 0.42
           }

    assert get_in(artifact, ["operational_feedback", "image_quality_status"]) == %{
             "target_a" => "marginal"
           }

    assert get_in(artifact, ["operational_feedback", "image_quality_source"]) == %{
             "target_a" => "provider_image_assessment"
           }

    assert get_in(artifact, ["operational_feedback", "cloud_cover_fraction"]) == %{
             "target_a" => 0.55
           }

    assert get_in(artifact, ["operational_feedback", "blur_score"]) == %{
             "target_a" => 0.15
           }

    assert %{
             "image_quality_score" => 0.42,
             "image_quality_status" => "marginal",
             "image_quality_source" => "provider_image_assessment",
             "cloud_cover_fraction" => 0.55,
             "blur_score" => 0.15
           } =
             Map.take(observation, [
               "image_quality_score",
               "image_quality_status",
               "image_quality_source",
               "cloud_cover_fraction",
               "blur_score"
             ])

    assert observation["score_terms"]["target_value"] == 0.0
  end

  test "strategy uses partial completed fraction for branch-local observation feedback" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "partial_observation",
          type: "observe",
          target_id: "target_a",
          status: "partial",
          completed_fraction: 0.25
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    observation_branch = branch(artifact, "derived_observation_success_feedback")

    assert get_in(artifact, ["operational_feedback", "observation_success_rate"]) == %{
             "target_a" => 0.25
           }

    assert %{
             "type" => "observation_success_feedback",
             "target_id" => "target_a",
             "observation_success_factor" => 0.25
           } = List.first(observation_branch["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             observation_branch["assumptions"]["candidate_source"]

    observation =
      observation_branch
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "observe" and &1["target_id"] == "target_a"))

    assert_in_delta observation["score_terms"]["target_value"],
                    observation["duration_s"] * 0.5,
                    1.0e-9

    assert [
             %{
               "target_id" => "target_a",
               "repair" => %{"reason" => "observation_success_feedback_candidate_inserted"}
             }
           ] = observation_branch["candidate_plan"]["strategic_additions"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives observation feedback by joining sparse realized rows to planned activities" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "prior_observation",
          status: "failed"
        }
      ])

    artifact =
      strategy(
        base_plan(%{
          "activities" => [observe("prior_observation", "leo_1", "target_a", 120.0, 240.0, 42.0)]
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

    observation =
      artifact
      |> branch("urgent")
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "observe" and &1["target_id"] == "target_a"))

    assert get_in(artifact, ["operational_feedback", "observation_success_rate"]) == %{
             "target_a" => 0.0
           }

    assert observation["score_terms"]["target_value"] == 0.0
  end

  test "strategy does not derive sparse observation feedback from duplicate planned activity ids" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "duplicate_activity",
          status: "failed"
        }
      ])

    artifact =
      strategy(
        base_plan(%{
          "activities" => [
            downlink("duplicate_activity", 100.0, 160.0),
            observe("duplicate_activity", "leo_1", "target_a", 120.0, 240.0, 42.0)
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

    assert get_in(artifact, ["operational_feedback", "observation_success_rate"]) == %{}
  end

  test "explicit operational feedback overrides mission-state derived observation telemetry" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "prior_observation",
          type: "observe",
          target_id: "target_a",
          status: "failed"
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        operational_feedback: %{
          observation_success_rate: %{"target_a" => 0.5}
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

    observation =
      artifact
      |> branch("urgent")
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "observe" and &1["target_id"] == "target_a"))

    assert get_in(artifact, ["operational_feedback", "observation_success_rate"]) == %{
             "target_a" => 0.5
           }

    assert artifact["operational_feedback_provenance"]["explicit_request_override"] ==
             true

    assert Enum.any?(
             artifact["operational_feedback_provenance"]["sources"],
             &(&1["source"] == "mission_state.realized_activities")
           )

    assert Enum.any?(
             artifact["operational_feedback_provenance"]["sources"],
             &(&1["source"] == "request.operational_feedback" and
                 &1["input_keys"] == ["observation_success_rate"])
           )

    assert_in_delta observation["score_terms"]["target_value"],
                    observation["duration_s"],
                    1.0e-9
  end

  test "strategy-derived refresh applies target priority feedback to generated observations" do
    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state_with_refresh_inputs(),
        operational_feedback: %{
          target_priority_overrides: %{target_a: 4.0}
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

    observation =
      artifact
      |> branch("urgent")
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "observe" and &1["target_id"] == "target_a"))

    assert_in_delta observation["score_terms"]["target_value"],
                    observation["duration_s"] * 4.0,
                    1.0e-9
  end

  test "strategy derives target priority refresh branch from operational feedback" do
    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state_with_refresh_inputs(),
        operational_feedback: %{
          target_priority_overrides: %{target_a: 12.0}
        },
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    priority_branch = branch(artifact, "derived_target_priority_feedback")

    assert %{
             "type" => "target_priority_feedback",
             "target_id" => "target_a",
             "priority" => 12.0,
             "feedback_source" => "operational_feedback.target_priority_overrides"
           } = List.first(priority_branch["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             priority_branch["assumptions"]["candidate_source"]

    assert [
             %{
               "type" => "observe",
               "target_id" => "target_a",
               "repair" => %{"reason" => "target_priority_feedback_candidate_inserted"},
               "feasibility" => %{
                 "status" => "validated_candidate_window",
                 "target_id" => "target_a",
                 "source_window" => %{"type" => "target_visibility"}
               }
             }
           ] = priority_branch["candidate_plan"]["strategic_additions"]

    assert Enum.any?(
             priority_branch["risk_indicators"],
             &(&1["type"] == "target_priority_feedback_high" and &1["value"] == 12.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives target priority refresh branch from realized observation telemetry" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "obs_target_a_low",
          type: "observe",
          target_id: "target_a",
          status: "completed",
          target_priority: 10.0,
          confidence_weight: 1.0
        },
        %{
          id: "obs_target_a_high",
          type: "observe",
          target_id: "target_a",
          status: "completed",
          target_priority: "14.0",
          confidence_weight: "3.0"
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "target_priority_overrides"]) == %{
             "target_a" => 13.0
           }

    priority_branch = branch(artifact, "derived_target_priority_feedback")

    assert %{
             "type" => "target_priority_feedback",
             "target_id" => "target_a",
             "priority" => 13.0,
             "feedback_source" => "operational_feedback.target_priority_overrides"
           } = List.first(priority_branch["events"])

    assert %{
             "source" => "mission_state.realized_activities",
             "input_keys" => ["observation_success_rate", "target_priority_overrides"]
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] == "mission_state.realized_activities")
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy weights direct realized observation feedback by provider confidence" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "obs_good",
          type: "observe",
          target_id: "target_a",
          status: "completed",
          target_priority: 2.0,
          feedback_weight: 1.0
        },
        %{
          id: "obs_bad",
          type: "observe",
          target_id: "target_a",
          status: "failed",
          target_priority: 10.0,
          feedback_weight: 3.0
        },
        %{
          id: "obs_zero_confidence",
          type: "observe",
          target_id: "target_a",
          status: "completed",
          target_priority: 100.0,
          feedback_weight: 0.0,
          feedback_weight_source: "zero_confidence"
        }
      ])

    artifact =
      strategy(
        base_plan(%{
          "activities" => [
            observe("obs_good", "leo_1", "target_a", 100.0, 160.0, 42.0),
            observe("obs_bad", "leo_1", "target_a", 180.0, 240.0, 42.0),
            observe("obs_zero_confidence", "leo_1", "target_a", 250.0, 310.0, 42.0)
          ]
        }),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "observation_success_rate"]) == %{
             "target_a" => 0.25
           }

    assert get_in(artifact, ["operational_feedback", "target_priority_overrides"]) == %{
             "target_a" => 8.0
           }

    realized_source =
      Enum.find(
        artifact["operational_feedback_provenance"]["sources"],
        &(&1["source"] == "mission_state.realized_activities")
      )

    assert %{"weighted_feedback_row_count" => 2} = realized_source
    refute Map.has_key?(realized_source, "feedback_weight_sources")

    observation_branch = branch(artifact, "derived_observation_success_feedback")
    priority_branch = branch(artifact, "derived_target_priority_feedback")

    assert %{
             "observation_success_factor" => 0.25,
             "feedback_source" => "operational_feedback.observation_success_rate"
           } = List.first(observation_branch["events"])

    assert %{
             "priority" => 8.0,
             "feedback_source" => "operational_feedback.target_priority_overrides"
           } = List.first(priority_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy does not derive target priority feedback from planned observation context alone" do
    prior_plan =
      base_plan(%{
        "activities" => [
          observe("obs_target_a", "leo_1", "target_a", 100.0, 160.0, 20.0)
          |> Map.put("target_priority", 12.0)
        ]
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "obs_target_a",
          type: "observe",
          status: "completed"
        }
      ])

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "target_priority_overrides"]) == %{}
    refute branch(artifact, "derived_target_priority_feedback")

    assert %{
             "source" => "mission_state.realized_activities",
             "input_keys" => ["observation_success_rate"]
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] == "mission_state.realized_activities")
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
