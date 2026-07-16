defmodule OrbitalDynamics.OperatorReview.CandidateRefreshOperationalReadinessTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "candidate refresh result artifact operational readiness reports become operator review rows" do
    report =
      operational_readiness_resource_report()
      |> Map.put("report_id", "operational_readiness:wrapped_resource_pressure")
      |> Map.put("source_artifact_id", "candidate_refresh:wrapped_operational_readiness:001")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_operational_readiness:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "operational_readiness_report" => report
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_operational_readiness:001",
             "review_count" => 2,
             "operational_readiness_review_count" => 2
           } = package

    assert %{
             "review_type" => "operational_readiness_review",
             "source" => "candidate_refresh.source_result_artifact.operational_readiness_report",
             "subject_id" => "operational_readiness:wrapped_resource_pressure",
             "required_operator_action" => "review_operational_readiness",
             "operational_readiness_status" => "review_required",
             "resource_availability_pressure_count" => 3,
             "source_operational_readiness_report" => %{
               "report_id" => "operational_readiness:wrapped_resource_pressure"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["subject_id"] == "operational_readiness:wrapped_resource_pressure")
             )

    assert %{
             "review_type" => "operational_readiness_review",
             "source" =>
               "candidate_refresh.source_result_artifact.operational_readiness_report.gates",
             "readiness_gate_id" => "resource_availability",
             "required_operator_action" => "review_operational_readiness",
             "resource_availability_pressure_count" => 3
           } = Enum.find(package["rows"], &(&1["readiness_gate_id"] == "resource_availability"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh operational readiness summaries become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:operational_readiness_summaries:001",
      "source_operational_import_eligibility_summary" =>
        study_result_fixture("operational_import_eligibility_summary_v1.json"),
      "source_operational_readiness_gate_summary" =>
        study_result_fixture("operational_readiness_gate_summary_v1.json"),
      "source_operational_execution_boundary_summary" =>
        study_result_fixture("operational_execution_boundary_summary_v1.json")
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:operational_readiness_summaries:001",
             "review_count" => 3,
             "operational_readiness_review_count" => 3
           } = package

    assert %{
             "review_type" => "operational_readiness_review",
             "source" => "candidate_refresh.source_operational_import_eligibility_summary",
             "subject_id" => "activity_1",
             "required_operator_action" => "record_operational_readiness_importable",
             "cadence_import_status" => "present",
             "source_operational_readiness_report" => %{
               "schema_contract" => "operational_import_eligibility_summary.v1",
               "source_summary_schema_contract" => "operational_import_eligibility_summary.v1",
               "source_summary_model" => "artifact_only_import_eligibility_summary"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] == "candidate_refresh.source_operational_import_eligibility_summary")
             )

    assert %{
             "review_type" => "operational_readiness_review",
             "source" => "candidate_refresh.source_operational_readiness_gate_summary",
             "gate_count" => 5,
             "passed_gate_count" => 5,
             "source_operational_readiness_report" => %{
               "schema_contract" => "operational_readiness_gate_summary.v1",
               "source_summary_schema_contract" => "operational_readiness_gate_summary.v1",
               "gates" => [%{"id" => "source_contract"} | _]
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] == "candidate_refresh.source_operational_readiness_gate_summary")
             )

    assert %{
             "review_type" => "operational_readiness_review",
             "source" => "candidate_refresh.source_operational_execution_boundary_summary",
             "source_operational_readiness_report" => %{
               "schema_contract" => "operational_execution_boundary_summary.v1",
               "source_summary_schema_contract" => "operational_execution_boundary_summary.v1",
               "assumptions" => %{
                 "command_execution" => "not_performed_by_summary"
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_operational_execution_boundary_summary")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact operational readiness summaries become review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_operational_readiness_summaries:001",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "source_operational_readiness_gate_summary" =>
            study_result_fixture("operational_readiness_gate_summary_v1.json"),
          "operational_execution_boundary_summary" =>
            study_result_fixture("operational_execution_boundary_summary_v1.json")
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:wrapped_operational_readiness_summaries:001",
             "review_count" => 2,
             "operational_readiness_review_count" => 2
           } = package

    assert %{
             "review_type" => "operational_readiness_review",
             "source" =>
               "candidate_refresh.source_result_artifact[0].source_operational_readiness_gate_summary",
             "source_operational_readiness_report" => %{
               "source_summary_schema_contract" => "operational_readiness_gate_summary.v1"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact[0].source_operational_readiness_gate_summary")
             )

    assert %{
             "review_type" => "operational_readiness_review",
             "source" =>
               "candidate_refresh.source_result_artifact[0].operational_execution_boundary_summary",
             "source_operational_readiness_report" => %{
               "source_summary_schema_contract" => "operational_execution_boundary_summary.v1"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact[0].operational_execution_boundary_summary")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  defp study_result_fixture(filename) do
    ["study_results", filename]
    |> Path.join()
    |> File.read!()
    |> :json.decode()
  end

  defp operational_readiness_resource_report do
    %{
      "schema_contract" => "operational_readiness_report.v1",
      "schema_version" => 1,
      "model" => "artifact_only_operational_readiness_classifier",
      "report_id" => "operational_readiness:resource_pressure",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "activity_resource_pressure",
      "readiness_level" => "operator_review",
      "import_classification" => "review_only",
      "status" => "review_required",
      "gate_count" => 1,
      "passed_gate_count" => 0,
      "review_gate_count" => 1,
      "analysis_gate_count" => 0,
      "blocked_gate_count" => 0,
      "gates" => [
        %{
          "id" => "resource_availability",
          "status" => "review_required",
          "classification" => "review_only",
          "reason" => "resource availability evidence requires operator review before import",
          "resource_availability_pressure_count" => 3,
          "resource_availability_reason_counts" => %{
            "antenna_unavailable" => 1,
            "ground_station_reserved" => 1,
            "payload_unavailable" => 1
          },
          "resource_blocking_dimension_counts" => %{"communications" => 2}
        }
      ],
      "evidence" => %{
        "review_required_count" => 1,
        "resource_availability_pressure_count" => 3,
        "resource_availability_reason_counts" => %{
          "antenna_unavailable" => 1,
          "ground_station_reserved" => 1,
          "payload_unavailable" => 1
        },
        "resource_blocking_dimension_counts" => %{"communications" => 2}
      }
    }
  end
end
