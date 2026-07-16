defmodule OrbitalDynamics.CandidateRefresh.TimelineActivityPreconditionReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, CandidateRefresh, OperatorReview, Timeline}

  test "source report summary replays timeline activity precondition summaries from direct review and import handoffs" do
    summary =
      Timeline.activity_precondition_summary(%{
        id: :cmd_preflight,
        type: :command,
        payload_available: false,
        degraded: true,
        resource_blocking_dimension: :power,
        dependency_activity_ids: [:health_check_1, :obs_1, :obs_1],
        dependency_timeline_ids: [:"timeline:health_check_1", :"timeline:health_check_1"],
        exclusive_with_activity_ids: [:dl_conflict, :dl_conflict],
        exclusive_with_timeline_ids: [:"timeline:dl_conflict", :"timeline:dl_conflict"],
        allow_overlap: true,
        metadata: %{timeline_id: :"timeline:cmd_preflight"}
      })
      |> Map.put("provenance", %{"trust_boundary" => "ops_activity_precondition"})

    invalid_summary = Timeline.activity_precondition_summary(%{id: :bad_missing_type})

    refresh = %{
      "source_timeline_activity_precondition_summary" => summary,
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "provenance" => %{"trust_boundary" => "ops_activity_precondition"},
          "timeline_activity_precondition_summary" => invalid_summary
        }
      ],
      "source_operator_review_package" =>
        OperatorReview.from_timeline_activity_precondition_summary(summary),
      "source_cadence_import_manifest" =>
        CadenceImport.from_timeline_activity_precondition_summary(summary)
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_counts_by_family" => %{
               "timeline_activity_precondition_summary" => 4
             },
             "source_report_row_counts_by_family" => %{
               "timeline_activity_precondition_summary" => 9
             },
             "source_report_timeline_activity_precondition_contract" =>
               "timeline_activity_precondition_summary.v1",
             "source_report_timeline_activity_precondition_count" => 4,
             "source_report_timeline_activity_precondition_row_count" => 9,
             "source_report_timeline_activity_precondition_paths" => [
               "source_timeline_activity_precondition_summary",
               "source_result_artifact[0].timeline_activity_precondition_summary",
               "source_operator_review_package.rows.source_timeline_activity_precondition_summary",
               "source_cadence_import_manifest.rows.source_review_row.source_timeline_activity_precondition_summary"
             ],
             "source_report_timeline_activity_precondition_source_summary_model_counts" => %{
               "artifact_only_timeline_activity_precondition_summary" => 4
             },
             "source_report_timeline_activity_precondition_source_summary_schema_contract_counts" =>
               %{
                 "timeline_activity_precondition_summary.v1" => 4
               },
             "source_report_timeline_activity_precondition_status_counts" => %{
               "blocked" => 3,
               "review_required" => 1
             },
             "source_report_timeline_activity_precondition_blocked_precondition_count" => 6,
             "source_report_timeline_activity_precondition_review_precondition_count" => 3,
             "source_report_timeline_activity_precondition_blocked_precondition_type_counts" => %{
               "payload_unavailable" => 3,
               "resource_block_declared" => 3
             },
             "source_report_timeline_activity_precondition_review_precondition_type_counts" => %{
               "degraded_mode" => 3
             },
             "source_report_timeline_activity_precondition_invalid_activity_input_count" => 1,
             "source_report_timeline_activity_precondition_invalid_activity_input_reason_counts" =>
               %{
                 "missing_activity_type" => 1
               },
             "source_report_timeline_activity_precondition_invalid_activity_input_reasons" => [
               "missing_activity_type"
             ],
             "source_report_timeline_activity_precondition_activity_id_counts" => %{
               "bad_missing_type" => 2,
               "cmd_preflight" => 4
             },
             "source_report_timeline_activity_precondition_timeline_id_counts" => %{
               "timeline:cmd_preflight" => 4,
               "timeline:invalid_activity_input:bad_missing_type" => 2
             },
             "source_report_timeline_activity_precondition_dependency_activity_id_counts" => %{
               "health_check_1" => 3,
               "obs_1" => 3
             },
             "source_report_timeline_activity_precondition_dependency_timeline_id_counts" => %{
               "timeline:health_check_1" => 3
             },
             "source_report_timeline_activity_precondition_exclusive_with_activity_id_counts" =>
               %{
                 "dl_conflict" => 3
               },
             "source_report_timeline_activity_precondition_exclusive_with_timeline_id_counts" =>
               %{
                 "timeline:dl_conflict" => 3
               },
             "source_report_timeline_activity_precondition_duplicate_dependency_activity_id_counts" =>
               %{
                 "obs_1" => 3
               },
             "source_report_timeline_activity_precondition_duplicate_dependency_timeline_id_counts" =>
               %{
                 "timeline:health_check_1" => 3
               },
             "source_report_timeline_activity_precondition_duplicate_exclusivity_activity_id_counts" =>
               %{
                 "dl_conflict" => 3
               },
             "source_report_timeline_activity_precondition_duplicate_exclusivity_timeline_id_counts" =>
               %{
                 "timeline:dl_conflict" => 3
               },
             "source_report_timeline_activity_precondition_allow_overlap_counts" => %{"true" => 3},
             "source_report_timeline_activity_precondition_branch_local_timeline_activity_precondition_pressure" =>
               true,
             "source_report_timeline_activity_precondition_branch_local_review_pressure" => true,
             "source_report_timeline_activity_precondition_branch_local_dependency_pressure" =>
               true,
             "source_report_timeline_activity_precondition_branch_local_exclusivity_pressure" =>
               true,
             "source_report_timeline_activity_precondition_branch_local_invalid_input_pressure" =>
               true,
             "source_report_timeline_activity_precondition_branch_local_routing_pressure" => true,
             "source_reports" => %{
               "timeline_activity_precondition_summary" => %{
                 "contract" => "timeline_activity_precondition_summary.v1",
                 "count" => 4,
                 "row_count" => 9,
                 "precondition_status_counts" => %{
                   "blocked" => 3,
                   "review_required" => 1
                 },
                 "blocked_precondition_count" => 6,
                 "review_precondition_count" => 3,
                 "blocked_precondition_type_counts" => %{
                   "payload_unavailable" => 3,
                   "resource_block_declared" => 3
                 },
                 "review_precondition_type_counts" => %{"degraded_mode" => 3},
                 "invalid_activity_input_count" => 1,
                 "invalid_activity_input_reason_counts" => %{
                   "missing_activity_type" => 1
                 },
                 "dependency_activity_id_counts" => %{
                   "health_check_1" => 3,
                   "obs_1" => 3
                 },
                 "dependency_timeline_id_counts" => %{"timeline:health_check_1" => 3},
                 "exclusive_with_activity_id_counts" => %{"dl_conflict" => 3},
                 "exclusive_with_timeline_id_counts" => %{"timeline:dl_conflict" => 3},
                 "duplicate_dependency_activity_id_counts" => %{"obs_1" => 3},
                 "duplicate_dependency_timeline_id_counts" => %{"timeline:health_check_1" => 3},
                 "duplicate_exclusivity_activity_id_counts" => %{"dl_conflict" => 3},
                 "duplicate_exclusivity_timeline_id_counts" => %{"timeline:dl_conflict" => 3},
                 "allow_overlap_counts" => %{"true" => 3},
                 "source_summary_model_counts" => %{
                   "artifact_only_timeline_activity_precondition_summary" => 4
                 },
                 "source_summary_schema_contract_counts" => %{
                   "timeline_activity_precondition_summary.v1" => 4
                 },
                 "paths" => [
                   "source_timeline_activity_precondition_summary",
                   "source_result_artifact[0].timeline_activity_precondition_summary",
                   "source_operator_review_package.rows.source_timeline_activity_precondition_summary",
                   "source_cadence_import_manifest.rows.source_review_row.source_timeline_activity_precondition_summary"
                 ],
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => ["ops_activity_precondition"]
               }
             }
           } = source_summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = CandidateRefresh.timeline_activity_precondition_replay_summary(refresh)

    assert %{
             "model" =>
               "artifact_only_candidate_refresh_timeline_activity_precondition_replay_summary",
             "source" =>
               "candidate_refresh.source_report_provenance.timeline_activity_precondition_summary",
             "contract" => "timeline_activity_precondition_summary.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 9,
             "source_report_paths" => [
               "source_timeline_activity_precondition_summary",
               "source_result_artifact[0].timeline_activity_precondition_summary",
               "source_operator_review_package.rows.source_timeline_activity_precondition_summary",
               "source_cadence_import_manifest.rows.source_review_row.source_timeline_activity_precondition_summary"
             ],
             "precondition_status_counts" => %{"blocked" => 3, "review_required" => 1},
             "blocked_precondition_count" => 6,
             "review_precondition_count" => 3,
             "blocked_precondition_type_counts" => %{
               "payload_unavailable" => 3,
               "resource_block_declared" => 3
             },
             "review_precondition_type_counts" => %{"degraded_mode" => 3},
             "invalid_activity_input_count" => 1,
             "invalid_activity_input_reason_counts" => %{"missing_activity_type" => 1},
             "dependency_activity_id_counts" => %{"health_check_1" => 3, "obs_1" => 3},
             "dependency_timeline_id_counts" => %{"timeline:health_check_1" => 3},
             "exclusive_with_activity_id_counts" => %{"dl_conflict" => 3},
             "exclusive_with_timeline_id_counts" => %{"timeline:dl_conflict" => 3},
             "duplicate_dependency_activity_id_counts" => %{"obs_1" => 3},
             "duplicate_dependency_timeline_id_counts" => %{"timeline:health_check_1" => 3},
             "duplicate_exclusivity_activity_id_counts" => %{"dl_conflict" => 3},
             "duplicate_exclusivity_timeline_id_counts" => %{"timeline:dl_conflict" => 3},
             "allow_overlap_counts" => %{"true" => 3},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["ops_activity_precondition"],
             "branch_local_timeline_activity_precondition_pressure" => true,
             "branch_local_activity_precondition_review_pressure" => true,
             "branch_local_activity_precondition_dependency_pressure" => true,
             "branch_local_activity_precondition_exclusivity_pressure" => true,
             "branch_local_activity_precondition_invalid_input_pressure" => true,
             "branch_local_activity_precondition_routing_pressure" => true,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
               "replay_scope" =>
                 "timeline_activity_precondition_summary_source_report_provenance_only",
               "operator_authority" =>
                 "not_granted_by_timeline_activity_precondition_replay_summary",
               "timeline_mutation" => "not_performed_by_summary",
               "activity_precondition_evaluation" => "not_performed_by_summary",
               "resource_authority" => "not_reserved_by_summary",
               "candidate_selection" => "not_performed_by_summary",
               "import_approval" =>
                 "not_granted_by_timeline_activity_precondition_replay_summary",
               "cadence_write" => "not_performed_by_summary",
               "command_execution" => "not_performed_by_summary",
               "candidate_generation" => "not_performed_by_summary"
             }
           } = replay_summary

    assert OrbitalDynamics.candidate_refresh_timeline_activity_precondition_replay_summary(
             refresh
           ) == replay_summary

    row_only_review =
      refresh["source_operator_review_package"]
      |> Map.update!("rows", fn rows ->
        Enum.map(rows, &Map.delete(&1, "source_timeline_activity_precondition_summary"))
      end)

    row_only_import =
      refresh["source_cadence_import_manifest"]
      |> Map.update!("rows", fn rows ->
        Enum.map(rows, fn row ->
          row
          |> Map.delete("source_timeline_activity_precondition_summary")
          |> Map.update("source_review_row", %{}, fn source_review_row ->
            Map.delete(source_review_row, "source_timeline_activity_precondition_summary")
          end)
        end)
      end)

    row_only_refresh = %{
      "source_operator_review_package" => row_only_review,
      "source_cadence_import_manifest" => row_only_import
    }

    assert %{
             "source_report_timeline_activity_precondition_count" => 2,
             "source_report_timeline_activity_precondition_duplicate_dependency_activity_id_counts" =>
               %{"obs_1" => 2},
             "source_report_timeline_activity_precondition_duplicate_dependency_timeline_id_counts" =>
               %{"timeline:health_check_1" => 2},
             "source_report_timeline_activity_precondition_duplicate_exclusivity_activity_id_counts" =>
               %{"dl_conflict" => 2},
             "source_report_timeline_activity_precondition_duplicate_exclusivity_timeline_id_counts" =>
               %{"timeline:dl_conflict" => 2}
           } = CandidateRefresh.source_report_summary(row_only_refresh)

    assert %{
             "source_report_count" => 2,
             "duplicate_dependency_activity_id_counts" => %{"obs_1" => 2},
             "duplicate_dependency_timeline_id_counts" => %{"timeline:health_check_1" => 2},
             "duplicate_exclusivity_activity_id_counts" => %{"dl_conflict" => 2},
             "duplicate_exclusivity_timeline_id_counts" => %{"timeline:dl_conflict" => 2}
           } = CandidateRefresh.timeline_activity_precondition_replay_summary(row_only_refresh)

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_summary["source_reports"]}
    }

    assert %{
             "source_report_timeline_activity_precondition_branch_local_timeline_activity_precondition_pressure" =>
               true,
             "source_report_timeline_activity_precondition_branch_local_review_pressure" => true,
             "source_report_timeline_activity_precondition_branch_local_dependency_pressure" =>
               true,
             "source_report_timeline_activity_precondition_branch_local_exclusivity_pressure" =>
               true,
             "source_report_timeline_activity_precondition_branch_local_invalid_input_pressure" =>
               true,
             "source_report_timeline_activity_precondition_branch_local_routing_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.timeline_activity_precondition_replay_summary(artifact) ==
             replay_summary

    assert OrbitalDynamics.candidate_refresh_timeline_activity_precondition_replay_summary(
             artifact
           ) == replay_summary
  end

  test "timeline activity precondition replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.timeline_activity_precondition_replay_summary(artifact)
    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_timeline_activity_precondition_pressure"]
    refute Map.has_key?(source_summary, "source_report_timeline_activity_precondition_contract")
    refute Map.has_key?(source_summary, "source_report_timeline_activity_precondition_count")

    refute Map.has_key?(
             source_summary,
             "source_report_timeline_activity_precondition_row_count"
           )

    refute Map.has_key?(source_summary, "source_report_timeline_activity_precondition_paths")
  end

  test "timeline activity precondition source summaries derive stale aggregate pressure from rows" do
    stale_summary =
      Timeline.activity_precondition_summary(%{
        id: :stale_precondition_refresh,
        type: :command,
        payload_available: false,
        degraded: true,
        resource_blocking_dimension: :power,
        metadata: %{timeline_id: :"timeline:stale_precondition_refresh"}
      })
      |> Map.put("provenance", %{"trust_boundary" => "stale_precondition_refresh_boundary"})
      |> Map.update!("preconditions", fn preconditions ->
        Enum.map(preconditions, fn precondition ->
          precondition
          |> Map.put("blocked_precondition_count", 99)
          |> Map.put("review_precondition_count", 99)
          |> Map.put("blocked_precondition_types", ["bogus_blocked_row_type"])
          |> Map.put("review_precondition_types", ["bogus_review_row_type"])
          |> Map.put("precondition_status", "clear")
        end)
      end)
      |> Map.merge(%{
        "precondition_status" => "clear",
        "blocked_precondition_count" => 0,
        "review_precondition_count" => 0,
        "blocked_precondition_types" => [],
        "review_precondition_types" => []
      })

    refresh = %{
      "source_timeline_activity_precondition_summary" => stale_summary,
      "source_operator_review_package" =>
        OperatorReview.from_timeline_activity_precondition_summary(stale_summary),
      "source_cadence_import_manifest" =>
        CadenceImport.from_timeline_activity_precondition_summary(stale_summary)
    }

    assert %{
             "source_report_timeline_activity_precondition_status_counts" => %{
               "blocked" => 3
             },
             "source_report_timeline_activity_precondition_blocked_precondition_count" => 6,
             "source_report_timeline_activity_precondition_review_precondition_count" => 3,
             "source_report_timeline_activity_precondition_blocked_precondition_type_counts" => %{
               "payload_unavailable" => 3,
               "resource_block_declared" => 3
             },
             "source_report_timeline_activity_precondition_review_precondition_type_counts" => %{
               "degraded_mode" => 3
             },
             "source_report_timeline_activity_precondition_branch_local_timeline_activity_precondition_pressure" =>
               true,
             "source_report_timeline_activity_precondition_branch_local_review_pressure" => true,
             "source_reports" => %{
               "timeline_activity_precondition_summary" => %{
                 "precondition_status_counts" => %{"blocked" => 3},
                 "blocked_precondition_count" => 6,
                 "review_precondition_count" => 3,
                 "blocked_precondition_type_counts" => %{
                   "payload_unavailable" => 3,
                   "resource_block_declared" => 3
                 },
                 "review_precondition_type_counts" => %{"degraded_mode" => 3}
               }
             }
           } = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "precondition_status_counts" => %{"blocked" => 3},
             "blocked_precondition_count" => 6,
             "review_precondition_count" => 3,
             "blocked_precondition_type_counts" => %{
               "payload_unavailable" => 3,
               "resource_block_declared" => 3
             },
             "review_precondition_type_counts" => %{"degraded_mode" => 3},
             "branch_local_timeline_activity_precondition_pressure" => true,
             "branch_local_activity_precondition_review_pressure" => true
           } = CandidateRefresh.timeline_activity_precondition_replay_summary(refresh)

    row_only_refresh = %{
      "source_operator_review_package" =>
        Map.update!(refresh["source_operator_review_package"], "rows", fn rows ->
          Enum.map(rows, &Map.delete(&1, "source_timeline_activity_precondition_summary"))
        end),
      "source_cadence_import_manifest" =>
        Map.update!(refresh["source_cadence_import_manifest"], "rows", fn rows ->
          Enum.map(rows, fn row ->
            row
            |> Map.delete("source_timeline_activity_precondition_summary")
            |> Map.update("source_review_row", %{}, fn source_review_row ->
              Map.delete(source_review_row, "source_timeline_activity_precondition_summary")
            end)
          end)
        end)
    }

    assert %{
             "source_report_timeline_activity_precondition_status_counts" => %{
               "blocked" => 2
             },
             "source_report_timeline_activity_precondition_blocked_precondition_count" => 4,
             "source_report_timeline_activity_precondition_review_precondition_count" => 2,
             "source_report_timeline_activity_precondition_blocked_precondition_type_counts" => %{
               "payload_unavailable" => 2,
               "resource_block_declared" => 2
             },
             "source_report_timeline_activity_precondition_review_precondition_type_counts" => %{
               "degraded_mode" => 2
             }
           } = CandidateRefresh.source_report_summary(row_only_refresh)
  end

  test "timeline activity precondition source summary keeps declared contract without partial identity placeholders" do
    placeholder_fields = [
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.timeline_activity_precondition_summary"]},
      %{"count" => nil, "row_count" => 2},
      %{"count" => 1, "row_count" => nil}
    ]

    for placeholder <- placeholder_fields do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "timeline_activity_precondition_summary" =>
              Map.put(
                placeholder,
                "contract",
                "timeline_activity_precondition_summary.v1"
              )
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      assert source_summary["source_report_timeline_activity_precondition_contract"] ==
               "timeline_activity_precondition_summary.v1"

      refute Map.has_key?(source_summary, "source_report_timeline_activity_precondition_count")

      refute Map.has_key?(
               source_summary,
               "source_report_timeline_activity_precondition_row_count"
             )

      refute Map.has_key?(source_summary, "source_report_timeline_activity_precondition_paths")
    end
  end

  test "timeline activity precondition source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "timeline_activity_precondition_summary" => %{
            "contract" => "timeline_activity_precondition_summary.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.timeline_activity_precondition_summary"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_timeline_activity_precondition_contract"] ==
             "timeline_activity_precondition_summary.v1"

    assert source_summary["source_report_timeline_activity_precondition_count"] == 0
    assert source_summary["source_report_timeline_activity_precondition_row_count"] == 0

    assert source_summary["source_report_timeline_activity_precondition_paths"] == [
             "provenance.source_reports.timeline_activity_precondition_summary"
           ]
  end

  test "timeline activity precondition source summary omits missing identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "timeline_activity_precondition_summary" => %{
            "contract" => "timeline_activity_precondition_summary.v1",
            "count" => 1,
            "row_count" => 2
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_timeline_activity_precondition_contract"] ==
             "timeline_activity_precondition_summary.v1"

    assert source_summary["source_report_timeline_activity_precondition_count"] == 1
    assert source_summary["source_report_timeline_activity_precondition_row_count"] == 2
    refute Map.has_key?(source_summary, "source_report_timeline_activity_precondition_paths")
  end

  test "timeline activity precondition source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "timeline_activity_precondition_summary" => %{
            "contract" => "timeline_activity_precondition_summary.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_timeline_activity_precondition_contract"] ==
             "timeline_activity_precondition_summary.v1"

    assert source_summary["source_report_timeline_activity_precondition_count"] == 1
    assert source_summary["source_report_timeline_activity_precondition_row_count"] == 2
    assert source_summary["source_report_timeline_activity_precondition_paths"] == []
  end
end
