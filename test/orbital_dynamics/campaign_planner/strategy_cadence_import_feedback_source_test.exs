Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyCadenceImportFeedbackSourceTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport, except: [maneuver: 2]

  alias OrbitalDynamics.Schema

  test "strategy derives operational feedback from prior Cadence import source review rows" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          downlink("dl_cadence_review", 100.0, 160.0)
          |> Map.put("estimated_throughput_mb", 100.0)
        ],
        "cadence_import_manifest" => %{
          "schema_contract" => "cadence_import_manifest.v1",
          "source_artifact_type" => "operator_review_package.v1",
          "provenance" => %{"trust_boundary" => "cadence_manifest_feedback_archive"},
          "rows" => [
            %{
              "id" => "cadence_import:realized_feedback:dl_cadence_review",
              "source_review_type" => "realized_feedback",
              "approval_status" => "operator_review_required",
              "required_operator_action" => "review_realized_feedback",
              "trust_boundary" => "cadence_feedback_queue",
              "source_review_row" => %{
                "id" => "operator_review:realized_feedback:dl_cadence_review",
                "review_type" => "realized_feedback",
                "activity_id" => "dl_cadence_review",
                "activity_type" => "downlink",
                "feedback_status" => "matched",
                "realized_status" => "completed",
                "ground_station_id" => "equator_prime",
                "confidence_weight" => "2.0",
                "confidence_weight_source" => "cadence_sample_size",
                "source_feedback" => %{
                  "activity_id" => "dl_cadence_review",
                  "status" => "matched",
                  "realized_status" => "completed",
                  "planned_type" => "downlink",
                  "ground_station_id" => "equator_prime",
                  "contact_success_factor" => 0.25,
                  "actual_throughput_mb" => 25.0,
                  "estimated_throughput_mb" => 100.0,
                  "required_downlink_mb" => 100.0
                }
              }
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}, %{id: "review"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 0.25
           }

    assert Enum.any?(
             get_in(artifact, ["operational_feedback_provenance", "sources"]),
             &(&1["source"] == "prior_plan.cadence_import_manifest.rows.source_review_row" and
                 &1["source_report_contract"] == "cadence_import_manifest.v1" and
                 &1["source_report_row_count"] == 1 and
                 &1["source_review_type_counts"] == %{"realized_feedback" => 1} and
                 &1["source_review_action_counts"] == %{"review_realized_feedback" => 1} and
                 &1["weighted_feedback_row_count"] == 1 and
                 &1["feedback_weight_sources"] == ["cadence_sample_size"])
           )

    assert %{
             "type" => "contact_success_feedback",
             "ground_station_id" => "equator_prime",
             "contact_success_factor" => 0.25,
             "feedback_source" => "operational_feedback.contact_success_rate"
           } = List.first(branch(artifact, "derived_contact_success_feedback")["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives operational feedback from top-level Cadence import feedback rows" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          downlink("dl_cadence_top_level", 100.0, 160.0)
          |> Map.put("estimated_throughput_mb", 100.0),
          maneuver("burn_cadence_top_level", 220.0)
        ],
        "cadence_import_manifest" => %{
          "schema_contract" => "cadence_import_manifest.v1",
          "source_artifact_type" => "timeline_feedback_report.v1",
          "rows" => [
            %{
              "id" => "cadence_import:realized_feedback:dl_cadence_top_level",
              "source_review_row_id" => "operator_review:realized_feedback:dl_cadence_top_level",
              "source_review_type" => "realized_feedback",
              "source_review_action" => "review_realized_feedback",
              "approval_status" => "operator_review_required",
              "activity_id" => "dl_cadence_top_level",
              "activity_type" => "downlink",
              "feedback_status" => "matched",
              "realized_status" => "completed",
              "ground_station_id" => "equator_prime",
              "contact_success_factor" => 0.6,
              "actual_throughput_mb" => 60.0,
              "estimated_throughput_mb" => 100.0,
              "required_downlink_mb" => 100.0,
              "confidence_weight" => "4.0",
              "confidence_weight_source" => "cadence_import_sample_size",
              "trust_boundary" => "cadence_feedback_queue"
            },
            %{
              "id" => "cadence_import:realized_feedback:burn_cadence_top_level",
              "source_review_row_id" =>
                "operator_review:realized_feedback:burn_cadence_top_level",
              "source_review_type" => "realized_feedback",
              "source_review_action" => "review_realized_feedback",
              "approval_status" => "operator_review_required",
              "activity_id" => "burn_cadence_top_level",
              "activity_type" => "impulsive_burn",
              "feedback_status" => "matched",
              "realized_status" => "completed",
              "maneuver_success_factor" => 0.4,
              "execution_uncertainty" => %{
                "timing_3sigma_s" => "80.0",
                "delta_v_3sigma_km_s" => ["0.0", "0.002", "0.0"],
                "source" => "cadence_import_realized_covariance"
              },
              "trust_boundary" => "cadence_feedback_queue"
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

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 0.6
           }

    assert Enum.any?(
             get_in(artifact, ["operational_feedback_provenance", "sources"]),
             &(&1["source"] == "prior_plan.cadence_import_manifest.rows.source_review_row" and
                 &1["source_report_contract"] == "cadence_import_manifest.v1" and
                 &1["source_report_row_count"] == 2 and
                 &1["source_review_type_counts"] == %{"realized_feedback" => 2} and
                 &1["source_review_action_counts"] == %{"review_realized_feedback" => 2} and
                 &1["weighted_feedback_row_count"] == 1 and
                 &1["feedback_weight_sources"] == ["cadence_import_sample_size"])
           )

    assert %{
             "ground_station_id" => "equator_prime",
             "contact_success_factor" => 0.6
           } = List.first(branch(artifact, "derived_contact_success_feedback")["events"])

    assert get_in(artifact, ["operational_feedback", "maneuver_success_rate"]) == %{
             "burn_cadence_top_level" => 0.4
           }

    assert get_in(artifact, ["operational_feedback", "maneuver_execution_uncertainty"]) == %{
             "burn_cadence_top_level" => %{
               "execution_uncertainty_status" => "declared",
               "execution_uncertainty" => %{
                 "timing_3sigma_s" => "80.0",
                 "delta_v_3sigma_km_s" => ["0.0", "0.002", "0.0"],
                 "source" => "cadence_import_realized_covariance"
               },
               "timing_3sigma_s" => 80.0,
               "delta_v_3sigma_km_s" => [0.0, 0.002, 0.0],
               "delta_v_3sigma_magnitude_km_s" => 0.002,
               "execution_uncertainty_source" => "cadence_import_realized_covariance"
             }
           }

    realized_maneuver_branch =
      branch(artifact, "derived_realized_feedback_burn_cadence_top_level")

    assert Enum.any?(
             realized_maneuver_branch["events"],
             &(&1["type"] == "maneuver_success_feedback" and
                 &1["activity_id"] == "burn_cadence_top_level" and
                 &1["feedback_source"] ==
                   "prior_plan.cadence_import_manifest.rows.realized_feedback" and
                 &1["trust_boundary"] == "cadence_feedback_queue")
           )

    assert Enum.any?(
             realized_maneuver_branch["events"],
             &(&1["type"] == "maneuver_execution_uncertainty_feedback" and
                 &1["activity_id"] == "burn_cadence_top_level" and
                 &1["timing_3sigma_s"] == 80.0 and
                 &1["execution_uncertainty_source"] == "cadence_import_realized_covariance" and
                 &1["feedback_source"] ==
                   "prior_plan.cadence_import_manifest.rows.realized_feedback" and
                 &1["derivation_reasons"] == ["realized_maneuver_uncertainty"])
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from top-level Cadence import operational timeline rows" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          downlink("dl_cadence_timeline_review", 100.0, 160.0)
          |> Map.put("estimated_throughput_mb", 100.0),
          maneuver("burn_cadence_timeline_review", 220.0)
        ],
        "cadence_import_manifest" => %{
          "schema_contract" => "cadence_import_manifest.v1",
          "source_artifact_type" => "operator_review_package.v1",
          "provenance" => %{"trust_boundary" => "cadence_manifest_feedback_archive"},
          "rows" => [
            %{
              "id" => "cadence_import:operational_timeline:dl_cadence_timeline_review",
              "source_review_type" => "operational_timeline_review",
              "source_review_action" => "review_contact_feedback",
              "import_action" => "review_operational_timeline",
              "approval_status" => "operator_review_required",
              "required_operator_action" => "review_operational_timeline",
              "activity_id" => "dl_cadence_timeline_review",
              "activity_type" => "downlink",
              "scenario_id" => "leo_1",
              "ground_station_id" => "equator_prime",
              "contact_success_factor" => 0.3,
              "actual_throughput_mb" => 45.0,
              "estimated_throughput_mb" => 100.0,
              "trust_boundary" => "cadence_timeline_review_queue"
            },
            %{
              "id" => "cadence_import:operational_timeline:burn_cadence_timeline_review",
              "source_review_type" => "operational_timeline_review",
              "source_review_action" => "review_maneuver_recommendation",
              "import_action" => "review_operational_timeline",
              "approval_status" => "operator_review_required",
              "required_operator_action" => "review_operational_timeline",
              "activity_id" => "burn_cadence_timeline_review",
              "activity_type" => "impulsive_burn",
              "scenario_id" => "leo_1",
              "maneuver_success_factor" => 0.45,
              "execution_uncertainty" => %{
                "timing_3sigma_s" => "95.0",
                "delta_v_3sigma_km_s" => ["0.0", "0.0035", "0.0"],
                "source" => "cadence_import_timeline_covariance"
              },
              "trust_boundary" => "cadence_timeline_review_queue"
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

    timeline_branch =
      branch(
        artifact,
        "derived_operational_timeline_feedback_dl_cadence_timeline_review"
      )

    assert [
             %{
               "type" => "contact_success_feedback",
               "activity_id" => "dl_cadence_timeline_review",
               "ground_station_id" => "equator_prime",
               "contact_success_factor" => 0.3,
               "feedback_source" =>
                 "prior_plan.cadence_import_manifest.rows.operational_timeline_review",
               "feedback_scope" => "operational_timeline",
               "trust_boundary" => "cadence_timeline_review_queue"
             },
             %{
               "type" => "station_throughput_feedback",
               "activity_id" => "dl_cadence_timeline_review",
               "station_throughput_factor" => 0.45,
               "feedback_scope" => "operational_timeline",
               "trust_boundary" => "cadence_timeline_review_queue"
             }
           ] = timeline_branch["events"]

    maneuver_timeline_branch =
      branch(
        artifact,
        "derived_operational_timeline_feedback_burn_cadence_timeline_review"
      )

    assert Enum.any?(
             maneuver_timeline_branch["events"],
             &(&1["type"] == "maneuver_success_feedback" and
                 &1["activity_id"] == "burn_cadence_timeline_review" and
                 &1["maneuver_success_factor"] == 0.45 and
                 &1["feedback_source"] ==
                   "prior_plan.cadence_import_manifest.rows.operational_timeline_review" and
                 &1["trust_boundary"] == "cadence_timeline_review_queue")
           )

    assert Enum.any?(
             maneuver_timeline_branch["events"],
             &(&1["type"] == "maneuver_execution_uncertainty_feedback" and
                 &1["activity_id"] == "burn_cadence_timeline_review" and
                 &1["timing_3sigma_s"] == 95.0 and
                 &1["delta_v_3sigma_magnitude_km_s"] == 0.0035 and
                 &1["execution_uncertainty_source"] == "cadence_import_timeline_covariance" and
                 &1["feedback_source"] ==
                   "prior_plan.cadence_import_manifest.rows.operational_timeline_review" and
                 &1["derivation_reasons"] == ["operational_timeline_maneuver_uncertainty"])
           )

    assert get_in(artifact, ["operational_feedback", "maneuver_success_rate"]) == %{
             "burn_cadence_timeline_review" => 0.45
           }

    assert get_in(artifact, ["operational_feedback", "maneuver_execution_uncertainty"]) == %{
             "burn_cadence_timeline_review" => %{
               "execution_uncertainty_status" => "declared",
               "execution_uncertainty" => %{
                 "timing_3sigma_s" => "95.0",
                 "delta_v_3sigma_km_s" => ["0.0", "0.0035", "0.0"],
                 "source" => "cadence_import_timeline_covariance"
               },
               "timing_3sigma_s" => 95.0,
               "delta_v_3sigma_km_s" => [0.0, 0.0035, 0.0],
               "delta_v_3sigma_magnitude_km_s" => 0.0035,
               "execution_uncertainty_source" => "cadence_import_timeline_covariance"
             }
           }

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives operational feedback from prior Cadence import source feedback rows" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [downlink("dl_cadence_feedback", 100.0, 160.0)],
        "cadence_import_manifest" => %{
          "schema_contract" => "cadence_import_manifest.v1",
          "source_artifact_type" => "campaign_strategy.v3",
          "provenance" => %{"trust_boundary" => "cadence_manifest_feedback_archive"},
          "rows" => [
            %{
              "id" => "cadence_import:strategy_branch:feedback",
              "import_action" => "import_strategy_recommendation",
              "source_review_type" => "strategy_branch_comparison",
              "source_operational_feedback" => %{
                "contact_success_rate" => %{"equator_prime" => 0.42},
                "station_throughput_factor" => %{"equator_prime" => 0.5}
              },
              "source_operational_feedback_provenance" => %{
                "source_count" => 1,
                "sources" => [
                  %{
                    "source" => "campaign_strategy.operational_feedback",
                    "trust_boundary" => "strategy_feedback_archive"
                  }
                ]
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

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 0.42
           }

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 0.5
           }

    assert %{
             "source" => "prior_plan.cadence_import_manifest.rows.source_operational_feedback",
             "source_report_contract" => "cadence_import_manifest.v1",
             "source_report_row_count" => 1,
             "source_import_action_counts" => %{"import_strategy_recommendation" => 1},
             "source_review_type_counts" => %{"strategy_branch_comparison" => 1},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "cadence_manifest_feedback_archive",
               "strategy_feedback_archive"
             ],
             "source_operational_feedback_provenance" => %{"source_count" => 1}
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] ==
                   "prior_plan.cadence_import_manifest.rows.source_operational_feedback")
             )

    assert %{
             "type" => "contact_success_feedback",
             "ground_station_id" => "equator_prime",
             "contact_success_factor" => 0.42
           } = List.first(branch(artifact, "derived_contact_success_feedback")["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives operational feedback from nested Cadence source review rows" do
    invalid_sections = [
      %{
        "field" => "realized_activities.target.id",
        "key" => "bad target",
        "reason" => "key_must_be_stable_id",
        "row_id" => "realized_bad_target",
        "row_index" => 1
      }
    ]

    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [downlink("dl_nested_cadence_feedback", 100.0, 160.0)],
        "cadence_import_manifest" => %{
          "schema_contract" => "cadence_import_manifest.v1",
          "source_artifact_type" => "operator_review_package.v1",
          "provenance" => %{"trust_boundary" => "cadence_manifest_feedback_archive"},
          "rows" => [
            %{
              "id" => "cadence_import:strategy_branch:nested_feedback",
              "import_action" => "review_strategy_recommendation",
              "source_review_type" => "strategy_recommendation",
              "source_review_row" => %{
                "id" => "operator_review:strategy_recommendation:nested_feedback",
                "review_type" => "strategy_recommendation",
                "source_operational_feedback" => %{
                  "contact_success_rate" => %{"equator_prime" => 0.47}
                },
                "source_operational_feedback_provenance" => %{
                  "source_count" => 1,
                  "sources" => [
                    %{
                      "source" => "operator_review.source_operational_feedback",
                      "trust_boundary" => "nested_review_archive"
                    }
                  ]
                }
              }
            },
            %{
              "id" => "cadence_import:warning:nested_feedback",
              "import_action" => "review_warning",
              "source_review_type" => "warning",
              "source_review_row" => %{
                "id" => "operator_review:warning:nested_feedback",
                "review_type" => "warning",
                "source_operational_feedback" => %{
                  "invalid_feedback_sections" => invalid_sections
                },
                "source_operational_feedback_provenance" => %{
                  "invalid_operational_feedback_sections" => invalid_sections
                }
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

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 0.47
           }

    source =
      Enum.find(
        artifact["operational_feedback_provenance"]["sources"],
        &(&1["source"] ==
            "prior_plan.cadence_import_manifest.rows.source_operational_feedback")
      )

    assert %{
             "source_report_contract" => "cadence_import_manifest.v1",
             "source_report_row_count" => 2,
             "source_import_action_counts" => %{
               "review_strategy_recommendation" => 1,
               "review_warning" => 1
             },
             "source_review_type_counts" => %{
               "strategy_recommendation" => 1,
               "warning" => 1
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "cadence_manifest_feedback_archive",
               "nested_review_archive"
             ],
             "invalid_operational_feedback_input" => true
           } = source

    assert [
             %{
               "field" => "realized_activities.target.id",
               "key" => "bad target",
               "reason" => "key_must_be_stable_id",
               "row_id" => "operator_review:warning:nested_feedback",
               "source_review_type" => "warning",
               "import_action" => "review_warning"
             }
           ] = source["invalid_operational_feedback_sections"]

    assert %{
             "type" => "contact_success_feedback",
             "ground_station_id" => "equator_prime",
             "contact_success_factor" => 0.47
           } = List.first(branch(artifact, "derived_contact_success_feedback")["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp maneuver(id, epoch_s) do
    %{
      "id" => id,
      "type" => "maneuver",
      "scenario_id" => "leo_1",
      "starts_at_s" => epoch_s,
      "ends_at_s" => epoch_s,
      "duration_s" => 0.0,
      "score" => 0.0
    }
  end
end
