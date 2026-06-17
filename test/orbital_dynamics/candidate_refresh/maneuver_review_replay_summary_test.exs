defmodule OrbitalDynamics.CandidateRefresh.ManeuverReviewReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary aggregates maneuver review feedback routing keys" do
    refresh = %{
      "source_maneuver_review_report" => %{
        "schema_contract" => "maneuver_review_report.v1",
        "rows" => [
          %{
            "maneuver_id" => "burn_success_uncertainty",
            "maneuver_success_factor" => 0.4,
            "execution_uncertainty" => %{"timing_3sigma_s" => 75.0},
            "required_operator_action" => "review_maneuver_execution",
            "provenance" => %{"trust_boundary" => "ops_maneuver_review"}
          },
          %{
            "maneuver_id" => "burn_missing_uncertainty",
            "maneuver_success" => false,
            "execution_uncertainty_status" => "missing",
            "required_operator_action" => "review_maneuver_uncertainty",
            "provenance" => %{"trust_boundary" => "ops_maneuver_review"}
          },
          %{
            "maneuver_id" => "burn_no_feedback"
          }
        ],
        "maneuver_id_counts" => %{"stale_burn" => 99},
        "required_operator_action_counts" => %{"stale_action" => 99}
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_maneuver_review_contract" => "maneuver_review_report.v1",
             "source_report_maneuver_review_count" => 1,
             "source_report_maneuver_review_row_count" => 3,
             "source_report_maneuver_review_paths" => ["source_maneuver_review_report"],
             "source_report_maneuver_review_maneuver_success_feedback_count" => 2,
             "source_report_maneuver_review_execution_uncertainty_declared_count" => 1,
             "source_report_maneuver_review_execution_uncertainty_missing_count" => 1,
             "source_report_maneuver_review_input_keys" => [
               "maneuver_execution_uncertainty",
               "maneuver_success_rate"
             ],
             "source_report_maneuver_review_maneuver_id_counts" => %{
               "burn_missing_uncertainty" => 1,
               "burn_no_feedback" => 1,
               "burn_success_uncertainty" => 1
             },
             "source_report_maneuver_review_required_operator_action_counts" => %{
               "review_maneuver_execution" => 1,
               "review_maneuver_uncertainty" => 1
             },
             "source_report_maneuver_review_branch_local_maneuver_review_pressure" => true,
             "source_report_maneuver_review_branch_local_maneuver_feedback_pressure" => true,
             "source_report_maneuver_review_branch_local_maneuver_routing_pressure" => true,
             "source_report_maneuver_review_branch_local_maneuver_action_pressure" => true,
             "source_report_maneuver_review_branch_local_execution_uncertainty_pressure" => true,
             "source_reports" => %{
               "maneuver_review_report" => %{
                 "contract" => "maneuver_review_report.v1",
                 "count" => 1,
                 "row_count" => 3,
                 "paths" => ["source_maneuver_review_report"],
                 "maneuver_success_feedback_count" => 2,
                 "execution_uncertainty_declared_count" => 1,
                 "execution_uncertainty_missing_count" => 1,
                 "input_keys" => [
                   "maneuver_execution_uncertainty",
                   "maneuver_success_rate"
                 ],
                 "maneuver_id_counts" => %{
                   "burn_missing_uncertainty" => 1,
                   "burn_no_feedback" => 1,
                   "burn_success_uncertainty" => 1
                 },
                 "required_operator_action_counts" => %{
                   "review_maneuver_execution" => 1,
                   "review_maneuver_uncertainty" => 1
                 }
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = %{
      "model" => "artifact_only_candidate_refresh_maneuver_review_replay_summary",
      "source" => "candidate_refresh.source_report_provenance.maneuver_review_report",
      "contract" => "maneuver_review_report.v1",
      "source_report_count" => 1,
      "source_report_row_count" => 3,
      "source_report_paths" => ["source_maneuver_review_report"],
      "maneuver_success_feedback_count" => 2,
      "execution_uncertainty_declared_count" => 1,
      "execution_uncertainty_missing_count" => 1,
      "input_keys" => [
        "maneuver_execution_uncertainty",
        "maneuver_success_rate"
      ],
      "maneuver_id_counts" => %{
        "burn_missing_uncertainty" => 1,
        "burn_no_feedback" => 1,
        "burn_success_uncertainty" => 1
      },
      "required_operator_action_counts" => %{
        "review_maneuver_execution" => 1,
        "review_maneuver_uncertainty" => 1
      },
      "trust_boundary_status" => "declared",
      "trust_boundaries" => ["ops_maneuver_review"],
      "branch_local_maneuver_review_pressure" => true,
      "branch_local_maneuver_feedback_pressure" => true,
      "branch_local_maneuver_routing_pressure" => true,
      "branch_local_maneuver_action_pressure" => true,
      "branch_local_execution_uncertainty_pressure" => true,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => "maneuver_review_source_report_provenance_only",
        "operator_authority" => "not_granted_by_maneuver_review_replay_summary",
        "maneuver_execution" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_maneuver_review_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }

    assert CandidateRefresh.maneuver_review_replay_summary(refresh) == replay_summary

    assert OrbitalDynamics.candidate_refresh_maneuver_review_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => summary["source_reports"]}
    }

    assert %{
             "source_report_maneuver_review_contract" => "maneuver_review_report.v1",
             "source_report_maneuver_review_count" => 1,
             "source_report_maneuver_review_row_count" => 3,
             "source_report_maneuver_review_paths" => ["source_maneuver_review_report"],
             "source_report_maneuver_review_maneuver_success_feedback_count" => 2,
             "source_report_maneuver_review_execution_uncertainty_missing_count" => 1,
             "source_report_maneuver_review_input_keys" => [
               "maneuver_execution_uncertainty",
               "maneuver_success_rate"
             ],
             "source_report_maneuver_review_maneuver_id_counts" => %{
               "burn_missing_uncertainty" => 1,
               "burn_no_feedback" => 1,
               "burn_success_uncertainty" => 1
             },
             "source_report_maneuver_review_required_operator_action_counts" => %{
               "review_maneuver_execution" => 1,
               "review_maneuver_uncertainty" => 1
             },
             "source_report_maneuver_review_branch_local_maneuver_review_pressure" => true,
             "source_report_maneuver_review_branch_local_maneuver_feedback_pressure" => true,
             "source_report_maneuver_review_branch_local_maneuver_routing_pressure" => true,
             "source_report_maneuver_review_branch_local_maneuver_action_pressure" => true,
             "source_report_maneuver_review_branch_local_execution_uncertainty_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.maneuver_review_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_maneuver_review_replay_summary(artifact) ==
             replay_summary
  end

  test "maneuver review replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.maneuver_review_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_maneuver_review_contract")
    refute Map.has_key?(source_summary, "source_report_maneuver_review_count")
    refute Map.has_key?(source_summary, "source_report_maneuver_review_row_count")
    refute Map.has_key?(source_summary, "source_report_maneuver_review_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_maneuver_review_pressure"]
  end

  test "maneuver review source summary omits missing identity counts for partial family placeholder" do
    partial_summaries = [
      %{"contract" => "maneuver_review_report.v1"},
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.maneuver_review_report"]},
      %{"count" => nil, "row_count" => nil},
      %{
        "count" => nil,
        "row_count" => nil,
        "paths" => ["provenance.source_reports.maneuver_review_report"]
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "maneuver_review_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      if Map.has_key?(partial_summary, "contract") do
        assert source_summary["source_report_maneuver_review_contract"] ==
                 "maneuver_review_report.v1"
      else
        refute Map.has_key?(source_summary, "source_report_maneuver_review_contract")
      end

      refute Map.has_key?(source_summary, "source_report_maneuver_review_count")
      refute Map.has_key?(source_summary, "source_report_maneuver_review_row_count")
      refute Map.has_key?(source_summary, "source_report_maneuver_review_paths")
    end
  end

  test "maneuver review source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "maneuver_review_report" => %{
            "contract" => "maneuver_review_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.maneuver_review_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_maneuver_review_contract"] ==
             "maneuver_review_report.v1"

    assert source_summary["source_report_maneuver_review_count"] == 0
    assert source_summary["source_report_maneuver_review_row_count"] == 0

    assert source_summary["source_report_maneuver_review_paths"] == [
             "provenance.source_reports.maneuver_review_report"
           ]
  end

  test "maneuver review source summary omits missing identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "maneuver_review_report" => %{
            "contract" => "maneuver_review_report.v1",
            "count" => 1,
            "row_count" => 2
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_maneuver_review_contract"] ==
             "maneuver_review_report.v1"

    assert source_summary["source_report_maneuver_review_count"] == 1
    assert source_summary["source_report_maneuver_review_row_count"] == 2
    refute Map.has_key?(source_summary, "source_report_maneuver_review_paths")
  end

  test "maneuver review source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "maneuver_review_report" => %{
            "contract" => "maneuver_review_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_maneuver_review_contract"] ==
             "maneuver_review_report.v1"

    assert source_summary["source_report_maneuver_review_count"] == 1
    assert source_summary["source_report_maneuver_review_row_count"] == 2
    assert source_summary["source_report_maneuver_review_paths"] == []
  end

  test "maneuver review replay treats preserved feedback and uncertainty keys as pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "maneuver_review_report" => %{
            "contract" => "maneuver_review_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["source_maneuver_review_report"],
            "maneuver_success_feedback_count" => 0,
            "execution_uncertainty_declared_count" => 0,
            "execution_uncertainty_missing_count" => 0,
            "input_keys" => [
              "maneuver_execution_uncertainty",
              "maneuver_success_rate"
            ],
            "maneuver_id_counts" => %{"burn_map_only" => 1},
            "required_operator_action_counts" => %{"review_maneuver_uncertainty" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.maneuver_review_replay_summary(artifact)

    assert summary["maneuver_success_feedback_count"] == 0
    assert summary["execution_uncertainty_declared_count"] == 0
    assert summary["execution_uncertainty_missing_count"] == 0

    assert summary["input_keys"] == [
             "maneuver_execution_uncertainty",
             "maneuver_success_rate"
           ]

    assert summary["maneuver_id_counts"] == %{"burn_map_only" => 1}
    assert summary["required_operator_action_counts"] == %{"review_maneuver_uncertainty" => 1}
    assert summary["branch_local_maneuver_review_pressure"]
    assert summary["branch_local_maneuver_feedback_pressure"]
    assert summary["branch_local_maneuver_routing_pressure"]
    assert summary["branch_local_maneuver_action_pressure"]
    assert summary["branch_local_execution_uncertainty_pressure"]
  end

  test "maneuver review replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "maneuver_review_report" => %{
              "contract" => "maneuver_review_report.v1",
              "count" => 1,
              "row_count" => 2,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_maneuver_review_report"
              ],
              "maneuver_success_feedback_count" => 1,
              "execution_uncertainty_declared_count" => 1,
              "execution_uncertainty_missing_count" => 0,
              "input_keys" => [
                "maneuver_execution_uncertainty",
                "maneuver_success_rate"
              ],
              "maneuver_id_counts" => %{"burn_branch_review" => 1},
              "required_operator_action_counts" => %{"review_maneuver_execution" => 1},
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_maneuver_review"]
            }
          }
        }
      },
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.maneuver_review_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.maneuver_review_report"

    assert summary["contract"] == "maneuver_review_report.v1"
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 2

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_maneuver_review_report"
           ]

    assert summary["maneuver_success_feedback_count"] == 1
    assert summary["execution_uncertainty_declared_count"] == 1
    assert summary["execution_uncertainty_missing_count"] == 0

    assert summary["input_keys"] == [
             "maneuver_execution_uncertainty",
             "maneuver_success_rate"
           ]

    assert summary["maneuver_id_counts"] == %{"burn_branch_review" => 1}
    assert summary["required_operator_action_counts"] == %{"review_maneuver_execution" => 1}
    assert summary["trust_boundaries"] == ["branch_maneuver_review"]
    assert summary["branch_local_maneuver_review_pressure"]
    assert summary["branch_local_maneuver_feedback_pressure"]
    assert summary["branch_local_maneuver_routing_pressure"]
    assert summary["branch_local_maneuver_action_pressure"]
    assert summary["branch_local_execution_uncertainty_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "maneuver_review_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_maneuver_review_replay_summary(artifact) ==
             summary
  end

  test "maneuver review replay falls back to provenance when branch summary lacks usable family" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "command_window_report" => %{
              "contract" => "command_window_report.v1",
              "count" => 1,
              "row_count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_command_window_report"
              ]
            },
            "maneuver_review_report" => %{}
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "maneuver_review_report" => %{
            "contract" => "maneuver_review_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["source_maneuver_review_report"],
            "maneuver_success_feedback_count" => 0,
            "execution_uncertainty_declared_count" => 0,
            "execution_uncertainty_missing_count" => 0,
            "input_keys" => ["maneuver_success_rate"],
            "maneuver_id_counts" => %{"burn_provenance" => 1},
            "required_operator_action_counts" => %{"review_maneuver_execution" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.maneuver_review_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.maneuver_review_report"

    assert summary["source_report_paths"] == ["source_maneuver_review_report"]
    assert summary["input_keys"] == ["maneuver_success_rate"]
    assert summary["maneuver_id_counts"] == %{"burn_provenance" => 1}
    assert summary["required_operator_action_counts"] == %{"review_maneuver_execution" => 1}
    assert summary["branch_local_maneuver_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "maneuver_review_source_report_provenance_only"
  end

  test "maneuver review replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "maneuver_review_report" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_maneuver_review_report"
              ],
              "maneuver_id_counts" => %{"burn_branch_review" => 1}
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "maneuver_review_report" => %{
            "contract" => "maneuver_review_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_maneuver_review_report"],
            "maneuver_success_feedback_count" => 9,
            "execution_uncertainty_declared_count" => 9,
            "execution_uncertainty_missing_count" => 9,
            "input_keys" => ["maneuver_success_rate"],
            "maneuver_id_counts" => %{"burn_provenance" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.maneuver_review_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.maneuver_review_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_maneuver_review_report"
           ]

    assert summary["maneuver_success_feedback_count"] == 0
    assert summary["execution_uncertainty_declared_count"] == 0
    assert summary["execution_uncertainty_missing_count"] == 0
    assert summary["input_keys"] == []
    assert summary["maneuver_id_counts"] == %{"burn_branch_review" => 1}
    assert summary["branch_local_maneuver_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "maneuver_review_candidate_source_report_summary_only"
  end
end
