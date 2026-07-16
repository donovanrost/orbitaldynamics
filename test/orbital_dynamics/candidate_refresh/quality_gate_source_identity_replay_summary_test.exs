defmodule OrbitalDynamics.CandidateRefresh.QualityGateSourceIdentityReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

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
end
