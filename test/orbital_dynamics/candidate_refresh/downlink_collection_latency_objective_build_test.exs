defmodule OrbitalDynamics.CandidateRefresh.DownlinkCollectionLatencyObjectiveBuildTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CandidateRefresh,
    CollectionLatencyObjectiveType,
    Epoch,
    ResultSet,
    Schema
  }

  test "applies collection latency objectives to refreshed downlink demand" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("objectives", [
            %{
              "id" => "latency:collection_alpha",
              "type" => "collection_latency",
              "ground_station_id" => "equator_prime",
              "collection_id" => "collection_alpha",
              "max_latency_s" => 900.0,
              "required_downlink_mb" => 180.0
            },
            %{
              "id" => "latency:other_station",
              "type" => "collection_latency",
              "ground_station_id" => "polar_station",
              "required_downlink_mb" => 500.0
            }
          ]),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [downlink] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 180.0
    assert downlink["candidate_downlink_mb"] == 360.0
    assert downlink["downlink_completion_ratio"] == 1.0
    assert downlink["selected_downlink_shortfall_mb"] == 0.0
    assert downlink["downlink_requirement_status"] == "satisfied"

    assert downlink["downlink_completion_source"] ==
             "candidate_refresh.objectives.collection_latency"

    assert get_in(downlink, ["throughput_model", "required_downlink_mb"]) == 180.0
    assert get_in(downlink, ["activity_context", "required_downlink_mb"]) == 180.0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "applies collection latency objectives to refreshed observation candidates" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("objectives", [
            %{
              "id" => "latency:collection_alpha",
              "type" => "collection_latency",
              "target_id" => "target_a",
              "spacecraft_id" => "sat_1",
              "ground_station_id" => "equator_prime",
              "collection_id" => "collection_alpha",
              "product_ids" => ["image_l0", "image_l1"],
              "payload_id" => "camera_a",
              "instrument_id" => "imager",
              "max_latency_s" => 900.0,
              "required_downlink_mb" => 180.0
            },
            %{
              "id" => "latency:other_target",
              "type" => "collection_latency",
              "target_id" => "target_b",
              "spacecraft_id" => "sat_2",
              "required_downlink_mb" => 500.0
            }
          ])
          |> put_in(["scoring_policy", "collection_latency_observation_weight"], 35.0),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [observe] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "observe"))

    assert %{
             "collection_latency_objective_count" => 1,
             "collection_latency_objective_ids" => ["latency:collection_alpha"],
             "collection_latency_objective_types" => ["collection_latency"],
             "collection_latency_objective_source" =>
               "candidate_refresh.objectives.collection_latency",
             "collection_id" => "collection_alpha",
             "product_ids" => ["image_l0", "image_l1"],
             "payload_id" => "camera_a",
             "instrument_id" => "imager",
             "max_latency_s" => 900.0,
             "required_downlink_mb" => 180.0,
             "score_terms" => %{
               "target_value" => 240.0,
               "collection_latency_observation_value" => 35.0
             },
             "activity_context" => %{
               "collection_latency_objective_count" => 1,
               "collection_latency_objective_ids" => ["latency:collection_alpha"],
               "collection_latency_objective_types" => ["collection_latency"],
               "collection_id" => "collection_alpha",
               "product_ids" => ["image_l0", "image_l1"],
               "payload_id" => "camera_a",
               "instrument_id" => "imager",
               "max_latency_s" => 900.0,
               "required_downlink_mb" => 180.0
             }
           } = observe

    assert observe["score"] == 275.0

    assert [downlink] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 180.0

    assert {:ok, schema} = Schema.json_schema("candidate_activity.v1")

    assert get_in(schema, [
             "properties",
             "collection_latency_objective_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, [
             "properties",
             "max_latency_s",
             "minimum"
           ]) == 0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "applies every collection latency objective alias consistently" do
    aliases = CollectionLatencyObjectiveType.aliases()

    assert aliases == [
             "collection_latency",
             "collection_downlink_latency",
             "data_latency",
             "downlink_latency",
             "max_collection_latency",
             "collection_latency_limit"
           ]

    Enum.each(aliases, fn objective_type ->
      objective_id = "latency:#{objective_type}"

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
                "ground_station_id" => "equator_prime",
                "collection_id" => "collection_alias",
                "max_latency_s" => 900.0,
                "required_downlink_mb" => 42.0
              }
            ]),
          generated_at: ~U[2026-05-14 00:00:00Z]
        )

      assert [observe] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "observe"))

      assert [downlink] =
               Enum.filter(artifact["candidate_activities"], &(&1["type"] == "downlink"))

      assert observe["collection_latency_objective_ids"] == [objective_id]
      assert observe["collection_latency_objective_types"] == [objective_type]
      assert observe["max_latency_s"] == 900.0
      assert downlink["required_downlink_mb"] == 42.0

      assert downlink["downlink_completion_source"] ==
               "candidate_refresh.objectives.collection_latency"

      assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
               Schema.validate_artifact(artifact)
    end)
  end

  test "combines downlink completion and collection latency demand objectives" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("objectives", [
            %{
              "type" => "downlink_completion",
              "ground_station_id" => "equator_prime",
              "required_downlink_mb" => 120.0
            },
            %{
              "type" => "collection_downlink_latency",
              "station_id" => "equator_prime",
              "required_data_volume_mb" => 240.0
            }
          ]),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [downlink] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 360.0

    assert downlink["downlink_completion_source"] ==
             "candidate_refresh.objectives.downlink_completion_and_latency"

    assert downlink["downlink_completion_sources"] == [
             "candidate_refresh.objectives.collection_latency",
             "candidate_refresh.objectives.downlink_completion"
           ]

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
