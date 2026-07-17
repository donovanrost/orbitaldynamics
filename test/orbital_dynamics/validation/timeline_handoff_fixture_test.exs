defmodule OrbitalDynamics.Validation.TimelineHandoffFixtureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.Validation.TimelineHandoffFixtures,
    only: [
      timeline_diff_report_fixture_observations: 0,
      timeline_diff_report_fixture: 0,
      timeline_feedback_report_fixture_observations: 0,
      timeline_feedback_report_fixture: 0,
      cadence_import_manifest_fixture_observations: 0,
      cadence_import_manifest_fixture: 0
    ]

  alias OrbitalDynamics.{Schema, Validation}

  test "verifies curated timeline diff report reference fixtures" do
    fixture_id = "fixture.artifact.timeline_diff_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_diff_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_diff_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               timeline_diff_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      timeline_diff_report_fixture_observations()
      |> Map.put("review_required_count", 3)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "review_required_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      timeline_diff_report_fixture_observations()
      |> put_in(["row_derived_diff_status_counts", "changed"], 1)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_diff_status_counts" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "timeline_diff_report.v1")

    stale_row_count = Map.put(report, "row_count", 0)

    assert {:error, stale_row_count_report} =
             Schema.validate_artifact(stale_row_count,
               schema_contract: "timeline_diff_report.v1"
             )

    assert Enum.any?(
             stale_row_count_report["errors"],
             &(&1["path"] == "$.row_count")
           )

    stale_added_count = Map.put(report, "added_count", 0)

    assert {:error, stale_added_count_report} =
             Schema.validate_artifact(stale_added_count,
               schema_contract: "timeline_diff_report.v1"
             )

    assert Enum.any?(
             stale_added_count_report["errors"],
             &(&1["path"] == "$.added_count")
           )

    stale_model_limits = Map.put(report, "model_limits", ["artifact_level_only"])

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "timeline_diff_report.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_diff_report.v1",
             report
           ) == Validation.artifact_observations("timeline_diff_report.v1", report)
  end

  test "verifies curated timeline feedback report reference fixtures" do
    fixture_id = "fixture.artifact.timeline_feedback_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_feedback_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_feedback_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               timeline_feedback_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      timeline_feedback_report_fixture_observations()
      |> Map.put("execution_uncertainty_missing_count", 0)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "execution_uncertainty_missing_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      timeline_feedback_report_fixture_observations()
      |> put_in(["row_derived_feedback_kind_counts", "maneuver"], 0)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_feedback_kind_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "timeline_feedback_report.v1")

    stale_row_count = Map.put(report, "row_count", 0)

    assert {:error, stale_row_count_report} =
             Schema.validate_artifact(stale_row_count,
               schema_contract: "timeline_feedback_report.v1"
             )

    assert Enum.any?(
             stale_row_count_report["errors"],
             &(&1["path"] == "$.row_count")
           )

    stale_model_limits = Map.put(report, "model_limits", ["artifact_level_only"])

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "timeline_feedback_report.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_feedback_report.v1",
             report
           ) == Validation.artifact_observations("timeline_feedback_report.v1", report)
  end

  test "verifies curated Cadence import manifest reference fixtures" do
    fixture_id = "fixture.artifact.cadence_import_manifest.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.cadence_import_manifest.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = cadence_import_manifest_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               cadence_import_manifest_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      cadence_import_manifest_fixture_observations()
      |> Map.put("blocked_count", 0)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "blocked_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      cadence_import_manifest_fixture_observations()
      |> put_in(["row_derived_import_status_counts", "blocked_missing_cadence_import"], 0)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_import_status_counts" and &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(artifact,
               schema_contract: "cadence_import_manifest.v1"
             )

    stale_row_count = Map.put(artifact, "row_count", 1)

    assert {:error, stale_row_count_report} =
             Schema.validate_artifact(stale_row_count,
               schema_contract: "cadence_import_manifest.v1"
             )

    assert Enum.any?(
             stale_row_count_report["errors"],
             &(&1["path"] == "$.row_count")
           )

    stale_ready_count = Map.put(artifact, "ready_count", 0)

    assert {:error, stale_ready_count_report} =
             Schema.validate_artifact(stale_ready_count,
               schema_contract: "cadence_import_manifest.v1"
             )

    assert Enum.any?(
             stale_ready_count_report["errors"],
             &(&1["path"] == "$.ready_count")
           )

    stale_import_action_counts = Map.put(artifact, "import_action_counts", %{})

    assert {:error, stale_import_action_counts_report} =
             Schema.validate_artifact(stale_import_action_counts,
               schema_contract: "cadence_import_manifest.v1"
             )

    assert Enum.any?(
             stale_import_action_counts_report["errors"],
             &(&1["path"] == "$.import_action_counts")
           )

    stale_import_status_counts =
      put_in(artifact, ["import_status_counts", "blocked_missing_cadence_import"], 0)

    assert {:error, stale_import_status_counts_report} =
             Schema.validate_artifact(stale_import_status_counts,
               schema_contract: "cadence_import_manifest.v1"
             )

    assert Enum.any?(
             stale_import_status_counts_report["errors"],
             &(&1["path"] == "$.import_status_counts")
           )

    stale_model_limits =
      Map.put(artifact, "model_limits", Enum.drop(Map.fetch!(artifact, "model_limits"), 1))

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "cadence_import_manifest.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )

    stale_execution_boundary =
      put_in(artifact, ["assumptions", "execution_boundary"], "cadence_api_write_ready")

    assert {:error, stale_execution_boundary_report} =
             Schema.validate_artifact(stale_execution_boundary,
               schema_contract: "cadence_import_manifest.v1"
             )

    assert Enum.any?(
             stale_execution_boundary_report["errors"],
             &(&1["path"] == "$.assumptions.execution_boundary")
           )

    stale_authorization_boundary =
      put_in(artifact, ["assumptions", "authorization_boundary"], "already_authorized")

    assert {:error, stale_authorization_boundary_report} =
             Schema.validate_artifact(stale_authorization_boundary,
               schema_contract: "cadence_import_manifest.v1"
             )

    assert Enum.any?(
             stale_authorization_boundary_report["errors"],
             &(&1["path"] == "$.assumptions.authorization_boundary")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "cadence_import_manifest.v1",
             artifact
           ) == Validation.artifact_observations("cadence_import_manifest.v1", artifact)
  end
end
