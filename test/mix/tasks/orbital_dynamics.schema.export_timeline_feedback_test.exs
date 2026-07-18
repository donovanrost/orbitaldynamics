defmodule Mix.Tasks.OrbitalDynamics.Schema.ExportTimelineFeedbackTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias OrbitalDynamics.Schema

  test "exports timeline feedback contract" do
    output_path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics.timeline_feedback.schema_bundle.#{System.unique_integer([:positive])}.json"
      )

    on_exit(fn ->
      File.rm(output_path)
      Mix.Task.reenable("orbital_dynamics.schema.export")
    end)

    capture_io(fn ->
      Mix.Task.run("orbital_dynamics.schema.export", ["--all", "--output", output_path])
    end)

    assert %{"schemas" => schemas} = output_path |> File.read!() |> :json.decode()

    assert Map.has_key?(schemas, "timeline_feedback_report.v1")

    feedback_schema = schemas["timeline_feedback_report.v1"]

    assert get_in(feedback_schema, ["properties", "model", "const"]) ==
             "planned_vs_realized_activity_reconciliation"

    assert get_in(feedback_schema, ["properties", "model_limits", "const"]) ==
             timeline_feedback_report_model_limits()

    assert get_in(schemas, [
             "timeline_feedback_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "status",
             "enum"
           ]) == ["matched", "planned_only", "realized_only"]

    assert get_in(schemas, [
             "timeline_feedback_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "lighting_condition",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "timeline_feedback_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "realized_activity_context",
             "properties",
             "lighting_confidence",
             "type"
           ]) == ["number", "string"]

    assert get_in(schemas, [
             "timeline_feedback_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "attitude_confidence",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "timeline_feedback_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "command_authority_status",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "timeline_feedback_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "realized_command_authorized",
             "type"
           ]) == "boolean"

    assert get_in(schemas, [
             "timeline_feedback_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "realized_activity_context",
             "properties",
             "command_safety_checked",
             "type"
           ]) == "boolean"

    assert get_in(schemas, [
             "timeline_feedback_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "source_activity_context",
             "properties",
             "attitude_target_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]
  end

  defp timeline_feedback_report_model_limits do
    OrbitalDynamics.TimelineFeedback.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end
end
