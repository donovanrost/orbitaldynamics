defmodule OrbitalDynamics.CandidateRefresh.ValidationSafetyCaseReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summaries include validation safety-case summaries" do
    direct_summary = %{
      "schema_contract" => "validation_safety_case_summary.v1",
      "status" => "blocked",
      "evidence_count" => 2,
      "evidence_status_counts" => %{"blocked" => 1, "review_required" => 1},
      "input_contracts" => ["model_acceptance_report.v1", "quality_gate_report.v1"],
      "evidence_refs_by_status" => %{
        "blocked" => ["model_acceptance_report.v1:model.blocked"],
        "review_required" => ["quality_gate_report.v1:gate.review"]
      },
      "evidence_refs_by_contract" => %{
        "model_acceptance_report.v1" => ["model_acceptance_report.v1:model.blocked"],
        "quality_gate_report.v1" => ["quality_gate_report.v1:gate.review"]
      },
      "blocked_evidence_count" => 1,
      "review_required_evidence_count" => 1,
      "model_blocked_count" => 1,
      "quality_gate_review_count" => 1,
      "provenance" => %{"trust_boundary" => "mission_state_safety_case"}
    }

    wrapped_summary = %{
      "schema_contract" => "validation_safety_case_summary.v1",
      "status" => "review_required",
      "evidence" => [%{"status" => "review_required", "schema_warning_count" => 2}],
      "evidence_status_counts" => %{"stale_evidence_status" => 99},
      "accepted_evidence_count" => 0,
      "review_required_evidence_count" => 1,
      "schema_warning_count" => 2
    }

    refresh = %{
      "mission_state" => %{"source_validation_safety_case_summary" => direct_summary},
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "validation_safety_case_summary" => wrapped_summary,
        "provenance" => %{"trust_boundary" => "result_wrapper"}
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_count" => 2,
             "source_report_row_count" => 3,
             "source_report_counts_by_family" => %{
               "validation_safety_case_summary" => 2
             },
             "source_report_row_counts_by_contract" => %{
               "validation_safety_case_summary.v1" => 3
             },
             "source_report_paths" => [
               "mission_state.source_validation_safety_case_summary",
               "source_result_artifact.validation_safety_case_summary"
             ],
             "source_report_validation_safety_case_contract" =>
               "validation_safety_case_summary.v1",
             "source_report_validation_safety_case_count" => 2,
             "source_report_validation_safety_case_row_count" => 3,
             "source_report_validation_safety_case_paths" => [
               "mission_state.source_validation_safety_case_summary",
               "source_result_artifact.validation_safety_case_summary"
             ],
             "source_report_validation_safety_case_evidence_count" => 3,
             "source_report_validation_safety_case_status_counts" => %{
               "blocked" => 1,
               "review_required" => 1
             },
             "source_report_validation_safety_case_evidence_status_counts" => %{
               "blocked" => 1,
               "review_required" => 2
             },
             "source_report_validation_safety_case_input_contract_counts" => %{
               "model_acceptance_report.v1" => 1,
               "quality_gate_report.v1" => 1
             },
             "source_report_validation_safety_case_evidence_refs_by_status" => %{
               "blocked" => ["model_acceptance_report.v1:model.blocked"],
               "review_required" => ["quality_gate_report.v1:gate.review"]
             },
             "source_report_validation_safety_case_evidence_refs_by_contract" => %{
               "model_acceptance_report.v1" => ["model_acceptance_report.v1:model.blocked"],
               "quality_gate_report.v1" => ["quality_gate_report.v1:gate.review"]
             },
             "source_report_validation_safety_case_review_required_evidence_count" => 2,
             "source_report_validation_safety_case_blocked_evidence_count" => 1,
             "source_report_validation_safety_case_model_blocked_count" => 1,
             "source_report_validation_safety_case_quality_gate_review_count" => 1,
             "source_report_validation_safety_case_schema_warning_count" => 2,
             "source_report_validation_safety_case_branch_local_review_pressure" => true,
             "source_report_validation_safety_case_branch_local_blocking_pressure" => true,
             "source_report_validation_safety_case_branch_local_schema_pressure" => true,
             "source_report_validation_safety_case_branch_local_fixture_pressure" => false,
             "source_reports" => %{
               "validation_safety_case_summary" => safety_case_summary
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "contract" => "validation_safety_case_summary.v1",
             "count" => 2,
             "row_count" => 3,
             "status_counts" => %{"blocked" => 1, "review_required" => 1},
             "evidence_status_counts" => %{"blocked" => 1, "review_required" => 2},
             "input_contract_counts" => %{
               "model_acceptance_report.v1" => 1,
               "quality_gate_report.v1" => 1
             },
             "evidence_refs_by_status" => %{
               "blocked" => ["model_acceptance_report.v1:model.blocked"],
               "review_required" => ["quality_gate_report.v1:gate.review"]
             },
             "blocked_evidence_count" => 1,
             "review_required_evidence_count" => 2,
             "model_blocked_count" => 1,
             "quality_gate_review_count" => 1,
             "schema_warning_count" => 2,
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["mission_state_safety_case", "result_wrapper"]
           } = safety_case_summary

    assert %{
             "model" => "artifact_only_candidate_refresh_validation_safety_case_replay_summary",
             "source" =>
               "candidate_refresh.source_report_provenance.validation_safety_case_summary",
             "contract" => "validation_safety_case_summary.v1",
             "source_report_count" => 2,
             "source_report_row_count" => 3,
             "source_report_paths" => [
               "mission_state.source_validation_safety_case_summary",
               "source_result_artifact.validation_safety_case_summary"
             ],
             "status_counts" => %{"blocked" => 1, "review_required" => 1},
             "evidence_status_counts" => %{"blocked" => 1, "review_required" => 2},
             "input_contract_counts" => %{
               "model_acceptance_report.v1" => 1,
               "quality_gate_report.v1" => 1
             },
             "evidence_refs_by_status" => %{
               "blocked" => ["model_acceptance_report.v1:model.blocked"],
               "review_required" => ["quality_gate_report.v1:gate.review"]
             },
             "evidence_refs_by_contract" => %{
               "model_acceptance_report.v1" => ["model_acceptance_report.v1:model.blocked"],
               "quality_gate_report.v1" => ["quality_gate_report.v1:gate.review"]
             },
             "accepted_evidence_count" => 0,
             "review_required_evidence_count" => 2,
             "blocked_evidence_count" => 1,
             "model_blocked_count" => 1,
             "quality_gate_review_count" => 1,
             "schema_warning_count" => 2,
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["mission_state_safety_case", "result_wrapper"],
             "branch_local_review_pressure" => true,
             "branch_local_blocking_pressure" => true,
             "branch_local_schema_pressure" => true,
             "branch_local_fixture_pressure" => false,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
               "replay_scope" => "validation_safety_case_source_report_provenance_only",
               "operator_authority" => "not_granted_by_validation_safety_case_replay_summary",
               "safety_case_certification" => "not_performed_by_summary",
               "model_certification" => "not_performed_by_summary",
               "import_approval" => "not_granted_by_validation_safety_case_replay_summary",
               "cadence_write" => "not_performed_by_summary",
               "candidate_generation" => "not_performed_by_summary"
             }
           } = replay_summary = CandidateRefresh.validation_safety_case_replay_summary(refresh)

    assert OrbitalDynamics.candidate_refresh_validation_safety_case_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" =>
          Map.put(summary["source_reports"], "model_acceptance_report", %{
            "contract" => "model_acceptance_report.v1",
            "count" => 1,
            "row_count" => 1,
            "blocked_count" => 99,
            "trust_boundary_status" => "declared"
          })
      }
    }

    assert %{
             "source_report_family_count" => 2,
             "source_report_validation_safety_case_contract" =>
               "validation_safety_case_summary.v1",
             "source_report_validation_safety_case_count" => 2,
             "source_report_validation_safety_case_row_count" => 3,
             "source_report_validation_safety_case_paths" => [
               "mission_state.source_validation_safety_case_summary",
               "source_result_artifact.validation_safety_case_summary"
             ],
             "source_report_validation_safety_case_evidence_count" => 3,
             "source_report_validation_safety_case_status_counts" => %{
               "blocked" => 1,
               "review_required" => 1
             },
             "source_report_validation_safety_case_evidence_refs_by_status" => %{
               "blocked" => ["model_acceptance_report.v1:model.blocked"],
               "review_required" => ["quality_gate_report.v1:gate.review"]
             },
             "source_report_validation_safety_case_blocked_evidence_count" => 1,
             "source_report_validation_safety_case_schema_warning_count" => 2,
             "source_report_validation_safety_case_branch_local_review_pressure" => true,
             "source_report_validation_safety_case_branch_local_blocking_pressure" => true,
             "source_report_validation_safety_case_branch_local_schema_pressure" => true,
             "source_report_validation_safety_case_branch_local_fixture_pressure" => false
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.validation_safety_case_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_validation_safety_case_replay_summary(artifact) ==
             replay_summary
  end

  test "validation safety case replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "validation_safety_case_summary" => %{
              "contract" => "validation_safety_case_summary.v1",
              "count" => 1,
              "row_count" => 2,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_validation_safety_case_summary"
              ],
              "status_counts" => %{"review_required" => 1},
              "evidence_status_counts" => %{"blocked" => 1, "review_required" => 1},
              "input_contract_counts" => %{
                "schema_validation_report.v1" => 1,
                "validation_reference_fixture.v1" => 1
              },
              "evidence_refs_by_status" => %{
                "blocked" => ["schema_validation_report.v1:error"],
                "review_required" => ["quality_gate_report.v1:review"]
              },
              "evidence_refs_by_contract" => %{
                "schema_validation_report.v1" => ["schema_validation_report.v1:error"],
                "validation_reference_fixture.v1" => ["fixture:challenge_case"]
              },
              "accepted_evidence_count" => 0,
              "review_required_evidence_count" => 0,
              "blocked_evidence_count" => 0,
              "model_blocked_count" => 0,
              "readiness_blocked_count" => 0,
              "quality_gate_blocked_count" => 0,
              "schema_error_count" => 0,
              "schema_warning_count" => 0,
              "schema_validation_failed_report_count" => 0,
              "fixture_failed_count" => 0,
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_validation_safety_case"]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "validation_safety_case_summary" => %{
            "contract" => "validation_safety_case_summary.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.validation_safety_case_summary"],
            "status_counts" => %{},
            "evidence_status_counts" => %{},
            "input_contract_counts" => %{},
            "evidence_refs_by_status" => %{},
            "evidence_refs_by_contract" => %{}
          }
        }
      }
    }

    summary = CandidateRefresh.validation_safety_case_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.validation_safety_case_summary"

    assert summary["contract"] == "validation_safety_case_summary.v1"
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 2

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_validation_safety_case_summary"
           ]

    assert summary["status_counts"] == %{"review_required" => 1}
    assert summary["evidence_status_counts"] == %{"blocked" => 1, "review_required" => 1}

    assert summary["input_contract_counts"] == %{
             "schema_validation_report.v1" => 1,
             "validation_reference_fixture.v1" => 1
           }

    assert summary["evidence_refs_by_status"] == %{
             "blocked" => ["schema_validation_report.v1:error"],
             "review_required" => ["quality_gate_report.v1:review"]
           }

    assert summary["evidence_refs_by_contract"] == %{
             "schema_validation_report.v1" => ["schema_validation_report.v1:error"],
             "validation_reference_fixture.v1" => ["fixture:challenge_case"]
           }

    assert summary["review_required_evidence_count"] == 1
    assert summary["blocked_evidence_count"] == 1
    assert summary["schema_warning_count"] == 0
    assert summary["fixture_failed_count"] == 0
    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_validation_safety_case"]
    assert summary["branch_local_review_pressure"]
    assert summary["branch_local_blocking_pressure"]
    assert summary["branch_local_schema_pressure"]
    assert summary["branch_local_fixture_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "validation_safety_case_candidate_source_report_summary_only"

    assert %{
             "source_report_validation_safety_case_branch_local_review_pressure" => true,
             "source_report_validation_safety_case_branch_local_blocking_pressure" => true,
             "source_report_validation_safety_case_branch_local_schema_pressure" => true,
             "source_report_validation_safety_case_branch_local_fixture_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert OrbitalDynamics.candidate_refresh_validation_safety_case_replay_summary(artifact) ==
             summary
  end

  test "validation safety case source summary derives pressure counts from evidence rows" do
    stale_safety_case_summary = %{
      "schema_contract" => "validation_safety_case_summary.v1",
      "schema_version" => 1,
      "status" => "accepted_for_use",
      "evidence_count" => 99,
      "input_contracts" => [],
      "evidence_status_counts" => %{"accepted_for_use" => 99},
      "evidence_refs_by_status" => %{"accepted_for_use" => ["stale.accepted"]},
      "evidence_refs_by_contract" => %{"stale_contract.v1" => ["stale.accepted"]},
      "accepted_evidence_count" => 99,
      "review_required_evidence_count" => 0,
      "blocked_evidence_count" => 0,
      "model_review_required_count" => 0,
      "model_blocked_count" => 0,
      "readiness_review_required_count" => 0,
      "readiness_blocked_count" => 0,
      "quality_gate_review_count" => 0,
      "quality_gate_blocked_count" => 0,
      "schema_error_count" => 0,
      "schema_warning_count" => 0,
      "schema_validation_report_count" => 0,
      "schema_validation_failed_report_count" => 0,
      "fixture_passed_count" => 99,
      "fixture_failed_count" => 0,
      "evidence" => [
        %{
          "schema_contract" => "schema_validation_batch_report.v1",
          "status" => "blocked",
          "evidence_ref" => "schema_validation_batch_report.v1:batch.blocked",
          "schema_error_count" => 2,
          "schema_warning_count" => 1,
          "schema_validation_report_count" => 3,
          "schema_validation_failed_report_count" => 2
        },
        %{
          "schema_contract" => "validation_reference_fixture_report.v1",
          "status" => "blocked",
          "evidence_ref" => "validation_reference_fixture_report.v1:fixtures.failed",
          "fixture_passed_count" => 1,
          "fixture_failed_count" => 2
        },
        %{
          "schema_contract" => "model_acceptance_report.v1",
          "status" => "review_required",
          "evidence_ref" => "model_acceptance_report.v1:model.review",
          "model_review_required_count" => 1,
          "model_blocked_count" => 1
        },
        %{
          "schema_contract" => "operational_readiness_report.v1",
          "status" => "review_required",
          "evidence_ref" => "operational_readiness_report.v1:readiness.review",
          "readiness_review_required_count" => 1,
          "readiness_blocked_count" => 1
        },
        %{
          "schema_contract" => "quality_gate_report.v1",
          "status" => "accepted_for_use",
          "evidence_ref" => "quality_gate_report.v1:gate.accepted",
          "quality_gate_review_count" => 1,
          "quality_gate_blocked_count" => 1
        }
      ],
      "provenance" => %{"trust_boundary" => "stale_safety_case_rows"}
    }

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "source_validation_safety_case_summary" => stale_safety_case_summary
    }

    assert %{
             "source_report_validation_safety_case_evidence_count" => 5,
             "source_report_validation_safety_case_evidence_status_counts" => %{
               "accepted_for_use" => 1,
               "blocked" => 2,
               "review_required" => 2
             },
             "source_report_validation_safety_case_input_contract_counts" => %{
               "model_acceptance_report.v1" => 1,
               "operational_readiness_report.v1" => 1,
               "quality_gate_report.v1" => 1,
               "schema_validation_batch_report.v1" => 1,
               "validation_reference_fixture_report.v1" => 1
             },
             "source_report_validation_safety_case_evidence_refs_by_status" => %{
               "accepted_for_use" => ["quality_gate_report.v1:gate.accepted"],
               "blocked" => [
                 "schema_validation_batch_report.v1:batch.blocked",
                 "validation_reference_fixture_report.v1:fixtures.failed"
               ],
               "review_required" => [
                 "model_acceptance_report.v1:model.review",
                 "operational_readiness_report.v1:readiness.review"
               ]
             },
             "source_report_validation_safety_case_accepted_evidence_count" => 1,
             "source_report_validation_safety_case_review_required_evidence_count" => 2,
             "source_report_validation_safety_case_blocked_evidence_count" => 2,
             "source_report_validation_safety_case_model_review_required_count" => 1,
             "source_report_validation_safety_case_model_blocked_count" => 1,
             "source_report_validation_safety_case_readiness_review_required_count" => 1,
             "source_report_validation_safety_case_readiness_blocked_count" => 1,
             "source_report_validation_safety_case_quality_gate_review_count" => 1,
             "source_report_validation_safety_case_quality_gate_blocked_count" => 1,
             "source_report_validation_safety_case_schema_error_count" => 2,
             "source_report_validation_safety_case_schema_warning_count" => 1,
             "source_report_validation_safety_case_schema_validation_report_count" => 3,
             "source_report_validation_safety_case_schema_validation_failed_report_count" => 2,
             "source_report_validation_safety_case_fixture_passed_count" => 1,
             "source_report_validation_safety_case_fixture_failed_count" => 2,
             "source_report_validation_safety_case_branch_local_review_pressure" => true,
             "source_report_validation_safety_case_branch_local_blocking_pressure" => true,
             "source_report_validation_safety_case_branch_local_schema_pressure" => true,
             "source_report_validation_safety_case_branch_local_fixture_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    summary = CandidateRefresh.validation_safety_case_replay_summary(artifact)

    assert summary["source_report_row_count"] == 5
    assert summary["accepted_evidence_count"] == 1
    assert summary["review_required_evidence_count"] == 2
    assert summary["blocked_evidence_count"] == 2
    assert summary["schema_error_count"] == 2
    assert summary["schema_warning_count"] == 1
    assert summary["schema_validation_report_count"] == 3
    assert summary["schema_validation_failed_report_count"] == 2
    assert summary["fixture_passed_count"] == 1
    assert summary["fixture_failed_count"] == 2
    assert summary["branch_local_review_pressure"]
    assert summary["branch_local_blocking_pressure"]
    assert summary["branch_local_schema_pressure"]
    assert summary["branch_local_fixture_pressure"]
  end

  test "validation safety case replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.validation_safety_case_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_validation_safety_case_contract")
    refute Map.has_key?(source_summary, "source_report_validation_safety_case_count")
    refute Map.has_key?(source_summary, "source_report_validation_safety_case_row_count")
    refute Map.has_key?(source_summary, "source_report_validation_safety_case_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_review_pressure"]
    refute summary["branch_local_blocking_pressure"]
    refute summary["branch_local_schema_pressure"]
    refute summary["branch_local_fixture_pressure"]
  end

  test "validation safety case source summary omits identity counts for empty family placeholder" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{"validation_safety_case_summary" => %{}}
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_validation_safety_case_contract")
    refute Map.has_key?(source_summary, "source_report_validation_safety_case_count")
    refute Map.has_key?(source_summary, "source_report_validation_safety_case_row_count")
    refute Map.has_key?(source_summary, "source_report_validation_safety_case_paths")
  end

  test "validation safety case source summary omits missing identity counts for partial family placeholder" do
    partial_summaries = [
      %{"contract" => "validation_safety_case_summary.v1"},
      %{"count" => 2},
      %{"row_count" => 3},
      %{"paths" => ["provenance.source_reports.validation_safety_case_summary"]},
      %{"count" => nil, "row_count" => nil},
      %{
        "count" => nil,
        "row_count" => nil,
        "paths" => ["provenance.source_reports.validation_safety_case_summary"]
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "validation_safety_case_summary" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      if Map.has_key?(partial_summary, "contract") do
        assert source_summary["source_report_validation_safety_case_contract"] ==
                 "validation_safety_case_summary.v1"
      else
        refute Map.has_key?(source_summary, "source_report_validation_safety_case_contract")
      end

      refute Map.has_key?(source_summary, "source_report_validation_safety_case_count")
      refute Map.has_key?(source_summary, "source_report_validation_safety_case_row_count")
      refute Map.has_key?(source_summary, "source_report_validation_safety_case_paths")
    end
  end

  test "validation safety case source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "validation_safety_case_summary" => %{
            "contract" => "validation_safety_case_summary.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.validation_safety_case_summary"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_validation_safety_case_contract"] ==
             "validation_safety_case_summary.v1"

    assert source_summary["source_report_validation_safety_case_count"] == 0
    assert source_summary["source_report_validation_safety_case_row_count"] == 0

    assert source_summary["source_report_validation_safety_case_paths"] == [
             "provenance.source_reports.validation_safety_case_summary"
           ]
  end

  test "validation safety case source summary omits missing identity paths after preserving counts" do
    summaries = [
      {"missing paths",
       %{
         "contract" => "validation_safety_case_summary.v1",
         "count" => 1,
         "row_count" => 2
       }},
      {"nil paths",
       %{
         "contract" => "validation_safety_case_summary.v1",
         "count" => 1,
         "row_count" => 2,
         "paths" => nil
       }}
    ]

    for {label, validation_safety_case_summary} <- summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "validation_safety_case_summary" => validation_safety_case_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      assert source_summary["source_report_validation_safety_case_contract"] ==
               "validation_safety_case_summary.v1",
             label

      assert source_summary["source_report_validation_safety_case_count"] == 1, label
      assert source_summary["source_report_validation_safety_case_row_count"] == 2, label
      refute Map.has_key?(source_summary, "source_report_validation_safety_case_paths"), label
    end
  end

  test "validation safety case source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "validation_safety_case_summary" => %{
            "contract" => "validation_safety_case_summary.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_validation_safety_case_contract"] ==
             "validation_safety_case_summary.v1"

    assert source_summary["source_report_validation_safety_case_count"] == 1
    assert source_summary["source_report_validation_safety_case_row_count"] == 2
    assert source_summary["source_report_validation_safety_case_paths"] == []
  end

  test "validation safety case replay preserves pressure maps with partial identity" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "validation_safety_case_summary" => %{
            "contract" => "validation_safety_case_summary.v1",
            "count" => 1,
            "status_counts" => %{"review_required" => 1},
            "evidence_status_counts" => %{"blocked" => 1},
            "input_contract_counts" => %{"schema_validation_report.v1" => 1},
            "evidence_refs_by_status" => %{
              "blocked" => ["schema_validation_report.v1:error"]
            },
            "evidence_refs_by_contract" => %{
              "validation_reference_fixture.v1" => ["fixture:challenge_case"]
            }
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_validation_safety_case_count")
    refute Map.has_key?(source_summary, "source_report_validation_safety_case_row_count")
    refute Map.has_key?(source_summary, "source_report_validation_safety_case_paths")

    assert source_summary["source_report_validation_safety_case_status_counts"] == %{
             "review_required" => 1
           }

    assert source_summary["source_report_validation_safety_case_evidence_status_counts"] == %{
             "blocked" => 1
           }

    assert source_summary["source_report_validation_safety_case_input_contract_counts"] == %{
             "schema_validation_report.v1" => 1
           }

    assert source_summary["source_report_validation_safety_case_evidence_refs_by_status"] == %{
             "blocked" => ["schema_validation_report.v1:error"]
           }

    assert source_summary[
             "source_report_validation_safety_case_evidence_refs_by_contract"
           ] == %{
             "validation_reference_fixture.v1" => ["fixture:challenge_case"]
           }

    summary = CandidateRefresh.validation_safety_case_replay_summary(artifact)

    assert summary["source_report_row_count"] == 1
    assert summary["blocked_evidence_count"] == 1
    assert summary["branch_local_review_pressure"]
    assert summary["branch_local_blocking_pressure"]
    assert summary["branch_local_schema_pressure"]
    assert summary["branch_local_fixture_pressure"]
  end

  test "validation safety case replay treats status and contract maps as pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "validation_safety_case_summary" => %{
            "contract" => "validation_safety_case_summary.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => ["provenance.source_reports.validation_safety_case_summary"],
            "review_required_evidence_count" => 0,
            "blocked_evidence_count" => 0,
            "model_review_required_count" => 0,
            "model_blocked_count" => 0,
            "readiness_review_required_count" => 0,
            "readiness_blocked_count" => 0,
            "quality_gate_review_count" => 0,
            "quality_gate_blocked_count" => 0,
            "schema_error_count" => 0,
            "schema_warning_count" => 0,
            "schema_validation_failed_report_count" => 0,
            "fixture_failed_count" => 0,
            "status_counts" => %{"review_required" => 1},
            "evidence_status_counts" => %{
              "blocked" => 1,
              "review_required" => 1
            },
            "input_contract_counts" => %{
              "schema_validation_report.v1" => 1,
              "validation_reference_fixture.v1" => 1
            },
            "evidence_refs_by_status" => %{
              "blocked" => ["schema_validation_report.v1:error"],
              "review_required" => ["quality_gate_report.v1:review"]
            },
            "evidence_refs_by_contract" => %{
              "schema_validation_report.v1" => ["schema_validation_report.v1:error"],
              "validation_reference_fixture.v1" => ["fixture:challenge_case"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.validation_safety_case_replay_summary(artifact)

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 2

    assert summary["source_report_paths"] == [
             "provenance.source_reports.validation_safety_case_summary"
           ]

    assert summary["review_required_evidence_count"] == 1
    assert summary["blocked_evidence_count"] == 1
    assert summary["schema_warning_count"] == 0
    assert summary["schema_validation_failed_report_count"] == 0
    assert summary["fixture_failed_count"] == 0
    assert summary["status_counts"] == %{"review_required" => 1}
    assert summary["evidence_status_counts"] == %{"blocked" => 1, "review_required" => 1}

    assert summary["input_contract_counts"] == %{
             "schema_validation_report.v1" => 1,
             "validation_reference_fixture.v1" => 1
           }

    assert summary["evidence_refs_by_status"] == %{
             "blocked" => ["schema_validation_report.v1:error"],
             "review_required" => ["quality_gate_report.v1:review"]
           }

    assert summary["evidence_refs_by_contract"] == %{
             "schema_validation_report.v1" => ["schema_validation_report.v1:error"],
             "validation_reference_fixture.v1" => ["fixture:challenge_case"]
           }

    assert summary["branch_local_review_pressure"]
    assert summary["branch_local_blocking_pressure"]
    assert summary["branch_local_schema_pressure"]
    assert summary["branch_local_fixture_pressure"]
  end

  test "validation safety case compact source summary derives counts from evidence maps" do
    compact_safety_case_summary = %{
      "schema_contract" => "validation_safety_case_summary.v1",
      "status" => "accepted_for_use",
      "evidence_count" => 99,
      "accepted_evidence_count" => 99,
      "review_required_evidence_count" => 0,
      "blocked_evidence_count" => 0,
      "evidence_status_counts" => %{
        "blocked" => 1,
        "review_required" => 1
      },
      "input_contract_counts" => %{
        "schema_validation_report.v1" => 1,
        "validation_reference_fixture.v1" => 1
      },
      "evidence_refs_by_status" => %{
        "blocked" => ["schema_validation_report.v1:error"],
        "review_required" => ["validation_reference_fixture.v1:fixture.review"]
      },
      "evidence_refs_by_contract" => %{
        "schema_validation_report.v1" => ["schema_validation_report.v1:error"],
        "validation_reference_fixture.v1" => ["validation_reference_fixture.v1:fixture.review"]
      },
      "provenance" => %{"trust_boundary" => "compact_safety_case"}
    }

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "source_validation_safety_case_summary" => compact_safety_case_summary
    }

    assert %{
             "source_report_validation_safety_case_evidence_count" => 2,
             "source_report_validation_safety_case_accepted_evidence_count" => 0,
             "source_report_validation_safety_case_review_required_evidence_count" => 1,
             "source_report_validation_safety_case_blocked_evidence_count" => 1,
             "source_report_validation_safety_case_input_contract_counts" => %{
               "schema_validation_report.v1" => 1,
               "validation_reference_fixture.v1" => 1
             },
             "source_report_validation_safety_case_branch_local_review_pressure" => true,
             "source_report_validation_safety_case_branch_local_blocking_pressure" => true,
             "source_report_validation_safety_case_branch_local_schema_pressure" => true,
             "source_report_validation_safety_case_branch_local_fixture_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert %{
             "source_report_row_count" => 2,
             "accepted_evidence_count" => 0,
             "review_required_evidence_count" => 1,
             "blocked_evidence_count" => 1,
             "branch_local_review_pressure" => true,
             "branch_local_blocking_pressure" => true,
             "branch_local_schema_pressure" => true,
             "branch_local_fixture_pressure" => true
           } = CandidateRefresh.validation_safety_case_replay_summary(artifact)
  end

  test "validation safety case replay treats explicit empty evidence maps as zero counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "validation_safety_case_summary" => %{
            "contract" => "validation_safety_case_summary.v1",
            "count" => 1,
            "row_count" => 99,
            "accepted_evidence_count" => 99,
            "review_required_evidence_count" => 99,
            "blocked_evidence_count" => 99,
            "evidence_status_counts" => %{},
            "input_contract_counts" => %{},
            "evidence_refs_by_status" => %{},
            "evidence_refs_by_contract" => %{}
          }
        }
      }
    }

    summary = CandidateRefresh.validation_safety_case_replay_summary(artifact)

    assert summary["source_report_row_count"] == 0
    assert summary["accepted_evidence_count"] == 0
    assert summary["review_required_evidence_count"] == 0
    assert summary["blocked_evidence_count"] == 0
    refute summary["branch_local_review_pressure"]
    refute summary["branch_local_blocking_pressure"]
    refute summary["branch_local_schema_pressure"]
    refute summary["branch_local_fixture_pressure"]
  end
end
