defmodule OrbitalDynamics.Validation.ContactWindowFixtureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.Validation.ContactWindowFixtures,
    only: [
      contact_intent_fixture_observations: 0,
      contact_intent_fixture: 0,
      contact_intent_summary_fixture_observations: 0,
      contact_intent_summary_fixture: 0,
      refreshed_window_fixture_observations: 0,
      refreshed_window_fixture: 0,
      source_window_lineage_fixture_observations: 0,
      source_window_lineage_fixture: 0
    ]

  alias OrbitalDynamics.{Schema, Validation}

  test "verifies curated contact intent reference fixtures" do
    fixture_id = "fixture.artifact.contact_intent.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.contact_intent.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = contact_intent_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               contact_intent_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      contact_intent_fixture_observations()
      |> Map.put("approval_status", "approved")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "approval_status" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "contact_intent.v1")

    stale_policy_classification =
      put_in(report, ["policy_decision", "classification"], "auto_approvable")

    assert {:error, stale_policy_report} =
             Schema.validate_artifact(stale_policy_classification,
               schema_contract: "contact_intent.v1"
             )

    assert Enum.any?(
             stale_policy_report["errors"],
             &(&1["path"] == "$.policy_decision.classification")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_intent.v1",
             report
           ) == Validation.artifact_observations("contact_intent.v1", report)
  end

  test "verifies curated contact intent summary reference fixtures" do
    fixture_id = "fixture.artifact.contact_intent_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.contact_intent_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = contact_intent_summary_fixture()
    observations = contact_intent_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["contact_intent_count"] == 3
    assert observations["capacity_pack_required_contact_count"] == 3
    assert observations["capacity_pack_required_capacity_fraction"] == 0.95
    assert observations["direction_counts"] == %{"command" => 1, "downlink" => 1, "tracking" => 1}
    assert observations["direction_keys"] == "command|downlink|tracking"
    assert observations["ground_station_keys"] == "dss_43|equator_prime"

    assert observations["capacity_pack_required_capacity_fraction_by_direction"] == %{
             "command" => 0.5,
             "downlink" => 0.25,
             "tracking" => 0.2
           }

    assert observations["required_capacity_fraction_source_keys"] ==
             "capacity_model|contact_required_capacity_fraction|throughput_model"

    assert observations["execution_boundary"] ==
             "artifact_only_no_provider_reservation_or_schedule_mutation"

    assert observations["no_provider_reservation"] == true
    assert observations["no_schedule_mutation"] == true
    assert observations["no_command_execution"] == true

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_intent_summary.v1",
             report
           ) == Validation.artifact_observations("contact_intent_summary.v1", report)

    stale_direction_observations = put_in(observations, ["direction_counts", "downlink"], 0)

    assert {:ok, stale_direction_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_direction_observations)

    assert stale_direction_verification["status"] == "fail"

    assert Enum.any?(
             stale_direction_verification["checks"],
             &(&1["field"] == "direction_counts" and &1["status"] == "fail")
           )

    stale_capacity_observations =
      Map.put(observations, "capacity_pack_required_capacity_fraction", 0.5)

    assert {:ok, stale_capacity_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_capacity_observations)

    assert stale_capacity_verification["status"] == "fail"

    assert Enum.any?(
             stale_capacity_verification["checks"],
             &(&1["field"] == "capacity_pack_required_capacity_fraction" and
                 &1["status"] == "fail")
           )

    stale_boundary_observations =
      Map.put(observations, "execution_boundary", "provider_reservation_ready")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "execution_boundary" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "contact_intent_summary.v1")
  end

  test "verifies curated refreshed window reference fixtures" do
    fixture_id = "fixture.artifact.refreshed_window.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.refreshed_window.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = refreshed_window_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               refreshed_window_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      refreshed_window_fixture_observations()
      |> Map.put("sample_count", 4)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "sample_count" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "refreshed_window.v1")

    stale_sample_count = Map.put(report, "sample_count", 4)

    assert {:error, stale_sample_count_report} =
             Schema.validate_artifact(stale_sample_count, schema_contract: "refreshed_window.v1")

    assert Enum.any?(
             stale_sample_count_report["errors"],
             &(&1["path"] == "$.sample_count")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "refreshed_window.v1",
             report
           ) == Validation.artifact_observations("refreshed_window.v1", report)
  end

  test "verifies curated source window lineage reference fixtures" do
    fixture_id = "fixture.artifact.source_window_lineage.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.source_window_lineage.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = source_window_lineage_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               source_window_lineage_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      source_window_lineage_fixture_observations()
      |> Map.put("source_window_type", "target_visibility")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "source_window_type" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "source_window_lineage.v1")

    stale_source_window_type = Map.put(report, "source_window_type", "target_visibility")

    assert {:error, stale_source_window_type_report} =
             Schema.validate_artifact(stale_source_window_type,
               schema_contract: "source_window_lineage.v1"
             )

    assert Enum.any?(
             stale_source_window_type_report["errors"],
             &(&1["path"] == "$.source_window_type")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "source_window_lineage.v1",
             report
           ) == Validation.artifact_observations("source_window_lineage.v1", report)
  end
end
