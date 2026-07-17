defmodule OrbitalDynamics.Validation.SafetyCaseEvidenceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema, Validation}

  test "summarizes validation safety-case evidence without granting authority" do
    model_acceptance_report =
      Validation.model_acceptance_report(
        [
          "orbit_data.simple_json",
          "event.access_windows",
          "propagator.two_body",
          "missing.model"
        ],
        intended_use: :operational_import
      )

    operational_readiness_report = %{
      "schema_contract" => "operational_readiness_report.v1",
      "status" => "review_required",
      "readiness_level" => "operator_review",
      "import_classification" => "review_only",
      "review_gate_count" => 1,
      "blocked_gate_count" => 0,
      "evidence" => %{
        "ready_for_import_count" => 0,
        "review_required_count" => 1
      }
    }

    quality_gate_report = %{
      "schema_contract" => "quality_gate_report.v1",
      "status" => "review_required",
      "readiness_level" => "operator_review",
      "import_classification" => "review_only",
      "review_gate_count" => 1,
      "analysis_gate_count" => 0,
      "blocked_gate_count" => 0
    }

    schema_validation_report = %{
      "schema_contract" => "schema_validation_report.v1",
      "status" => "fail",
      "validated_contract" => "candidate_refresh.v1",
      "error_count" => 1,
      "warning_count" => 2
    }

    schema_validation_batch_report = %{
      "schema_contract" => "schema_validation_batch_report.v1",
      "status" => "fail",
      "validation_mode" => "artifact_directory",
      "error_count" => 1,
      "warning_count" => 1,
      "reports" => [
        %{
          "path" => "study_results/good.json",
          "report" => %{"schema_contract" => "schema_validation_report.v1", "status" => "pass"}
        },
        %{
          "path" => "study_results/bad.json",
          "report" => %{"schema_contract" => "schema_validation_report.v1", "status" => "fail"}
        }
      ]
    }

    fixture_report = %{
      "schema_contract" => "validation_reference_fixture_report.v1",
      "status" => "fail",
      "fixture_count" => 2,
      "reports" => [
        %{"fixture_id" => "fixture.pass", "status" => "pass"},
        %{"fixture_id" => "fixture.fail", "status" => "fail"}
      ]
    }

    assert %{
             "schema_contract" => "validation_safety_case_summary.v1",
             "schema_version" => 1,
             "model" => "artifact_only_validation_safety_case_summary",
             "source" => "validation.safety_case_evidence",
             "summary_id" => "validation_safety_case:case:refresh-import",
             "case_id" => "case:refresh-import",
             "status" => "blocked",
             "evidence_count" => 6,
             "input_contracts" => [
               "model_acceptance_report.v1",
               "operational_readiness_report.v1",
               "quality_gate_report.v1",
               "schema_validation_batch_report.v1",
               "schema_validation_report.v1",
               "validation_reference_fixture_report.v1"
             ],
             "evidence_status_counts" => %{
               "blocked" => 4,
               "review_required" => 2
             },
             "evidence_refs_by_status" => %{
               "blocked" => [
                 "model_acceptance_report.v1:model_acceptance:operational_import:orbit_data.simple_json__event.access_windows__propagator.two_body__missing.model",
                 "schema_validation_report.v1:candidate_refresh.v1",
                 "schema_validation_batch_report.v1:artifact_directory",
                 "validation_reference_fixture_report.v1:6"
               ],
               "review_required" => [
                 "operational_readiness_report.v1:2",
                 "quality_gate_report.v1:3"
               ]
             },
             "evidence_refs_by_contract" => %{
               "model_acceptance_report.v1" => [
                 "model_acceptance_report.v1:model_acceptance:operational_import:orbit_data.simple_json__event.access_windows__propagator.two_body__missing.model"
               ],
               "operational_readiness_report.v1" => ["operational_readiness_report.v1:2"],
               "quality_gate_report.v1" => ["quality_gate_report.v1:3"],
               "schema_validation_batch_report.v1" => [
                 "schema_validation_batch_report.v1:artifact_directory"
               ],
               "schema_validation_report.v1" => [
                 "schema_validation_report.v1:candidate_refresh.v1"
               ],
               "validation_reference_fixture_report.v1" => [
                 "validation_reference_fixture_report.v1:6"
               ]
             },
             "blocked_evidence_count" => 4,
             "review_required_evidence_count" => 2,
             "model_accepted_count" => 1,
             "model_review_required_count" => 1,
             "model_blocked_count" => 2,
             "unknown_model_count" => 1,
             "readiness_review_required_count" => 2,
             "readiness_blocked_count" => 0,
             "ready_for_import_count" => 0,
             "quality_gate_review_count" => 1,
             "quality_gate_blocked_count" => 0,
             "schema_error_count" => 2,
             "schema_warning_count" => 3,
             "schema_validation_report_count" => 2,
             "schema_validation_failed_report_count" => 1,
             "fixture_passed_count" => 1,
             "fixture_failed_count" => 1,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_cadence_write",
               "certification_authority" => "not_granted_by_summary",
               "operator_authority" => "not_granted_by_summary"
             }
           } =
             safety_case_summary =
             Validation.safety_case_summary(
               [
                 model_acceptance_report,
                 operational_readiness_report,
                 quality_gate_report,
                 schema_validation_report,
                 schema_validation_batch_report,
                 fixture_report
               ],
               case_id: "case:refresh-import"
             )

    assert {:ok, %{"schema_contract" => "validation_safety_case_summary.v1"}} =
             Schema.validate_artifact(safety_case_summary,
               schema_contract: "validation_safety_case_summary.v1"
             )

    assert {:ok, safety_case_schema} =
             Schema.json_schema("validation_safety_case_summary.v1")

    assert get_in(safety_case_schema, ["properties", "model", "const"]) ==
             "artifact_only_validation_safety_case_summary"

    model_evidence_index =
      Enum.find_index(
        safety_case_summary["evidence"],
        &(&1["schema_contract"] == "model_acceptance_report.v1")
      )

    assert %{
             "status_counts" => %{
               "accepted" => 1,
               "blocked" => 2,
               "review_required" => 1
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
             }
           } = Enum.at(safety_case_summary["evidence"], model_evidence_index)

    stale_model_status_counts =
      put_in(
        safety_case_summary,
        ["evidence", Access.at(model_evidence_index), "status_counts", "blocked"],
        1
      )

    assert {:error, stale_model_status_counts_report} =
             Schema.validate_artifact(stale_model_status_counts,
               schema_contract: "validation_safety_case_summary.v1"
             )

    assert Enum.any?(
             stale_model_status_counts_report["errors"],
             &(&1["path"] == "$.evidence[#{model_evidence_index}].status_counts")
           )

    readiness_evidence_index =
      Enum.find_index(
        safety_case_summary["evidence"],
        &(&1["schema_contract"] == "operational_readiness_report.v1")
      )

    assert is_integer(readiness_evidence_index)

    readiness_review_count =
      safety_case_summary["evidence"]
      |> Enum.at(readiness_evidence_index)
      |> Map.fetch!("readiness_review_required_count")

    stale_readiness_evidence =
      safety_case_summary
      |> put_in(
        ["evidence", Access.at(readiness_evidence_index), "readiness_review_required_count"],
        0
      )
      |> Map.put(
        "readiness_review_required_count",
        Map.fetch!(safety_case_summary, "readiness_review_required_count") -
          readiness_review_count
      )

    assert {:error, stale_readiness_evidence_report} =
             Schema.validate_artifact(stale_readiness_evidence,
               schema_contract: "validation_safety_case_summary.v1"
             )

    assert Enum.any?(
             stale_readiness_evidence_report["errors"],
             &(&1["path"] == "$.evidence[#{readiness_evidence_index}].status" and
                 &1["message"] == "must match operational-readiness evidence counts")
           )

    quality_gate_evidence_index =
      Enum.find_index(
        safety_case_summary["evidence"],
        &(&1["schema_contract"] == "quality_gate_report.v1")
      )

    assert is_integer(quality_gate_evidence_index)

    quality_gate_review_count =
      safety_case_summary["evidence"]
      |> Enum.at(quality_gate_evidence_index)
      |> Map.fetch!("quality_gate_review_count")

    stale_quality_gate_evidence =
      safety_case_summary
      |> put_in(
        ["evidence", Access.at(quality_gate_evidence_index), "quality_gate_review_count"],
        0
      )
      |> Map.put(
        "quality_gate_review_count",
        Map.fetch!(safety_case_summary, "quality_gate_review_count") - quality_gate_review_count
      )

    assert {:error, stale_quality_gate_evidence_report} =
             Schema.validate_artifact(stale_quality_gate_evidence,
               schema_contract: "validation_safety_case_summary.v1"
             )

    assert Enum.any?(
             stale_quality_gate_evidence_report["errors"],
             &(&1["path"] == "$.evidence[#{quality_gate_evidence_index}].status" and
                 &1["message"] == "must match quality-gate evidence counts")
           )

    fixture_evidence_index =
      Enum.find_index(
        safety_case_summary["evidence"],
        &(&1["schema_contract"] == "validation_reference_fixture_report.v1")
      )

    assert is_integer(fixture_evidence_index)

    stale_fixture_evidence =
      safety_case_summary
      |> put_in(["evidence", Access.at(fixture_evidence_index), "fixture_failed_count"], 0)
      |> Map.put("fixture_failed_count", 0)

    assert {:error, stale_fixture_evidence_report} =
             Schema.validate_artifact(stale_fixture_evidence,
               schema_contract: "validation_safety_case_summary.v1"
             )

    assert Enum.any?(
             stale_fixture_evidence_report["errors"],
             &(&1["path"] == "$.evidence[#{fixture_evidence_index}].status" and
                 &1["message"] == "must match validation-fixture evidence counts")
           )

    operator_handoff = %{
      "schema_contract" => "operator_review_package.v1",
      "rows" => [
        %{
          "row_type" => "schema_validation_batch",
          "source_schema_validation_batch_report" => schema_validation_batch_report
        }
      ]
    }

    cadence_handoff = %{
      "schema_contract" => "cadence_import_manifest.v1",
      "rows" => [
        %{
          "row_type" => "validation_reference_fixture",
          "source_review_row" => %{
            "source_validation_reference_fixture_report" => fixture_report
          }
        }
      ]
    }

    assert %{
             "status" => "blocked",
             "evidence_count" => 4,
             "input_contracts" => [
               "cadence_import_manifest.v1",
               "operator_review_package.v1",
               "schema_validation_batch_report.v1",
               "validation_reference_fixture_report.v1"
             ],
             "evidence_status_counts" => %{
               "blocked" => 2,
               "review_required" => 2
             },
             "schema_error_count" => 1,
             "schema_warning_count" => 1,
             "schema_validation_report_count" => 2,
             "schema_validation_failed_report_count" => 1,
             "fixture_passed_count" => 1,
             "fixture_failed_count" => 1,
             "evidence_refs_by_contract" => %{
               "cadence_import_manifest.v1" => ["cadence_import_manifest.v1:3"],
               "operator_review_package.v1" => ["operator_review_package.v1:1"],
               "schema_validation_batch_report.v1" => [
                 "schema_validation_batch_report.v1:artifact_directory"
               ],
               "validation_reference_fixture_report.v1" => [
                 "validation_reference_fixture_report.v1:4"
               ]
             }
           } =
             handoff_summary =
             Validation.safety_case_summary([operator_handoff, cadence_handoff],
               case_id: "case:review-import-handoff"
             )

    assert {:ok, %{"schema_contract" => "validation_safety_case_summary.v1"}} =
             Schema.validate_artifact(handoff_summary,
               schema_contract: "validation_safety_case_summary.v1"
             )

    stale_handoff_input_contracts =
      Map.put(handoff_summary, "input_contracts", [
        "schema_validation_batch_report.v1",
        "validation_reference_fixture_report.v1"
      ])

    assert {:error, stale_handoff_input_contracts_report} =
             Schema.validate_artifact(stale_handoff_input_contracts,
               schema_contract: "validation_safety_case_summary.v1"
             )

    assert Enum.any?(
             stale_handoff_input_contracts_report["errors"],
             &(&1["path"] == "$.input_contracts")
           )

    stale_handoff_refs_by_contract =
      put_in(handoff_summary, ["evidence_refs_by_contract", "operator_review_package.v1"], [])

    assert {:error, stale_handoff_refs_by_contract_report} =
             Schema.validate_artifact(stale_handoff_refs_by_contract,
               schema_contract: "validation_safety_case_summary.v1"
             )

    assert Enum.any?(
             stale_handoff_refs_by_contract_report["errors"],
             &(&1["path"] == "$.evidence_refs_by_contract")
           )

    stale_summary = Map.put(safety_case_summary, "blocked_evidence_count", 99)

    assert {:error, validation_report} =
             Schema.validate_artifact(stale_summary,
               schema_contract: "validation_safety_case_summary.v1"
             )

    assert Enum.any?(validation_report["errors"], &(&1["path"] == "$.blocked_evidence_count"))

    stale_status_counts =
      put_in(safety_case_summary, ["evidence_status_counts", "blocked"], 99)

    assert {:error, stale_status_counts_report} =
             Schema.validate_artifact(stale_status_counts,
               schema_contract: "validation_safety_case_summary.v1"
             )

    assert Enum.any?(
             stale_status_counts_report["errors"],
             &(&1["path"] == "$.evidence_status_counts")
           )

    stale_refs_by_status =
      put_in(safety_case_summary, ["evidence_refs_by_status", "review_required"], [])

    assert {:error, stale_refs_by_status_report} =
             Schema.validate_artifact(stale_refs_by_status,
               schema_contract: "validation_safety_case_summary.v1"
             )

    assert Enum.any?(
             stale_refs_by_status_report["errors"],
             &(&1["path"] == "$.evidence_refs_by_status")
           )

    stale_refs_by_contract =
      put_in(safety_case_summary, ["evidence_refs_by_contract", "quality_gate_report.v1"], [])

    assert {:error, stale_refs_by_contract_report} =
             Schema.validate_artifact(stale_refs_by_contract,
               schema_contract: "validation_safety_case_summary.v1"
             )

    assert Enum.any?(
             stale_refs_by_contract_report["errors"],
             &(&1["path"] == "$.evidence_refs_by_contract")
           )

    assert %{"status" => "missing_evidence", "evidence_count" => 0} =
             empty_summary =
             Validation.safety_case_summary([])

    refute Map.has_key?(empty_summary, "evidence_refs_by_status")

    assert {:ok, %{"schema_contract" => "validation_safety_case_summary.v1"}} =
             Schema.validate_artifact(empty_summary,
               schema_contract: "validation_safety_case_summary.v1"
             )

    capabilities = Validation.capabilities()

    assert :validation_safety_case_evidence_status_counts in capabilities.summary_semantics
    assert :validation_safety_case_evidence_refs_by_status in capabilities.summary_semantics
    assert :validation_safety_case_evidence_refs_by_contract in capabilities.summary_semantics

    assert :validation_safety_case_model_count_rollups in capabilities.safety_case_evidence_semantics

    assert :validation_safety_case_model_acceptance_row_status_floor in capabilities.safety_case_evidence_semantics

    assert :validation_safety_case_readiness_count_rollups in capabilities.safety_case_evidence_semantics

    assert :validation_safety_case_readiness_gate_status_floor in capabilities.safety_case_evidence_semantics

    assert :validation_safety_case_quality_gate_count_rollups in capabilities.safety_case_evidence_semantics

    assert :validation_safety_case_quality_gate_row_status_floor in capabilities.safety_case_evidence_semantics

    assert :validation_safety_case_schema_validation_count_rollups in capabilities.safety_case_evidence_semantics

    assert :validation_safety_case_schema_validation_issue_list_floor in capabilities.safety_case_evidence_semantics

    assert :validation_safety_case_schema_validation_batch_nested_status_floor in capabilities.safety_case_evidence_semantics

    assert :validation_safety_case_fixture_count_rollups in capabilities.safety_case_evidence_semantics

    assert :validation_safety_case_fixture_nested_status_floor in capabilities.safety_case_evidence_semantics

    assert :validation_safety_case_review_import_handoff_evidence in capabilities.safety_case_evidence_semantics
  end

  test "derives safety-case model-acceptance evidence from rows when top-level counts are stale" do
    stale_top_level_model_acceptance = %{
      "schema_contract" => "model_acceptance_report.v1",
      "report_id" => "model_acceptance:operational_import:stale_top_level",
      "intended_use" => "operational_import",
      "status" => "accepted_for_use",
      "accepted_count" => 3,
      "review_required_count" => 0,
      "blocked_count" => 0,
      "unknown_model_count" => 0,
      "status_counts" => %{"accepted" => 3},
      "model_ids_by_status" => %{
        "accepted" => ["model.accepted", "model.review", "model.blocked"]
      },
      "model_ids_by_validation_level" => %{"artifact_contract" => ["model.accepted"]},
      "model_ids_by_intended_use" => %{
        "operational_import" => ["model.accepted", "model.review", "model.blocked"]
      },
      "rows" => [
        %{
          "model_id" => "model.review",
          "status" => "review_required",
          "validation_level" => "analysis"
        },
        %{
          "model_id" => "model.blocked",
          "status" => "blocked",
          "validation_level" => "unknown"
        }
      ]
    }

    assert %{
             "status" => "blocked",
             "model_accepted_count" => 0,
             "model_review_required_count" => 1,
             "model_blocked_count" => 1,
             "unknown_model_count" => 1,
             "evidence_status_counts" => %{"blocked" => 1},
             "evidence" => [
               %{
                 "schema_contract" => "model_acceptance_report.v1",
                 "status" => "blocked",
                 "status_counts" => %{"blocked" => 1, "review_required" => 1},
                 "model_ids_by_status" => %{
                   "blocked" => ["model.blocked"],
                   "review_required" => ["model.review"]
                 },
                 "model_ids_by_validation_level" => %{
                   "analysis" => ["model.review"],
                   "unknown" => ["model.blocked"]
                 },
                 "model_ids_by_intended_use" => %{
                   "operational_import" => ["model.review", "model.blocked"]
                 }
               }
             ]
           } =
             safety_case_summary =
             Validation.safety_case_summary(stale_top_level_model_acceptance)

    assert {:ok, %{"schema_contract" => "validation_safety_case_summary.v1"}} =
             Schema.validate_artifact(safety_case_summary,
               schema_contract: "validation_safety_case_summary.v1"
             )
  end

  test "derives safety-case readiness evidence from gates when top-level counts are stale" do
    stale_top_level_readiness = %{
      "schema_contract" => "operational_readiness_report.v1",
      "report_id" => "operational_readiness:stale_top_level",
      "readiness_level" => "import_eligible",
      "import_classification" => "importable",
      "status" => "ready",
      "review_gate_count" => 0,
      "analysis_gate_count" => 0,
      "blocked_gate_count" => 0,
      "evidence" => %{"ready_for_import_count" => 9},
      "gates" => [
        %{"id" => "operator_review", "status" => "review_required"},
        %{"id" => "cadence_import", "status" => "blocked", "ready_for_import_count" => 1}
      ]
    }

    assert %{
             "status" => "blocked",
             "readiness_review_required_count" => 1,
             "readiness_blocked_count" => 1,
             "ready_for_import_count" => 1,
             "evidence_status_counts" => %{"blocked" => 1},
             "evidence_refs_by_status" => %{
               "blocked" => [
                 "operational_readiness_report.v1:operational_readiness:stale_top_level"
               ]
             },
             "evidence" => [
               %{
                 "schema_contract" => "operational_readiness_report.v1",
                 "status" => "blocked",
                 "readiness_review_required_count" => 1,
                 "readiness_blocked_count" => 1,
                 "ready_for_import_count" => 1
               }
             ]
           } =
             safety_case_summary = Validation.safety_case_summary(stale_top_level_readiness)

    assert {:ok, %{"schema_contract" => "validation_safety_case_summary.v1"}} =
             Schema.validate_artifact(safety_case_summary,
               schema_contract: "validation_safety_case_summary.v1"
             )
  end

  test "derives safety-case quality-gate evidence from rows when top-level counts are stale" do
    stale_top_level_quality_gate = %{
      "schema_contract" => "quality_gate_report.v1",
      "report_id" => "quality_gate:stale_top_level",
      "source_readiness_report_id" => "operational_readiness:stale_top_level",
      "readiness_level" => "import_eligible",
      "import_classification" => "importable",
      "status" => "passed",
      "review_gate_count" => 0,
      "analysis_gate_count" => 0,
      "blocked_gate_count" => 0,
      "rows" => [
        %{"id" => "schema_validation", "status" => "review_required"},
        %{"id" => "cadence_import", "status" => "blocked"}
      ]
    }

    assert %{
             "status" => "blocked",
             "quality_gate_review_count" => 1,
             "quality_gate_blocked_count" => 1,
             "evidence_status_counts" => %{"blocked" => 1},
             "evidence_refs_by_status" => %{
               "blocked" => ["quality_gate_report.v1:quality_gate:stale_top_level"]
             },
             "evidence" => [
               %{
                 "schema_contract" => "quality_gate_report.v1",
                 "status" => "blocked",
                 "quality_gate_review_count" => 1,
                 "quality_gate_blocked_count" => 1
               }
             ]
           } =
             safety_case_summary = Validation.safety_case_summary(stale_top_level_quality_gate)

    assert {:ok, %{"schema_contract" => "validation_safety_case_summary.v1"}} =
             Schema.validate_artifact(safety_case_summary,
               schema_contract: "validation_safety_case_summary.v1"
             )
  end

  test "derives safety-case schema-validation evidence from issue lists when top-level counts are stale" do
    stale_top_level_schema_validation = %{
      "schema_contract" => "schema_validation_report.v1",
      "status" => "pass",
      "artifact_path" => "study_results/stale_schema.json",
      "validated_contract" => "candidate_refresh.v1",
      "error_count" => 0,
      "warning_count" => 0,
      "errors" => [
        %{"severity" => "error", "path" => "$.schema_contract", "message" => "forced error"}
      ],
      "warnings" => [
        %{"severity" => "warning", "path" => "$.model_limits", "message" => "forced warning"}
      ]
    }

    assert %{
             "status" => "blocked",
             "schema_error_count" => 1,
             "schema_warning_count" => 1,
             "evidence_status_counts" => %{"blocked" => 1},
             "evidence_refs_by_status" => %{
               "blocked" => ["schema_validation_report.v1:study_results_stale_schema.json"]
             },
             "evidence" => [
               %{
                 "schema_contract" => "schema_validation_report.v1",
                 "status" => "blocked",
                 "schema_error_count" => 1,
                 "schema_warning_count" => 1
               }
             ]
           } =
             safety_case_summary =
             Validation.safety_case_summary(stale_top_level_schema_validation)

    assert {:ok, %{"schema_contract" => "validation_safety_case_summary.v1"}} =
             Schema.validate_artifact(safety_case_summary,
               schema_contract: "validation_safety_case_summary.v1"
             )
  end

  test "discovers nested schema-validation batch evidence in safety-case inputs" do
    wrapper = %{
      "schema_validation_batch_report" => %{
        "schema_contract" => "schema_validation_batch_report.v1",
        "status" => "fail",
        "validation_mode" => "artifact_directory",
        "input_dir" => "study_results",
        "error_count" => 2,
        "warning_count" => 1,
        "reports" => [
          %{
            "path" => "study_results/bad.json",
            "report" => %{"schema_contract" => "schema_validation_report.v1", "status" => "fail"}
          }
        ]
      },
      "source_schema_validation_batch_report" => %{
        "schema_contract" => "schema_validation_batch_report.v1",
        "status" => "pass",
        "validation_mode" => "source_artifacts",
        "error_count" => 0,
        "warning_count" => 0,
        "reports" => [
          %{
            "path" => "source/good.json",
            "report" => %{"schema_contract" => "schema_validation_report.v1", "status" => "pass"}
          }
        ]
      }
    }

    assert %{
             "status" => "blocked",
             "evidence_count" => 2,
             "schema_error_count" => 2,
             "schema_warning_count" => 1,
             "schema_validation_report_count" => 2,
             "schema_validation_failed_report_count" => 1,
             "evidence_refs_by_status" => %{
               "accepted_for_use" => [
                 "schema_validation_batch_report.v1:source_artifacts"
               ],
               "blocked" => [
                 "schema_validation_batch_report.v1:study_results"
               ]
             },
             "evidence_refs_by_contract" => %{
               "schema_validation_batch_report.v1" => [
                 "schema_validation_batch_report.v1:study_results",
                 "schema_validation_batch_report.v1:source_artifacts"
               ]
             }
           } = Validation.safety_case_summary(wrapper)

    stale_top_level_batch = %{
      "schema_contract" => "schema_validation_batch_report.v1",
      "status" => "pass",
      "validation_mode" => "artifact_directory",
      "input_dir" => "study_results",
      "error_count" => 0,
      "warning_count" => 0,
      "reports" => [
        %{
          "path" => "study_results/bad.json",
          "report" => %{
            "schema_contract" => "schema_validation_report.v1",
            "status" => "fail",
            "error_count" => 1
          }
        },
        %{
          "path" => "study_results/error.json",
          "report" => %{
            "schema_contract" => "schema_validation_report.v1",
            "status" => "error",
            "error_count" => 1
          }
        }
      ]
    }

    assert %{
             "status" => "blocked",
             "evidence_status_counts" => %{"blocked" => 1},
             "schema_validation_failed_report_count" => 2,
             "evidence" => [
               %{
                 "schema_contract" => "schema_validation_batch_report.v1",
                 "status" => "blocked",
                 "schema_validation_failed_report_count" => 2
               }
             ]
           } = stale_batch_summary = Validation.safety_case_summary(stale_top_level_batch)

    assert {:ok, %{"schema_contract" => "validation_safety_case_summary.v1"}} =
             Schema.validate_artifact(stale_batch_summary,
               schema_contract: "validation_safety_case_summary.v1"
             )

    stale_batch_evidence =
      stale_batch_summary
      |> put_in(["evidence", Access.at(0), "schema_validation_failed_report_count"], 0)
      |> Map.put("schema_validation_failed_report_count", 0)

    assert {:error, stale_batch_evidence_report} =
             Schema.validate_artifact(stale_batch_evidence,
               schema_contract: "validation_safety_case_summary.v1"
             )

    assert Enum.any?(
             stale_batch_evidence_report["errors"],
             &(&1["path"] == "$.evidence[0].status" and
                 &1["message"] == "must match schema-validation batch evidence counts")
           )
  end

  test "blocks safety-case fixture evidence from nested failed fixture reports" do
    stale_top_level_fixture_report = %{
      "schema_contract" => "validation_reference_fixture_report.v1",
      "status" => "pass",
      "report_id" => "validation_fixture_stale_status",
      "fixture_count" => 2,
      "status_counts" => %{"pass" => 2},
      "reports" => [
        %{
          "schema_contract" => "validation_reference_report.v1",
          "fixture_id" => "fixture.artifact.schema_validation_report.v1",
          "model_id" => "artifact.schema_validation_report.v1",
          "validation_level" => "artifact_contract",
          "status" => "fail",
          "status_counts" => %{"fail" => 1},
          "checks" => [
            %{
              "field" => "status",
              "status" => "fail",
              "expected" => "pass",
              "observed" => "fail",
              "tolerance" => 0.0
            }
          ]
        },
        %{
          "schema_contract" => "validation_reference_report.v1",
          "fixture_id" => "fixture.artifact.validation_check.v1",
          "model_id" => "artifact.validation_check.v1",
          "validation_level" => "artifact_contract",
          "status" => "pass",
          "status_counts" => %{"pass" => 1},
          "checks" => [
            %{
              "field" => "status",
              "status" => "pass",
              "expected" => "pass",
              "observed" => "pass",
              "tolerance" => 0.0
            }
          ]
        }
      ]
    }

    assert %{
             "status" => "blocked",
             "fixture_passed_count" => 1,
             "fixture_failed_count" => 1,
             "evidence_status_counts" => %{"blocked" => 1},
             "evidence_refs_by_status" => %{
               "blocked" => [
                 "validation_reference_fixture_report.v1:validation_fixture_stale_status"
               ]
             },
             "evidence" => [
               %{
                 "schema_contract" => "validation_reference_fixture_report.v1",
                 "status" => "blocked",
                 "fixture_passed_count" => 1,
                 "fixture_failed_count" => 1
               }
             ]
           } =
             safety_case_summary = Validation.safety_case_summary(stale_top_level_fixture_report)

    assert {:ok, %{"schema_contract" => "validation_safety_case_summary.v1"}} =
             Schema.validate_artifact(safety_case_summary,
               schema_contract: "validation_safety_case_summary.v1"
             )
  end

  test "discovers schema-validation evidence preserved in review and import containers" do
    schema_validation_report = %{
      "schema_contract" => "schema_validation_report.v1",
      "validation_mode" => "artifact_file",
      "validated_contract" => "candidate_refresh.v1",
      "status" => "fail",
      "error_count" => 1,
      "warning_count" => 0,
      "errors" => [
        %{
          "severity" => "error",
          "path" => "$.targets",
          "message" => "must include at least one target"
        }
      ],
      "warnings" => [],
      "remediation_count" => 1,
      "remediation" => [
        %{
          "path" => "$.targets",
          "category" => "missing_required_field",
          "action" => "Populate this required field"
        }
      ]
    }

    wrapper = %{
      "source_operator_review_package" =>
        OperatorReview.from_schema_validation_report(schema_validation_report),
      "source_cadence_import_manifest" =>
        CadenceImport.from_schema_validation_report(schema_validation_report)
    }

    assert %{
             "status" => "blocked",
             "evidence_count" => 2,
             "schema_error_count" => 2,
             "schema_warning_count" => 0,
             "evidence_refs_by_contract" => %{
               "schema_validation_report.v1" => [
                 "schema_validation_report.v1:candidate_refresh.v1",
                 "schema_validation_report.v1:candidate_refresh.v1"
               ]
             }
           } = safety_case_summary = Validation.safety_case_summary(wrapper)

    assert {:ok, %{"schema_contract" => "validation_safety_case_summary.v1"}} =
             Schema.validate_artifact(safety_case_summary,
               schema_contract: "validation_safety_case_summary.v1"
             )
  end
end
