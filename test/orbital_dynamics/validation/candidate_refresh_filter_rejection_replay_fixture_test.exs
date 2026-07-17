defmodule OrbitalDynamics.Validation.CandidateRefreshFilterRejectionReplayFixtureTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Validation}

  import OrbitalDynamics.Validation.CandidateRefreshFilterRejectionReplayFixtures,
    only: [
      candidate_refresh_candidate_rejection_fixture: 0,
      candidate_refresh_candidate_rejection_fixture_observations: 0,
      candidate_refresh_contact_filter_fixture: 0,
      candidate_refresh_contact_filter_fixture_observations: 0
    ]

  test "verifies candidate refresh contact filter replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.contact_filter_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_contact_filter_fixture()
    observations = candidate_refresh_contact_filter_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 4,
             "source_contact_filter_report_count" => 1,
             "source_contact_filter_row_count" => 4,
             "source_contact_filter_suppressed_candidate_count" => 4,
             "source_contact_filter_invalid_contact_input_count" => 1,
             "source_contact_filter_invalid_contact_input_ids" => ["invalid_contact"],
             "source_contact_filter_suppressed_reason_counts" => %{
               "ground_station_capacity_zero" => 1,
               "ground_station_reserved" => 1,
               "ground_station_unavailable" => 1,
               "invalid_contact_input" => 1
             },
             "source_contact_filter_contact_ids_by_suppressed_reason" => %{
               "ground_station_capacity_zero" => ["dl_station_capacity_zero"],
               "ground_station_reserved" => ["dl_station_reserved"],
               "ground_station_unavailable" => ["dl_station_unavailable"],
               "invalid_contact_input" => ["invalid_contact"]
             },
             "source_contact_filter_direction_counts" => %{
               "command" => 1,
               "downlink" => 1,
               "health_check" => 1,
               "tracking" => 1
             },
             "source_contact_filter_contact_ids_by_direction" => %{
               "command" => ["dl_station_reserved"],
               "downlink" => ["dl_station_unavailable"],
               "health_check" => ["invalid_contact"],
               "tracking" => ["dl_station_capacity_zero"]
             },
             "source_contact_filter_station_suppression_count" => 3,
             "source_contact_filter_station_suppression_ground_station_counts" => %{
               "dss_43" => 2,
               "equator_prime" => 1
             },
             "source_contact_filter_station_suppression_availability_counts" => %{
               "reduced_capacity" => 1,
               "reserved" => 1,
               "unavailable" => 1
             },
             "source_contact_filter_station_suppression_status_counts" => %{
               "reserved" => 1,
               "unavailable" => 1
             },
             "source_contact_filter_station_suppression_station_reservation_ids_by_status" => %{
               "reserved" => ["reservation_dss_43"]
             },
             "source_contact_filter_trust_boundary_status" => "declared",
             "source_contact_filter_branch_local_contact_filter_pressure" => true,
             "source_contact_filter_branch_local_candidate_suppression_pressure" => true,
             "source_contact_filter_branch_local_invalid_contact_input_pressure" => true,
             "source_contact_filter_branch_local_station_suppression_pressure" => true
           } = observations

    stale_contact_filter_pressure_observations =
      observations
      |> Map.put("source_contact_filter_branch_local_contact_filter_pressure", false)

    assert {:ok, stale_contact_filter_pressure_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_contact_filter_pressure_observations
             )

    assert stale_contact_filter_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_contact_filter_pressure_verification["checks"],
             &(&1["field"] == "source_contact_filter_branch_local_contact_filter_pressure" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh candidate rejection replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.candidate_rejection_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_candidate_rejection_fixture()
    observations = candidate_refresh_candidate_rejection_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 2,
             "source_candidate_rejection_report_count" => 1,
             "source_candidate_rejection_row_count" => 2,
             "source_candidate_rejection_rejected_count" => 2,
             "source_candidate_rejection_reviewable_count" => 1,
             "source_candidate_rejection_invalid_candidate_input_count" => 1,
             "source_candidate_rejection_rejection_reason_counts" => %{
               "invalid_candidate_input" => 1,
               "station_reserved" => 1
             },
             "source_candidate_rejection_required_operator_action_counts" => %{
               "none" => 1,
               "review_candidate_rejection" => 1
             },
             "source_candidate_rejection_candidate_id_counts" => %{
               "bad_candidate" => 1,
               "dl_reserved" => 1
             },
             "source_candidate_rejection_ground_station_counts" => %{
               "dss_43" => 1,
               "equator_prime" => 1
             },
             "source_candidate_rejection_trust_boundary_status" => "declared",
             "source_candidate_rejection_branch_local_rejection_pressure" => true,
             "source_candidate_rejection_branch_local_review_pressure" => true,
             "source_candidate_rejection_branch_local_invalid_input_pressure" => true
           } = observations

    stale_rejection_pressure_observations =
      observations
      |> Map.put("source_candidate_rejection_branch_local_rejection_pressure", false)

    assert {:ok, stale_rejection_pressure_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_rejection_pressure_observations
             )

    assert stale_rejection_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_rejection_pressure_verification["checks"],
             &(&1["field"] == "source_candidate_rejection_branch_local_rejection_pressure" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end
end
