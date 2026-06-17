defmodule OrbitalDynamics.CandidateRefresh.OperationalReadinessReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CadenceImport,
    CandidateRefresh,
    Epoch,
    OperatorReview,
    ResultSet,
    Schema
  }

  test "source report summary aggregates operational readiness routing maps" do
    refresh = %{
      "source_operational_readiness_report" => %{
        "schema_contract" => "operational_readiness_report.v1",
        "readiness_level" => "operator_review",
        "import_classification" => "review_only",
        "status" => "review_required",
        "gate_count" => 5,
        "passed_gate_count" => 1,
        "review_gate_count" => 2,
        "analysis_gate_count" => 1,
        "blocked_gate_count" => 1,
        "gates" => [
          %{
            "id" => "operational_mode",
            "status" => "analysis_only",
            "classification" => "analysis_only",
            "analysis_mode" => "not_for_execution"
          },
          %{
            "id" => "resource_availability",
            "resource_availability_reason_counts" => %{
              "antenna_unavailable" => 1,
              "ground_station_reserved" => 1,
              "payload_unavailable" => 1
            },
            "station_availability_reason_counts" => %{"ground_station_reserved" => 1},
            "resource_blocking_dimension_counts" => %{"communications" => 1}
          }
        ],
        "evidence" => %{
          "ready_for_import_count" => 0,
          "manifest_review_required_count" => 1,
          "blocked_import_count" => 1,
          "missing_import_count" => 1,
          "invalid_cadence_import_count" => 1,
          "review_required_count" => 2,
          "current_freshness_count" => 0,
          "stale_freshness_count" => 2,
          "unknown_freshness_count" => 1,
          "freshness_status_counts" => %{"stale" => 2, "unknown" => 1},
          "schema_validation_pass_count" => 0,
          "schema_validation_fail_count" => 1,
          "schema_validation_error_count" => 2,
          "schema_validation_warning_count" => 1,
          "schema_validation_remediation_count" => 2,
          "schema_validation_status_counts" => %{"fail" => 1},
          "import_status_counts" => %{"review_required_before_import" => 1},
          "cadence_import_status_counts" => %{"missing" => 1},
          "adapter_trust_boundary_declared_count" => 0,
          "adapter_trust_boundary_missing_count" => 1,
          "adapter_trust_boundary_untrusted_count" => 1,
          "adapter_boundary_status_counts" => %{"missing" => 1, "untrusted" => 1},
          "resource_availability_pressure_count" => 3,
          "resource_availability_reason_counts" => %{
            "antenna_unavailable" => 1,
            "ground_station_reserved" => 1,
            "payload_unavailable" => 1
          },
          "station_availability_reason_counts" => %{"ground_station_reserved" => 1},
          "resource_blocking_dimension_counts" => %{"communications" => 1},
          "review_type_counts" => %{"contact_allocation_review" => 1},
          "import_action_counts" => %{"review_contact_allocation" => 1},
          "source_review_type_counts" => %{"contact_allocation_review" => 1},
          "publication_status_counts" => %{
            "published_with_downstream_invalidations" => 1,
            "review_required" => 1
          },
          "dependency_impact_status_counts" => %{"review_required" => 2},
          "publication_authority_counts" => %{"operator_review" => 1},
          "source_artifact_type_counts" => %{"operational_timeline_report.v1" => 1},
          "publication_ids" => ["timeline_publication:ops_review"],
          "source_artifact_ids" => ["operational_timeline:activity_1"],
          "supersedes_artifact_ids" => ["timeline_publication:prior"],
          "downstream_product_ids" => ["cadence_import:activity_1"],
          "invalidated_downstream_product_ids" => ["timeline_product:stale"],
          "dependency_impact_row_count" => 2,
          "impacted_dependency_activity_ids" => ["activity_dependency:antenna"],
          "impacted_dependency_timeline_ids" => ["timeline:dependency"],
          "impacted_exclusive_with_activity_ids" => ["activity:exclusive"],
          "impacted_exclusive_with_timeline_ids" => ["timeline:exclusive"],
          "timeline_diff_row_count" => 2,
          "timeline_diff_changed_count" => 1,
          "timeline_diff_review_required_count" => 1,
          "changed_field_counts" => %{"start_time" => 1},
          "changed_timeline_ids" => ["timeline:changed"],
          "review_timeline_ids" => ["timeline:review"],
          "timeline_ids_by_changed_field" => %{"start_time" => ["timeline:changed"]}
        },
        "provenance" => %{"trust_boundary" => "ops_readiness"}
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_operational_readiness_contract" => "operational_readiness_report.v1",
             "source_report_operational_readiness_count" => 1,
             "source_report_operational_readiness_row_count" => 1,
             "source_report_operational_readiness_paths" => [
               "source_operational_readiness_report"
             ],
             "source_report_operational_readiness_readiness_level_counts" => %{
               "operator_review" => 1
             },
             "source_report_operational_readiness_import_classification_counts" => %{
               "review_only" => 1
             },
             "source_report_operational_readiness_status_counts" => %{
               "review_required" => 1
             },
             "source_report_operational_readiness_gate_count" => 5,
             "source_report_operational_readiness_passed_gate_count" => 1,
             "source_report_operational_readiness_review_gate_count" => 2,
             "source_report_operational_readiness_analysis_gate_count" => 1,
             "source_report_operational_readiness_analysis_mode_counts" => %{
               "not_for_execution" => 1
             },
             "source_report_operational_readiness_blocked_gate_count" => 1,
             "source_report_operational_readiness_manifest_review_required_count" => 1,
             "source_report_operational_readiness_blocked_import_count" => 1,
             "source_report_operational_readiness_missing_import_count" => 1,
             "source_report_operational_readiness_invalid_cadence_import_count" => 1,
             "source_report_operational_readiness_review_required_count" => 2,
             "source_report_operational_readiness_stale_freshness_count" => 2,
             "source_report_operational_readiness_unknown_freshness_count" => 1,
             "source_report_operational_readiness_freshness_status_counts" => %{
               "stale" => 2,
               "unknown" => 1
             },
             "source_report_operational_readiness_schema_validation_fail_count" => 1,
             "source_report_operational_readiness_schema_validation_error_count" => 2,
             "source_report_operational_readiness_schema_validation_remediation_count" => 2,
             "source_report_operational_readiness_schema_validation_status_counts" => %{
               "fail" => 1
             },
             "source_report_operational_readiness_import_status_counts" => %{
               "review_required_before_import" => 1
             },
             "source_report_operational_readiness_cadence_import_status_counts" => %{
               "missing" => 1
             },
             "source_report_operational_readiness_adapter_trust_boundary_missing_count" => 1,
             "source_report_operational_readiness_adapter_trust_boundary_untrusted_count" => 1,
             "source_report_operational_readiness_adapter_boundary_status_counts" => %{
               "missing" => 1,
               "untrusted" => 1
             },
             "source_report_operational_readiness_resource_availability_pressure_count" => 3,
             "source_report_operational_readiness_resource_availability_reason_counts" => %{
               "antenna_unavailable" => 1,
               "ground_station_reserved" => 1,
               "payload_unavailable" => 1
             },
             "source_report_operational_readiness_resource_availability_reason_ids" => [
               "antenna_unavailable",
               "ground_station_reserved",
               "payload_unavailable"
             ],
             "source_report_operational_readiness_station_availability_reason_ids" => [
               "ground_station_reserved"
             ],
             "source_report_operational_readiness_station_availability_reason_counts" => %{
               "ground_station_reserved" => 1
             },
             "source_report_operational_readiness_unavailable_resource_reason_ids" => [
               "antenna_unavailable",
               "payload_unavailable"
             ],
             "source_report_operational_readiness_resource_blocking_dimension_counts" => %{
               "communications" => 1
             },
             "source_report_operational_readiness_review_type_counts" => %{
               "contact_allocation_review" => 1
             },
             "source_report_operational_readiness_import_action_counts" => %{
               "review_contact_allocation" => 1
             },
             "source_report_operational_readiness_publication_status_counts" => %{
               "published_with_downstream_invalidations" => 1,
               "review_required" => 1
             },
             "source_report_operational_readiness_dependency_impact_status_counts" => %{
               "review_required" => 2
             },
             "source_report_operational_readiness_publication_authority_counts" => %{
               "operator_review" => 1
             },
             "source_report_operational_readiness_timeline_publication_source_artifact_type_counts" =>
               %{
                 "operational_timeline_report.v1" => 1
               },
             "source_report_operational_readiness_publication_ids" => [
               "timeline_publication:ops_review"
             ],
             "source_report_operational_readiness_source_artifact_ids" => [
               "operational_timeline:activity_1"
             ],
             "source_report_operational_readiness_supersedes_artifact_ids" => [
               "timeline_publication:prior"
             ],
             "source_report_operational_readiness_downstream_product_ids" => [
               "cadence_import:activity_1"
             ],
             "source_report_operational_readiness_invalidated_downstream_product_ids" => [
               "timeline_product:stale"
             ],
             "source_report_operational_readiness_dependency_impact_row_count" => 2,
             "source_report_operational_readiness_impacted_dependency_activity_ids" => [
               "activity_dependency:antenna"
             ],
             "source_report_operational_readiness_impacted_dependency_timeline_ids" => [
               "timeline:dependency"
             ],
             "source_report_operational_readiness_impacted_exclusive_with_activity_ids" => [
               "activity:exclusive"
             ],
             "source_report_operational_readiness_impacted_exclusive_with_timeline_ids" => [
               "timeline:exclusive"
             ],
             "source_report_operational_readiness_timeline_diff_row_count" => 2,
             "source_report_operational_readiness_timeline_diff_changed_count" => 1,
             "source_report_operational_readiness_timeline_diff_review_required_count" => 1,
             "source_report_operational_readiness_changed_field_counts" => %{
               "start_time" => 1
             },
             "source_report_operational_readiness_changed_timeline_ids" => [
               "timeline:changed"
             ],
             "source_report_operational_readiness_review_timeline_ids" => [
               "timeline:review"
             ],
             "source_report_operational_readiness_timeline_ids_by_changed_field" => %{
               "start_time" => ["timeline:changed"]
             },
             "source_report_operational_readiness_branch_local_review_pressure" => true,
             "source_report_operational_readiness_branch_local_import_pressure" => true,
             "source_report_operational_readiness_branch_local_execution_boundary_pressure" =>
               false,
             "source_report_operational_readiness_branch_local_resource_pressure" => true,
             "source_report_operational_readiness_branch_local_timeline_publication_pressure" =>
               true,
             "source_report_operational_readiness_branch_local_timeline_publication_dependency_pressure" =>
               true,
             "source_report_operational_readiness_branch_local_timeline_publication_changed_field_pressure" =>
               true,
             "source_report_operational_readiness_branch_local_timeline_publication_invalidation_pressure" =>
               true,
             "source_report_operational_readiness_branch_local_timeline_publication_review_pressure" =>
               true,
             "source_reports" => %{
               "operational_readiness_report" => %{
                 "gate_count" => 5,
                 "analysis_mode_counts" => %{"not_for_execution" => 1},
                 "readiness_level_counts" => %{"operator_review" => 1},
                 "publication_status_counts" => %{
                   "published_with_downstream_invalidations" => 1,
                   "review_required" => 1
                 },
                 "timeline_publication_source_artifact_type_counts" => %{
                   "operational_timeline_report.v1" => 1
                 },
                 "timeline_ids_by_changed_field" => %{"start_time" => ["timeline:changed"]},
                 "resource_availability_reason_counts" => %{
                   "antenna_unavailable" => 1,
                   "ground_station_reserved" => 1,
                   "payload_unavailable" => 1
                 },
                 "station_availability_reason_counts" => %{"ground_station_reserved" => 1}
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "model" => "artifact_only_candidate_refresh_operational_readiness_replay_summary",
             "source" =>
               "candidate_refresh.source_report_provenance.operational_readiness_report",
             "contract" => "operational_readiness_report.v1",
             "source_report_count" => 1,
             "source_report_row_count" => 1,
             "source_report_paths" => ["source_operational_readiness_report"],
             "readiness_level_counts" => %{"operator_review" => 1},
             "import_classification_counts" => %{"review_only" => 1},
             "status_counts" => %{"review_required" => 1},
             "gate_count" => 5,
             "passed_gate_count" => 1,
             "review_gate_count" => 2,
             "analysis_gate_count" => 1,
             "analysis_mode_counts" => %{"not_for_execution" => 1},
             "blocked_gate_count" => 1,
             "ready_for_import_count" => 0,
             "manifest_review_required_count" => 1,
             "blocked_import_count" => 1,
             "missing_import_count" => 1,
             "invalid_cadence_import_count" => 1,
             "review_required_count" => 2,
             "current_freshness_count" => 0,
             "stale_freshness_count" => 2,
             "unknown_freshness_count" => 1,
             "freshness_status_counts" => %{"stale" => 2, "unknown" => 1},
             "schema_validation_pass_count" => 0,
             "schema_validation_fail_count" => 1,
             "schema_validation_error_count" => 2,
             "schema_validation_warning_count" => 1,
             "schema_validation_remediation_count" => 2,
             "schema_validation_status_counts" => %{"fail" => 1},
             "import_status_counts" => %{"review_required_before_import" => 1},
             "cadence_import_status_counts" => %{"missing" => 1},
             "adapter_trust_boundary_missing_count" => 1,
             "adapter_trust_boundary_untrusted_count" => 1,
             "adapter_boundary_status_counts" => %{"missing" => 1, "untrusted" => 1},
             "resource_availability_pressure_count" => 3,
             "resource_availability_reason_counts" => %{
               "antenna_unavailable" => 1,
               "ground_station_reserved" => 1,
               "payload_unavailable" => 1
             },
             "resource_availability_reason_ids" => [
               "antenna_unavailable",
               "ground_station_reserved",
               "payload_unavailable"
             ],
             "station_availability_reason_ids" => ["ground_station_reserved"],
             "station_availability_reason_counts" => %{"ground_station_reserved" => 1},
             "unavailable_resource_reason_ids" => [
               "antenna_unavailable",
               "payload_unavailable"
             ],
             "resource_blocking_dimension_counts" => %{"communications" => 1},
             "review_type_counts" => %{"contact_allocation_review" => 1},
             "import_action_counts" => %{"review_contact_allocation" => 1},
             "source_review_type_counts" => %{"contact_allocation_review" => 1},
             "publication_status_counts" => %{
               "published_with_downstream_invalidations" => 1,
               "review_required" => 1
             },
             "dependency_impact_status_counts" => %{"review_required" => 2},
             "publication_authority_counts" => %{"operator_review" => 1},
             "timeline_publication_source_artifact_type_counts" => %{
               "operational_timeline_report.v1" => 1
             },
             "publication_ids" => ["timeline_publication:ops_review"],
             "source_artifact_ids" => ["operational_timeline:activity_1"],
             "supersedes_artifact_ids" => ["timeline_publication:prior"],
             "downstream_product_ids" => ["cadence_import:activity_1"],
             "invalidated_downstream_product_ids" => ["timeline_product:stale"],
             "dependency_impact_row_count" => 2,
             "impacted_dependency_activity_ids" => ["activity_dependency:antenna"],
             "impacted_dependency_timeline_ids" => ["timeline:dependency"],
             "impacted_exclusive_with_activity_ids" => ["activity:exclusive"],
             "impacted_exclusive_with_timeline_ids" => ["timeline:exclusive"],
             "timeline_diff_row_count" => 2,
             "timeline_diff_changed_count" => 1,
             "timeline_diff_review_required_count" => 1,
             "changed_field_counts" => %{"start_time" => 1},
             "changed_timeline_ids" => ["timeline:changed"],
             "review_timeline_ids" => ["timeline:review"],
             "timeline_ids_by_changed_field" => %{"start_time" => ["timeline:changed"]},
             "branch_local_review_pressure" => true,
             "branch_local_import_pressure" => true,
             "branch_local_resource_pressure" => true,
             "branch_local_timeline_publication_pressure" => true,
             "branch_local_timeline_publication_dependency_pressure" => true,
             "branch_local_timeline_publication_changed_field_pressure" => true,
             "branch_local_timeline_publication_invalidation_pressure" => true,
             "branch_local_timeline_publication_review_pressure" => true,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
               "replay_scope" => "operational_readiness_source_report_provenance_only",
               "operator_authority" => "not_granted_by_operational_readiness_replay_summary",
               "cadence_write" => "not_performed_by_summary",
               "candidate_generation" => "not_performed_by_summary"
             }
           } = replay_summary = CandidateRefresh.operational_readiness_replay_summary(refresh)

    assert OrbitalDynamics.candidate_refresh_operational_readiness_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" =>
          Map.put(summary["source_reports"], "quality_gate_report", %{
            "contract" => "quality_gate_report.v1",
            "count" => 1,
            "row_count" => 1,
            "readiness_level_counts" => %{"blocked" => 99},
            "trust_boundary_status" => "declared"
          })
      }
    }

    assert %{
             "source_report_family_count" => 2,
             "source_report_operational_readiness_contract" => "operational_readiness_report.v1",
             "source_report_operational_readiness_count" => 1,
             "source_report_operational_readiness_row_count" => 1,
             "source_report_operational_readiness_paths" => [
               "source_operational_readiness_report"
             ],
             "source_report_operational_readiness_readiness_level_counts" => %{
               "operator_review" => 1
             },
             "source_report_operational_readiness_gate_count" => 5,
             "source_report_operational_readiness_analysis_mode_counts" => %{
               "not_for_execution" => 1
             },
             "source_report_operational_readiness_resource_blocking_dimension_counts" => %{
               "communications" => 1
             },
             "source_report_operational_readiness_station_availability_reason_counts" => %{
               "ground_station_reserved" => 1
             },
             "source_report_operational_readiness_branch_local_review_pressure" => true,
             "source_report_operational_readiness_branch_local_import_pressure" => true,
             "source_report_operational_readiness_branch_local_execution_boundary_pressure" =>
               false,
             "source_report_operational_readiness_branch_local_resource_pressure" => true,
             "source_report_operational_readiness_branch_local_timeline_publication_pressure" =>
               true,
             "source_report_operational_readiness_branch_local_timeline_publication_dependency_pressure" =>
               true,
             "source_report_operational_readiness_branch_local_timeline_publication_changed_field_pressure" =>
               true,
             "source_report_operational_readiness_branch_local_timeline_publication_invalidation_pressure" =>
               true,
             "source_report_operational_readiness_branch_local_timeline_publication_review_pressure" =>
               true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.operational_readiness_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_operational_readiness_replay_summary(artifact) ==
             replay_summary
  end

  test "source report summary replays compact operational import eligibility summaries" do
    summary = operational_import_eligibility_summary_fixture()

    refresh = %{
      "accepted_planning_state" => %{"operational_import_eligibility_summary" => summary},
      "mission_state" => %{"source_operational_import_eligibility_summary" => summary},
      "source_operational_import_eligibility_summary" => summary,
      "source_result_artifact" => %{"operational_import_eligibility_summary" => summary}
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_counts_by_contract" => %{
               "operational_import_eligibility_summary.v1" => 4
             },
             "source_report_row_counts_by_contract" => %{
               "operational_import_eligibility_summary.v1" => 4
             },
             "source_report_operational_readiness_contract" =>
               "operational_import_eligibility_summary.v1",
             "source_report_operational_readiness_count" => 4,
             "source_report_operational_readiness_row_count" => 4,
             "source_report_operational_readiness_paths" => [
               "accepted_planning_state.operational_import_eligibility_summary",
               "mission_state.source_operational_import_eligibility_summary",
               "source_operational_import_eligibility_summary",
               "source_result_artifact.operational_import_eligibility_summary"
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
                   "accepted_planning_state.operational_import_eligibility_summary",
                   "mission_state.source_operational_import_eligibility_summary",
                   "source_operational_import_eligibility_summary",
                   "source_result_artifact.operational_import_eligibility_summary"
                 ],
                 "contract" => "operational_import_eligibility_summary.v1",
                 "count" => 4,
                 "row_count" => 4,
                 "source_summary_model_counts" => %{
                   "artifact_only_import_eligibility_summary" => 4
                 },
                 "source_summary_schema_contract_counts" => %{
                   "operational_import_eligibility_summary.v1" => 4
                 },
                 "source_artifact_type_counts" => %{"planned_activity.v1" => 4},
                 "readiness_level_counts" => %{"operator_review" => 4},
                 "import_classification_counts" => %{"review_only" => 4},
                 "status_counts" => %{"review_required" => 4},
                 "import_ineligible_count" => 4,
                 "gate_count" => 20,
                 "passed_gate_count" => 8,
                 "review_gate_count" => 4,
                 "analysis_gate_count" => 4,
                 "blocked_gate_count" => 4,
                 "non_passed_gate_count" => 12,
                 "non_passed_gate_ids" => [
                   "cadence_import",
                   "operational_mode",
                   "operator_review"
                 ],
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => ["ops_import_eligibility_summary"]
               }
             }
           } = source_summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = CandidateRefresh.operational_readiness_replay_summary(refresh)

    assert replay_summary["contract"] == "operational_import_eligibility_summary.v1"
    assert replay_summary["source_report_count"] == 4
    assert replay_summary["source_report_row_count"] == 4
    assert replay_summary["import_eligible_count"] == 0
    assert replay_summary["import_ineligible_count"] == 4
    assert replay_summary["gate_count"] == 20
    assert replay_summary["passed_gate_count"] == 8
    assert replay_summary["review_gate_count"] == 4
    assert replay_summary["analysis_gate_count"] == 4
    assert replay_summary["blocked_gate_count"] == 4
    assert replay_summary["non_passed_gate_count"] == 12

    assert replay_summary["non_passed_gate_ids"] == [
             "cadence_import",
             "operational_mode",
             "operator_review"
           ]

    assert replay_summary["trust_boundary_status"] == "declared"
    assert replay_summary["trust_boundaries"] == ["ops_import_eligibility_summary"]
    assert replay_summary["branch_local_review_pressure"]
    assert replay_summary["branch_local_import_pressure"]
    refute replay_summary["branch_local_resource_pressure"]

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_summary["source_reports"]}
    }

    assert CandidateRefresh.operational_readiness_replay_summary(artifact) == replay_summary
  end

  test "source report summary replays wrapped operational import eligibility summaries" do
    direct_summary =
      operational_import_eligibility_summary_fixture()
      |> Map.put("source", "ops_import.direct")

    nested_summary =
      operational_import_eligibility_summary_fixture()
      |> Map.put("source", "ops_import.nested")

    refresh = %{
      "source_result_artifact" => [
        direct_summary,
        %{
          "schema_contract" => "result_artifact.v1",
          "operational_import_eligibility_summary" => nested_summary
        }
      ]
    }

    source_summary = CandidateRefresh.source_report_summary(refresh)

    assert get_in(source_summary, ["source_reports", "operational_readiness_report", "paths"]) ==
             [
               "source_result_artifact[0]",
               "source_result_artifact[1].operational_import_eligibility_summary"
             ]

    assert get_in(source_summary, ["source_reports", "operational_readiness_report", "contract"]) ==
             "operational_import_eligibility_summary.v1"

    assert get_in(source_summary, ["source_reports", "operational_readiness_report", "count"]) ==
             2

    assert get_in(source_summary, ["source_reports", "operational_readiness_report", "row_count"]) ==
             2

    assert get_in(source_summary, [
             "source_reports",
             "operational_readiness_report",
             "import_ineligible_count"
           ]) == 2

    assert get_in(source_summary, [
             "source_reports",
             "operational_readiness_report",
             "non_passed_gate_count"
           ]) == 6

    replay_summary = CandidateRefresh.operational_readiness_replay_summary(refresh)

    assert replay_summary["source_report_paths"] == [
             "source_result_artifact[0]",
             "source_result_artifact[1].operational_import_eligibility_summary"
           ]

    assert replay_summary["contract"] == "operational_import_eligibility_summary.v1"
    assert replay_summary["import_ineligible_count"] == 2
    assert replay_summary["non_passed_gate_count"] == 6
    assert replay_summary["branch_local_import_pressure"]
  end

  test "source report summary replays compact operational execution boundary summaries" do
    summary = operational_execution_boundary_summary_fixture()

    refresh = %{
      "accepted_planning_state" => %{"operational_execution_boundary_summary" => summary},
      "mission_state" => %{"source_operational_execution_boundary_summary" => summary},
      "source_operational_execution_boundary_summary" => summary,
      "source_result_artifact" => %{"operational_execution_boundary_summary" => summary}
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_counts_by_contract" => %{
               "operational_execution_boundary_summary.v1" => 4
             },
             "source_report_row_counts_by_contract" => %{
               "operational_execution_boundary_summary.v1" => 4
             },
             "source_report_operational_readiness_contract" =>
               "operational_execution_boundary_summary.v1",
             "source_report_operational_readiness_count" => 4,
             "source_report_operational_readiness_row_count" => 4,
             "source_report_operational_readiness_paths" => [
               "accepted_planning_state.operational_execution_boundary_summary",
               "mission_state.source_operational_execution_boundary_summary",
               "source_operational_execution_boundary_summary",
               "source_result_artifact.operational_execution_boundary_summary"
             ],
             "source_report_operational_readiness_readiness_level_counts" => %{
               "analysis_only" => 4
             },
             "source_report_operational_readiness_import_classification_counts" => %{
               "analysis_only" => 4
             },
             "source_report_operational_readiness_status_counts" => %{"analysis_only" => 4},
             "source_report_operational_readiness_gate_count" => 20,
             "source_report_operational_readiness_passed_gate_count" => 16,
             "source_report_operational_readiness_analysis_gate_count" => 4,
             "source_report_operational_readiness_analysis_mode_counts" => %{
               "simulation" => 4
             },
             "source_reports" => %{
               "operational_readiness_report" => %{
                 "paths" => [
                   "accepted_planning_state.operational_execution_boundary_summary",
                   "mission_state.source_operational_execution_boundary_summary",
                   "source_operational_execution_boundary_summary",
                   "source_result_artifact.operational_execution_boundary_summary"
                 ],
                 "contract" => "operational_execution_boundary_summary.v1",
                 "count" => 4,
                 "row_count" => 4,
                 "source_summary_model_counts" => %{
                   "artifact_only_operational_execution_boundary_summary" => 4
                 },
                 "source_summary_schema_contract_counts" => %{
                   "operational_execution_boundary_summary.v1" => 4
                 },
                 "source_artifact_type_counts" => %{"planned_activity.v1" => 4},
                 "readiness_level_counts" => %{"analysis_only" => 4},
                 "import_classification_counts" => %{"analysis_only" => 4},
                 "status_counts" => %{"analysis_only" => 4},
                 "import_ineligible_count" => 4,
                 "execution_boundary_counts" => %{"analysis_only_not_for_execution" => 4},
                 "analysis_mode_counts" => %{"simulation" => 4},
                 "analysis_mode_source_counts" => %{"root" => 4},
                 "handoff_only_count" => 4,
                 "execution_denied_count" => 4,
                 "cadence_write_denied_count" => 4,
                 "operator_authority_denied_count" => 4,
                 "gate_count" => 20,
                 "passed_gate_count" => 16,
                 "analysis_gate_count" => 4,
                 "non_passed_gate_count" => 4,
                 "non_passed_gate_ids" => ["operational_mode"],
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => ["ops_execution_boundary_summary"]
               }
             }
           } = source_summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = CandidateRefresh.operational_readiness_replay_summary(refresh)

    assert replay_summary["contract"] == "operational_execution_boundary_summary.v1"
    assert replay_summary["source_report_count"] == 4
    assert replay_summary["source_report_row_count"] == 4
    assert replay_summary["import_ineligible_count"] == 4

    assert replay_summary["execution_boundary_counts"] == %{
             "analysis_only_not_for_execution" => 4
           }

    assert replay_summary["analysis_mode_counts"] == %{"simulation" => 4}
    assert replay_summary["analysis_mode_source_counts"] == %{"root" => 4}
    assert replay_summary["handoff_only_count"] == 4
    assert replay_summary["execution_denied_count"] == 4
    assert replay_summary["cadence_write_denied_count"] == 4
    assert replay_summary["operator_authority_denied_count"] == 4
    assert replay_summary["non_passed_gate_count"] == 4
    assert replay_summary["non_passed_gate_ids"] == ["operational_mode"]
    assert replay_summary["trust_boundary_status"] == "declared"
    assert replay_summary["trust_boundaries"] == ["ops_execution_boundary_summary"]
    assert replay_summary["branch_local_review_pressure"]
    assert replay_summary["branch_local_import_pressure"]
    assert replay_summary["branch_local_execution_boundary_pressure"]
    refute replay_summary["branch_local_resource_pressure"]

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_summary["source_reports"]}
    }

    assert CandidateRefresh.operational_readiness_replay_summary(artifact) == replay_summary
  end

  test "source report summary replays wrapped operational execution boundary summaries" do
    direct_summary =
      operational_execution_boundary_summary_fixture()
      |> Map.put("source", "ops_execution.direct")

    nested_summary =
      operational_execution_boundary_summary_fixture()
      |> Map.put("source", "ops_execution.nested")

    refresh = %{
      "source_result_artifact" => [
        direct_summary,
        %{
          "schema_contract" => "result_artifact.v1",
          "operational_execution_boundary_summary" => nested_summary
        }
      ]
    }

    source_summary = CandidateRefresh.source_report_summary(refresh)

    assert get_in(source_summary, ["source_reports", "operational_readiness_report", "paths"]) ==
             [
               "source_result_artifact[0]",
               "source_result_artifact[1].operational_execution_boundary_summary"
             ]

    assert get_in(source_summary, ["source_reports", "operational_readiness_report", "contract"]) ==
             "operational_execution_boundary_summary.v1"

    assert get_in(source_summary, ["source_reports", "operational_readiness_report", "count"]) ==
             2

    assert get_in(source_summary, ["source_reports", "operational_readiness_report", "row_count"]) ==
             2

    assert get_in(source_summary, [
             "source_reports",
             "operational_readiness_report",
             "execution_denied_count"
           ]) == 2

    replay_summary = CandidateRefresh.operational_readiness_replay_summary(refresh)

    assert replay_summary["source_report_paths"] == [
             "source_result_artifact[0]",
             "source_result_artifact[1].operational_execution_boundary_summary"
           ]

    assert replay_summary["contract"] == "operational_execution_boundary_summary.v1"
    assert replay_summary["execution_denied_count"] == 2
    assert replay_summary["branch_local_execution_boundary_pressure"]
  end

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

  test "operational readiness replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.operational_readiness_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_operational_readiness_contract")
    refute Map.has_key?(source_summary, "source_report_operational_readiness_count")
    refute Map.has_key?(source_summary, "source_report_operational_readiness_row_count")
    refute Map.has_key?(source_summary, "source_report_operational_readiness_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_review_pressure"]
    refute summary["branch_local_import_pressure"]
    refute summary["branch_local_resource_pressure"]
  end

  test "operational readiness source summary keeps declared contract without partial identity placeholders" do
    placeholder_fields = [
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.operational_readiness_report"]},
      %{"count" => nil, "row_count" => 2},
      %{"count" => 1, "row_count" => nil}
    ]

    for placeholder <- placeholder_fields do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "operational_readiness_report" =>
              Map.put(
                placeholder,
                "contract",
                "operational_readiness_report.v1"
              )
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      assert source_summary["source_report_operational_readiness_contract"] ==
               "operational_readiness_report.v1"

      refute Map.has_key?(source_summary, "source_report_operational_readiness_count")

      refute Map.has_key?(
               source_summary,
               "source_report_operational_readiness_row_count"
             )

      refute Map.has_key?(source_summary, "source_report_operational_readiness_paths")
    end
  end

  test "operational readiness source summary preserves non-identity rollups with partial identity" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "operational_readiness_report" => %{
            "contract" => "operational_readiness_report.v1",
            "count" => 1,
            "readiness_level_counts" => %{"operator_review" => 1},
            "resource_blocking_dimension_counts" => %{"communications" => 1}
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_operational_readiness_contract"] ==
             "operational_readiness_report.v1"

    refute Map.has_key?(source_summary, "source_report_operational_readiness_count")

    refute Map.has_key?(
             source_summary,
             "source_report_operational_readiness_row_count"
           )

    refute Map.has_key?(source_summary, "source_report_operational_readiness_paths")

    assert source_summary["source_report_operational_readiness_readiness_level_counts"] ==
             %{"operator_review" => 1}

    assert source_summary[
             "source_report_operational_readiness_resource_blocking_dimension_counts"
           ] == %{"communications" => 1}
  end

  test "operational readiness source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "operational_readiness_report" => %{
            "contract" => "operational_readiness_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.operational_readiness_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_operational_readiness_contract"] ==
             "operational_readiness_report.v1"

    assert source_summary["source_report_operational_readiness_count"] == 0
    assert source_summary["source_report_operational_readiness_row_count"] == 0

    assert source_summary["source_report_operational_readiness_paths"] == [
             "provenance.source_reports.operational_readiness_report"
           ]
  end

  test "operational readiness source summary omits missing identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "operational_readiness_report" => %{
            "contract" => "operational_readiness_report.v1",
            "count" => 1,
            "row_count" => 2
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_operational_readiness_contract"] ==
             "operational_readiness_report.v1"

    assert source_summary["source_report_operational_readiness_count"] == 1
    assert source_summary["source_report_operational_readiness_row_count"] == 2
    refute Map.has_key?(source_summary, "source_report_operational_readiness_paths")
  end

  test "operational readiness source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "operational_readiness_report" => %{
            "contract" => "operational_readiness_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_operational_readiness_contract"] ==
             "operational_readiness_report.v1"

    assert source_summary["source_report_operational_readiness_count"] == 1
    assert source_summary["source_report_operational_readiness_row_count"] == 2
    assert source_summary["source_report_operational_readiness_paths"] == []
  end

  test "operational readiness replay treats resource routing maps as resource pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "operational_readiness_report" => %{
            "contract" => "operational_readiness_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_operational_readiness_report"],
            "review_gate_count" => 0,
            "blocked_gate_count" => 0,
            "review_required_count" => 0,
            "manifest_review_required_count" => 0,
            "missing_import_count" => 0,
            "blocked_import_count" => 0,
            "invalid_cadence_import_count" => 0,
            "resource_availability_pressure_count" => 0,
            "resource_availability_reason_counts" => %{"antenna_unavailable" => 1},
            "resource_availability_reason_ids" => ["antenna_unavailable"],
            "station_availability_reason_ids" => [],
            "station_availability_reason_counts" => %{},
            "unavailable_resource_reason_ids" => ["antenna_unavailable"],
            "resource_blocking_dimension_counts" => %{"communications" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.operational_readiness_replay_summary(artifact)

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1
    assert summary["resource_availability_pressure_count"] == 0
    assert summary["resource_availability_reason_counts"] == %{"antenna_unavailable" => 1}
    assert summary["resource_availability_reason_ids"] == ["antenna_unavailable"]
    assert summary["unavailable_resource_reason_ids"] == ["antenna_unavailable"]
    assert summary["resource_blocking_dimension_counts"] == %{"communications" => 1}
    assert summary["branch_local_resource_pressure"]
    refute summary["branch_local_review_pressure"]
    refute summary["branch_local_import_pressure"]
  end

  test "operational readiness replay treats review and import maps as pressure" do
    base_summary = %{
      "contract" => "operational_readiness_report.v1",
      "count" => 1,
      "row_count" => 1,
      "paths" => ["source_operational_readiness_report"],
      "review_gate_count" => 0,
      "blocked_gate_count" => 0,
      "review_required_count" => 0,
      "manifest_review_required_count" => 0,
      "missing_import_count" => 0,
      "blocked_import_count" => 0,
      "invalid_cadence_import_count" => 0,
      "resource_availability_pressure_count" => 0,
      "resource_availability_reason_counts" => %{},
      "resource_availability_reason_ids" => [],
      "station_availability_reason_ids" => [],
      "station_availability_reason_counts" => %{},
      "unavailable_resource_reason_ids" => [],
      "resource_blocking_dimension_counts" => %{},
      "review_type_counts" => %{},
      "import_action_counts" => %{},
      "source_review_type_counts" => %{}
    }

    cases = [
      {"review type", %{"review_type_counts" => %{"contact_allocation_review" => 1}},
       "branch_local_review_pressure"},
      {"source review type",
       %{"source_review_type_counts" => %{"contact_allocation_review" => 1}},
       "branch_local_review_pressure"},
      {"import action", %{"import_action_counts" => %{"review_contact_allocation" => 1}},
       "branch_local_import_pressure"}
    ]

    for {label, evidence, expected_pressure} <- cases do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "operational_readiness_report" => Map.merge(base_summary, evidence)
          }
        }
      }

      summary = CandidateRefresh.operational_readiness_replay_summary(artifact)

      assert summary["source_report_count"] == 1, label
      assert summary["review_gate_count"] == 0, label
      assert summary["blocked_gate_count"] == 0, label
      assert summary["review_required_count"] == 0, label
      assert summary["manifest_review_required_count"] == 0, label
      assert summary["missing_import_count"] == 0, label
      assert summary["blocked_import_count"] == 0, label
      assert summary["invalid_cadence_import_count"] == 0, label
      refute summary["branch_local_resource_pressure"], label
      assert summary[expected_pressure], label
    end
  end

  test "operational readiness replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "operational_readiness_report" => %{
              "contract" => "operational_readiness_report.v1",
              "count" => 1,
              "row_count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_operational_readiness_report"
              ],
              "readiness_level_counts" => %{"operator_review" => 1},
              "import_classification_counts" => %{"review_only" => 1},
              "status_counts" => %{"review_required" => 1},
              "gate_count" => 3,
              "passed_gate_count" => 1,
              "review_gate_count" => 1,
              "analysis_gate_count" => 1,
              "analysis_mode_counts" => %{"not_for_execution" => 1},
              "blocked_gate_count" => 1,
              "ready_for_import_count" => 0,
              "manifest_review_required_count" => 1,
              "blocked_import_count" => 1,
              "missing_import_count" => 1,
              "invalid_cadence_import_count" => 1,
              "review_required_count" => 1,
              "stale_freshness_count" => 1,
              "freshness_status_counts" => %{"stale" => 1},
              "schema_validation_fail_count" => 1,
              "schema_validation_error_count" => 1,
              "schema_validation_status_counts" => %{"fail" => 1},
              "import_status_counts" => %{"review_required_before_import" => 1},
              "cadence_import_status_counts" => %{"missing" => 1},
              "adapter_trust_boundary_missing_count" => 1,
              "adapter_boundary_status_counts" => %{"missing" => 1},
              "resource_availability_pressure_count" => 1,
              "resource_availability_reason_counts" => %{"antenna_unavailable" => 1},
              "resource_availability_reason_ids" => ["antenna_unavailable"],
              "station_availability_reason_ids" => ["ground_station_reserved"],
              "station_availability_reason_counts" => %{"ground_station_reserved" => 1},
              "unavailable_resource_reason_ids" => ["antenna_unavailable"],
              "resource_blocking_dimension_counts" => %{"communications" => 1},
              "review_type_counts" => %{"operational_readiness_review" => 1},
              "import_action_counts" => %{"review_operational_readiness" => 1},
              "source_review_type_counts" => %{"operational_readiness_review" => 1},
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_operational_readiness"]
            }
          }
        }
      },
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.operational_readiness_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.operational_readiness_report"

    assert summary["contract"] == "operational_readiness_report.v1"
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_operational_readiness_report"
           ]

    assert summary["readiness_level_counts"] == %{"operator_review" => 1}
    assert summary["import_classification_counts"] == %{"review_only" => 1}
    assert summary["status_counts"] == %{"review_required" => 1}
    assert summary["gate_count"] == 3
    assert summary["passed_gate_count"] == 1
    assert summary["review_gate_count"] == 1
    assert summary["analysis_gate_count"] == 1
    assert summary["analysis_mode_counts"] == %{"not_for_execution" => 1}
    assert summary["blocked_gate_count"] == 1
    assert summary["manifest_review_required_count"] == 1
    assert summary["blocked_import_count"] == 1
    assert summary["missing_import_count"] == 1
    assert summary["invalid_cadence_import_count"] == 1
    assert summary["review_required_count"] == 1
    assert summary["stale_freshness_count"] == 1
    assert summary["freshness_status_counts"] == %{"stale" => 1}
    assert summary["schema_validation_fail_count"] == 1
    assert summary["schema_validation_error_count"] == 1
    assert summary["schema_validation_status_counts"] == %{"fail" => 1}
    assert summary["import_status_counts"] == %{"review_required_before_import" => 1}
    assert summary["cadence_import_status_counts"] == %{"missing" => 1}
    assert summary["adapter_trust_boundary_missing_count"] == 1
    assert summary["adapter_boundary_status_counts"] == %{"missing" => 1}
    assert summary["resource_availability_pressure_count"] == 1
    assert summary["resource_availability_reason_counts"] == %{"antenna_unavailable" => 1}
    assert summary["resource_availability_reason_ids"] == ["antenna_unavailable"]
    assert summary["station_availability_reason_ids"] == ["ground_station_reserved"]
    assert summary["station_availability_reason_counts"] == %{"ground_station_reserved" => 1}
    assert summary["unavailable_resource_reason_ids"] == ["antenna_unavailable"]
    assert summary["resource_blocking_dimension_counts"] == %{"communications" => 1}
    assert summary["review_type_counts"] == %{"operational_readiness_review" => 1}
    assert summary["import_action_counts"] == %{"review_operational_readiness" => 1}
    assert summary["source_review_type_counts"] == %{"operational_readiness_review" => 1}
    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_operational_readiness"]
    assert summary["branch_local_review_pressure"]
    assert summary["branch_local_import_pressure"]
    assert summary["branch_local_resource_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "operational_readiness_candidate_source_report_summary_only"

    assert %{
             "source_report_operational_readiness_branch_local_review_pressure" => true,
             "source_report_operational_readiness_branch_local_import_pressure" => true,
             "source_report_operational_readiness_branch_local_execution_boundary_pressure" =>
               false,
             "source_report_operational_readiness_branch_local_resource_pressure" => true,
             "source_report_operational_readiness_branch_local_timeline_publication_pressure" =>
               false
           } = CandidateRefresh.source_report_summary(artifact)

    assert OrbitalDynamics.candidate_refresh_operational_readiness_replay_summary(artifact) ==
             summary
  end

  test "operational readiness replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "operational_readiness_report" => %{
            "contract" => "operational_readiness_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_operational_readiness_report"
            ],
            "review_type_counts" => %{"operational_readiness_review" => 1},
            "import_action_counts" => %{"review_operational_readiness" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.operational_readiness_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.operational_readiness_report"

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_operational_readiness_report"
           ]

    assert summary["review_type_counts"] == %{"operational_readiness_review" => 1}
    assert summary["import_action_counts"] == %{"review_operational_readiness" => 1}
    assert summary["branch_local_review_pressure"]
    assert summary["branch_local_import_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "operational_readiness_candidate_source_report_summary_only"
  end

  test "operational readiness replay falls back when branch summary is empty" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{"operational_readiness_report" => %{}}
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "operational_readiness_report" => %{
            "contract" => "operational_readiness_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["provenance.source_reports.operational_readiness_report"],
            "readiness_level_counts" => %{"operator_review" => 1},
            "review_type_counts" => %{"operational_readiness_review" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.operational_readiness_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.operational_readiness_report"

    assert summary["source_report_paths"] == [
             "provenance.source_reports.operational_readiness_report"
           ]

    assert summary["readiness_level_counts"] == %{"operator_review" => 1}
    assert summary["review_type_counts"] == %{"operational_readiness_review" => 1}
    assert summary["branch_local_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "operational_readiness_source_report_provenance_only"
  end

  test "operational readiness replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "operational_readiness_report" => %{
              "contract" => "operational_readiness_report.v1",
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_operational_readiness_report"
              ],
              "resource_availability_reason_counts" => %{"antenna_unavailable" => 1}
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "operational_readiness_report" => %{
            "contract" => "operational_readiness_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["provenance.source_reports.operational_readiness_report"],
            "review_gate_count" => 9,
            "manifest_review_required_count" => 9,
            "resource_availability_pressure_count" => 9,
            "readiness_level_counts" => %{"blocked" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.operational_readiness_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.operational_readiness_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_operational_readiness_report"
           ]

    assert summary["review_gate_count"] == 0
    assert summary["manifest_review_required_count"] == 0
    assert summary["resource_availability_pressure_count"] == 0
    assert summary["readiness_level_counts"] == %{}
    assert summary["resource_availability_reason_counts"] == %{"antenna_unavailable" => 1}
    refute summary["branch_local_review_pressure"]
    refute summary["branch_local_import_pressure"]
    assert summary["branch_local_resource_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "operational_readiness_candidate_source_report_summary_only"

    source_summary = CandidateRefresh.source_report_summary(artifact)

    refute source_summary["source_report_operational_readiness_branch_local_review_pressure"]
    refute source_summary["source_report_operational_readiness_branch_local_import_pressure"]

    assert source_summary[
             "source_report_operational_readiness_branch_local_resource_pressure"
           ]
  end

  defp operational_import_eligibility_summary_fixture do
    %{
      "schema_contract" => "operational_import_eligibility_summary.v1",
      "model" => "artifact_only_import_eligibility_summary",
      "source" => "operational_readiness_report.v1",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "activity_1",
      "readiness_level" => "operator_review",
      "import_classification" => "review_only",
      "status" => "review_required",
      "import_eligible" => false,
      "gate_count" => 5,
      "passed_gate_count" => 2,
      "review_gate_count" => 1,
      "analysis_gate_count" => 1,
      "blocked_gate_count" => 1,
      "non_passed_gate_count" => 3,
      "non_passed_gates" => [
        %{"id" => "operational_mode"},
        %{"id" => "operator_review"},
        %{"id" => "cadence_import"}
      ],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "source" => "operational_readiness_report.v1",
        "operator_authority" => "not_granted_by_summary"
      },
      "model_limits" => [
        "operational_import_eligibility_summary_routes_only",
        "operational_import_eligibility_summary_does_not_approve_or_import"
      ],
      "provenance" => %{"trust_boundary" => "ops_import_eligibility_summary"}
    }
  end

  defp operational_execution_boundary_summary_fixture do
    %{
      "schema_contract" => "operational_execution_boundary_summary.v1",
      "model" => "artifact_only_operational_execution_boundary_summary",
      "source" => "operational_readiness_report.v1",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "activity_1",
      "readiness_level" => "analysis_only",
      "import_classification" => "analysis_only",
      "status" => "analysis_only",
      "import_eligible" => false,
      "handoff_only" => true,
      "execution_allowed" => false,
      "cadence_write_allowed" => false,
      "operator_authority_granted" => false,
      "execution_boundary" => "analysis_only_not_for_execution",
      "analysis_mode" => "simulation",
      "analysis_mode_source" => "root",
      "operational_mode_gate" => %{
        "id" => "operational_mode",
        "status" => "analysis_only",
        "classification" => "analysis_only",
        "analysis_mode" => "simulation",
        "analysis_mode_source" => "root"
      },
      "gate_count" => 5,
      "passed_gate_count" => 4,
      "review_gate_count" => 0,
      "analysis_gate_count" => 1,
      "blocked_gate_count" => 0,
      "non_passed_gate_count" => 1,
      "non_passed_gate_ids" => ["operational_mode"],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write_no_command_execution",
        "source" => "operational_readiness_report.v1",
        "operator_authority" => "not_granted_by_execution_boundary_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary"
      },
      "model_limits" => [
        "operational_execution_boundary_summary_routes_only",
        "operational_execution_boundary_summary_does_not_execute_or_import"
      ],
      "provenance" => %{"trust_boundary" => "ops_execution_boundary_summary"}
    }
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

  test "replays operational-readiness source reports from review and import containers" do
    readiness_report = %{
      "schema_contract" => "operational_readiness_report.v1",
      "schema_version" => 1,
      "model" => "artifact_only_operational_readiness_classifier",
      "report_id" => "operational_readiness:contact_allocation_report.v1:allocation_1",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source_artifact_id" => "allocation_1",
      "readiness_level" => "operator_review",
      "import_classification" => "review_only",
      "status" => "review_required",
      "gate_count" => 4,
      "passed_gate_count" => 2,
      "review_gate_count" => 2,
      "analysis_gate_count" => 0,
      "blocked_gate_count" => 0,
      "gates" => [
        %{
          "id" => "operator_review",
          "status" => "review_required",
          "classification" => "review_only",
          "reason" => "operator review required"
        }
      ],
      "evidence" => %{
        "review_required_count" => 1,
        "ready_for_import_count" => 0,
        "manifest_review_required_count" => 1,
        "missing_import_count" => 1,
        "stale_freshness_count" => 1,
        "freshness_status_counts" => %{"stale" => 1},
        "schema_validation_fail_count" => 1,
        "schema_validation_error_count" => 1,
        "schema_validation_status_counts" => %{"fail" => 1},
        "import_status_counts" => %{"review_required_before_import" => 1},
        "cadence_import_status_counts" => %{"missing" => 1},
        "review_type_counts" => %{"contact_allocation_review" => 1},
        "import_action_counts" => %{"review_contact_allocation" => 1},
        "source_review_type_counts" => %{"contact_allocation_review" => 1}
      },
      "provenance" => %{"trust_boundary" => "readiness_report"}
    }

    package = OperatorReview.from_operational_readiness_report(readiness_report)
    manifest = CadenceImport.from_operational_readiness_report(readiness_report)

    for {source, expected_path, expected_trust_boundary_status, expected_trust_boundaries} <- [
          {%{"source_operator_review_package" => package},
           "source_operator_review_package.rows.source_operational_readiness_report", "declared",
           ["readiness_report"]},
          {%{"source_cadence_import_manifest" => manifest},
           "source_cadence_import_manifest.rows.source_operational_readiness_report", "missing",
           []}
        ] do
      artifact =
        result_set()
        |> CandidateRefresh.build(
          candidate_refresh: Map.merge(refresh_request(), source),
          generated_at: ~U[2026-05-14 00:00:00Z]
        )

      assert %{
               "paths" => [^expected_path],
               "contract" => "operational_readiness_report.v1",
               "count" => 1,
               "row_count" => 1,
               "readiness_level_counts" => %{"operator_review" => 1},
               "import_classification_counts" => %{"review_only" => 1},
               "status_counts" => %{"review_required" => 1},
               "gate_count" => 4,
               "review_gate_count" => 2,
               "ready_for_import_count" => 0,
               "manifest_review_required_count" => 1,
               "missing_import_count" => 1,
               "review_required_count" => 1,
               "stale_freshness_count" => 1,
               "freshness_status_counts" => %{"stale" => 1},
               "schema_validation_fail_count" => 1,
               "schema_validation_error_count" => 1,
               "schema_validation_status_counts" => %{"fail" => 1},
               "import_status_counts" => %{"review_required_before_import" => 1},
               "cadence_import_status_counts" => %{"missing" => 1},
               "review_type_counts" => %{"contact_allocation_review" => 1},
               "import_action_counts" => %{"review_contact_allocation" => 1},
               "source_review_type_counts" => %{"contact_allocation_review" => 1},
               "trust_boundary_status" => ^expected_trust_boundary_status,
               "trust_boundaries" => ^expected_trust_boundaries
             } =
               get_in(artifact, [
                 "provenance",
                 "source_reports",
                 "operational_readiness_report"
               ])

      assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
               Schema.validate_artifact(artifact)

      invalid_source_report_count =
        put_in(
          artifact,
          [
            "provenance",
            "source_reports",
            "operational_readiness_report",
            "freshness_status_counts",
            "stale"
          ],
          -1
        )

      assert {:error, invalid_source_report_count_report} =
               Schema.validate_artifact(invalid_source_report_count)

      assert Enum.any?(
               invalid_source_report_count_report["errors"],
               &(&1["path"] ==
                   "$.provenance.source_reports.operational_readiness_report.freshness_status_counts.stale")
             )
    end
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

  defp ordered_event_result_set(order) do
    target_events = [
      target_visibility_event(120.0, 240.0),
      target_visibility_event(260.0, 340.0)
    ]

    access_events = [
      access_event(300.0, 420.0),
      access_event(430.0, 500.0)
    ]

    event_results = [
      %{
        scenario_id: :leo_1,
        event_type: :target_visibility,
        events: order_events(target_events, order),
        source: %{target_id: :target_a}
      },
      %{
        scenario_id: :leo_1,
        event_type: :ground_station_access,
        events: order_events(access_events, order),
        source: %{ground_station_id: :equator_prime}
      }
    ]

    ResultSet.new!(%{
      study_id: :candidate_refresh_demo,
      trajectory_results: [],
      event_results: order_events(event_results, order),
      errors: [],
      assumptions: %{propagator: OrbitalDynamics.Propagators.TwoBody, outputs: [:access_windows]},
      metadata: %{}
    })
  end

  defp order_events(events, :reversed), do: Enum.reverse(events)
  defp order_events(events, _order), do: events

  defp target_visibility_event(starts_at_s, ends_at_s) do
    %{
      type: :target_visibility,
      starts_at: Epoch.new!(starts_at_s, :tdb),
      ends_at: Epoch.new!(ends_at_s, :tdb),
      metadata: %{
        target_id: :target_a,
        target_priority: 1.0,
        max_elevation_deg: 80.0,
        minimum_elevation_deg: 10.0,
        sample_count: 3
      }
    }
  end

  defp access_event(starts_at_s, ends_at_s) do
    %{
      type: :ground_station_access,
      starts_at: Epoch.new!(starts_at_s, :tdb),
      ends_at: Epoch.new!(ends_at_s, :tdb),
      metadata: %{
        max_elevation_deg: 70.0,
        minimum_elevation_deg: 5.0,
        sample_count: 4
      }
    }
  end

  test "source report summaries separate station and unavailable readiness reasons" do
    reason_counts = %{"ground_station_reserved" => 1, "payload_unavailable" => 1}

    readiness_report = %{
      "schema_contract" => "operational_readiness_report.v1",
      "readiness_level" => "operator_review",
      "import_classification" => "review_only",
      "status" => "review_required",
      "gates" => [
        %{
          "id" => "resource_availability",
          "status" => "review_required",
          "classification" => "review_only",
          "reason" => "resource availability requires review",
          "resource_availability_pressure_count" => 2,
          "resource_availability_reason_counts" => reason_counts,
          "station_availability_reason_ids" => ["ground_station_reserved"],
          "unavailable_resource_reason_ids" => ["payload_unavailable"]
        }
      ],
      "evidence" => %{
        "resource_availability_pressure_count" => 2,
        "resource_availability_reason_counts" => reason_counts
      },
      "provenance" => %{"trust_boundary" => "mission_state_readiness"}
    }

    quality_gate_report = %{
      "schema_contract" => "quality_gate_report.v1",
      "readiness_level" => "operator_review",
      "import_classification" => "review_only",
      "status" => "review_required",
      "gate_count" => 1,
      "review_gate_count" => 1,
      "rows" => [
        %{
          "id" => "quality_gate:activity_1:resource_availability:1",
          "rank" => 1,
          "gate_id" => "resource_availability",
          "status" => "review_required",
          "classification" => "review_only",
          "reason" => "resource availability requires review",
          "resource_availability_pressure_count" => 2,
          "resource_availability_reason_counts" => reason_counts,
          "station_availability_reason_ids" => ["ground_station_reserved"],
          "unavailable_resource_reason_ids" => ["payload_unavailable"]
        }
      ],
      "provenance" => %{"trust_boundary" => "mission_state_quality_gate"}
    }

    summary =
      CandidateRefresh.source_report_summary(%{
        "mission_state" => %{
          "source_operational_readiness_report" => readiness_report,
          "source_quality_gate_report" => quality_gate_report
        }
      })

    assert %{
             "source_reports" => %{
               "operational_readiness_report" => %{
                 "resource_availability_reason_counts" => ^reason_counts,
                 "resource_availability_reason_ids" => [
                   "ground_station_reserved",
                   "payload_unavailable"
                 ],
                 "station_availability_reason_ids" => ["ground_station_reserved"],
                 "station_availability_reason_counts" => %{"ground_station_reserved" => 1},
                 "unavailable_resource_reason_ids" => ["payload_unavailable"]
               },
               "quality_gate_report" => %{
                 "resource_availability_reason_counts" => ^reason_counts,
                 "resource_availability_reason_ids" => [
                   "ground_station_reserved",
                   "payload_unavailable"
                 ],
                 "station_availability_reason_ids" => ["ground_station_reserved"],
                 "station_availability_reason_counts" => %{"ground_station_reserved" => 1},
                 "unavailable_resource_reason_ids" => ["payload_unavailable"]
               }
             }
           } = summary

    artifact =
      ordered_event_result_set(:canonical)
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("mission_state", %{
            "source_operational_readiness_report" => readiness_report,
            "source_quality_gate_report" => quality_gate_report
          }),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact)

    assert get_in(artifact, [
             "provenance",
             "source_reports",
             "operational_readiness_report",
             "station_availability_reason_ids"
           ]) == ["ground_station_reserved"]

    assert get_in(artifact, [
             "provenance",
             "source_reports",
             "operational_readiness_report",
             "station_availability_reason_counts"
           ]) == %{"ground_station_reserved" => 1}

    assert get_in(artifact, [
             "provenance",
             "source_reports",
             "quality_gate_report",
             "station_availability_reason_ids"
           ]) == ["ground_station_reserved"]

    assert get_in(artifact, [
             "provenance",
             "source_reports",
             "quality_gate_report",
             "station_availability_reason_counts"
           ]) == %{"ground_station_reserved" => 1}

    stale_quality_gate_source_report =
      artifact
      |> put_in(
        [
          "provenance",
          "source_reports",
          "quality_gate_report",
          "station_availability_reason_ids"
        ],
        []
      )
      |> put_in(
        [
          "provenance",
          "source_reports",
          "quality_gate_report",
          "station_availability_reason_counts"
        ],
        %{}
      )

    assert {:error, stale_quality_gate_source_report_errors} =
             Schema.validate_artifact(stale_quality_gate_source_report)

    assert Enum.any?(
             stale_quality_gate_source_report_errors["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.quality_gate_report.station_availability_reason_ids" and
                 &1["message"] ==
                   "must equal station availability reason IDs from resource_availability_reason_counts")
           )

    assert Enum.any?(
             stale_quality_gate_source_report_errors["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.quality_gate_report.station_availability_reason_counts" and
                 &1["message"] ==
                   "must equal station availability reason counts from resource_availability_reason_counts")
           )
  end
end
