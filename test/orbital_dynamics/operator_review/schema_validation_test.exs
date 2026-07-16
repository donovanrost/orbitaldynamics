defmodule OrbitalDynamics.OperatorReview.SchemaValidationTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "schema validation report source ids use generated report ids" do
    assert %{"source_artifact_id" => "schema_validation:campaign_plan.v1:artifact_file:fail"} =
             OperatorReview.from_schema_validation_report(%{
               validated_contract: :"campaign_plan.v1",
               validation_mode: :artifact_file,
               status: :fail
             })

    assert %{"source_artifact_id" => "schema_validation"} =
             OperatorReview.from_schema_validation_report(%{})
  end

  test "schema validation batch report source ids use generated batch ids" do
    assert %{
             "source_artifact_id" =>
               "schema_validation_batch:artifact_directory:study_results:fail"
           } =
             OperatorReview.from_schema_validation_batch_report(%{
               validation_mode: :artifact_directory,
               input_dir: :study_results,
               status: :fail
             })

    assert %{"source_artifact_id" => "schema_validation_batch"} =
             OperatorReview.from_schema_validation_batch_report(%{})
  end

  test "builds review package from schema validation report failures" do
    report = schema_validation_report()

    package = OperatorReview.from_schema_validation_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "schema_validation_report.v1",
             "source_artifact_id" => "schema_validation:campaign_plan.v1:artifact_file:fail",
             "review_count" => 1,
             "schema_validation_review_count" => 1
           } = package

    assert [
             %{
               "id" => id,
               "review_type" => "schema_validation_review",
               "source" => "schema_validation_report.errors",
               "subject_id" => "campaign_plan.v1",
               "required_operator_action" => "review_schema_validation",
               "action" => "review_schema_validation_failure",
               "validation_status" => "fail",
               "validation_mode" => "artifact_file",
               "validated_contract" => "campaign_plan.v1",
               "artifact_path" => "study_results/bad_campaign.json",
               "issue_severity" => "error",
               "issue_path" => "$.plan_id",
               "issue_message" => "is required",
               "remediation_category" => "missing_required_field",
               "remediation_action" => "Populate this required field",
               "source_validation_issue" => %{"path" => "$.plan_id", "message" => "is required"},
               "source_validation_remediation" => %{
                 "path" => "$.plan_id",
                 "action" => "Populate this required field"
               },
               "source_schema_validation_report" => ^report
             }
           ] = package["rows"]

    assert String.starts_with?(
             id,
             "schema_validation:campaign_plan.v1:artifact_file:path:.plan_id:"
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_status =
      update_in(package, ["rows"], fn [row] ->
        [Map.put(row, "validation_status", "pass")]
      end)

    assert {:error, invalid_source_status_report} =
             Schema.validate_artifact(invalid_source_status)

    assert Enum.any?(
             invalid_source_status_report["errors"],
             &(&1["path"] == "$.rows[0].source_schema_validation_report.status" and
                 &1["message"] == "must match validation_status")
           )
  end

  test "builds review package from schema validation batch report failures" do
    failing_report = schema_validation_report()

    passing_report = %{
      failing_report
      | "validated_contract" => "candidate_refresh.v1",
        "validated_artifact_family" => "candidate_refresh",
        "status" => "pass",
        "error_count" => 0,
        "warning_count" => 0,
        "errors" => [],
        "warnings" => [],
        "artifact_path" => "study_results/candidate_refresh_v1.json",
        "remediation_count" => 0,
        "remediation" => []
    }

    batch = %{
      "schema_contract" => "schema_validation_batch_report.v1",
      "validation_mode" => "artifact_directory",
      "input_dir" => "study_results",
      "file_count" => 2,
      "artifact_count" => 2,
      "skipped_count" => 0,
      "skipped_artifacts" => [],
      "status" => "fail",
      "error_count" => 1,
      "warning_count" => 0,
      "reports" => [
        %{"path" => "study_results/bad_campaign.json", "report" => failing_report},
        %{"path" => "study_results/candidate_refresh_v1.json", "report" => passing_report}
      ]
    }

    package = OperatorReview.from_schema_validation_batch_report(batch)

    assert OrbitalDynamics.operator_review_package(batch) == package

    assert %{
             "source_artifact_type" => "schema_validation_batch_report.v1",
             "source_artifact_id" =>
               "schema_validation_batch:artifact_directory:study_results:fail",
             "review_count" => 1,
             "schema_validation_review_count" => 1,
             "rows" => [
               %{
                 "review_type" => "schema_validation_review",
                 "source" => "schema_validation_batch_report.reports.report.errors",
                 "validated_contract" => "campaign_plan.v1",
                 "artifact_path" => "study_results/bad_campaign.json",
                 "issue_path" => "$.plan_id",
                 "source_schema_validation_report" => %{
                   "batch_entry_path" => "study_results/bad_campaign.json"
                 }
               }
             ]
           } = package

    assert {:ok, %{"schema_contract" => "schema_validation_batch_report.v1"}} =
             Schema.validate_artifact(batch)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  defp schema_validation_report do
    %{
      "schema_contract" => "schema_validation_report.v1",
      "model" => "executable_artifact_contract_validation",
      "validation_mode" => "artifact_file",
      "validated_contract" => "campaign_plan.v1",
      "validated_artifact_family" => "campaign_plan",
      "validated_schema_version" => 1,
      "status" => "fail",
      "error_count" => 1,
      "warning_count" => 0,
      "errors" => [
        %{
          "severity" => "error",
          "path" => "$.plan_id",
          "message" => "is required"
        }
      ],
      "warnings" => [],
      "artifact_path" => "study_results/bad_campaign.json",
      "remediation_count" => 1,
      "remediation" => [
        %{
          "path" => "$.plan_id",
          "category" => "missing_required_field",
          "action" => "Populate this required field",
          "source_message" => "is required"
        }
      ],
      "assumptions" => %{"validator" => "OrbitalDynamics.Schema.validate_artifact"}
    }
  end
end
