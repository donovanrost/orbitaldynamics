defmodule OrbitalDynamics.Validation.CandidateRefreshBaseFixtureTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Validation}

  import OrbitalDynamics.Validation.CandidateRefreshBaseFixtures,
    only: [
      candidate_refresh_fixture: 0,
      candidate_refresh_fixture_observations: 0,
      candidate_refresh_resource_provenance_fixture: 0,
      candidate_refresh_resource_provenance_fixture_observations: 0
    ]

  test "verifies curated candidate refresh artifact reference fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               candidate_refresh_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert OrbitalDynamics.validation_artifact_observations("candidate_refresh.v1", artifact) ==
             Validation.artifact_observations("candidate_refresh.v1", artifact)

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")

    stale_validation_level =
      put_in(
        artifact,
        ["validation_records", Access.at(0), "validation_level"],
        "flight_certified"
      )

    assert {:error, stale_validation_level_report} =
             Schema.validate_artifact(stale_validation_level,
               schema_contract: "candidate_refresh.v1"
             )

    assert Enum.any?(
             stale_validation_level_report["errors"],
             &(&1["path"] == "$.validation_records[0].validation_level")
           )
  end

  test "verifies curated candidate refresh resource provenance reference fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.resource_provenance_v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_resource_provenance_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               candidate_refresh_resource_provenance_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert get_in(artifact, [
             "provenance",
             "source_reports",
             "operational_readiness_report",
             "resource_availability_reason_counts"
           ]) == %{"antenna_unavailable" => 1, "payload_unavailable" => 1}

    assert get_in(artifact, [
             "provenance",
             "source_reports",
             "quality_gate_report",
             "resource_availability_reason_ids"
           ]) == ["antenna_unavailable", "payload_unavailable"]

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")

    stale_resource_pressure_count =
      put_in(
        artifact,
        [
          "provenance",
          "source_reports",
          "operational_readiness_report",
          "resource_availability_pressure_count"
        ],
        1
      )

    assert {:error, stale_resource_pressure_report} =
             Schema.validate_artifact(stale_resource_pressure_count,
               schema_contract: "candidate_refresh.v1"
             )

    assert Enum.any?(
             stale_resource_pressure_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.operational_readiness_report.resource_availability_pressure_count")
           )
  end
end
