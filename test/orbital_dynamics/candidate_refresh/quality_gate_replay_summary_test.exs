defmodule OrbitalDynamics.CandidateRefresh.QualityGateReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CandidateRefresh, Epoch, ResultSet, Schema}

  test "quality gate replay accepts operational operator-training summaries" do
    operator_training_summary =
      quality_gate_operator_training_summary_fixture()
      |> Map.put("operator_training_row_count", 99)

    refresh = %{
      "accepted_planning_state" => %{
        "operational_quality_gate_operator_training_summary" => operator_training_summary
      },
      "mission_state" => %{
        "source_operational_quality_gate_operator_training_summary" => operator_training_summary
      },
      "source_operational_quality_gate_operator_training_summary" => operator_training_summary
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_count" => 3,
             "source_report_row_count" => 3,
             "source_report_quality_gate_contract" => "quality_gate_report.v1",
             "source_report_quality_gate_count" => 3,
             "source_report_quality_gate_row_count" => 3,
             "source_report_quality_gate_paths" => [
               "accepted_planning_state.operational_quality_gate_operator_training_summary",
               "mission_state.source_operational_quality_gate_operator_training_summary",
               "source_operational_quality_gate_operator_training_summary"
             ],
             "source_report_quality_gate_source_summary_model_counts" => %{
               "artifact_only_quality_gate_operator_training_summary" => 3
             },
             "source_report_quality_gate_source_summary_schema_contract_counts" => %{
               "operational_quality_gate_operator_training_summary.v1" => 3
             },
             "source_report_quality_gate_gate_count" => 3,
             "source_report_quality_gate_review_gate_count" => 3,
             "source_reports" => %{
               "quality_gate_report" => %{
                 "paths" => [
                   "accepted_planning_state.operational_quality_gate_operator_training_summary",
                   "mission_state.source_operational_quality_gate_operator_training_summary",
                   "source_operational_quality_gate_operator_training_summary"
                 ],
                 "contract" => "quality_gate_report.v1",
                 "count" => 3,
                 "row_count" => 3,
                 "source_summary_schema_contract_counts" => %{
                   "operational_quality_gate_operator_training_summary.v1" => 3
                 },
                 "operator_training_requirement_count" => 15,
                 "operator_training_requirement_counts" => %{
                   "certification" => 3,
                   "operator_role" => 6,
                   "qualification" => 3,
                   "training" => 3
                 }
               }
             }
           } = source_report_summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "source_report_paths" => [
               "accepted_planning_state.operational_quality_gate_operator_training_summary",
               "mission_state.source_operational_quality_gate_operator_training_summary",
               "source_operational_quality_gate_operator_training_summary"
             ],
             "source_report_row_count" => 3,
             "source_summary_model_counts" => %{
               "artifact_only_quality_gate_operator_training_summary" => 3
             },
             "source_summary_schema_contract_counts" => %{
               "operational_quality_gate_operator_training_summary.v1" => 3
             },
             "gate_count" => 3,
             "review_gate_count" => 3,
             "operator_training_requirement_count" => 15,
             "operator_training_requirement_counts" => %{
               "certification" => 3,
               "operator_role" => 6,
               "qualification" => 3,
               "training" => 3
             },
             "required_operator_roles" => ["contact_operator", "mission_director"],
             "required_training_ids" => ["contact_replan_drill"],
             "required_certification_ids" => ["cadence_import_cert"],
             "required_qualification_ids" => ["sat_ops_current"],
             "review_only_quality_gate_row_ids" => [
               "quality_gate:activity_1:operator_training"
             ],
             "operator_training_gate_ids" => ["operator_training"],
             "review_required_quality_gate_row_ids" => [
               "quality_gate:activity_1:operator_training"
             ],
             "branch_local_review_pressure" => true,
             "branch_local_import_pressure" => false,
             "branch_local_resource_pressure" => false
           } = replay_summary = CandidateRefresh.quality_gate_replay_summary(refresh)

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_report_summary["source_reports"]}
    }

    assert CandidateRefresh.quality_gate_replay_summary(artifact) == replay_summary
  end

  test "quality gate replay treats explicit empty operator-training status maps as zero rows" do
    operator_training_summary =
      quality_gate_operator_training_summary_fixture()
      |> Map.merge(%{
        "operator_training_row_count" => 99,
        "quality_gate_row_ids_by_status" => %{},
        "quality_gate_ids_by_status" => %{}
      })

    refresh = %{
      "source_operational_quality_gate_operator_training_summary" => operator_training_summary
    }

    source_report_summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "source_report_count" => 1,
             "source_report_row_count" => 0,
             "source_report_quality_gate_count" => 1,
             "source_report_quality_gate_row_count" => 0,
             "source_report_quality_gate_gate_count" => 0,
             "source_report_quality_gate_review_gate_count" => 0,
             "source_reports" => %{
               "quality_gate_report" => %{
                 "row_count" => 0,
                 "gate_count" => 0,
                 "review_gate_count" => 0,
                 "operator_training_requirement_count" => 5
               }
             }
           } = source_report_summary

    assert Map.get(
             source_report_summary,
             "source_report_quality_gate_quality_gate_row_ids_by_status",
             %{}
           ) ==
             %{}

    replay_summary = CandidateRefresh.quality_gate_replay_summary(refresh)

    assert %{
             "source_report_count" => 1,
             "source_report_row_count" => 0,
             "gate_count" => 0,
             "review_gate_count" => 0,
             "operator_training_requirement_count" => 5,
             "branch_local_review_pressure" => true
           } = replay_summary

    assert Map.get(replay_summary, "quality_gate_row_ids_by_status", %{}) == %{}
    assert Map.get(replay_summary, "review_required_quality_gate_row_ids", []) == []
  end

  test "quality gate replay accepts wrapped operational operator-training summaries" do
    operator_training_summary = quality_gate_operator_training_summary_fixture()

    wrapper = %{
      "schema_contract" => "result_artifact.v1",
      "provenance" => %{"trust_boundary" => "operator_training_adapter"},
      "source_operational_quality_gate_operator_training_summary" => operator_training_summary
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
               "source_result_artifact[0].source_operational_quality_gate_operator_training_summary"
             ],
             "source_summary_schema_contract_counts" => %{
               "operational_quality_gate_operator_training_summary.v1" => 1
             },
             "operator_training_requirement_count" => 5,
             "required_operator_roles" => ["contact_operator", "mission_director"],
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "operator_training_adapter",
               "operator_training_summary_fixture"
             ]
           } = get_in(artifact, ["provenance", "source_reports", "quality_gate_report"])

    assert %{
             "source_report_paths" => [
               "source_result_artifact[0].source_operational_quality_gate_operator_training_summary"
             ],
             "source_summary_schema_contract_counts" => %{
               "operational_quality_gate_operator_training_summary.v1" => 1
             },
             "operator_training_requirement_count" => 5,
             "required_operator_roles" => ["contact_operator", "mission_director"],
             "branch_local_review_pressure" => true
           } = CandidateRefresh.quality_gate_replay_summary(artifact)

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "quality gate replay accepts operational schema-validation summaries" do
    schema_summary =
      quality_gate_schema_validation_summary_fixture()
      |> Map.put("schema_validation_row_count", 99)

    refresh = %{
      "accepted_planning_state" => %{
        "operational_quality_gate_schema_validation_summary" => schema_summary
      },
      "mission_state" => %{
        "source_operational_quality_gate_schema_validation_summary" => schema_summary
      },
      "source_operational_quality_gate_schema_validation_summary" => schema_summary
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_count" => 3,
             "source_report_row_count" => 3,
             "source_report_quality_gate_contract" => "quality_gate_report.v1",
             "source_report_quality_gate_count" => 3,
             "source_report_quality_gate_row_count" => 3,
             "source_report_quality_gate_paths" => [
               "accepted_planning_state.operational_quality_gate_schema_validation_summary",
               "mission_state.source_operational_quality_gate_schema_validation_summary",
               "source_operational_quality_gate_schema_validation_summary"
             ],
             "source_report_quality_gate_source_summary_model_counts" => %{
               "artifact_only_quality_gate_schema_validation_summary" => 3
             },
             "source_report_quality_gate_source_summary_schema_contract_counts" => %{
               "operational_quality_gate_schema_validation_summary.v1" => 3
             },
             "source_report_quality_gate_gate_count" => 3,
             "source_report_quality_gate_blocked_gate_count" => 3,
             "source_report_quality_gate_schema_validation_status_counts" => %{
               "fail" => 3
             },
             "source_report_quality_gate_schema_validation_status_ids" => ["fail"],
             "source_report_quality_gate_failed_schema_validation_quality_gate_row_ids" => [
               "quality_gate:activity_1:schema_validation"
             ],
             "source_report_quality_gate_schema_validation_gate_ids" => ["cadence_import"],
             "source_reports" => %{
               "quality_gate_report" => %{
                 "paths" => [
                   "accepted_planning_state.operational_quality_gate_schema_validation_summary",
                   "mission_state.source_operational_quality_gate_schema_validation_summary",
                   "source_operational_quality_gate_schema_validation_summary"
                 ],
                 "contract" => "quality_gate_report.v1",
                 "count" => 3,
                 "row_count" => 3,
                 "source_summary_schema_contract_counts" => %{
                   "operational_quality_gate_schema_validation_summary.v1" => 3
                 },
                 "schema_validation_status_counts" => %{"fail" => 3},
                 "schema_validation_status_ids" => ["fail"],
                 "failed_schema_validation_quality_gate_row_ids" => [
                   "quality_gate:activity_1:schema_validation"
                 ]
               }
             }
           } = source_report_summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "source_report_paths" => [
               "accepted_planning_state.operational_quality_gate_schema_validation_summary",
               "mission_state.source_operational_quality_gate_schema_validation_summary",
               "source_operational_quality_gate_schema_validation_summary"
             ],
             "source_report_row_count" => 3,
             "source_summary_model_counts" => %{
               "artifact_only_quality_gate_schema_validation_summary" => 3
             },
             "source_summary_schema_contract_counts" => %{
               "operational_quality_gate_schema_validation_summary.v1" => 3
             },
             "gate_count" => 3,
             "blocked_gate_count" => 3,
             "schema_validation_status_counts" => %{"fail" => 3},
             "schema_validation_status_ids" => ["fail"],
             "failed_schema_validation_quality_gate_row_ids" => [
               "quality_gate:activity_1:schema_validation"
             ],
             "schema_validation_gate_ids" => ["cadence_import"],
             "blocked_quality_gate_row_ids" => ["quality_gate:activity_1:schema_validation"],
             "branch_local_review_pressure" => true,
             "branch_local_import_pressure" => false,
             "branch_local_resource_pressure" => false
           } = replay_summary = CandidateRefresh.quality_gate_replay_summary(refresh)

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_report_summary["source_reports"]}
    }

    assert CandidateRefresh.quality_gate_replay_summary(artifact) == replay_summary
  end

  test "quality gate replay treats explicit empty schema-validation status maps as zero rows" do
    schema_summary =
      quality_gate_schema_validation_summary_fixture()
      |> Map.merge(%{
        "schema_validation_row_count" => 99,
        "quality_gate_row_ids_by_status" => %{},
        "quality_gate_ids_by_status" => %{}
      })

    refresh = %{
      "source_operational_quality_gate_schema_validation_summary" => schema_summary
    }

    source_report_summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "source_report_count" => 1,
             "source_report_row_count" => 0,
             "source_report_quality_gate_count" => 1,
             "source_report_quality_gate_row_count" => 0,
             "source_report_quality_gate_gate_count" => 0,
             "source_report_quality_gate_blocked_gate_count" => 0,
             "source_reports" => %{
               "quality_gate_report" => %{
                 "row_count" => 0,
                 "gate_count" => 0,
                 "blocked_gate_count" => 0
               }
             }
           } = source_report_summary

    assert Map.get(
             source_report_summary,
             "source_report_quality_gate_quality_gate_row_ids_by_status",
             %{}
           ) ==
             %{}

    assert get_in(source_report_summary, [
             "source_reports",
             "quality_gate_report",
             "quality_gate_row_ids_by_status"
           ]) in [nil, %{}]

    replay_summary = CandidateRefresh.quality_gate_replay_summary(refresh)

    assert %{
             "source_report_count" => 1,
             "source_report_row_count" => 0,
             "gate_count" => 0,
             "blocked_gate_count" => 0
           } = replay_summary

    assert Map.get(replay_summary, "quality_gate_row_ids_by_status", %{}) == %{}
    assert Map.get(replay_summary, "blocked_quality_gate_row_ids", []) == []
  end

  test "quality gate replay accepts wrapped operational schema-validation summaries" do
    schema_summary = quality_gate_schema_validation_summary_fixture()

    wrapper = %{
      "schema_contract" => "result_artifact.v1",
      "provenance" => %{"trust_boundary" => "schema_validation_adapter"},
      "source_operational_quality_gate_schema_validation_summary" => schema_summary
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
               "source_result_artifact[0].source_operational_quality_gate_schema_validation_summary"
             ],
             "source_summary_schema_contract_counts" => %{
               "operational_quality_gate_schema_validation_summary.v1" => 1
             },
             "schema_validation_status_counts" => %{"fail" => 1},
             "schema_validation_status_ids" => ["fail"],
             "failed_schema_validation_quality_gate_row_ids" => [
               "quality_gate:activity_1:schema_validation"
             ],
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "schema_validation_adapter",
               "schema_validation_summary_fixture"
             ]
           } = get_in(artifact, ["provenance", "source_reports", "quality_gate_report"])

    assert %{
             "source_report_paths" => [
               "source_result_artifact[0].source_operational_quality_gate_schema_validation_summary"
             ],
             "source_summary_schema_contract_counts" => %{
               "operational_quality_gate_schema_validation_summary.v1" => 1
             },
             "schema_validation_status_counts" => %{"fail" => 1},
             "schema_validation_status_ids" => ["fail"],
             "failed_schema_validation_quality_gate_row_ids" => [
               "quality_gate:activity_1:schema_validation"
             ],
             "branch_local_review_pressure" => true
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

  defp quality_gate_operator_training_summary_fixture do
    %{
      "schema_contract" => "operational_quality_gate_operator_training_summary.v1",
      "model" => "artifact_only_quality_gate_operator_training_summary",
      "source" => "quality_gate_report.v1",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "activity_1",
      "source_quality_gate_report_id" => "quality_gate:planned_activity.v1:activity_1",
      "source_readiness_report_id" => "operational_readiness:planned_activity.v1:activity_1",
      "operator_training_row_count" => 1,
      "operator_training_requirement_count" => 5,
      "operator_training_requirement_counts" => %{
        "operator_role" => 2,
        "training" => 1,
        "certification" => 1,
        "qualification" => 1
      },
      "operator_training_requirement_ids" => [
        "certification",
        "operator_role",
        "qualification",
        "training"
      ],
      "required_operator_roles" => ["contact_operator", "mission_director"],
      "required_training_ids" => ["contact_replan_drill"],
      "required_certification_ids" => ["cadence_import_cert"],
      "required_qualification_ids" => ["sat_ops_current"],
      "quality_gate_row_ids_by_status" => %{
        "review_required" => ["quality_gate:activity_1:operator_training"]
      },
      "quality_gate_row_ids_by_classification" => %{
        "review_only" => ["quality_gate:activity_1:operator_training"]
      },
      "quality_gate_ids_by_status" => %{"review_required" => ["operator_training"]},
      "quality_gate_ids_by_classification" => %{"review_only" => ["operator_training"]},
      "review_required_quality_gate_row_ids" => [
        "quality_gate:activity_1:operator_training"
      ],
      "blocked_quality_gate_row_ids" => [],
      "review_only_quality_gate_row_ids" => [
        "quality_gate:activity_1:operator_training"
      ],
      "operator_training_gate_ids" => ["operator_training"],
      "operator_training_review_required" => true,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "source" => "quality_gate_report.v1",
        "operator_authority" => "not_granted_by_operator_training_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary"
      },
      "provenance" => %{"trust_boundary" => "operator_training_summary_fixture"}
    }
  end

  defp quality_gate_schema_validation_summary_fixture do
    %{
      "schema_contract" => "operational_quality_gate_schema_validation_summary.v1",
      "model" => "artifact_only_quality_gate_schema_validation_summary",
      "source" => "quality_gate_report.v1",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "activity_1",
      "source_quality_gate_report_id" => "quality_gate:planned_activity.v1:activity_1",
      "source_readiness_report_id" => "operational_readiness:planned_activity.v1:activity_1",
      "schema_validation_row_count" => 1,
      "schema_validation_pass_count" => 0,
      "schema_validation_fail_count" => 1,
      "schema_validation_error_count" => 1,
      "schema_validation_warning_count" => 0,
      "schema_validation_remediation_count" => 1,
      "schema_validation_status_counts" => %{"fail" => 1},
      "schema_validation_status_ids" => ["fail"],
      "schema_validation_import_blocked" => true,
      "quality_gate_row_ids_by_status" => %{
        "blocked" => ["quality_gate:activity_1:schema_validation"]
      },
      "quality_gate_ids_by_status" => %{"blocked" => ["cadence_import"]},
      "blocked_quality_gate_row_ids" => ["quality_gate:activity_1:schema_validation"],
      "review_required_quality_gate_row_ids" => [],
      "failed_schema_validation_quality_gate_row_ids" => [
        "quality_gate:activity_1:schema_validation"
      ],
      "schema_validation_gate_ids" => ["cadence_import"],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "source" => "quality_gate_report.v1",
        "operator_authority" => "not_granted_by_schema_validation_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary"
      },
      "provenance" => %{"trust_boundary" => "schema_validation_summary_fixture"}
    }
  end
end
