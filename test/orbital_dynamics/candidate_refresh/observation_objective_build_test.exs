defmodule OrbitalDynamics.CandidateRefresh.ObservationObjectiveBuildTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CandidateRefresh,
    Epoch,
    ResultSet,
    Schema,
    TargetObservationObjectiveType
  }

  test "applies target observation objectives to refreshed observation candidates" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("objectives", [
            %{
              "id" => "obs:target_a:revisit",
              "type" => "target_revisit",
              "target_id" => "target_a",
              "spacecraft_id" => "sat_1",
              "required_revisits" => 2
            },
            %{
              "id" => "obs:other_target",
              "type" => "target_observation",
              "target_id" => "target_b",
              "required_observations" => 5
            }
          ])
          |> put_in(["scoring_policy", "observation_objective_weight"], 40.0),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [observe] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "observe"))

    assert %{
             "observation_objective_count" => 1,
             "observation_objective_ids" => ["obs:target_a:revisit"],
             "observation_objective_types" => ["target_revisit"],
             "required_observations" => 2.0,
             "observation_objective_source" => "candidate_refresh.objectives.observation",
             "score_terms" => %{
               "target_value" => 240.0,
               "observation_objective_value" => 80.0
             },
             "activity_context" => %{
               "observation_objective_count" => 1,
               "observation_objective_ids" => ["obs:target_a:revisit"],
               "observation_objective_types" => ["target_revisit"],
               "required_observations" => 2.0
             }
           } = observe

    assert observe["score"] == 320.0

    assert {:ok, schema} = Schema.json_schema("candidate_activity.v1")

    assert get_in(schema, [
             "properties",
             "observation_objective_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, [
             "properties",
             "required_observations",
             "minimum"
           ]) == 0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "applies every target observation objective alias consistently" do
    aliases = TargetObservationObjectiveType.aliases()

    assert aliases == ["target_observation", "target_commitment"]

    Enum.each(aliases, fn objective_type ->
      objective_id = "obs:target_a:#{objective_type}"

      artifact =
        result_set()
        |> CandidateRefresh.build(
          candidate_refresh:
            refresh_request()
            |> Map.put("objectives", [
              %{
                "id" => objective_id,
                "type" => objective_type,
                "target_id" => "target_a",
                "spacecraft_id" => "sat_1",
                "required_count" => 2
              }
            ]),
          generated_at: ~U[2026-05-14 00:00:00Z]
        )

      assert [observe] =
               Enum.filter(artifact["candidate_activities"], &(&1["type"] == "observe"))

      assert observe["observation_objective_ids"] == [objective_id]
      assert observe["observation_objective_types"] == [objective_type]
      assert observe["required_observations"] == 2.0
      assert observe["score_terms"]["observation_objective_value"] == 50.0

      assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
               Schema.validate_artifact(artifact)
    end)
  end

  test "refresh identity changes when mission-state objectives change generated candidates" do
    base_refresh =
      refresh_request()
      |> Map.put("mission_state", %{
        "objectives" => [
          %{
            "id" => "urgent:target_a",
            "type" => "urgent_target",
            "target_id" => "target_a",
            "spacecraft_id" => "sat_1",
            "priority" => 5.0
          }
        ]
      })

    changed_refresh =
      put_in(base_refresh, ["mission_state", "objectives", Access.at(0), "priority"], 9.0)

    base =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: base_refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    changed =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: changed_refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert base["refresh_id"] != changed["refresh_id"]

    assert [base_observe] = Enum.filter(base["candidate_activities"], &(&1["type"] == "observe"))

    assert [changed_observe] =
             Enum.filter(changed["candidate_activities"], &(&1["type"] == "observe"))

    assert base_observe["target_priority"] == 5.0
    assert changed_observe["target_priority"] == 9.0
  end

  test "applies nested-target observation objectives to refreshed observation candidates" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("objectives", [
            %{
              "id" => "obs:target_a:nested",
              "type" => "target_observation",
              "target" => %{"id" => "target_a"},
              "spacecraft" => %{"id" => "sat_1"},
              "required_observations" => 2
            },
            %{
              "id" => "obs:target_b:nested",
              "type" => "target_observation",
              "targets" => [%{"id" => "target_b"}],
              "required_observations" => 5
            }
          ])
          |> put_in(["scoring_policy", "observation_objective_weight"], 40.0),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [observe] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "observe"))

    assert %{
             "target_id" => "target_a",
             "observation_objective_count" => 1,
             "observation_objective_ids" => ["obs:target_a:nested"],
             "required_observations" => 2.0,
             "score_terms" => %{"observation_objective_value" => 80.0},
             "activity_context" => %{
               "observation_objective_ids" => ["obs:target_a:nested"],
               "required_observations" => 2.0
             }
           } = observe

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "applies target-gap selector aliases to refreshed observation candidates" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("objectives", [
            %{
              "id" => "gap:unsatisfied_target_a",
              "type" => "target_coverage",
              "unsatisfied_target_ids" => ["target_a"],
              "coverage_gap_count" => 2
            },
            %{
              "id" => "gap:uncovered_target_b",
              "type" => "target_coverage",
              "uncovered_targets" => [%{"id" => "target_b"}],
              "coverage_gap_count" => 5
            }
          ])
          |> put_in(["scoring_policy", "observation_objective_weight"], 40.0),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [observe] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "observe"))

    assert %{
             "target_id" => "target_a",
             "observation_objective_count" => 1,
             "observation_objective_ids" => ["gap:unsatisfied_target_a"],
             "required_observations" => 2.0,
             "score_terms" => %{"observation_objective_value" => 80.0},
             "activity_context" => %{
               "observation_objective_ids" => ["gap:unsatisfied_target_a"],
               "required_observations" => 2.0
             }
           } = observe

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "uses unique inline target spec as target metadata when target catalog omits it" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("targets", [])
          |> Map.put("objectives", [
            %{
              "id" => "obs:inline_quality_target_a",
              "type" => "target_observation",
              "target_specs" => [
                %{
                  "id" => "target_a",
                  "latitude_deg" => "12.5",
                  "longitude_deg" => "-45.25",
                  "minimum_elevation_deg" => "17.5",
                  "geometry_model" => "operator_inline_target_geometry",
                  "image_quality_score" => 0.5,
                  "image_quality_status" => "degraded",
                  "image_quality_source" => "operator_inline_target_spec"
                }
              ]
            }
          ]),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [observe] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "observe"))

    assert %{
             "target_id" => "target_a",
             "target_priority" => 0.5,
             "target_priority_source" => "source_window.target_priority",
             "source_target_id" => "target_a",
             "source_target" => %{
               "id" => "target_a",
               "latitude_deg" => 12.5,
               "longitude_deg" => -45.25,
               "minimum_elevation_deg" => 17.5,
               "geometry_model" => "operator_inline_target_geometry"
             },
             "target_latitude_deg" => 12.5,
             "target_longitude_deg" => -45.25,
             "target_minimum_elevation_deg" => 17.5,
             "observation_success_factor" => 0.5,
             "observation_success_factor_source" => "target.image_quality_score",
             "image_quality_score" => 0.5,
             "image_quality_status" => "degraded",
             "image_quality_source" => "operator_inline_target_spec",
             "score_terms" => %{
               "target_value" => 60.0,
               "observation_objective_value" => 25.0
             },
             "activity_context" => %{
               "image_quality_score" => 0.5,
               "image_quality_status" => "degraded",
               "image_quality_source" => "operator_inline_target_spec",
               "source_target_id" => "target_a",
               "target_latitude_deg" => 12.5,
               "target_longitude_deg" => -45.25,
               "target_minimum_elevation_deg" => 17.5
             }
           } = observe

    assert [
             %{
               "id" => observe_id,
               "target_id" => "target_a",
               "source_target_id" => "target_a",
               "source_target" => %{
                 "id" => "target_a",
                 "latitude_deg" => 12.5,
                 "longitude_deg" => -45.25,
                 "minimum_elevation_deg" => 17.5,
                 "geometry_model" => "operator_inline_target_geometry"
               },
               "target_latitude_deg" => 12.5,
               "target_longitude_deg" => -45.25,
               "target_minimum_elevation_deg" => 17.5,
               "target_priority" => 0.5,
               "target_priority_source" => "source_window.target_priority"
             }
           ] =
             Enum.filter(
               artifact["candidate_diff_report"]["new_candidates"],
               &(&1["id"] == observe["id"])
             )

    assert observe_id == observe["id"]

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
