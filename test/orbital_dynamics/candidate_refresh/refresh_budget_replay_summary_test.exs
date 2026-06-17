defmodule OrbitalDynamics.CandidateRefresh.RefreshBudgetReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary aggregates refresh budget routing maps" do
    refresh = %{
      "source_refresh_budget_report" => [
        %{
          "schema_contract" => "refresh_budget_report.v1",
          "input_candidate_count" => 4,
          "kept_candidate_count" => 2,
          "dropped_candidate_count" => 2,
          "kept_candidate_ids" => ["candidate_a", "candidate_b"],
          "dropped_candidate_ids" => ["candidate_c", "candidate_d"],
          "provenance" => %{"trust_boundary" => "ops_refresh_budget"}
        },
        %{
          "schema_contract" => "refresh_budget_report.v1",
          "input_candidate_count" => 1,
          "kept_candidate_count" => 1,
          "dropped_candidate_count" => 0,
          "invalid_candidate_limit_policy" => true,
          "invalid_candidate_limit_policy_reason" => "max_candidate_activities_must_be_integer",
          "kept_candidate_ids" => ["candidate_e"],
          "dropped_candidate_ids" => [],
          "provenance" => %{"trust_boundary" => "ops_refresh_budget"}
        }
      ]
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_count" => 2,
             "source_report_row_count" => 2,
             "source_report_refresh_budget_contract" => "refresh_budget_report.v1",
             "source_report_refresh_budget_count" => 2,
             "source_report_refresh_budget_row_count" => 2,
             "source_report_refresh_budget_paths" => [
               "source_refresh_budget_report[0]",
               "source_refresh_budget_report[1]"
             ],
             "source_report_refresh_budget_input_candidate_count" => 5,
             "source_report_refresh_budget_kept_candidate_count" => 3,
             "source_report_refresh_budget_dropped_candidate_count" => 2,
             "source_report_refresh_budget_invalid_candidate_limit_policy_count" => 1,
             "source_report_refresh_budget_invalid_candidate_limit_policy_reason_counts" => %{
               "max_candidate_activities_must_be_integer" => 1
             },
             "source_report_refresh_budget_kept_candidate_ids" => [
               "candidate_a",
               "candidate_b",
               "candidate_e"
             ],
             "source_report_refresh_budget_dropped_candidate_ids" => [
               "candidate_c",
               "candidate_d"
             ],
             "source_report_refresh_budget_branch_local_budget_pressure" => true,
             "source_report_refresh_budget_branch_local_dropped_candidate_pressure" => true,
             "source_report_refresh_budget_branch_local_invalid_limit_pressure" => true,
             "source_report_refresh_budget_branch_local_candidate_limit_applied" => true,
             "source_reports" => %{
               "refresh_budget_report" => %{
                 "count" => 2,
                 "row_count" => 2,
                 "input_candidate_count" => 5,
                 "kept_candidate_count" => 3,
                 "dropped_candidate_count" => 2,
                 "invalid_candidate_limit_policy_count" => 1,
                 "invalid_candidate_limit_policy_reason_counts" => %{
                   "max_candidate_activities_must_be_integer" => 1
                 },
                 "kept_candidate_ids" => [
                   "candidate_a",
                   "candidate_b",
                   "candidate_e"
                 ],
                 "dropped_candidate_ids" => [
                   "candidate_c",
                   "candidate_d"
                 ]
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "model" => "artifact_only_candidate_refresh_refresh_budget_replay_summary",
             "source" => "candidate_refresh.source_report_provenance.refresh_budget_report",
             "contract" => "refresh_budget_report.v1",
             "source_report_count" => 2,
             "source_report_row_count" => 2,
             "source_report_paths" => [
               "source_refresh_budget_report[0]",
               "source_refresh_budget_report[1]"
             ],
             "input_candidate_count" => 5,
             "kept_candidate_count" => 3,
             "dropped_candidate_count" => 2,
             "invalid_candidate_limit_policy_count" => 1,
             "invalid_candidate_limit_policy_reason_counts" => %{
               "max_candidate_activities_must_be_integer" => 1
             },
             "kept_candidate_ids" => [
               "candidate_a",
               "candidate_b",
               "candidate_e"
             ],
             "dropped_candidate_ids" => [
               "candidate_c",
               "candidate_d"
             ],
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["ops_refresh_budget"],
             "branch_local_budget_pressure" => true,
             "branch_local_dropped_candidate_pressure" => true,
             "branch_local_invalid_limit_pressure" => true,
             "branch_local_candidate_limit_applied" => true,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
               "replay_scope" => "refresh_budget_source_report_provenance_only",
               "operator_authority" => "not_granted_by_refresh_budget_replay_summary",
               "import_approval" => "not_granted_by_refresh_budget_replay_summary",
               "cadence_write" => "not_performed_by_summary",
               "candidate_generation" => "not_performed_by_summary"
             }
           } = replay_summary = CandidateRefresh.refresh_budget_replay_summary(refresh)

    assert OrbitalDynamics.candidate_refresh_refresh_budget_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" =>
          Map.put(summary["source_reports"], "quality_gate_report", %{
            "contract" => "quality_gate_report.v1",
            "count" => 1,
            "row_count" => 1,
            "dropped_candidate_count" => 99,
            "trust_boundary_status" => "declared"
          })
      }
    }

    assert %{
             "source_report_family_count" => 2,
             "source_report_refresh_budget_contract" => "refresh_budget_report.v1",
             "source_report_refresh_budget_count" => 2,
             "source_report_refresh_budget_row_count" => 2,
             "source_report_refresh_budget_paths" => [
               "source_refresh_budget_report[0]",
               "source_refresh_budget_report[1]"
             ],
             "source_report_refresh_budget_input_candidate_count" => 5,
             "source_report_refresh_budget_dropped_candidate_count" => 2,
             "source_report_refresh_budget_invalid_candidate_limit_policy_reason_counts" => %{
               "max_candidate_activities_must_be_integer" => 1
             },
             "source_report_refresh_budget_dropped_candidate_ids" => [
               "candidate_c",
               "candidate_d"
             ],
             "source_report_refresh_budget_branch_local_budget_pressure" => true,
             "source_report_refresh_budget_branch_local_dropped_candidate_pressure" => true,
             "source_report_refresh_budget_branch_local_invalid_limit_pressure" => true,
             "source_report_refresh_budget_branch_local_candidate_limit_applied" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.refresh_budget_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_refresh_budget_replay_summary(artifact) ==
             replay_summary
  end

  test "refresh budget replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.refresh_budget_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_refresh_budget_contract")
    refute Map.has_key?(source_summary, "source_report_refresh_budget_count")
    refute Map.has_key?(source_summary, "source_report_refresh_budget_row_count")
    refute Map.has_key?(source_summary, "source_report_refresh_budget_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_budget_pressure"]
    refute summary["branch_local_dropped_candidate_pressure"]
    refute summary["branch_local_invalid_limit_pressure"]
    refute summary["branch_local_candidate_limit_applied"]
  end

  test "refresh budget source summary keeps declared contract without partial identity placeholders" do
    placeholder_fields = [
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.refresh_budget_report"]},
      %{"count" => nil, "row_count" => 2},
      %{"count" => 1, "row_count" => nil}
    ]

    for placeholder <- placeholder_fields do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "refresh_budget_report" =>
              Map.put(
                placeholder,
                "contract",
                "refresh_budget_report.v1"
              )
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      assert source_summary["source_report_refresh_budget_contract"] ==
               "refresh_budget_report.v1"

      refute Map.has_key?(source_summary, "source_report_refresh_budget_count")
      refute Map.has_key?(source_summary, "source_report_refresh_budget_row_count")
      refute Map.has_key?(source_summary, "source_report_refresh_budget_paths")
    end
  end

  test "refresh budget source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "refresh_budget_report" => %{
            "contract" => "refresh_budget_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.refresh_budget_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_refresh_budget_contract"] ==
             "refresh_budget_report.v1"

    assert source_summary["source_report_refresh_budget_count"] == 0
    assert source_summary["source_report_refresh_budget_row_count"] == 0

    assert source_summary["source_report_refresh_budget_paths"] == [
             "provenance.source_reports.refresh_budget_report"
           ]
  end

  test "refresh budget source summary omits missing identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "refresh_budget_report" => %{
            "contract" => "refresh_budget_report.v1",
            "count" => 1,
            "row_count" => 2
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_refresh_budget_contract"] ==
             "refresh_budget_report.v1"

    assert source_summary["source_report_refresh_budget_count"] == 1
    assert source_summary["source_report_refresh_budget_row_count"] == 2
    refute Map.has_key?(source_summary, "source_report_refresh_budget_paths")
  end

  test "refresh budget source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "refresh_budget_report" => %{
            "contract" => "refresh_budget_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_refresh_budget_contract"] ==
             "refresh_budget_report.v1"

    assert source_summary["source_report_refresh_budget_count"] == 1
    assert source_summary["source_report_refresh_budget_row_count"] == 2
    assert source_summary["source_report_refresh_budget_paths"] == []
  end

  test "refresh budget replay treats reason maps and candidate IDs as budget pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "refresh_budget_report" => %{
            "contract" => "refresh_budget_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["provenance.source_reports.refresh_budget_report"],
            "input_candidate_count" => 0,
            "kept_candidate_count" => 0,
            "dropped_candidate_count" => 0,
            "invalid_candidate_limit_policy_count" => 0,
            "invalid_candidate_limit_policy_reason_counts" => %{
              "max_candidate_activities_must_be_integer" => 1
            },
            "kept_candidate_ids" => ["candidate_a"],
            "dropped_candidate_ids" => ["candidate_b"]
          }
        }
      }
    }

    summary = CandidateRefresh.refresh_budget_replay_summary(artifact)

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1
    assert summary["source_report_paths"] == ["provenance.source_reports.refresh_budget_report"]
    assert summary["input_candidate_count"] == 0
    assert summary["kept_candidate_count"] == 0
    assert summary["dropped_candidate_count"] == 0
    assert summary["invalid_candidate_limit_policy_count"] == 0

    assert summary["invalid_candidate_limit_policy_reason_counts"] == %{
             "max_candidate_activities_must_be_integer" => 1
           }

    assert summary["kept_candidate_ids"] == ["candidate_a"]
    assert summary["dropped_candidate_ids"] == ["candidate_b"]
    assert summary["branch_local_budget_pressure"]
    assert summary["branch_local_dropped_candidate_pressure"]
    assert summary["branch_local_invalid_limit_pressure"]
    assert summary["branch_local_candidate_limit_applied"]
  end

  test "refresh budget replay treats preserved candidate-limit counts as budget pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "refresh_budget_report" => %{
            "contract" => "refresh_budget_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["provenance.source_reports.refresh_budget_report"],
            "input_candidate_count" => 4,
            "kept_candidate_count" => 2,
            "dropped_candidate_count" => 0,
            "invalid_candidate_limit_policy_count" => 0,
            "invalid_candidate_limit_policy_reason_counts" => %{},
            "kept_candidate_ids" => [],
            "dropped_candidate_ids" => []
          }
        }
      }
    }

    summary = CandidateRefresh.refresh_budget_replay_summary(artifact)

    assert summary["source_report_count"] == 1
    assert summary["input_candidate_count"] == 4
    assert summary["kept_candidate_count"] == 2
    assert summary["dropped_candidate_count"] == 0
    assert summary["dropped_candidate_ids"] == []
    assert summary["invalid_candidate_limit_policy_count"] == 0
    assert summary["invalid_candidate_limit_policy_reason_counts"] == %{}
    refute summary["branch_local_dropped_candidate_pressure"]
    refute summary["branch_local_invalid_limit_pressure"]
    assert summary["branch_local_candidate_limit_applied"]
    assert summary["branch_local_budget_pressure"]
  end

  test "refresh budget replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "refresh_budget_report" => %{
              "contract" => "refresh_budget_report.v1",
              "count" => 1,
              "row_count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_refresh_budget_report"
              ],
              "input_candidate_count" => 4,
              "kept_candidate_count" => 2,
              "dropped_candidate_count" => 0,
              "invalid_candidate_limit_policy_count" => 0,
              "invalid_candidate_limit_policy_reason_counts" => %{
                "max_candidate_activities_must_be_integer" => 1
              },
              "kept_candidate_ids" => ["branch_kept"],
              "dropped_candidate_ids" => ["branch_dropped"],
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_refresh_budget"]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "refresh_budget_report" => %{
            "contract" => "refresh_budget_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["source_refresh_budget_report"],
            "input_candidate_count" => 0,
            "kept_candidate_count" => 0,
            "dropped_candidate_count" => 0,
            "invalid_candidate_limit_policy_count" => 0,
            "invalid_candidate_limit_policy_reason_counts" => %{},
            "kept_candidate_ids" => [],
            "dropped_candidate_ids" => []
          }
        }
      }
    }

    summary = CandidateRefresh.refresh_budget_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.refresh_budget_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_refresh_budget_report"
           ]

    assert summary["input_candidate_count"] == 4
    assert summary["kept_candidate_count"] == 2
    assert summary["dropped_candidate_count"] == 0
    assert summary["invalid_candidate_limit_policy_count"] == 0

    assert summary["invalid_candidate_limit_policy_reason_counts"] == %{
             "max_candidate_activities_must_be_integer" => 1
           }

    assert summary["kept_candidate_ids"] == ["branch_kept"]
    assert summary["dropped_candidate_ids"] == ["branch_dropped"]
    assert summary["trust_boundaries"] == ["branch_refresh_budget"]
    assert summary["branch_local_budget_pressure"]
    assert summary["branch_local_dropped_candidate_pressure"]
    assert summary["branch_local_invalid_limit_pressure"]
    assert summary["branch_local_candidate_limit_applied"]

    assert summary["assumptions"]["replay_scope"] ==
             "refresh_budget_candidate_source_report_summary_only"

    assert %{
             "source_report_refresh_budget_branch_local_budget_pressure" => true,
             "source_report_refresh_budget_branch_local_dropped_candidate_pressure" => true,
             "source_report_refresh_budget_branch_local_invalid_limit_pressure" => true,
             "source_report_refresh_budget_branch_local_candidate_limit_applied" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert OrbitalDynamics.candidate_refresh_refresh_budget_replay_summary(artifact) == summary
  end
end
