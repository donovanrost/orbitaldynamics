defmodule OrbitalDynamics.Validation.ResourceSummaryFixtureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.Validation.ResourceSummaryFixtures,
    only: [
      resource_summary_fixture_observations: 0,
      resource_summary_fixture: 0,
      resource_filter_report_fixture_observations: 0,
      resource_filter_report_fixture: 0,
      resource_filter_summary_fixture_observations: 0,
      resource_filter_summary_fixture: 0
    ]

  alias OrbitalDynamics.{Schema, Validation}

  test "verifies curated resource summary reference fixtures" do
    fixture_id = "fixture.artifact.resource_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.resource_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = resource_summary_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               resource_summary_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      resource_summary_fixture_observations()
      |> Map.put("spacecraft_available", true)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "spacecraft_available" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations("resource_summary.v1", report) ==
             Validation.artifact_observations("resource_summary.v1", report)

    assert {:ok, _validated_report} =
             Schema.validate_artifact(report, schema_contract: "resource_summary.v1")

    stale_battery_margin = Map.put(report, "battery_state_of_charge", 0.9)

    assert {:error, stale_battery_margin_report} =
             Schema.validate_artifact(stale_battery_margin,
               schema_contract: "resource_summary.v1"
             )

    assert Enum.any?(
             stale_battery_margin_report["errors"],
             &(&1["path"] == "$.battery_state_of_charge")
           )
  end

  test "verifies curated resource filter report reference fixtures" do
    fixture_id = "fixture.artifact.resource_filter_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.resource_filter_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = resource_filter_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               resource_filter_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      resource_filter_report_fixture_observations()
      |> Map.put("suppressed_candidate_count", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "suppressed_candidate_count" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "resource_filter_report.v1")

    stale_kept_candidate_count = Map.put(report, "kept_candidate_count", 0)

    assert {:error, stale_kept_candidate_count_report} =
             Schema.validate_artifact(stale_kept_candidate_count,
               schema_contract: "resource_filter_report.v1"
             )

    assert Enum.any?(
             stale_kept_candidate_count_report["errors"],
             &(&1["path"] == "$.kept_candidate_count")
           )

    stale_model_limits = Map.put(report, "model_limits", ["artifact_level_only"])

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "resource_filter_report.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )

    stale_suppressed_trust_counts =
      Map.put(report, "suppressed_resource_trust_boundary_status_counts", %{"missing" => 0})

    assert {:error, stale_suppressed_trust_counts_report} =
             Schema.validate_artifact(stale_suppressed_trust_counts,
               schema_contract: "resource_filter_report.v1"
             )

    assert Enum.any?(
             stale_suppressed_trust_counts_report["errors"],
             &(&1["path"] == "$.suppressed_resource_trust_boundary_status_counts")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "resource_filter_report.v1",
             report
           ) == Validation.artifact_observations("resource_filter_report.v1", report)
  end

  test "verifies curated resource filter summary reference fixtures" do
    fixture_id = "fixture.artifact.resource_filter_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.resource_filter_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = resource_filter_summary_fixture()
    observations = resource_filter_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "input_candidate_count" => 3,
             "kept_candidate_count" => 1,
             "suppressed_candidate_count" => 2,
             "suppression_review_status" => "review_required",
             "suppressed_candidate_ids" =>
               "leo_1_downlink_equator_prime_1|leo_1_observe_target_a_1",
             "suppressed_reason_counts" => %{
               "downlink_margin_below_policy" => 1,
               "storage_margin_below_observe_policy" => 1
             },
             "resource_blocking_dimension_counts" => %{"downlink" => 1, "storage" => 1},
             "suppressed_resource_source_quality_counts" => %{"operator_supplied" => 2},
             "suppressed_resource_trust_boundary_status_counts" => %{"missing" => 2},
             "review_row_count" => 2,
             "review_row_ids" => "leo_1_observe_target_a_1|leo_1_downlink_equator_prime_1",
             "execution_boundary" => "artifact_only_no_schedule_mutation",
             "assumption_source" => "resource_filter_report.v1",
             "operator_authority" => "not_granted_by_resource_filter_summary",
             "resource_state_propagation" => "not_performed",
             "no_schedule_mutation" => true,
             "no_resource_time_propagation" => true,
             "no_subsystem_simulation" => true
           } = observations

    assert OrbitalDynamics.validation_artifact_observations(
             "resource_filter_summary.v1",
             report
           ) == Validation.artifact_observations("resource_filter_summary.v1", report)

    stale_count_observations = Map.put(observations, "suppressed_candidate_count", 1)

    assert {:ok, stale_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_count_observations)

    assert stale_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_count_verification["checks"],
             &(&1["field"] == "suppressed_candidate_count" and &1["status"] == "fail")
           )

    stale_routing_observations =
      put_in(
        observations,
        ["suppressed_candidate_ids_by_resource_blocking_dimension", "downlink"],
        []
      )

    assert {:ok, stale_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_routing_observations)

    assert stale_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_routing_verification["checks"],
             &(&1["field"] == "suppressed_candidate_ids_by_resource_blocking_dimension" and
                 &1["status"] == "fail")
           )

    stale_boundary_observations =
      Map.put(observations, "execution_boundary", "resource_state_propagated")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "execution_boundary" and &1["status"] == "fail")
           )

    assert {:ok, %{"schema_contract" => "resource_filter_summary.v1"}} =
             Schema.validate_artifact(report, schema_contract: "resource_filter_summary.v1")
  end
end
