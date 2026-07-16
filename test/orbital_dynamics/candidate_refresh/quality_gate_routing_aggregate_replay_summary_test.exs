defmodule OrbitalDynamics.CandidateRefresh.QualityGateRoutingAggregateReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary aggregates quality gate routing maps" do
    refresh = %{
      "source_quality_gate_report" => %{
        "schema_contract" => "quality_gate_report.v1",
        "source_readiness_report_id" => "operational_readiness:activity_1",
        "readiness_level" => "blocked",
        "import_classification" => "review_only",
        "status" => "review_required",
        "rows" => [
          %{
            "id" => "quality_gate:operational_mode",
            "status" => "analysis_only",
            "classification" => "analysis_only",
            "analysis_mode" => "simulation"
          },
          %{
            "id" => "quality_gate:adapter_boundary",
            "status" => "review_required",
            "classification" => "review_only",
            "adapter_context_count" => 1,
            "adapter_trust_boundary_missing_count" => 1,
            "adapter_boundary_status_counts" => %{"missing" => 1}
          },
          %{
            "id" => "quality_gate:resource_availability",
            "status" => "blocked",
            "classification" => "blocked",
            "manifest_review_required_count" => 1,
            "blocked_import_count" => 1,
            "missing_import_count" => 1,
            "invalid_cadence_import_count" => 1,
            "stale_freshness_count" => 1,
            "freshness_status_counts" => %{"stale" => 1},
            "schema_validation_fail_count" => 1,
            "schema_validation_error_count" => 1,
            "schema_validation_remediation_count" => 1,
            "schema_validation_status_counts" => %{"fail" => 1},
            "import_status_counts" => %{"review_required_before_import" => 1},
            "cadence_import_status_counts" => %{"missing" => 1},
            "resource_availability_pressure_count" => 2,
            "resource_availability_reason_counts" => %{
              "ground_station_reserved" => 1,
              "payload_unavailable" => 1
            },
            "station_availability_reason_ids" => ["ground_station_reserved"],
            "unavailable_resource_reason_ids" => ["payload_unavailable"],
            "resource_blocking_dimension_counts" => %{"communications" => 1},
            "publication_status_counts" => %{"review_required" => 1},
            "dependency_impact_status_counts" => %{"review_required" => 1},
            "publication_authority_counts" => %{"operator_review" => 1},
            "source_artifact_type_counts" => %{"operational_timeline_report.v1" => 1},
            "publication_ids" => ["timeline_publication:quality_review"],
            "source_artifact_ids" => ["operational_timeline:quality_activity"],
            "supersedes_artifact_ids" => ["timeline_publication:quality_prior"],
            "downstream_product_ids" => ["cadence_import:quality_activity"],
            "invalidated_downstream_product_ids" => ["timeline_product:quality_stale"],
            "dependency_impact_row_count" => 1,
            "impacted_dependency_activity_ids" => ["activity_dependency:quality_antenna"],
            "impacted_dependency_timeline_ids" => ["timeline:quality_dependency"],
            "impacted_exclusive_with_activity_ids" => ["activity:quality_exclusive"],
            "impacted_exclusive_with_timeline_ids" => ["timeline:quality_exclusive"],
            "timeline_diff_row_count" => 1,
            "timeline_diff_changed_count" => 1,
            "timeline_diff_review_required_count" => 1,
            "changed_field_counts" => %{"resource_assignment" => 1},
            "changed_timeline_ids" => ["timeline:quality_changed"],
            "review_timeline_ids" => ["timeline:quality_review"],
            "timeline_ids_by_changed_field" => %{
              "resource_assignment" => ["timeline:quality_changed"]
            }
          }
        ],
        "provenance" => %{"trust_boundary" => "ops_quality_gate"}
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_quality_gate_contract" => "quality_gate_report.v1",
             "source_report_quality_gate_count" => 1,
             "source_report_quality_gate_row_count" => 3,
             "source_report_quality_gate_paths" => ["source_quality_gate_report"],
             "source_report_quality_gate_readiness_level_counts" => %{"blocked" => 1},
             "source_report_quality_gate_import_classification_counts" => %{
               "blocked" => 1
             },
             "source_report_quality_gate_status_counts" => %{"blocked" => 1},
             "source_report_quality_gate_gate_count" => 3,
             "source_report_quality_gate_analysis_gate_count" => 1,
             "source_report_quality_gate_analysis_mode_counts" => %{"simulation" => 1},
             "source_report_quality_gate_review_gate_count" => 1,
             "source_report_quality_gate_blocked_gate_count" => 1,
             "source_report_quality_gate_gate_status_counts" => %{
               "analysis_only" => 1,
               "blocked" => 1,
               "review_required" => 1
             },
             "source_report_quality_gate_gate_classification_counts" => %{
               "analysis_only" => 1,
               "blocked" => 1,
               "review_only" => 1
             },
             "source_report_quality_gate_manifest_review_required_count" => 1,
             "source_report_quality_gate_blocked_import_count" => 1,
             "source_report_quality_gate_missing_import_count" => 1,
             "source_report_quality_gate_invalid_cadence_import_count" => 1,
             "source_report_quality_gate_freshness_status_counts" => %{"stale" => 1},
             "source_report_quality_gate_schema_validation_status_counts" => %{"fail" => 1},
             "source_report_quality_gate_import_status_counts" => %{
               "review_required_before_import" => 1
             },
             "source_report_quality_gate_cadence_import_status_counts" => %{
               "missing" => 1
             },
             "source_report_quality_gate_adapter_boundary_status_counts" => %{"missing" => 1},
             "source_report_quality_gate_resource_availability_pressure_count" => 2,
             "source_report_quality_gate_resource_availability_reason_counts" => %{
               "ground_station_reserved" => 1,
               "payload_unavailable" => 1
             },
             "source_report_quality_gate_resource_availability_reason_ids" => [
               "ground_station_reserved",
               "payload_unavailable"
             ],
             "source_report_quality_gate_station_availability_reason_ids" => [
               "ground_station_reserved"
             ],
             "source_report_quality_gate_station_availability_reason_counts" => %{
               "ground_station_reserved" => 1
             },
             "source_report_quality_gate_unavailable_resource_reason_ids" => [
               "payload_unavailable"
             ],
             "source_report_quality_gate_resource_blocking_dimension_counts" => %{
               "communications" => 1
             },
             "source_report_quality_gate_source_readiness_report_count" => 1,
             "source_report_quality_gate_publication_status_counts" => %{
               "review_required" => 1
             },
             "source_report_quality_gate_dependency_impact_status_counts" => %{
               "review_required" => 1
             },
             "source_report_quality_gate_publication_authority_counts" => %{
               "operator_review" => 1
             },
             "source_report_quality_gate_timeline_publication_source_artifact_type_counts" => %{
               "operational_timeline_report.v1" => 1
             },
             "source_report_quality_gate_publication_ids" => [
               "timeline_publication:quality_review"
             ],
             "source_report_quality_gate_source_artifact_ids" => [
               "operational_timeline:quality_activity"
             ],
             "source_report_quality_gate_supersedes_artifact_ids" => [
               "timeline_publication:quality_prior"
             ],
             "source_report_quality_gate_downstream_product_ids" => [
               "cadence_import:quality_activity"
             ],
             "source_report_quality_gate_invalidated_downstream_product_ids" => [
               "timeline_product:quality_stale"
             ],
             "source_report_quality_gate_dependency_impact_row_count" => 1,
             "source_report_quality_gate_impacted_dependency_activity_ids" => [
               "activity_dependency:quality_antenna"
             ],
             "source_report_quality_gate_impacted_dependency_timeline_ids" => [
               "timeline:quality_dependency"
             ],
             "source_report_quality_gate_impacted_exclusive_with_activity_ids" => [
               "activity:quality_exclusive"
             ],
             "source_report_quality_gate_impacted_exclusive_with_timeline_ids" => [
               "timeline:quality_exclusive"
             ],
             "source_report_quality_gate_timeline_diff_row_count" => 1,
             "source_report_quality_gate_timeline_diff_changed_count" => 1,
             "source_report_quality_gate_timeline_diff_review_required_count" => 1,
             "source_report_quality_gate_changed_field_counts" => %{
               "resource_assignment" => 1
             },
             "source_report_quality_gate_changed_timeline_ids" => [
               "timeline:quality_changed"
             ],
             "source_report_quality_gate_review_timeline_ids" => ["timeline:quality_review"],
             "source_report_quality_gate_timeline_ids_by_changed_field" => %{
               "resource_assignment" => ["timeline:quality_changed"]
             },
             "source_report_quality_gate_branch_local_review_pressure" => true,
             "source_report_quality_gate_branch_local_import_pressure" => true,
             "source_report_quality_gate_branch_local_resource_pressure" => true,
             "source_report_quality_gate_branch_local_timeline_publication_pressure" => true,
             "source_report_quality_gate_branch_local_timeline_publication_dependency_pressure" =>
               true,
             "source_report_quality_gate_branch_local_timeline_publication_changed_field_pressure" =>
               true,
             "source_report_quality_gate_branch_local_timeline_publication_invalidation_pressure" =>
               true,
             "source_report_quality_gate_branch_local_timeline_publication_review_pressure" =>
               true,
             "source_reports" => %{
               "quality_gate_report" => %{
                 "gate_count" => 3,
                 "analysis_mode_counts" => %{"simulation" => 1},
                 "gate_status_counts" => %{
                   "analysis_only" => 1,
                   "blocked" => 1,
                   "review_required" => 1
                 },
                 "resource_availability_reason_counts" => %{
                   "ground_station_reserved" => 1,
                   "payload_unavailable" => 1
                 },
                 "station_availability_reason_counts" => %{"ground_station_reserved" => 1},
                 "publication_status_counts" => %{"review_required" => 1},
                 "timeline_publication_source_artifact_type_counts" => %{
                   "operational_timeline_report.v1" => 1
                 },
                 "timeline_ids_by_changed_field" => %{
                   "resource_assignment" => ["timeline:quality_changed"]
                 }
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "model" => "artifact_only_candidate_refresh_quality_gate_replay_summary",
             "source" => "candidate_refresh.source_report_provenance.quality_gate_report",
             "contract" => "quality_gate_report.v1",
             "source_report_count" => 1,
             "source_report_row_count" => 3,
             "source_report_paths" => ["source_quality_gate_report"],
             "readiness_level_counts" => %{"blocked" => 1},
             "import_classification_counts" => %{"blocked" => 1},
             "status_counts" => %{"blocked" => 1},
             "gate_count" => 3,
             "passed_gate_count" => 0,
             "review_gate_count" => 1,
             "analysis_gate_count" => 1,
             "analysis_mode_counts" => %{"simulation" => 1},
             "blocked_gate_count" => 1,
             "gate_status_counts" => %{
               "analysis_only" => 1,
               "blocked" => 1,
               "review_required" => 1
             },
             "gate_classification_counts" => %{
               "analysis_only" => 1,
               "blocked" => 1,
               "review_only" => 1
             },
             "ready_for_import_count" => 0,
             "manifest_review_required_count" => 1,
             "blocked_import_count" => 1,
             "missing_import_count" => 1,
             "invalid_cadence_import_count" => 1,
             "freshness_status_counts" => %{"stale" => 1},
             "schema_validation_status_counts" => %{"fail" => 1},
             "import_status_counts" => %{"review_required_before_import" => 1},
             "cadence_import_status_counts" => %{"missing" => 1},
             "resource_availability_pressure_count" => 2,
             "resource_availability_reason_counts" => %{
               "ground_station_reserved" => 1,
               "payload_unavailable" => 1
             },
             "resource_availability_reason_ids" => [
               "ground_station_reserved",
               "payload_unavailable"
             ],
             "station_availability_reason_ids" => ["ground_station_reserved"],
             "station_availability_reason_counts" => %{"ground_station_reserved" => 1},
             "unavailable_resource_reason_ids" => ["payload_unavailable"],
             "resource_blocking_dimension_counts" => %{"communications" => 1},
             "source_readiness_report_count" => 1,
             "publication_status_counts" => %{"review_required" => 1},
             "dependency_impact_status_counts" => %{"review_required" => 1},
             "publication_authority_counts" => %{"operator_review" => 1},
             "timeline_publication_source_artifact_type_counts" => %{
               "operational_timeline_report.v1" => 1
             },
             "publication_ids" => ["timeline_publication:quality_review"],
             "source_artifact_ids" => ["operational_timeline:quality_activity"],
             "supersedes_artifact_ids" => ["timeline_publication:quality_prior"],
             "downstream_product_ids" => ["cadence_import:quality_activity"],
             "invalidated_downstream_product_ids" => ["timeline_product:quality_stale"],
             "dependency_impact_row_count" => 1,
             "impacted_dependency_activity_ids" => ["activity_dependency:quality_antenna"],
             "impacted_dependency_timeline_ids" => ["timeline:quality_dependency"],
             "impacted_exclusive_with_activity_ids" => ["activity:quality_exclusive"],
             "impacted_exclusive_with_timeline_ids" => ["timeline:quality_exclusive"],
             "timeline_diff_row_count" => 1,
             "timeline_diff_changed_count" => 1,
             "timeline_diff_review_required_count" => 1,
             "changed_field_counts" => %{"resource_assignment" => 1},
             "changed_timeline_ids" => ["timeline:quality_changed"],
             "review_timeline_ids" => ["timeline:quality_review"],
             "timeline_ids_by_changed_field" => %{
               "resource_assignment" => ["timeline:quality_changed"]
             },
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
               "replay_scope" => "quality_gate_source_report_provenance_only",
               "operator_authority" => "not_granted_by_quality_gate_replay_summary",
               "cadence_write" => "not_performed_by_summary",
               "candidate_generation" => "not_performed_by_summary"
             }
           } = replay_summary = CandidateRefresh.quality_gate_replay_summary(refresh)

    assert OrbitalDynamics.candidate_refresh_quality_gate_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" =>
          Map.put(summary["source_reports"], "operational_readiness_report", %{
            "contract" => "operational_readiness_report.v1",
            "count" => 1,
            "row_count" => 1,
            "readiness_level_counts" => %{"blocked" => 99},
            "trust_boundary_status" => "declared"
          })
      }
    }

    assert %{
             "source_report_family_count" => 2,
             "source_report_quality_gate_contract" => "quality_gate_report.v1",
             "source_report_quality_gate_count" => 1,
             "source_report_quality_gate_row_count" => 3,
             "source_report_quality_gate_paths" => ["source_quality_gate_report"],
             "source_report_quality_gate_readiness_level_counts" => %{"blocked" => 1},
             "source_report_quality_gate_gate_status_counts" => %{
               "analysis_only" => 1,
               "blocked" => 1,
               "review_required" => 1
             },
             "source_report_quality_gate_analysis_mode_counts" => %{"simulation" => 1},
             "source_report_quality_gate_source_readiness_report_count" => 1,
             "source_report_quality_gate_branch_local_review_pressure" => true,
             "source_report_quality_gate_branch_local_import_pressure" => true,
             "source_report_quality_gate_branch_local_resource_pressure" => true,
             "source_report_quality_gate_branch_local_timeline_publication_pressure" => true,
             "source_report_quality_gate_branch_local_timeline_publication_dependency_pressure" =>
               true,
             "source_report_quality_gate_branch_local_timeline_publication_changed_field_pressure" =>
               true,
             "source_report_quality_gate_branch_local_timeline_publication_invalidation_pressure" =>
               true,
             "source_report_quality_gate_branch_local_timeline_publication_review_pressure" =>
               true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.quality_gate_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_quality_gate_replay_summary(artifact) ==
             replay_summary
  end
end
