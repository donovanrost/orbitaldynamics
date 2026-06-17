defmodule OrbitalDynamics.CandidateRefresh.RealizedActivityFeedbackBuildTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CadenceImport,
    CandidateRefresh,
    Epoch,
    OperatorReview,
    ResultSet,
    Schema
  }

  test "derives refresh feedback from provider-shaped realized activities" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("prior_candidate_activities", [
            %{
              "id" => "prior_observe_target_a",
              "type" => "observe",
              "scenario_id" => "leo_1",
              "target_id" => "target_a",
              "starts_at_s" => 10.0,
              "ends_at_s" => 20.0
            },
            %{
              "id" => "prior_observe_target_b",
              "type" => "observe",
              "scenario_id" => "leo_1",
              "target_id" => "target_b",
              "starts_at_s" => 30.0,
              "ends_at_s" => 40.0
            },
            %{
              "id" => "prior_observe_target_a_zero_confidence",
              "type" => "observe",
              "scenario_id" => "leo_1",
              "target_id" => "target_a",
              "starts_at_s" => 50.0,
              "ends_at_s" => 60.0
            },
            %{
              "id" => "prior_downlink_equator_prime",
              "type" => "downlink",
              "scenario_id" => "leo_1",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 300.0,
              "ends_at_s" => 420.0,
              "required_downlink_mb" => 360.0
            },
            %{
              "id" => "prior_command_health",
              "type" => "command",
              "scenario_id" => "leo_1",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 500.0,
              "ends_at_s" => 520.0
            },
            %{
              "id" => "prior_burn_cleanup",
              "type" => "impulsive_burn",
              "scenario_id" => "leo_1",
              "starts_at_s" => 600.0,
              "ends_at_s" => 600.0,
              "duration_s" => 0.0,
              "delta_v_km_s" => [0.0, 0.001, 0.0]
            }
          ])
          |> put_in(["operational_feedback"], %{
            "trust_boundary" => "cadence_operational_feedback",
            "realized_activities" => [
              %{
                "id" => "realized_observe_target_a",
                "planned_activity_id" => "prior_observe_target_a",
                "type" => "observe",
                "status" => "completed",
                "target" => %{"id" => "target_a"},
                "target_priority" => 6.0,
                "feedback_weight" => 2.0,
                "feedback_weight_source" => "provider_confidence",
                "source_quality" => "operator_verified",
                "trust_boundary" => "operator_supplied_feedback"
              },
              %{
                "id" => "realized_observe_target_a_zero_confidence",
                "planned_activity_id" => "prior_observe_target_a_zero_confidence",
                "type" => "observe",
                "status" => "completed",
                "target" => %{"id" => "target_a"},
                "target_priority" => 100.0,
                "feedback_weight" => 0.0,
                "feedback_weight_source" => "zero_confidence_provider"
              },
              %{
                "id" => "realized_downlink_equator_prime",
                "planned_activity_id" => "prior_downlink_equator_prime",
                "type" => "downlink",
                "status" => "partial",
                "station" => %{"id" => "equator_prime"},
                "actual_throughput_mb" => 120.0
              },
              %{
                "id" => "realized_burn_cleanup",
                "planned_activity_id" => "prior_burn_cleanup",
                "type" => "impulsive_burn",
                "status" => "completed",
                "maneuver_success_factor" => 0.75,
                "execution_uncertainty" => %{
                  "timing_3sigma_s" => 8.0,
                  "delta_v_3sigma_km_s" => [0.0, 0.0001, 0.0],
                  "source" => "provider_covariance"
                }
              }
            ]
          }),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert get_in(artifact, ["operational_feedback", "target_priority_overrides"]) == %{
             "target_a" => 6.0
           }

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{
             "equator_prime" => 240.0
           }

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 1 / 3
           }

    assert get_in(artifact, ["operational_feedback", "maneuver_success_rate"]) == %{
             "prior_burn_cleanup" => 0.75
           }

    assert get_in(artifact, [
             "operational_feedback",
             "maneuver_execution_uncertainty",
             "prior_burn_cleanup"
           ]) == %{
             "execution_uncertainty_status" => "declared",
             "timing_3sigma_s" => 8.0,
             "delta_v_3sigma_km_s" => [0.0, 0.0001, 0.0],
             "delta_v_3sigma_magnitude_km_s" => 0.0001,
             "execution_uncertainty" => %{
               "timing_3sigma_s" => 8.0,
               "delta_v_3sigma_km_s" => [0.0, 0.0001, 0.0],
               "source" => "provider_covariance"
             },
             "execution_uncertainty_source" => "provider_covariance"
           }

    observe = Enum.find(artifact["candidate_activities"], &(&1["type"] == "observe"))
    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))

    assert observe["target_priority"] == 6.0
    assert observe["target_priority_source"] == "operational_feedback.target_priority_overrides"
    assert downlink["required_downlink_mb"] == 240.0
    assert downlink["throughput_model"]["station_throughput_factor"] == 1 / 3

    assert get_in(artifact, ["provenance", "operational_feedback", "input_keys"]) == [
             "contact_success_rate",
             "downlink_demand_mb",
             "downlink_demand_sources",
             "maneuver_execution_uncertainty",
             "maneuver_success_rate",
             "observation_success_rate",
             "realized_activities",
             "station_throughput_factor",
             "target_priority_overrides"
           ]

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "derived_from_realized_activities"
           ])

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_realized_activity_count"
           ]) ==
             4

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_weighted_feedback_row_count"
           ]) == 1

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "feedback_weight_sources"
           ]) == ["provider_confidence"]

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_realized_source_quality_counts"
           ]) == %{"operator_verified" => 1}

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_timeline_feedback_report_contract"
           ]) == "timeline_feedback_report.v1"

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_timeline_feedback_report_count"
           ]) == 1

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_timeline_feedback_report_row_count"
           ]) == 6

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_timeline_feedback_input_keys"
           ]) == [
             "contact_success_rate",
             "downlink_demand_mb",
             "downlink_demand_sources",
             "maneuver_execution_uncertainty",
             "maneuver_success_rate",
             "observation_success_rate",
             "station_throughput_factor",
             "target_priority_overrides"
           ]

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_timeline_feedback_trust_boundary_status"
           ]) == "declared"

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_timeline_feedback_trust_boundaries"
           ]) == ["operator_supplied_feedback"]

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "feedback_trust_boundaries",
             "target_priority_overrides",
             "target_a"
           ]) == ["operator_supplied_feedback"]

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_report_status_counts"
           ]) == %{"matched" => 4, "planned_only" => 2}

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_feedback_kind_counts"
           ]) == %{"command" => 1, "contact" => 1, "maneuver" => 1, "observation" => 3}

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_match_strategy_counts"
           ]) == %{"planned_activity_id" => 4, "unmatched_planned" => 2}

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_cadence_import_status_counts"
           ]) == %{"missing" => 2, "not_applicable" => 4}

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_planned_protection_decision_counts"
           ]) == %{"mutable" => 2, "preserve" => 4}

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_execution_uncertainty_declared_count"
           ]) == 1

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_execution_uncertainty_missing_count"
           ]) == 0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "derives refresh feedback from standalone realized source rows" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("prior_candidate_activities", [
            %{
              "id" => "prior_downlink_equator_prime",
              "type" => "downlink",
              "scenario_id" => "leo_1",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 300.0,
              "ends_at_s" => 420.0,
              "required_downlink_mb" => 360.0,
              "estimated_throughput_mb" => 120.0
            },
            %{
              "id" => "prior_observe_target_a",
              "type" => "observe",
              "scenario_id" => "leo_1",
              "target_id" => "target_a",
              "starts_at_s" => 500.0,
              "ends_at_s" => 560.0,
              "estimated_data_volume_mb" => 90.0
            },
            %{
              "id" => "prior_command_health",
              "type" => "command",
              "scenario_id" => "leo_1",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 700.0,
              "ends_at_s" => 730.0
            }
          ])
          |> Map.put("mission_state", %{
            "source_realized_activity" => %{
              "schema_contract" => "realized_activity.v1",
              "id" => "realized:prior_downlink_equator_prime",
              "planned_activity_id" => "prior_downlink_equator_prime",
              "type" => "downlink",
              "status" => "partial",
              "ground_station_id" => "equator_prime",
              "direction" => "downlink",
              "completed_fraction" => 0.25,
              "actual_throughput_mb" => 30.0,
              "estimated_throughput_mb" => 120.0,
              "feedback_weight" => 2.0,
              "feedback_weight_source" => "live_samples",
              "trust_boundary" => "cadence_live_realized_feedback"
            },
            "source_realized_state_snapshot" => %{
              "schema_contract" => "realized_state_snapshot.v1",
              "snapshot_id" => "snapshot:ops",
              "provenance" => %{"trust_boundary" => "cadence_realized_snapshot"},
              "activities" => [
                %{
                  "schema_contract" => "realized_activity.v1",
                  "id" => "realized:prior_observe_target_a",
                  "planned_activity_id" => "prior_observe_target_a",
                  "type" => "observe",
                  "status" => "partial",
                  "target_id" => "target_a",
                  "completed_fraction" => 0.6,
                  "image_quality_score" => 0.6,
                  "image_quality_status" => "usable",
                  "image_quality_source" => "ops_quality"
                }
              ]
            },
            "source_result_artifact" => %{
              "schema_contract" => "result_artifact.v1",
              "study_id" => "realized_wrapper",
              "metadata" => %{"trust_boundary" => "wrapped_realized_feedback"},
              "source_realized_activity" => %{
                "schema_contract" => "realized_activity.v1",
                "id" => "realized:prior_command_health",
                "planned_activity_id" => "prior_command_health",
                "type" => "command",
                "status" => "failed",
                "command_success_factor" => 0.4,
                "command_result" => "failed"
              }
            }
          }),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 0.25
           }

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 0.25
           }

    assert get_in(artifact, ["operational_feedback", "observation_success_rate"]) == %{
             "target_a" => 0.6
           }

    assert get_in(artifact, ["operational_feedback", "image_quality_score"]) == %{
             "target_a" => 0.6
           }

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "prior_command_health" => 0.4
           }

    provenance = get_in(artifact, ["provenance", "operational_feedback"])

    assert provenance["derived_from_source_realized_activities"]
    assert provenance["source_realized_activity_count"] == 3

    assert provenance["source_realized_activity_paths"] == [
             "mission_state.source_realized_activity",
             "mission_state.source_realized_state_snapshot.activities",
             "mission_state.source_result_artifact.source_realized_activity"
           ]

    assert provenance["source_realized_activity_type_counts"] == %{
             "command" => 1,
             "downlink" => 1,
             "observe" => 1
           }

    assert provenance["source_realized_status_counts"] == %{
             "failed" => 1,
             "partial" => 2
           }

    assert provenance["source_realized_trust_boundary_status"] == "declared"

    assert provenance["source_realized_trust_boundaries"] == [
             "cadence_live_realized_feedback",
             "cadence_realized_snapshot",
             "wrapped_realized_feedback"
           ]

    assert provenance["source_weighted_feedback_row_count"] == 1
    assert provenance["feedback_weight_sources"] == ["live_samples"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "derives refresh feedback from review and import realized feedback rows" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("prior_candidate_activities", [
            %{
              "id" => "dl_review_feedback",
              "type" => "downlink",
              "scenario_id" => "leo_1",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 100.0,
              "ends_at_s" => 160.0,
              "estimated_throughput_mb" => 100.0,
              "required_downlink_mb" => 100.0
            },
            %{
              "id" => "obs_import_feedback",
              "type" => "observe",
              "scenario_id" => "leo_1",
              "target_id" => "target_a",
              "starts_at_s" => 200.0,
              "ends_at_s" => 260.0,
              "estimated_data_volume_mb" => 80.0
            },
            %{
              "id" => "cmd_import_feedback",
              "type" => "command",
              "scenario_id" => "leo_1",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 300.0,
              "ends_at_s" => 330.0
            }
          ])
          |> Map.put("operator_review_package", %{
            "schema_contract" => "operator_review_package.v1",
            "source_artifact_type" => "timeline_feedback_report.v1",
            "provenance" => %{"trust_boundary" => "ops_review_queue"},
            "rows" => [
              %{
                "id" => "operator_review:realized_feedback:dl_review_feedback",
                "review_type" => "realized_feedback",
                "activity_id" => "dl_review_feedback",
                "activity_type" => "downlink",
                "feedback_status" => "matched",
                "realized_status" => "completed",
                "confidence_weight" => "2.0",
                "confidence_weight_source" => "ops_sample_count",
                "source_feedback" => %{
                  "activity_id" => "dl_review_feedback",
                  "status" => "matched",
                  "realized_status" => "completed",
                  "planned_type" => "downlink",
                  "ground_station_id" => "equator_prime",
                  "contact_success_factor" => 0.2,
                  "actual_throughput_mb" => 20.0,
                  "estimated_throughput_mb" => 100.0,
                  "required_downlink_mb" => 100.0
                }
              }
            ]
          })
          |> Map.put("cadence_import_manifest", %{
            "schema_contract" => "cadence_import_manifest.v1",
            "source_artifact_type" => "operator_review_package.v1",
            "provenance" => %{"trust_boundary" => "cadence_review_queue"},
            "rows" => [
              %{
                "id" => "cadence_import:realized_feedback:obs_import_feedback",
                "source_review_type" => "realized_feedback",
                "required_operator_action" => "review_realized_feedback",
                "source_review_row" => %{
                  "id" => "operator_review:realized_feedback:obs_import_feedback",
                  "review_type" => "realized_feedback",
                  "activity_id" => "obs_import_feedback",
                  "activity_type" => "observe",
                  "feedback_status" => "matched",
                  "realized_status" => "completed",
                  "source_feedback" => %{
                    "activity_id" => "obs_import_feedback",
                    "status" => "matched",
                    "realized_status" => "completed",
                    "planned_type" => "observe",
                    "target_id" => "target_a",
                    "observation_success_factor" => 0.4,
                    "image_quality_score" => 0.4,
                    "image_quality_status" => "marginal",
                    "image_quality_source" => "cadence_imagery_review"
                  }
                }
              },
              %{
                "id" => "cadence_import:realized_feedback:cmd_import_feedback",
                "source_review_type" => "realized_feedback",
                "source_review_action" => "review_realized_feedback",
                "activity_id" => "cmd_import_feedback",
                "activity_type" => "command",
                "feedback_status" => "matched",
                "realized_status" => "failed",
                "command_success_factor" => 0.3,
                "command_result" => "failed"
              }
            ]
          }),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 0.2
           }

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 0.2
           }

    assert get_in(artifact, ["operational_feedback", "observation_success_rate"]) == %{
             "target_a" => 0.4
           }

    assert get_in(artifact, ["operational_feedback", "image_quality_score"]) == %{
             "target_a" => 0.4
           }

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_import_feedback" => 0.3
           }

    provenance = get_in(artifact, ["provenance", "operational_feedback"])

    assert provenance["source_realized_activity_count"] == 3

    assert provenance["source_realized_activity_paths"] == [
             "cadence_import_manifest.rows.source_feedback",
             "cadence_import_manifest.rows.source_review_row.source_feedback",
             "operator_review_package.rows.source_feedback"
           ]

    assert provenance["source_realized_activity_type_counts"] == %{
             "command" => 1,
             "downlink" => 1,
             "observe" => 1
           }

    assert provenance["source_realized_trust_boundaries"] == [
             "cadence_review_queue",
             "ops_review_queue"
           ]

    assert provenance["source_weighted_feedback_row_count"] == 1
    assert provenance["feedback_weight_sources"] == ["ops_sample_count"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "preserves invalid provider-shaped realized activity feedback scalars without clamping" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("prior_candidate_activities", [
            %{
              "id" => "prior_observe_target_a",
              "type" => "observe",
              "scenario_id" => "leo_1",
              "target_id" => "target_a",
              "starts_at_s" => 10.0,
              "ends_at_s" => 20.0,
              "estimated_data_volume_mb" => 80.0
            },
            %{
              "id" => "prior_downlink_equator_prime",
              "type" => "downlink",
              "scenario_id" => "leo_1",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 300.0,
              "ends_at_s" => 420.0,
              "required_downlink_mb" => 360.0
            },
            %{
              "id" => "prior_command_health",
              "type" => "command",
              "scenario_id" => "leo_1",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 500.0,
              "ends_at_s" => 520.0
            }
          ])
          |> put_in(["operational_feedback"], %{
            "trust_boundary" => "cadence_operational_feedback",
            "realized_activities" => [
              %{
                "id" => "realized_observe_target_a",
                "planned_activity_id" => "prior_observe_target_a",
                "type" => "observe",
                "status" => "partial",
                "target" => %{"id" => "target_a"},
                "completed_fraction" => -0.2,
                "image_quality_score" => 1.5,
                "quality" => %{"cloud_cover_fraction" => -0.25},
                "metadata" => %{"blur_score" => "bad-blur"}
              },
              %{
                "id" => "realized_downlink_equator_prime",
                "planned_activity_id" => "prior_downlink_equator_prime",
                "type" => "downlink",
                "status" => "partial",
                "station" => %{"id" => "equator_prime"},
                "completed_fraction" => 1.4
              },
              %{
                "id" => "realized_command_health",
                "planned_activity_id" => "prior_command_health",
                "type" => "command",
                "status" => "completed",
                "command_success_factor" => 0.7,
                "feedback_weight" => -3.0,
                "feedback_weight_source" => "provider_confidence"
              }
            ]
          }),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert "operational feedback input is invalid" in artifact["warnings"]

    assert get_in(artifact, ["operational_feedback", "observation_success_rate"]) == %{
             "target_a" => 0.5
           }

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 0.5
           }

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{
             "equator_prime" => 360.0
           }

    refute Map.has_key?(artifact["operational_feedback"], "command_success_rate")
    refute Map.has_key?(artifact["operational_feedback"], "image_quality_score")
    refute Map.has_key?(artifact["operational_feedback"], "cloud_cover_fraction")
    refute Map.has_key?(artifact["operational_feedback"], "blur_score")

    observe = Enum.find(artifact["candidate_activities"], &(&1["type"] == "observe"))
    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))

    assert observe["observation_success_factor"] == 0.5
    refute Map.has_key?(observe, "image_quality_score")
    refute Map.has_key?(observe, "cloud_cover_fraction")
    refute Map.has_key?(observe, "blur_score")

    assert downlink["contact_success_factor"] == 0.5
    assert downlink["required_downlink_mb"] == 360.0

    assert %{
             "derived_from_realized_activities" => true,
             "source_realized_activity_count" => 3,
             "invalid_operational_feedback_input" => true,
             "invalid_operational_feedback_input_reason" =>
               "operational_feedback_sections_invalid",
             "invalid_operational_feedback_sections" => invalid_sections,
             "source_operational_feedback" => %{
               "invalid_feedback_sections" => invalid_sections
             }
           } = get_in(artifact, ["provenance", "operational_feedback"])

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_realized_activity_count"
           ]) == 3

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_operational_feedback_excluded_count"
           ]) == 1

    assert %{
             "field" => "realized_activities.completed_fraction",
             "reason" => "entry_must_be_unit_interval_number",
             "invalid_feedback_shape" => -0.2,
             "row_id" => "realized_observe_target_a",
             "row_index" => 1
           } in invalid_sections

    assert %{
             "field" => "realized_activities.image_quality_score",
             "reason" => "entry_must_be_unit_interval_number",
             "invalid_feedback_shape" => 1.5,
             "row_id" => "realized_observe_target_a",
             "row_index" => 1
           } in invalid_sections

    assert %{
             "field" => "realized_activities.quality.cloud_cover_fraction",
             "reason" => "entry_must_be_unit_interval_number",
             "invalid_feedback_shape" => -0.25,
             "row_id" => "realized_observe_target_a",
             "row_index" => 1
           } in invalid_sections

    assert %{
             "field" => "realized_activities.metadata.blur_score",
             "reason" => "entry_must_be_unit_interval_number",
             "invalid_feedback_shape" => "bad-blur",
             "row_id" => "realized_observe_target_a",
             "row_index" => 1
           } in invalid_sections

    assert %{
             "field" => "realized_activities.completed_fraction",
             "reason" => "entry_must_be_unit_interval_number",
             "invalid_feedback_shape" => 1.4,
             "row_id" => "realized_downlink_equator_prime",
             "row_index" => 2
           } in invalid_sections

    assert %{
             "field" => "realized_activities.feedback_weight",
             "reason" => "entry_must_be_nonnegative_number",
             "invalid_feedback_shape" => -3.0,
             "row_id" => "realized_command_health",
             "row_index" => 3
           } in invalid_sections

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "preserves malformed provider-shaped realized activity feedback identities" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("prior_candidate_activities", [
            %{
              "id" => "prior_observe_target_a",
              "type" => "observe",
              "scenario_id" => "leo_1",
              "target_id" => "target_a",
              "starts_at_s" => 10.0,
              "ends_at_s" => 20.0
            },
            %{
              "id" => "prior_downlink_equator_prime",
              "type" => "downlink",
              "scenario_id" => "leo_1",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 300.0,
              "ends_at_s" => 420.0,
              "required_downlink_mb" => 360.0
            }
          ])
          |> put_in(["operational_feedback"], %{
            "trust_boundary" => "cadence_operational_feedback",
            "realized_activities" => [
              %{
                "id" => "realized_observe_target_a",
                "planned_activity_id" => "prior_observe_target_a",
                "type" => "observe",
                "status" => "completed",
                "target" => %{"id" => "target_a"},
                "target_priority" => 6.0
              },
              %{
                "id" => "realized_bad_station",
                "planned_activity_id" => "prior_downlink_equator_prime",
                "type" => "downlink",
                "status" => "partial",
                "station" => %{"id" => "bad station"},
                "actual_throughput_mb" => 120.0
              },
              %{
                "id" => "realized_bad_target",
                "planned_activity_id" => "prior_observe_target_b",
                "type" => "observe",
                "status" => "completed",
                "target" => %{"id" => "bad target"},
                "target_priority" => 9.0
              }
            ]
          }),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert "operational feedback input is invalid" in artifact["warnings"]

    assert get_in(artifact, ["operational_feedback", "target_priority_overrides"]) == %{
             "target_a" => 6.0
           }

    refute Map.has_key?(
             get_in(artifact, ["operational_feedback", "downlink_demand_mb"]),
             "bad station"
           )

    refute Map.has_key?(
             get_in(artifact, ["operational_feedback", "target_priority_overrides"]),
             "bad target"
           )

    assert %{
             "derived_from_realized_activities" => true,
             "source_realized_activity_count" => 3,
             "invalid_operational_feedback_input" => true,
             "invalid_operational_feedback_input_reason" =>
               "operational_feedback_sections_invalid",
             "invalid_operational_feedback_sections" => invalid_sections,
             "source_operational_feedback" => %{
               "invalid_feedback_sections" => invalid_sections
             }
           } = get_in(artifact, ["provenance", "operational_feedback"])

    assert %{
             "field" => "realized_activities.station.id",
             "key" => "bad station",
             "reason" => "key_must_be_stable_id",
             "row_id" => "realized_bad_station",
             "row_index" => 2
           } in invalid_sections

    assert %{
             "field" => "realized_activities.target.id",
             "key" => "bad target",
             "reason" => "key_must_be_stable_id",
             "row_id" => "realized_bad_target",
             "row_index" => 3
           } in invalid_sections

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_operational_feedback_provenance" => %{
               "invalid_operational_feedback_sections" => ^invalid_sections
             },
             "source_operational_feedback" => %{
               "invalid_feedback_sections" => ^invalid_sections
             }
           } =
             Enum.find(review["rows"], &(&1["reason"] == "operational feedback input is invalid"))

    assert %{
             "source_operational_feedback_provenance" => %{
               "invalid_operational_feedback_sections" => ^invalid_sections
             },
             "source_operational_feedback" => %{
               "invalid_feedback_sections" => ^invalid_sections
             },
             "source_review_row" => %{
               "source_operational_feedback" => %{
                 "invalid_feedback_sections" => ^invalid_sections
               }
             }
           } =
             Enum.find(import["rows"], &(&1["reason"] == "operational feedback input is invalid"))

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  defp result_set do
    ResultSet.new!(%{
      study_id: :candidate_refresh_demo,
      trajectory_results: [],
      event_results: [
        %{
          scenario_id: :leo_1,
          event_type: :target_visibility,
          events: [
            %{
              type: :target_visibility,
              starts_at: Epoch.new!(120.0, :tdb),
              ends_at: Epoch.new!(240.0, :tdb),
              metadata: %{
                target_id: :target_a,
                target_priority: 1.0,
                max_elevation_deg: 80.0,
                minimum_elevation_deg: 10.0,
                sample_count: 3,
                interpolation: :linear_sample_crossing,
                boundary_refinement: :target_visibility_linear_margin_interpolation,
                start_boundary: :clipped_start,
                end_boundary: :visibility_end,
                start_boundary_detail: %{
                  boundary: :clipped_start,
                  interpolation: :clipped_to_sample,
                  interpolation_fraction: 0.0,
                  sample_index: 1,
                  elevation_deg: 80.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                end_boundary_detail: %{
                  edge: :end,
                  boundary: :visibility_end,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.5,
                  before_sample_index: 4,
                  after_sample_index: 5,
                  before_elevation_deg: 20.0,
                  after_elevation_deg: 0.0,
                  minimum_elevation_deg: 10.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                event_timing_policy: :sampled_state_linear_boundary,
                event_detector: :target_visibility,
                event_time_tolerance_s: 60.0,
                max_sample_step_s: 60.0,
                confidence: :bounded_by_sample_cadence
              }
            }
          ],
          source: %{target_id: :target_a}
        },
        %{
          scenario_id: :leo_1,
          event_type: :ground_station_access,
          events: [
            %{
              type: :ground_station_access,
              starts_at: Epoch.new!(300.0, :tdb),
              ends_at: Epoch.new!(420.0, :tdb),
              metadata: %{
                max_elevation_deg: 70.0,
                minimum_elevation_deg: 5.0,
                sample_count: 4,
                interpolation: :linear_sample_crossing,
                boundary_refinement: :aos_los_linear_margin_interpolation,
                start_boundary: :aos,
                end_boundary: :los,
                start_boundary_detail: %{
                  edge: :start,
                  boundary: :aos,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.25,
                  before_sample_index: 2,
                  after_sample_index: 3,
                  before_elevation_deg: 0.0,
                  after_elevation_deg: 20.0,
                  minimum_elevation_deg: 5.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                end_boundary_detail: %{
                  edge: :end,
                  boundary: :los,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.75,
                  before_sample_index: 4,
                  after_sample_index: 5,
                  before_elevation_deg: 20.0,
                  after_elevation_deg: 0.0,
                  minimum_elevation_deg: 5.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                event_timing_policy: :sampled_state_linear_boundary,
                event_detector: :access_windows,
                event_time_tolerance_s: 60.0,
                max_sample_step_s: 60.0,
                confidence: :bounded_by_sample_cadence
              }
            }
          ],
          source: %{ground_station_id: :equator_prime}
        },
        %{
          scenario_id: :other,
          event_type: :eclipse,
          events: [
            %{
              type: :eclipse,
              starts_at: Epoch.new!(120.0, :tdb),
              ends_at: Epoch.new!(240.0, :tdb),
              metadata: %{sample_count: 3}
            }
          ],
          source: %{shadow_model: :cylindrical_central_body_shadow}
        }
      ],
      errors: [],
      assumptions: %{propagator: OrbitalDynamics.Propagators.TwoBody, outputs: [:access_windows]},
      metadata: %{}
    })
  end

  defp refresh_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-1",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [%{"spacecraft_id" => "sat_1", "scenario_id" => "leo_1"}],
        "maneuver_execution_deltas" => [],
        "source" => %{"system" => "cadence"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "test"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [%{"id" => "target_a", "priority" => 2.0}],
      "constraints" => %{"avoid_eclipse" => true, "min_activity_duration_s" => 60.0},
      "scoring_policy" => %{
        "target_value_weight" => 1.0,
        "contact_value_weight" => 0.5,
        "downlink_rate_mb_s" => 3.0
      },
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "resource_summaries" => [
        %{
          "spacecraft_id" => "leo_1",
          "fuel_margin" => 0.9,
          "storage_capacity_mb" => 1000.0,
          "storage_used_mb" => 200.0
        }
      ],
      "prior_candidate_activities" => [
        %{
          "id" => "stale_observe",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "starts_at_s" => 10.0,
          "ends_at_s" => 20.0
        }
      ]
    }
  end
end
