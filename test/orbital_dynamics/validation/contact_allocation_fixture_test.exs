defmodule OrbitalDynamics.Validation.ContactAllocationFixtureTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Validation}

  import OrbitalDynamics.Validation.ContactAllocationFixtures,
    only: [
      contact_allocation_report_fixture: 0,
      contact_allocation_report_fixture_observations: 0
    ]

  test "verifies curated contact allocation report reference fixtures" do
    fixture_id = "fixture.artifact.contact_allocation_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.contact_allocation_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = contact_allocation_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               contact_allocation_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      contact_allocation_report_fixture_observations()
      |> Map.put("blocked_contact_count", 2)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "blocked_contact_count" and &1["status"] == "fail")
           )

    stale_row_derived_count_observations =
      contact_allocation_report_fixture_observations()
      |> Map.put("row_derived_blocked_contact_count", 2)

    assert {:ok, stale_row_derived_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_count_observations)

    assert stale_row_derived_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_count_verification["checks"],
             &(&1["field"] == "row_derived_blocked_contact_count" and
                 &1["status"] == "fail")
           )

    stale_row_derived_observations =
      contact_allocation_report_fixture_observations()
      |> put_in(["row_derived_allocation_reason_counts", "ground_station_reserved"], 0)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_allocation_reason_counts" and
                 &1["status"] == "fail")
           )

    stale_reservation_observations =
      contact_allocation_report_fixture_observations()
      |> Map.put("row_derived_station_reservation_id_counts", %{})

    assert {:ok, stale_reservation_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_reservation_observations)

    assert stale_reservation_verification["status"] == "fail"

    assert Enum.any?(
             stale_reservation_verification["checks"],
             &(&1["field"] == "row_derived_station_reservation_id_counts" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_allocation_report.v1",
             report
           ) ==
             Validation.artifact_observations("contact_allocation_report.v1", report)

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "contact_allocation_report.v1"
             )

    stale_allocation_status_counts =
      put_in(report, ["allocation_status_counts", "blocked"], 2)

    assert {:error, stale_allocation_status_counts_report} =
             Schema.validate_artifact(stale_allocation_status_counts,
               schema_contract: "contact_allocation_report.v1"
             )

    assert Enum.any?(
             stale_allocation_status_counts_report["errors"],
             &(&1["path"] == "$.allocation_status_counts")
           )

    stale_allocation_reason_counts =
      put_in(report, ["allocation_reason_counts", "ground_station_reserved"], 0)

    assert {:error, stale_allocation_reason_counts_report} =
             Schema.validate_artifact(stale_allocation_reason_counts,
               schema_contract: "contact_allocation_report.v1"
             )

    assert Enum.any?(
             stale_allocation_reason_counts_report["errors"],
             &(&1["path"] == "$.allocation_reason_counts")
           )

    stale_reservation_match_status_counts =
      put_in(report, ["station_reservation_match_status_counts", "overlap"], 0)

    assert {:error, stale_reservation_match_status_counts_report} =
             Schema.validate_artifact(stale_reservation_match_status_counts,
               schema_contract: "contact_allocation_report.v1"
             )

    assert Enum.any?(
             stale_reservation_match_status_counts_report["errors"],
             &(&1["path"] == "$.station_reservation_match_status_counts")
           )

    stale_reservation_ids = Map.put(report, "station_reservation_ids", [])

    assert {:error, stale_reservation_ids_report} =
             Schema.validate_artifact(stale_reservation_ids,
               schema_contract: "contact_allocation_report.v1"
             )

    assert Enum.any?(
             stale_reservation_ids_report["errors"],
             &(&1["path"] == "$.station_reservation_ids")
           )
  end

  test "verifies curated reservation conflict summary reference fixtures" do
    fixture_id = "fixture.artifact.contact_allocation_reservation_conflict_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] ==
             "artifact.contact_allocation_reservation_conflict_summary.v1"

    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    summary = read_json!("study_results/contact_allocation_reservation_conflict_summary_v1.json")

    observations =
      Validation.artifact_observations(
        "contact_allocation_reservation_conflict_summary.v1",
        summary
      )

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               observations
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_conflict_direction_station_observations =
      observations
      |> put_in(
        [
          "row_derived_reservation_conflict_contact_ids_by_direction_and_ground_station_id",
          "downlink",
          "equator_prime"
        ],
        ["stale_contact"]
      )

    assert {:ok, stale_conflict_direction_station_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_conflict_direction_station_observations
             )

    assert stale_conflict_direction_station_verification["status"] == "fail"

    assert Enum.any?(
             stale_conflict_direction_station_verification["checks"],
             &(&1["field"] ==
                 "row_derived_reservation_conflict_contact_ids_by_direction_and_ground_station_id" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_allocation_reservation_conflict_summary.v1",
             summary
           ) == observations

    assert {:ok, %{"schema_contract" => "contact_allocation_reservation_conflict_summary.v1"}} =
             Schema.validate_artifact(summary)
  end

  test "verifies curated station pressure summary reference fixtures" do
    fixture_id = "fixture.artifact.contact_allocation_station_pressure_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.contact_allocation_station_pressure_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    summary = read_json!("study_results/contact_allocation_station_pressure_summary_v1.json")

    observations =
      Validation.artifact_observations(
        "contact_allocation_station_pressure_summary.v1",
        summary
      )

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               observations
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_station_direction_observations =
      observations
      |> put_in(
        [
          "row_derived_station_pressure_contact_ids_by_direction_and_ground_station_id",
          "downlink",
          "equator_prime"
        ],
        ["stale_contact"]
      )

    assert {:ok, stale_station_direction_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_station_direction_observations
             )

    assert stale_station_direction_verification["status"] == "fail"

    assert Enum.any?(
             stale_station_direction_verification["checks"],
             &(&1["field"] ==
                 "row_derived_station_pressure_contact_ids_by_direction_and_ground_station_id" and
                 &1["status"] == "fail")
           )

    stale_station_status_observations =
      put_in(
        observations,
        ["row_derived_station_pressure_contact_ids_by_status", "reserved"],
        ["stale_contact"]
      )

    assert {:ok, stale_station_status_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_station_status_observations
             )

    assert stale_station_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_station_status_verification["checks"],
             &(&1["field"] == "row_derived_station_pressure_contact_ids_by_status" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_allocation_station_pressure_summary.v1",
             summary
           ) == observations

    assert {:ok, %{"schema_contract" => "contact_allocation_station_pressure_summary.v1"}} =
             Schema.validate_artifact(summary)
  end

  test "verifies curated capacity pack summary reference fixtures" do
    fixture_id = "fixture.artifact.contact_allocation_capacity_pack_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.contact_allocation_capacity_pack_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    summary = read_json!("study_results/contact_allocation_capacity_pack_summary_v1.json")

    observations =
      Validation.artifact_observations(
        "contact_allocation_capacity_pack_summary.v1",
        summary
      )

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               observations
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_capacity_status_observations =
      observations
      |> put_in(
        [
          "row_derived_capacity_pack_contact_ids_by_status",
          "deferred_by_reduced_station_capacity_pack"
        ],
        []
      )

    assert {:ok, stale_capacity_status_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_capacity_status_observations
             )

    assert stale_capacity_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_capacity_status_verification["checks"],
             &(&1["field"] == "row_derived_capacity_pack_contact_ids_by_status" and
                 &1["status"] == "fail")
           )

    stale_group_status_observations =
      observations
      |> put_in(
        [
          "row_derived_reduced_capacity_pack_group_ids_by_status",
          "capacity_limited"
        ],
        []
      )

    assert {:ok, stale_group_status_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_group_status_observations
             )

    assert stale_group_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_group_status_verification["checks"],
             &(&1["field"] == "row_derived_reduced_capacity_pack_group_ids_by_status" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_allocation_capacity_pack_summary.v1",
             summary
           ) == observations

    assert {:ok, %{"schema_contract" => "contact_allocation_capacity_pack_summary.v1"}} =
             Schema.validate_artifact(summary)
  end

  test "verifies curated contact allocation summary reference fixtures" do
    fixture_id = "fixture.artifact.contact_allocation_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.contact_allocation_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    summary = read_json!("study_results/contact_allocation_summary_v1.json")

    observations =
      Validation.artifact_observations(
        "contact_allocation_summary.v1",
        summary
      )

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               observations
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_allocation_status_observations =
      observations
      |> put_in(
        [
          "row_derived_contact_ids_by_effective_allocation_status",
          "blocked"
        ],
        []
      )

    assert {:ok, stale_allocation_status_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_allocation_status_observations
             )

    assert stale_allocation_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_allocation_status_verification["checks"],
             &(&1["field"] == "row_derived_contact_ids_by_effective_allocation_status" and
                 &1["status"] == "fail")
           )

    stale_station_pressure_observations =
      observations
      |> put_in(
        [
          "row_derived_station_pressure_contact_ids_by_ground_station_id",
          "equator_prime"
        ],
        []
      )

    assert {:ok, stale_station_pressure_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_station_pressure_observations
             )

    assert stale_station_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_station_pressure_verification["checks"],
             &(&1["field"] == "row_derived_station_pressure_contact_ids_by_ground_station_id" and
                 &1["status"] == "fail")
           )

    stale_station_pressure_status_observations =
      put_in(
        observations,
        ["row_derived_station_pressure_contact_ids_by_status", "reserved"],
        []
      )

    assert {:ok, stale_station_pressure_status_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_station_pressure_status_observations
             )

    assert stale_station_pressure_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_station_pressure_status_verification["checks"],
             &(&1["field"] == "row_derived_station_pressure_contact_ids_by_status" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_allocation_summary.v1",
             summary
           ) == observations

    assert {:ok, %{"schema_contract" => "contact_allocation_summary.v1"}} =
             Schema.validate_artifact(summary)
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
