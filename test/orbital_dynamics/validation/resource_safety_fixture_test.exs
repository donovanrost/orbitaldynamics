defmodule OrbitalDynamics.Validation.ResourceSafetyFixtureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.Validation.ResourceSafetyFixtures,
    only: [
      resource_projection_battery_handoff_fixture_observations: 0,
      resource_projection_battery_handoff_fixture: 0,
      operator_review_resource_projection_battery_handoff_fixture_observations: 0,
      operator_review_resource_projection_battery_handoff_fixture: 0,
      cadence_import_resource_projection_battery_handoff_fixture_observations: 0,
      cadence_import_resource_projection_battery_handoff_fixture: 0,
      resource_projection_stale_margin_fixture_observations: 0,
      resource_projection_stale_margin_fixture: 0,
      resource_filter_stale_margin_fixture_observations: 0,
      resource_filter_stale_margin_fixture: 0
    ]

  alias OrbitalDynamics.{Schema, Validation}

  test "verifies resource projection battery handoff reference fixtures" do
    fixtures = [
      {
        "fixture.artifact.resource_projection_report.battery_handoff_v1",
        "resource_projection_report.v1",
        resource_projection_battery_handoff_fixture(),
        resource_projection_battery_handoff_fixture_observations()
      },
      {
        "fixture.artifact.operator_review_package.resource_projection_battery_handoff_v1",
        "operator_review_package.v1",
        operator_review_resource_projection_battery_handoff_fixture(),
        operator_review_resource_projection_battery_handoff_fixture_observations()
      },
      {
        "fixture.artifact.cadence_import_manifest.resource_projection_battery_handoff_v1",
        "cadence_import_manifest.v1",
        cadence_import_resource_projection_battery_handoff_fixture(),
        cadence_import_resource_projection_battery_handoff_fixture_observations()
      }
    ]

    Enum.each(fixtures, fn {fixture_id, contract, artifact, observations} ->
      assert {:ok, fixture} = Validation.reference_fixture(fixture_id)
      assert fixture["fixture_type"] == "curated_internal_artifact_regression"

      assert {:ok, %{"schema_contract" => ^contract}} =
               OrbitalDynamics.Schema.validate_artifact(artifact)

      assert {:ok, verification} =
               Validation.verify_reference_fixture(fixture_id, observations)

      assert verification["status"] == "pass"
      assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))
    end)

    stale_observations =
      operator_review_resource_projection_battery_handoff_fixture_observations()
      |> Map.put("net_resource_projection_battery_energy_delta_wh", 16.0)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.operator_review_package.resource_projection_battery_handoff_v1",
               stale_observations
             )

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "net_resource_projection_battery_energy_delta_wh" and
                 &1["status"] == "fail")
           )
  end

  test "verifies stale derived-margin resource summary reference fixtures" do
    fixtures = [
      {
        "fixture.artifact.resource_projection_report.stale_resource_summary_margins",
        "resource_projection_report.v1",
        resource_projection_stale_margin_fixture(),
        resource_projection_stale_margin_fixture_observations()
      },
      {
        "fixture.artifact.resource_filter_report.stale_resource_summary_margins",
        "resource_filter_report.v1",
        resource_filter_stale_margin_fixture(),
        resource_filter_stale_margin_fixture_observations()
      }
    ]

    Enum.each(fixtures, fn {fixture_id, contract, artifact, observations} ->
      assert {:ok, fixture} = Validation.reference_fixture(fixture_id)
      assert fixture["fixture_type"] == "curated_internal_artifact_regression"

      assert {:ok, %{"schema_contract" => ^contract}} =
               Schema.validate_artifact(artifact)

      assert {:ok, verification} =
               Validation.verify_reference_fixture(fixture_id, observations)

      assert verification["status"] == "pass"
      assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

      assert observations["invalid_resource_summary_input_reasons"] ==
               "stale_battery_state_of_charge|stale_storage_margin"
    end)

    stale_observations =
      resource_projection_stale_margin_fixture_observations()
      |> Map.put("stale_storage_margin_count", 0)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.resource_projection_report.stale_resource_summary_margins",
               stale_observations
             )

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "stale_storage_margin_count" and &1["status"] == "fail")
           )

    stale_projection_count =
      resource_projection_stale_margin_fixture()
      |> Map.put("invalid_resource_summary_input_count", 1)

    assert {:error, stale_projection_count_report} =
             Schema.validate_artifact(stale_projection_count,
               schema_contract: "resource_projection_report.v1"
             )

    assert Enum.any?(
             stale_projection_count_report["errors"],
             &(&1["path"] == "$.invalid_resource_summary_input_count")
           )

    stale_projection_ids =
      resource_projection_stale_margin_fixture()
      |> Map.put("invalid_resource_summary_input_ids", ["leo_2"])

    assert {:error, stale_projection_ids_report} =
             Schema.validate_artifact(stale_projection_ids,
               schema_contract: "resource_projection_report.v1"
             )

    assert Enum.any?(
             stale_projection_ids_report["errors"],
             &(&1["path"] == "$.invalid_resource_summary_input_ids")
           )

    stale_filter_count =
      resource_filter_stale_margin_fixture()
      |> Map.put("invalid_resource_summary_input_count", 1)

    assert {:error, stale_filter_count_report} =
             Schema.validate_artifact(stale_filter_count,
               schema_contract: "resource_filter_report.v1"
             )

    assert Enum.any?(
             stale_filter_count_report["errors"],
             &(&1["path"] == "$.invalid_resource_summary_input_count")
           )
  end
end
