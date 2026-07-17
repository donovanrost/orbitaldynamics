defmodule OrbitalDynamics.Validation.ManifestFixtureTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Validation}

  import OrbitalDynamics.Validation.ManifestFixtures,
    only: [
      manifest_field_reference_fixture: 0,
      manifest_field_reference_fixture_observations: 0,
      study_manifest_lint_fixture: 0,
      study_manifest_lint_fixture_observations: 0
    ]

  test "verifies curated manifest field reference fixtures" do
    fixture_id = "fixture.artifact.manifest_field_reference.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.manifest_field_reference.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = manifest_field_reference_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               manifest_field_reference_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      manifest_field_reference_fixture_observations()
      |> Map.put("field_row_count", 3719)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "field_row_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "manifest_field_reference.v1",
             report
           ) == Validation.artifact_observations("manifest_field_reference.v1", report)

    assert {:ok, %{"schema_contract" => "manifest_field_reference.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "manifest_field_reference.v1"
             )

    stale_field_count = Map.put(report, "field_count", 3719)

    assert {:error, stale_field_count_report} =
             Schema.validate_artifact(stale_field_count,
               schema_contract: "manifest_field_reference.v1"
             )

    assert Enum.any?(
             stale_field_count_report["errors"],
             &(&1["path"] == "$.field_count")
           )

    fields = Map.fetch!(report, "fields")

    duplicate_path_fields =
      fields
      |> List.replace_at(1, Map.put(Enum.at(fields, 1), "path", "$.campaign"))

    stale_duplicate_path = Map.put(report, "fields", duplicate_path_fields)

    assert {:error, stale_duplicate_path_report} =
             Schema.validate_artifact(stale_duplicate_path,
               schema_contract: "manifest_field_reference.v1"
             )

    assert Enum.any?(
             stale_duplicate_path_report["errors"],
             &(&1["path"] == "$.fields")
           )

    stale_top_level_required =
      Map.put(report, "top_level_required", ["schema_version", "study_id"])

    assert {:error, stale_top_level_required_report} =
             Schema.validate_artifact(stale_top_level_required,
               schema_contract: "manifest_field_reference.v1"
             )

    assert Enum.any?(
             stale_top_level_required_report["errors"],
             &(&1["path"] == "$.top_level_required")
           )

    stale_activation_sections =
      Map.put(
        report,
        "activation_sections",
        List.replace_at(Map.fetch!(report, "activation_sections"), 0, "invalid_section")
      )

    assert {:error, stale_activation_sections_report} =
             Schema.validate_artifact(stale_activation_sections,
               schema_contract: "manifest_field_reference.v1"
             )

    assert Enum.any?(
             stale_activation_sections_report["errors"],
             &(&1["path"] == "$.activation_sections[0]")
           )

    stale_supported_outputs = put_in(report, ["supported", "outputs"], ["events"])

    assert {:error, stale_supported_outputs_report} =
             Schema.validate_artifact(stale_supported_outputs,
               schema_contract: "manifest_field_reference.v1"
             )

    assert Enum.any?(
             stale_supported_outputs_report["errors"],
             &(&1["path"] == "$.supported.outputs")
           )
  end

  test "verifies curated study manifest lint reference fixtures" do
    fixture_id = "fixture.artifact.study_manifest_lint.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.study_manifest_lint.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = study_manifest_lint_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               study_manifest_lint_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      study_manifest_lint_fixture_observations()
      |> Map.put("error_count", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "error_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "study_manifest_lint.v1",
             report
           ) == Validation.artifact_observations("study_manifest_lint.v1", report)

    assert {:ok, %{"schema_contract" => "study_manifest_lint.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "study_manifest_lint.v1"
             )

    stale_error_count = Map.put(report, "error_count", 1)

    assert {:error, stale_error_count_report} =
             Schema.validate_artifact(stale_error_count,
               schema_contract: "study_manifest_lint.v1"
             )

    assert Enum.any?(
             stale_error_count_report["errors"],
             &(&1["path"] == "$.error_count")
           )

    stale_warning_count = Map.put(report, "warning_count", 1)

    assert {:error, stale_warning_count_report} =
             Schema.validate_artifact(stale_warning_count,
               schema_contract: "study_manifest_lint.v1"
             )

    assert Enum.any?(
             stale_warning_count_report["errors"],
             &(&1["path"] == "$.warning_count")
           )

    stale_status = Map.put(report, "status", "fail")

    assert {:error, stale_status_report} =
             Schema.validate_artifact(stale_status,
               schema_contract: "study_manifest_lint.v1"
             )

    assert Enum.any?(
             stale_status_report["errors"],
             &(&1["path"] == "$.status")
           )

    stale_duplicate_outputs =
      Map.put(report, "outputs", ["trajectories", "trajectories"])

    assert {:error, stale_duplicate_outputs_report} =
             Schema.validate_artifact(stale_duplicate_outputs,
               schema_contract: "study_manifest_lint.v1"
             )

    assert Enum.any?(
             stale_duplicate_outputs_report["errors"],
             &(&1["path"] == "$.outputs")
           )

    stale_unsupported_output = Map.put(report, "outputs", ["unsupported_output"])

    assert {:error, stale_unsupported_output_report} =
             Schema.validate_artifact(stale_unsupported_output,
               schema_contract: "study_manifest_lint.v1"
             )

    assert Enum.any?(
             stale_unsupported_output_report["errors"],
             &(&1["path"] == "$.outputs")
           )
  end
end
