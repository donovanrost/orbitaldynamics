defmodule OrbitalDynamics.OperatorReview.QualityGateTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "quality gate source ids and provenance use mapper package input" do
    assert %{
             "source_artifact_id" => "quality:atom",
             "provenance" => %{"source" => "quality_test"}
           } =
             OperatorReview.from_quality_gate_report(%{
               report_id: :"quality:atom",
               provenance: %{source: :quality_test}
             })

    assert %{"source_artifact_id" => "quality_gate_report"} =
             OperatorReview.from_quality_gate_report(%{})
  end

  test "builds quality gate review rows with resource reason context" do
    report =
      operational_readiness_resource_report()
      |> OrbitalDynamics.operational_quality_gate_report()

    package = OperatorReview.from_quality_gate_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "quality_gate_report.v1",
             "source_artifact_id" =>
               "quality_gate:planned_activity.v1:activity_resource_pressure",
             "review_count" => 1,
             "quality_gate_review_count" => 1,
             "review_type_counts" => %{"quality_gate_review" => 1},
             "source_readiness_report_id" => "operational_readiness:resource_pressure",
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "status" => "review_required",
             "gate_count" => 1,
             "passed_gate_count" => 0,
             "review_gate_count" => 1,
             "analysis_gate_count" => 0,
             "blocked_gate_count" => 0,
             "gate_status_counts" => %{"review_required" => 1},
             "gate_classification_counts" => %{"review_only" => 1}
           } = package

    assert package["gate_ids_by_status"] == report["gate_ids_by_status"]
    assert package["gate_ids_by_classification"] == report["gate_ids_by_classification"]
    assert package["quality_gate_row_ids_by_status"] == report["quality_gate_row_ids_by_status"]

    assert package["quality_gate_row_ids_by_classification"] ==
             report["quality_gate_row_ids_by_classification"]

    assert package["review_required_gate_ids"] == report["review_required_gate_ids"]

    assert [
             %{
               "review_type" => "quality_gate_review",
               "source" => "quality_gate_report.rows",
               "required_operator_action" => "review_quality_gate",
               "quality_gate_id" => "resource_availability",
               "quality_gate_status" => "review_required",
               "quality_gate_classification" => "review_only",
               "readiness_gate_id" => "resource_availability",
               "resource_availability_pressure_count" => 3,
               "resource_availability_reason_counts" => %{
                 "antenna_unavailable" => 1,
                 "ground_station_reserved" => 1,
                 "payload_unavailable" => 1
               },
               "resource_availability_reason_ids" => [
                 "antenna_unavailable",
                 "ground_station_reserved",
                 "payload_unavailable"
               ],
               "station_availability_reason_ids" => ["ground_station_reserved"],
               "unavailable_resource_reason_ids" => [
                 "antenna_unavailable",
                 "payload_unavailable"
               ],
               "source_quality_gate_row" => %{
                 "gate_id" => "resource_availability",
                 "resource_availability_reason_ids" => [
                   "antenna_unavailable",
                   "ground_station_reserved",
                   "payload_unavailable"
                 ]
               },
               "source_quality_gate_report" => %{
                 "schema_contract" => "quality_gate_report.v1",
                 "source_artifact_type" => "planned_activity.v1"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_evidence =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"source_quality_gate_report" => source_report} = row ->
            Map.put(
              row,
              "source_quality_gate_report",
              Map.put(source_report, "report_id", "quality gate with spaces")
            )

          row ->
            row
        end)
      end)

    assert {:error, invalid_source_evidence_report} =
             Schema.validate_artifact(invalid_source_evidence)

    assert Enum.any?(
             invalid_source_evidence_report["errors"],
             &(&1["path"] == "$.rows[0].source_quality_gate_report.report_id")
           )

    stale_source_report =
      update_in(package, ["rows", Access.at(0), "source_quality_gate_report"], fn report ->
        Map.put(report, "readiness_level", "blocked")
      end)

    assert {:error, stale_source_report_result} = Schema.validate_artifact(stale_source_report)

    assert Enum.any?(
             stale_source_report_result["errors"],
             &(&1["path"] == "$.rows[0].source_quality_gate_report.readiness_level" and
                 &1["message"] == "must match readiness_level on handoff row")
           )

    stale_source_quality_gate =
      update_in(package, ["rows", Access.at(0), "source_quality_gate_row"], fn row ->
        Map.put(row, "classification", "blocked")
      end)

    assert {:error, stale_source_quality_gate_report} =
             Schema.validate_artifact(stale_source_quality_gate)

    assert Enum.any?(
             stale_source_quality_gate_report["errors"],
             &(&1["path"] == "$.rows[0].source_quality_gate_row.classification" and
                 &1["message"] == "must match quality_gate_classification on handoff row")
           )

    stale_source_quality_gate_resource_context =
      update_in(package, ["rows", Access.at(0), "source_quality_gate_row"], fn row ->
        row
        |> Map.put("resource_availability_reason_counts", %{"ground_station_unavailable" => 1})
        |> Map.put("station_availability_reason_ids", ["ground_station_unavailable"])
        |> Map.put("unavailable_resource_reason_ids", [])
      end)

    assert {:error, stale_source_quality_gate_resource_context_report} =
             Schema.validate_artifact(stale_source_quality_gate_resource_context)

    assert Enum.any?(
             stale_source_quality_gate_resource_context_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_quality_gate_row.resource_availability_reason_counts" and
                 &1["message"] ==
                   "must match resource_availability_reason_counts on handoff row")
           )

    assert Enum.any?(
             stale_source_quality_gate_resource_context_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_quality_gate_row.station_availability_reason_ids" and
                 &1["message"] == "must match station_availability_reason_ids on handoff row")
           )
  end

  test "quality gate review rows preserve import readiness context" do
    report = stale_import_readiness_quality_gate_report()
    source_row = Enum.find(report["rows"], &(&1["gate_id"] == "cadence_import"))

    package = OperatorReview.from_quality_gate_report(report)

    assert [
             %{
               "review_type" => "quality_gate_review",
               "required_operator_action" => "review_quality_gate",
               "approval_status" => "operator_review_required",
               "cadence_import_status" => "present",
               "quality_gate_id" => "cadence_import",
               "quality_gate_status" => "review_required",
               "quality_gate_classification" => "review_only",
               "ready_for_import_count" => 1,
               "manifest_review_required_count" => 0,
               "blocked_import_count" => 0,
               "missing_import_count" => 0,
               "invalid_cadence_import_count" => 0,
               "current_freshness_count" => 0,
               "stale_freshness_count" => 1,
               "unknown_freshness_count" => 0,
               "freshness_status_counts" => %{"stale" => 1},
               "schema_validation_pass_count" => 1,
               "schema_validation_fail_count" => 0,
               "schema_validation_status_counts" => %{"pass" => 1},
               "import_status_counts" => %{"ready_for_import" => 1},
               "cadence_import_status_counts" => %{"present" => 1},
               "source_quality_gate_row" => ^source_row
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "quality gate analysis-only rows remain not-required handoffs" do
    report = analysis_only_quality_gate_report()
    package = OperatorReview.from_quality_gate_report(report)

    assert %{
             "readiness_level" => "analysis_only",
             "import_classification" => "analysis_only",
             "status" => "analysis_only",
             "analysis_gate_count" => 1,
             "review_gate_count" => 0,
             "quality_gate_review_count" => 1,
             "review_type_counts" => %{"quality_gate_review" => 1}
           } = package

    assert [
             %{
               "review_type" => "quality_gate_review",
               "required_operator_action" => "record_quality_gate_analysis_only",
               "action" => "record_quality_gate_analysis_only",
               "approval_status" => "not_required",
               "cadence_import_status" => "not_applicable",
               "quality_gate_id" => "resource_availability",
               "quality_gate_status" => "analysis_only",
               "quality_gate_classification" => "analysis_only",
               "source_quality_gate_row" => %{
                 "status" => "analysis_only",
                 "classification" => "analysis_only"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
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

  defp stale_import_readiness_quality_gate_report do
    operational_readiness_resource_report()
    |> Map.merge(%{
      "report_id" => "operational_readiness:stale_import_readiness",
      "source_artifact_id" => "activity_stale_import_readiness",
      "gates" => [
        %{
          "id" => "cadence_import",
          "status" => "review_required",
          "classification" => "review_only",
          "reason" => "source freshness evidence is stale or unknown",
          "ready_for_import_count" => 1,
          "manifest_review_required_count" => 0,
          "blocked_import_count" => 0,
          "missing_import_count" => 0,
          "invalid_cadence_import_count" => 0,
          "current_freshness_count" => 0,
          "stale_freshness_count" => 1,
          "unknown_freshness_count" => 0,
          "freshness_status_counts" => %{"stale" => 1},
          "schema_validation_pass_count" => 1,
          "schema_validation_fail_count" => 0,
          "schema_validation_error_count" => 0,
          "schema_validation_warning_count" => 0,
          "schema_validation_remediation_count" => 0,
          "schema_validation_status_counts" => %{"pass" => 1},
          "import_status_counts" => %{"ready_for_import" => 1},
          "cadence_import_status_counts" => %{"present" => 1}
        }
      ],
      "evidence" => %{
        "ready_for_import_count" => 1,
        "stale_freshness_count" => 1,
        "freshness_status_counts" => %{"stale" => 1},
        "schema_validation_pass_count" => 1,
        "schema_validation_status_counts" => %{"pass" => 1},
        "import_status_counts" => %{"ready_for_import" => 1},
        "cadence_import_status_counts" => %{"present" => 1}
      }
    })
    |> OrbitalDynamics.operational_quality_gate_report()
  end

  defp analysis_only_quality_gate_report do
    operational_readiness_resource_report()
    |> Map.merge(%{
      "readiness_level" => "analysis_only",
      "import_classification" => "analysis_only",
      "status" => "analysis_only",
      "review_gate_count" => 0,
      "analysis_gate_count" => 1
    })
    |> update_in(["gates", Access.at(0)], fn gate ->
      Map.merge(gate, %{
        "status" => "analysis_only",
        "classification" => "analysis_only",
        "reason" => "resource availability gate is analysis-only before execution"
      })
    end)
    |> OrbitalDynamics.operational_quality_gate_report()
  end
end
