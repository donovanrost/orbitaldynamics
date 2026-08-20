defmodule OrbitalDynamics.Validation.PlanningInputFixtureTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Validation}

  import OrbitalDynamics.Validation.PlanningInputFixtures,
    only: [
      campaign_request_lint_fixture: 0,
      campaign_request_lint_fixture_observations: 0,
      capability_catalog_fixture: 0,
      capability_catalog_fixture_observations: 0,
      environment_model_capability_fixture: 1,
      environment_provider_capability_fixture: 1
    ]

  test "verifies curated campaign request lint reference fixtures" do
    fixture_id = "fixture.artifact.campaign_request_lint.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.campaign_request_lint.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = campaign_request_lint_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               campaign_request_lint_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      campaign_request_lint_fixture_observations()
      |> Map.put("status", "fail")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "status" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "campaign_request_lint.v1")

    stale_status = Map.put(report, "status", "fail")

    assert {:error, stale_status_report} =
             Schema.validate_artifact(stale_status, schema_contract: "campaign_request_lint.v1")

    assert Enum.any?(
             stale_status_report["errors"],
             &(&1["path"] == "$.status")
           )

    stale_request_sha =
      put_in(report, ["request", "sha256"], String.upcase(report["request"]["sha256"]))

    assert {:error, stale_request_sha_report} =
             Schema.validate_artifact(stale_request_sha,
               schema_contract: "campaign_request_lint.v1"
             )

    assert Enum.any?(
             stale_request_sha_report["errors"],
             &(&1["path"] == "$.request.sha256")
           )

    stale_source_plan_sha =
      put_in(report, ["source_plan", "sha256"], "not-a-sha")

    assert {:error, stale_source_plan_sha_report} =
             Schema.validate_artifact(stale_source_plan_sha,
               schema_contract: "campaign_request_lint.v1"
             )

    assert Enum.any?(
             stale_source_plan_sha_report["errors"],
             &(&1["path"] == "$.source_plan.sha256")
           )

    assert OrbitalDynamics.validation_artifact_observations("campaign_request_lint.v1", report) ==
             Validation.artifact_observations("campaign_request_lint.v1", report)
  end

  test "verifies curated capability catalog reference fixtures" do
    fixture_id = "fixture.artifact.capability_catalog.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.capability_catalog.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = capability_catalog_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               capability_catalog_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    fixture_observations = capability_catalog_fixture_observations()

    assert fixture_observations["station_calendar_reservation_contract"] ==
             "station_reservation_report.v1"

    assert fixture_observations["candidate_refresh_input_count"] == 81
    assert fixture_observations["candidate_refresh_source_report_input_count"] == 64
    assert fixture_observations["candidate_refresh_source_report_helper_count"] == 40

    assert fixture_observations["candidate_refresh_source_report_input_order"] =~
             "schema_validation_batch_report"

    assert fixture_observations["candidate_refresh_source_report_input_order"] =~
             "timeline_dependency_impact_summary"

    assert fixture_observations["candidate_refresh_source_report_input_order"] =~
             "timeline_publication_summary"

    assert fixture_observations["candidate_refresh_source_report_input_order"] =~
             "timeline_activity_precondition_summary"

    assert fixture_observations["candidate_refresh_source_report_input_order"] =~
             "contact_contention_report"

    assert fixture_observations["candidate_refresh_source_report_input_order"] =~
             "relay_data_path_summary"

    assert fixture_observations["candidate_refresh_source_report_input_order"] =~
             "operational_import_eligibility_summary"

    assert fixture_observations["candidate_refresh_source_report_input_order"] =~
             "station_reservation_review_summary"

    assert fixture_observations["candidate_refresh_source_report_input_order"] =~
             "operational_quality_gate_schema_validation_summary"

    stale_observations =
      fixture_observations
      |> Map.put("artifact_contract_count", 78)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "artifact_contract_count" and &1["status"] == "fail")
           )

    stale_candidate_refresh_observations =
      fixture_observations
      |> Map.put("candidate_refresh_source_report_input_count", 33)

    assert {:ok, stale_candidate_refresh_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_candidate_refresh_observations)

    assert stale_candidate_refresh_verification["status"] == "fail"

    assert Enum.any?(
             stale_candidate_refresh_verification["checks"],
             &(&1["field"] == "candidate_refresh_source_report_input_count" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations("capability_catalog.v1", report) ==
             Validation.artifact_observations("capability_catalog.v1", report)

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "capability_catalog.v1")

    stale_contract_list =
      update_in(report, ["validation", "schema", "artifact_contracts"], &tl/1)

    assert {:error, stale_contract_list_report} =
             Schema.validate_artifact(stale_contract_list,
               schema_contract: "capability_catalog.v1"
             )

    assert Enum.any?(
             stale_contract_list_report["errors"],
             &(&1["path"] == "$.validation.schema.artifact_contracts")
           )
  end

  test "verifies curated environment capability reference fixtures" do
    tabular_earth_orientation_fixture_id =
      "fixture.artifact.environment_provider_capability.tabular_earth_orientation"

    tabular_earth_orientation_capability =
      environment_provider_capability_fixture(
        "environment.provider.earth_orientation.tabular_rotation"
      )

    fixtures = [
      {
        "fixture.artifact.environment_model_capability.fixed_sun",
        "environment_model_capability.v1",
        environment_model_capability_fixture("environment.solar.fixed_inertial_direction")
      },
      {
        "fixture.artifact.environment_model_capability.constant_earth_rotation",
        "environment_model_capability.v1",
        environment_model_capability_fixture("environment.earth_rotation.constant_rate")
      },
      {
        "fixture.artifact.environment_provider_capability.fixed_sun",
        "environment_provider_capability.v1",
        environment_provider_capability_fixture(
          "environment.provider.solar.fixed_inertial_direction"
        )
      },
      {
        "fixture.artifact.environment_provider_capability.constant_earth_rotation",
        "environment_provider_capability.v1",
        environment_provider_capability_fixture(
          "environment.provider.earth_rotation.constant_rate"
        )
      },
      {
        tabular_earth_orientation_fixture_id,
        "environment_provider_capability.v1",
        tabular_earth_orientation_capability
      },
      {
        "fixture.artifact.environment_provider_capability.exponential_atmosphere",
        "environment_provider_capability.v1",
        environment_provider_capability_fixture(
          "environment.provider.atmosphere.exponential_reference"
        )
      }
    ]

    assert {:ok, tabular_earth_orientation_fixture} =
             Validation.reference_fixture(tabular_earth_orientation_fixture_id)

    assert tabular_earth_orientation_capability["parameters"]
           |> Map.keys()
           |> Enum.sort() == ["file_input_integrity", "input_modes"]

    assert tabular_earth_orientation_fixture["expected"]["parameter_count"] ==
             map_size(tabular_earth_orientation_capability["parameters"])

    for {fixture_id, contract, artifact} <- fixtures do
      assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

      assert fixture["model_id"] == "artifact.#{contract}"
      assert fixture["fixture_type"] == "curated_runtime_capability_regression"

      observations = Validation.artifact_observations(contract, artifact)

      assert {:ok, verification} =
               Validation.verify_reference_fixture(fixture_id, observations)

      assert verification["status"] == "pass"
      assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

      assert OrbitalDynamics.validation_artifact_observations(contract, artifact) == observations
    end

    stale_observations =
      "environment_provider_capability.v1"
      |> Validation.artifact_observations(
        environment_provider_capability_fixture(
          "environment.provider.solar.fixed_inertial_direction"
        )
      )
      |> Map.put("network_access", true)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.environment_provider_capability.fixed_sun",
               stale_observations
             )

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "network_access" and &1["status"] == "fail")
           )

    model_capability =
      environment_model_capability_fixture("environment.solar.fixed_inertial_direction")

    assert {:ok, _valid_model_capability} =
             Schema.validate_artifact(model_capability,
               schema_contract: "environment_model_capability.v1"
             )

    stale_model_validation_level =
      Map.put(model_capability, "validation_level", "flight_certified")

    assert {:error, stale_model_validation_level_report} =
             Schema.validate_artifact(stale_model_validation_level,
               schema_contract: "environment_model_capability.v1"
             )

    assert Enum.any?(
             stale_model_validation_level_report["errors"],
             &(&1["path"] == "$.validation_level")
           )
  end
end
