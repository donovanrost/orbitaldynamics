Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyModelGovernancePressureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.{CandidateRefresh, Schema}

  test "strategy derives branch refresh from mission-state model acceptance reports" do
    model_acceptance_report =
      %{
        "schema_contract" => "model_acceptance_report.v1",
        "schema_version" => 1,
        "report_id" => "model_acceptance:operational_import:live_ops",
        "model" => "registry_model_acceptance_classifier",
        "intended_use" => "operational_import",
        "status" => "review_required",
        "model_count" => 1,
        "accepted_count" => 0,
        "review_required_count" => 1,
        "blocked_count" => 0,
        "unknown_model_count" => 0,
        "status_counts" => %{"review_required" => 1},
        "validation_level_counts" => %{"analysis" => 1},
        "model_ids_by_status" => %{"review_required" => ["live_analysis_model"]},
        "model_ids_by_validation_level" => %{"analysis" => ["live_analysis_model"]},
        "model_ids_by_intended_use" => %{"operational_import" => ["live_analysis_model"]},
        "records" => [],
        "rows" => [
          %{
            "id" => "model_acceptance:live_analysis_model",
            "rank" => 1,
            "model_id" => "live_analysis_model",
            "validation_level" => "analysis",
            "status" => "review_required",
            "reason" => "analysis evidence requires operator review for operational_import"
          }
        ],
        "assumptions" => %{"source" => "test.model_acceptance_report"},
        "model_limits" => ["artifact_only"],
        "provenance" => %{"trust_boundary" => "mission_state_model_acceptance_report"}
      }

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:source_model_acceptance_report, model_acceptance_report)

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    model_branch = branch(artifact, "derived_model_acceptance_pressure_live_analysis_model")

    assert %{
             "type" => "model_acceptance_pressure",
             "report_id" => "model_acceptance:operational_import:live_ops",
             "intended_use" => "operational_import",
             "model_acceptance_status" => "review_required",
             "model_id" => "live_analysis_model",
             "validation_level" => "analysis",
             "model_status" => "review_required",
             "status_counts" => %{"review_required" => 1},
             "validation_level_counts" => %{"analysis" => 1},
             "model_ids_by_status" => %{"review_required" => ["live_analysis_model"]},
             "model_ids_by_validation_level" => %{"analysis" => ["live_analysis_model"]},
             "model_ids_by_intended_use" => %{"operational_import" => ["live_analysis_model"]},
             "model_reason" =>
               "analysis evidence requires operator review for operational_import",
             "required_operator_action" => "review_model_acceptance",
             "feedback_source" => "mission_state.source_model_acceptance_report.rows",
             "feedback_scope" => "model_acceptance",
             "trust_boundary" => "mission_state_model_acceptance_report",
             "source_model_acceptance_row" => %{
               "model_id" => "live_analysis_model"
             },
             "source_model_acceptance_report" => %{
               "report_id" => "model_acceptance:operational_import:live_ops"
             }
           } = List.first(model_branch["events"])

    assert %{
             "type" => "candidate_refresh.v1",
             "scope" => "branch_generated"
           } = model_branch["assumptions"]["candidate_source"]

    assert "mission_state.source_model_acceptance_report" in get_in(
             model_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    assert "mission_state.source_model_acceptance_report" in get_in(
             model_branch,
             [
               "assumptions",
               "candidate_source",
               "candidate_refresh_request_source_report_input_paths"
             ]
           )

    assert_validation_refresh_pressure_score_terms(model_branch, artifact, "model_acceptance")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    model_branch_index =
      Enum.find_index(
        artifact["branches"],
        &(&1["branch_id"] == "derived_model_acceptance_pressure_live_analysis_model")
      )

    stale_model_acceptance_routing =
      put_in(
        artifact,
        [
          "branches",
          Access.at(model_branch_index),
          "events",
          Access.at(0),
          "model_ids_by_status",
          "review_required"
        ],
        ["live_analysis_model", 42]
      )

    assert {:error, stale_model_acceptance_routing_report} =
             Schema.validate_artifact(stale_model_acceptance_routing)

    assert Enum.any?(
             stale_model_acceptance_routing_report["errors"],
             &(&1["path"] =~ ".model_ids_by_status.review_required" and
                 &1["message"] == "must contain only strings")
           )
  end

  test "strategy challenge scores model-acceptance replay from rows when top-level fields are stale" do
    stale_report =
      %{
        "schema_contract" => "model_acceptance_report.v1",
        "schema_version" => 1,
        "report_id" => "model_acceptance:operational_import:stale_top_level",
        "model" => "registry_model_acceptance_classifier",
        "intended_use" => "operational_import",
        "status" => "accepted",
        "model_count" => 1,
        "accepted_count" => 1,
        "review_required_count" => 0,
        "blocked_count" => 0,
        "unknown_model_count" => 0,
        "status_counts" => %{"accepted" => 1},
        "validation_level_counts" => %{"artifact_contract" => 1},
        "model_ids_by_status" => %{"accepted" => ["stale.accepted"]},
        "model_ids_by_validation_level" => %{
          "artifact_contract" => ["stale.accepted"]
        },
        "model_ids_by_intended_use" => %{
          "operational_import" => ["stale.accepted"]
        },
        "records" => [],
        "rows" => [
          %{
            "id" => "model_acceptance:row.blocked",
            "rank" => 1,
            "model_id" => "row.blocked",
            "validation_level" => "educational",
            "status" => "blocked",
            "reason" => "educational model evidence cannot support operational import"
          },
          %{
            "id" => "model_acceptance:row.review",
            "rank" => 2,
            "model_id" => "row.review",
            "validation_level" => "analysis",
            "status" => "review_required",
            "reason" => "analysis model evidence requires operator review"
          }
        ],
        "assumptions" => %{"stale_top_level_challenge" => true},
        "model_limits" => ["artifact_only"],
        "provenance" => %{"trust_boundary" => "stale_model_acceptance_boundary"}
      }

    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_model_acceptance_report, stale_report),
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    urgent = branch(artifact, "urgent")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = urgent["assumptions"]["candidate_source"]

    assert %{
             "status_counts" => %{"accepted" => 1},
             "model_count" => 2,
             "accepted_count" => 0,
             "review_required_count" => 1,
             "blocked_count" => 1,
             "unknown_model_count" => 0,
             "validation_level_counts" => %{"analysis" => 1, "educational" => 1},
             "model_ids_by_status" => %{
               "blocked" => ["row.blocked"],
               "review_required" => ["row.review"]
             },
             "model_ids_by_validation_level" => %{
               "analysis" => ["row.review"],
               "educational" => ["row.blocked"]
             },
             "model_ids_by_intended_use" => %{
               "operational_import" => ["row.blocked", "row.review"]
             },
             "branch_local_review_pressure" => true,
             "branch_local_blocking_pressure" => true
           } = CandidateRefresh.model_acceptance_replay_summary(candidate_source)

    assert Enum.any?(
             urgent["risk_indicators"],
             &(&1["type"] == "model_acceptance_pressure" and
                 &1["feedback_source"] ==
                   "candidate_source.model_acceptance_replay_summary" and
                 &1["severity"] == "high" and
                 &1["model_acceptance_status"] == "blocked" and
                 &1["model_status"] == "blocked" and
                 &1["model_acceptance_statuses"] == [
                   "accepted",
                   "blocked",
                   "review_required"
                 ] and
                 &1["status_counts"] == %{"accepted" => 1} and
                 &1["model_ids_by_status"] == %{
                   "blocked" => ["row.blocked"],
                   "review_required" => ["row.review"]
                 } and
                 &1["review_required_count"] == 1 and
                 &1["blocked_count"] == 1 and
                 &1["model_ids"] == ["row.blocked", "row.review"] and
                 &1["branch_local_review_pressure"] == true and
                 &1["branch_local_blocking_pressure"] == true)
           )

    assert_validation_refresh_pressure_score_terms(urgent, artifact, "model_acceptance")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from mission-state validation safety-case summaries" do
    safety_case_summary =
      %{
        "schema_contract" => "validation_safety_case_summary.v1",
        "schema_version" => 1,
        "model" => "artifact_only_validation_safety_case_summary",
        "report_id" => "validation_safety_case:live_ops",
        "status" => "blocked",
        "evidence_count" => 2,
        "accepted_evidence_count" => 0,
        "review_required_evidence_count" => 1,
        "blocked_evidence_count" => 1,
        "schema_error_count" => 1,
        "schema_warning_count" => 2,
        "model_blocked_count" => 1,
        "quality_gate_review_count" => 1,
        "quality_gate_blocked_count" => 1,
        "input_contracts" => ["model_acceptance_report.v1", "quality_gate_report.v1"],
        "evidence_status_counts" => %{"blocked" => 1, "review_required" => 1},
        "evidence_refs_by_status" => %{
          "blocked" => ["model_acceptance_report.v1:model.blocked"],
          "review_required" => ["quality_gate_report.v1:gate.review"]
        },
        "evidence_refs_by_contract" => %{
          "model_acceptance_report.v1" => ["model_acceptance_report.v1:model.blocked"],
          "quality_gate_report.v1" => ["quality_gate_report.v1:gate.review"]
        },
        "evidence" => [
          %{
            "id" => "model.blocked",
            "ref" => "model_acceptance_report.v1:model.blocked",
            "input_contract" => "model_acceptance_report.v1",
            "status" => "blocked",
            "model_blocked_count" => 1,
            "schema_error_count" => 1,
            "schema_warning_count" => 2,
            "reason" => "model acceptance blocks operational import"
          },
          %{
            "id" => "gate.review",
            "ref" => "quality_gate_report.v1:gate.review",
            "input_contract" => "quality_gate_report.v1",
            "status" => "review_required",
            "quality_gate_review_count" => 1,
            "quality_gate_blocked_count" => 1,
            "reason" => "quality gate requires operator review"
          }
        ],
        "assumptions" => %{"source" => "test.validation_safety_case_summary"},
        "model_limits" => ["artifact_only"],
        "provenance" => %{"trust_boundary" => "mission_state_validation_safety_case"}
      }

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:source_validation_safety_case_summary, safety_case_summary)

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    safety_case_branch =
      branch(
        artifact,
        "derived_validation_safety_case_pressure_model_acceptance_report.v1:model.blocked"
      )

    assert %{
             "type" => "validation_safety_case_pressure",
             "report_id" => "validation_safety_case:live_ops",
             "validation_safety_case_status" => "blocked",
             "evidence_status" => "blocked",
             "input_contract" => "model_acceptance_report.v1",
             "input_contracts" => ["model_acceptance_report.v1", "quality_gate_report.v1"],
             "evidence_ref" => "model_acceptance_report.v1:model.blocked",
             "evidence_count" => 2,
             "blocked_evidence_count" => 1,
             "schema_error_count" => 1,
             "schema_warning_count" => 2,
             "model_blocked_count" => 1,
             "quality_gate_review_count" => 1,
             "quality_gate_blocked_count" => 1,
             "evidence_status_counts" => %{"blocked" => 1, "review_required" => 1},
             "evidence_refs_by_status" => %{
               "blocked" => ["model_acceptance_report.v1:model.blocked"],
               "review_required" => ["quality_gate_report.v1:gate.review"]
             },
             "required_operator_action" => "review_blocked_validation_safety_case",
             "feedback_source" => "mission_state.source_validation_safety_case_summary.evidence",
             "feedback_scope" => "validation_safety_case",
             "trust_boundary" => "mission_state_validation_safety_case",
             "source_validation_safety_case_evidence" => %{
               "id" => "model.blocked"
             },
             "source_validation_safety_case_summary" => %{
               "report_id" => "validation_safety_case:live_ops"
             }
           } = List.first(safety_case_branch["events"])

    assert %{
             "type" => "candidate_refresh.v1",
             "scope" => "branch_generated"
           } = candidate_source = safety_case_branch["assumptions"]["candidate_source"]

    assert "mission_state.source_validation_safety_case_summary" in get_in(
             safety_case_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    assert "mission_state.source_validation_safety_case_summary" in get_in(
             safety_case_branch,
             [
               "assumptions",
               "candidate_source",
               "candidate_refresh_request_source_report_input_paths"
             ]
           )

    validation_safety_case_replay_summary =
      CandidateRefresh.validation_safety_case_replay_summary(candidate_source)

    assert %{
             "contract" => "validation_safety_case_summary.v1",
             "source_report_count" => 1,
             "source_report_row_count" => 2,
             "source_report_paths" => validation_safety_case_source_paths,
             "status_counts" => %{"blocked" => 1},
             "evidence_status_counts" => %{"blocked" => 1, "review_required" => 1},
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
             "review_required_evidence_count" => 1,
             "blocked_evidence_count" => 1,
             "model_blocked_count" => 1,
             "quality_gate_review_count" => 1,
             "quality_gate_blocked_count" => 1,
             "schema_error_count" => 1,
             "schema_warning_count" => 2,
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["mission_state_validation_safety_case"],
             "branch_local_review_pressure" => true,
             "branch_local_blocking_pressure" => true,
             "branch_local_schema_pressure" => true,
             "branch_local_fixture_pressure" => false
           } = validation_safety_case_replay_summary

    assert "mission_state.source_validation_safety_case_summary" in validation_safety_case_source_paths

    assert_validation_refresh_pressure_score_terms(
      safety_case_branch,
      artifact,
      "validation_safety_case"
    )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    safety_case_branch_index =
      Enum.find_index(
        artifact["branches"],
        &(&1["branch_id"] ==
            "derived_validation_safety_case_pressure_model_acceptance_report.v1:model.blocked")
      )

    stale_safety_case_counts =
      put_in(
        artifact,
        [
          "branches",
          Access.at(safety_case_branch_index),
          "events",
          Access.at(0),
          "evidence_status_counts",
          "blocked"
        ],
        -1
      )

    assert {:error, stale_safety_case_counts_report} =
             Schema.validate_artifact(stale_safety_case_counts)

    assert Enum.any?(
             stale_safety_case_counts_report["errors"],
             &(&1["path"] =~ ".evidence_status_counts.blocked" and
                 &1["message"] == "must be a non-negative integer")
           )
  end

  test "strategy carries wrapped validation safety-case summaries into branch refresh requests" do
    direct_summary =
      %{
        "schema_contract" => "validation_safety_case_summary.v1",
        "schema_version" => 1,
        "model" => "artifact_only_validation_safety_case_summary",
        "report_id" => "validation_safety_case:direct",
        "status" => "blocked",
        "evidence_count" => 1,
        "accepted_evidence_count" => 0,
        "review_required_evidence_count" => 0,
        "blocked_evidence_count" => 1,
        "schema_error_count" => 1,
        "schema_warning_count" => 0,
        "model_blocked_count" => 1,
        "quality_gate_review_count" => 0,
        "quality_gate_blocked_count" => 0,
        "input_contracts" => ["model_acceptance_report.v1"],
        "evidence_status_counts" => %{"blocked" => 1},
        "evidence_refs_by_status" => %{
          "blocked" => ["model_acceptance_report.v1:direct.blocked"]
        },
        "evidence_refs_by_contract" => %{
          "model_acceptance_report.v1" => ["model_acceptance_report.v1:direct.blocked"]
        },
        "evidence" => [
          %{
            "id" => "direct.blocked",
            "ref" => "model_acceptance_report.v1:direct.blocked",
            "input_contract" => "model_acceptance_report.v1",
            "status" => "blocked",
            "model_blocked_count" => 1,
            "schema_error_count" => 1
          }
        ],
        "assumptions" => %{"source" => "test.validation_safety_case_summary"},
        "model_limits" => ["artifact_only"],
        "provenance" => %{"trust_boundary" => "direct_validation_safety_case_boundary"}
      }

    canonical_summary =
      %{
        "schema_contract" => "validation_safety_case_summary.v1",
        "schema_version" => 1,
        "model" => "artifact_only_validation_safety_case_summary",
        "report_id" => "validation_safety_case:canonical",
        "status" => "review_required",
        "evidence_count" => 1,
        "accepted_evidence_count" => 0,
        "review_required_evidence_count" => 1,
        "blocked_evidence_count" => 0,
        "schema_error_count" => 0,
        "schema_warning_count" => 0,
        "model_blocked_count" => 0,
        "quality_gate_review_count" => 1,
        "quality_gate_blocked_count" => 0,
        "input_contracts" => ["quality_gate_report.v1"],
        "evidence_status_counts" => %{"review_required" => 1},
        "evidence_refs_by_status" => %{
          "review_required" => ["quality_gate_report.v1:canonical.review"]
        },
        "evidence_refs_by_contract" => %{
          "quality_gate_report.v1" => ["quality_gate_report.v1:canonical.review"]
        },
        "evidence" => [
          %{
            "id" => "canonical.review",
            "ref" => "quality_gate_report.v1:canonical.review",
            "input_contract" => "quality_gate_report.v1",
            "status" => "review_required",
            "quality_gate_review_count" => 1
          }
        ],
        "assumptions" => %{"source" => "test.canonical_validation_safety_case_summary"},
        "model_limits" => ["artifact_only"],
        "provenance" => %{"trust_boundary" => "canonical_validation_safety_case_boundary"}
      }

    wrapped_summary =
      %{
        "schema_contract" => "validation_safety_case_summary.v1",
        "schema_version" => 1,
        "model" => "artifact_only_validation_safety_case_summary",
        "report_id" => "validation_safety_case:wrapped",
        "status" => "review_required",
        "evidence_count" => 1,
        "accepted_evidence_count" => 0,
        "review_required_evidence_count" => 1,
        "blocked_evidence_count" => 0,
        "schema_error_count" => 0,
        "schema_warning_count" => 0,
        "model_blocked_count" => 0,
        "quality_gate_review_count" => 1,
        "quality_gate_blocked_count" => 0,
        "input_contracts" => ["quality_gate_report.v1"],
        "evidence_status_counts" => %{"review_required" => 1},
        "evidence_refs_by_status" => %{
          "review_required" => ["quality_gate_report.v1:wrapped.review"]
        },
        "evidence_refs_by_contract" => %{
          "quality_gate_report.v1" => ["quality_gate_report.v1:wrapped.review"]
        },
        "evidence" => [
          %{
            "id" => "wrapped.review",
            "ref" => "quality_gate_report.v1:wrapped.review",
            "input_contract" => "quality_gate_report.v1",
            "status" => "review_required",
            "quality_gate_review_count" => 1
          }
        ],
        "assumptions" => %{"source" => "test.wrapped_validation_safety_case_summary"},
        "model_limits" => ["artifact_only"]
      }

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:source_validation_safety_case_summary, direct_summary)
      |> Map.put(:validation_safety_case_summary, canonical_summary)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "validation_safety_case_summary" => wrapped_summary,
        "provenance" => %{
          "trust_boundary" => "wrapped_validation_safety_case_boundary"
        }
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    safety_case_branch =
      branch(
        artifact,
        "derived_validation_safety_case_pressure_model_acceptance_report.v1:direct.blocked"
      )

    assert %{
             "type" => "candidate_refresh.v1",
             "scope" => "branch_generated"
           } = candidate_source = safety_case_branch["assumptions"]["candidate_source"]

    assert "mission_state.source_validation_safety_case_summary" in candidate_source[
             "source_report_input_paths"
           ]

    assert "mission_state.validation_safety_case_summary" in candidate_source[
             "source_report_input_paths"
           ]

    assert "mission_state.source_result_artifact.validation_safety_case_summary" in candidate_source[
             "source_report_input_paths"
           ]

    assert "mission_state.source_validation_safety_case_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert "mission_state.validation_safety_case_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert "mission_state.source_result_artifact.validation_safety_case_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert %{
             "source_report_validation_safety_case_evidence_count" => 3,
             "source_report_validation_safety_case_status_counts" => %{
               "blocked" => 1,
               "review_required" => 2
             },
             "source_report_validation_safety_case_evidence_status_counts" => %{
               "blocked" => 1,
               "review_required" => 2
             },
             "source_report_validation_safety_case_input_contract_counts" => %{
               "model_acceptance_report.v1" => 1,
               "quality_gate_report.v1" => 2
             },
             "source_report_validation_safety_case_review_required_evidence_count" => 2,
             "source_report_validation_safety_case_blocked_evidence_count" => 1,
             "source_report_validation_safety_case_model_blocked_count" => 1,
             "source_report_validation_safety_case_quality_gate_review_count" => 2,
             "source_report_validation_safety_case_schema_error_count" => 1
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "contract" => "validation_safety_case_summary.v1",
             "source_report_count" => 3,
             "source_report_row_count" => 3,
             "source_report_paths" => replay_source_paths,
             "status_counts" => %{"blocked" => 1, "review_required" => 2},
             "evidence_status_counts" => %{"blocked" => 1, "review_required" => 2},
             "input_contract_counts" => %{
               "model_acceptance_report.v1" => 1,
               "quality_gate_report.v1" => 2
             },
             "review_required_evidence_count" => 2,
             "blocked_evidence_count" => 1,
             "model_blocked_count" => 1,
             "quality_gate_review_count" => 2,
             "schema_error_count" => 1,
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "canonical_validation_safety_case_boundary",
               "direct_validation_safety_case_boundary",
               "wrapped_validation_safety_case_boundary"
             ],
             "branch_local_review_pressure" => true,
             "branch_local_blocking_pressure" => true,
             "branch_local_schema_pressure" => true
           } = CandidateRefresh.validation_safety_case_replay_summary(candidate_source)

    assert Enum.sort(replay_source_paths) == [
             "mission_state.source_result_artifact.validation_safety_case_summary",
             "mission_state.source_validation_safety_case_summary",
             "mission_state.validation_safety_case_summary"
           ]

    replay_artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    urgent = branch(replay_artifact, "urgent")

    validation_safety_case_pressure_count =
      Enum.count(
        urgent["risk_indicators"],
        &(&1["type"] == "validation_safety_case_pressure" and
            &1["feedback_source"] ==
              "candidate_source.validation_safety_case_replay_summary")
      )

    assert validation_safety_case_pressure_count == 1

    assert Enum.any?(
             urgent["risk_indicators"],
             &(&1["type"] == "validation_safety_case_pressure" and
                 &1["feedback_scope"] == "validation_safety_case" and
                 &1["severity"] == "high" and
                 &1["source_report_count"] == 3 and
                 &1["source_report_row_count"] == 3 and
                 &1["source_report_paths"] == replay_source_paths and
                 &1["validation_safety_case_status"] == "blocked" and
                 &1["validation_safety_case_statuses"] == ["blocked", "review_required"] and
                 &1["evidence_status"] == "blocked" and
                 &1["evidence_statuses"] == ["blocked", "review_required"] and
                 &1["input_contract"] == "model_acceptance_report.v1" and
                 &1["input_contracts"] == [
                   "model_acceptance_report.v1",
                   "quality_gate_report.v1"
                 ] and
                 &1["evidence_refs"] == [
                   "model_acceptance_report.v1:direct.blocked",
                   "quality_gate_report.v1:canonical.review",
                   "quality_gate_report.v1:wrapped.review"
                 ] and
                 &1["status_counts"] == %{"blocked" => 1, "review_required" => 2} and
                 &1["evidence_status_counts"] == %{
                   "blocked" => 1,
                   "review_required" => 2
                 } and
                 &1["input_contract_counts"] == %{
                   "model_acceptance_report.v1" => 1,
                   "quality_gate_report.v1" => 2
                 } and
                 &1["review_required_evidence_count"] == 2 and
                 &1["blocked_evidence_count"] == 1 and
                 &1["model_blocked_count"] == 1 and
                 &1["quality_gate_review_count"] == 2 and
                 &1["schema_error_count"] == 1 and
                 &1["branch_local_review_pressure"] == true and
                 &1["branch_local_blocking_pressure"] == true and
                 &1["branch_local_schema_pressure"] == true)
           )

    assert_validation_refresh_pressure_score_terms(
      urgent,
      replay_artifact,
      "validation_safety_case"
    )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(replay_artifact)
  end

  test "strategy challenge scores validation safety-case replay from rows when top-level fields are stale" do
    stale_summary =
      %{
        "schema_contract" => "validation_safety_case_summary.v1",
        "schema_version" => 1,
        "model" => "artifact_only_validation_safety_case_summary",
        "report_id" => "validation_safety_case:stale_top_level",
        "status" => "accepted",
        "evidence_count" => 1,
        "accepted_evidence_count" => 1,
        "review_required_evidence_count" => 0,
        "blocked_evidence_count" => 0,
        "schema_error_count" => 0,
        "schema_warning_count" => 0,
        "model_blocked_count" => 0,
        "quality_gate_review_count" => 0,
        "quality_gate_blocked_count" => 0,
        "input_contracts" => ["model_acceptance_report.v1", "quality_gate_report.v1"],
        "evidence_status_counts" => %{"accepted" => 1},
        "evidence_refs_by_status" => %{
          "accepted" => ["model_acceptance_report.v1:stale.accepted"]
        },
        "evidence_refs_by_contract" => %{
          "model_acceptance_report.v1" => ["model_acceptance_report.v1:stale.accepted"]
        },
        "evidence" => [
          %{
            "id" => "row.blocked",
            "ref" => "model_acceptance_report.v1:row.blocked",
            "input_contract" => "model_acceptance_report.v1",
            "status" => "blocked",
            "model_blocked_count" => 1,
            "schema_error_count" => 1
          },
          %{
            "id" => "row.review",
            "ref" => "quality_gate_report.v1:row.review",
            "input_contract" => "quality_gate_report.v1",
            "status" => "review_required",
            "quality_gate_review_count" => 1
          }
        ],
        "assumptions" => %{"stale_top_level_challenge" => true},
        "model_limits" => ["artifact_only"],
        "provenance" => %{"trust_boundary" => "stale_safety_case_boundary"}
      }

    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_validation_safety_case_summary, stale_summary),
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    urgent = branch(artifact, "urgent")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = urgent["assumptions"]["candidate_source"]

    assert %{
             "status_counts" => %{"accepted" => 1},
             "evidence_status_counts" => %{"blocked" => 1, "review_required" => 1},
             "input_contract_counts" => %{
               "model_acceptance_report.v1" => 1,
               "quality_gate_report.v1" => 1
             },
             "review_required_evidence_count" => 1,
             "blocked_evidence_count" => 1,
             "model_blocked_count" => 1,
             "quality_gate_review_count" => 1,
             "schema_error_count" => 1,
             "branch_local_review_pressure" => true,
             "branch_local_blocking_pressure" => true,
             "branch_local_schema_pressure" => true
           } = CandidateRefresh.validation_safety_case_replay_summary(candidate_source)

    assert Enum.any?(
             urgent["risk_indicators"],
             &(&1["type"] == "validation_safety_case_pressure" and
                 &1["feedback_source"] ==
                   "candidate_source.validation_safety_case_replay_summary" and
                 &1["validation_safety_case_status"] == "blocked" and
                 &1["evidence_status"] == "blocked" and
                 &1["status_counts"] == %{
                   "accepted" => 1
                 } and
                 &1["evidence_refs"] == [
                   "model_acceptance_report.v1:row.blocked",
                   "quality_gate_report.v1:row.review"
                 ] and
                 &1["blocked_evidence_count"] == 1 and
                 &1["review_required_evidence_count"] == 1 and
                 &1["model_blocked_count"] == 1 and
                 &1["quality_gate_review_count"] == 1 and
                 &1["schema_error_count"] == 1)
           )

    assert_validation_refresh_pressure_score_terms(urgent, artifact, "validation_safety_case")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from mission-state freshness and refresh budget reports" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> put_in([:candidate_refresh_defaults, :candidate_limit_policy], %{
        max_candidate_activities: 1
      })
      |> Map.put(
        :source_freshness_report,
        freshness_report("stale")
        |> Map.put("provenance", %{"trust_boundary" => "mission_state_freshness_report"})
      )
      |> Map.put(
        :source_refresh_budget_report,
        refresh_budget_report()
        |> Map.put("provenance", %{"trust_boundary" => "mission_state_refresh_budget_report"})
      )

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    freshness_branch = branch(artifact, "derived_refresh_freshness_pressure_stale")

    assert %{
             "type" => "refresh_freshness_pressure",
             "freshness_status" => "stale",
             "accepted_snapshot_age_s" => 3600.0,
             "feedback_source" => "mission_state.source_freshness_report",
             "feedback_scope" => "refresh_freshness",
             "trust_boundary" => "mission_state_freshness_report"
           } = List.first(freshness_branch["events"])

    assert "mission_state.source_freshness_report" in get_in(
             freshness_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    budget_branch = branch(artifact, "derived_refresh_budget_pressure_limit_2")

    assert %{
             "type" => "refresh_budget_pressure",
             "input_candidate_count" => 2,
             "dropped_candidate_count" => 1,
             "current_max_candidate_activities" => 1,
             "relaxed_max_candidate_activities" => 2,
             "feedback_source" => "mission_state.source_refresh_budget_report",
             "feedback_scope" => "refresh_budget",
             "trust_boundary" => "mission_state_refresh_budget_report"
           } = List.first(budget_branch["events"])

    assert %{
             "schema_contract" => "refresh_budget_report.v1",
             "max_candidate_activities" => 2,
             "dropped_candidate_count" => 0,
             "kept_candidate_count" => 2
           } = budget_branch["repair_result"]["source_refresh_budget_report"]

    assert "mission_state.source_refresh_budget_report" in get_in(
             budget_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    assert_validation_refresh_pressure_score_terms(
      freshness_branch,
      artifact,
      "refresh_freshness"
    )

    assert_validation_refresh_pressure_score_terms(budget_branch, artifact, "refresh_budget")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from mission-state result artifact refresh-governance reports" do
    candidate_diff_report = %{
      "schema_contract" => "candidate_diff_report.v1",
      "model" => "candidate_id_set_diff_with_semantic_change_reasons",
      "prior_candidate_count" => 1,
      "refreshed_candidate_count" => 1,
      "retained_candidate_count" => 0,
      "new_candidate_count" => 1,
      "invalidated_candidate_count" => 1,
      "retained_candidates" => [],
      "new_candidates" => [],
      "invalidated_candidates" => [
        %{
          "id" => "dl_wrapper_stale",
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "invalidated_reason" => "replaced_by_semantically_similar_candidate",
          "replacement_candidate_id" => "dl_wrapper_replacement",
          "required_downlink_mb" => 150.0,
          "candidate_downlink_mb" => 210.0,
          "source_window_id" => "window:leo_1:ground_station_access:equator_prime:wrapper_stale",
          "replacement_source_window_id" =>
            "window:leo_1:ground_station_access:equator_prime:wrapper_replacement"
        }
      ]
    }

    mission_state =
      mission_state_with_refresh_inputs()
      |> put_in([:candidate_refresh_defaults, :candidate_limit_policy], %{
        max_candidate_activities: 1
      })
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "study_id" => "live_refresh_governance",
        "provenance" => %{"trust_boundary" => "mission_state_refresh_governance_wrapper"},
        "source_candidate_diff_report" => candidate_diff_report,
        "source_freshness_report" => freshness_report("stale"),
        "source_refresh_budget_report" => refresh_budget_report()
      })

    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          downlink("dl_wrapper_replacement", 500.0, 560.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    diff_branch = branch(artifact, "derived_candidate_diff_replacement_dl_wrapper_replacement")

    assert %{
             "type" => "candidate_diff_replacement",
             "replacement_candidate_id" => "dl_wrapper_replacement",
             "invalidated_candidate_id" => "dl_wrapper_stale",
             "feedback_source" =>
               "mission_state.source_result_artifact.source_candidate_diff_report.invalidated_candidates",
             "feedback_scope" => "candidate_diff",
             "trust_boundary" => "mission_state_refresh_governance_wrapper"
           } = List.first(diff_branch["events"])

    assert "mission_state.source_result_artifact.source_candidate_diff_report" in get_in(
             diff_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    assert_candidate_refresh_request_report_path(
      diff_branch,
      "mission_state.source_candidate_diff_report"
    )

    freshness_branch = branch(artifact, "derived_refresh_freshness_pressure_stale")

    assert %{
             "type" => "refresh_freshness_pressure",
             "freshness_status" => "stale",
             "feedback_source" => "mission_state.source_result_artifact.source_freshness_report",
             "feedback_scope" => "refresh_freshness",
             "trust_boundary" => "mission_state_refresh_governance_wrapper"
           } = List.first(freshness_branch["events"])

    assert "mission_state.source_result_artifact.source_freshness_report" in get_in(
             freshness_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    budget_branch = branch(artifact, "derived_refresh_budget_pressure_limit_2")

    assert %{
             "type" => "refresh_budget_pressure",
             "relaxed_max_candidate_activities" => 2,
             "feedback_source" =>
               "mission_state.source_result_artifact.source_refresh_budget_report",
             "feedback_scope" => "refresh_budget",
             "trust_boundary" => "mission_state_refresh_governance_wrapper"
           } = List.first(budget_branch["events"])

    assert "mission_state.source_result_artifact.source_refresh_budget_report" in get_in(
             budget_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp assert_candidate_refresh_request_report_path(branch, expected_path) do
    assert expected_path in get_in(branch, [
             "assumptions",
             "candidate_source",
             "candidate_refresh_request_source_report_input_paths"
           ])
  end

  defp refresh_budget_report do
    %{
      "schema_contract" => "refresh_budget_report.v1",
      "model" => "deterministic_candidate_limit_after_filters",
      "input_candidate_count" => 2,
      "kept_candidate_count" => 1,
      "dropped_candidate_count" => 1,
      "max_candidate_activities" => 1,
      "selection_order" => "score_descending_then_start_then_id",
      "kept_candidate_ids" => ["dl_refreshed"],
      "dropped_candidate_ids" => ["dl_deferred"],
      "assumptions" => %{
        "budget_stage" => "after_contact_resource_and_allocation_filters",
        "optimizer_search_performed" => false
      }
    }
  end

  defp freshness_report(status) do
    stale_reasons =
      if status == "stale",
        do: ["accepted_snapshot_older_than_policy"],
        else: []

    %{
      "schema_contract" => "freshness_report.v1",
      "model" => "accepted_snapshot_horizon_and_quality_freshness",
      "generated_at" => "2026-05-14T00:00:00Z",
      "accepted_at" => "2026-05-13T23:00:00Z",
      "current_epoch_s" => 165.0,
      "horizon_starts_at_s" => 165.0,
      "accepted_snapshot_age_s" => 3600.0,
      "horizon_start_offset_s" => 0.0,
      "max_snapshot_age_s" => 60.0,
      "max_horizon_start_offset_s" => 1.0,
      "status" => status,
      "stale_reasons" => stale_reasons,
      "unknown_reasons" => []
    }
  end

  defp assert_validation_refresh_pressure_score_terms(branch, artifact, feedback_scope) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    source_report_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &validation_refresh_source_report_pressure?(&1, feedback_scope)
      )

    scoped_pressure_count =
      Enum.count(branch["risk_indicators"], &(&1["feedback_scope"] == feedback_scope))

    scored_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &validation_refresh_scored_pressure?(&1, feedback_scope)
      )

    blended_validation_refresh_pressure_count =
      Enum.count(branch["risk_indicators"], &validation_refresh_pressure?/1)

    validation_refresh_family_pressure_count =
      Enum.count(branch["risk_indicators"], &validation_refresh_family_pressure?/1)

    pressure_term =
      if feedback_scope == "schema_validation" and scored_pressure_count == 0 and
           source_report_pressure_count > 0 do
        "validation_refresh_pressure_penalty"
      else
        validation_refresh_pressure_term(feedback_scope)
      end

    validation_refresh_pressure_count =
      if pressure_term == "validation_refresh_pressure_penalty" do
        blended_validation_refresh_pressure_count
      else
        scored_pressure_count
      end

    requested_validation_refresh_pressure_count =
      source_report_pressure_count + scoped_pressure_count

    assert requested_validation_refresh_pressure_count > 0
    assert validation_refresh_pressure_count > 0

    assert branch["score_terms"][pressure_term] ==
             -validation_refresh_pressure_count * risk_weight

    assert branch["score_terms"]["validation_refresh_pressure_penalty"] ==
             -blended_validation_refresh_pressure_count * risk_weight

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - validation_refresh_family_pressure_count) *
               risk_weight

    assert pressure_term in artifact["score_term_report"]["score_term_keys"]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == pressure_term and
                 &1["value"] < 0.0)
           )
  end

  defp validation_refresh_pressure_term("model_acceptance"),
    do: "model_acceptance_pressure_penalty"

  defp validation_refresh_pressure_term("validation_safety_case"),
    do: "validation_safety_case_pressure_penalty"

  defp validation_refresh_pressure_term("schema_validation"),
    do: "schema_validation_pressure_penalty"

  defp validation_refresh_pressure_term("refresh_budget"),
    do: "refresh_budget_pressure_penalty"

  defp validation_refresh_pressure_term("refresh_freshness"),
    do: "refresh_freshness_pressure_penalty"

  defp validation_refresh_pressure_term(_feedback_scope),
    do: "validation_refresh_pressure_penalty"

  defp validation_refresh_scored_pressure?(risk, "model_acceptance"),
    do:
      risk["feedback_scope"] == "model_acceptance" or risk["type"] == "model_acceptance_pressure"

  defp validation_refresh_scored_pressure?(risk, "validation_safety_case"),
    do:
      risk["feedback_scope"] == "validation_safety_case" or
        risk["type"] == "validation_safety_case_pressure"

  defp validation_refresh_scored_pressure?(risk, "schema_validation"),
    do:
      risk["feedback_scope"] == "schema_validation" or
        risk["type"] == "schema_validation_pressure"

  defp validation_refresh_scored_pressure?(risk, "refresh_budget"),
    do: risk["feedback_scope"] == "refresh_budget" or risk["type"] == "refresh_budget_pressure"

  defp validation_refresh_scored_pressure?(risk, "refresh_freshness"),
    do:
      risk["feedback_scope"] == "refresh_freshness" or
        risk["type"] == "refresh_freshness_pressure"

  defp validation_refresh_scored_pressure?(risk, _feedback_scope),
    do: validation_refresh_pressure?(risk)

  defp validation_refresh_family_pressure?(risk) do
    validation_refresh_pressure?(risk) or
      validation_refresh_scored_pressure?(risk, "model_acceptance") or
      validation_refresh_scored_pressure?(risk, "validation_safety_case") or
      validation_refresh_scored_pressure?(risk, "schema_validation") or
      validation_refresh_scored_pressure?(risk, "refresh_budget") or
      validation_refresh_scored_pressure?(risk, "refresh_freshness")
  end

  defp validation_refresh_pressure?(risk) do
    validation_refresh_source_report_pressure?(risk, "schema_validation")
  end

  defp validation_refresh_source_report_pressure?(risk, "schema_validation"),
    do: schema_validation_source_report_pressure?(risk)

  defp validation_refresh_source_report_pressure?(_risk, _feedback_scope), do: false

  defp schema_validation_source_report_pressure?(%{"type" => "quality_gate_pressure"} = risk) do
    risk["schema_validation_import_blocked"] == true or
      is_map(risk["schema_validation_status_counts"]) or
      risk["failed_schema_validation_quality_gate_row_ids"] not in [nil, []]
  end

  defp schema_validation_source_report_pressure?(
         %{"type" => "operational_readiness_pressure"} = risk
       ) do
    risk["schema_validation_import_blocked"] == true or
      risk["schema_validation_row_count"] not in [nil, 0] or
      risk["schema_validation_fail_count"] not in [nil, 0] or
      risk["schema_validation_error_count"] not in [nil, 0] or
      risk["schema_validation_warning_count"] not in [nil, 0] or
      risk["schema_validation_remediation_count"] not in [nil, 0] or
      is_map(risk["schema_validation_status_counts"]) or
      risk["failed_schema_validation_quality_gate_row_ids"] not in [nil, []]
  end

  defp schema_validation_source_report_pressure?(_risk), do: false
end
