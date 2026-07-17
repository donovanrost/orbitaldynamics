defmodule OrbitalDynamics.ValidationTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Communications.{ContactContention, StationCalendar}
  alias OrbitalDynamics.Propagators.{J2, TwoBody, TwoBodyNxCompiled}

  alias OrbitalDynamics.{
    CadenceImport,
    CandidateRefresh,
    Environment,
    ResultSet,
    ResourceFilter,
    ResourceProjection,
    Schema,
    Timeline,
    OperatorReview,
    OperationalReadiness,
    Validation
  }

  alias OrbitalDynamics.ResultSet.Artifact

  import OrbitalDynamics.Validation.OrbitalReferenceFixtures,
    only: [
      access_fixture_observations: 0,
      eclipse_fixture_observations: 0,
      ground_track_crossing_fixture_observations: 0,
      j2_fixture_observations: 0,
      target_visibility_fixture_observations: 0,
      two_body_fixture_observations: 0
    ]

  test "fetches validation records by model id and implementation module" do
    assert {:ok, %{"validation_level" => "educational", "model" => "point_mass_two_body"}} =
             Validation.record("propagator.two_body")

    assert {:ok, %{"id" => "propagator.j2", "validation_level" => "educational"}} =
             Validation.record(J2)

    assert {:ok, %{"validation_level" => "educational"}} = Validation.record(TwoBodyNxCompiled)
  end

  test "public facades expose validation records policies and fixture verification" do
    assert OrbitalDynamics.validation_registry() == Validation.registry()

    assert OrbitalDynamics.validation_record("propagator.two_body") ==
             Validation.record("propagator.two_body")

    assert OrbitalDynamics.validation_tolerance_policy() == Validation.tolerance_policy()

    assert OrbitalDynamics.validation_model_acceptance_report(["event.access_windows"]) ==
             Validation.model_acceptance_report(["event.access_windows"])

    assert OrbitalDynamics.validation_safety_case_summary([]) ==
             Validation.safety_case_summary([])

    assert OrbitalDynamics.validation_schema_migration_report() ==
             Validation.schema_migration_report()

    schema_migration_opts = [
      deprecated_contracts: %{"campaign_plan.v1" => "campaign_strategy.v3"},
      future_contracts: [
        %{
          schema_contract: "campaign_plan.v2",
          artifact_family: "campaign_plan",
          schema_version: 2,
          replacement_contract: "campaign_strategy.v3",
          required_field_count: 12,
          optional_field_count: 3,
          nested_contract_count: 4
        }
      ]
    ]

    schema_migration_report =
      OrbitalDynamics.validation_schema_migration_report(schema_migration_opts)

    assert schema_migration_report == Validation.schema_migration_report(schema_migration_opts)

    assert %{
             "status" => "review_required",
             "deprecated_contract_count" => 1,
             "future_contract_count" => 1,
             "status_counts" => %{"current" => 120, "deprecated" => 1, "future" => 1},
             "migration_action_counts" => %{
               "continue_current_contract" => 120,
               "plan_replacement" => 1,
               "prepare_future_contract" => 1
             }
           } = schema_migration_report

    schema_migration_capabilities = Validation.capabilities()

    assert schema_migration_capabilities.schema_migration_actions == [
             "continue_current_contract",
             "plan_replacement",
             "prepare_future_contract",
             "review_deprecated_contract"
           ]

    assert Map.keys(schema_migration_report["migration_action_counts"]) --
             schema_migration_capabilities.schema_migration_actions == []

    assert OrbitalDynamics.backend_acceptance_policy() == Validation.backend_acceptance_policy()

    assert OrbitalDynamics.backend_acceptance_evidence(TwoBody) ==
             Validation.backend_acceptance_evidence(TwoBody)

    assert OrbitalDynamics.dependency_policy() == Validation.dependency_policy()
    assert OrbitalDynamics.validation_reference_fixtures() == Validation.reference_fixtures()

    fixture_id = "fixture.two_body.circular_leo_600s"

    assert OrbitalDynamics.validation_reference_fixture(fixture_id) ==
             Validation.reference_fixture(fixture_id)

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert OrbitalDynamics.verify_validation_reference_fixture(fixture_id, fixture["expected"]) ==
             Validation.verify_reference_fixture(fixture_id, fixture["expected"])

    assert %{"schema_contract" => "validation_reference_fixture_report.v1"} =
             OrbitalDynamics.validation_reference_fixture_report(%{
               fixture_id => fixture["expected"]
             })
  end

  test "builds model acceptance reports for declared intended use" do
    report =
      Validation.model_acceptance_report(
        [
          "orbit_data.simple_json",
          "event.access_windows",
          "propagator.two_body",
          "missing.model"
        ],
        intended_use: :operational_import
      )

    assert %{
             "schema_contract" => "model_acceptance_report.v1",
             "model" => "registry_model_acceptance_classifier",
             "intended_use" => "operational_import",
             "status" => "blocked",
             "model_count" => 4,
             "accepted_count" => 1,
             "review_required_count" => 1,
             "blocked_count" => 2,
             "unknown_model_count" => 1,
             "status_counts" => %{
               "accepted" => 1,
               "blocked" => 2,
               "review_required" => 1
             },
             "validation_level_counts" => %{
               "artifact_contract" => 1,
               "analysis" => 1,
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
             }
           } = report

    assert [
             %{"model_id" => "orbit_data.simple_json", "status" => "accepted"},
             %{"model_id" => "event.access_windows", "status" => "review_required"},
             %{"model_id" => "propagator.two_body", "status" => "blocked"},
             %{"model_id" => "missing.model", "status" => "blocked"}
           ] = report["rows"]

    assert length(report["records"]) == 3
    assert Enum.all?(report["records"], &(&1["schema_contract"] == "validation_record.v1"))

    assert {:ok, %{"schema_contract" => "model_acceptance_report.v1"}} =
             Schema.validate_artifact(report, schema_contract: "model_acceptance_report.v1")

    invalid_report = Map.put(report, "accepted_count", 99)

    assert {:error, validation_report} =
             Schema.validate_artifact(invalid_report,
               schema_contract: "model_acceptance_report.v1"
             )

    assert Enum.any?(validation_report["errors"], &(&1["path"] == "$.accepted_count"))

    stale_model_report = Map.put(report, "model", "stale_model_acceptance_classifier")

    assert {:error, validation_report} =
             Schema.validate_artifact(stale_model_report,
               schema_contract: "model_acceptance_report.v1"
             )

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] == "must equal \"registry_model_acceptance_classifier\"")
           )

    stale_status_counts = put_in(report, ["status_counts", "blocked"], 1)

    assert {:error, validation_report} =
             Schema.validate_artifact(stale_status_counts,
               schema_contract: "model_acceptance_report.v1"
             )

    assert Enum.any?(validation_report["errors"], &(&1["path"] == "$.status_counts"))

    stale_routing_report = put_in(report, ["model_ids_by_status", "accepted"], ["missing.model"])

    assert {:error, validation_report} =
             Schema.validate_artifact(stale_routing_report,
               schema_contract: "model_acceptance_report.v1"
             )

    assert Enum.any?(validation_report["errors"], &(&1["path"] == "$.model_ids_by_status"))

    capabilities = Validation.capabilities()

    assert :model_acceptance_status_counts in capabilities.summary_semantics
    assert :model_acceptance_model_ids_by_status in capabilities.summary_semantics
    assert :model_acceptance_model_ids_by_validation_level in capabilities.summary_semantics
    assert :model_acceptance_model_ids_by_intended_use in capabilities.summary_semantics
  end

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

  test "dependency policy keeps Nx required while EXLA remains optional" do
    assert %{
             "required_dependencies" => [
               %{
                 "package" => "nx",
                 "backend_modules" => nx_modules
               }
             ],
             "optional_dependencies" => [
               %{
                 "package" => "exla",
                 "backend_modules" => exla_modules
               }
             ],
             "backend_acceptance_policy" => "backend_acceptance_policy.v1",
             "decisions" => decisions
           } = Validation.dependency_policy()

    assert "OrbitalDynamics.Propagators.TwoBodyNxCompiled" in nx_modules
    assert "OrbitalDynamics.Propagators.TwoBodyExlaCpu" in exla_modules
    assert "do_not_mark_nx_optional_while_nx_modules_compile_unconditionally" in decisions
  end

  test "selects validation records from result-set assumptions" do
    result_set =
      result_set(%{
        propagator: TwoBody,
        outputs: [:trajectories, :access_windows, :eclipses]
      })

    ids =
      result_set
      |> Validation.records_for_result_set()
      |> Enum.map(& &1["id"])

    assert ids == [
             "propagator.two_body",
             "event.access_windows",
             "event.eclipses"
           ]

    assert OrbitalDynamics.validation_records_for_result_set(result_set) ==
             Validation.records_for_result_set(result_set)
  end

  test "archives model validation records in result artifacts" do
    artifact =
      %{propagator: J2, outputs: [:trajectories, :target_visibility]}
      |> result_set()
      |> Artifact.build()

    validation_ids =
      artifact.assumptions["model_validation"]
      |> Enum.map(& &1["id"])

    assert validation_ids == ["propagator.j2", "event.target_visibility"]
  end

  test "selects ground-track crossing validation from result-set assumptions" do
    result_set =
      result_set(%{
        propagator: TwoBody,
        outputs: [:trajectories, :ground_track_crossings]
      })

    ids =
      result_set
      |> Validation.records_for_result_set()
      |> Enum.map(& &1["id"])

    assert ids == ["propagator.two_body", "event.ground_track_crossings"]
  end

  test "documents tolerance policy and validation level vocabulary" do
    policy = Validation.tolerance_policy()

    assert policy["schema_contract"] == "validation_tolerance_policy.v1"
    assert policy["comparison_model"]["numeric_vectors"] =~ "maximum component-wise"

    assert policy["event_timing"]["event_time_tolerance_s"] ==
             "maximum adjacent trajectory sample spacing"

    declared_levels =
      policy["validation_levels"]
      |> Map.keys()
      |> MapSet.new()

    registry_levels =
      Validation.registry()
      |> Map.values()
      |> Enum.map(& &1["validation_level"])
      |> MapSet.new()

    fixture_levels =
      Validation.reference_fixtures()
      |> Map.values()
      |> Enum.map(& &1["validation_level"])
      |> MapSet.new()

    assert MapSet.subset?(registry_levels, declared_levels)
    assert MapSet.subset?(fixture_levels, declared_levels)
  end

  test "documents orbit-data adapter validation boundaries" do
    assert {:ok, simple_json} = Validation.record("orbit_data.simple_json")
    assert simple_json["validation_level"] == "artifact_contract"
    assert simple_json["model"] == "simple_json_cartesian_state_estimate_batch"
    assert "no hidden unit conversion" in simple_json["known_limits"]

    assert {:ok, opm} = Validation.record("orbit_data.ccsds_opm_kvn")
    assert opm["implementation"] == "OrbitalDynamics.OrbitData.import_ccsds_opm"
    assert "Earth center only" in opm["known_limits"]
    assert "duplicate single-value KVN fields are rejected" in opm["known_limits"]

    assert "OPM covariance matrices are preserved as metadata-only evidence and are not propagated" in opm[
             "known_limits"
           ]

    assert "unit tests import and export complete OPM covariance matrix components as metadata-only evidence" in opm[
             "evidence"
           ]

    assert "OPM maneuver metadata is preserved as metadata-only evidence and is not propagated" in opm[
             "known_limits"
           ]

    assert "unit tests export and re-import multiple OPM MAN_* maneuver metadata blocks from maneuver_execution_delta evidence" in opm[
             "evidence"
           ]

    assert {:ok, oem} = Validation.record("orbit_data.ccsds_oem_kvn")
    assert oem["tolerances"]["position_km"] == "selected sample is preserved, no interpolation"
    assert "no interpolation despite OEM interpolation metadata" in oem["known_limits"]
    assert "duplicate single-value KVN fields are rejected" in oem["known_limits"]

    assert "OEM covariance blocks are preserved as metadata-only evidence and are not propagated" in oem[
             "known_limits"
           ]

    assert "unit tests import and export one OEM covariance block as metadata-only evidence" in oem[
             "evidence"
           ]

    assert {:ok, tle} = Validation.record("orbit_data.tle_metadata")
    assert tle["implementation"] == "OrbitalDynamics.OrbitData.inspect_tle"
    assert tle["tolerances"]["checksum"] == "exact modulo-10 TLE checksum match"
    assert "single-object metadata preflight only" in tle["known_limits"]

    assert "unit tests reject multi-object TLE drops as ambiguous metadata preflight input" in tle[
             "evidence"
           ]

    registry_levels =
      Validation.registry()
      |> Map.take([
        "orbit_data.simple_json",
        "orbit_data.ccsds_opm_kvn",
        "orbit_data.ccsds_oem_kvn",
        "orbit_data.tle_metadata"
      ])
      |> Map.values()
      |> Enum.map(& &1["validation_level"])

    assert Enum.all?(registry_levels, &(&1 == "artifact_contract"))
  end

  test "documents backend acceptance tiers" do
    policy = Validation.backend_acceptance_policy()

    assert policy["schema_contract"] == "backend_acceptance_policy.v1"
    assert policy["reference_backend"]["tier"] == "reference_default"

    assert policy["acceptance_tiers"]["reference_default"] == %{
             "description" => "default planning backend for current artifacts",
             "requires_benchmark_artifact" => false,
             "requires_reference_match" => true
           }

    assert policy["implementation_tiers"]["OrbitalDynamics.Propagators.TwoBody"] ==
             "reference_default"

    assert policy["implementation_tiers"]["OrbitalDynamics.Propagators.TwoBodyNxCompiled"] ==
             "experimental_accelerator"

    assert policy["acceptance_tiers"]["experimental_accelerator"][
             "requires_benchmark_artifact"
           ] == true

    assert {:ok,
            %{
              "backend_acceptance_policy" => "backend_acceptance_policy.v1",
              "implementation" => "OrbitalDynamics.Propagators.TwoBody",
              "tier" => "reference_default",
              "reference_backend" => true,
              "requires_reference_match" => true,
              "requires_benchmark_artifact" => false
            }} = Validation.backend_acceptance_evidence(TwoBody)

    assert {:ok,
            %{
              "implementation" => "OrbitalDynamics.Propagators.TwoBodyNxCompiled",
              "tier" => "experimental_accelerator",
              "reference_backend" => false,
              "requires_reference_match" => true,
              "requires_benchmark_artifact" => true
            }} = Validation.backend_acceptance_evidence(TwoBodyNxCompiled)

    assert {:error, {:unknown_backend_implementation, "UnknownBackend"}} =
             Validation.backend_acceptance_evidence("UnknownBackend")

    assert policy["comparison_requirements"]["numeric_tolerance_policy"] ==
             "validation_tolerance_policy.v1"

    assert Enum.any?(
             policy["benchmark_reference_cases"],
             &(&1["artifact_family"] == "orbital_dynamics.study.benchmark")
           )

    assert "speedup claims are workload-specific" in policy["known_limits"]
  end

  test "verifies curated campaign artifact reference fixtures" do
    artifact =
      "study_results/leo_constellation_campaign.json"
      |> read_json!()
      |> Map.fetch!("campaign_plan")

    assert {:ok, fixture} =
             Validation.reference_fixture("fixture.artifact.campaign_plan.leo_constellation_v1")

    assert fixture["model_id"] == "artifact.campaign_plan.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    assert {:ok, report} =
             Validation.verify_reference_fixture(
               "fixture.artifact.campaign_plan.leo_constellation_v1",
               campaign_plan_fixture_observations()
             )

    assert report["status"] == "pass"
    assert Enum.all?(report["checks"], &(&1["status"] == "pass"))

    assert OrbitalDynamics.validation_artifact_observations("campaign_plan.v1", artifact) ==
             Validation.artifact_observations("campaign_plan.v1", artifact)
  end

  test "verifies curated result artifact reference fixtures" do
    assert {:ok, fixture} =
             Validation.reference_fixture(
               "fixture.artifact.result_artifact.leo_constellation_campaign"
             )

    assert fixture["model_id"] == "artifact.result_artifact.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    assert {:ok, report} =
             Validation.verify_reference_fixture(
               "fixture.artifact.result_artifact.leo_constellation_campaign",
               result_artifact_fixture_observations()
             )

    assert report["status"] == "pass"
    assert Enum.all?(report["checks"], &(&1["status"] == "pass"))

    stale_observations =
      result_artifact_fixture_observations()
      |> Map.put("payload_metrics_section_count", 14)

    assert {:ok, stale_report} =
             Validation.verify_reference_fixture(
               "fixture.artifact.result_artifact.leo_constellation_campaign",
               stale_observations
             )

    assert stale_report["status"] == "fail"

    assert Enum.any?(
             stale_report["checks"],
             &(&1["field"] == "payload_metrics_section_count" and &1["status"] == "fail")
           )

    artifact = result_artifact_fixture()

    assert OrbitalDynamics.validation_artifact_observations("result_artifact.v1", artifact) ==
             Validation.artifact_observations("result_artifact.v1", artifact)

    assert {:ok, %{"schema_contract" => "result_artifact.v1"}} =
             Schema.validate_artifact(artifact,
               schema_contract: "result_artifact.v1"
             )

    stale_payload_top_level_count =
      put_in(artifact, ["payload_metrics", "top_level_key_count"], 14)

    assert {:error, stale_payload_top_level_count_report} =
             Schema.validate_artifact(stale_payload_top_level_count,
               schema_contract: "result_artifact.v1"
             )

    assert Enum.any?(
             stale_payload_top_level_count_report["errors"],
             &(&1["path"] == "$.payload_metrics.top_level_key_count")
           )

    stale_payload_sections =
      update_in(artifact, ["payload_metrics", "sections"], &Map.delete(&1, "errors"))

    assert {:error, stale_payload_sections_report} =
             Schema.validate_artifact(stale_payload_sections,
               schema_contract: "result_artifact.v1"
             )

    assert Enum.any?(
             stale_payload_sections_report["errors"],
             &(&1["path"] == "$.payload_metrics.sections")
           )

    invalid_payload_section_bytes =
      put_in(artifact, ["payload_metrics", "sections", "errors", "bytes"], -1)

    assert {:error, invalid_payload_section_bytes_report} =
             Schema.validate_artifact(invalid_payload_section_bytes,
               schema_contract: "result_artifact.v1"
             )

    assert Enum.any?(
             invalid_payload_section_bytes_report["errors"],
             &(&1["path"] == "$.payload_metrics.sections.errors.bytes")
           )
  end

  test "verifies curated result artifact variant reference fixtures" do
    fixtures = [
      {
        "fixture.artifact.result_artifact.leo_access_demo",
        leo_access_result_artifact_fixture(),
        leo_access_result_artifact_fixture_observations(),
        "access_window_count",
        2
      },
      {
        "fixture.artifact.result_artifact.leo_access_demo_manifest",
        leo_access_manifest_result_artifact_fixture(),
        leo_access_manifest_result_artifact_fixture_observations(),
        "payload_metrics_artifact_body_bytes",
        21_802
      },
      {
        "fixture.artifact.result_artifact.ground_track_crossings",
        ground_track_result_artifact_fixture(),
        ground_track_result_artifact_fixture_observations(),
        "ground_track_crossing_count",
        11
      },
      {
        "fixture.artifact.result_artifact.raise_apogee_search",
        raise_apogee_result_artifact_fixture(),
        raise_apogee_result_artifact_fixture_observations(),
        "maneuver_recommendation_count",
        3
      },
      {
        "fixture.artifact.result_artifact.candidate_refresh_v1",
        candidate_refresh_result_artifact_fixture(),
        candidate_refresh_result_artifact_fixture_observations(),
        "candidate_refresh_refreshed_window_count",
        2
      },
      {
        "fixture.artifact.result_artifact.candidate_refresh_orbit_data_v1",
        candidate_refresh_orbit_data_result_artifact_fixture(),
        candidate_refresh_orbit_data_result_artifact_fixture_observations(),
        "payload_metrics_artifact_body_bytes",
        81_234
      },
      {
        "fixture.artifact.result_artifact.leo_dispersion_monte_carlo",
        monte_carlo_result_artifact_fixture(),
        monte_carlo_result_artifact_fixture_observations(),
        "trajectory_count",
        19
      },
      {
        "fixture.artifact.result_artifact.mission_plan_checkout",
        mission_plan_checkout_result_artifact_fixture(),
        mission_plan_checkout_result_artifact_fixture_observations(),
        "maneuver_recommendation_count",
        0
      }
    ]

    for {fixture_id, artifact, observations, stale_field, stale_value} <- fixtures do
      assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

      assert fixture["model_id"] == "artifact.result_artifact.v1"
      assert fixture["fixture_type"] == "curated_internal_artifact_regression"

      assert {:ok, verification} =
               Validation.verify_reference_fixture(fixture_id, observations)

      assert verification["status"] == "pass"
      assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

      stale_observations = Map.put(observations, stale_field, stale_value)

      assert {:ok, stale_verification} =
               Validation.verify_reference_fixture(fixture_id, stale_observations)

      assert stale_verification["status"] == "fail"

      assert Enum.any?(
               stale_verification["checks"],
               &(&1["field"] == stale_field and &1["status"] == "fail")
             )

      assert OrbitalDynamics.validation_artifact_observations("result_artifact.v1", artifact) ==
               Validation.artifact_observations("result_artifact.v1", artifact)
    end
  end

  test "verifies curated repair artifact reference fixtures" do
    assert {:ok, fixture} =
             Validation.reference_fixture("fixture.artifact.campaign_repair.leo_constellation_v2")

    assert fixture["model_id"] == "artifact.campaign_repair.v2"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    assert {:ok, report} =
             Validation.verify_reference_fixture(
               "fixture.artifact.campaign_repair.leo_constellation_v2",
               campaign_repair_fixture_observations()
             )

    assert report["status"] == "pass"
    assert Enum.all?(report["checks"], &(&1["status"] == "pass"))
  end

  test "verifies curated strategy artifact reference fixtures" do
    assert {:ok, fixture} =
             Validation.reference_fixture(
               "fixture.artifact.campaign_strategy.leo_constellation_v3"
             )

    assert fixture["model_id"] == "artifact.campaign_strategy.v3"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = read_json!("study_results/leo_constellation_campaign_strategy_v3.json")

    assert {:ok, report} =
             Validation.verify_reference_fixture(
               "fixture.artifact.campaign_strategy.leo_constellation_v3",
               campaign_strategy_fixture_observations()
             )

    assert report["status"] == "pass"
    assert Enum.all?(report["checks"], &(&1["status"] == "pass"))

    observations = campaign_strategy_fixture_observations()

    assert observations["score_term_report_row_count"] == 1674
    assert observations["score_term_report_key_count"] == 62

    assert observations["score_term_report_row_derived_key_counts"][
             "resource_availability_pressure_penalty"
           ] == 27

    assert observations["score_term_report_row_derived_key_counts"][
             "resource_filter_pressure_penalty"
           ] == 27

    assert observations["score_term_report_row_derived_key_counts"][
             "resource_projection_pressure_penalty"
           ] == 27

    assert observations["score_term_report_row_derived_key_counts"][
             "timeline_transition_application_pressure_penalty"
           ] == 27

    assert observations["score_term_report_validation_refresh_pressure_row_count"] == 27

    stale_score_term_key_observations =
      observations
      |> put_in(
        ["score_term_report_row_derived_key_counts", "resource_availability_pressure_penalty"],
        0
      )

    assert {:ok, stale_score_term_key_report} =
             Validation.verify_reference_fixture(
               "fixture.artifact.campaign_strategy.leo_constellation_v3",
               stale_score_term_key_observations
             )

    assert stale_score_term_key_report["status"] == "fail"

    assert Enum.any?(
             stale_score_term_key_report["checks"],
             &(&1["field"] == "score_term_report_row_derived_key_counts" and
                 &1["status"] == "fail")
           )

    stale_validation_refresh_pressure_observations =
      Map.put(observations, "score_term_report_validation_refresh_pressure_row_count", 0)

    assert {:ok, stale_validation_refresh_pressure_report} =
             Validation.verify_reference_fixture(
               "fixture.artifact.campaign_strategy.leo_constellation_v3",
               stale_validation_refresh_pressure_observations
             )

    assert stale_validation_refresh_pressure_report["status"] == "fail"

    assert Enum.any?(
             stale_validation_refresh_pressure_report["checks"],
             &(&1["field"] == "score_term_report_validation_refresh_pressure_row_count" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "campaign_strategy.v3",
             artifact
           ) == Validation.artifact_observations("campaign_strategy.v3", artifact)

    assert {:ok, _valid_report} =
             Schema.validate_artifact(artifact, schema_contract: "campaign_strategy.v3")

    stale_policy_decision_count =
      put_in(
        artifact,
        ["branches", Access.at(2), "policy_decision", "approval_requirement_count"],
        3
      )

    assert {:error, stale_count_report} =
             Schema.validate_artifact(stale_policy_decision_count,
               schema_contract: "campaign_strategy.v3"
             )

    assert Enum.any?(
             stale_count_report["errors"],
             &(&1["path"] == "$.branches[2].policy_decision.approval_requirement_count")
           )

    stale_validation_safety_case_event =
      update_in(artifact, ["branches", Access.at(2), "events"], fn events ->
        [
          %{
            "type" => "validation_safety_case_pressure",
            "validation_safety_case_status" => "blocked",
            "evidence_status" => "blocked",
            "input_contract" => "model_acceptance_report.v1",
            "evidence_ref" => "model_acceptance_report.v1:model.blocked",
            "required_operator_action" => "review_blocked_validation_safety_case",
            "evidence_status_counts" => %{"blocked" => -1}
          }
          | List.wrap(events)
        ]
      end)

    assert {:error, stale_safety_case_event_report} =
             Schema.validate_artifact(stale_validation_safety_case_event,
               schema_contract: "campaign_strategy.v3"
             )

    assert Enum.any?(
             stale_safety_case_event_report["errors"],
             &(&1["path"] == "$.branches[2].events[0].evidence_status_counts.blocked" and
                 &1["message"] == "must be a non-negative integer")
           )

    stale_validation_safety_case_action =
      update_in(artifact, ["branches", Access.at(2), "events"], fn events ->
        [
          %{
            "type" => "validation_safety_case_pressure",
            "validation_safety_case_status" => "blocked",
            "evidence_status" => "blocked",
            "input_contract" => "model_acceptance_report.v1",
            "evidence_ref" => "model_acceptance_report.v1:model.blocked",
            "required_operator_action" => "review_validation_safety_case"
          }
          | List.wrap(events)
        ]
      end)

    assert {:error, stale_safety_case_action_report} =
             Schema.validate_artifact(stale_validation_safety_case_action,
               schema_contract: "campaign_strategy.v3"
             )

    assert Enum.any?(
             stale_safety_case_action_report["errors"],
             &(&1["path"] ==
                 "$.branches[2].events[0].required_operator_action" and
                 &1["message"] ==
                   "must equal \"review_blocked_validation_safety_case\"")
           )

    stale_validation_safety_case_status =
      update_in(artifact, ["branches", Access.at(2), "events"], fn events ->
        [
          %{
            "type" => "validation_safety_case_pressure",
            "validation_safety_case_status" => "accepted_for_use",
            "evidence_status" => "accepted_for_use",
            "input_contract" => "model_acceptance_report.v1",
            "evidence_ref" => "model_acceptance_report.v1:model.accepted",
            "required_operator_action" => "review_validation_safety_case"
          }
          | List.wrap(events)
        ]
      end)

    assert {:error, stale_safety_case_status_report} =
             Schema.validate_artifact(stale_validation_safety_case_status,
               schema_contract: "campaign_strategy.v3"
             )

    assert Enum.any?(
             stale_safety_case_status_report["errors"],
             &(&1["path"] ==
                 "$.branches[2].events[0].validation_safety_case_status" and
                 &1["message"] =~ "must be one of")
           )

    assert Enum.any?(
             stale_safety_case_status_report["errors"],
             &(&1["path"] == "$.branches[2].events[0].evidence_status" and
                 &1["message"] =~ "must be one of")
           )

    missing_validation_safety_case_evidence_status =
      update_in(artifact, ["branches", Access.at(2), "events"], fn events ->
        [
          %{
            "type" => "validation_safety_case_pressure",
            "validation_safety_case_status" => "review_required",
            "input_contract" => "model_acceptance_report.v1",
            "evidence_ref" => "model_acceptance_report.v1:model.review",
            "required_operator_action" => "review_validation_safety_case"
          }
          | List.wrap(events)
        ]
      end)

    assert {:error, missing_safety_case_evidence_status_report} =
             Schema.validate_artifact(missing_validation_safety_case_evidence_status,
               schema_contract: "campaign_strategy.v3"
             )

    assert Enum.any?(
             missing_safety_case_evidence_status_report["errors"],
             &(&1["path"] == "$.branches[2].events[0].evidence_status" and
                 &1["message"] == "is required")
           )
  end

  test "verifies curated operator review package reference fixtures" do
    assert {:ok, fixture} =
             Validation.reference_fixture("fixture.artifact.operator_review_package.v1")

    assert fixture["model_id"] == "artifact.operator_review_package.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    assert {:ok, report} =
             Validation.verify_reference_fixture(
               "fixture.artifact.operator_review_package.v1",
               operator_review_package_fixture_observations()
             )

    assert report["status"] == "pass"
    assert Enum.all?(report["checks"], &(&1["status"] == "pass"))

    stale_row_derived_observations =
      operator_review_package_fixture_observations()
      |> put_in(["row_derived_review_type_counts", "timeline_diff_review"], 0)

    assert {:ok, stale_row_derived_report} =
             Validation.verify_reference_fixture(
               "fixture.artifact.operator_review_package.v1",
               stale_row_derived_observations
             )

    assert stale_row_derived_report["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_report["checks"],
             &(&1["field"] == "row_derived_review_type_counts" and &1["status"] == "fail")
           )

    package = operator_review_package_fixture()

    assert {:ok, _schema_report} =
             Schema.validate_artifact(package,
               schema_contract: "operator_review_package.v1"
             )

    stale_review_count = Map.put(package, "review_count", 7)

    assert {:error, stale_review_count_report} =
             Schema.validate_artifact(stale_review_count,
               schema_contract: "operator_review_package.v1"
             )

    assert Enum.any?(
             stale_review_count_report["errors"],
             &(&1["path"] == "$.review_count")
           )

    stale_review_type_counts =
      put_in(package, ["review_type_counts", "timeline_diff_review"], 0)

    assert {:error, stale_review_type_counts_report} =
             Schema.validate_artifact(stale_review_type_counts,
               schema_contract: "operator_review_package.v1"
             )

    assert Enum.any?(
             stale_review_type_counts_report["errors"],
             &(&1["path"] == "$.review_type_counts")
           )

    stale_review_queue_counts = Map.put(package, "review_queue_counts", %{})

    assert {:error, stale_review_queue_counts_report} =
             Schema.validate_artifact(stale_review_queue_counts,
               schema_contract: "operator_review_package.v1"
             )

    assert Enum.any?(
             stale_review_queue_counts_report["errors"],
             &(&1["path"] == "$.review_queue_counts")
           )

    stale_required_operator_action_counts =
      Map.put(package, "required_operator_action_counts", %{})

    assert {:error, stale_required_operator_action_counts_report} =
             Schema.validate_artifact(stale_required_operator_action_counts,
               schema_contract: "operator_review_package.v1"
             )

    assert Enum.any?(
             stale_required_operator_action_counts_report["errors"],
             &(&1["path"] == "$.required_operator_action_counts")
           )

    stale_model_limits =
      Map.put(package, "model_limits", Enum.drop(Map.fetch!(package, "model_limits"), 1))

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "operator_review_package.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )

    stale_assumption_boundary =
      put_in(package, ["assumptions", "boundary"], "api_write_ready")

    assert {:error, stale_assumption_boundary_report} =
             Schema.validate_artifact(stale_assumption_boundary,
               schema_contract: "operator_review_package.v1"
             )

    assert Enum.any?(
             stale_assumption_boundary_report["errors"],
             &(&1["path"] == "$.assumptions.boundary")
           )
  end

  test "verifies curated operational readiness report reference fixtures" do
    assert {:ok, fixture} =
             Validation.reference_fixture("fixture.artifact.operational_readiness_report.v1")

    assert fixture["model_id"] == "artifact.operational_readiness_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_readiness_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.operational_readiness_report.v1",
               operational_readiness_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    observations = operational_readiness_report_fixture_observations()

    assert observations["row_derived_ready_for_import_count"] == 1
    assert observations["row_derived_import_status_counts"] == %{"ready_for_import" => 1}
    assert observations["row_derived_cadence_import_status_counts"] == %{"present" => 1}

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_readiness_report.v1",
             report
           ) == Validation.artifact_observations("operational_readiness_report.v1", report)

    stale_row_derived_observations =
      operational_readiness_report_fixture_observations()
      |> put_in(["row_derived_gate_status_counts", "passed"], 4)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.operational_readiness_report.v1",
               stale_row_derived_observations
             )

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_gate_status_counts" and
                 &1["status"] == "fail")
           )

    stale_import_status_observations =
      observations
      |> put_in(["row_derived_import_status_counts", "ready_for_import"], 0)

    assert {:ok, stale_import_status_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.operational_readiness_report.v1",
               stale_import_status_observations
             )

    assert stale_import_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_import_status_verification["checks"],
             &(&1["field"] == "row_derived_import_status_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_readiness_report.v1"
             )

    stale_model = Map.put(report, "model", "stale_operational_readiness_model")

    assert {:error, stale_model_report} =
             Schema.validate_artifact(stale_model,
               schema_contract: "operational_readiness_report.v1"
             )

    assert Enum.any?(
             stale_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"artifact_only_operational_readiness_classifier\"")
           )

    stale_import_classification = Map.put(report, "import_classification", "review_only")

    assert {:error, stale_import_classification_report} =
             Schema.validate_artifact(stale_import_classification,
               schema_contract: "operational_readiness_report.v1"
             )

    assert Enum.any?(
             stale_import_classification_report["errors"],
             &(&1["path"] == "$.import_classification")
           )

    stale_readiness_level = Map.put(report, "readiness_level", "operator_review")

    assert {:error, stale_readiness_level_report} =
             Schema.validate_artifact(stale_readiness_level,
               schema_contract: "operational_readiness_report.v1"
             )

    assert Enum.any?(
             stale_readiness_level_report["errors"],
             &(&1["path"] == "$.readiness_level")
           )

    stale_gate_count = Map.put(report, "gate_count", 4)

    assert {:error, stale_gate_count_report} =
             Schema.validate_artifact(stale_gate_count,
               schema_contract: "operational_readiness_report.v1"
             )

    assert Enum.any?(
             stale_gate_count_report["errors"],
             &(&1["path"] == "$.gate_count")
           )

    stale_passed_gate_count = Map.put(report, "passed_gate_count", 4)

    assert {:error, stale_passed_gate_count_report} =
             Schema.validate_artifact(stale_passed_gate_count,
               schema_contract: "operational_readiness_report.v1"
             )

    assert Enum.any?(
             stale_passed_gate_count_report["errors"],
             &(&1["path"] == "$.passed_gate_count")
           )

    stale_evidence_count = put_in(report, ["evidence", "ready_for_import_count"], 0)

    assert {:error, stale_evidence_count_report} =
             Schema.validate_artifact(stale_evidence_count,
               schema_contract: "operational_readiness_report.v1"
             )

    assert Enum.any?(
             stale_evidence_count_report["errors"],
             &(&1["path"] == "$.evidence.ready_for_import_count")
           )

    stale_evidence_map = put_in(report, ["evidence", "import_status_counts"], %{})

    assert {:error, stale_evidence_map_report} =
             Schema.validate_artifact(stale_evidence_map,
               schema_contract: "operational_readiness_report.v1"
             )

    assert Enum.any?(
             stale_evidence_map_report["errors"],
             &(&1["path"] == "$.evidence.import_status_counts")
           )

    stale_model_limits =
      Map.put(report, "model_limits", Enum.drop(Map.fetch!(report, "model_limits"), 1))

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "operational_readiness_report.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )

    stale_assumptions =
      Map.put(
        report,
        "assumptions",
        List.replace_at(Map.fetch!(report, "assumptions"), 1, "external_import_write_ready")
      )

    assert {:error, stale_assumptions_report} =
             Schema.validate_artifact(stale_assumptions,
               schema_contract: "operational_readiness_report.v1"
             )

    assert Enum.any?(
             stale_assumptions_report["errors"],
             &(&1["path"] == "$.assumptions")
           )
  end

  test "verifies curated operational execution boundary summary reference fixtures" do
    fixture_id = "fixture.artifact.operational_execution_boundary_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.operational_execution_boundary_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_execution_boundary_summary_fixture()
    observations = operational_execution_boundary_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["import_eligible"] == true
    assert observations["handoff_only"] == true
    assert observations["execution_allowed"] == false
    assert observations["cadence_write_allowed"] == false
    assert observations["operator_authority_granted"] == false
    assert observations["execution_boundary"] == "adapter_handoff_only"

    assert observations["assumption_execution_boundary"] ==
             "artifact_only_no_cadence_write_no_command_execution"

    assert observations["operator_authority"] == "not_granted_by_execution_boundary_summary"
    assert observations["cadence_write"] == "not_performed_by_summary"
    assert observations["command_execution"] == "not_performed_by_summary"
    assert observations["operational_mode_gate_id"] == "operational_mode"
    assert observations["operational_mode_gate_status"] == "passed"
    assert observations["gate_count"] == 5

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_execution_boundary_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "operational_execution_boundary_summary.v1",
               report
             )

    stale_execution_observations = Map.put(observations, "execution_allowed", true)

    assert {:ok, stale_execution_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_execution_observations)

    assert stale_execution_verification["status"] == "fail"

    assert Enum.any?(
             stale_execution_verification["checks"],
             &(&1["field"] == "execution_allowed" and &1["status"] == "fail")
           )

    stale_boundary_observations =
      Map.put(observations, "execution_boundary", "ready_for_command_execution")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "execution_boundary" and &1["status"] == "fail")
           )

    stale_assumption_observations =
      Map.put(observations, "command_execution", "performed_by_summary")

    assert {:ok, stale_assumption_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_assumption_observations)

    assert stale_assumption_verification["status"] == "fail"

    assert Enum.any?(
             stale_assumption_verification["checks"],
             &(&1["field"] == "command_execution" and &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_execution_boundary_summary.v1"
             )
  end

  test "verifies curated operational import eligibility summary reference fixtures" do
    fixture_id = "fixture.artifact.operational_import_eligibility_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.operational_import_eligibility_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_import_eligibility_summary_fixture()
    observations = operational_import_eligibility_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["import_eligible"] == true
    assert observations["import_classification"] == "importable"
    assert observations["readiness_level"] == "import_eligible"
    assert observations["status"] == "passed"
    assert observations["gate_count"] == 5
    assert observations["passed_gate_count"] == 5
    assert observations["row_derived_non_passed_gate_count"] == 0
    assert observations["execution_boundary"] == "artifact_only_no_cadence_write"
    assert observations["operator_authority"] == "not_granted_by_summary"

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_import_eligibility_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "operational_import_eligibility_summary.v1",
               report
             )

    stale_eligible_observations = Map.put(observations, "import_eligible", false)

    assert {:ok, stale_eligible_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_eligible_observations)

    assert stale_eligible_verification["status"] == "fail"

    assert Enum.any?(
             stale_eligible_verification["checks"],
             &(&1["field"] == "import_eligible" and &1["status"] == "fail")
           )

    stale_count_observations = Map.put(observations, "gate_count", 4)

    assert {:ok, stale_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_count_observations)

    assert stale_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_count_verification["checks"],
             &(&1["field"] == "gate_count" and &1["status"] == "fail")
           )

    stale_boundary_observations =
      Map.put(observations, "execution_boundary", "cadence_write_ready")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "execution_boundary" and &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_import_eligibility_summary.v1"
             )
  end

  test "verifies curated operational readiness gate summary reference fixtures" do
    fixture_id = "fixture.artifact.operational_readiness_gate_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.operational_readiness_gate_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_readiness_gate_summary_fixture()
    observations = operational_readiness_gate_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["gate_count"] == 5
    assert observations["row_derived_gate_count"] == 5
    assert observations["gate_status_counts"] == %{"passed" => 5}
    assert observations["row_derived_gate_status_counts"] == %{"passed" => 5}
    assert observations["gate_classification_counts"] == %{"importable" => 5}

    assert observations["row_derived_gate_ids_by_status"] == %{
             "passed" => [
               "adapter_boundary",
               "cadence_import",
               "operational_mode",
               "operator_review",
               "source_contract"
             ]
           }

    assert observations["passed_gate_keys"] ==
             "source_contract|operational_mode|adapter_boundary|operator_review|cadence_import"

    assert observations["non_passed_gate_keys"] == ""
    assert observations["execution_boundary"] == "artifact_only_no_cadence_write"
    assert observations["operator_authority"] == "not_granted_by_summary"

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_readiness_gate_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "operational_readiness_gate_summary.v1",
               report
             )

    stale_status_observations =
      Map.put(observations, "row_derived_gate_status_counts", %{"passed" => 4})

    assert {:ok, stale_status_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_status_observations)

    assert stale_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_status_verification["checks"],
             &(&1["field"] == "row_derived_gate_status_counts" and
                 &1["status"] == "fail")
           )

    stale_routing_observations =
      put_in(observations, ["row_derived_gate_ids_by_status", "passed"], ["source_contract"])

    assert {:ok, stale_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_routing_observations)

    assert stale_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_routing_verification["checks"],
             &(&1["field"] == "row_derived_gate_ids_by_status" and &1["status"] == "fail")
           )

    stale_boundary_observations = Map.put(observations, "operator_authority", "granted")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "operator_authority" and &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_readiness_gate_summary.v1"
             )
  end

  test "verifies curated quality gate report reference fixtures" do
    fixture_id = "fixture.artifact.quality_gate_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.quality_gate_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = quality_gate_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               quality_gate_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    observations = quality_gate_report_fixture_observations()

    assert observations["row_derived_ready_for_import_count"] == 1
    assert observations["row_derived_import_status_counts"] == %{"ready_for_import" => 1}
    assert observations["row_derived_cadence_import_status_counts"] == %{"present" => 1}

    assert OrbitalDynamics.validation_artifact_observations("quality_gate_report.v1", report) ==
             Validation.artifact_observations("quality_gate_report.v1", report)

    stale_row_derived_observations =
      quality_gate_report_fixture_observations()
      |> put_in(["row_derived_gate_ids_by_status", "passed"], ["source_contract"])

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_gate_ids_by_status" and &1["status"] == "fail")
           )

    stale_import_status_observations =
      observations
      |> put_in(["row_derived_cadence_import_status_counts", "present"], 0)

    assert {:ok, stale_import_status_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_import_status_observations)

    assert stale_import_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_import_status_verification["checks"],
             &(&1["field"] == "row_derived_cadence_import_status_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "quality_gate_report.v1"
             )

    stale_import_classification = Map.put(report, "import_classification", "review_only")

    assert {:error, stale_import_classification_report} =
             Schema.validate_artifact(stale_import_classification,
               schema_contract: "quality_gate_report.v1"
             )

    assert Enum.any?(
             stale_import_classification_report["errors"],
             &(&1["path"] == "$.import_classification")
           )

    stale_gate_count = Map.put(report, "gate_count", 4)

    assert {:error, stale_gate_count_report} =
             Schema.validate_artifact(stale_gate_count,
               schema_contract: "quality_gate_report.v1"
             )

    assert Enum.any?(
             stale_gate_count_report["errors"],
             &(&1["path"] == "$.gate_count")
           )

    stale_gate_status_counts = Map.put(report, "gate_status_counts", %{"passed" => 4})

    assert {:error, stale_gate_status_counts_report} =
             Schema.validate_artifact(stale_gate_status_counts,
               schema_contract: "quality_gate_report.v1"
             )

    assert Enum.any?(
             stale_gate_status_counts_report["errors"],
             &(&1["path"] == "$.gate_status_counts")
           )

    stale_gate_ids_by_status =
      put_in(report, ["gate_ids_by_status", "passed"], ["source_contract"])

    assert {:error, stale_gate_ids_by_status_report} =
             Schema.validate_artifact(stale_gate_ids_by_status,
               schema_contract: "quality_gate_report.v1"
             )

    assert Enum.any?(
             stale_gate_ids_by_status_report["errors"],
             &(&1["path"] == "$.gate_ids_by_status")
           )

    stale_model_limits =
      Map.put(report, "model_limits", Enum.drop(Map.fetch!(report, "model_limits"), 1))

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "quality_gate_report.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )

    stale_execution_boundary =
      put_in(report, ["assumptions", "execution_boundary"], "cadence_write_ready")

    assert {:error, stale_execution_boundary_report} =
             Schema.validate_artifact(stale_execution_boundary,
               schema_contract: "quality_gate_report.v1"
             )

    assert Enum.any?(
             stale_execution_boundary_report["errors"],
             &(&1["path"] == "$.assumptions.execution_boundary")
           )
  end

  test "verifies curated operational quality gate summary reference fixtures" do
    fixture_id = "fixture.artifact.operational_quality_gate_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.operational_quality_gate_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_quality_gate_summary_fixture()
    observations = operational_quality_gate_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["review_gate_count"] == 3
    assert observations["row_derived_review_gate_count"] == 3
    assert observations["non_passed_gate_count"] == 3

    assert observations["row_derived_non_passed_gate_keys"] ==
             "cadence_import|operator_review|resource_availability"

    assert observations["row_derived_non_passed_quality_gate_row_keys"] ==
             "quality_gate:resource_projection_report.v1:resource_summaries:cadence_import:6|quality_gate:resource_projection_report.v1:resource_summaries:operator_review:5|quality_gate:resource_projection_report.v1:resource_summaries:resource_availability:4"

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_quality_gate_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "operational_quality_gate_summary.v1",
               report
             )

    stale_review_count_observations = Map.put(observations, "row_derived_review_gate_count", 0)

    assert {:ok, stale_review_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_review_count_observations)

    assert stale_review_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_review_count_verification["checks"],
             &(&1["field"] == "row_derived_review_gate_count" and &1["status"] == "fail")
           )

    stale_non_passed_routing_observations =
      Map.put(observations, "row_derived_non_passed_gate_keys", "cadence_import")

    assert {:ok, stale_non_passed_routing_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_non_passed_routing_observations
             )

    assert stale_non_passed_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_non_passed_routing_verification["checks"],
             &(&1["field"] == "row_derived_non_passed_gate_keys" and &1["status"] == "fail")
           )

    stale_non_passed_row_routing_observations =
      Map.put(
        observations,
        "row_derived_non_passed_quality_gate_row_keys",
        "quality_gate:resource_projection_report.v1:resource_summaries:cadence_import:6"
      )

    assert {:ok, stale_non_passed_row_routing_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_non_passed_row_routing_observations
             )

    assert stale_non_passed_row_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_non_passed_row_routing_verification["checks"],
             &(&1["field"] == "row_derived_non_passed_quality_gate_row_keys" and
                 &1["status"] == "fail")
           )

    stale_boundary_observations = Map.put(observations, "operator_authority", "granted")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "operator_authority" and &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_quality_gate_summary.v1"
             )
  end

  test "verifies curated operational quality gate import readiness summary reference fixtures" do
    fixture_id = "fixture.artifact.operational_quality_gate_import_readiness_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.operational_quality_gate_import_readiness_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_quality_gate_import_readiness_summary_fixture()
    observations = operational_quality_gate_import_readiness_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["ready_for_import_count"] == 1
    assert observations["row_derived_ready_for_import_count"] == 1
    assert observations["stale_freshness_count"] == 1
    assert observations["row_derived_stale_freshness_count"] == 1
    assert observations["cadence_import_status_counts"] == %{"present" => 1}
    assert observations["freshness_review_required"] == true
    assert observations["import_blocked"] == false

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_quality_gate_import_readiness_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "operational_quality_gate_import_readiness_summary.v1",
               report
             )

    stale_ready_observations = Map.put(observations, "ready_for_import_count", 0)

    assert {:ok, stale_ready_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_ready_observations)

    assert stale_ready_verification["status"] == "fail"

    assert Enum.any?(
             stale_ready_verification["checks"],
             &(&1["field"] == "ready_for_import_count" and &1["status"] == "fail")
           )

    stale_row_derived_freshness_observations =
      Map.put(observations, "row_derived_stale_freshness_count", 0)

    assert {:ok, stale_row_derived_freshness_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_row_derived_freshness_observations
             )

    assert stale_row_derived_freshness_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_freshness_verification["checks"],
             &(&1["field"] == "row_derived_stale_freshness_count" and
                 &1["status"] == "fail")
           )

    stale_cadence_status_observations =
      Map.put(observations, "row_derived_cadence_import_present_count", 0)

    assert {:ok, stale_cadence_status_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_cadence_status_observations)

    assert stale_cadence_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_cadence_status_verification["checks"],
             &(&1["field"] == "row_derived_cadence_import_present_count" and
                 &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_quality_gate_import_readiness_summary.v1"
             )
  end

  test "verifies curated operational quality gate unavailable-resource summary reference fixtures" do
    fixture_id = "fixture.artifact.operational_quality_gate_unavailable_resource_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] ==
             "artifact.operational_quality_gate_unavailable_resource_summary.v1"

    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_quality_gate_unavailable_resource_summary_fixture()
    observations = operational_quality_gate_unavailable_resource_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_reason_count_observations =
      observations
      |> put_in(["unavailable_resource_reason_counts", "antenna_unavailable"], 0)

    assert {:ok, stale_reason_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_reason_count_observations)

    assert stale_reason_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_reason_count_verification["checks"],
             &(&1["field"] == "unavailable_resource_reason_counts" and
                 &1["status"] == "fail")
           )

    stale_contact_routing_observations =
      observations
      |> put_in(["blocked_contact_ids_by_blocking_dimension", "antenna"], [])

    assert {:ok, stale_contact_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_contact_routing_observations)

    assert stale_contact_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_contact_routing_verification["checks"],
             &(&1["field"] == "blocked_contact_ids_by_blocking_dimension" and
                 &1["status"] == "fail")
           )

    stale_row_status_observations =
      observations
      |> Map.put("row_derived_review_required_quality_gate_row_count", 0)

    assert {:ok, stale_row_status_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_status_observations)

    assert stale_row_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_status_verification["checks"],
             &(&1["field"] == "row_derived_review_required_quality_gate_row_count" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_quality_gate_unavailable_resource_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "operational_quality_gate_unavailable_resource_summary.v1",
               report
             )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_quality_gate_unavailable_resource_summary.v1"
             )
  end

  test "verifies checked-in operational quality gate unavailable-resource summary reference fixture" do
    fixture_id =
      "fixture.artifact.operational_quality_gate_unavailable_resource_summary.resource_projection_v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] ==
             "artifact.operational_quality_gate_unavailable_resource_summary.v1"

    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    assert fixture["inputs"]["artifact_path"] ==
             "study_results/operational_quality_gate_unavailable_resource_summary_v1.json"

    report = operational_quality_gate_unavailable_resource_summary_checked_in_fixture()
    observations = operational_quality_gate_unavailable_resource_summary_checked_in_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["source_artifact_type"] == "resource_projection_report.v1"
    assert observations["unavailable_resource_pressure_count"] == 2
    assert observations["row_derived_unavailable_resource_pressure_count"] == 2

    assert observations["unavailable_resource_reason_counts"] == %{
             "antenna_unavailable" => 1,
             "payload_unavailable" => 1
           }

    assert observations["unavailable_resource_reason_keys"] ==
             "antenna_unavailable|payload_unavailable"

    assert observations["blocked_contact_ids_by_blocking_dimension"] == %{}

    assert observations["quality_gate_row_ids_by_status"] == %{
             "review_required" => [
               "quality_gate:resource_projection_report.v1:resource_summaries:resource_availability:4"
             ]
           }

    assert observations["execution_boundary"] == "artifact_only_no_cadence_write"
    assert observations["operator_authority"] == "not_granted_by_unavailable_resource_summary"

    stale_pressure_observations =
      observations
      |> Map.put("row_derived_unavailable_resource_pressure_count", 1)

    assert {:ok, stale_pressure_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_pressure_observations)

    assert stale_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_pressure_verification["checks"],
             &(&1["field"] == "row_derived_unavailable_resource_pressure_count" and
                 &1["status"] == "fail")
           )

    stale_reason_observations =
      observations
      |> put_in(["unavailable_resource_reason_counts", "payload_unavailable"], 0)

    assert {:ok, stale_reason_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_reason_observations)

    assert stale_reason_verification["status"] == "fail"

    assert Enum.any?(
             stale_reason_verification["checks"],
             &(&1["field"] == "unavailable_resource_reason_counts" and
                 &1["status"] == "fail")
           )

    stale_quality_gate_routing_observations =
      observations
      |> put_in(["quality_gate_row_ids_by_status", "review_required"], [])

    assert {:ok, stale_quality_gate_routing_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_quality_gate_routing_observations
             )

    assert stale_quality_gate_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_quality_gate_routing_verification["checks"],
             &(&1["field"] == "quality_gate_row_ids_by_status" and &1["status"] == "fail")
           )

    stale_boundary_observations =
      observations
      |> Map.put("execution_boundary", "cadence_write_ready")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "execution_boundary" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_quality_gate_unavailable_resource_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "operational_quality_gate_unavailable_resource_summary.v1",
               report
             )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_quality_gate_unavailable_resource_summary.v1"
             )
  end

  test "verifies curated operational quality gate schema validation summary reference fixtures" do
    fixture_id = "fixture.artifact.operational_quality_gate_schema_validation_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.operational_quality_gate_schema_validation_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_quality_gate_schema_validation_summary_fixture()
    observations = operational_quality_gate_schema_validation_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["schema_validation_fail_count"] == 1
    assert observations["row_derived_schema_validation_fail_count"] == 1
    assert observations["schema_validation_error_count"] == 1
    assert observations["schema_validation_remediation_count"] == 1
    assert observations["schema_validation_import_blocked"] == true
    assert observations["row_derived_blocked_quality_gate_row_count"] == 1
    assert observations["row_derived_failed_schema_validation_quality_gate_row_count"] == 1

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_quality_gate_schema_validation_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "operational_quality_gate_schema_validation_summary.v1",
               report
             )

    stale_fail_count_observations = Map.put(observations, "schema_validation_fail_count", 0)

    assert {:ok, stale_fail_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_fail_count_observations)

    assert stale_fail_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_fail_count_verification["checks"],
             &(&1["field"] == "schema_validation_fail_count" and &1["status"] == "fail")
           )

    stale_row_derived_fail_observations =
      Map.put(observations, "row_derived_schema_validation_fail_count", 0)

    assert {:ok, stale_row_derived_fail_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_fail_observations)

    assert stale_row_derived_fail_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_fail_verification["checks"],
             &(&1["field"] == "row_derived_schema_validation_fail_count" and
                 &1["status"] == "fail")
           )

    stale_blocked_row_observations =
      Map.put(observations, "row_derived_blocked_quality_gate_row_count", 0)

    assert {:ok, stale_blocked_row_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_blocked_row_observations)

    assert stale_blocked_row_verification["status"] == "fail"

    assert Enum.any?(
             stale_blocked_row_verification["checks"],
             &(&1["field"] == "row_derived_blocked_quality_gate_row_count" and
                 &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_quality_gate_schema_validation_summary.v1"
             )
  end

  test "verifies curated operational quality gate operator training summary reference fixtures" do
    fixture_id = "fixture.artifact.operational_quality_gate_operator_training_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.operational_quality_gate_operator_training_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_quality_gate_operator_training_summary_fixture()
    observations = operational_quality_gate_operator_training_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["operator_training_requirement_count"] == 5
    assert observations["row_derived_operator_training_requirement_count"] == 5

    assert observations["operator_training_requirement_counts"] == %{
             "certification" => 1,
             "operator_role" => 2,
             "qualification" => 1,
             "training" => 1
           }

    assert observations["required_operator_role_keys"] == "contact_operator|mission_director"
    assert observations["required_training_keys"] == "contact_replan_drill"
    assert observations["required_certification_keys"] == "cadence_import_cert"
    assert observations["required_qualification_keys"] == "sat_ops_current"
    assert observations["operator_training_review_required"] == true
    assert observations["row_derived_review_required_quality_gate_row_count"] == 1
    assert observations["row_derived_review_only_quality_gate_row_count"] == 1

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_quality_gate_operator_training_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "operational_quality_gate_operator_training_summary.v1",
               report
             )

    stale_requirement_count_observations =
      Map.put(observations, "operator_training_requirement_count", 4)

    assert {:ok, stale_requirement_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_requirement_count_observations)

    assert stale_requirement_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_requirement_count_verification["checks"],
             &(&1["field"] == "operator_training_requirement_count" and
                 &1["status"] == "fail")
           )

    stale_row_derived_requirement_observations =
      Map.put(observations, "row_derived_operator_training_requirement_count", 4)

    assert {:ok, stale_row_derived_requirement_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_row_derived_requirement_observations
             )

    assert stale_row_derived_requirement_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_requirement_verification["checks"],
             &(&1["field"] == "row_derived_operator_training_requirement_count" and
                 &1["status"] == "fail")
           )

    stale_role_routing_observations =
      Map.put(observations, "required_operator_role_keys", "contact_operator")

    assert {:ok, stale_role_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_role_routing_observations)

    assert stale_role_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_role_routing_verification["checks"],
             &(&1["field"] == "required_operator_role_keys" and &1["status"] == "fail")
           )

    stale_training_routing_observations =
      Map.put(observations, "required_training_keys", "")

    assert {:ok, stale_training_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_training_routing_observations)

    assert stale_training_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_training_routing_verification["checks"],
             &(&1["field"] == "required_training_keys" and &1["status"] == "fail")
           )

    stale_review_row_observations =
      Map.put(observations, "row_derived_review_required_quality_gate_row_count", 0)

    assert {:ok, stale_review_row_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_review_row_observations)

    assert stale_review_row_verification["status"] == "fail"

    assert Enum.any?(
             stale_review_row_verification["checks"],
             &(&1["field"] == "row_derived_review_required_quality_gate_row_count" and
                 &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_quality_gate_operator_training_summary.v1"
             )
  end

  test "rejects stale copied readiness and quality source reports from challenge fixtures" do
    readiness_review = read_json!("study_results/operator_review_resource_pressure_v1.json")
    readiness_import = read_json!("study_results/cadence_import_resource_pressure_v1.json")
    quality_gate = read_json!("study_results/quality_gate_resource_pressure_v1.json")
    quality_review = OperatorReview.from_quality_gate_report(quality_gate)
    quality_import = CadenceImport.from_quality_gate_report(quality_gate)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(readiness_review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(readiness_import)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(quality_review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(quality_import)

    stale_readiness_review =
      put_in(
        readiness_review,
        ["rows", Access.at(0), "source_operational_readiness_report", "status"],
        "passed"
      )

    assert {:error, stale_readiness_review_report} =
             Schema.validate_artifact(stale_readiness_review)

    assert Enum.any?(
             stale_readiness_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_operational_readiness_report.status" and
                 &1["message"] == "must match operational_readiness_status on handoff row")
           )

    stale_readiness_import =
      put_in(
        readiness_import,
        ["rows", Access.at(0), "source_operational_readiness_report", "readiness_level"],
        "blocked"
      )

    assert {:error, stale_readiness_import_report} =
             Schema.validate_artifact(stale_readiness_import)

    assert Enum.any?(
             stale_readiness_import_report["errors"],
             &(&1["path"] == "$.rows[0].source_operational_readiness_report.readiness_level" and
                 &1["message"] == "must match readiness_level on handoff row")
           )

    stale_quality_review =
      put_in(
        quality_review,
        ["rows", Access.at(0), "source_quality_gate_report", "readiness_level"],
        "blocked"
      )

    assert {:error, stale_quality_review_report} =
             Schema.validate_artifact(stale_quality_review)

    assert Enum.any?(
             stale_quality_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_quality_gate_report.readiness_level" and
                 &1["message"] == "must match readiness_level on handoff row")
           )

    stale_quality_import =
      put_in(
        quality_import,
        ["rows", Access.at(0), "source_quality_gate_report", "report_id"],
        "quality_gate:wrong_report"
      )

    assert {:error, stale_quality_import_report} =
             Schema.validate_artifact(stale_quality_import)

    assert Enum.any?(
             stale_quality_import_report["errors"],
             &(&1["path"] == "$.rows[0].source_quality_gate_report.report_id" and
                 &1["message"] == "must match quality_gate_report_id on handoff row")
           )
  end

  test "verifies curated station calendar stale reservation hold reference fixtures" do
    fixtures = [
      {
        "fixture.artifact.station_calendar_report.stale_provider_reservation_hold",
        station_calendar_report_fixture(),
        station_calendar_report_fixture_observations()
      },
      {
        "fixture.artifact.station_calendar_report.v1",
        checked_in_station_calendar_report_fixture(),
        checked_in_station_calendar_report_fixture_observations()
      }
    ]

    for {fixture_id, report, observations} <- fixtures do
      assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

      assert fixture["model_id"] == "artifact.station_calendar_report.v1"
      assert fixture["fixture_type"] == "curated_internal_artifact_regression"

      assert {:ok, verification} =
               Validation.verify_reference_fixture(fixture_id, observations)

      assert verification["status"] == "pass"
      assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

      stale_row_derived_observations =
        observations
        |> put_in(["row_derived_station_reservation_match_status_counts", "overlap"], 0)

      assert {:ok, stale_row_derived_verification} =
               Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

      assert stale_row_derived_verification["status"] == "fail"

      assert Enum.any?(
               stale_row_derived_verification["checks"],
               &(&1["field"] == "row_derived_station_reservation_match_status_counts" and
                   &1["status"] == "fail")
             )

      stale_status_observations =
        observations
        |> Map.put("station_calendar_status_counts", %{"stale_status" => 1})

      assert {:ok, stale_status_verification} =
               Validation.verify_reference_fixture(fixture_id, stale_status_observations)

      assert stale_status_verification["status"] == "fail"

      assert Enum.any?(
               stale_status_verification["checks"],
               &(&1["field"] == "station_calendar_status_counts" and &1["status"] == "fail")
             )

      assert OrbitalDynamics.validation_artifact_observations(
               "station_calendar_report.v1",
               report
             ) == Validation.artifact_observations("station_calendar_report.v1", report)
    end

    report = station_calendar_report_fixture()

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "station_calendar_report.v1"
             )

    stale_match_status_counts =
      put_in(report, ["station_reservation_match_status_counts", "overlap"], 0)

    assert {:error, stale_match_status_counts_report} =
             Schema.validate_artifact(stale_match_status_counts,
               schema_contract: "station_calendar_report.v1"
             )

    assert Enum.any?(
             stale_match_status_counts_report["errors"],
             &(&1["path"] == "$.station_reservation_match_status_counts")
           )

    checked_in_report = checked_in_station_calendar_report_fixture()

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(checked_in_report,
               schema_contract: "station_calendar_report.v1"
             )

    stale_affected_duration = Map.put(checked_in_report, "affected_duration_s", 0)

    assert {:error, stale_affected_duration_report} =
             Schema.validate_artifact(stale_affected_duration,
               schema_contract: "station_calendar_report.v1"
             )

    assert Enum.any?(
             stale_affected_duration_report["errors"],
             &(&1["path"] == "$.affected_duration_s")
           )

    stale_trust_counts =
      put_in(checked_in_report, ["station_calendar_trust_boundary_status_counts", "declared"], 0)

    assert {:error, stale_trust_counts_report} =
             Schema.validate_artifact(stale_trust_counts,
               schema_contract: "station_calendar_report.v1"
             )

    assert Enum.any?(
             stale_trust_counts_report["errors"],
             &(&1["path"] == "$.station_calendar_trust_boundary_status_counts")
           )

    stale_model_limits = Map.put(checked_in_report, "model_limits", ["declared_data_only"])

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "station_calendar_report.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )
  end

  test "verifies curated station reservation report reference fixtures" do
    fixture_id = "fixture.artifact.station_reservation_report.stale_provider_reservation_hold"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.station_reservation_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = station_reservation_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               station_reservation_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_row_derived_observations =
      station_reservation_report_fixture_observations()
      |> put_in(["row_derived_reservation_status_counts", "tentative_hold"], 1)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_reservation_status_counts" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "station_reservation_report.v1",
             report
           ) == Validation.artifact_observations("station_reservation_report.v1", report)

    assert {:ok, %{"schema_contract" => "station_reservation_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "station_reservation_report.v1"
             )

    stale_match_status_counts =
      put_in(report, ["station_reservation_match_status_counts", "overlap"], 0)

    assert {:error, stale_match_status_counts_report} =
             Schema.validate_artifact(stale_match_status_counts,
               schema_contract: "station_reservation_report.v1"
             )

    assert Enum.any?(
             stale_match_status_counts_report["errors"],
             &(&1["path"] == "$.station_reservation_match_status_counts")
           )

    stale_reservation_status_counts =
      put_in(report, ["reservation_status_counts", "tentative_hold"], 1)

    assert {:error, stale_reservation_status_counts_report} =
             Schema.validate_artifact(stale_reservation_status_counts,
               schema_contract: "station_reservation_report.v1"
             )

    assert Enum.any?(
             stale_reservation_status_counts_report["errors"],
             &(&1["path"] == "$.reservation_status_counts")
           )

    stale_reservation_ids = Map.put(report, "reservation_ids", [])

    assert {:error, stale_reservation_ids_report} =
             Schema.validate_artifact(stale_reservation_ids,
               schema_contract: "station_reservation_report.v1"
             )

    assert Enum.any?(
             stale_reservation_ids_report["errors"],
             &(&1["path"] == "$.reservation_ids")
           )
  end

  test "verifies curated station reservation review summary reference fixtures" do
    fixture_id = "fixture.artifact.station_reservation_review_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.station_reservation_review_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    summary = station_reservation_review_summary_fixture()
    observations = station_reservation_review_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "reservation_count" => 3,
             "reservation_review_status" => "review_required",
             "reservation_expiration_status_counts" => %{
               "active" => 1,
               "expired" => 1,
               "missing" => 1
             },
             "row_derived_reservation_expiration_status_counts" => %{
               "active" => 1,
               "expired" => 1,
               "missing" => 1
             },
             "reservation_ids_by_expiration_status" => %{
               "active" => ["reservation_active"],
               "expired" => ["reservation_expired"],
               "missing" => ["reservation_missing"]
             },
             "row_derived_reservation_ids_by_expiration_status" => %{
               "active" => ["reservation_active"],
               "expired" => ["reservation_expired"],
               "missing" => ["reservation_missing"]
             },
             "row_derived_required_operator_action_counts" => %{
               "review_station_provider_contention" => 2,
               "review_station_reservation_overlap" => 1
             },
             "execution_boundary" => "artifact_only_no_provider_reservation",
             "operator_authority" => "not_granted_by_summary"
           } = observations

    stale_expiration_observations =
      observations
      |> put_in(["row_derived_reservation_expiration_status_counts", "active"], 0)

    assert {:ok, stale_expiration_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_expiration_observations)

    assert stale_expiration_verification["status"] == "fail"

    assert Enum.any?(
             stale_expiration_verification["checks"],
             &(&1["field"] == "row_derived_reservation_expiration_status_counts" and
                 &1["status"] == "fail")
           )

    stale_review_ids_observations =
      observations
      |> put_in(["row_derived_reservation_ids_by_expiration_status", "expired"], [])

    assert {:ok, stale_review_ids_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_review_ids_observations)

    assert stale_review_ids_verification["status"] == "fail"

    assert Enum.any?(
             stale_review_ids_verification["checks"],
             &(&1["field"] == "row_derived_reservation_ids_by_expiration_status" and
                 &1["status"] == "fail")
           )

    stale_boundary_observations =
      observations
      |> Map.put("execution_boundary", "provider_reservation_write_performed")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "execution_boundary" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "station_reservation_review_summary.v1",
             summary
           ) ==
             Validation.artifact_observations("station_reservation_review_summary.v1", summary)

    assert {:ok, %{"schema_contract" => "station_reservation_review_summary.v1"}} =
             Schema.validate_artifact(summary)
  end

  test "verifies curated station reservation hold summary reference fixtures" do
    fixture_id = "fixture.artifact.station_reservation_hold_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.station_reservation_hold_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    summary = station_reservation_hold_summary_fixture()
    observations = station_reservation_hold_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "reservation_hold_count" => 2,
             "reservation_hold_review_status" => "review_required",
             "reservation_hold_status_counts" => %{"held" => 2},
             "row_derived_reservation_hold_status_counts" => %{"held" => 2},
             "reservation_hold_expiration_status_counts" => %{
               "expired" => 1,
               "missing" => 1
             },
             "row_derived_reservation_hold_expiration_status_counts" => %{
               "expired" => 1,
               "missing" => 1
             },
             "reservation_hold_ids_by_reserved_by" => %{
               "ops_calendar" => ["reservation_expired"],
               "partner_calendar" => ["reservation_missing"]
             },
             "row_derived_reservation_hold_ids_by_reserved_by" => %{
               "ops_calendar" => ["reservation_expired"],
               "partner_calendar" => ["reservation_missing"]
             },
             "execution_boundary" => "artifact_only_no_provider_reservation",
             "operator_authority" => "not_granted_by_summary"
           } = observations

    stale_expiration_observations =
      observations
      |> put_in(["row_derived_reservation_hold_expiration_status_counts", "expired"], 0)

    assert {:ok, stale_expiration_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_expiration_observations)

    assert stale_expiration_verification["status"] == "fail"

    assert Enum.any?(
             stale_expiration_verification["checks"],
             &(&1["field"] == "row_derived_reservation_hold_expiration_status_counts" and
                 &1["status"] == "fail")
           )

    stale_owner_observations =
      observations
      |> put_in(["row_derived_reservation_hold_ids_by_reserved_by", "ops_calendar"], [])

    assert {:ok, stale_owner_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_owner_observations)

    assert stale_owner_verification["status"] == "fail"

    assert Enum.any?(
             stale_owner_verification["checks"],
             &(&1["field"] == "row_derived_reservation_hold_ids_by_reserved_by" and
                 &1["status"] == "fail")
           )

    stale_boundary_observations =
      observations
      |> Map.put("execution_boundary", "provider_reservation_write_performed")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "execution_boundary" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "station_reservation_hold_summary.v1",
             summary
           ) ==
             Validation.artifact_observations("station_reservation_hold_summary.v1", summary)

    assert {:ok, %{"schema_contract" => "station_reservation_hold_summary.v1"}} =
             Schema.validate_artifact(summary)
  end

  test "verifies curated station reservation hold import-readiness summary reference fixtures" do
    fixture_id = "fixture.artifact.station_reservation_hold_import_readiness_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] ==
             "artifact.station_reservation_hold_import_readiness_summary.v1"

    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    summary = station_reservation_hold_import_readiness_summary_fixture()
    observations = station_reservation_hold_import_readiness_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "import_readiness_status" => "review_required",
             "import_classification" => "review_only",
             "reservation_hold_import_status_counts" => %{
               "review_required_before_import" => 2
             },
             "row_derived_reservation_hold_import_status_counts" => %{
               "review_required_before_import" => 2
             },
             "required_import_action_counts" => %{
               "review_station_provider_contention" => 1,
               "review_station_reservation_overlap" => 1
             },
             "row_derived_required_import_action_counts" => %{
               "review_station_provider_contention" => 1,
               "review_station_reservation_overlap" => 1
             },
             "execution_boundary" => "artifact_only_no_provider_or_cadence_writes",
             "provider_write" => "not_performed_by_summary",
             "cadence_write" => "not_performed_by_summary"
           } = observations

    stale_import_status_observations =
      observations
      |> put_in(["row_derived_reservation_hold_import_status_counts", "ready_for_import"], 1)

    assert {:ok, stale_import_status_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_import_status_observations)

    assert stale_import_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_import_status_verification["checks"],
             &(&1["field"] == "row_derived_reservation_hold_import_status_counts" and
                 &1["status"] == "fail")
           )

    stale_action_ids_observations =
      observations
      |> put_in(
        [
          "row_derived_reservation_hold_ids_by_required_import_action",
          "review_station_reservation_overlap"
        ],
        []
      )

    assert {:ok, stale_action_ids_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_action_ids_observations)

    assert stale_action_ids_verification["status"] == "fail"

    assert Enum.any?(
             stale_action_ids_verification["checks"],
             &(&1["field"] == "row_derived_reservation_hold_ids_by_required_import_action" and
                 &1["status"] == "fail")
           )

    stale_boundary_observations =
      observations
      |> Map.put("cadence_write", "performed_by_summary")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "cadence_write" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "station_reservation_hold_import_readiness_summary.v1",
             summary
           ) ==
             Validation.artifact_observations(
               "station_reservation_hold_import_readiness_summary.v1",
               summary
             )

    assert {:ok,
            %{
              "schema_contract" => "station_reservation_hold_import_readiness_summary.v1"
            }} = Schema.validate_artifact(summary)
  end

  test "verifies curated station calendar precedence summary reference fixtures" do
    fixture_id = "fixture.artifact.station_calendar_precedence_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.station_calendar_precedence_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = station_calendar_precedence_summary_fixture()
    observations = station_calendar_precedence_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source" => "ops_calendar",
             "affected_contact_count" => 1,
             "precedence_review_status" => "review_required",
             "applied_availability_counts" => %{"unavailable" => 1},
             "applied_status_counts" => %{"unavailable" => 1},
             "overlap_availability_counts" => %{
               "reduced_capacity" => 1,
               "reserved" => 1,
               "unavailable" => 1
             },
             "affected_contact_ids_by_overlap_availability" => %{
               "reduced_capacity" => ["dl_1"],
               "reserved" => ["dl_1"],
               "unavailable" => ["dl_1"]
             },
             "reserved_under_higher_precedence_contact_count" => 1,
             "reserved_under_higher_precedence_contact_ids" => "dl_1",
             "unavailable_contact_ids" => "dl_1",
             "reserved_overlap_contact_ids" => "dl_1",
             "reduced_capacity_contact_ids" => "dl_1",
             "execution_boundary" => "artifact_only_no_provider_reservation",
             "scope" => "station_calendar_availability_precedence_review",
             "operator_authority" => "not_granted_by_summary",
             "no_provider_reservation" => true,
             "no_schedule_mutation" => true,
             "no_conflict_resolution" => true
           } = observations

    assert OrbitalDynamics.validation_artifact_observations(
             "station_calendar_precedence_summary.v1",
             report
           ) == Validation.artifact_observations("station_calendar_precedence_summary.v1", report)

    stale_count_observations =
      Map.put(observations, "reserved_under_higher_precedence_contact_count", 0)

    assert {:ok, stale_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_count_observations)

    assert stale_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_count_verification["checks"],
             &(&1["field"] == "reserved_under_higher_precedence_contact_count" and
                 &1["status"] == "fail")
           )

    stale_routing_observations =
      put_in(observations, ["affected_contact_ids_by_overlap_availability", "reserved"], [])

    assert {:ok, stale_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_routing_observations)

    assert stale_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_routing_verification["checks"],
             &(&1["field"] == "affected_contact_ids_by_overlap_availability" and
                 &1["status"] == "fail")
           )

    stale_boundary_observations =
      Map.put(observations, "execution_boundary", "provider_reservation_ready")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "execution_boundary" and &1["status"] == "fail")
           )

    assert {:ok, %{"schema_contract" => "station_calendar_precedence_summary.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "station_calendar_precedence_summary.v1"
             )
  end

  test "verifies curated station calendar provider reference fixtures" do
    fixture_id = "fixture.artifact.station_calendar_provider.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.station_calendar_provider.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = station_calendar_provider_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               station_calendar_provider_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      station_calendar_provider_fixture_observations()
      |> Map.put("reserved_entry_count", 0)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "reserved_entry_count" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "station_calendar_provider.v1")

    duplicate_entry_id =
      put_in(
        report,
        ["entries", Access.at(1), "id"],
        get_in(report, ["entries", Access.at(0), "id"])
      )

    assert {:error, duplicate_entry_id_report} =
             Schema.validate_artifact(duplicate_entry_id,
               schema_contract: "station_calendar_provider.v1"
             )

    assert Enum.any?(
             duplicate_entry_id_report["errors"],
             &(&1["path"] == "$.entries")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "station_calendar_provider.v1",
             report
           ) == Validation.artifact_observations("station_calendar_provider.v1", report)
  end

  test "verifies curated provider counteroffer report reference fixtures" do
    fixture_id = "fixture.artifact.provider_counteroffer_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.provider_counteroffer_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = provider_counteroffer_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               provider_counteroffer_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      provider_counteroffer_report_fixture_observations()
      |> Map.put("row_derived_counteroffer_cost_delta_total", 0.0)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "row_derived_counteroffer_cost_delta_total" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "provider_counteroffer_report.v1",
             report
           ) == Validation.artifact_observations("provider_counteroffer_report.v1", report)

    assert {:ok, %{"schema_contract" => "provider_counteroffer_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "provider_counteroffer_report.v1"
             )

    stale_cost_total = Map.put(report, "counteroffer_cost_delta_total", 0.0)

    assert {:error, stale_cost_total_report} =
             Schema.validate_artifact(stale_cost_total,
               schema_contract: "provider_counteroffer_report.v1"
             )

    assert Enum.any?(
             stale_cost_total_report["errors"],
             &(&1["path"] == "$.counteroffer_cost_delta_total")
           )

    stale_status_counts = put_in(report, ["counteroffer_status_counts", "proposed"], 0)

    assert {:error, stale_status_counts_report} =
             Schema.validate_artifact(stale_status_counts,
               schema_contract: "provider_counteroffer_report.v1"
             )

    assert Enum.any?(
             stale_status_counts_report["errors"],
             &(&1["path"] == "$.counteroffer_status_counts")
           )

    stale_required_action_counts =
      put_in(report, ["required_operator_action_counts", "review_provider_counteroffer"], 0)

    assert {:error, stale_required_action_counts_report} =
             Schema.validate_artifact(stale_required_action_counts,
               schema_contract: "provider_counteroffer_report.v1"
             )

    assert Enum.any?(
             stale_required_action_counts_report["errors"],
             &(&1["path"] == "$.required_operator_action_counts")
           )
  end

  test "verifies curated provider counteroffer summary reference fixtures" do
    fixtures = [
      {
        "fixture.artifact.provider_counteroffer_review_summary.v1",
        "artifact.provider_counteroffer_review_summary.v1",
        provider_counteroffer_review_summary_fixture(),
        provider_counteroffer_review_summary_fixture_observations()
      },
      {
        "fixture.artifact.provider_counteroffer_import_readiness_summary.v1",
        "artifact.provider_counteroffer_import_readiness_summary.v1",
        provider_counteroffer_import_readiness_summary_fixture(),
        provider_counteroffer_import_readiness_summary_fixture_observations()
      },
      {
        "fixture.artifact.provider_counteroffer_plan_impact_summary.v1",
        "artifact.provider_counteroffer_plan_impact_summary.v1",
        provider_counteroffer_plan_impact_summary_fixture(),
        provider_counteroffer_plan_impact_summary_fixture_observations()
      }
    ]

    for {fixture_id, model_id, artifact, observations} <- fixtures do
      assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

      assert fixture["model_id"] == model_id
      assert fixture["fixture_type"] == "curated_internal_artifact_regression"

      assert {:ok, verification} =
               Validation.verify_reference_fixture(fixture_id, observations)

      assert verification["status"] == "pass"
      assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

      assert {:ok, %{"schema_contract" => schema_contract}} =
               Schema.validate_artifact(artifact)

      assert OrbitalDynamics.validation_artifact_observations(schema_contract, artifact) ==
               Validation.artifact_observations(schema_contract, artifact)
    end

    stale_review_observations =
      provider_counteroffer_review_summary_fixture_observations()
      |> Map.put("counteroffer_review_status", "clear")

    assert {:ok, stale_review_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.provider_counteroffer_review_summary.v1",
               stale_review_observations
             )

    assert stale_review_verification["status"] == "fail"

    assert Enum.any?(
             stale_review_verification["checks"],
             &(&1["field"] == "counteroffer_review_status" and &1["status"] == "fail")
           )

    stale_import_routing_observations =
      provider_counteroffer_import_readiness_summary_fixture_observations()
      |> put_in(
        ["counteroffer_ids_by_required_import_action", "review_provider_counteroffer"],
        []
      )

    assert {:ok, stale_import_routing_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.provider_counteroffer_import_readiness_summary.v1",
               stale_import_routing_observations
             )

    assert stale_import_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_import_routing_verification["checks"],
             &(&1["field"] == "counteroffer_ids_by_required_import_action" and
                 &1["status"] == "fail")
           )

    stale_import_boundary_observations =
      provider_counteroffer_import_readiness_summary_fixture_observations()
      |> Map.put("cadence_write", "performed_by_summary")

    assert {:ok, stale_import_boundary_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.provider_counteroffer_import_readiness_summary.v1",
               stale_import_boundary_observations
             )

    assert stale_import_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_import_boundary_verification["checks"],
             &(&1["field"] == "cadence_write" and &1["status"] == "fail")
           )

    stale_impact_observations =
      provider_counteroffer_plan_impact_summary_fixture_observations()
      |> Map.put("row_derived_counteroffer_cost_delta_total", 0.0)

    assert {:ok, stale_impact_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.provider_counteroffer_plan_impact_summary.v1",
               stale_impact_observations
             )

    assert stale_impact_verification["status"] == "fail"

    assert Enum.any?(
             stale_impact_verification["checks"],
             &(&1["field"] == "row_derived_counteroffer_cost_delta_total" and
                 &1["status"] == "fail")
           )
  end

  test "verifies curated model acceptance report reference fixtures" do
    fixture_id = "fixture.artifact.model_acceptance_report.operational_import"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.model_acceptance_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = model_acceptance_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               model_acceptance_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert verification["status_counts"] == %{"pass" => 16}

    assert OrbitalDynamics.validation_artifact_observations(
             "model_acceptance_report.v1",
             report
           ) == Validation.artifact_observations("model_acceptance_report.v1", report)

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "model_acceptance_report.v1"
             )

    assert report["status_counts"] == %{
             "accepted" => 1,
             "blocked" => 2,
             "review_required" => 1
           }

    observations = model_acceptance_report_fixture_observations()

    assert observations["model_ids_by_status"] == %{
             "accepted" => ["orbit_data.simple_json"],
             "blocked" => ["propagator.two_body", "missing.model"],
             "review_required" => ["event.access_windows"]
           }

    assert observations["model_ids_by_validation_level"] == %{
             "analysis" => ["event.access_windows"],
             "artifact_contract" => ["orbit_data.simple_json"],
             "educational" => ["propagator.two_body"],
             "unknown" => ["missing.model"]
           }

    assert observations["model_ids_by_intended_use"] == %{
             "operational_import" => [
               "orbit_data.simple_json",
               "event.access_windows",
               "propagator.two_body",
               "missing.model"
             ]
           }

    stale_observed_model_ids_by_status =
      put_in(observations, ["model_ids_by_status", "blocked"], ["missing.model"])

    assert {:ok, stale_observed_model_ids_by_status_report} =
             Validation.verify_reference_fixture(fixture_id, stale_observed_model_ids_by_status)

    assert stale_observed_model_ids_by_status_report["status"] == "fail"

    assert Enum.any?(
             stale_observed_model_ids_by_status_report["checks"],
             &(&1["field"] == "model_ids_by_status" and &1["status"] == "fail")
           )

    stale_status = Map.put(report, "status", "accepted_for_use")

    assert {:error, stale_status_report} =
             Schema.validate_artifact(stale_status,
               schema_contract: "model_acceptance_report.v1"
             )

    assert Enum.any?(
             stale_status_report["errors"],
             &(&1["path"] == "$.status")
           )

    stale_validation_level_counts =
      put_in(report, ["validation_level_counts", "unknown"], 0)

    assert {:error, stale_validation_level_counts_report} =
             Schema.validate_artifact(stale_validation_level_counts,
               schema_contract: "model_acceptance_report.v1"
             )

    assert Enum.any?(
             stale_validation_level_counts_report["errors"],
             &(&1["path"] == "$.validation_level_counts")
           )

    stale_status_counts = put_in(report, ["status_counts", "blocked"], 1)

    assert {:error, stale_status_counts_report} =
             Schema.validate_artifact(stale_status_counts,
               schema_contract: "model_acceptance_report.v1"
             )

    assert Enum.any?(
             stale_status_counts_report["errors"],
             &(&1["path"] == "$.status_counts" and
                 &1["message"] == "must match row-derived status_counts")
           )

    stale_model_ids_by_validation_level =
      put_in(report, ["model_ids_by_validation_level", "unknown"], [])

    assert {:error, stale_model_ids_by_validation_level_report} =
             Schema.validate_artifact(stale_model_ids_by_validation_level,
               schema_contract: "model_acceptance_report.v1"
             )

    assert Enum.any?(
             stale_model_ids_by_validation_level_report["errors"],
             &(&1["path"] == "$.model_ids_by_validation_level")
           )

    stale_records = Map.put(report, "records", Enum.drop(Map.fetch!(report, "records"), 1))

    assert {:error, stale_records_report} =
             Schema.validate_artifact(stale_records,
               schema_contract: "model_acceptance_report.v1"
             )

    assert Enum.any?(
             stale_records_report["errors"],
             &(&1["path"] == "$.records")
           )

    stale_assumption_model_ids =
      put_in(report, ["assumptions", "input_model_ids"], ["orbit_data.simple_json"])

    assert {:error, stale_assumption_model_ids_report} =
             Schema.validate_artifact(stale_assumption_model_ids,
               schema_contract: "model_acceptance_report.v1"
             )

    assert Enum.any?(
             stale_assumption_model_ids_report["errors"],
             &(&1["path"] == "$.assumptions.input_model_ids")
           )

    stale_model_limits =
      Map.put(report, "model_limits", Enum.drop(Map.fetch!(report, "model_limits"), 1))

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "model_acceptance_report.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )
  end

  test "verifies curated validation safety-case summary reference fixtures" do
    fixture_id = "fixture.artifact.validation_safety_case_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.validation_safety_case_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = validation_safety_case_summary_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               validation_safety_case_summary_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert OrbitalDynamics.validation_artifact_observations(
             "validation_safety_case_summary.v1",
             report
           ) == Validation.artifact_observations("validation_safety_case_summary.v1", report)

    assert {:ok, %{"schema_contract" => "validation_safety_case_summary.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "validation_safety_case_summary.v1"
             )

    stale_model_limits = Map.put(report, "model_limits", ["artifact_only"])

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "validation_safety_case_summary.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match validation safety case summary model limits")
           )

    observations = validation_safety_case_summary_fixture_observations()

    assert observations["model_acceptance_evidence_status_counts"] == %{
             "accepted" => 1,
             "review_required" => 1
           }

    assert observations["model_acceptance_evidence_model_ids_by_status"] == %{
             "accepted" => ["orbit_data.simple_json"],
             "review_required" => ["event.access_windows"]
           }

    assert observations["model_acceptance_evidence_model_ids_by_validation_level"] == %{
             "analysis" => ["event.access_windows"],
             "artifact_contract" => ["orbit_data.simple_json"]
           }

    assert observations["model_acceptance_evidence_model_ids_by_intended_use"] == %{
             "operational_import" => ["orbit_data.simple_json", "event.access_windows"]
           }

    assert observations["evidence_refs_by_status"] == %{
             "accepted_for_use" => ["schema_validation_report.v1:candidate_refresh.v1"],
             "blocked" => [
               "schema_validation_report.v1:candidate_refresh.v1",
               "schema_validation_report.v1:candidate_refresh.v1"
             ],
             "review_required" => [
               "model_acceptance_report.v1:model_acceptance:operational_import:orbit_data.simple_json__event.access_windows"
             ]
           }

    assert observations["evidence_refs_by_contract"] == %{
             "model_acceptance_report.v1" => [
               "model_acceptance_report.v1:model_acceptance:operational_import:orbit_data.simple_json__event.access_windows"
             ],
             "schema_validation_report.v1" => [
               "schema_validation_report.v1:candidate_refresh.v1",
               "schema_validation_report.v1:candidate_refresh.v1",
               "schema_validation_report.v1:candidate_refresh.v1"
             ]
           }

    stale_model_acceptance_evidence_status_counts =
      put_in(observations, ["model_acceptance_evidence_status_counts", "accepted"], 0)

    assert {:ok, stale_model_acceptance_evidence_status_counts_report} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_model_acceptance_evidence_status_counts
             )

    assert stale_model_acceptance_evidence_status_counts_report["status"] == "fail"

    assert Enum.any?(
             stale_model_acceptance_evidence_status_counts_report["checks"],
             &(&1["field"] == "model_acceptance_evidence_status_counts" and
                 &1["status"] == "fail")
           )

    stale_model_acceptance_validation_level_ids =
      put_in(
        observations,
        ["model_acceptance_evidence_model_ids_by_validation_level", "artifact_contract"],
        []
      )

    assert {:ok, stale_model_acceptance_validation_level_ids_report} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_model_acceptance_validation_level_ids
             )

    assert stale_model_acceptance_validation_level_ids_report["status"] == "fail"

    assert Enum.any?(
             stale_model_acceptance_validation_level_ids_report["checks"],
             &(&1["field"] == "model_acceptance_evidence_model_ids_by_validation_level" and
                 &1["status"] == "fail")
           )

    model_acceptance_evidence_index =
      Enum.find_index(
        report["evidence"],
        &(&1["schema_contract"] == "model_acceptance_report.v1")
      )

    assert is_integer(model_acceptance_evidence_index)

    stale_copied_model_acceptance_ids =
      put_in(
        report,
        [
          "evidence",
          Access.at(model_acceptance_evidence_index),
          "model_ids_by_status",
          "accepted"
        ],
        []
      )

    assert {:error, stale_copied_model_acceptance_ids_report} =
             Schema.validate_artifact(stale_copied_model_acceptance_ids,
               schema_contract: "validation_safety_case_summary.v1"
             )

    assert Enum.any?(
             stale_copied_model_acceptance_ids_report["errors"],
             &(&1["path"] ==
                 "$.evidence[#{model_acceptance_evidence_index}].model_ids_by_status" and
                 &1["message"] == "must match model acceptance evidence status counts")
           )

    stale_schema_validation_evidence_index =
      Enum.find_index(
        report["evidence"],
        &(&1["schema_contract"] == "schema_validation_report.v1" and
            &1["status"] == "blocked")
      )

    assert is_integer(stale_schema_validation_evidence_index)

    stale_schema_validation_evidence =
      report
      |> put_in(
        ["evidence", Access.at(stale_schema_validation_evidence_index), "schema_error_count"],
        0
      )
      |> Map.put("schema_error_count", Map.fetch!(report, "schema_error_count") - 1)

    assert {:error, stale_schema_validation_evidence_report} =
             Schema.validate_artifact(stale_schema_validation_evidence,
               schema_contract: "validation_safety_case_summary.v1"
             )

    assert Enum.any?(
             stale_schema_validation_evidence_report["errors"],
             &(&1["path"] == "$.evidence[#{stale_schema_validation_evidence_index}].status" and
                 &1["message"] == "must match schema-validation evidence counts")
           )

    stale_observed_refs_by_contract =
      put_in(observations, ["evidence_refs_by_contract", "schema_validation_report.v1"], [
        "schema_validation_report.v1:candidate_refresh.v1"
      ])

    assert {:ok, stale_observed_refs_by_contract_report} =
             Validation.verify_reference_fixture(fixture_id, stale_observed_refs_by_contract)

    assert stale_observed_refs_by_contract_report["status"] == "fail"

    assert Enum.any?(
             stale_observed_refs_by_contract_report["checks"],
             &(&1["field"] == "evidence_refs_by_contract" and &1["status"] == "fail")
           )

    stale_status_counts = put_in(report, ["evidence_status_counts", "blocked"], 1)

    assert {:error, stale_status_counts_report} =
             Schema.validate_artifact(stale_status_counts,
               schema_contract: "validation_safety_case_summary.v1"
             )

    assert Enum.any?(
             stale_status_counts_report["errors"],
             &(&1["path"] == "$.evidence_status_counts")
           )

    stale_refs_by_status =
      put_in(report, ["evidence_refs_by_status", "blocked"], [
        "schema_validation_report.v1:candidate_refresh.v1"
      ])

    assert {:error, stale_refs_by_status_report} =
             Schema.validate_artifact(stale_refs_by_status,
               schema_contract: "validation_safety_case_summary.v1"
             )

    assert Enum.any?(
             stale_refs_by_status_report["errors"],
             &(&1["path"] == "$.evidence_refs_by_status")
           )

    stale_refs_by_contract =
      put_in(report, ["evidence_refs_by_contract", "schema_validation_report.v1"], [
        "schema_validation_report.v1:candidate_refresh.v1"
      ])

    assert {:error, stale_refs_by_contract_report} =
             Schema.validate_artifact(stale_refs_by_contract,
               schema_contract: "validation_safety_case_summary.v1"
             )

    assert Enum.any?(
             stale_refs_by_contract_report["errors"],
             &(&1["path"] == "$.evidence_refs_by_contract")
           )

    stale_fixture_failed_count = Map.put(report, "fixture_failed_count", 1)

    assert {:error, stale_fixture_failed_count_report} =
             Schema.validate_artifact(stale_fixture_failed_count,
               schema_contract: "validation_safety_case_summary.v1"
             )

    assert Enum.any?(
             stale_fixture_failed_count_report["errors"],
             &(&1["path"] == "$.fixture_failed_count")
           )
  end

  test "verifies curated candidate refresh artifact reference fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               candidate_refresh_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert OrbitalDynamics.validation_artifact_observations("candidate_refresh.v1", artifact) ==
             Validation.artifact_observations("candidate_refresh.v1", artifact)

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")

    stale_validation_level =
      put_in(
        artifact,
        ["validation_records", Access.at(0), "validation_level"],
        "flight_certified"
      )

    assert {:error, stale_validation_level_report} =
             Schema.validate_artifact(stale_validation_level,
               schema_contract: "candidate_refresh.v1"
             )

    assert Enum.any?(
             stale_validation_level_report["errors"],
             &(&1["path"] == "$.validation_records[0].validation_level")
           )
  end

  test "verifies curated candidate refresh resource provenance reference fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.resource_provenance_v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_resource_provenance_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               candidate_refresh_resource_provenance_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert get_in(artifact, [
             "provenance",
             "source_reports",
             "operational_readiness_report",
             "resource_availability_reason_counts"
           ]) == %{"antenna_unavailable" => 1, "payload_unavailable" => 1}

    assert get_in(artifact, [
             "provenance",
             "source_reports",
             "quality_gate_report",
             "resource_availability_reason_ids"
           ]) == ["antenna_unavailable", "payload_unavailable"]

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")

    stale_resource_pressure_count =
      put_in(
        artifact,
        [
          "provenance",
          "source_reports",
          "operational_readiness_report",
          "resource_availability_pressure_count"
        ],
        1
      )

    assert {:error, stale_resource_pressure_report} =
             Schema.validate_artifact(stale_resource_pressure_count,
               schema_contract: "candidate_refresh.v1"
             )

    assert Enum.any?(
             stale_resource_pressure_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.operational_readiness_report.resource_availability_pressure_count")
           )
  end

  test "verifies candidate refresh contact contention challenge replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.contact_contention_cross_station_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_contact_contention_challenge_fixture()
    observations = candidate_refresh_contact_contention_challenge_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_contact_contention_report_count" => 1,
             "source_contact_contention_row_count" => 1,
             "source_contact_contention_resource_scope_counts" => %{"spacecraft" => 1},
             "source_contact_contention_direction_counts" => %{"downlink" => 2},
             "source_contact_contention_contact_ids_by_direction" => %{
               "downlink" => ["dl_dsn", "dl_equator"]
             },
             "source_contact_contention_required_operator_action_counts" => %{
               "review_contact_contention" => 1
             },
             "source_contact_contention_trust_boundary_status" => "declared"
           } = observations

    stale_scope_observations =
      observations
      |> Map.put("source_contact_contention_resource_scope_counts", %{"ground_station" => 1})

    assert {:ok, stale_scope_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_scope_observations)

    assert stale_scope_verification["status"] == "fail"

    assert Enum.any?(
             stale_scope_verification["checks"],
             &(&1["field"] == "source_contact_contention_resource_scope_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh contact intent direction replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.contact_intent_direction_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_contact_intent_direction_fixture()
    observations = candidate_refresh_contact_intent_direction_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_contact_intent_report_count" => 3,
             "source_contact_intent_row_count" => 3,
             "source_contact_intent_capacity_pack_required_contact_count" => 2,
             "source_contact_intent_capacity_pack_required_capacity_fraction" => 0.65,
             "source_contact_intent_capacity_pack_required_capacity_fraction_by_direction" => %{
               "downlink" => 0.25,
               "tracking" => 0.4
             },
             "source_contact_intent_capacity_pack_required_capacity_fraction_by_direction_and_ground_station" =>
               %{
                 "downlink" => %{"equator_prime" => 0.25},
                 "tracking" => %{"dss_43" => 0.4}
               },
             "source_contact_intent_capacity_pack_contact_ids_by_direction" => %{
               "downlink" => ["intent_direct_capacity"],
               "tracking" => ["intent_nested_capacity"]
             },
             "source_contact_intent_capacity_pack_contact_ids_by_direction_and_ground_station" =>
               %{
                 "downlink" => %{"equator_prime" => ["intent_direct_capacity"]},
                 "tracking" => %{"dss_43" => ["intent_nested_capacity"]}
               },
             "source_contact_intent_direction_keys" => "command|downlink|tracking",
             "source_contact_intent_direction_counts" => %{
               "command" => 1,
               "downlink" => 1,
               "tracking" => 1
             },
             "source_contact_intent_contact_ids_by_direction" => %{
               "command" => ["intent_station_only"],
               "downlink" => ["intent_direct_capacity"],
               "tracking" => ["intent_nested_capacity"]
             },
             "source_contact_intent_contact_ids_by_direction_and_ground_station" => %{
               "command" => %{"dss_43" => ["intent_station_only"]},
               "downlink" => %{"equator_prime" => ["intent_direct_capacity"]},
               "tracking" => %{"dss_43" => ["intent_nested_capacity"]}
             },
             "source_contact_intent_direction_routing" => %{
               "command" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["intent_station_only"],
                 "capacity_pack_contact_ids" => [],
                 "ground_station_ids" => ["dss_43"],
                 "contact_ids_by_ground_station" => %{"dss_43" => ["intent_station_only"]}
               },
               "downlink" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["intent_direct_capacity"],
                 "capacity_pack_required_capacity_fraction" => 0.25,
                 "capacity_pack_contact_ids" => ["intent_direct_capacity"],
                 "ground_station_ids" => ["equator_prime"],
                 "contact_ids_by_ground_station" => %{
                   "equator_prime" => ["intent_direct_capacity"]
                 },
                 "capacity_pack_required_capacity_fraction_by_ground_station" => %{
                   "equator_prime" => 0.25
                 },
                 "capacity_pack_contact_ids_by_ground_station" => %{
                   "equator_prime" => ["intent_direct_capacity"]
                 }
               },
               "tracking" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["intent_nested_capacity"],
                 "capacity_pack_required_capacity_fraction" => 0.4,
                 "capacity_pack_contact_ids" => ["intent_nested_capacity"],
                 "ground_station_ids" => ["dss_43"],
                 "contact_ids_by_ground_station" => %{"dss_43" => ["intent_nested_capacity"]},
                 "capacity_pack_required_capacity_fraction_by_ground_station" => %{
                   "dss_43" => 0.4
                 },
                 "capacity_pack_contact_ids_by_ground_station" => %{
                   "dss_43" => ["intent_nested_capacity"]
                 }
               }
             },
             "source_contact_intent_trust_boundary_status" => "declared"
           } = observations

    stale_routing_observations =
      observations
      |> put_in(
        ["source_contact_intent_direction_routing", "downlink", "capacity_pack_contact_ids"],
        ["stale_intent"]
      )

    assert {:ok, stale_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_routing_observations)

    assert stale_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_routing_verification["checks"],
             &(&1["field"] == "source_contact_intent_direction_routing" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh resource projection replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.resource_projection_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_resource_projection_fixture()
    observations = candidate_refresh_resource_projection_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 4,
             "source_resource_projection_report_count" => 1,
             "source_resource_projection_row_count" => 4,
             "source_resource_projection_projected_resource_count" => 2,
             "source_resource_projection_invalid_activity_input_count" => 1,
             "source_resource_projection_invalid_resource_summary_input_count" => 1,
             "source_resource_projection_resource_pressure_status_counts" => %{
               "downlink_shortfall" => 1,
               "storage_shortfall" => 1
             },
             "source_resource_projection_resource_pressure_type_counts" => %{
               "downlink_shortfall" => 1,
               "storage_pressure" => 1,
               "storage_shortfall" => 1
             },
             "source_resource_projection_resource_pressure_direction_counts" => %{
               "downlink" => 1,
               "tracking" => 1
             },
             "source_resource_projection_resource_pressure_activity_ids_by_status" => %{
               "downlink_shortfall" => ["dl_pressure_1"],
               "storage_shortfall" => ["imaging_1", "imaging_2"]
             },
             "source_resource_projection_resource_pressure_activity_ids_by_type" => %{
               "downlink_shortfall" => ["dl_pressure_1"],
               "storage_pressure" => ["dl_pressure_1"],
               "storage_shortfall" => ["imaging_1", "imaging_2"]
             },
             "source_resource_projection_resource_pressure_activity_ids_by_direction" => %{
               "downlink" => ["dl_pressure_1"],
               "tracking" => ["imaging_1", "imaging_2"]
             },
             "source_resource_projection_trust_boundary_status" => "declared"
           } = observations

    stale_status_observations =
      observations
      |> Map.put("source_resource_projection_resource_pressure_status_counts", %{
        "stale_status" => 2
      })

    assert {:ok, stale_status_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_status_observations)

    assert stale_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_status_verification["checks"],
             &(&1["field"] == "source_resource_projection_resource_pressure_status_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh quality gate replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.quality_gate_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_quality_gate_fixture()
    observations = candidate_refresh_quality_gate_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 6,
             "source_quality_gate_report_count" => 1,
             "source_quality_gate_row_count" => 6,
             "source_quality_gate_gate_count" => 6,
             "source_quality_gate_passed_gate_count" => 3,
             "source_quality_gate_review_gate_count" => 3,
             "source_quality_gate_analysis_gate_count" => 0,
             "source_quality_gate_blocked_gate_count" => 0,
             "source_quality_gate_readiness_level_counts" => %{"operator_review" => 1},
             "source_quality_gate_import_classification_counts" => %{"review_only" => 1},
             "source_quality_gate_status_counts" => %{"review_required" => 1},
             "source_quality_gate_gate_status_counts" => %{
               "passed" => 3,
               "review_required" => 3
             },
             "source_quality_gate_gate_classification_counts" => %{
               "importable" => 3,
               "review_only" => 3
             },
             "source_quality_gate_ready_for_import_count" => 0,
             "source_quality_gate_trust_boundary_status" => "declared",
             "source_quality_gate_resource_availability_pressure_count" => 2,
             "source_quality_gate_resource_availability_reason_counts" => %{
               "antenna_unavailable" => 1,
               "payload_unavailable" => 1
             },
             "source_quality_gate_resource_availability_reason_ids" =>
               "antenna_unavailable|payload_unavailable",
             "source_quality_gate_branch_local_review_pressure" => true,
             "source_quality_gate_branch_local_import_pressure" => false,
             "source_quality_gate_branch_local_resource_pressure" => true
           } = observations

    stale_resource_pressure_observations =
      observations
      |> Map.put("source_quality_gate_branch_local_resource_pressure", false)

    assert {:ok, stale_resource_pressure_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_resource_pressure_observations)

    assert stale_resource_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_resource_pressure_verification["checks"],
             &(&1["field"] == "source_quality_gate_branch_local_resource_pressure" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh operational readiness replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.operational_readiness_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_operational_readiness_fixture()
    observations = candidate_refresh_operational_readiness_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 1,
             "source_operational_readiness_report_count" => 1,
             "source_operational_readiness_row_count" => 1,
             "source_operational_readiness_gate_count" => 6,
             "source_operational_readiness_passed_gate_count" => 3,
             "source_operational_readiness_review_gate_count" => 3,
             "source_operational_readiness_analysis_gate_count" => 0,
             "source_operational_readiness_blocked_gate_count" => 0,
             "source_operational_readiness_readiness_level_counts" => %{
               "operator_review" => 1
             },
             "source_operational_readiness_import_classification_counts" => %{
               "review_only" => 1
             },
             "source_operational_readiness_status_counts" => %{"review_required" => 1},
             "source_operational_readiness_trust_boundary_status" => "declared",
             "source_operational_readiness_resource_availability_pressure_count" => 2,
             "source_operational_readiness_resource_availability_reason_counts" => %{
               "antenna_unavailable" => 1,
               "payload_unavailable" => 1
             },
             "source_operational_readiness_resource_availability_reason_ids" =>
               "antenna_unavailable|payload_unavailable",
             "source_operational_readiness_branch_local_review_pressure" => true,
             "source_operational_readiness_branch_local_import_pressure" => true,
             "source_operational_readiness_branch_local_resource_pressure" => true
           } = observations

    stale_status_observations =
      observations
      |> Map.put("source_operational_readiness_status_counts", %{"stale_status" => 1})

    assert {:ok, stale_status_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_status_observations)

    assert stale_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_status_verification["checks"],
             &(&1["field"] == "source_operational_readiness_status_counts" and
                 &1["status"] == "fail")
           )

    stale_resource_pressure_observations =
      observations
      |> Map.put("source_operational_readiness_branch_local_resource_pressure", false)

    assert {:ok, stale_resource_pressure_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_resource_pressure_observations)

    assert stale_resource_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_resource_pressure_verification["checks"],
             &(&1["field"] == "source_operational_readiness_branch_local_resource_pressure" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh timeline activity precondition replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.timeline_activity_precondition_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_timeline_activity_precondition_fixture()
    observations = candidate_refresh_timeline_activity_precondition_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 3,
             "source_timeline_activity_precondition_report_count" => 2,
             "source_timeline_activity_precondition_row_count" => 3,
             "source_timeline_activity_precondition_status_counts" => %{
               "blocked" => 1,
               "review_required" => 1
             },
             "source_timeline_activity_precondition_blocked_precondition_count" => 2,
             "source_timeline_activity_precondition_review_precondition_count" => 1,
             "source_timeline_activity_precondition_blocked_precondition_type_counts" => %{
               "payload_unavailable" => 1,
               "resource_block_declared" => 1
             },
             "source_timeline_activity_precondition_review_precondition_type_counts" => %{
               "degraded_mode" => 1
             },
             "source_timeline_activity_precondition_invalid_activity_input_count" => 1,
             "source_timeline_activity_precondition_invalid_activity_input_reason_counts" => %{
               "missing_activity_type" => 1
             },
             "source_timeline_activity_precondition_dependency_activity_id_counts" => %{
               "health_check_1" => 1,
               "obs_1" => 1
             },
             "source_timeline_activity_precondition_dependency_timeline_id_counts" => %{
               "timeline:health_check_1" => 1
             },
             "source_timeline_activity_precondition_exclusive_with_activity_id_counts" => %{
               "dl_conflict" => 1
             },
             "source_timeline_activity_precondition_exclusive_with_timeline_id_counts" => %{
               "timeline:dl_conflict" => 1
             },
             "source_timeline_activity_precondition_duplicate_dependency_activity_id_counts" => %{
               "obs_1" => 1
             },
             "source_timeline_activity_precondition_duplicate_dependency_timeline_id_counts" => %{
               "timeline:health_check_1" => 1
             },
             "source_timeline_activity_precondition_duplicate_exclusivity_activity_id_counts" =>
               %{
                 "dl_conflict" => 1
               },
             "source_timeline_activity_precondition_duplicate_exclusivity_timeline_id_counts" =>
               %{
                 "timeline:dl_conflict" => 1
               },
             "source_timeline_activity_precondition_allow_overlap_counts" => %{"true" => 1},
             "source_timeline_activity_precondition_trust_boundary_status" => "declared"
           } = observations

    stale_dependency_observations =
      observations
      |> Map.put("source_timeline_activity_precondition_dependency_activity_id_counts", %{
        "stale_dependency" => 1
      })

    assert {:ok, stale_dependency_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_dependency_observations)

    assert stale_dependency_verification["status"] == "fail"

    assert Enum.any?(
             stale_dependency_verification["checks"],
             &(&1["field"] ==
                 "source_timeline_activity_precondition_dependency_activity_id_counts" and
                 &1["status"] == "fail")
           )

    stale_duplicate_observations =
      observations
      |> Map.put(
        "source_timeline_activity_precondition_duplicate_dependency_activity_id_counts",
        %{"stale_duplicate_dependency" => 1}
      )

    assert {:ok, stale_duplicate_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_duplicate_observations)

    assert stale_duplicate_verification["status"] == "fail"

    assert Enum.any?(
             stale_duplicate_verification["checks"],
             &(&1["field"] ==
                 "source_timeline_activity_precondition_duplicate_dependency_activity_id_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh timeline lifecycle state replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.timeline_lifecycle_state_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_timeline_lifecycle_state_fixture()
    observations = candidate_refresh_timeline_lifecycle_state_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 4,
             "source_timeline_lifecycle_state_report_count" => 1,
             "source_timeline_lifecycle_state_row_count" => 4,
             "source_timeline_lifecycle_state_planned_activity_count" => 5,
             "source_timeline_lifecycle_state_realized_activity_count" => 3,
             "source_timeline_lifecycle_state_recordable_count" => 1,
             "source_timeline_lifecycle_state_preserved_count" => 1,
             "source_timeline_lifecycle_state_review_required_count" => 2,
             "source_timeline_lifecycle_state_duplicate_timeline_identity_count" => 1,
             "source_timeline_lifecycle_state_invalid_activity_input_count" => 0,
             "source_timeline_lifecycle_state_transition_decision_counts" => %{
               "none" => 1,
               "record" => 1,
               "review" => 2
             },
             "source_timeline_lifecycle_state_required_operator_action_counts" => %{
               "none" => 1,
               "record_timeline_change" => 1,
               "review_activity_approval" => 1,
               "review_duplicate_timeline_identity" => 1
             },
             "source_timeline_lifecycle_state_import_action_counts" => %{
               "import_replacement_activity" => 1,
               "record_preserved_activity" => 1,
               "review_timeline_diff" => 2
             },
             "source_timeline_lifecycle_state_preserved_timeline_keys" => "timeline:done_keep",
             "source_timeline_lifecycle_state_review_timeline_keys" =>
               "timeline:cmd_provider|timeline:dup",
             "source_timeline_lifecycle_state_review_activity_keys" => "cmd_provider|dup_a|dup_b",
             "source_timeline_lifecycle_state_review_timeline_ids_by_required_operator_action" =>
               %{
                 "review_activity_approval" => ["timeline:cmd_provider"],
                 "review_duplicate_timeline_identity" => ["timeline:dup"]
               },
             "source_timeline_lifecycle_state_trust_boundary_status" => "declared"
           } = observations

    stale_review_observations =
      observations
      |> put_in(
        [
          "source_timeline_lifecycle_state_review_timeline_ids_by_required_operator_action",
          "review_activity_approval"
        ],
        ["timeline:stale_review"]
      )

    assert {:ok, stale_review_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_review_observations)

    assert stale_review_verification["status"] == "fail"

    assert Enum.any?(
             stale_review_verification["checks"],
             &(&1["field"] ==
                 "source_timeline_lifecycle_state_review_timeline_ids_by_required_operator_action" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh timeline activity lifecycle replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.timeline_activity_lifecycle_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_timeline_activity_lifecycle_fixture()
    observations = candidate_refresh_timeline_activity_lifecycle_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 1,
             "source_timeline_activity_lifecycle_report_count" => 1,
             "source_timeline_activity_lifecycle_row_count" => 1,
             "source_timeline_activity_lifecycle_review_required_count" => 1,
             "source_timeline_activity_lifecycle_invalid_activity_input_count" => 0,
             "source_timeline_activity_lifecycle_transition_decision_counts" => %{
               "review" => 1
             },
             "source_timeline_activity_lifecycle_status_transition_decision_counts" => %{
               "record" => 1
             },
             "source_timeline_activity_lifecycle_approval_transition_decision_counts" => %{
               "review" => 1
             },
             "source_timeline_activity_lifecycle_required_operator_action_counts" => %{
               "record_timeline_change" => 1,
               "review_activity_approval" => 1
             },
             "source_timeline_activity_lifecycle_import_action_counts" => %{
               "review_timeline_diff" => 1
             },
             "source_timeline_activity_lifecycle_planned_status_category_counts" => %{
               "planned" => 1
             },
             "source_timeline_activity_lifecycle_realized_status_category_counts" => %{
               "executed" => 1
             },
             "source_timeline_activity_lifecycle_planned_approval_category_counts" => %{
               "review_required" => 1
             },
             "source_timeline_activity_lifecycle_realized_approval_category_counts" => %{
               "protected" => 1
             },
             "source_timeline_activity_lifecycle_status_transition_category_counts" => %{
               "execution_recorded" => 1
             },
             "source_timeline_activity_lifecycle_approval_transition_category_counts" => %{
               "approval_granted" => 1
             },
             "source_timeline_activity_lifecycle_protection_decision_counts" => %{
               "mutable" => 1,
               "preserve" => 1
             },
             "source_timeline_activity_lifecycle_protection_category_counts" => %{
               "executed" => 1,
               "none" => 1
             },
             "source_timeline_activity_lifecycle_trust_boundary_status" => "declared"
           } = observations

    stale_action_observations =
      observations
      |> put_in(
        [
          "source_timeline_activity_lifecycle_required_operator_action_counts",
          "review_activity_approval"
        ],
        0
      )

    assert {:ok, stale_action_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_action_observations)

    assert stale_action_verification["status"] == "fail"

    assert Enum.any?(
             stale_action_verification["checks"],
             &(&1["field"] ==
                 "source_timeline_activity_lifecycle_required_operator_action_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh timeline transition application replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.timeline_transition_application_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_timeline_transition_application_fixture()
    observations = candidate_refresh_timeline_transition_application_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 1,
             "source_timeline_transition_application_report_count" => 1,
             "source_timeline_transition_application_row_count" => 1,
             "source_timeline_transition_application_application_count" => 1,
             "source_timeline_transition_application_selected_activity_count" => 1,
             "source_timeline_transition_application_selected_integrity_review_count" => 1,
             "source_timeline_transition_application_selected_integrity_issue_count" => 1,
             "source_timeline_transition_application_selected_integrity_issue_type_counts" => %{
               "missing_dependency_activity" => 1
             },
             "source_timeline_transition_application_review_required_count" => 1,
             "source_timeline_transition_application_status_counts" => %{
               "selected_timeline_integrity_review_required" => 1
             },
             "source_timeline_transition_application_required_operator_action_counts" => %{
               "review_timeline_integrity" => 1
             },
             "source_timeline_transition_application_trust_boundary_status" => "declared"
           } = observations

    stale_issue_type_observations =
      observations
      |> Map.put("source_timeline_transition_application_selected_integrity_issue_type_counts", %{
        "stale_issue" => 1
      })

    assert {:ok, stale_issue_type_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_issue_type_observations)

    assert stale_issue_type_verification["status"] == "fail"

    assert Enum.any?(
             stale_issue_type_verification["checks"],
             &(&1["field"] ==
                 "source_timeline_transition_application_selected_integrity_issue_type_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh objective gap replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.objective_gap_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_objective_gap_fixture()
    observations = candidate_refresh_objective_gap_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 3,
             "source_report_row_count" => 9,
             "source_objective_satisfaction_gap_row_count" => 3,
             "source_objective_satisfaction_status_counts" => %{
               "partial" => 2,
               "unmet" => 1
             },
             "source_objective_satisfaction_objective_type_counts" => %{
               "collection_latency" => 1,
               "downlink_completion" => 1,
               "target_coverage" => 1
             },
             "source_objective_tradeoff_collection_latency_gap_row_count" => 2,
             "source_score_term_term_key_counts" => %{
               "collection_latency_gap_s" => 1,
               "downlink_shortfall_mb" => 1,
               "target_gap_count" => 1
             },
             "source_score_term_source_activity_id_counts" => %{
               "score_collection_activity" => 1,
               "score_downlink_activity" => 1,
               "score_target_activity" => 1
             },
             "source_objective_gap_branch_local_objective_gap_pressure" => true,
             "source_objective_gap_branch_local_downlink_gap_pressure" => true,
             "source_objective_gap_branch_local_target_gap_pressure" => true,
             "source_objective_gap_branch_local_collection_latency_gap_pressure" => true,
             "source_objective_gap_branch_local_objective_status_pressure" => true,
             "source_objective_gap_branch_local_score_term_pressure" => true,
             "source_objective_gap_branch_local_routing_pressure" => true,
             "source_objective_satisfaction_trust_boundary_status" => "declared",
             "source_objective_tradeoff_trust_boundary_status" => "declared",
             "source_score_term_trust_boundary_status" => "declared",
             "source_score_term_branch_local_score_term_pressure" => true,
             "source_score_term_branch_local_downlink_gap_pressure" => true,
             "source_score_term_branch_local_target_gap_pressure" => true,
             "source_score_term_branch_local_collection_latency_gap_pressure" => true,
             "source_score_term_branch_local_routing_pressure" => true
           } = observations

    stale_score_term_pressure_observations =
      observations
      |> Map.put("source_score_term_branch_local_score_term_pressure", false)

    assert {:ok, stale_score_term_pressure_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_score_term_pressure_observations
             )

    assert stale_score_term_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_score_term_pressure_verification["checks"],
             &(&1["field"] == "source_score_term_branch_local_score_term_pressure" and
                 &1["status"] == "fail")
           )

    stale_objective_gap_pressure_observations =
      observations
      |> Map.put("source_objective_gap_branch_local_objective_gap_pressure", false)

    assert {:ok, stale_objective_gap_pressure_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_objective_gap_pressure_observations
             )

    assert stale_objective_gap_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_objective_gap_pressure_verification["checks"],
             &(&1["field"] == "source_objective_gap_branch_local_objective_gap_pressure" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh constraint replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.constraint_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_constraint_fixture()
    observations = candidate_refresh_constraint_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 3,
             "source_constraint_report_count" => 1,
             "source_constraint_row_count" => 3,
             "source_constraint_downlink_gap_row_count" => 1,
             "source_constraint_resource_margin_row_count" => 2,
             "source_constraint_status_counts" => %{"fail" => 1, "warning" => 2},
             "source_constraint_ground_station_counts" => %{"equator_prime" => 1},
             "source_constraint_metric_counts" => %{
               "battery_margin" => 1,
               "selected_downlink_shortfall_mb" => 1,
               "storage_margin" => 1
             },
             "source_constraint_id_counts" => %{
               "battery_margin" => 1,
               "downlink_shortfall" => 1,
               "storage_margin" => 1
             },
             "source_constraint_source_activity_id_counts" => %{
               "constraint_battery_activity" => 1,
               "constraint_downlink_activity" => 1,
               "constraint_storage_activity" => 1
             },
             "source_constraint_resource_counts" => %{"battery_1" => 1, "storage_1" => 1},
             "source_constraint_spacecraft_counts" => %{"sat_1" => 2},
             "source_constraint_trust_boundary_status" => "declared",
             "source_constraint_branch_local_constraint_pressure" => true,
             "source_constraint_branch_local_downlink_gap_pressure" => true,
             "source_constraint_branch_local_resource_margin_pressure" => true,
             "source_constraint_branch_local_constraint_routing_pressure" => true
           } = observations

    stale_constraint_pressure_observations =
      observations
      |> Map.put("source_constraint_branch_local_constraint_pressure", false)

    assert {:ok, stale_constraint_pressure_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_constraint_pressure_observations
             )

    assert stale_constraint_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_constraint_pressure_verification["checks"],
             &(&1["field"] == "source_constraint_branch_local_constraint_pressure" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh link capacity replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.link_capacity_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_link_capacity_fixture()
    observations = candidate_refresh_link_capacity_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 2,
             "source_link_capacity_report_count" => 1,
             "source_link_capacity_row_count" => 2,
             "source_link_capacity_selected_shortfall_row_count" => 1,
             "source_link_capacity_actual_shortfall_row_count" => 1,
             "source_link_capacity_actual_throughput_row_count" => 2,
             "source_link_capacity_capacity_adjusted_throughput_row_count" => 2,
             "source_link_capacity_capacity_adjusted_throughput_mb_total" => 85.0,
             "source_link_capacity_selected_capacity_adjusted_throughput_mb_total" => 40.0,
             "source_link_capacity_unused_capacity_adjusted_throughput_mb_total" => 45.0,
             "source_link_capacity_ground_station_counts" => %{
               "dss_43" => 1,
               "equator_prime" => 1
             },
             "source_link_capacity_spacecraft_counts" => %{"leo_1" => 1, "leo_2" => 1},
             "source_link_capacity_direction_counts" => %{
               "command" => 1,
               "downlink" => 1,
               "tracking" => 1
             },
             "source_link_capacity_contact_ids_by_ground_station" => %{
               "dss_43" => ["contact_gamma"],
               "equator_prime" => ["contact_alpha", "contact_beta"]
             },
             "source_link_capacity_selected_contact_ids" => [
               "contact_alpha",
               "contact_beta",
               "contact_gamma"
             ],
             "source_link_capacity_actual_throughput_contact_ids" => [
               "contact_alpha",
               "contact_gamma"
             ],
             "source_link_capacity_downlink_requirement_status_counts" => %{
               "actual_met" => 1,
               "actual_shortfall" => 1,
               "selected_met" => 1,
               "selected_shortfall" => 1
             },
             "source_link_capacity_contact_ids_by_requirement_status" => %{
               "actual_met" => ["contact_alpha"],
               "actual_shortfall" => ["contact_gamma"],
               "selected_met" => ["contact_gamma"],
               "selected_shortfall" => ["contact_alpha", "contact_beta"]
             },
             "source_link_capacity_trust_boundary_status" => "declared",
             "source_link_capacity_branch_local_link_capacity_pressure" => true,
             "source_link_capacity_branch_local_capacity_adjusted_throughput_pressure" => true,
             "source_link_capacity_branch_local_downlink_shortfall_pressure" => true,
             "source_link_capacity_branch_local_actual_throughput_pressure" => true
           } = observations

    stale_link_capacity_pressure_observations =
      observations
      |> Map.put("source_link_capacity_branch_local_link_capacity_pressure", false)

    assert {:ok, stale_link_capacity_pressure_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_link_capacity_pressure_observations
             )

    assert stale_link_capacity_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_link_capacity_pressure_verification["checks"],
             &(&1["field"] == "source_link_capacity_branch_local_link_capacity_pressure" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh resource filter replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.resource_filter_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_resource_filter_fixture()
    observations = candidate_refresh_resource_filter_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 4,
             "source_resource_filter_report_count" => 1,
             "source_resource_filter_row_count" => 4,
             "source_resource_filter_suppressed_candidate_count" => 3,
             "source_resource_filter_invalid_resource_summary_input_count" => 1,
             "source_resource_filter_invalid_resource_summary_input_ids" => ["bad_summary"],
             "source_resource_filter_suppressed_reason_counts" => %{
               "downlink_margin_low" => 1,
               "payload_unavailable" => 1,
               "power_margin_low" => 1
             },
             "source_resource_filter_candidate_ids_by_suppressed_reason" => %{
               "downlink_margin_low" => ["downlink_margin_block"],
               "payload_unavailable" => ["obs_payload_block"],
               "power_margin_low" => ["power_block"]
             },
             "source_resource_filter_spacecraft_counts" => %{"leo_1" => 2, "leo_2" => 1},
             "source_resource_filter_candidate_ids_by_spacecraft" => %{
               "leo_1" => ["downlink_margin_block", "obs_payload_block"],
               "leo_2" => ["power_block"]
             },
             "source_resource_filter_resource_counts" => %{
               "battery_main" => 1,
               "downlink_budget" => 1,
               "payload_1" => 1
             },
             "source_resource_filter_candidate_ids_by_resource" => %{
               "battery_main" => ["power_block"],
               "downlink_budget" => ["downlink_margin_block"],
               "payload_1" => ["obs_payload_block"]
             },
             "source_resource_filter_blocking_dimension_counts" => %{
               "communications" => 1,
               "payload" => 1,
               "power" => 1
             },
             "source_resource_filter_candidate_ids_by_blocking_dimension" => %{
               "communications" => ["downlink_margin_block"],
               "payload" => ["obs_payload_block"],
               "power" => ["power_block"]
             },
             "source_resource_filter_direction_counts" => %{
               "command" => 1,
               "downlink" => 1
             },
             "source_resource_filter_directions" => ["command", "downlink"],
             "source_resource_filter_candidate_ids_by_direction" => %{
               "command" => ["power_block"],
               "downlink" => ["downlink_margin_block"]
             },
             "source_resource_filter_direction_routing" => %{
               "command" => %{
                 "candidate_count" => 1,
                 "candidate_ids" => ["power_block"]
               },
               "downlink" => %{
                 "candidate_count" => 1,
                 "candidate_ids" => ["downlink_margin_block"]
               }
             },
             "source_resource_filter_trust_boundary_status" => "declared",
             "source_resource_filter_branch_local_resource_filter_pressure" => true,
             "source_resource_filter_branch_local_candidate_suppression_pressure" => true,
             "source_resource_filter_branch_local_invalid_resource_summary_pressure" => true,
             "source_resource_filter_branch_local_resource_blocking_pressure" => true
           } = observations

    stale_resource_filter_pressure_observations =
      observations
      |> Map.put("source_resource_filter_branch_local_resource_filter_pressure", false)

    assert {:ok, stale_resource_filter_pressure_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_resource_filter_pressure_observations
             )

    assert stale_resource_filter_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_resource_filter_pressure_verification["checks"],
             &(&1["field"] == "source_resource_filter_branch_local_resource_filter_pressure" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh contact filter replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.contact_filter_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_contact_filter_fixture()
    observations = candidate_refresh_contact_filter_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 4,
             "source_contact_filter_report_count" => 1,
             "source_contact_filter_row_count" => 4,
             "source_contact_filter_suppressed_candidate_count" => 4,
             "source_contact_filter_invalid_contact_input_count" => 1,
             "source_contact_filter_invalid_contact_input_ids" => ["invalid_contact"],
             "source_contact_filter_suppressed_reason_counts" => %{
               "ground_station_capacity_zero" => 1,
               "ground_station_reserved" => 1,
               "ground_station_unavailable" => 1,
               "invalid_contact_input" => 1
             },
             "source_contact_filter_contact_ids_by_suppressed_reason" => %{
               "ground_station_capacity_zero" => ["dl_station_capacity_zero"],
               "ground_station_reserved" => ["dl_station_reserved"],
               "ground_station_unavailable" => ["dl_station_unavailable"],
               "invalid_contact_input" => ["invalid_contact"]
             },
             "source_contact_filter_direction_counts" => %{
               "command" => 1,
               "downlink" => 1,
               "health_check" => 1,
               "tracking" => 1
             },
             "source_contact_filter_contact_ids_by_direction" => %{
               "command" => ["dl_station_reserved"],
               "downlink" => ["dl_station_unavailable"],
               "health_check" => ["invalid_contact"],
               "tracking" => ["dl_station_capacity_zero"]
             },
             "source_contact_filter_station_suppression_count" => 3,
             "source_contact_filter_station_suppression_ground_station_counts" => %{
               "dss_43" => 2,
               "equator_prime" => 1
             },
             "source_contact_filter_station_suppression_availability_counts" => %{
               "reduced_capacity" => 1,
               "reserved" => 1,
               "unavailable" => 1
             },
             "source_contact_filter_station_suppression_status_counts" => %{
               "reserved" => 1,
               "unavailable" => 1
             },
             "source_contact_filter_station_suppression_station_reservation_ids_by_status" => %{
               "reserved" => ["reservation_dss_43"]
             },
             "source_contact_filter_trust_boundary_status" => "declared",
             "source_contact_filter_branch_local_contact_filter_pressure" => true,
             "source_contact_filter_branch_local_candidate_suppression_pressure" => true,
             "source_contact_filter_branch_local_invalid_contact_input_pressure" => true,
             "source_contact_filter_branch_local_station_suppression_pressure" => true
           } = observations

    stale_contact_filter_pressure_observations =
      observations
      |> Map.put("source_contact_filter_branch_local_contact_filter_pressure", false)

    assert {:ok, stale_contact_filter_pressure_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_contact_filter_pressure_observations
             )

    assert stale_contact_filter_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_contact_filter_pressure_verification["checks"],
             &(&1["field"] == "source_contact_filter_branch_local_contact_filter_pressure" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh candidate rejection replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.candidate_rejection_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_candidate_rejection_fixture()
    observations = candidate_refresh_candidate_rejection_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 2,
             "source_candidate_rejection_report_count" => 1,
             "source_candidate_rejection_row_count" => 2,
             "source_candidate_rejection_rejected_count" => 2,
             "source_candidate_rejection_reviewable_count" => 1,
             "source_candidate_rejection_invalid_candidate_input_count" => 1,
             "source_candidate_rejection_rejection_reason_counts" => %{
               "invalid_candidate_input" => 1,
               "station_reserved" => 1
             },
             "source_candidate_rejection_required_operator_action_counts" => %{
               "none" => 1,
               "review_candidate_rejection" => 1
             },
             "source_candidate_rejection_candidate_id_counts" => %{
               "bad_candidate" => 1,
               "dl_reserved" => 1
             },
             "source_candidate_rejection_ground_station_counts" => %{
               "dss_43" => 1,
               "equator_prime" => 1
             },
             "source_candidate_rejection_trust_boundary_status" => "declared",
             "source_candidate_rejection_branch_local_rejection_pressure" => true,
             "source_candidate_rejection_branch_local_review_pressure" => true,
             "source_candidate_rejection_branch_local_invalid_input_pressure" => true
           } = observations

    stale_rejection_pressure_observations =
      observations
      |> Map.put("source_candidate_rejection_branch_local_rejection_pressure", false)

    assert {:ok, stale_rejection_pressure_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_rejection_pressure_observations
             )

    assert stale_rejection_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_rejection_pressure_verification["checks"],
             &(&1["field"] == "source_candidate_rejection_branch_local_rejection_pressure" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh freshness replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.freshness_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_freshness_fixture()
    observations = candidate_refresh_freshness_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 2,
             "source_freshness_report_count" => 2,
             "source_freshness_row_count" => 2,
             "source_freshness_path_keys" =>
               "source_freshness_report[0]|source_freshness_report[1]",
             "source_freshness_status_counts" => %{
               "stale" => 1,
               "unknown" => 1
             },
             "source_freshness_stale_reason_count" => 2,
             "source_freshness_stale_reason_keys" =>
               "accepted_snapshot_older_than_policy|horizon_start_before_now",
             "source_freshness_stale_reason_counts" => %{
               "accepted_snapshot_older_than_policy" => 1,
               "horizon_start_before_now" => 1
             },
             "source_freshness_unknown_reason_count" => 1,
             "source_freshness_unknown_reason_keys" => "missing_generated_at",
             "source_freshness_unknown_reason_counts" => %{"missing_generated_at" => 1},
             "source_freshness_trust_boundary_status" => "declared",
             "source_freshness_branch_local_stale_pressure" => true,
             "source_freshness_branch_local_unknown_pressure" => true,
             "source_freshness_branch_local_freshness_pressure" => true
           } = observations

    stale_freshness_pressure_observations =
      observations
      |> Map.put("source_freshness_branch_local_freshness_pressure", false)

    assert {:ok, stale_freshness_pressure_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_freshness_pressure_observations
             )

    assert stale_freshness_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_freshness_pressure_verification["checks"],
             &(&1["field"] == "source_freshness_branch_local_freshness_pressure" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh refresh-budget replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.refresh_budget_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_refresh_budget_fixture()
    observations = candidate_refresh_refresh_budget_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 2,
             "source_refresh_budget_report_count" => 2,
             "source_refresh_budget_row_count" => 2,
             "source_refresh_budget_path_keys" =>
               "source_refresh_budget_report[0]|source_refresh_budget_report[1]",
             "source_refresh_budget_input_candidate_count" => 5,
             "source_refresh_budget_kept_candidate_count" => 3,
             "source_refresh_budget_dropped_candidate_count" => 2,
             "source_refresh_budget_invalid_candidate_limit_policy_count" => 1,
             "source_refresh_budget_invalid_candidate_limit_policy_reason_counts" => %{
               "max_candidate_activities_must_be_integer" => 1
             },
             "source_refresh_budget_kept_candidate_id_keys" =>
               "candidate_a|candidate_b|candidate_e",
             "source_refresh_budget_dropped_candidate_id_keys" => "candidate_c|candidate_d",
             "source_refresh_budget_trust_boundary_status" => "declared",
             "source_refresh_budget_branch_local_budget_pressure" => true,
             "source_refresh_budget_branch_local_dropped_candidate_pressure" => true,
             "source_refresh_budget_branch_local_invalid_limit_pressure" => true,
             "source_refresh_budget_branch_local_candidate_limit_applied" => true
           } = observations

    stale_budget_pressure_observations =
      observations
      |> Map.put("source_refresh_budget_branch_local_budget_pressure", false)

    assert {:ok, stale_budget_pressure_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_budget_pressure_observations
             )

    assert stale_budget_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_budget_pressure_verification["checks"],
             &(&1["field"] == "source_refresh_budget_branch_local_budget_pressure" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh station-calendar replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.station_calendar_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_station_calendar_fixture()
    observations = candidate_refresh_station_calendar_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 4,
             "source_station_calendar_report_count" => 1,
             "source_station_calendar_row_count" => 4,
             "source_station_calendar_path_keys" => "source_station_calendar_report",
             "source_station_calendar_affected_contact_count" => 3,
             "source_station_calendar_provider_calendar_contention_group_count" => 1,
             "source_station_calendar_provider_calendar_contention_group_id_keys" =>
               "station_calendar_provider_contention:equator_prime:1",
             "source_station_calendar_provider_calendar_contention_source_entry_id_keys" =>
               "provider_a|provider_b",
             "source_station_calendar_provider_calendar_contention_provider_entry_id_keys" =>
               "provider_entry_ops|provider_entry_partner",
             "source_station_calendar_provider_calendar_contention_provider_counts" => %{
               "ops_calendar" => 1,
               "partner_calendar" => 1
             },
             "source_station_calendar_provider_calendar_contention_ground_station_counts" => %{
               "dss_43" => 1,
               "equator_prime" => 1
             },
             "source_station_calendar_provider_calendar_contention_direction_counts" => %{
               "downlink" => 1,
               "tracking" => 1
             },
             "source_station_calendar_provider_calendar_contention_minimum_capacity_fraction" =>
               0.25,
             "source_station_calendar_affected_contact_ground_station_counts" => %{
               "dss_43" => 1,
               "equator_prime" => 2
             },
             "source_station_calendar_affected_contact_availability_counts" => %{
               "reduced_capacity" => 1,
               "reserved" => 1,
               "unavailable" => 1
             },
             "source_station_calendar_direction_counts" => %{
               "downlink" => 2,
               "uplink" => 1
             },
             "source_station_calendar_status_counts" => %{
               "reduced_capacity" => 1,
               "reserved" => 1,
               "unavailable" => 1
             },
             "source_station_calendar_trust_boundary_status" => "declared",
             "source_station_calendar_branch_local_station_calendar_pressure" => true,
             "source_station_calendar_branch_local_affected_contact_pressure" => true,
             "source_station_calendar_branch_local_provider_contention_pressure" => true,
             "source_station_calendar_branch_local_station_availability_pressure" => true
           } = observations

    stale_station_calendar_pressure_observations =
      observations
      |> Map.put("source_station_calendar_branch_local_station_calendar_pressure", false)

    assert {:ok, stale_station_calendar_pressure_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_station_calendar_pressure_observations
             )

    assert stale_station_calendar_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_station_calendar_pressure_verification["checks"],
             &(&1["field"] == "source_station_calendar_branch_local_station_calendar_pressure" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh contact allocation contradiction replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.contact_allocation_contradiction_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_contact_allocation_contradiction_fixture()
    observations = candidate_refresh_contact_allocation_contradiction_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 2,
             "source_report_row_count" => 9,
             "source_station_calendar_provider_calendar_contention_group_count" => 1,
             "source_station_calendar_branch_local_provider_contention_pressure" => true,
             "source_contact_allocation_report_count" => 2,
             "source_contact_allocation_row_count" => 6,
             "source_contact_allocation_source_summary_schema_contract_counts" => %{
               "contact_allocation_provider_reservation_request_summary.v1" => 1,
               "contact_allocation_reservation_conflict_summary.v1" => 1
             },
             "source_contact_allocation_reservation_conflict_contact_count" => 3,
             "source_contact_allocation_reservation_conflict_contact_ids_by_direction_and_ground_station" =>
               %{
                 "command" => %{"equator_prime" => ["dl_review_overlap"]},
                 "downlink" => %{"equator_prime" => ["dl_reserved_intruder"]},
                 "tracking" => %{"equator_prime" => ["dl_reserved_intruder"]}
               },
             "source_contact_allocation_provider_reservation_request_contact_count" => 2,
             "source_contact_allocation_provider_reservation_review_contact_count" => 1,
             "source_contact_allocation_branch_local_reservation_conflict_pressure" => true,
             "source_contact_allocation_branch_local_provider_reservation_request_pressure" =>
               true
           } = observations

    stale_conflict_observations =
      observations
      |> Map.put("source_contact_allocation_reservation_conflict_contact_count", 1)

    assert {:ok, stale_conflict_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_conflict_observations)

    assert stale_conflict_verification["status"] == "fail"

    assert Enum.any?(
             stale_conflict_verification["checks"],
             &(&1["field"] ==
                 "source_contact_allocation_reservation_conflict_contact_count" and
                 &1["status"] == "fail")
           )

    stale_provider_request_observations =
      observations
      |> Map.put(
        "source_contact_allocation_branch_local_provider_reservation_request_pressure",
        false
      )

    assert {:ok, stale_provider_request_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_provider_request_observations)

    assert stale_provider_request_verification["status"] == "fail"

    assert Enum.any?(
             stale_provider_request_verification["checks"],
             &(&1["field"] ==
                 "source_contact_allocation_branch_local_provider_reservation_request_pressure" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies curated candidate rejection report reference fixtures" do
    fixture_id = "fixture.artifact.candidate_rejection_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_rejection_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = candidate_rejection_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               candidate_rejection_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      candidate_rejection_report_fixture_observations()
      |> Map.put("required_operator_review_count", 2)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "required_operator_review_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "candidate_rejection_report.v1",
             report
           ) == Validation.artifact_observations("candidate_rejection_report.v1", report)

    assert {:ok, %{"schema_contract" => "candidate_rejection_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "candidate_rejection_report.v1"
             )

    stale_rejected_count = Map.put(report, "rejected_count", 2)

    assert {:error, stale_rejected_count_report} =
             Schema.validate_artifact(stale_rejected_count,
               schema_contract: "candidate_rejection_report.v1"
             )

    assert Enum.any?(
             stale_rejected_count_report["errors"],
             &(&1["path"] == "$.rejected_count")
           )

    stale_rejection_reason_counts =
      put_in(report, ["rejection_reason_counts", "station_reserved"], 0)

    assert {:error, stale_rejection_reason_counts_report} =
             Schema.validate_artifact(stale_rejection_reason_counts,
               schema_contract: "candidate_rejection_report.v1"
             )

    assert Enum.any?(
             stale_rejection_reason_counts_report["errors"],
             &(&1["path"] == "$.rejection_reason_counts")
           )

    stale_candidate_id_sets =
      put_in(report, ["candidate_id_sets_by_rejection_reason", "station_reserved"], [])

    assert {:error, stale_candidate_id_sets_report} =
             Schema.validate_artifact(stale_candidate_id_sets,
               schema_contract: "candidate_rejection_report.v1"
             )

    assert Enum.any?(
             stale_candidate_id_sets_report["errors"],
             &(&1["path"] == "$.candidate_id_sets_by_rejection_reason")
           )

    stale_required_operator_action_counts =
      put_in(report, ["required_operator_action_counts", "review_candidate_rejection"], 2)

    assert {:error, stale_required_operator_action_counts_report} =
             Schema.validate_artifact(stale_required_operator_action_counts,
               schema_contract: "candidate_rejection_report.v1"
             )

    assert Enum.any?(
             stale_required_operator_action_counts_report["errors"],
             &(&1["path"] == "$.required_operator_action_counts")
           )

    stale_reviewable_candidate_ids = Map.put(report, "reviewable_candidate_ids", ["obs_clouded"])

    assert {:error, stale_reviewable_candidate_ids_report} =
             Schema.validate_artifact(stale_reviewable_candidate_ids,
               schema_contract: "candidate_rejection_report.v1"
             )

    assert Enum.any?(
             stale_reviewable_candidate_ids_report["errors"],
             &(&1["path"] == "$.reviewable_candidate_ids")
           )
  end

  test "verifies curated candidate diff row reference fixtures" do
    fixture_id = "fixture.artifact.candidate_diff_row.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_diff_row.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = candidate_diff_row_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               candidate_diff_row_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      candidate_diff_row_fixture_observations()
      |> Map.put("candidate_diff_changed_field_count", 2)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "candidate_diff_changed_field_count" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "candidate_diff_row.v1")

    stale_changed_field_count = Map.put(report, "candidate_diff_changed_field_count", 2)

    assert {:error, stale_changed_field_count_report} =
             Schema.validate_artifact(stale_changed_field_count,
               schema_contract: "candidate_diff_row.v1"
             )

    assert Enum.any?(
             stale_changed_field_count_report["errors"],
             &(&1["path"] == "$.candidate_diff_changed_field_count")
           )

    stale_changed_field_alias =
      Map.put(report, "candidate_diff_changed_fields", ["starts_at_s"])

    assert {:error, stale_changed_field_alias_report} =
             Schema.validate_artifact(stale_changed_field_alias,
               schema_contract: "candidate_diff_row.v1"
             )

    assert Enum.any?(
             stale_changed_field_alias_report["errors"],
             &(&1["path"] == "$.candidate_diff_changed_fields")
           )

    stale_semantic_reasons = Map.put(report, "semantic_change_reasons", ["starts_at_s_changed"])

    assert {:error, stale_semantic_reasons_report} =
             Schema.validate_artifact(stale_semantic_reasons,
               schema_contract: "candidate_diff_row.v1"
             )

    assert Enum.any?(
             stale_semantic_reasons_report["errors"],
             &(&1["path"] == "$.semantic_change_reasons")
           )

    assert OrbitalDynamics.validation_artifact_observations("candidate_diff_row.v1", report) ==
             Validation.artifact_observations("candidate_diff_row.v1", report)
  end

  test "verifies curated accepted planning state reference fixtures" do
    fixture_id = "fixture.artifact.accepted_planning_state.simple"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.accepted_planning_state.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = accepted_planning_state_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               accepted_planning_state_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      accepted_planning_state_fixture_observations()
      |> Map.put("provenance_network_access", true)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "provenance_network_access" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "accepted_planning_state.v1")

    stale_state_estimate_count =
      put_in(report, ["provenance", "state_estimate_count"], 0)

    assert {:error, stale_state_estimate_count_report} =
             Schema.validate_artifact(stale_state_estimate_count,
               schema_contract: "accepted_planning_state.v1"
             )

    assert Enum.any?(
             stale_state_estimate_count_report["errors"],
             &(&1["path"] == "$.provenance.state_estimate_count")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "accepted_planning_state.v1",
             report
           ) == Validation.artifact_observations("accepted_planning_state.v1", report)
  end

  test "verifies curated CCSDS OPM accepted planning state reference fixtures" do
    fixture_id = "fixture.artifact.accepted_planning_state.opm"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.accepted_planning_state.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = accepted_planning_state_opm_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               accepted_planning_state_opm_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      accepted_planning_state_opm_fixture_observations()
      |> Map.put("provenance_input_format", "simple_json_state_estimate_batch")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "provenance_input_format" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "accepted_planning_state.v1",
             report
           ) == Validation.artifact_observations("accepted_planning_state.v1", report)
  end

  test "verifies curated CCSDS OEM accepted planning state reference fixtures" do
    fixture_id = "fixture.artifact.accepted_planning_state.oem"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.accepted_planning_state.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = accepted_planning_state_oem_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               accepted_planning_state_oem_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      accepted_planning_state_oem_fixture_observations()
      |> Map.put("provenance_input_format", "ccsds_opm_kvn")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "provenance_input_format" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "accepted_planning_state.v1",
             report
           ) == Validation.artifact_observations("accepted_planning_state.v1", report)
  end

  test "verifies curated campaign request lint reference fixtures" do
    fixture_id = "fixture.artifact.campaign_request_lint.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.campaign_request_lint.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = campaign_request_lint_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               campaign_request_lint_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      campaign_request_lint_fixture_observations()
      |> Map.put("status", "fail")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "status" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "campaign_request_lint.v1")

    stale_status = Map.put(report, "status", "fail")

    assert {:error, stale_status_report} =
             Schema.validate_artifact(stale_status, schema_contract: "campaign_request_lint.v1")

    assert Enum.any?(
             stale_status_report["errors"],
             &(&1["path"] == "$.status")
           )

    stale_request_sha =
      put_in(report, ["request", "sha256"], String.upcase(report["request"]["sha256"]))

    assert {:error, stale_request_sha_report} =
             Schema.validate_artifact(stale_request_sha,
               schema_contract: "campaign_request_lint.v1"
             )

    assert Enum.any?(
             stale_request_sha_report["errors"],
             &(&1["path"] == "$.request.sha256")
           )

    stale_source_plan_sha =
      put_in(report, ["source_plan", "sha256"], "not-a-sha")

    assert {:error, stale_source_plan_sha_report} =
             Schema.validate_artifact(stale_source_plan_sha,
               schema_contract: "campaign_request_lint.v1"
             )

    assert Enum.any?(
             stale_source_plan_sha_report["errors"],
             &(&1["path"] == "$.source_plan.sha256")
           )

    assert OrbitalDynamics.validation_artifact_observations("campaign_request_lint.v1", report) ==
             Validation.artifact_observations("campaign_request_lint.v1", report)
  end

  test "verifies curated capability catalog reference fixtures" do
    fixture_id = "fixture.artifact.capability_catalog.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.capability_catalog.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = capability_catalog_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               capability_catalog_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    fixture_observations = capability_catalog_fixture_observations()

    assert fixture_observations["station_calendar_reservation_contract"] ==
             "station_reservation_report.v1"

    assert fixture_observations["candidate_refresh_input_count"] == 81
    assert fixture_observations["candidate_refresh_source_report_input_count"] == 64
    assert fixture_observations["candidate_refresh_source_report_helper_count"] == 40

    assert fixture_observations["candidate_refresh_source_report_input_order"] =~
             "schema_validation_batch_report"

    assert fixture_observations["candidate_refresh_source_report_input_order"] =~
             "timeline_dependency_impact_summary"

    assert fixture_observations["candidate_refresh_source_report_input_order"] =~
             "timeline_publication_summary"

    assert fixture_observations["candidate_refresh_source_report_input_order"] =~
             "timeline_activity_precondition_summary"

    assert fixture_observations["candidate_refresh_source_report_input_order"] =~
             "contact_contention_report"

    assert fixture_observations["candidate_refresh_source_report_input_order"] =~
             "relay_data_path_summary"

    assert fixture_observations["candidate_refresh_source_report_input_order"] =~
             "operational_import_eligibility_summary"

    assert fixture_observations["candidate_refresh_source_report_input_order"] =~
             "station_reservation_review_summary"

    assert fixture_observations["candidate_refresh_source_report_input_order"] =~
             "operational_quality_gate_schema_validation_summary"

    stale_observations =
      fixture_observations
      |> Map.put("artifact_contract_count", 78)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "artifact_contract_count" and &1["status"] == "fail")
           )

    stale_candidate_refresh_observations =
      fixture_observations
      |> Map.put("candidate_refresh_source_report_input_count", 33)

    assert {:ok, stale_candidate_refresh_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_candidate_refresh_observations)

    assert stale_candidate_refresh_verification["status"] == "fail"

    assert Enum.any?(
             stale_candidate_refresh_verification["checks"],
             &(&1["field"] == "candidate_refresh_source_report_input_count" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations("capability_catalog.v1", report) ==
             Validation.artifact_observations("capability_catalog.v1", report)

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "capability_catalog.v1")

    stale_contract_list =
      update_in(report, ["validation", "schema", "artifact_contracts"], &tl/1)

    assert {:error, stale_contract_list_report} =
             Schema.validate_artifact(stale_contract_list,
               schema_contract: "capability_catalog.v1"
             )

    assert Enum.any?(
             stale_contract_list_report["errors"],
             &(&1["path"] == "$.validation.schema.artifact_contracts")
           )
  end

  test "verifies curated environment capability reference fixtures" do
    fixtures = [
      {
        "fixture.artifact.environment_model_capability.fixed_sun",
        "environment_model_capability.v1",
        environment_model_capability_fixture("environment.solar.fixed_inertial_direction")
      },
      {
        "fixture.artifact.environment_model_capability.constant_earth_rotation",
        "environment_model_capability.v1",
        environment_model_capability_fixture("environment.earth_rotation.constant_rate")
      },
      {
        "fixture.artifact.environment_provider_capability.fixed_sun",
        "environment_provider_capability.v1",
        environment_provider_capability_fixture(
          "environment.provider.solar.fixed_inertial_direction"
        )
      },
      {
        "fixture.artifact.environment_provider_capability.constant_earth_rotation",
        "environment_provider_capability.v1",
        environment_provider_capability_fixture(
          "environment.provider.earth_rotation.constant_rate"
        )
      },
      {
        "fixture.artifact.environment_provider_capability.tabular_earth_orientation",
        "environment_provider_capability.v1",
        environment_provider_capability_fixture(
          "environment.provider.earth_orientation.tabular_rotation"
        )
      },
      {
        "fixture.artifact.environment_provider_capability.exponential_atmosphere",
        "environment_provider_capability.v1",
        environment_provider_capability_fixture(
          "environment.provider.atmosphere.exponential_reference"
        )
      }
    ]

    for {fixture_id, contract, artifact} <- fixtures do
      assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

      assert fixture["model_id"] == "artifact.#{contract}"
      assert fixture["fixture_type"] == "curated_runtime_capability_regression"

      observations = Validation.artifact_observations(contract, artifact)

      assert {:ok, verification} =
               Validation.verify_reference_fixture(fixture_id, observations)

      assert verification["status"] == "pass"
      assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

      assert OrbitalDynamics.validation_artifact_observations(contract, artifact) == observations
    end

    stale_observations =
      "environment_provider_capability.v1"
      |> Validation.artifact_observations(
        environment_provider_capability_fixture(
          "environment.provider.solar.fixed_inertial_direction"
        )
      )
      |> Map.put("network_access", true)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.environment_provider_capability.fixed_sun",
               stale_observations
             )

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "network_access" and &1["status"] == "fail")
           )

    model_capability =
      environment_model_capability_fixture("environment.solar.fixed_inertial_direction")

    assert {:ok, _valid_model_capability} =
             Schema.validate_artifact(model_capability,
               schema_contract: "environment_model_capability.v1"
             )

    stale_model_validation_level =
      Map.put(model_capability, "validation_level", "flight_certified")

    assert {:error, stale_model_validation_level_report} =
             Schema.validate_artifact(stale_model_validation_level,
               schema_contract: "environment_model_capability.v1"
             )

    assert Enum.any?(
             stale_model_validation_level_report["errors"],
             &(&1["path"] == "$.validation_level")
           )
  end

  test "verifies curated proposed contact reference fixtures" do
    fixture_id = "fixture.artifact.proposed_contact.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.proposed_contact.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = proposed_contact_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               proposed_contact_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      proposed_contact_fixture_observations()
      |> Map.put("station_availability", "reserved")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "station_availability" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "proposed_contact.v1")

    stale_source_window_id =
      Map.put(report, "source_window_id", "window:leo_1:ground_station_access:equator_prime:2")

    assert {:error, stale_source_window_id_report} =
             Schema.validate_artifact(stale_source_window_id,
               schema_contract: "proposed_contact.v1"
             )

    assert Enum.any?(
             stale_source_window_id_report["errors"],
             &(&1["path"] == "$.source_window_id")
           )

    assert OrbitalDynamics.validation_artifact_observations("proposed_contact.v1", report) ==
             Validation.artifact_observations("proposed_contact.v1", report)
  end

  test "verifies curated branch comparison report reference fixtures" do
    fixture_id = "fixture.artifact.branch_comparison_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.branch_comparison_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = branch_comparison_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               branch_comparison_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      branch_comparison_report_fixture_observations()
      |> Map.put("selected_count", 2)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "selected_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      branch_comparison_report_fixture_observations()
      |> Map.put("row_derived_approval_status_counts", %{
        "blocked_by_policy" => 8,
        "operator_review_required" => 5
      })

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_approval_status_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "branch_comparison_report.v1")

    stale_branch_count = Map.put(report, "branch_count", 0)

    assert {:error, stale_branch_count_report} =
             Schema.validate_artifact(stale_branch_count,
               schema_contract: "branch_comparison_report.v1"
             )

    assert Enum.any?(
             stale_branch_count_report["errors"],
             &(&1["path"] == "$.branch_count")
           )

    stale_score_delta =
      put_in(report, ["rows", Access.at(1), "score_delta_from_recommended"], 0)

    assert {:error, stale_score_delta_report} =
             Schema.validate_artifact(stale_score_delta,
               schema_contract: "branch_comparison_report.v1"
             )

    assert Enum.any?(
             stale_score_delta_report["errors"],
             &(&1["path"] == "$.rows[1].score_delta_from_recommended")
           )

    stale_repair_score_term_count =
      put_in(report, ["rows", Access.at(0), "repair_score_term_count"], 0)

    assert {:error, stale_repair_score_term_count_report} =
             Schema.validate_artifact(stale_repair_score_term_count,
               schema_contract: "branch_comparison_report.v1"
             )

    assert Enum.any?(
             stale_repair_score_term_count_report["errors"],
             &(&1["path"] == "$.rows[0].repair_score_term_count")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "branch_comparison_report.v1",
             report
           ) == Validation.artifact_observations("branch_comparison_report.v1", report)
  end

  test "verifies curated optimizer contract reference fixtures" do
    fixture_id = "fixture.artifact.optimizer_contract.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.optimizer_contract.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = optimizer_contract_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               optimizer_contract_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      optimizer_contract_fixture_observations()
      |> Map.put("external_solver", true)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "external_solver" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations("optimizer_contract.v1", report) ==
             Validation.artifact_observations("optimizer_contract.v1", report)

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "optimizer_contract.v1")

    stale_candidate_count = Map.put(report, "candidate_count", 1)

    assert {:error, stale_candidate_count_report} =
             Schema.validate_artifact(stale_candidate_count,
               schema_contract: "optimizer_contract.v1"
             )

    assert Enum.any?(
             stale_candidate_count_report["errors"],
             &(&1["path"] == "$.candidate_count")
           )
  end

  test "verifies curated invalidated candidate reference fixtures" do
    fixture_id = "fixture.artifact.invalidated_candidate.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.invalidated_candidate.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = invalidated_candidate_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               invalidated_candidate_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      invalidated_candidate_fixture_observations()
      |> Map.put("replacement_candidate_id", "other_candidate")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "replacement_candidate_id" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "invalidated_candidate.v1")

    stale_source_target_id = Map.put(report, "source_target_id", "target_b")

    assert {:error, stale_source_target_id_report} =
             Schema.validate_artifact(stale_source_target_id,
               schema_contract: "invalidated_candidate.v1"
             )

    assert Enum.any?(
             stale_source_target_id_report["errors"],
             &(&1["path"] == "$.source_target_id")
           )

    assert OrbitalDynamics.validation_artifact_observations("invalidated_candidate.v1", report) ==
             Validation.artifact_observations("invalidated_candidate.v1", report)
  end

  test "verifies curated strategy branch reference fixtures" do
    fixture_id = "fixture.artifact.strategy_branch.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.strategy_branch.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = strategy_branch_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               strategy_branch_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      strategy_branch_fixture_observations()
      |> Map.put("approval_status", "blocked_by_policy")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "approval_status" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations("strategy_branch.v1", report) ==
             Validation.artifact_observations("strategy_branch.v1", report)

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "strategy_branch.v1")

    stale_score = Map.put(report, "score", report["score"] + 1.0)

    assert {:error, stale_score_report} =
             Schema.validate_artifact(stale_score,
               schema_contract: "strategy_branch.v1"
             )

    assert Enum.any?(stale_score_report["errors"], &(&1["path"] == "$.score"))
  end

  test "verifies curated strategy recommendation reference fixtures" do
    fixture_id = "fixture.artifact.strategy_recommendation.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.strategy_recommendation.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = strategy_recommendation_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               strategy_recommendation_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      strategy_recommendation_fixture_observations()
      |> Map.put("ranked_branch_count", 3)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "ranked_branch_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations("strategy_recommendation.v1", report) ==
             Validation.artifact_observations("strategy_recommendation.v1", report)

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "strategy_recommendation.v1")

    stale_ranked_branch_ids =
      Map.put(
        report,
        "ranked_branch_ids",
        tl(report["ranked_branch_ids"]) ++ [report["recommended_branch_id"]]
      )

    assert {:error, stale_rank_report} =
             Schema.validate_artifact(stale_ranked_branch_ids,
               schema_contract: "strategy_recommendation.v1"
             )

    assert Enum.any?(stale_rank_report["errors"], &(&1["path"] == "$.recommended_branch_id"))
  end

  test "verifies curated study benchmark reference fixtures" do
    fixtures = [
      {
        "fixture.artifact.study_benchmark.v1",
        study_benchmark_fixture(),
        study_benchmark_fixture_observations(),
        "matches_baseline_count",
        1
      },
      {
        "fixture.artifact.study_benchmark.distributed_concurrency_sweep",
        distributed_concurrency_benchmark_fixture(),
        distributed_concurrency_benchmark_fixture_observations(),
        "distributed_result_count",
        53
      },
      {
        "fixture.artifact.study_benchmark.distributed_chunk_sweep",
        distributed_chunk_benchmark_fixture(),
        distributed_chunk_benchmark_fixture_observations(),
        "task_chunk_size_option_count",
        5
      },
      {
        "fixture.artifact.study_benchmark.distributed_monte_carlo_scaling",
        distributed_monte_carlo_scaling_benchmark_fixture(),
        distributed_monte_carlo_scaling_benchmark_fixture_observations(),
        "monte_carlo_count_option_count",
        2
      },
      {
        "fixture.artifact.study_benchmark.distributed_diagnostic_sweep",
        distributed_diagnostic_benchmark_fixture(),
        distributed_diagnostic_benchmark_fixture_observations(),
        "distributed_result_count",
        23
      },
      {
        "fixture.artifact.study_benchmark.distributed_monte_carlo_chunked",
        distributed_monte_carlo_chunked_benchmark_fixture(),
        distributed_monte_carlo_chunked_benchmark_fixture_observations(),
        "result_count",
        17
      },
      {
        "fixture.artifact.study_benchmark.monte_carlo_scaling",
        monte_carlo_scaling_benchmark_fixture(),
        monte_carlo_scaling_benchmark_fixture_observations(),
        "repetition_count",
        2
      },
      {
        "fixture.artifact.study_benchmark.nx_study_benchmark",
        nx_study_benchmark_fixture(),
        nx_study_benchmark_fixture_observations(),
        "backend_count",
        2
      }
    ]

    for {fixture_id, artifact, observations, stale_field, stale_value} <- fixtures do
      assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

      assert fixture["model_id"] == "artifact.study_benchmark.v1"
      assert fixture["fixture_type"] == "curated_internal_artifact_regression"

      assert {:ok, verification} =
               Validation.verify_reference_fixture(fixture_id, observations)

      assert verification["status"] == "pass"
      assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

      stale_observations = Map.put(observations, stale_field, stale_value)

      assert {:ok, stale_verification} =
               Validation.verify_reference_fixture(fixture_id, stale_observations)

      assert stale_verification["status"] == "fail"

      assert Enum.any?(
               stale_verification["checks"],
               &(&1["field"] == stale_field and &1["status"] == "fail")
             )

      assert OrbitalDynamics.validation_artifact_observations("study_benchmark.v1", artifact) ==
               Validation.artifact_observations("study_benchmark.v1", artifact)
    end

    benchmark_report = study_benchmark_fixture()

    assert {:ok, _validated_report} =
             Schema.validate_artifact(benchmark_report, schema_contract: "study_benchmark.v1")

    stale_scenario_count =
      put_in(benchmark_report, ["results", Access.at(0), "scenario_count"], 99)

    assert {:error, stale_scenario_count_report} =
             Schema.validate_artifact(stale_scenario_count,
               schema_contract: "study_benchmark.v1"
             )

    assert Enum.any?(
             stale_scenario_count_report["errors"],
             &(&1["path"] == "$.results[0].scenario_count")
           )
  end

  test "verifies curated validation reference report fixtures" do
    fixture_id = "fixture.artifact.validation_reference_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.validation_reference_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = validation_reference_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               validation_reference_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert verification["status_counts"] == %{"pass" => 10}
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      validation_reference_report_fixture_observations()
      |> Map.put("check_count", 2)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"
    assert stale_verification["status_counts"] == %{"fail" => 1, "pass" => 9}

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "check_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "validation_reference_report.v1",
             report
           ) == Validation.artifact_observations("validation_reference_report.v1", report)

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "validation_reference_report.v1"
             )

    assert report["status_counts"] == %{"pass" => 3}

    stale_check_status =
      report
      |> put_in(["checks", Access.at(0), "status"], "fail")
      |> Map.put("status", "pass")

    assert {:error, stale_check_status_report} =
             Schema.validate_artifact(stale_check_status,
               schema_contract: "validation_reference_report.v1"
             )

    assert Enum.any?(
             stale_check_status_report["errors"],
             &(&1["path"] == "$.status")
           )

    stale_status_counts = put_in(report, ["status_counts", "pass"], 2)

    assert {:error, stale_status_counts_report} =
             Schema.validate_artifact(stale_status_counts,
               schema_contract: "validation_reference_report.v1"
             )

    assert Enum.any?(
             stale_status_counts_report["errors"],
             &(&1["path"] == "$.status_counts" and
                 &1["message"] == "must equal nested check status counts")
           )
  end

  test "verifies curated candidate diff report reference fixtures" do
    fixture_id = "fixture.artifact.candidate_diff_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_diff_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = candidate_diff_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               candidate_diff_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      candidate_diff_report_fixture_observations()
      |> Map.put("invalidated_candidate_count", 0)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "invalidated_candidate_count" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "candidate_diff_report.v1")

    stale_new_candidate_count = Map.put(report, "new_candidate_count", 0)

    assert {:error, stale_new_candidate_count_report} =
             Schema.validate_artifact(stale_new_candidate_count,
               schema_contract: "candidate_diff_report.v1"
             )

    assert Enum.any?(
             stale_new_candidate_count_report["errors"],
             &(&1["path"] == "$.new_candidate_count")
           )

    stale_changed_field_alias =
      put_in(report, ["invalidated_candidates", Access.at(0), "candidate_diff_changed_fields"], [
        "starts_at_s"
      ])

    assert {:error, stale_changed_field_alias_report} =
             Schema.validate_artifact(stale_changed_field_alias,
               schema_contract: "candidate_diff_report.v1"
             )

    assert Enum.any?(
             stale_changed_field_alias_report["errors"],
             &(&1["path"] ==
                 "$.invalidated_candidates[0].candidate_diff_changed_fields")
           )

    stale_semantic_reasons =
      put_in(report, ["invalidated_candidates", Access.at(0), "semantic_change_reasons"], [
        "starts_at_s_changed"
      ])

    assert {:error, stale_semantic_reasons_report} =
             Schema.validate_artifact(stale_semantic_reasons,
               schema_contract: "candidate_diff_report.v1"
             )

    assert Enum.any?(
             stale_semantic_reasons_report["errors"],
             &(&1["path"] == "$.invalidated_candidates[0].semantic_change_reasons")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "candidate_diff_report.v1",
             report
           ) == Validation.artifact_observations("candidate_diff_report.v1", report)
  end

  test "verifies curated refresh budget report reference fixtures" do
    fixture_id = "fixture.artifact.refresh_budget_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.refresh_budget_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = refresh_budget_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               refresh_budget_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      refresh_budget_report_fixture_observations()
      |> Map.put("dropped_candidate_count", 0)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "dropped_candidate_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "refresh_budget_report.v1",
             report
           ) == Validation.artifact_observations("refresh_budget_report.v1", report)

    assert {:ok, %{"schema_contract" => "refresh_budget_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "refresh_budget_report.v1"
             )

    stale_model = Map.put(report, "model", "stale_refresh_budget_model")

    assert {:error, stale_model_report} =
             Schema.validate_artifact(stale_model,
               schema_contract: "refresh_budget_report.v1"
             )

    assert Enum.any?(
             stale_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"deterministic_candidate_limit_after_filters\"")
           )

    stale_kept_candidate_count = Map.put(report, "kept_candidate_count", 2)

    assert {:error, stale_kept_candidate_count_report} =
             Schema.validate_artifact(stale_kept_candidate_count,
               schema_contract: "refresh_budget_report.v1"
             )

    assert Enum.any?(
             stale_kept_candidate_count_report["errors"],
             &(&1["path"] == "$.kept_candidate_count")
           )

    stale_input_candidate_count = Map.put(report, "input_candidate_count", 3)

    assert {:error, stale_input_candidate_count_report} =
             Schema.validate_artifact(stale_input_candidate_count,
               schema_contract: "refresh_budget_report.v1"
             )

    assert Enum.any?(
             stale_input_candidate_count_report["errors"],
             &(&1["path"] == "$.input_candidate_count")
           )

    stale_duplicate_kept_candidate_ids =
      Map.put(report, "kept_candidate_ids", [
        "leo_1_observe_target_a_1",
        "leo_1_observe_target_a_1"
      ])
      |> Map.put("kept_candidate_count", 2)
      |> Map.put("input_candidate_count", 3)

    assert {:error, stale_duplicate_kept_candidate_ids_report} =
             Schema.validate_artifact(stale_duplicate_kept_candidate_ids,
               schema_contract: "refresh_budget_report.v1"
             )

    assert Enum.any?(
             stale_duplicate_kept_candidate_ids_report["errors"],
             &(&1["path"] == "$.kept_candidate_ids")
           )

    stale_overlapping_candidate_ids =
      Map.put(report, "dropped_candidate_ids", ["leo_1_observe_target_a_1"])

    assert {:error, stale_overlapping_candidate_ids_report} =
             Schema.validate_artifact(stale_overlapping_candidate_ids,
               schema_contract: "refresh_budget_report.v1"
             )

    assert Enum.any?(
             stale_overlapping_candidate_ids_report["errors"],
             &(&1["path"] == "$.dropped_candidate_ids")
           )
  end

  test "verifies curated execution report reference fixtures" do
    fixture_id = "fixture.artifact.execution_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.execution_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = execution_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               execution_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      execution_report_fixture_observations()
      |> Map.put("failed_scenario_count", 0)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "failed_scenario_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "execution_report.v1",
             report
           ) == Validation.artifact_observations("execution_report.v1", report)

    assert {:ok, %{"schema_contract" => "execution_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "execution_report.v1"
             )

    stale_scenario_count = Map.put(report, "scenario_count", 1999)

    assert {:error, stale_scenario_count_report} =
             Schema.validate_artifact(stale_scenario_count,
               schema_contract: "execution_report.v1"
             )

    assert Enum.any?(
             stale_scenario_count_report["errors"],
             &(&1["path"] == "$.scenario_count")
           )

    stale_failed_scenario_count = Map.put(report, "failed_scenario_count", 0)

    assert {:error, stale_failed_scenario_count_report} =
             Schema.validate_artifact(stale_failed_scenario_count,
               schema_contract: "execution_report.v1"
             )

    assert Enum.any?(
             stale_failed_scenario_count_report["errors"],
             &(&1["path"] == "$.failed_scenario_count")
           )

    stale_status = Map.put(report, "status", "completed")

    assert {:error, stale_status_report} =
             Schema.validate_artifact(stale_status,
               schema_contract: "execution_report.v1"
             )

    assert Enum.any?(
             stale_status_report["errors"],
             &(&1["path"] == "$.status")
           )

    stale_execution_plan_count = put_in(report, ["execution_plan", "scenario_count"], 1999)

    assert {:error, stale_execution_plan_count_report} =
             Schema.validate_artifact(stale_execution_plan_count,
               schema_contract: "execution_report.v1"
             )

    assert Enum.any?(
             stale_execution_plan_count_report["errors"],
             &(&1["path"] == "$.execution_plan.scenario_count")
           )

    stale_node_distribution = put_in(report, ["node_distribution", "mission_ops@node_b"], 999)

    assert {:error, stale_node_distribution_report} =
             Schema.validate_artifact(stale_node_distribution,
               schema_contract: "execution_report.v1"
             )

    assert Enum.any?(
             stale_node_distribution_report["errors"],
             &(&1["path"] == "$.node_distribution")
           )
  end

  test "verifies curated freshness report reference fixtures" do
    fixture_id = "fixture.artifact.freshness_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.freshness_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = freshness_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               freshness_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      freshness_report_fixture_observations()
      |> Map.put("status", "stale")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "status" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "freshness_report.v1",
             report
           ) == Validation.artifact_observations("freshness_report.v1", report)

    assert {:ok, %{"schema_contract" => "freshness_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "freshness_report.v1"
             )

    stale_status = Map.put(report, "status", "stale")

    assert {:error, stale_status_report} =
             Schema.validate_artifact(stale_status,
               schema_contract: "freshness_report.v1"
             )

    assert Enum.any?(
             stale_status_report["errors"],
             &(&1["path"] == "$.status")
           )

    stale_horizon_offset = Map.put(report, "horizon_start_offset_s", 2)

    assert {:error, stale_horizon_offset_report} =
             Schema.validate_artifact(stale_horizon_offset,
               schema_contract: "freshness_report.v1"
             )

    assert Enum.any?(
             stale_horizon_offset_report["errors"],
             &(&1["path"] == "$.stale_reasons")
           )

    stale_unknown_reasons = Map.put(report, "unknown_reasons", ["horizon_alignment_unknown"])

    assert {:error, stale_unknown_reasons_report} =
             Schema.validate_artifact(stale_unknown_reasons,
               schema_contract: "freshness_report.v1"
             )

    assert Enum.any?(
             stale_unknown_reasons_report["errors"],
             &(&1["path"] == "$.unknown_reasons")
           )

    stale_state_quality_status = Map.put(report, "state_quality_status", "not_accepted")

    assert {:error, stale_state_quality_status_report} =
             Schema.validate_artifact(stale_state_quality_status,
               schema_contract: "freshness_report.v1"
             )

    assert Enum.any?(
             stale_state_quality_status_report["errors"],
             &(&1["path"] == "$.state_quality_status" and
                 &1["message"] == "must equal accepted")
           )

    stale_model = Map.put(report, "model", "stale_freshness_model")

    assert {:error, stale_model_report} =
             Schema.validate_artifact(stale_model,
               schema_contract: "freshness_report.v1"
             )

    assert Enum.any?(
             stale_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"accepted_snapshot_horizon_and_quality_freshness\"")
           )

    stale_state_quality_policy_input =
      Map.put(report, "accepted_state_quality_level", "telemetry_unreviewed")

    assert {:error, stale_state_quality_policy_input_report} =
             Schema.validate_artifact(stale_state_quality_policy_input,
               schema_contract: "freshness_report.v1"
             )

    assert Enum.any?(
             stale_state_quality_policy_input_report["errors"],
             &(&1["path"] == "$.stale_reasons" and
                 &1["message"] == "must equal freshness-policy-derived stale_reasons")
           )

    assert Enum.any?(
             stale_state_quality_policy_input_report["errors"],
             &(&1["path"] == "$.status" and &1["message"] == "must equal stale")
           )

    stale_model_limits =
      Map.put(report, "model_limits", Enum.drop(Map.fetch!(report, "model_limits"), 1))

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "freshness_report.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )
  end

  test "verifies curated manifest field reference fixtures" do
    fixture_id = "fixture.artifact.manifest_field_reference.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.manifest_field_reference.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = manifest_field_reference_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               manifest_field_reference_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      manifest_field_reference_fixture_observations()
      |> Map.put("field_row_count", 3719)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "field_row_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "manifest_field_reference.v1",
             report
           ) == Validation.artifact_observations("manifest_field_reference.v1", report)

    assert {:ok, %{"schema_contract" => "manifest_field_reference.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "manifest_field_reference.v1"
             )

    stale_field_count = Map.put(report, "field_count", 3719)

    assert {:error, stale_field_count_report} =
             Schema.validate_artifact(stale_field_count,
               schema_contract: "manifest_field_reference.v1"
             )

    assert Enum.any?(
             stale_field_count_report["errors"],
             &(&1["path"] == "$.field_count")
           )

    fields = Map.fetch!(report, "fields")

    duplicate_path_fields =
      fields
      |> List.replace_at(1, Map.put(Enum.at(fields, 1), "path", "$.campaign"))

    stale_duplicate_path = Map.put(report, "fields", duplicate_path_fields)

    assert {:error, stale_duplicate_path_report} =
             Schema.validate_artifact(stale_duplicate_path,
               schema_contract: "manifest_field_reference.v1"
             )

    assert Enum.any?(
             stale_duplicate_path_report["errors"],
             &(&1["path"] == "$.fields")
           )

    stale_top_level_required =
      Map.put(report, "top_level_required", ["schema_version", "study_id"])

    assert {:error, stale_top_level_required_report} =
             Schema.validate_artifact(stale_top_level_required,
               schema_contract: "manifest_field_reference.v1"
             )

    assert Enum.any?(
             stale_top_level_required_report["errors"],
             &(&1["path"] == "$.top_level_required")
           )

    stale_activation_sections =
      Map.put(
        report,
        "activation_sections",
        List.replace_at(Map.fetch!(report, "activation_sections"), 0, "invalid_section")
      )

    assert {:error, stale_activation_sections_report} =
             Schema.validate_artifact(stale_activation_sections,
               schema_contract: "manifest_field_reference.v1"
             )

    assert Enum.any?(
             stale_activation_sections_report["errors"],
             &(&1["path"] == "$.activation_sections[0]")
           )

    stale_supported_outputs = put_in(report, ["supported", "outputs"], ["events"])

    assert {:error, stale_supported_outputs_report} =
             Schema.validate_artifact(stale_supported_outputs,
               schema_contract: "manifest_field_reference.v1"
             )

    assert Enum.any?(
             stale_supported_outputs_report["errors"],
             &(&1["path"] == "$.supported.outputs")
           )
  end

  test "verifies curated study manifest lint reference fixtures" do
    fixture_id = "fixture.artifact.study_manifest_lint.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.study_manifest_lint.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = study_manifest_lint_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               study_manifest_lint_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      study_manifest_lint_fixture_observations()
      |> Map.put("error_count", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "error_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "study_manifest_lint.v1",
             report
           ) == Validation.artifact_observations("study_manifest_lint.v1", report)

    assert {:ok, %{"schema_contract" => "study_manifest_lint.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "study_manifest_lint.v1"
             )

    stale_error_count = Map.put(report, "error_count", 1)

    assert {:error, stale_error_count_report} =
             Schema.validate_artifact(stale_error_count,
               schema_contract: "study_manifest_lint.v1"
             )

    assert Enum.any?(
             stale_error_count_report["errors"],
             &(&1["path"] == "$.error_count")
           )

    stale_warning_count = Map.put(report, "warning_count", 1)

    assert {:error, stale_warning_count_report} =
             Schema.validate_artifact(stale_warning_count,
               schema_contract: "study_manifest_lint.v1"
             )

    assert Enum.any?(
             stale_warning_count_report["errors"],
             &(&1["path"] == "$.warning_count")
           )

    stale_status = Map.put(report, "status", "fail")

    assert {:error, stale_status_report} =
             Schema.validate_artifact(stale_status,
               schema_contract: "study_manifest_lint.v1"
             )

    assert Enum.any?(
             stale_status_report["errors"],
             &(&1["path"] == "$.status")
           )

    stale_duplicate_outputs =
      Map.put(report, "outputs", ["trajectories", "trajectories"])

    assert {:error, stale_duplicate_outputs_report} =
             Schema.validate_artifact(stale_duplicate_outputs,
               schema_contract: "study_manifest_lint.v1"
             )

    assert Enum.any?(
             stale_duplicate_outputs_report["errors"],
             &(&1["path"] == "$.outputs")
           )

    stale_unsupported_output = Map.put(report, "outputs", ["unsupported_output"])

    assert {:error, stale_unsupported_output_report} =
             Schema.validate_artifact(stale_unsupported_output,
               schema_contract: "study_manifest_lint.v1"
             )

    assert Enum.any?(
             stale_unsupported_output_report["errors"],
             &(&1["path"] == "$.outputs")
           )
  end

  test "verifies curated approval requirement reference fixtures" do
    fixture_id = "fixture.artifact.approval_requirement.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.approval_requirement.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = approval_requirement_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               approval_requirement_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      approval_requirement_fixture_observations()
      |> Map.put("required_authority", "mission_planning_authority")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "required_authority" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "approval_requirement.v1",
             report
           ) == Validation.artifact_observations("approval_requirement.v1", report)

    assert {:ok, %{"schema_contract" => "approval_requirement.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "approval_requirement.v1"
             )

    stale_decision_classification =
      put_in(report, ["policy_decision", "classification"], "auto_approvable")

    assert {:error, stale_decision_classification_report} =
             Schema.validate_artifact(stale_decision_classification,
               schema_contract: "approval_requirement.v1"
             )

    assert Enum.any?(
             stale_decision_classification_report["errors"],
             &(&1["path"] == "$.policy_decision.classification")
           )

    stale_decision_policy_bundle =
      put_in(report, ["policy_decision", "policy_bundle_id"], "other_policy_bundle")

    assert {:error, stale_decision_policy_bundle_report} =
             Schema.validate_artifact(stale_decision_policy_bundle,
               schema_contract: "approval_requirement.v1"
             )

    assert Enum.any?(
             stale_decision_policy_bundle_report["errors"],
             &(&1["path"] == "$.policy_decision.policy_bundle_id")
           )

    stale_rule_matches = Map.put(report, "approval_rule_matches", [])

    assert {:error, stale_rule_matches_report} =
             Schema.validate_artifact(stale_rule_matches,
               schema_contract: "approval_requirement.v1"
             )

    assert Enum.any?(
             stale_rule_matches_report["errors"],
             &(&1["path"] == "$.approval_rule_matches")
           )

    stale_escalations = put_in(report, ["policy_decision", "escalations"], [])

    assert {:error, stale_escalations_report} =
             Schema.validate_artifact(stale_escalations,
               schema_contract: "approval_requirement.v1"
             )

    assert Enum.any?(
             stale_escalations_report["errors"],
             &(&1["path"] == "$.policy_decision.escalations")
           )
  end

  test "verifies curated policy decision reference fixtures" do
    fixture_id = "fixture.artifact.policy_decision.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.policy_decision.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = policy_decision_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               policy_decision_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      policy_decision_fixture_observations()
      |> Map.put("classification", "approved")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "classification" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "policy_decision.v1",
             report
           ) == Validation.artifact_observations("policy_decision.v1", report)

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "policy_decision.v1"
             )

    stale_classification = Map.put(report, "classification", "auto_approvable")

    assert {:error, stale_classification_report} =
             Schema.validate_artifact(stale_classification,
               schema_contract: "policy_decision.v1"
             )

    assert Enum.any?(
             stale_classification_report["errors"],
             &(&1["path"] == "$.classification")
           )

    stale_approval_requirement_count = Map.put(report, "approval_requirement_count", 0)

    assert {:error, stale_approval_requirement_count_report} =
             Schema.validate_artifact(stale_approval_requirement_count,
               schema_contract: "policy_decision.v1"
             )

    assert Enum.any?(
             stale_approval_requirement_count_report["errors"],
             &(&1["path"] == "$.approval_requirement_count")
           )

    stale_risk_count = Map.put(report, "risk_count", 1)

    assert {:error, stale_risk_count_report} =
             Schema.validate_artifact(stale_risk_count,
               schema_contract: "policy_decision.v1"
             )

    assert Enum.any?(
             stale_risk_count_report["errors"],
             &(&1["path"] == "$.risk_count")
           )

    stale_escalation_rule_id =
      put_in(report, ["escalations", Access.at(0), "rule_id"], "other_rule")

    assert {:error, stale_escalation_rule_id_report} =
             Schema.validate_artifact(stale_escalation_rule_id,
               schema_contract: "policy_decision.v1"
             )

    assert Enum.any?(
             stale_escalation_rule_id_report["errors"],
             &(&1["path"] == "$.escalations")
           )

    stale_model_limits =
      Map.put(report, "model_limits", Enum.drop(Map.fetch!(report, "model_limits"), 1))

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "policy_decision.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )
  end

  test "verifies curated policy bundle reference fixtures" do
    fixture_id = "fixture.artifact.policy_bundle.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.policy_bundle.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = policy_bundle_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               policy_bundle_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      policy_bundle_fixture_observations()
      |> Map.put("action_rule_count", 5)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "action_rule_count" and &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report, schema_contract: "policy_bundle.v1")

    first_rule_id = get_in(report, ["approval_policy", "action_rules", Access.at(0), "id"])

    stale_duplicate_rule_id =
      put_in(report, ["approval_policy", "action_rules", Access.at(1), "id"], first_rule_id)

    assert {:error, stale_duplicate_rule_id_report} =
             Schema.validate_artifact(stale_duplicate_rule_id,
               schema_contract: "policy_bundle.v1"
             )

    assert Enum.any?(
             stale_duplicate_rule_id_report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[1].id")
           )

    stale_provenance_bundle_id =
      put_in(report, ["provenance", "bundle_id"], "other_policy_bundle")

    assert {:error, stale_provenance_bundle_id_report} =
             Schema.validate_artifact(stale_provenance_bundle_id,
               schema_contract: "policy_bundle.v1"
             )

    assert Enum.any?(
             stale_provenance_bundle_id_report["errors"],
             &(&1["path"] == "$.provenance.bundle_id")
           )

    stale_authority_route =
      update_in(
        report,
        ["approval_policy", "action_rules", Access.at(0)],
        &Map.delete(&1, "required_authority")
      )

    assert {:error, stale_authority_route_report} =
             Schema.validate_artifact(stale_authority_route,
               schema_contract: "policy_bundle.v1"
             )

    assert Enum.any?(
             stale_authority_route_report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[0].required_authority")
           )

    stale_assumption_boundary =
      put_in(report, ["assumptions", "boundary"], "external_authority_lookup")

    assert {:error, stale_assumption_boundary_report} =
             Schema.validate_artifact(stale_assumption_boundary,
               schema_contract: "policy_bundle.v1"
             )

    assert Enum.any?(
             stale_assumption_boundary_report["errors"],
             &(&1["path"] == "$.assumptions.boundary")
           )

    stale_model_limits =
      Map.put(report, "model_limits", Enum.drop(Map.fetch!(report, "model_limits"), 1))

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "policy_bundle.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "policy_bundle.v1",
             report
           ) == Validation.artifact_observations("policy_bundle.v1", report)
  end

  test "verifies curated ground-network policy bundle reference fixtures" do
    fixture_id = "fixture.artifact.policy_bundle.ground_network_allocation"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.policy_bundle.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = ground_network_policy_bundle_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               ground_network_policy_bundle_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      ground_network_policy_bundle_fixture_observations()
      |> Map.put("reduced_capacity_rule_count", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "reduced_capacity_rule_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "policy_bundle.v1",
             report
           ) == Validation.artifact_observations("policy_bundle.v1", report)

    assert {:ok, _validated_report} =
             Schema.validate_artifact(report, schema_contract: "policy_bundle.v1")

    missing_classification =
      update_in(
        report,
        ["approval_policy", "action_rules", Access.at(0)],
        &Map.delete(&1, "classification")
      )

    assert {:error, missing_classification_report} =
             Schema.validate_artifact(missing_classification,
               schema_contract: "policy_bundle.v1"
             )

    assert Enum.any?(
             missing_classification_report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[0].classification")
           )

    missing_reason =
      update_in(
        report,
        ["approval_policy", "action_rules", Access.at(0)],
        &Map.delete(&1, "reason")
      )

    assert {:error, missing_reason_report} =
             Schema.validate_artifact(missing_reason,
               schema_contract: "policy_bundle.v1"
             )

    assert Enum.any?(
             missing_reason_report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[0].reason")
           )
  end

  test "verifies curated operator-review queue policy bundle reference fixtures" do
    fixture_id = "fixture.artifact.policy_bundle.operator_review_queue_authority"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.policy_bundle.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operator_review_queue_policy_bundle_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               operator_review_queue_policy_bundle_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      operator_review_queue_policy_bundle_fixture_observations()
      |> Map.put("required_authority_counts", %{"mission_operations_authority" => 5})

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "required_authority_counts" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "policy_bundle.v1",
             report
           ) == Validation.artifact_observations("policy_bundle.v1", report)
  end

  test "verifies curated command/contact policy bundle reference fixtures" do
    fixture_id = "fixture.artifact.policy_bundle.command_contact_authority"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.policy_bundle.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = command_contact_policy_bundle_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               command_contact_policy_bundle_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      command_contact_policy_bundle_fixture_observations()
      |> Map.put("station_availability_rule_count", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "station_availability_rule_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "policy_bundle.v1",
             report
           ) == Validation.artifact_observations("policy_bundle.v1", report)
  end

  test "verifies curated domain authority policy bundle reference fixtures" do
    fixtures = [
      {
        "fixture.artifact.policy_bundle.maneuver_authority",
        maneuver_authority_policy_bundle_fixture(),
        maneuver_authority_policy_bundle_fixture_observations(),
        "escalation_queue_counts",
        %{"mission_planning" => 4}
      },
      {
        "fixture.artifact.policy_bundle.resource_projection_authority",
        resource_projection_authority_policy_bundle_fixture(),
        resource_projection_authority_policy_bundle_fixture_observations(),
        "required_authority_counts",
        %{"resource_model_authority" => 7}
      },
      {
        "fixture.artifact.policy_bundle.timeline_protection",
        timeline_protection_policy_bundle_fixture(),
        timeline_protection_policy_bundle_fixture_observations(),
        "action_rule_count",
        8
      }
    ]

    for {fixture_id, report, observations, stale_field, stale_value} <- fixtures do
      assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

      assert fixture["model_id"] == "artifact.policy_bundle.v1"
      assert fixture["fixture_type"] == "curated_internal_artifact_regression"

      assert {:ok, verification} =
               Validation.verify_reference_fixture(fixture_id, observations)

      assert verification["status"] == "pass"
      assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

      stale_observations = Map.put(observations, stale_field, stale_value)

      assert {:ok, stale_verification} =
               Validation.verify_reference_fixture(fixture_id, stale_observations)

      assert stale_verification["status"] == "fail"

      assert Enum.any?(
               stale_verification["checks"],
               &(&1["field"] == stale_field and &1["status"] == "fail")
             )

      assert OrbitalDynamics.validation_artifact_observations(
               "policy_bundle.v1",
               report
             ) == Validation.artifact_observations("policy_bundle.v1", report)

      assert {:ok, _validated_report} =
               Schema.validate_artifact(report, schema_contract: "policy_bundle.v1")
    end
  end

  test "verifies curated remaining policy bundle variant reference fixtures" do
    fixtures = [
      {
        "fixture.artifact.policy_bundle.conservative_ops",
        conservative_policy_bundle_fixture(),
        conservative_policy_bundle_fixture_observations(),
        "blocked_risk_type_count",
        7
      },
      {
        "fixture.artifact.policy_bundle.contact_command_review",
        contact_command_review_policy_bundle_fixture(),
        contact_command_review_policy_bundle_fixture_observations(),
        "action_rule_count",
        2
      },
      {
        "fixture.artifact.policy_bundle.degraded_payload_guard",
        degraded_payload_guard_policy_bundle_fixture(),
        degraded_payload_guard_policy_bundle_fixture_observations(),
        "auto_approvable_approval_count_limit",
        1
      },
      {
        "fixture.artifact.policy_bundle.default",
        default_policy_bundle_fixture(),
        default_policy_bundle_fixture_observations(),
        "operator_review_risk_limit",
        2
      },
      {
        "fixture.artifact.policy_bundle.organization_adapter",
        organization_adapter_policy_bundle_fixture(),
        organization_adapter_policy_bundle_fixture_observations(),
        "workflow_execution",
        "external_workflow"
      }
    ]

    for {fixture_id, report, observations, stale_field, stale_value} <- fixtures do
      assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

      assert fixture["model_id"] == "artifact.policy_bundle.v1"
      assert fixture["fixture_type"] == "curated_internal_artifact_regression"

      assert {:ok, verification} =
               Validation.verify_reference_fixture(fixture_id, observations)

      assert verification["status"] == "pass"
      assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

      stale_observations = Map.put(observations, stale_field, stale_value)

      assert {:ok, stale_verification} =
               Validation.verify_reference_fixture(fixture_id, stale_observations)

      assert stale_verification["status"] == "fail"

      assert Enum.any?(
               stale_verification["checks"],
               &(&1["field"] == stale_field and &1["status"] == "fail")
             )

      assert OrbitalDynamics.validation_artifact_observations(
               "policy_bundle.v1",
               report
             ) == Validation.artifact_observations("policy_bundle.v1", report)
    end
  end

  test "verifies curated planned activity reference fixtures" do
    fixture_id = "fixture.artifact.planned_activity.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.planned_activity.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = planned_activity_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               planned_activity_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      planned_activity_fixture_observations()
      |> Map.put("timeline_identity_field_count", 5)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "timeline_identity_field_count" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "planned_activity.v1")

    stale_timeline_identity =
      put_in(report, ["timeline_identity", "activity_id"], "cmd_other")

    assert {:error, stale_timeline_identity_report} =
             Schema.validate_artifact(stale_timeline_identity,
               schema_contract: "planned_activity.v1"
             )

    assert Enum.any?(
             stale_timeline_identity_report["errors"],
             &(&1["path"] == "$.timeline_identity.activity_id")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "planned_activity.v1",
             report
           ) == Validation.artifact_observations("planned_activity.v1", report)
  end

  test "verifies curated activity template reference fixtures" do
    fixture_id = "fixture.artifact.activity_template.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.activity_template.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    template = activity_template_fixture()
    observations = activity_template_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["activity_type"] == "observe"
    assert observations["required_field_keys"] == "id|type|target_id|starts_at_s|ends_at_s"
    assert observations["optional_field_count"] == 7
    assert observations["setup_duration_s"] == 120
    assert observations["cooldown_duration_s"] == 60
    assert observations["telemetry_confirmation_required"] == true
    assert observations["required_state_keys"] == "spacecraft:standby|payload:ready"
    assert observations["produced_state_keys"] == "payload:observation_collected"
    assert observations["precondition_type_keys"] == "payload_unavailable"
    assert observations["boundary"] == "template_only_no_schedule_mutation"

    stale_hint_observations =
      observations
      |> Map.put("setup_duration_s", 30)

    assert {:ok, stale_hint_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_hint_observations)

    assert stale_hint_verification["status"] == "fail"

    assert Enum.any?(
             stale_hint_verification["checks"],
             &(&1["field"] == "setup_duration_s" and &1["status"] == "fail")
           )

    stale_state_observations =
      observations
      |> Map.put("required_state_keys", "payload:ready")

    assert {:ok, stale_state_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_state_observations)

    assert stale_state_verification["status"] == "fail"

    assert Enum.any?(
             stale_state_verification["checks"],
             &(&1["field"] == "required_state_keys" and &1["status"] == "fail")
           )

    stale_limit_observations =
      observations
      |> Map.put("no_resource_reservation", false)

    assert {:ok, stale_limit_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_limit_observations)

    assert stale_limit_verification["status"] == "fail"

    assert Enum.any?(
             stale_limit_verification["checks"],
             &(&1["field"] == "no_resource_reservation" and &1["status"] == "fail")
           )

    assert {:ok, _valid_template} =
             Schema.validate_artifact(template, schema_contract: "activity_template.v1")

    assert OrbitalDynamics.validation_artifact_observations(
             "activity_template.v1",
             template
           ) == Validation.artifact_observations("activity_template.v1", template)
  end

  test "verifies curated subsystem model capability reference fixtures" do
    battery_fixture_id = "fixture.artifact.subsystem_model_capability.battery"
    storage_fixture_id = "fixture.artifact.subsystem_model_capability.storage"

    assert {:ok, battery_fixture} = Validation.reference_fixture(battery_fixture_id)
    assert {:ok, storage_fixture} = Validation.reference_fixture(storage_fixture_id)

    assert battery_fixture["model_id"] == "artifact.subsystem_model_capability.v1"
    assert storage_fixture["model_id"] == "artifact.subsystem_model_capability.v1"

    battery_capability = subsystem_model_capability_fixture()
    storage_capability = subsystem_model_capability_storage_fixture()
    battery_observations = subsystem_model_capability_fixture_observations()
    storage_observations = subsystem_model_capability_storage_fixture_observations()

    assert {:ok, battery_verification} =
             Validation.verify_reference_fixture(battery_fixture_id, battery_observations)

    assert {:ok, storage_verification} =
             Validation.verify_reference_fixture(storage_fixture_id, storage_observations)

    assert battery_verification["status"] == "pass"
    assert storage_verification["status"] == "pass"
    assert Enum.all?(battery_verification["checks"], &(&1["status"] == "pass"))
    assert Enum.all?(storage_verification["checks"], &(&1["status"] == "pass"))

    assert battery_observations["id"] ==
             "subsystem.power.battery.energy_storage.planning_grade"

    assert battery_observations["resource_dimensions"] == "battery"
    assert battery_observations["activity_effect_types"] == "consumption|generation"

    assert battery_observations["known_limit_keys"] ==
             "selected_activity_sequence_only|declared_energy_hints_only|no_continuous_power_bus_or_thermal_coupling|no_battery_degradation_or_charge_dynamics"

    assert storage_observations["id"] ==
             "subsystem.data_recorder.storage_buffer.planning_grade"

    assert storage_observations["resource_dimensions"] == "storage|downlink"
    assert storage_observations["activity_effect_types"] == "downlink|production"

    assert storage_observations["known_limit_keys"] ==
             "selected_activity_sequence_only|declared_data_volume_hints_only|storage_limited_downlink_arithmetic_only|no_partition_priority_deletion_or_latency_model"

    stale_battery_observations =
      battery_observations
      |> Map.put("resource_dimensions", "power")

    assert {:ok, stale_battery_verification} =
             Validation.verify_reference_fixture(battery_fixture_id, stale_battery_observations)

    assert stale_battery_verification["status"] == "fail"

    assert Enum.any?(
             stale_battery_verification["checks"],
             &(&1["field"] == "resource_dimensions" and &1["status"] == "fail")
           )

    stale_storage_observations =
      storage_observations
      |> Map.put("storage_limited_downlink_arithmetic_only", false)

    assert {:ok, stale_storage_verification} =
             Validation.verify_reference_fixture(storage_fixture_id, stale_storage_observations)

    assert stale_storage_verification["status"] == "fail"

    assert Enum.any?(
             stale_storage_verification["checks"],
             &(&1["field"] == "storage_limited_downlink_arithmetic_only" and
                 &1["status"] == "fail")
           )

    assert {:ok, _valid_battery_capability} =
             Schema.validate_artifact(battery_capability,
               schema_contract: "subsystem_model_capability.v1"
             )

    assert {:ok, _valid_storage_capability} =
             Schema.validate_artifact(storage_capability,
               schema_contract: "subsystem_model_capability.v1"
             )

    assert OrbitalDynamics.validation_artifact_observations(
             "subsystem_model_capability.v1",
             battery_capability
           ) ==
             Validation.artifact_observations("subsystem_model_capability.v1", battery_capability)

    assert OrbitalDynamics.validation_artifact_observations(
             "subsystem_model_capability.v1",
             storage_capability
           ) ==
             Validation.artifact_observations("subsystem_model_capability.v1", storage_capability)
  end

  test "verifies curated realized activity reference fixtures" do
    fixture_id = "fixture.artifact.realized_activity.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.realized_activity.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = realized_activity_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               realized_activity_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      realized_activity_fixture_observations()
      |> Map.put("status", "completed")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "status" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "realized_activity.v1")

    stale_metadata =
      put_in(report, ["metadata", "planned_activity_id"], "other_activity")

    assert {:error, stale_metadata_report} =
             Schema.validate_artifact(stale_metadata, schema_contract: "realized_activity.v1")

    assert Enum.any?(
             stale_metadata_report["errors"],
             &(&1["path"] == "$.metadata.planned_activity_id")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "realized_activity.v1",
             report
           ) == Validation.artifact_observations("realized_activity.v1", report)
  end

  test "verifies curated plan delta reference fixtures" do
    fixture_id = "fixture.artifact.plan_delta.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.plan_delta.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = plan_delta_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               plan_delta_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      plan_delta_fixture_observations()
      |> Map.put("requires_approval", false)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "requires_approval" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "plan_delta.v1")

    stale_source_identity =
      put_in(report, ["source_activity_context", "timeline_identity", "activity_id"], "other")

    assert {:error, stale_source_identity_report} =
             Schema.validate_artifact(stale_source_identity, schema_contract: "plan_delta.v1")

    assert Enum.any?(
             stale_source_identity_report["errors"],
             &(&1["path"] == "$.source_activity_context.timeline_identity.activity_id")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "plan_delta.v1",
             report
           ) == Validation.artifact_observations("plan_delta.v1", report)
  end

  test "verifies curated candidate activity reference fixtures" do
    fixture_id = "fixture.artifact.candidate_activity.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_activity.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = candidate_activity_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               candidate_activity_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      candidate_activity_fixture_observations()
      |> Map.put("score_term_count", 3)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "score_term_count" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "candidate_activity.v1")

    stale_score = Map.put(report, "score", 1.0)

    assert {:error, stale_score_report} =
             Schema.validate_artifact(stale_score, schema_contract: "candidate_activity.v1")

    assert Enum.any?(
             stale_score_report["errors"],
             &(&1["path"] == "$.score")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "candidate_activity.v1",
             report
           ) == Validation.artifact_observations("candidate_activity.v1", report)
  end

  test "verifies curated contact intent reference fixtures" do
    fixture_id = "fixture.artifact.contact_intent.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.contact_intent.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = contact_intent_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               contact_intent_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      contact_intent_fixture_observations()
      |> Map.put("approval_status", "approved")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "approval_status" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "contact_intent.v1")

    stale_policy_classification =
      put_in(report, ["policy_decision", "classification"], "auto_approvable")

    assert {:error, stale_policy_report} =
             Schema.validate_artifact(stale_policy_classification,
               schema_contract: "contact_intent.v1"
             )

    assert Enum.any?(
             stale_policy_report["errors"],
             &(&1["path"] == "$.policy_decision.classification")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_intent.v1",
             report
           ) == Validation.artifact_observations("contact_intent.v1", report)
  end

  test "verifies curated contact intent summary reference fixtures" do
    fixture_id = "fixture.artifact.contact_intent_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.contact_intent_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = contact_intent_summary_fixture()
    observations = contact_intent_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["contact_intent_count"] == 3
    assert observations["capacity_pack_required_contact_count"] == 3
    assert observations["capacity_pack_required_capacity_fraction"] == 0.95
    assert observations["direction_counts"] == %{"command" => 1, "downlink" => 1, "tracking" => 1}
    assert observations["direction_keys"] == "command|downlink|tracking"
    assert observations["ground_station_keys"] == "dss_43|equator_prime"

    assert observations["capacity_pack_required_capacity_fraction_by_direction"] == %{
             "command" => 0.5,
             "downlink" => 0.25,
             "tracking" => 0.2
           }

    assert observations["required_capacity_fraction_source_keys"] ==
             "capacity_model|contact_required_capacity_fraction|throughput_model"

    assert observations["execution_boundary"] ==
             "artifact_only_no_provider_reservation_or_schedule_mutation"

    assert observations["no_provider_reservation"] == true
    assert observations["no_schedule_mutation"] == true
    assert observations["no_command_execution"] == true

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_intent_summary.v1",
             report
           ) == Validation.artifact_observations("contact_intent_summary.v1", report)

    stale_direction_observations = put_in(observations, ["direction_counts", "downlink"], 0)

    assert {:ok, stale_direction_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_direction_observations)

    assert stale_direction_verification["status"] == "fail"

    assert Enum.any?(
             stale_direction_verification["checks"],
             &(&1["field"] == "direction_counts" and &1["status"] == "fail")
           )

    stale_capacity_observations =
      Map.put(observations, "capacity_pack_required_capacity_fraction", 0.5)

    assert {:ok, stale_capacity_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_capacity_observations)

    assert stale_capacity_verification["status"] == "fail"

    assert Enum.any?(
             stale_capacity_verification["checks"],
             &(&1["field"] == "capacity_pack_required_capacity_fraction" and
                 &1["status"] == "fail")
           )

    stale_boundary_observations =
      Map.put(observations, "execution_boundary", "provider_reservation_ready")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "execution_boundary" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "contact_intent_summary.v1")
  end

  test "verifies curated refreshed window reference fixtures" do
    fixture_id = "fixture.artifact.refreshed_window.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.refreshed_window.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = refreshed_window_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               refreshed_window_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      refreshed_window_fixture_observations()
      |> Map.put("sample_count", 4)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "sample_count" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "refreshed_window.v1")

    stale_sample_count = Map.put(report, "sample_count", 4)

    assert {:error, stale_sample_count_report} =
             Schema.validate_artifact(stale_sample_count, schema_contract: "refreshed_window.v1")

    assert Enum.any?(
             stale_sample_count_report["errors"],
             &(&1["path"] == "$.sample_count")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "refreshed_window.v1",
             report
           ) == Validation.artifact_observations("refreshed_window.v1", report)
  end

  test "verifies curated source window lineage reference fixtures" do
    fixture_id = "fixture.artifact.source_window_lineage.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.source_window_lineage.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = source_window_lineage_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               source_window_lineage_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      source_window_lineage_fixture_observations()
      |> Map.put("source_window_type", "target_visibility")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "source_window_type" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "source_window_lineage.v1")

    stale_source_window_type = Map.put(report, "source_window_type", "target_visibility")

    assert {:error, stale_source_window_type_report} =
             Schema.validate_artifact(stale_source_window_type,
               schema_contract: "source_window_lineage.v1"
             )

    assert Enum.any?(
             stale_source_window_type_report["errors"],
             &(&1["path"] == "$.source_window_type")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "source_window_lineage.v1",
             report
           ) == Validation.artifact_observations("source_window_lineage.v1", report)
  end

  test "verifies curated spacecraft state estimate reference fixtures" do
    fixture_id = "fixture.artifact.spacecraft_state_estimate.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.spacecraft_state_estimate.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = spacecraft_state_estimate_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               spacecraft_state_estimate_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      spacecraft_state_estimate_fixture_observations()
      |> Map.put("quality_level", "planning_accepted")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "quality_level" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "spacecraft_state_estimate.v1")

    stale_quality_sigma =
      put_in(report, ["quality", "position_sigma_km"], [0.1, 0.1])

    assert {:error, stale_quality_sigma_report} =
             Schema.validate_artifact(stale_quality_sigma,
               schema_contract: "spacecraft_state_estimate.v1"
             )

    assert Enum.any?(
             stale_quality_sigma_report["errors"],
             &(&1["path"] == "$.quality.position_sigma_km")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "spacecraft_state_estimate.v1",
             report
           ) == Validation.artifact_observations("spacecraft_state_estimate.v1", report)
  end

  test "verifies curated realized state snapshot reference fixtures" do
    fixture_id = "fixture.artifact.realized_state_snapshot.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.realized_state_snapshot.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = realized_state_snapshot_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               realized_state_snapshot_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      realized_state_snapshot_fixture_observations()
      |> Map.put("degraded_count", 0)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "degraded_count" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "realized_state_snapshot.v1")

    stale_degraded_count = Map.put(report, "degraded_count", 0)

    assert {:error, stale_degraded_count_report} =
             Schema.validate_artifact(stale_degraded_count,
               schema_contract: "realized_state_snapshot.v1"
             )

    assert Enum.any?(
             stale_degraded_count_report["errors"],
             &(&1["path"] == "$.degraded_count")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "realized_state_snapshot.v1",
             report
           ) == Validation.artifact_observations("realized_state_snapshot.v1", report)
  end

  test "verifies curated remaining horizon reference fixtures" do
    fixture_id = "fixture.artifact.remaining_horizon.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.remaining_horizon.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = remaining_horizon_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               remaining_horizon_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      remaining_horizon_fixture_observations()
      |> Map.put("duration_s", 540)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "duration_s" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "remaining_horizon.v1")

    stale_duration = Map.put(report, "duration_s", 540)

    assert {:error, stale_duration_report} =
             Schema.validate_artifact(stale_duration, schema_contract: "remaining_horizon.v1")

    assert Enum.any?(
             stale_duration_report["errors"],
             &(&1["path"] == "$.duration_s")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "remaining_horizon.v1",
             report
           ) == Validation.artifact_observations("remaining_horizon.v1", report)
  end

  test "verifies curated maneuver execution delta reference fixtures" do
    fixture_id = "fixture.artifact.maneuver_execution_delta.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.maneuver_execution_delta.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = maneuver_execution_delta_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               maneuver_execution_delta_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      maneuver_execution_delta_fixture_observations()
      |> Map.put("status", "partial")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "status" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "maneuver_execution_delta.v1")

    stale_delta_v = Map.put(report, "delta_v_km_s", [0.0, 0.01])

    assert {:error, stale_delta_v_report} =
             Schema.validate_artifact(stale_delta_v,
               schema_contract: "maneuver_execution_delta.v1"
             )

    assert Enum.any?(
             stale_delta_v_report["errors"],
             &(&1["path"] == "$.delta_v_km_s")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "maneuver_execution_delta.v1",
             report
           ) == Validation.artifact_observations("maneuver_execution_delta.v1", report)
  end

  test "verifies curated maneuver recommendation reference fixtures" do
    fixture_id = "fixture.artifact.maneuver_recommendation.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.maneuver_recommendation.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = maneuver_recommendation_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               maneuver_recommendation_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      maneuver_recommendation_fixture_observations()
      |> Map.put("recommendation_only_no_command_execution", false)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "recommendation_only_no_command_execution" and
                 &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "maneuver_recommendation.v1")

    stale_delta_v_magnitude = Map.put(report, "delta_v_magnitude_km_s", 0.02)

    assert {:error, stale_delta_v_magnitude_report} =
             Schema.validate_artifact(stale_delta_v_magnitude,
               schema_contract: "maneuver_recommendation.v1"
             )

    assert Enum.any?(
             stale_delta_v_magnitude_report["errors"],
             &(&1["path"] == "$.delta_v_magnitude_km_s")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "maneuver_recommendation.v1",
             report
           ) == Validation.artifact_observations("maneuver_recommendation.v1", report)
  end

  test "verifies curated backend acceptance policy reference fixtures" do
    fixture_id = "fixture.artifact.backend_acceptance_policy.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.backend_acceptance_policy.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = backend_acceptance_policy_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               backend_acceptance_policy_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      backend_acceptance_policy_fixture_observations()
      |> Map.put("implementation_count", 5)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "implementation_count" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "backend_acceptance_policy.v1")

    stale_reference_tier =
      put_in(
        report,
        ["implementation_tiers", "OrbitalDynamics.Propagators.TwoBody"],
        "experimental_accelerator"
      )

    assert {:error, stale_reference_tier_report} =
             Schema.validate_artifact(stale_reference_tier,
               schema_contract: "backend_acceptance_policy.v1"
             )

    assert Enum.any?(
             stale_reference_tier_report["errors"],
             &(&1["path"] == "$.reference_backend.implementations[0]")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "backend_acceptance_policy.v1",
             report
           ) == Validation.artifact_observations("backend_acceptance_policy.v1", report)
  end

  test "verifies curated validation tolerance policy reference fixtures" do
    fixture_id = "fixture.artifact.validation_tolerance_policy.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.validation_tolerance_policy.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = validation_tolerance_policy_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               validation_tolerance_policy_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      validation_tolerance_policy_fixture_observations()
      |> Map.put("validation_level_count", 4)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "validation_level_count" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "validation_tolerance_policy.v1")

    stale_validation_levels =
      update_in(report, ["validation_levels"], &Map.delete(&1, "validated"))

    assert {:error, stale_validation_levels_report} =
             Schema.validate_artifact(stale_validation_levels,
               schema_contract: "validation_tolerance_policy.v1"
             )

    assert Enum.any?(
             stale_validation_levels_report["errors"],
             &(&1["path"] == "$.validation_levels")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "validation_tolerance_policy.v1",
             report
           ) == Validation.artifact_observations("validation_tolerance_policy.v1", report)
  end

  test "verifies curated validation record reference fixtures" do
    fixture_id = "fixture.artifact.validation_record.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.validation_record.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = validation_record_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               validation_record_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      validation_record_fixture_observations()
      |> Map.put("validation_level", "validated")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "validation_level" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "validation_record.v1")

    stale_validation_level = Map.put(report, "validation_level", "flight_certified")

    assert {:error, stale_validation_level_report} =
             Schema.validate_artifact(stale_validation_level,
               schema_contract: "validation_record.v1"
             )

    assert Enum.any?(
             stale_validation_level_report["errors"],
             &(&1["path"] == "$.validation_level")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "validation_record.v1",
             report
           ) == Validation.artifact_observations("validation_record.v1", report)
  end

  test "verifies curated validation check reference fixtures" do
    fixture_id = "fixture.artifact.validation_check.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.validation_check.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = validation_check_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               validation_check_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      validation_check_fixture_observations()
      |> Map.put("status", "fail")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "status" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "validation_check.v1",
             report
           ) == Validation.artifact_observations("validation_check.v1", report)

    assert {:ok, %{"schema_contract" => "validation_check.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "validation_check.v1"
             )

    stale_status = Map.put(report, "status", "fail")

    assert {:error, stale_status_report} =
             Schema.validate_artifact(stale_status,
               schema_contract: "validation_check.v1"
             )

    assert Enum.any?(stale_status_report["errors"], &(&1["path"] == "$.status"))

    stale_observed = Map.put(report, "observed", 2)

    assert {:error, stale_observed_report} =
             Schema.validate_artifact(stale_observed,
               schema_contract: "validation_check.v1"
             )

    assert Enum.any?(stale_observed_report["errors"], &(&1["path"] == "$.status"))
    assert Enum.any?(stale_observed_report["errors"], &(&1["path"] == "$.error"))

    stale_error = Map.put(report, "error", 1)

    assert {:error, stale_error_report} =
             Schema.validate_artifact(stale_error,
               schema_contract: "validation_check.v1"
             )

    assert Enum.any?(stale_error_report["errors"], &(&1["path"] == "$.error"))
  end

  test "verifies curated timeline diff report reference fixtures" do
    fixture_id = "fixture.artifact.timeline_diff_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_diff_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_diff_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               timeline_diff_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      timeline_diff_report_fixture_observations()
      |> Map.put("review_required_count", 3)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "review_required_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      timeline_diff_report_fixture_observations()
      |> put_in(["row_derived_diff_status_counts", "changed"], 1)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_diff_status_counts" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "timeline_diff_report.v1")

    stale_row_count = Map.put(report, "row_count", 0)

    assert {:error, stale_row_count_report} =
             Schema.validate_artifact(stale_row_count,
               schema_contract: "timeline_diff_report.v1"
             )

    assert Enum.any?(
             stale_row_count_report["errors"],
             &(&1["path"] == "$.row_count")
           )

    stale_added_count = Map.put(report, "added_count", 0)

    assert {:error, stale_added_count_report} =
             Schema.validate_artifact(stale_added_count,
               schema_contract: "timeline_diff_report.v1"
             )

    assert Enum.any?(
             stale_added_count_report["errors"],
             &(&1["path"] == "$.added_count")
           )

    stale_model_limits = Map.put(report, "model_limits", ["artifact_level_only"])

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "timeline_diff_report.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_diff_report.v1",
             report
           ) == Validation.artifact_observations("timeline_diff_report.v1", report)
  end

  test "verifies curated timeline activity precondition summary reference fixtures" do
    fixture_id = "fixture.artifact.timeline_activity_precondition_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_activity_precondition_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_activity_precondition_summary_fixture()

    assert generated_timeline_activity_precondition_summary_fixture() == report

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               timeline_activity_precondition_summary_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      timeline_activity_precondition_summary_fixture_observations()
      |> Map.put("blocked_precondition_count", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "blocked_precondition_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      timeline_activity_precondition_summary_fixture_observations()
      |> put_in(["row_derived_precondition_type_counts", "payload_unavailable"], 0)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_precondition_type_counts" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report,
               schema_contract: "timeline_activity_precondition_summary.v1"
             )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_activity_precondition_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "timeline_activity_precondition_summary.v1",
               report
             )
  end

  test "verifies curated timeline activity state reference fixtures" do
    fixture_id = "fixture.artifact.timeline_activity_state.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_activity_state.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_activity_state_fixture()

    assert generated_timeline_activity_state_fixture() == report

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               timeline_activity_state_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      timeline_activity_state_fixture_observations()
      |> Map.put("row_count", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "row_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      timeline_activity_state_fixture_observations()
      |> put_in(["row_derived_match_strategy_counts", "unmatched_realized"], 0)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_match_strategy_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "timeline_activity_state.v1")

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_activity_state.v1",
             report
           ) == Validation.artifact_observations("timeline_activity_state.v1", report)
  end

  test "verifies curated timeline activity approval state reference fixtures" do
    fixture_id = "fixture.artifact.timeline_activity_approval_state.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_activity_approval_state.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_activity_approval_state_fixture()
    observations = timeline_activity_approval_state_fixture_observations()

    assert generated_timeline_activity_approval_state_fixture() == report

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["transition_decision"] == "review"
    assert observations["review_required"] == true
    assert observations["required_operator_action"] == "review_activity_approval"
    assert observations["operator_action_reason"] == "approval_grant_requires_operator_authority"
    assert observations["import_action"] == "review_timeline_diff"
    assert observations["approval_transition_category"] == "approval_granted"
    assert observations["approval_transition_requires_operator_review"] == true
    assert observations["no_operator_authority_grant"] == true
    assert observations["no_command_execution"] == true

    stale_action_observations =
      observations
      |> Map.put("required_operator_action", "none")

    assert {:ok, stale_action_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_action_observations)

    assert stale_action_verification["status"] == "fail"

    assert Enum.any?(
             stale_action_verification["checks"],
             &(&1["field"] == "required_operator_action" and &1["status"] == "fail")
           )

    stale_authority_observations =
      observations
      |> Map.put("no_operator_authority_grant", false)

    assert {:ok, stale_authority_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_authority_observations)

    assert stale_authority_verification["status"] == "fail"

    assert Enum.any?(
             stale_authority_verification["checks"],
             &(&1["field"] == "no_operator_authority_grant" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report,
               schema_contract: "timeline_activity_approval_state.v1"
             )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_activity_approval_state.v1",
             report
           ) ==
             Validation.artifact_observations("timeline_activity_approval_state.v1", report)
  end

  test "verifies curated timeline activity status state reference fixtures" do
    fixture_id = "fixture.artifact.timeline_activity_status_state.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_activity_status_state.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_activity_status_state_fixture()
    observations = timeline_activity_status_state_fixture_observations()

    assert generated_timeline_activity_status_state_fixture() == report

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["transition_decision"] == "record"
    assert observations["review_required"] == false
    assert observations["required_operator_action"] == "record_timeline_change"
    assert observations["operator_action_reason"] == "activity_execution_recorded"
    assert observations["import_action"] == "import_replacement_activity"
    assert observations["status_transition_category"] == "execution_recorded"
    assert observations["status_transition_requires_operator_review"] == false
    assert observations["no_operator_authority_grant"] == true
    assert observations["no_command_execution"] == true

    stale_transition_observations =
      observations
      |> Map.put("transition_decision", "none")

    assert {:ok, stale_transition_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_transition_observations)

    assert stale_transition_verification["status"] == "fail"

    assert Enum.any?(
             stale_transition_verification["checks"],
             &(&1["field"] == "transition_decision" and &1["status"] == "fail")
           )

    stale_execution_boundary_observations =
      observations
      |> Map.put("no_command_execution", false)

    assert {:ok, stale_execution_boundary_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_execution_boundary_observations
             )

    assert stale_execution_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_execution_boundary_verification["checks"],
             &(&1["field"] == "no_command_execution" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report,
               schema_contract: "timeline_activity_status_state.v1"
             )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_activity_status_state.v1",
             report
           ) ==
             Validation.artifact_observations("timeline_activity_status_state.v1", report)
  end

  test "verifies curated timeline activity lifecycle state reference fixtures" do
    fixture_id = "fixture.artifact.timeline_activity_lifecycle_state.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_activity_lifecycle_state.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_activity_lifecycle_state_fixture()
    observations = timeline_activity_lifecycle_state_fixture_observations()

    assert generated_timeline_activity_lifecycle_state_fixture() == report

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["transition_decision"] == "review"
    assert observations["status_transition_decision"] == "record"
    assert observations["approval_transition_decision"] == "review"
    assert observations["required_operator_action_count"] == 2
    assert observations["operator_action_reason_count"] == 2
    assert observations["no_operator_authority_grant"] == true
    assert observations["no_cadence_import"] == true
    assert observations["no_command_execution"] == true

    stale_action_observations =
      observations
      |> Map.put("required_operator_action_keys", "record_timeline_change")

    assert {:ok, stale_action_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_action_observations)

    assert stale_action_verification["status"] == "fail"

    assert Enum.any?(
             stale_action_verification["checks"],
             &(&1["field"] == "required_operator_action_keys" and &1["status"] == "fail")
           )

    stale_authority_observations =
      observations
      |> Map.put("no_operator_authority_grant", false)

    assert {:ok, stale_authority_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_authority_observations)

    assert stale_authority_verification["status"] == "fail"

    assert Enum.any?(
             stale_authority_verification["checks"],
             &(&1["field"] == "no_operator_authority_grant" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report,
               schema_contract: "timeline_activity_lifecycle_state.v1"
             )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_activity_lifecycle_state.v1",
             report
           ) ==
             Validation.artifact_observations("timeline_activity_lifecycle_state.v1", report)
  end

  test "verifies curated timeline lifecycle state summary reference fixtures" do
    fixture_id = "fixture.artifact.timeline_lifecycle_state_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_lifecycle_state_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_lifecycle_state_summary_fixture()
    observations = timeline_lifecycle_state_summary_fixture_observations()

    assert generated_timeline_lifecycle_state_summary_fixture() == report

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["row_count"] == 4
    assert observations["row_derived_row_count"] == 4
    assert observations["review_required_count"] == 2
    assert observations["row_derived_review_required_count"] == 2
    assert observations["duplicate_timeline_identity_count"] == 1
    assert observations["row_derived_duplicate_timeline_identity_count"] == 1
    assert observations["review_timeline_keys"] == "timeline:cmd_provider|timeline:dup"

    assert observations["row_derived_review_timeline_keys"] ==
             "timeline:cmd_provider|timeline:dup"

    assert observations["operator_action_reason_counts"] == %{
             "activity_execution_recorded" => 2,
             "approval_grant_requires_operator_authority" => 1,
             "duplicate_timeline_identity" => 1
           }

    assert observations["row_derived_operator_action_reason_counts"] ==
             observations["operator_action_reason_counts"]

    assert observations["review_timeline_ids_by_operator_action_reason"] == %{
             "activity_execution_recorded" => ["timeline:cmd_provider"],
             "approval_grant_requires_operator_authority" => ["timeline:cmd_provider"],
             "duplicate_timeline_identity" => ["timeline:dup"]
           }

    assert observations["row_derived_review_timeline_ids_by_operator_action_reason"] ==
             observations["review_timeline_ids_by_operator_action_reason"]

    assert observations["operator_authority"] == "not_granted_by_summary"
    assert observations["cadence_import"] == "not_performed_by_summary"

    stale_review_count_observations =
      observations
      |> Map.put("row_derived_review_required_count", 1)

    assert {:ok, stale_review_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_review_count_observations)

    assert stale_review_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_review_count_verification["checks"],
             &(&1["field"] == "row_derived_review_required_count" and &1["status"] == "fail")
           )

    stale_review_routing_observations =
      observations
      |> Map.put("row_derived_review_timeline_ids_by_required_operator_action", %{})

    assert {:ok, stale_review_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_review_routing_observations)

    assert stale_review_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_review_routing_verification["checks"],
             &(&1["field"] == "row_derived_review_timeline_ids_by_required_operator_action" and
                 &1["status"] == "fail")
           )

    stale_operator_reason_observations =
      observations
      |> put_in(["row_derived_operator_action_reason_counts", "activity_execution_recorded"], 1)

    assert {:ok, stale_operator_reason_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_operator_reason_observations)

    assert stale_operator_reason_verification["status"] == "fail"

    assert Enum.any?(
             stale_operator_reason_verification["checks"],
             &(&1["field"] == "row_derived_operator_action_reason_counts" and
                 &1["status"] == "fail")
           )

    stale_operator_routing_observations =
      observations
      |> put_in(["row_derived_review_timeline_ids_by_operator_action_reason"], %{})

    assert {:ok, stale_operator_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_operator_routing_observations)

    assert stale_operator_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_operator_routing_verification["checks"],
             &(&1["field"] == "row_derived_review_timeline_ids_by_operator_action_reason" and
                 &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report,
               schema_contract: "timeline_lifecycle_state_summary.v1"
             )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_lifecycle_state_summary.v1",
             report
           ) ==
             Validation.artifact_observations("timeline_lifecycle_state_summary.v1", report)
  end

  test "verifies curated timeline preservation report reference fixtures" do
    fixture_id = "fixture.artifact.timeline_preservation_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_preservation_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_preservation_report_fixture()
    observations = timeline_preservation_report_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["activity_count"] == 4
    assert observations["row_count"] == 3
    assert observations["row_derived_row_count"] == 3
    assert observations["preservation_sensitive_activity_count"] == 3
    assert observations["row_derived_preservation_sensitive_activity_count"] == 3
    assert observations["review_change_activity_count"] == 1
    assert observations["row_derived_review_change_activity_count"] == 1
    assert observations["row_derived_invalid_activity_input_count"] == 1
    assert observations["timeline_preservation_status"] == "review_required"

    assert observations["row_derived_protection_decision_counts"] == %{
             "preserve" => 2,
             "review_change" => 1
           }

    assert observations["activity_id_sets_by_protection_decision"] == %{
             "mutable" => ["cmd_mutable"],
             "preserve" => ["contact_locked", "obs_done"],
             "review_change" => ["bad_missing_type"]
           }

    assert observations["row_derived_activity_id_sets_by_protection_decision"] == %{
             "preserve" => ["contact_locked", "obs_done"],
             "review_change" => ["bad_missing_type"]
           }

    assert observations["preservation_sensitive_activity_keys"] ==
             "bad_missing_type|contact_locked|obs_done"

    assert observations["row_derived_preservation_sensitive_activity_keys"] ==
             "bad_missing_type|contact_locked|obs_done"

    assert observations["execution_boundary"] == "artifact_only_no_schedule_mutation"
    assert observations["scope"] == "lifecycle_lock_approval_and_executed_preservation_review"
    assert observations["model_limit_count"] == 4

    stale_review_observations =
      observations
      |> Map.put("row_derived_review_change_activity_count", 0)

    assert {:ok, stale_review_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_review_observations)

    assert stale_review_verification["status"] == "fail"

    assert Enum.any?(
             stale_review_verification["checks"],
             &(&1["field"] == "row_derived_review_change_activity_count" and
                 &1["status"] == "fail")
           )

    stale_routing_observations =
      observations
      |> Map.put("row_derived_activity_id_sets_by_protection_decision", %{})

    assert {:ok, stale_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_routing_observations)

    assert stale_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_routing_verification["checks"],
             &(&1["field"] == "row_derived_activity_id_sets_by_protection_decision" and
                 &1["status"] == "fail")
           )

    stale_boundary_observations =
      observations
      |> Map.put("execution_boundary", "schedule_mutation_allowed")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "execution_boundary" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report,
               schema_contract: "timeline_preservation_report.v1"
             )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_preservation_report.v1",
             report
           ) ==
             Validation.artifact_observations("timeline_preservation_report.v1", report)
  end

  test "verifies curated timeline preservation status reference fixtures" do
    fixture_id = "fixture.artifact.timeline_preservation_status.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_preservation_status.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    status = timeline_preservation_status_fixture()
    observations = timeline_preservation_status_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["activity_id"] == "dl_locked"
    assert observations["activity_type"] == "downlink"
    assert observations["timeline_identity_timeline_id"] == "timeline:dl_locked"
    assert observations["protection_decision"] == "preserve"
    assert observations["timeline_preservation_status"] == "preservation_required"
    assert observations["requires_preservation"] == true
    assert observations["requires_operator_review"] == false
    assert observations["execution_boundary"] == "artifact_only_no_schedule_mutation"

    stale_status_observations =
      observations
      |> Map.put("timeline_preservation_status", "mutable")

    assert {:ok, stale_status_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_status_observations)

    assert stale_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_status_verification["checks"],
             &(&1["field"] == "timeline_preservation_status" and &1["status"] == "fail")
           )

    stale_identity_observations =
      observations
      |> Map.put("timeline_identity_timeline_id", "timeline:dl_unlocked")

    assert {:ok, stale_identity_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_identity_observations)

    assert stale_identity_verification["status"] == "fail"

    assert Enum.any?(
             stale_identity_verification["checks"],
             &(&1["field"] == "timeline_identity_timeline_id" and &1["status"] == "fail")
           )

    stale_boundary_observations =
      observations
      |> Map.put("execution_boundary", "schedule_mutation_ready")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "execution_boundary" and &1["status"] == "fail")
           )

    assert {:ok, _valid_status} =
             Schema.validate_artifact(status,
               schema_contract: "timeline_preservation_status.v1"
             )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_preservation_status.v1",
             status
           ) == Validation.artifact_observations("timeline_preservation_status.v1", status)
  end

  test "verifies curated timeline integrity report reference fixtures" do
    fixture_id = "fixture.artifact.timeline_integrity_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_integrity_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_integrity_report_fixture()

    assert generated_timeline_integrity_report_fixture() == report

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               timeline_integrity_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      timeline_integrity_report_fixture_observations()
      |> Map.put("timeline_integrity_issue_count", 2)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "timeline_integrity_issue_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      timeline_integrity_report_fixture_observations()
      |> put_in(["row_derived_timeline_integrity_issue_type_counts", "exclusivity_overlap"], 0)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_timeline_integrity_issue_type_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "timeline_integrity_report.v1")

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_integrity_report.v1",
             report
           ) == Validation.artifact_observations("timeline_integrity_report.v1", report)
  end

  test "verifies curated timeline dependency impact summary reference fixtures" do
    fixture_id = "fixture.artifact.timeline_dependency_impact_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_dependency_impact_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_dependency_impact_summary_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               timeline_dependency_impact_summary_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      timeline_dependency_impact_summary_fixture_observations()
      |> Map.put("dependent_activity_count", 3)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "dependent_activity_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      timeline_dependency_impact_summary_fixture_observations()
      |> put_in(
        [
          "row_derived_operator_action_reason_counts",
          "dependency_changed_or_removed_source_activity"
        ],
        1
      )

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_operator_action_reason_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report,
               schema_contract: "timeline_dependency_impact_summary.v1"
             )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_dependency_impact_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "timeline_dependency_impact_summary.v1",
               report
             )
  end

  test "verifies curated timeline diff summary reference fixtures" do
    fixture_id = "fixture.artifact.timeline_diff_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_diff_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_diff_summary_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               timeline_diff_summary_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      timeline_diff_summary_fixture_observations()
      |> Map.put("review_required_count", 2)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "review_required_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      timeline_diff_summary_fixture_observations()
      |> put_in(["row_derived_status_transition_category_counts", "status_changed"], 0)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_status_transition_category_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "timeline_diff_summary.v1")

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_diff_summary.v1",
             report
           ) == Validation.artifact_observations("timeline_diff_summary.v1", report)
  end

  test "verifies curated timeline publication summary reference fixtures" do
    fixture_id = "fixture.artifact.timeline_publication_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_publication_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_publication_summary_fixture()

    assert generated_timeline_publication_summary_fixture() == report

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               timeline_publication_summary_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      timeline_publication_summary_fixture_observations()
      |> Map.put("publication_status", "published")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "publication_status" and &1["status"] == "fail")
           )

    stale_downstream_invalidation_observations =
      timeline_publication_summary_fixture_observations()
      |> Map.put("downstream_invalidation_status", "clear")

    assert {:ok, stale_downstream_invalidation_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_downstream_invalidation_observations
             )

    assert stale_downstream_invalidation_verification["status"] == "fail"

    assert Enum.any?(
             stale_downstream_invalidation_verification["checks"],
             &(&1["field"] == "downstream_invalidation_status" and &1["status"] == "fail")
           )

    stale_invalidation_reason_observations =
      timeline_publication_summary_fixture_observations()
      |> Map.put("downstream_invalidation_reason_counts", %{
        "superseded_publication" => 2
      })

    assert {:ok, stale_invalidation_reason_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_invalidation_reason_observations
             )

    assert stale_invalidation_reason_verification["status"] == "fail"

    assert Enum.any?(
             stale_invalidation_reason_verification["checks"],
             &(&1["field"] == "downstream_invalidation_reason_counts" and
                 &1["status"] == "fail")
           )

    stale_dependent_observations =
      timeline_publication_summary_fixture_observations()
      |> Map.put("dependent_activity_ids", "wrong_dependent")

    assert {:ok, stale_dependent_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_dependent_observations)

    assert stale_dependent_verification["status"] == "fail"

    assert Enum.any?(
             stale_dependent_verification["checks"],
             &(&1["field"] == "dependent_activity_ids" and &1["status"] == "fail")
           )

    stale_routing_observations =
      timeline_publication_summary_fixture_observations()
      |> put_in(
        [
          "source_timeline_diff_review_timeline_ids_by_required_operator_action",
          "review_added_activity"
        ],
        []
      )

    assert {:ok, stale_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_routing_observations)

    assert stale_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_routing_verification["checks"],
             &(&1["field"] ==
                 "source_timeline_diff_review_timeline_ids_by_required_operator_action" and
                 &1["status"] == "fail")
           )

    stale_boundary_observations =
      timeline_publication_summary_fixture_observations()
      |> Map.put("execution_boundary", "schedule_mutation_ready")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "execution_boundary" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report,
               schema_contract: "timeline_publication_summary.v1"
             )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_publication_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "timeline_publication_summary.v1",
               report
             )
  end

  test "verifies curated timeline transition application summary reference fixtures" do
    fixture_id = "fixture.artifact.timeline_transition_application_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_transition_application_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_transition_application_summary_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               timeline_transition_application_summary_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      timeline_transition_application_summary_fixture_observations()
      |> Map.put("review_required_count", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "review_required_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      timeline_transition_application_summary_fixture_observations()
      |> put_in(["row_derived_required_operator_action_counts", "review_added_activity"], 0)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_required_operator_action_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report,
               schema_contract: "timeline_transition_application_summary.v1"
             )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_transition_application_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "timeline_transition_application_summary.v1",
               report
             )
  end

  test "verifies curated timeline transition application selected integrity summary reference fixtures" do
    fixture_id = "fixture.artifact.timeline_transition_application_selected_integrity_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_transition_application_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    summary = timeline_transition_application_selected_integrity_summary_fixture()

    observations =
      timeline_transition_application_selected_integrity_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "selected_timeline_integrity_issue_count" => 1,
             "selected_timeline_integrity_review_count" => 1,
             "selected_timeline_integrity_issue_type_counts" => %{
               "missing_dependency_activity" => 1
             },
             "row_derived_selected_timeline_integrity_issue_type_counts" => %{
               "missing_dependency_activity" => 1
             },
             "row_derived_selected_required_operator_action_counts" => %{
               "review_changed_protected_activity" => 1
             },
             "row_derived_selected_review_timeline_ids_by_required_operator_action" => %{
               "review_changed_protected_activity" => ["timeline:cmd_lock"]
             },
             "row_derived_selected_missing_dependency_activity_keys" => "cmd_prereq"
           } = observations

    stale_selected_issue_count_observations =
      observations
      |> Map.put("selected_timeline_integrity_issue_count", 0)

    assert {:ok, stale_selected_issue_count_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_selected_issue_count_observations
             )

    assert stale_selected_issue_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_selected_issue_count_verification["checks"],
             &(&1["field"] == "selected_timeline_integrity_issue_count" and
                 &1["status"] == "fail")
           )

    stale_selected_routing_observations =
      observations
      |> put_in(
        [
          "row_derived_selected_review_timeline_ids_by_required_operator_action",
          "review_changed_protected_activity"
        ],
        []
      )

    assert {:ok, stale_selected_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_selected_routing_observations)

    assert stale_selected_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_selected_routing_verification["checks"],
             &(&1["field"] ==
                 "row_derived_selected_review_timeline_ids_by_required_operator_action" and
                 &1["status"] == "fail")
           )

    stale_selected_dependency_observations =
      observations
      |> Map.put("row_derived_selected_missing_dependency_activity_keys", "")

    assert {:ok, stale_selected_dependency_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_selected_dependency_observations
             )

    assert stale_selected_dependency_verification["status"] == "fail"

    assert Enum.any?(
             stale_selected_dependency_verification["checks"],
             &(&1["field"] == "row_derived_selected_missing_dependency_activity_keys" and
                 &1["status"] == "fail")
           )

    assert {:ok, _valid_summary} =
             Schema.validate_artifact(summary,
               schema_contract: "timeline_transition_application_summary.v1"
             )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_transition_application_summary.v1",
             summary
           ) ==
             Validation.artifact_observations(
               "timeline_transition_application_summary.v1",
               summary
             )
  end

  test "verifies curated timeline transition application report reference fixtures" do
    fixture_id = "fixture.artifact.timeline_transition_application_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_transition_application_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_transition_application_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               timeline_transition_application_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      timeline_transition_application_report_fixture_observations()
      |> Map.put("application_count", 3)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "application_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      timeline_transition_application_report_fixture_observations()
      |> put_in(["row_derived_application_status_counts", "operator_review_required"], 1)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_application_status_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report,
               schema_contract: "timeline_transition_application_report.v1"
             )

    stale_application_count = Map.put(report, "application_count", 0)

    assert {:error, stale_application_count_report} =
             Schema.validate_artifact(stale_application_count,
               schema_contract: "timeline_transition_application_report.v1"
             )

    assert Enum.any?(
             stale_application_count_report["errors"],
             &(&1["path"] == "$.application_count")
           )

    stale_transition_decision_counts =
      Map.put(report, "transition_decision_counts", %{"none" => 4})

    assert {:error, stale_transition_decision_counts_report} =
             Schema.validate_artifact(stale_transition_decision_counts,
               schema_contract: "timeline_transition_application_report.v1"
             )

    assert Enum.any?(
             stale_transition_decision_counts_report["errors"],
             &(&1["path"] == "$.transition_decision_counts")
           )

    stale_model_limits = Map.put(report, "model_limits", ["artifact_level_only"])

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "timeline_transition_application_report.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_transition_application_report.v1",
             report
           ) ==
             Validation.artifact_observations("timeline_transition_application_report.v1", report)
  end

  test "verifies curated timeline transition application selected integrity reference fixtures" do
    fixture_id = "fixture.artifact.timeline_transition_application_selected_integrity.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_transition_application_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_transition_application_selected_integrity_fixture()
    observations = timeline_transition_application_selected_integrity_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "selected_timeline_integrity_issue_count" => 1,
             "selected_timeline_integrity_review_count" => 1,
             "selected_timeline_integrity_issue_type_counts" => %{
               "missing_dependency_activity" => 1
             },
             "row_derived_selected_timeline_integrity_issue_type_counts" => %{
               "missing_dependency_activity" => 1
             },
             "row_derived_selected_required_operator_action_counts" => %{
               "review_changed_protected_activity" => 1
             },
             "row_derived_selected_application_ids_by_required_operator_action" => %{
               "review_changed_protected_activity" => ["timeline_diff:timeline:cmd_lock"]
             },
             "row_derived_selected_missing_dependency_activity_keys" => "cmd_prereq"
           } = observations

    stale_selected_issue_count_observations =
      observations
      |> Map.put("selected_timeline_integrity_issue_count", 0)

    assert {:ok, stale_selected_issue_count_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_selected_issue_count_observations
             )

    assert stale_selected_issue_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_selected_issue_count_verification["checks"],
             &(&1["field"] == "selected_timeline_integrity_issue_count" and
                 &1["status"] == "fail")
           )

    stale_selected_issue_type_observations =
      observations
      |> put_in(
        [
          "row_derived_selected_timeline_integrity_issue_type_counts",
          "missing_dependency_activity"
        ],
        0
      )

    assert {:ok, stale_selected_issue_type_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_selected_issue_type_observations
             )

    assert stale_selected_issue_type_verification["status"] == "fail"

    assert Enum.any?(
             stale_selected_issue_type_verification["checks"],
             &(&1["field"] == "row_derived_selected_timeline_integrity_issue_type_counts" and
                 &1["status"] == "fail")
           )

    stale_selected_dependency_observations =
      observations
      |> Map.put("row_derived_selected_missing_dependency_activity_keys", "")

    assert {:ok, stale_selected_dependency_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_selected_dependency_observations
             )

    assert stale_selected_dependency_verification["status"] == "fail"

    assert Enum.any?(
             stale_selected_dependency_verification["checks"],
             &(&1["field"] == "row_derived_selected_missing_dependency_activity_keys" and
                 &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report,
               schema_contract: "timeline_transition_application_report.v1"
             )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_transition_application_report.v1",
             report
           ) ==
             Validation.artifact_observations("timeline_transition_application_report.v1", report)
  end

  test "verifies curated timeline feedback report reference fixtures" do
    fixture_id = "fixture.artifact.timeline_feedback_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_feedback_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_feedback_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               timeline_feedback_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      timeline_feedback_report_fixture_observations()
      |> Map.put("execution_uncertainty_missing_count", 0)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "execution_uncertainty_missing_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      timeline_feedback_report_fixture_observations()
      |> put_in(["row_derived_feedback_kind_counts", "maneuver"], 0)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_feedback_kind_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "timeline_feedback_report.v1")

    stale_row_count = Map.put(report, "row_count", 0)

    assert {:error, stale_row_count_report} =
             Schema.validate_artifact(stale_row_count,
               schema_contract: "timeline_feedback_report.v1"
             )

    assert Enum.any?(
             stale_row_count_report["errors"],
             &(&1["path"] == "$.row_count")
           )

    stale_model_limits = Map.put(report, "model_limits", ["artifact_level_only"])

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "timeline_feedback_report.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_feedback_report.v1",
             report
           ) == Validation.artifact_observations("timeline_feedback_report.v1", report)
  end

  test "verifies curated Cadence import manifest reference fixtures" do
    fixture_id = "fixture.artifact.cadence_import_manifest.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.cadence_import_manifest.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = cadence_import_manifest_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               cadence_import_manifest_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      cadence_import_manifest_fixture_observations()
      |> Map.put("blocked_count", 0)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "blocked_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      cadence_import_manifest_fixture_observations()
      |> put_in(["row_derived_import_status_counts", "blocked_missing_cadence_import"], 0)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_import_status_counts" and &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(artifact,
               schema_contract: "cadence_import_manifest.v1"
             )

    stale_row_count = Map.put(artifact, "row_count", 1)

    assert {:error, stale_row_count_report} =
             Schema.validate_artifact(stale_row_count,
               schema_contract: "cadence_import_manifest.v1"
             )

    assert Enum.any?(
             stale_row_count_report["errors"],
             &(&1["path"] == "$.row_count")
           )

    stale_ready_count = Map.put(artifact, "ready_count", 0)

    assert {:error, stale_ready_count_report} =
             Schema.validate_artifact(stale_ready_count,
               schema_contract: "cadence_import_manifest.v1"
             )

    assert Enum.any?(
             stale_ready_count_report["errors"],
             &(&1["path"] == "$.ready_count")
           )

    stale_import_action_counts = Map.put(artifact, "import_action_counts", %{})

    assert {:error, stale_import_action_counts_report} =
             Schema.validate_artifact(stale_import_action_counts,
               schema_contract: "cadence_import_manifest.v1"
             )

    assert Enum.any?(
             stale_import_action_counts_report["errors"],
             &(&1["path"] == "$.import_action_counts")
           )

    stale_import_status_counts =
      put_in(artifact, ["import_status_counts", "blocked_missing_cadence_import"], 0)

    assert {:error, stale_import_status_counts_report} =
             Schema.validate_artifact(stale_import_status_counts,
               schema_contract: "cadence_import_manifest.v1"
             )

    assert Enum.any?(
             stale_import_status_counts_report["errors"],
             &(&1["path"] == "$.import_status_counts")
           )

    stale_model_limits =
      Map.put(artifact, "model_limits", Enum.drop(Map.fetch!(artifact, "model_limits"), 1))

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "cadence_import_manifest.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )

    stale_execution_boundary =
      put_in(artifact, ["assumptions", "execution_boundary"], "cadence_api_write_ready")

    assert {:error, stale_execution_boundary_report} =
             Schema.validate_artifact(stale_execution_boundary,
               schema_contract: "cadence_import_manifest.v1"
             )

    assert Enum.any?(
             stale_execution_boundary_report["errors"],
             &(&1["path"] == "$.assumptions.execution_boundary")
           )

    stale_authorization_boundary =
      put_in(artifact, ["assumptions", "authorization_boundary"], "already_authorized")

    assert {:error, stale_authorization_boundary_report} =
             Schema.validate_artifact(stale_authorization_boundary,
               schema_contract: "cadence_import_manifest.v1"
             )

    assert Enum.any?(
             stale_authorization_boundary_report["errors"],
             &(&1["path"] == "$.assumptions.authorization_boundary")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "cadence_import_manifest.v1",
             artifact
           ) == Validation.artifact_observations("cadence_import_manifest.v1", artifact)
  end

  test "verifies curated resource pressure handoff reference fixtures" do
    fixtures = [
      {
        "fixture.artifact.quality_gate_report.resource_pressure_v1",
        "quality_gate_report.v1",
        quality_gate_resource_pressure_fixture(),
        quality_gate_resource_pressure_fixture_observations()
      },
      {
        "fixture.artifact.operational_readiness_report.resource_pressure_v1",
        "operational_readiness_report.v1",
        operational_readiness_resource_pressure_fixture(),
        operational_readiness_resource_pressure_fixture_observations()
      },
      {
        "fixture.artifact.operator_review_package.resource_pressure_v1",
        "operator_review_package.v1",
        operator_review_resource_pressure_fixture(),
        operator_review_resource_pressure_fixture_observations()
      },
      {
        "fixture.artifact.cadence_import_manifest.resource_pressure_v1",
        "cadence_import_manifest.v1",
        cadence_import_resource_pressure_fixture(),
        cadence_import_resource_pressure_fixture_observations()
      }
    ]

    for {fixture_id, contract, artifact, observations} <- fixtures do
      assert {:ok, fixture} = Validation.reference_fixture(fixture_id)
      assert fixture["fixture_type"] == "curated_internal_artifact_regression"

      assert {:ok, verification} =
               Validation.verify_reference_fixture(fixture_id, observations)

      assert verification["status"] == "pass"
      assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

      assert {:ok, _schema_report} =
               Schema.validate_artifact(artifact, schema_contract: contract)

      assert OrbitalDynamics.validation_artifact_observations(contract, artifact) ==
               Validation.artifact_observations(contract, artifact)
    end

    quality_gate_observations = quality_gate_resource_pressure_fixture_observations()

    assert quality_gate_observations["resource_availability_gate_count"] == 1
    assert quality_gate_observations["row_derived_resource_availability_pressure_count"] == 2

    assert quality_gate_observations["row_derived_resource_availability_reason_counts"] == %{
             "antenna_unavailable" => 1,
             "payload_unavailable" => 1
           }

    readiness_observations = operational_readiness_resource_pressure_fixture_observations()

    assert readiness_observations["resource_availability_pressure_count"] == 2

    assert readiness_observations["row_derived_resource_availability_reason_keys"] ==
             "antenna_unavailable|payload_unavailable"

    review_observations = operator_review_resource_pressure_fixture_observations()

    assert review_observations["resource_availability_review_row_count"] == 2
    assert review_observations["row_derived_resource_availability_pressure_count"] == 4

    import_observations = cadence_import_resource_pressure_fixture_observations()

    assert import_observations["resource_availability_import_row_count"] == 2
    assert import_observations["row_derived_resource_availability_pressure_count"] == 4

    stale_quality_gate_observations =
      quality_gate_observations
      |> Map.put("resource_availability_gate_count", 0)

    assert {:ok, stale_quality_gate_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.quality_gate_report.resource_pressure_v1",
               stale_quality_gate_observations
             )

    assert stale_quality_gate_verification["status"] == "fail"

    assert Enum.any?(
             stale_quality_gate_verification["checks"],
             &(&1["field"] == "resource_availability_gate_count" and &1["status"] == "fail")
           )

    stale_readiness_observations =
      readiness_observations
      |> Map.put("resource_availability_pressure_count", 0)

    assert {:ok, stale_readiness_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.operational_readiness_report.resource_pressure_v1",
               stale_readiness_observations
             )

    assert stale_readiness_verification["status"] == "fail"

    assert Enum.any?(
             stale_readiness_verification["checks"],
             &(&1["field"] == "resource_availability_pressure_count" and
                 &1["status"] == "fail")
           )

    stale_review_observations =
      review_observations
      |> Map.put("resource_availability_review_row_count", 1)

    assert {:ok, stale_review_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.operator_review_package.resource_pressure_v1",
               stale_review_observations
             )

    assert stale_review_verification["status"] == "fail"

    assert Enum.any?(
             stale_review_verification["checks"],
             &(&1["field"] == "resource_availability_review_row_count" and
                 &1["status"] == "fail")
           )

    stale_import_observations =
      import_observations
      |> put_in(["row_derived_resource_availability_reason_counts", "antenna_unavailable"], 1)

    assert {:ok, stale_import_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.cadence_import_manifest.resource_pressure_v1",
               stale_import_observations
             )

    assert stale_import_verification["status"] == "fail"

    assert Enum.any?(
             stale_import_verification["checks"],
             &(&1["field"] == "row_derived_resource_availability_reason_counts" and
                 &1["status"] == "fail")
           )
  end

  test "verifies curated command window report reference fixtures" do
    fixture_id = "fixture.artifact.command_window_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.command_window_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = command_window_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               command_window_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      command_window_report_fixture_observations()
      |> Map.put("review_required_count", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "review_required_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      command_window_report_fixture_observations()
      |> put_in(["row_derived_required_operator_action_counts", "monitor_activity"], 1)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_required_operator_action_counts" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "command_window_report.v1",
             report
           ) == Validation.artifact_observations("command_window_report.v1", report)

    assert {:ok, %{"schema_contract" => "command_window_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "command_window_report.v1"
             )

    stale_window_count = Map.put(report, "window_count", 3)

    assert {:error, stale_window_count_report} =
             Schema.validate_artifact(stale_window_count,
               schema_contract: "command_window_report.v1"
             )

    assert Enum.any?(
             stale_window_count_report["errors"],
             &(&1["path"] == "$.window_count")
           )

    stale_command_count = Map.put(report, "command_count", 2)

    assert {:error, stale_command_count_report} =
             Schema.validate_artifact(stale_command_count,
               schema_contract: "command_window_report.v1"
             )

    assert Enum.any?(
             stale_command_count_report["errors"],
             &(&1["path"] == "$.command_count")
           )

    stale_review_required_count = Map.put(report, "review_required_count", 1)

    assert {:error, stale_review_required_count_report} =
             Schema.validate_artifact(stale_review_required_count,
               schema_contract: "command_window_report.v1"
             )

    assert Enum.any?(
             stale_review_required_count_report["errors"],
             &(&1["path"] == "$.review_required_count")
           )

    stale_source_window_lineage_count = Map.put(report, "source_window_lineage_count", 0)

    assert {:error, stale_source_window_lineage_count_report} =
             Schema.validate_artifact(stale_source_window_lineage_count,
               schema_contract: "command_window_report.v1"
             )

    assert Enum.any?(
             stale_source_window_lineage_count_report["errors"],
             &(&1["path"] == "$.source_window_lineage_count")
           )
  end

  test "verifies curated constraint report reference fixtures" do
    fixture_id = "fixture.artifact.constraint_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.constraint_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = constraint_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               constraint_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      constraint_report_fixture_observations()
      |> Map.put("status_counts", %{"fail" => 2, "pass" => 1})

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "status_counts" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      constraint_report_fixture_observations()
      |> put_in(["row_derived_status_counts", "warning"], 0)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_status_counts" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "constraint_report.v1",
             report
           ) == Validation.artifact_observations("constraint_report.v1", report)

    assert {:ok, %{"schema_contract" => "constraint_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "constraint_report.v1"
             )

    stale_constraint_count = Map.put(report, "constraint_count", 3)

    assert {:error, stale_constraint_count_report} =
             Schema.validate_artifact(stale_constraint_count,
               schema_contract: "constraint_report.v1"
             )

    assert Enum.any?(
             stale_constraint_count_report["errors"],
             &(&1["path"] == "$.constraint_count")
           )

    stale_row_count = Map.put(report, "row_count", 2)

    assert {:error, stale_row_count_report} =
             Schema.validate_artifact(stale_row_count,
               schema_contract: "constraint_report.v1"
             )

    assert Enum.any?(
             stale_row_count_report["errors"],
             &(&1["path"] == "$.row_count")
           )

    stale_status = Map.put(report, "status", "warning")

    assert {:error, stale_status_report} =
             Schema.validate_artifact(stale_status,
               schema_contract: "constraint_report.v1"
             )

    assert Enum.any?(
             stale_status_report["errors"],
             &(&1["path"] == "$.status")
           )

    stale_status_counts = put_in(report, ["status_counts", "warning"], 0)

    assert {:error, stale_status_counts_report} =
             Schema.validate_artifact(stale_status_counts,
               schema_contract: "constraint_report.v1"
             )

    assert Enum.any?(
             stale_status_counts_report["errors"],
             &(&1["path"] == "$.status_counts")
           )
  end

  test "verifies curated operational timeline report reference fixtures" do
    fixture_id = "fixture.artifact.operational_timeline_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.operational_timeline_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_timeline_report_fixture()

    assert generated_operational_timeline_report_fixture() == report

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               operational_timeline_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      operational_timeline_report_fixture_observations()
      |> Map.put("timeline_integrity_review_count", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "timeline_integrity_review_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      operational_timeline_report_fixture_observations()
      |> put_in(["row_derived_required_operator_action_counts", "review_timeline_integrity"], 1)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_required_operator_action_counts" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_timeline_report.v1",
             report
           ) == Validation.artifact_observations("operational_timeline_report.v1", report)

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "operational_timeline_report.v1"
             )

    stale_row_count = Map.put(report, "row_count", 2)

    assert {:error, stale_row_count_report} =
             Schema.validate_artifact(stale_row_count,
               schema_contract: "operational_timeline_report.v1"
             )

    assert Enum.any?(
             stale_row_count_report["errors"],
             &(&1["path"] == "$.row_count")
           )

    stale_activity_status_counts = put_in(report, ["activity_status_counts", "planned"], 2)

    assert {:error, stale_activity_status_counts_report} =
             Schema.validate_artifact(stale_activity_status_counts,
               schema_contract: "operational_timeline_report.v1"
             )

    assert Enum.any?(
             stale_activity_status_counts_report["errors"],
             &(&1["path"] == "$.activity_status_counts")
           )

    stale_required_operator_action_counts =
      put_in(report, ["required_operator_action_counts", "review_timeline_integrity"], 1)

    assert {:error, stale_required_operator_action_counts_report} =
             Schema.validate_artifact(stale_required_operator_action_counts,
               schema_contract: "operational_timeline_report.v1"
             )

    assert Enum.any?(
             stale_required_operator_action_counts_report["errors"],
             &(&1["path"] == "$.required_operator_action_counts")
           )

    stale_cadence_import_status_counts =
      put_in(report, ["cadence_import_status_counts", "present"], 0)

    assert {:error, stale_cadence_import_status_counts_report} =
             Schema.validate_artifact(stale_cadence_import_status_counts,
               schema_contract: "operational_timeline_report.v1"
             )

    assert Enum.any?(
             stale_cadence_import_status_counts_report["errors"],
             &(&1["path"] == "$.cadence_import_status_counts")
           )

    stale_timeline_integrity_issue_count = Map.put(report, "timeline_integrity_issue_count", 4)

    assert {:error, stale_timeline_integrity_issue_count_report} =
             Schema.validate_artifact(stale_timeline_integrity_issue_count,
               schema_contract: "operational_timeline_report.v1"
             )

    assert Enum.any?(
             stale_timeline_integrity_issue_count_report["errors"],
             &(&1["path"] == "$.timeline_integrity_issue_count")
           )
  end

  test "verifies curated contact allocation report reference fixtures" do
    fixture_id = "fixture.artifact.contact_allocation_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.contact_allocation_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = contact_allocation_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               contact_allocation_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      contact_allocation_report_fixture_observations()
      |> Map.put("blocked_contact_count", 2)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "blocked_contact_count" and &1["status"] == "fail")
           )

    stale_row_derived_count_observations =
      contact_allocation_report_fixture_observations()
      |> Map.put("row_derived_blocked_contact_count", 2)

    assert {:ok, stale_row_derived_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_count_observations)

    assert stale_row_derived_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_count_verification["checks"],
             &(&1["field"] == "row_derived_blocked_contact_count" and
                 &1["status"] == "fail")
           )

    stale_row_derived_observations =
      contact_allocation_report_fixture_observations()
      |> put_in(["row_derived_allocation_reason_counts", "ground_station_reserved"], 0)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_allocation_reason_counts" and
                 &1["status"] == "fail")
           )

    stale_reservation_observations =
      contact_allocation_report_fixture_observations()
      |> Map.put("row_derived_station_reservation_id_counts", %{})

    assert {:ok, stale_reservation_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_reservation_observations)

    assert stale_reservation_verification["status"] == "fail"

    assert Enum.any?(
             stale_reservation_verification["checks"],
             &(&1["field"] == "row_derived_station_reservation_id_counts" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_allocation_report.v1",
             report
           ) ==
             Validation.artifact_observations("contact_allocation_report.v1", report)

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "contact_allocation_report.v1"
             )

    stale_allocation_status_counts =
      put_in(report, ["allocation_status_counts", "blocked"], 2)

    assert {:error, stale_allocation_status_counts_report} =
             Schema.validate_artifact(stale_allocation_status_counts,
               schema_contract: "contact_allocation_report.v1"
             )

    assert Enum.any?(
             stale_allocation_status_counts_report["errors"],
             &(&1["path"] == "$.allocation_status_counts")
           )

    stale_allocation_reason_counts =
      put_in(report, ["allocation_reason_counts", "ground_station_reserved"], 0)

    assert {:error, stale_allocation_reason_counts_report} =
             Schema.validate_artifact(stale_allocation_reason_counts,
               schema_contract: "contact_allocation_report.v1"
             )

    assert Enum.any?(
             stale_allocation_reason_counts_report["errors"],
             &(&1["path"] == "$.allocation_reason_counts")
           )

    stale_reservation_match_status_counts =
      put_in(report, ["station_reservation_match_status_counts", "overlap"], 0)

    assert {:error, stale_reservation_match_status_counts_report} =
             Schema.validate_artifact(stale_reservation_match_status_counts,
               schema_contract: "contact_allocation_report.v1"
             )

    assert Enum.any?(
             stale_reservation_match_status_counts_report["errors"],
             &(&1["path"] == "$.station_reservation_match_status_counts")
           )

    stale_reservation_ids = Map.put(report, "station_reservation_ids", [])

    assert {:error, stale_reservation_ids_report} =
             Schema.validate_artifact(stale_reservation_ids,
               schema_contract: "contact_allocation_report.v1"
             )

    assert Enum.any?(
             stale_reservation_ids_report["errors"],
             &(&1["path"] == "$.station_reservation_ids")
           )
  end

  test "verifies curated reservation conflict summary reference fixtures" do
    fixture_id = "fixture.artifact.contact_allocation_reservation_conflict_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] ==
             "artifact.contact_allocation_reservation_conflict_summary.v1"

    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    summary = read_json!("study_results/contact_allocation_reservation_conflict_summary_v1.json")

    observations =
      Validation.artifact_observations(
        "contact_allocation_reservation_conflict_summary.v1",
        summary
      )

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               observations
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_conflict_direction_station_observations =
      observations
      |> put_in(
        [
          "row_derived_reservation_conflict_contact_ids_by_direction_and_ground_station_id",
          "downlink",
          "equator_prime"
        ],
        ["stale_contact"]
      )

    assert {:ok, stale_conflict_direction_station_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_conflict_direction_station_observations
             )

    assert stale_conflict_direction_station_verification["status"] == "fail"

    assert Enum.any?(
             stale_conflict_direction_station_verification["checks"],
             &(&1["field"] ==
                 "row_derived_reservation_conflict_contact_ids_by_direction_and_ground_station_id" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_allocation_reservation_conflict_summary.v1",
             summary
           ) == observations

    assert {:ok, %{"schema_contract" => "contact_allocation_reservation_conflict_summary.v1"}} =
             Schema.validate_artifact(summary)
  end

  test "verifies curated station pressure summary reference fixtures" do
    fixture_id = "fixture.artifact.contact_allocation_station_pressure_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.contact_allocation_station_pressure_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    summary = read_json!("study_results/contact_allocation_station_pressure_summary_v1.json")

    observations =
      Validation.artifact_observations(
        "contact_allocation_station_pressure_summary.v1",
        summary
      )

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               observations
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_station_direction_observations =
      observations
      |> put_in(
        [
          "row_derived_station_pressure_contact_ids_by_direction_and_ground_station_id",
          "downlink",
          "equator_prime"
        ],
        ["stale_contact"]
      )

    assert {:ok, stale_station_direction_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_station_direction_observations
             )

    assert stale_station_direction_verification["status"] == "fail"

    assert Enum.any?(
             stale_station_direction_verification["checks"],
             &(&1["field"] ==
                 "row_derived_station_pressure_contact_ids_by_direction_and_ground_station_id" and
                 &1["status"] == "fail")
           )

    stale_station_status_observations =
      put_in(
        observations,
        ["row_derived_station_pressure_contact_ids_by_status", "reserved"],
        ["stale_contact"]
      )

    assert {:ok, stale_station_status_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_station_status_observations
             )

    assert stale_station_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_station_status_verification["checks"],
             &(&1["field"] == "row_derived_station_pressure_contact_ids_by_status" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_allocation_station_pressure_summary.v1",
             summary
           ) == observations

    assert {:ok, %{"schema_contract" => "contact_allocation_station_pressure_summary.v1"}} =
             Schema.validate_artifact(summary)
  end

  test "verifies curated capacity pack summary reference fixtures" do
    fixture_id = "fixture.artifact.contact_allocation_capacity_pack_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.contact_allocation_capacity_pack_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    summary = read_json!("study_results/contact_allocation_capacity_pack_summary_v1.json")

    observations =
      Validation.artifact_observations(
        "contact_allocation_capacity_pack_summary.v1",
        summary
      )

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               observations
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_capacity_status_observations =
      observations
      |> put_in(
        [
          "row_derived_capacity_pack_contact_ids_by_status",
          "deferred_by_reduced_station_capacity_pack"
        ],
        []
      )

    assert {:ok, stale_capacity_status_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_capacity_status_observations
             )

    assert stale_capacity_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_capacity_status_verification["checks"],
             &(&1["field"] == "row_derived_capacity_pack_contact_ids_by_status" and
                 &1["status"] == "fail")
           )

    stale_group_status_observations =
      observations
      |> put_in(
        [
          "row_derived_reduced_capacity_pack_group_ids_by_status",
          "capacity_limited"
        ],
        []
      )

    assert {:ok, stale_group_status_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_group_status_observations
             )

    assert stale_group_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_group_status_verification["checks"],
             &(&1["field"] == "row_derived_reduced_capacity_pack_group_ids_by_status" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_allocation_capacity_pack_summary.v1",
             summary
           ) == observations

    assert {:ok, %{"schema_contract" => "contact_allocation_capacity_pack_summary.v1"}} =
             Schema.validate_artifact(summary)
  end

  test "verifies curated contact allocation summary reference fixtures" do
    fixture_id = "fixture.artifact.contact_allocation_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.contact_allocation_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    summary = read_json!("study_results/contact_allocation_summary_v1.json")

    observations =
      Validation.artifact_observations(
        "contact_allocation_summary.v1",
        summary
      )

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               observations
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_allocation_status_observations =
      observations
      |> put_in(
        [
          "row_derived_contact_ids_by_effective_allocation_status",
          "blocked"
        ],
        []
      )

    assert {:ok, stale_allocation_status_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_allocation_status_observations
             )

    assert stale_allocation_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_allocation_status_verification["checks"],
             &(&1["field"] == "row_derived_contact_ids_by_effective_allocation_status" and
                 &1["status"] == "fail")
           )

    stale_station_pressure_observations =
      observations
      |> put_in(
        [
          "row_derived_station_pressure_contact_ids_by_ground_station_id",
          "equator_prime"
        ],
        []
      )

    assert {:ok, stale_station_pressure_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_station_pressure_observations
             )

    assert stale_station_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_station_pressure_verification["checks"],
             &(&1["field"] == "row_derived_station_pressure_contact_ids_by_ground_station_id" and
                 &1["status"] == "fail")
           )

    stale_station_pressure_status_observations =
      put_in(
        observations,
        ["row_derived_station_pressure_contact_ids_by_status", "reserved"],
        []
      )

    assert {:ok, stale_station_pressure_status_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_station_pressure_status_observations
             )

    assert stale_station_pressure_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_station_pressure_status_verification["checks"],
             &(&1["field"] == "row_derived_station_pressure_contact_ids_by_status" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_allocation_summary.v1",
             summary
           ) == observations

    assert {:ok, %{"schema_contract" => "contact_allocation_summary.v1"}} =
             Schema.validate_artifact(summary)
  end

  test "verifies curated provider reservation request summary reference fixtures" do
    fixture_id = "fixture.artifact.contact_allocation_provider_reservation_request_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] ==
             "artifact.contact_allocation_provider_reservation_request_summary.v1"

    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    summary = contact_allocation_provider_reservation_request_summary_fixture()
    observations = contact_allocation_provider_reservation_request_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               observations
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_checked_in_summary =
      summary
      |> put_in(
        ["provider_reservation_request_contact_ids_by_direction", "downlink"],
        ["stale_contact"]
      )

    assert {:ok, stale_checked_in_summary_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               Validation.artifact_observations(
                 "contact_allocation_provider_reservation_request_summary.v1",
                 stale_checked_in_summary
               )
             )

    assert stale_checked_in_summary_verification["status"] == "fail"

    assert Enum.any?(
             stale_checked_in_summary_verification["checks"],
             &(&1["field"] == "provider_reservation_request_contact_ids_by_direction" and
                 &1["status"] == "fail")
           )

    stale_request_direction_observations =
      observations
      |> put_in(
        ["row_derived_provider_reservation_request_contact_ids_by_direction", "downlink"],
        ["stale_contact"]
      )

    assert {:ok, stale_request_direction_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_request_direction_observations)

    assert stale_request_direction_verification["status"] == "fail"

    assert Enum.any?(
             stale_request_direction_verification["checks"],
             &(&1["field"] ==
                 "row_derived_provider_reservation_request_contact_ids_by_direction" and
                 &1["status"] == "fail")
           )

    stale_request_direction_station_observations =
      observations
      |> put_in(
        [
          "row_derived_provider_reservation_request_contact_ids_by_direction_and_ground_station_id",
          "downlink",
          "equator_prime"
        ],
        ["stale_contact"]
      )

    assert {:ok, stale_request_direction_station_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_request_direction_station_observations
             )

    assert stale_request_direction_station_verification["status"] == "fail"

    assert Enum.any?(
             stale_request_direction_station_verification["checks"],
             &(&1["field"] ==
                 "row_derived_provider_reservation_request_contact_ids_by_direction_and_ground_station_id" and
                 &1["status"] == "fail")
           )

    stale_review_direction_station_observations =
      observations
      |> put_in(
        [
          "row_derived_provider_reservation_review_contact_ids_by_direction_and_ground_station_id",
          "command",
          "equator_prime"
        ],
        ["stale_contact"]
      )

    assert {:ok, stale_review_direction_station_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_review_direction_station_observations
             )

    assert stale_review_direction_station_verification["status"] == "fail"

    assert Enum.any?(
             stale_review_direction_station_verification["checks"],
             &(&1["field"] ==
                 "row_derived_provider_reservation_review_contact_ids_by_direction_and_ground_station_id" and
                 &1["status"] == "fail")
           )

    stale_no_request_direction_observations =
      observations
      |> put_in(
        ["row_derived_provider_reservation_no_request_contact_ids_by_direction", "tracking"],
        []
      )

    assert {:ok, stale_no_request_direction_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_no_request_direction_observations
             )

    assert stale_no_request_direction_verification["status"] == "fail"

    assert Enum.any?(
             stale_no_request_direction_verification["checks"],
             &(&1["field"] ==
                 "row_derived_provider_reservation_no_request_contact_ids_by_direction" and
                 &1["status"] == "fail")
           )

    stale_no_request_direction_station_observations =
      observations
      |> put_in(
        [
          "row_derived_provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id",
          "tracking",
          "equator_prime"
        ],
        ["stale_contact"]
      )

    assert {:ok, stale_no_request_direction_station_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_no_request_direction_station_observations
             )

    assert stale_no_request_direction_station_verification["status"] == "fail"

    assert Enum.any?(
             stale_no_request_direction_station_verification["checks"],
             &(&1["field"] ==
                 "row_derived_provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_allocation_provider_reservation_request_summary.v1",
             summary
           ) ==
             Validation.artifact_observations(
               "contact_allocation_provider_reservation_request_summary.v1",
               summary
             )

    assert {:ok,
            %{"schema_contract" => "contact_allocation_provider_reservation_request_summary.v1"}} =
             Schema.validate_artifact(summary)

    stale_request_direction_map =
      Map.put(summary, "provider_reservation_request_contact_ids_by_direction", %{
        "downlink" => ["stale_contact"]
      })

    assert {:error, stale_request_direction_map_report} =
             Schema.validate_artifact(stale_request_direction_map)

    assert Enum.any?(
             stale_request_direction_map_report["errors"],
             &(&1["path"] == "$.provider_reservation_request_contact_ids_by_direction")
           )
  end

  test "verifies curated reduced-capacity contact allocation pack reference fixtures" do
    fixture_id = "fixture.artifact.contact_allocation_report.reduced_capacity_pack"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.contact_allocation_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = contact_allocation_capacity_pack_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               contact_allocation_capacity_pack_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      contact_allocation_capacity_pack_report_fixture_observations()
      |> Map.put("reduced_capacity_pack_capacity_packed_contact_count", 0)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "reduced_capacity_pack_capacity_packed_contact_count" and
                 &1["status"] == "fail")
           )

    stale_reported_observations =
      contact_allocation_capacity_pack_report_fixture_observations()
      |> put_in(
        [
          "reported_capacity_pack_contact_ids_by_status",
          "selected_by_reduced_station_capacity_pack"
        ],
        ["dl_capacity_primary"]
      )

    assert {:ok, stale_reported_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_reported_observations)

    assert stale_reported_verification["status"] == "fail"

    assert Enum.any?(
             stale_reported_verification["checks"],
             &(&1["field"] == "reported_capacity_pack_contact_ids_by_status" and
                 &1["status"] == "fail")
           )

    stale_station_pressure_observations =
      contact_allocation_capacity_pack_report_fixture_observations()
      |> put_in(
        [
          "reported_station_pressure_contact_ids_by_availability",
          "reduced_capacity"
        ],
        ["dl_capacity_primary"]
      )

    assert {:ok, stale_station_pressure_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_station_pressure_observations)

    assert stale_station_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_station_pressure_verification["checks"],
             &(&1["field"] == "reported_station_pressure_contact_ids_by_availability" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_allocation_report.v1",
             report
           ) ==
             Validation.artifact_observations("contact_allocation_report.v1", report)

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "contact_allocation_report.v1"
             )

    stale_pack_status_counts =
      put_in(report, ["reduced_capacity_pack_status_counts", "capacity_limited"], 0)

    assert {:error, stale_pack_status_counts_report} =
             Schema.validate_artifact(stale_pack_status_counts,
               schema_contract: "contact_allocation_report.v1"
             )

    assert Enum.any?(
             stale_pack_status_counts_report["errors"],
             &(&1["path"] == "$.reduced_capacity_pack_status_counts")
           )

    stale_contact_status_counts =
      put_in(
        report,
        ["capacity_pack_status_counts", "selected_by_reduced_station_capacity_pack"],
        0
      )

    assert {:error, stale_contact_status_counts_report} =
             Schema.validate_artifact(stale_contact_status_counts,
               schema_contract: "contact_allocation_report.v1"
             )

    assert Enum.any?(
             stale_contact_status_counts_report["errors"],
             &(&1["path"] == "$.capacity_pack_status_counts")
           )

    stale_contact_ids_by_status =
      put_in(
        report,
        ["capacity_pack_contact_ids_by_status", "selected_by_reduced_station_capacity_pack"],
        ["dl_capacity_primary"]
      )

    assert {:error, stale_contact_ids_by_status_report} =
             Schema.validate_artifact(stale_contact_ids_by_status,
               schema_contract: "contact_allocation_report.v1"
             )

    assert Enum.any?(
             stale_contact_ids_by_status_report["errors"],
             &(&1["path"] == "$.capacity_pack_contact_ids_by_status")
           )
  end

  test "verifies curated contact filter report reference fixtures" do
    fixture_id = "fixture.artifact.contact_filter_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.contact_filter_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = contact_filter_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               contact_filter_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      contact_filter_report_fixture_observations()
      |> Map.put("suppressed_candidate_count", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "suppressed_candidate_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      contact_filter_report_fixture_observations()
      |> Map.put("row_derived_suppressed_candidate_count", 1)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_suppressed_candidate_count" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_filter_report.v1",
             report
           ) == Validation.artifact_observations("contact_filter_report.v1", report)

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "contact_filter_report.v1"
             )

    stale_suppressed_count = Map.put(report, "suppressed_candidate_count", 1)

    assert {:error, stale_suppressed_count_report} =
             Schema.validate_artifact(stale_suppressed_count,
               schema_contract: "contact_filter_report.v1"
             )

    assert Enum.any?(
             stale_suppressed_count_report["errors"],
             &(&1["path"] == "$.suppressed_candidate_count")
           )

    stale_kept_count = Map.put(report, "kept_candidate_count", 2)

    assert {:error, stale_kept_count_report} =
             Schema.validate_artifact(stale_kept_count,
               schema_contract: "contact_filter_report.v1"
             )

    assert Enum.any?(
             stale_kept_count_report["errors"],
             &(&1["path"] == "$.kept_candidate_count")
           )

    stale_reservation_match_status_counts =
      put_in(report, ["station_reservation_match_status_counts", "overlap"], 0)

    assert {:error, stale_reservation_match_status_counts_report} =
             Schema.validate_artifact(stale_reservation_match_status_counts,
               schema_contract: "contact_filter_report.v1"
             )

    assert Enum.any?(
             stale_reservation_match_status_counts_report["errors"],
             &(&1["path"] == "$.station_reservation_match_status_counts")
           )

    stale_invalid_contact_input_ids =
      Map.put(report, "invalid_contact_input_ids", ["leo_1_downlink_equator_prime_1"])

    assert {:error, stale_invalid_contact_input_ids_report} =
             Schema.validate_artifact(stale_invalid_contact_input_ids,
               schema_contract: "contact_filter_report.v1"
             )

    assert Enum.any?(
             stale_invalid_contact_input_ids_report["errors"],
             &(&1["path"] == "$.invalid_contact_input_ids")
           )
  end

  test "verifies curated contact contention report reference fixtures" do
    fixture_id = "fixture.artifact.contact_contention_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.contact_contention_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = contact_contention_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               contact_contention_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      contact_contention_report_fixture_observations()
      |> Map.put("conflicted_contact_count", 3)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "conflicted_contact_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      contact_contention_report_fixture_observations()
      |> Map.put("row_derived_conflicted_contact_count", 3)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_conflicted_contact_count" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_contention_report.v1",
             report
           ) == Validation.artifact_observations("contact_contention_report.v1", report)

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "contact_contention_report.v1"
             )

    stale_conflict_group_count = Map.put(report, "conflict_group_count", 1)

    assert {:error, stale_conflict_group_count_report} =
             Schema.validate_artifact(stale_conflict_group_count,
               schema_contract: "contact_contention_report.v1"
             )

    assert Enum.any?(
             stale_conflict_group_count_report["errors"],
             &(&1["path"] == "$.conflict_group_count")
           )

    stale_conflicted_contact_count = Map.put(report, "conflicted_contact_count", 3)

    assert {:error, stale_conflicted_contact_count_report} =
             Schema.validate_artifact(stale_conflicted_contact_count,
               schema_contract: "contact_contention_report.v1"
             )

    assert Enum.any?(
             stale_conflicted_contact_count_report["errors"],
             &(&1["path"] == "$.conflicted_contact_count")
           )
  end

  test "verifies cross-station contact contention challenge fixture" do
    fixture_id = "fixture.artifact.contact_contention_report.cross_station_spacecraft"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.contact_contention_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = contact_contention_cross_station_fixture()

    checked_in_report =
      read_json!("study_results/contact_contention_cross_station_spacecraft_v1.json")

    assert checked_in_report == report

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "contact_contention_report.v1"
             )

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               contact_contention_cross_station_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "resource_scope_counts" => %{"spacecraft" => 1},
             "conflict_group_ids_by_resource_scope" => %{
               "spacecraft" => ["spacecraft:sat_1:contention:1"]
             }
           } = contact_contention_cross_station_fixture_observations()

    stale_scope_counts =
      contact_contention_cross_station_fixture_observations()
      |> Map.put("resource_scope_counts", %{"ground_station" => 1})

    assert {:ok, stale_scope_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_scope_counts)

    assert stale_scope_verification["status"] == "fail"

    assert Enum.any?(
             stale_scope_verification["checks"],
             &(&1["field"] == "resource_scope_counts" and &1["status"] == "fail")
           )

    stale_row_count = Map.put(report, "conflict_group_count", 2)

    assert {:error, stale_row_count_report} =
             Schema.validate_artifact(stale_row_count,
               schema_contract: "contact_contention_report.v1"
             )

    assert Enum.any?(
             stale_row_count_report["errors"],
             &(&1["path"] == "$.conflict_group_count")
           )
  end

  test "verifies curated contact contention resolution report reference fixtures" do
    fixture_id = "fixture.artifact.contact_contention_resolution_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.contact_contention_resolution_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = contact_contention_resolution_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               contact_contention_resolution_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      contact_contention_resolution_report_fixture_observations()
      |> Map.put("selected_contact_count", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "selected_contact_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      contact_contention_resolution_report_fixture_observations()
      |> Map.put("row_derived_recommendation_count", 1)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_recommendation_count" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_contention_resolution_report.v1",
             report
           ) ==
             Validation.artifact_observations("contact_contention_resolution_report.v1", report)

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "contact_contention_resolution_report.v1"
             )

    stale_recommendation_count = Map.put(report, "recommendation_count", 1)

    assert {:error, stale_recommendation_count_report} =
             Schema.validate_artifact(stale_recommendation_count,
               schema_contract: "contact_contention_resolution_report.v1"
             )

    assert Enum.any?(
             stale_recommendation_count_report["errors"],
             &(&1["path"] == "$.recommendation_count")
           )

    stale_conflict_group_count = Map.put(report, "conflict_group_count", 1)

    assert {:error, stale_conflict_group_count_report} =
             Schema.validate_artifact(stale_conflict_group_count,
               schema_contract: "contact_contention_resolution_report.v1"
             )

    assert Enum.any?(
             stale_conflict_group_count_report["errors"],
             &(&1["path"] == "$.conflict_group_count")
           )
  end

  test "verifies curated contact contention resolution summary reference fixtures" do
    fixture_id = "fixture.artifact.contact_contention_resolution_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.contact_contention_resolution_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = contact_contention_resolution_summary_fixture()
    observations = contact_contention_resolution_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "conflict_group_count" => 2,
             "recommendation_count" => 2,
             "recommendation_group_ids" =>
               "spacecraft:sat_1:contention:1|station:equator_prime:contention:1",
             "review_group_ids" =>
               "spacecraft:sat_1:contention:1|station:equator_prime:contention:1",
             "selected_contact_ids" => "dl_1|dl_3",
             "deferred_contact_ids" => "dl_2|dl_4",
             "review_contact_ids" => "dl_1|dl_2|dl_3|dl_4",
             "review_recommendation_count" => 2,
             "resource_scope_counts" => %{"ground_station" => 1, "spacecraft" => 1},
             "selected_contact_ids_by_resource_scope" => %{
               "ground_station" => ["dl_1"],
               "spacecraft" => ["dl_3"]
             },
             "deferred_contact_ids_by_resource_scope" => %{
               "ground_station" => ["dl_2"],
               "spacecraft" => ["dl_4"]
             },
             "selection_reason_counts" => %{"highest_score_earliest_start" => 2},
             "action_counts" => %{"recommend_preferred_contact_for_operator_review" => 2},
             "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
             "candidate_mutation" => "none",
             "operator_authority" => "not_granted_by_summary",
             "no_provider_reservation" => true,
             "no_candidate_suppression" => true,
             "no_schedule_mutation" => true
           } = observations

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_contention_resolution_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "contact_contention_resolution_summary.v1",
               report
             )

    stale_count_observations = Map.put(observations, "recommendation_count", 1)

    assert {:ok, stale_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_count_observations)

    assert stale_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_count_verification["checks"],
             &(&1["field"] == "recommendation_count" and &1["status"] == "fail")
           )

    stale_routing_observations =
      put_in(observations, ["selected_contact_ids_by_resource_scope", "spacecraft"], [])

    assert {:ok, stale_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_routing_observations)

    assert stale_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_routing_verification["checks"],
             &(&1["field"] == "selected_contact_ids_by_resource_scope" and
                 &1["status"] == "fail")
           )

    stale_boundary_observations =
      Map.put(observations, "execution_boundary", "provider_reservation_ready")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "execution_boundary" and &1["status"] == "fail")
           )

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_summary.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "contact_contention_resolution_summary.v1"
             )
  end

  test "verifies curated link capacity report reference fixtures" do
    fixture_id = "fixture.artifact.link_capacity_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.link_capacity_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = link_capacity_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               link_capacity_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      link_capacity_report_fixture_observations()
      |> Map.put("selected_contact_count", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "selected_contact_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      link_capacity_report_fixture_observations()
      |> Map.put("row_derived_contact_count", 2)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_contact_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "link_capacity_report.v1",
             report
           ) == Validation.artifact_observations("link_capacity_report.v1", report)

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "link_capacity_report.v1"
             )

    stale_contact_count = Map.put(report, "contact_count", 2)

    assert {:error, stale_contact_count_report} =
             Schema.validate_artifact(stale_contact_count,
               schema_contract: "link_capacity_report.v1"
             )

    assert Enum.any?(
             stale_contact_count_report["errors"],
             &(&1["path"] == "$.contact_count")
           )

    stale_selected_count = Map.put(report, "selected_contact_count", 1)

    assert {:error, stale_selected_count_report} =
             Schema.validate_artifact(stale_selected_count,
               schema_contract: "link_capacity_report.v1"
             )

    assert Enum.any?(
             stale_selected_count_report["errors"],
             &(&1["path"] == "$.selected_contact_count")
           )

    stale_throughput = Map.put(report, "estimated_throughput_mb", 0.0)

    assert {:error, stale_throughput_report} =
             Schema.validate_artifact(stale_throughput,
               schema_contract: "link_capacity_report.v1"
             )

    assert Enum.any?(
             stale_throughput_report["errors"],
             &(&1["path"] == "$.estimated_throughput_mb")
           )

    stale_ignored_ids = Map.put(report, "ignored_contact_ids", ["leo_1_downlink_equator_prime_1"])

    assert {:error, stale_ignored_ids_report} =
             Schema.validate_artifact(stale_ignored_ids,
               schema_contract: "link_capacity_report.v1"
             )

    assert Enum.any?(
             stale_ignored_ids_report["errors"],
             &(&1["path"] == "$.ignored_contact_ids")
           )
  end

  test "verifies curated link capacity summary reference fixtures" do
    fixture_id = "fixture.artifact.link_capacity_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.link_capacity_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = link_capacity_summary_fixture()
    observations = link_capacity_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "station_count" => 1,
             "contact_count" => 1,
             "effective_contact_count" => 1,
             "selected_contact_count" => 1,
             "actual_throughput_contact_count" => 1,
             "actual_completion_contact_count" => 0,
             "downlink_requirement_status" => "satisfied",
             "actual_downlink_requirement_status" => "shortfall",
             "selection_utilization_status" => "fully_selected",
             "capacity_adjusted_throughput_mb" => 120.0,
             "actual_downlink_shortfall_mb" => 10.0,
             "contact_ids" => "science_downlink",
             "selected_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["science_downlink"]
             },
             "actual_throughput_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["science_downlink"]
             },
             "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
             "assumption_source" => "link_capacity_report.v1",
             "operator_authority" => "not_granted_by_summary",
             "no_provider_reservation" => true,
             "no_schedule_mutation" => true,
             "no_link_budget_model" => true
           } = observations

    assert OrbitalDynamics.validation_artifact_observations(
             "link_capacity_summary.v1",
             report
           ) == Validation.artifact_observations("link_capacity_summary.v1", report)

    stale_count_observations = Map.put(observations, "actual_throughput_contact_count", 0)

    assert {:ok, stale_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_count_observations)

    assert stale_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_count_verification["checks"],
             &(&1["field"] == "actual_throughput_contact_count" and &1["status"] == "fail")
           )

    stale_routing_observations =
      put_in(observations, ["selected_contact_ids_by_ground_station_id", "equator_prime"], [])

    assert {:ok, stale_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_routing_observations)

    assert stale_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_routing_verification["checks"],
             &(&1["field"] == "selected_contact_ids_by_ground_station_id" and
                 &1["status"] == "fail")
           )

    stale_boundary_observations =
      Map.put(observations, "execution_boundary", "provider_reservation_ready")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "execution_boundary" and &1["status"] == "fail")
           )

    assert {:ok, %{"schema_contract" => "link_capacity_summary.v1"}} =
             Schema.validate_artifact(report, schema_contract: "link_capacity_summary.v1")
  end

  test "verifies curated relay data-path summary reference fixtures" do
    fixture_id = "fixture.artifact.relay_data_path_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.relay_data_path_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = relay_data_path_summary_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               relay_data_path_summary_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      relay_data_path_summary_fixture_observations()
      |> Map.put("relay_route_count", 2)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "relay_route_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      relay_data_path_summary_fixture_observations()
      |> put_in(["row_derived_route_ids_by_latency_status", "within_limit"], ["route_direct"])

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_route_ids_by_latency_status" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "relay_data_path_summary.v1",
             report
           ) == Validation.artifact_observations("relay_data_path_summary.v1", report)

    assert {:ok, %{"schema_contract" => "relay_data_path_summary.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "relay_data_path_summary.v1"
             )

    stale_route_count = Map.put(report, "route_count", 1)

    assert {:error, stale_route_count_report} =
             Schema.validate_artifact(stale_route_count,
               schema_contract: "relay_data_path_summary.v1"
             )

    assert Enum.any?(
             stale_route_count_report["errors"],
             &(&1["path"] == "$.route_count")
           )

    stale_custody_counts =
      Map.put(report, "custody_status_counts", %{"confirmed" => 2, "missing_ack" => 1})

    assert {:error, stale_custody_counts_report} =
             Schema.validate_artifact(stale_custody_counts,
               schema_contract: "relay_data_path_summary.v1"
             )

    assert Enum.any?(
             stale_custody_counts_report["errors"],
             &(&1["path"] == "$.custody_status_counts")
           )

    stale_relay_spacecraft_ids = Map.put(report, "relay_spacecraft_ids", ["relay_2"])

    assert {:error, stale_relay_spacecraft_ids_report} =
             Schema.validate_artifact(stale_relay_spacecraft_ids,
               schema_contract: "relay_data_path_summary.v1"
             )

    assert Enum.any?(
             stale_relay_spacecraft_ids_report["errors"],
             &(&1["path"] == "$.relay_spacecraft_ids")
           )

    stale_latency_routing =
      put_in(report, ["route_ids_by_latency_status", "within_limit"], ["route_direct"])

    assert {:error, stale_latency_routing_report} =
             Schema.validate_artifact(stale_latency_routing,
               schema_contract: "relay_data_path_summary.v1"
             )

    assert Enum.any?(
             stale_latency_routing_report["errors"],
             &(&1["path"] == "$.route_ids_by_latency_status")
           )
  end

  test "verifies curated maneuver review report reference fixtures" do
    fixture_id = "fixture.artifact.maneuver_review_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.maneuver_review_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = maneuver_review_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               maneuver_review_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      maneuver_review_report_fixture_observations()
      |> Map.put("execution_uncertainty_missing_count", 0)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "execution_uncertainty_missing_count" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "maneuver_review_report.v1")

    stale_model = Map.put(report, "model", "stale_maneuver_review_model")

    assert {:error, stale_model_report} =
             Schema.validate_artifact(stale_model,
               schema_contract: "maneuver_review_report.v1"
             )

    assert Enum.any?(
             stale_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] == "must equal \"artifact_only_maneuver_review_report\"")
           )

    stale_total_delta_v = Map.put(report, "total_delta_v_km_s", 0.0)

    assert {:error, stale_total_delta_v_report} =
             Schema.validate_artifact(stale_total_delta_v,
               schema_contract: "maneuver_review_report.v1"
             )

    assert Enum.any?(
             stale_total_delta_v_report["errors"],
             &(&1["path"] == "$.total_delta_v_km_s")
           )

    stale_model_limits = Map.put(report, "model_limits", ["no_command_execution"])

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "maneuver_review_report.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )

    stale_operator_action_counts =
      Map.put(report, "required_operator_action_counts", %{"review_maneuver_recommendation" => 0})

    assert {:error, stale_operator_action_counts_report} =
             Schema.validate_artifact(stale_operator_action_counts,
               schema_contract: "maneuver_review_report.v1"
             )

    assert Enum.any?(
             stale_operator_action_counts_report["errors"],
             &(&1["path"] == "$.required_operator_action_counts")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "maneuver_review_report.v1",
             report
           ) == Validation.artifact_observations("maneuver_review_report.v1", report)
  end

  test "verifies curated Monte Carlo reproducibility report reference fixtures" do
    fixture_id = "fixture.artifact.monte_carlo_reproducibility_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.monte_carlo_reproducibility_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = monte_carlo_reproducibility_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               monte_carlo_reproducibility_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      monte_carlo_reproducibility_report_fixture_observations()
      |> Map.put("generated_scenario_count", 19)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "generated_scenario_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "monte_carlo_reproducibility_report.v1",
             report
           ) ==
             Validation.artifact_observations("monte_carlo_reproducibility_report.v1", report)

    assert {:ok, %{"schema_contract" => "monte_carlo_reproducibility_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "monte_carlo_reproducibility_report.v1"
             )

    stale_model = Map.put(report, "model", "stale_monte_carlo_dispersion_model")

    assert {:error, stale_model_report} =
             Schema.validate_artifact(stale_model,
               schema_contract: "monte_carlo_reproducibility_report.v1"
             )

    assert Enum.any?(
             stale_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"seeded_independent_normal_cartesian_dispersion\"")
           )

    stale_generated_scenario_count = Map.put(report, "generated_scenario_count", 19)

    assert {:error, stale_generated_scenario_count_report} =
             Schema.validate_artifact(stale_generated_scenario_count,
               schema_contract: "monte_carlo_reproducibility_report.v1"
             )

    assert Enum.any?(
             stale_generated_scenario_count_report["errors"],
             &(&1["path"] == "$.generated_scenario_count")
           )

    duplicate_generated_scenario_ids =
      report
      |> Map.fetch!("generated_scenario_ids")
      |> List.replace_at(1, "dispersion_1")

    stale_generated_scenario_ids =
      Map.put(report, "generated_scenario_ids", duplicate_generated_scenario_ids)

    assert {:error, stale_generated_scenario_ids_report} =
             Schema.validate_artifact(stale_generated_scenario_ids,
               schema_contract: "monte_carlo_reproducibility_report.v1"
             )

    assert Enum.any?(
             stale_generated_scenario_ids_report["errors"],
             &(&1["path"] == "$.generated_scenario_ids")
           )

    stale_known_limits =
      Map.put(report, "known_limits", Enum.drop(Map.fetch!(report, "known_limits"), 1))

    assert {:error, stale_known_limits_report} =
             Schema.validate_artifact(stale_known_limits,
               schema_contract: "monte_carlo_reproducibility_report.v1"
             )

    assert Enum.any?(
             stale_known_limits_report["errors"],
             &(&1["path"] == "$.known_limits")
           )
  end

  test "verifies curated Pareto frontier report reference fixtures" do
    fixture_id = "fixture.artifact.pareto_frontier_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.pareto_frontier_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = pareto_frontier_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               pareto_frontier_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      pareto_frontier_report_fixture_observations()
      |> Map.put("frontier_count", 2)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "frontier_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "pareto_frontier_report.v1",
             report
           ) == Validation.artifact_observations("pareto_frontier_report.v1", report)

    assert {:ok, %{"schema_contract" => "pareto_frontier_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "pareto_frontier_report.v1"
             )

    stale_model = Map.put(report, "model", "stale_pareto_frontier_model")

    assert {:error, stale_model_report} =
             Schema.validate_artifact(stale_model,
               schema_contract: "pareto_frontier_report.v1"
             )

    assert Enum.any?(
             stale_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] == "must equal \"objective_vector_pareto_frontier\"")
           )

    stale_count_fields = [
      {"alternative_count", 3},
      {"frontier_count", 2},
      {"dominated_count", 0},
      {"objective_count", 1}
    ]

    Enum.each(stale_count_fields, fn {field, stale_value} ->
      stale_report = Map.put(report, field, stale_value)

      assert {:error, stale_validation_report} =
               Schema.validate_artifact(stale_report,
                 schema_contract: "pareto_frontier_report.v1"
               )

      assert Enum.any?(stale_validation_report["errors"], &(&1["path"] == "$.#{field}"))
    end)

    stale_frontier_ids = Map.put(report, "frontier_ids", ["balanced"])

    assert {:error, stale_frontier_ids_report} =
             Schema.validate_artifact(stale_frontier_ids,
               schema_contract: "pareto_frontier_report.v1"
             )

    assert Enum.any?(
             stale_frontier_ids_report["errors"],
             &(&1["path"] == "$.frontier_ids")
           )

    stale_dominated_ids = Map.put(report, "dominated_ids", [])

    assert {:error, stale_dominated_ids_report} =
             Schema.validate_artifact(stale_dominated_ids,
               schema_contract: "pareto_frontier_report.v1"
             )

    assert Enum.any?(
             stale_dominated_ids_report["errors"],
             &(&1["path"] == "$.dominated_ids")
           )

    stale_objective_keys = put_in(report, ["rows", Access.at(0), "objective_keys"], ["coverage"])

    assert {:error, stale_objective_keys_report} =
             Schema.validate_artifact(stale_objective_keys,
               schema_contract: "pareto_frontier_report.v1"
             )

    assert Enum.any?(
             stale_objective_keys_report["errors"],
             &(&1["path"] == "$.rows[0].objective_keys")
           )
  end

  test "verifies curated resource projection report reference fixtures" do
    fixture_id = "fixture.artifact.resource_projection_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.resource_projection_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = resource_projection_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               resource_projection_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      resource_projection_report_fixture_observations()
      |> Map.put("downlink_shortfall_row_count", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "downlink_shortfall_row_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "resource_projection_report.v1",
             report
           ) == Validation.artifact_observations("resource_projection_report.v1", report)

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "resource_projection_report.v1"
             )

    stale_scalar_fields = [
      {"input_resource_summary_count", 0},
      {"valid_resource_summary_count", 0},
      {"activity_count", 2},
      {"valid_activity_count", 0},
      {"invalid_activity_input_count", 1}
    ]

    Enum.each(stale_scalar_fields, fn {field, stale_value} ->
      stale_report = Map.put(report, field, stale_value)

      assert {:error, stale_validation_report} =
               Schema.validate_artifact(stale_report,
                 schema_contract: "resource_projection_report.v1"
               )

      assert Enum.any?(stale_validation_report["errors"], &(&1["path"] == "$.#{field}"))
    end)

    stale_warnings = Map.put(report, "warnings", ["stale_resource_projection_warning"])

    assert {:error, stale_warnings_report} =
             Schema.validate_artifact(stale_warnings,
               schema_contract: "resource_projection_report.v1"
             )

    assert Enum.any?(stale_warnings_report["errors"], &(&1["path"] == "$.warnings"))

    stale_source_quality_counts =
      put_in(report, ["resource_source_quality_counts", "operator_supplied"], 0)

    assert {:error, stale_source_quality_counts_report} =
             Schema.validate_artifact(stale_source_quality_counts,
               schema_contract: "resource_projection_report.v1"
             )

    assert Enum.any?(
             stale_source_quality_counts_report["errors"],
             &(&1["path"] == "$.resource_source_quality_counts")
           )

    stale_trust_boundary_counts =
      put_in(report, ["resource_trust_boundary_status_counts", "missing"], 0)

    assert {:error, stale_trust_boundary_counts_report} =
             Schema.validate_artifact(stale_trust_boundary_counts,
               schema_contract: "resource_projection_report.v1"
             )

    assert Enum.any?(
             stale_trust_boundary_counts_report["errors"],
             &(&1["path"] == "$.resource_trust_boundary_status_counts")
           )

    stale_limits = Map.put(report, "model_limits", ["stale_resource_projection_boundary"])

    assert {:error, stale_limits_report} =
             Schema.validate_artifact(stale_limits,
               schema_contract: "resource_projection_report.v1"
             )

    assert Enum.any?(stale_limits_report["errors"], &(&1["path"] == "$.model_limits"))
  end

  test "verifies curated resource projection flow summary reference fixtures" do
    fixture_id = "fixture.artifact.resource_projection_flow_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.resource_projection_flow_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    summary = resource_projection_flow_summary_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               resource_projection_flow_summary_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      resource_projection_flow_summary_fixture_observations()
      |> Map.put("total_battery_energy_consumed_wh", 0.0)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "total_battery_energy_consumed_wh" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "resource_projection_flow_summary.v1",
             summary
           ) == Validation.artifact_observations("resource_projection_flow_summary.v1", summary)

    assert {:ok, %{"schema_contract" => "resource_projection_flow_summary.v1"}} =
             Schema.validate_artifact(summary,
               schema_contract: "resource_projection_flow_summary.v1"
             )
  end

  test "verifies resource projection battery handoff reference fixtures" do
    fixtures = [
      {
        "fixture.artifact.resource_projection_report.battery_handoff_v1",
        "resource_projection_report.v1",
        resource_projection_battery_handoff_fixture(),
        resource_projection_battery_handoff_fixture_observations()
      },
      {
        "fixture.artifact.operator_review_package.resource_projection_battery_handoff_v1",
        "operator_review_package.v1",
        operator_review_resource_projection_battery_handoff_fixture(),
        operator_review_resource_projection_battery_handoff_fixture_observations()
      },
      {
        "fixture.artifact.cadence_import_manifest.resource_projection_battery_handoff_v1",
        "cadence_import_manifest.v1",
        cadence_import_resource_projection_battery_handoff_fixture(),
        cadence_import_resource_projection_battery_handoff_fixture_observations()
      }
    ]

    Enum.each(fixtures, fn {fixture_id, contract, artifact, observations} ->
      assert {:ok, fixture} = Validation.reference_fixture(fixture_id)
      assert fixture["fixture_type"] == "curated_internal_artifact_regression"

      assert {:ok, %{"schema_contract" => ^contract}} =
               OrbitalDynamics.Schema.validate_artifact(artifact)

      assert {:ok, verification} =
               Validation.verify_reference_fixture(fixture_id, observations)

      assert verification["status"] == "pass"
      assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))
    end)

    stale_observations =
      operator_review_resource_projection_battery_handoff_fixture_observations()
      |> Map.put("net_resource_projection_battery_energy_delta_wh", 16.0)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.operator_review_package.resource_projection_battery_handoff_v1",
               stale_observations
             )

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "net_resource_projection_battery_energy_delta_wh" and
                 &1["status"] == "fail")
           )
  end

  test "verifies stale derived-margin resource summary reference fixtures" do
    fixtures = [
      {
        "fixture.artifact.resource_projection_report.stale_resource_summary_margins",
        "resource_projection_report.v1",
        resource_projection_stale_margin_fixture(),
        resource_projection_stale_margin_fixture_observations()
      },
      {
        "fixture.artifact.resource_filter_report.stale_resource_summary_margins",
        "resource_filter_report.v1",
        resource_filter_stale_margin_fixture(),
        resource_filter_stale_margin_fixture_observations()
      }
    ]

    Enum.each(fixtures, fn {fixture_id, contract, artifact, observations} ->
      assert {:ok, fixture} = Validation.reference_fixture(fixture_id)
      assert fixture["fixture_type"] == "curated_internal_artifact_regression"

      assert {:ok, %{"schema_contract" => ^contract}} =
               Schema.validate_artifact(artifact)

      assert {:ok, verification} =
               Validation.verify_reference_fixture(fixture_id, observations)

      assert verification["status"] == "pass"
      assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

      assert observations["invalid_resource_summary_input_reasons"] ==
               "stale_battery_state_of_charge|stale_storage_margin"
    end)

    stale_observations =
      resource_projection_stale_margin_fixture_observations()
      |> Map.put("stale_storage_margin_count", 0)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.resource_projection_report.stale_resource_summary_margins",
               stale_observations
             )

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "stale_storage_margin_count" and &1["status"] == "fail")
           )

    stale_projection_count =
      resource_projection_stale_margin_fixture()
      |> Map.put("invalid_resource_summary_input_count", 1)

    assert {:error, stale_projection_count_report} =
             Schema.validate_artifact(stale_projection_count,
               schema_contract: "resource_projection_report.v1"
             )

    assert Enum.any?(
             stale_projection_count_report["errors"],
             &(&1["path"] == "$.invalid_resource_summary_input_count")
           )

    stale_projection_ids =
      resource_projection_stale_margin_fixture()
      |> Map.put("invalid_resource_summary_input_ids", ["leo_2"])

    assert {:error, stale_projection_ids_report} =
             Schema.validate_artifact(stale_projection_ids,
               schema_contract: "resource_projection_report.v1"
             )

    assert Enum.any?(
             stale_projection_ids_report["errors"],
             &(&1["path"] == "$.invalid_resource_summary_input_ids")
           )

    stale_filter_count =
      resource_filter_stale_margin_fixture()
      |> Map.put("invalid_resource_summary_input_count", 1)

    assert {:error, stale_filter_count_report} =
             Schema.validate_artifact(stale_filter_count,
               schema_contract: "resource_filter_report.v1"
             )

    assert Enum.any?(
             stale_filter_count_report["errors"],
             &(&1["path"] == "$.invalid_resource_summary_input_count")
           )
  end

  test "verifies curated resource summary reference fixtures" do
    fixture_id = "fixture.artifact.resource_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.resource_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = resource_summary_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               resource_summary_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      resource_summary_fixture_observations()
      |> Map.put("spacecraft_available", true)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "spacecraft_available" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations("resource_summary.v1", report) ==
             Validation.artifact_observations("resource_summary.v1", report)

    assert {:ok, _validated_report} =
             Schema.validate_artifact(report, schema_contract: "resource_summary.v1")

    stale_battery_margin = Map.put(report, "battery_state_of_charge", 0.9)

    assert {:error, stale_battery_margin_report} =
             Schema.validate_artifact(stale_battery_margin,
               schema_contract: "resource_summary.v1"
             )

    assert Enum.any?(
             stale_battery_margin_report["errors"],
             &(&1["path"] == "$.battery_state_of_charge")
           )
  end

  test "verifies curated resource filter report reference fixtures" do
    fixture_id = "fixture.artifact.resource_filter_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.resource_filter_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = resource_filter_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               resource_filter_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      resource_filter_report_fixture_observations()
      |> Map.put("suppressed_candidate_count", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "suppressed_candidate_count" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "resource_filter_report.v1")

    stale_kept_candidate_count = Map.put(report, "kept_candidate_count", 0)

    assert {:error, stale_kept_candidate_count_report} =
             Schema.validate_artifact(stale_kept_candidate_count,
               schema_contract: "resource_filter_report.v1"
             )

    assert Enum.any?(
             stale_kept_candidate_count_report["errors"],
             &(&1["path"] == "$.kept_candidate_count")
           )

    stale_model_limits = Map.put(report, "model_limits", ["artifact_level_only"])

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "resource_filter_report.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )

    stale_suppressed_trust_counts =
      Map.put(report, "suppressed_resource_trust_boundary_status_counts", %{"missing" => 0})

    assert {:error, stale_suppressed_trust_counts_report} =
             Schema.validate_artifact(stale_suppressed_trust_counts,
               schema_contract: "resource_filter_report.v1"
             )

    assert Enum.any?(
             stale_suppressed_trust_counts_report["errors"],
             &(&1["path"] == "$.suppressed_resource_trust_boundary_status_counts")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "resource_filter_report.v1",
             report
           ) == Validation.artifact_observations("resource_filter_report.v1", report)
  end

  test "verifies curated resource filter summary reference fixtures" do
    fixture_id = "fixture.artifact.resource_filter_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.resource_filter_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = resource_filter_summary_fixture()
    observations = resource_filter_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "input_candidate_count" => 3,
             "kept_candidate_count" => 1,
             "suppressed_candidate_count" => 2,
             "suppression_review_status" => "review_required",
             "suppressed_candidate_ids" =>
               "leo_1_downlink_equator_prime_1|leo_1_observe_target_a_1",
             "suppressed_reason_counts" => %{
               "downlink_margin_below_policy" => 1,
               "storage_margin_below_observe_policy" => 1
             },
             "resource_blocking_dimension_counts" => %{"downlink" => 1, "storage" => 1},
             "suppressed_resource_source_quality_counts" => %{"operator_supplied" => 2},
             "suppressed_resource_trust_boundary_status_counts" => %{"missing" => 2},
             "review_row_count" => 2,
             "review_row_ids" => "leo_1_observe_target_a_1|leo_1_downlink_equator_prime_1",
             "execution_boundary" => "artifact_only_no_schedule_mutation",
             "assumption_source" => "resource_filter_report.v1",
             "operator_authority" => "not_granted_by_resource_filter_summary",
             "resource_state_propagation" => "not_performed",
             "no_schedule_mutation" => true,
             "no_resource_time_propagation" => true,
             "no_subsystem_simulation" => true
           } = observations

    assert OrbitalDynamics.validation_artifact_observations(
             "resource_filter_summary.v1",
             report
           ) == Validation.artifact_observations("resource_filter_summary.v1", report)

    stale_count_observations = Map.put(observations, "suppressed_candidate_count", 1)

    assert {:ok, stale_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_count_observations)

    assert stale_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_count_verification["checks"],
             &(&1["field"] == "suppressed_candidate_count" and &1["status"] == "fail")
           )

    stale_routing_observations =
      put_in(
        observations,
        ["suppressed_candidate_ids_by_resource_blocking_dimension", "downlink"],
        []
      )

    assert {:ok, stale_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_routing_observations)

    assert stale_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_routing_verification["checks"],
             &(&1["field"] == "suppressed_candidate_ids_by_resource_blocking_dimension" and
                 &1["status"] == "fail")
           )

    stale_boundary_observations =
      Map.put(observations, "execution_boundary", "resource_state_propagated")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "execution_boundary" and &1["status"] == "fail")
           )

    assert {:ok, %{"schema_contract" => "resource_filter_summary.v1"}} =
             Schema.validate_artifact(report, schema_contract: "resource_filter_summary.v1")
  end

  test "verifies curated objective satisfaction report reference fixtures" do
    fixture_id = "fixture.artifact.objective_satisfaction_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.objective_satisfaction_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = objective_satisfaction_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               objective_satisfaction_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    observations = objective_satisfaction_report_fixture_observations()

    assert observations["status_counts"] == %{
             "no_candidate_window" => 1,
             "partial" => 1,
             "selected" => 1,
             "unmet" => 1
           }

    assert observations["objective_ids_by_status"] == %{
             "no_candidate_window" => ["objective:target_commitment:target_b"],
             "partial" => ["objective:target_coverage"],
             "selected" => ["objective:target_commitment:target_a"],
             "unmet" => ["objective:downlink_completion"]
           }

    stale_observations =
      observations
      |> Map.put("satisfied_count_total", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "satisfied_count_total" and &1["status"] == "fail")
           )

    stale_status_count_observations =
      observations
      |> put_in(["status_counts", "partial"], 0)

    assert {:ok, stale_status_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_status_count_observations)

    assert stale_status_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_status_count_verification["checks"],
             &(&1["field"] == "status_counts" and &1["status"] == "fail")
           )

    stale_status_routing_observations =
      observations
      |> put_in(["objective_ids_by_status", "partial"], [])

    assert {:ok, stale_status_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_status_routing_observations)

    assert stale_status_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_status_routing_verification["checks"],
             &(&1["field"] == "objective_ids_by_status" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "objective_satisfaction_report.v1",
             report
           ) == Validation.artifact_observations("objective_satisfaction_report.v1", report)

    assert {:ok, %{"schema_contract" => "objective_satisfaction_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "objective_satisfaction_report.v1"
             )

    stale_model = Map.put(report, "model", "stale_objective_satisfaction_model")

    assert {:error, stale_model_report} =
             Schema.validate_artifact(stale_model,
               schema_contract: "objective_satisfaction_report.v1"
             )

    assert Enum.any?(
             stale_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"campaign_v1_selected_activity_objective_summary\"")
           )

    stale_objective_count = Map.put(report, "objective_count", 3)

    assert {:error, stale_objective_count_report} =
             Schema.validate_artifact(stale_objective_count,
               schema_contract: "objective_satisfaction_report.v1"
             )

    assert Enum.any?(
             stale_objective_count_report["errors"],
             &(&1["path"] == "$.objective_count")
           )

    stale_candidate_count = put_in(report, ["rows", Access.at(0), "candidate_count"], 2)

    assert {:error, stale_candidate_count_report} =
             Schema.validate_artifact(stale_candidate_count,
               schema_contract: "objective_satisfaction_report.v1"
             )

    assert Enum.any?(
             stale_candidate_count_report["errors"],
             &(&1["path"] == "$.rows[0].candidate_count")
           )

    stale_selected_count = put_in(report, ["rows", Access.at(0), "selected_count"], 2)

    assert {:error, stale_selected_count_report} =
             Schema.validate_artifact(stale_selected_count,
               schema_contract: "objective_satisfaction_report.v1"
             )

    assert Enum.any?(
             stale_selected_count_report["errors"],
             &(&1["path"] == "$.rows[0].selected_count")
           )
  end

  test "verifies curated objective tradeoff report reference fixtures" do
    fixture_id = "fixture.artifact.objective_tradeoff_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.objective_tradeoff_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = objective_tradeoff_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               objective_tradeoff_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      objective_tradeoff_report_fixture_observations()
      |> Map.put("score_term_key_count", 6)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "score_term_key_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "objective_tradeoff_report.v1",
             report
           ) == Validation.artifact_observations("objective_tradeoff_report.v1", report)

    assert {:ok, %{"schema_contract" => "objective_tradeoff_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "objective_tradeoff_report.v1"
             )

    stale_model = Map.put(report, "model", "stale_objective_tradeoff_model")

    assert {:error, stale_model_report} =
             Schema.validate_artifact(stale_model,
               schema_contract: "objective_tradeoff_report.v1"
             )

    assert Enum.any?(
             stale_model_report["errors"],
             &(&1["path"] == "$.model" and String.starts_with?(&1["message"], "must be one of"))
           )

    stale_ranking_count = Map.put(report, "ranking_count", 0)

    assert {:error, stale_ranking_count_report} =
             Schema.validate_artifact(stale_ranking_count,
               schema_contract: "objective_tradeoff_report.v1"
             )

    assert Enum.any?(
             stale_ranking_count_report["errors"],
             &(&1["path"] == "$.ranking_count")
           )

    stale_score_term_keys = Map.put(report, "score_term_keys", ["activity_score"])

    assert {:error, stale_score_term_keys_report} =
             Schema.validate_artifact(stale_score_term_keys,
               schema_contract: "objective_tradeoff_report.v1"
             )

    assert Enum.any?(
             stale_score_term_keys_report["errors"],
             &(&1["path"] == "$.score_term_keys")
           )

    stale_activity_count = put_in(report, ["tradeoffs", Access.at(0), "activity_count"], 0)

    assert {:error, stale_activity_count_report} =
             Schema.validate_artifact(stale_activity_count,
               schema_contract: "objective_tradeoff_report.v1"
             )

    assert Enum.any?(
             stale_activity_count_report["errors"],
             &(&1["path"] == "$.tradeoffs[0].activity_count")
           )
  end

  test "verifies curated score term report reference fixtures" do
    fixture_id = "fixture.artifact.score_term_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.score_term_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = score_term_report_fixture()

    assert campaign_plan_score_term_report_fixture() == report

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               score_term_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    observations = score_term_report_fixture_observations()

    assert observations["row_derived_score_term_key_counts"] ==
             observations["score_term_key_counts"]

    stale_observations =
      observations
      |> Map.put("selected_row_count", 6)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "selected_row_count" and &1["status"] == "fail")
           )

    stale_row_derived_key_observations =
      observations
      |> put_in(["row_derived_score_term_key_counts", "activity_score"], 2)

    assert {:ok, stale_row_derived_key_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_key_observations)

    assert stale_row_derived_key_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_key_verification["checks"],
             &(&1["field"] == "row_derived_score_term_key_counts" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "score_term_report.v1",
             report
           ) == Validation.artifact_observations("score_term_report.v1", report)

    assert {:ok, %{"schema_contract" => "score_term_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "score_term_report.v1"
             )

    stale_row_count = Map.put(report, "row_count", 6)

    assert {:error, stale_row_count_report} =
             Schema.validate_artifact(stale_row_count,
               schema_contract: "score_term_report.v1"
             )

    assert Enum.any?(stale_row_count_report["errors"], &(&1["path"] == "$.row_count"))

    stale_score_term_keys =
      Map.put(report, "score_term_keys", ["activity_count_penalty"])

    assert {:error, stale_score_term_keys_report} =
             Schema.validate_artifact(stale_score_term_keys,
               schema_contract: "score_term_report.v1"
             )

    assert Enum.any?(
             stale_score_term_keys_report["errors"],
             &(&1["path"] == "$.score_term_keys")
           )
  end

  test "verifies curated ranking comparison report reference fixtures" do
    fixture_id = "fixture.artifact.ranking_comparison_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.ranking_comparison_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = ranking_comparison_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               ranking_comparison_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    observations = ranking_comparison_report_fixture_observations()

    assert observations["status_counts"] == %{
             "left_only" => 1,
             "matched" => 1,
             "right_only" => 1
           }

    assert observations["scenario_ids_by_status"] == %{
             "left_only" => ["burn_a"],
             "matched" => ["burn_b"],
             "right_only" => ["burn_c"]
           }

    stale_observations =
      observations
      |> Map.put("matched_count", 0)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "matched_count" and &1["status"] == "fail")
           )

    stale_status_count_observations =
      observations
      |> put_in(["status_counts", "matched"], 0)

    assert {:ok, stale_status_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_status_count_observations)

    assert stale_status_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_status_count_verification["checks"],
             &(&1["field"] == "status_counts" and &1["status"] == "fail")
           )

    stale_status_routing_observations =
      observations
      |> put_in(["scenario_ids_by_status", "matched"], [])

    assert {:ok, stale_status_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_status_routing_observations)

    assert stale_status_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_status_routing_verification["checks"],
             &(&1["field"] == "scenario_ids_by_status" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "ranking_comparison_report.v1",
             report
           ) == Validation.artifact_observations("ranking_comparison_report.v1", report)

    assert {:ok, %{"schema_contract" => "ranking_comparison_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "ranking_comparison_report.v1"
             )

    stale_model = Map.put(report, "model", "stale_ranking_comparison_model")

    assert {:error, stale_model_report} =
             Schema.validate_artifact(stale_model,
               schema_contract: "ranking_comparison_report.v1"
             )

    assert Enum.any?(
             stale_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] == "must equal \"scenario_ranking_pairwise_delta\"")
           )

    stale_count_fields = [
      {"row_count", 2},
      {"matched_count", 0},
      {"left_only_count", 0},
      {"right_only_count", 0},
      {"left_count", 1},
      {"right_count", 1}
    ]

    Enum.each(stale_count_fields, fn {field, stale_value} ->
      stale_report = Map.put(report, field, stale_value)

      assert {:error, stale_validation_report} =
               Schema.validate_artifact(stale_report,
                 schema_contract: "ranking_comparison_report.v1"
               )

      assert Enum.any?(stale_validation_report["errors"], &(&1["path"] == "$.#{field}"))
    end)

    stale_rank_delta = put_in(report, ["rows", Access.at(0), "rank_delta"], 0)

    assert {:error, stale_rank_delta_report} =
             Schema.validate_artifact(stale_rank_delta,
               schema_contract: "ranking_comparison_report.v1"
             )

    assert Enum.any?(
             stale_rank_delta_report["errors"],
             &(&1["path"] == "$.rows[0].rank_delta")
           )

    stale_value_delta = put_in(report, ["rows", Access.at(0), "value_delta"], 0)

    assert {:error, stale_value_delta_report} =
             Schema.validate_artifact(stale_value_delta,
               schema_contract: "ranking_comparison_report.v1"
             )

    assert Enum.any?(
             stale_value_delta_report["errors"],
             &(&1["path"] == "$.rows[0].value_delta")
           )
  end

  test "verifies curated schema validation report reference fixtures" do
    fixture_id = "fixture.artifact.schema_validation_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.schema_validation_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = schema_validation_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               schema_validation_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert OrbitalDynamics.validation_artifact_observations("schema_validation_report.v1", report) ==
             Validation.artifact_observations("schema_validation_report.v1", report)

    assert {:ok, _validated_report} =
             Schema.validate_artifact(report,
               schema_contract: "schema_validation_report.v1"
             )

    stale_error_count = Map.put(report, "error_count", 1)

    assert {:error, stale_error_count_report} =
             Schema.validate_artifact(stale_error_count,
               schema_contract: "schema_validation_report.v1"
             )

    assert Enum.any?(
             stale_error_count_report["errors"],
             &(&1["path"] == "$.error_count")
           )

    stale_status = Map.put(report, "status", "fail")

    assert {:error, stale_status_report} =
             Schema.validate_artifact(stale_status,
               schema_contract: "schema_validation_report.v1"
             )

    assert Enum.any?(
             stale_status_report["errors"],
             &(&1["path"] == "$.status")
           )
  end

  test "verifies curated schema validation batch report reference fixtures" do
    fixture_id = "fixture.artifact.schema_validation_batch_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.schema_validation_batch_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = schema_validation_batch_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               schema_validation_batch_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert OrbitalDynamics.validation_artifact_observations(
             "schema_validation_batch_report.v1",
             report
           ) == Validation.artifact_observations("schema_validation_batch_report.v1", report)

    assert {:ok, %{"schema_contract" => "schema_validation_batch_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "schema_validation_batch_report.v1"
             )

    Enum.each(
      [
        {"file_count", 0},
        {"artifact_count", 0},
        {"skipped_count", 1},
        {"error_count", 1},
        {"warning_count", 1},
        {"remediation_count", 1}
      ],
      fn {field, stale_value} ->
        stale_report = Map.put(report, field, stale_value)

        assert {:error, validation_report} =
                 Schema.validate_artifact(stale_report,
                   schema_contract: "schema_validation_batch_report.v1"
                 )

        assert Enum.any?(validation_report["errors"], &(&1["path"] == "$.#{field}"))
      end
    )

    stale_status_counts = put_in(report, ["status_counts", "pass"], 0)

    assert {:error, stale_status_counts_report} =
             Schema.validate_artifact(stale_status_counts,
               schema_contract: "schema_validation_batch_report.v1"
             )

    assert Enum.any?(
             stale_status_counts_report["errors"],
             &(&1["path"] == "$.status_counts")
           )

    nested_failure =
      update_in(report, ["reports", Access.at(0), "report"], fn nested_report ->
        nested_report
        |> Map.put("status", "fail")
        |> Map.put("error_count", 1)
        |> Map.put("errors", [
          %{"severity" => "error", "path" => "$.status", "message" => "forced stale fixture"}
        ])
      end)

    assert {:error, stale_status_report} =
             Schema.validate_artifact(nested_failure,
               schema_contract: "schema_validation_batch_report.v1"
             )

    assert Enum.any?(stale_status_report["errors"], &(&1["path"] == "$.status"))

    stale_limits = Map.put(report, "model_limits", ["stale_schema_validation_boundary"])

    assert {:error, stale_limits_report} =
             Schema.validate_artifact(stale_limits,
               schema_contract: "schema_validation_batch_report.v1"
             )

    assert Enum.any?(stale_limits_report["errors"], &(&1["path"] == "$.model_limits"))
  end

  test "verifies curated schema migration report reference fixtures" do
    fixture_id = "fixture.artifact.schema_migration_report.deprecated_campaign_plan"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.schema_migration_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = schema_migration_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               schema_migration_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "status" => "review_required",
             "deprecated_contract_count" => 1,
             "deprecated_contracts" => "campaign_plan.v1",
             "replacement_contracts" => "campaign_strategy.v3",
             "status_counts" => %{"current" => 120, "deprecated" => 1},
             "row_derived_status_counts" => %{"current" => 120, "deprecated" => 1}
           } = schema_migration_report_fixture_observations()

    stale_status_counts =
      schema_migration_report_fixture_observations()
      |> Map.put("row_derived_status_counts", %{"current" => 120})

    assert {:ok, stale_status_counts_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_status_counts)

    assert stale_status_counts_verification["status"] == "fail"

    assert Enum.any?(
             stale_status_counts_verification["checks"],
             &(&1["field"] == "row_derived_status_counts" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations("schema_migration_report.v1", report) ==
             Validation.artifact_observations("schema_migration_report.v1", report)

    assert {:ok, %{"schema_contract" => "schema_migration_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "schema_migration_report.v1"
             )

    stale_model_limits = Map.put(report, "model_limits", ["artifact_only"])

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "schema_migration_report.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match schema migration report model limits")
           )

    stale_contract_count = Map.put(report, "contract_count", 116)

    assert {:error, stale_contract_count_report} =
             Schema.validate_artifact(stale_contract_count,
               schema_contract: "schema_migration_report.v1"
             )

    assert Enum.any?(
             stale_contract_count_report["errors"],
             &(&1["path"] == "$.contract_count")
           )

    stale_status = Map.put(report, "status", "current")

    assert {:error, stale_status_report} =
             Schema.validate_artifact(stale_status,
               schema_contract: "schema_migration_report.v1"
             )

    assert Enum.any?(stale_status_report["errors"], &(&1["path"] == "$.status"))
  end

  test "verifies schema migration future-contract challenge fixtures" do
    fixture_id = "fixture.artifact.schema_migration_report.future_campaign_plan"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.schema_migration_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = schema_migration_future_contract_fixture()
    observations = schema_migration_future_contract_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "status" => "review_required",
             "future_contract_count" => 1,
             "deprecated_contract_count" => 0,
             "status_counts" => %{"current" => 121, "future" => 1},
             "row_derived_status_counts" => %{"current" => 121, "future" => 1},
             "migration_action_counts" => %{
               "continue_current_contract" => 121,
               "prepare_future_contract" => 1
             },
             "row_derived_migration_action_counts" => %{
               "continue_current_contract" => 121,
               "prepare_future_contract" => 1
             }
           } = observations

    schema_migration_actions = Validation.capabilities().schema_migration_actions

    assert Map.keys(observations["migration_action_counts"]) -- schema_migration_actions == []

    assert Map.keys(observations["row_derived_migration_action_counts"]) --
             schema_migration_actions == []

    stale_action_counts =
      observations
      |> Map.put("row_derived_migration_action_counts", %{
        "continue_current_contract" => 121
      })

    assert {:ok, stale_action_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_action_counts)

    assert stale_action_verification["status"] == "fail"

    assert Enum.any?(
             stale_action_verification["checks"],
             &(&1["field"] == "row_derived_migration_action_counts" and &1["status"] == "fail")
           )

    assert {:ok, %{"schema_contract" => "schema_migration_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "schema_migration_report.v1"
             )

    stale_future_count = Map.put(report, "future_contract_count", 0)

    assert {:error, stale_future_count_report} =
             Schema.validate_artifact(stale_future_count,
               schema_contract: "schema_migration_report.v1"
             )

    assert Enum.any?(
             stale_future_count_report["errors"],
             &(&1["path"] == "$.future_contract_count")
           )
  end

  test "fails reference fixture verification outside declared tolerances" do
    observations =
      two_body_fixture_observations()
      |> Map.update!("final_position_km", fn [x, y, z] -> [x + 0.01, y, z] end)

    assert {:ok, %{"status" => "fail", "checks" => checks}} =
             Validation.verify_reference_fixture(
               "fixture.two_body.circular_leo_600s",
               observations
             )

    assert %{"status" => "fail", "max_abs_error" => error, "tolerance" => tolerance} =
             Enum.find(checks, &(&1["field"] == "final_position_km"))

    assert error > tolerance
  end

  test "builds deterministic reference fixture reports" do
    report =
      Validation.reference_fixture_report(%{
        "fixture.event.access.equator_overhead_120s" => access_fixture_observations(),
        "fixture.event.eclipse.cylindrical_shadow_120s" => eclipse_fixture_observations(),
        "fixture.event.target_visibility.equator_overhead_120s" =>
          target_visibility_fixture_observations(),
        "fixture.event.ground_track.latitude_equator_60s" =>
          ground_track_crossing_fixture_observations(),
        "fixture.artifact.accepted_planning_state.oem" =>
          accepted_planning_state_oem_fixture_observations(),
        "fixture.artifact.accepted_planning_state.opm" =>
          accepted_planning_state_opm_fixture_observations(),
        "fixture.artifact.accepted_planning_state.simple" =>
          accepted_planning_state_fixture_observations(),
        "fixture.artifact.activity_template.v1" => activity_template_fixture_observations(),
        "fixture.artifact.approval_requirement.v1" => approval_requirement_fixture_observations(),
        "fixture.artifact.backend_acceptance_policy.v1" =>
          backend_acceptance_policy_fixture_observations(),
        "fixture.artifact.branch_comparison_report.v1" =>
          branch_comparison_report_fixture_observations(),
        "fixture.artifact.cadence_import_manifest.v1" =>
          cadence_import_manifest_fixture_observations(),
        "fixture.artifact.cadence_import_manifest.resource_pressure_v1" =>
          cadence_import_resource_pressure_fixture_observations(),
        "fixture.artifact.cadence_import_manifest.resource_projection_battery_handoff_v1" =>
          cadence_import_resource_projection_battery_handoff_fixture_observations(),
        "fixture.artifact.campaign_plan.leo_constellation_v1" =>
          campaign_plan_fixture_observations(),
        "fixture.artifact.campaign_repair.leo_constellation_v2" =>
          campaign_repair_fixture_observations(),
        "fixture.artifact.campaign_request_lint.v1" =>
          campaign_request_lint_fixture_observations(),
        "fixture.artifact.campaign_strategy.leo_constellation_v3" =>
          campaign_strategy_fixture_observations(),
        "fixture.artifact.capability_catalog.v1" => capability_catalog_fixture_observations(),
        "fixture.artifact.candidate_activity.v1" => candidate_activity_fixture_observations(),
        "fixture.artifact.candidate_diff_report.v1" =>
          candidate_diff_report_fixture_observations(),
        "fixture.artifact.candidate_diff_row.v1" => candidate_diff_row_fixture_observations(),
        "fixture.artifact.candidate_refresh.v1" => candidate_refresh_fixture_observations(),
        "fixture.artifact.candidate_refresh.candidate_rejection_replay" =>
          candidate_refresh_candidate_rejection_fixture_observations(),
        "fixture.artifact.candidate_refresh.contact_contention_cross_station_replay" =>
          candidate_refresh_contact_contention_challenge_fixture_observations(),
        "fixture.artifact.candidate_refresh.contact_allocation_contradiction_replay" =>
          candidate_refresh_contact_allocation_contradiction_fixture_observations(),
        "fixture.artifact.candidate_refresh.contact_filter_replay" =>
          candidate_refresh_contact_filter_fixture_observations(),
        "fixture.artifact.candidate_refresh.contact_intent_direction_replay" =>
          candidate_refresh_contact_intent_direction_fixture_observations(),
        "fixture.artifact.candidate_refresh.constraint_replay" =>
          candidate_refresh_constraint_fixture_observations(),
        "fixture.artifact.candidate_refresh.freshness_replay" =>
          candidate_refresh_freshness_fixture_observations(),
        "fixture.artifact.candidate_refresh.link_capacity_replay" =>
          candidate_refresh_link_capacity_fixture_observations(),
        "fixture.artifact.candidate_refresh.operational_readiness_replay" =>
          candidate_refresh_operational_readiness_fixture_observations(),
        "fixture.artifact.candidate_refresh.timeline_activity_precondition_replay" =>
          candidate_refresh_timeline_activity_precondition_fixture_observations(),
        "fixture.artifact.candidate_refresh.timeline_activity_lifecycle_replay" =>
          candidate_refresh_timeline_activity_lifecycle_fixture_observations(),
        "fixture.artifact.candidate_refresh.timeline_lifecycle_state_replay" =>
          candidate_refresh_timeline_lifecycle_state_fixture_observations(),
        "fixture.artifact.candidate_refresh.resource_projection_replay" =>
          candidate_refresh_resource_projection_fixture_observations(),
        "fixture.artifact.candidate_refresh.timeline_transition_application_replay" =>
          candidate_refresh_timeline_transition_application_fixture_observations(),
        "fixture.artifact.candidate_refresh.objective_gap_replay" =>
          candidate_refresh_objective_gap_fixture_observations(),
        "fixture.artifact.candidate_refresh.quality_gate_replay" =>
          candidate_refresh_quality_gate_fixture_observations(),
        "fixture.artifact.candidate_refresh.refresh_budget_replay" =>
          candidate_refresh_refresh_budget_fixture_observations(),
        "fixture.artifact.candidate_refresh.resource_filter_replay" =>
          candidate_refresh_resource_filter_fixture_observations(),
        "fixture.artifact.candidate_refresh.station_calendar_replay" =>
          candidate_refresh_station_calendar_fixture_observations(),
        "fixture.artifact.candidate_refresh.resource_provenance_v1" =>
          candidate_refresh_resource_provenance_fixture_observations(),
        "fixture.artifact.candidate_rejection_report.v1" =>
          candidate_rejection_report_fixture_observations(),
        "fixture.artifact.command_window_report.v1" =>
          command_window_report_fixture_observations(),
        "fixture.artifact.constraint_report.v1" => constraint_report_fixture_observations(),
        "fixture.artifact.contact_allocation_report.reduced_capacity_pack" =>
          contact_allocation_capacity_pack_report_fixture_observations(),
        "fixture.artifact.contact_allocation_capacity_pack_summary.v1" =>
          contact_allocation_capacity_pack_summary_fixture_observations(),
        "fixture.artifact.contact_allocation_summary.v1" =>
          contact_allocation_summary_fixture_observations(),
        "fixture.artifact.contact_allocation_report.v1" =>
          contact_allocation_report_fixture_observations(),
        "fixture.artifact.contact_allocation_reservation_conflict_summary.v1" =>
          contact_allocation_reservation_conflict_summary_fixture_observations(),
        "fixture.artifact.contact_allocation_station_pressure_summary.v1" =>
          contact_allocation_station_pressure_summary_fixture_observations(),
        "fixture.artifact.contact_allocation_provider_reservation_request_summary.v1" =>
          contact_allocation_provider_reservation_request_summary_fixture_observations(),
        "fixture.artifact.contact_contention_report.v1" =>
          contact_contention_report_fixture_observations(),
        "fixture.artifact.contact_contention_report.cross_station_spacecraft" =>
          contact_contention_cross_station_fixture_observations(),
        "fixture.artifact.contact_contention_resolution_report.v1" =>
          contact_contention_resolution_report_fixture_observations(),
        "fixture.artifact.contact_contention_resolution_summary.v1" =>
          contact_contention_resolution_summary_fixture_observations(),
        "fixture.artifact.contact_filter_report.v1" =>
          contact_filter_report_fixture_observations(),
        "fixture.artifact.contact_intent.v1" => contact_intent_fixture_observations(),
        "fixture.artifact.contact_intent_summary.v1" =>
          contact_intent_summary_fixture_observations(),
        "fixture.artifact.environment_model_capability.constant_earth_rotation" =>
          environment_model_capability_constant_earth_rotation_fixture_observations(),
        "fixture.artifact.environment_model_capability.fixed_sun" =>
          environment_model_capability_fixed_sun_fixture_observations(),
        "fixture.artifact.environment_provider_capability.constant_earth_rotation" =>
          environment_provider_capability_constant_earth_rotation_fixture_observations(),
        "fixture.artifact.environment_provider_capability.exponential_atmosphere" =>
          environment_provider_capability_exponential_atmosphere_fixture_observations(),
        "fixture.artifact.environment_provider_capability.fixed_sun" =>
          environment_provider_capability_fixed_sun_fixture_observations(),
        "fixture.artifact.environment_provider_capability.tabular_earth_orientation" =>
          environment_provider_capability_tabular_earth_orientation_fixture_observations(),
        "fixture.artifact.execution_report.v1" => execution_report_fixture_observations(),
        "fixture.artifact.freshness_report.v1" => freshness_report_fixture_observations(),
        "fixture.artifact.invalidated_candidate.v1" =>
          invalidated_candidate_fixture_observations(),
        "fixture.artifact.link_capacity_report.v1" => link_capacity_report_fixture_observations(),
        "fixture.artifact.link_capacity_summary.v1" =>
          link_capacity_summary_fixture_observations(),
        "fixture.artifact.relay_data_path_summary.v1" =>
          relay_data_path_summary_fixture_observations(),
        "fixture.artifact.maneuver_execution_delta.v1" =>
          maneuver_execution_delta_fixture_observations(),
        "fixture.artifact.maneuver_review_report.v1" =>
          maneuver_review_report_fixture_observations(),
        "fixture.artifact.maneuver_recommendation.v1" =>
          maneuver_recommendation_fixture_observations(),
        "fixture.artifact.manifest_field_reference.v1" =>
          manifest_field_reference_fixture_observations(),
        "fixture.artifact.model_acceptance_report.operational_import" =>
          model_acceptance_report_fixture_observations(),
        "fixture.artifact.monte_carlo_reproducibility_report.v1" =>
          monte_carlo_reproducibility_report_fixture_observations(),
        "fixture.artifact.objective_satisfaction_report.v1" =>
          objective_satisfaction_report_fixture_observations(),
        "fixture.artifact.objective_tradeoff_report.v1" =>
          objective_tradeoff_report_fixture_observations(),
        "fixture.artifact.ranking_comparison_report.v1" =>
          ranking_comparison_report_fixture_observations(),
        "fixture.artifact.realized_activity.v1" => realized_activity_fixture_observations(),
        "fixture.artifact.realized_state_snapshot.v1" =>
          realized_state_snapshot_fixture_observations(),
        "fixture.artifact.refresh_budget_report.v1" =>
          refresh_budget_report_fixture_observations(),
        "fixture.artifact.refreshed_window.v1" => refreshed_window_fixture_observations(),
        "fixture.artifact.remaining_horizon.v1" => remaining_horizon_fixture_observations(),
        "fixture.artifact.pareto_frontier_report.v1" =>
          pareto_frontier_report_fixture_observations(),
        "fixture.artifact.plan_delta.v1" => plan_delta_fixture_observations(),
        "fixture.artifact.planned_activity.v1" => planned_activity_fixture_observations(),
        "fixture.artifact.policy_bundle.command_contact_authority" =>
          command_contact_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.conservative_ops" =>
          conservative_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.contact_command_review" =>
          contact_command_review_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.default" => default_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.degraded_payload_guard" =>
          degraded_payload_guard_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.ground_network_allocation" =>
          ground_network_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.maneuver_authority" =>
          maneuver_authority_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.operator_review_queue_authority" =>
          operator_review_queue_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.organization_adapter" =>
          organization_adapter_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.resource_projection_authority" =>
          resource_projection_authority_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.timeline_protection" =>
          timeline_protection_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.v1" => policy_bundle_fixture_observations(),
        "fixture.artifact.policy_decision.v1" => policy_decision_fixture_observations(),
        "fixture.artifact.proposed_contact.v1" => proposed_contact_fixture_observations(),
        "fixture.artifact.validation_safety_case_summary.v1" =>
          validation_safety_case_summary_fixture_observations(),
        "fixture.artifact.operator_review_package.v1" =>
          operator_review_package_fixture_observations(),
        "fixture.artifact.operator_review_package.resource_pressure_v1" =>
          operator_review_resource_pressure_fixture_observations(),
        "fixture.artifact.operator_review_package.resource_projection_battery_handoff_v1" =>
          operator_review_resource_projection_battery_handoff_fixture_observations(),
        "fixture.artifact.operational_execution_boundary_summary.v1" =>
          operational_execution_boundary_summary_fixture_observations(),
        "fixture.artifact.operational_import_eligibility_summary.v1" =>
          operational_import_eligibility_summary_fixture_observations(),
        "fixture.artifact.operational_readiness_report.v1" =>
          operational_readiness_report_fixture_observations(),
        "fixture.artifact.operational_readiness_report.resource_pressure_v1" =>
          operational_readiness_resource_pressure_fixture_observations(),
        "fixture.artifact.operational_readiness_gate_summary.v1" =>
          operational_readiness_gate_summary_fixture_observations(),
        "fixture.artifact.operational_quality_gate_summary.v1" =>
          operational_quality_gate_summary_fixture_observations(),
        "fixture.artifact.operational_quality_gate_import_readiness_summary.v1" =>
          operational_quality_gate_import_readiness_summary_fixture_observations(),
        "fixture.artifact.operational_quality_gate_unavailable_resource_summary.v1" =>
          operational_quality_gate_unavailable_resource_summary_fixture_observations(),
        "fixture.artifact.operational_quality_gate_unavailable_resource_summary.resource_projection_v1" =>
          operational_quality_gate_unavailable_resource_summary_checked_in_observations(),
        "fixture.artifact.operational_quality_gate_operator_training_summary.v1" =>
          operational_quality_gate_operator_training_summary_fixture_observations(),
        "fixture.artifact.operational_quality_gate_schema_validation_summary.v1" =>
          operational_quality_gate_schema_validation_summary_fixture_observations(),
        "fixture.artifact.operational_timeline_report.v1" =>
          operational_timeline_report_fixture_observations(),
        "fixture.artifact.optimizer_contract.v1" => optimizer_contract_fixture_observations(),
        "fixture.artifact.provider_counteroffer_import_readiness_summary.v1" =>
          provider_counteroffer_import_readiness_summary_fixture_observations(),
        "fixture.artifact.provider_counteroffer_plan_impact_summary.v1" =>
          provider_counteroffer_plan_impact_summary_fixture_observations(),
        "fixture.artifact.provider_counteroffer_report.v1" =>
          provider_counteroffer_report_fixture_observations(),
        "fixture.artifact.provider_counteroffer_review_summary.v1" =>
          provider_counteroffer_review_summary_fixture_observations(),
        "fixture.artifact.quality_gate_report.v1" => quality_gate_report_fixture_observations(),
        "fixture.artifact.quality_gate_report.resource_pressure_v1" =>
          quality_gate_resource_pressure_fixture_observations(),
        "fixture.artifact.resource_filter_report.v1" =>
          resource_filter_report_fixture_observations(),
        "fixture.artifact.resource_filter_summary.v1" =>
          resource_filter_summary_fixture_observations(),
        "fixture.artifact.resource_filter_report.stale_resource_summary_margins" =>
          resource_filter_stale_margin_fixture_observations(),
        "fixture.artifact.resource_projection_report.v1" =>
          resource_projection_report_fixture_observations(),
        "fixture.artifact.resource_projection_flow_summary.v1" =>
          resource_projection_flow_summary_fixture_observations(),
        "fixture.artifact.resource_projection_report.battery_handoff_v1" =>
          resource_projection_battery_handoff_fixture_observations(),
        "fixture.artifact.resource_projection_report.stale_resource_summary_margins" =>
          resource_projection_stale_margin_fixture_observations(),
        "fixture.artifact.resource_summary.v1" => resource_summary_fixture_observations(),
        "fixture.artifact.result_artifact.candidate_refresh_v1" =>
          candidate_refresh_result_artifact_fixture_observations(),
        "fixture.artifact.result_artifact.candidate_refresh_orbit_data_v1" =>
          candidate_refresh_orbit_data_result_artifact_fixture_observations(),
        "fixture.artifact.result_artifact.ground_track_crossings" =>
          ground_track_result_artifact_fixture_observations(),
        "fixture.artifact.result_artifact.leo_access_demo" =>
          leo_access_result_artifact_fixture_observations(),
        "fixture.artifact.result_artifact.leo_access_demo_manifest" =>
          leo_access_manifest_result_artifact_fixture_observations(),
        "fixture.artifact.result_artifact.leo_constellation_campaign" =>
          result_artifact_fixture_observations(),
        "fixture.artifact.result_artifact.leo_dispersion_monte_carlo" =>
          monte_carlo_result_artifact_fixture_observations(),
        "fixture.artifact.result_artifact.mission_plan_checkout" =>
          mission_plan_checkout_result_artifact_fixture_observations(),
        "fixture.artifact.result_artifact.raise_apogee_search" =>
          raise_apogee_result_artifact_fixture_observations(),
        "fixture.artifact.score_term_report.v1" => score_term_report_fixture_observations(),
        "fixture.artifact.schema_validation_batch_report.v1" =>
          schema_validation_batch_report_fixture_observations(),
        "fixture.artifact.schema_validation_report.v1" =>
          schema_validation_report_fixture_observations(),
        "fixture.artifact.schema_migration_report.deprecated_campaign_plan" =>
          schema_migration_report_fixture_observations(),
        "fixture.artifact.schema_migration_report.future_campaign_plan" =>
          schema_migration_future_contract_fixture_observations(),
        "fixture.artifact.source_window_lineage.v1" =>
          source_window_lineage_fixture_observations(),
        "fixture.artifact.spacecraft_state_estimate.v1" =>
          spacecraft_state_estimate_fixture_observations(),
        "fixture.artifact.station_calendar_precedence_summary.v1" =>
          station_calendar_precedence_summary_fixture_observations(),
        "fixture.artifact.station_calendar_provider.v1" =>
          station_calendar_provider_fixture_observations(),
        "fixture.artifact.station_calendar_report.stale_provider_reservation_hold" =>
          station_calendar_report_fixture_observations(),
        "fixture.artifact.station_reservation_review_summary.v1" =>
          station_reservation_review_summary_fixture_observations(),
        "fixture.artifact.station_reservation_hold_summary.v1" =>
          station_reservation_hold_summary_fixture_observations(),
        "fixture.artifact.station_reservation_hold_import_readiness_summary.v1" =>
          station_reservation_hold_import_readiness_summary_fixture_observations(),
        "fixture.artifact.station_reservation_report.stale_provider_reservation_hold" =>
          station_reservation_report_fixture_observations(),
        "fixture.artifact.station_calendar_report.v1" =>
          checked_in_station_calendar_report_fixture_observations(),
        "fixture.artifact.strategy_branch.v1" => strategy_branch_fixture_observations(),
        "fixture.artifact.strategy_recommendation.v1" =>
          strategy_recommendation_fixture_observations(),
        "fixture.artifact.study_benchmark.distributed_concurrency_sweep" =>
          distributed_concurrency_benchmark_fixture_observations(),
        "fixture.artifact.study_benchmark.distributed_chunk_sweep" =>
          distributed_chunk_benchmark_fixture_observations(),
        "fixture.artifact.study_benchmark.distributed_diagnostic_sweep" =>
          distributed_diagnostic_benchmark_fixture_observations(),
        "fixture.artifact.study_benchmark.distributed_monte_carlo_chunked" =>
          distributed_monte_carlo_chunked_benchmark_fixture_observations(),
        "fixture.artifact.study_benchmark.distributed_monte_carlo_scaling" =>
          distributed_monte_carlo_scaling_benchmark_fixture_observations(),
        "fixture.artifact.study_benchmark.monte_carlo_scaling" =>
          monte_carlo_scaling_benchmark_fixture_observations(),
        "fixture.artifact.study_benchmark.nx_study_benchmark" =>
          nx_study_benchmark_fixture_observations(),
        "fixture.artifact.study_benchmark.v1" => study_benchmark_fixture_observations(),
        "fixture.artifact.study_manifest_lint.v1" => study_manifest_lint_fixture_observations(),
        "fixture.artifact.subsystem_model_capability.battery" =>
          subsystem_model_capability_fixture_observations(),
        "fixture.artifact.subsystem_model_capability.storage" =>
          subsystem_model_capability_storage_fixture_observations(),
        "fixture.artifact.timeline_activity_approval_state.v1" =>
          timeline_activity_approval_state_fixture_observations(),
        "fixture.artifact.timeline_activity_lifecycle_state.v1" =>
          timeline_activity_lifecycle_state_fixture_observations(),
        "fixture.artifact.timeline_activity_precondition_summary.v1" =>
          timeline_activity_precondition_summary_fixture_observations(),
        "fixture.artifact.timeline_activity_state.v1" =>
          timeline_activity_state_fixture_observations(),
        "fixture.artifact.timeline_activity_status_state.v1" =>
          timeline_activity_status_state_fixture_observations(),
        "fixture.artifact.timeline_dependency_impact_summary.v1" =>
          timeline_dependency_impact_summary_fixture_observations(),
        "fixture.artifact.timeline_diff_report.v1" => timeline_diff_report_fixture_observations(),
        "fixture.artifact.timeline_diff_summary.v1" =>
          timeline_diff_summary_fixture_observations(),
        "fixture.artifact.timeline_feedback_report.v1" =>
          timeline_feedback_report_fixture_observations(),
        "fixture.artifact.timeline_integrity_report.v1" =>
          timeline_integrity_report_fixture_observations(),
        "fixture.artifact.timeline_lifecycle_state_summary.v1" =>
          timeline_lifecycle_state_summary_fixture_observations(),
        "fixture.artifact.timeline_preservation_report.v1" =>
          timeline_preservation_report_fixture_observations(),
        "fixture.artifact.timeline_preservation_status.v1" =>
          timeline_preservation_status_fixture_observations(),
        "fixture.artifact.timeline_publication_summary.v1" =>
          timeline_publication_summary_fixture_observations(),
        "fixture.artifact.timeline_transition_application_report.v1" =>
          timeline_transition_application_report_fixture_observations(),
        "fixture.artifact.timeline_transition_application_selected_integrity.v1" =>
          timeline_transition_application_selected_integrity_fixture_observations(),
        "fixture.artifact.timeline_transition_application_selected_integrity_summary.v1" =>
          timeline_transition_application_selected_integrity_summary_fixture_observations(),
        "fixture.artifact.timeline_transition_application_summary.v1" =>
          timeline_transition_application_summary_fixture_observations(),
        "fixture.artifact.validation_check.v1" => validation_check_fixture_observations(),
        "fixture.artifact.validation_record.v1" => validation_record_fixture_observations(),
        "fixture.artifact.validation_reference_report.v1" =>
          validation_reference_report_fixture_observations(),
        "fixture.artifact.validation_tolerance_policy.v1" =>
          validation_tolerance_policy_fixture_observations(),
        "fixture.j2.circular_leo_600s" => j2_fixture_observations(),
        "fixture.two_body.circular_leo_600s" => two_body_fixture_observations()
      })

    assert %{
             "schema_contract" => "validation_reference_fixture_report.v1",
             "status" => "pass",
             "fixture_count" => 195,
             "status_counts" => %{"pass" => 195},
             "reports" => reports
           } = report

    checked_in_report = read_json!("study_results/validation_reference_fixtures.json")

    assert checked_in_report == report

    stale_checked_in_report =
      checked_in_report
      |> Map.update!("fixture_count", &(&1 - 1))

    refute stale_checked_in_report == report

    assert Enum.map(reports, & &1["fixture_id"]) == [
             "fixture.artifact.accepted_planning_state.oem",
             "fixture.artifact.accepted_planning_state.opm",
             "fixture.artifact.accepted_planning_state.simple",
             "fixture.artifact.activity_template.v1",
             "fixture.artifact.approval_requirement.v1",
             "fixture.artifact.backend_acceptance_policy.v1",
             "fixture.artifact.branch_comparison_report.v1",
             "fixture.artifact.cadence_import_manifest.resource_pressure_v1",
             "fixture.artifact.cadence_import_manifest.resource_projection_battery_handoff_v1",
             "fixture.artifact.cadence_import_manifest.v1",
             "fixture.artifact.campaign_plan.leo_constellation_v1",
             "fixture.artifact.campaign_repair.leo_constellation_v2",
             "fixture.artifact.campaign_request_lint.v1",
             "fixture.artifact.campaign_strategy.leo_constellation_v3",
             "fixture.artifact.candidate_activity.v1",
             "fixture.artifact.candidate_diff_report.v1",
             "fixture.artifact.candidate_diff_row.v1",
             "fixture.artifact.candidate_refresh.candidate_rejection_replay",
             "fixture.artifact.candidate_refresh.constraint_replay",
             "fixture.artifact.candidate_refresh.contact_allocation_contradiction_replay",
             "fixture.artifact.candidate_refresh.contact_contention_cross_station_replay",
             "fixture.artifact.candidate_refresh.contact_filter_replay",
             "fixture.artifact.candidate_refresh.contact_intent_direction_replay",
             "fixture.artifact.candidate_refresh.freshness_replay",
             "fixture.artifact.candidate_refresh.link_capacity_replay",
             "fixture.artifact.candidate_refresh.objective_gap_replay",
             "fixture.artifact.candidate_refresh.operational_readiness_replay",
             "fixture.artifact.candidate_refresh.quality_gate_replay",
             "fixture.artifact.candidate_refresh.refresh_budget_replay",
             "fixture.artifact.candidate_refresh.resource_filter_replay",
             "fixture.artifact.candidate_refresh.resource_projection_replay",
             "fixture.artifact.candidate_refresh.resource_provenance_v1",
             "fixture.artifact.candidate_refresh.station_calendar_replay",
             "fixture.artifact.candidate_refresh.timeline_activity_lifecycle_replay",
             "fixture.artifact.candidate_refresh.timeline_activity_precondition_replay",
             "fixture.artifact.candidate_refresh.timeline_lifecycle_state_replay",
             "fixture.artifact.candidate_refresh.timeline_transition_application_replay",
             "fixture.artifact.candidate_refresh.v1",
             "fixture.artifact.candidate_rejection_report.v1",
             "fixture.artifact.capability_catalog.v1",
             "fixture.artifact.command_window_report.v1",
             "fixture.artifact.constraint_report.v1",
             "fixture.artifact.contact_allocation_capacity_pack_summary.v1",
             "fixture.artifact.contact_allocation_provider_reservation_request_summary.v1",
             "fixture.artifact.contact_allocation_report.reduced_capacity_pack",
             "fixture.artifact.contact_allocation_report.v1",
             "fixture.artifact.contact_allocation_reservation_conflict_summary.v1",
             "fixture.artifact.contact_allocation_station_pressure_summary.v1",
             "fixture.artifact.contact_allocation_summary.v1",
             "fixture.artifact.contact_contention_report.cross_station_spacecraft",
             "fixture.artifact.contact_contention_report.v1",
             "fixture.artifact.contact_contention_resolution_report.v1",
             "fixture.artifact.contact_contention_resolution_summary.v1",
             "fixture.artifact.contact_filter_report.v1",
             "fixture.artifact.contact_intent.v1",
             "fixture.artifact.contact_intent_summary.v1",
             "fixture.artifact.environment_model_capability.constant_earth_rotation",
             "fixture.artifact.environment_model_capability.fixed_sun",
             "fixture.artifact.environment_provider_capability.constant_earth_rotation",
             "fixture.artifact.environment_provider_capability.exponential_atmosphere",
             "fixture.artifact.environment_provider_capability.fixed_sun",
             "fixture.artifact.environment_provider_capability.tabular_earth_orientation",
             "fixture.artifact.execution_report.v1",
             "fixture.artifact.freshness_report.v1",
             "fixture.artifact.invalidated_candidate.v1",
             "fixture.artifact.link_capacity_report.v1",
             "fixture.artifact.link_capacity_summary.v1",
             "fixture.artifact.maneuver_execution_delta.v1",
             "fixture.artifact.maneuver_recommendation.v1",
             "fixture.artifact.maneuver_review_report.v1",
             "fixture.artifact.manifest_field_reference.v1",
             "fixture.artifact.model_acceptance_report.operational_import",
             "fixture.artifact.monte_carlo_reproducibility_report.v1",
             "fixture.artifact.objective_satisfaction_report.v1",
             "fixture.artifact.objective_tradeoff_report.v1",
             "fixture.artifact.operational_execution_boundary_summary.v1",
             "fixture.artifact.operational_import_eligibility_summary.v1",
             "fixture.artifact.operational_quality_gate_import_readiness_summary.v1",
             "fixture.artifact.operational_quality_gate_operator_training_summary.v1",
             "fixture.artifact.operational_quality_gate_schema_validation_summary.v1",
             "fixture.artifact.operational_quality_gate_summary.v1",
             "fixture.artifact.operational_quality_gate_unavailable_resource_summary.resource_projection_v1",
             "fixture.artifact.operational_quality_gate_unavailable_resource_summary.v1",
             "fixture.artifact.operational_readiness_gate_summary.v1",
             "fixture.artifact.operational_readiness_report.resource_pressure_v1",
             "fixture.artifact.operational_readiness_report.v1",
             "fixture.artifact.operational_timeline_report.v1",
             "fixture.artifact.operator_review_package.resource_pressure_v1",
             "fixture.artifact.operator_review_package.resource_projection_battery_handoff_v1",
             "fixture.artifact.operator_review_package.v1",
             "fixture.artifact.optimizer_contract.v1",
             "fixture.artifact.pareto_frontier_report.v1",
             "fixture.artifact.plan_delta.v1",
             "fixture.artifact.planned_activity.v1",
             "fixture.artifact.policy_bundle.command_contact_authority",
             "fixture.artifact.policy_bundle.conservative_ops",
             "fixture.artifact.policy_bundle.contact_command_review",
             "fixture.artifact.policy_bundle.default",
             "fixture.artifact.policy_bundle.degraded_payload_guard",
             "fixture.artifact.policy_bundle.ground_network_allocation",
             "fixture.artifact.policy_bundle.maneuver_authority",
             "fixture.artifact.policy_bundle.operator_review_queue_authority",
             "fixture.artifact.policy_bundle.organization_adapter",
             "fixture.artifact.policy_bundle.resource_projection_authority",
             "fixture.artifact.policy_bundle.timeline_protection",
             "fixture.artifact.policy_bundle.v1",
             "fixture.artifact.policy_decision.v1",
             "fixture.artifact.proposed_contact.v1",
             "fixture.artifact.provider_counteroffer_import_readiness_summary.v1",
             "fixture.artifact.provider_counteroffer_plan_impact_summary.v1",
             "fixture.artifact.provider_counteroffer_report.v1",
             "fixture.artifact.provider_counteroffer_review_summary.v1",
             "fixture.artifact.quality_gate_report.resource_pressure_v1",
             "fixture.artifact.quality_gate_report.v1",
             "fixture.artifact.ranking_comparison_report.v1",
             "fixture.artifact.realized_activity.v1",
             "fixture.artifact.realized_state_snapshot.v1",
             "fixture.artifact.refresh_budget_report.v1",
             "fixture.artifact.refreshed_window.v1",
             "fixture.artifact.relay_data_path_summary.v1",
             "fixture.artifact.remaining_horizon.v1",
             "fixture.artifact.resource_filter_report.stale_resource_summary_margins",
             "fixture.artifact.resource_filter_report.v1",
             "fixture.artifact.resource_filter_summary.v1",
             "fixture.artifact.resource_projection_flow_summary.v1",
             "fixture.artifact.resource_projection_report.battery_handoff_v1",
             "fixture.artifact.resource_projection_report.stale_resource_summary_margins",
             "fixture.artifact.resource_projection_report.v1",
             "fixture.artifact.resource_summary.v1",
             "fixture.artifact.result_artifact.candidate_refresh_orbit_data_v1",
             "fixture.artifact.result_artifact.candidate_refresh_v1",
             "fixture.artifact.result_artifact.ground_track_crossings",
             "fixture.artifact.result_artifact.leo_access_demo",
             "fixture.artifact.result_artifact.leo_access_demo_manifest",
             "fixture.artifact.result_artifact.leo_constellation_campaign",
             "fixture.artifact.result_artifact.leo_dispersion_monte_carlo",
             "fixture.artifact.result_artifact.mission_plan_checkout",
             "fixture.artifact.result_artifact.raise_apogee_search",
             "fixture.artifact.schema_migration_report.deprecated_campaign_plan",
             "fixture.artifact.schema_migration_report.future_campaign_plan",
             "fixture.artifact.schema_validation_batch_report.v1",
             "fixture.artifact.schema_validation_report.v1",
             "fixture.artifact.score_term_report.v1",
             "fixture.artifact.source_window_lineage.v1",
             "fixture.artifact.spacecraft_state_estimate.v1",
             "fixture.artifact.station_calendar_precedence_summary.v1",
             "fixture.artifact.station_calendar_provider.v1",
             "fixture.artifact.station_calendar_report.stale_provider_reservation_hold",
             "fixture.artifact.station_calendar_report.v1",
             "fixture.artifact.station_reservation_hold_import_readiness_summary.v1",
             "fixture.artifact.station_reservation_hold_summary.v1",
             "fixture.artifact.station_reservation_report.stale_provider_reservation_hold",
             "fixture.artifact.station_reservation_review_summary.v1",
             "fixture.artifact.strategy_branch.v1",
             "fixture.artifact.strategy_recommendation.v1",
             "fixture.artifact.study_benchmark.distributed_chunk_sweep",
             "fixture.artifact.study_benchmark.distributed_concurrency_sweep",
             "fixture.artifact.study_benchmark.distributed_diagnostic_sweep",
             "fixture.artifact.study_benchmark.distributed_monte_carlo_chunked",
             "fixture.artifact.study_benchmark.distributed_monte_carlo_scaling",
             "fixture.artifact.study_benchmark.monte_carlo_scaling",
             "fixture.artifact.study_benchmark.nx_study_benchmark",
             "fixture.artifact.study_benchmark.v1",
             "fixture.artifact.study_manifest_lint.v1",
             "fixture.artifact.subsystem_model_capability.battery",
             "fixture.artifact.subsystem_model_capability.storage",
             "fixture.artifact.timeline_activity_approval_state.v1",
             "fixture.artifact.timeline_activity_lifecycle_state.v1",
             "fixture.artifact.timeline_activity_precondition_summary.v1",
             "fixture.artifact.timeline_activity_state.v1",
             "fixture.artifact.timeline_activity_status_state.v1",
             "fixture.artifact.timeline_dependency_impact_summary.v1",
             "fixture.artifact.timeline_diff_report.v1",
             "fixture.artifact.timeline_diff_summary.v1",
             "fixture.artifact.timeline_feedback_report.v1",
             "fixture.artifact.timeline_integrity_report.v1",
             "fixture.artifact.timeline_lifecycle_state_summary.v1",
             "fixture.artifact.timeline_preservation_report.v1",
             "fixture.artifact.timeline_preservation_status.v1",
             "fixture.artifact.timeline_publication_summary.v1",
             "fixture.artifact.timeline_transition_application_report.v1",
             "fixture.artifact.timeline_transition_application_selected_integrity.v1",
             "fixture.artifact.timeline_transition_application_selected_integrity_summary.v1",
             "fixture.artifact.timeline_transition_application_summary.v1",
             "fixture.artifact.validation_check.v1",
             "fixture.artifact.validation_record.v1",
             "fixture.artifact.validation_reference_report.v1",
             "fixture.artifact.validation_safety_case_summary.v1",
             "fixture.artifact.validation_tolerance_policy.v1",
             "fixture.event.access.equator_overhead_120s",
             "fixture.event.eclipse.cylindrical_shadow_120s",
             "fixture.event.ground_track.latitude_equator_60s",
             "fixture.event.target_visibility.equator_overhead_120s",
             "fixture.j2.circular_leo_600s",
             "fixture.two_body.circular_leo_600s"
           ]

    assert {:ok, %{"schema_contract" => "validation_reference_fixture_report.v1"}} =
             OrbitalDynamics.Schema.validate_artifact(report)

    invalid_observation_report =
      Validation.reference_fixture_report(%{
        "fixture.two_body.circular_leo_600s" => :not_an_observation_map
      })

    assert %{
             "status" => "fail",
             "status_counts" => %{"fail" => 195},
             "reports" => invalid_observation_reports
           } = invalid_observation_report

    assert %{
             "schema_contract" => "validation_reference_report.v1",
             "fixture_id" => "fixture.two_body.circular_leo_600s",
             "status" => "fail",
             "checks" => [
               %{
                 "field" => "observations",
                 "status" => "fail",
                 "expected" => "valid observations map"
               }
             ]
           } =
             Enum.find(
               invalid_observation_reports,
               &(&1["fixture_id"] == "fixture.two_body.circular_leo_600s")
             )

    assert {:ok, %{"schema_contract" => "validation_reference_fixture_report.v1"}} =
             OrbitalDynamics.Schema.validate_artifact(invalid_observation_report)

    invalid_fixture_count = Map.put(report, "fixture_count", 99)

    assert {:error, fixture_count_report} =
             OrbitalDynamics.Schema.validate_artifact(invalid_fixture_count)

    assert Enum.any?(
             fixture_count_report["errors"],
             &(&1["path"] == "$.fixture_count")
           )

    inconsistent_status_report =
      report
      |> put_in(["reports", Access.at(0), "status"], "fail")
      |> Map.put("status", "pass")

    assert {:error, inconsistent_status_errors} =
             OrbitalDynamics.Schema.validate_artifact(inconsistent_status_report)

    assert Enum.any?(
             inconsistent_status_errors["errors"],
             &(&1["path"] == "$.status" and
                 &1["message"] == "must equal nested report statuses")
           )

    invalid_negative_fixture_count = Map.put(report, "fixture_count", -1)

    assert {:error, negative_fixture_count_report} =
             OrbitalDynamics.Schema.validate_artifact(invalid_negative_fixture_count)

    assert Enum.any?(
             negative_fixture_count_report["errors"],
             &(&1["path"] == "$.fixture_count")
           )

    stale_status_counts = put_in(report, ["status_counts", "pass"], 123)

    assert {:error, stale_status_counts_report} =
             OrbitalDynamics.Schema.validate_artifact(stale_status_counts)

    assert Enum.any?(
             stale_status_counts_report["errors"],
             &(&1["path"] == "$.status_counts" and
                 &1["message"] == "must equal nested report status counts")
           )
  end

  defp result_set(assumptions) do
    ResultSet.new!(%{
      study_id: :validation,
      trajectory_results: [],
      event_results: [],
      errors: [],
      assumptions: assumptions,
      metadata: %{}
    })
  end

  defp campaign_plan_fixture_observations do
    artifact =
      "study_results/leo_constellation_campaign.json"
      |> read_json!()
      |> Map.fetch!("campaign_plan")

    Validation.artifact_observations("campaign_plan.v1", artifact)
  end

  defp result_artifact_fixture_observations do
    "result_artifact.v1"
    |> Validation.artifact_observations(result_artifact_fixture())
  end

  defp result_artifact_fixture do
    read_json!("study_results/leo_constellation_campaign.json")
  end

  defp leo_access_result_artifact_fixture_observations do
    "result_artifact.v1"
    |> Validation.artifact_observations(leo_access_result_artifact_fixture())
  end

  defp leo_access_result_artifact_fixture do
    read_json!("study_results/leo_access_demo.json")
  end

  defp leo_access_manifest_result_artifact_fixture_observations do
    "result_artifact.v1"
    |> Validation.artifact_observations(leo_access_manifest_result_artifact_fixture())
  end

  defp leo_access_manifest_result_artifact_fixture do
    read_json!("study_results/leo_access_demo_manifest.json")
  end

  defp ground_track_result_artifact_fixture_observations do
    "result_artifact.v1"
    |> Validation.artifact_observations(ground_track_result_artifact_fixture())
  end

  defp ground_track_result_artifact_fixture do
    read_json!("study_results/ground_track_crossings.json")
  end

  defp raise_apogee_result_artifact_fixture_observations do
    "result_artifact.v1"
    |> Validation.artifact_observations(raise_apogee_result_artifact_fixture())
  end

  defp raise_apogee_result_artifact_fixture do
    read_json!("study_results/raise_apogee_search.json")
  end

  defp candidate_refresh_result_artifact_fixture_observations do
    "result_artifact.v1"
    |> Validation.artifact_observations(candidate_refresh_result_artifact_fixture())
  end

  defp candidate_refresh_result_artifact_fixture do
    read_json!("study_results/candidate_refresh_v1.json")
  end

  defp candidate_refresh_orbit_data_result_artifact_fixture_observations do
    "result_artifact.v1"
    |> Validation.artifact_observations(candidate_refresh_orbit_data_result_artifact_fixture())
  end

  defp candidate_refresh_orbit_data_result_artifact_fixture do
    read_json!("study_results/candidate_refresh_orbit_data_v1.json")
  end

  defp monte_carlo_result_artifact_fixture_observations do
    "result_artifact.v1"
    |> Validation.artifact_observations(monte_carlo_result_artifact_fixture())
  end

  defp monte_carlo_result_artifact_fixture do
    read_json!("study_results/leo_dispersion_monte_carlo.json")
  end

  defp mission_plan_checkout_result_artifact_fixture_observations do
    "result_artifact.v1"
    |> Validation.artifact_observations(mission_plan_checkout_result_artifact_fixture())
  end

  defp mission_plan_checkout_result_artifact_fixture do
    read_json!("study_results/mission_plan_checkout.json")
  end

  defp accepted_planning_state_fixture_observations do
    "accepted_planning_state.v1"
    |> Validation.artifact_observations(accepted_planning_state_fixture())
  end

  defp accepted_planning_state_fixture do
    read_json!("study_results/accepted_planning_state_simple.json")
  end

  defp accepted_planning_state_opm_fixture_observations do
    "accepted_planning_state.v1"
    |> Validation.artifact_observations(accepted_planning_state_opm_fixture())
  end

  defp accepted_planning_state_opm_fixture do
    read_json!("study_results/accepted_planning_state_opm.json")
  end

  defp accepted_planning_state_oem_fixture_observations do
    "accepted_planning_state.v1"
    |> Validation.artifact_observations(accepted_planning_state_oem_fixture())
  end

  defp accepted_planning_state_oem_fixture do
    read_json!("study_results/accepted_planning_state_oem.json")
  end

  defp campaign_repair_fixture_observations do
    "study_results/leo_constellation_campaign_repair_v2.json"
    |> read_json!()
    |> then(&Validation.artifact_observations("campaign_repair.v2", &1))
  end

  defp campaign_strategy_fixture_observations do
    "study_results/leo_constellation_campaign_strategy_v3.json"
    |> read_json!()
    |> then(&Validation.artifact_observations("campaign_strategy.v3", &1))
  end

  defp candidate_refresh_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_fixture())
  end

  defp candidate_refresh_fixture do
    "study_results/candidate_refresh_v1.json"
    |> read_json!()
    |> Map.fetch!("candidate_refresh")
  end

  defp candidate_refresh_resource_provenance_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_resource_provenance_fixture())
  end

  defp candidate_refresh_resource_provenance_fixture do
    read_json!("study_results/candidate_refresh_resource_provenance_v1.json")
  end

  defp candidate_refresh_contact_contention_challenge_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_contact_contention_challenge_fixture())
  end

  defp candidate_refresh_contact_contention_challenge_fixture do
    contact_contention_report =
      contact_contention_cross_station_fixture()
      |> update_in(["provenance"], fn provenance ->
        (provenance || %{})
        |> Map.put("trust_boundary", "generated_cross_station_spacecraft_contention_fixture")
      end)

    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh:
        candidate_refresh_contact_contention_challenge_request(contact_contention_report),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  defp candidate_refresh_contact_contention_challenge_request(contact_contention_report) do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-contact-contention-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [],
      "constraints" => %{},
      "scoring_policy" => %{},
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "source_contact_contention_report" => contact_contention_report
    }
  end

  defp candidate_refresh_contact_intent_direction_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_contact_intent_direction_fixture())
  end

  defp candidate_refresh_contact_intent_direction_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_contact_intent_direction_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  defp candidate_refresh_contact_intent_direction_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-contact-intent-direction-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [],
      "constraints" => %{},
      "scoring_policy" => %{},
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "source_contact_intents" => [
        %{
          "schema_contract" => "contact_intent.v1",
          "id" => "intent_direct_capacity",
          "activity_id" => "intent_direct_capacity",
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "direction" => "Down Link",
          "starts_at_s" => 10.0,
          "ends_at_s" => 70.0,
          "station_calendar_status" => "reserved",
          "cadence_import_status" => "ready_for_import",
          "policy_classification" => "review_only",
          "required_capacity_fraction" => 0.25,
          "capacity_pack_required_capacity_fraction" => 99.0,
          "direction_routing" => %{
            "stale_direction" => %{"capacity_pack_contact_ids" => ["stale_contact_intent"]}
          },
          "provenance" => %{
            "trust_boundary" => "generated_contact_intent_direction_fixture"
          }
        },
        %{
          "schema_contract" => "contact_intent.v1",
          "id" => "intent_nested_capacity",
          "activity_id" => "intent_nested_capacity",
          "scenario_id" => "leo_1",
          "ground_station_id" => "dss_43",
          "direction" => "tracking_pass",
          "starts_at_s" => 80.0,
          "ends_at_s" => 130.0,
          "station_availability" => "unavailable",
          "cadence_import_status" => "blocked",
          "policy_classification" => "blocked_by_policy",
          "capacity_model" => %{"station_capacity_requirement" => "0.4"},
          "provenance" => %{
            "trust_boundary" => "generated_contact_intent_direction_fixture"
          }
        },
        %{
          "schema_contract" => "contact_intent.v1",
          "id" => "intent_station_only",
          "activity_id" => "intent_station_only",
          "scenario_id" => "leo_1",
          "ground_station_id" => "dss_43",
          "direction" => "Command",
          "starts_at_s" => 140.0,
          "ends_at_s" => 180.0,
          "provenance" => %{
            "trust_boundary" => "generated_contact_intent_direction_fixture"
          }
        }
      ]
    }
  end

  defp candidate_refresh_resource_projection_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_resource_projection_fixture())
  end

  defp candidate_refresh_resource_projection_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_resource_projection_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  defp candidate_refresh_resource_projection_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-resource-projection-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [],
      "constraints" => %{},
      "scoring_policy" => %{},
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "source_resource_projection_report" => [
        candidate_refresh_resource_projection_report()
      ]
    }
  end

  defp candidate_refresh_resource_projection_report do
    %{
      "schema_contract" => "resource_projection_report.v1",
      "projected_resources" => [
        %{
          "spacecraft_id" => "leo_1",
          "resource_pressure_status" => "downlink_shortfall",
          "resource_pressure_types" => ["downlink_shortfall", "storage_pressure"],
          "first_resource_pressure_activity_id" => "dl_pressure_1",
          "first_resource_pressure_direction" => "Down Link",
          "first_resource_pressure_ground_station_id" => "equator_prime",
          "source_window_id" => "flow_access_window_1",
          "station_calendar_entry_id" => "station_flow_window_1",
          "station_calendar_provider_id" => "ops_calendar_flow",
          "station_calendar_provider_entry_id" => "provider_flow_window_1"
        },
        %{
          "spacecraft_id" => "leo_2",
          "resource_pressure_status" => "storage_shortfall",
          "resource_pressure_types" => ["storage_shortfall"],
          "source_activity_ids" => ["imaging_1", "imaging_2"],
          "direction" => "tracking_pass",
          "ground_station_id" => "dss_43",
          "source_window" => %{"id" => "tracking_window_1"},
          "source_station_calendar_entry" => %{
            "station_calendar_entry_id" => "station_tracking_window_1",
            "station_calendar_provider_id" => "ops_calendar_tracking",
            "station_calendar_provider_entry_id" => "provider_tracking_window_1"
          }
        }
      ],
      "invalid_activity_inputs" => [%{"activity_id" => "bad_activity"}],
      "invalid_resource_summary_inputs" => [%{"spacecraft_id" => "bad_resource_summary"}],
      "resource_pressure_status_counts" => %{"stale_status" => 99},
      "resource_pressure_activity_ids_by_status" => %{"stale_status" => ["stale_activity"]},
      "provenance" => %{"trust_boundary" => "generated_resource_projection_fixture"}
    }
  end

  defp candidate_refresh_quality_gate_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_quality_gate_fixture())
  end

  defp candidate_refresh_quality_gate_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_quality_gate_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  defp candidate_refresh_quality_gate_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-quality-gate-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [],
      "constraints" => %{},
      "scoring_policy" => %{},
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "source_quality_gate_report" => candidate_refresh_quality_gate_report()
    }
  end

  defp candidate_refresh_quality_gate_report do
    quality_gate_resource_pressure_fixture()
    |> Map.put("provenance", %{"trust_boundary" => "generated_quality_gate_fixture"})
  end

  defp candidate_refresh_operational_readiness_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_operational_readiness_fixture())
  end

  defp candidate_refresh_operational_readiness_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_operational_readiness_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  defp candidate_refresh_operational_readiness_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-operational-readiness-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [],
      "constraints" => %{},
      "scoring_policy" => %{},
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "source_operational_readiness_report" => candidate_refresh_operational_readiness_report()
    }
  end

  defp candidate_refresh_operational_readiness_report do
    operational_readiness_resource_pressure_fixture()
    |> Map.put("provenance", %{
      "trust_boundary" => "generated_operational_readiness_fixture"
    })
  end

  defp candidate_refresh_timeline_activity_precondition_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(
      candidate_refresh_timeline_activity_precondition_fixture()
    )
  end

  defp candidate_refresh_timeline_activity_precondition_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_timeline_activity_precondition_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  defp candidate_refresh_timeline_activity_precondition_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-timeline-precondition-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [],
      "constraints" => %{},
      "scoring_policy" => %{},
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "source_timeline_activity_precondition_summary" =>
        candidate_refresh_timeline_activity_precondition_summaries()
    }
  end

  defp candidate_refresh_timeline_activity_precondition_summaries do
    [
      %{
        id: :cmd_preflight,
        type: :command,
        payload_available: false,
        degraded: true,
        resource_blocking_dimension: :power,
        dependency_activity_ids: [:health_check_1, :obs_1, :obs_1],
        dependency_timeline_ids: [:"timeline:health_check_1", :"timeline:health_check_1"],
        exclusive_with_activity_ids: [:dl_conflict, :dl_conflict],
        exclusive_with_timeline_ids: [:"timeline:dl_conflict", :"timeline:dl_conflict"],
        allow_overlap: true,
        metadata: %{timeline_id: :"timeline:cmd_preflight"}
      }
      |> Timeline.activity_precondition_summary(),
      %{id: :bad_missing_type}
      |> Timeline.activity_precondition_summary()
    ]
    |> Enum.map(
      &Map.put(&1, "provenance", %{
        "trust_boundary" => "generated_timeline_precondition_fixture"
      })
    )
  end

  defp candidate_refresh_timeline_lifecycle_state_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_timeline_lifecycle_state_fixture())
  end

  defp candidate_refresh_timeline_lifecycle_state_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_timeline_lifecycle_state_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  defp candidate_refresh_timeline_lifecycle_state_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-timeline-lifecycle-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [],
      "constraints" => %{},
      "scoring_policy" => %{},
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "source_timeline_lifecycle_state_summary" =>
        candidate_refresh_timeline_lifecycle_state_summary()
    }
  end

  defp candidate_refresh_timeline_lifecycle_state_summary do
    timeline_lifecycle_state_summary_fixture()
    |> Map.put("provenance", %{
      "trust_boundary" => "generated_timeline_lifecycle_fixture"
    })
  end

  defp candidate_refresh_timeline_activity_lifecycle_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_timeline_activity_lifecycle_fixture())
  end

  defp candidate_refresh_timeline_activity_lifecycle_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_timeline_activity_lifecycle_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  defp candidate_refresh_timeline_activity_lifecycle_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-timeline-activity-lifecycle-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [],
      "constraints" => %{},
      "scoring_policy" => %{},
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "source_timeline_activity_lifecycle_state" =>
        candidate_refresh_timeline_activity_lifecycle_state()
    }
  end

  defp candidate_refresh_timeline_activity_lifecycle_state do
    timeline_activity_lifecycle_state_fixture()
    |> Map.put("provenance", %{
      "trust_boundary" => "generated_timeline_activity_lifecycle_fixture"
    })
  end

  defp candidate_refresh_timeline_transition_application_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(
      candidate_refresh_timeline_transition_application_fixture()
    )
  end

  defp candidate_refresh_timeline_transition_application_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_timeline_transition_application_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  defp candidate_refresh_timeline_transition_application_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-transition-application-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [],
      "constraints" => %{},
      "scoring_policy" => %{},
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "source_timeline_transition_application_summary" =>
        candidate_refresh_timeline_transition_application_summary()
    }
  end

  defp candidate_refresh_timeline_transition_application_summary do
    activity = %{
      id: :obs_waiting_on_gate,
      type: :observe,
      target_id: :target_alpha,
      starts_at_s: 30.0,
      ends_at_s: 40.0,
      depends_on: [:missing_gate],
      metadata: %{timeline_id: :"timeline:obs_waiting_on_gate"}
    }

    [activity]
    |> Timeline.transition_application_summary([activity])
    |> Map.put("provenance", %{
      "trust_boundary" => "generated_timeline_transition_application_fixture"
    })
  end

  defp candidate_refresh_objective_gap_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_objective_gap_fixture())
  end

  defp candidate_refresh_objective_gap_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_objective_gap_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  defp candidate_refresh_objective_gap_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-objective-gap-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [],
      "constraints" => %{},
      "scoring_policy" => %{},
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "source_objective_satisfaction_report" => %{
        "schema_contract" => "objective_satisfaction_report.v1",
        "rows" => [
          %{
            "gap_id" => "gap_downlink",
            "objective_type" => "downlink_completion",
            "status" => "unmet",
            "ground_station_id" => "equator_prime",
            "missing_downlink_mb" => 20.0,
            "source_activity_id" => "dl_gap_activity",
            "trust_boundary" => "objective_gap_rows"
          },
          %{
            "gap_id" => "gap_target",
            "objective_type" => "target_coverage",
            "status" => "partial",
            "target_id" => "target_a",
            "missing_revisits" => 1,
            "source_activity_id" => "target_gap_activity",
            "trust_boundary" => "objective_gap_rows"
          },
          %{
            "gap_id" => "gap_latency",
            "objective_type" => "collection_latency",
            "status" => "partial",
            "collection_id" => "collection_alpha",
            "max_latency_s" => 600.0,
            "missed_downlink_activity_ids" => ["collection_latency_activity"],
            "trust_boundary" => "objective_gap_rows"
          }
        ],
        "source_activity_id_counts" => %{"stale_objective_activity" => 99},
        "provenance" => %{"trust_boundary" => "objective_gap_report"}
      },
      "source_objective_tradeoff_report" => %{
        "schema_contract" => "objective_tradeoff_report.v1",
        "tradeoffs" => [
          %{
            "tradeoff_id" => "tradeoff_downlink",
            "required_downlink_mb" => 20.0,
            "ground_station_id" => "equator_prime",
            "activity_ids" => ["tradeoff_downlink_activity"],
            "trust_boundary" => "objective_gap_tradeoff_rows"
          },
          %{
            "tradeoff_id" => "tradeoff_target",
            "target_id" => "target_a",
            "required_revisits" => 1.0,
            "source_activity_ids" => ["tradeoff_target_activity"],
            "trust_boundary" => "objective_gap_tradeoff_rows"
          },
          %{
            "tradeoff_id" => "tradeoff_latency",
            "collection_id" => "collection_alpha",
            "collection_latency_gap_s" => 300.0,
            "source_activity_id" => "tradeoff_latency_activity",
            "trust_boundary" => "objective_gap_tradeoff_rows"
          }
        ],
        "source_activity_id_counts" => %{"stale_tradeoff_activity" => 99},
        "provenance" => %{"trust_boundary" => "objective_gap_tradeoff_report"}
      },
      "source_score_term_report" => %{
        "schema_contract" => "score_term_report.v1",
        "rows" => [
          %{
            "term_key" => "downlink_shortfall_mb",
            "value" => 20.0,
            "ground_station_id" => "equator_prime",
            "source_activity_id" => "score_downlink_activity",
            "trust_boundary" => "objective_gap_score_rows"
          },
          %{
            "term_key" => "target_gap_count",
            "value" => 1.0,
            "target_id" => "target_a",
            "source_activity_id" => "score_target_activity",
            "trust_boundary" => "objective_gap_score_rows"
          },
          %{
            "term_key" => "collection_latency_gap_s",
            "value" => 300.0,
            "collection_id" => "collection_alpha",
            "selected_contact" => %{"contact_id" => "score_collection_activity"},
            "trust_boundary" => "objective_gap_score_rows"
          }
        ],
        "source_activity_id_counts" => %{"stale_score_activity" => 99},
        "provenance" => %{"trust_boundary" => "objective_gap_score_report"}
      }
    }
  end

  defp candidate_refresh_constraint_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_constraint_fixture())
  end

  defp candidate_refresh_constraint_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_constraint_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  defp candidate_refresh_constraint_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-constraint-replay-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [],
      "constraints" => %{},
      "scoring_policy" => %{},
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "source_constraint_report" => %{
        "schema_contract" => "constraint_report.v1",
        "rows" => [
          %{
            "constraint_id" => "downlink_shortfall",
            "metric" => "selected_downlink_shortfall_mb",
            "status" => "warning",
            "value" => 40.0,
            "ground_station_id" => "equator_prime",
            "source_activity_id" => "constraint_downlink_activity",
            "trust_boundary" => "constraint_replay_rows"
          },
          %{
            "constraint_id" => "battery_margin",
            "metric" => "battery_margin",
            "status" => "fail",
            "value" => -0.2,
            "resource_id" => "battery_1",
            "spacecraft_id" => "sat_1",
            "activity_ids" => ["constraint_battery_activity"],
            "trust_boundary" => "constraint_replay_rows"
          },
          %{
            "constraint_id" => "storage_margin",
            "metric" => "storage_margin",
            "status" => "warning",
            "value" => -0.1,
            "resource_id" => "storage_1",
            "spacecraft_id" => "sat_1",
            "activity_id" => "constraint_storage_activity",
            "trust_boundary" => "constraint_replay_rows"
          }
        ],
        "provenance" => %{"trust_boundary" => "constraint_replay_report"}
      }
    }
  end

  defp candidate_refresh_link_capacity_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_link_capacity_fixture())
  end

  defp candidate_refresh_link_capacity_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_link_capacity_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  defp candidate_refresh_link_capacity_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-link-capacity-replay-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [],
      "constraints" => %{},
      "scoring_policy" => %{},
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "source_link_capacity_report" => %{
        "schema_contract" => "link_capacity_report.v1",
        "rows" => [
          %{
            "spacecraft_id" => "leo_1",
            "ground_station_id" => "equator_prime",
            "direction" => "Down Link",
            "capacity_adjusted_throughput_mb" => 65.0,
            "selected_capacity_adjusted_throughput_mb" => 25.0,
            "unused_capacity_adjusted_throughput_mb" => 40.0,
            "selected_downlink_shortfall_mb" => 12.0,
            "actual_throughput_mb" => 21.0,
            "source_window_id" => "window_alpha",
            "station_calendar_entry_ids" => ["station_entry_alpha", "station_entry_beta"],
            "station_calendar_provider_entry_ids" => [
              "provider_entry_alpha",
              "provider_entry_beta"
            ],
            "selected_contacts" => [
              %{
                "id" => "contact_alpha",
                "direction" => "Down Link",
                "source_window_id" => "window_alpha",
                "station_calendar_entry_id" => "station_entry_alpha",
                "station_calendar_provider_entry_id" => "provider_entry_alpha"
              },
              %{
                "id" => "contact_beta",
                "direction" => "tracking_pass",
                "source_window_id" => "window_beta",
                "station_calendar_entry_id" => "station_entry_beta",
                "station_calendar_provider_entry_id" => "provider_entry_beta"
              }
            ],
            "actual_throughput_contact" => %{
              "id" => "contact_alpha",
              "source_window_id" => "window_alpha",
              "station_calendar_entry_id" => "station_entry_alpha",
              "station_calendar_provider_entry_id" => "provider_entry_alpha"
            },
            "downlink_requirement_status" => "selected_shortfall",
            "actual_downlink_requirement_status" => "actual_met"
          },
          %{
            "spacecraft_id" => "leo_2",
            "ground_station_id" => "dss_43",
            "direction" => "s-band command",
            "capacity_adjusted_throughput_mb" => 20.0,
            "selected_capacity_adjusted_throughput_mb" => 15.0,
            "unused_capacity_adjusted_throughput_mb" => 5.0,
            "actual_throughput_mb" => 18.0,
            "actual_downlink_shortfall_mb" => 7.0,
            "source_window_ids" => ["window_gamma"],
            "station_calendar_entry_id" => "station_entry_gamma",
            "station_calendar_provider_entry_id" => "provider_entry_gamma",
            "selected_contact" => %{
              "id" => "contact_gamma",
              "source_window_id" => "window_gamma",
              "station_calendar_entry_id" => "station_entry_gamma",
              "station_calendar_provider_entry_id" => "provider_entry_gamma"
            },
            "actual_throughput_contact" => %{
              "id" => "contact_gamma",
              "source_window_id" => "window_gamma",
              "station_calendar_entry_id" => "station_entry_gamma",
              "station_calendar_provider_entry_id" => "provider_entry_gamma"
            },
            "downlink_requirement_status" => "selected_met",
            "actual_downlink_requirement_status" => "actual_shortfall"
          }
        ],
        "capacity_adjusted_throughput_mb_total" => 999.0,
        "selected_capacity_adjusted_throughput_mb_total" => 999.0,
        "unused_capacity_adjusted_throughput_mb_total" => 999.0,
        "contact_ids_by_requirement_status" => %{"stale_status" => ["stale_contact"]},
        "selected_contact_ids" => ["stale_selected_contact"],
        "actual_throughput_contact_ids" => ["stale_actual_contact"],
        "provenance" => %{"trust_boundary" => "link_capacity_replay_report"}
      }
    }
  end

  defp candidate_refresh_resource_filter_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_resource_filter_fixture())
  end

  defp candidate_refresh_resource_filter_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_resource_filter_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  defp candidate_refresh_resource_filter_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-resource-filter-replay-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [],
      "constraints" => %{},
      "scoring_policy" => %{},
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "source_resource_filter_report" => %{
        "schema_contract" => "resource_filter_report.v1",
        "suppressed_candidates" => [
          %{
            "id" => "obs_payload_block",
            "spacecraft_id" => "leo_1",
            "resource_id" => "payload_1",
            "suppressed_reason" => "payload_unavailable",
            "resource_blocking_dimension" => "payload"
          },
          %{
            "id" => "downlink_margin_block",
            "direction" => "Down Link",
            "spacecraft_id" => "leo_1",
            "resource_summary_id" => "downlink_budget",
            "suppressed_reason" => "downlink_margin_low",
            "resource_blocking_dimension" => "communications"
          },
          %{
            "id" => "power_block",
            "activity_context" => %{"direction" => "s-band command"},
            "spacecraft_id" => "leo_2",
            "battery_id" => "battery_main",
            "suppressed_reason" => "power_margin_low",
            "resource_blocking_dimension" => "power"
          }
        ],
        "invalid_resource_summary_inputs" => [%{"resource_summary_id" => "bad_summary"}],
        "suppressed_reason_counts" => %{"stale_reason" => 99},
        "resource_filter_spacecraft_counts" => %{"stale_spacecraft" => 99},
        "candidate_ids_by_spacecraft" => %{"stale_spacecraft" => ["stale_candidate"]},
        "resource_filter_resource_counts" => %{"stale_resource" => 99},
        "candidate_ids_by_resource" => %{"stale_resource" => ["stale_candidate"]},
        "resource_filter_blocking_dimension_counts" => %{"stale_dimension" => 99},
        "candidate_ids_by_blocking_dimension" => %{"stale_dimension" => ["stale_candidate"]},
        "direction_counts" => %{"stale_direction" => 99},
        "candidate_ids_by_direction" => %{"stale_direction" => ["stale_candidate"]},
        "candidate_ids_by_suppressed_reason" => %{"stale_reason" => ["stale_candidate"]},
        "provenance" => %{"trust_boundary" => "resource_filter_replay_report"}
      }
    }
  end

  defp candidate_refresh_contact_filter_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_contact_filter_fixture())
  end

  defp candidate_refresh_contact_filter_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_contact_filter_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  defp candidate_refresh_contact_filter_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-contact-filter-replay-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [],
      "constraints" => %{},
      "scoring_policy" => %{},
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "source_contact_filter_report" => %{
        "schema_contract" => "contact_filter_report.v1",
        "suppressed_candidates" => [
          %{
            "id" => "dl_station_unavailable",
            "direction" => "Down Link",
            "ground_station_id" => "equator_prime",
            "station_calendar_entry_id" => "entry_unavailable",
            "station_calendar_provider_entry_id" => "provider_entry_unavailable",
            "suppressed_reason" => "ground_station_unavailable"
          },
          %{
            "id" => "dl_station_reserved",
            "direction" => "s-band command",
            "ground_station_id" => "dss_43",
            "station_calendar_entry_id" => "entry_reserved",
            "station_calendar_provider_entry_id" => "provider_entry_reserved",
            "station_reservation_id" => "reservation_dss_43",
            "suppressed_reason" => "ground_station_reserved"
          },
          %{
            "id" => "dl_station_capacity_zero",
            "direction" => "tracking_pass",
            "ground_station_id" => "dss_43",
            "station_calendar_entry_id" => "entry_capacity_zero",
            "station_calendar_provider_entry_id" => "provider_entry_capacity_zero",
            "suppressed_reason" => "ground_station_capacity_zero"
          },
          %{
            "id" => "invalid_contact",
            "direction" => "health-check",
            "suppressed_reason" => "invalid_contact_input",
            "required_operator_action" => "review_invalid_contact_filter_input"
          }
        ],
        "suppressed_reason_counts" => %{"stale_reason" => 99},
        "direction_counts" => %{"stale_direction" => 99},
        "contact_ids_by_direction" => %{"stale_direction" => ["stale_contact"]},
        "station_suppression_ground_station_counts" => %{"stale_station" => 99},
        "station_suppression_availability_counts" => %{"stale_availability" => 99},
        "station_suppression_status_counts" => %{"stale_status" => 99},
        "station_suppression_station_calendar_provider_entry_ids_by_ground_station" => %{
          "stale_station" => ["stale_provider_entry"]
        },
        "station_suppression_station_calendar_provider_entry_ids_by_availability" => %{
          "stale_availability" => ["stale_provider_entry"]
        },
        "station_suppression_station_calendar_provider_entry_ids_by_status" => %{
          "stale_status" => ["stale_provider_entry"]
        },
        "provenance" => %{"trust_boundary" => "contact_filter_replay_report"}
      }
    }
  end

  defp candidate_refresh_candidate_rejection_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_candidate_rejection_fixture())
  end

  defp candidate_refresh_candidate_rejection_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_candidate_rejection_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  defp candidate_refresh_candidate_rejection_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-candidate-rejection-replay-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [],
      "constraints" => %{},
      "scoring_policy" => %{},
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "source_candidate_rejection_report" => %{
        "schema_contract" => "candidate_rejection_report.v1",
        "row_count" => 2,
        "rejected_count" => 2,
        "reviewable_count" => 1,
        "invalid_candidate_input_count" => 1,
        "rejection_reason_counts" => %{
          "stale_rejection_reason" => 99
        },
        "required_operator_action_counts" => %{
          "stale_required_action" => 99
        },
        "rows" => [
          %{
            "id" => "candidate_rejection:dl_reserved",
            "candidate_id" => "dl_reserved",
            "ground_station_id" => "equator_prime",
            "rejection_reasons" => ["station_reserved"],
            "primary_rejection_reason" => "station_reserved",
            "required_operator_action" => "review_candidate_rejection"
          },
          %{
            "id" => "candidate_rejection:bad_candidate",
            "candidate_id" => "bad_candidate",
            "activity_context" => %{"ground_station_id" => "dss_43"},
            "rejection_reasons" => ["invalid_candidate_input"],
            "primary_rejection_reason" => "invalid_candidate_input",
            "required_operator_action" => "none"
          }
        ],
        "provenance" => %{"trust_boundary" => "candidate_rejection_replay_report"}
      }
    }
  end

  defp candidate_refresh_freshness_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_freshness_fixture())
  end

  defp candidate_refresh_freshness_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_freshness_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  defp candidate_refresh_freshness_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-freshness-replay-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [],
      "constraints" => %{},
      "scoring_policy" => %{},
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "source_freshness_report" => [
        %{
          "schema_contract" => "freshness_report.v1",
          "status" => "stale",
          "stale_reasons" => [
            "accepted_snapshot_older_than_policy",
            "horizon_start_before_now"
          ],
          "provenance" => %{"trust_boundary" => "ops_freshness"}
        },
        %{
          "schema_contract" => "freshness_report.v1",
          "freshness_status" => "unknown",
          "unknown_reasons" => ["missing_generated_at"],
          "provenance" => %{"trust_boundary" => "ops_freshness"}
        }
      ]
    }
  end

  defp candidate_refresh_refresh_budget_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_refresh_budget_fixture())
  end

  defp candidate_refresh_refresh_budget_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_refresh_budget_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  defp candidate_refresh_refresh_budget_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-refresh-budget-replay-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [],
      "constraints" => %{},
      "scoring_policy" => %{},
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
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
  end

  defp candidate_refresh_station_calendar_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_station_calendar_fixture())
  end

  defp candidate_refresh_station_calendar_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_station_calendar_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  defp candidate_refresh_station_calendar_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-station-calendar-replay-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [],
      "constraints" => %{},
      "scoring_policy" => %{},
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "source_station_calendar_report" => %{
        "schema_contract" => "station_calendar_report.v1",
        "affected_contacts" => [
          %{
            "id" => "station_calendar:dl_unavailable",
            "contact_id" => "dl_unavailable",
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "station_calendar_entry_id" => "station_entry_unavailable",
            "station_calendar_status" => "unavailable"
          },
          %{
            "id" => "station_calendar:dl_reserved",
            "contact_id" => "dl_reserved",
            "ground_station_id" => "dss_43",
            "direction" => "uplink",
            "station_calendar_entry_id" => "station_entry_reserved",
            "station_reservation_id" => "reservation_dss_43",
            "station_reserved_by" => "ops_team_b",
            "station_reservation_expires_at_s" => 1800.0,
            "station_availability" => "reserved",
            "station_calendar_status" => "reserved"
          },
          %{
            "id" => "station_calendar:dl_reduced",
            "contact_id" => "dl_reduced",
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "station_calendar_entry_id" => "station_entry_reduced",
            "capacity_fraction" => 0.4,
            "station_availability" => "reduced_capacity",
            "station_calendar_status" => "reduced_capacity"
          }
        ],
        "provider_calendar_contention_groups" => [
          %{
            "id" => "station_calendar_provider_contention:equator_prime:1",
            "provider_ids" => ["ops_calendar", "partner_calendar"],
            "provider_entry_ids" => ["provider_entry_ops", "provider_entry_partner"],
            "ground_station_id" => "equator_prime",
            "capacity_fraction" => 0.25,
            "directions" => ["Down Link", "Track-ing"],
            "source_station_calendar_entries" => [
              %{"id" => "provider_a", "ground_station_id" => "equator_prime"},
              %{"id" => "provider_b", "ground_station_id" => "dss_43"}
            ]
          }
        ],
        "station_calendar_status_counts" => %{"stale_status" => 99},
        "affected_contact_ground_station_counts" => %{"stale_station" => 99},
        "affected_contact_availability_counts" => %{"stale_availability" => 99},
        "provider_calendar_contention_provider_counts" => %{"stale_provider" => 99},
        "provider_calendar_contention_ground_station_counts" => %{"stale_station" => 99},
        "provider_calendar_contention_provider_entry_ids_by_provider" => %{
          "stale_provider" => ["stale_provider_entry"]
        },
        "provider_calendar_contention_provider_entry_ids_by_ground_station" => %{
          "stale_station" => ["stale_provider_entry"]
        },
        "provider_calendar_contention_provider_entry_ids_by_direction" => %{
          "stale_direction" => ["stale_provider_entry"]
        },
        "provenance" => %{"trust_boundary" => "ops_station_calendar"}
      }
    }
  end

  defp candidate_refresh_contact_allocation_contradiction_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(
      candidate_refresh_contact_allocation_contradiction_fixture()
    )
  end

  defp candidate_refresh_contact_allocation_contradiction_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_contact_allocation_contradiction_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  defp candidate_refresh_contact_allocation_contradiction_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-provider-calendar-reservation-allocation-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [],
      "constraints" => %{},
      "scoring_policy" => %{},
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "source_station_calendar_report" =>
        read_json!("study_results/station_calendar_report_v1.json"),
      "source_contact_allocation_reservation_conflict_summary" =>
        read_json!("study_results/contact_allocation_reservation_conflict_summary_v1.json"),
      "source_contact_allocation_provider_reservation_request_summary" =>
        read_json!(
          "study_results/contact_allocation_provider_reservation_request_summary_v1.json"
        )
    }
  end

  defp candidate_rejection_report_fixture_observations do
    "candidate_rejection_report.v1"
    |> Validation.artifact_observations(candidate_rejection_report_fixture())
  end

  defp candidate_rejection_report_fixture do
    read_json!("study_results/candidate_rejection_report_v1.json")
  end

  defp candidate_diff_row_fixture_observations do
    "candidate_diff_row.v1"
    |> Validation.artifact_observations(candidate_diff_row_fixture())
  end

  defp candidate_diff_row_fixture do
    read_json!("study_results/candidate_diff_row_v1.json")
  end

  defp campaign_request_lint_fixture_observations do
    "campaign_request_lint.v1"
    |> Validation.artifact_observations(campaign_request_lint_fixture())
  end

  defp campaign_request_lint_fixture do
    read_json!("study_results/campaign_request_lint_v1.json")
  end

  defp capability_catalog_fixture_observations do
    "capability_catalog.v1"
    |> Validation.artifact_observations(capability_catalog_fixture())
  end

  defp capability_catalog_fixture do
    read_json!("study_results/capability_catalog_v1.json")
  end

  defp environment_model_capability_fixed_sun_fixture_observations do
    "environment_model_capability.v1"
    |> Validation.artifact_observations(
      environment_model_capability_fixture("environment.solar.fixed_inertial_direction")
    )
  end

  defp environment_model_capability_constant_earth_rotation_fixture_observations do
    "environment_model_capability.v1"
    |> Validation.artifact_observations(
      environment_model_capability_fixture("environment.earth_rotation.constant_rate")
    )
  end

  defp environment_model_capability_fixture(id) do
    Environment.model_capabilities()
    |> Enum.find(&(Map.get(&1, "id") == id))
  end

  defp environment_provider_capability_fixed_sun_fixture_observations do
    "environment_provider_capability.v1"
    |> Validation.artifact_observations(
      environment_provider_capability_fixture(
        "environment.provider.solar.fixed_inertial_direction"
      )
    )
  end

  defp environment_provider_capability_constant_earth_rotation_fixture_observations do
    "environment_provider_capability.v1"
    |> Validation.artifact_observations(
      environment_provider_capability_fixture("environment.provider.earth_rotation.constant_rate")
    )
  end

  defp environment_provider_capability_tabular_earth_orientation_fixture_observations do
    "environment_provider_capability.v1"
    |> Validation.artifact_observations(
      environment_provider_capability_fixture(
        "environment.provider.earth_orientation.tabular_rotation"
      )
    )
  end

  defp environment_provider_capability_exponential_atmosphere_fixture_observations do
    "environment_provider_capability.v1"
    |> Validation.artifact_observations(
      environment_provider_capability_fixture(
        "environment.provider.atmosphere.exponential_reference"
      )
    )
  end

  defp environment_provider_capability_fixture(id) do
    Environment.provider_capabilities()
    |> Enum.find(&(Map.get(&1, "id") == id))
  end

  defp branch_comparison_report_fixture_observations do
    "branch_comparison_report.v1"
    |> Validation.artifact_observations(branch_comparison_report_fixture())
  end

  defp branch_comparison_report_fixture do
    read_json!("study_results/branch_comparison_report_v1.json")
  end

  defp optimizer_contract_fixture_observations do
    "optimizer_contract.v1"
    |> Validation.artifact_observations(optimizer_contract_fixture())
  end

  defp optimizer_contract_fixture do
    read_json!("study_results/optimizer_contract_v1.json")
  end

  defp proposed_contact_fixture_observations do
    "proposed_contact.v1"
    |> Validation.artifact_observations(proposed_contact_fixture())
  end

  defp proposed_contact_fixture do
    read_json!("study_results/proposed_contact_v1.json")
  end

  defp invalidated_candidate_fixture_observations do
    "invalidated_candidate.v1"
    |> Validation.artifact_observations(invalidated_candidate_fixture())
  end

  defp invalidated_candidate_fixture do
    read_json!("study_results/invalidated_candidate_v1.json")
  end

  defp strategy_branch_fixture_observations do
    "strategy_branch.v1"
    |> Validation.artifact_observations(strategy_branch_fixture())
  end

  defp strategy_branch_fixture do
    read_json!("study_results/strategy_branch_v1.json")
  end

  defp strategy_recommendation_fixture_observations do
    "strategy_recommendation.v1"
    |> Validation.artifact_observations(strategy_recommendation_fixture())
  end

  defp strategy_recommendation_fixture do
    read_json!("study_results/strategy_recommendation_v1.json")
  end

  defp study_benchmark_fixture_observations do
    "study_benchmark.v1"
    |> Validation.artifact_observations(study_benchmark_fixture())
  end

  defp study_benchmark_fixture do
    read_json!("study_results/study_benchmark.json")
  end

  defp distributed_concurrency_benchmark_fixture_observations do
    "study_benchmark.v1"
    |> Validation.artifact_observations(distributed_concurrency_benchmark_fixture())
  end

  defp distributed_concurrency_benchmark_fixture do
    read_json!("study_results/distributed_concurrency_sweep.json")
  end

  defp distributed_chunk_benchmark_fixture_observations do
    "study_benchmark.v1"
    |> Validation.artifact_observations(distributed_chunk_benchmark_fixture())
  end

  defp distributed_chunk_benchmark_fixture do
    read_json!("study_results/distributed_chunk_sweep.json")
  end

  defp distributed_monte_carlo_scaling_benchmark_fixture_observations do
    "study_benchmark.v1"
    |> Validation.artifact_observations(distributed_monte_carlo_scaling_benchmark_fixture())
  end

  defp distributed_monte_carlo_scaling_benchmark_fixture do
    read_json!("study_results/distributed_monte_carlo_scaling.json")
  end

  defp distributed_diagnostic_benchmark_fixture_observations do
    "study_benchmark.v1"
    |> Validation.artifact_observations(distributed_diagnostic_benchmark_fixture())
  end

  defp distributed_diagnostic_benchmark_fixture do
    read_json!("study_results/distributed_diagnostic_sweep.json")
  end

  defp distributed_monte_carlo_chunked_benchmark_fixture_observations do
    "study_benchmark.v1"
    |> Validation.artifact_observations(distributed_monte_carlo_chunked_benchmark_fixture())
  end

  defp distributed_monte_carlo_chunked_benchmark_fixture do
    read_json!("study_results/distributed_monte_carlo_chunked.json")
  end

  defp monte_carlo_scaling_benchmark_fixture_observations do
    "study_benchmark.v1"
    |> Validation.artifact_observations(monte_carlo_scaling_benchmark_fixture())
  end

  defp monte_carlo_scaling_benchmark_fixture do
    read_json!("study_results/monte_carlo_scaling.json")
  end

  defp nx_study_benchmark_fixture_observations do
    "study_benchmark.v1"
    |> Validation.artifact_observations(nx_study_benchmark_fixture())
  end

  defp nx_study_benchmark_fixture do
    read_json!("study_results/nx_study_benchmark.json")
  end

  defp validation_reference_report_fixture_observations do
    "validation_reference_report.v1"
    |> Validation.artifact_observations(validation_reference_report_fixture())
  end

  defp validation_reference_report_fixture do
    read_json!("study_results/validation_reference_report_v1.json")
  end

  defp candidate_diff_report_fixture_observations do
    "candidate_diff_report.v1"
    |> Validation.artifact_observations(candidate_diff_report_fixture())
  end

  defp candidate_diff_report_fixture do
    read_json!("study_results/candidate_diff_report_v1.json")
  end

  defp refresh_budget_report_fixture_observations do
    "refresh_budget_report.v1"
    |> Validation.artifact_observations(refresh_budget_report_fixture())
  end

  defp refresh_budget_report_fixture do
    read_json!("study_results/refresh_budget_report_v1.json")
  end

  defp execution_report_fixture_observations do
    "execution_report.v1"
    |> Validation.artifact_observations(execution_report_fixture())
  end

  defp execution_report_fixture do
    read_json!("study_results/execution_report_v1.json")
  end

  defp freshness_report_fixture_observations do
    "freshness_report.v1"
    |> Validation.artifact_observations(freshness_report_fixture())
  end

  defp freshness_report_fixture do
    read_json!("study_results/freshness_report_v1.json")
  end

  defp manifest_field_reference_fixture_observations do
    "manifest_field_reference.v1"
    |> Validation.artifact_observations(manifest_field_reference_fixture())
  end

  defp manifest_field_reference_fixture do
    read_json!("study_results/manifest_field_reference.json")
  end

  defp study_manifest_lint_fixture_observations do
    "study_manifest_lint.v1"
    |> Validation.artifact_observations(study_manifest_lint_fixture())
  end

  defp study_manifest_lint_fixture do
    read_json!("study_results/study_manifest_lint_v1.json")
  end

  defp approval_requirement_fixture_observations do
    "approval_requirement.v1"
    |> Validation.artifact_observations(approval_requirement_fixture())
  end

  defp approval_requirement_fixture do
    read_json!("study_results/approval_requirement_v1.json")
  end

  defp policy_decision_fixture_observations do
    "policy_decision.v1"
    |> Validation.artifact_observations(policy_decision_fixture())
  end

  defp policy_decision_fixture do
    read_json!("study_results/policy_decision_v1.json")
  end

  defp policy_bundle_fixture_observations do
    "policy_bundle.v1"
    |> Validation.artifact_observations(policy_bundle_fixture())
  end

  defp policy_bundle_fixture do
    read_json!("study_results/policy_bundle_v1.json")
  end

  defp ground_network_policy_bundle_fixture_observations do
    "policy_bundle.v1"
    |> Validation.artifact_observations(ground_network_policy_bundle_fixture())
  end

  defp ground_network_policy_bundle_fixture do
    read_json!("study_results/policy_bundle_ground_network_allocation_v1.json")
  end

  defp operator_review_queue_policy_bundle_fixture_observations do
    "policy_bundle.v1"
    |> Validation.artifact_observations(operator_review_queue_policy_bundle_fixture())
  end

  defp operator_review_queue_policy_bundle_fixture do
    read_json!("study_results/policy_bundle_operator_review_queue_authority_v1.json")
  end

  defp command_contact_policy_bundle_fixture_observations do
    "policy_bundle.v1"
    |> Validation.artifact_observations(command_contact_policy_bundle_fixture())
  end

  defp command_contact_policy_bundle_fixture do
    read_json!("study_results/policy_bundle_command_contact_authority_v1.json")
  end

  defp conservative_policy_bundle_fixture_observations do
    "policy_bundle.v1"
    |> Validation.artifact_observations(conservative_policy_bundle_fixture())
  end

  defp conservative_policy_bundle_fixture do
    read_json!("study_results/policy_bundle_conservative_ops_v1.json")
  end

  defp contact_command_review_policy_bundle_fixture_observations do
    "policy_bundle.v1"
    |> Validation.artifact_observations(contact_command_review_policy_bundle_fixture())
  end

  defp contact_command_review_policy_bundle_fixture do
    read_json!("study_results/policy_bundle_contact_command_review_v1.json")
  end

  defp degraded_payload_guard_policy_bundle_fixture_observations do
    "policy_bundle.v1"
    |> Validation.artifact_observations(degraded_payload_guard_policy_bundle_fixture())
  end

  defp degraded_payload_guard_policy_bundle_fixture do
    read_json!("study_results/policy_bundle_degraded_payload_guard_v1.json")
  end

  defp default_policy_bundle_fixture_observations do
    "policy_bundle.v1"
    |> Validation.artifact_observations(default_policy_bundle_fixture())
  end

  defp default_policy_bundle_fixture do
    read_json!("study_results/policy_bundle_default_v1.json")
  end

  defp maneuver_authority_policy_bundle_fixture_observations do
    "policy_bundle.v1"
    |> Validation.artifact_observations(maneuver_authority_policy_bundle_fixture())
  end

  defp maneuver_authority_policy_bundle_fixture do
    read_json!("study_results/policy_bundle_maneuver_authority_v1.json")
  end

  defp resource_projection_authority_policy_bundle_fixture_observations do
    "policy_bundle.v1"
    |> Validation.artifact_observations(resource_projection_authority_policy_bundle_fixture())
  end

  defp resource_projection_authority_policy_bundle_fixture do
    read_json!("study_results/policy_bundle_resource_projection_authority_v1.json")
  end

  defp timeline_protection_policy_bundle_fixture_observations do
    "policy_bundle.v1"
    |> Validation.artifact_observations(timeline_protection_policy_bundle_fixture())
  end

  defp timeline_protection_policy_bundle_fixture do
    read_json!("study_results/policy_bundle_timeline_protection_v1.json")
  end

  defp organization_adapter_policy_bundle_fixture_observations do
    "policy_bundle.v1"
    |> Validation.artifact_observations(organization_adapter_policy_bundle_fixture())
  end

  defp organization_adapter_policy_bundle_fixture do
    read_json!("study_results/policy_bundle_organization_adapter_v1.json")
  end

  defp planned_activity_fixture_observations do
    "planned_activity.v1"
    |> Validation.artifact_observations(planned_activity_fixture())
  end

  defp planned_activity_fixture do
    read_json!("study_results/planned_activity_v1.json")
  end

  defp activity_template_fixture_observations do
    "activity_template.v1"
    |> Validation.artifact_observations(activity_template_fixture())
  end

  defp activity_template_fixture do
    read_json!("study_results/activity_template_v1.json")
  end

  defp subsystem_model_capability_fixture_observations do
    "subsystem_model_capability.v1"
    |> Validation.artifact_observations(subsystem_model_capability_fixture())
  end

  defp subsystem_model_capability_fixture do
    read_json!("study_results/subsystem_model_capability_v1.json")
  end

  defp subsystem_model_capability_storage_fixture_observations do
    "subsystem_model_capability.v1"
    |> Validation.artifact_observations(subsystem_model_capability_storage_fixture())
  end

  defp subsystem_model_capability_storage_fixture do
    read_json!("study_results/subsystem_model_capability_storage_v1.json")
  end

  defp realized_activity_fixture_observations do
    "realized_activity.v1"
    |> Validation.artifact_observations(realized_activity_fixture())
  end

  defp realized_activity_fixture do
    read_json!("study_results/realized_activity_v1.json")
  end

  defp plan_delta_fixture_observations do
    "plan_delta.v1"
    |> Validation.artifact_observations(plan_delta_fixture())
  end

  defp plan_delta_fixture do
    read_json!("study_results/plan_delta_v1.json")
  end

  defp candidate_activity_fixture_observations do
    "candidate_activity.v1"
    |> Validation.artifact_observations(candidate_activity_fixture())
  end

  defp candidate_activity_fixture do
    read_json!("study_results/candidate_activity_v1.json")
  end

  defp contact_intent_fixture_observations do
    "contact_intent.v1"
    |> Validation.artifact_observations(contact_intent_fixture())
  end

  defp contact_intent_fixture do
    read_json!("study_results/contact_intent_v1.json")
  end

  defp contact_intent_summary_fixture_observations do
    "contact_intent_summary.v1"
    |> Validation.artifact_observations(contact_intent_summary_fixture())
  end

  defp contact_intent_summary_fixture do
    read_json!("study_results/contact_intent_summary_v1.json")
  end

  defp refreshed_window_fixture_observations do
    "refreshed_window.v1"
    |> Validation.artifact_observations(refreshed_window_fixture())
  end

  defp refreshed_window_fixture do
    read_json!("study_results/refreshed_window_v1.json")
  end

  defp source_window_lineage_fixture_observations do
    "source_window_lineage.v1"
    |> Validation.artifact_observations(source_window_lineage_fixture())
  end

  defp source_window_lineage_fixture do
    read_json!("study_results/source_window_lineage_v1.json")
  end

  defp spacecraft_state_estimate_fixture_observations do
    "spacecraft_state_estimate.v1"
    |> Validation.artifact_observations(spacecraft_state_estimate_fixture())
  end

  defp spacecraft_state_estimate_fixture do
    read_json!("study_results/spacecraft_state_estimate_v1.json")
  end

  defp realized_state_snapshot_fixture_observations do
    "realized_state_snapshot.v1"
    |> Validation.artifact_observations(realized_state_snapshot_fixture())
  end

  defp realized_state_snapshot_fixture do
    read_json!("study_results/realized_state_snapshot_v1.json")
  end

  defp remaining_horizon_fixture_observations do
    "remaining_horizon.v1"
    |> Validation.artifact_observations(remaining_horizon_fixture())
  end

  defp remaining_horizon_fixture do
    read_json!("study_results/remaining_horizon_v1.json")
  end

  defp maneuver_execution_delta_fixture_observations do
    "maneuver_execution_delta.v1"
    |> Validation.artifact_observations(maneuver_execution_delta_fixture())
  end

  defp maneuver_execution_delta_fixture do
    read_json!("study_results/maneuver_execution_delta_v1.json")
  end

  defp maneuver_recommendation_fixture_observations do
    "maneuver_recommendation.v1"
    |> Validation.artifact_observations(maneuver_recommendation_fixture())
  end

  defp maneuver_recommendation_fixture do
    read_json!("study_results/maneuver_recommendation_v1.json")
  end

  defp backend_acceptance_policy_fixture_observations do
    "backend_acceptance_policy.v1"
    |> Validation.artifact_observations(backend_acceptance_policy_fixture())
  end

  defp backend_acceptance_policy_fixture do
    read_json!("study_results/backend_acceptance_policy_v1.json")
  end

  defp validation_tolerance_policy_fixture_observations do
    "validation_tolerance_policy.v1"
    |> Validation.artifact_observations(validation_tolerance_policy_fixture())
  end

  defp validation_tolerance_policy_fixture do
    read_json!("study_results/validation_tolerance_policy_v1.json")
  end

  defp validation_record_fixture_observations do
    "validation_record.v1"
    |> Validation.artifact_observations(validation_record_fixture())
  end

  defp validation_record_fixture do
    read_json!("study_results/validation_record_v1.json")
  end

  defp validation_check_fixture_observations do
    "validation_check.v1"
    |> Validation.artifact_observations(validation_check_fixture())
  end

  defp validation_check_fixture do
    read_json!("study_results/validation_check_v1.json")
  end

  defp timeline_diff_report_fixture_observations do
    "timeline_diff_report.v1"
    |> Validation.artifact_observations(timeline_diff_report_fixture())
  end

  defp timeline_diff_report_fixture do
    read_json!("study_results/timeline_diff_report_v1.json")
  end

  defp timeline_diff_summary_fixture_observations do
    "timeline_diff_summary.v1"
    |> Validation.artifact_observations(timeline_diff_summary_fixture())
  end

  defp timeline_diff_summary_fixture do
    read_json!("study_results/timeline_diff_summary_v1.json")
  end

  defp timeline_publication_summary_fixture_observations do
    "timeline_publication_summary.v1"
    |> Validation.artifact_observations(timeline_publication_summary_fixture())
  end

  defp timeline_publication_summary_fixture do
    read_json!("study_results/timeline_publication_summary_v1.json")
  end

  defp generated_timeline_publication_summary_fixture do
    source = [
      %{id: :health_gate, type: :health_check, starts_at_s: 0.0, ends_at_s: 10.0},
      %{
        id: :cmd_main,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependencies: [:health_gate]
      }
    ]

    replacement = [
      %{id: :health_gate, type: :health_check, starts_at_s: 5.0, ends_at_s: 15.0},
      %{
        id: :cmd_main,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependencies: [:health_gate]
      }
    ]

    source_artifact = %{
      "schema_contract" => "operational_timeline_report.v1",
      "id" => "timeline:published_plan:v2"
    }

    OrbitalDynamics.timeline_publication_summary(source_artifact,
      publication_sequence: 7,
      publication_authority: :mission_operations,
      supersedes_artifact_ids: ["timeline:published_plan:v1"],
      downstream_product_ids: ["operator_review:plan:v1", "cadence_import:plan:v1"],
      dependency_impact_summary:
        OrbitalDynamics.timeline_dependency_impact_summary(source, replacement),
      timeline_diff_summary: OrbitalDynamics.timeline_diff_summary(source, replacement)
    )
  end

  defp timeline_activity_precondition_summary_fixture_observations do
    "timeline_activity_precondition_summary.v1"
    |> Validation.artifact_observations(timeline_activity_precondition_summary_fixture())
  end

  defp timeline_activity_precondition_summary_fixture do
    read_json!("study_results/timeline_activity_precondition_summary_v1.json")
  end

  defp generated_timeline_activity_precondition_summary_fixture do
    %{
      "id" => "cmd_source",
      "type" => "command",
      "scenario_id" => "leo_1",
      "metadata" => %{"timeline_id" => "timeline:cmd_source"},
      "payload_available" => false,
      "resource_blocking_dimension" => "power",
      "degraded" => true
    }
    |> OrbitalDynamics.timeline_activity_precondition_summary()
  end

  defp timeline_activity_state_fixture_observations do
    "timeline_activity_state.v1"
    |> Validation.artifact_observations(timeline_activity_state_fixture())
  end

  defp timeline_activity_state_fixture do
    read_json!("study_results/timeline_activity_state_v1.json")
  end

  defp generated_timeline_activity_state_fixture do
    planned = %{
      id: :cmd_lock,
      type: :command,
      status: :approved,
      approved: true,
      locked: true,
      starts_at_s: 100,
      ends_at_s: 120,
      metadata: %{timeline_id: :"timeline:cmd_lock"}
    }

    realized = %{
      id: :cmd_new,
      type: :command,
      status: :executed,
      starts_at_s: 130,
      ends_at_s: 140,
      metadata: %{timeline_id: :"timeline:cmd_new"}
    }

    OrbitalDynamics.timeline_activity_state(planned, realized)
  end

  defp timeline_activity_approval_state_fixture_observations do
    "timeline_activity_approval_state.v1"
    |> Validation.artifact_observations(timeline_activity_approval_state_fixture())
  end

  defp timeline_activity_approval_state_fixture do
    read_json!("study_results/timeline_activity_approval_state_v1.json")
  end

  defp generated_timeline_activity_approval_state_fixture do
    planned = %{
      id: :cmd_provider,
      type: :command,
      scenario_id: :leo_1,
      approval_status: "Review Required",
      command_window_id: :"command_window:cmd_provider",
      command_window_type: :command_window,
      source_window_id: :"command:cmd_provider",
      metadata: %{
        timeline_id: :"timeline:cmd_provider",
        source_window_id: :"command:cmd_provider"
      }
    }

    realized = %{
      id: :cmd_provider,
      type: :command,
      scenario_id: :leo_1,
      approval_status: :approved,
      command_window_id: :"command_window:cmd_provider",
      command_window_type: :command_window,
      metadata: %{timeline_id: :"timeline:cmd_provider"}
    }

    OrbitalDynamics.timeline_activity_approval_state(planned, realized)
  end

  defp timeline_activity_status_state_fixture_observations do
    "timeline_activity_status_state.v1"
    |> Validation.artifact_observations(timeline_activity_status_state_fixture())
  end

  defp timeline_activity_status_state_fixture do
    read_json!("study_results/timeline_activity_status_state_v1.json")
  end

  defp generated_timeline_activity_status_state_fixture do
    planned = %{
      id: :obs_provider,
      type: :observe,
      scenario_id: :leo_1,
      status: "In Progress",
      source_window_id: :"visibility:obs_provider",
      metadata: %{
        timeline_id: :"timeline:obs_provider",
        source_window_id: :"visibility:obs_provider"
      }
    }

    realized = %{
      id: :obs_provider,
      type: :observe,
      scenario_id: :leo_1,
      status: "succeeded",
      metadata: %{timeline_id: :"timeline:obs_provider"}
    }

    OrbitalDynamics.timeline_activity_status_state(planned, realized)
  end

  defp timeline_activity_lifecycle_state_fixture_observations do
    "timeline_activity_lifecycle_state.v1"
    |> Validation.artifact_observations(timeline_activity_lifecycle_state_fixture())
  end

  defp timeline_activity_lifecycle_state_fixture do
    read_json!("study_results/timeline_activity_lifecycle_state_v1.json")
  end

  defp generated_timeline_activity_lifecycle_state_fixture do
    planned = %{
      id: :cmd_provider,
      type: :command,
      scenario_id: :leo_1,
      status: "In Progress",
      approval_status: "Review Required",
      command_window_id: :"command_window:cmd_provider",
      command_window_type: :command_window,
      source_window_id: :"command:cmd_provider",
      metadata: %{
        timeline_id: :"timeline:cmd_provider",
        source_window_id: :"command:cmd_provider"
      }
    }

    realized = %{
      id: :cmd_provider,
      type: :command,
      scenario_id: :leo_1,
      status: "succeeded",
      approval_status: :approved,
      command_window_id: :"command_window:cmd_provider",
      command_window_type: :command_window,
      metadata: %{timeline_id: :"timeline:cmd_provider"}
    }

    OrbitalDynamics.timeline_activity_lifecycle_state(planned, realized)
  end

  defp timeline_lifecycle_state_summary_fixture_observations do
    "timeline_lifecycle_state_summary.v1"
    |> Validation.artifact_observations(timeline_lifecycle_state_summary_fixture())
  end

  defp timeline_lifecycle_state_summary_fixture do
    read_json!("study_results/timeline_lifecycle_state_summary_v1.json")
  end

  defp generated_timeline_lifecycle_state_summary_fixture do
    planned = [
      %{
        id: :cmd_provider,
        type: :command,
        scenario_id: :leo_1,
        status: "In Progress",
        approval_status: "Review Required",
        command_window_id: :"command_window:cmd_provider",
        command_window_type: :command_window,
        metadata: %{timeline_id: :"timeline:cmd_provider"}
      },
      %{
        id: :obs_record,
        type: :observe,
        status: :planned,
        approval_status: :not_required,
        metadata: %{timeline_id: :"timeline:obs_record"}
      },
      %{
        id: :done_keep,
        type: :command,
        status: :completed,
        approval_status: :approved,
        command_window_id: :"command_window:done_keep",
        command_window_type: :command_window,
        metadata: %{timeline_id: :"timeline:done_keep"}
      },
      %{
        id: :dup_a,
        type: :observe,
        status: :planned,
        metadata: %{timeline_id: :"timeline:dup"}
      },
      %{
        id: :dup_b,
        type: :observe,
        status: :planned,
        metadata: %{timeline_id: :"timeline:dup"}
      }
    ]

    realized = [
      %{
        id: :cmd_provider,
        type: :command,
        scenario_id: :leo_1,
        status: "succeeded",
        approval_status: :approved,
        command_window_id: :"command_window:cmd_provider",
        command_window_type: :command_window,
        metadata: %{timeline_id: :"timeline:cmd_provider"}
      },
      %{
        id: :obs_record,
        type: :observe,
        status: :completed,
        approval_status: :not_required,
        metadata: %{timeline_id: :"timeline:obs_record"}
      },
      %{
        id: :done_keep,
        type: :command,
        status: :completed,
        approval_status: :approved,
        command_window_id: :"command_window:done_keep",
        command_window_type: :command_window,
        metadata: %{timeline_id: :"timeline:done_keep"}
      }
    ]

    OrbitalDynamics.timeline_lifecycle_state_summary(
      planned,
      realized,
      source: "validation.timeline_lifecycle_state_summary"
    )
  end

  defp timeline_preservation_report_fixture_observations do
    "timeline_preservation_report.v1"
    |> Validation.artifact_observations(timeline_preservation_report_fixture())
  end

  defp timeline_preservation_report_fixture do
    read_json!("study_results/timeline_preservation_report_v1.json")
  end

  defp timeline_preservation_status_fixture_observations do
    "timeline_preservation_status.v1"
    |> Validation.artifact_observations(timeline_preservation_status_fixture())
  end

  defp timeline_preservation_status_fixture do
    read_json!("study_results/timeline_preservation_status_v1.json")
  end

  defp timeline_dependency_impact_summary_fixture_observations do
    "timeline_dependency_impact_summary.v1"
    |> Validation.artifact_observations(timeline_dependency_impact_summary_fixture())
  end

  defp timeline_dependency_impact_summary_fixture do
    read_json!("study_results/timeline_dependency_impact_summary_v1.json")
  end

  defp timeline_feedback_report_fixture_observations do
    "timeline_feedback_report.v1"
    |> Validation.artifact_observations(timeline_feedback_report_fixture())
  end

  defp timeline_feedback_report_fixture do
    read_json!("study_results/timeline_feedback_report_v1.json")
  end

  defp timeline_integrity_report_fixture_observations do
    "timeline_integrity_report.v1"
    |> Validation.artifact_observations(timeline_integrity_report_fixture())
  end

  defp timeline_integrity_report_fixture do
    read_json!("study_results/timeline_integrity_report_v1.json")
  end

  defp generated_timeline_integrity_report_fixture do
    [
      %{
        id: :health_gate,
        type: :health_check,
        starts_at_s: 0.0,
        ends_at_s: 15.0,
        ground_station_id: :dss_14,
        direction: :command
      },
      %{
        id: :cmd_main,
        type: :command,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        ground_station_id: :dss_14,
        direction: :command,
        dependencies: [:health_gate, :missing_gate],
        exclusive_with: [:dl_conflict]
      },
      %{
        id: :dl_conflict,
        type: :downlink,
        starts_at_s: 12.0,
        ends_at_s: 22.0,
        ground_station_id: :dss_14,
        direction: :downlink
      }
    ]
    |> OrbitalDynamics.timeline_integrity_report()
  end

  defp timeline_transition_application_report_fixture_observations do
    "timeline_transition_application_report.v1"
    |> Validation.artifact_observations(timeline_transition_application_report_fixture())
  end

  defp timeline_transition_application_report_fixture do
    read_json!("study_results/timeline_transition_application_report_v1.json")
  end

  defp timeline_transition_application_selected_integrity_fixture_observations do
    "timeline_transition_application_report.v1"
    |> Validation.artifact_observations(
      timeline_transition_application_selected_integrity_fixture()
    )
  end

  defp timeline_transition_application_selected_integrity_fixture do
    read_json!("study_results/timeline_transition_application_selected_integrity_v1.json")
  end

  defp timeline_transition_application_selected_integrity_summary_fixture_observations do
    "timeline_transition_application_summary.v1"
    |> Validation.artifact_observations(
      timeline_transition_application_selected_integrity_summary_fixture()
    )
  end

  defp timeline_transition_application_selected_integrity_summary_fixture do
    read_json!("study_results/timeline_transition_application_selected_integrity_summary_v1.json")
  end

  defp timeline_transition_application_summary_fixture_observations do
    "timeline_transition_application_summary.v1"
    |> Validation.artifact_observations(timeline_transition_application_summary_fixture())
  end

  defp timeline_transition_application_summary_fixture do
    read_json!("study_results/timeline_transition_application_summary_v1.json")
  end

  defp cadence_import_manifest_fixture_observations do
    "cadence_import_manifest.v1"
    |> Validation.artifact_observations(cadence_import_manifest_fixture())
  end

  defp cadence_import_manifest_fixture do
    read_json!("study_results/cadence_import_manifest_v1.json")
  end

  defp cadence_import_resource_projection_battery_handoff_fixture_observations do
    "cadence_import_manifest.v1"
    |> Validation.artifact_observations(
      cadence_import_resource_projection_battery_handoff_fixture()
    )
  end

  defp cadence_import_resource_projection_battery_handoff_fixture do
    read_json!("study_results/cadence_import_resource_projection_battery_handoff_v1.json")
  end

  defp cadence_import_resource_pressure_fixture_observations do
    "cadence_import_manifest.v1"
    |> Validation.artifact_observations(cadence_import_resource_pressure_fixture())
  end

  defp cadence_import_resource_pressure_fixture do
    read_json!("study_results/cadence_import_resource_pressure_v1.json")
  end

  defp command_window_report_fixture_observations do
    "command_window_report.v1"
    |> Validation.artifact_observations(command_window_report_fixture())
  end

  defp command_window_report_fixture do
    read_json!("study_results/command_window_report_v1.json")
  end

  defp constraint_report_fixture_observations do
    "constraint_report.v1"
    |> Validation.artifact_observations(constraint_report_fixture())
  end

  defp constraint_report_fixture do
    read_json!("study_results/constraint_report_v1.json")
  end

  defp operational_timeline_report_fixture_observations do
    "operational_timeline_report.v1"
    |> Validation.artifact_observations(operational_timeline_report_fixture())
  end

  defp operational_timeline_report_fixture do
    read_json!("study_results/operational_timeline_report_v1.json")
  end

  defp generated_operational_timeline_report_fixture do
    [
      %{
        id: :health_1,
        type: :health_check,
        scenario_id: :leo_1,
        starts_at_s: 20.0,
        ends_at_s: 35.0,
        approval_status: :approved,
        source_window_id: :health_window_1
      },
      %{
        id: :cmd_1,
        type: :command,
        scenario_id: :leo_1,
        ground_station_id: :dss_14,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        dependencies: [:health_1, :ops_gate],
        exclusive_with_activity_ids: [:dl_1],
        exclusivity_group: :station_dss_14_ops,
        approval_status: :pending,
        cadence_import: %{activity_type: :command_window},
        direction: :command,
        source_window_id: :cmd_window_1
      },
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :dss_14,
        starts_at_s: 35.0,
        ends_at_s: 60.0,
        approval_status: :approved,
        direction: :downlink,
        exclusivity_group: :station_dss_14_ops
      }
    ]
    |> OrbitalDynamics.operational_timeline_report(
      source: "mission_plan.activities",
      validate_missing_dependencies?: true
    )
  end

  defp contact_allocation_report_fixture_observations do
    "contact_allocation_report.v1"
    |> Validation.artifact_observations(contact_allocation_report_fixture())
  end

  defp contact_allocation_report_fixture do
    read_json!("study_results/contact_allocation_report_v1.json")
  end

  defp contact_allocation_summary_fixture_observations do
    "contact_allocation_summary.v1"
    |> Validation.artifact_observations(
      read_json!("study_results/contact_allocation_summary_v1.json")
    )
  end

  defp contact_allocation_capacity_pack_summary_fixture_observations do
    "contact_allocation_capacity_pack_summary.v1"
    |> Validation.artifact_observations(
      read_json!("study_results/contact_allocation_capacity_pack_summary_v1.json")
    )
  end

  defp contact_allocation_reservation_conflict_summary_fixture_observations do
    "contact_allocation_reservation_conflict_summary.v1"
    |> Validation.artifact_observations(
      read_json!("study_results/contact_allocation_reservation_conflict_summary_v1.json")
    )
  end

  defp contact_allocation_station_pressure_summary_fixture_observations do
    "contact_allocation_station_pressure_summary.v1"
    |> Validation.artifact_observations(
      read_json!("study_results/contact_allocation_station_pressure_summary_v1.json")
    )
  end

  defp contact_allocation_provider_reservation_request_summary_fixture_observations do
    "contact_allocation_provider_reservation_request_summary.v1"
    |> Validation.artifact_observations(
      contact_allocation_provider_reservation_request_summary_fixture()
    )
  end

  defp contact_allocation_provider_reservation_request_summary_fixture do
    read_json!("study_results/contact_allocation_provider_reservation_request_summary_v1.json")
  end

  defp contact_allocation_capacity_pack_report_fixture_observations do
    "contact_allocation_report.v1"
    |> Validation.artifact_observations(contact_allocation_capacity_pack_report_fixture())
  end

  defp contact_allocation_capacity_pack_report_fixture do
    read_json!("study_results/contact_allocation_capacity_pack_report_v1.json")
  end

  defp contact_filter_report_fixture_observations do
    "contact_filter_report.v1"
    |> Validation.artifact_observations(contact_filter_report_fixture())
  end

  defp contact_filter_report_fixture do
    read_json!("study_results/contact_filter_report_v1.json")
  end

  defp contact_contention_report_fixture_observations do
    "contact_contention_report.v1"
    |> Validation.artifact_observations(contact_contention_report_fixture())
  end

  defp contact_contention_report_fixture do
    read_json!("study_results/contact_contention_report_v1.json")
  end

  defp contact_contention_cross_station_fixture_observations do
    "contact_contention_report.v1"
    |> Validation.artifact_observations(contact_contention_cross_station_fixture())
  end

  defp contact_contention_cross_station_fixture do
    [
      %{
        id: :dl_equator,
        type: :downlink,
        scenario_id: :leo_1,
        spacecraft_id: :sat_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        score: 8.0
      },
      %{
        id: :dl_dsn,
        type: :downlink,
        scenario_id: :leo_1,
        spacecraft_id: :sat_1,
        ground_station_id: :deep_space_net,
        starts_at_s: 120.0,
        ends_at_s: 170.0,
        score: 10.0
      },
      %{
        id: :dl_other_spacecraft,
        type: :downlink,
        scenario_id: :leo_1,
        spacecraft_id: :sat_2,
        ground_station_id: :polar_aux,
        starts_at_s: 125.0,
        ends_at_s: 155.0,
        score: 7.0
      }
    ]
    |> ContactContention.report(source: "generated_cross_station_spacecraft_contention_fixture")
  end

  defp contact_contention_resolution_report_fixture_observations do
    "contact_contention_resolution_report.v1"
    |> Validation.artifact_observations(contact_contention_resolution_report_fixture())
  end

  defp contact_contention_resolution_report_fixture do
    read_json!("study_results/contact_contention_resolution_report_v1.json")
  end

  defp contact_contention_resolution_summary_fixture_observations do
    "contact_contention_resolution_summary.v1"
    |> Validation.artifact_observations(contact_contention_resolution_summary_fixture())
  end

  defp contact_contention_resolution_summary_fixture do
    read_json!("study_results/contact_contention_resolution_summary_v1.json")
  end

  defp link_capacity_report_fixture_observations do
    "link_capacity_report.v1"
    |> Validation.artifact_observations(link_capacity_report_fixture())
  end

  defp link_capacity_report_fixture do
    read_json!("study_results/link_capacity_report_v1.json")
  end

  defp link_capacity_summary_fixture_observations do
    "link_capacity_summary.v1"
    |> Validation.artifact_observations(link_capacity_summary_fixture())
  end

  defp link_capacity_summary_fixture do
    read_json!("study_results/link_capacity_summary_v1.json")
  end

  defp relay_data_path_summary_fixture_observations do
    "relay_data_path_summary.v1"
    |> Validation.artifact_observations(relay_data_path_summary_fixture())
  end

  defp relay_data_path_summary_fixture do
    read_json!("study_results/relay_data_path_summary_v1.json")
  end

  defp maneuver_review_report_fixture_observations do
    "maneuver_review_report.v1"
    |> Validation.artifact_observations(maneuver_review_report_fixture())
  end

  defp maneuver_review_report_fixture do
    read_json!("study_results/maneuver_review_report_v1.json")
  end

  defp monte_carlo_reproducibility_report_fixture_observations do
    "monte_carlo_reproducibility_report.v1"
    |> Validation.artifact_observations(monte_carlo_reproducibility_report_fixture())
  end

  defp monte_carlo_reproducibility_report_fixture do
    read_json!("study_results/monte_carlo_reproducibility_report_v1.json")
  end

  defp pareto_frontier_report_fixture_observations do
    "pareto_frontier_report.v1"
    |> Validation.artifact_observations(pareto_frontier_report_fixture())
  end

  defp pareto_frontier_report_fixture do
    read_json!("study_results/pareto_frontier_report_v1.json")
  end

  defp resource_projection_report_fixture_observations do
    "resource_projection_report.v1"
    |> Validation.artifact_observations(resource_projection_report_fixture())
  end

  defp resource_projection_report_fixture do
    read_json!("study_results/resource_projection_report_v1.json")
  end

  defp resource_projection_flow_summary_fixture_observations do
    "resource_projection_flow_summary.v1"
    |> Validation.artifact_observations(resource_projection_flow_summary_fixture())
  end

  defp resource_projection_flow_summary_fixture do
    read_json!("study_results/resource_projection_flow_summary_v1.json")
  end

  defp resource_projection_battery_handoff_fixture_observations do
    "resource_projection_report.v1"
    |> Validation.artifact_observations(resource_projection_battery_handoff_fixture())
  end

  defp resource_projection_battery_handoff_fixture do
    read_json!("study_results/resource_projection_battery_handoff_v1.json")
  end

  defp resource_projection_stale_margin_fixture_observations do
    "resource_projection_report.v1"
    |> Validation.artifact_observations(resource_projection_stale_margin_fixture())
  end

  defp resource_projection_stale_margin_fixture do
    ResourceProjection.report(
      [
        %{
          id: :obs_1,
          type: :observe,
          scenario_id: :leo_1,
          starts_at_s: 10.0,
          estimated_storage_mb: 20.0
        }
      ],
      [
        %{
          spacecraft_id: :leo_1,
          storage_capacity_mb: 100.0,
          storage_used_mb: 10.0,
          battery_capacity_wh: 100.0,
          battery_energy_used_wh: 20.0
        },
        %{
          spacecraft_id: :leo_2,
          battery_capacity_wh: 100.0,
          battery_energy_used_wh: 20.0,
          battery_state_of_charge: 0.7
        },
        %{
          spacecraft_id: :leo_3,
          storage_capacity_mb: 100.0,
          storage_used_mb: 10.0,
          storage_margin: 0.75
        }
      ],
      model: "thin_stale_derived_margin_resource_projection_fixture",
      source: "generated_resource_projection_stale_derived_margin_fixture",
      approval_policy: %{policy_bundle_id: "resource_projection_authority_v1"}
    )
  end

  defp resource_summary_fixture_observations do
    "resource_summary.v1"
    |> Validation.artifact_observations(resource_summary_fixture())
  end

  defp resource_summary_fixture do
    read_json!("study_results/resource_summary_v1.json")
  end

  defp resource_filter_report_fixture_observations do
    "resource_filter_report.v1"
    |> Validation.artifact_observations(resource_filter_report_fixture())
  end

  defp resource_filter_report_fixture do
    read_json!("study_results/resource_filter_report_v1.json")
  end

  defp resource_filter_summary_fixture_observations do
    "resource_filter_summary.v1"
    |> Validation.artifact_observations(resource_filter_summary_fixture())
  end

  defp resource_filter_summary_fixture do
    read_json!("study_results/resource_filter_summary_v1.json")
  end

  defp resource_filter_stale_margin_fixture_observations do
    "resource_filter_report.v1"
    |> Validation.artifact_observations(resource_filter_stale_margin_fixture())
  end

  defp resource_filter_stale_margin_fixture do
    ResourceFilter.report(
      [
        %{
          id: :obs_1,
          type: :observe,
          scenario_id: :leo_1,
          spacecraft_id: :sat_1,
          target_id: :target_alpha,
          starts_at_s: 10.0,
          ends_at_s: 20.0
        }
      ],
      [
        %{
          spacecraft_id: :sat_1,
          battery_capacity_wh: 100.0,
          battery_energy_used_wh: 20.0,
          battery_state_of_charge: 0.7
        },
        %{
          spacecraft_id: :sat_2,
          storage_capacity_mb: 100.0,
          storage_used_mb: 10.0,
          storage_margin: 0.75
        }
      ],
      approval_policy: %{policy_bundle_id: "degraded_payload_guard_v1"}
    )
  end

  defp objective_satisfaction_report_fixture_observations do
    "objective_satisfaction_report.v1"
    |> Validation.artifact_observations(objective_satisfaction_report_fixture())
  end

  defp objective_satisfaction_report_fixture do
    read_json!("study_results/objective_satisfaction_report_v1.json")
  end

  defp objective_tradeoff_report_fixture_observations do
    "objective_tradeoff_report.v1"
    |> Validation.artifact_observations(objective_tradeoff_report_fixture())
  end

  defp objective_tradeoff_report_fixture do
    read_json!("study_results/objective_tradeoff_report_v1.json")
  end

  defp score_term_report_fixture_observations do
    "score_term_report.v1"
    |> Validation.artifact_observations(score_term_report_fixture())
  end

  defp score_term_report_fixture do
    read_json!("study_results/score_term_report_v1.json")
  end

  defp campaign_plan_score_term_report_fixture do
    "study_results/leo_constellation_campaign.json"
    |> read_json!()
    |> get_in(["campaign_plan", "score_term_report"])
  end

  defp ranking_comparison_report_fixture_observations do
    "ranking_comparison_report.v1"
    |> Validation.artifact_observations(ranking_comparison_report_fixture())
  end

  defp ranking_comparison_report_fixture do
    read_json!("study_results/ranking_comparison_report_v1.json")
  end

  defp schema_validation_report_fixture_observations do
    "schema_validation_report.v1"
    |> Validation.artifact_observations(schema_validation_report_fixture())
  end

  defp schema_validation_report_fixture do
    read_json!("study_results/schema_validation_report_v1.json")
  end

  defp schema_validation_batch_report_fixture_observations do
    "schema_validation_batch_report.v1"
    |> Validation.artifact_observations(schema_validation_batch_report_fixture())
  end

  defp schema_validation_batch_report_fixture do
    read_json!("study_results/schema_validation_batch_report_v1.json")
  end

  defp schema_migration_report_fixture_observations do
    "schema_migration_report.v1"
    |> Validation.artifact_observations(schema_migration_report_fixture())
  end

  defp schema_migration_report_fixture do
    read_json!("study_results/schema_migration_report_v1.json")
  end

  defp schema_migration_future_contract_fixture_observations do
    "schema_migration_report.v1"
    |> Validation.artifact_observations(schema_migration_future_contract_fixture())
  end

  defp schema_migration_future_contract_fixture do
    Validation.schema_migration_report(
      future_contracts: [
        %{
          "schema_contract" => "campaign_plan.v2",
          "artifact_family" => "campaign_plan",
          "schema_version" => 2,
          "required_field_count" => 4,
          "optional_field_count" => 2,
          "nested_contract_count" => 1
        }
      ]
    )
  end

  defp operator_review_package_fixture_observations do
    operator_review_package_fixture()
    |> then(&Validation.artifact_observations("operator_review_package.v1", &1))
  end

  defp operator_review_package_fixture do
    read_json!("study_results/operator_review_package_v1.json")
  end

  defp operator_review_resource_projection_battery_handoff_fixture_observations do
    "study_results/operator_review_resource_projection_battery_handoff_v1.json"
    |> read_json!()
    |> then(&Validation.artifact_observations("operator_review_package.v1", &1))
  end

  defp operator_review_resource_projection_battery_handoff_fixture do
    read_json!("study_results/operator_review_resource_projection_battery_handoff_v1.json")
  end

  defp operator_review_resource_pressure_fixture_observations do
    "operator_review_package.v1"
    |> Validation.artifact_observations(operator_review_resource_pressure_fixture())
  end

  defp operator_review_resource_pressure_fixture do
    read_json!("study_results/operator_review_resource_pressure_v1.json")
  end

  defp operational_readiness_report_fixture_observations do
    "operational_readiness_report.v1"
    |> Validation.artifact_observations(operational_readiness_report_fixture())
  end

  defp operational_readiness_report_fixture do
    read_json!("study_results/operational_readiness_report_v1.json")
  end

  defp operational_readiness_resource_pressure_fixture_observations do
    "operational_readiness_report.v1"
    |> Validation.artifact_observations(operational_readiness_resource_pressure_fixture())
  end

  defp operational_readiness_resource_pressure_fixture do
    read_json!("study_results/operational_readiness_resource_pressure_v1.json")
  end

  defp operational_execution_boundary_summary_fixture_observations do
    "operational_execution_boundary_summary.v1"
    |> Validation.artifact_observations(operational_execution_boundary_summary_fixture())
  end

  defp operational_execution_boundary_summary_fixture do
    read_json!("study_results/operational_execution_boundary_summary_v1.json")
  end

  defp operational_import_eligibility_summary_fixture_observations do
    "operational_import_eligibility_summary.v1"
    |> Validation.artifact_observations(operational_import_eligibility_summary_fixture())
  end

  defp operational_import_eligibility_summary_fixture do
    read_json!("study_results/operational_import_eligibility_summary_v1.json")
  end

  defp operational_readiness_gate_summary_fixture_observations do
    "operational_readiness_gate_summary.v1"
    |> Validation.artifact_observations(operational_readiness_gate_summary_fixture())
  end

  defp operational_readiness_gate_summary_fixture do
    read_json!("study_results/operational_readiness_gate_summary_v1.json")
  end

  defp operational_quality_gate_summary_fixture_observations do
    "operational_quality_gate_summary.v1"
    |> Validation.artifact_observations(operational_quality_gate_summary_fixture())
  end

  defp operational_quality_gate_summary_fixture do
    read_json!("study_results/operational_quality_gate_summary_v1.json")
  end

  defp operational_quality_gate_import_readiness_summary_fixture_observations do
    "operational_quality_gate_import_readiness_summary.v1"
    |> Validation.artifact_observations(
      operational_quality_gate_import_readiness_summary_fixture()
    )
  end

  defp operational_quality_gate_import_readiness_summary_fixture do
    read_json!("study_results/operational_quality_gate_import_readiness_summary_v1.json")
  end

  defp operational_quality_gate_unavailable_resource_summary_fixture_observations do
    "operational_quality_gate_unavailable_resource_summary.v1"
    |> Validation.artifact_observations(
      operational_quality_gate_unavailable_resource_summary_fixture()
    )
  end

  defp operational_quality_gate_unavailable_resource_summary_fixture do
    review_source = %{
      "schema_contract" => "operator_review_package.v1",
      "source_artifact_type" => "contact_allocation_report.v1",
      "package_id" => "validation_unavailable_resource_fixture",
      "rows" => [
        %{
          "id" => "operator_review:contact_allocation:dl_resource_blocked",
          "review_type" => "contact_allocation_review",
          "approval_status" => "operator_review_required",
          "source_contact_allocation" => %{
            "contact_id" => "dl_resource_blocked",
            "type" => "downlink",
            "spacecraft_id" => "leo_1",
            "ground_station_id" => "equator_prime",
            "starts_at_s" => 620.0,
            "ends_at_s" => 680.0,
            "allocation_status" => "blocked",
            "allocation_reason" => "antenna_unavailable",
            "source_resource_suppression" => %{
              "id" => "dl_resource_blocked",
              "type" => "downlink",
              "spacecraft_id" => "leo_1",
              "suppressed_reason" => "antenna_unavailable",
              "resource_blocking_dimension" => "antenna",
              "antenna_available" => false,
              "resource_source_quality" => "operator_supplied",
              "resource_trust_boundary_status" => "declared"
            }
          }
        }
      ]
    }

    review_source
    |> OperationalReadiness.report()
    |> OperationalReadiness.quality_gate_report()
    |> OrbitalDynamics.operational_quality_gate_unavailable_resource_summary()
  end

  defp operational_quality_gate_unavailable_resource_summary_checked_in_observations do
    "operational_quality_gate_unavailable_resource_summary.v1"
    |> Validation.artifact_observations(
      operational_quality_gate_unavailable_resource_summary_checked_in_fixture()
    )
  end

  defp operational_quality_gate_unavailable_resource_summary_checked_in_fixture do
    read_json!("study_results/operational_quality_gate_unavailable_resource_summary_v1.json")
  end

  defp operational_quality_gate_operator_training_summary_fixture_observations do
    "operational_quality_gate_operator_training_summary.v1"
    |> Validation.artifact_observations(
      operational_quality_gate_operator_training_summary_fixture()
    )
  end

  defp operational_quality_gate_operator_training_summary_fixture do
    read_json!("study_results/operational_quality_gate_operator_training_summary_v1.json")
  end

  defp operational_quality_gate_schema_validation_summary_fixture_observations do
    "operational_quality_gate_schema_validation_summary.v1"
    |> Validation.artifact_observations(
      operational_quality_gate_schema_validation_summary_fixture()
    )
  end

  defp operational_quality_gate_schema_validation_summary_fixture do
    read_json!("study_results/operational_quality_gate_schema_validation_summary_v1.json")
  end

  defp quality_gate_report_fixture_observations do
    "quality_gate_report.v1"
    |> Validation.artifact_observations(quality_gate_report_fixture())
  end

  defp quality_gate_report_fixture do
    operational_readiness_report_fixture()
    |> OperationalReadiness.quality_gate_report()
  end

  defp quality_gate_resource_pressure_fixture_observations do
    "quality_gate_report.v1"
    |> Validation.artifact_observations(quality_gate_resource_pressure_fixture())
  end

  defp quality_gate_resource_pressure_fixture do
    read_json!("study_results/quality_gate_resource_pressure_v1.json")
  end

  defp model_acceptance_report_fixture_observations do
    "model_acceptance_report.v1"
    |> Validation.artifact_observations(model_acceptance_report_fixture())
  end

  defp model_acceptance_report_fixture do
    Validation.model_acceptance_report(
      [
        "orbit_data.simple_json",
        "event.access_windows",
        "propagator.two_body",
        "missing.model"
      ],
      intended_use: :operational_import
    )
  end

  defp validation_safety_case_summary_fixture_observations do
    "validation_safety_case_summary.v1"
    |> Validation.artifact_observations(validation_safety_case_summary_fixture())
  end

  defp validation_safety_case_summary_fixture do
    read_json!("study_results/validation_safety_case_summary_v1.json")
  end

  defp station_calendar_report_fixture_observations do
    "station_calendar_report.v1"
    |> Validation.artifact_observations(station_calendar_report_fixture())
  end

  defp station_reservation_report_fixture_observations do
    "station_reservation_report.v1"
    |> Validation.artifact_observations(station_reservation_report_fixture())
  end

  defp station_reservation_report_fixture do
    station_calendar_report_fixture()
    |> StationCalendar.reservation_report()
  end

  defp station_reservation_review_summary_fixture_observations do
    "station_reservation_review_summary.v1"
    |> Validation.artifact_observations(station_reservation_review_summary_fixture())
  end

  defp station_reservation_review_summary_fixture do
    read_json!("study_results/station_reservation_review_summary_v1.json")
  end

  defp station_reservation_hold_summary_fixture_observations do
    "station_reservation_hold_summary.v1"
    |> Validation.artifact_observations(station_reservation_hold_summary_fixture())
  end

  defp station_reservation_hold_summary_fixture do
    read_json!("study_results/station_reservation_hold_summary_v1.json")
  end

  defp station_reservation_hold_import_readiness_summary_fixture_observations do
    "station_reservation_hold_import_readiness_summary.v1"
    |> Validation.artifact_observations(
      station_reservation_hold_import_readiness_summary_fixture()
    )
  end

  defp station_reservation_hold_import_readiness_summary_fixture do
    read_json!("study_results/station_reservation_hold_import_readiness_summary_v1.json")
  end

  defp station_calendar_precedence_summary_fixture_observations do
    "station_calendar_precedence_summary.v1"
    |> Validation.artifact_observations(station_calendar_precedence_summary_fixture())
  end

  defp station_calendar_precedence_summary_fixture do
    read_json!("study_results/station_calendar_precedence_summary_v1.json")
  end

  defp station_calendar_provider_fixture_observations do
    "station_calendar_provider.v1"
    |> Validation.artifact_observations(station_calendar_provider_fixture())
  end

  defp station_calendar_provider_fixture do
    read_json!("study_results/station_calendar_provider_v1.json")
  end

  defp checked_in_station_calendar_report_fixture_observations do
    "station_calendar_report.v1"
    |> Validation.artifact_observations(checked_in_station_calendar_report_fixture())
  end

  defp checked_in_station_calendar_report_fixture do
    read_json!("study_results/station_calendar_report_v1.json")
  end

  defp station_calendar_report_fixture do
    contacts = [
      %{
        id: :dl_hold,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 160.0
      }
    ]

    provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: :ops_calendar,
      trust_boundary: :declared_station_calendar,
      entries: [
        %{
          id: :provider_downlink_hold,
          station_id: :equator_prime,
          availability: :reservation_hold,
          directions: [:downlink],
          start_s: 100.0,
          end_s: 200.0,
          hold_id: :provider_hold_1,
          hold_expires_at_s: 95.0,
          held_by: :ops_calendar,
          hold_status: :tentative_hold
        }
      ]
    }

    StationCalendar.report(contacts, provider, source: "stale_provider_calendar")
  end

  defp provider_counteroffer_report_fixture_observations do
    "provider_counteroffer_report.v1"
    |> Validation.artifact_observations(provider_counteroffer_report_fixture())
  end

  defp provider_counteroffer_report_fixture do
    contacts = [
      %{
        id: :dl_counteroffer,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 140.0
      }
    ]

    provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: :ops_calendar,
      trust_boundary: :declared_station_calendar,
      entries: [
        %{
          id: :provider_counteroffer_window,
          station_id: :equator_prime,
          availability: :available,
          directions: [:downlink],
          start_s: 130.0,
          end_s: 170.0,
          counteroffer_id: :provider_offer_1,
          counteroffer_status: :proposed,
          counteroffer_reason_code: :provider_shifted_window,
          counteroffer_cost_delta: 125.5,
          schedule_lock_deadline_s: 150.0,
          counteroffer_start_s: 130.0,
          counteroffer_end_s: 170.0
        }
      ]
    }

    contacts
    |> StationCalendar.report(provider, source: "provider_counteroffer_fixture")
    |> StationCalendar.provider_counteroffer_report()
  end

  defp provider_counteroffer_review_summary_fixture_observations do
    "provider_counteroffer_review_summary.v1"
    |> Validation.artifact_observations(provider_counteroffer_review_summary_fixture())
  end

  defp provider_counteroffer_review_summary_fixture do
    read_json!("study_results/provider_counteroffer_review_summary_v1.json")
  end

  defp provider_counteroffer_import_readiness_summary_fixture_observations do
    "provider_counteroffer_import_readiness_summary.v1"
    |> Validation.artifact_observations(provider_counteroffer_import_readiness_summary_fixture())
  end

  defp provider_counteroffer_import_readiness_summary_fixture do
    read_json!("study_results/provider_counteroffer_import_readiness_summary_v1.json")
  end

  defp provider_counteroffer_plan_impact_summary_fixture_observations do
    "provider_counteroffer_plan_impact_summary.v1"
    |> Validation.artifact_observations(provider_counteroffer_plan_impact_summary_fixture())
  end

  defp provider_counteroffer_plan_impact_summary_fixture do
    read_json!("study_results/provider_counteroffer_plan_impact_summary_v1.json")
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
