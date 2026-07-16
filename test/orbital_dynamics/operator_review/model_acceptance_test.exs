defmodule OrbitalDynamics.OperatorReview.ModelAcceptanceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "model acceptance report source ids fall back through report id generation" do
    assert %{"source_artifact_id" => "model-acceptance:report"} =
             OperatorReview.from_model_acceptance_report(%{
               report_id: :"model-acceptance:report"
             })

    assert %{
             "source_artifact_id" =>
               "model_acceptance_report:operational_import:review_required:2"
           } =
             OperatorReview.from_model_acceptance_report(%{
               intended_use: :operational_import,
               status: :review_required,
               model_count: 2
             })

    assert %{"source_artifact_id" => "model_acceptance_report"} =
             OperatorReview.from_model_acceptance_report(%{})
  end

  test "builds standalone model acceptance review packages" do
    report =
      OrbitalDynamics.validation_model_acceptance_report(
        ["orbit_data.simple_json", "event.access_windows", "missing.model"],
        intended_use: :operational_import
      )

    package = OperatorReview.from_model_acceptance_report(report)
    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "model_acceptance_report.v1",
             "source_artifact_id" => report_id,
             "review_count" => 2,
             "model_acceptance_review_count" => 2,
             "review_type_counts" => %{"model_acceptance_review" => 2},
             "rows" => [
               %{
                 "review_type" => "model_acceptance_review",
                 "source" => "model_acceptance_report.rows",
                 "subject_id" => "event.access_windows",
                 "required_operator_action" => "review_model_acceptance",
                 "approval_status" => "operator_review_required",
                 "model_acceptance_status" => "review_required",
                 "model_acceptance_validation_level" => "analysis"
               },
               %{
                 "review_type" => "model_acceptance_review",
                 "source" => "model_acceptance_report.rows",
                 "subject_id" => "missing.model",
                 "required_operator_action" => "review_blocked_model_acceptance",
                 "approval_status" => "blocked_by_policy",
                 "model_acceptance_status" => "blocked",
                 "model_acceptance_validation_level" => "unknown"
               }
             ]
           } = package

    assert report_id == report["report_id"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end
end
