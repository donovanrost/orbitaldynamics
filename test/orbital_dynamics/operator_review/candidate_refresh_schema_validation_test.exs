defmodule OrbitalDynamics.OperatorReview.CandidateRefreshSchemaValidationTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema}

  test "candidate refresh source schema validation reports become operator review rows" do
    source_schema_validation_report = %{
      "schema_contract" => "schema_validation_report.v1",
      "status" => "fail",
      "validation_mode" => "artifact_file",
      "validated_contract" => "campaign_plan.v1",
      "validated_artifact_family" => "campaign_plan",
      "artifact_path" => "study_results/bad_campaign.json",
      "error_count" => 1,
      "warning_count" => 0,
      "remediation_count" => 1,
      "errors" => [
        %{
          "path" => "$.plan_id",
          "message" => "is required",
          "severity" => "error"
        }
      ],
      "remediation" => [
        %{
          "path" => "$.plan_id",
          "category" => "missing_required_field",
          "action" => "Populate this required field"
        }
      ]
    }

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:schema_validation_review:001",
      "source_schema_validation_report" => source_schema_validation_report
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:schema_validation_review:001",
             "review_count" => 1,
             "schema_validation_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "schema_validation_review",
               "source" => "candidate_refresh.source_schema_validation_report.errors",
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
               "source_validation_issue" => %{
                 "path" => "$.plan_id",
                 "message" => "is required"
               },
               "source_schema_validation_report" => ^source_schema_validation_report
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source schema validation batch reports become operator review rows" do
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
      "status" => "fail",
      "error_count" => 1,
      "warning_count" => 0,
      "reports" => [
        %{"path" => "study_results/bad_campaign.json", "report" => failing_report},
        %{"path" => "study_results/candidate_refresh_v1.json", "report" => passing_report}
      ]
    }

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:schema_validation_batch_review:001",
      "source_schema_validation_batch_report" => [batch]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:schema_validation_batch_review:001",
             "review_count" => 1,
             "schema_validation_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "schema_validation_review",
               "source" =>
                 "candidate_refresh.source_schema_validation_batch_report[0].reports[0].report.errors",
               "validated_contract" => "campaign_plan.v1",
               "artifact_path" => "study_results/bad_campaign.json",
               "issue_path" => "$.plan_id",
               "source_schema_validation_report" => %{
                 "batch_entry_path" => "study_results/bad_campaign.json"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh state-scoped schema validation reports become review and import rows" do
    report = schema_validation_report()

    batch = %{
      "schema_contract" => "schema_validation_batch_report.v1",
      "validation_mode" => "artifact_directory",
      "input_dir" => "study_results",
      "status" => "fail",
      "reports" => [
        %{"path" => "study_results/bad_campaign.json", "report" => report}
      ]
    }

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:state_schema_validation:001",
      "accepted_planning_state" => %{"source_schema_validation_report" => report},
      "mission_state" => %{"source_schema_validation_batch_report" => batch}
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:state_schema_validation:001",
             "review_count" => 2,
             "schema_validation_review_count" => 2
           } = package

    assert Enum.map(package["rows"], & &1["source"]) == [
             "candidate_refresh.accepted_planning_state.source_schema_validation_report.errors",
             "candidate_refresh.mission_state.source_schema_validation_batch_report.reports[0].report.errors"
           ]

    assert %{
             "review_type" => "schema_validation_review",
             "validated_contract" => "campaign_plan.v1",
             "issue_path" => "$.plan_id",
             "source_schema_validation_report" => %{
               "schema_contract" => "schema_validation_report.v1"
             }
           } = List.first(package["rows"])

    assert %{
             "source_schema_validation_report" => %{
               "batch_entry_path" => "study_results/bad_campaign.json"
             }
           } = List.last(package["rows"])

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:state_schema_validation:001",
             "row_count" => 2,
             "source_review_type_counts" => %{"schema_validation_review" => 2}
           } = manifest

    assert Enum.map(manifest["rows"], &get_in(&1, ["source_review_row", "source"])) == [
             "candidate_refresh.accepted_planning_state.source_schema_validation_report.errors",
             "candidate_refresh.mission_state.source_schema_validation_batch_report.reports[0].report.errors"
           ]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh schema validation containers become operator review rows" do
    operator_report = schema_validation_report()

    import_report =
      schema_validation_report()
      |> Map.put("validated_contract", "candidate_refresh.v1")
      |> Map.put("validated_artifact_family", "candidate_refresh")
      |> Map.put("artifact_path", "study_results/bad_candidate_refresh.json")

    wrapped_report =
      schema_validation_report()
      |> Map.put("validated_contract", "campaign_strategy.v3")
      |> Map.put("validated_artifact_family", "campaign_strategy")
      |> Map.put("artifact_path", "study_results/bad_strategy.json")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:schema_validation_container_review:001",
      "source_operator_review_package" =>
        OperatorReview.from_schema_validation_report(operator_report),
      "source_cadence_import_manifest" =>
        CadenceImport.from_schema_validation_report(import_report),
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "schema_validation_report" => wrapped_report
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:schema_validation_container_review:001",
             "review_count" => 3,
             "schema_validation_review_count" => 3
           } = package

    assert [
             %{
               "review_type" => "schema_validation_review",
               "source" =>
                 "candidate_refresh.source_operator_review_package.rows.source_schema_validation_report.errors",
               "validated_contract" => "campaign_plan.v1",
               "artifact_path" => "study_results/bad_campaign.json",
               "issue_path" => "$.plan_id",
               "source_schema_validation_report" => %{
                 "source" => "preserved_schema_validation_review_rows"
               }
             },
             %{
               "review_type" => "schema_validation_review",
               "source" =>
                 "candidate_refresh.source_cadence_import_manifest.rows.source_schema_validation_report.errors",
               "validated_contract" => "candidate_refresh.v1",
               "artifact_path" => "study_results/bad_candidate_refresh.json",
               "issue_path" => "$.plan_id",
               "source_schema_validation_report" => %{
                 "source" => "preserved_schema_validation_review_rows"
               }
             },
             %{
               "review_type" => "schema_validation_review",
               "source" =>
                 "candidate_refresh.source_result_artifact.schema_validation_report.errors",
               "validated_contract" => "campaign_strategy.v3",
               "artifact_path" => "study_results/bad_strategy.json",
               "issue_path" => "$.plan_id",
               "source_schema_validation_report" => ^wrapped_report
             }
           ] = package["rows"]

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
