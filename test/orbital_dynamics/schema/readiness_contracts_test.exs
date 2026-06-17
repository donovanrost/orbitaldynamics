defmodule OrbitalDynamics.Schema.ReadinessContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "validates checked-in operational readiness report fixture" do
    readiness_report = read_json!("study_results/operational_readiness_report_v1.json")

    assert {:ok, %{"schema_contract" => "operational_readiness_report.v1"}} =
             Schema.validate_artifact(readiness_report)

    stale_model = Map.put(readiness_report, "model", "stale_operational_readiness_model")

    assert {:error, stale_model_report} = Schema.validate_artifact(stale_model)

    assert Enum.any?(
             stale_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"artifact_only_operational_readiness_classifier\"")
           )

    assert %{
             "model" => "artifact_only_operational_readiness_classifier",
             "readiness_level" => "import_eligible",
             "import_classification" => "importable",
             "status" => "passed",
             "evidence" => %{
               "ready_for_import_count" => 1,
               "source_model_limit_count" => 1
             }
           } = readiness_report

    invalid_negative_count = Map.put(readiness_report, "blocked_gate_count", -1)

    assert {:error, negative_count_report} = Schema.validate_artifact(invalid_negative_count)
    assert Enum.any?(negative_count_report["errors"], &(&1["path"] == "$.blocked_gate_count"))

    assert {:ok, readiness_schema} = Schema.json_schema("operational_readiness_report.v1")

    assert get_in(readiness_schema, ["properties", "model", "const"]) ==
             "artifact_only_operational_readiness_classifier"

    assert get_in(readiness_schema, ["properties", "gate_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(readiness_schema, ["properties", "passed_gate_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(readiness_schema, ["properties", "review_gate_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(readiness_schema, ["properties", "analysis_gate_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(readiness_schema, ["properties", "blocked_gate_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(readiness_schema, [
             "properties",
             "evidence",
             "properties",
             "resource_availability_reason_ids",
             "items",
             "type"
           ]) == "string"

    assert get_in(readiness_schema, [
             "properties",
             "evidence",
             "properties",
             "station_availability_reason_ids",
             "items",
             "type"
           ]) == "string"

    assert get_in(readiness_schema, [
             "properties",
             "evidence",
             "properties",
             "station_availability_reason_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(readiness_schema, [
             "properties",
             "evidence",
             "properties",
             "unavailable_resource_reason_ids",
             "items",
             "type"
           ]) == "string"
  end

  test "validates readiness resource context fields on handoff rows" do
    readiness_report =
      "study_results/operational_readiness_report_v1.json"
      |> read_json!()
      |> put_readiness_resource_context(["gates", Access.at(0)])

    assert {:ok, %{"schema_contract" => "operational_readiness_report.v1"}} =
             Schema.validate_artifact(readiness_report)

    invalid_gate_count =
      put_in(
        readiness_report,
        ["gates", Access.at(0), "resource_availability_reason_counts", "antenna_unavailable"],
        -1
      )

    assert {:error, invalid_gate_count_report} = Schema.validate_artifact(invalid_gate_count)

    assert Enum.any?(
             invalid_gate_count_report["errors"],
             &(&1["path"] ==
                 "$.gates[0].resource_availability_reason_counts.antenna_unavailable")
           )

    operator_review =
      "study_results/operator_review_package_v1.json"
      |> read_json!()
      |> put_readiness_resource_context(["rows", Access.at(0)])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(operator_review)

    invalid_operator_reason_id =
      put_in(
        operator_review,
        ["rows", Access.at(0), "resource_availability_reason_ids", Access.at(1)],
        42
      )

    assert {:error, invalid_operator_reason_id_report} =
             Schema.validate_artifact(invalid_operator_reason_id)

    assert Enum.any?(
             invalid_operator_reason_id_report["errors"],
             &(&1["path"] == "$.rows[0].resource_availability_reason_ids[1]")
           )

    cadence_manifest =
      "study_results/cadence_import_manifest_v1.json"
      |> read_json!()
      |> put_readiness_resource_context(["rows", Access.at(0)])
      |> put_in(["rows", Access.at(0), "source_review_row"], %{})
      |> put_readiness_resource_context(["rows", Access.at(0), "source_review_row"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(cadence_manifest)

    invalid_source_review_count =
      put_in(
        cadence_manifest,
        [
          "rows",
          Access.at(0),
          "source_review_row",
          "resource_blocking_dimension_counts",
          "spacecraft"
        ],
        -1
      )

    assert {:error, invalid_source_review_count_report} =
             Schema.validate_artifact(invalid_source_review_count)

    assert Enum.any?(
             invalid_source_review_count_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.resource_blocking_dimension_counts.spacecraft")
           )
  end

  test "validates checked-in readiness resource pressure handoff fixtures" do
    readiness_report = read_json!("study_results/operational_readiness_resource_pressure_v1.json")
    quality_gate_report = read_json!("study_results/quality_gate_resource_pressure_v1.json")

    unavailable_resource_summary =
      read_json!("study_results/operational_quality_gate_unavailable_resource_summary_v1.json")

    operator_review = read_json!("study_results/operator_review_resource_pressure_v1.json")
    cadence_manifest = read_json!("study_results/cadence_import_resource_pressure_v1.json")

    assert {:ok, %{"schema_contract" => "operational_readiness_report.v1"}} =
             Schema.validate_artifact(readiness_report)

    assert {:ok, %{"schema_contract" => "quality_gate_report.v1"}} =
             Schema.validate_artifact(quality_gate_report)

    assert {:ok,
            %{"schema_contract" => "operational_quality_gate_unavailable_resource_summary.v1"}} =
             Schema.validate_artifact(unavailable_resource_summary)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(operator_review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(cadence_manifest)

    expected_reason_counts = %{"antenna_unavailable" => 1, "payload_unavailable" => 1}
    expected_reason_ids = ["antenna_unavailable", "payload_unavailable"]

    assert %{
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "status" => "review_required",
             "evidence" => %{
               "resource_availability_pressure_count" => 2,
               "resource_availability_reason_counts" => ^expected_reason_counts
             }
           } = readiness_report

    assert %{
             "id" => "resource_availability",
             "resource_availability_pressure_count" => 2,
             "resource_availability_reason_counts" => ^expected_reason_counts
           } =
             Enum.find(readiness_report["gates"], &(&1["id"] == "resource_availability"))

    assert %{
             "gate_id" => "resource_availability",
             "resource_availability_pressure_count" => 2,
             "resource_availability_reason_counts" => ^expected_reason_counts,
             "resource_availability_reason_ids" => ^expected_reason_ids,
             "unavailable_resource_reason_ids" => ^expected_reason_ids
           } =
             Enum.find(
               quality_gate_report["rows"],
               &(&1["gate_id"] == "resource_availability")
             )

    assert OrbitalDynamics.operational_quality_gate_unavailable_resource_summary(
             quality_gate_report
           ) == unavailable_resource_summary

    assert %{
             "source_artifact_type" => "resource_projection_report.v1",
             "source_artifact_id" => "resource_summaries",
             "source_quality_gate_report_id" =>
               "quality_gate:resource_projection_report.v1:resource_summaries",
             "source_readiness_report_id" =>
               "operational_readiness:resource_projection_report.v1:resource_summaries",
             "resource_availability_row_count" => 1,
             "unavailable_resource_row_count" => 1,
             "unavailable_resource_pressure_count" => 2,
             "unavailable_resource_reason_counts" => ^expected_reason_counts,
             "unavailable_resource_reason_ids" => ^expected_reason_ids,
             "station_availability_reason_counts" => %{},
             "station_availability_reason_ids" => [],
             "blocked_contact_ids_by_blocking_dimension" => %{},
             "blocked_contact_ids_by_spacecraft_id" => %{},
             "blocked_contact_ids_by_status" => %{},
             "quality_gate_row_ids_by_status" => %{
               "review_required" => [
                 "quality_gate:resource_projection_report.v1:resource_summaries:resource_availability:4"
               ]
             },
             "quality_gate_ids_by_status" => %{"review_required" => ["resource_availability"]},
             "review_required_quality_gate_row_ids" => [
               "quality_gate:resource_projection_report.v1:resource_summaries:resource_availability:4"
             ],
             "resource_availability_gate_ids" => ["resource_availability"],
             "assumptions" => %{
               "operator_authority" => "not_granted_by_unavailable_resource_summary",
               "cadence_write" => "not_performed_by_summary",
               "command_execution" => "not_performed_by_summary"
             }
           } = unavailable_resource_summary

    assert %{
             "readiness_gate_id" => "resource_availability",
             "resource_availability_pressure_count" => 2,
             "resource_availability_reason_counts" => ^expected_reason_counts,
             "resource_availability_reason_ids" => ^expected_reason_ids,
             "unavailable_resource_reason_ids" => ^expected_reason_ids
           } =
             Enum.find(
               operator_review["rows"],
               &(&1["readiness_gate_id"] == "resource_availability")
             )

    assert %{
             "readiness_gate_id" => "resource_availability",
             "resource_availability_pressure_count" => 2,
             "resource_availability_reason_counts" => ^expected_reason_counts,
             "resource_availability_reason_ids" => ^expected_reason_ids,
             "unavailable_resource_reason_ids" => ^expected_reason_ids,
             "source_review_row" => %{
               "resource_availability_pressure_count" => 2,
               "resource_availability_reason_counts" => ^expected_reason_counts,
               "resource_availability_reason_ids" => ^expected_reason_ids,
               "unavailable_resource_reason_ids" => ^expected_reason_ids
             }
           } =
             Enum.find(
               cadence_manifest["rows"],
               &(&1["readiness_gate_id"] == "resource_availability")
             )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end

  defp put_readiness_resource_context(artifact, path) do
    artifact
    |> put_in(path ++ ["resource_availability_pressure_count"], 3)
    |> put_in(path ++ ["resource_availability_reason_counts"], %{
      "antenna_unavailable" => 1,
      "ground_station_reserved" => 1,
      "payload_unavailable" => 1
    })
    |> put_in(path ++ ["resource_availability_reason_ids"], [
      "antenna_unavailable",
      "ground_station_reserved",
      "payload_unavailable"
    ])
    |> put_in(path ++ ["station_availability_reason_ids"], [
      "ground_station_reserved"
    ])
    |> put_in(path ++ ["station_availability_reason_counts"], %{
      "ground_station_reserved" => 1
    })
    |> put_in(path ++ ["unavailable_resource_reason_ids"], [
      "antenna_unavailable",
      "payload_unavailable"
    ])
    |> put_in(path ++ ["resource_blocking_dimension_counts"], %{
      "spacecraft" => 1,
      "station" => 1
    })
  end
end
