defmodule OrbitalDynamics.CandidateRefresh.StationCalendarBuildFilterTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CandidateRefresh, Epoch, ResultSet, Schema}

  test "uses mission-state station calendar intervals for branch-local contact filtering" do
    refresh =
      refresh_request()
      |> Map.delete("ground_network")
      |> Map.put("mission_state", %{
        "station_calendar" => [
          %{
            "id" => "mission_state_station_calendar_reserved",
            "station_id" => "equator_prime",
            "availability" => "reserved",
            "starts_at_s" => "280.0",
            "ends_at_s" => "450.0",
            "reservation_id" => "reservation_branch_1",
            "reserved_by" => "ops_team_branch",
            "reservation_status" => "confirmed",
            "reservation_hold_expires_at_s" => "420.0",
            "provenance" => %{"trust_boundary" => "strategy_branch_station_calendar"}
          }
        ]
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1"
           ]

    assert %{
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "leo_1_downlink_equator_prime_1",
                 "suppressed_reason" => "ground_station_reserved",
                 "station_calendar_entry_id" => "mission_state_station_calendar_reserved",
                 "station_calendar_reservation_ids" => ["reservation_branch_1"],
                 "station_calendar_reserved_by" => ["ops_team_branch"],
                 "station_calendar_reservation_statuses" => ["confirmed"],
                 "station_reservation_expires_at_s" => 420.0,
                 "station_calendar_reservation_expires_at_s" => [420.0],
                 "station_calendar_trust_boundary_status" => "declared",
                 "source_station_calendar_entry" => %{
                   "availability" => "reserved",
                   "ground_station_id" => "equator_prime",
                   "reservation_expires_at_s" => 420.0,
                   "provenance" => %{
                     "trust_boundary" => "strategy_branch_station_calendar"
                   }
                 }
               }
             ]
           } = artifact["contact_filter_report"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "uses mission-state station calendar provider lists for contact filtering" do
    refresh =
      refresh_request()
      |> Map.delete("ground_network")
      |> Map.put("mission_state", %{
        "station_calendar_provider" => [
          %{
            "schema_contract" => "station_calendar_provider.v1",
            "provider_id" => "ground_partner_aux",
            "trust_boundary" => "partner_api",
            "entries" => [
              %{
                "id" => "aux_station_available",
                "station_id" => "polar_aux",
                "availability" => "available",
                "starts_at_s" => 0.0,
                "ends_at_s" => 600.0
              }
            ]
          },
          %{
            "schema_contract" => "station_calendar_provider.v1",
            "provider_id" => "ground_partner_primary",
            "trust_boundary" => "partner_api",
            "entries" => [
              %{
                "id" => "primary_downlink_reserved",
                "station_id" => "equator_prime",
                "availability" => "reserved",
                "directions" => ["downlink"],
                "starts_at_s" => "280.0",
                "ends_at_s" => "450.0",
                "reservation_id" => "provider_reservation_1",
                "reserved_by" => "ground_partner_primary",
                "reservation_status" => "confirmed"
              }
            ]
          }
        ]
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1"
           ]

    assert %{
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "leo_1_downlink_equator_prime_1",
                 "suppressed_reason" => "ground_station_reserved",
                 "station_calendar_entry_id" => "primary_downlink_reserved",
                 "station_calendar_provider_id" => "ground_partner_primary",
                 "station_calendar_provider_entry_id" => "primary_downlink_reserved",
                 "station_calendar_reservation_ids" => ["provider_reservation_1"],
                 "station_calendar_reserved_by" => ["ground_partner_primary"],
                 "station_calendar_reservation_statuses" => ["confirmed"],
                 "station_calendar_directions" => ["downlink"],
                 "source_station_calendar_entry" => %{
                   "ground_station_id" => "equator_prime",
                   "provenance" => %{
                     "source" => "station_calendar_provider",
                     "provider_id" => "ground_partner_primary",
                     "trust_boundary" => "partner_api"
                   }
                 }
               }
             ]
           } = artifact["contact_filter_report"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "mission-state station calendar providers take precedence over duplicate direct entries" do
    refresh =
      refresh_request()
      |> Map.delete("ground_network")
      |> Map.put("mission_state", %{
        "station_calendar" => [
          %{
            "id" => "branch_station_entry",
            "station_id" => "equator_prime",
            "availability" => "unavailable",
            "starts_at_s" => "280.0",
            "ends_at_s" => "450.0",
            "provenance" => %{"trust_boundary" => "branch_direct_calendar"}
          }
        ],
        "station_calendar_provider" => [
          %{
            "schema_contract" => "station_calendar_provider.v1",
            "provider_id" => "ground_partner_primary",
            "trust_boundary" => "partner_api",
            "entries" => [
              %{
                "id" => "branch_station_entry",
                "station_id" => "equator_prime",
                "availability" => "available",
                "starts_at_s" => "280.0",
                "ends_at_s" => "450.0"
              }
            ]
          }
        ]
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1",
             "leo_1_downlink_equator_prime_1"
           ]

    assert %{
             "suppressed_candidate_count" => 0,
             "suppressed_candidates" => []
           } = artifact["contact_filter_report"]

    downlink_allocation =
      Enum.find(
        artifact["contact_allocation_report"]["rows"],
        &(&1["contact_id"] == "leo_1_downlink_equator_prime_1")
      )

    assert %{
             "contact_id" => "leo_1_downlink_equator_prime_1",
             "allocation_status" => "allocated",
             "station_calendar_entry_id" => "branch_station_entry",
             "station_calendar_provider_id" => "ground_partner_primary",
             "station_calendar_provider_entry_id" => "branch_station_entry",
             "station_calendar_trust_boundary_status" => "declared",
             "station_availability" => "available",
             "source_station_calendar_entry" => %{
               "availability" => "available",
               "provenance" => %{
                 "provider_id" => "ground_partner_primary",
                 "trust_boundary" => "partner_api"
               }
             }
           } = downlink_allocation

    refute Map.has_key?(downlink_allocation, "station_calendar_entry_ambiguous")

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "uses accepted planning-state station calendar intervals for contact filtering" do
    refresh =
      refresh_request()
      |> Map.delete("ground_network")
      |> put_in(["accepted_planning_state", "ground_network"], [])
      |> put_in(["accepted_planning_state", "station_calendar"], [
        %{
          "id" => "accepted_state_downlink_reserved",
          "station_id" => "equator_prime",
          "availability" => "reserved",
          "starts_at_s" => "280.0",
          "ends_at_s" => "450.0",
          "reservation_id" => "accepted_reservation_1",
          "reserved_by" => "ops_team_accepted",
          "reservation_status" => "confirmed",
          "provenance" => %{"trust_boundary" => "accepted_planning_state_calendar"}
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1"
           ]

    assert %{
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "leo_1_downlink_equator_prime_1",
                 "suppressed_reason" => "ground_station_reserved",
                 "station_calendar_entry_id" => "accepted_state_downlink_reserved",
                 "station_calendar_reservation_ids" => ["accepted_reservation_1"],
                 "station_calendar_reserved_by" => ["ops_team_accepted"],
                 "station_calendar_reservation_statuses" => ["confirmed"],
                 "station_calendar_trust_boundary_status" => "declared",
                 "trust_boundary" => "accepted_planning_state_calendar",
                 "source_station_calendar_entry" => %{
                   "availability" => "reserved",
                   "ground_station_id" => "equator_prime",
                   "provenance" => %{
                     "trust_boundary" => "accepted_planning_state_calendar"
                   }
                 }
               }
             ]
           } = artifact["contact_filter_report"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "does not apply ambiguous duplicate ground network state to refreshed downlinks" do
    refresh =
      refresh_request()
      |> Map.put("ground_network", [
        %{
          "ground_station_id" => "equator_prime",
          "capacity_fraction" => 0.25,
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0
        },
        %{
          "ground_station_id" => "equator_prime",
          "capacity_fraction" => 0.75,
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [downlink] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["estimated_throughput_mb"] == 360.0
    assert downlink["throughput_model"]["station_capacity_fraction"] == 1.0
    assert downlink["station_availability"] == "reduced_capacity"
    assert downlink["station_calendar_status"] == "ambiguous"
    assert downlink["station_calendar_entry_ambiguous"] == true
    assert downlink["station_calendar_ambiguous_entry_count"] == 2
    assert downlink["station_calendar_overlap_availabilities"] == ["reduced_capacity"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "ignores non-downlink direction-scoped ground network state for refreshed downlinks" do
    refresh =
      refresh_request()
      |> Map.put("ground_network", [
        %{
          "id" => "equator_uplink_reserved",
          "ground_station_id" => "equator_prime",
          "availability" => "Reserved",
          "station_calendar_directions" => ["uplink"],
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0,
          "reservation_id" => "uplink_reservation"
        },
        %{
          "id" => "equator_downlink_capacity",
          "ground_station_id" => "equator_prime",
          "availability" => "Reduced Capacity",
          "capacity_fraction" => 0.5,
          "station_calendar_directions" => ["downlink"],
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [downlink] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["station_calendar_entry_id"] == "equator_downlink_capacity"
    assert downlink["station_calendar_directions"] == ["downlink"]
    assert downlink["station_availability"] == "reduced_capacity"
    assert get_in(downlink, ["throughput_model", "station_capacity_fraction"]) == 0.5
    refute downlink["station_contention_status"] == "reserved_overlap"

    assert [contact_intent] = artifact["contact_intents"]
    assert contact_intent["station_calendar_entry_id"] == "equator_downlink_capacity"
    assert contact_intent["station_calendar_directions"] == ["downlink"]
    assert contact_intent["activity_context"]["station_calendar_directions"] == ["downlink"]

    assert artifact["contact_filter_report"]["suppressed_candidate_count"] == 0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "normalizes provider direction aliases at the candidate-refresh station boundary" do
    refresh =
      refresh_request()
      |> Map.put("ground_network", [
        %{
          "id" => "equator_uplink_reserved_alias",
          "ground_station_id" => "equator_prime",
          "availability" => "Reserved",
          "direction" => "Up Link",
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0,
          "reservation_id" => "uplink_reservation"
        }
      ])
      |> Map.put("station_calendar_provider", %{
        "schema_contract" => "station_calendar_provider.v1",
        "provider_id" => "ground_partner_a",
        "trust_boundary" => "ground_partner_api",
        "entries" => [
          %{
            "id" => "partner_down_link_capacity",
            "ground_station_id" => "equator_prime",
            "availability" => "Reduced Capacity",
            "capacity_fraction" => 0.5,
            "direction" => "Down Link",
            "starts_at_s" => 250.0,
            "ends_at_s" => 450.0
          }
        ]
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [downlink] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["station_calendar_entry_id"] == "partner_down_link_capacity"
    assert downlink["station_calendar_directions"] == ["downlink"]
    assert downlink["station_availability"] == "reduced_capacity"
    assert downlink["estimated_throughput_mb"] == 180.0
    assert get_in(downlink, ["throughput_model", "station_capacity_fraction"]) == 0.5
    refute downlink["station_reservation_id"] == "uplink_reservation"

    assert [contact_intent] = artifact["contact_intents"]
    assert contact_intent["station_calendar_directions"] == ["downlink"]

    assert artifact["contact_filter_report"]["suppressed_candidate_count"] == 0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "suppresses ambiguous unavailable ground-network rows in refreshed downlinks" do
    refresh =
      refresh_request()
      |> Map.put("ground_network", [
        %{
          "id" => "equator_outage_a",
          "ground_station_id" => "equator_prime",
          "status" => "maintenance",
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0
        },
        %{
          "id" => "equator_outage_b",
          "ground_station_id" => "equator_prime",
          "status" => "unavailable",
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1"
           ]

    assert %{
             "suppressed_candidates" => [
               %{
                 "id" => "leo_1_downlink_equator_prime_1",
                 "suppressed_reason" => "ground_station_unavailable",
                 "station_availability" => "unavailable",
                 "station_calendar_status" => "ambiguous",
                 "station_calendar_entry_ambiguous" => true,
                 "station_calendar_ambiguous_entry_count" => 2,
                 "station_calendar_ambiguous_entry_ids" => [
                   "equator_outage_a",
                   "equator_outage_b"
                 ]
               }
             ]
           } = artifact["contact_filter_report"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "suppresses ambiguous reserved ground-network rows without selecting one reservation" do
    refresh =
      refresh_request()
      |> Map.put("approval_policy", %{"policy_bundle_id" => "ground_network_allocation_v1"})
      |> Map.put("ground_network", [
        %{
          "id" => "equator_reserved_a",
          "ground_station_id" => "equator_prime",
          "status" => "Reserved",
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0,
          "reservation_id" => "reservation_a",
          "reserved_by" => "ops_team_a",
          "reservation_status" => "tentative",
          "hold_expires_at_s" => "360.0"
        },
        %{
          "id" => "equator_reserved_b",
          "ground_station_id" => "equator_prime",
          "availability" => "Reserved",
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0,
          "reservation_id" => "reservation_b",
          "reserved_by" => "ops_team_b",
          "reservation_status" => "confirmed",
          "reservation_expires_at_s" => 480.0
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "suppressed_candidates" => [
               %{
                 "id" => "leo_1_downlink_equator_prime_1",
                 "suppressed_reason" => "ground_station_reserved",
                 "station_availability" => "reserved",
                 "station_contention_status" => "reserved_overlap",
                 "station_calendar_status" => "ambiguous",
                 "station_calendar_entry_ambiguous" => true,
                 "station_calendar_ambiguous_entry_ids" => [
                   "equator_reserved_a",
                   "equator_reserved_b"
                 ],
                 "station_calendar_reservation_overlap_count" => 2,
                 "station_calendar_reservation_ids" => ["reservation_a", "reservation_b"],
                 "station_calendar_reserved_by" => ["ops_team_a", "ops_team_b"],
                 "station_calendar_reservation_statuses" => ["confirmed", "tentative"],
                 "station_calendar_reservation_expires_at_s" => [360.0, 480.0],
                 "approval_rule_matches" => rule_matches
               } = suppressed
             ]
           } = artifact["contact_filter_report"]

    refute Map.has_key?(suppressed, "station_reservation_id")
    refute Map.has_key?(suppressed, "station_reserved_by")
    refute Map.has_key?(suppressed, "station_reservation_status")
    refute Map.has_key?(suppressed, "station_reservation_expires_at_s")

    assert Enum.any?(
             rule_matches,
             &(&1["rule_id"] == "reserved_station_contact_review")
           )

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "applies station-id-only ground network state to refreshed downlinks" do
    refresh =
      refresh_request()
      |> Map.put("ground_network", [
        %{
          "id" => "equator_capacity",
          "station_id" => "equator_prime",
          "capacity_percent" => "50",
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0,
          "provenance" => %{
            "source" => "station_calendar_provider",
            "trust_boundary" => "declared_station_calendar"
          }
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [downlink] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["estimated_throughput_mb"] == 180.0
    assert downlink["throughput_model"]["station_capacity_fraction"] == 0.5
    assert downlink["station_availability"] == "reduced_capacity"
    assert downlink["source_station_calendar_entry"]["capacity_percent"] == "50"
    assert downlink["station_calendar_trust_boundary_status"] == "declared"
    assert downlink["trust_boundary"] == "declared_station_calendar"

    assert downlink["provenance"] == %{
             "source" => "station_calendar_provider",
             "trust_boundary" => "declared_station_calendar"
           }

    assert downlink["source_station_calendar_entry"]["id"] == "equator_capacity"
    assert [source_overlap] = downlink["source_station_calendar_overlaps"]
    assert source_overlap["id"] == "equator_capacity"

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "applies numeric availability aliases as refreshed downlink capacity factors" do
    refresh =
      refresh_request()
      |> Map.put("ground_network", [
        %{
          "id" => "equator_capacity_alias",
          "ground_station" => %{"id" => "equator_prime"},
          "availability" => "0.5",
          "start_s" => "250.0",
          "end_s" => "450.0"
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [downlink] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["station_calendar_entry_id"] == "equator_capacity_alias"
    assert downlink["estimated_throughput_mb"] == 180.0
    assert downlink["station_availability"] == "reduced_capacity"
    assert downlink["throughput_model"]["station_capacity_fraction"] == 0.5
    assert downlink["throughput_model"]["declared_station_capacity_fraction"] == 0.5
    assert artifact["contact_filter_report"]["suppressed_candidate_count"] == 0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "applies nested numeric availability aliases as refreshed downlink capacity factors" do
    refresh =
      refresh_request()
      |> Map.put("ground_network", [
        %{
          "id" => "equator_nested_capacity_alias",
          "station_id" => "equator_prime",
          "capacity_model" => %{"availability" => "0.4"},
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [downlink] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["station_calendar_entry_id"] == "equator_nested_capacity_alias"
    assert downlink["estimated_throughput_mb"] == 144.0
    assert downlink["station_availability"] == "reduced_capacity"
    assert downlink["throughput_model"]["station_capacity_fraction"] == 0.4
    assert downlink["throughput_model"]["declared_station_capacity_fraction"] == 0.4

    assert get_in(downlink, [
             "source_station_calendar_entry",
             "capacity_model",
             "availability"
           ]) == "0.4"

    assert artifact["contact_filter_report"]["suppressed_candidate_count"] == 0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "does not apply non-overlapping ground-network timing aliases to refreshed downlinks" do
    refresh =
      refresh_request()
      |> Map.put("ground_network", [
        %{
          "id" => "equator_off_horizon_outage",
          "station_id" => "equator_prime",
          "availability" => "Unavailable",
          "start_s" => "10.0",
          "end_s" => "20.0"
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [downlink] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["station_availability"] == "available"
    refute Map.has_key?(downlink, "station_calendar_entry_id")
    assert artifact["contact_filter_report"]["suppressed_candidate_count"] == 0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "accepts station calendar provider artifacts for refresh filtering and allocation" do
    refresh =
      refresh_request()
      |> Map.put("approval_policy", %{"policy_bundle_id" => "ground_network_allocation_v1"})
      |> Map.put("station_calendar_provider", %{
        "schema_contract" => "station_calendar_provider.v1",
        "provider_id" => "ground_partner_a",
        "trust_boundary" => "ground_partner_api",
        "entries" => [
          %{
            "id" => "partner_reserved_downlink",
            "ground_station_id" => "equator_prime",
            "status" => "reserved",
            "directions" => ["downlink"],
            "starts_at_s" => 250.0,
            "ends_at_s" => 450.0,
            "reservation_id" => "provider_reservation_1",
            "reserved_by" => "partner_ops",
            "reservation_status" => "confirmed"
          }
        ]
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1"
           ]

    assert %{
             "suppressed_candidates" => [
               %{
                 "id" => "leo_1_downlink_equator_prime_1",
                 "suppressed_reason" => "ground_station_reserved",
                 "station_calendar_entry_id" => "partner_reserved_downlink",
                 "station_reservation_id" => "provider_reservation_1",
                 "station_reserved_by" => "partner_ops",
                 "station_reservation_status" => "confirmed",
                 "station_calendar_trust_boundary_status" => "declared",
                 "trust_boundary" => "ground_partner_api",
                 "source_station_calendar_entry" => %{
                   "id" => "partner_reserved_downlink",
                   "provenance" => %{
                     "source" => "station_calendar_provider",
                     "provider_id" => "ground_partner_a",
                     "trust_boundary" => "ground_partner_api"
                   }
                 }
               }
             ]
           } = artifact["contact_filter_report"]

    assert %{
             "blocked_contact_count" => 1,
             "station_reservation_match_status_counts" => %{"overlap" => 1},
             "rows" => [
               %{
                 "contact_id" => "leo_1_downlink_equator_prime_1",
                 "allocation_status" => "blocked",
                 "allocation_reason" => "ground_station_reserved",
                 "station_calendar_entry_id" => "partner_reserved_downlink",
                 "station_reservation_id" => "provider_reservation_1",
                 "trust_boundary" => "ground_partner_api"
               }
             ]
           } = artifact["contact_allocation_report"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "merges direct ground-network entries with station calendar provider artifacts" do
    refresh =
      refresh_request()
      |> Map.put("approval_policy", %{"policy_bundle_id" => "ground_network_allocation_v1"})
      |> Map.put("ground_network", [
        %{
          "id" => "equator_declared_capacity",
          "ground_station_id" => "equator_prime",
          "capacity_fraction" => 0.75,
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0
        }
      ])
      |> Map.put("station_calendar_provider", %{
        "schema_contract" => "station_calendar_provider.v1",
        "provider_id" => "ground_partner_a",
        "trust_boundary" => "ground_partner_api",
        "entries" => [
          %{
            "id" => "partner_reserved_downlink",
            "ground_station_id" => "equator_prime",
            "status" => "reserved",
            "directions" => ["downlink"],
            "starts_at_s" => 250.0,
            "ends_at_s" => 450.0,
            "reservation_id" => "provider_reservation_1"
          }
        ]
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1"
           ]

    assert [suppressed] = artifact["contact_filter_report"]["suppressed_candidates"]

    assert suppressed["id"] == "leo_1_downlink_equator_prime_1"
    assert suppressed["suppressed_reason"] == "ground_station_reserved"
    assert suppressed["station_calendar_entry_id"] == "partner_reserved_downlink"
    assert suppressed["station_reservation_id"] == "provider_reservation_1"

    source_entry =
      suppressed["source_station_calendar_entry"] ||
        get_in(suppressed, ["activity_context", "source_station_calendar_entry"])

    assert %{
             "id" => "partner_reserved_downlink",
             "provenance" => %{
               "source" => "station_calendar_provider",
               "provider_id" => "ground_partner_a",
               "trust_boundary" => "ground_partner_api"
             }
           } = source_entry

    overlaps =
      suppressed["source_station_calendar_overlaps"] ||
        get_in(suppressed, ["activity_context", "source_station_calendar_overlaps"])

    overlap_entry_ids =
      suppressed["station_calendar_overlap_entry_ids"] ||
        get_in(suppressed, ["activity_context", "station_calendar_overlap_entry_ids"]) ||
        Enum.map(overlaps || [], & &1["id"])

    assert Enum.sort(overlap_entry_ids) == [
             "equator_declared_capacity",
             "partner_reserved_downlink"
           ]

    assert Enum.any?(overlaps, &(&1["id"] == "equator_declared_capacity"))
    assert Enum.any?(overlaps, &(&1["id"] == "partner_reserved_downlink"))

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "prefers provider calendar source over same-id direct ground-network entries" do
    refresh =
      refresh_request()
      |> Map.put("ground_network", [
        %{
          "id" => "partner_capacity_downlink",
          "ground_station_id" => "equator_prime",
          "capacity_fraction" => 0.25,
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0
        }
      ])
      |> Map.put("station_calendar_provider", %{
        "schema_contract" => "station_calendar_provider.v1",
        "provider_id" => "ground_partner_a",
        "trust_boundary" => "ground_partner_api",
        "entries" => [
          %{
            "id" => "partner_capacity_downlink",
            "ground_station_id" => "equator_prime",
            "availability" => "reduced_capacity",
            "capacity_fraction" => 0.5,
            "directions" => ["downlink"],
            "starts_at_s" => 250.0,
            "ends_at_s" => 450.0
          }
        ]
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [downlink] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["station_calendar_entry_id"] == "partner_capacity_downlink"
    assert downlink["station_calendar_provider_id"] == "ground_partner_a"
    assert downlink["station_calendar_provider_entry_id"] == "partner_capacity_downlink"
    assert downlink["estimated_throughput_mb"] == 180.0
    assert downlink["station_availability"] == "reduced_capacity"
    assert downlink["throughput_model"]["station_capacity_fraction"] == 0.5
    assert downlink["throughput_model"]["declared_station_capacity_fraction"] == 0.5
    assert downlink["station_calendar_trust_boundary_status"] == "declared"
    assert downlink["trust_boundary"] == "ground_partner_api"
    refute downlink["station_calendar_entry_ambiguous"]

    assert [source_overlap] = downlink["source_station_calendar_overlaps"]
    assert source_overlap["id"] == "partner_capacity_downlink"
    assert get_in(source_overlap, ["provenance", "source"]) == "station_calendar_provider"

    assert artifact["contact_filter_report"]["suppressed_candidate_count"] == 0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "filters refreshed contacts using ground network availability" do
    refresh =
      Map.put(refresh_request(), "ground_network", [
        %{
          "ground_station_id" => "equator_prime",
          "status" => "Unavailable",
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1"
           ]

    assert artifact["contact_intents"] == []

    assert %{
             "schema_contract" => "contact_filter_report.v1",
             "input_candidate_count" => 2,
             "kept_candidate_count" => 1,
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "leo_1_downlink_equator_prime_1",
                 "suppressed_reason" => "ground_station_unavailable"
               }
             ]
           } = artifact["contact_filter_report"]

    assert "ground network filters suppressed refreshed contact candidates" in artifact[
             "warnings"
           ]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "filters refreshed contacts using reserved ground station windows" do
    refresh =
      refresh_request()
      |> Map.put("approval_policy", %{"policy_bundle_id" => "ground_network_allocation_v1"})
      |> Map.put("ground_network", [
        %{
          "ground_station_id" => "equator_prime",
          "status" => "Reserved",
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0,
          "reservation_id" => "reservation_equator_prime_1",
          "reserved_by" => "ops_team_b",
          "reservation_status" => "reserved"
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1"
           ]

    assert artifact["contact_intents"] == []

    assert %{
             "schema_contract" => "contact_filter_report.v1",
             "input_candidate_count" => 2,
             "kept_candidate_count" => 1,
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "leo_1_downlink_equator_prime_1",
                 "suppressed_reason" => "ground_station_reserved",
                 "station_availability" => "reserved",
                 "station_contention_status" => "reserved_overlap",
                 "station_reservation_id" => "reservation_equator_prime_1",
                 "station_reserved_by" => "ops_team_b",
                 "station_reservation_status" => "reserved",
                 "station_reservation_match_status" => "overlap",
                 "approval_status" => "operator_review_required",
                 "policy_decision" => %{
                   "policy_bundle_id" => "ground_network_allocation_v1"
                 },
                 "approval_rule_matches" => [
                   %{"rule_id" => "reserved_station_contact_review"}
                 ]
               }
             ]
           } = artifact["contact_filter_report"]

    assert %{
             "schema_contract" => "contact_allocation_report.v1",
             "input_contact_count" => 1,
             "allocated_contact_count" => 0,
             "blocked_contact_count" => 1,
             "rows" => [
               %{
                 "contact_id" => "leo_1_downlink_equator_prime_1",
                 "allocation_status" => "blocked",
                 "allocation_reason" => "ground_station_reserved",
                 "station_contention_status" => "reserved_overlap",
                 "station_reservation_id" => "reservation_equator_prime_1",
                 "station_reservation_match_status" => "overlap",
                 "approval_status" => "operator_review_required",
                 "policy_decision" => %{
                   "schema_contract" => "policy_decision.v1",
                   "policy_bundle_id" => "ground_network_allocation_v1",
                   "classification" => "operator_review_required"
                 },
                 "approval_rule_matches" => rule_matches
               }
             ]
           } = artifact["contact_allocation_report"]

    assert Enum.any?(
             rule_matches,
             &(&1["rule_id"] == "reserved_station_contact_review" and
                 &1["station_reservation_status"] == "reserved")
           )

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "unavailable station refresh state outranks reserved overlap while preserving reservation evidence" do
    refresh =
      refresh_request()
      |> Map.put("approval_policy", %{"policy_bundle_id" => "ground_network_allocation_v1"})
      |> Map.put("ground_network", [
        %{
          "ground_station_id" => "equator_prime",
          "status" => "Unavailable",
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0
        },
        %{
          "ground_station_id" => "equator_prime",
          "status" => "Reserved",
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0,
          "reservation_id" => "reservation_equator_prime_1",
          "reserved_by" => "ops_team_b",
          "reservation_status" => "confirmed"
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "suppressed_candidates" => [
               %{
                 "id" => "leo_1_downlink_equator_prime_1",
                 "suppressed_reason" => "ground_station_unavailable",
                 "station_availability" => "unavailable",
                 "station_contention_status" => "reserved_overlap",
                 "station_reservation_id" => "reservation_equator_prime_1",
                 "station_reserved_by" => "ops_team_b",
                 "station_reservation_status" => "confirmed",
                 "station_reservation_match_status" => "overlap",
                 "station_calendar_reservation_overlap_count" => 1,
                 "station_calendar_reservation_ids" => ["reservation_equator_prime_1"],
                 "station_calendar_reserved_by" => ["ops_team_b"],
                 "station_calendar_reservation_statuses" => ["confirmed"],
                 "approval_status" => "blocked_by_policy",
                 "approval_rule_matches" => rule_matches
               }
             ]
           } = artifact["contact_filter_report"]

    assert Enum.any?(
             rule_matches,
             &(&1["rule_id"] == "unavailable_station_contact_block" and
                 &1["classification"] == "blocked_by_policy")
           )

    assert %{
             "rows" => [
               %{
                 "contact_id" => "leo_1_downlink_equator_prime_1",
                 "allocation_status" => "blocked",
                 "allocation_reason" => "ground_station_unavailable",
                 "station_availability" => "unavailable",
                 "station_contention_status" => "reserved_overlap",
                 "station_reservation_id" => "reservation_equator_prime_1",
                 "station_reservation_match_status" => "overlap"
               }
             ]
           } = artifact["contact_allocation_report"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "availability-only maintenance station refresh state suppresses generated downlinks" do
    refresh =
      refresh_request()
      |> Map.put("approval_policy", %{"policy_bundle_id" => "ground_network_allocation_v1"})
      |> Map.put("ground_network", [
        %{
          "id" => "equator_maintenance",
          "ground_station_id" => "equator_prime",
          "availability" => "Maintenance",
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1"
           ]

    assert %{
             "suppressed_candidates" => [
               %{
                 "id" => "leo_1_downlink_equator_prime_1",
                 "suppressed_reason" => "ground_station_unavailable",
                 "station_availability" => "unavailable",
                 "station_calendar_entry_id" => "equator_maintenance",
                 "source_station_calendar_entry" => %{
                   "availability" => "maintenance"
                 },
                 "approval_status" => "blocked_by_policy"
               }
             ]
           } = artifact["contact_filter_report"]

    assert %{
             "rows" => [
               %{
                 "contact_id" => "leo_1_downlink_equator_prime_1",
                 "allocation_status" => "blocked",
                 "allocation_reason" => "ground_station_unavailable",
                 "station_availability" => "unavailable",
                 "station_calendar_entry_id" => "equator_maintenance"
               }
             ]
           } = artifact["contact_allocation_report"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp result_set do
    ResultSet.new!(%{
      study_id: :candidate_refresh_demo,
      trajectory_results: [],
      event_results: [
        %{
          scenario_id: :leo_1,
          event_type: :target_visibility,
          events: [
            %{
              type: :target_visibility,
              starts_at: Epoch.new!(120.0, :tdb),
              ends_at: Epoch.new!(240.0, :tdb),
              metadata: %{
                target_id: :target_a,
                target_priority: 1.0,
                max_elevation_deg: 80.0,
                minimum_elevation_deg: 10.0,
                sample_count: 3,
                interpolation: :linear_sample_crossing,
                boundary_refinement: :target_visibility_linear_margin_interpolation,
                start_boundary: :clipped_start,
                end_boundary: :visibility_end,
                start_boundary_detail: %{
                  boundary: :clipped_start,
                  interpolation: :clipped_to_sample,
                  interpolation_fraction: 0.0,
                  sample_index: 1,
                  elevation_deg: 80.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                end_boundary_detail: %{
                  edge: :end,
                  boundary: :visibility_end,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.5,
                  before_sample_index: 4,
                  after_sample_index: 5,
                  before_elevation_deg: 20.0,
                  after_elevation_deg: 0.0,
                  minimum_elevation_deg: 10.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                event_timing_policy: :sampled_state_linear_boundary,
                event_detector: :target_visibility,
                event_time_tolerance_s: 60.0,
                max_sample_step_s: 60.0,
                confidence: :bounded_by_sample_cadence
              }
            }
          ],
          source: %{target_id: :target_a}
        },
        %{
          scenario_id: :leo_1,
          event_type: :ground_station_access,
          events: [
            %{
              type: :ground_station_access,
              starts_at: Epoch.new!(300.0, :tdb),
              ends_at: Epoch.new!(420.0, :tdb),
              metadata: %{
                max_elevation_deg: 70.0,
                minimum_elevation_deg: 5.0,
                sample_count: 4,
                interpolation: :linear_sample_crossing,
                boundary_refinement: :aos_los_linear_margin_interpolation,
                start_boundary: :aos,
                end_boundary: :los,
                start_boundary_detail: %{
                  edge: :start,
                  boundary: :aos,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.25,
                  before_sample_index: 2,
                  after_sample_index: 3,
                  before_elevation_deg: 0.0,
                  after_elevation_deg: 20.0,
                  minimum_elevation_deg: 5.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                end_boundary_detail: %{
                  edge: :end,
                  boundary: :los,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.75,
                  before_sample_index: 4,
                  after_sample_index: 5,
                  before_elevation_deg: 20.0,
                  after_elevation_deg: 0.0,
                  minimum_elevation_deg: 5.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                event_timing_policy: :sampled_state_linear_boundary,
                event_detector: :access_windows,
                event_time_tolerance_s: 60.0,
                max_sample_step_s: 60.0,
                confidence: :bounded_by_sample_cadence
              }
            }
          ],
          source: %{ground_station_id: :equator_prime}
        },
        %{
          scenario_id: :other,
          event_type: :eclipse,
          events: [
            %{
              type: :eclipse,
              starts_at: Epoch.new!(120.0, :tdb),
              ends_at: Epoch.new!(240.0, :tdb),
              metadata: %{sample_count: 3}
            }
          ],
          source: %{shadow_model: :cylindrical_central_body_shadow}
        }
      ],
      errors: [],
      assumptions: %{propagator: OrbitalDynamics.Propagators.TwoBody, outputs: [:access_windows]},
      metadata: %{}
    })
  end

  defp refresh_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-1",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [%{"spacecraft_id" => "sat_1", "scenario_id" => "leo_1"}],
        "maneuver_execution_deltas" => [],
        "source" => %{"system" => "cadence"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "test"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [%{"id" => "target_a", "priority" => 2.0}],
      "constraints" => %{"avoid_eclipse" => true, "min_activity_duration_s" => 60.0},
      "scoring_policy" => %{
        "target_value_weight" => 1.0,
        "contact_value_weight" => 0.5,
        "downlink_rate_mb_s" => 3.0
      },
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "resource_summaries" => [
        %{
          "spacecraft_id" => "leo_1",
          "fuel_margin" => 0.9,
          "storage_capacity_mb" => 1000.0,
          "storage_used_mb" => 200.0
        }
      ],
      "prior_candidate_activities" => [
        %{
          "id" => "stale_observe",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "starts_at_s" => 10.0,
          "ends_at_s" => 20.0
        }
      ]
    }
  end
end
