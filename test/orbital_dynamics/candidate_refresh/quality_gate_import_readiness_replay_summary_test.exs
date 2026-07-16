defmodule OrbitalDynamics.CandidateRefresh.QualityGateImportReadinessReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CandidateRefresh, Epoch, ResultSet, Schema}

  test "quality gate replay accepts operational import-readiness summaries" do
    import_readiness_summary =
      quality_gate_import_readiness_summary_fixture()
      |> Map.merge(%{
        "import_readiness_row_count" => 99,
        "review_required_quality_gate_row_ids" => ["stale_review_gate"],
        "blocked_quality_gate_row_ids" => ["stale_blocked_gate"],
        "ready_quality_gate_row_ids" => ["stale_ready_gate"],
        "analysis_only_quality_gate_row_ids" => ["stale_analysis_gate"]
      })

    refresh = %{
      "source_operational_quality_gate_import_readiness_summary" => import_readiness_summary
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_count" => 1,
             "source_report_row_count" => 2,
             "source_report_quality_gate_contract" => "quality_gate_report.v1",
             "source_report_quality_gate_count" => 1,
             "source_report_quality_gate_row_count" => 2,
             "source_report_quality_gate_paths" => [
               "source_operational_quality_gate_import_readiness_summary"
             ],
             "source_report_quality_gate_source_summary_model_counts" => %{
               "artifact_only_quality_gate_import_readiness_summary" => 1
             },
             "source_report_quality_gate_source_summary_schema_contract_counts" => %{
               "operational_quality_gate_import_readiness_summary.v1" => 1
             },
             "source_report_quality_gate_source_artifact_type_counts" => %{
               "quality_gate_report.v1" => 1
             },
             "source_report_quality_gate_publication_status_counts" => %{
               "published" => 1
             },
             "source_report_quality_gate_timeline_publication_source_artifact_type_counts" => %{
               "operational_timeline_report.v1" => 1
             },
             "source_report_quality_gate_publication_ids" => [
               "timeline_publication:import_ready"
             ],
             "source_report_quality_gate_source_artifact_ids" => [
               "operational_timeline:import_ready"
             ],
             "source_report_quality_gate_timeline_diff_changed_count" => 1,
             "source_report_quality_gate_changed_field_counts" => %{"end_time" => 1},
             "source_report_quality_gate_changed_timeline_ids" => ["timeline:import_ready"],
             "source_report_quality_gate_timeline_ids_by_changed_field" => %{
               "end_time" => ["timeline:import_ready"]
             },
             "source_report_quality_gate_gate_count" => 2,
             "source_report_quality_gate_review_gate_count" => 1,
             "source_report_quality_gate_blocked_gate_count" => 1,
             "source_report_quality_gate_ready_for_import_count" => 1,
             "source_report_quality_gate_manifest_review_required_count" => 1,
             "source_report_quality_gate_blocked_import_count" => 1,
             "source_report_quality_gate_missing_import_count" => 1,
             "source_report_quality_gate_invalid_cadence_import_count" => 1,
             "source_report_quality_gate_freshness_status_counts" => %{
               "stale" => 1,
               "unknown" => 1
             },
             "source_report_quality_gate_freshness_status_ids" => ["stale", "unknown"],
             "source_report_quality_gate_schema_validation_status_counts" => %{"fail" => 1},
             "source_report_quality_gate_import_status_counts" => %{
               "ready_for_import" => 1,
               "review_required_before_import" => 1
             },
             "source_report_quality_gate_import_status_ids" => [
               "ready_for_import",
               "review_required_before_import"
             ],
             "source_report_quality_gate_cadence_import_status_counts" => %{
               "invalid" => 1,
               "missing" => 1,
               "present" => 1
             },
             "source_report_quality_gate_cadence_import_status_ids" => [
               "invalid",
               "missing",
               "present"
             ],
             "source_report_quality_gate_quality_gate_row_ids_by_status" => %{
               "blocked" => ["quality_gate:cadence_import:blocked"],
               "review_required" => ["quality_gate:cadence_import:stale"]
             },
             "source_report_quality_gate_quality_gate_ids_by_status" => %{
               "blocked" => ["cadence_import"],
               "review_required" => ["cadence_import"]
             },
             "source_report_quality_gate_stale_or_unknown_freshness_quality_gate_row_ids" => [
               "quality_gate:cadence_import:stale"
             ],
             "source_report_quality_gate_import_preparation_quality_gate_row_ids" => [
               "quality_gate:cadence_import:stale"
             ],
             "source_report_quality_gate_blocked_import_quality_gate_row_ids" => [
               "quality_gate:cadence_import:blocked"
             ],
             "source_report_quality_gate_import_readiness_gate_ids" => ["cadence_import"],
             "source_reports" => %{
               "quality_gate_report" => %{
                 "paths" => ["source_operational_quality_gate_import_readiness_summary"],
                 "contract" => "quality_gate_report.v1",
                 "row_count" => 2,
                 "source_summary_schema_contract_counts" => %{
                   "operational_quality_gate_import_readiness_summary.v1" => 1
                 },
                 "publication_status_counts" => %{"published" => 1},
                 "freshness_status_ids" => ["stale", "unknown"],
                 "import_status_ids" => [
                   "ready_for_import",
                   "review_required_before_import"
                 ],
                 "cadence_import_status_ids" => ["invalid", "missing", "present"],
                 "timeline_publication_source_artifact_type_counts" => %{
                   "operational_timeline_report.v1" => 1
                 },
                 "quality_gate_row_ids_by_status" => %{
                   "blocked" => ["quality_gate:cadence_import:blocked"],
                   "review_required" => ["quality_gate:cadence_import:stale"]
                 }
               }
             }
           } = source_report_summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "source_report_paths" => [
               "source_operational_quality_gate_import_readiness_summary"
             ],
             "source_report_row_count" => 2,
             "source_summary_model_counts" => %{
               "artifact_only_quality_gate_import_readiness_summary" => 1
             },
             "source_summary_schema_contract_counts" => %{
               "operational_quality_gate_import_readiness_summary.v1" => 1
             },
             "source_artifact_type_counts" => %{"quality_gate_report.v1" => 1},
             "publication_status_counts" => %{"published" => 1},
             "timeline_publication_source_artifact_type_counts" => %{
               "operational_timeline_report.v1" => 1
             },
             "publication_ids" => ["timeline_publication:import_ready"],
             "source_artifact_ids" => ["operational_timeline:import_ready"],
             "timeline_diff_changed_count" => 1,
             "changed_field_counts" => %{"end_time" => 1},
             "changed_timeline_ids" => ["timeline:import_ready"],
             "timeline_ids_by_changed_field" => %{"end_time" => ["timeline:import_ready"]},
             "gate_count" => 2,
             "review_gate_count" => 1,
             "blocked_gate_count" => 1,
             "ready_for_import_count" => 1,
             "manifest_review_required_count" => 1,
             "blocked_import_count" => 1,
             "missing_import_count" => 1,
             "invalid_cadence_import_count" => 1,
             "freshness_status_counts" => %{"stale" => 1, "unknown" => 1},
             "freshness_status_ids" => ["stale", "unknown"],
             "schema_validation_status_counts" => %{"fail" => 1},
             "import_status_counts" => %{
               "ready_for_import" => 1,
               "review_required_before_import" => 1
             },
             "import_status_ids" => [
               "ready_for_import",
               "review_required_before_import"
             ],
             "cadence_import_status_counts" => %{
               "invalid" => 1,
               "missing" => 1,
               "present" => 1
             },
             "cadence_import_status_ids" => ["invalid", "missing", "present"],
             "quality_gate_row_ids_by_status" => %{
               "blocked" => ["quality_gate:cadence_import:blocked"],
               "review_required" => ["quality_gate:cadence_import:stale"]
             },
             "review_required_quality_gate_row_ids" => [
               "quality_gate:cadence_import:stale"
             ],
             "blocked_quality_gate_row_ids" => ["quality_gate:cadence_import:blocked"],
             "stale_or_unknown_freshness_quality_gate_row_ids" => [
               "quality_gate:cadence_import:stale"
             ],
             "import_preparation_quality_gate_row_ids" => [
               "quality_gate:cadence_import:stale"
             ],
             "blocked_import_quality_gate_row_ids" => [
               "quality_gate:cadence_import:blocked"
             ],
             "import_readiness_gate_ids" => ["cadence_import"],
             "branch_local_review_pressure" => true,
             "branch_local_import_pressure" => true,
             "branch_local_resource_pressure" => false,
             "branch_local_timeline_publication_pressure" => true,
             "branch_local_timeline_publication_changed_field_pressure" => true
           } = replay_summary = CandidateRefresh.quality_gate_replay_summary(refresh)

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_report_summary["source_reports"]}
    }

    assert CandidateRefresh.quality_gate_replay_summary(artifact) == replay_summary
  end

  test "quality gate replay accepts wrapped operational import-readiness summaries" do
    import_readiness_summary = quality_gate_import_readiness_summary_fixture()

    wrapper = %{
      "schema_contract" => "result_artifact.v1",
      "provenance" => %{"trust_boundary" => "readiness_adapter"},
      "source_operational_quality_gate_import_readiness_summary" => import_readiness_summary
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_result_artifact", [wrapper]),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "paths" => [
               "source_result_artifact[0].source_operational_quality_gate_import_readiness_summary"
             ],
             "source_summary_schema_contract_counts" => %{
               "operational_quality_gate_import_readiness_summary.v1" => 1
             },
             "quality_gate_row_ids_by_status" => %{
               "blocked" => ["quality_gate:cadence_import:blocked"],
               "review_required" => ["quality_gate:cadence_import:stale"]
             },
             "freshness_status_ids" => ["stale", "unknown"],
             "import_status_ids" => [
               "ready_for_import",
               "review_required_before_import"
             ],
             "cadence_import_status_ids" => ["invalid", "missing", "present"],
             "stale_or_unknown_freshness_quality_gate_row_ids" => [
               "quality_gate:cadence_import:stale"
             ],
             "blocked_import_quality_gate_row_ids" => [
               "quality_gate:cadence_import:blocked"
             ],
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["readiness_adapter", "readiness_summary_fixture"]
           } = get_in(artifact, ["provenance", "source_reports", "quality_gate_report"])

    assert %{
             "source_report_paths" => [
               "source_result_artifact[0].source_operational_quality_gate_import_readiness_summary"
             ],
             "source_summary_schema_contract_counts" => %{
               "operational_quality_gate_import_readiness_summary.v1" => 1
             },
             "freshness_status_ids" => ["stale", "unknown"],
             "import_status_ids" => [
               "ready_for_import",
               "review_required_before_import"
             ],
             "cadence_import_status_ids" => ["invalid", "missing", "present"],
             "branch_local_import_pressure" => true
           } = CandidateRefresh.quality_gate_replay_summary(artifact)

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

  defp quality_gate_import_readiness_summary_fixture do
    %{
      "schema_contract" => "operational_quality_gate_import_readiness_summary.v1",
      "model" => "artifact_only_quality_gate_import_readiness_summary",
      "source" => "quality_gate_report.v1",
      "source_artifact_type" => "quality_gate_report.v1",
      "source_artifact_id" => "quality_gate:ops_import_readiness",
      "source_quality_gate_report_id" => "quality_gate:ops_import_readiness",
      "source_readiness_report_id" => "operational_readiness:ops_import_readiness",
      "import_readiness_row_count" => 2,
      "ready_for_import_count" => 1,
      "manifest_review_required_count" => 1,
      "blocked_import_count" => 1,
      "missing_import_count" => 1,
      "invalid_cadence_import_count" => 1,
      "current_freshness_count" => 0,
      "stale_freshness_count" => 1,
      "unknown_freshness_count" => 1,
      "freshness_status_counts" => %{"stale" => 1, "unknown" => 1},
      "freshness_status_ids" => ["stale", "unknown"],
      "schema_validation_pass_count" => 0,
      "schema_validation_fail_count" => 1,
      "schema_validation_error_count" => 1,
      "schema_validation_warning_count" => 0,
      "schema_validation_remediation_count" => 1,
      "schema_validation_status_counts" => %{"fail" => 1},
      "import_status_counts" => %{
        "ready_for_import" => 1,
        "review_required_before_import" => 1
      },
      "import_status_ids" => ["ready_for_import", "review_required_before_import"],
      "cadence_import_status_counts" => %{
        "invalid" => 1,
        "missing" => 1,
        "present" => 1
      },
      "cadence_import_status_ids" => ["invalid", "missing", "present"],
      "quality_gate_row_ids_by_status" => %{
        "blocked" => ["quality_gate:cadence_import:blocked"],
        "review_required" => ["quality_gate:cadence_import:stale"]
      },
      "quality_gate_ids_by_status" => %{
        "blocked" => ["cadence_import"],
        "review_required" => ["cadence_import"]
      },
      "publication_status_counts" => %{"published" => 1},
      "dependency_impact_status_counts" => %{},
      "publication_authority_counts" => %{"automation" => 1},
      "source_artifact_type_counts" => %{"operational_timeline_report.v1" => 1},
      "publication_ids" => ["timeline_publication:import_ready"],
      "source_artifact_ids" => ["operational_timeline:import_ready"],
      "timeline_diff_changed_count" => 1,
      "changed_field_counts" => %{"end_time" => 1},
      "changed_timeline_ids" => ["timeline:import_ready"],
      "timeline_ids_by_changed_field" => %{"end_time" => ["timeline:import_ready"]},
      "review_required_quality_gate_row_ids" => ["quality_gate:cadence_import:stale"],
      "blocked_quality_gate_row_ids" => ["quality_gate:cadence_import:blocked"],
      "ready_quality_gate_row_ids" => [],
      "analysis_only_quality_gate_row_ids" => [],
      "stale_or_unknown_freshness_quality_gate_row_ids" => [
        "quality_gate:cadence_import:stale"
      ],
      "import_preparation_quality_gate_row_ids" => ["quality_gate:cadence_import:stale"],
      "blocked_import_quality_gate_row_ids" => ["quality_gate:cadence_import:blocked"],
      "import_readiness_gate_ids" => ["cadence_import"],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_import_readiness_summary",
        "cadence_write" => "not_performed_by_summary"
      },
      "provenance" => %{"trust_boundary" => "readiness_summary_fixture"}
    }
  end
end
