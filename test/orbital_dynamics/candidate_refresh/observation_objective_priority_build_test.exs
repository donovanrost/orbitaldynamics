defmodule OrbitalDynamics.CandidateRefresh.ObservationObjectivePriorityBuildTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CandidateRefresh, Epoch, ResultSet, Schema}

  test "applies urgent target objective priority to refreshed observation scores" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("objectives", [
            %{
              "id" => "urgent:target_a",
              "type" => "urgent_target",
              "target_id" => "target_a",
              "spacecraft_id" => "sat_1",
              "priority" => 12.0
            }
          ])
          |> put_in(["scoring_policy", "observation_objective_weight"], 40.0),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [observe] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "observe"))

    assert %{
             "target_priority" => 12.0,
             "target_priority_source" => "candidate_refresh.objectives.observation_priority",
             "target_priority_objective_ids" => ["urgent:target_a"],
             "target_priority_objective_type" => "urgent_target",
             "required_observations" => 1.0,
             "score_terms" => %{
               "target_value" => 1440.0,
               "observation_objective_value" => 40.0
             },
             "activity_context" => %{
               "target_priority" => 12.0,
               "target_priority_source" => "candidate_refresh.objectives.observation_priority",
               "target_priority_objective_ids" => ["urgent:target_a"],
               "target_priority_objective_type" => "urgent_target"
             }
           } = observe

    assert observe["score"] == 1480.0

    assert {:ok, schema} = Schema.json_schema("candidate_activity.v1")

    assert get_in(schema, [
             "properties",
             "target_priority_objective_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "applies matched inline target-spec objective priority to refreshed observations" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("objectives", [
            %{
              "id" => "urgent:inline_targets",
              "type" => "urgent_target",
              "priority_targets" => [
                %{"id" => "target_a", "priority" => 12.0},
                %{"id" => "target_b", "priority" => 30.0}
              ]
            }
          ])
          |> put_in(["scoring_policy", "observation_objective_weight"], 40.0),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [observe] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "observe"))

    assert %{
             "target_id" => "target_a",
             "target_priority" => 12.0,
             "target_priority_source" => "candidate_refresh.objectives.observation_priority",
             "target_priority_objective_ids" => ["urgent:inline_targets"],
             "score_terms" => %{
               "target_value" => 1440.0,
               "observation_objective_value" => 40.0
             },
             "activity_context" => %{
               "target_priority" => 12.0,
               "target_priority_objective_ids" => ["urgent:inline_targets"]
             }
           } = observe

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "does not lower operational target priority with lower objective priority" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(["operational_feedback"], %{
            "target_priority_overrides" => %{"target_a" => 15.0}
          })
          |> Map.put("objectives", [
            %{
              "id" => "urgent:target_a:lower",
              "type" => "urgent_target",
              "target_id" => "target_a",
              "priority" => 4.0
            }
          ]),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [observe] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "observe"))

    assert observe["target_priority"] == 15.0
    assert observe["target_priority_source"] == "operational_feedback.target_priority_overrides"
    refute Map.has_key?(observe, "target_priority_objective_ids")
    assert observe["score_terms"]["target_value"] == 1800.0

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
