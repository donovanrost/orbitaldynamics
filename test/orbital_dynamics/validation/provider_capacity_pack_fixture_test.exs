defmodule OrbitalDynamics.Validation.ProviderCapacityPackFixtureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.Validation.ProviderCapacityPackFixtures,
    only: [
      contact_allocation_provider_reservation_request_summary_fixture_observations: 0,
      contact_allocation_provider_reservation_request_summary_fixture: 0,
      contact_allocation_capacity_pack_report_fixture_observations: 0,
      contact_allocation_capacity_pack_report_fixture: 0
    ]

  alias OrbitalDynamics.{Schema, Validation}

  test "verifies curated provider reservation request summary reference fixtures" do
    fixture_id = "fixture.artifact.contact_allocation_provider_reservation_request_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] ==
             "artifact.contact_allocation_provider_reservation_request_summary.v1"

    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    summary = contact_allocation_provider_reservation_request_summary_fixture()
    observations = contact_allocation_provider_reservation_request_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               observations
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_checked_in_summary =
      summary
      |> put_in(
        ["provider_reservation_request_contact_ids_by_direction", "downlink"],
        ["stale_contact"]
      )

    assert {:ok, stale_checked_in_summary_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               Validation.artifact_observations(
                 "contact_allocation_provider_reservation_request_summary.v1",
                 stale_checked_in_summary
               )
             )

    assert stale_checked_in_summary_verification["status"] == "fail"

    assert Enum.any?(
             stale_checked_in_summary_verification["checks"],
             &(&1["field"] == "provider_reservation_request_contact_ids_by_direction" and
                 &1["status"] == "fail")
           )

    stale_request_direction_observations =
      observations
      |> put_in(
        ["row_derived_provider_reservation_request_contact_ids_by_direction", "downlink"],
        ["stale_contact"]
      )

    assert {:ok, stale_request_direction_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_request_direction_observations)

    assert stale_request_direction_verification["status"] == "fail"

    assert Enum.any?(
             stale_request_direction_verification["checks"],
             &(&1["field"] ==
                 "row_derived_provider_reservation_request_contact_ids_by_direction" and
                 &1["status"] == "fail")
           )

    stale_request_direction_station_observations =
      observations
      |> put_in(
        [
          "row_derived_provider_reservation_request_contact_ids_by_direction_and_ground_station_id",
          "downlink",
          "equator_prime"
        ],
        ["stale_contact"]
      )

    assert {:ok, stale_request_direction_station_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_request_direction_station_observations
             )

    assert stale_request_direction_station_verification["status"] == "fail"

    assert Enum.any?(
             stale_request_direction_station_verification["checks"],
             &(&1["field"] ==
                 "row_derived_provider_reservation_request_contact_ids_by_direction_and_ground_station_id" and
                 &1["status"] == "fail")
           )

    stale_review_direction_station_observations =
      observations
      |> put_in(
        [
          "row_derived_provider_reservation_review_contact_ids_by_direction_and_ground_station_id",
          "command",
          "equator_prime"
        ],
        ["stale_contact"]
      )

    assert {:ok, stale_review_direction_station_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_review_direction_station_observations
             )

    assert stale_review_direction_station_verification["status"] == "fail"

    assert Enum.any?(
             stale_review_direction_station_verification["checks"],
             &(&1["field"] ==
                 "row_derived_provider_reservation_review_contact_ids_by_direction_and_ground_station_id" and
                 &1["status"] == "fail")
           )

    stale_no_request_direction_observations =
      observations
      |> put_in(
        ["row_derived_provider_reservation_no_request_contact_ids_by_direction", "tracking"],
        []
      )

    assert {:ok, stale_no_request_direction_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_no_request_direction_observations
             )

    assert stale_no_request_direction_verification["status"] == "fail"

    assert Enum.any?(
             stale_no_request_direction_verification["checks"],
             &(&1["field"] ==
                 "row_derived_provider_reservation_no_request_contact_ids_by_direction" and
                 &1["status"] == "fail")
           )

    stale_no_request_direction_station_observations =
      observations
      |> put_in(
        [
          "row_derived_provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id",
          "tracking",
          "equator_prime"
        ],
        ["stale_contact"]
      )

    assert {:ok, stale_no_request_direction_station_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_no_request_direction_station_observations
             )

    assert stale_no_request_direction_station_verification["status"] == "fail"

    assert Enum.any?(
             stale_no_request_direction_station_verification["checks"],
             &(&1["field"] ==
                 "row_derived_provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_allocation_provider_reservation_request_summary.v1",
             summary
           ) ==
             Validation.artifact_observations(
               "contact_allocation_provider_reservation_request_summary.v1",
               summary
             )

    assert {:ok,
            %{"schema_contract" => "contact_allocation_provider_reservation_request_summary.v1"}} =
             Schema.validate_artifact(summary)

    stale_request_direction_map =
      Map.put(summary, "provider_reservation_request_contact_ids_by_direction", %{
        "downlink" => ["stale_contact"]
      })

    assert {:error, stale_request_direction_map_report} =
             Schema.validate_artifact(stale_request_direction_map)

    assert Enum.any?(
             stale_request_direction_map_report["errors"],
             &(&1["path"] == "$.provider_reservation_request_contact_ids_by_direction")
           )
  end

  test "verifies curated reduced-capacity contact allocation pack reference fixtures" do
    fixture_id = "fixture.artifact.contact_allocation_report.reduced_capacity_pack"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.contact_allocation_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = contact_allocation_capacity_pack_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               contact_allocation_capacity_pack_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      contact_allocation_capacity_pack_report_fixture_observations()
      |> Map.put("reduced_capacity_pack_capacity_packed_contact_count", 0)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "reduced_capacity_pack_capacity_packed_contact_count" and
                 &1["status"] == "fail")
           )

    stale_reported_observations =
      contact_allocation_capacity_pack_report_fixture_observations()
      |> put_in(
        [
          "reported_capacity_pack_contact_ids_by_status",
          "selected_by_reduced_station_capacity_pack"
        ],
        ["dl_capacity_primary"]
      )

    assert {:ok, stale_reported_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_reported_observations)

    assert stale_reported_verification["status"] == "fail"

    assert Enum.any?(
             stale_reported_verification["checks"],
             &(&1["field"] == "reported_capacity_pack_contact_ids_by_status" and
                 &1["status"] == "fail")
           )

    stale_station_pressure_observations =
      contact_allocation_capacity_pack_report_fixture_observations()
      |> put_in(
        [
          "reported_station_pressure_contact_ids_by_availability",
          "reduced_capacity"
        ],
        ["dl_capacity_primary"]
      )

    assert {:ok, stale_station_pressure_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_station_pressure_observations)

    assert stale_station_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_station_pressure_verification["checks"],
             &(&1["field"] == "reported_station_pressure_contact_ids_by_availability" and
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

    stale_pack_status_counts =
      put_in(report, ["reduced_capacity_pack_status_counts", "capacity_limited"], 0)

    assert {:error, stale_pack_status_counts_report} =
             Schema.validate_artifact(stale_pack_status_counts,
               schema_contract: "contact_allocation_report.v1"
             )

    assert Enum.any?(
             stale_pack_status_counts_report["errors"],
             &(&1["path"] == "$.reduced_capacity_pack_status_counts")
           )

    stale_contact_status_counts =
      put_in(
        report,
        ["capacity_pack_status_counts", "selected_by_reduced_station_capacity_pack"],
        0
      )

    assert {:error, stale_contact_status_counts_report} =
             Schema.validate_artifact(stale_contact_status_counts,
               schema_contract: "contact_allocation_report.v1"
             )

    assert Enum.any?(
             stale_contact_status_counts_report["errors"],
             &(&1["path"] == "$.capacity_pack_status_counts")
           )

    stale_contact_ids_by_status =
      put_in(
        report,
        ["capacity_pack_contact_ids_by_status", "selected_by_reduced_station_capacity_pack"],
        ["dl_capacity_primary"]
      )

    assert {:error, stale_contact_ids_by_status_report} =
             Schema.validate_artifact(stale_contact_ids_by_status,
               schema_contract: "contact_allocation_report.v1"
             )

    assert Enum.any?(
             stale_contact_ids_by_status_report["errors"],
             &(&1["path"] == "$.capacity_pack_contact_ids_by_status")
           )
  end
end
