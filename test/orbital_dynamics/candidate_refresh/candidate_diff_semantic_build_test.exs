defmodule OrbitalDynamics.CandidateRefresh.CandidateDiffSemanticBuildTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CandidateRefresh, Epoch, ResultSet, Schema}

  test "records semantic changes for retained candidate ids" do
    refresh =
      update_in(refresh_request(), ["prior_candidate_activities"], fn prior ->
        [
          %{
            "id" => "leo_1_observe_target_a_1",
            "type" => "observe",
            "scenario_id" => "leo_1",
            "target_id" => "target_a",
            "starts_at_s" => 100.0,
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

    assert [
             %{
               "id" => "leo_1_observe_target_a_1",
               "diff_reason" => "present_in_prior_candidate_set_with_semantic_changes",
               "matched_prior_candidate_id" => "leo_1_observe_target_a_1",
               "semantic_change_reasons" => ["starts_at_s_changed"]
             }
           ] = artifact["candidate_diff_report"]["retained_candidates"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "matches semantically similar new and invalidated candidates" do
    refresh =
      put_in(refresh_request(), ["prior_candidate_activities"], [
        %{
          "id" => "ops_observe_target_a_shift_1",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "target_id" => "target_a",
          "starts_at_s" => 90.0,
          "ends_at_s" => 210.0,
          "source_window_id" => "operator-window-target-a-previous"
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "id" => "leo_1_observe_target_a_1",
             "diff_reason" => "semantically_similar_prior_candidate_changed",
             "matched_prior_candidate_id" => "ops_observe_target_a_shift_1",
             "semantic_change_reasons" => [
               "starts_at_s_changed",
               "ends_at_s_changed",
               "source_window_id_changed"
             ]
           } =
             Enum.find(
               artifact["candidate_diff_report"]["new_candidates"],
               &(&1["id"] == "leo_1_observe_target_a_1")
             )

    assert [
             %{
               "id" => "ops_observe_target_a_shift_1",
               "invalidated_reason" => "replaced_by_semantically_similar_candidate",
               "replacement_candidate_id" => "leo_1_observe_target_a_1",
               "semantic_change_reasons" => [
                 "starts_at_s_changed",
                 "ends_at_s_changed",
                 "source_window_id_changed"
               ]
             }
           ] = artifact["invalidated_candidates"]

    assert artifact["candidate_diff_report"]["invalidated_candidates"] ==
             artifact["invalidated_candidates"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "candidate diff semantically matches station-id-only provider prior contacts" do
    refresh =
      put_in(refresh_request(), ["prior_candidate_activities"], [
        %{
          "id" => "ops_provider_downlink_previous",
          "type" => "contact",
          "direction" => "Down Link",
          "scenario_id" => "leo_1",
          "station" => %{"id" => "equator_prime"},
          "start_s" => "290.0",
          "end_s" => "410.0",
          "source_window_id" => "provider-window-equator-prime-previous"
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "id" => "leo_1_downlink_equator_prime_1",
             "diff_reason" => "semantically_similar_prior_candidate_changed",
             "matched_prior_candidate_id" => "ops_provider_downlink_previous",
             "semantic_change_reasons" => [
               "starts_at_s_changed",
               "ends_at_s_changed",
               "source_window_id_changed"
             ]
           } =
             Enum.find(
               artifact["candidate_diff_report"]["new_candidates"],
               &(&1["id"] == "leo_1_downlink_equator_prime_1")
             )

    assert [
             %{
               "id" => "ops_provider_downlink_previous",
               "type" => "downlink",
               "invalidated_reason" => "replaced_by_semantically_similar_candidate",
               "replacement_candidate_id" => "leo_1_downlink_equator_prime_1",
               "semantic_change_reasons" => [
                 "starts_at_s_changed",
                 "ends_at_s_changed",
                 "source_window_id_changed"
               ]
             }
           ] = artifact["invalidated_candidates"]

    assert artifact["candidate_diff_report"]["invalidated_candidates"] ==
             artifact["invalidated_candidates"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "marks ambiguous semantic prior matches without choosing an arbitrary candidate" do
    refresh =
      put_in(refresh_request(), ["prior_candidate_activities"], [
        %{
          "id" => "ops_observe_target_a_shift_1",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "target_id" => "target_a",
          "starts_at_s" => 90.0,
          "ends_at_s" => 210.0,
          "source_window_id" => "operator-window-target-a-previous-1"
        },
        %{
          "id" => "ops_observe_target_a_shift_2",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "target_id" => "target_a",
          "starts_at_s" => 100.0,
          "ends_at_s" => 220.0,
          "source_window_id" => "operator-window-target-a-previous-2"
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "id" => "leo_1_observe_target_a_1",
             "diff_reason" => "ambiguous_semantic_prior_candidate_match",
             "semantic_match_status" => "ambiguous_prior_candidate",
             "semantic_match_candidate_count" => 2,
             "semantic_match_candidate_ids" => [
               "ops_observe_target_a_shift_1",
               "ops_observe_target_a_shift_2"
             ]
           } =
             Enum.find(
               artifact["candidate_diff_report"]["new_candidates"],
               &(&1["id"] == "leo_1_observe_target_a_1")
             )

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "marks ambiguous semantic replacement matches without choosing an arbitrary candidate" do
    refresh =
      put_in(refresh_request(), ["prior_candidate_activities"], [
        %{
          "id" => "ops_observe_target_a_shift_1",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "target_id" => "target_a",
          "starts_at_s" => 90.0,
          "ends_at_s" => 210.0,
          "source_window_id" => "operator-window-target-a-previous"
        }
      ])

    artifact =
      result_set_with_duplicate_target_visibility()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [
             %{
               "id" => "ops_observe_target_a_shift_1",
               "invalidated_reason" => "ambiguous_semantic_replacement_candidate",
               "semantic_match_status" => "ambiguous_replacement_candidate",
               "semantic_match_candidate_count" => 2,
               "semantic_match_candidate_ids" => [
                 "leo_1_observe_target_a_1",
                 "leo_1_observe_target_a_2"
               ]
             }
           ] = artifact["invalidated_candidates"]

    refute Map.has_key?(
             List.first(artifact["invalidated_candidates"]),
             "replacement_candidate_id"
           )

    assert artifact["candidate_diff_report"]["invalidated_candidates"] ==
             artifact["invalidated_candidates"]

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

  defp result_set_with_duplicate_target_visibility do
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
                sample_count: 3
              }
            },
            %{
              type: :target_visibility,
              starts_at: Epoch.new!(300.0, :tdb),
              ends_at: Epoch.new!(420.0, :tdb),
              metadata: %{
                target_id: :target_a,
                target_priority: 1.0,
                max_elevation_deg: 75.0,
                minimum_elevation_deg: 12.0,
                sample_count: 3
              }
            }
          ],
          source: %{target_id: :target_a}
        }
      ],
      errors: [],
      assumptions: %{propagator: OrbitalDynamics.Propagators.TwoBody, outputs: [:visibility]},
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
