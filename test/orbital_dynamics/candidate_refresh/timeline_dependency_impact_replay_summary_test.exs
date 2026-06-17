defmodule OrbitalDynamics.CandidateRefresh.TimelineDependencyImpactReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, CandidateRefresh, OperatorReview, Schema, Timeline}

  test "source report summary replays timeline dependency impact summaries from direct review and import handoffs" do
    source = [
      %{
        id: :health_gate,
        type: :health_check,
        starts_at_s: 0.0,
        ends_at_s: 10.0
      },
      %{
        id: :cmd_combo,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependency_timeline_ids: [:"timeline:health_check:0.0"],
        exclusive_with: [:health_gate],
        exclusive_with_timeline_ids: [:"timeline:health_check:0.0"]
      }
    ]

    replacement = [
      %{
        id: :health_gate,
        type: :health_check,
        starts_at_s: 5.0,
        ends_at_s: 15.0
      },
      %{
        id: :cmd_combo,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependency_timeline_ids: [:"timeline:health_check:0.0"],
        exclusive_with: [:health_gate],
        exclusive_with_timeline_ids: [:"timeline:health_check:0.0"]
      }
    ]

    dependency_summary =
      source
      |> Timeline.dependency_impact_summary(replacement)
      |> Map.put("provenance", %{"trust_boundary" => "ops_dependency_impact"})

    refresh = %{
      "source_timeline_dependency_impact_summary" => dependency_summary,
      "source_operator_review_package" =>
        OperatorReview.from_timeline_dependency_impact_summary(dependency_summary),
      "source_cadence_import_manifest" =>
        CadenceImport.from_timeline_dependency_impact_summary(dependency_summary)
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_counts_by_family" => %{"timeline_dependency_impact_summary" => 3},
             "source_report_row_counts_by_family" => %{
               "timeline_dependency_impact_summary" => 6
             },
             "source_report_timeline_dependency_impact_contract" =>
               "timeline_dependency_impact_summary.v1",
             "source_report_timeline_dependency_impact_count" => 3,
             "source_report_timeline_dependency_impact_row_count" => 6,
             "source_report_timeline_dependency_impact_paths" => [
               "source_timeline_dependency_impact_summary",
               "source_operator_review_package.rows.source_timeline_dependency_impact",
               "source_cadence_import_manifest.rows.source_review_row.source_timeline_dependency_impact"
             ],
             "source_report_timeline_dependency_impact_source_activity_count" => 2,
             "source_report_timeline_dependency_impact_replacement_activity_count" => 2,
             "source_report_timeline_dependency_impact_changed_source_activity_count" => 1,
             "source_report_timeline_dependency_impact_changed_source_timeline_count" => 1,
             "source_report_timeline_dependency_impact_dependent_activity_count" => 6,
             "source_report_timeline_dependency_impact_source_dependent_activity_count" => 3,
             "source_report_timeline_dependency_impact_replacement_dependent_activity_count" => 3,
             "source_report_timeline_dependency_impact_status_counts" => %{
               "review_required" => 6
             },
             "source_report_timeline_dependency_impact_scope_counts" => %{
               "replacement" => 3,
               "source" => 3
             },
             "source_report_timeline_dependency_impact_required_operator_action_counts" => %{
               "review_timeline_integrity" => 6
             },
             "source_report_timeline_dependency_impact_impacted_source_activity_id_counts" => %{
               "health_gate" => 5
             },
             "source_report_timeline_dependency_impact_impacted_dependency_timeline_id_counts" =>
               %{
                 "timeline:health_check:0.0" => 6
               },
             "source_report_timeline_dependency_impact_impacted_exclusive_activity_id_counts" =>
               %{
                 "health_gate" => 6
               },
             "source_report_timeline_dependency_impact_impacted_exclusive_timeline_id_counts" =>
               %{
                 "timeline:health_check:0.0" => 6
               },
             "source_report_timeline_dependency_impact_dependent_activity_id_counts" => %{
               "cmd_combo" => 6
             },
             "source_report_timeline_dependency_impact_branch_local_timeline_dependency_impact_pressure" =>
               true,
             "source_report_timeline_dependency_impact_branch_local_changed_source_pressure" =>
               true,
             "source_report_timeline_dependency_impact_branch_local_dependency_pressure" => true,
             "source_report_timeline_dependency_impact_branch_local_exclusivity_pressure" => true,
             "source_report_timeline_dependency_impact_branch_local_dependent_activity_pressure" =>
               true,
             "source_report_timeline_dependency_impact_branch_local_operator_review_pressure" =>
               true,
             "source_reports" => %{
               "timeline_dependency_impact_summary" => %{
                 "contract" => "timeline_dependency_impact_summary.v1",
                 "count" => 3,
                 "row_count" => 6,
                 "paths" => [
                   "source_timeline_dependency_impact_summary",
                   "source_operator_review_package.rows.source_timeline_dependency_impact",
                   "source_cadence_import_manifest.rows.source_review_row.source_timeline_dependency_impact"
                 ],
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => ["ops_dependency_impact"]
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = CandidateRefresh.timeline_dependency_impact_replay_summary(refresh)

    assert %{
             "model" =>
               "artifact_only_candidate_refresh_timeline_dependency_impact_replay_summary",
             "source" =>
               "candidate_refresh.source_report_provenance.timeline_dependency_impact_summary",
             "contract" => "timeline_dependency_impact_summary.v1",
             "source_report_count" => 3,
             "source_report_row_count" => 6,
             "source_report_paths" => [
               "source_timeline_dependency_impact_summary",
               "source_operator_review_package.rows.source_timeline_dependency_impact",
               "source_cadence_import_manifest.rows.source_review_row.source_timeline_dependency_impact"
             ],
             "changed_source_activity_count" => 1,
             "changed_source_timeline_count" => 1,
             "dependency_impact_status_counts" => %{"review_required" => 6},
             "dependency_impact_scope_counts" => %{"replacement" => 3, "source" => 3},
             "required_operator_action_counts" => %{"review_timeline_integrity" => 6},
             "impacted_source_activity_id_counts" => %{"health_gate" => 5},
             "impacted_dependency_timeline_id_counts" => %{
               "timeline:health_check:0.0" => 6
             },
             "impacted_exclusive_activity_id_counts" => %{"health_gate" => 6},
             "impacted_exclusive_timeline_id_counts" => %{
               "timeline:health_check:0.0" => 6
             },
             "dependent_activity_id_counts" => %{"cmd_combo" => 6},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["ops_dependency_impact"],
             "branch_local_timeline_dependency_impact_pressure" => true,
             "branch_local_changed_source_pressure" => true,
             "branch_local_dependency_pressure" => true,
             "branch_local_exclusivity_pressure" => true,
             "branch_local_dependent_activity_pressure" => true,
             "branch_local_operator_review_pressure" => true,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
               "replay_scope" => "timeline_dependency_impact_source_report_provenance_only",
               "operator_authority" => "not_granted_by_timeline_dependency_impact_replay_summary",
               "timeline_mutation" => "not_performed_by_summary",
               "candidate_selection" => "not_performed_by_summary",
               "import_approval" => "not_granted_by_timeline_dependency_impact_replay_summary",
               "cadence_write" => "not_performed_by_summary",
               "candidate_generation" => "not_performed_by_summary"
             }
           } = replay_summary

    assert OrbitalDynamics.candidate_refresh_timeline_dependency_impact_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => summary["source_reports"]}
    }

    assert %{
             "source_report_timeline_dependency_impact_branch_local_timeline_dependency_impact_pressure" =>
               true,
             "source_report_timeline_dependency_impact_branch_local_changed_source_pressure" =>
               true,
             "source_report_timeline_dependency_impact_branch_local_dependency_pressure" => true,
             "source_report_timeline_dependency_impact_branch_local_exclusivity_pressure" => true,
             "source_report_timeline_dependency_impact_branch_local_dependent_activity_pressure" =>
               true,
             "source_report_timeline_dependency_impact_branch_local_operator_review_pressure" =>
               true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.timeline_dependency_impact_replay_summary(artifact) ==
             replay_summary

    assert OrbitalDynamics.candidate_refresh_timeline_dependency_impact_replay_summary(artifact) ==
             replay_summary
  end

  test "source report summary replays exact timeline summaries from result artifacts" do
    dependency_source = [
      %{
        id: :exact_health_gate,
        type: :health_check,
        starts_at_s: 0.0,
        ends_at_s: 10.0,
        metadata: %{timeline_id: "timeline:exact_dependency:health_gate"}
      },
      %{
        id: :exact_cmd_combo,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependency_timeline_ids: ["timeline:exact_dependency:health_gate"],
        exclusive_with: [:exact_health_gate],
        metadata: %{timeline_id: "timeline:exact_dependency:cmd_combo"}
      }
    ]

    dependency_replacement = [
      %{
        id: :exact_health_gate,
        type: :health_check,
        starts_at_s: 5.0,
        ends_at_s: 15.0,
        metadata: %{timeline_id: "timeline:exact_dependency:health_gate"}
      },
      %{
        id: :exact_cmd_combo,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependency_timeline_ids: ["timeline:exact_dependency:health_gate"],
        exclusive_with: [:exact_health_gate],
        metadata: %{timeline_id: "timeline:exact_dependency:cmd_combo"}
      }
    ]

    dependency_summary =
      dependency_source
      |> Timeline.dependency_impact_summary(dependency_replacement)
      |> Map.put("provenance", %{"trust_boundary" => "exact_dependency_boundary"})

    lifecycle_summary =
      [
        %{
          id: :exact_cmd_pending,
          type: :command,
          status: :planned,
          approval_status: :pending,
          starts_at_s: 40.0,
          ends_at_s: 50.0,
          metadata: %{timeline_id: "timeline:exact_lifecycle:cmd_pending"}
        }
      ]
      |> Timeline.lifecycle_state_summary([
        %{
          id: :exact_cmd_pending,
          type: :command,
          status: :executed,
          approval_status: :approved,
          starts_at_s: 40.0,
          ends_at_s: 50.0,
          metadata: %{timeline_id: "timeline:exact_lifecycle:cmd_pending"}
        }
      ])
      |> Map.put("provenance", %{"trust_boundary" => "exact_lifecycle_boundary"})

    assert {:ok, %{"schema_contract" => "timeline_dependency_impact_summary.v1"}} =
             Schema.validate_artifact(dependency_summary)

    assert {:ok, %{"schema_contract" => "timeline_lifecycle_state_summary.v1"}} =
             Schema.validate_artifact(lifecycle_summary)

    refresh = %{
      "source_result_artifact" => dependency_summary,
      "result_artifact" => lifecycle_summary
    }

    assert %{
             "source_reports" => %{
               "timeline_dependency_impact_summary" => %{
                 "count" => 1,
                 "row_count" => 2,
                 "paths" => ["source_result_artifact"],
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => ["exact_dependency_boundary"]
               },
               "timeline_lifecycle_state_summary" => %{
                 "count" => 1,
                 "row_count" => 1,
                 "paths" => ["result_artifact"],
                 "review_required_count" => 1,
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => ["exact_lifecycle_boundary"]
               }
             }
           } = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "contract" => "timeline_dependency_impact_summary.v1",
             "source_report_count" => 1,
             "source_report_row_count" => 2,
             "source_report_paths" => ["source_result_artifact"],
             "trust_boundaries" => ["exact_dependency_boundary"],
             "branch_local_timeline_dependency_impact_pressure" => true
           } = CandidateRefresh.timeline_dependency_impact_replay_summary(refresh)

    assert %{
             "contract" => "timeline_lifecycle_state_summary.v1",
             "source_report_count" => 1,
             "source_report_row_count" => 1,
             "source_report_paths" => ["result_artifact"],
             "review_required_count" => 1,
             "trust_boundaries" => ["exact_lifecycle_boundary"],
             "branch_local_timeline_lifecycle_state_pressure" => true
           } = CandidateRefresh.timeline_lifecycle_state_replay_summary(refresh)
  end

  test "timeline dependency impact replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.timeline_dependency_impact_replay_summary(artifact)
    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_timeline_dependency_impact_pressure"]
    refute Map.has_key?(source_summary, "source_report_timeline_dependency_impact_contract")
    refute Map.has_key?(source_summary, "source_report_timeline_dependency_impact_count")
    refute Map.has_key?(source_summary, "source_report_timeline_dependency_impact_row_count")
    refute Map.has_key?(source_summary, "source_report_timeline_dependency_impact_paths")
  end

  test "timeline dependency impact source summary keeps declared contract without partial identity placeholders" do
    placeholder_fields = [
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.timeline_dependency_impact_summary"]},
      %{"count" => nil, "row_count" => 2},
      %{"count" => 1, "row_count" => nil}
    ]

    for placeholder <- placeholder_fields do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "timeline_dependency_impact_summary" =>
              Map.put(
                placeholder,
                "contract",
                "timeline_dependency_impact_summary.v1"
              )
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      assert source_summary["source_report_timeline_dependency_impact_contract"] ==
               "timeline_dependency_impact_summary.v1"

      refute Map.has_key?(source_summary, "source_report_timeline_dependency_impact_count")

      refute Map.has_key?(
               source_summary,
               "source_report_timeline_dependency_impact_row_count"
             )

      refute Map.has_key?(source_summary, "source_report_timeline_dependency_impact_paths")
    end
  end

  test "timeline dependency impact source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "timeline_dependency_impact_summary" => %{
            "contract" => "timeline_dependency_impact_summary.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.timeline_dependency_impact_summary"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_timeline_dependency_impact_contract"] ==
             "timeline_dependency_impact_summary.v1"

    assert source_summary["source_report_timeline_dependency_impact_count"] == 0
    assert source_summary["source_report_timeline_dependency_impact_row_count"] == 0

    assert source_summary["source_report_timeline_dependency_impact_paths"] == [
             "provenance.source_reports.timeline_dependency_impact_summary"
           ]
  end

  test "timeline dependency impact source summary omits missing identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "timeline_dependency_impact_summary" => %{
            "contract" => "timeline_dependency_impact_summary.v1",
            "count" => 1,
            "row_count" => 2
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_timeline_dependency_impact_contract"] ==
             "timeline_dependency_impact_summary.v1"

    assert source_summary["source_report_timeline_dependency_impact_count"] == 1
    assert source_summary["source_report_timeline_dependency_impact_row_count"] == 2
    refute Map.has_key?(source_summary, "source_report_timeline_dependency_impact_paths")
  end

  test "timeline dependency impact source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "timeline_dependency_impact_summary" => %{
            "contract" => "timeline_dependency_impact_summary.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_timeline_dependency_impact_contract"] ==
             "timeline_dependency_impact_summary.v1"

    assert source_summary["source_report_timeline_dependency_impact_count"] == 1
    assert source_summary["source_report_timeline_dependency_impact_row_count"] == 2
    assert source_summary["source_report_timeline_dependency_impact_paths"] == []
  end

  test "timeline dependency impact replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_dependency_impact_summary" => %{
              "contract" => "timeline_dependency_impact_summary.v1",
              "count" => 1,
              "row_count" => 2,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_dependency_impact_summary"
              ],
              "source_activity_count" => 2,
              "replacement_activity_count" => 2,
              "changed_source_activity_count" => 1,
              "changed_source_timeline_count" => 1,
              "dependent_activity_count" => 2,
              "source_dependent_activity_count" => 1,
              "replacement_dependent_activity_count" => 1,
              "dependency_impact_status_counts" => %{"review_required" => 2},
              "dependency_impact_scope_counts" => %{"replacement" => 1, "source" => 1},
              "required_operator_action_counts" => %{"review_timeline_integrity" => 2},
              "impacted_source_activity_id_counts" => %{"health_gate" => 1},
              "impacted_source_timeline_id_counts" => %{"timeline:health_gate" => 1},
              "impacted_dependency_activity_id_counts" => %{"dependency_gate" => 1},
              "impacted_dependency_timeline_id_counts" => %{"timeline:dependency_gate" => 1},
              "impacted_exclusive_activity_id_counts" => %{"exclusive_gate" => 1},
              "impacted_exclusive_timeline_id_counts" => %{"timeline:exclusive_gate" => 1},
              "dependent_activity_id_counts" => %{"cmd_combo" => 2},
              "dependent_timeline_id_counts" => %{"timeline:cmd_combo" => 2},
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_dependency_impact"]
            }
          }
        }
      },
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.timeline_dependency_impact_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_dependency_impact_summary"

    assert summary["contract"] == "timeline_dependency_impact_summary.v1"
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 2

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_dependency_impact_summary"
           ]

    assert summary["source_activity_count"] == 2
    assert summary["replacement_activity_count"] == 2
    assert summary["changed_source_activity_count"] == 1
    assert summary["changed_source_timeline_count"] == 1
    assert summary["dependent_activity_count"] == 2
    assert summary["source_dependent_activity_count"] == 1
    assert summary["replacement_dependent_activity_count"] == 1
    assert summary["dependency_impact_status_counts"] == %{"review_required" => 2}
    assert summary["dependency_impact_scope_counts"] == %{"replacement" => 1, "source" => 1}
    assert summary["required_operator_action_counts"] == %{"review_timeline_integrity" => 2}
    assert summary["impacted_source_activity_id_counts"] == %{"health_gate" => 1}
    assert summary["impacted_source_timeline_id_counts"] == %{"timeline:health_gate" => 1}
    assert summary["impacted_dependency_activity_id_counts"] == %{"dependency_gate" => 1}
    assert summary["impacted_dependency_timeline_id_counts"] == %{"timeline:dependency_gate" => 1}
    assert summary["impacted_exclusive_activity_id_counts"] == %{"exclusive_gate" => 1}
    assert summary["impacted_exclusive_timeline_id_counts"] == %{"timeline:exclusive_gate" => 1}
    assert summary["dependent_activity_id_counts"] == %{"cmd_combo" => 2}
    assert summary["dependent_timeline_id_counts"] == %{"timeline:cmd_combo" => 2}
    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_dependency_impact"]
    assert summary["branch_local_timeline_dependency_impact_pressure"]
    assert summary["branch_local_changed_source_pressure"]
    assert summary["branch_local_dependency_pressure"]
    assert summary["branch_local_exclusivity_pressure"]
    assert summary["branch_local_dependent_activity_pressure"]
    assert summary["branch_local_operator_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_dependency_impact_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_timeline_dependency_impact_replay_summary(artifact) ==
             summary
  end

  test "timeline dependency impact replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "timeline_dependency_impact_summary" => %{
            "contract" => "timeline_dependency_impact_summary.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_timeline_dependency_impact_summary"
            ],
            "dependent_activity_id_counts" => %{"direct_dependent_activity" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_dependency_impact_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_dependency_impact_summary"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_dependency_impact_summary"
           ]

    assert summary["dependent_activity_id_counts"] == %{"direct_dependent_activity" => 1}
    assert summary["branch_local_timeline_dependency_impact_pressure"]
    assert summary["branch_local_dependent_activity_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_dependency_impact_candidate_source_report_summary_only"
  end

  test "timeline dependency impact replay falls back to provenance when branch summary lacks usable family" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_dependency_impact_summary" => %{},
            "timeline_diff_report" => %{
              "contract" => "timeline_diff_report.v1",
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_diff_report"
              ]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "timeline_dependency_impact_summary" => %{
            "contract" => "timeline_dependency_impact_summary.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_timeline_dependency_impact_summary"],
            "dependent_activity_id_counts" => %{"provenance_dependent_activity" => 1},
            "required_operator_action_counts" => %{"review_timeline_integrity" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_dependency_impact_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.timeline_dependency_impact_summary"

    assert summary["source_report_paths"] == ["source_timeline_dependency_impact_summary"]
    assert summary["dependent_activity_id_counts"] == %{"provenance_dependent_activity" => 1}
    assert summary["required_operator_action_counts"] == %{"review_timeline_integrity" => 1}
    assert summary["branch_local_timeline_dependency_impact_pressure"]
    assert summary["branch_local_dependent_activity_pressure"]
    assert summary["branch_local_operator_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_dependency_impact_source_report_provenance_only"
  end

  test "timeline dependency impact replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_dependency_impact_summary" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_dependency_impact_summary"
              ],
              "dependent_activity_id_counts" => %{"branch_dependent_activity" => 1}
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "timeline_dependency_impact_summary" => %{
            "contract" => "timeline_dependency_impact_summary.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_timeline_dependency_impact_summary"],
            "required_operator_action_counts" => %{"review_timeline_integrity" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_dependency_impact_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_dependency_impact_summary"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_dependency_impact_summary"
           ]

    assert summary["dependent_activity_id_counts"] == %{"branch_dependent_activity" => 1}
    assert summary["required_operator_action_counts"] == %{}
    assert summary["branch_local_timeline_dependency_impact_pressure"]
    assert summary["branch_local_dependent_activity_pressure"]
    refute summary["branch_local_operator_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_dependency_impact_candidate_source_report_summary_only"
  end

  test "operator review and import lift exact timeline dependency-impact summaries from candidate refresh result artifacts" do
    dependency_summary = fn prefix, trust_boundary ->
      source = [
        %{
          id: "#{prefix}_health_gate",
          type: :health_check,
          starts_at_s: 0.0,
          ends_at_s: 10.0,
          metadata: %{timeline_id: "timeline:#{prefix}:health_gate"}
        },
        %{
          id: "#{prefix}_cmd_combo",
          type: :command,
          starts_at_s: 20.0,
          ends_at_s: 30.0,
          dependency_timeline_ids: ["timeline:#{prefix}:health_gate"],
          exclusive_with: ["#{prefix}_health_gate"],
          metadata: %{timeline_id: "timeline:#{prefix}:cmd_combo"}
        }
      ]

      replacement = [
        %{
          id: "#{prefix}_health_gate",
          type: :health_check,
          starts_at_s: 5.0,
          ends_at_s: 15.0,
          metadata: %{timeline_id: "timeline:#{prefix}:health_gate"}
        },
        %{
          id: "#{prefix}_cmd_combo",
          type: :command,
          starts_at_s: 20.0,
          ends_at_s: 30.0,
          dependency_timeline_ids: ["timeline:#{prefix}:health_gate"],
          exclusive_with: ["#{prefix}_health_gate"],
          metadata: %{timeline_id: "timeline:#{prefix}:cmd_combo"}
        }
      ]

      source
      |> Timeline.dependency_impact_summary(replacement)
      |> Map.put("provenance", %{"trust_boundary" => trust_boundary})
    end

    direct_summary = dependency_summary.("direct_dependency", "direct_dependency_boundary")
    result_summary = dependency_summary.("result_dependency", "result_dependency_boundary")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:timeline_dependency_impact_handoff",
      "source_timeline_dependency_impact_summary" => [direct_summary],
      "source_result_artifact" => result_summary
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    dependency_rows =
      Enum.filter(review["rows"], &(&1["review_type"] == "timeline_dependency_impact_review"))

    assert length(dependency_rows) == 4

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "timeline_dependency_impact_review_count" => 4,
             "review_type_counts" => %{"timeline_dependency_impact_review" => 4}
           } = review

    assert Enum.sort(Enum.map(dependency_rows, & &1["source"]) |> Enum.uniq()) == [
             "candidate_refresh.source_result_artifact.dependency_impact_rows",
             "candidate_refresh.source_timeline_dependency_impact_summary[0].dependency_impact_rows"
           ]

    assert Enum.any?(
             dependency_rows,
             &match?(
               %{
                 "source" => "candidate_refresh.source_result_artifact.dependency_impact_rows",
                 "timeline_id" => "timeline:result_dependency:cmd_combo",
                 "required_operator_action" => "review_timeline_integrity",
                 "source_timeline_dependency_impact" => %{
                   "dependency_impact_status" => "review_required"
                 }
               },
               &1
             )
           )

    import_rows =
      Enum.filter(
        import["rows"],
        &(&1["source_review_type"] == "timeline_dependency_impact_review")
      )

    assert length(import_rows) == 4

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "import_action_counts" => %{"review_timeline_dependency_impact" => 4},
             "source_review_type_counts" => %{"timeline_dependency_impact_review" => 4}
           } = import

    assert Enum.all?(
             import_rows,
             &(&1["import_action"] == "review_timeline_dependency_impact" and
                 &1["source_review_row"]["source_timeline_dependency_impact"])
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end
end
