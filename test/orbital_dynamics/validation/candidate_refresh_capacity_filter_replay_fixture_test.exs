defmodule OrbitalDynamics.Validation.CandidateRefreshCapacityFilterReplayFixtureTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Validation}

  import OrbitalDynamics.Validation.CandidateRefreshCapacityFilterReplayFixtures,
    only: [
      candidate_refresh_link_capacity_fixture: 0,
      candidate_refresh_link_capacity_fixture_observations: 0,
      candidate_refresh_resource_filter_fixture: 0,
      candidate_refresh_resource_filter_fixture_observations: 0
    ]

  test "verifies candidate refresh link capacity replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.link_capacity_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_link_capacity_fixture()
    observations = candidate_refresh_link_capacity_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 2,
             "source_link_capacity_report_count" => 1,
             "source_link_capacity_row_count" => 2,
             "source_link_capacity_selected_shortfall_row_count" => 1,
             "source_link_capacity_actual_shortfall_row_count" => 1,
             "source_link_capacity_actual_throughput_row_count" => 2,
             "source_link_capacity_capacity_adjusted_throughput_row_count" => 2,
             "source_link_capacity_capacity_adjusted_throughput_mb_total" => 85.0,
             "source_link_capacity_selected_capacity_adjusted_throughput_mb_total" => 40.0,
             "source_link_capacity_unused_capacity_adjusted_throughput_mb_total" => 45.0,
             "source_link_capacity_ground_station_counts" => %{
               "dss_43" => 1,
               "equator_prime" => 1
             },
             "source_link_capacity_spacecraft_counts" => %{"leo_1" => 1, "leo_2" => 1},
             "source_link_capacity_direction_counts" => %{
               "command" => 1,
               "downlink" => 1,
               "tracking" => 1
             },
             "source_link_capacity_contact_ids_by_ground_station" => %{
               "dss_43" => ["contact_gamma"],
               "equator_prime" => ["contact_alpha", "contact_beta"]
             },
             "source_link_capacity_selected_contact_ids" => [
               "contact_alpha",
               "contact_beta",
               "contact_gamma"
             ],
             "source_link_capacity_actual_throughput_contact_ids" => [
               "contact_alpha",
               "contact_gamma"
             ],
             "source_link_capacity_downlink_requirement_status_counts" => %{
               "actual_met" => 1,
               "actual_shortfall" => 1,
               "selected_met" => 1,
               "selected_shortfall" => 1
             },
             "source_link_capacity_contact_ids_by_requirement_status" => %{
               "actual_met" => ["contact_alpha"],
               "actual_shortfall" => ["contact_gamma"],
               "selected_met" => ["contact_gamma"],
               "selected_shortfall" => ["contact_alpha", "contact_beta"]
             },
             "source_link_capacity_trust_boundary_status" => "declared",
             "source_link_capacity_branch_local_link_capacity_pressure" => true,
             "source_link_capacity_branch_local_capacity_adjusted_throughput_pressure" => true,
             "source_link_capacity_branch_local_downlink_shortfall_pressure" => true,
             "source_link_capacity_branch_local_actual_throughput_pressure" => true
           } = observations

    stale_link_capacity_pressure_observations =
      observations
      |> Map.put("source_link_capacity_branch_local_link_capacity_pressure", false)

    assert {:ok, stale_link_capacity_pressure_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_link_capacity_pressure_observations
             )

    assert stale_link_capacity_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_link_capacity_pressure_verification["checks"],
             &(&1["field"] == "source_link_capacity_branch_local_link_capacity_pressure" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh resource filter replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.resource_filter_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_resource_filter_fixture()
    observations = candidate_refresh_resource_filter_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 4,
             "source_resource_filter_report_count" => 1,
             "source_resource_filter_row_count" => 4,
             "source_resource_filter_suppressed_candidate_count" => 3,
             "source_resource_filter_invalid_resource_summary_input_count" => 1,
             "source_resource_filter_invalid_resource_summary_input_ids" => ["bad_summary"],
             "source_resource_filter_suppressed_reason_counts" => %{
               "downlink_margin_low" => 1,
               "payload_unavailable" => 1,
               "power_margin_low" => 1
             },
             "source_resource_filter_candidate_ids_by_suppressed_reason" => %{
               "downlink_margin_low" => ["downlink_margin_block"],
               "payload_unavailable" => ["obs_payload_block"],
               "power_margin_low" => ["power_block"]
             },
             "source_resource_filter_spacecraft_counts" => %{"leo_1" => 2, "leo_2" => 1},
             "source_resource_filter_candidate_ids_by_spacecraft" => %{
               "leo_1" => ["downlink_margin_block", "obs_payload_block"],
               "leo_2" => ["power_block"]
             },
             "source_resource_filter_resource_counts" => %{
               "battery_main" => 1,
               "downlink_budget" => 1,
               "payload_1" => 1
             },
             "source_resource_filter_candidate_ids_by_resource" => %{
               "battery_main" => ["power_block"],
               "downlink_budget" => ["downlink_margin_block"],
               "payload_1" => ["obs_payload_block"]
             },
             "source_resource_filter_blocking_dimension_counts" => %{
               "communications" => 1,
               "payload" => 1,
               "power" => 1
             },
             "source_resource_filter_candidate_ids_by_blocking_dimension" => %{
               "communications" => ["downlink_margin_block"],
               "payload" => ["obs_payload_block"],
               "power" => ["power_block"]
             },
             "source_resource_filter_direction_counts" => %{
               "command" => 1,
               "downlink" => 1
             },
             "source_resource_filter_directions" => ["command", "downlink"],
             "source_resource_filter_candidate_ids_by_direction" => %{
               "command" => ["power_block"],
               "downlink" => ["downlink_margin_block"]
             },
             "source_resource_filter_direction_routing" => %{
               "command" => %{
                 "candidate_count" => 1,
                 "candidate_ids" => ["power_block"]
               },
               "downlink" => %{
                 "candidate_count" => 1,
                 "candidate_ids" => ["downlink_margin_block"]
               }
             },
             "source_resource_filter_trust_boundary_status" => "declared",
             "source_resource_filter_branch_local_resource_filter_pressure" => true,
             "source_resource_filter_branch_local_candidate_suppression_pressure" => true,
             "source_resource_filter_branch_local_invalid_resource_summary_pressure" => true,
             "source_resource_filter_branch_local_resource_blocking_pressure" => true
           } = observations

    stale_resource_filter_pressure_observations =
      observations
      |> Map.put("source_resource_filter_branch_local_resource_filter_pressure", false)

    assert {:ok, stale_resource_filter_pressure_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_resource_filter_pressure_observations
             )

    assert stale_resource_filter_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_resource_filter_pressure_verification["checks"],
             &(&1["field"] == "source_resource_filter_branch_local_resource_filter_pressure" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end
end
