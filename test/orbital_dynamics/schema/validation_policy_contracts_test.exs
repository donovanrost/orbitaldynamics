defmodule OrbitalDynamics.Schema.ValidationPolicyContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Validation}

  test "exports and validates validation policy contracts" do
    assert {:ok, %{"schema_contract" => "validation_tolerance_policy.v1"}} =
             Validation.tolerance_policy()
             |> Schema.validate_artifact(schema_contract: "validation_tolerance_policy.v1")

    assert {:ok, %{"schema_contract" => "backend_acceptance_policy.v1"}} =
             Validation.backend_acceptance_policy()
             |> Schema.validate_artifact(schema_contract: "backend_acceptance_policy.v1")

    assert {:ok, tolerance_schema} = Schema.json_schema("validation_tolerance_policy.v1")

    assert tolerance_schema["required"] == [
             "schema_contract",
             "comparison_model",
             "event_timing",
             "artifact_regressions",
             "validation_levels"
           ]

    assert {:ok, backend_schema} = Schema.json_schema("backend_acceptance_policy.v1")

    assert backend_schema["x-orbital-dynamics"]["nested_contracts"] == [
             "validation_tolerance_policy.v1"
           ]

    report =
      Validation.model_acceptance_report(["orbit_data.simple_json", "event.access_windows"],
        intended_use: :operational_import
      )

    assert {:ok, %{"schema_contract" => "model_acceptance_report.v1"}} =
             Schema.validate_artifact(report, schema_contract: "model_acceptance_report.v1")

    assert report["status_counts"] == %{"accepted" => 1, "review_required" => 1}

    assert {:ok, model_acceptance_schema} = Schema.json_schema("model_acceptance_report.v1")

    assert model_acceptance_schema["required"] == [
             "schema_contract",
             "schema_version",
             "model",
             "report_id",
             "intended_use",
             "status",
             "model_count",
             "accepted_count",
             "review_required_count",
             "blocked_count",
             "unknown_model_count",
             "validation_level_counts",
             "records",
             "rows",
             "assumptions",
             "model_limits"
           ]

    assert model_acceptance_schema["x-orbital-dynamics"]["nested_contracts"] == [
             "validation_record.v1"
           ]

    assert get_in(model_acceptance_schema, [
             "properties",
             "status_counts",
             "propertyNames",
             "enum"
           ]) ==
             ["accepted", "review_required", "blocked"]

    assert get_in(model_acceptance_schema, [
             "properties",
             "status_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    safety_case_summary =
      Validation.safety_case_summary(
        [
          Validation.model_acceptance_report(["orbit_data.simple_json", "event.access_windows"],
            intended_use: :operational_import
          ),
          %{
            "schema_contract" => "schema_validation_report.v1",
            "status" => "pass",
            "validated_contract" => "candidate_refresh.v1",
            "error_count" => 0,
            "warning_count" => 0
          }
        ],
        case_id: "case:schema-export"
      )

    assert {:ok, %{"schema_contract" => "validation_safety_case_summary.v1"}} =
             Schema.validate_artifact(safety_case_summary,
               schema_contract: "validation_safety_case_summary.v1"
             )

    invalid_summary = Map.put(safety_case_summary, "evidence_count", 99)

    assert {:error, validation_report} =
             Schema.validate_artifact(invalid_summary,
               schema_contract: "validation_safety_case_summary.v1"
             )

    assert Enum.any?(validation_report["errors"], &(&1["path"] == "$.evidence_count"))

    checked_in_summary = read_json!("study_results/validation_safety_case_summary_v1.json")

    schema_validation_pass = %{
      "schema_contract" => "schema_validation_report.v1",
      "status" => "pass",
      "validated_contract" => "candidate_refresh.v1",
      "error_count" => 0,
      "warning_count" => 0
    }

    schema_validation_fail = %{
      "schema_contract" => "schema_validation_report.v1",
      "status" => "fail",
      "validated_contract" => "candidate_refresh.v1",
      "error_count" => 1,
      "warning_count" => 0
    }

    checked_in_evidence = [
      Validation.model_acceptance_report(["orbit_data.simple_json", "event.access_windows"],
        intended_use: :operational_import
      ),
      schema_validation_pass,
      schema_validation_fail,
      schema_validation_fail
    ]

    generated_checked_in_summary =
      OrbitalDynamics.validation_safety_case_summary(checked_in_evidence,
        case_id: "case:compatibility-example"
      )

    assert generated_checked_in_summary == checked_in_summary

    assert {:ok, %{"schema_contract" => "validation_safety_case_summary.v1"}} =
             Schema.validate_artifact(checked_in_summary,
               schema_contract: "validation_safety_case_summary.v1"
             )

    assert %{
             "schema_contract" => "validation_safety_case_summary.v1",
             "schema_version" => 1,
             "model" => "artifact_only_validation_safety_case_summary",
             "source" => "validation.safety_case_evidence",
             "summary_id" => "validation_safety_case:case:compatibility-example",
             "case_id" => "case:compatibility-example",
             "status" => "blocked",
             "evidence_count" => 4,
             "input_contracts" => [
               "model_acceptance_report.v1",
               "schema_validation_report.v1"
             ],
             "evidence_status_counts" => %{
               "accepted_for_use" => 1,
               "blocked" => 2,
               "review_required" => 1
             },
             "blocked_evidence_count" => 2,
             "review_required_evidence_count" => 1,
             "accepted_evidence_count" => 1,
             "model_accepted_count" => 1,
             "model_review_required_count" => 1,
             "model_blocked_count" => 0,
             "unknown_model_count" => 0,
             "schema_error_count" => 2,
             "schema_warning_count" => 0,
             "schema_validation_report_count" => 0,
             "schema_validation_failed_report_count" => 0,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_cadence_write",
               "certification_authority" => "not_granted_by_summary",
               "operator_authority" => "not_granted_by_summary"
             }
           } = checked_in_summary

    assert checked_in_summary["evidence_refs_by_status"] == %{
             "accepted_for_use" => ["schema_validation_report.v1:candidate_refresh.v1"],
             "blocked" => [
               "schema_validation_report.v1:candidate_refresh.v1",
               "schema_validation_report.v1:candidate_refresh.v1"
             ],
             "review_required" => [
               "model_acceptance_report.v1:model_acceptance:operational_import:orbit_data.simple_json__event.access_windows"
             ]
           }

    assert checked_in_summary["evidence_refs_by_contract"] == %{
             "model_acceptance_report.v1" => [
               "model_acceptance_report.v1:model_acceptance:operational_import:orbit_data.simple_json__event.access_windows"
             ],
             "schema_validation_report.v1" => [
               "schema_validation_report.v1:candidate_refresh.v1",
               "schema_validation_report.v1:candidate_refresh.v1",
               "schema_validation_report.v1:candidate_refresh.v1"
             ]
           }

    assert Enum.map(checked_in_summary["evidence"], & &1["rank"]) == [1, 2, 3, 4]

    assert checked_in_summary["model_limits"] == [
             "acceptance is evidence-based and not flight certification",
             "unknown models are blocked until registered validation evidence exists",
             "operational import acceptance remains artifact-only and requires downstream operator policy"
           ]

    assert {:ok, safety_case_schema} = Schema.json_schema("validation_safety_case_summary.v1")

    assert safety_case_schema["required"] == [
             "schema_contract",
             "schema_version",
             "model",
             "source",
             "summary_id",
             "status",
             "evidence_count",
             "blocked_evidence_count",
             "review_required_evidence_count",
             "accepted_evidence_count",
             "assumptions",
             "model_limits"
           ]

    assert safety_case_schema["x-orbital-dynamics"]["nested_contracts"] == [
             "model_acceptance_report.v1",
             "operational_readiness_report.v1",
             "quality_gate_report.v1",
             "schema_validation_report.v1",
             "schema_validation_batch_report.v1",
             "validation_reference_fixture_report.v1"
           ]

    migration_report =
      Validation.schema_migration_report(
        deprecated_contracts: %{"campaign_plan.v1" => "campaign_strategy.v3"}
      )

    assert {:ok, %{"schema_contract" => "schema_migration_report.v1"}} =
             Schema.validate_artifact(migration_report,
               schema_contract: "schema_migration_report.v1"
             )

    assert migration_report["status"] == "review_required"
    assert migration_report["deprecated_contract_count"] == 1
    assert migration_report["status_counts"] == %{"current" => 127, "deprecated" => 1}

    stale_migration_model =
      Map.put(migration_report, "model", "stale_schema_migration_report_model")

    assert {:error, stale_migration_model_report} =
             Schema.validate_artifact(stale_migration_model,
               schema_contract: "schema_migration_report.v1"
             )

    assert Enum.any?(
             stale_migration_model_report["errors"],
             &(&1["path"] == "$.model")
           )

    stale_migration_count = Map.put(migration_report, "migration_row_count", 80)

    assert {:error, stale_migration_count_report} =
             Schema.validate_artifact(stale_migration_count,
               schema_contract: "schema_migration_report.v1"
             )

    assert Enum.any?(
             stale_migration_count_report["errors"],
             &(&1["path"] == "$.migration_row_count")
           )

    stale_migration_actions =
      put_in(migration_report, ["migration_action_counts", "plan_replacement"], 0)

    assert {:error, stale_migration_actions_report} =
             Schema.validate_artifact(stale_migration_actions,
               schema_contract: "schema_migration_report.v1"
             )

    assert Enum.any?(
             stale_migration_actions_report["errors"],
             &(&1["path"] == "$.migration_action_counts")
           )

    stale_row_action =
      put_in(
        migration_report,
        ["rows", Access.at(0), "migration_action"],
        "silently_rewrite_contract"
      )

    assert {:error, stale_row_action_report} =
             Schema.validate_artifact(stale_row_action,
               schema_contract: "schema_migration_report.v1"
             )

    assert Enum.any?(
             stale_row_action_report["errors"],
             &(&1["path"] == "$.rows[0].migration_action")
           )

    assert {:ok, migration_schema} = Schema.json_schema("schema_migration_report.v1")

    assert get_in(migration_schema, ["properties", "model", "const"]) ==
             "executable_schema_migration_and_deprecation_report"

    assert migration_schema["required"] == [
             "schema_contract",
             "schema_version",
             "model",
             "source",
             "status",
             "compatibility_policy_version",
             "compatible_change_rule_count",
             "breaking_change_rule_count",
             "contract_count",
             "current_contract_count",
             "deprecated_contract_count",
             "future_contract_count",
             "migration_row_count",
             "deprecation_warning_count",
             "status_counts",
             "migration_action_counts",
             "rows",
             "assumptions",
             "model_limits"
           ]

    assert get_in(migration_schema, ["properties", "rows", "items", "required"]) == [
             "schema_contract",
             "artifact_family",
             "schema_version",
             "status",
             "migration_action",
             "required_field_count",
             "optional_field_count",
             "nested_contract_count"
           ]

    assert get_in(migration_schema, [
             "properties",
             "rows",
             "items",
             "properties",
             "migration_action",
             "enum"
           ]) == Validation.capabilities().schema_migration_actions
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
