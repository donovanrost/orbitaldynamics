defmodule OrbitalDynamics.CandidateRefresh.BuildFallbackTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CandidateRefresh, Epoch, ResultSet, Schema}

  test "uses mission-state targets resources and station calendar when refresh request omits them" do
    refresh =
      refresh_request()
      |> Map.delete("targets")
      |> Map.delete("resource_summaries")
      |> Map.put("mission_state", %{
        "targets" => [%{"id" => "target_a", "priority" => 4.0}],
        "resource_summaries" => [
          %{
            "spacecraft_id" => "leo_1",
            "fuel_margin" => 0.8,
            "storage_capacity_mb" => 1000.0,
            "storage_used_mb" => 100.0
          }
        ],
        "ground_network" => [
          %{
            "id" => "mission_state_outage",
            "ground_station_id" => "equator_prime",
            "status" => "maintenance",
            "starts_at_s" => 280.0,
            "ends_at_s" => 450.0
          }
        ]
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [observe] = artifact["candidate_activities"]

    assert %{
             "type" => "observe",
             "target_id" => "target_a",
             "target_priority" => 4.0,
             "target_priority_source" => "candidate_refresh.targets.priority",
             "score_terms" => %{"target_value" => 480.0}
           } = observe

    assert [
             %{
               "schema_contract" => "resource_summary.v1",
               "spacecraft_id" => "leo_1",
               "storage_margin" => 0.9
             }
           ] = artifact["resource_summaries"]

    assert %{
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "leo_1_downlink_equator_prime_1",
                 "suppressed_reason" => "ground_station_unavailable",
                 "station_calendar_entry_id" => "mission_state_outage"
               }
             ]
           } = artifact["contact_filter_report"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "uses accepted planning-state targets and ground network when refresh request omits them" do
    refresh =
      refresh_request()
      |> Map.delete("targets")
      |> Map.delete("ground_network")
      |> put_in(["accepted_planning_state", "targets"], [
        %{"id" => "target_a", "priority" => 6.0}
      ])
      |> put_in(["accepted_planning_state", "ground_network"], [
        %{
          "id" => "accepted_state_outage",
          "ground_station_id" => "equator_prime",
          "status" => "maintenance",
          "starts_at_s" => 280.0,
          "ends_at_s" => 450.0,
          "provenance" => %{"trust_boundary" => "accepted_ground_network_snapshot"}
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [observe] = artifact["candidate_activities"]

    assert %{
             "type" => "observe",
             "target_id" => "target_a",
             "target_priority" => 6.0,
             "target_priority_source" => "candidate_refresh.targets.priority",
             "score_terms" => %{"target_value" => 720.0}
           } = observe

    assert %{
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "leo_1_downlink_equator_prime_1",
                 "suppressed_reason" => "ground_station_unavailable",
                 "station_calendar_entry_id" => "accepted_state_outage",
                 "station_calendar_trust_boundary_status" => "declared",
                 "trust_boundary" => "accepted_ground_network_snapshot",
                 "source_station_calendar_entry" => %{
                   "status" => "maintenance",
                   "provenance" => %{
                     "trust_boundary" => "accepted_ground_network_snapshot"
                   }
                 }
               }
             ]
           } = artifact["contact_filter_report"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "uses mission-state remaining horizon when refresh request omits it" do
    refresh =
      refresh_request()
      |> Map.delete("remaining_horizon")
      |> Map.put("mission_state", %{
        "remaining_horizon" => %{
          "starts_at_s" => "300.0",
          "ends_at_s" => "500.0",
          "output_step_s" => "60.0"
        }
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert artifact["remaining_horizon"] == %{
             "starts_at_s" => 300.0,
             "ends_at_s" => 500.0,
             "output_step_s" => 60.0
           }

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_downlink_equator_prime_1"
           ]

    assert artifact["freshness_report"]["horizon_start_offset_s"] == 300.0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "uses accepted planning-state remaining horizon when request and mission-state omit it" do
    refresh =
      refresh_request()
      |> Map.delete("remaining_horizon")
      |> put_in(["accepted_planning_state", "remaining_horizon"], %{
        "starts_at_s" => "300.0",
        "ends_at_s" => "500.0",
        "output_step_s" => "60.0"
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert artifact["remaining_horizon"] == %{
             "starts_at_s" => 300.0,
             "ends_at_s" => 500.0,
             "output_step_s" => 60.0
           }

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_downlink_equator_prime_1"
           ]

    assert artifact["freshness_report"]["horizon_start_offset_s"] == 300.0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "uses mission-state current epoch when refresh request omits it" do
    refresh =
      refresh_request()
      |> Map.delete("current_epoch_s")
      |> put_in(["remaining_horizon", "starts_at_s"], 120.0)
      |> Map.put("mission_state", %{
        "current_epoch" => %{"seconds_since_j2000" => "120.0"}
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert artifact["current_epoch_s"] == 120.0
    assert artifact["freshness_report"]["horizon_start_offset_s"] == 0.0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "uses accepted planning-state spacecraft epoch when request and mission-state omit it" do
    refresh =
      refresh_request()
      |> Map.delete("current_epoch_s")
      |> put_in(["remaining_horizon", "starts_at_s"], 120.0)
      |> put_in(["accepted_planning_state", "spacecraft_states"], [
        %{
          "spacecraft_id" => "sat_1",
          "scenario_id" => "leo_1",
          "epoch" => %{"seconds_since_j2000" => "120.0"}
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert artifact["current_epoch_s"] == 120.0
    assert artifact["freshness_report"]["horizon_start_offset_s"] == 0.0

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
