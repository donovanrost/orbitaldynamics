defmodule OrbitalDynamics.CandidateRefresh.TimelineDiffFeedbackBuildTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CandidateRefresh, Epoch, ResultSet, Schema, Timeline}

  test "derives downlink demand from removed downlink rows in a source timeline diff report" do
    diff_report =
      Timeline.diff_report(
        [
          %{
            id: :dl_removed,
            type: :downlink,
            scenario_id: :leo_1,
            spacecraft_id: :leo_1,
            ground_station_id: :equator_prime,
            direction: :downlink,
            starts_at_s: 10.0,
            ends_at_s: 40.0,
            required_downlink_mb: 360.0,
            metadata: %{timeline_id: :"timeline:dl_removed"},
            provenance: %{trust_boundary: :cadence_plan_delta_archive}
          }
        ],
        [],
        source: "candidate_refresh.prior_timeline_diff"
      )
      |> Map.put("diff_status_counts", %{"stale_diff_status" => 99})
      |> Map.put("required_operator_action_counts", %{"stale_required_action" => 99})

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_timeline_diff_report", diff_report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 360.0

    assert downlink["downlink_completion_sources"] == [
             "timeline_diff.removed.required_downlink_mb:dl_removed"
           ]

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{
             "equator_prime" => 360.0
           }

    assert get_in(artifact, ["operational_feedback", "downlink_demand_context", "equator_prime"]) ==
             %{
               "source" => "timeline_diff_report.rows",
               "source_activity_id" => "dl_removed",
               "source_activity_type" => "downlink",
               "source_diff_status" => "removed",
               "source_reason" => "replacement timeline removes activity dl_removed",
               "source_required_operator_action" => "review_removed_activity",
               "source_timeline_id" => "timeline:dl_removed"
             }

    assert get_in(artifact, ["operational_feedback", "trust_boundary"]) ==
             "cadence_plan_delta_archive"

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "derived_from_source_timeline_diff_report"
           ])

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_timeline_diff_report_paths"
           ]) == ["source_timeline_diff_report"]

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_timeline_diff_removed_downlink_count"
           ]) == 1

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_timeline_diff_status_counts"
           ]) == %{"removed" => 1}

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_timeline_diff_required_operator_action_counts"
           ]) == %{"review_removed_activity" => 1}

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "derives downlink demand from changed downlink shortfall rows in source timeline diff reports" do
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
            required_downlink_mb: 500.0,
            selected_downlink_mb: 500.0,
            metadata: %{timeline_id: :"timeline:dl_changed"}
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
            starts_at_s: 12.0,
            ends_at_s: 38.0,
            required_downlink_mb: 500.0,
            selected_downlink_mb: 300.0,
            metadata: %{timeline_id: :"timeline:dl_changed"}
          }
        ],
        source: "candidate_refresh.prior_timeline_diff"
      )
      |> update_in(["rows"], fn rows ->
        Enum.map(rows, fn row ->
          row
          |> Map.put("diff_status", "Changed")
          |> Map.put("replacement_activity_type", "Contact")
          |> Map.put("replacement_direction", "Down Link")
        end)
      end)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_timeline_diff_report", diff_report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 200.0

    assert downlink["downlink_completion_sources"] == [
             "timeline_diff.changed.downlink_shortfall_mb:dl_source:dl_replacement"
           ]

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{
             "equator_prime" => 200.0
           }

    assert get_in(artifact, ["operational_feedback", "downlink_demand_context", "equator_prime"]) ==
             %{
               "planned_downlink_mb" => 300.0,
               "replacement_activity_id" => "dl_replacement",
               "replacement_activity_type" => "Contact",
               "replacement_ends_at_s" => 38.0,
               "replacement_starts_at_s" => 12.0,
               "required_downlink_mb" => 500.0,
               "selected_downlink_shortfall_mb" => 200.0,
               "source" => "timeline_diff_report.rows",
               "source_activity_id" => "dl_source",
               "source_activity_type" => "downlink",
               "source_changed_fields" => [
                 "activity_id",
                 "ends_at_s",
                 "selected_downlink_mb",
                 "starts_at_s"
               ],
               "source_diff_status" => "changed",
               "source_ends_at_s" => 40.0,
               "source_reason" =>
                 "timeline activity dl_source changes to dl_replacement: activity_id,starts_at_s,ends_at_s,selected_downlink_mb",
               "source_required_operator_action" => "review_timeline_change",
               "source_starts_at_s" => 10.0,
               "source_timeline_id" => "timeline:dl_changed"
             }

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_timeline_diff_changed_downlink_shortfall_count"
           ]) == 1

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "derives contact success feedback from changed contact failure rows in source timeline diff reports" do
    diff_report =
      Timeline.diff_report(
        [
          %{
            id: :contact_source,
            type: :downlink,
            scenario_id: :leo_1,
            spacecraft_id: :leo_1,
            ground_station_id: :equator_prime,
            direction: :downlink,
            starts_at_s: 10.0,
            ends_at_s: 40.0,
            contact_success_factor: 1.0,
            metadata: %{timeline_id: :"timeline:contact_changed"}
          }
        ],
        [
          %{
            id: :contact_replacement,
            type: :downlink,
            scenario_id: :leo_1,
            spacecraft_id: :leo_1,
            ground_station_id: :equator_prime,
            direction: :downlink,
            starts_at_s: 10.0,
            ends_at_s: 40.0,
            contact_result: :failed,
            metadata: %{timeline_id: :"timeline:contact_changed"}
          }
        ],
        source: "candidate_refresh.prior_timeline_diff"
      )
      |> update_in(["rows"], fn rows ->
        Enum.map(rows, fn row ->
          row
          |> Map.put("diff_status", "Changed")
          |> Map.put("replacement_activity_type", "Tracking")
        end)
      end)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_timeline_diff_report", diff_report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["contact_success_factor"] == 0.0

    assert downlink["contact_success_factor_source"] ==
             "operational_feedback.contact_success_rate.station"

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 0.0
           }

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_timeline_diff_changed_contact_feedback_count"
           ]) == 1

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
