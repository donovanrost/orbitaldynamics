defmodule OrbitalDynamics.CandidateRefresh.SourceReportPassiveWrapperProvenanceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CandidateRefresh, Epoch, ResultSet, Schema, Validation}

  test "summarizes passive source reports from result artifact wrappers" do
    wrapper = %{
      "schema_contract" => "result_artifact.v1",
      "provenance" => %{"trust_boundary" => "mission_planning"},
      "source_candidate_diff_report" => [
        %{
          "schema_contract" => "candidate_diff_report.v1",
          "retained_candidates" => [
            %{
              "id" => "retained_prior",
              "ground_station_id" => "equator_prime",
              "diff_reason" => "present_in_prior_candidate_set_with_semantic_changes",
              "semantic_change_reasons" => ["contact_window_shifted"],
              "candidate_diff_changed_fields" => ["starts_at_s"]
            }
          ],
          "new_candidates" => [],
          "invalidated_candidates" => []
        },
        %{
          "schema_contract" => "candidate_diff_report.v1",
          "retained_candidates" => [],
          "new_candidates" => [
            %{
              "id" => "new_prior",
              "source_window" => %{"ground_station_id" => "equator_prime"},
              "diff_reason" => "not_present_in_prior_candidate_set"
            }
          ],
          "invalidated_candidates" => [
            %{
              "id" => "invalidated_prior",
              "source_window" => %{"ground_station_id" => "polar_prime"},
              "invalidated_reason" => "not_present_in_refreshed_candidate_set",
              "semantic_change_reasons" => ["station_reservation_changed"],
              "candidate_diff_changed_fields" => ["station_reservation_status"]
            }
          ]
        }
      ],
      "freshness_report" => %{
        "schema_contract" => "freshness_report.v1",
        "status" => "stale",
        "stale_reasons" => ["orbit_state_age_exceeds_policy"],
        "unknown_reasons" => []
      },
      "source_refresh_budget_report" => %{
        "schema_contract" => "refresh_budget_report.v1",
        "input_candidate_count" => 4,
        "kept_candidate_count" => 2,
        "dropped_candidate_count" => 2
      },
      "source_contact_contention_report" => %{
        "schema_contract" => "contact_contention_report.v1",
        "input_contact_count" => 2,
        "conflict_group_count" => 1,
        "conflict_groups" => [
          %{
            "id" => "station:equator_prime:contention:1",
            "ground_station_id" => "equator_prime",
            "resource_scope" => "ground_station",
            "direction" => "downlink",
            "contact_ids" => ["dl_primary", "dl_backup"],
            "required_operator_action" => "review_contact_contention"
          }
        ]
      },
      "source_model_acceptance_report" =>
        [
          "orbit_data.simple_json",
          "event.access_windows",
          "propagator.two_body",
          "missing.model"
        ]
        |> Validation.model_acceptance_report(intended_use: :operational_import),
      "source_quality_gate_report" => %{
        "schema_contract" => "quality_gate_report.v1",
        "source_readiness_report_id" => "operational_readiness:planned_activity.v1:activity_1",
        "readiness_level" => "operator_review",
        "import_classification" => "review_only",
        "status" => "review_required",
        "gate_count" => 1,
        "passed_gate_count" => 0,
        "review_gate_count" => 1,
        "analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "gate_status_counts" => %{"review_required" => 1},
        "gate_classification_counts" => %{"review_only" => 1},
        "rows" => [
          %{
            "id" => "quality_gate:activity_1:operator_review:1",
            "rank" => 1,
            "gate_id" => "operator_review",
            "status" => "review_required",
            "classification" => "review_only",
            "reason" => "operator review required"
          }
        ]
      }
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_result_artifact", wrapper),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "paths" => [
               "source_result_artifact.source_candidate_diff_report[0]",
               "source_result_artifact.source_candidate_diff_report[1]"
             ],
             "contract" => "candidate_diff_report.v1",
             "count" => 2,
             "row_count" => 3,
             "retained_candidate_count" => 1,
             "new_candidate_count" => 1,
             "invalidated_candidate_count" => 1,
             "diff_reason_counts" => %{
               "not_present_in_prior_candidate_set" => 1,
               "present_in_prior_candidate_set_with_semantic_changes" => 1
             },
             "invalidated_reason_counts" => %{
               "not_present_in_refreshed_candidate_set" => 1
             },
             "semantic_change_reason_counts" => %{
               "contact_window_shifted" => 1,
               "station_reservation_changed" => 1
             },
             "candidate_diff_changed_field_counts" => %{
               "starts_at_s" => 1,
               "station_reservation_status" => 1
             },
             "candidate_diff_candidate_id_counts" => %{
               "invalidated_prior" => 1,
               "new_prior" => 1,
               "retained_prior" => 1
             },
             "candidate_diff_ground_station_counts" => %{
               "equator_prime" => 2,
               "polar_prime" => 1
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["mission_planning"]
           } = get_in(artifact, ["provenance", "source_reports", "candidate_diff_report"])

    assert %{
             "source_report_candidate_diff_diff_reason_counts" => %{
               "not_present_in_prior_candidate_set" => 1,
               "present_in_prior_candidate_set_with_semantic_changes" => 1
             },
             "source_report_candidate_diff_invalidated_reason_counts" => %{
               "not_present_in_refreshed_candidate_set" => 1
             },
             "source_report_candidate_diff_candidate_id_counts" => %{
               "invalidated_prior" => 1,
               "new_prior" => 1,
               "retained_prior" => 1
             },
             "source_report_candidate_diff_ground_station_counts" => %{
               "equator_prime" => 2,
               "polar_prime" => 1
             }
           } = CandidateRefresh.source_report_summary(artifact)

    assert %{
             "paths" => ["source_result_artifact.freshness_report"],
             "contract" => "freshness_report.v1",
             "count" => 1,
             "row_count" => 1,
             "status_counts" => %{"stale" => 1},
             "stale_reason_count" => 1,
             "unknown_reason_count" => 0,
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["mission_planning"]
           } = get_in(artifact, ["provenance", "source_reports", "freshness_report"])

    assert %{
             "paths" => ["source_result_artifact.source_refresh_budget_report"],
             "contract" => "refresh_budget_report.v1",
             "count" => 1,
             "row_count" => 1,
             "input_candidate_count" => 4,
             "kept_candidate_count" => 2,
             "dropped_candidate_count" => 2,
             "invalid_candidate_limit_policy_count" => 0,
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["mission_planning"]
           } = get_in(artifact, ["provenance", "source_reports", "refresh_budget_report"])

    assert %{
             "paths" => ["source_result_artifact.source_contact_contention_report"],
             "contract" => "contact_contention_report.v1",
             "count" => 1,
             "row_count" => 1,
             "conflict_group_count" => 1,
             "invalid_contact_input_count" => 0,
             "resource_scope_counts" => %{"ground_station" => 1},
             "contact_contention_ground_station_counts" => %{"equator_prime" => 1},
             "contact_contention_contact_id_counts" => %{"dl_backup" => 1, "dl_primary" => 1},
             "required_operator_action_counts" => %{"review_contact_contention" => 1},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["mission_planning"]
           } = get_in(artifact, ["provenance", "source_reports", "contact_contention_report"])

    assert %{
             "paths" => ["source_result_artifact.source_model_acceptance_report"],
             "contract" => "model_acceptance_report.v1",
             "count" => 1,
             "row_count" => 4,
             "record_count" => 3,
             "intended_use_counts" => %{"operational_import" => 1},
             "status_counts" => %{"blocked" => 1},
             "model_count" => 4,
             "accepted_count" => 1,
             "review_required_count" => 1,
             "blocked_count" => 2,
             "unknown_model_count" => 1,
             "model_ids_by_status" => %{
               "accepted" => ["orbit_data.simple_json"],
               "blocked" => ["propagator.two_body", "missing.model"],
               "review_required" => ["event.access_windows"]
             },
             "model_ids_by_validation_level" => %{
               "analysis" => ["event.access_windows"],
               "artifact_contract" => ["orbit_data.simple_json"],
               "educational" => ["propagator.two_body"],
               "unknown" => ["missing.model"]
             },
             "model_ids_by_intended_use" => %{
               "operational_import" => [
                 "orbit_data.simple_json",
                 "event.access_windows",
                 "propagator.two_body",
                 "missing.model"
               ]
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["mission_planning"]
           } = get_in(artifact, ["provenance", "source_reports", "model_acceptance_report"])

    assert %{
             "paths" => ["source_result_artifact.source_quality_gate_report"],
             "contract" => "quality_gate_report.v1",
             "count" => 1,
             "row_count" => 1,
             "readiness_level_counts" => %{"operator_review" => 1},
             "import_classification_counts" => %{"review_only" => 1},
             "status_counts" => %{"review_required" => 1},
             "gate_count" => 1,
             "review_gate_count" => 1,
             "gate_status_counts" => %{"review_required" => 1},
             "gate_classification_counts" => %{"review_only" => 1},
             "source_readiness_report_count" => 1,
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["mission_planning"]
           } = get_in(artifact, ["provenance", "source_reports", "quality_gate_report"])

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
