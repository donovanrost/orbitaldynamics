defmodule OrbitalDynamics.Schema.OperationalTimelineContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "validates standalone operational timeline report contracts" do
    report = %{
      "schema_contract" => "operational_timeline_report.v1",
      "model" => "selected_activity_operational_context_summary",
      "source" => "campaign_plan.activities",
      "activity_count" => 1,
      "row_count" => 1,
      "contact_count" => 1,
      "command_count" => 0,
      "locked_count" => 1,
      "approved_count" => 1,
      "executed_count" => 0,
      "source_window_lineage_count" => 1,
      "rows" => [
        %{
          "id" => "timeline_row:1:contact_1",
          "activity_id" => "contact_1",
          "timeline_id" => "timeline:leo_1:downlink:equator:0.0",
          "scenario_id" => "leo_1",
          "activity_type" => "downlink",
          "status" => "planned",
          "approval_status" => "approved",
          "locked" => true,
          "starts_at_s" => 0.0,
          "ends_at_s" => 60.0,
          "ground_station_id" => "equator",
          "has_source_window" => true,
          "has_cadence_import" => true,
          "timeline_identity" => %{
            "timeline_id" => "timeline:leo_1:downlink:equator:0.0",
            "activity_id" => "contact_1",
            "activity_type" => "downlink",
            "scenario_id" => "leo_1",
            "subject_id" => "equator"
          }
        }
      ],
      "assumptions" => %{"execution_boundary" => "planned_not_commanded"}
    }

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)

    invalid_model = Map.put(report, "model", "operational_timeline_v0")

    assert {:error, invalid_model_report} = Schema.validate_artifact(invalid_model)

    assert Enum.any?(
             invalid_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"selected_activity_operational_context_summary\"")
           )

    invalid = put_in(report, ["rows", Access.at(0), "timeline_id"], "bad id")

    assert {:error, validation_report} = Schema.validate_artifact(invalid)
    assert Enum.any?(validation_report["errors"], &(&1["path"] == "$.rows[0].timeline_id"))

    invalid_dependency =
      put_in(report, ["rows", Access.at(0), "dependency_activity_ids"], ["bad dependency"])

    assert {:error, dependency_report} = Schema.validate_artifact(invalid_dependency)

    assert Enum.any?(
             dependency_report["errors"],
             &(&1["path"] == "$.rows[0].dependency_activity_ids[0]")
           )

    invalid_self_dependency =
      put_in(report, ["rows", Access.at(0), "self_dependency_activity_ids"], ["bad self"])

    assert {:error, self_dependency_report} = Schema.validate_artifact(invalid_self_dependency)

    assert Enum.any?(
             self_dependency_report["errors"],
             &(&1["path"] == "$.rows[0].self_dependency_activity_ids[0]")
           )

    float_row_integrity_count =
      put_in(report, ["rows", Access.at(0), "timeline_integrity_issue_count"], 1.0)

    assert {:error, float_row_integrity_count_report} =
             Schema.validate_artifact(float_row_integrity_count)

    assert Enum.any?(
             float_row_integrity_count_report["errors"],
             &(&1["path"] == "$.rows[0].timeline_integrity_issue_count")
           )

    negative_row_integrity_count =
      put_in(report, ["rows", Access.at(0), "timeline_integrity_issue_count"], -1)

    assert {:error, negative_row_integrity_count_report} =
             Schema.validate_artifact(negative_row_integrity_count)

    assert Enum.any?(
             negative_row_integrity_count_report["errors"],
             &(&1["path"] == "$.rows[0].timeline_integrity_issue_count")
           )

    invalid_attitude_confidence =
      put_in(report, ["rows", Access.at(0), "attitude_confidence"], 1.2)

    assert {:error, invalid_attitude_confidence_report} =
             Schema.validate_artifact(invalid_attitude_confidence)

    assert Enum.any?(
             invalid_attitude_confidence_report["errors"],
             &(&1["path"] == "$.rows[0].attitude_confidence")
           )

    invalid_counts = Map.put(report, "activity_status_counts", %{"planned" => 2})

    assert {:error, counts_report} = Schema.validate_artifact(invalid_counts)
    assert Enum.any?(counts_report["errors"], &(&1["path"] == "$.activity_status_counts"))

    float_activity_count = Map.put(report, "activity_count", 1.0)

    assert {:error, float_activity_count_report} =
             Schema.validate_artifact(float_activity_count)

    assert Enum.any?(
             float_activity_count_report["errors"],
             &(&1["path"] == "$.activity_count")
           )

    negative_contact_count = Map.put(report, "contact_count", -1)

    assert {:error, negative_contact_count_report} =
             Schema.validate_artifact(negative_contact_count)

    assert Enum.any?(
             negative_contact_count_report["errors"],
             &(&1["path"] == "$.contact_count")
           )

    negative_dependency_count = Map.put(report, "dependency_count", -1)

    assert {:error, negative_dependency_count_report} =
             Schema.validate_artifact(negative_dependency_count)

    assert Enum.any?(
             negative_dependency_count_report["errors"],
             &(&1["path"] == "$.dependency_count")
           )

    negative_timeline_integrity_count =
      Map.put(report, "timeline_integrity_issue_count", -1)

    assert {:error, negative_timeline_integrity_count_report} =
             Schema.validate_artifact(negative_timeline_integrity_count)

    assert Enum.any?(
             negative_timeline_integrity_count_report["errors"],
             &(&1["path"] == "$.timeline_integrity_issue_count")
           )
  end

  test "exports operational timeline top-level counter contract fields" do
    assert {:ok, schema} = Schema.json_schema("operational_timeline_report.v1")

    assert get_in(schema, ["properties", "model", "const"]) ==
             "selected_activity_operational_context_summary"

    assert get_in(schema, ["properties", "activity_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(schema, ["properties", "contact_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(schema, ["properties", "source_window_lineage_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(schema, ["properties", "dependency_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(schema, ["properties", "timeline_integrity_issue_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    row_properties = get_in(schema, ["properties", "rows", "items", "properties"])

    assert row_properties["self_dependency_activity_ids"] == %{
             "type" => "array",
             "items" => %{"type" => "string", "pattern" => "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"}
           }

    assert row_properties["self_dependency_timeline_ids"] == %{
             "type" => "array",
             "items" => %{"type" => "string", "pattern" => "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"}
           }

    assert row_properties["station_calendar_reservation_ids"] == %{
             "type" => "array",
             "items" => %{"type" => "string", "pattern" => "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"}
           }

    assert row_properties["station_calendar_reservation_expires_at_s"] == %{
             "type" => "array",
             "items" => %{"type" => "number"}
           }

    assert row_properties["station_reservation_id"] == %{
             "type" => "string",
             "pattern" => "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"
           }

    assert row_properties["station_reservation_expires_at_s"] == %{"type" => "number"}

    assert row_properties["attitude_confidence"] == %{
             "type" => "number",
             "minimum" => 0.0,
             "maximum" => 1.0
           }

    assert row_properties["command_authority_status"] == %{"type" => "string"}
    assert row_properties["required_authority"] == %{"type" => "string"}
    assert row_properties["command_safety_status"] == %{"type" => "string"}
    assert row_properties["command_authorized"] == %{"type" => "boolean"}
    assert row_properties["command_safety_checked"] == %{"type" => "boolean"}
  end
end
