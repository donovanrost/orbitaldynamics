defmodule OrbitalDynamics.CandidateRefresh.PriorCandidateReviewTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CadenceImport,
    CandidateRefresh,
    Epoch,
    OperatorReview,
    ResultSet,
    Schema
  }

  test "preserves invalid prior candidate inputs as invalidated review evidence" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(["prior_candidate_activities"], [
            %{
              type: :observe,
              scenario_id: :leo_1,
              target_id: :target_a,
              starts_at_s: -120.0,
              ends_at_s: -60.0
            },
            %{
              id: :prior_missing_type,
              scenario_id: :leo_1,
              starts_at_s: -50.0,
              ends_at_s: -40.0
            }
          ]),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "prior_candidate_count" => 2,
             "valid_prior_candidate_count" => 0,
             "invalid_prior_candidate_input_count" => 2,
             "invalid_prior_candidate_input_ids" => [
               "invalid_prior_candidate:missing_candidate_id:1",
               "prior_missing_type"
             ],
             "invalidated_candidate_count" => 2,
             "invalidated_candidates" => [
               %{
                 "id" => "invalid_prior_candidate:missing_candidate_id:1",
                 "invalidated_reason" => "invalid_prior_candidate_input",
                 "invalid_prior_candidate_input" => true,
                 "invalid_prior_candidate_input_reason" => "missing_candidate_id",
                 "source_candidate" => %{"type" => "observe"}
               },
               %{
                 "id" => "prior_missing_type",
                 "invalidated_reason" => "invalid_prior_candidate_input",
                 "invalid_prior_candidate_input_reason" => "missing_candidate_type"
               }
             ]
           } = artifact["candidate_diff_report"]

    assert artifact["invalidated_candidates"] ==
             artifact["candidate_diff_report"]["invalidated_candidates"]

    review = OperatorReview.from_candidate_diff_report(artifact["candidate_diff_report"])

    assert %{
             "review_type" => "candidate_diff_review",
             "invalid_prior_candidate_input" => true,
             "invalid_prior_candidate_input_reason" => "missing_candidate_id",
             "source_candidate" => %{"type" => "observe"},
             "source_candidate_diff" => %{"invalid_prior_candidate_input" => true}
           } =
             Enum.find(
               review["rows"],
               &(&1["activity_id"] == "invalid_prior_candidate:missing_candidate_id:1")
             )

    manifest = CadenceImport.from_candidate_diff_report(artifact["candidate_diff_report"])

    assert %{
             "import_action" => "review_candidate_diff",
             "invalid_prior_candidate_input" => true,
             "invalid_prior_candidate_input_reason" => "missing_candidate_id",
             "source_candidate" => %{"type" => "observe"},
             "source_candidate_diff" => %{"invalid_prior_candidate_input" => true}
           } =
             Enum.find(
               manifest["rows"],
               &(&1["activity_id"] == "invalid_prior_candidate:missing_candidate_id:1")
             )

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "preserves malformed prior candidate stable identity fields for review" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(["prior_candidate_activities"], [
            %{
              id: "bad candidate id",
              type: :observe,
              scenario_id: :leo_1,
              target_id: :target_a,
              starts_at_s: -120.0,
              ends_at_s: -60.0
            },
            %{
              id: :bad_scenario,
              type: :observe,
              scenario_id: "bad scenario id",
              target_id: :target_a,
              starts_at_s: -50.0,
              ends_at_s: -40.0
            },
            %{
              id: :bad_source_window,
              type: :downlink,
              scenario_id: :leo_1,
              ground_station_id: :equator_prime,
              source_window_id: "bad source window",
              station_calendar_overlap_entry_ids: [
                :overlap_1,
                "bad overlap id",
                %{id: :overlap_2},
                %{id: "bad nested overlap id"}
              ],
              starts_at_s: -30.0,
              ends_at_s: -20.0
            }
          ]),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "invalid_prior_candidate_input_count" => 3,
             "invalid_prior_candidate_input_ids" => [
               "invalid_prior_candidate:invalid_candidate_id:1",
               "bad_scenario",
               "bad_source_window"
             ]
           } = artifact["candidate_diff_report"]

    invalidated_by_id =
      Map.new(
        artifact["candidate_diff_report"]["invalidated_candidates"],
        &{&1["id"], &1}
      )

    assert %{
             "id" => "invalid_prior_candidate:invalid_candidate_id:1",
             "scenario_id" => "leo_1",
             "invalidated_reason" => "invalid_prior_candidate_input",
             "invalid_prior_candidate_input_reason" => "invalid_candidate_id",
             "source_candidate" => %{"id" => "bad candidate id"}
           } = invalidated_by_id["invalid_prior_candidate:invalid_candidate_id:1"]

    assert %{
             "id" => "bad_scenario",
             "scenario_id" => "missing_scenario_id:bad_scenario",
             "invalid_prior_candidate_input_reason" => "invalid_scenario_id",
             "source_candidate" => %{"scenario_id" => "bad scenario id"}
           } = invalidated_by_id["bad_scenario"]

    assert %{
             "id" => "bad_source_window",
             "source_window_id" => nil,
             "station_calendar_overlap_entry_ids" => ["overlap_1", "overlap_2"],
             "invalid_prior_candidate_input_reason" => "invalid_source_window_id",
             "source_candidate" => %{
               "source_window_id" => "bad source window",
               "station_calendar_overlap_entry_ids" => source_overlap_ids
             }
           } = Map.put_new(invalidated_by_id["bad_source_window"], "source_window_id", nil)

    assert "bad overlap id" in source_overlap_ids

    review = OperatorReview.from_candidate_diff_report(artifact["candidate_diff_report"])

    assert %{
             "activity_id" => "bad_source_window",
             "invalid_prior_candidate_input" => true,
             "invalid_prior_candidate_input_reason" => "invalid_source_window_id",
             "source_candidate" => %{"source_window_id" => "bad source window"},
             "source_candidate_diff" => %{
               "station_calendar_overlap_entry_ids" => [
                 "overlap_1",
                 "overlap_2"
               ]
             }
           } = Enum.find(review["rows"], &(&1["activity_id"] == "bad_source_window"))

    manifest = CadenceImport.from_candidate_diff_report(artifact["candidate_diff_report"])

    assert %{
             "activity_id" => "bad_source_window",
             "import_action" => "review_candidate_diff",
             "invalid_prior_candidate_input" => true,
             "invalid_prior_candidate_input_reason" => "invalid_source_window_id",
             "source_candidate" => %{"source_window_id" => "bad source window"},
             "source_candidate_diff" => %{
               "station_calendar_overlap_entry_ids" => [
                 "overlap_1",
                 "overlap_2"
               ]
             }
           } = Enum.find(manifest["rows"], &(&1["activity_id"] == "bad_source_window"))

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
