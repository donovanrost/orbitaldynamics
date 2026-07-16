defmodule OrbitalDynamics.OperatorReview.CandidateRefreshValidationSafetyCaseTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema}

  test "candidate refresh source validation safety-case summaries become operator review rows" do
    model_acceptance_report =
      OrbitalDynamics.validation_model_acceptance_report(["missing.model"],
        intended_use: :operational_import
      )

    quality_gate_report = %{
      "schema_contract" => "quality_gate_report.v1",
      "status" => "review_required",
      "readiness_level" => "operator_review",
      "import_classification" => "review_only",
      "review_gate_count" => 1,
      "blocked_gate_count" => 0
    }

    summary =
      OrbitalDynamics.validation_safety_case_summary(
        [model_acceptance_report, quality_gate_report],
        case_id: "case:branch-refresh"
      )

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_validation_safety_review:001",
      "source_validation_safety_case_summary" => [summary]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_validation_safety_review:001",
             "review_count" => 2,
             "validation_safety_case_review_count" => 2
           } = package

    assert [
             %{
               "review_type" => "validation_safety_case_review",
               "source" => "candidate_refresh.source_validation_safety_case_summary[0].evidence",
               "required_operator_action" => "review_blocked_validation_safety_case",
               "approval_status" => "blocked_by_policy",
               "validation_safety_case_evidence_status" => "blocked",
               "validation_safety_case_input_contract" => "model_acceptance_report.v1",
               "validation_safety_case_blocked_evidence_count" => 1,
               "source_validation_safety_case_evidence" => %{
                 "schema_contract" => "model_acceptance_report.v1",
                 "status" => "blocked"
               },
               "source_validation_safety_case_summary" => %{
                 "schema_contract" => "validation_safety_case_summary.v1",
                 "case_id" => "case:branch-refresh",
                 "status" => "blocked"
               }
             },
             %{
               "review_type" => "validation_safety_case_review",
               "source" => "candidate_refresh.source_validation_safety_case_summary[0].evidence",
               "required_operator_action" => "review_validation_safety_case",
               "approval_status" => "operator_review_required",
               "validation_safety_case_evidence_status" => "review_required",
               "validation_safety_case_input_contract" => "quality_gate_report.v1"
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact validation safety-case summaries become operator review rows" do
    model_acceptance_report =
      OrbitalDynamics.validation_model_acceptance_report(["missing.model"],
        intended_use: :operational_import
      )

    quality_gate_report = %{
      "schema_contract" => "quality_gate_report.v1",
      "status" => "review_required",
      "readiness_level" => "operator_review",
      "import_classification" => "review_only",
      "review_gate_count" => 1,
      "blocked_gate_count" => 0
    }

    summary =
      OrbitalDynamics.validation_safety_case_summary(
        [model_acceptance_report, quality_gate_report],
        case_id: "case:wrapped-refresh"
      )

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_validation_safety_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "validation_safety_case_summary" => summary
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_validation_safety_review:001",
             "review_count" => 2,
             "validation_safety_case_review_count" => 2
           } = package

    assert [
             %{
               "review_type" => "validation_safety_case_review",
               "source" =>
                 "candidate_refresh.source_result_artifact.validation_safety_case_summary.evidence",
               "required_operator_action" => "review_blocked_validation_safety_case",
               "approval_status" => "blocked_by_policy",
               "validation_safety_case_evidence_status" => "blocked",
               "validation_safety_case_input_contract" => "model_acceptance_report.v1",
               "source_validation_safety_case_summary" => %{
                 "schema_contract" => "validation_safety_case_summary.v1",
                 "case_id" => "case:wrapped-refresh",
                 "status" => "blocked"
               }
             },
             %{
               "review_type" => "validation_safety_case_review",
               "source" =>
                 "candidate_refresh.source_result_artifact.validation_safety_case_summary.evidence",
               "required_operator_action" => "review_validation_safety_case",
               "approval_status" => "operator_review_required",
               "validation_safety_case_evidence_status" => "review_required",
               "validation_safety_case_input_contract" => "quality_gate_report.v1"
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh state-scoped validation safety-case summaries become operator review rows" do
    model_acceptance_report =
      OrbitalDynamics.validation_model_acceptance_report(["missing.model"],
        intended_use: :operational_import
      )

    quality_gate_report = %{
      "schema_contract" => "quality_gate_report.v1",
      "status" => "review_required",
      "readiness_level" => "operator_review",
      "import_classification" => "review_only",
      "review_gate_count" => 1,
      "blocked_gate_count" => 0
    }

    summary =
      OrbitalDynamics.validation_safety_case_summary(
        [model_acceptance_report, quality_gate_report],
        case_id: "case:state-refresh"
      )

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:state_validation_safety_review:001",
      "accepted_planning_state" => %{"source_validation_safety_case_summary" => summary},
      "mission_state" => %{"validation_safety_case_summary" => summary}
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:state_validation_safety_review:001",
             "review_count" => 4,
             "validation_safety_case_review_count" => 4
           } = package

    assert Enum.map(package["rows"], & &1["source"]) == [
             "candidate_refresh.accepted_planning_state.source_validation_safety_case_summary.evidence",
             "candidate_refresh.accepted_planning_state.source_validation_safety_case_summary.evidence",
             "candidate_refresh.mission_state.validation_safety_case_summary.evidence",
             "candidate_refresh.mission_state.validation_safety_case_summary.evidence"
           ]

    assert %{
             "review_type" => "validation_safety_case_review",
             "required_operator_action" => "review_blocked_validation_safety_case",
             "approval_status" => "blocked_by_policy",
             "validation_safety_case_evidence_status" => "blocked",
             "validation_safety_case_input_contract" => "model_acceptance_report.v1",
             "source_validation_safety_case_summary" => %{
               "schema_contract" => "validation_safety_case_summary.v1",
               "case_id" => "case:state-refresh",
               "status" => "blocked"
             }
           } = List.first(package["rows"])

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert manifest["row_count"] == 0
    assert manifest["rows"] == []

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end
end
