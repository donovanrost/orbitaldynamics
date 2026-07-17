defmodule OrbitalDynamics.Validation.ResourcePressureHandoffFixtureTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Validation}

  import OrbitalDynamics.Validation.ResourcePressureHandoffFixtures,
    only: [
      cadence_import_resource_pressure_fixture: 0,
      cadence_import_resource_pressure_fixture_observations: 0,
      operational_readiness_resource_pressure_fixture_observations: 0,
      operator_review_resource_pressure_fixture: 0,
      operator_review_resource_pressure_fixture_observations: 0,
      quality_gate_resource_pressure_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.CandidateRefreshReadinessReplayFixtures,
    only: [
      operational_readiness_resource_pressure_fixture: 0,
      quality_gate_resource_pressure_fixture: 0
    ]

  test "verifies curated resource pressure handoff reference fixtures" do
    fixtures = [
      {
        "fixture.artifact.quality_gate_report.resource_pressure_v1",
        "quality_gate_report.v1",
        quality_gate_resource_pressure_fixture(),
        quality_gate_resource_pressure_fixture_observations()
      },
      {
        "fixture.artifact.operational_readiness_report.resource_pressure_v1",
        "operational_readiness_report.v1",
        operational_readiness_resource_pressure_fixture(),
        operational_readiness_resource_pressure_fixture_observations()
      },
      {
        "fixture.artifact.operator_review_package.resource_pressure_v1",
        "operator_review_package.v1",
        operator_review_resource_pressure_fixture(),
        operator_review_resource_pressure_fixture_observations()
      },
      {
        "fixture.artifact.cadence_import_manifest.resource_pressure_v1",
        "cadence_import_manifest.v1",
        cadence_import_resource_pressure_fixture(),
        cadence_import_resource_pressure_fixture_observations()
      }
    ]

    for {fixture_id, contract, artifact, observations} <- fixtures do
      assert {:ok, fixture} = Validation.reference_fixture(fixture_id)
      assert fixture["fixture_type"] == "curated_internal_artifact_regression"

      assert {:ok, verification} =
               Validation.verify_reference_fixture(fixture_id, observations)

      assert verification["status"] == "pass"
      assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

      assert {:ok, _schema_report} =
               Schema.validate_artifact(artifact, schema_contract: contract)

      assert OrbitalDynamics.validation_artifact_observations(contract, artifact) ==
               Validation.artifact_observations(contract, artifact)
    end

    quality_gate_observations = quality_gate_resource_pressure_fixture_observations()

    assert quality_gate_observations["resource_availability_gate_count"] == 1
    assert quality_gate_observations["row_derived_resource_availability_pressure_count"] == 2

    assert quality_gate_observations["row_derived_resource_availability_reason_counts"] == %{
             "antenna_unavailable" => 1,
             "payload_unavailable" => 1
           }

    readiness_observations = operational_readiness_resource_pressure_fixture_observations()

    assert readiness_observations["resource_availability_pressure_count"] == 2

    assert readiness_observations["row_derived_resource_availability_reason_keys"] ==
             "antenna_unavailable|payload_unavailable"

    review_observations = operator_review_resource_pressure_fixture_observations()

    assert review_observations["resource_availability_review_row_count"] == 2
    assert review_observations["row_derived_resource_availability_pressure_count"] == 4

    import_observations = cadence_import_resource_pressure_fixture_observations()

    assert import_observations["resource_availability_import_row_count"] == 2
    assert import_observations["row_derived_resource_availability_pressure_count"] == 4

    stale_quality_gate_observations =
      quality_gate_observations
      |> Map.put("resource_availability_gate_count", 0)

    assert {:ok, stale_quality_gate_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.quality_gate_report.resource_pressure_v1",
               stale_quality_gate_observations
             )

    assert stale_quality_gate_verification["status"] == "fail"

    assert Enum.any?(
             stale_quality_gate_verification["checks"],
             &(&1["field"] == "resource_availability_gate_count" and &1["status"] == "fail")
           )

    stale_readiness_observations =
      readiness_observations
      |> Map.put("resource_availability_pressure_count", 0)

    assert {:ok, stale_readiness_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.operational_readiness_report.resource_pressure_v1",
               stale_readiness_observations
             )

    assert stale_readiness_verification["status"] == "fail"

    assert Enum.any?(
             stale_readiness_verification["checks"],
             &(&1["field"] == "resource_availability_pressure_count" and
                 &1["status"] == "fail")
           )

    stale_review_observations =
      review_observations
      |> Map.put("resource_availability_review_row_count", 1)

    assert {:ok, stale_review_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.operator_review_package.resource_pressure_v1",
               stale_review_observations
             )

    assert stale_review_verification["status"] == "fail"

    assert Enum.any?(
             stale_review_verification["checks"],
             &(&1["field"] == "resource_availability_review_row_count" and
                 &1["status"] == "fail")
           )

    stale_import_observations =
      import_observations
      |> put_in(["row_derived_resource_availability_reason_counts", "antenna_unavailable"], 1)

    assert {:ok, stale_import_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.cadence_import_manifest.resource_pressure_v1",
               stale_import_observations
             )

    assert stale_import_verification["status"] == "fail"

    assert Enum.any?(
             stale_import_verification["checks"],
             &(&1["field"] == "row_derived_resource_availability_reason_counts" and
                 &1["status"] == "fail")
           )
  end
end
