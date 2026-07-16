defmodule OrbitalDynamics.OperatorReview.CandidateRefreshModelAcceptanceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema}

  test "candidate refresh source model acceptance reports become operator review rows" do
    report =
      OrbitalDynamics.validation_model_acceptance_report(
        ["orbit_data.simple_json", "event.access_windows", "propagator.two_body"],
        intended_use: :operational_import
      )

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_model_acceptance_review:001",
      "source_model_acceptance_report" => [report]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_model_acceptance_review:001",
             "review_count" => 2,
             "model_acceptance_review_count" => 2
           } = package

    assert [
             %{
               "review_type" => "model_acceptance_review",
               "source" => "candidate_refresh.source_model_acceptance_report[0].rows",
               "subject_id" => "event.access_windows",
               "required_operator_action" => "review_model_acceptance",
               "approval_status" => "operator_review_required",
               "model_acceptance_status" => "review_required",
               "model_acceptance_intended_use" => "operational_import",
               "model_acceptance_validation_level" => "analysis",
               "source_model_acceptance_row" => %{
                 "model_id" => "event.access_windows",
                 "status" => "review_required"
               },
               "source_model_acceptance_report" => %{
                 "schema_contract" => "model_acceptance_report.v1",
                 "status" => "blocked",
                 "review_required_count" => 1,
                 "blocked_count" => 1
               }
             },
             %{
               "review_type" => "model_acceptance_review",
               "source" => "candidate_refresh.source_model_acceptance_report[0].rows",
               "subject_id" => "propagator.two_body",
               "required_operator_action" => "review_blocked_model_acceptance",
               "approval_status" => "blocked_by_policy",
               "model_acceptance_status" => "blocked",
               "model_acceptance_validation_level" => "educational"
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact model acceptance reports become operator review rows" do
    report =
      OrbitalDynamics.validation_model_acceptance_report(
        ["orbit_data.simple_json", "event.access_windows", "propagator.two_body"],
        intended_use: :operational_import
      )

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_model_acceptance_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "model_acceptance_report" => report
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_model_acceptance_review:001",
             "review_count" => 2,
             "model_acceptance_review_count" => 2
           } = package

    assert [
             %{
               "review_type" => "model_acceptance_review",
               "source" =>
                 "candidate_refresh.source_result_artifact.model_acceptance_report.rows",
               "subject_id" => "event.access_windows",
               "required_operator_action" => "review_model_acceptance",
               "approval_status" => "operator_review_required",
               "model_acceptance_status" => "review_required",
               "source_model_acceptance_report" => %{
                 "schema_contract" => "model_acceptance_report.v1",
                 "status" => "blocked"
               }
             },
             %{
               "review_type" => "model_acceptance_review",
               "source" =>
                 "candidate_refresh.source_result_artifact.model_acceptance_report.rows",
               "subject_id" => "propagator.two_body",
               "required_operator_action" => "review_blocked_model_acceptance",
               "approval_status" => "blocked_by_policy",
               "model_acceptance_status" => "blocked"
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh state-scoped model acceptance reports become operator review rows" do
    report =
      OrbitalDynamics.validation_model_acceptance_report(
        ["orbit_data.simple_json", "event.access_windows", "propagator.two_body"],
        intended_use: :operational_import
      )

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:state_model_acceptance_review:001",
      "accepted_planning_state" => %{"source_model_acceptance_report" => report},
      "mission_state" => %{"model_acceptance_report" => report}
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:state_model_acceptance_review:001",
             "review_count" => 4,
             "model_acceptance_review_count" => 4
           } = package

    assert Enum.map(package["rows"], & &1["source"]) == [
             "candidate_refresh.accepted_planning_state.source_model_acceptance_report.rows",
             "candidate_refresh.accepted_planning_state.source_model_acceptance_report.rows",
             "candidate_refresh.mission_state.model_acceptance_report.rows",
             "candidate_refresh.mission_state.model_acceptance_report.rows"
           ]

    assert %{
             "review_type" => "model_acceptance_review",
             "subject_id" => "event.access_windows",
             "required_operator_action" => "review_model_acceptance",
             "approval_status" => "operator_review_required",
             "model_acceptance_status" => "review_required",
             "source_model_acceptance_report" => %{
               "schema_contract" => "model_acceptance_report.v1",
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
