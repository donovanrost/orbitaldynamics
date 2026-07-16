defmodule OrbitalDynamics.CandidateRefresh.ObjectiveReplayBuildTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CadenceImport,
    CandidateRefresh,
    Epoch,
    OperatorReview,
    ResultSet,
    Schema
  }

  test "derives downlink completion objectives from source objective satisfaction reports" do
    report = %{
      "schema_contract" => "objective_satisfaction_report.v1",
      "rows" => [
        %{
          "id" => "objective:downlink_completion:ignored",
          "objective" => "downlink_completion",
          "status" => "selected",
          "ground_station_id" => "equator_prime",
          "required_downlink_mb" => 900.0
        },
        %{
          "id" => "objective:downlink_completion:gap",
          "objective" => "downlink completion",
          "satisfaction_status" => "below target",
          "ground_station_id" => "equator_prime",
          "required_downlink_mb" => 720.0,
          "selected_downlink_mb" => 120.0
        }
      ]
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_objective_satisfaction_report", report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 720.0
    assert downlink["candidate_downlink_mb"] == 360.0
    assert downlink["selected_downlink_shortfall_mb"] == 360.0

    assert downlink["downlink_completion_source"] ==
             "candidate_refresh.objectives.downlink_completion"

    assert downlink["score_terms"]["downlink_completion_value"] == 25.0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays objective satisfaction rows from operator review packages" do
    report = %{
      "schema_contract" => "objective_satisfaction_report.v1",
      "rows" => [
        %{
          "id" => "objective:target_coverage:target_a",
          "objective" => "target_coverage",
          "status" => "no candidate window",
          "target_id" => "target_a",
          "required_count" => 2,
          "selected_count" => 0
        }
      ]
    }

    package = OperatorReview.from_objective_satisfaction_report(report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_operator_review_package", package),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    observe = Enum.find(artifact["candidate_activities"], &(&1["type"] == "observe"))

    assert %{
             "observation_objective_count" => 1,
             "observation_objective_ids" => [objective_id],
             "observation_objective_types" => ["target_coverage"],
             "required_observations" => 2.0,
             "score_terms" => %{"observation_objective_value" => 50.0}
           } = observe

    assert String.starts_with?(
             objective_id,
             "objective_satisfaction:target_coverage:target_a:"
           )

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "derives downlink completion objectives from routed source score term reports" do
    report = %{
      "schema_contract" => "score_term_report.v1",
      "rows" => [
        %{
          "id" => "score:ignored",
          "scenario_id" => "leo_1",
          "term_key" => "target_value",
          "value" => 999.0
        },
        %{
          "id" => "score:downlink_gap",
          "scenario_id" => "leo_1",
          "term_key" => "Downlink Shortfall MB",
          "value" => 420.0,
          "ground_station_id" => "equator_prime"
        }
      ]
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_score_term_report", report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 420.0
    assert downlink["candidate_downlink_mb"] == 360.0
    assert downlink["selected_downlink_shortfall_mb"] == 60.0

    assert downlink["downlink_completion_source"] ==
             "candidate_refresh.objectives.downlink_completion"

    assert downlink["score_terms"]["downlink_completion_value"] == 42.857142857142854

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays score term target gaps from operator review packages" do
    report = %{
      "schema_contract" => "score_term_report.v1",
      "rows" => [
        %{
          "id" => "score:target_gap",
          "scenario_id" => "leo_1",
          "term_key" => "target gap count",
          "value" => 2,
          "target_id" => "target_a"
        }
      ]
    }

    package = OperatorReview.from_score_term_report(report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_operator_review_package", package),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    observe = Enum.find(artifact["candidate_activities"], &(&1["type"] == "observe"))

    assert %{
             "observation_objective_count" => 1,
             "observation_objective_ids" => [objective_id],
             "observation_objective_types" => ["target_revisit"],
             "required_observations" => 2.0,
             "score_terms" => %{"observation_objective_value" => 50.0}
           } = observe

    assert String.starts_with?(
             objective_id,
             "score_term:target_revisit:target_a:"
           )

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays score term collection latency gaps from Cadence import manifests" do
    report = %{
      "schema_contract" => "score_term_report.v1",
      "rows" => [
        %{
          "id" => "score:collection_latency_gap",
          "scenario_id" => "leo_1",
          "term_key" => "collection latency gap",
          "value" => 1,
          "target_id" => "target_a",
          "collection_id" => "collection_7",
          "product_id" => "image_7",
          "max_latency_s" => 900.0
        }
      ]
    }

    manifest = CadenceImport.from_score_term_report(report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_cadence_import_manifest", manifest),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    observe = Enum.find(artifact["candidate_activities"], &(&1["type"] == "observe"))

    assert %{
             "collection_latency_objective_count" => 1,
             "collection_latency_objective_ids" => [objective_id],
             "collection_latency_objective_types" => ["collection_latency"],
             "collection_id" => "collection_7",
             "product_id" => "image_7",
             "product_ids" => ["image_7"],
             "max_latency_s" => 900.0,
             "score_terms" => %{"collection_latency_observation_value" => 20.0}
           } = observe

    assert String.starts_with?(
             objective_id,
             "score_term:collection_latency:score:collection_latency_gap:"
           )

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "derives downlink completion objectives from source objective tradeoff reports" do
    report = %{
      "schema_contract" => "objective_tradeoff_report.v1",
      "tradeoffs" => [
        %{
          "id" => "tradeoff:ignored",
          "rank" => 1,
          "scenario_id" => "leo_1",
          "score" => 100.0,
          "score_delta_from_selected" => 0.0,
          "activity_count" => 1,
          "activity_ids" => ["leo_1_observe_target_a_1"],
          "score_terms" => %{"target_value" => 100.0}
        },
        %{
          "id" => "tradeoff:downlink_gap",
          "rank" => 2,
          "scenario_id" => "leo_1",
          "score" => 50.0,
          "score_delta_from_selected" => -25.0,
          "activity_count" => 1,
          "activity_ids" => ["leo_1_downlink_equator_prime_1"],
          "ground_station_id" => "equator_prime",
          "score_terms" => %{"downlink_shortfall_mb" => 420.0}
        }
      ]
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_objective_tradeoff_report", report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 420.0
    assert downlink["candidate_downlink_mb"] == 360.0
    assert downlink["selected_downlink_shortfall_mb"] == 60.0

    assert downlink["downlink_completion_source"] ==
             "candidate_refresh.objectives.downlink_completion"

    assert %{
             "paths" => ["source_objective_tradeoff_report"],
             "contract" => "objective_tradeoff_report.v1",
             "count" => 1,
             "row_count" => 2,
             "downlink_gap_row_count" => 1,
             "target_gap_row_count" => 0,
             "collection_latency_gap_row_count" => 0,
             "ground_station_counts" => %{"equator_prime" => 1}
           } = get_in(artifact, ["provenance", "source_reports", "objective_tradeoff_report"])

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays objective tradeoff target gaps from operator review packages" do
    report = %{
      "schema_contract" => "objective_tradeoff_report.v1",
      "tradeoffs" => [
        %{
          "id" => "tradeoff:target_gap",
          "rank" => 1,
          "scenario_id" => "leo_1",
          "score" => 10.0,
          "score_delta_from_selected" => -90.0,
          "activity_count" => 0,
          "activity_ids" => [],
          "target_id" => "target_a",
          "score_terms" => %{"target_gap_count" => 2.0}
        }
      ]
    }

    package = OperatorReview.from_objective_tradeoff_report(report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_operator_review_package", package),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    observe = Enum.find(artifact["candidate_activities"], &(&1["type"] == "observe"))

    assert %{
             "observation_objective_count" => 1,
             "observation_objective_ids" => [objective_id],
             "observation_objective_types" => ["target_revisit"],
             "required_observations" => 2.0,
             "score_terms" => %{"observation_objective_value" => 50.0}
           } = observe

    assert String.starts_with?(
             objective_id,
             "objective_tradeoff:target_revisit:target_a:"
           )

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays objective tradeoff collection latency gaps from Cadence import manifests" do
    report = %{
      "schema_contract" => "objective_tradeoff_report.v1",
      "tradeoffs" => [
        %{
          "id" => "tradeoff:collection_latency_gap",
          "rank" => 1,
          "scenario_id" => "leo_1",
          "score" => 20.0,
          "score_delta_from_selected" => -10.0,
          "activity_count" => 0,
          "activity_ids" => [],
          "target_id" => "target_a",
          "collection_id" => "collection_9",
          "product_id" => "image_9",
          "max_latency_s" => 600.0,
          "score_terms" => %{"collection_latency_gap_s" => 1.0}
        }
      ]
    }

    manifest = CadenceImport.from_objective_tradeoff_report(report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_cadence_import_manifest", manifest),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    observe = Enum.find(artifact["candidate_activities"], &(&1["type"] == "observe"))

    assert %{
             "collection_latency_objective_count" => 1,
             "collection_latency_objective_ids" => [objective_id],
             "collection_latency_objective_types" => ["collection_latency"],
             "collection_id" => "collection_9",
             "product_id" => "image_9",
             "product_ids" => ["image_9"],
             "max_latency_s" => 600.0,
             "score_terms" => %{"collection_latency_observation_value" => 20.0}
           } = observe

    assert String.starts_with?(
             objective_id,
             "objective_tradeoff:collection_latency:tradeoff:collection_latency_gap:"
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
