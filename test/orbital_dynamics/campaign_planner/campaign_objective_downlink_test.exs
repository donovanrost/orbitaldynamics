defmodule OrbitalDynamics.CampaignPlanner.CampaignObjectiveDownlinkTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CampaignPlanner, Epoch, ResultSet, Schema}

  test "campaign objective satisfaction reports required downlink data volume" do
    result_set =
      ResultSet.new!(%{
        study_id: :campaign,
        trajectory_results: [],
        event_results: [
          access_result(:leo_1, :equator_prime, 0.0, 100.0),
          access_result(:leo_1, :deep_space_net, 200.0, 260.0)
        ],
        errors: [],
        assumptions: %{},
        metadata: %{}
      })

    artifact =
      CampaignPlanner.build(result_set,
        generated_at: ~U[2026-05-14 00:00:00Z],
        campaign: %{
          "objectives" => [
            %{
              "type" => "downlink_completion",
              "required_downlink_mb" => 150.0
            }
          ],
          "constraints" => %{},
          "scoring_policy" => %{
            "contact_value_weight" => 1.0,
            "downlink_rate_mb_s" => 1.0
          }
        }
      )

    row =
      Enum.find(
        artifact["objective_satisfaction_report"]["rows"],
        &(&1["objective"] == "downlink_completion")
      )

    assert %{
             "status" => "met",
             "required_downlink_mb" => 150.0,
             "candidate_downlink_mb" => 160.0,
             "selected_downlink_mb" => 160.0,
             "satisfied_downlink_mb" => 150.0,
             "selected_count" => 2,
             "selected_contact_ids" => [
               "leo_1_downlink_deep_space_net_1",
               "leo_1_downlink_equator_prime_1"
             ]
           } = row

    assert artifact["objective_satisfaction_report"]["assumptions"][
             "downlink_completion_model"
           ] == "selected_downlink_activity_count_or_data_volume"

    assert %{
             "required_downlink_mb" => 150.0,
             "selected_capacity_adjusted_throughput_mb" => 160.0,
             "downlink_requirement_status" => "satisfied"
           } = artifact["link_capacity_report"]

    assert artifact["link_capacity_report"]["selected_downlink_shortfall_mb"] == 0.0

    assert {:ok, %{"schema_contract" => "objective_satisfaction_report.v1"}} =
             Schema.validate_artifact(artifact["objective_satisfaction_report"])

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(artifact["link_capacity_report"])
  end

  test "campaign ranked timelines can score downlink completion progress" do
    result_set =
      ResultSet.new!(%{
        study_id: :campaign,
        trajectory_results: [],
        event_results: [
          access_result(:shortfall, :equator_prime, 0.0, 60.0),
          access_result(:satisfied, :equator_prime, 0.0, 100.0)
        ],
        errors: [],
        assumptions: %{},
        metadata: %{}
      })

    artifact =
      CampaignPlanner.build(result_set,
        generated_at: ~U[2026-05-14 00:00:00Z],
        campaign: %{
          "objectives" => [
            %{
              "type" => "downlink_completion",
              "required_downlink_mb" => 100.0
            }
          ],
          "constraints" => %{},
          "scoring_policy" => %{
            "contact_value_weight" => 0.0,
            "downlink_completion_weight" => 40.0,
            "downlink_rate_mb_s" => 1.0
          }
        }
      )

    assert [
             %{
               "scenario_id" => "satisfied",
               "score" => 40.0,
               "score_terms" => %{
                 "activity_score" => satisfied_activity_score,
                 "downlink_completion_score" => 40.0,
                 "downlink_completion_ratio" => 1.0,
                 "selected_downlink_mb" => 100.0,
                 "required_downlink_mb" => 100.0
               }
             },
             %{
               "scenario_id" => "shortfall",
               "score" => 24.0,
               "score_terms" => %{
                 "activity_score" => shortfall_activity_score,
                 "downlink_completion_score" => 24.0,
                 "downlink_completion_ratio" => 0.6,
                 "selected_downlink_mb" => 60.0,
                 "required_downlink_mb" => 100.0
               }
             }
           ] = artifact["ranked_timelines"]

    assert satisfied_activity_score == 0.0
    assert shortfall_activity_score == 0.0
    assert "downlink_completion_score" in artifact["score_term_report"]["score_term_keys"]
    assert "selected_downlink_mb" in artifact["objective_tradeoff_report"]["score_term_keys"]

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "campaign downlink completion weight affects greedy activity selection" do
    result_set =
      ResultSet.new!(%{
        study_id: :campaign,
        trajectory_results: [],
        event_results: [
          target_visibility_result(:leo_1, :priority_target, 0.0, 100.0, 1.0),
          access_result(:leo_1, :equator_prime, 0.0, 100.0)
        ],
        errors: [],
        assumptions: %{},
        metadata: %{}
      })

    default_artifact =
      CampaignPlanner.build(result_set,
        generated_at: ~U[2026-05-14 00:00:00Z],
        campaign: %{
          "targets" => [%{"id" => "priority_target", "priority" => 1.0}],
          "objectives" => [
            %{"type" => "downlink_completion", "required_downlink_mb" => 100.0}
          ],
          "constraints" => %{"max_timeline_activities" => 1},
          "scoring_policy" => %{
            "target_value_weight" => 1.0,
            "contact_value_weight" => 0.0,
            "downlink_rate_mb_s" => 1.0
          }
        }
      )

    assert [%{"type" => "observe"}] = default_artifact["activities"]

    refute Map.has_key?(
             List.first(default_artifact["ranked_timelines"])["score_terms"],
             "downlink_completion_score"
           )

    weighted_artifact =
      CampaignPlanner.build(result_set,
        generated_at: ~U[2026-05-14 00:00:00Z],
        campaign: %{
          "targets" => [%{"id" => "priority_target", "priority" => 1.0}],
          "objectives" => [
            %{"type" => "downlink_completion", "required_downlink_mb" => 100.0}
          ],
          "constraints" => %{"max_timeline_activities" => 1},
          "scoring_policy" => %{
            "target_value_weight" => 1.0,
            "contact_value_weight" => 0.0,
            "downlink_completion_weight" => 120.0,
            "downlink_rate_mb_s" => 1.0
          }
        }
      )

    assert [
             %{
               "type" => "downlink",
               "estimated_throughput_mb" => 100.0
             }
           ] = weighted_artifact["activities"]

    assert [
             %{
               "score" => 120.0,
               "score_terms" => %{
                 "activity_score" => weighted_activity_score,
                 "downlink_completion_score" => 120.0,
                 "downlink_completion_ratio" => 1.0,
                 "selected_downlink_mb" => 100.0
               }
             }
           ] = weighted_artifact["ranked_timelines"]

    assert weighted_activity_score == 0.0

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(weighted_artifact)
  end

  test "campaign timeline precondition weight affects ranked timeline selection" do
    blocked_observation =
      :blocked
      |> target_visibility_result(:high_value_target, 0.0, 100.0, 2.0)
      |> put_in([:events, Access.at(0), :metadata, :payload_available], false)

    result_set =
      ResultSet.new!(%{
        study_id: :campaign,
        trajectory_results: [],
        event_results: [
          blocked_observation,
          target_visibility_result(:clear, :standard_target, 0.0, 100.0, 1.0)
        ],
        errors: [],
        assumptions: %{},
        metadata: %{}
      })

    default_artifact =
      CampaignPlanner.build(result_set,
        generated_at: ~U[2026-05-14 00:00:00Z],
        campaign: %{
          "targets" => [
            %{"id" => "high_value_target", "priority" => 2.0},
            %{"id" => "standard_target", "priority" => 1.0}
          ],
          "constraints" => %{"max_timeline_activities" => 1},
          "scoring_policy" => %{"target_value_weight" => 1.0}
        }
      )

    assert [%{"scenario_id" => "blocked", "target_id" => "high_value_target"}] =
             default_artifact["activities"]

    refute "timeline_precondition_pressure_penalty" in default_artifact["score_term_report"][
             "score_term_keys"
           ]

    weighted_artifact =
      CampaignPlanner.build(result_set,
        generated_at: ~U[2026-05-14 00:00:00Z],
        campaign: %{
          "targets" => [
            %{"id" => "high_value_target", "priority" => 2.0},
            %{"id" => "standard_target", "priority" => 1.0}
          ],
          "constraints" => %{"max_timeline_activities" => 1},
          "scoring_policy" => %{
            "target_value_weight" => 1.0,
            "timeline_precondition_weight" => 150.0
          }
        }
      )

    assert [%{"scenario_id" => "clear", "target_id" => "standard_target"}] =
             weighted_artifact["activities"]

    blocked_timeline =
      Enum.find(weighted_artifact["ranked_timelines"], &(&1["scenario_id"] == "blocked"))

    assert %{
             "score" => 50.0,
             "score_terms" => %{
               "activity_score" => 200.0,
               "timeline_precondition_pressure_penalty" => -150.0,
               "timeline_precondition_pressure_count" => 1,
               "blocked_precondition_count" => 1,
               "review_precondition_count" => 0
             }
           } = blocked_timeline

    assert "timeline_precondition_pressure_penalty" in weighted_artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             weighted_artifact["score_term_report"]["rows"],
             &(&1["scenario_id"] == "blocked" and
                 &1["term_key"] == "timeline_precondition_pressure_penalty" and
                 &1["value"] == -150.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(weighted_artifact)
  end

  test "campaign resource projection weight affects ranked timeline selection" do
    overflowing_observation =
      :overflowing
      |> target_visibility_result(:high_value_target, 0.0, 100.0, 2.0)
      |> put_in([:events, Access.at(0), :metadata, :estimated_storage_mb], 100.0)

    clear_observation =
      :clear
      |> target_visibility_result(:standard_target, 0.0, 100.0, 1.0)
      |> put_in([:events, Access.at(0), :metadata, :estimated_storage_mb], 10.0)

    result_set =
      ResultSet.new!(%{
        study_id: :campaign,
        trajectory_results: [],
        event_results: [
          overflowing_observation,
          clear_observation
        ],
        errors: [],
        assumptions: %{},
        metadata: %{}
      })

    campaign =
      %{
        "targets" => [
          %{"id" => "high_value_target", "priority" => 2.0},
          %{"id" => "standard_target", "priority" => 1.0}
        ],
        "constraints" => %{"max_timeline_activities" => 1},
        "resource_summaries" => [
          %{
            "schema_contract" => "resource_summary.v1",
            "spacecraft_id" => "overflowing",
            "storage_capacity_mb" => 50.0,
            "storage_used_mb" => 0.0
          },
          %{
            "schema_contract" => "resource_summary.v1",
            "spacecraft_id" => "clear",
            "storage_capacity_mb" => 200.0,
            "storage_used_mb" => 0.0
          }
        ],
        "scoring_policy" => %{"target_value_weight" => 1.0}
      }

    default_artifact =
      CampaignPlanner.build(result_set,
        generated_at: ~U[2026-05-14 00:00:00Z],
        campaign: campaign
      )

    assert [%{"scenario_id" => "overflowing", "target_id" => "high_value_target"}] =
             default_artifact["activities"]

    refute "resource_projection_pressure_penalty" in default_artifact["score_term_report"][
             "score_term_keys"
           ]

    weighted_artifact =
      CampaignPlanner.build(result_set,
        generated_at: ~U[2026-05-14 00:00:00Z],
        campaign: put_in(campaign, ["scoring_policy", "resource_projection_weight"], 150.0)
      )

    assert [%{"scenario_id" => "clear", "target_id" => "standard_target"}] =
             weighted_artifact["activities"]

    overflowing_timeline =
      Enum.find(weighted_artifact["ranked_timelines"], &(&1["scenario_id"] == "overflowing"))

    assert overflowing_timeline["score"] == 50.0
    score_terms = overflowing_timeline["score_terms"]
    assert score_terms["activity_score"] == 200.0
    assert score_terms["resource_projection_pressure_penalty"] == -150.0
    assert score_terms["resource_projection_pressure_count"] == 1
    assert score_terms["projected_storage_overflow_mb"] == 50.0
    assert score_terms["projected_downlink_shortfall_mb"] == 0.0
    assert score_terms["projected_battery_overuse_wh"] == 0.0

    assert "resource_projection_pressure_penalty" in weighted_artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             weighted_artifact["score_term_report"]["rows"],
             &(&1["scenario_id"] == "overflowing" and
                 &1["term_key"] == "resource_projection_pressure_penalty" and
                 &1["value"] == -150.0)
           )

    clear_projection =
      Enum.find(
        weighted_artifact["resource_projection_report"]["projected_resources"],
        &(&1["spacecraft_id"] == "clear")
      )

    assert clear_projection["projected_storage_overflow_mb"] == 0.0
    assert clear_projection["resource_pressure_status"] == "nominal"

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(weighted_artifact)
  end

  test "campaign objective satisfaction requires both downlink count and data volume when declared" do
    result_set =
      ResultSet.new!(%{
        study_id: :campaign,
        trajectory_results: [],
        event_results: [
          access_result(:leo_1, :equator_prime, 0.0, 100.0)
        ],
        errors: [],
        assumptions: %{},
        metadata: %{}
      })

    artifact =
      CampaignPlanner.build(result_set,
        generated_at: ~U[2026-05-14 00:00:00Z],
        campaign: %{
          "objectives" => [
            %{
              "type" => "downlink_completion",
              "required_contacts" => 2,
              "required_downlink_mb" => 50.0
            }
          ],
          "constraints" => %{},
          "scoring_policy" => %{
            "contact_value_weight" => 1.0,
            "downlink_rate_mb_s" => 1.0
          }
        }
      )

    row =
      Enum.find(
        artifact["objective_satisfaction_report"]["rows"],
        &(&1["objective"] == "downlink_completion")
      )

    assert %{
             "status" => "partial",
             "required_count" => 2,
             "required_downlink_mb" => 50.0,
             "selected_count" => 1,
             "selected_downlink_mb" => 100.0,
             "satisfied_downlink_mb" => 50.0
           } = row

    assert {:ok, %{"schema_contract" => "objective_satisfaction_report.v1"}} =
             Schema.validate_artifact(artifact["objective_satisfaction_report"])
  end

  test "campaign objective satisfaction aggregates multiple scoped downlink objectives" do
    result_set =
      ResultSet.new!(%{
        study_id: :campaign,
        trajectory_results: [],
        event_results: [
          access_result(:leo_1, :equator_prime, 0.0, 100.0),
          access_result(:leo_1, :dss_14, 200.0, 260.0)
        ],
        errors: [],
        assumptions: %{},
        metadata: %{}
      })

    artifact =
      CampaignPlanner.build(result_set,
        generated_at: ~U[2026-05-14 00:00:00Z],
        campaign: %{
          "objectives" => [
            %{
              "type" => "downlink_completion",
              "required_contacts" => 1,
              "ground_station_id" => "equator_prime"
            },
            %{
              "type" => "downlink_completion",
              "required_contacts" => 1,
              "ground_station_id" => "dss_14"
            }
          ],
          "constraints" => %{"max_timeline_activities" => "1"},
          "scoring_policy" => %{
            "contact_value_weight" => "1.0",
            "downlink_rate_mb_s" => "1.0"
          }
        }
      )

    row =
      Enum.find(
        artifact["objective_satisfaction_report"]["rows"],
        &(&1["objective"] == "downlink_completion")
      )

    assert %{
             "status" => "partial",
             "required_count" => 2,
             "candidate_count" => 2,
             "selected_count" => 1,
             "satisfied_count" => 1,
             "candidate_downlink_mb" => 160.0,
             "selected_downlink_mb" => 100.0,
             "satisfied_downlink_mb" => 100.0,
             "selected_contact_ids" => ["leo_1_downlink_equator_prime_1"]
           } = row

    assert {:ok, %{"schema_contract" => "objective_satisfaction_report.v1"}} =
             Schema.validate_artifact(artifact["objective_satisfaction_report"])
  end

  test "explicit link capacity policy overrides campaign downlink objective demand" do
    result_set =
      ResultSet.new!(%{
        study_id: :campaign,
        trajectory_results: [],
        event_results: [
          access_result(:leo_1, :equator_prime, 0.0, 100.0),
          access_result(:leo_1, :deep_space_net, 200.0, 260.0)
        ],
        errors: [],
        assumptions: %{},
        metadata: %{}
      })

    artifact =
      CampaignPlanner.build(result_set,
        generated_at: ~U[2026-05-14 00:00:00Z],
        campaign: %{
          "objectives" => [
            %{
              "type" => "downlink_completion",
              "required_downlink_mb" => 150.0
            }
          ],
          "constraints" => %{},
          "scoring_policy" => %{
            "contact_value_weight" => 1.0,
            "downlink_rate_mb_s" => 1.0,
            "required_downlink_mb" => 200.0
          }
        }
      )

    assert %{
             "required_downlink_mb" => 200.0,
             "selected_capacity_adjusted_throughput_mb" => 160.0,
             "selected_downlink_shortfall_mb" => 40.0,
             "downlink_requirement_status" => "shortfall"
           } = artifact["link_capacity_report"]

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "campaign promotes objective shortfalls to operator review and import rows" do
    result_set =
      ResultSet.new!(%{
        study_id: :campaign,
        trajectory_results: [],
        event_results: [
          access_result(:leo_1, :equator_prime, 0.0, 100.0),
          access_result(:leo_1, :deep_space_net, 200.0, 260.0)
        ],
        errors: [],
        assumptions: %{},
        metadata: %{}
      })

    artifact =
      CampaignPlanner.build(result_set,
        generated_at: ~U[2026-05-14 00:00:00Z],
        campaign: %{
          "objectives" => [
            %{
              "type" => "downlink_completion",
              "required_downlink_mb" => 300.0
            }
          ],
          "constraints" => %{},
          "scoring_policy" => %{
            "contact_value_weight" => 1.0,
            "downlink_rate_mb_s" => 1.0
          }
        }
      )

    assert %{
             "objective" => "downlink_completion",
             "status" => "partial",
             "required_downlink_mb" => 300.0,
             "selected_downlink_mb" => 160.0,
             "satisfied_downlink_mb" => 160.0
           } =
             Enum.find(
               artifact["objective_satisfaction_report"]["rows"],
               &(&1["objective"] == "downlink_completion")
             )

    assert %{"objective_satisfaction_review_count" => 1} = artifact["operator_review_package"]

    assert %{
             "review_type" => "objective_satisfaction_review",
             "source" => "campaign_plan.objective_satisfaction_report.rows",
             "objective" => "downlink_completion",
             "objective_status" => "partial",
             "required_downlink_mb" => 300.0,
             "selected_downlink_mb" => 160.0,
             "satisfied_downlink_mb" => 160.0,
             "required_operator_action" => "review_objective_satisfaction",
             "source_objective_satisfaction" => %{"objective" => "downlink_completion"}
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "objective_satisfaction_review")
             )

    assert %{
             "import_action" => "review_objective_satisfaction",
             "source_review_type" => "objective_satisfaction_review",
             "objective" => "downlink_completion",
             "objective_status" => "partial",
             "required_downlink_mb" => 300.0,
             "selected_downlink_mb" => 160.0,
             "satisfied_downlink_mb" => 160.0,
             "source_objective_satisfaction" => %{"objective" => "downlink_completion"}
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source_review_type"] == "objective_satisfaction_review")
             )

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  defp target_visibility_result(scenario_id, target_id, starts_at_s, ends_at_s, priority) do
    %{
      scenario_id: scenario_id,
      event_type: :target_visibility,
      events: [
        %{
          type: :target_visibility,
          starts_at: Epoch.new!(starts_at_s, :tdb),
          ends_at: Epoch.new!(ends_at_s, :tdb),
          metadata: %{
            target_id: target_id,
            target_priority: priority,
            max_elevation_deg: 60.0,
            minimum_elevation_deg: 10.0
          }
        }
      ],
      source: %{target_id: target_id}
    }
  end

  defp access_result(scenario_id, ground_station_id, starts_at_s, ends_at_s) do
    %{
      scenario_id: scenario_id,
      event_type: :ground_station_access,
      events: [
        %{
          type: :ground_station_access,
          starts_at: Epoch.new!(starts_at_s, :tdb),
          ends_at: Epoch.new!(ends_at_s, :tdb),
          metadata: %{
            max_elevation_deg: 45.0,
            minimum_elevation_deg: 5.0
          }
        }
      ],
      source: %{ground_station_id: ground_station_id}
    }
  end
end
