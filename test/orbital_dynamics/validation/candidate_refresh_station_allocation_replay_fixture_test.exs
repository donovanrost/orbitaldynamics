defmodule OrbitalDynamics.Validation.CandidateRefreshStationAllocationReplayFixtureTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Validation}

  import OrbitalDynamics.Validation.CandidateRefreshStationAllocationReplayFixtures,
    only: [
      candidate_refresh_contact_allocation_contradiction_fixture: 0,
      candidate_refresh_contact_allocation_contradiction_fixture_observations: 0,
      candidate_refresh_contact_allocation_resource_selection_challenge_fixture: 0,
      candidate_refresh_contact_allocation_resource_selection_challenge_fixture_observations: 0,
      candidate_refresh_contact_allocation_resource_selection_challenge_request: 0,
      candidate_refresh_station_calendar_fixture: 0,
      candidate_refresh_station_calendar_fixture_observations: 0
    ]

  test "verifies candidate refresh station-calendar replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.station_calendar_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_station_calendar_fixture()
    observations = candidate_refresh_station_calendar_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 4,
             "source_station_calendar_report_count" => 1,
             "source_station_calendar_row_count" => 4,
             "source_station_calendar_path_keys" => "source_station_calendar_report",
             "source_station_calendar_affected_contact_count" => 3,
             "source_station_calendar_provider_calendar_contention_group_count" => 1,
             "source_station_calendar_provider_calendar_contention_group_id_keys" =>
               "station_calendar_provider_contention:equator_prime:1",
             "source_station_calendar_provider_calendar_contention_source_entry_id_keys" =>
               "provider_a|provider_b",
             "source_station_calendar_provider_calendar_contention_provider_entry_id_keys" =>
               "provider_entry_ops|provider_entry_partner",
             "source_station_calendar_provider_calendar_contention_provider_counts" => %{
               "ops_calendar" => 1,
               "partner_calendar" => 1
             },
             "source_station_calendar_provider_calendar_contention_ground_station_counts" => %{
               "dss_43" => 1,
               "equator_prime" => 1
             },
             "source_station_calendar_provider_calendar_contention_direction_counts" => %{
               "downlink" => 1,
               "tracking" => 1
             },
             "source_station_calendar_provider_calendar_contention_minimum_capacity_fraction" =>
               0.25,
             "source_station_calendar_affected_contact_ground_station_counts" => %{
               "dss_43" => 1,
               "equator_prime" => 2
             },
             "source_station_calendar_affected_contact_availability_counts" => %{
               "reduced_capacity" => 1,
               "reserved" => 1,
               "unavailable" => 1
             },
             "source_station_calendar_direction_counts" => %{
               "downlink" => 2,
               "uplink" => 1
             },
             "source_station_calendar_status_counts" => %{
               "reduced_capacity" => 1,
               "reserved" => 1,
               "unavailable" => 1
             },
             "source_station_calendar_trust_boundary_status" => "declared",
             "source_station_calendar_branch_local_station_calendar_pressure" => true,
             "source_station_calendar_branch_local_affected_contact_pressure" => true,
             "source_station_calendar_branch_local_provider_contention_pressure" => true,
             "source_station_calendar_branch_local_station_availability_pressure" => true
           } = observations

    stale_station_calendar_pressure_observations =
      observations
      |> Map.put("source_station_calendar_branch_local_station_calendar_pressure", false)

    assert {:ok, stale_station_calendar_pressure_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_station_calendar_pressure_observations
             )

    assert stale_station_calendar_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_station_calendar_pressure_verification["checks"],
             &(&1["field"] == "source_station_calendar_branch_local_station_calendar_pressure" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh contact allocation contradiction replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.contact_allocation_contradiction_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_contact_allocation_contradiction_fixture()
    observations = candidate_refresh_contact_allocation_contradiction_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 2,
             "source_report_row_count" => 9,
             "source_station_calendar_provider_calendar_contention_group_count" => 1,
             "source_station_calendar_branch_local_provider_contention_pressure" => true,
             "source_contact_allocation_report_count" => 2,
             "source_contact_allocation_row_count" => 6,
             "source_contact_allocation_source_summary_schema_contract_counts" => %{
               "contact_allocation_provider_reservation_request_summary.v1" => 1,
               "contact_allocation_reservation_conflict_summary.v1" => 1
             },
             "source_contact_allocation_reservation_conflict_contact_count" => 2,
             "source_contact_allocation_reservation_conflict_contact_ids_by_direction_and_ground_station" =>
               %{
                 "command" => %{"equator_prime" => ["dl_review_overlap"]},
                 "downlink" => %{"equator_prime" => ["dl_reserved_intruder"]},
                 "tracking" => %{"equator_prime" => ["dl_reserved_intruder"]}
               },
             "source_contact_allocation_provider_reservation_request_contact_count" => 2,
             "source_contact_allocation_provider_reservation_review_contact_count" => 1,
             "source_contact_allocation_branch_local_reservation_conflict_pressure" => true,
             "source_contact_allocation_branch_local_provider_reservation_request_pressure" =>
               true
           } = observations

    stale_conflict_observations =
      observations
      |> Map.put("source_contact_allocation_reservation_conflict_contact_count", 1)

    assert {:ok, stale_conflict_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_conflict_observations)

    assert stale_conflict_verification["status"] == "fail"

    assert Enum.any?(
             stale_conflict_verification["checks"],
             &(&1["field"] ==
                 "source_contact_allocation_reservation_conflict_contact_count" and
                 &1["status"] == "fail")
           )

    stale_provider_request_observations =
      observations
      |> Map.put(
        "source_contact_allocation_branch_local_provider_reservation_request_pressure",
        false
      )

    assert {:ok, stale_provider_request_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_provider_request_observations)

    assert stale_provider_request_verification["status"] == "fail"

    assert Enum.any?(
             stale_provider_request_verification["checks"],
             &(&1["field"] ==
                 "source_contact_allocation_branch_local_provider_reservation_request_pressure" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies row-derived allocation resource selection without stale aggregate leakage" do
    fixture_id =
      "fixture.artifact.candidate_refresh.contact_allocation_resource_selection_challenge"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)
    assert fixture["fixture_type"] == "curated_internal_artifact_challenge"

    artifact = candidate_refresh_contact_allocation_resource_selection_challenge_fixture()

    observations =
      candidate_refresh_contact_allocation_resource_selection_challenge_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "candidate_count" => 1,
             "candidate_activity_id_keys" => "leo_2_downlink_dss_43_1",
             "contact_intent_activity_id_keys" => "leo_2_downlink_dss_43_1",
             "candidate_rejection_rejected_candidate_id_keys" => "leo_1_downlink_equator_prime_1",
             "candidate_rejection_contact_allocation_filter_candidate_id_keys" =>
               "leo_1_downlink_equator_prime_1",
             "candidate_rejection_contact_allocation_filter_source_artifact_id_keys" =>
               "allocation-resource-selection-challenge",
             "candidate_rejection_contact_allocation_filter_source_report_id_keys" =>
               "contact_allocation:resource_selection:stale_aggregate_challenge",
             "candidate_rejection_contact_allocation_filter_source_report_source_keys" =>
               "validation.contact_allocation_resource_selection",
             "candidate_rejection_contact_allocation_filter_resource_blocking_dimension_keys" =>
               "antenna",
             "candidate_rejection_contact_allocation_filter_blocked_spacecraft_id_keys" =>
               "sat_1",
             "candidate_rejection_contact_allocation_filter_trust_boundary_keys" =>
               "allocation_resource_challenge|generated_contact_allocation_resource_selection_challenge",
             "invalidated_candidate_id_keys" => "leo_1_downlink_equator_prime_1",
             "invalidated_candidate_reason_counts" => %{
               "dropped_by_contact_allocation_unavailable_resource" => 1
             },
             "source_contact_allocation_resource_blocked_contact_count" => 2,
             "source_contact_allocation_resource_blocked_contact_ids_by_spacecraft" => %{
               "sat_1" => [
                 "leo_1_downlink_equator_prime_1",
                 "leo_2_downlink_dss_43_1"
               ]
             }
           } = observations

    request = candidate_refresh_contact_allocation_resource_selection_challenge_request()
    source_report = request["source_contact_allocation_report"]

    assert source_report["resource_blocked_contact_ids_by_spacecraft_id"] == %{
             "sat_2" => ["leo_2_downlink_dss_43_1"],
             "stale_spacecraft" => ["leo_1_downlink_equator_prime_1"]
           }

    assert Enum.map(source_report["rows"], &{&1["contact_id"], &1["spacecraft_id"]}) == [
             {"leo_2_downlink_dss_43_1", "sat_1"},
             {"leo_1_downlink_equator_prime_1", "sat_1"}
           ]

    corrected_source_report =
      Map.put(source_report, "resource_blocked_contact_ids_by_spacecraft_id", %{
        "sat_1" => [
          "leo_1_downlink_equator_prime_1",
          "leo_2_downlink_dss_43_1"
        ]
      })

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(corrected_source_report)

    assert {:error, _stale_aggregate_report} = Schema.validate_artifact(source_report)

    assert [
             %{
               "candidate_id" => "leo_1_downlink_equator_prime_1",
               "activity_context" => %{
                 "provenance" => %{
                   "contact_allocation_candidate_filter" => %{
                     "blocked_spacecraft_ids" => ["sat_1"],
                     "resource_blocking_dimensions" => ["antenna"],
                     "source_artifact_ids" => ["allocation-resource-selection-challenge"],
                     "source_contact_allocation_report_ids" => [
                       "contact_allocation:resource_selection:stale_aggregate_challenge"
                     ],
                     "trust_boundaries" => [
                       "allocation_resource_challenge",
                       "generated_contact_allocation_resource_selection_challenge"
                     ]
                   }
                 }
               }
             },
             %{"candidate_id" => "leo_2_downlink_dss_43_1"}
           ] = artifact["candidate_rejection_report"]["rows"]

    stale_scope_observations =
      Map.put(
        observations,
        "candidate_rejection_contact_allocation_filter_blocked_spacecraft_id_keys",
        "sat_2"
      )

    assert {:ok, stale_scope_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_scope_observations)

    assert stale_scope_verification["status"] == "fail"

    assert Enum.any?(
             stale_scope_verification["checks"],
             &(&1["field"] ==
                 "candidate_rejection_contact_allocation_filter_blocked_spacecraft_id_keys" and
                 &1["status"] == "fail")
           )

    assert {:ok, %{"schema_contract" => "candidate_rejection_report.v1"}} =
             Schema.validate_artifact(artifact["candidate_rejection_report"])

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact)
  end
end
