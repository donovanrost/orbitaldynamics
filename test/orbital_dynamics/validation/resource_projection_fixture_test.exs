defmodule OrbitalDynamics.Validation.ResourceProjectionFixtureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.Validation.ResourceProjectionFixtures,
    only: [
      resource_projection_report_fixture_observations: 0,
      resource_projection_report_fixture: 0,
      resource_projection_flow_summary_fixture_observations: 0,
      resource_projection_flow_summary_fixture: 0
    ]

  alias OrbitalDynamics.{Schema, Validation}

  test "verifies curated resource projection report reference fixtures" do
    fixture_id = "fixture.artifact.resource_projection_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.resource_projection_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = resource_projection_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               resource_projection_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      resource_projection_report_fixture_observations()
      |> Map.put("downlink_shortfall_row_count", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "downlink_shortfall_row_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "resource_projection_report.v1",
             report
           ) == Validation.artifact_observations("resource_projection_report.v1", report)

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "resource_projection_report.v1"
             )

    stale_scalar_fields = [
      {"input_resource_summary_count", 0},
      {"valid_resource_summary_count", 0},
      {"activity_count", 2},
      {"valid_activity_count", 0},
      {"invalid_activity_input_count", 1}
    ]

    Enum.each(stale_scalar_fields, fn {field, stale_value} ->
      stale_report = Map.put(report, field, stale_value)

      assert {:error, stale_validation_report} =
               Schema.validate_artifact(stale_report,
                 schema_contract: "resource_projection_report.v1"
               )

      assert Enum.any?(stale_validation_report["errors"], &(&1["path"] == "$.#{field}"))
    end)

    stale_warnings = Map.put(report, "warnings", ["stale_resource_projection_warning"])

    assert {:error, stale_warnings_report} =
             Schema.validate_artifact(stale_warnings,
               schema_contract: "resource_projection_report.v1"
             )

    assert Enum.any?(stale_warnings_report["errors"], &(&1["path"] == "$.warnings"))

    stale_source_quality_counts =
      put_in(report, ["resource_source_quality_counts", "operator_supplied"], 0)

    assert {:error, stale_source_quality_counts_report} =
             Schema.validate_artifact(stale_source_quality_counts,
               schema_contract: "resource_projection_report.v1"
             )

    assert Enum.any?(
             stale_source_quality_counts_report["errors"],
             &(&1["path"] == "$.resource_source_quality_counts")
           )

    stale_trust_boundary_counts =
      put_in(report, ["resource_trust_boundary_status_counts", "missing"], 0)

    assert {:error, stale_trust_boundary_counts_report} =
             Schema.validate_artifact(stale_trust_boundary_counts,
               schema_contract: "resource_projection_report.v1"
             )

    assert Enum.any?(
             stale_trust_boundary_counts_report["errors"],
             &(&1["path"] == "$.resource_trust_boundary_status_counts")
           )

    stale_limits = Map.put(report, "model_limits", ["stale_resource_projection_boundary"])

    assert {:error, stale_limits_report} =
             Schema.validate_artifact(stale_limits,
               schema_contract: "resource_projection_report.v1"
             )

    assert Enum.any?(stale_limits_report["errors"], &(&1["path"] == "$.model_limits"))
  end

  test "verifies curated resource projection flow summary reference fixtures" do
    fixture_id = "fixture.artifact.resource_projection_flow_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.resource_projection_flow_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    summary = resource_projection_flow_summary_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               resource_projection_flow_summary_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      resource_projection_flow_summary_fixture_observations()
      |> Map.put("total_battery_energy_consumed_wh", 0.0)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "total_battery_energy_consumed_wh" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "resource_projection_flow_summary.v1",
             summary
           ) == Validation.artifact_observations("resource_projection_flow_summary.v1", summary)

    assert {:ok, %{"schema_contract" => "resource_projection_flow_summary.v1"}} =
             Schema.validate_artifact(summary,
               schema_contract: "resource_projection_flow_summary.v1"
             )
  end
end
