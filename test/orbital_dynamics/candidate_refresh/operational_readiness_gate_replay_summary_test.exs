defmodule OrbitalDynamics.CandidateRefresh.OperationalReadinessGateReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary replays compact operational readiness gate summaries" do
    summary =
      operational_readiness_gate_summary_fixture()
      |> Map.merge(%{
        "gate_ids_by_status" => %{
          "analysis_only" => ["stale_operational_mode"],
          "blocked" => ["stale_cadence_import"],
          "passed" => ["adapter_boundary", "source_contract"],
          "review_required" => ["stale_operator_review"]
        },
        "gate_ids_by_classification" => %{
          "analysis_only" => ["stale_operational_mode"],
          "blocked_by_policy" => ["stale_cadence_import"],
          "importable" => ["adapter_boundary", "source_contract"],
          "operator_review_required" => ["stale_operator_review"]
        },
        "review_required_gate_ids" => ["stale_operator_review"],
        "analysis_only_gate_ids" => ["stale_operational_mode"],
        "blocked_gate_ids" => ["stale_cadence_import"],
        "non_passed_gate_ids" => [
          "stale_cadence_import",
          "stale_operational_mode",
          "stale_operator_review"
        ],
        "non_passed_gates" => [
          %{
            "id" => "operational_mode",
            "status" => "analysis_only",
            "classification" => "analysis_only"
          },
          %{
            "id" => "operator_review",
            "status" => "review_required",
            "classification" => "operator_review_required"
          },
          %{
            "id" => "cadence_import",
            "status" => "blocked",
            "classification" => "blocked_by_policy"
          }
        ]
      })

    refresh = %{
      "accepted_planning_state" => %{"operational_readiness_gate_summary" => summary},
      "mission_state" => %{"source_operational_readiness_gate_summary" => summary},
      "source_operational_readiness_gate_summary" => summary,
      "source_result_artifact" => %{"operational_readiness_gate_summary" => summary}
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_counts_by_contract" => %{
               "operational_readiness_gate_summary.v1" => 4
             },
             "source_report_row_counts_by_contract" => %{
               "operational_readiness_gate_summary.v1" => 4
             },
             "source_report_operational_readiness_contract" =>
               "operational_readiness_gate_summary.v1",
             "source_report_operational_readiness_count" => 4,
             "source_report_operational_readiness_row_count" => 4,
             "source_report_operational_readiness_paths" => [
               "accepted_planning_state.operational_readiness_gate_summary",
               "mission_state.source_operational_readiness_gate_summary",
               "source_operational_readiness_gate_summary",
               "source_result_artifact.operational_readiness_gate_summary"
             ],
             "source_report_operational_readiness_readiness_level_counts" => %{
               "operator_review" => 4
             },
             "source_report_operational_readiness_import_classification_counts" => %{
               "review_only" => 4
             },
             "source_report_operational_readiness_status_counts" => %{
               "review_required" => 4
             },
             "source_report_operational_readiness_gate_count" => 20,
             "source_report_operational_readiness_passed_gate_count" => 8,
             "source_report_operational_readiness_review_gate_count" => 4,
             "source_report_operational_readiness_analysis_gate_count" => 4,
             "source_report_operational_readiness_blocked_gate_count" => 4,
             "source_reports" => %{
               "operational_readiness_report" => %{
                 "paths" => [
                   "accepted_planning_state.operational_readiness_gate_summary",
                   "mission_state.source_operational_readiness_gate_summary",
                   "source_operational_readiness_gate_summary",
                   "source_result_artifact.operational_readiness_gate_summary"
                 ],
                 "contract" => "operational_readiness_gate_summary.v1",
                 "count" => 4,
                 "row_count" => 4,
                 "source_summary_model_counts" => %{
                   "artifact_only_operational_readiness_gate_summary" => 4
                 },
                 "source_summary_schema_contract_counts" => %{
                   "operational_readiness_gate_summary.v1" => 4
                 },
                 "source_artifact_type_counts" => %{"planned_activity.v1" => 4},
                 "readiness_level_counts" => %{"operator_review" => 4},
                 "import_classification_counts" => %{"review_only" => 4},
                 "status_counts" => %{"review_required" => 4},
                 "gate_count" => 20,
                 "passed_gate_count" => 8,
                 "review_gate_count" => 4,
                 "analysis_gate_count" => 4,
                 "blocked_gate_count" => 4,
                 "gate_status_counts" => %{
                   "analysis_only" => 4,
                   "blocked" => 4,
                   "passed" => 8,
                   "review_required" => 4
                 },
                 "gate_classification_counts" => %{
                   "analysis_only" => 4,
                   "blocked_by_policy" => 4,
                   "importable" => 8,
                   "operator_review_required" => 4
                 },
                 "gate_ids_by_status" => %{
                   "analysis_only" => ["operational_mode"],
                   "blocked" => ["cadence_import"],
                   "passed" => ["adapter_boundary", "source_contract"],
                   "review_required" => ["operator_review"]
                 },
                 "gate_ids_by_classification" => %{
                   "analysis_only" => ["operational_mode"],
                   "blocked_by_policy" => ["cadence_import"],
                   "importable" => ["adapter_boundary", "source_contract"],
                   "operator_review_required" => ["operator_review"]
                 },
                 "passed_gate_ids" => ["adapter_boundary", "source_contract"],
                 "review_required_gate_ids" => ["operator_review"],
                 "analysis_only_gate_ids" => ["operational_mode"],
                 "blocked_gate_ids" => ["cadence_import"],
                 "non_passed_gate_ids" => [
                   "cadence_import",
                   "operational_mode",
                   "operator_review"
                 ],
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => ["ops_readiness_gate_summary"]
               }
             }
           } = source_summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = CandidateRefresh.operational_readiness_replay_summary(refresh)

    assert replay_summary["contract"] == "operational_readiness_gate_summary.v1"
    assert replay_summary["source_report_count"] == 4
    assert replay_summary["source_report_row_count"] == 4
    assert replay_summary["gate_count"] == 20
    assert replay_summary["passed_gate_count"] == 8
    assert replay_summary["review_gate_count"] == 4
    assert replay_summary["analysis_gate_count"] == 4
    assert replay_summary["blocked_gate_count"] == 4

    assert replay_summary["gate_status_counts"] == %{
             "analysis_only" => 4,
             "blocked" => 4,
             "passed" => 8,
             "review_required" => 4
           }

    assert replay_summary["gate_ids_by_status"] == %{
             "analysis_only" => ["operational_mode"],
             "blocked" => ["cadence_import"],
             "passed" => ["adapter_boundary", "source_contract"],
             "review_required" => ["operator_review"]
           }

    assert replay_summary["review_required_gate_ids"] == ["operator_review"]
    assert replay_summary["analysis_only_gate_ids"] == ["operational_mode"]
    assert replay_summary["blocked_gate_ids"] == ["cadence_import"]

    assert replay_summary["non_passed_gate_ids"] == [
             "cadence_import",
             "operational_mode",
             "operator_review"
           ]

    assert replay_summary["gate_ids_by_classification"] == %{
             "analysis_only" => ["operational_mode"],
             "blocked_by_policy" => ["cadence_import"],
             "importable" => ["adapter_boundary", "source_contract"],
             "operator_review_required" => ["operator_review"]
           }

    replay_routed_gate_ids =
      replay_summary["gate_ids_by_status"]
      |> Map.values()
      |> List.flatten()

    refute "stale_cadence_import" in replay_routed_gate_ids
    refute "stale_operational_mode" in replay_routed_gate_ids
    refute "stale_operator_review" in replay_routed_gate_ids

    assert replay_summary["trust_boundary_status"] == "declared"
    assert replay_summary["trust_boundaries"] == ["ops_readiness_gate_summary"]
    assert replay_summary["branch_local_review_pressure"]
    refute replay_summary["branch_local_import_pressure"]
    refute replay_summary["branch_local_resource_pressure"]

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_summary["source_reports"]}
    }

    assert CandidateRefresh.operational_readiness_replay_summary(artifact) == replay_summary
  end

  test "source report summary replays wrapped operational readiness gate summaries" do
    direct_summary =
      operational_readiness_gate_summary_fixture()
      |> Map.put("source", "ops_readiness.direct")

    nested_summary =
      operational_readiness_gate_summary_fixture()
      |> Map.put("source", "ops_readiness.nested")

    refresh = %{
      "source_result_artifact" => [
        direct_summary,
        %{
          "schema_contract" => "result_artifact.v1",
          "operational_readiness_gate_summary" => nested_summary
        }
      ]
    }

    source_summary = CandidateRefresh.source_report_summary(refresh)

    assert get_in(source_summary, ["source_reports", "operational_readiness_report", "paths"]) ==
             [
               "source_result_artifact[0]",
               "source_result_artifact[1].operational_readiness_gate_summary"
             ]

    assert get_in(source_summary, ["source_reports", "operational_readiness_report", "contract"]) ==
             "operational_readiness_gate_summary.v1"

    assert get_in(source_summary, ["source_reports", "operational_readiness_report", "count"]) ==
             2

    assert get_in(source_summary, ["source_reports", "operational_readiness_report", "row_count"]) ==
             2

    assert get_in(source_summary, ["source_reports", "operational_readiness_report", "gate_count"]) ==
             10

    replay_summary = CandidateRefresh.operational_readiness_replay_summary(refresh)

    assert replay_summary["source_report_paths"] == [
             "source_result_artifact[0]",
             "source_result_artifact[1].operational_readiness_gate_summary"
           ]

    assert replay_summary["contract"] == "operational_readiness_gate_summary.v1"
    assert replay_summary["gate_count"] == 10
    assert replay_summary["review_gate_count"] == 2
    assert replay_summary["blocked_gate_ids"] == ["cadence_import"]
    assert replay_summary["branch_local_review_pressure"]
  end

  defp operational_readiness_gate_summary_fixture do
    %{
      "schema_contract" => "operational_readiness_gate_summary.v1",
      "model" => "artifact_only_operational_readiness_gate_summary",
      "source" => "operational_readiness_report.v1",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "activity_1",
      "readiness_level" => "operator_review",
      "import_classification" => "review_only",
      "status" => "review_required",
      "gate_count" => 5,
      "passed_gate_count" => 2,
      "review_gate_count" => 1,
      "analysis_gate_count" => 1,
      "blocked_gate_count" => 1,
      "non_passed_gate_count" => 3,
      "gate_status_counts" => %{
        "analysis_only" => 1,
        "blocked" => 1,
        "passed" => 2,
        "review_required" => 1
      },
      "gate_classification_counts" => %{
        "analysis_only" => 1,
        "blocked_by_policy" => 1,
        "importable" => 2,
        "operator_review_required" => 1
      },
      "gate_ids_by_status" => %{
        "analysis_only" => ["operational_mode"],
        "blocked" => ["cadence_import"],
        "passed" => ["adapter_boundary", "source_contract"],
        "review_required" => ["operator_review"]
      },
      "gate_ids_by_classification" => %{
        "analysis_only" => ["operational_mode"],
        "blocked_by_policy" => ["cadence_import"],
        "importable" => ["adapter_boundary", "source_contract"],
        "operator_review_required" => ["operator_review"]
      },
      "passed_gate_ids" => ["adapter_boundary", "source_contract"],
      "review_required_gate_ids" => ["operator_review"],
      "analysis_only_gate_ids" => ["operational_mode"],
      "blocked_gate_ids" => ["cadence_import"],
      "non_passed_gate_ids" => [
        "cadence_import",
        "operational_mode",
        "operator_review"
      ],
      "non_passed_gates" => [
        %{"id" => "operational_mode"},
        %{"id" => "operator_review"},
        %{"id" => "cadence_import"}
      ],
      "gates" => [
        %{"id" => "source_contract", "status" => "passed", "classification" => "importable"},
        %{"id" => "adapter_boundary", "status" => "passed", "classification" => "importable"},
        %{
          "id" => "operational_mode",
          "status" => "analysis_only",
          "classification" => "analysis_only"
        },
        %{
          "id" => "operator_review",
          "status" => "review_required",
          "classification" => "operator_review_required"
        },
        %{
          "id" => "cadence_import",
          "status" => "blocked",
          "classification" => "blocked_by_policy"
        }
      ],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "source" => "operational_readiness_report.v1",
        "operator_authority" => "not_granted_by_summary"
      },
      "model_limits" => [
        "operational_readiness_gate_summary_routes_only",
        "operational_readiness_gate_summary_does_not_approve_or_import"
      ],
      "provenance" => %{"trust_boundary" => "ops_readiness_gate_summary"}
    }
  end
end
