defmodule OrbitalDynamics.CandidateRefresh.ResultArtifactOperationalFeedbackMapBuildTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CandidateRefresh, Epoch, ResultSet, Schema}

  test "applies operational feedback maps from result artifact wrappers" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_result_artifact", %{
            "schema_contract" => "result_artifact.v1",
            "metadata" => %{"trust_boundary" => "cadence_feedback_archive"},
            "operational_feedback" => %{
              "downlink_demand_mb" => %{"equator_prime" => 180.0},
              "downlink_demand_sources" => %{
                "equator_prime" => ["result_artifact.operational_feedback:dl_gap"]
              }
            }
          }),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 180.0

    assert downlink["downlink_completion_sources"] == [
             "result_artifact.operational_feedback:dl_gap"
           ]

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{
             "equator_prime" => 180.0
           }

    assert get_in(artifact, ["operational_feedback", "trust_boundary"]) ==
             "cadence_feedback_archive"

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "derived_from_source_result_artifact_operational_feedback"
           ])

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_result_artifact_operational_feedback_paths"
           ]) == ["source_result_artifact.operational_feedback"]

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_result_artifact_operational_feedback_input_keys"
           ]) == ["downlink_demand_mb", "downlink_demand_sources"]

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_result_artifact_operational_feedback_trust_boundaries"
           ]) == ["cadence_feedback_archive"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "records field trust boundaries from multiple result artifact operational feedback wrappers" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_result_artifact", [
            %{
              "schema_contract" => "result_artifact.v1",
              "metadata" => %{"trust_boundary" => "cadence_feedback_archive_a"},
              "operational_feedback" => %{
                "downlink_demand_mb" => %{"equator_prime" => 180.0},
                "downlink_demand_sources" => %{
                  "equator_prime" => ["archive_a.downlink_gap"]
                }
              }
            },
            %{
              "schema_contract" => "result_artifact.v1",
              "provenance" => %{"trust_boundary" => "cadence_feedback_archive_b"},
              "operational_feedback" => %{
                "target_priority_overrides" => %{"target_a" => 4.0}
              }
            }
          ]),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_result_artifact_operational_feedback_paths"
           ]) == [
             "source_result_artifact[0].operational_feedback",
             "source_result_artifact[1].operational_feedback"
           ]

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_result_artifact_operational_feedback_trust_boundaries"
           ]) == ["cadence_feedback_archive_a", "cadence_feedback_archive_b"]

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_result_artifact_operational_feedback_field_trust_boundaries"
           ]) == %{
             "downlink_demand_mb" => %{"equator_prime" => ["cadence_feedback_archive_a"]},
             "downlink_demand_sources" => %{
               "equator_prime" => ["cadence_feedback_archive_a"]
             },
             "target_priority_overrides" => %{"target_a" => ["cadence_feedback_archive_b"]}
           }

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
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
