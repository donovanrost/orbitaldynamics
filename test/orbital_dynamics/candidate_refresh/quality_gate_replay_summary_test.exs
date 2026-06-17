defmodule OrbitalDynamics.CandidateRefresh.QualityGateReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CandidateRefresh, Epoch, ResultSet, Schema}

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

  test "quality gate replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "quality_gate_report" => %{
              "contract" => "quality_gate_report.v1",
              "count" => 1,
              "row_count" => 2,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_quality_gate_report"
              ],
              "readiness_level_counts" => %{"operator_review" => 1},
              "import_classification_counts" => %{"review_only" => 1},
              "status_counts" => %{"review_required" => 1},
              "gate_count" => 2,
              "review_gate_count" => 1,
              "blocked_gate_count" => 1,
              "gate_status_counts" => %{"review_required" => 1, "blocked" => 1},
              "gate_classification_counts" => %{"review_only" => 1, "blocked" => 1},
              "quality_gate_row_ids_by_status" => %{
                "review_required" => ["quality_gate:branch:review"],
                "blocked" => ["quality_gate:branch:blocked"],
                "passed" => ["quality_gate:branch:ready"],
                "analysis_only" => ["quality_gate:branch:analysis"]
              },
              "review_required_quality_gate_row_ids" => ["stale_branch_review"],
              "blocked_quality_gate_row_ids" => ["stale_branch_blocked"],
              "ready_quality_gate_row_ids" => ["stale_branch_ready"],
              "analysis_only_quality_gate_row_ids" => ["stale_branch_analysis"],
              "manifest_review_required_count" => 1,
              "blocked_import_count" => 1,
              "import_status_counts" => %{"review_required_before_import" => 1},
              "cadence_import_status_counts" => %{"missing" => 1},
              "resource_availability_reason_counts" => %{"payload_unavailable" => 1},
              "resource_availability_reason_ids" => ["payload_unavailable"],
              "unavailable_resource_reason_ids" => ["payload_unavailable"],
              "resource_blocking_dimension_counts" => %{"payload" => 1},
              "publication_status_counts" => %{"review_required" => 1},
              "dependency_impact_status_counts" => %{"review_required" => 1},
              "publication_authority_counts" => %{"operator_review" => 1},
              "publication_ids" => ["timeline_publication:quality_branch"],
              "changed_field_counts" => %{"resource_assignment" => 1},
              "timeline_ids_by_changed_field" => %{
                "resource_assignment" => ["timeline:quality_branch_changed"]
              },
              "review_timeline_ids" => ["timeline:quality_branch_review"],
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_quality_gate"]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "quality_gate_report" => %{
            "contract" => "quality_gate_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.quality_gate_report"],
            "readiness_level_counts" => %{},
            "import_status_counts" => %{},
            "resource_availability_reason_counts" => %{}
          }
        }
      }
    }

    summary = CandidateRefresh.quality_gate_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.quality_gate_report"

    assert summary["contract"] == "quality_gate_report.v1"
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 2

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_quality_gate_report"
           ]

    assert summary["readiness_level_counts"] == %{"operator_review" => 1}
    assert summary["import_classification_counts"] == %{"review_only" => 1}
    assert summary["status_counts"] == %{"review_required" => 1}
    assert summary["gate_count"] == 2
    assert summary["review_gate_count"] == 1
    assert summary["blocked_gate_count"] == 1
    assert summary["gate_status_counts"] == %{"review_required" => 1, "blocked" => 1}
    assert summary["gate_classification_counts"] == %{"review_only" => 1, "blocked" => 1}
    assert summary["review_required_quality_gate_row_ids"] == ["quality_gate:branch:review"]
    assert summary["blocked_quality_gate_row_ids"] == ["quality_gate:branch:blocked"]
    assert summary["ready_quality_gate_row_ids"] == ["quality_gate:branch:ready"]
    assert summary["analysis_only_quality_gate_row_ids"] == ["quality_gate:branch:analysis"]
    assert summary["manifest_review_required_count"] == 1
    assert summary["blocked_import_count"] == 1
    assert summary["import_status_counts"] == %{"review_required_before_import" => 1}
    assert summary["cadence_import_status_counts"] == %{"missing" => 1}
    assert summary["resource_availability_reason_counts"] == %{"payload_unavailable" => 1}
    assert summary["resource_availability_reason_ids"] == ["payload_unavailable"]
    assert summary["unavailable_resource_reason_ids"] == ["payload_unavailable"]
    assert summary["resource_blocking_dimension_counts"] == %{"payload" => 1}
    assert summary["publication_status_counts"] == %{"review_required" => 1}
    assert summary["dependency_impact_status_counts"] == %{"review_required" => 1}
    assert summary["publication_authority_counts"] == %{"operator_review" => 1}
    assert summary["publication_ids"] == ["timeline_publication:quality_branch"]
    assert summary["changed_field_counts"] == %{"resource_assignment" => 1}

    assert summary["timeline_ids_by_changed_field"] == %{
             "resource_assignment" => ["timeline:quality_branch_changed"]
           }

    assert summary["review_timeline_ids"] == ["timeline:quality_branch_review"]
    assert summary["branch_local_review_pressure"]
    assert summary["branch_local_import_pressure"]
    assert summary["branch_local_resource_pressure"]
    assert summary["branch_local_timeline_publication_pressure"]
    assert summary["branch_local_timeline_publication_dependency_pressure"]
    assert summary["branch_local_timeline_publication_changed_field_pressure"]
    refute summary["branch_local_timeline_publication_invalidation_pressure"]
    assert summary["branch_local_timeline_publication_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "quality_gate_candidate_source_report_summary_only"

    assert %{
             "source_report_quality_gate_branch_local_review_pressure" => true,
             "source_report_quality_gate_branch_local_import_pressure" => true,
             "source_report_quality_gate_branch_local_resource_pressure" => true,
             "source_report_quality_gate_branch_local_timeline_publication_pressure" => true,
             "source_report_quality_gate_branch_local_timeline_publication_dependency_pressure" =>
               true,
             "source_report_quality_gate_branch_local_timeline_publication_changed_field_pressure" =>
               true,
             "source_report_quality_gate_branch_local_timeline_publication_invalidation_pressure" =>
               false,
             "source_report_quality_gate_branch_local_timeline_publication_review_pressure" =>
               true
           } = CandidateRefresh.source_report_summary(artifact)

    assert OrbitalDynamics.candidate_refresh_quality_gate_replay_summary(artifact) ==
             summary
  end

  test "quality gate replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.quality_gate_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_quality_gate_contract")
    refute Map.has_key?(source_summary, "source_report_quality_gate_count")
    refute Map.has_key?(source_summary, "source_report_quality_gate_row_count")
    refute Map.has_key?(source_summary, "source_report_quality_gate_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_review_pressure"]
    refute summary["branch_local_import_pressure"]
    refute summary["branch_local_resource_pressure"]
  end

  test "quality gate source summary keeps declared contract without partial identity placeholders" do
    placeholder_fields = [
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.quality_gate_report"]},
      %{"count" => nil, "row_count" => 2},
      %{"count" => 1, "row_count" => nil}
    ]

    for placeholder <- placeholder_fields do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "quality_gate_report" =>
              Map.put(
                placeholder,
                "contract",
                "quality_gate_report.v1"
              )
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      assert source_summary["source_report_quality_gate_contract"] ==
               "quality_gate_report.v1"

      refute Map.has_key?(source_summary, "source_report_quality_gate_count")
      refute Map.has_key?(source_summary, "source_report_quality_gate_row_count")
      refute Map.has_key?(source_summary, "source_report_quality_gate_paths")
    end
  end

  test "quality gate source summary preserves non-identity rollups with partial identity" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "quality_gate_report" => %{
            "contract" => "quality_gate_report.v1",
            "count" => 1,
            "gate_status_counts" => %{"blocked" => 1},
            "resource_blocking_dimension_counts" => %{"communications" => 1}
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_quality_gate_contract"] ==
             "quality_gate_report.v1"

    refute Map.has_key?(source_summary, "source_report_quality_gate_count")
    refute Map.has_key?(source_summary, "source_report_quality_gate_row_count")
    refute Map.has_key?(source_summary, "source_report_quality_gate_paths")

    assert source_summary["source_report_quality_gate_gate_status_counts"] ==
             %{"blocked" => 1}

    assert source_summary["source_report_quality_gate_resource_blocking_dimension_counts"] ==
             %{"communications" => 1}
  end

  test "quality gate source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "quality_gate_report" => %{
            "contract" => "quality_gate_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.quality_gate_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_quality_gate_contract"] ==
             "quality_gate_report.v1"

    assert source_summary["source_report_quality_gate_count"] == 0
    assert source_summary["source_report_quality_gate_row_count"] == 0

    assert source_summary["source_report_quality_gate_paths"] == [
             "provenance.source_reports.quality_gate_report"
           ]
  end

  test "quality gate source summary omits missing identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "quality_gate_report" => %{
            "contract" => "quality_gate_report.v1",
            "count" => 1,
            "row_count" => 2
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_quality_gate_contract"] ==
             "quality_gate_report.v1"

    assert source_summary["source_report_quality_gate_count"] == 1
    assert source_summary["source_report_quality_gate_row_count"] == 2
    refute Map.has_key?(source_summary, "source_report_quality_gate_paths")
  end

  test "quality gate source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "quality_gate_report" => %{
            "contract" => "quality_gate_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_quality_gate_contract"] ==
             "quality_gate_report.v1"

    assert source_summary["source_report_quality_gate_count"] == 1
    assert source_summary["source_report_quality_gate_row_count"] == 2
    assert source_summary["source_report_quality_gate_paths"] == []
  end

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

  test "quality gate replay accepts operational unavailable-resource summaries" do
    unavailable_resource_summary =
      quality_gate_unavailable_resource_summary_fixture()
      |> Map.put("resource_availability_row_count", 99)

    refresh = %{
      "accepted_planning_state" => %{
        "operational_quality_gate_unavailable_resource_summary" => unavailable_resource_summary
      },
      "mission_state" => %{
        "source_operational_quality_gate_unavailable_resource_summary" =>
          unavailable_resource_summary
      },
      "source_operational_quality_gate_unavailable_resource_summary" =>
        unavailable_resource_summary
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_count" => 3,
             "source_report_row_count" => 3,
             "source_report_quality_gate_contract" => "quality_gate_report.v1",
             "source_report_quality_gate_count" => 3,
             "source_report_quality_gate_row_count" => 3,
             "source_report_quality_gate_paths" => [
               "accepted_planning_state.operational_quality_gate_unavailable_resource_summary",
               "mission_state.source_operational_quality_gate_unavailable_resource_summary",
               "source_operational_quality_gate_unavailable_resource_summary"
             ],
             "source_report_quality_gate_source_summary_model_counts" => %{
               "artifact_only_quality_gate_unavailable_resource_summary" => 3
             },
             "source_report_quality_gate_source_summary_schema_contract_counts" => %{
               "operational_quality_gate_unavailable_resource_summary.v1" => 3
             },
             "source_report_quality_gate_resource_availability_pressure_count" => 6,
             "source_report_quality_gate_resource_availability_reason_counts" => %{
               "ground_station_unavailable" => 3,
               "payload_unavailable" => 3
             },
             "source_report_quality_gate_station_availability_reason_ids" => [
               "ground_station_unavailable"
             ],
             "source_report_quality_gate_station_availability_reason_counts" => %{
               "ground_station_unavailable" => 3
             },
             "source_report_quality_gate_unavailable_resource_reason_ids" => [
               "payload_unavailable"
             ],
             "source_report_quality_gate_resource_blocking_dimension_counts" => %{
               "payload" => 3
             },
             "source_report_quality_gate_blocked_contact_ids_by_blocking_dimension" => %{
               "payload" => ["contact:payload_blocked"]
             },
             "source_report_quality_gate_blocked_contact_ids_by_spacecraft_id" => %{
               "leo_1" => ["contact:payload_blocked"]
             },
             "source_report_quality_gate_blocked_contact_ids_by_status" => %{
               "review_required" => ["contact:payload_blocked"]
             },
             "source_reports" => %{
               "quality_gate_report" => %{
                 "paths" => [
                   "accepted_planning_state.operational_quality_gate_unavailable_resource_summary",
                   "mission_state.source_operational_quality_gate_unavailable_resource_summary",
                   "source_operational_quality_gate_unavailable_resource_summary"
                 ],
                 "contract" => "quality_gate_report.v1",
                 "count" => 3,
                 "row_count" => 3,
                 "source_summary_schema_contract_counts" => %{
                   "operational_quality_gate_unavailable_resource_summary.v1" => 3
                 },
                 "resource_availability_reason_counts" => %{
                   "ground_station_unavailable" => 3,
                   "payload_unavailable" => 3
                 }
               }
             }
           } = source_report_summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "source_report_paths" => [
               "accepted_planning_state.operational_quality_gate_unavailable_resource_summary",
               "mission_state.source_operational_quality_gate_unavailable_resource_summary",
               "source_operational_quality_gate_unavailable_resource_summary"
             ],
             "source_report_row_count" => 3,
             "source_summary_model_counts" => %{
               "artifact_only_quality_gate_unavailable_resource_summary" => 3
             },
             "source_summary_schema_contract_counts" => %{
               "operational_quality_gate_unavailable_resource_summary.v1" => 3
             },
             "resource_availability_pressure_count" => 6,
             "resource_availability_reason_counts" => %{
               "ground_station_unavailable" => 3,
               "payload_unavailable" => 3
             },
             "resource_availability_reason_ids" => [
               "ground_station_unavailable",
               "payload_unavailable"
             ],
             "station_availability_reason_ids" => ["ground_station_unavailable"],
             "station_availability_reason_counts" => %{"ground_station_unavailable" => 3},
             "unavailable_resource_reason_ids" => ["payload_unavailable"],
             "resource_blocking_dimension_counts" => %{"payload" => 3},
             "blocked_contact_ids_by_blocking_dimension" => %{
               "payload" => ["contact:payload_blocked"]
             },
             "blocked_contact_ids_by_spacecraft_id" => %{
               "leo_1" => ["contact:payload_blocked"]
             },
             "blocked_contact_ids_by_status" => %{
               "review_required" => ["contact:payload_blocked"]
             },
             "review_required_quality_gate_row_ids" => [
               "quality_gate:activity_1:resource_availability"
             ],
             "branch_local_review_pressure" => true,
             "branch_local_import_pressure" => false,
             "branch_local_resource_pressure" => true
           } = replay_summary = CandidateRefresh.quality_gate_replay_summary(refresh)

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_report_summary["source_reports"]}
    }

    assert CandidateRefresh.quality_gate_replay_summary(artifact) == replay_summary
  end

  test "quality gate replay treats explicit empty unavailable-resource status maps as zero rows" do
    unavailable_resource_summary =
      quality_gate_unavailable_resource_summary_fixture()
      |> Map.merge(%{
        "resource_availability_row_count" => 99,
        "quality_gate_row_ids_by_status" => %{},
        "quality_gate_ids_by_status" => %{}
      })

    refresh = %{
      "source_operational_quality_gate_unavailable_resource_summary" =>
        unavailable_resource_summary
    }

    source_report_summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "source_report_count" => 1,
             "source_report_row_count" => 0,
             "source_report_quality_gate_count" => 1,
             "source_report_quality_gate_row_count" => 0,
             "source_report_quality_gate_gate_count" => 0,
             "source_report_quality_gate_resource_availability_pressure_count" => 2,
             "source_report_quality_gate_resource_availability_reason_counts" => %{
               "ground_station_unavailable" => 1,
               "payload_unavailable" => 1
             },
             "source_reports" => %{
               "quality_gate_report" => %{
                 "row_count" => 0,
                 "gate_count" => 0,
                 "resource_availability_pressure_count" => 2
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
             "resource_availability_pressure_count" => 2,
             "branch_local_resource_pressure" => true
           } = replay_summary

    assert Map.get(replay_summary, "quality_gate_row_ids_by_status", %{}) == %{}
    assert Map.get(replay_summary, "review_required_quality_gate_row_ids", []) == []
  end

  test "quality gate replay accepts wrapped operational unavailable-resource summaries" do
    unavailable_resource_summary = quality_gate_unavailable_resource_summary_fixture()

    wrapper = %{
      "schema_contract" => "result_artifact.v1",
      "provenance" => %{"trust_boundary" => "unavailable_resource_adapter"},
      "source_operational_quality_gate_unavailable_resource_summary" =>
        unavailable_resource_summary
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
               "source_result_artifact[0].source_operational_quality_gate_unavailable_resource_summary"
             ],
             "source_summary_schema_contract_counts" => %{
               "operational_quality_gate_unavailable_resource_summary.v1" => 1
             },
             "resource_availability_reason_counts" => %{
               "ground_station_unavailable" => 1,
               "payload_unavailable" => 1
             },
             "blocked_contact_ids_by_spacecraft_id" => %{
               "leo_1" => ["contact:payload_blocked"]
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "unavailable_resource_adapter",
               "unavailable_resource_summary_fixture"
             ]
           } = get_in(artifact, ["provenance", "source_reports", "quality_gate_report"])

    assert %{
             "source_report_paths" => [
               "source_result_artifact[0].source_operational_quality_gate_unavailable_resource_summary"
             ],
             "source_summary_schema_contract_counts" => %{
               "operational_quality_gate_unavailable_resource_summary.v1" => 1
             },
             "resource_availability_reason_counts" => %{
               "ground_station_unavailable" => 1,
               "payload_unavailable" => 1
             },
             "blocked_contact_ids_by_spacecraft_id" => %{
               "leo_1" => ["contact:payload_blocked"]
             },
             "branch_local_resource_pressure" => true
           } = CandidateRefresh.quality_gate_replay_summary(artifact)

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

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

  test "quality gate replay derives raw provenance row routing from status maps" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "quality_gate_report" => %{
            "contract" => "quality_gate_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.quality_gate_report"],
            "review_gate_count" => 0,
            "blocked_gate_count" => 0,
            "quality_gate_row_ids_by_status" => %{
              "review_required" => ["quality_gate:raw:review"],
              "blocked" => ["quality_gate:raw:blocked"],
              "passed" => ["quality_gate:raw:ready"],
              "analysis_only" => ["quality_gate:raw:analysis"]
            },
            "review_required_quality_gate_row_ids" => ["stale_review"],
            "blocked_quality_gate_row_ids" => ["stale_blocked"],
            "ready_quality_gate_row_ids" => ["stale_ready"],
            "analysis_only_quality_gate_row_ids" => ["stale_analysis"]
          }
        }
      }
    }

    assert %{
             "source_report_quality_gate_review_required_quality_gate_row_ids" => [
               "quality_gate:raw:review"
             ],
             "source_report_quality_gate_blocked_quality_gate_row_ids" => [
               "quality_gate:raw:blocked"
             ],
             "source_report_quality_gate_ready_quality_gate_row_ids" => [
               "quality_gate:raw:ready"
             ],
             "source_report_quality_gate_analysis_only_quality_gate_row_ids" => [
               "quality_gate:raw:analysis"
             ]
           } = CandidateRefresh.source_report_summary(artifact)

    assert %{
             "quality_gate_row_ids_by_status" => %{
               "review_required" => ["quality_gate:raw:review"],
               "blocked" => ["quality_gate:raw:blocked"],
               "passed" => ["quality_gate:raw:ready"],
               "analysis_only" => ["quality_gate:raw:analysis"]
             },
             "review_required_quality_gate_row_ids" => ["quality_gate:raw:review"],
             "blocked_quality_gate_row_ids" => ["quality_gate:raw:blocked"],
             "ready_quality_gate_row_ids" => ["quality_gate:raw:ready"],
             "analysis_only_quality_gate_row_ids" => ["quality_gate:raw:analysis"]
           } = CandidateRefresh.quality_gate_replay_summary(artifact)
  end

  test "source report summary derives direct compact quality-gate summary row routing from status maps" do
    refresh = %{
      "source_operational_quality_gate_summary" => %{
        "schema_contract" => "operational_quality_gate_summary.v1",
        "model" => "artifact_only_quality_gate_summary",
        "rows" => [],
        "quality_gate_row_ids_by_status" => %{
          "review_required" => ["quality_gate:direct:review"],
          "blocked" => ["quality_gate:direct:blocked"],
          "passed" => ["quality_gate:direct:ready"],
          "analysis_only" => ["quality_gate:direct:analysis"]
        },
        "review_required_quality_gate_row_ids" => ["stale_review"],
        "blocked_quality_gate_row_ids" => ["stale_blocked"],
        "ready_quality_gate_row_ids" => ["stale_ready"],
        "analysis_only_quality_gate_row_ids" => ["stale_analysis"]
      }
    }

    assert %{
             "source_report_quality_gate_review_required_quality_gate_row_ids" => [
               "quality_gate:direct:review"
             ],
             "source_report_quality_gate_blocked_quality_gate_row_ids" => [
               "quality_gate:direct:blocked"
             ],
             "source_report_quality_gate_ready_quality_gate_row_ids" => [
               "quality_gate:direct:ready"
             ],
             "source_report_quality_gate_analysis_only_quality_gate_row_ids" => [
               "quality_gate:direct:analysis"
             ],
             "source_reports" => %{
               "quality_gate_report" => %{
                 "review_required_quality_gate_row_ids" => ["quality_gate:direct:review"],
                 "blocked_quality_gate_row_ids" => ["quality_gate:direct:blocked"],
                 "ready_quality_gate_row_ids" => ["quality_gate:direct:ready"],
                 "analysis_only_quality_gate_row_ids" => ["quality_gate:direct:analysis"]
               }
             }
           } = source_summary = CandidateRefresh.source_report_summary(refresh)

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_summary["source_reports"]}
    }

    assert CandidateRefresh.quality_gate_replay_summary(artifact) ==
             CandidateRefresh.quality_gate_replay_summary(refresh)
  end

  test "quality gate replay lets empty status maps block stale row routing arrays" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "quality_gate_report" => %{
            "contract" => "quality_gate_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.quality_gate_report"],
            "review_gate_count" => 0,
            "blocked_gate_count" => 0,
            "quality_gate_row_ids_by_status" => %{},
            "review_required_quality_gate_row_ids" => ["stale_review"],
            "blocked_quality_gate_row_ids" => ["stale_blocked"],
            "ready_quality_gate_row_ids" => ["stale_ready"],
            "analysis_only_quality_gate_row_ids" => ["stale_analysis"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.quality_gate_replay_summary(artifact)

    assert Map.get(
             source_summary,
             "source_report_quality_gate_review_required_quality_gate_row_ids",
             []
           ) == []

    assert Map.get(
             source_summary,
             "source_report_quality_gate_blocked_quality_gate_row_ids",
             []
           ) == []

    assert Map.get(source_summary, "source_report_quality_gate_ready_quality_gate_row_ids", []) ==
             []

    assert Map.get(
             source_summary,
             "source_report_quality_gate_analysis_only_quality_gate_row_ids",
             []
           ) == []

    assert replay_summary["quality_gate_row_ids_by_status"] == %{}
    assert replay_summary["review_required_quality_gate_row_ids"] == []
    assert replay_summary["blocked_quality_gate_row_ids"] == []
    assert replay_summary["ready_quality_gate_row_ids"] == []
    assert replay_summary["analysis_only_quality_gate_row_ids"] == []
  end

  test "source report summary lets direct compact summary empty status maps block stale row routing arrays" do
    refresh = %{
      "source_operational_quality_gate_summary" => %{
        "schema_contract" => "operational_quality_gate_summary.v1",
        "model" => "artifact_only_quality_gate_summary",
        "rows" => [],
        "quality_gate_row_ids_by_status" => %{},
        "review_required_quality_gate_row_ids" => ["stale_review"],
        "blocked_quality_gate_row_ids" => ["stale_blocked"],
        "ready_quality_gate_row_ids" => ["stale_ready"],
        "analysis_only_quality_gate_row_ids" => ["stale_analysis"]
      }
    }

    source_summary = CandidateRefresh.source_report_summary(refresh)

    assert get_in(source_summary, [
             "source_reports",
             "quality_gate_report",
             "review_required_quality_gate_row_ids"
           ]) in [nil, []]

    assert get_in(source_summary, [
             "source_reports",
             "quality_gate_report",
             "blocked_quality_gate_row_ids"
           ]) in [nil, []]

    assert get_in(source_summary, [
             "source_reports",
             "quality_gate_report",
             "ready_quality_gate_row_ids"
           ]) in [nil, []]

    assert get_in(source_summary, [
             "source_reports",
             "quality_gate_report",
             "analysis_only_quality_gate_row_ids"
           ]) in [nil, []]
  end

  test "quality gate replay treats status and import maps as pressure" do
    base_summary = %{
      "contract" => "quality_gate_report.v1",
      "count" => 1,
      "row_count" => 1,
      "paths" => ["provenance.source_reports.quality_gate_report"],
      "review_gate_count" => 0,
      "blocked_gate_count" => 0,
      "manifest_review_required_count" => 0,
      "missing_import_count" => 0,
      "blocked_import_count" => 0,
      "invalid_cadence_import_count" => 0,
      "resource_availability_pressure_count" => 0,
      "readiness_level_counts" => %{},
      "import_classification_counts" => %{},
      "status_counts" => %{},
      "analysis_mode_counts" => %{},
      "gate_status_counts" => %{},
      "gate_classification_counts" => %{},
      "import_status_counts" => %{},
      "cadence_import_status_counts" => %{},
      "resource_availability_reason_counts" => %{},
      "resource_availability_reason_ids" => [],
      "station_availability_reason_ids" => [],
      "station_availability_reason_counts" => %{},
      "unavailable_resource_reason_ids" => [],
      "resource_blocking_dimension_counts" => %{}
    }

    cases = [
      {"readiness level", %{"readiness_level_counts" => %{"operator_review" => 1}},
       "branch_local_review_pressure"},
      {"import classification", %{"import_classification_counts" => %{"review_only" => 1}},
       "branch_local_review_pressure"},
      {"status", %{"status_counts" => %{"review_required" => 1}}, "branch_local_review_pressure"},
      {"analysis mode", %{"analysis_mode_counts" => %{"simulation" => 1}},
       "branch_local_review_pressure"},
      {"gate status", %{"gate_status_counts" => %{"review_required" => 1}},
       "branch_local_review_pressure"},
      {"gate classification", %{"gate_classification_counts" => %{"review_only" => 1}},
       "branch_local_review_pressure"},
      {"import status", %{"import_status_counts" => %{"review_required_before_import" => 1}},
       "branch_local_import_pressure"},
      {"cadence import status", %{"cadence_import_status_counts" => %{"missing" => 1}},
       "branch_local_import_pressure"}
    ]

    for {label, evidence, expected_pressure} <- cases do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "quality_gate_report" => Map.merge(base_summary, evidence)
          }
        }
      }

      summary = CandidateRefresh.quality_gate_replay_summary(artifact)

      assert summary["source_report_count"] == 1, label
      assert summary["source_report_row_count"] == 1, label
      assert summary["review_gate_count"] == 0, label
      assert summary["blocked_gate_count"] == 0, label
      assert summary["manifest_review_required_count"] == 0, label
      assert summary["missing_import_count"] == 0, label
      assert summary["blocked_import_count"] == 0, label
      assert summary["invalid_cadence_import_count"] == 0, label
      refute summary["branch_local_resource_pressure"], label
      assert summary[expected_pressure], label
    end
  end

  test "quality gate replay treats resource routing maps as resource pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "quality_gate_report" => %{
            "contract" => "quality_gate_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["provenance.source_reports.quality_gate_report"],
            "review_gate_count" => 0,
            "blocked_gate_count" => 0,
            "manifest_review_required_count" => 0,
            "missing_import_count" => 0,
            "blocked_import_count" => 0,
            "invalid_cadence_import_count" => 0,
            "resource_availability_pressure_count" => 0,
            "resource_availability_reason_counts" => %{"payload_unavailable" => 1},
            "resource_availability_reason_ids" => ["payload_unavailable"],
            "station_availability_reason_ids" => [],
            "station_availability_reason_counts" => %{},
            "unavailable_resource_reason_ids" => ["payload_unavailable"],
            "resource_blocking_dimension_counts" => %{"payload" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.quality_gate_replay_summary(artifact)

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1
    assert summary["source_report_paths"] == ["provenance.source_reports.quality_gate_report"]
    assert summary["resource_availability_pressure_count"] == 0
    assert summary["resource_availability_reason_counts"] == %{"payload_unavailable" => 1}
    assert summary["resource_availability_reason_ids"] == ["payload_unavailable"]
    assert summary["unavailable_resource_reason_ids"] == ["payload_unavailable"]
    assert summary["resource_blocking_dimension_counts"] == %{"payload" => 1}
    assert summary["branch_local_resource_pressure"]
    refute summary["branch_local_review_pressure"]
    refute summary["branch_local_import_pressure"]
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

  defp quality_gate_unavailable_resource_summary_fixture do
    %{
      "schema_contract" => "operational_quality_gate_unavailable_resource_summary.v1",
      "model" => "artifact_only_quality_gate_unavailable_resource_summary",
      "source" => "quality_gate_report.v1",
      "source_artifact_type" => "contact_filter_report.v1",
      "source_artifact_id" => "contact_filter:payload_blocked",
      "source_quality_gate_report_id" => "quality_gate:contact_filter:payload_blocked",
      "source_readiness_report_id" => "operational_readiness:contact_filter:payload_blocked",
      "resource_availability_row_count" => 1,
      "unavailable_resource_row_count" => 1,
      "unavailable_resource_pressure_count" => 1,
      "unavailable_resource_reason_counts" => %{"payload_unavailable" => 1},
      "unavailable_resource_reason_ids" => ["payload_unavailable"],
      "station_availability_reason_counts" => %{"ground_station_unavailable" => 1},
      "station_availability_reason_ids" => ["ground_station_unavailable"],
      "resource_blocking_dimension_counts" => %{"payload" => 1},
      "blocked_contact_ids_by_blocking_dimension" => %{
        "payload" => ["contact:payload_blocked"]
      },
      "blocked_contact_ids_by_spacecraft_id" => %{
        "leo_1" => ["contact:payload_blocked"]
      },
      "blocked_contact_ids_by_status" => %{
        "review_required" => ["contact:payload_blocked"]
      },
      "quality_gate_row_ids_by_status" => %{
        "review_required" => ["quality_gate:activity_1:resource_availability"]
      },
      "quality_gate_ids_by_status" => %{"review_required" => ["resource_availability"]},
      "review_required_quality_gate_row_ids" => [
        "quality_gate:activity_1:resource_availability"
      ],
      "blocked_quality_gate_row_ids" => [],
      "resource_availability_gate_ids" => ["resource_availability"],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "source" => "quality_gate_report.v1",
        "operator_authority" => "not_granted_by_unavailable_resource_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary"
      },
      "provenance" => %{"trust_boundary" => "unavailable_resource_summary_fixture"}
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
