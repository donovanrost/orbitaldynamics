defmodule OrbitalDynamics.CandidateRefresh.ContactAllocationPressureBuildTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CandidateRefresh,
    Epoch,
    ResultSet,
    Schema
  }

  test "derives downlink completion objectives from source contact allocation reports" do
    report = %{
      "schema_contract" => "contact_allocation_report.v1",
      "rows" => [
        %{
          contact_id: "dl_prior_deferred",
          type: "downlink",
          direction: "downlink",
          allocation_status: "deferred",
          effective_allocation_status: "deferred",
          allocation_reason: "same_station_contention",
          ground_station_id: "equator_prime",
          required_downlink_mb: 420.0,
          source_window_id: "window_prior",
          trust_boundary: "cadence_ops"
        }
      ]
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_contact_allocation_report", report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 420.0
    assert downlink["candidate_downlink_mb"] == 360.0
    assert downlink["selected_downlink_shortfall_mb"] == 60.0

    assert downlink["downlink_completion_source"] ==
             "candidate_refresh.objectives.downlink_completion"

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "ignores contact allocation rows that do not represent blocked downlink pressure" do
    report = %{
      "schema_contract" => "contact_allocation_report.v1",
      "rows" => [
        %{
          "contact_id" => "dl_allocated",
          "type" => "downlink",
          "allocation_status" => "allocated",
          "ground_station_id" => "equator_prime",
          "required_downlink_mb" => 900.0
        },
        %{
          "contact_id" => "uplink_blocked",
          "type" => "uplink",
          "direction" => "uplink",
          "allocation_status" => "blocked",
          "ground_station_id" => "equator_prime",
          "required_downlink_mb" => 900.0
        },
        %{
          "contact_id" => "dl_blocked_without_station",
          "type" => "downlink",
          "allocation_status" => "blocked",
          "required_downlink_mb" => 900.0
        },
        %{
          "contact_id" => "dl_deferred_without_volume",
          "type" => "downlink",
          "allocation_status" => "deferred",
          "ground_station_id" => "equator_prime",
          "required_downlink_mb" => 0.0
        }
      ]
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_contact_allocation_report", report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    refute Map.has_key?(downlink, "required_downlink_mb")
    refute Map.has_key?(downlink, "selected_downlink_shortfall_mb")

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays source contact allocation station blocks into ground network state" do
    report = %{
      "schema_contract" => "contact_allocation_report.v1",
      "rows" => [
        %{
          "contact_id" => "dl_prior_unavailable",
          "type" => "downlink",
          "direction" => "downlink",
          "allocation_status" => "blocked",
          "effective_allocation_status" => "blocked",
          "allocation_reason" => "ground_station_unavailable",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0,
          "source_window_id" => "window_prior",
          "trust_boundary" => "cadence_ops"
        }
      ]
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_contact_allocation_report", report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1"
           ]

    assert [
             %{
               "id" => "leo_1_downlink_equator_prime_1",
               "suppressed_reason" => "ground_station_unavailable",
               "trust_boundary" => "cadence_ops",
               "source_station_calendar_entry" => %{
                 "source_contact_allocation" => %{
                   "contact_id" => "dl_prior_unavailable",
                   "allocation_reason" => "ground_station_unavailable"
                 }
               }
             }
           ] = artifact["contact_filter_report"]["suppressed_candidates"]

    assert %{
             "paths" => ["source_contact_allocation_report"],
             "contract" => "contact_allocation_report.v1",
             "count" => 1,
             "row_count" => 1,
             "blocked_row_count" => 1,
             "allocation_status_counts" => %{"blocked" => 1},
             "allocation_reason_counts" => %{"ground_station_unavailable" => 1},
             "station_pressure_contact_count" => 1,
             "station_pressure_ground_station_counts" => %{"equator_prime" => 1},
             "station_pressure_availability_counts" => %{"unavailable" => 1},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["cadence_ops"]
           } = get_in(artifact, ["provenance", "source_reports", "contact_allocation_report"])

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays source contact allocation reduced-capacity pressure into allocation policy" do
    report = %{
      "schema_contract" => "contact_allocation_report.v1",
      "rows" => [
        %{
          "contact_id" => "dl_prior_capacity_limited",
          "type" => "downlink",
          "direction" => "downlink",
          "allocation_status" => "blocked",
          "effective_allocation_status" => "blocked",
          "allocation_reason" => "ground_station_reduced_capacity_insufficient",
          "ground_station_id" => "equator_prime",
          "capacity_pack_capacity_fraction" => 0.4,
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0,
          "source_window_id" => "window_prior_capacity",
          "trust_boundary" => "cadence_ops"
        }
      ]
    }

    approval_policy = %{
      "action_rules" => [
        %{
          "id" => "block_replayed_reduced_capacity",
          "station_availabilities" => ["reduced_capacity"],
          "classification" => "blocked_by_policy",
          "reason" => "replayed reduced capacity requires operator review"
        }
      ]
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_contact_allocation_report", report)
          |> Map.put("approval_policy", approval_policy),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1"
           ]

    assert [allocation_row] = artifact["contact_allocation_report"]["rows"]

    assert %{
             "contact_id" => "leo_1_downlink_equator_prime_1",
             "allocation_status" => "allocated",
             "effective_allocation_status" => "policy_blocked",
             "approval_status" => "blocked_by_policy",
             "station_availability" => "reduced_capacity",
             "capacity_fraction" => 0.4,
             "trust_boundary" => "cadence_ops",
             "policy_decision" => %{"classification" => "blocked_by_policy"}
           } = allocation_row

    assert %{
             "contact_id" => "dl_prior_capacity_limited",
             "allocation_reason" => "ground_station_reduced_capacity_insufficient",
             "capacity_pack_capacity_fraction" => 0.4
           } =
             get_in(allocation_row, ["source_station_calendar_entry", "source_contact_allocation"])

    assert Enum.any?(
             allocation_row["approval_rule_matches"],
             &(&1["rule_id"] == "block_replayed_reduced_capacity" and
                 &1["classification"] == "blocked_by_policy")
           )

    assert artifact["contact_allocation_report"]["policy_blocked_allocated_contact_count"] == 1

    assert "contact allocation excluded refreshed contact candidates" in artifact["warnings"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays source contact allocation precedence station pressure into allocation policy" do
    report = %{
      "schema_contract" => "contact_allocation_report.v1",
      "rows" => [
        %{
          "contact_id" => "dl_prior_precedence_capacity_limited",
          "type" => "downlink",
          "direction" => "downlink",
          "allocation_status" => "allocated",
          "effective_allocation_status" => "allocated",
          "review_status" => "operator_review_required",
          "ground_station_id" => "equator_prime",
          "station_calendar_overlap_count" => 1,
          "station_calendar_overlap_availabilities" => ["reserved"],
          "station_calendar_precedence_availability" => "reduced_capacity",
          "station_calendar_precedence_rank" => 2,
          "capacity_pack_capacity_fraction" => 0.4,
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0,
          "source_window_id" => "window_prior_precedence_capacity",
          "trust_boundary" => "cadence_ops"
        }
      ]
    }

    approval_policy = %{
      "action_rules" => [
        %{
          "id" => "block_replayed_precedence_capacity",
          "station_availabilities" => ["reduced_capacity"],
          "classification" => "blocked_by_policy",
          "reason" => "replayed precedence capacity requires operator review"
        }
      ]
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_contact_allocation_report", report)
          |> Map.put("approval_policy", approval_policy),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [allocation_row] = artifact["contact_allocation_report"]["rows"]

    assert %{
             "contact_id" => "leo_1_downlink_equator_prime_1",
             "allocation_status" => "allocated",
             "effective_allocation_status" => "policy_blocked",
             "approval_status" => "blocked_by_policy",
             "station_availability" => "reduced_capacity",
             "capacity_fraction" => 0.4,
             "trust_boundary" => "cadence_ops",
             "policy_decision" => %{"classification" => "blocked_by_policy"},
             "source_station_calendar_entry" => %{
               "capacity_fraction" => 0.4,
               "source_contact_allocation" => %{
                 "contact_id" => "dl_prior_precedence_capacity_limited",
                 "station_calendar_overlap_availabilities" => ["reserved"],
                 "station_calendar_precedence_availability" => "reduced_capacity",
                 "station_calendar_precedence_rank" => 2
               }
             }
           } = allocation_row

    assert Enum.any?(
             allocation_row["approval_rule_matches"],
             &(&1["rule_id"] == "block_replayed_precedence_capacity" and
                 &1["classification"] == "blocked_by_policy")
           )

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays nested source contact allocation capacity-pack fractions into station feedback" do
    report = %{
      "schema_contract" => "contact_allocation_report.v1",
      "rows" => [
        %{
          "contact_id" => "dl_nested_capacity_limited",
          "type" => "downlink",
          "direction" => "downlink",
          "allocation_status" => "blocked",
          "effective_allocation_status" => "blocked",
          "allocation_reason" => "ground_station_reduced_capacity_insufficient",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0,
          "source_contact_candidate" => %{
            "contact_id" => "dl_nested_capacity_limited",
            "type" => "downlink",
            "direction" => "downlink",
            "ground_station_id" => "equator_prime",
            "capacity_pack_capacity_fraction" => 0.35
          },
          "trust_boundary" => "cadence_ops"
        }
      ]
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_contact_allocation_report", report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [allocation_row] = artifact["contact_allocation_report"]["rows"]

    assert %{
             "contact_id" => "leo_1_downlink_equator_prime_1",
             "station_availability" => "reduced_capacity",
             "capacity_fraction" => 0.35,
             "source_station_calendar_entry" => %{
               "capacity_fraction" => 0.35,
               "source_contact_allocation" => %{
                 "contact_id" => "dl_nested_capacity_limited",
                 "source_contact_candidate" => %{
                   "capacity_pack_capacity_fraction" => 0.35
                 }
               }
             }
           } = allocation_row

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
