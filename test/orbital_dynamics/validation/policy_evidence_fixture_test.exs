defmodule OrbitalDynamics.Validation.PolicyEvidenceFixtureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.Validation.PolicyEvidenceFixtures,
    only: [
      backend_acceptance_policy_fixture_observations: 0,
      backend_acceptance_policy_fixture: 0,
      validation_tolerance_policy_fixture_observations: 0,
      validation_tolerance_policy_fixture: 0,
      validation_record_fixture_observations: 0,
      validation_record_fixture: 0,
      validation_check_fixture_observations: 0,
      validation_check_fixture: 0
    ]

  alias OrbitalDynamics.{Schema, Validation}

  test "verifies curated backend acceptance policy reference fixtures" do
    fixture_id = "fixture.artifact.backend_acceptance_policy.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.backend_acceptance_policy.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = backend_acceptance_policy_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               backend_acceptance_policy_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      backend_acceptance_policy_fixture_observations()
      |> Map.put("implementation_count", 5)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "implementation_count" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "backend_acceptance_policy.v1")

    stale_reference_tier =
      put_in(
        report,
        ["implementation_tiers", "OrbitalDynamics.Propagators.TwoBody"],
        "experimental_accelerator"
      )

    assert {:error, stale_reference_tier_report} =
             Schema.validate_artifact(stale_reference_tier,
               schema_contract: "backend_acceptance_policy.v1"
             )

    assert Enum.any?(
             stale_reference_tier_report["errors"],
             &(&1["path"] == "$.reference_backend.implementations[0]")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "backend_acceptance_policy.v1",
             report
           ) == Validation.artifact_observations("backend_acceptance_policy.v1", report)
  end

  test "verifies curated validation tolerance policy reference fixtures" do
    fixture_id = "fixture.artifact.validation_tolerance_policy.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.validation_tolerance_policy.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = validation_tolerance_policy_fixture()
    assert report == Validation.tolerance_policy()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               validation_tolerance_policy_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      validation_tolerance_policy_fixture_observations()
      |> Map.put("validation_level_count", 4)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "validation_level_count" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "validation_tolerance_policy.v1")

    stale_validation_levels =
      update_in(report, ["validation_levels"], &Map.delete(&1, "validated"))

    assert {:error, stale_validation_levels_report} =
             Schema.validate_artifact(stale_validation_levels,
               schema_contract: "validation_tolerance_policy.v1"
             )

    assert Enum.any?(
             stale_validation_levels_report["errors"],
             &(&1["path"] == "$.validation_levels")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "validation_tolerance_policy.v1",
             report
           ) == Validation.artifact_observations("validation_tolerance_policy.v1", report)
  end

  test "verifies curated validation record reference fixtures" do
    fixture_id = "fixture.artifact.validation_record.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.validation_record.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = validation_record_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               validation_record_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      validation_record_fixture_observations()
      |> Map.put("validation_level", "validated")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "validation_level" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "validation_record.v1")

    stale_validation_level = Map.put(report, "validation_level", "flight_certified")

    assert {:error, stale_validation_level_report} =
             Schema.validate_artifact(stale_validation_level,
               schema_contract: "validation_record.v1"
             )

    assert Enum.any?(
             stale_validation_level_report["errors"],
             &(&1["path"] == "$.validation_level")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "validation_record.v1",
             report
           ) == Validation.artifact_observations("validation_record.v1", report)
  end

  test "verifies curated validation check reference fixtures" do
    fixture_id = "fixture.artifact.validation_check.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.validation_check.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = validation_check_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               validation_check_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      validation_check_fixture_observations()
      |> Map.put("status", "fail")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "status" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "validation_check.v1",
             report
           ) == Validation.artifact_observations("validation_check.v1", report)

    assert {:ok, %{"schema_contract" => "validation_check.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "validation_check.v1"
             )

    stale_status = Map.put(report, "status", "fail")

    assert {:error, stale_status_report} =
             Schema.validate_artifact(stale_status,
               schema_contract: "validation_check.v1"
             )

    assert Enum.any?(stale_status_report["errors"], &(&1["path"] == "$.status"))

    stale_observed = Map.put(report, "observed", 2)

    assert {:error, stale_observed_report} =
             Schema.validate_artifact(stale_observed,
               schema_contract: "validation_check.v1"
             )

    assert Enum.any?(stale_observed_report["errors"], &(&1["path"] == "$.status"))
    assert Enum.any?(stale_observed_report["errors"], &(&1["path"] == "$.error"))

    stale_error = Map.put(report, "error", 1)

    assert {:error, stale_error_report} =
             Schema.validate_artifact(stale_error,
               schema_contract: "validation_check.v1"
             )

    assert Enum.any?(stale_error_report["errors"], &(&1["path"] == "$.error"))
  end
end
