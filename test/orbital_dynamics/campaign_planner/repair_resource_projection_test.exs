Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.RepairResourceProjectionTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "repair replacement ranking internalizes calibrated projected resource risk" do
    pressured_observation =
      "obs_pressured"
      |> observe("leo_1", "target_a", 500.0, 560.0, 10.0)
      |> Map.merge(%{
        "estimated_storage_mb" => 40.0,
        "score_terms" => %{"target_value" => 10.0},
        "source_window_id" => "window:leo_1:target_visibility:target_a:2",
        "source_window" => %{
          "id" => "window:leo_1:target_visibility:target_a:2",
          "type" => "target_visibility"
        }
      })

    nominal_observation =
      "obs_nominal"
      |> observe("leo_2", "target_a", 500.0, 560.0, 9.5)
      |> Map.merge(%{
        "estimated_storage_mb" => 40.0,
        "score_terms" => %{"target_value" => 9.5},
        "source_window_id" => "window:leo_2:target_visibility:target_a:2",
        "source_window" => %{
          "id" => "window:leo_2:target_visibility:target_a:2",
          "type" => "target_visibility"
        }
      })

    deeper_pressured_observation =
      "obs_deeper_pressured"
      |> observe("leo_3", "target_a", 500.0, 560.0, 9.0)
      |> Map.merge(%{
        "estimated_storage_mb" => 40.0,
        "score_terms" => %{"target_value" => 9.0},
        "source_window_id" => "window:leo_3:target_visibility:target_a:2",
        "source_window" => %{
          "id" => "window:leo_3:target_visibility:target_a:2",
          "type" => "target_visibility"
        }
      })

    plan = %{
      "activities" => [observe("obs_1", "leo_1", "target_a", 100.0, 160.0, 10.0)],
      "candidate_activities" => []
    }

    resource_summaries = [
      %{
        "schema_contract" => "resource_summary.v1",
        "spacecraft_id" => "leo_1",
        "storage_capacity_mb" => 1_000.0,
        "storage_used_mb" => 100.0,
        "downlink_capacity_mb" => 500.0,
        "payload_available" => false,
        "antenna_available" => true
      },
      %{
        "schema_contract" => "resource_summary.v1",
        "spacecraft_id" => "leo_2",
        "storage_capacity_mb" => 1_000.0,
        "storage_used_mb" => 100.0,
        "downlink_capacity_mb" => 500.0,
        "payload_available" => true,
        "antenna_available" => true
      },
      %{
        "schema_contract" => "resource_summary.v1",
        "spacecraft_id" => "leo_3",
        "storage_capacity_mb" => 1_000.0,
        "storage_used_mb" => 100.0,
        "downlink_capacity_mb" => 500.0,
        "payload_available" => false,
        "antenna_available" => true
      }
    ]

    candidate_refresh =
      candidate_refresh_artifact(
        [pressured_observation, nominal_observation, deeper_pressured_observation],
        resource_summaries: resource_summaries
      )

    common_opts = [
      realized_state: %{activities: [%{id: "obs_1", status: "failed"}]},
      current_epoch_s: 165.0,
      candidate_refresh: candidate_refresh
    ]

    nominal_artifact =
      repair(plan, Keyword.put(common_opts, :scoring_policy, %{"risk_weight" => "1.0"}))

    pressured_artifact =
      repair(plan, Keyword.put(common_opts, :scoring_policy, %{"risk_weight" => "0.25"}))

    assert [%{"id" => "obs_nominal", "scenario_id" => "leo_2"}] =
             nominal_artifact["activities"]

    assert %{
             "selected_candidate_id" => "obs_nominal",
             "evaluated_candidate_count" => 3,
             "rows" => [
               %{
                 "rank" => 1,
                 "candidate_id" => "obs_nominal",
                 "resource_projection_pressure_penalty" => nominal_resource_penalty,
                 "selected" => true,
                 "ranking_score" => nominal_ranking_score
               },
               %{
                 "rank" => 2,
                 "candidate_id" => "obs_pressured",
                 "resource_projection_pressure_penalty" => -1.0,
                 "resource_projection_pressure_risk_indicators" => [
                   %{
                     "type" => "payload_unavailable",
                     "candidate_id" => "obs_pressured",
                     "spacecraft_id" => "leo_1"
                   }
                 ],
                 "selected" => false,
                 "ranking_score" => pressured_ranking_score
               },
               %{
                 "rank" => 3,
                 "candidate_id" => "obs_deeper_pressured",
                 "resource_projection_pressure_penalty" => -1.0,
                 "resource_projection_pressure_risk_indicators" => [
                   %{
                     "type" => "payload_unavailable",
                     "candidate_id" => "obs_deeper_pressured",
                     "spacecraft_id" => "leo_3"
                   }
                 ],
                 "selected" => false,
                 "ranking_score" => deeper_pressured_ranking_score
               }
             ]
           } =
             get_in(nominal_artifact, [
               "activities",
               Access.at(0),
               "repair",
               "replacement_ranking"
             ])

    assert_in_delta nominal_ranking_score, -94.5, 1.0e-9
    assert_in_delta pressured_ranking_score, -95.0, 1.0e-9
    assert_in_delta deeper_pressured_ranking_score, -96.0, 1.0e-9
    assert nominal_resource_penalty == 0.0

    [nominal_ranking_row, _pressured_ranking_row, _deeper_pressured_ranking_row] =
      get_in(nominal_artifact, [
        "activities",
        Access.at(0),
        "repair",
        "replacement_ranking",
        "rows"
      ])

    refute Map.has_key?(
             nominal_ranking_row,
             "resource_projection_pressure_risk_indicators"
           )

    assert [] ==
             OrbitalDynamics.CampaignPlanner.ResourceProjectionRisk.risk_indicators(
               nominal_artifact["source_resource_projection_report"]
             )

    refute Map.has_key?(
             nominal_artifact["score_terms"],
             "resource_projection_pressure_penalty"
           )

    refute "resource_projection_pressure_penalty" in nominal_artifact["score_term_report"][
             "score_term_keys"
           ]

    assert_in_delta nominal_artifact["score"], -94.5, 1.0e-9

    assert [%{"id" => "obs_pressured", "scenario_id" => "leo_1"}] =
             pressured_artifact["activities"]

    assert %{
             "selected_candidate_id" => "obs_pressured",
             "rows" => [
               %{
                 "candidate_id" => "obs_pressured",
                 "resource_projection_pressure_penalty" => -0.25,
                 "resource_projection_pressure_risk_indicators" => [
                   %{
                     "type" => "payload_unavailable",
                     "candidate_id" => "obs_pressured",
                     "spacecraft_id" => "leo_1"
                   }
                 ],
                 "selected" => true
               },
               %{"candidate_id" => "obs_nominal", "selected" => false},
               %{
                 "candidate_id" => "obs_deeper_pressured",
                 "resource_projection_pressure_risk_indicators" => [
                   %{
                     "candidate_id" => "obs_deeper_pressured",
                     "spacecraft_id" => "leo_3"
                   }
                 ],
                 "selected" => false
               }
             ]
           } =
             get_in(pressured_artifact, [
               "activities",
               Access.at(0),
               "repair",
               "replacement_ranking"
             ])

    [_pressured_ranking_row, nominal_ranking_row, _deeper_pressured_ranking_row] =
      get_in(pressured_artifact, [
        "activities",
        Access.at(0),
        "repair",
        "replacement_ranking",
        "rows"
      ])

    refute Map.has_key?(
             nominal_ranking_row,
             "resource_projection_pressure_risk_indicators"
           )

    assert [%{"type" => "payload_unavailable", "spacecraft_id" => "leo_1"} = source_risk] =
             OrbitalDynamics.CampaignPlanner.ResourceProjectionRisk.risk_indicators(
               pressured_artifact["source_resource_projection_report"]
             )

    refute Map.has_key?(source_risk, "candidate_id")

    assert pressured_artifact["score_terms"]["resource_projection_pressure_penalty"] == -0.25
    assert_in_delta pressured_artifact["score"], -94.25, 1.0e-9

    assert [
             %{
               "term_key" => "resource_projection_pressure_penalty",
               "value" => -0.25,
               "selected" => true
             }
           ] =
             Enum.filter(
               pressured_artifact["score_term_report"]["rows"],
               &(&1["term_key"] == "resource_projection_pressure_penalty")
             )

    assert Enum.any?(
             pressured_artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "resource_projection_review" and
                 &1["spacecraft_id"] == "leo_1")
           )

    assert Enum.any?(
             pressured_artifact["cadence_import_manifest"]["rows"],
             &(&1["import_action"] == "review_resource_projection" and
                 &1["spacecraft_id"] == "leo_1")
           )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(nominal_artifact)

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(pressured_artifact)

    legacy_artifact =
      update_in(
        pressured_artifact,
        ["activities", Access.at(0), "repair", "replacement_ranking", "rows"],
        fn rows ->
          Enum.map(rows, fn
            %{"resource_projection_pressure_risk_indicators" => indicators} = row ->
              Map.put(
                row,
                "resource_projection_pressure_risk_indicators",
                Enum.map(indicators, &Map.delete(&1, "candidate_id"))
              )

            row ->
              row
          end)
        end
      )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(legacy_artifact)

    invalid_mixed_generation =
      update_in(
        pressured_artifact,
        ["activities", Access.at(0), "repair", "replacement_ranking", "rows", Access.at(2)],
        fn row ->
          Map.update!(row, "resource_projection_pressure_risk_indicators", fn indicators ->
            Enum.map(indicators, &Map.delete(&1, "candidate_id"))
          end)
        end
      )

    assert {:error, mixed_report} = Schema.validate_artifact(invalid_mixed_generation)

    assert Enum.any?(
             mixed_report["errors"],
             &(&1["path"] ==
                 "$.activities[0].repair.replacement_ranking.rows[2].resource_projection_pressure_risk_indicators[0].candidate_id")
           )

    invalid_resource_scope =
      update_in(
        pressured_artifact,
        ["activities", Access.at(0), "repair", "replacement_ranking", "rows", Access.at(0)],
        fn row ->
          Map.update!(row, "resource_projection_pressure_risk_indicators", fn indicators ->
            Enum.map(indicators, &Map.put(&1, "spacecraft_id", "leo_2"))
          end)
        end
      )

    assert {:error, report} = Schema.validate_artifact(invalid_resource_scope)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] ==
                 "$.activities[0].repair.replacement_ranking.rows[0].resource_projection_pressure_risk_indicators[0].spacecraft_id")
           )

    invalid_ranking =
      update_in(
        pressured_artifact,
        ["activities", Access.at(0), "repair", "replacement_ranking", "rows", Access.at(0)],
        fn row ->
          row
          |> Map.put("resource_projection_pressure_penalty", -0.5)
          |> Map.update!("ranking_score", &(&1 - 0.25))
        end
      )

    assert {:error, report} = Schema.validate_artifact(invalid_ranking)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] ==
                 "$.activities[0].repair.replacement_ranking.rows[0].resource_projection_pressure_penalty")
           )
  end

  test "repair projects thin resource impacts from repaired activities" do
    replacement_observation =
      "obs_2"
      |> observe("leo_1", "target_a", 500.0, 560.0, 120.0)
      |> Map.merge(%{
        "estimated_storage_mb" => 40.0,
        "score_terms" => %{"target_value" => 120.0},
        "source_window_id" => "window:leo_1:target_visibility:target_a:2",
        "source_window" => %{
          "id" => "window:leo_1:target_visibility:target_a:2",
          "type" => "target_visibility"
        }
      })

    replacement_downlink = refreshed_downlink("dl_2", 700.0, 760.0)

    artifact =
      repair(
        %{
          "activities" => [
            observe("obs_1", "leo_1", "target_a", 100.0, 160.0, 100.0),
            downlink("dl_1", 180.0, 240.0)
          ],
          "candidate_activities" => []
        },
        realized_state: %{
          activities: [
            %{id: "obs_1", status: "failed"},
            %{id: "dl_1", status: "missed"}
          ]
        },
        current_epoch_s: 250.0,
        candidate_refresh:
          candidate_refresh_artifact([replacement_observation, replacement_downlink],
            resource_summaries: [
              %{
                "schema_contract" => "resource_summary.v1",
                "spacecraft_id" => "leo_1",
                "fuel_margin" => 0.8,
                "power_margin" => 0.7,
                "storage_capacity_mb" => 1000.0,
                "storage_used_mb" => 250.0,
                "downlink_capacity_mb" => 500.0,
                "downlink_margin" => 0.6,
                "payload_available" => true,
                "antenna_available" => true
              }
            ]
          ),
        approval_policy: %{policy_bundle_id: "conservative_ops_v1"}
      )

    assert %{
             "schema_contract" => "resource_projection_report.v1",
             "model" => "thin_repaired_activity_resource_projection",
             "input_resource_summary_count" => 1,
             "activity_count" => 2,
             "projected_resources" => [
               %{
                 "spacecraft_id" => "leo_1",
                 "activity_count" => 2,
                 "observation_count" => 1,
                 "downlink_count" => 1,
                 "estimated_storage_produced_mb" => 40.0,
                 "estimated_downlink_mb" => 60.0,
                 "starting_storage_used_mb" => 250.0,
                 "projected_storage_used_mb" => 230.0,
                 "projected_storage_margin" => projected_storage_margin,
                 "projected_downlink_margin" => projected_downlink_margin
               }
             ]
           } = artifact["source_resource_projection_report"]

    assert_in_delta projected_storage_margin, 0.77, 1.0e-12
    assert_in_delta projected_downlink_margin, 0.88, 1.0e-12

    refute Map.has_key?(artifact["score_terms"], "resource_projection_pressure_penalty")

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(artifact["source_resource_projection_report"])

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "repair resource projection uses station capacity adjusted downlink throughput" do
    replacement_downlink =
      "dl_2"
      |> refreshed_downlink(700.0, 760.0)
      |> Map.merge(%{
        "station_capacity_fraction" => 0.5,
        "throughput_model" => %{
          "estimated_throughput_mb" => 60.0,
          "station_capacity_fraction" => 0.5
        }
      })

    artifact =
      repair(
        %{
          "activities" => [downlink("dl_1", 180.0, 240.0)],
          "candidate_activities" => []
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 250.0,
        candidate_refresh:
          candidate_refresh_artifact([replacement_downlink],
            resource_summaries: [
              %{
                "schema_contract" => "resource_summary.v1",
                "spacecraft_id" => "leo_1",
                "storage_capacity_mb" => 1000.0,
                "storage_used_mb" => 250.0,
                "downlink_capacity_mb" => 500.0,
                "payload_available" => true,
                "antenna_available" => true
              }
            ]
          ),
        approval_policy: %{
          blocked_risk_types: [
            "spacecraft_degraded_unprotected",
            "no_viable_downlink",
            "storage_overflow",
            "downlink_shortfall"
          ]
        }
      )

    assert %{
             "assumptions" => %{
               "downlink_model" =>
                 "capacity_adjusted_estimated_throughput_consumes_downlink_capacity"
             },
             "projected_resources" => [
               %{
                 "estimated_downlink_mb" => 30.0,
                 "starting_storage_used_mb" => 250.0,
                 "projected_storage_used_mb" => 220.0,
                 "projected_storage_margin" => projected_storage_margin,
                 "projected_downlink_margin" => projected_downlink_margin
               }
             ]
           } = report = artifact["source_resource_projection_report"]

    assert_in_delta projected_storage_margin, 0.78, 1.0e-12
    assert_in_delta projected_downlink_margin, 0.94, 1.0e-12

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "repair surfaces resource projection storage overflow and downlink shortfall" do
    replacement_observation =
      "obs_2"
      |> observe("leo_1", "target_a", 500.0, 560.0, 120.0)
      |> Map.merge(%{
        "estimated_storage_mb" => 50.0,
        "score_terms" => %{"target_value" => 120.0},
        "source_window_id" => "window:leo_1:target_visibility:target_a:2",
        "source_window" => %{
          "id" => "window:leo_1:target_visibility:target_a:2",
          "type" => "target_visibility"
        }
      })

    replacement_downlink = refreshed_downlink("dl_2", 700.0, 720.0)

    artifact =
      repair(
        %{
          "activities" => [
            observe("obs_1", "leo_1", "target_a", 100.0, 160.0, 100.0),
            downlink("dl_1", 180.0, 240.0)
          ],
          "candidate_activities" => []
        },
        realized_state: %{
          activities: [
            %{id: "obs_1", status: "failed"},
            %{id: "dl_1", status: "missed"}
          ]
        },
        current_epoch_s: 250.0,
        candidate_refresh:
          candidate_refresh_artifact([replacement_observation, replacement_downlink],
            resource_summaries: [
              %{
                "schema_contract" => "resource_summary.v1",
                "spacecraft_id" => "leo_1",
                "fuel_margin" => 0.8,
                "power_margin" => 0.7,
                "storage_capacity_mb" => 100.0,
                "storage_used_mb" => 90.0,
                "downlink_capacity_mb" => 10.0,
                "downlink_margin" => 0.6,
                "payload_available" => true,
                "antenna_available" => true
              }
            ]
          ),
        approval_policy: %{
          blocked_risk_types: [
            "spacecraft_degraded_unprotected",
            "no_viable_downlink",
            "storage_overflow",
            "downlink_shortfall"
          ]
        }
      )

    assert %{
             "projected_resources" => [
               %{
                 "spacecraft_id" => "leo_1",
                 "estimated_storage_produced_mb" => 50.0,
                 "estimated_downlink_mb" => 20.0,
                 "starting_storage_used_mb" => 90.0,
                 "projected_storage_used_mb" => 120.0,
                 "projected_storage_margin" => projected_storage_margin,
                 "projected_storage_overflow_mb" => 20.0,
                 "projected_downlink_margin" => projected_downlink_margin,
                 "projected_downlink_shortfall_mb" => 10.0,
                 "approval_status" => "blocked_by_policy",
                 "policy_decision" => %{
                   "schema_contract" => "policy_decision.v1",
                   "classification" => "blocked_by_policy"
                 },
                 "warnings" => warnings
               } = row
             ]
           } = report = artifact["source_resource_projection_report"]

    assert projected_storage_margin == 0.0
    assert projected_downlink_margin == 0.0
    assert "projected storage exceeds declared capacity by 20.0 MB" in warnings
    assert "projected downlink demand exceeds declared capacity by 10.0 MB" in warnings

    assert artifact["score_terms"]["resource_projection_pressure_penalty"] == -2.0

    assert [
             %{
               "term_key" => "resource_projection_pressure_penalty",
               "value" => -2.0,
               "selected" => true
             }
           ] =
             Enum.filter(
               artifact["score_term_report"]["rows"],
               &(&1["term_key"] == "resource_projection_pressure_penalty")
             )

    assert %{
             "objective" =>
               "maximize repaired activity value while minimizing churn, schedule movement, resource-projection pressure, contact pressure, resource-filter pressure, refresh-budget pressure, candidate-rejection pressure, operational-readiness pressure, and quality-gate pressure",
             "score_term_keys" => score_term_keys,
             "tradeoffs" => [
               %{
                 "score_terms" => %{
                   "resource_projection_pressure_penalty" => -2.0
                 }
               }
             ]
           } = artifact["objective_tradeoff_report"]

    assert "resource_projection_pressure_penalty" in score_term_keys

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)

    assert %{
             "resource_projection_review_count" => 1
           } = artifact["operator_review_package"]

    assert %{
             "review_type" => "resource_projection_review",
             "source" => "campaign_repair.source_resource_projection_report.projected_resources",
             "approval_status" => "blocked_by_policy",
             "projected_storage_overflow_mb" => 20.0,
             "projected_downlink_shortfall_mb" => 10.0,
             "source_policy_decision" => %{"classification" => "blocked_by_policy"},
             "source_resource_projection" => ^row
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "resource_projection_review")
             )

    assert %{
             "import_action" => "review_resource_projection",
             "source_review_type" => "resource_projection_review",
             "approval_status" => "blocked_by_policy",
             "import_status" => "review_required_before_import",
             "projected_storage_overflow_mb" => 20.0,
             "projected_downlink_shortfall_mb" => 10.0,
             "source_policy_decision" => %{"classification" => "blocked_by_policy"},
             "source_resource_projection" => ^row
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["import_action"] == "review_resource_projection")
             )

    review_package = OrbitalDynamics.OperatorReview.from_resource_projection_report(report)

    assert [
             %{
               "review_type" => "resource_projection_review",
               "approval_status" => "blocked_by_policy",
               "projected_storage_overflow_mb" => 20.0,
               "projected_downlink_shortfall_mb" => 10.0,
               "source_policy_decision" => %{"classification" => "blocked_by_policy"},
               "source_resource_projection" => ^row
             }
           ] = review_package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review_package)
  end

  test "repair scores resource projection battery depletion pressure" do
    replacement_downlink =
      "dl_battery"
      |> refreshed_downlink(700.0, 760.0)
      |> Map.put("estimated_energy_used_wh", 80.0)

    artifact =
      repair(
        %{
          "activities" => [downlink("dl_1", 180.0, 240.0)],
          "candidate_activities" => []
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 250.0,
        candidate_refresh:
          candidate_refresh_artifact([replacement_downlink],
            resource_summaries: [
              %{
                "schema_contract" => "resource_summary.v1",
                "spacecraft_id" => "leo_1",
                "storage_capacity_mb" => 1000.0,
                "storage_used_mb" => 250.0,
                "downlink_capacity_mb" => 500.0,
                "battery_capacity_wh" => 100.0,
                "battery_energy_used_wh" => 50.0,
                "payload_available" => true,
                "antenna_available" => true
              }
            ]
          )
      )

    assert %{
             "projected_resources" => [
               %{
                 "projected_battery_overuse_wh" => 30.0,
                 "activity_resource_flow" => [
                   %{
                     "activity_id" => "dl_battery",
                     "battery_overuse_wh" => 30.0
                   }
                 ]
               }
             ]
           } = artifact["source_resource_projection_report"]

    assert artifact["score_terms"]["resource_projection_pressure_penalty"] == -1.0

    assert [
             %{
               "term_key" => "resource_projection_pressure_penalty",
               "value" => -1.0,
               "selected" => true
             }
           ] =
             Enum.filter(
               artifact["score_term_report"]["rows"],
               &(&1["term_key"] == "resource_projection_pressure_penalty")
             )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "repair scores selected resource projection thermal-margin pressure" do
    replacement_downlink = refreshed_downlink("dl_thermal", 700.0, 760.0)

    artifact =
      repair(
        %{
          "activities" => [downlink("dl_1", 180.0, 240.0)],
          "candidate_activities" => []
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 250.0,
        candidate_refresh:
          candidate_refresh_artifact([replacement_downlink],
            resource_summaries: [
              %{
                "schema_contract" => "resource_summary.v1",
                "spacecraft_id" => "leo_1",
                "storage_capacity_mb" => 1000.0,
                "storage_used_mb" => 250.0,
                "downlink_capacity_mb" => 500.0,
                "thermal_margin_c" => -2.0,
                "payload_available" => true,
                "antenna_available" => true
              }
            ]
          ),
        scoring_policy: %{"risk_weight" => "1.5"}
      )

    assert %{
             "projected_resources" => [
               %{
                 "thermal_margin_c" => -2.0,
                 "resource_pressure_types" => ["thermal_margin_below_limit"]
               }
             ]
           } = artifact["source_resource_projection_report"]

    assert artifact["score_terms"]["resource_projection_pressure_penalty"] == -1.5

    assert [
             %{
               "term_key" => "resource_projection_pressure_penalty",
               "value" => -1.5,
               "selected" => true
             }
           ] =
             Enum.filter(
               artifact["score_term_report"]["rows"],
               &(&1["term_key"] == "resource_projection_pressure_penalty")
             )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "repair scores selected resource projection payload-unavailable pressure" do
    replacement_observation =
      "obs_payload"
      |> observe("leo_1", "target_a", 500.0, 560.0, 120.0)
      |> Map.merge(%{
        "estimated_storage_mb" => 40.0,
        "score_terms" => %{"target_value" => 120.0},
        "source_window_id" => "window:leo_1:target_visibility:target_a:2",
        "source_window" => %{
          "id" => "window:leo_1:target_visibility:target_a:2",
          "type" => "target_visibility"
        }
      })

    artifact =
      repair(
        %{
          "activities" => [observe("obs_1", "leo_1", "target_a", 100.0, 160.0, 100.0)],
          "candidate_activities" => []
        },
        realized_state: %{activities: [%{id: "obs_1", status: "failed"}]},
        current_epoch_s: 250.0,
        candidate_refresh:
          candidate_refresh_artifact([replacement_observation],
            resource_summaries: [
              %{
                "schema_contract" => "resource_summary.v1",
                "spacecraft_id" => "leo_1",
                "storage_capacity_mb" => 1000.0,
                "storage_used_mb" => 250.0,
                "downlink_capacity_mb" => 500.0,
                "payload_available" => false,
                "antenna_available" => true
              }
            ]
          )
      )

    assert [%{"id" => "obs_payload"}] = artifact["activities"]

    assert %{
             "projected_resources" => [
               %{
                 "payload_available" => false,
                 "resource_pressure_types" => ["payload_unavailable"]
               }
             ]
           } = artifact["source_resource_projection_report"]

    assert artifact["score_terms"]["resource_projection_pressure_penalty"] == -1.0

    assert [
             %{
               "term_key" => "resource_projection_pressure_penalty",
               "value" => -1.0,
               "selected" => true
             }
           ] =
             Enum.filter(
               artifact["score_term_report"]["rows"],
               &(&1["term_key"] == "resource_projection_pressure_penalty")
             )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
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
end
