Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyTimelineDiffObservationPressureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives changed timeline diff collection latency refresh from late observation rows" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          refreshed_downlink("dl_latency_recovery", 180.0, 240.0)
          |> Map.put("estimated_throughput_mb", 60.0)
        ],
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_latency_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:obs_latency",
              "rank" => 1,
              "timeline_id" => "timeline:obs_latency",
              "diff_status" => "changed",
              "changed_fields" => [
                "actual_delivery_latency_s",
                "target_delivery_latency_s",
                "collection_latency_gap_s"
              ],
              "objective_id" => "objective:latency_alpha",
              "source_activity_id" => "obs_latency_source",
              "replacement_activity_id" => "obs_latency_replacement",
              "source_activity_type" => "observe",
              "replacement_activity_type" => "observe",
              "source_target_id" => "target_a",
              "replacement_target_id" => "target_a",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "replacement_activity_context" => %{
                "starts_at_s" => 60.0,
                "ends_at_s" => 120.0,
                "ground_station" => %{"id" => "equator_prime"},
                "collection_id" => "collection_alpha",
                "collections" => [
                  %{"id" => "collection_alpha"},
                  %{"collection_id" => "collection_beta"}
                ],
                "product_id" => "product_alpha",
                "products" => [%{"id" => "product_alpha"}, %{"product_id" => "product_beta"}],
                "payload_id" => "camera_a",
                "instrument_id" => "instrument_a",
                "target_delivery_latency_s" => 180.0,
                "actual_delivery_latency_s" => 260.0,
                "collection_latency_gap_s" => 80.0,
                "required_downlink_mb" => 45.0,
                "selected_downlink_mb" => 5.0
              },
              "required_operator_action" => "review_collection_latency"
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

    branch = branch(artifact, "derived_timeline_diff_changed_obs_latency_source")

    assert %{
             "type" => "downlink_completion_gap",
             "objective_id" => "objective:latency_alpha",
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
             "instrument_id" => "instrument_a",
             "starts_at_s" => 120.0,
             "ends_at_s" => 300.0,
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 45.0,
             "planned_downlink_mb" => 5.0,
             "max_latency_s" => 180.0,
             "planned_latency_s" => 260.0,
             "latency_gap_s" => 80.0,
             "source_activity_id" => "obs_latency_source",
             "source_activity_ids" => ["obs_latency_replacement", "obs_latency_source"],
             "missed_downlink_activity_id" => "obs_latency_replacement",
             "timeline_id" => "timeline:obs_latency",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "feedback_key" => "obs_latency_source",
             "trust_boundary" => "ops_latency_review",
             "derivation_reasons" => [
               "timeline_diff_changed_activity",
               "timeline_diff_changed_collection_latency",
               "collection_latency_gap",
               "timeline_diff_collection_latency_limit_exceeded"
             ]
           } = List.first(branch["events"])

    assert Enum.any?(
             branch["candidate_plan"]["strategic_additions"],
             &(get_in(&1, ["repair", "reason"]) ==
                 "collection_latency_downlink_candidate_inserted" and
                 get_in(&1, ["feasibility", "status"]) == "validated_candidate_window" and
                 get_in(&1, ["feasibility", "required_contacts"]) == 1 and
                 get_in(&1, ["feasibility", "planned_contacts"]) == 0 and
                 get_in(&1, ["feasibility", "required_downlink_mb"]) == 45.0 and
                 get_in(&1, ["feasibility", "planned_downlink_mb"]) == 5.0 and
                 get_in(&1, ["feasibility", "source_timeline_id"]) == "timeline:obs_latency")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy ignores on-time changed timeline diff collection latency rows" do
    prior_plan =
      base_plan(%{
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_latency_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:obs_latency_ok",
              "rank" => 1,
              "timeline_id" => "timeline:obs_latency_ok",
              "diff_status" => "changed",
              "changed_fields" => ["actual_delivery_latency_s"],
              "source_activity_id" => "obs_latency_ok_source",
              "replacement_activity_id" => "obs_latency_ok_replacement",
              "source_activity_type" => "observe",
              "replacement_activity_type" => "observe",
              "source_target_id" => "target_a",
              "replacement_target_id" => "target_a",
              "scenario_id" => "leo_1",
              "replacement_activity_context" => %{
                "ground_station_id" => "equator_prime",
                "collection_id" => "collection_alpha",
                "target_delivery_latency_s" => 300.0,
                "actual_delivery_latency_s" => 180.0
              },
              "required_operator_action" => "review_collection_latency"
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

    refute branch(artifact, "derived_timeline_diff_changed_obs_latency_ok_source")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives changed timeline diff contact feedback from operator review rows" do
    prior_plan =
      base_plan(%{
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "timeline_diff_report.v1",
          "review_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_timeline_review_queue"},
          "rows" => [
            %{
              "id" => "operator_review:timeline_diff:contact_review_changed",
              "review_type" => "timeline_diff_review",
              "source" => "timeline_diff_report.rows",
              "subject_id" => "timeline:contact_review_changed",
              "approval_status" => "operator_review_required",
              "source_timeline_diff" => %{
                "id" => "timeline_diff:timeline:contact_review_changed",
                "rank" => 1,
                "timeline_id" => "timeline:contact_review_changed",
                "diff_status" => "changed",
                "changed_fields" => ["contact_result", "contact_success_factor"],
                "source_activity_id" => "contact_review_source",
                "replacement_activity_id" => "contact_review_changed",
                "source_activity_type" => "contact",
                "replacement_activity_type" => "contact",
                "source_direction" => "downlink",
                "replacement_direction" => "downlink",
                "source_ground_station_id" => "equator_prime",
                "replacement_ground_station_id" => "equator_prime",
                "scenario_id" => "leo_1",
                "source_status" => "planned",
                "replacement_activity_context" => %{
                  "starts_at_s" => 300.0,
                  "ends_at_s" => 360.0,
                  "contact_result" => "dropped"
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

    branch = branch(artifact, "derived_timeline_diff_changed_contact_review_source")

    assert %{
             "type" => "contact_success_feedback",
             "ground_station_id" => "equator_prime",
             "source_activity_id" => "contact_review_source",
             "replacement_activity_id" => "contact_review_changed",
             "source_activity_ids" => ["contact_review_changed", "contact_review_source"],
             "feedback_source" => "prior_plan.operator_review_package.rows.source_timeline_diff",
             "feedback_scope" => "timeline_diff",
             "trust_boundary" => "ops_timeline_review_queue",
             "derivation_reasons" => [
               "timeline_diff_changed_activity",
               "timeline_diff_changed_contact"
             ]
           } = List.first(branch["events"])

    assert List.first(branch["events"])["contact_success_factor"] == 0.0
    assert branch["feedback_adjustments"]["contact_success_factor"] == 0.0

    assert Enum.any?(
             branch["risk_indicators"],
             &(&1["type"] == "contact_success_rate_low" and &1["value"] == 0.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives changed timeline diff observation refresh from failed outcome rows" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe("obs_changed_recovery", "leo_1", "target_a", 600.0, 660.0, 12.0)
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
              "id" => "timeline_diff:timeline:obs_changed",
              "rank" => 1,
              "timeline_id" => "timeline:obs_changed",
              "diff_status" => "changed",
              "changed_fields" => ["observation_result", "observation_success_factor"],
              "source_activity_id" => "obs_source",
              "replacement_activity_id" => "obs_changed",
              "source_activity_type" => "observe",
              "replacement_activity_type" => "observe",
              "source_target_id" => "target_a",
              "replacement_target_id" => "target_a",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "replacement_activity_context" => %{
                "starts_at_s" => 600.0,
                "ends_at_s" => 660.0,
                "observation_result" => "accepted, failed",
                "observation_success_factor" => 0.0,
                "realized_status" => "failed"
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

    branch = branch(artifact, "derived_timeline_diff_changed_obs_source")

    assert %{
             "type" => "urgent_target",
             "objective_type" => "target_revisit",
             "target_id" => "target_a",
             "scenario_id" => "leo_1",
             "starts_at_s" => 600.0,
             "ends_at_s" => 660.0,
             "required_observations" => 1,
             "planned_observations" => 0,
             "observation_result" => "accepted, failed",
             "realized_status" => "failed",
             "source_activity_id" => "obs_source",
             "replacement_activity_id" => "obs_changed",
             "source_activity_ids" => ["obs_changed", "obs_source"],
             "timeline_id" => "timeline:obs_changed",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "feedback_key" => "target_a",
             "trust_boundary" => "ops_timeline_review"
           } = List.first(branch["events"])

    assert List.first(branch["events"])["observation_success_factor"] == 0.0

    assert [
             %{
               "type" => "observe",
               "target_id" => "target_a",
               "feasibility" => %{
                 "feedback_source" => "prior_plan.source_timeline_diff_report",
                 "feedback_scope" => "timeline_diff",
                 "trust_boundary" => "ops_timeline_review",
                 "source_event_type" => "urgent_target",
                 "source_activity_id" => "obs_source",
                 "source_activity_ids" => ["obs_changed", "obs_source"],
                 "source_timeline_id" => "timeline:obs_changed",
                 "observation_result" => "accepted, failed",
                 "realized_status" => "failed",
                 "derivation_reasons" => [
                   "timeline_diff_changed_activity",
                   "timeline_diff_changed_observation"
                 ]
               }
             }
           ] = branch["candidate_plan"]["strategic_additions"]

    assert Enum.any?(
             branch["risk_indicators"],
             &(&1["type"] == "urgent_target" and &1["target_id"] == "target_a" and
                 &1["observation_result"] == "accepted, failed" and
                 &1["realized_status"] == "failed" and
                 &1["source_activity_ids"] == ["obs_changed", "obs_source"])
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch-local refresh from changed timeline diff observation quality rows" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe("obs_quality_recovery", "leo_1", "target_a", 600.0, 660.0, 12.0)
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
              "id" => "timeline_diff:timeline:obs_quality",
              "rank" => 1,
              "timeline_id" => "timeline:obs_quality",
              "diff_status" => "changed",
              "changed_fields" => [
                "image_quality_score",
                "image_quality_status",
                "cloud_cover_fraction",
                "blur_score"
              ],
              "source_activity_id" => "obs_quality_source",
              "replacement_activity_id" => "obs_quality_replacement",
              "source_activity_type" => "observe",
              "replacement_activity_type" => "observe",
              "source_target_id" => "target_a",
              "replacement_target_id" => "target_a",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "replacement_activity_context" => %{
                "starts_at_s" => 600.0,
                "ends_at_s" => 660.0,
                "image_quality_score" => 0.4,
                "image_quality_status" => "marginal",
                "image_quality_source" => "provider_imagery_quality",
                "cloud_cover_fraction" => 0.55,
                "blur_score" => 0.15
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

    branch = branch(artifact, "derived_timeline_diff_changed_obs_quality_source")

    assert %{
             "type" => "observation_success_feedback",
             "target_id" => "target_a",
             "scenario_id" => "leo_1",
             "source_starts_at_s" => 600.0,
             "source_ends_at_s" => 660.0,
             "observation_success_factor" => 0.4,
             "image_quality_score" => 0.4,
             "image_quality_status" => "marginal",
             "image_quality_source" => "provider_imagery_quality",
             "cloud_cover_fraction" => 0.55,
             "blur_score" => 0.15,
             "source_activity_id" => "obs_quality_source",
             "replacement_activity_id" => "obs_quality_replacement",
             "source_activity_ids" => ["obs_quality_replacement", "obs_quality_source"],
             "timeline_id" => "timeline:obs_quality",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "feedback_key" => "target_a",
             "trust_boundary" => "ops_timeline_review"
           } = List.first(branch["events"])

    assert Enum.sort(branch["assumptions"]["candidate_source"]["operational_feedback_input_keys"]) ==
             [
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
               "image_quality_score" => 0.4,
               "image_quality_status" => "marginal",
               "image_quality_source" => "provider_imagery_quality",
               "cloud_cover_fraction" => 0.55,
               "blur_score" => 0.15,
               "repair" => %{"reason" => "observation_success_feedback_candidate_inserted"}
             }
           ] = branch["candidate_plan"]["strategic_additions"]

    assert Enum.any?(
             branch["risk_indicators"],
             &(&1["type"] == "observation_success_rate_low" and &1["value"] == 0.4 and
                 &1["target_id"] == "target_a")
           )

    assert_execution_feedback_pressure_score_terms(
      branch,
      artifact,
      "observation_success_rate_low"
    )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch-local refresh from changed timeline diff observation pointing rows" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe("obs_pointing_recovery", "leo_1", "target_a", 600.0, 660.0, 12.0)
        ],
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_pointing_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:obs_pointing",
              "rank" => 1,
              "timeline_id" => "timeline:obs_pointing",
              "diff_status" => "changed",
              "changed_fields" => [
                "pointing_target_match_status",
                "realized_pointing_target_id",
                "pointing_status",
                "attitude_status"
              ],
              "source_activity_id" => "obs_pointing_source",
              "replacement_activity_id" => "obs_pointing_replacement",
              "source_activity_type" => "observe",
              "replacement_activity_type" => "observe",
              "source_target_id" => "target_a",
              "replacement_target_id" => "target_b",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "pointing_target_match_status" => "mismatch",
              "planned_pointing_target_id" => "target_a",
              "realized_pointing_target_id" => "target_b",
              "replacement_activity_context" => %{
                "starts_at_s" => 600.0,
                "ends_at_s" => 660.0,
                "pointing_status" => "off target",
                "pointing_error_deg" => 4.5,
                "pointing_model" => "provider_attitude_solution",
                "pointing_source" => "ops_attitude_telemetry",
                "attitude_status" => "out of tolerance",
                "attitude_error_deg" => 3.2
              },
              "required_operator_action" => "review_pointing_variance"
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

    branch = branch(artifact, "derived_timeline_diff_changed_obs_pointing_source")

    assert %{
             "type" => "observation_success_feedback",
             "target_id" => "target_a",
             "scenario_id" => "leo_1",
             "source_starts_at_s" => 600.0,
             "source_ends_at_s" => 660.0,
             "pointing_target_match_status" => "mismatch",
             "planned_pointing_target_id" => "target_a",
             "realized_pointing_target_id" => "target_b",
             "pointing_status" => "off_target",
             "pointing_error_deg" => 4.5,
             "pointing_model" => "provider_attitude_solution",
             "pointing_source" => "ops_attitude_telemetry",
             "attitude_status" => "out_of_tolerance",
             "attitude_error_deg" => 3.2,
             "source_activity_id" => "obs_pointing_source",
             "replacement_activity_id" => "obs_pointing_replacement",
             "source_activity_ids" => ["obs_pointing_replacement", "obs_pointing_source"],
             "timeline_id" => "timeline:obs_pointing",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "feedback_key" => "target_a",
             "trust_boundary" => "ops_pointing_review",
             "derivation_reasons" => [
               "timeline_diff_changed_activity",
               "timeline_diff_changed_observation_pointing",
               "pointing_target_mismatch",
               "pointing_status_off_target",
               "attitude_status_out_of_tolerance"
             ]
           } = List.first(branch["events"])

    assert List.first(branch["events"])["observation_success_factor"] == 0.0
    assert branch["feedback_adjustments"]["observation_success_factor"] == 0.0

    assert branch["assumptions"]["candidate_source"]["operational_feedback_input_keys"] ==
             ["observation_success_rate"]

    assert [
             %{
               "type" => "observe",
               "target_id" => "target_a",
               "repair" => %{"reason" => "observation_success_feedback_candidate_inserted"}
             }
           ] = branch["candidate_plan"]["strategic_additions"]

    assert Enum.any?(
             branch["risk_indicators"],
             &(&1["type"] == "observation_success_rate_low" and &1["value"] == 0.0 and
                 &1["target_id"] == "target_a" and
                 &1["pointing_target_match_status"] == "mismatch" and
                 &1["pointing_status"] == "off_target" and
                 &1["attitude_status"] == "out_of_tolerance")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch-local refresh from changed timeline diff observation target mismatch rows" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe("obs_target_recovery", "leo_1", "target_a", 600.0, 660.0, 12.0)
        ],
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_target_identity_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:obs_target_identity",
              "rank" => 1,
              "timeline_id" => "timeline:obs_target_identity",
              "diff_status" => "changed",
              "changed_fields" => [
                "target_id",
                "target_match_status",
                "realized_target_id"
              ],
              "source_activity_id" => "obs_target_identity_source",
              "replacement_activity_id" => "obs_target_identity_replacement",
              "source_activity_type" => "observe",
              "replacement_activity_type" => "observe",
              "source_target_id" => "target_a",
              "replacement_target_id" => "target_b",
              "target_match_status" => "mismatch",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "replacement_activity_context" => %{
                "starts_at_s" => 600.0,
                "ends_at_s" => 660.0,
                "observation_result" => "accepted, collected",
                "realized_status" => "completed"
              },
              "required_operator_action" => "review_target_identity_variance"
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

    branch = branch(artifact, "derived_timeline_diff_changed_obs_target_identity_source")

    assert %{
             "type" => "observation_success_feedback",
             "target_id" => "target_a",
             "scenario_id" => "leo_1",
             "source_starts_at_s" => 600.0,
             "source_ends_at_s" => 660.0,
             "target_match_status" => "mismatch",
             "planned_target_id" => "target_a",
             "realized_target_id" => "target_b",
             "observation_result" => "accepted, collected",
             "realized_status" => "completed",
             "source_activity_id" => "obs_target_identity_source",
             "replacement_activity_id" => "obs_target_identity_replacement",
             "source_activity_ids" => [
               "obs_target_identity_replacement",
               "obs_target_identity_source"
             ],
             "timeline_id" => "timeline:obs_target_identity",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "feedback_key" => "target_a",
             "trust_boundary" => "ops_target_identity_review",
             "derivation_reasons" => [
               "timeline_diff_changed_activity",
               "timeline_diff_changed_observation_target_identity",
               "target_mismatch"
             ]
           } = List.first(branch["events"])

    assert List.first(branch["events"])["observation_success_factor"] == 0.0
    assert branch["feedback_adjustments"]["observation_success_factor"] == 0.0

    assert [
             %{
               "type" => "observe",
               "target_id" => "target_a",
               "repair" => %{"reason" => "observation_success_feedback_candidate_inserted"}
             }
           ] = branch["candidate_plan"]["strategic_additions"]

    assert Enum.any?(
             branch["risk_indicators"],
             &(&1["type"] == "observation_success_rate_low" and &1["value"] == 0.0 and
                 &1["target_id"] == "target_a" and &1["target_match_status"] == "mismatch" and
                 &1["planned_target_id"] == "target_a" and &1["realized_target_id"] == "target_b")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch-local refresh from changed timeline diff observation product identity rows" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe("obs_product_recovery", "leo_1", "target_a", 600.0, 660.0, 12.0)
        ],
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_product_identity_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:obs_product_identity",
              "rank" => 1,
              "timeline_id" => "timeline:obs_product_identity",
              "diff_status" => "changed",
              "changed_fields" => [
                "collection_id",
                "product_id",
                "product_ids",
                "payload_id",
                "instrument_id"
              ],
              "source_activity_id" => "obs_product_identity_source",
              "replacement_activity_id" => "obs_product_identity_replacement",
              "source_activity_type" => "observe",
              "replacement_activity_type" => "observe",
              "source_target_id" => "target_a",
              "replacement_target_id" => "target_a",
              "source_collection_id" => "collection_a",
              "replacement_collection_id" => "collection_b",
              "source_product_id" => "product_a",
              "replacement_product_id" => "product_b",
              "source_product_ids" => ["product_a", "product_l0"],
              "replacement_product_ids" => ["product_b", "product_l1"],
              "source_payload_id" => "payload_visible",
              "replacement_payload_id" => "payload_ir",
              "source_instrument_id" => "instrument_nadir",
              "replacement_instrument_id" => "instrument_limb",
              "collection_match_status" => "mismatch",
              "product_match_status" => "mismatch",
              "product_ids_match_status" => "mismatch",
              "payload_match_status" => "mismatch",
              "instrument_match_status" => "mismatch",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "replacement_activity_context" => %{
                "starts_at_s" => 600.0,
                "ends_at_s" => 660.0,
                "observation_result" => "accepted, collected",
                "realized_status" => "completed"
              },
              "required_operator_action" => "review_product_identity_variance"
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

    branch = branch(artifact, "derived_timeline_diff_changed_obs_product_identity_source")
    event = List.first(branch["events"])

    assert %{
             "type" => "observation_success_feedback",
             "target_id" => "target_a",
             "scenario_id" => "leo_1",
             "source_starts_at_s" => 600.0,
             "source_ends_at_s" => 660.0,
             "collection_id" => "collection_b",
             "planned_collection_id" => "collection_a",
             "realized_collection_id" => "collection_b",
             "collection_match_status" => "mismatch",
             "product_id" => "product_b",
             "planned_product_id" => "product_a",
             "realized_product_id" => "product_b",
             "product_match_status" => "mismatch",
             "product_ids" => ["product_b", "product_l1"],
             "planned_product_ids" => ["product_a", "product_l0"],
             "realized_product_ids" => ["product_b", "product_l1"],
             "product_ids_match_status" => "mismatch",
             "payload_id" => "payload_ir",
             "planned_payload_id" => "payload_visible",
             "realized_payload_id" => "payload_ir",
             "payload_match_status" => "mismatch",
             "instrument_id" => "instrument_limb",
             "planned_instrument_id" => "instrument_nadir",
             "realized_instrument_id" => "instrument_limb",
             "instrument_match_status" => "mismatch",
             "observation_identity_mismatch_fields" => [
               "collection",
               "product",
               "product_ids",
               "payload",
               "instrument"
             ],
             "observation_result" => "accepted, collected",
             "realized_status" => "completed",
             "source_activity_id" => "obs_product_identity_source",
             "replacement_activity_id" => "obs_product_identity_replacement",
             "source_activity_ids" => [
               "obs_product_identity_replacement",
               "obs_product_identity_source"
             ],
             "timeline_id" => "timeline:obs_product_identity",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "feedback_key" => "target_a",
             "trust_boundary" => "ops_product_identity_review",
             "derivation_reasons" => [
               "timeline_diff_changed_activity",
               "timeline_diff_changed_observation_product_identity",
               "collection_mismatch",
               "product_mismatch",
               "product_ids_mismatch",
               "payload_mismatch",
               "instrument_mismatch"
             ]
           } = event

    assert event["observation_success_factor"] == 0.0
    assert branch["feedback_adjustments"]["observation_success_factor"] == 0.0

    assert [
             %{
               "type" => "observe",
               "target_id" => "target_a",
               "repair" => %{"reason" => "observation_success_feedback_candidate_inserted"}
             }
           ] = branch["candidate_plan"]["strategic_additions"]

    assert Enum.any?(
             branch["risk_indicators"],
             &(&1["type"] == "observation_success_rate_low" and &1["value"] == 0.0 and
                 &1["target_id"] == "target_a" and
                 &1["observation_identity_mismatch_fields"] == [
                   "collection",
                   "product",
                   "product_ids",
                   "payload",
                   "instrument"
                 ])
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy ignores healthy changed timeline diff observation pointing rows" do
    prior_plan =
      base_plan(%{
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_pointing_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:obs_pointing_nominal",
              "rank" => 1,
              "timeline_id" => "timeline:obs_pointing_nominal",
              "diff_status" => "changed",
              "changed_fields" => ["pointing_status", "attitude_status"],
              "source_activity_id" => "obs_pointing_nominal_source",
              "replacement_activity_id" => "obs_pointing_nominal_replacement",
              "source_activity_type" => "observe",
              "replacement_activity_type" => "observe",
              "source_target_id" => "target_a",
              "replacement_target_id" => "target_a",
              "scenario_id" => "leo_1",
              "pointing_target_match_status" => "matched",
              "attitude_target_match_status" => "matched",
              "replacement_activity_context" => %{
                "pointing_status" => "within tolerance",
                "attitude_status" => "within tolerance",
                "pointing_error_deg" => 0.2,
                "attitude_error_deg" => 0.1
              },
              "required_operator_action" => "review_pointing_variance"
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

    refute branch(artifact, "derived_timeline_diff_changed_obs_pointing_nominal_source")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch-local refresh from changed timeline diff observation lighting rows" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe("obs_lighting_recovery", "leo_1", "target_a", 600.0, 660.0, 12.0)
        ],
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_lighting_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:obs_lighting",
              "rank" => 1,
              "timeline_id" => "timeline:obs_lighting",
              "diff_status" => "changed",
              "changed_fields" => [
                "lighting_condition",
                "eclipse_overlap_fraction",
                "eclipse_overlap_s"
              ],
              "source_activity_id" => "obs_lighting_source",
              "replacement_activity_id" => "obs_lighting_replacement",
              "source_activity_type" => "observe",
              "replacement_activity_type" => "observe",
              "source_target_id" => "target_a",
              "replacement_target_id" => "target_a",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "lighting_condition_match_status" => "mismatch",
              "planned_lighting_condition" => "sunlit",
              "replacement_activity_context" => %{
                "starts_at_s" => 600.0,
                "ends_at_s" => 660.0,
                "lighting_condition" => "penumbra",
                "lighting_condition_detail" => "mixed lighting",
                "lighting_condition_model" => "provider_lighting_replay",
                "lighting_detail_model" => "provider_overlap_fraction",
                "lighting_confidence" => "bounded_by_sampled_eclipse_overlap",
                "eclipse_overlap_fraction" => 0.35,
                "eclipse_overlap_s" => 21.0
              },
              "required_operator_action" => "review_lighting_variance"
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

    branch = branch(artifact, "derived_timeline_diff_changed_obs_lighting_source")

    assert %{
             "type" => "observation_success_feedback",
             "target_id" => "target_a",
             "scenario_id" => "leo_1",
             "source_starts_at_s" => 600.0,
             "source_ends_at_s" => 660.0,
             "observation_success_factor" => 0.65,
             "lighting_condition_match_status" => "mismatch",
             "planned_lighting_condition" => "sunlit",
             "realized_lighting_condition" => "penumbra",
             "lighting_condition_detail" => "mixed_lighting",
             "lighting_condition_model" => "provider_lighting_replay",
             "lighting_detail_model" => "provider_overlap_fraction",
             "lighting_confidence" => "bounded_by_sampled_eclipse_overlap",
             "eclipse_overlap_fraction" => 0.35,
             "eclipse_overlap_s" => 21.0,
             "source_activity_id" => "obs_lighting_source",
             "replacement_activity_id" => "obs_lighting_replacement",
             "source_activity_ids" => ["obs_lighting_replacement", "obs_lighting_source"],
             "timeline_id" => "timeline:obs_lighting",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "feedback_key" => "target_a",
             "trust_boundary" => "ops_lighting_review",
             "derivation_reasons" => [
               "timeline_diff_changed_activity",
               "timeline_diff_changed_observation_lighting",
               "lighting_condition_mismatch",
               "eclipse_overlap_fraction_positive",
               "eclipse_overlap_duration_positive",
               "lighting_condition_penumbra",
               "lighting_detail_mixed_lighting"
             ]
           } = List.first(branch["events"])

    assert branch["feedback_adjustments"]["observation_success_factor"] == 0.65

    assert branch["assumptions"]["candidate_source"]["operational_feedback_input_keys"] ==
             ["observation_success_rate"]

    assert [
             %{
               "type" => "observe",
               "target_id" => "target_a",
               "repair" => %{"reason" => "observation_success_feedback_candidate_inserted"}
             }
           ] = branch["candidate_plan"]["strategic_additions"]

    assert Enum.any?(
             branch["risk_indicators"],
             &(&1["type"] == "observation_success_rate_low" and &1["value"] == 0.65 and
                 &1["target_id"] == "target_a" and
                 &1["lighting_condition_match_status"] == "mismatch" and
                 &1["realized_lighting_condition"] == "penumbra" and
                 &1["eclipse_overlap_fraction"] == 0.35)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy ignores healthy changed timeline diff observation lighting rows" do
    prior_plan =
      base_plan(%{
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_lighting_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:obs_lighting_nominal",
              "rank" => 1,
              "timeline_id" => "timeline:obs_lighting_nominal",
              "diff_status" => "changed",
              "changed_fields" => ["lighting_condition", "eclipse_overlap_fraction"],
              "source_activity_id" => "obs_lighting_nominal_source",
              "replacement_activity_id" => "obs_lighting_nominal_replacement",
              "source_activity_type" => "observe",
              "replacement_activity_type" => "observe",
              "source_target_id" => "target_a",
              "replacement_target_id" => "target_a",
              "scenario_id" => "leo_1",
              "lighting_condition_match_status" => "matched",
              "planned_lighting_condition" => "sunlit",
              "replacement_activity_context" => %{
                "lighting_condition" => "sunlit",
                "lighting_condition_detail" => "sunlit",
                "eclipse_overlap_fraction" => 0.0,
                "eclipse_overlap_s" => 0.0
              },
              "required_operator_action" => "review_lighting_variance"
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

    refute branch(artifact, "derived_timeline_diff_changed_obs_lighting_nominal_source")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch-local refresh from changed timeline diff target priority rows" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe("obs_priority_recovery", "leo_1", "target_a", 600.0, 660.0, 12.0)
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
              "id" => "timeline_diff:timeline:obs_priority",
              "rank" => 1,
              "timeline_id" => "timeline:obs_priority",
              "diff_status" => "changed",
              "changed_fields" => ["target_priority", "target_geometry"],
              "source_activity_id" => "obs_priority_source",
              "replacement_activity_id" => "obs_priority_replacement",
              "source_activity_type" => "observe",
              "replacement_activity_type" => "observe",
              "source_target_id" => "target_a",
              "replacement_target_id" => "target_a",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "replacement_activity_context" => %{
                "starts_at_s" => 600.0,
                "ends_at_s" => 660.0,
                "target_priority" => 12.0,
                "target_priority_source" => "timeline_diff_target_priority",
                "target_priority_objective_ids" => ["objective:priority_target_a"],
                "target_priority_objective_type" => "priority_commitment",
                "target" => %{
                  "latitude_deg" => 22.0,
                  "longitude_deg" => 44.0,
                  "minimum_elevation_deg" => 18.0
                }
              },
              "required_operator_action" => "review_target_priority"
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

    branch = branch(artifact, "derived_timeline_diff_changed_obs_priority_source")

    assert %{
             "type" => "target_priority_feedback",
             "target_id" => "target_a",
             "scenario_id" => "leo_1",
             "priority" => 12.0,
             "latitude_deg" => 22.0,
             "longitude_deg" => 44.0,
             "minimum_elevation_deg" => 18.0,
             "target_priority_source" => "timeline_diff_target_priority",
             "target_priority_objective_ids" => ["objective:priority_target_a"],
             "target_priority_objective_type" => "priority_commitment",
             "source_activity_id" => "obs_priority_source",
             "replacement_activity_id" => "obs_priority_replacement",
             "source_activity_ids" => ["obs_priority_replacement", "obs_priority_source"],
             "timeline_id" => "timeline:obs_priority",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "feedback_key" => "target_a",
             "trust_boundary" => "ops_timeline_review",
             "derivation_reasons" => [
               "timeline_diff_changed_activity",
               "timeline_diff_changed_target_priority"
             ]
           } = List.first(branch["events"])

    assert ["target_priority_overrides"] ==
             branch["assumptions"]["candidate_source"]["operational_feedback_input_keys"]

    assert [
             %{
               "type" => "observe",
               "target_id" => "target_a",
               "repair" => %{"reason" => "target_priority_feedback_candidate_inserted"},
               "metadata" => %{"priority" => 12.0}
             }
           ] = branch["candidate_plan"]["strategic_additions"]

    assert Enum.any?(
             branch["risk_indicators"],
             &(&1["type"] == "target_priority_feedback_high" and &1["target_id"] == "target_a" and
                 &1["value"] == 12.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy ignores low-priority changed timeline diff target priority rows" do
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
              "id" => "timeline_diff:timeline:obs_priority_low",
              "rank" => 1,
              "timeline_id" => "timeline:obs_priority_low",
              "diff_status" => "changed",
              "changed_fields" => ["target_priority"],
              "source_activity_id" => "obs_priority_low_source",
              "replacement_activity_id" => "obs_priority_low_replacement",
              "source_activity_type" => "observe",
              "replacement_activity_type" => "observe",
              "source_target_id" => "target_a",
              "replacement_target_id" => "target_a",
              "scenario_id" => "leo_1",
              "replacement_activity_context" => %{"target_priority" => 4.0},
              "required_operator_action" => "review_target_priority"
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

    refute branch(artifact, "derived_timeline_diff_changed_obs_priority_low_source")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy ignores successful changed timeline diff observation rows" do
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
              "id" => "timeline_diff:timeline:obs_success",
              "rank" => 1,
              "timeline_id" => "timeline:obs_success",
              "diff_status" => "changed",
              "changed_fields" => ["observation_result"],
              "source_activity_id" => "obs_success_source",
              "replacement_activity_id" => "obs_success",
              "source_activity_type" => "observe",
              "replacement_activity_type" => "observe",
              "source_target_id" => "target_a",
              "replacement_target_id" => "target_a",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "replacement_activity_context" => %{"observation_result" => "accepted, completed"},
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

    refute branch(artifact, "derived_timeline_diff_changed_obs_success_source")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives changed timeline diff observation refresh from operator review rows" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe("obs_review_changed_recovery", "leo_1", "target_a", 600.0, 660.0, 12.0)
        ],
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "timeline_diff_report.v1",
          "review_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_timeline_review_queue"},
          "rows" => [
            %{
              "id" => "operator_review:timeline_diff:obs_review_changed",
              "review_type" => "timeline_diff_review",
              "source" => "timeline_diff_report.rows",
              "subject_id" => "timeline:obs_review_changed",
              "approval_status" => "operator_review_required",
              "source_timeline_diff" => %{
                "id" => "timeline_diff:timeline:obs_review_changed",
                "rank" => 1,
                "timeline_id" => "timeline:obs_review_changed",
                "diff_status" => "changed",
                "changed_fields" => ["observation_result", "observation_success_factor"],
                "source_activity_id" => "obs_review_source",
                "replacement_activity_id" => "obs_review_changed",
                "source_activity_type" => "observe",
                "replacement_activity_type" => "observe",
                "source_target_id" => "target_a",
                "replacement_target_id" => "target_a",
                "scenario_id" => "leo_1",
                "source_status" => "planned",
                "replacement_activity_context" => %{
                  "starts_at_s" => 600.0,
                  "ends_at_s" => 660.0,
                  "observation_result" => "failed"
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

    branch = branch(artifact, "derived_timeline_diff_changed_obs_review_source")

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_a",
             "source_activity_id" => "obs_review_source",
             "replacement_activity_id" => "obs_review_changed",
             "source_activity_ids" => ["obs_review_changed", "obs_review_source"],
             "feedback_source" => "prior_plan.operator_review_package.rows.source_timeline_diff",
             "feedback_scope" => "timeline_diff",
             "trust_boundary" => "ops_timeline_review_queue"
           } = List.first(branch["events"])

    assert List.first(branch["events"])["observation_success_factor"] == 0.0

    assert [
             %{
               "type" => "observe",
               "target_id" => "target_a",
               "feasibility" => %{
                 "feedback_source" =>
                   "prior_plan.operator_review_package.rows.source_timeline_diff",
                 "feedback_scope" => "timeline_diff",
                 "trust_boundary" => "ops_timeline_review_queue",
                 "source_event_type" => "urgent_target",
                 "source_activity_id" => "obs_review_source",
                 "source_activity_ids" => ["obs_review_changed", "obs_review_source"],
                 "source_timeline_id" => "timeline:obs_review_changed",
                 "derivation_reasons" => [
                   "timeline_diff_changed_activity",
                   "timeline_diff_changed_observation"
                 ]
               }
             }
           ] = branch["candidate_plan"]["strategic_additions"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp assert_execution_feedback_pressure_score_terms(branch, artifact, risk_types) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])
    expected_risk_types = List.wrap(risk_types)

    execution_feedback_risk_types =
      ~w(contact_success_rate_low observation_success_rate_low station_throughput_factor_low command_success_rate_low maneuver_success_rate_low maneuver_execution_uncertainty_high maneuver_execution_uncertainty_missing)

    Enum.each(expected_risk_types, fn risk_type ->
      assert Enum.any?(branch["risk_indicators"], &(&1["type"] == risk_type))
    end)

    execution_feedback_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] in execution_feedback_risk_types)
      )

    assert execution_feedback_pressure_count > 0

    assert branch["score_terms"]["execution_feedback_pressure_penalty"] ==
             -execution_feedback_pressure_count * risk_weight

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - execution_feedback_pressure_count) *
               risk_weight

    assert "execution_feedback_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "execution_feedback_pressure_penalty" and
                 &1["value"] < 0.0)
           )
  end
end
