defmodule OrbitalDynamics.CandidateRefresh.CandidateDiffBuildTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CandidateRefresh, Epoch, ResultSet, Schema}

  test "records candidates retained across refreshes" do
    refresh =
      update_in(refresh_request(), ["prior_candidate_activities"], fn prior ->
        [
          %{
            "id" => "leo_1_observe_target_a_1",
            "type" => "observe",
            "scenario_id" => "leo_1",
            "starts_at_s" => 120.0,
            "ends_at_s" => 240.0,
            "source_window_id" => "window:leo_1:target_visibility:target_a:1"
          }
          | prior
        ]
      end)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "prior_candidate_count" => 2,
             "retained_candidate_count" => 1,
             "new_candidate_count" => 1,
             "invalidated_candidate_count" => 1,
             "retained_candidates" => [
               %{
                 "id" => "leo_1_observe_target_a_1",
                 "diff_reason" => "present_in_prior_candidate_set"
               }
             ]
           } = artifact["candidate_diff_report"]

    assert Enum.map(artifact["candidate_diff_report"]["new_candidates"], & &1["id"]) == [
             "leo_1_downlink_equator_prime_1"
           ]
  end

  test "candidate diff accepts activity-type-only prior candidates" do
    refresh =
      put_in(refresh_request(), ["prior_candidate_activities"], [
        %{
          "id" => "leo_1_observe_target_a_1",
          "activity_type" => "observe",
          "scenario_id" => "leo_1",
          "target_id" => "target_a",
          "starts_at_s" => 120.0,
          "ends_at_s" => 240.0,
          "source_window_id" => "window:leo_1:target_visibility:target_a:1"
        },
        %{
          "id" => "blank_activity_type_prior",
          "activity_type" => "",
          "scenario_id" => "leo_1",
          "starts_at_s" => 10.0,
          "ends_at_s" => 20.0
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "prior_candidate_count" => 2,
             "valid_prior_candidate_count" => 1,
             "invalid_prior_candidate_input_count" => 1,
             "invalid_prior_candidate_input_ids" => ["blank_activity_type_prior"]
           } = artifact["candidate_diff_report"]

    assert [
             %{
               "id" => "leo_1_observe_target_a_1",
               "type" => "observe",
               "diff_reason" => "present_in_prior_candidate_set",
               "matched_prior_candidate_id" => "leo_1_observe_target_a_1"
             }
           ] = artifact["candidate_diff_report"]["retained_candidates"]

    assert [
             %{
               "id" => "blank_activity_type_prior",
               "invalidated_reason" => "invalid_prior_candidate_input",
               "invalid_prior_candidate_input_reason" => "missing_candidate_type"
             }
           ] = artifact["candidate_diff_report"]["invalidated_candidates"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "candidate diff retains station-id-only provider downlink prior candidates" do
    refresh =
      put_in(refresh_request(), ["prior_candidate_activities"], [
        %{
          "id" => "leo_1_downlink_equator_prime_1",
          "type" => "contact",
          "direction" => "downlink",
          "scenario_id" => "leo_1",
          "station_id" => "equator_prime",
          "starts_at_s" => 300.0,
          "ends_at_s" => 420.0,
          "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1"
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [
             %{
               "id" => "leo_1_downlink_equator_prime_1",
               "type" => "downlink",
               "diff_reason" => "present_in_prior_candidate_set",
               "matched_prior_candidate_id" => "leo_1_downlink_equator_prime_1"
             }
           ] = artifact["candidate_diff_report"]["retained_candidates"]

    refute Map.has_key?(
             List.first(artifact["candidate_diff_report"]["retained_candidates"]),
             "semantic_change_reasons"
           )

    assert artifact["candidate_diff_report"]["invalidated_candidates"] == []

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "candidate diff retains provider downlink prior candidates with nested station identity" do
    refresh =
      put_in(refresh_request(), ["prior_candidate_activities"], [
        %{
          "id" => "leo_1_downlink_equator_prime_1",
          "type" => "contact",
          "direction" => "downlink",
          "scenario_id" => "leo_1",
          "ground_station" => %{"ground_station_id" => "equator_prime"},
          "starts_at_s" => 300.0,
          "ends_at_s" => 420.0,
          "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1"
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [
             %{
               "id" => "leo_1_downlink_equator_prime_1",
               "type" => "downlink",
               "diff_reason" => "present_in_prior_candidate_set",
               "matched_prior_candidate_id" => "leo_1_downlink_equator_prime_1"
             }
           ] = artifact["candidate_diff_report"]["retained_candidates"]

    assert artifact["candidate_diff_report"]["invalidated_candidates"] == []

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "candidate diff records provider-calendar identity changes for retained downlinks" do
    refresh =
      refresh_request()
      |> Map.put("station_calendar_provider", %{
        "schema_contract" => "station_calendar_provider.v1",
        "provider_id" => "ground_partner_a",
        "trust_boundary" => "ground_partner_api",
        "entries" => [
          %{
            "id" => "partner_capacity_downlink",
            "ground_station_id" => "equator_prime",
            "status" => "reduced_capacity",
            "capacity_fraction" => 0.5,
            "directions" => ["downlink"],
            "starts_at_s" => 250.0,
            "ends_at_s" => 450.0
          }
        ]
      })
      |> Map.put("prior_candidate_activities", [
        %{
          "id" => "leo_1_downlink_equator_prime_1",
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 300.0,
          "ends_at_s" => 420.0,
          "estimated_throughput_mb" => 180.0,
          "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
          "station_calendar_entry_id" => "old_partner_capacity",
          "station_calendar_provider_id" => "ground_partner_old",
          "station_calendar_provider_entry_id" => "old_partner_capacity"
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [downlink] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["station_calendar_entry_id"] == "partner_capacity_downlink"
    assert downlink["station_calendar_provider_id"] == "ground_partner_a"
    assert downlink["station_calendar_provider_entry_id"] == "partner_capacity_downlink"
    assert downlink["estimated_throughput_mb"] == 180.0

    assert [
             %{
               "id" => "leo_1_downlink_equator_prime_1",
               "diff_reason" => "present_in_prior_candidate_set_with_semantic_changes",
               "semantic_change_reasons" => semantic_change_reasons
             }
           ] = artifact["candidate_diff_report"]["retained_candidates"]

    assert "station_calendar_entry_id_changed" in semantic_change_reasons
    assert "station_calendar_provider_id_changed" in semantic_change_reasons
    assert "station_calendar_provider_entry_id_changed" in semantic_change_reasons
    refute "estimated_throughput_mb_changed" in semantic_change_reasons

    assert artifact["candidate_diff_report"]["invalidated_candidates"] == []

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "candidate diff rejects malformed provider-calendar prior candidate identity" do
    refresh =
      put_in(refresh_request(), ["prior_candidate_activities"], [
        %{
          "id" => "leo_1_downlink_equator_prime_1",
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 300.0,
          "ends_at_s" => 420.0,
          "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
          "station_calendar_provider_id" => "bad id"
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "prior_candidate_count" => 1,
             "valid_prior_candidate_count" => 0,
             "invalid_prior_candidate_input_count" => 1
           } = artifact["candidate_diff_report"]

    assert [
             %{
               "id" => "leo_1_downlink_equator_prime_1",
               "invalidated_reason" => "invalid_prior_candidate_input",
               "invalid_prior_candidate_input_reason" => "invalid_station_calendar_provider_id"
             }
           ] = artifact["candidate_diff_report"]["invalidated_candidates"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "candidate diff retains no-type provider station-time prior candidates" do
    refresh =
      put_in(refresh_request(), ["prior_candidate_activities"], [
        %{
          "id" => "leo_1_downlink_equator_prime_1",
          "scenario_id" => "leo_1",
          "station_id" => "equator_prime",
          "start_s" => 300.0,
          "end_s" => 420.0,
          "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1"
        },
        %{
          "id" => "provider_command_status_without_type",
          "scenario_id" => "leo_1",
          "station_id" => "equator_prime",
          "start_s" => 300.0,
          "end_s" => 420.0,
          "command_result" => "failed"
        },
        %{
          "id" => "prior_direction_only_command",
          "scenario_id" => "leo_1",
          "station_id" => "equator_prime",
          "direction" => "s-band command",
          "start_s" => 430.0,
          "end_s" => 440.0
        },
        %{
          "id" => "prior_direction_only_health_check",
          "scenario_id" => "leo_1",
          "station_id" => "equator_prime",
          "direction" => "health_check",
          "start_s" => 450.0,
          "end_s" => 455.0
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "prior_candidate_count" => 4,
             "valid_prior_candidate_count" => 3,
             "invalid_prior_candidate_input_count" => 1,
             "invalid_prior_candidate_input_ids" => ["provider_command_status_without_type"]
           } = artifact["candidate_diff_report"]

    assert [
             %{
               "id" => "leo_1_downlink_equator_prime_1",
               "type" => "downlink",
               "starts_at_s" => 300.0,
               "ends_at_s" => 420.0,
               "diff_reason" => "present_in_prior_candidate_set",
               "matched_prior_candidate_id" => "leo_1_downlink_equator_prime_1"
             }
           ] = artifact["candidate_diff_report"]["retained_candidates"]

    assert %{
             "id" => "provider_command_status_without_type",
             "invalidated_reason" => "invalid_prior_candidate_input",
             "invalid_prior_candidate_input" => true,
             "invalid_prior_candidate_input_reason" => "missing_candidate_type"
           } =
             Enum.find(
               artifact["candidate_diff_report"]["invalidated_candidates"],
               &(&1["id"] == "provider_command_status_without_type")
             )

    assert %{
             "id" => "prior_direction_only_command",
             "type" => "planned_contact",
             "direction" => "command",
             "scenario_id" => "leo_1",
             "starts_at_s" => 430.0,
             "ends_at_s" => 440.0,
             "invalidated_reason" => "not_present_in_refreshed_candidate_set"
           } =
             Enum.find(
               artifact["candidate_diff_report"]["invalidated_candidates"],
               &(&1["id"] == "prior_direction_only_command")
             )

    assert %{
             "id" => "prior_direction_only_health_check",
             "type" => "health_check",
             "scenario_id" => "leo_1",
             "starts_at_s" => 450.0,
             "ends_at_s" => 455.0,
             "invalidated_reason" => "not_present_in_refreshed_candidate_set"
           } =
             Enum.find(
               artifact["candidate_diff_report"]["invalidated_candidates"],
               &(&1["id"] == "prior_direction_only_health_check")
             )

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
