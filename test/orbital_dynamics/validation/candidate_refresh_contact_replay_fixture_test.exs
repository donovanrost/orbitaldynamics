defmodule OrbitalDynamics.Validation.CandidateRefreshContactReplayFixtureTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Validation}

  import OrbitalDynamics.Validation.CandidateRefreshContactReplayFixtures,
    only: [
      candidate_refresh_contact_contention_challenge_fixture: 0,
      candidate_refresh_contact_contention_challenge_fixture_observations: 0,
      candidate_refresh_contact_intent_direction_fixture: 0,
      candidate_refresh_contact_intent_direction_fixture_observations: 0
    ]

  test "verifies candidate refresh contact contention challenge replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.contact_contention_cross_station_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_contact_contention_challenge_fixture()
    observations = candidate_refresh_contact_contention_challenge_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_contact_contention_report_count" => 1,
             "source_contact_contention_row_count" => 1,
             "source_contact_contention_resource_scope_counts" => %{"spacecraft" => 1},
             "source_contact_contention_direction_counts" => %{"downlink" => 2},
             "source_contact_contention_contact_ids_by_direction" => %{
               "downlink" => ["dl_dsn", "dl_equator"]
             },
             "source_contact_contention_required_operator_action_counts" => %{
               "review_contact_contention" => 1
             },
             "source_contact_contention_trust_boundary_status" => "declared"
           } = observations

    stale_scope_observations =
      observations
      |> Map.put("source_contact_contention_resource_scope_counts", %{"ground_station" => 1})

    assert {:ok, stale_scope_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_scope_observations)

    assert stale_scope_verification["status"] == "fail"

    assert Enum.any?(
             stale_scope_verification["checks"],
             &(&1["field"] == "source_contact_contention_resource_scope_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh contact intent direction replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.contact_intent_direction_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_contact_intent_direction_fixture()
    observations = candidate_refresh_contact_intent_direction_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_contact_intent_report_count" => 3,
             "source_contact_intent_row_count" => 3,
             "source_contact_intent_capacity_pack_required_contact_count" => 2,
             "source_contact_intent_capacity_pack_required_capacity_fraction" => 0.65,
             "source_contact_intent_capacity_pack_required_capacity_fraction_by_direction" => %{
               "downlink" => 0.25,
               "tracking" => 0.4
             },
             "source_contact_intent_capacity_pack_required_capacity_fraction_by_direction_and_ground_station" =>
               %{
                 "downlink" => %{"equator_prime" => 0.25},
                 "tracking" => %{"dss_43" => 0.4}
               },
             "source_contact_intent_capacity_pack_contact_ids_by_direction" => %{
               "downlink" => ["intent_direct_capacity"],
               "tracking" => ["intent_nested_capacity"]
             },
             "source_contact_intent_capacity_pack_contact_ids_by_direction_and_ground_station" =>
               %{
                 "downlink" => %{"equator_prime" => ["intent_direct_capacity"]},
                 "tracking" => %{"dss_43" => ["intent_nested_capacity"]}
               },
             "source_contact_intent_direction_keys" => "command|downlink|tracking",
             "source_contact_intent_direction_counts" => %{
               "command" => 1,
               "downlink" => 1,
               "tracking" => 1
             },
             "source_contact_intent_contact_ids_by_direction" => %{
               "command" => ["intent_station_only"],
               "downlink" => ["intent_direct_capacity"],
               "tracking" => ["intent_nested_capacity"]
             },
             "source_contact_intent_contact_ids_by_direction_and_ground_station" => %{
               "command" => %{"dss_43" => ["intent_station_only"]},
               "downlink" => %{"equator_prime" => ["intent_direct_capacity"]},
               "tracking" => %{"dss_43" => ["intent_nested_capacity"]}
             },
             "source_contact_intent_direction_routing" => %{
               "command" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["intent_station_only"],
                 "capacity_pack_contact_ids" => [],
                 "ground_station_ids" => ["dss_43"],
                 "contact_ids_by_ground_station" => %{"dss_43" => ["intent_station_only"]}
               },
               "downlink" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["intent_direct_capacity"],
                 "capacity_pack_required_capacity_fraction" => 0.25,
                 "capacity_pack_contact_ids" => ["intent_direct_capacity"],
                 "ground_station_ids" => ["equator_prime"],
                 "contact_ids_by_ground_station" => %{
                   "equator_prime" => ["intent_direct_capacity"]
                 },
                 "capacity_pack_required_capacity_fraction_by_ground_station" => %{
                   "equator_prime" => 0.25
                 },
                 "capacity_pack_contact_ids_by_ground_station" => %{
                   "equator_prime" => ["intent_direct_capacity"]
                 }
               },
               "tracking" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["intent_nested_capacity"],
                 "capacity_pack_required_capacity_fraction" => 0.4,
                 "capacity_pack_contact_ids" => ["intent_nested_capacity"],
                 "ground_station_ids" => ["dss_43"],
                 "contact_ids_by_ground_station" => %{"dss_43" => ["intent_nested_capacity"]},
                 "capacity_pack_required_capacity_fraction_by_ground_station" => %{
                   "dss_43" => 0.4
                 },
                 "capacity_pack_contact_ids_by_ground_station" => %{
                   "dss_43" => ["intent_nested_capacity"]
                 }
               }
             },
             "source_contact_intent_trust_boundary_status" => "declared"
           } = observations

    stale_routing_observations =
      observations
      |> put_in(
        ["source_contact_intent_direction_routing", "downlink", "capacity_pack_contact_ids"],
        ["stale_intent"]
      )

    assert {:ok, stale_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_routing_observations)

    assert stale_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_routing_verification["checks"],
             &(&1["field"] == "source_contact_intent_direction_routing" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end
end
