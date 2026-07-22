defmodule OrbitalDynamics.CandidateRefresh.QualityGateOperationalSummaryReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CadenceImport,
    CandidateRefresh,
    Epoch,
    OperatorReview,
    ResultSet,
    Schema
  }

  test "quality gate replay accepts operational quality gate summaries" do
    quality_gate_summary =
      quality_gate_summary_fixture()
      |> Map.drop(["rows", "non_passed_rows"])
      |> Map.merge(%{
        "readiness_level" => "import_eligible",
        "import_classification" => "importable",
        "status" => "passed",
        "gate_count" => 99,
        "passed_gate_count" => 99,
        "review_gate_count" => 99,
        "analysis_gate_count" => 99,
        "blocked_gate_count" => 99,
        "gate_status_counts" => %{"passed" => 99},
        "gate_classification_counts" => %{"importable" => 99}
      })

    refresh = %{
      "accepted_planning_state" => %{
        "operational_quality_gate_summary" => quality_gate_summary
      },
      "mission_state" => %{
        "source_operational_quality_gate_summary" => quality_gate_summary
      },
      "source_operational_quality_gate_summary" => quality_gate_summary
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_count" => 3,
             "source_report_row_count" => 6,
             "source_report_quality_gate_contract" => "quality_gate_report.v1",
             "source_report_quality_gate_count" => 3,
             "source_report_quality_gate_row_count" => 6,
             "source_report_quality_gate_paths" => [
               "accepted_planning_state.operational_quality_gate_summary",
               "mission_state.source_operational_quality_gate_summary",
               "source_operational_quality_gate_summary"
             ],
             "source_report_quality_gate_source_summary_model_counts" => %{
               "artifact_only_quality_gate_summary" => 3
             },
             "source_report_quality_gate_source_summary_schema_contract_counts" => %{
               "operational_quality_gate_summary.v1" => 3
             },
             "source_report_quality_gate_source_artifact_type_counts" => %{
               "planned_activity.v1" => 3
             },
             "source_report_quality_gate_readiness_level_counts" => %{"blocked" => 3},
             "source_report_quality_gate_import_classification_counts" => %{
               "blocked" => 3
             },
             "source_report_quality_gate_status_counts" => %{"blocked" => 3},
             "source_report_quality_gate_gate_count" => 6,
             "source_report_quality_gate_review_gate_count" => 3,
             "source_report_quality_gate_blocked_gate_count" => 3,
             "source_report_quality_gate_gate_status_counts" => %{
               "blocked" => 3,
               "review_required" => 3
             },
             "source_report_quality_gate_gate_classification_counts" => %{
               "blocked" => 3,
               "review_only" => 3
             },
             "source_report_quality_gate_quality_gate_row_ids_by_status" => %{
               "blocked" => ["quality_gate:activity_1:cadence_import"],
               "review_required" => ["quality_gate:activity_1:mission_policy"]
             },
             "source_report_quality_gate_quality_gate_ids_by_status" => %{
               "blocked" => ["cadence_import"],
               "review_required" => ["mission_policy"]
             },
             "source_reports" => %{
               "quality_gate_report" => %{
                 "paths" => [
                   "accepted_planning_state.operational_quality_gate_summary",
                   "mission_state.source_operational_quality_gate_summary",
                   "source_operational_quality_gate_summary"
                 ],
                 "contract" => "quality_gate_report.v1",
                 "count" => 3,
                 "row_count" => 6,
                 "source_summary_schema_contract_counts" => %{
                   "operational_quality_gate_summary.v1" => 3
                 },
                 "quality_gate_row_ids_by_classification" => %{
                   "blocked" => ["quality_gate:activity_1:cadence_import"],
                   "review_only" => ["quality_gate:activity_1:mission_policy"]
                 },
                 "quality_gate_ids_by_classification" => %{
                   "blocked" => ["cadence_import"],
                   "review_only" => ["mission_policy"]
                 },
                 "non_passed_gate_count" => 6,
                 "passed_gate_ids" => [],
                 "review_required_gate_ids" => ["mission_policy"],
                 "analysis_only_gate_ids" => [],
                 "blocked_gate_ids" => ["cadence_import"],
                 "non_passed_gate_ids" => ["cadence_import", "mission_policy"],
                 "non_passed_quality_gate_row_ids" => [
                   "quality_gate:activity_1:cadence_import",
                   "quality_gate:activity_1:mission_policy"
                 ]
               }
             }
           } = source_report_summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "source_report_paths" => [
               "accepted_planning_state.operational_quality_gate_summary",
               "mission_state.source_operational_quality_gate_summary",
               "source_operational_quality_gate_summary"
             ],
             "source_report_row_count" => 6,
             "source_summary_model_counts" => %{
               "artifact_only_quality_gate_summary" => 3
             },
             "source_summary_schema_contract_counts" => %{
               "operational_quality_gate_summary.v1" => 3
             },
             "source_artifact_type_counts" => %{"planned_activity.v1" => 3},
             "readiness_level_counts" => %{"blocked" => 3},
             "import_classification_counts" => %{"blocked" => 3},
             "status_counts" => %{"blocked" => 3},
             "gate_count" => 6,
             "review_gate_count" => 3,
             "blocked_gate_count" => 3,
             "gate_status_counts" => %{"blocked" => 3, "review_required" => 3},
             "gate_classification_counts" => %{"blocked" => 3, "review_only" => 3},
             "quality_gate_row_ids_by_status" => %{
               "blocked" => ["quality_gate:activity_1:cadence_import"],
               "review_required" => ["quality_gate:activity_1:mission_policy"]
             },
             "quality_gate_row_ids_by_classification" => %{
               "blocked" => ["quality_gate:activity_1:cadence_import"],
               "review_only" => ["quality_gate:activity_1:mission_policy"]
             },
             "quality_gate_ids_by_classification" => %{
               "blocked" => ["cadence_import"],
               "review_only" => ["mission_policy"]
             },
             "non_passed_gate_count" => 6,
             "passed_gate_ids" => [],
             "review_required_gate_ids" => ["mission_policy"],
             "analysis_only_gate_ids" => [],
             "blocked_gate_ids" => ["cadence_import"],
             "non_passed_gate_ids" => ["cadence_import", "mission_policy"],
             "non_passed_quality_gate_row_ids" => [
               "quality_gate:activity_1:cadence_import",
               "quality_gate:activity_1:mission_policy"
             ],
             "review_required_quality_gate_row_ids" => [
               "quality_gate:activity_1:mission_policy"
             ],
             "blocked_quality_gate_row_ids" => ["quality_gate:activity_1:cadence_import"],
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

  test "quality gate replay treats explicit empty quality-gate summary status maps as zero rows" do
    quality_gate_summary =
      quality_gate_summary_fixture()
      |> Map.drop(["rows", "non_passed_rows"])
      |> Map.merge(%{
        "readiness_level" => "blocked",
        "import_classification" => "blocked",
        "status" => "blocked",
        "gate_count" => 99,
        "review_gate_count" => 99,
        "blocked_gate_count" => 99,
        "gate_status_counts" => %{"blocked" => 99},
        "gate_classification_counts" => %{"blocked" => 99},
        "quality_gate_row_ids_by_status" => %{},
        "gate_ids_by_status" => %{},
        "quality_gate_ids_by_status" => %{},
        "gate_ids_by_classification" => %{"blocked" => ["stale_gate"]},
        "quality_gate_row_ids_by_classification" => %{
          "blocked" => ["quality_gate:stale"]
        },
        "passed_gate_ids" => ["stale_passed_gate"],
        "review_required_gate_ids" => ["stale_review_gate"],
        "blocked_gate_ids" => ["stale_blocked_gate"],
        "non_passed_quality_gate_row_ids" => [],
        "non_passed_gate_ids" => [],
        "non_passed_gate_count" => 0
      })

    refresh = %{"source_operational_quality_gate_summary" => quality_gate_summary}

    source_report_summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "source_report_count" => 1,
             "source_report_row_count" => 0,
             "source_report_quality_gate_count" => 1,
             "source_report_quality_gate_row_count" => 0,
             "source_report_quality_gate_readiness_level_counts" => %{"import_eligible" => 1},
             "source_report_quality_gate_import_classification_counts" => %{
               "importable" => 1
             },
             "source_report_quality_gate_status_counts" => %{"passed" => 1},
             "source_report_quality_gate_gate_count" => 0,
             "source_report_quality_gate_review_gate_count" => 0,
             "source_report_quality_gate_blocked_gate_count" => 0,
             "source_reports" => %{
               "quality_gate_report" => %{
                 "row_count" => 0,
                 "gate_count" => 0,
                 "review_gate_count" => 0,
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

    replay_summary = CandidateRefresh.quality_gate_replay_summary(refresh)

    assert %{
             "source_report_count" => 1,
             "source_report_row_count" => 0,
             "readiness_level_counts" => %{"import_eligible" => 1},
             "import_classification_counts" => %{"importable" => 1},
             "status_counts" => %{"passed" => 1},
             "gate_count" => 0,
             "review_gate_count" => 0,
             "blocked_gate_count" => 0,
             "branch_local_review_pressure" => true
           } = replay_summary

    assert Map.get(replay_summary, "quality_gate_row_ids_by_status", %{}) == %{}
    assert Map.get(replay_summary, "quality_gate_row_ids_by_classification", %{}) == %{}
    assert Map.get(replay_summary, "quality_gate_ids_by_classification", %{}) == %{}
    assert Map.get(replay_summary, "review_required_quality_gate_row_ids", []) == []
    assert Map.get(replay_summary, "blocked_quality_gate_row_ids", []) == []
    assert Map.get(replay_summary, "non_passed_gate_count", 0) == 0
    assert Map.get(replay_summary, "passed_gate_ids", []) == []
    assert Map.get(replay_summary, "review_required_gate_ids", []) == []
    assert Map.get(replay_summary, "blocked_gate_ids", []) == []
    assert Map.get(replay_summary, "non_passed_gate_ids", []) == []
    assert Map.get(replay_summary, "non_passed_quality_gate_row_ids", []) == []
  end

  test "quality gate replay accepts wrapped operational quality gate summaries" do
    quality_gate_summary = quality_gate_summary_fixture()

    wrapper = %{
      "schema_contract" => "result_artifact.v1",
      "provenance" => %{"trust_boundary" => "quality_gate_adapter"},
      "source_operational_quality_gate_summary" => quality_gate_summary
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
               "source_result_artifact[0].source_operational_quality_gate_summary"
             ],
             "source_summary_schema_contract_counts" => %{
               "operational_quality_gate_summary.v1" => 1
             },
             "gate_status_counts" => %{"blocked" => 1, "review_required" => 1},
             "quality_gate_row_ids_by_status" => %{
               "blocked" => ["quality_gate:activity_1:cadence_import"],
               "review_required" => ["quality_gate:activity_1:mission_policy"]
             },
             "quality_gate_row_ids_by_classification" => %{
               "blocked" => ["quality_gate:activity_1:cadence_import"],
               "review_only" => ["quality_gate:activity_1:mission_policy"]
             },
             "quality_gate_ids_by_classification" => %{
               "blocked" => ["cadence_import"],
               "review_only" => ["mission_policy"]
             },
             "non_passed_gate_count" => 2,
             "review_required_gate_ids" => ["mission_policy"],
             "blocked_gate_ids" => ["cadence_import"],
             "non_passed_gate_ids" => ["cadence_import", "mission_policy"],
             "non_passed_quality_gate_row_ids" => [
               "quality_gate:activity_1:cadence_import",
               "quality_gate:activity_1:mission_policy"
             ],
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["quality_gate_adapter", "quality_gate_summary_fixture"]
           } = get_in(artifact, ["provenance", "source_reports", "quality_gate_report"])

    assert %{
             "source_report_paths" => [
               "source_result_artifact[0].source_operational_quality_gate_summary"
             ],
             "source_summary_schema_contract_counts" => %{
               "operational_quality_gate_summary.v1" => 1
             },
             "quality_gate_row_ids_by_classification" => %{
               "blocked" => ["quality_gate:activity_1:cadence_import"],
               "review_only" => ["quality_gate:activity_1:mission_policy"]
             },
             "quality_gate_ids_by_classification" => %{
               "blocked" => ["cadence_import"],
               "review_only" => ["mission_policy"]
             },
             "non_passed_gate_count" => 2,
             "review_required_gate_ids" => ["mission_policy"],
             "blocked_gate_ids" => ["cadence_import"],
             "non_passed_gate_ids" => ["cadence_import", "mission_policy"],
             "non_passed_quality_gate_row_ids" => [
               "quality_gate:activity_1:cadence_import",
               "quality_gate:activity_1:mission_policy"
             ],
             "branch_local_review_pressure" => true
           } = CandidateRefresh.quality_gate_replay_summary(artifact)

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "build excludes the exact candidate named by a blocked planned-activity quality gate" do
    blocked_candidate_id = "leo_1_observe_target_a_1"

    quality_gate_report = candidate_quality_gate_report(blocked_candidate_id, :blocked)

    assert {:ok, %{"schema_contract" => "quality_gate_report.v1", "status" => "pass"}} =
             Schema.validate_artifact(quality_gate_report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("prior_candidate_activities", [
            %{
              "id" => blocked_candidate_id,
              "type" => "observe",
              "scenario_id" => "leo_1",
              "target_id" => "target_a",
              "starts_at_s" => 120.0,
              "ends_at_s" => 240.0
            }
          ])
          |> put_in(
            ["accepted_planning_state", "quality_gate_report"],
            quality_gate_report
          ),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_downlink_equator_prime_1"
           ]

    assert %{
             "source" => "candidate_refresh.candidate_scoped_quality_gate",
             "candidate_count" => 2,
             "rejected_count" => 1,
             "rejected_candidate_ids" => [^blocked_candidate_id],
             "rejection_reason_counts" => %{"quality_gate_failed" => 1}
           } = rejection_report = artifact["candidate_rejection_report"]

    assert %{
             "candidate_id" => ^blocked_candidate_id,
             "activity_context" => %{
               "provenance" => %{
                 "quality_gate_candidate_filter" => %{
                   "source_schema_contract" => "quality_gate_report.v1",
                   "source_report_paths" => ["accepted_planning_state.quality_gate_report"],
                   "source_artifact_types" => ["planned_activity.v1"],
                   "source_artifact_ids" => [^blocked_candidate_id],
                   "blocked_candidate_ids" => [^blocked_candidate_id],
                   "quality_gate_statuses" => ["blocked"],
                   "selection_scopes" => ["candidate_artifact"],
                   "trust_boundaries" => ["candidate_quality_gate_fixture"]
                 }
               }
             }
           } =
             Enum.find(
               rejection_report["rows"],
               &(&1["candidate_id"] == blocked_candidate_id)
             )

    assert [
             %{
               "id" => ^blocked_candidate_id,
               "invalidated_reason" => "dropped_by_candidate_scoped_quality_gate",
               "replacement_candidate_id" => ^blocked_candidate_id
             }
           ] = artifact["invalidated_candidates"]

    assert "blocked quality gates excluded exact source-artifact candidates" in artifact[
             "warnings"
           ]

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "review_type" => "candidate_rejection_review",
             "candidate_id" => ^blocked_candidate_id
           } = Enum.find(review["rows"], &(&1["candidate_id"] == blocked_candidate_id))

    assert %{
             "source_review_type" => "candidate_rejection_review",
             "subject_id" => ^blocked_candidate_id
           } =
             Enum.find(
               import["rows"],
               &(&1["source_review_type"] == "candidate_rejection_review" and
                   &1["subject_id"] == blocked_candidate_id)
             )

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "candidate_rejection_report.v1"}} =
             Schema.validate_artifact(rejection_report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "nonmatching and non-blocked quality gates remain selection-neutral" do
    candidate_id = "leo_1_observe_target_a_1"

    nonmatching_report =
      "activity_1"
      |> candidate_quality_gate_report(:blocked)
      |> Map.put("blocked_quality_gate_row_ids", [
        "quality_gate:#{candidate_id}:cadence_import"
      ])

    nonmatching_artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(
            ["accepted_planning_state", "quality_gate_report"],
            nonmatching_report
          ),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    review_only_report = candidate_quality_gate_report(candidate_id, :review_required)

    nonblocked_artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(
            ["accepted_planning_state", "quality_gate_report"],
            review_only_report
          ),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    wrong_source_type_report =
      candidate_quality_gate_report(candidate_id, :blocked, "campaign_plan.v1")

    wrong_source_type_artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(
            ["accepted_planning_state", "quality_gate_report"],
            wrong_source_type_report
          ),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    compact_summary =
      candidate_id
      |> candidate_quality_gate_report(:blocked)
      |> OrbitalDynamics.operational_quality_gate_summary()

    assert {:ok, %{"schema_contract" => "operational_quality_gate_summary.v1"}} =
             Schema.validate_artifact(compact_summary)

    compact_summary_artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(
            ["accepted_planning_state", "operational_quality_gate_summary"],
            compact_summary
          ),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    invalid_report =
      candidate_id
      |> candidate_quality_gate_report(:blocked)
      |> Map.put("model", "unvalidated_quality_gate_fixture")

    assert {:error, %{"schema_contract" => "quality_gate_report.v1", "status" => "fail"}} =
             Schema.validate_artifact(invalid_report)

    invalid_report_artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(["accepted_planning_state", "quality_gate_report"], invalid_report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    stale_lineage_report =
      candidate_id
      |> candidate_quality_gate_report(:blocked)
      |> Map.put(
        "source_readiness_report_id",
        "operational_readiness:planned_activity.v1:stale_observe_target_a_1"
      )

    assert {:error, %{"errors" => stale_lineage_errors}} =
             Schema.validate_artifact(stale_lineage_report)

    assert Enum.any?(
             stale_lineage_errors,
             &(&1["path"] == "$.source_readiness_report_id" and
                 &1["message"] == "must match source artifact identity")
           )

    stale_lineage_artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(
            ["accepted_planning_state", "quality_gate_report"],
            stale_lineage_report
          ),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    for artifact <- [
          nonmatching_artifact,
          nonblocked_artifact,
          wrong_source_type_artifact,
          compact_summary_artifact,
          invalid_report_artifact,
          stale_lineage_artifact
        ] do
      assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
               "leo_1_observe_target_a_1",
               "leo_1_downlink_equator_prime_1"
             ]

      refute "blocked quality gates excluded exact source-artifact candidates" in artifact[
               "warnings"
             ]

      assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
               Schema.validate_artifact(artifact)
    end

    assert nonmatching_artifact["candidate_rejection_report"]["rejected_count"] == 0
    refute Map.has_key?(nonblocked_artifact, "candidate_rejection_report")
    refute Map.has_key?(wrong_source_type_artifact, "candidate_rejection_report")
    refute Map.has_key?(compact_summary_artifact, "candidate_rejection_report")
    refute Map.has_key?(invalid_report_artifact, "candidate_rejection_report")
    refute Map.has_key?(stale_lineage_artifact, "candidate_rejection_report")
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

  defp quality_gate_summary_fixture do
    review_row = %{
      "id" => "quality_gate:activity_1:mission_policy",
      "gate_id" => "mission_policy",
      "status" => "review_required",
      "classification" => "review_only"
    }

    blocked_row = %{
      "id" => "quality_gate:activity_1:cadence_import",
      "gate_id" => "cadence_import",
      "status" => "blocked",
      "classification" => "blocked"
    }

    %{
      "schema_contract" => "operational_quality_gate_summary.v1",
      "model" => "artifact_only_quality_gate_summary",
      "source" => "quality_gate_report.v1",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "activity_1",
      "source_quality_gate_report_id" => "quality_gate:planned_activity.v1:activity_1",
      "source_readiness_report_id" => "operational_readiness:planned_activity.v1:activity_1",
      "readiness_level" => "blocked",
      "import_classification" => "blocked",
      "status" => "blocked",
      "handoff_only" => true,
      "execution_allowed" => false,
      "cadence_write_allowed" => false,
      "operator_authority_granted" => false,
      "execution_boundary" => "blocked_until_operator_resolution",
      "gate_count" => 2,
      "passed_gate_count" => 0,
      "review_gate_count" => 1,
      "analysis_gate_count" => 0,
      "blocked_gate_count" => 1,
      "non_passed_gate_count" => 2,
      "gate_status_counts" => %{"blocked" => 1, "review_required" => 1},
      "gate_classification_counts" => %{"blocked" => 1, "review_only" => 1},
      "gate_ids_by_status" => %{
        "blocked" => ["cadence_import"],
        "review_required" => ["mission_policy"]
      },
      "gate_ids_by_classification" => %{
        "blocked" => ["cadence_import"],
        "review_only" => ["mission_policy"]
      },
      "quality_gate_row_ids_by_status" => %{
        "blocked" => ["quality_gate:activity_1:cadence_import"],
        "review_required" => ["quality_gate:activity_1:mission_policy"]
      },
      "quality_gate_row_ids_by_classification" => %{
        "blocked" => ["quality_gate:activity_1:cadence_import"],
        "review_only" => ["quality_gate:activity_1:mission_policy"]
      },
      "passed_gate_ids" => [],
      "review_required_gate_ids" => ["mission_policy"],
      "analysis_only_gate_ids" => [],
      "blocked_gate_ids" => ["cadence_import"],
      "non_passed_gate_ids" => ["cadence_import", "mission_policy"],
      "non_passed_quality_gate_row_ids" => [
        "quality_gate:activity_1:cadence_import",
        "quality_gate:activity_1:mission_policy"
      ],
      "non_passed_rows" => [review_row, blocked_row],
      "rows" => [review_row, blocked_row],
      "assumptions" => %{
        "source" => "quality_gate_report.v1",
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_quality_gate_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary"
      },
      "provenance" => %{"trust_boundary" => "quality_gate_summary_fixture"}
    }
  end

  defp candidate_quality_gate_report(
         candidate_id,
         status,
         source_artifact_type \\ "planned_activity.v1"
       ) do
    {import_status, cadence_import_status} =
      case status do
        :blocked -> {"blocked_missing_cadence_import", "invalid"}
        :review_required -> {"review_required_before_import", "present"}
      end

    %{
      "schema_contract" => "cadence_import_manifest.v1",
      "model" => "candidate_quality_gate_manifest_fixture",
      "manifest_id" => "manifest:#{candidate_id}",
      "source_artifact_type" => source_artifact_type,
      "source_artifact_id" => candidate_id,
      "model_limits" => ["adapter_handoff_only"],
      "rows" => [
        %{
          "id" => "import:#{candidate_id}",
          "rank" => 1,
          "import_action" => "review_candidate_activity",
          "import_status" => import_status,
          "cadence_import_status" => cadence_import_status
        }
      ]
    }
    |> OrbitalDynamics.operational_quality_gate_report()
    |> Map.put("provenance", %{"trust_boundary" => "candidate_quality_gate_fixture"})
  end
end
