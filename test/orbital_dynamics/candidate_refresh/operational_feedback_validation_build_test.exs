defmodule OrbitalDynamics.CandidateRefresh.OperationalFeedbackValidationBuildTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CadenceImport,
    CandidateRefresh,
    Epoch,
    OperatorReview,
    ResultSet,
    Schema
  }

  test "malformed and out-of-range scalar operational feedback entries are review gated instead of emitted" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("operational_feedback", %{
            "trust_boundary" => "cadence_operational_feedback",
            "contact_success_rate" => %{
              "equator_prime" => -0.25,
              "default" => "0.8"
            },
            "station_throughput_factor" => %{
              "equator_prime" => 1.5,
              "default" => "0.5"
            },
            "observation_success_rate" => %{
              "target_a" => 1.25
            },
            "image_quality_score" => %{
              "target_a" => -0.1
            },
            "downlink_demand_mb" => %{
              "equator_prime" => "bad-demand",
              "polar_prime" => -40.0,
              "default" => "120.0"
            },
            "target_priority_overrides" => %{
              "target_a" => "bad-priority",
              "target_b" => -2.0
            }
          }),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert "operational feedback input is invalid" in artifact["warnings"]

    assert %{
             "contact_success_rate" => %{"default" => 0.8},
             "station_throughput_factor" => %{"default" => 0.5},
             "downlink_demand_mb" => %{"default" => 120.0}
           } = artifact["operational_feedback"]

    refute Map.has_key?(artifact["operational_feedback"]["contact_success_rate"], "equator_prime")

    refute Map.has_key?(
             artifact["operational_feedback"]["station_throughput_factor"],
             "equator_prime"
           )

    refute Map.has_key?(artifact["operational_feedback"], "observation_success_rate")
    refute Map.has_key?(artifact["operational_feedback"], "image_quality_score")
    refute Map.has_key?(artifact["operational_feedback"]["downlink_demand_mb"], "equator_prime")
    refute Map.has_key?(artifact["operational_feedback"]["downlink_demand_mb"], "polar_prime")
    refute Map.has_key?(artifact["operational_feedback"], "target_priority_overrides")

    assert %{
             "activity_context" => %{
               "contact_success_factor" => 0.8,
               "required_downlink_mb" => 120.0
             },
             "contact_success_factor" => 0.8,
             "estimated_throughput_mb" => 180.0,
             "throughput_model" => %{"station_throughput_factor" => 0.5}
           } = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))

    assert %{
             "operational_feedback" => %{
               "invalid_operational_feedback_input" => true,
               "invalid_operational_feedback_input_reason" =>
                 "operational_feedback_sections_invalid",
               "invalid_operational_feedback_sections" => invalid_sections
             }
           } = artifact["provenance"]

    assert %{
             "field" => "contact_success_rate",
             "key" => "equator_prime",
             "reason" => "entry_must_be_unit_interval_number",
             "invalid_feedback_shape" => -0.25
           } in invalid_sections

    assert %{
             "field" => "station_throughput_factor",
             "key" => "equator_prime",
             "reason" => "entry_must_be_unit_interval_number",
             "invalid_feedback_shape" => 1.5
           } in invalid_sections

    assert %{
             "field" => "observation_success_rate",
             "key" => "target_a",
             "reason" => "entry_must_be_unit_interval_number",
             "invalid_feedback_shape" => 1.25
           } in invalid_sections

    assert %{
             "field" => "image_quality_score",
             "key" => "target_a",
             "reason" => "entry_must_be_unit_interval_number",
             "invalid_feedback_shape" => -0.1
           } in invalid_sections

    assert %{
             "field" => "downlink_demand_mb",
             "key" => "equator_prime",
             "reason" => "entry_must_be_number",
             "invalid_feedback_shape" => "bad-demand"
           } in invalid_sections

    assert %{
             "field" => "downlink_demand_mb",
             "key" => "polar_prime",
             "reason" => "entry_must_be_nonnegative_number",
             "invalid_feedback_shape" => -40.0
           } in invalid_sections

    assert %{
             "field" => "target_priority_overrides",
             "key" => "target_a",
             "reason" => "entry_must_be_number",
             "invalid_feedback_shape" => "bad-priority"
           } in invalid_sections

    assert %{
             "field" => "target_priority_overrides",
             "key" => "target_b",
             "reason" => "entry_must_be_nonnegative_number",
             "invalid_feedback_shape" => -2.0
           } in invalid_sections

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_operational_feedback_provenance" => %{
               "invalid_operational_feedback_sections" => ^invalid_sections
             }
           } =
             Enum.find(review["rows"], &(&1["reason"] == "operational feedback input is invalid"))

    assert %{
             "source_operational_feedback_provenance" => %{
               "invalid_operational_feedback_sections" => ^invalid_sections
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
