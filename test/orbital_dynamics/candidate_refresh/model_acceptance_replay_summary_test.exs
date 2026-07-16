defmodule OrbitalDynamics.CandidateRefresh.ModelAcceptanceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary aggregates model acceptance routing maps" do
    refresh = %{
      "source_model_acceptance_report" => %{
        "schema_contract" => "model_acceptance_report.v1",
        "intended_use" => "operational_import",
        "status" => "blocked",
        "rows" => [
          %{
            "model_id" => "orbit_data.simple_json",
            "validation_level" => "artifact_contract",
            "status" => "accepted"
          },
          %{
            "model_id" => "event.access_windows",
            "validation_level" => "analysis",
            "status" => "review_required"
          },
          %{
            "model_id" => "propagator.two_body",
            "validation_level" => "educational",
            "status" => "blocked"
          },
          %{
            "model_id" => "missing.model",
            "validation_level" => "unknown",
            "status" => "blocked"
          }
        ],
        "records" => [
          %{"record_id" => "acceptance:orbit_data.simple_json"},
          %{"record_id" => "acceptance:event.access_windows"},
          %{"record_id" => "acceptance:propagator.two_body"}
        ],
        "model_count" => 4,
        "accepted_count" => 1,
        "review_required_count" => 1,
        "blocked_count" => 2,
        "unknown_model_count" => 1,
        "validation_level_counts" => %{
          "stale_validation_level" => 99
        },
        "model_ids_by_status" => %{
          "accepted" => ["stale.accepted.model"],
          "blocked" => ["stale.blocked.model"],
          "review_required" => ["stale.review.model"]
        },
        "model_ids_by_validation_level" => %{
          "stale_validation_level" => ["stale.validation.model"]
        },
        "model_ids_by_intended_use" => %{
          "operational_import" => ["stale.intended-use.model"]
        },
        "provenance" => %{"trust_boundary" => "ops_model_acceptance"}
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_model_acceptance_contract" => "model_acceptance_report.v1",
             "source_report_model_acceptance_count" => 1,
             "source_report_model_acceptance_row_count" => 4,
             "source_report_model_acceptance_paths" => ["source_model_acceptance_report"],
             "source_report_model_acceptance_record_count" => 3,
             "source_report_model_acceptance_intended_use_counts" => %{
               "operational_import" => 1
             },
             "source_report_model_acceptance_status_counts" => %{"blocked" => 1},
             "source_report_model_acceptance_model_count" => 4,
             "source_report_model_acceptance_accepted_count" => 1,
             "source_report_model_acceptance_review_required_count" => 1,
             "source_report_model_acceptance_blocked_count" => 2,
             "source_report_model_acceptance_unknown_model_count" => 1,
             "source_report_model_acceptance_validation_level_counts" => %{
               "analysis" => 1,
               "artifact_contract" => 1,
               "educational" => 1,
               "unknown" => 1
             },
             "source_report_model_acceptance_model_ids_by_status" => %{
               "accepted" => ["orbit_data.simple_json"],
               "blocked" => ["propagator.two_body", "missing.model"],
               "review_required" => ["event.access_windows"]
             },
             "source_report_model_acceptance_model_ids_by_validation_level" => %{
               "analysis" => ["event.access_windows"],
               "artifact_contract" => ["orbit_data.simple_json"],
               "educational" => ["propagator.two_body"],
               "unknown" => ["missing.model"]
             },
             "source_report_model_acceptance_model_ids_by_intended_use" => %{
               "operational_import" => [
                 "orbit_data.simple_json",
                 "event.access_windows",
                 "propagator.two_body",
                 "missing.model"
               ]
             },
             "source_report_model_acceptance_branch_local_review_pressure" => true,
             "source_report_model_acceptance_branch_local_blocking_pressure" => true,
             "source_report_model_acceptance_branch_local_unknown_model_pressure" => true,
             "source_reports" => %{
               "model_acceptance_report" => %{
                 "record_count" => 3,
                 "model_count" => 4,
                 "model_ids_by_status" => %{
                   "blocked" => ["propagator.two_body", "missing.model"]
                 }
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "model" => "artifact_only_candidate_refresh_model_acceptance_replay_summary",
             "source" => "candidate_refresh.source_report_provenance.model_acceptance_report",
             "contract" => "model_acceptance_report.v1",
             "source_report_count" => 1,
             "source_report_row_count" => 4,
             "source_report_record_count" => 3,
             "source_report_paths" => ["source_model_acceptance_report"],
             "intended_use_counts" => %{"operational_import" => 1},
             "status_counts" => %{"blocked" => 1},
             "model_count" => 4,
             "accepted_count" => 1,
             "review_required_count" => 1,
             "blocked_count" => 2,
             "unknown_model_count" => 1,
             "validation_level_counts" => %{
               "analysis" => 1,
               "artifact_contract" => 1,
               "educational" => 1,
               "unknown" => 1
             },
             "model_ids_by_status" => %{
               "accepted" => ["orbit_data.simple_json"],
               "blocked" => ["propagator.two_body", "missing.model"],
               "review_required" => ["event.access_windows"]
             },
             "model_ids_by_validation_level" => %{
               "analysis" => ["event.access_windows"],
               "artifact_contract" => ["orbit_data.simple_json"],
               "educational" => ["propagator.two_body"],
               "unknown" => ["missing.model"]
             },
             "model_ids_by_intended_use" => %{
               "operational_import" => [
                 "orbit_data.simple_json",
                 "event.access_windows",
                 "propagator.two_body",
                 "missing.model"
               ]
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["ops_model_acceptance"],
             "branch_local_review_pressure" => true,
             "branch_local_blocking_pressure" => true,
             "branch_local_unknown_model_pressure" => true,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
               "replay_scope" => "model_acceptance_source_report_provenance_only",
               "operator_authority" => "not_granted_by_model_acceptance_replay_summary",
               "model_certification" => "not_performed_by_summary",
               "import_approval" => "not_granted_by_model_acceptance_replay_summary",
               "cadence_write" => "not_performed_by_summary",
               "candidate_generation" => "not_performed_by_summary"
             }
           } = replay_summary = CandidateRefresh.model_acceptance_replay_summary(refresh)

    assert OrbitalDynamics.candidate_refresh_model_acceptance_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" =>
          Map.put(summary["source_reports"], "quality_gate_report", %{
            "contract" => "quality_gate_report.v1",
            "count" => 1,
            "row_count" => 1,
            "status_counts" => %{"blocked" => 99},
            "trust_boundary_status" => "declared"
          })
      }
    }

    assert %{
             "source_report_family_count" => 2,
             "source_report_model_acceptance_contract" => "model_acceptance_report.v1",
             "source_report_model_acceptance_count" => 1,
             "source_report_model_acceptance_row_count" => 4,
             "source_report_model_acceptance_paths" => ["source_model_acceptance_report"],
             "source_report_model_acceptance_status_counts" => %{"blocked" => 1},
             "source_report_model_acceptance_model_count" => 4,
             "source_report_model_acceptance_model_ids_by_status" => %{
               "blocked" => ["propagator.two_body", "missing.model"]
             },
             "source_report_model_acceptance_branch_local_review_pressure" => true,
             "source_report_model_acceptance_branch_local_blocking_pressure" => true,
             "source_report_model_acceptance_branch_local_unknown_model_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.model_acceptance_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_model_acceptance_replay_summary(artifact) ==
             replay_summary
  end

  test "model acceptance compact source summary derives counts from routing maps" do
    compact_model_acceptance_report = %{
      "schema_contract" => "model_acceptance_report.v1",
      "intended_use" => "operational_import",
      "status" => "accepted",
      "row_count" => 99,
      "model_count" => 99,
      "accepted_count" => 99,
      "review_required_count" => 0,
      "blocked_count" => 0,
      "unknown_model_count" => 0,
      "validation_level_counts" => %{"stale_validation_level" => 99},
      "model_ids_by_status" => %{
        "blocked" => ["missing.model"],
        "review_required" => ["event.access_windows"]
      },
      "model_ids_by_validation_level" => %{
        "analysis" => ["event.access_windows"],
        "unknown" => ["missing.model"]
      },
      "model_ids_by_intended_use" => %{
        "operational_import" => ["event.access_windows", "missing.model"]
      },
      "provenance" => %{"trust_boundary" => "compact_model_acceptance"}
    }

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "source_model_acceptance_report" => compact_model_acceptance_report
    }

    assert %{
             "source_report_model_acceptance_count" => 1,
             "source_report_model_acceptance_row_count" => 2,
             "source_report_model_acceptance_model_count" => 2,
             "source_report_model_acceptance_accepted_count" => 0,
             "source_report_model_acceptance_review_required_count" => 1,
             "source_report_model_acceptance_blocked_count" => 1,
             "source_report_model_acceptance_unknown_model_count" => 1,
             "source_report_model_acceptance_validation_level_counts" => %{
               "analysis" => 1,
               "unknown" => 1
             },
             "source_report_model_acceptance_model_ids_by_status" => %{
               "blocked" => ["missing.model"],
               "review_required" => ["event.access_windows"]
             },
             "source_report_model_acceptance_branch_local_review_pressure" => true,
             "source_report_model_acceptance_branch_local_blocking_pressure" => true,
             "source_report_model_acceptance_branch_local_unknown_model_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert %{
             "source_report_row_count" => 2,
             "model_count" => 2,
             "accepted_count" => 0,
             "review_required_count" => 1,
             "blocked_count" => 1,
             "unknown_model_count" => 1,
             "validation_level_counts" => %{"analysis" => 1, "unknown" => 1},
             "branch_local_review_pressure" => true,
             "branch_local_blocking_pressure" => true,
             "branch_local_unknown_model_pressure" => true
           } = CandidateRefresh.model_acceptance_replay_summary(artifact)
  end

  test "model acceptance replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.model_acceptance_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_model_acceptance_contract")
    refute Map.has_key?(source_summary, "source_report_model_acceptance_count")
    refute Map.has_key?(source_summary, "source_report_model_acceptance_row_count")
    refute Map.has_key?(source_summary, "source_report_model_acceptance_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_record_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_review_pressure"]
    refute summary["branch_local_blocking_pressure"]
    refute summary["branch_local_unknown_model_pressure"]
  end

  test "model acceptance source summary keeps declared contract without partial identity placeholders" do
    placeholder_fields = [
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.model_acceptance_report"]},
      %{"count" => nil, "row_count" => 2},
      %{"count" => 1, "row_count" => nil}
    ]

    for placeholder <- placeholder_fields do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "model_acceptance_report" =>
              Map.put(
                placeholder,
                "contract",
                "model_acceptance_report.v1"
              )
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      assert source_summary["source_report_model_acceptance_contract"] ==
               "model_acceptance_report.v1"

      refute Map.has_key?(source_summary, "source_report_model_acceptance_count")
      refute Map.has_key?(source_summary, "source_report_model_acceptance_row_count")
      refute Map.has_key?(source_summary, "source_report_model_acceptance_paths")
    end
  end

  test "model acceptance source summary preserves non-identity rollups with partial identity" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "model_acceptance_report" => %{
            "contract" => "model_acceptance_report.v1",
            "count" => 1,
            "status_counts" => %{"blocked" => 1},
            "model_ids_by_status" => %{"blocked" => ["missing.model"]}
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_model_acceptance_contract"] ==
             "model_acceptance_report.v1"

    refute Map.has_key?(source_summary, "source_report_model_acceptance_count")
    refute Map.has_key?(source_summary, "source_report_model_acceptance_row_count")
    refute Map.has_key?(source_summary, "source_report_model_acceptance_paths")

    assert source_summary["source_report_model_acceptance_status_counts"] ==
             %{"blocked" => 1}

    assert source_summary["source_report_model_acceptance_model_ids_by_status"] ==
             %{"blocked" => ["missing.model"]}
  end

  test "model acceptance source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "model_acceptance_report" => %{
            "contract" => "model_acceptance_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.model_acceptance_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_model_acceptance_contract"] ==
             "model_acceptance_report.v1"

    assert source_summary["source_report_model_acceptance_count"] == 0
    assert source_summary["source_report_model_acceptance_row_count"] == 0

    assert source_summary["source_report_model_acceptance_paths"] == [
             "provenance.source_reports.model_acceptance_report"
           ]
  end

  test "model acceptance source summary omits missing identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "model_acceptance_report" => %{
            "contract" => "model_acceptance_report.v1",
            "count" => 1,
            "row_count" => 2
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_model_acceptance_contract"] ==
             "model_acceptance_report.v1"

    assert source_summary["source_report_model_acceptance_count"] == 1
    assert source_summary["source_report_model_acceptance_row_count"] == 2
    refute Map.has_key?(source_summary, "source_report_model_acceptance_paths")
  end

  test "model acceptance source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "model_acceptance_report" => %{
            "contract" => "model_acceptance_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_model_acceptance_contract"] ==
             "model_acceptance_report.v1"

    assert source_summary["source_report_model_acceptance_count"] == 1
    assert source_summary["source_report_model_acceptance_row_count"] == 2
    assert source_summary["source_report_model_acceptance_paths"] == []
  end

  test "model acceptance replay treats status and model routing maps as review pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "model_acceptance_report" => %{
            "contract" => "model_acceptance_report.v1",
            "count" => 1,
            "row_count" => 2,
            "record_count" => 2,
            "paths" => ["provenance.source_reports.model_acceptance_report"],
            "review_required_count" => 0,
            "blocked_count" => 0,
            "unknown_model_count" => 0,
            "status_counts" => %{
              "blocked" => 1,
              "review_required" => 1
            },
            "validation_level_counts" => %{"unknown" => 1},
            "model_ids_by_status" => %{
              "blocked" => ["missing.model"],
              "review_required" => ["event.access_windows"]
            },
            "model_ids_by_validation_level" => %{"unknown" => ["missing.model"]},
            "model_ids_by_intended_use" => %{
              "operational_import" => ["event.access_windows", "missing.model"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.model_acceptance_replay_summary(artifact)

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 2
    assert summary["source_report_record_count"] == 2
    assert summary["source_report_paths"] == ["provenance.source_reports.model_acceptance_report"]
    assert summary["model_count"] == 2
    assert summary["review_required_count"] == 1
    assert summary["blocked_count"] == 1
    assert summary["unknown_model_count"] == 1
    assert summary["status_counts"] == %{"blocked" => 1, "review_required" => 1}
    assert summary["validation_level_counts"] == %{"unknown" => 1}

    assert summary["model_ids_by_status"] == %{
             "blocked" => ["missing.model"],
             "review_required" => ["event.access_windows"]
           }

    assert summary["model_ids_by_validation_level"] == %{"unknown" => ["missing.model"]}

    assert summary["model_ids_by_intended_use"] == %{
             "operational_import" => ["event.access_windows", "missing.model"]
           }

    assert summary["branch_local_review_pressure"]
    assert summary["branch_local_blocking_pressure"]
    assert summary["branch_local_unknown_model_pressure"]
  end

  test "model acceptance replay preserves routing pressure with partial identity" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "model_acceptance_report" => %{
            "contract" => "model_acceptance_report.v1",
            "count" => 1,
            "paths" => ["provenance.source_reports.model_acceptance_report"],
            "review_required_count" => 0,
            "blocked_count" => 0,
            "unknown_model_count" => 0,
            "status_counts" => %{"blocked" => 1},
            "model_ids_by_status" => %{"blocked" => ["missing.model"]},
            "model_ids_by_validation_level" => %{"unknown" => ["missing.model"]},
            "model_ids_by_intended_use" => %{
              "operational_import" => ["missing.model"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.model_acceptance_replay_summary(artifact)

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1
    assert summary["source_report_paths"] == ["provenance.source_reports.model_acceptance_report"]
    assert summary["status_counts"] == %{"blocked" => 1}
    assert summary["model_count"] == 1
    assert summary["blocked_count"] == 1
    assert summary["unknown_model_count"] == 1
    assert summary["model_ids_by_status"] == %{"blocked" => ["missing.model"]}
    assert summary["model_ids_by_validation_level"] == %{"unknown" => ["missing.model"]}
    assert summary["model_ids_by_intended_use"] == %{"operational_import" => ["missing.model"]}
    assert summary["branch_local_review_pressure"]
    assert summary["branch_local_blocking_pressure"]
    assert summary["branch_local_unknown_model_pressure"]
  end

  test "model acceptance replay treats explicit empty routing maps as zero counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "model_acceptance_report" => %{
            "contract" => "model_acceptance_report.v1",
            "count" => 1,
            "row_count" => 99,
            "model_count" => 99,
            "accepted_count" => 99,
            "review_required_count" => 99,
            "blocked_count" => 99,
            "unknown_model_count" => 99,
            "validation_level_counts" => %{"unknown" => 99},
            "model_ids_by_status" => %{},
            "model_ids_by_validation_level" => %{},
            "model_ids_by_intended_use" => %{}
          }
        }
      }
    }

    summary = CandidateRefresh.model_acceptance_replay_summary(artifact)

    assert summary["source_report_row_count"] == 0
    assert summary["model_count"] == 0
    assert summary["accepted_count"] == 0
    assert summary["review_required_count"] == 0
    assert summary["blocked_count"] == 0
    assert summary["unknown_model_count"] == 0
    assert summary["validation_level_counts"] == %{}
    refute summary["branch_local_review_pressure"]
    refute summary["branch_local_blocking_pressure"]
    refute summary["branch_local_unknown_model_pressure"]
  end
end
