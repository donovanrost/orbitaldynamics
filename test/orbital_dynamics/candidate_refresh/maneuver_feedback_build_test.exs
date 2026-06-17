defmodule OrbitalDynamics.CandidateRefresh.ManeuverFeedbackBuildTest do
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

  test "derives maneuver success feedback from changed maneuver failure rows in source timeline diff reports" do
    diff_report =
      Timeline.diff_report(
        [
          %{
            id: :burn_source,
            type: :impulsive_burn,
            scenario_id: :leo_1,
            spacecraft_id: :sat_1,
            maneuver_id: :burn_cleanup,
            starts_at_s: 10.0,
            ends_at_s: 40.0,
            maneuver_success_factor: 1.0,
            metadata: %{timeline_id: :"timeline:burn_changed"}
          }
        ],
        [
          %{
            id: :burn_replacement,
            type: :impulsive_burn,
            scenario_id: :leo_1,
            spacecraft_id: :sat_1,
            maneuver_id: :burn_cleanup,
            starts_at_s: 10.0,
            ends_at_s: 40.0,
            maneuver_result: :failed,
            metadata: %{timeline_id: :"timeline:burn_changed"}
          }
        ],
        source: "candidate_refresh.prior_timeline_diff"
      )
      |> update_in(["rows"], fn rows ->
        Enum.map(rows, fn row ->
          row
          |> Map.put("diff_status", "Changed")
          |> Map.put("replacement_activity_type", "Impulsive Burn")
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

    assert get_in(artifact, ["operational_feedback", "maneuver_success_rate"]) == %{
             "burn_cleanup" => 0.0
           }

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_timeline_diff_changed_maneuver_feedback_count"
           ]) == 1

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "derives maneuver feedback from source maneuver review reports" do
    report =
      maneuver_feedback_report(
        "burn_review_feedback",
        maneuver_success_factor: 0.35,
        execution_uncertainty: %{
          timing_3sigma_s: 75.0,
          delta_v_3sigma_km_s: [0.001, 0.002, 0.0],
          source: :ops_covariance
        }
      )
      |> Map.put("trust_boundary", "maneuver_ops_review")
      |> Map.put("required_operator_action_counts", %{"stale_maneuver_action" => 99})

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_maneuver_review_report", report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert get_in(artifact, ["operational_feedback", "maneuver_success_rate"]) == %{
             "burn_review_feedback" => 0.35
           }

    assert %{"burn_review_feedback" => uncertainty_feedback} =
             get_in(artifact, ["operational_feedback", "maneuver_execution_uncertainty"])

    assert uncertainty_feedback["execution_uncertainty_status"] == "declared"
    assert uncertainty_feedback["execution_uncertainty"]["timing_3sigma_s"] == 75.0

    assert uncertainty_feedback["execution_uncertainty"]["delta_v_3sigma_km_s"] == [
             0.001,
             0.002,
             0.0
           ]

    assert uncertainty_feedback["execution_uncertainty"]["source"] == "ops_covariance"
    assert uncertainty_feedback["timing_3sigma_s"] == 75.0
    assert uncertainty_feedback["delta_v_3sigma_km_s"] == [0.001, 0.002, 0.0]
    assert uncertainty_feedback["execution_uncertainty_source"] == "ops_covariance"

    assert_in_delta uncertainty_feedback["delta_v_3sigma_magnitude_km_s"],
                    0.00223606797749979,
                    1.0e-15

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "derived_from_source_maneuver_review_report"
           ])

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_maneuver_review_report_paths"
           ]) == ["source_maneuver_review_report"]

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_maneuver_review_success_feedback_count"
           ]) == 1

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_maneuver_review_execution_uncertainty_declared_count"
           ]) == 1

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_maneuver_review_trust_boundaries"
           ]) == ["maneuver_ops_review"]

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_maneuver_review_required_operator_action_counts"
           ]) == %{"review_maneuver_recommendation" => 1}

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays maneuver feedback rows from operator review packages" do
    report = maneuver_feedback_report("burn_review_package", maneuver_success_factor: 0.45)
    package = OperatorReview.from_maneuver_review_report(report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_operator_review_package", package),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert get_in(artifact, ["operational_feedback", "maneuver_success_rate"]) == %{
             "burn_review_package" => 0.45
           }

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_maneuver_review_report_paths"
           ]) == ["source_operator_review_package.rows.source_maneuver_review"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays maneuver feedback rows from Cadence import manifests" do
    report =
      maneuver_feedback_report(
        "burn_review_import",
        maneuver_success_factor: 0.2,
        execution_uncertainty: nil
      )

    manifest = CadenceImport.from_maneuver_review_report(report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_cadence_import_manifest", manifest),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert get_in(artifact, ["operational_feedback", "maneuver_success_rate"]) == %{
             "burn_review_import" => 0.2
           }

    assert get_in(artifact, ["operational_feedback", "maneuver_execution_uncertainty"]) == %{
             "burn_review_import" => %{"execution_uncertainty_status" => "missing"}
           }

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_maneuver_review_report_paths"
           ]) == ["source_cadence_import_manifest.rows.source_maneuver_review"]

    assert get_in(artifact, [
             "provenance",
             "operational_feedback",
             "source_maneuver_review_execution_uncertainty_missing_count"
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

  defp maneuver_feedback_report(maneuver_id, opts) do
    recommendation =
      %{
        id: maneuver_id,
        scenario_id: :leo_1,
        type: :impulsive_burn,
        epoch_s: 120.0,
        frame: :eci_j2000,
        delta_v_km_s: [0.001, 0.002, 0.0],
        delta_v_magnitude_km_s: 0.00223606797749979,
        maneuver_model: :impulsive_burns,
        maneuver_success_factor: Keyword.fetch!(opts, :maneuver_success_factor),
        maneuver_success_factor_source: :maneuver_review_feedback
      }

    recommendation =
      case Keyword.get(opts, :execution_uncertainty, :not_provided) do
        :not_provided -> recommendation
        nil -> recommendation
        uncertainty -> Map.put(recommendation, :execution_uncertainty, uncertainty)
      end

    OrbitalDynamics.maneuver_review_report([recommendation])
  end
end
