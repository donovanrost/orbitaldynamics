defmodule OrbitalDynamics.Validation.LinkCapacityFixtureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.Validation.LinkCapacityFixtures,
    only: [
      link_capacity_report_fixture_observations: 0,
      link_capacity_report_fixture: 0,
      link_capacity_summary_fixture_observations: 0,
      link_capacity_summary_fixture: 0,
      relay_data_path_summary_fixture_observations: 0,
      relay_data_path_summary_fixture: 0
    ]

  alias OrbitalDynamics.{Schema, Validation}

  test "verifies curated link capacity report reference fixtures" do
    fixture_id = "fixture.artifact.link_capacity_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.link_capacity_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = link_capacity_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               link_capacity_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      link_capacity_report_fixture_observations()
      |> Map.put("selected_contact_count", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "selected_contact_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      link_capacity_report_fixture_observations()
      |> Map.put("row_derived_contact_count", 2)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_contact_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "link_capacity_report.v1",
             report
           ) == Validation.artifact_observations("link_capacity_report.v1", report)

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "link_capacity_report.v1"
             )

    stale_contact_count = Map.put(report, "contact_count", 2)

    assert {:error, stale_contact_count_report} =
             Schema.validate_artifact(stale_contact_count,
               schema_contract: "link_capacity_report.v1"
             )

    assert Enum.any?(
             stale_contact_count_report["errors"],
             &(&1["path"] == "$.contact_count")
           )

    stale_selected_count = Map.put(report, "selected_contact_count", 1)

    assert {:error, stale_selected_count_report} =
             Schema.validate_artifact(stale_selected_count,
               schema_contract: "link_capacity_report.v1"
             )

    assert Enum.any?(
             stale_selected_count_report["errors"],
             &(&1["path"] == "$.selected_contact_count")
           )

    stale_throughput = Map.put(report, "estimated_throughput_mb", 0.0)

    assert {:error, stale_throughput_report} =
             Schema.validate_artifact(stale_throughput,
               schema_contract: "link_capacity_report.v1"
             )

    assert Enum.any?(
             stale_throughput_report["errors"],
             &(&1["path"] == "$.estimated_throughput_mb")
           )

    stale_ignored_ids = Map.put(report, "ignored_contact_ids", ["leo_1_downlink_equator_prime_1"])

    assert {:error, stale_ignored_ids_report} =
             Schema.validate_artifact(stale_ignored_ids,
               schema_contract: "link_capacity_report.v1"
             )

    assert Enum.any?(
             stale_ignored_ids_report["errors"],
             &(&1["path"] == "$.ignored_contact_ids")
           )
  end

  test "verifies curated link capacity summary reference fixtures" do
    fixture_id = "fixture.artifact.link_capacity_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.link_capacity_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = link_capacity_summary_fixture()
    observations = link_capacity_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "station_count" => 1,
             "contact_count" => 1,
             "effective_contact_count" => 1,
             "selected_contact_count" => 1,
             "actual_throughput_contact_count" => 1,
             "actual_completion_contact_count" => 0,
             "downlink_requirement_status" => "satisfied",
             "actual_downlink_requirement_status" => "shortfall",
             "selection_utilization_status" => "fully_selected",
             "capacity_adjusted_throughput_mb" => 120.0,
             "actual_downlink_shortfall_mb" => 10.0,
             "contact_ids" => "science_downlink",
             "selected_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["science_downlink"]
             },
             "actual_throughput_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["science_downlink"]
             },
             "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
             "assumption_source" => "link_capacity_report.v1",
             "operator_authority" => "not_granted_by_summary",
             "no_provider_reservation" => true,
             "no_schedule_mutation" => true,
             "no_link_budget_model" => true
           } = observations

    assert OrbitalDynamics.validation_artifact_observations(
             "link_capacity_summary.v1",
             report
           ) == Validation.artifact_observations("link_capacity_summary.v1", report)

    stale_count_observations = Map.put(observations, "actual_throughput_contact_count", 0)

    assert {:ok, stale_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_count_observations)

    assert stale_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_count_verification["checks"],
             &(&1["field"] == "actual_throughput_contact_count" and &1["status"] == "fail")
           )

    stale_routing_observations =
      put_in(observations, ["selected_contact_ids_by_ground_station_id", "equator_prime"], [])

    assert {:ok, stale_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_routing_observations)

    assert stale_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_routing_verification["checks"],
             &(&1["field"] == "selected_contact_ids_by_ground_station_id" and
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

    assert {:ok, %{"schema_contract" => "link_capacity_summary.v1"}} =
             Schema.validate_artifact(report, schema_contract: "link_capacity_summary.v1")
  end

  test "verifies curated relay data-path summary reference fixtures" do
    fixture_id = "fixture.artifact.relay_data_path_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.relay_data_path_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = relay_data_path_summary_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               relay_data_path_summary_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      relay_data_path_summary_fixture_observations()
      |> Map.put("relay_route_count", 2)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "relay_route_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      relay_data_path_summary_fixture_observations()
      |> put_in(["row_derived_route_ids_by_latency_status", "within_limit"], ["route_direct"])

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_route_ids_by_latency_status" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "relay_data_path_summary.v1",
             report
           ) == Validation.artifact_observations("relay_data_path_summary.v1", report)

    assert {:ok, %{"schema_contract" => "relay_data_path_summary.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "relay_data_path_summary.v1"
             )

    stale_route_count = Map.put(report, "route_count", 1)

    assert {:error, stale_route_count_report} =
             Schema.validate_artifact(stale_route_count,
               schema_contract: "relay_data_path_summary.v1"
             )

    assert Enum.any?(
             stale_route_count_report["errors"],
             &(&1["path"] == "$.route_count")
           )

    stale_custody_counts =
      Map.put(report, "custody_status_counts", %{"confirmed" => 2, "missing_ack" => 1})

    assert {:error, stale_custody_counts_report} =
             Schema.validate_artifact(stale_custody_counts,
               schema_contract: "relay_data_path_summary.v1"
             )

    assert Enum.any?(
             stale_custody_counts_report["errors"],
             &(&1["path"] == "$.custody_status_counts")
           )

    stale_relay_spacecraft_ids = Map.put(report, "relay_spacecraft_ids", ["relay_2"])

    assert {:error, stale_relay_spacecraft_ids_report} =
             Schema.validate_artifact(stale_relay_spacecraft_ids,
               schema_contract: "relay_data_path_summary.v1"
             )

    assert Enum.any?(
             stale_relay_spacecraft_ids_report["errors"],
             &(&1["path"] == "$.relay_spacecraft_ids")
           )

    stale_latency_routing =
      put_in(report, ["route_ids_by_latency_status", "within_limit"], ["route_direct"])

    assert {:error, stale_latency_routing_report} =
             Schema.validate_artifact(stale_latency_routing,
               schema_contract: "relay_data_path_summary.v1"
             )

    assert Enum.any?(
             stale_latency_routing_report["errors"],
             &(&1["path"] == "$.route_ids_by_latency_status")
           )
  end
end
