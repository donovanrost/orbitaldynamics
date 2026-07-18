defmodule Mix.Tasks.OrbitalDynamics.Schema.ExportOperationalTimelineTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "exports operational timeline contract" do
    output_path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics.operational_timeline.schema_bundle.#{System.unique_integer([:positive])}.json"
      )

    on_exit(fn ->
      File.rm(output_path)
      Mix.Task.reenable("orbital_dynamics.schema.export")
    end)

    capture_io(fn ->
      Mix.Task.run("orbital_dynamics.schema.export", ["--all", "--output", output_path])
    end)

    assert %{"schemas" => schemas} = output_path |> File.read!() |> :json.decode()

    assert Map.has_key?(schemas, "operational_timeline_report.v1")

    operational_timeline_schema = schemas["operational_timeline_report.v1"]

    assert get_in(operational_timeline_schema, ["properties", "model", "const"]) ==
             "selected_activity_operational_context_summary"

    assert get_in(operational_timeline_schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.Timeline.model_limits()

    operational_timeline_row_properties =
      get_in(operational_timeline_schema, ["properties", "rows", "items", "properties"])

    assert get_in(operational_timeline_row_properties, [
             "command_authority_status",
             "type"
           ]) == "string"

    assert get_in(operational_timeline_row_properties, ["required_authority", "type"]) ==
             "string"

    assert get_in(operational_timeline_row_properties, [
             "command_safety_status",
             "type"
           ]) == "string"

    assert get_in(operational_timeline_row_properties, ["command_authorized", "type"]) ==
             "boolean"

    assert get_in(operational_timeline_row_properties, [
             "command_safety_checked",
             "type"
           ]) == "boolean"

    assert get_in(schemas, [
             "operational_timeline_report.v1",
             "properties",
             "model_limits",
             "const"
           ]) == OrbitalDynamics.Timeline.model_limits()

    assert get_in(schemas, [
             "operational_timeline_report.v1",
             "properties",
             "source",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "operational_timeline_report.v1",
             "properties",
             "rows",
             "type"
           ]) == "array"

    assert get_in(schemas, [
             "operational_timeline_report.v1",
             "properties",
             "rows",
             "items",
             "required"
           ]) == [
             "id",
             "activity_id",
             "timeline_id",
             "activity_type",
             "status",
             "approval_status",
             "locked",
             "has_source_window",
             "has_cadence_import",
             "timeline_identity"
           ]

    assert get_in(schemas, [
             "operational_timeline_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "locked",
             "type"
           ]) == "boolean"

    assert get_in(schemas, [
             "operational_timeline_report.v1",
             "properties",
             "activity_status_counts",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().activity_statuses

    assert get_in(schemas, [
             "operational_timeline_report.v1",
             "properties",
             "required_operator_action_counts",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().required_operator_actions

    assert get_in(schemas, [
             "operational_timeline_report.v1",
             "properties",
             "operational_kind_counts",
             "additionalProperties"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(schemas, [
             "operational_timeline_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "roll_deg",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "operational_timeline_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "timeline_identity",
             "properties",
             "timeline_id",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"
  end
end
