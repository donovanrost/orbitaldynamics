defmodule OrbitalDynamics.CandidateRefresh.TimelineDiffReplayBuildTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CandidateRefresh,
    Epoch,
    ResultSet,
    Schema,
    Timeline
  }

  test "replays timeline diff rows from timeline transition application reports" do
    report =
      Timeline.transition_application_report(
        [
          %{
            id: :cmd_source,
            type: :command,
            scenario_id: :leo_1,
            spacecraft_id: :sat_1,
            direction: :uplink,
            command_window_id: :cmd_health_1,
            starts_at_s: 10.0,
            ends_at_s: 40.0,
            command_success_factor: 1.0,
            metadata: %{timeline_id: :"timeline:transition_cmd_changed"}
          }
        ],
        [
          %{
            id: :cmd_replacement,
            type: :command,
            scenario_id: :leo_1,
            spacecraft_id: :sat_1,
            direction: :uplink,
            command_window_id: :cmd_health_1,
            starts_at_s: 10.0,
            ends_at_s: 40.0,
            command_result: :failed,
            metadata: %{timeline_id: :"timeline:transition_cmd_changed"}
          }
        ],
        source: "candidate_refresh.prior_transition_application"
      )
      |> Map.put("provenance", %{"trust_boundary" => "ops_transition_application"})

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_timeline_transition_application_report", report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_health_1" => 0.0
           }

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_timeline_diff_report_paths"
           ]) == [
             "source_timeline_transition_application_report.applications.source_timeline_diff"
           ]

    assert %{
             "paths" => ["source_timeline_transition_application_report"],
             "contract" => "timeline_transition_application_report.v1",
             "count" => 1,
             "application_count" => 1,
             "selected_activity_count" => 0,
             "review_required_count" => 1,
             "preserved_source_count" => 0,
             "recorded_replacement_count" => 0,
             "withheld_review_count" => 1,
             "application_status_counts" => %{"operator_review_required" => 1},
             "transition_decision_counts" => %{"review" => 1},
             "required_operator_action_counts" => %{"review_timeline_change" => 1},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["ops_transition_application"]
           } =
             get_in(artifact, [
               "provenance",
               "source_reports",
               "timeline_transition_application_report"
             ])

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "summarizes duplicate timeline identity replay from transition application rows" do
    report =
      %{
        "schema_contract" => "timeline_transition_application_report.v1",
        "model" => "artifact_only_timeline_transition_application",
        "provenance" => %{"trust_boundary" => "ops_transition_application"},
        "applications" => [
          %{
            "id" => "timeline_application:timeline:cmd_duplicate",
            "rank" => 1,
            "timeline_id" => "timeline:cmd_duplicate",
            "diff_status" => "changed",
            "changed_fields" => ["timeline_identity_collision"],
            "transition_decision" => "review",
            "requires_operator_review" => true,
            "required_operator_action" => "review_duplicate_timeline_identity",
            "reason" => "duplicate identity requires review",
            "application_status" => "operator_review_required",
            "timeline_identity_collision" => true,
            "duplicate_timeline_identity_scope" => "source",
            "source_duplicate_activity_count" => 2,
            "replacement_duplicate_activity_count" => 1,
            "source_duplicate_activity_ids" => ["cmd_source_a", "cmd_source_b"],
            "replacement_duplicate_activity_ids" => ["cmd_replacement"],
            "source_timeline_diff" => %{
              "id" => "timeline_diff:timeline:cmd_duplicate",
              "rank" => 1,
              "timeline_id" => "timeline:cmd_duplicate",
              "diff_status" => "changed",
              "changed_fields" => ["timeline_identity_collision"],
              "required_operator_action" => "review_duplicate_timeline_identity"
            }
          }
        ]
      }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_timeline_transition_application_report", report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "paths" => [
               "source_timeline_transition_application_report.applications.source_timeline_diff"
             ],
             "row_count" => 1,
             "duplicate_timeline_identity_count" => 1,
             "duplicate_source_timeline_identity_count" => 1,
             "duplicate_replacement_timeline_identity_count" => 0,
             "duplicate_timeline_identity_scope_counts" => %{"source" => 1},
             "required_operator_action_counts" => %{
               "review_duplicate_timeline_identity" => 1
             }
           } = get_in(artifact, ["provenance", "source_reports", "timeline_diff_report"])

    assert %{
             "paths" => ["source_timeline_transition_application_report"],
             "application_count" => 1,
             "duplicate_timeline_identity_count" => 1,
             "duplicate_source_timeline_identity_count" => 1,
             "duplicate_replacement_timeline_identity_count" => 0,
             "duplicate_timeline_identity_scope_counts" => %{"source" => 1}
           } =
             get_in(artifact, [
               "provenance",
               "source_reports",
               "timeline_transition_application_report"
             ])

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
