defmodule OrbitalDynamics.CandidateRefresh.RealizedActivityFeedbackValidationBuildTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CadenceImport,
    CandidateRefresh,
    Epoch,
    OperatorReview,
    ResultSet,
    Schema
  }

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
