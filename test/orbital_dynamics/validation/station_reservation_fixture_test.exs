defmodule OrbitalDynamics.Validation.StationReservationFixtureTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Validation}

  import OrbitalDynamics.Validation.StationReservationFixtures,
    only: [
      checked_in_station_calendar_report_fixture: 0,
      checked_in_station_calendar_report_fixture_observations: 0,
      provider_counteroffer_import_readiness_summary_fixture: 0,
      provider_counteroffer_import_readiness_summary_fixture_observations: 0,
      provider_counteroffer_plan_impact_summary_fixture: 0,
      provider_counteroffer_plan_impact_summary_fixture_observations: 0,
      provider_counteroffer_report_fixture: 0,
      provider_counteroffer_report_fixture_observations: 0,
      provider_counteroffer_review_summary_fixture: 0,
      provider_counteroffer_review_summary_fixture_observations: 0,
      station_calendar_precedence_summary_fixture: 0,
      station_calendar_precedence_summary_fixture_observations: 0,
      station_calendar_provider_fixture: 0,
      station_calendar_provider_fixture_observations: 0,
      station_calendar_report_fixture: 0,
      station_calendar_report_fixture_observations: 0,
      station_reservation_hold_import_readiness_summary_fixture: 0,
      station_reservation_hold_import_readiness_summary_fixture_observations: 0,
      station_reservation_hold_summary_fixture: 0,
      station_reservation_hold_summary_fixture_observations: 0,
      station_reservation_report_fixture: 0,
      station_reservation_report_fixture_observations: 0,
      station_reservation_review_summary_fixture: 0,
      station_reservation_review_summary_fixture_observations: 0
    ]

  test "verifies curated station calendar stale reservation hold reference fixtures" do
    fixtures = [
      {
        "fixture.artifact.station_calendar_report.stale_provider_reservation_hold",
        station_calendar_report_fixture(),
        station_calendar_report_fixture_observations()
      },
      {
        "fixture.artifact.station_calendar_report.v1",
        checked_in_station_calendar_report_fixture(),
        checked_in_station_calendar_report_fixture_observations()
      }
    ]

    for {fixture_id, report, observations} <- fixtures do
      assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

      assert fixture["model_id"] == "artifact.station_calendar_report.v1"
      assert fixture["fixture_type"] == "curated_internal_artifact_regression"

      assert {:ok, verification} =
               Validation.verify_reference_fixture(fixture_id, observations)

      assert verification["status"] == "pass"
      assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

      stale_row_derived_observations =
        observations
        |> put_in(["row_derived_station_reservation_match_status_counts", "overlap"], 0)

      assert {:ok, stale_row_derived_verification} =
               Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

      assert stale_row_derived_verification["status"] == "fail"

      assert Enum.any?(
               stale_row_derived_verification["checks"],
               &(&1["field"] == "row_derived_station_reservation_match_status_counts" and
                   &1["status"] == "fail")
             )

      stale_status_observations =
        observations
        |> Map.put("station_calendar_status_counts", %{"stale_status" => 1})

      assert {:ok, stale_status_verification} =
               Validation.verify_reference_fixture(fixture_id, stale_status_observations)

      assert stale_status_verification["status"] == "fail"

      assert Enum.any?(
               stale_status_verification["checks"],
               &(&1["field"] == "station_calendar_status_counts" and &1["status"] == "fail")
             )

      assert OrbitalDynamics.validation_artifact_observations(
               "station_calendar_report.v1",
               report
             ) == Validation.artifact_observations("station_calendar_report.v1", report)
    end

    report = station_calendar_report_fixture()

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "station_calendar_report.v1"
             )

    stale_match_status_counts =
      put_in(report, ["station_reservation_match_status_counts", "overlap"], 0)

    assert {:error, stale_match_status_counts_report} =
             Schema.validate_artifact(stale_match_status_counts,
               schema_contract: "station_calendar_report.v1"
             )

    assert Enum.any?(
             stale_match_status_counts_report["errors"],
             &(&1["path"] == "$.station_reservation_match_status_counts")
           )

    checked_in_report = checked_in_station_calendar_report_fixture()

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(checked_in_report,
               schema_contract: "station_calendar_report.v1"
             )

    stale_affected_duration = Map.put(checked_in_report, "affected_duration_s", 0)

    assert {:error, stale_affected_duration_report} =
             Schema.validate_artifact(stale_affected_duration,
               schema_contract: "station_calendar_report.v1"
             )

    assert Enum.any?(
             stale_affected_duration_report["errors"],
             &(&1["path"] == "$.affected_duration_s")
           )

    stale_trust_counts =
      put_in(checked_in_report, ["station_calendar_trust_boundary_status_counts", "declared"], 0)

    assert {:error, stale_trust_counts_report} =
             Schema.validate_artifact(stale_trust_counts,
               schema_contract: "station_calendar_report.v1"
             )

    assert Enum.any?(
             stale_trust_counts_report["errors"],
             &(&1["path"] == "$.station_calendar_trust_boundary_status_counts")
           )

    stale_model_limits = Map.put(checked_in_report, "model_limits", ["declared_data_only"])

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "station_calendar_report.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )
  end

  test "verifies curated station reservation report reference fixtures" do
    fixture_id = "fixture.artifact.station_reservation_report.stale_provider_reservation_hold"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.station_reservation_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = station_reservation_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               station_reservation_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_row_derived_observations =
      station_reservation_report_fixture_observations()
      |> put_in(["row_derived_reservation_status_counts", "tentative_hold"], 1)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_reservation_status_counts" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "station_reservation_report.v1",
             report
           ) == Validation.artifact_observations("station_reservation_report.v1", report)

    assert {:ok, %{"schema_contract" => "station_reservation_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "station_reservation_report.v1"
             )

    stale_match_status_counts =
      put_in(report, ["station_reservation_match_status_counts", "overlap"], 0)

    assert {:error, stale_match_status_counts_report} =
             Schema.validate_artifact(stale_match_status_counts,
               schema_contract: "station_reservation_report.v1"
             )

    assert Enum.any?(
             stale_match_status_counts_report["errors"],
             &(&1["path"] == "$.station_reservation_match_status_counts")
           )

    stale_reservation_status_counts =
      put_in(report, ["reservation_status_counts", "tentative_hold"], 1)

    assert {:error, stale_reservation_status_counts_report} =
             Schema.validate_artifact(stale_reservation_status_counts,
               schema_contract: "station_reservation_report.v1"
             )

    assert Enum.any?(
             stale_reservation_status_counts_report["errors"],
             &(&1["path"] == "$.reservation_status_counts")
           )

    stale_reservation_ids = Map.put(report, "reservation_ids", [])

    assert {:error, stale_reservation_ids_report} =
             Schema.validate_artifact(stale_reservation_ids,
               schema_contract: "station_reservation_report.v1"
             )

    assert Enum.any?(
             stale_reservation_ids_report["errors"],
             &(&1["path"] == "$.reservation_ids")
           )
  end

  test "verifies curated station reservation review summary reference fixtures" do
    fixture_id = "fixture.artifact.station_reservation_review_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.station_reservation_review_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    summary = station_reservation_review_summary_fixture()
    observations = station_reservation_review_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "reservation_count" => 3,
             "reservation_review_status" => "review_required",
             "reservation_expiration_status_counts" => %{
               "active" => 1,
               "expired" => 1,
               "missing" => 1
             },
             "row_derived_reservation_expiration_status_counts" => %{
               "active" => 1,
               "expired" => 1,
               "missing" => 1
             },
             "reservation_ids_by_expiration_status" => %{
               "active" => ["reservation_active"],
               "expired" => ["reservation_expired"],
               "missing" => ["reservation_missing"]
             },
             "row_derived_reservation_ids_by_expiration_status" => %{
               "active" => ["reservation_active"],
               "expired" => ["reservation_expired"],
               "missing" => ["reservation_missing"]
             },
             "row_derived_required_operator_action_counts" => %{
               "review_station_provider_contention" => 2,
               "review_station_reservation_overlap" => 1
             },
             "execution_boundary" => "artifact_only_no_provider_reservation",
             "operator_authority" => "not_granted_by_summary"
           } = observations

    stale_expiration_observations =
      observations
      |> put_in(["row_derived_reservation_expiration_status_counts", "active"], 0)

    assert {:ok, stale_expiration_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_expiration_observations)

    assert stale_expiration_verification["status"] == "fail"

    assert Enum.any?(
             stale_expiration_verification["checks"],
             &(&1["field"] == "row_derived_reservation_expiration_status_counts" and
                 &1["status"] == "fail")
           )

    stale_review_ids_observations =
      observations
      |> put_in(["row_derived_reservation_ids_by_expiration_status", "expired"], [])

    assert {:ok, stale_review_ids_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_review_ids_observations)

    assert stale_review_ids_verification["status"] == "fail"

    assert Enum.any?(
             stale_review_ids_verification["checks"],
             &(&1["field"] == "row_derived_reservation_ids_by_expiration_status" and
                 &1["status"] == "fail")
           )

    stale_boundary_observations =
      observations
      |> Map.put("execution_boundary", "provider_reservation_write_performed")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "execution_boundary" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "station_reservation_review_summary.v1",
             summary
           ) ==
             Validation.artifact_observations("station_reservation_review_summary.v1", summary)

    assert {:ok, %{"schema_contract" => "station_reservation_review_summary.v1"}} =
             Schema.validate_artifact(summary)
  end

  test "verifies curated station reservation hold summary reference fixtures" do
    fixture_id = "fixture.artifact.station_reservation_hold_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.station_reservation_hold_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    summary = station_reservation_hold_summary_fixture()
    observations = station_reservation_hold_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "reservation_hold_count" => 2,
             "reservation_hold_review_status" => "review_required",
             "reservation_hold_status_counts" => %{"held" => 2},
             "row_derived_reservation_hold_status_counts" => %{"held" => 2},
             "reservation_hold_expiration_status_counts" => %{
               "expired" => 1,
               "missing" => 1
             },
             "row_derived_reservation_hold_expiration_status_counts" => %{
               "expired" => 1,
               "missing" => 1
             },
             "reservation_hold_ids_by_reserved_by" => %{
               "ops_calendar" => ["reservation_expired"],
               "partner_calendar" => ["reservation_missing"]
             },
             "row_derived_reservation_hold_ids_by_reserved_by" => %{
               "ops_calendar" => ["reservation_expired"],
               "partner_calendar" => ["reservation_missing"]
             },
             "execution_boundary" => "artifact_only_no_provider_reservation",
             "operator_authority" => "not_granted_by_summary"
           } = observations

    stale_expiration_observations =
      observations
      |> put_in(["row_derived_reservation_hold_expiration_status_counts", "expired"], 0)

    assert {:ok, stale_expiration_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_expiration_observations)

    assert stale_expiration_verification["status"] == "fail"

    assert Enum.any?(
             stale_expiration_verification["checks"],
             &(&1["field"] == "row_derived_reservation_hold_expiration_status_counts" and
                 &1["status"] == "fail")
           )

    stale_owner_observations =
      observations
      |> put_in(["row_derived_reservation_hold_ids_by_reserved_by", "ops_calendar"], [])

    assert {:ok, stale_owner_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_owner_observations)

    assert stale_owner_verification["status"] == "fail"

    assert Enum.any?(
             stale_owner_verification["checks"],
             &(&1["field"] == "row_derived_reservation_hold_ids_by_reserved_by" and
                 &1["status"] == "fail")
           )

    stale_boundary_observations =
      observations
      |> Map.put("execution_boundary", "provider_reservation_write_performed")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "execution_boundary" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "station_reservation_hold_summary.v1",
             summary
           ) ==
             Validation.artifact_observations("station_reservation_hold_summary.v1", summary)

    assert {:ok, %{"schema_contract" => "station_reservation_hold_summary.v1"}} =
             Schema.validate_artifact(summary)
  end

  test "verifies curated station reservation hold import-readiness summary reference fixtures" do
    fixture_id = "fixture.artifact.station_reservation_hold_import_readiness_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] ==
             "artifact.station_reservation_hold_import_readiness_summary.v1"

    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    summary = station_reservation_hold_import_readiness_summary_fixture()
    observations = station_reservation_hold_import_readiness_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "import_readiness_status" => "review_required",
             "import_classification" => "review_only",
             "reservation_hold_import_status_counts" => %{
               "review_required_before_import" => 2
             },
             "row_derived_reservation_hold_import_status_counts" => %{
               "review_required_before_import" => 2
             },
             "required_import_action_counts" => %{
               "review_station_provider_contention" => 1,
               "review_station_reservation_overlap" => 1
             },
             "row_derived_required_import_action_counts" => %{
               "review_station_provider_contention" => 1,
               "review_station_reservation_overlap" => 1
             },
             "execution_boundary" => "artifact_only_no_provider_or_cadence_writes",
             "provider_write" => "not_performed_by_summary",
             "cadence_write" => "not_performed_by_summary"
           } = observations

    stale_import_status_observations =
      observations
      |> put_in(["row_derived_reservation_hold_import_status_counts", "ready_for_import"], 1)

    assert {:ok, stale_import_status_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_import_status_observations)

    assert stale_import_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_import_status_verification["checks"],
             &(&1["field"] == "row_derived_reservation_hold_import_status_counts" and
                 &1["status"] == "fail")
           )

    stale_action_ids_observations =
      observations
      |> put_in(
        [
          "row_derived_reservation_hold_ids_by_required_import_action",
          "review_station_reservation_overlap"
        ],
        []
      )

    assert {:ok, stale_action_ids_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_action_ids_observations)

    assert stale_action_ids_verification["status"] == "fail"

    assert Enum.any?(
             stale_action_ids_verification["checks"],
             &(&1["field"] == "row_derived_reservation_hold_ids_by_required_import_action" and
                 &1["status"] == "fail")
           )

    stale_boundary_observations =
      observations
      |> Map.put("cadence_write", "performed_by_summary")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "cadence_write" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "station_reservation_hold_import_readiness_summary.v1",
             summary
           ) ==
             Validation.artifact_observations(
               "station_reservation_hold_import_readiness_summary.v1",
               summary
             )

    assert {:ok,
            %{
              "schema_contract" => "station_reservation_hold_import_readiness_summary.v1"
            }} = Schema.validate_artifact(summary)
  end

  test "verifies curated station calendar precedence summary reference fixtures" do
    fixture_id = "fixture.artifact.station_calendar_precedence_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.station_calendar_precedence_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = station_calendar_precedence_summary_fixture()
    observations = station_calendar_precedence_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source" => "ops_calendar",
             "affected_contact_count" => 1,
             "precedence_review_status" => "review_required",
             "applied_availability_counts" => %{"unavailable" => 1},
             "applied_status_counts" => %{"unavailable" => 1},
             "overlap_availability_counts" => %{
               "reduced_capacity" => 1,
               "reserved" => 1,
               "unavailable" => 1
             },
             "affected_contact_ids_by_overlap_availability" => %{
               "reduced_capacity" => ["dl_1"],
               "reserved" => ["dl_1"],
               "unavailable" => ["dl_1"]
             },
             "reserved_under_higher_precedence_contact_count" => 1,
             "reserved_under_higher_precedence_contact_ids" => "dl_1",
             "unavailable_contact_ids" => "dl_1",
             "reserved_overlap_contact_ids" => "dl_1",
             "reduced_capacity_contact_ids" => "dl_1",
             "execution_boundary" => "artifact_only_no_provider_reservation",
             "scope" => "station_calendar_availability_precedence_review",
             "operator_authority" => "not_granted_by_summary",
             "no_provider_reservation" => true,
             "no_schedule_mutation" => true,
             "no_conflict_resolution" => true
           } = observations

    assert OrbitalDynamics.validation_artifact_observations(
             "station_calendar_precedence_summary.v1",
             report
           ) == Validation.artifact_observations("station_calendar_precedence_summary.v1", report)

    stale_count_observations =
      Map.put(observations, "reserved_under_higher_precedence_contact_count", 0)

    assert {:ok, stale_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_count_observations)

    assert stale_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_count_verification["checks"],
             &(&1["field"] == "reserved_under_higher_precedence_contact_count" and
                 &1["status"] == "fail")
           )

    stale_routing_observations =
      put_in(observations, ["affected_contact_ids_by_overlap_availability", "reserved"], [])

    assert {:ok, stale_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_routing_observations)

    assert stale_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_routing_verification["checks"],
             &(&1["field"] == "affected_contact_ids_by_overlap_availability" and
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

    assert {:ok, %{"schema_contract" => "station_calendar_precedence_summary.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "station_calendar_precedence_summary.v1"
             )
  end

  test "verifies curated station calendar provider reference fixtures" do
    fixture_id = "fixture.artifact.station_calendar_provider.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.station_calendar_provider.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = station_calendar_provider_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               station_calendar_provider_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      station_calendar_provider_fixture_observations()
      |> Map.put("reserved_entry_count", 0)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "reserved_entry_count" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "station_calendar_provider.v1")

    duplicate_entry_id =
      put_in(
        report,
        ["entries", Access.at(1), "id"],
        get_in(report, ["entries", Access.at(0), "id"])
      )

    assert {:error, duplicate_entry_id_report} =
             Schema.validate_artifact(duplicate_entry_id,
               schema_contract: "station_calendar_provider.v1"
             )

    assert Enum.any?(
             duplicate_entry_id_report["errors"],
             &(&1["path"] == "$.entries")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "station_calendar_provider.v1",
             report
           ) == Validation.artifact_observations("station_calendar_provider.v1", report)
  end

  test "verifies curated provider counteroffer report reference fixtures" do
    fixture_id = "fixture.artifact.provider_counteroffer_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.provider_counteroffer_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = provider_counteroffer_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               provider_counteroffer_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      provider_counteroffer_report_fixture_observations()
      |> Map.put("row_derived_counteroffer_cost_delta_total", 0.0)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "row_derived_counteroffer_cost_delta_total" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "provider_counteroffer_report.v1",
             report
           ) == Validation.artifact_observations("provider_counteroffer_report.v1", report)

    assert {:ok, %{"schema_contract" => "provider_counteroffer_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "provider_counteroffer_report.v1"
             )

    stale_cost_total = Map.put(report, "counteroffer_cost_delta_total", 0.0)

    assert {:error, stale_cost_total_report} =
             Schema.validate_artifact(stale_cost_total,
               schema_contract: "provider_counteroffer_report.v1"
             )

    assert Enum.any?(
             stale_cost_total_report["errors"],
             &(&1["path"] == "$.counteroffer_cost_delta_total")
           )

    stale_status_counts = put_in(report, ["counteroffer_status_counts", "proposed"], 0)

    assert {:error, stale_status_counts_report} =
             Schema.validate_artifact(stale_status_counts,
               schema_contract: "provider_counteroffer_report.v1"
             )

    assert Enum.any?(
             stale_status_counts_report["errors"],
             &(&1["path"] == "$.counteroffer_status_counts")
           )

    stale_required_action_counts =
      put_in(report, ["required_operator_action_counts", "review_provider_counteroffer"], 0)

    assert {:error, stale_required_action_counts_report} =
             Schema.validate_artifact(stale_required_action_counts,
               schema_contract: "provider_counteroffer_report.v1"
             )

    assert Enum.any?(
             stale_required_action_counts_report["errors"],
             &(&1["path"] == "$.required_operator_action_counts")
           )
  end

  test "verifies curated provider counteroffer summary reference fixtures" do
    fixtures = [
      {
        "fixture.artifact.provider_counteroffer_review_summary.v1",
        "artifact.provider_counteroffer_review_summary.v1",
        provider_counteroffer_review_summary_fixture(),
        provider_counteroffer_review_summary_fixture_observations()
      },
      {
        "fixture.artifact.provider_counteroffer_import_readiness_summary.v1",
        "artifact.provider_counteroffer_import_readiness_summary.v1",
        provider_counteroffer_import_readiness_summary_fixture(),
        provider_counteroffer_import_readiness_summary_fixture_observations()
      },
      {
        "fixture.artifact.provider_counteroffer_plan_impact_summary.v1",
        "artifact.provider_counteroffer_plan_impact_summary.v1",
        provider_counteroffer_plan_impact_summary_fixture(),
        provider_counteroffer_plan_impact_summary_fixture_observations()
      }
    ]

    for {fixture_id, model_id, artifact, observations} <- fixtures do
      assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

      assert fixture["model_id"] == model_id
      assert fixture["fixture_type"] == "curated_internal_artifact_regression"

      assert {:ok, verification} =
               Validation.verify_reference_fixture(fixture_id, observations)

      assert verification["status"] == "pass"
      assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

      assert {:ok, %{"schema_contract" => schema_contract}} =
               Schema.validate_artifact(artifact)

      assert OrbitalDynamics.validation_artifact_observations(schema_contract, artifact) ==
               Validation.artifact_observations(schema_contract, artifact)
    end

    stale_review_observations =
      provider_counteroffer_review_summary_fixture_observations()
      |> Map.put("counteroffer_review_status", "clear")

    assert {:ok, stale_review_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.provider_counteroffer_review_summary.v1",
               stale_review_observations
             )

    assert stale_review_verification["status"] == "fail"

    assert Enum.any?(
             stale_review_verification["checks"],
             &(&1["field"] == "counteroffer_review_status" and &1["status"] == "fail")
           )

    stale_import_routing_observations =
      provider_counteroffer_import_readiness_summary_fixture_observations()
      |> put_in(
        ["counteroffer_ids_by_required_import_action", "review_provider_counteroffer"],
        []
      )

    assert {:ok, stale_import_routing_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.provider_counteroffer_import_readiness_summary.v1",
               stale_import_routing_observations
             )

    assert stale_import_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_import_routing_verification["checks"],
             &(&1["field"] == "counteroffer_ids_by_required_import_action" and
                 &1["status"] == "fail")
           )

    stale_import_boundary_observations =
      provider_counteroffer_import_readiness_summary_fixture_observations()
      |> Map.put("cadence_write", "performed_by_summary")

    assert {:ok, stale_import_boundary_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.provider_counteroffer_import_readiness_summary.v1",
               stale_import_boundary_observations
             )

    assert stale_import_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_import_boundary_verification["checks"],
             &(&1["field"] == "cadence_write" and &1["status"] == "fail")
           )

    stale_impact_observations =
      provider_counteroffer_plan_impact_summary_fixture_observations()
      |> Map.put("row_derived_counteroffer_cost_delta_total", 0.0)

    assert {:ok, stale_impact_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.provider_counteroffer_plan_impact_summary.v1",
               stale_impact_observations
             )

    assert stale_impact_verification["status"] == "fail"

    assert Enum.any?(
             stale_impact_verification["checks"],
             &(&1["field"] == "row_derived_counteroffer_cost_delta_total" and
                 &1["status"] == "fail")
           )
  end
end
