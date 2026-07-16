defmodule OrbitalDynamics.OperatorReview.ExecutionResultArtifactTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "execution report source ids use generated report ids" do
    assert %{"source_artifact_id" => "execution:study:run"} =
             OperatorReview.from_execution_report(%{study_id: :study, run_id: :run})

    assert %{"source_artifact_id" => "execution:study:failed"} =
             OperatorReview.from_execution_report(%{study_id: :study, status: :failed})

    assert %{"source_artifact_id" => "execution"} =
             OperatorReview.from_execution_report(%{})
  end

  test "builds review package from execution report failed scenarios" do
    report = read_json!("study_results/execution_report_v1.json")

    package = OperatorReview.from_execution_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "execution_report.v1",
             "source_artifact_id" =>
               "execution:large_monte_carlo:large_monte_carlo-2026-05-14T00:00:00Z",
             "review_count" => 1,
             "execution_review_count" => 1,
             "review_type_counts" => %{"execution_review" => 1}
           } = package

    assert [
             %{
               "id" => "execution:trial_1842:propagation:1",
               "review_type" => "execution_review",
               "source" => "execution_report.failed_scenarios",
               "subject_id" => "trial_1842",
               "scenario_id" => "trial_1842",
               "scenario_index" => 1841,
               "required_operator_action" => "review_execution_failure",
               "action" => "review_execution_failure",
               "approval_status" => "operator_review_required",
               "execution_status" => "completed_with_errors",
               "execution_mode" => "distributed_task_supervisors",
               "execution_stage" => "propagation",
               "execution_error" => ["task_timeout", 30000],
               "resumability" => "manual_rerun_only",
               "retry_recommendation" => "rerun_failed_scenario_from_source_manifest",
               "failed_scenario_count" => 1,
               "source_execution_failure" => %{"scenario_id" => "trial_1842"},
               "source_execution_report" => %{"schema_contract" => "execution_report.v1"}
             }
           ] = package["rows"]

    completed_report =
      report
      |> Map.put("status", "completed")
      |> Map.put("failed_scenario_count", 0)
      |> Map.put("failed_scenarios", [])

    assert %{"review_count" => 0, "execution_review_count" => 0, "rows" => []} =
             OperatorReview.from_execution_report(completed_report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_status =
      update_in(package, ["rows"], fn [row] ->
        [Map.put(row, "execution_status", "completed")]
      end)

    assert {:error, invalid_source_status_report} =
             Schema.validate_artifact(invalid_source_status)

    assert Enum.any?(
             invalid_source_status_report["errors"],
             &(&1["path"] == "$.rows[0].source_execution_report.status" and
                 &1["message"] == "must match execution_status")
           )
  end

  test "builds review package from result artifact execution failures" do
    artifact =
      "study_results/ground_track_crossings.json"
      |> read_json!()
      |> put_in(["execution_report"], result_artifact_failed_execution_report())

    package = OperatorReview.from_result_artifact(artifact)

    assert OrbitalDynamics.operator_review_package(artifact) == package

    assert %{
             "source_artifact_type" => "result_artifact.v1",
             "source_artifact_id" =>
               "result_artifact:ground_track_crossings:ground_track_crossings-20260514",
             "review_count" => 1,
             "execution_review_count" => 1,
             "review_type_counts" => %{"execution_review" => 1}
           } = package

    assert [
             %{
               "id" => "execution:ground_track_1:propagation:1",
               "review_type" => "execution_review",
               "source" => "result_artifact.execution_report.failed_scenarios",
               "subject_id" => "ground_track_1",
               "scenario_id" => "ground_track_1",
               "required_operator_action" => "review_execution_failure",
               "execution_status" => "completed_with_errors",
               "source_execution_report" => %{"schema_contract" => "execution_report.v1"}
             }
           ] = package["rows"]

    completed_artifact = read_json!("study_results/ground_track_crossings.json")

    assert %{"review_count" => 0, "execution_review_count" => 0, "rows" => []} =
             OperatorReview.from_result_artifact(completed_artifact)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "lifts result artifact nested constraint and maneuver review rows" do
    artifact =
      "study_results/ground_track_crossings.json"
      |> read_json!()
      |> Map.put("constraint_report", constraint_report())
      |> Map.put(
        "maneuver_review_report",
        read_json!("study_results/maneuver_review_report_v1.json")
      )

    package = OperatorReview.from_result_artifact(artifact)

    assert %{
             "source_artifact_type" => "result_artifact.v1",
             "review_count" => 3,
             "constraint_review_count" => 2,
             "maneuver_review_count" => 1,
             "review_type_counts" => %{"constraint_review" => 2, "maneuver_review" => 1}
           } = package

    assert %{
             "review_type" => "constraint_review",
             "source" => "result_artifact.constraint_report.rows",
             "constraint_id" => "minimum_operational_altitude",
             "constraint_status" => "fail"
           } =
             Enum.find(package["rows"], &(&1["constraint_status"] == "fail"))

    assert %{
             "review_type" => "maneuver_review",
             "source" => "result_artifact.maneuver_review_report.rows",
             "maneuver_id" => "trim_burn",
             "scenario_id" => "ops_checkout"
           } =
             Enum.find(package["rows"], &(&1["review_type"] == "maneuver_review"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "deduplicates result artifact maneuver recommendations when review report is embedded" do
    maneuver_review_report = read_json!("study_results/maneuver_review_report_v1.json")

    recommendation =
      maneuver_review_report["rows"] |> List.first() |> Map.fetch!("source_recommendation")

    artifact =
      "study_results/ground_track_crossings.json"
      |> read_json!()
      |> Map.put("maneuver_review_report", maneuver_review_report)
      |> Map.put("maneuver_recommendations", [recommendation])

    package = OperatorReview.from_result_artifact(artifact)

    assert %{
             "source_artifact_type" => "result_artifact.v1",
             "review_count" => 1,
             "maneuver_review_count" => 1,
             "review_type_counts" => %{"maneuver_review" => 1},
             "rows" => [
               %{
                 "review_type" => "maneuver_review",
                 "source" => "result_artifact.maneuver_review_report.rows",
                 "maneuver_id" => "trim_burn",
                 "scenario_id" => "ops_checkout"
               }
             ]
           } = package

    refute Enum.any?(
             package["rows"],
             &(&1["source"] == "result_artifact.maneuver_recommendations")
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end

  defp result_artifact_failed_execution_report do
    "study_results/ground_track_crossings.json"
    |> read_json!()
    |> get_in(["execution_report"])
    |> Map.put("status", "completed_with_errors")
    |> Map.put("failed_scenario_count", 1)
    |> Map.put("failed_scenarios", [
      %{
        "scenario_id" => "ground_track_1",
        "scenario_index" => 0,
        "stage" => "propagation",
        "error" => ["task_timeout", 30_000],
        "resumability" => "manual_rerun_only",
        "retry_recommendation" => "rerun_failed_scenario_from_source_manifest"
      }
    ])
  end

  defp constraint_report do
    %{
      "schema_contract" => "constraint_report.v1",
      "model" => "artifact_metric_threshold",
      "status" => "fail",
      "constraint_count" => 2,
      "row_count" => 3,
      "status_counts" => %{"fail" => 1, "pass" => 1, "warning" => 1},
      "assumptions" => %{
        "constraint_model" => "artifact_level_metric_thresholds",
        "missing_or_nil_values" => "fail",
        "source" => "study_metadata.constraints"
      },
      "rows" => [
        %{
          "constraint_id" => "minimum_operational_altitude",
          "metric" => "min_altitude_km",
          "operator" => ">=",
          "scenario_id" => "dispersion_1",
          "score" => 0.42,
          "status" => "pass",
          "threshold" => 621.5,
          "value" => 621.92
        },
        %{
          "constraint_id" => "minimum_operational_altitude",
          "metric" => "min_altitude_km",
          "operator" => ">=",
          "scenario_id" => "dispersion_2",
          "score" => -0.31,
          "status" => "fail",
          "threshold" => 621.5,
          "value" => 621.19
        },
        %{
          "constraint_id" => "downlink_margin",
          "metric" => "estimated_throughput_mb",
          "operator" => ">=",
          "scenario_id" => "dispersion_3",
          "status" => "warning",
          "threshold" => 120.0
        }
      ]
    }
  end
end
