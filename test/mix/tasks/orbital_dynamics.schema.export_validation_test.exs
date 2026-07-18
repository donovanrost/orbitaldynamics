defmodule Mix.Tasks.OrbitalDynamics.Schema.ExportValidationTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "exports validation family contracts" do
    output_path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics.validation.schema_bundle.#{System.unique_integer([:positive])}.json"
      )

    on_exit(fn ->
      File.rm(output_path)
      Mix.Task.reenable("orbital_dynamics.schema.export")
    end)

    capture_io(fn ->
      Mix.Task.run("orbital_dynamics.schema.export", ["--all", "--output", output_path])
    end)

    assert %{"schemas" => schemas} = output_path |> File.read!() |> :json.decode()

    assert get_in(schemas, [
             "model_acceptance_report.v1",
             "properties",
             "model",
             "const"
           ]) == "registry_model_acceptance_classifier"

    validation_model_limits = OrbitalDynamics.Validation.capabilities().known_limits

    assert get_in(schemas, [
             "model_acceptance_report.v1",
             "properties",
             "model_limits",
             "const"
           ]) == validation_model_limits

    assert get_in(schemas, [
             "model_acceptance_report.v1",
             "properties",
             "model_limits",
             "items",
             "enum"
           ]) == validation_model_limits

    assert get_in(schemas, [
             "validation_safety_case_summary.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_validation_safety_case_summary"

    assert get_in(schemas, [
             "validation_safety_case_summary.v1",
             "properties",
             "model_limits",
             "const"
           ]) == validation_model_limits

    assert get_in(schemas, [
             "validation_safety_case_summary.v1",
             "properties",
             "model_limits",
             "items",
             "enum"
           ]) == validation_model_limits

    assert get_in(schemas, [
             "model_acceptance_report.v1",
             "properties",
             "status_counts",
             "propertyNames",
             "enum"
           ]) == ["accepted", "review_required", "blocked"]

    assert get_in(schemas, [
             "validation_reference_fixture_report.v1",
             "properties",
             "fixture_count",
             "minimum"
           ]) == 0

    assert get_in(schemas, [
             "validation_reference_fixture_report.v1",
             "properties",
             "status_counts",
             "propertyNames",
             "enum"
           ]) == ["pass", "fail"]

    assert get_in(schemas, [
             "validation_reference_fixture_report.v1",
             "properties",
             "reports",
             "items",
             "properties",
             "status_counts",
             "propertyNames",
             "enum"
           ]) == ["pass", "fail"]

    assert get_in(schemas, [
             "validation_reference_fixture_report.v1",
             "properties",
             "reports",
             "items",
             "properties",
             "checks",
             "items",
             "properties",
             "status",
             "enum"
           ]) == ["pass", "fail"]
  end
end
