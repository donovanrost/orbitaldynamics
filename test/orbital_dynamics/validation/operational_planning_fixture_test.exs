defmodule OrbitalDynamics.Validation.OperationalPlanningFixtureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.Validation.OperationalPlanningFixtures,
    only: [
      command_window_report_fixture_observations: 0,
      command_window_report_fixture: 0,
      constraint_report_fixture_observations: 0,
      constraint_report_fixture: 0,
      operational_timeline_report_fixture_observations: 0,
      operational_timeline_report_fixture: 0,
      generated_operational_timeline_report_fixture: 0
    ]

  alias OrbitalDynamics.{Schema, Validation}

  test "verifies curated command window report reference fixtures" do
    fixture_id = "fixture.artifact.command_window_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.command_window_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = command_window_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               command_window_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      command_window_report_fixture_observations()
      |> Map.put("review_required_count", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "review_required_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      command_window_report_fixture_observations()
      |> put_in(["row_derived_required_operator_action_counts", "monitor_activity"], 1)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_required_operator_action_counts" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "command_window_report.v1",
             report
           ) == Validation.artifact_observations("command_window_report.v1", report)

    assert {:ok, %{"schema_contract" => "command_window_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "command_window_report.v1"
             )

    stale_window_count = Map.put(report, "window_count", 3)

    assert {:error, stale_window_count_report} =
             Schema.validate_artifact(stale_window_count,
               schema_contract: "command_window_report.v1"
             )

    assert Enum.any?(
             stale_window_count_report["errors"],
             &(&1["path"] == "$.window_count")
           )

    stale_command_count = Map.put(report, "command_count", 2)

    assert {:error, stale_command_count_report} =
             Schema.validate_artifact(stale_command_count,
               schema_contract: "command_window_report.v1"
             )

    assert Enum.any?(
             stale_command_count_report["errors"],
             &(&1["path"] == "$.command_count")
           )

    stale_review_required_count = Map.put(report, "review_required_count", 1)

    assert {:error, stale_review_required_count_report} =
             Schema.validate_artifact(stale_review_required_count,
               schema_contract: "command_window_report.v1"
             )

    assert Enum.any?(
             stale_review_required_count_report["errors"],
             &(&1["path"] == "$.review_required_count")
           )

    stale_source_window_lineage_count = Map.put(report, "source_window_lineage_count", 0)

    assert {:error, stale_source_window_lineage_count_report} =
             Schema.validate_artifact(stale_source_window_lineage_count,
               schema_contract: "command_window_report.v1"
             )

    assert Enum.any?(
             stale_source_window_lineage_count_report["errors"],
             &(&1["path"] == "$.source_window_lineage_count")
           )
  end

  test "verifies curated constraint report reference fixtures" do
    fixture_id = "fixture.artifact.constraint_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.constraint_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = constraint_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               constraint_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      constraint_report_fixture_observations()
      |> Map.put("status_counts", %{"fail" => 2, "pass" => 1})

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "status_counts" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      constraint_report_fixture_observations()
      |> put_in(["row_derived_status_counts", "warning"], 0)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_status_counts" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "constraint_report.v1",
             report
           ) == Validation.artifact_observations("constraint_report.v1", report)

    assert {:ok, %{"schema_contract" => "constraint_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "constraint_report.v1"
             )

    stale_constraint_count = Map.put(report, "constraint_count", 3)

    assert {:error, stale_constraint_count_report} =
             Schema.validate_artifact(stale_constraint_count,
               schema_contract: "constraint_report.v1"
             )

    assert Enum.any?(
             stale_constraint_count_report["errors"],
             &(&1["path"] == "$.constraint_count")
           )

    stale_row_count = Map.put(report, "row_count", 2)

    assert {:error, stale_row_count_report} =
             Schema.validate_artifact(stale_row_count,
               schema_contract: "constraint_report.v1"
             )

    assert Enum.any?(
             stale_row_count_report["errors"],
             &(&1["path"] == "$.row_count")
           )

    stale_status = Map.put(report, "status", "warning")

    assert {:error, stale_status_report} =
             Schema.validate_artifact(stale_status,
               schema_contract: "constraint_report.v1"
             )

    assert Enum.any?(
             stale_status_report["errors"],
             &(&1["path"] == "$.status")
           )

    stale_status_counts = put_in(report, ["status_counts", "warning"], 0)

    assert {:error, stale_status_counts_report} =
             Schema.validate_artifact(stale_status_counts,
               schema_contract: "constraint_report.v1"
             )

    assert Enum.any?(
             stale_status_counts_report["errors"],
             &(&1["path"] == "$.status_counts")
           )
  end

  test "verifies curated operational timeline report reference fixtures" do
    fixture_id = "fixture.artifact.operational_timeline_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.operational_timeline_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_timeline_report_fixture()

    assert generated_operational_timeline_report_fixture() == report

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               operational_timeline_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      operational_timeline_report_fixture_observations()
      |> Map.put("timeline_integrity_review_count", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "timeline_integrity_review_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      operational_timeline_report_fixture_observations()
      |> put_in(["row_derived_required_operator_action_counts", "review_timeline_integrity"], 1)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_required_operator_action_counts" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_timeline_report.v1",
             report
           ) == Validation.artifact_observations("operational_timeline_report.v1", report)

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "operational_timeline_report.v1"
             )

    stale_row_count = Map.put(report, "row_count", 2)

    assert {:error, stale_row_count_report} =
             Schema.validate_artifact(stale_row_count,
               schema_contract: "operational_timeline_report.v1"
             )

    assert Enum.any?(
             stale_row_count_report["errors"],
             &(&1["path"] == "$.row_count")
           )

    stale_activity_status_counts = put_in(report, ["activity_status_counts", "planned"], 2)

    assert {:error, stale_activity_status_counts_report} =
             Schema.validate_artifact(stale_activity_status_counts,
               schema_contract: "operational_timeline_report.v1"
             )

    assert Enum.any?(
             stale_activity_status_counts_report["errors"],
             &(&1["path"] == "$.activity_status_counts")
           )

    stale_required_operator_action_counts =
      put_in(report, ["required_operator_action_counts", "review_timeline_integrity"], 1)

    assert {:error, stale_required_operator_action_counts_report} =
             Schema.validate_artifact(stale_required_operator_action_counts,
               schema_contract: "operational_timeline_report.v1"
             )

    assert Enum.any?(
             stale_required_operator_action_counts_report["errors"],
             &(&1["path"] == "$.required_operator_action_counts")
           )

    stale_cadence_import_status_counts =
      put_in(report, ["cadence_import_status_counts", "present"], 0)

    assert {:error, stale_cadence_import_status_counts_report} =
             Schema.validate_artifact(stale_cadence_import_status_counts,
               schema_contract: "operational_timeline_report.v1"
             )

    assert Enum.any?(
             stale_cadence_import_status_counts_report["errors"],
             &(&1["path"] == "$.cadence_import_status_counts")
           )

    stale_timeline_integrity_issue_count = Map.put(report, "timeline_integrity_issue_count", 4)

    assert {:error, stale_timeline_integrity_issue_count_report} =
             Schema.validate_artifact(stale_timeline_integrity_issue_count,
               schema_contract: "operational_timeline_report.v1"
             )

    assert Enum.any?(
             stale_timeline_integrity_issue_count_report["errors"],
             &(&1["path"] == "$.timeline_integrity_issue_count")
           )
  end
end
