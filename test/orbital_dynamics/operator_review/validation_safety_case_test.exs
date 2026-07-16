defmodule OrbitalDynamics.OperatorReview.ValidationSafetyCaseTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "validation safety-case summary source ids fall back through summary id generation" do
    assert %{"source_artifact_id" => "validation-safety:summary"} =
             OperatorReview.from_validation_safety_case_summary(%{
               summary_id: :"validation-safety:summary"
             })

    assert %{
             "source_artifact_id" => "validation_safety_case_summary:case:standalone:blocked:2"
           } =
             OperatorReview.from_validation_safety_case_summary(%{
               case_id: :"case:standalone",
               status: :blocked,
               evidence_count: 2
             })

    assert %{"source_artifact_id" => "validation_safety_case_summary"} =
             OperatorReview.from_validation_safety_case_summary(%{})
  end

  test "builds standalone validation safety-case review packages" do
    model_acceptance_report =
      OrbitalDynamics.validation_model_acceptance_report(["missing.model"],
        intended_use: :operational_import
      )

    schema_validation_report = %{
      "schema_contract" => "schema_validation_report.v1",
      "status" => "fail",
      "validated_contract" => "candidate_refresh.v1",
      "error_count" => 1,
      "warning_count" => 0
    }

    summary =
      OrbitalDynamics.validation_safety_case_summary(
        [model_acceptance_report, schema_validation_report],
        case_id: "case:standalone-import"
      )

    package = OperatorReview.from_validation_safety_case_summary(summary)
    assert OrbitalDynamics.operator_review_package(summary) == package

    assert %{
             "source_artifact_type" => "validation_safety_case_summary.v1",
             "source_artifact_id" => summary_id,
             "review_count" => 2,
             "validation_safety_case_review_count" => 2,
             "review_type_counts" => %{"validation_safety_case_review" => 2},
             "rows" => [
               %{
                 "review_type" => "validation_safety_case_review",
                 "source" => "validation_safety_case_summary.evidence",
                 "required_operator_action" => "review_blocked_validation_safety_case",
                 "approval_status" => "blocked_by_policy",
                 "validation_safety_case_evidence_status" => "blocked",
                 "validation_safety_case_input_contract" => "model_acceptance_report.v1"
               },
               %{
                 "review_type" => "validation_safety_case_review",
                 "source" => "validation_safety_case_summary.evidence",
                 "required_operator_action" => "review_blocked_validation_safety_case",
                 "approval_status" => "blocked_by_policy",
                 "validation_safety_case_evidence_status" => "blocked",
                 "validation_safety_case_input_contract" => "schema_validation_report.v1"
               }
             ]
           } = package

    assert summary_id == summary["summary_id"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end
end
