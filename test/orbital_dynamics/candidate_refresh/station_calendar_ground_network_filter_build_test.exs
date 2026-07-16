defmodule OrbitalDynamics.CandidateRefresh.StationCalendarGroundNetworkFilterBuildTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CandidateRefresh, Epoch, ResultSet, Schema}

  test "filters refreshed contacts using ground network availability" do
    refresh =
      Map.put(refresh_request(), "ground_network", [
        %{
          "ground_station_id" => "equator_prime",
          "status" => "Unavailable",
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1"
           ]

    assert artifact["contact_intents"] == []

    assert %{
             "schema_contract" => "contact_filter_report.v1",
             "input_candidate_count" => 2,
             "kept_candidate_count" => 1,
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "leo_1_downlink_equator_prime_1",
                 "suppressed_reason" => "ground_station_unavailable"
               }
             ]
           } = artifact["contact_filter_report"]

    assert "ground network filters suppressed refreshed contact candidates" in artifact[
             "warnings"
           ]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "filters refreshed contacts using reserved ground station windows" do
    refresh =
      refresh_request()
      |> Map.put("approval_policy", %{"policy_bundle_id" => "ground_network_allocation_v1"})
      |> Map.put("ground_network", [
        %{
          "ground_station_id" => "equator_prime",
          "status" => "Reserved",
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0,
          "reservation_id" => "reservation_equator_prime_1",
          "reserved_by" => "ops_team_b",
          "reservation_status" => "reserved"
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1"
           ]

    assert artifact["contact_intents"] == []

    assert %{
             "schema_contract" => "contact_filter_report.v1",
             "input_candidate_count" => 2,
             "kept_candidate_count" => 1,
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "leo_1_downlink_equator_prime_1",
                 "suppressed_reason" => "ground_station_reserved",
                 "station_availability" => "reserved",
                 "station_contention_status" => "reserved_overlap",
                 "station_reservation_id" => "reservation_equator_prime_1",
                 "station_reserved_by" => "ops_team_b",
                 "station_reservation_status" => "reserved",
                 "station_reservation_match_status" => "overlap",
                 "approval_status" => "operator_review_required",
                 "policy_decision" => %{
                   "policy_bundle_id" => "ground_network_allocation_v1"
                 },
                 "approval_rule_matches" => [
                   %{"rule_id" => "reserved_station_contact_review"}
                 ]
               }
             ]
           } = artifact["contact_filter_report"]

    assert %{
             "schema_contract" => "contact_allocation_report.v1",
             "input_contact_count" => 1,
             "allocated_contact_count" => 0,
             "blocked_contact_count" => 1,
             "rows" => [
               %{
                 "contact_id" => "leo_1_downlink_equator_prime_1",
                 "allocation_status" => "blocked",
                 "allocation_reason" => "ground_station_reserved",
                 "station_contention_status" => "reserved_overlap",
                 "station_reservation_id" => "reservation_equator_prime_1",
                 "station_reservation_match_status" => "overlap",
                 "approval_status" => "operator_review_required",
                 "policy_decision" => %{
                   "schema_contract" => "policy_decision.v1",
                   "policy_bundle_id" => "ground_network_allocation_v1",
                   "classification" => "operator_review_required"
                 },
                 "approval_rule_matches" => rule_matches
               }
             ]
           } = artifact["contact_allocation_report"]

    assert Enum.any?(
             rule_matches,
             &(&1["rule_id"] == "reserved_station_contact_review" and
                 &1["station_reservation_status"] == "reserved")
           )

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "unavailable station refresh state outranks reserved overlap while preserving reservation evidence" do
    refresh =
      refresh_request()
      |> Map.put("approval_policy", %{"policy_bundle_id" => "ground_network_allocation_v1"})
      |> Map.put("ground_network", [
        %{
          "ground_station_id" => "equator_prime",
          "status" => "Unavailable",
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0
        },
        %{
          "ground_station_id" => "equator_prime",
          "status" => "Reserved",
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0,
          "reservation_id" => "reservation_equator_prime_1",
          "reserved_by" => "ops_team_b",
          "reservation_status" => "confirmed"
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "suppressed_candidates" => [
               %{
                 "id" => "leo_1_downlink_equator_prime_1",
                 "suppressed_reason" => "ground_station_unavailable",
                 "station_availability" => "unavailable",
                 "station_contention_status" => "reserved_overlap",
                 "station_reservation_id" => "reservation_equator_prime_1",
                 "station_reserved_by" => "ops_team_b",
                 "station_reservation_status" => "confirmed",
                 "station_reservation_match_status" => "overlap",
                 "station_calendar_reservation_overlap_count" => 1,
                 "station_calendar_reservation_ids" => ["reservation_equator_prime_1"],
                 "station_calendar_reserved_by" => ["ops_team_b"],
                 "station_calendar_reservation_statuses" => ["confirmed"],
                 "approval_status" => "blocked_by_policy",
                 "approval_rule_matches" => rule_matches
               }
             ]
           } = artifact["contact_filter_report"]

    assert Enum.any?(
             rule_matches,
             &(&1["rule_id"] == "unavailable_station_contact_block" and
                 &1["classification"] == "blocked_by_policy")
           )

    assert %{
             "rows" => [
               %{
                 "contact_id" => "leo_1_downlink_equator_prime_1",
                 "allocation_status" => "blocked",
                 "allocation_reason" => "ground_station_unavailable",
                 "station_availability" => "unavailable",
                 "station_contention_status" => "reserved_overlap",
                 "station_reservation_id" => "reservation_equator_prime_1",
                 "station_reservation_match_status" => "overlap"
               }
             ]
           } = artifact["contact_allocation_report"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "availability-only maintenance station refresh state suppresses generated downlinks" do
    refresh =
      refresh_request()
      |> Map.put("approval_policy", %{"policy_bundle_id" => "ground_network_allocation_v1"})
      |> Map.put("ground_network", [
        %{
          "id" => "equator_maintenance",
          "ground_station_id" => "equator_prime",
          "availability" => "Maintenance",
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1"
           ]

    assert %{
             "suppressed_candidates" => [
               %{
                 "id" => "leo_1_downlink_equator_prime_1",
                 "suppressed_reason" => "ground_station_unavailable",
                 "station_availability" => "unavailable",
                 "station_calendar_entry_id" => "equator_maintenance",
                 "source_station_calendar_entry" => %{
                   "availability" => "maintenance"
                 },
                 "approval_status" => "blocked_by_policy"
               }
             ]
           } = artifact["contact_filter_report"]

    assert %{
             "rows" => [
               %{
                 "contact_id" => "leo_1_downlink_equator_prime_1",
                 "allocation_status" => "blocked",
                 "allocation_reason" => "ground_station_unavailable",
                 "station_availability" => "unavailable",
                 "station_calendar_entry_id" => "equator_maintenance"
               }
             ]
           } = artifact["contact_allocation_report"]

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
