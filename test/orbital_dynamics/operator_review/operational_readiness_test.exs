defmodule OrbitalDynamics.OperatorReview.OperationalReadinessTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "operational readiness source ids and provenance use mapper package input" do
    assert %{
             "source_artifact_id" => "operational:atom",
             "source_readiness_report_id" => "operational:atom",
             "provenance" => %{"source" => "readiness_test"}
           } =
             OperatorReview.from_operational_readiness_report(%{
               report_id: :"operational:atom",
               provenance: %{source: :readiness_test}
             })

    assert %{"source_artifact_id" => "operational_readiness_report"} =
             OperatorReview.from_operational_readiness_report(%{})
  end

  test "builds operational readiness summary rows with top-level resource reason context" do
    report = operational_readiness_resource_report()
    package = OperatorReview.from_operational_readiness_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "operational_readiness_report.v1",
             "source_artifact_id" => "operational_readiness:resource_pressure",
             "review_count" => 2,
             "operational_readiness_review_count" => 2,
             "source_readiness_report_id" => "operational_readiness:resource_pressure",
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "status" => "review_required",
             "gate_count" => 1,
             "passed_gate_count" => 0,
             "review_gate_count" => 1,
             "analysis_gate_count" => 0,
             "blocked_gate_count" => 0
           } = package

    summary_row =
      Enum.find(
        package["rows"],
        &(&1["subject_id"] == "operational_readiness:resource_pressure")
      )

    assert %{
             "review_type" => "operational_readiness_review",
             "source" => "operational_readiness_report",
             "required_operator_action" => "review_operational_readiness",
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
             "station_availability_reason_counts" => %{"ground_station_reserved" => 1},
             "unavailable_resource_reason_ids" => [
               "antenna_unavailable",
               "payload_unavailable"
             ],
             "resource_blocking_dimension_counts" => %{"communications" => 2},
             "source_operational_readiness_report" => %{
               "schema_contract" => "operational_readiness_report.v1",
               "report_id" => "operational_readiness:resource_pressure"
             }
           } = summary_row

    assert %{
             "readiness_gate_id" => "resource_availability",
             "station_availability_reason_ids" => ["ground_station_reserved"],
             "station_availability_reason_counts" => %{"ground_station_reserved" => 1},
             "unavailable_resource_reason_ids" => [
               "antenna_unavailable",
               "payload_unavailable"
             ]
           } =
             Enum.find(
               package["rows"],
               &(&1["readiness_gate_id"] == "resource_availability")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_evidence =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"source_operational_readiness_report" => source_report} = row ->
            Map.put(
              row,
              "source_operational_readiness_report",
              Map.put(source_report, "report_id", "operational readiness with spaces")
            )

          row ->
            row
        end)
      end)

    assert {:error, invalid_source_evidence_report} =
             Schema.validate_artifact(invalid_source_evidence)

    assert Enum.any?(
             invalid_source_evidence_report["errors"],
             &(&1["path"] == "$.rows[0].source_operational_readiness_report.report_id")
           )

    stale_source_report =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{
            "subject_id" => "operational_readiness:resource_pressure",
            "source_operational_readiness_report" => %{} = source_report
          } = row ->
            Map.put(
              row,
              "source_operational_readiness_report",
              Map.put(source_report, "status", "passed")
            )

          row ->
            row
        end)
      end)

    assert {:error, stale_source_report_result} = Schema.validate_artifact(stale_source_report)

    assert Enum.any?(
             stale_source_report_result["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_operational_readiness_report.status" and
                 &1["message"] ==
                   "must match operational_readiness_status on handoff row")
           )
  end

  test "operational readiness analysis-only rows preserve not-for-execution context" do
    report = analysis_only_operational_readiness_report()
    package = OperatorReview.from_operational_readiness_report(report)

    assert %{
             "source_artifact_type" => "operational_readiness_report.v1",
             "source_artifact_id" => "operational_readiness:resource_pressure",
             "review_count" => 2,
             "operational_readiness_review_count" => 2,
             "readiness_level" => "analysis_only",
             "import_classification" => "analysis_only",
             "status" => "analysis_only",
             "analysis_gate_count" => 1,
             "review_gate_count" => 0
           } = package

    summary_row =
      Enum.find(
        package["rows"],
        &(&1["subject_id"] == "operational_readiness:resource_pressure")
      )

    assert %{
             "required_operator_action" => "record_operational_readiness_analysis_only",
             "approval_status" => "not_required",
             "cadence_import_status" => "not_applicable",
             "operational_readiness_status" => "analysis_only",
             "source_operational_readiness_report" => %{
               "assumptions" => %{"not_for_execution" => true},
               "model_limits" => ["artifact_only", "does_not_write_cadence"]
             }
           } = summary_row

    assert %{
             "required_operator_action" => "record_operational_readiness_analysis_only",
             "approval_status" => "not_required",
             "cadence_import_status" => "not_applicable",
             "readiness_gate_status" => "analysis_only",
             "readiness_gate_classification" => "analysis_only",
             "analysis_mode" => "not_for_execution",
             "source_operational_readiness_gate" => %{
               "analysis_mode" => "not_for_execution"
             },
             "source_operational_readiness_report" => %{
               "assumptions" => %{"not_for_execution" => true}
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["readiness_gate_id"] == "resource_availability")
             )

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

  defp analysis_only_operational_readiness_report do
    operational_readiness_resource_report()
    |> Map.merge(%{
      "readiness_level" => "analysis_only",
      "import_classification" => "analysis_only",
      "status" => "analysis_only",
      "review_gate_count" => 0,
      "analysis_gate_count" => 1,
      "assumptions" => %{"not_for_execution" => true},
      "model_limits" => ["artifact_only", "does_not_write_cadence"]
    })
    |> update_in(["gates", Access.at(0)], fn gate ->
      Map.merge(gate, %{
        "status" => "analysis_only",
        "classification" => "analysis_only",
        "reason" => "resource availability gate is analysis-only before execution",
        "analysis_mode" => "not_for_execution",
        "analysis_mode_source" => "operator_review_fixture"
      })
    end)
  end
end
