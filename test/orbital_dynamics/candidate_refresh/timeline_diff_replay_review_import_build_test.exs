defmodule OrbitalDynamics.CandidateRefresh.TimelineDiffReplayReviewImportBuildTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CadenceImport,
    CandidateRefresh,
    Epoch,
    OperatorReview,
    ResultSet,
    Schema,
    Timeline
  }

  test "replays timeline diff rows from operator review packages" do
    diff_report =
      Timeline.diff_report(
        [
          %{
            id: :dl_source,
            type: :downlink,
            scenario_id: :leo_1,
            spacecraft_id: :leo_1,
            ground_station_id: :equator_prime,
            direction: :downlink,
            starts_at_s: 10.0,
            ends_at_s: 40.0,
            required_downlink_mb: 420.0,
            selected_downlink_mb: 420.0,
            metadata: %{timeline_id: :"timeline:review_dl_changed"}
          }
        ],
        [
          %{
            id: :dl_replacement,
            type: :downlink,
            scenario_id: :leo_1,
            spacecraft_id: :leo_1,
            ground_station_id: :equator_prime,
            direction: :downlink,
            starts_at_s: 10.0,
            ends_at_s: 40.0,
            required_downlink_mb: 420.0,
            selected_downlink_mb: 300.0,
            metadata: %{timeline_id: :"timeline:review_dl_changed"}
          }
        ],
        source: "candidate_refresh.prior_timeline_diff"
      )

    package = OperatorReview.from_timeline_diff_report(diff_report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_operator_review_package", package),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 120.0

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_timeline_diff_report_paths"
           ]) == ["source_operator_review_package.rows.source_timeline_diff"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays timeline transition applications from review and import source rows" do
    report =
      Timeline.transition_application_report(
        [
          %{
            id: :cmd_source_review_import,
            type: :command,
            scenario_id: :leo_1,
            spacecraft_id: :sat_1,
            direction: :uplink,
            command_window_id: :cmd_transition_review_import,
            starts_at_s: 10.0,
            ends_at_s: 40.0,
            command_success_factor: 1.0,
            metadata: %{timeline_id: :"timeline:transition_review_import"}
          }
        ],
        [
          %{
            id: :cmd_replacement_review_import,
            type: :command,
            scenario_id: :leo_1,
            spacecraft_id: :sat_1,
            direction: :uplink,
            command_window_id: :cmd_transition_review_import,
            starts_at_s: 10.0,
            ends_at_s: 40.0,
            command_result: :failed,
            metadata: %{timeline_id: :"timeline:transition_review_import"}
          }
        ],
        source: "candidate_refresh.prior_transition_application_review_import"
      )
      |> update_in(["applications"], fn [application] ->
        [
          Map.merge(application, %{
            "timeline_identity_collision" => true,
            "duplicate_timeline_identity_scope" => "source",
            "source_duplicate_activity_count" => 2,
            "replacement_duplicate_activity_count" => 1,
            "source_duplicate_activity_ids" => [
              "cmd_source_review_import",
              "cmd_source_review_import_shadow"
            ],
            "replacement_duplicate_activity_ids" => ["cmd_replacement_review_import"]
          })
        ]
      end)

    review = OperatorReview.from_timeline_transition_application_report(report)
    manifest = CadenceImport.from_timeline_transition_application_report(report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_operator_review_package", review)
          |> Map.put("source_cadence_import_manifest", manifest),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_transition_review_import" => 0.0
           }

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_timeline_diff_report_paths"
           ]) == [
             "source_operator_review_package.rows.source_timeline_application",
             "source_cadence_import_manifest.rows.source_review_row.source_timeline_application"
           ]

    assert %{
             "row_count" => 2,
             "changed_command_feedback_count" => 2,
             "duplicate_timeline_identity_count" => 2,
             "duplicate_source_timeline_identity_count" => 2,
             "duplicate_replacement_timeline_identity_count" => 0,
             "duplicate_timeline_identity_scope_counts" => %{"source" => 2}
           } = get_in(artifact, ["provenance", "source_reports", "timeline_diff_report"])

    assert %{
             "paths" => [
               "source_operator_review_package.rows.source_timeline_application",
               "source_cadence_import_manifest.rows.source_review_row.source_timeline_application"
             ],
             "contract" => "timeline_transition_application_report.v1",
             "count" => 2,
             "application_count" => 2,
             "selected_activity_count" => 0,
             "review_required_count" => 2,
             "preserved_source_count" => 0,
             "recorded_replacement_count" => 0,
             "withheld_review_count" => 2,
             "duplicate_timeline_identity_count" => 2,
             "duplicate_source_timeline_identity_count" => 2,
             "duplicate_replacement_timeline_identity_count" => 0,
             "application_status_counts" => %{"operator_review_required" => 2},
             "transition_decision_counts" => %{"review" => 2},
             "required_operator_action_counts" => %{"review_timeline_change" => 2},
             "duplicate_timeline_identity_scope_counts" => %{"source" => 2}
           } =
             get_in(artifact, [
               "provenance",
               "source_reports",
               "timeline_transition_application_report"
             ])

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays timeline diff rows from Cadence import manifests" do
    diff_report =
      Timeline.diff_report(
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
            metadata: %{timeline_id: :"timeline:import_cmd_changed"}
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
            metadata: %{timeline_id: :"timeline:import_cmd_changed"}
          }
        ],
        source: "candidate_refresh.prior_timeline_diff"
      )

    manifest = CadenceImport.from_timeline_diff_report(diff_report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_cadence_import_manifest", manifest),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_health_1" => 0.0
           }

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_timeline_diff_report_paths"
           ]) == ["source_cadence_import_manifest.rows.source_timeline_diff"]

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
