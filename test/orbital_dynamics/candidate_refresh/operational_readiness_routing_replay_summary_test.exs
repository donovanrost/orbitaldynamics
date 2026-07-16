defmodule OrbitalDynamics.CandidateRefresh.OperationalReadinessRoutingReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

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
end
