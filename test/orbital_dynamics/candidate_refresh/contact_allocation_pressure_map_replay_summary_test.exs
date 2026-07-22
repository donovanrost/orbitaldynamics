defmodule OrbitalDynamics.CandidateRefresh.ContactAllocationPressureMapReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "contact allocation replay preserves pressure maps with partial identity" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 1,
            "capacity_pack_selected_contact_ids_by_ground_station" => %{
              "equator_prime" => ["selected_contact"]
            },
            "capacity_pack_deferred_contact_ids_by_ground_station" => %{
              "equator_prime" => ["deferred_contact"]
            },
            "deferred_contact_ids" => ["deferred_contact"],
            "station_pressure_contact_ids_by_ground_station" => %{
              "polar_prime" => ["station_pressure_contact"]
            },
            "station_pressure_review_contact_ids" => ["station_pressure_contact"],
            "reservation_conflict_contact_ids" => ["reservation_conflict_contact"],
            "invalid_contact_input_ids" => ["invalid_contact"],
            "review_contact_ids" => ["review_contact"],
            "direction_counts" => %{
              "Down Link" => 1,
              "tracking" => 1,
              "uplink" => 1
            },
            "contact_ids_by_direction" => %{
              "down" => ["selected_contact"],
              "missing_direction" => ["orphan_contact"],
              "uplink" => ["shifted_uplink_a", "shifted_uplink_b"]
            },
            "direction_routing" => %{
              "downlink" => %{
                "contact_count" => 1,
                "contact_ids" => ["selected_contact"]
              },
              "stale_direction" => %{
                "contact_count" => 99,
                "contact_ids" => ["stale_contact"]
              }
            }
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.contact_allocation_replay_summary(artifact)

    assert source_summary["source_report_contact_allocation_contract"] ==
             "contact_allocation_report.v1"

    refute Map.has_key?(source_summary, "source_report_contact_allocation_count")
    refute Map.has_key?(source_summary, "source_report_contact_allocation_row_count")
    refute Map.has_key?(source_summary, "source_report_contact_allocation_paths")

    assert source_summary[
             "source_report_contact_allocation_capacity_pack_selected_contact_ids_by_ground_station"
           ] == %{"equator_prime" => ["selected_contact"]}

    assert source_summary[
             "source_report_contact_allocation_capacity_pack_deferred_contact_ids_by_ground_station"
           ] == %{"equator_prime" => ["deferred_contact"]}

    assert source_summary["source_report_contact_allocation_deferred_contact_ids"] == [
             "deferred_contact"
           ]

    assert source_summary[
             "source_report_contact_allocation_station_pressure_contact_ids_by_ground_station"
           ] == %{"polar_prime" => ["station_pressure_contact"]}

    assert source_summary["source_report_contact_allocation_station_pressure_review_contact_ids"] ==
             ["station_pressure_contact"]

    assert source_summary["source_report_contact_allocation_reservation_conflict_contact_ids"] ==
             [
               "reservation_conflict_contact"
             ]

    assert source_summary["source_report_contact_allocation_invalid_contact_input_ids"] == [
             "invalid_contact"
           ]

    assert source_summary["source_report_contact_allocation_review_contact_ids"] == [
             "review_contact"
           ]

    assert source_summary["source_report_contact_allocation_direction_counts"] == %{
             "downlink" => 1,
             "tracking" => 1,
             "uplink" => 1
           }

    assert source_summary["source_report_contact_allocation_contact_ids_by_direction"] == %{
             "downlink" => ["selected_contact"]
           }

    assert source_summary["source_report_contact_allocation_direction_routing"] == %{
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["selected_contact"],
               "provider_reservation_no_request_contact_ids" => [],
               "provider_reservation_request_contact_ids" => [],
               "provider_reservation_review_contact_ids" => [],
               "reservation_conflict_contact_ids" => [],
               "station_pressure_contact_ids" => []
             }
           }

    assert replay_summary["contract"] == "contact_allocation_report.v1"
    assert replay_summary["source_report_count"] == 1
    assert replay_summary["source_report_row_count"] == 0
    assert replay_summary["source_report_paths"] == []

    assert replay_summary["capacity_pack_selected_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["selected_contact"]
           }

    assert replay_summary["capacity_pack_deferred_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["deferred_contact"]
           }

    assert replay_summary["deferred_contact_ids"] == ["deferred_contact"]

    assert replay_summary["station_pressure_contact_ids_by_ground_station"] == %{
             "polar_prime" => ["station_pressure_contact"]
           }

    assert replay_summary["station_pressure_review_contact_ids"] == ["station_pressure_contact"]
    assert replay_summary["reservation_conflict_contact_ids"] == ["reservation_conflict_contact"]
    assert replay_summary["invalid_contact_input_ids"] == ["invalid_contact"]
    assert replay_summary["review_contact_ids"] == ["review_contact"]

    assert replay_summary["direction_counts"] == %{
             "downlink" => 1,
             "tracking" => 1,
             "uplink" => 1
           }

    assert replay_summary["contact_ids_by_direction"] == %{"downlink" => ["selected_contact"]}

    assert replay_summary["direction_routing"] == %{
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["selected_contact"],
               "provider_reservation_no_request_contact_ids" => [],
               "provider_reservation_request_contact_ids" => [],
               "provider_reservation_review_contact_ids" => [],
               "reservation_conflict_contact_ids" => [],
               "station_pressure_contact_ids" => []
             }
           }

    assert replay_summary["branch_local_contact_allocation_pressure"]
    assert replay_summary["branch_local_capacity_pack_pressure"]
    assert replay_summary["branch_local_deferred_allocation_pressure"]
    assert replay_summary["branch_local_station_pressure"]
    assert replay_summary["branch_local_reservation_conflict_pressure"]
  end

  test "contact allocation replay treats preserved ID maps as pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "paths" => ["provenance.source_reports.contact_allocation_report"],
            "contract" => "contact_allocation_report.v1",
            "count" => 1,
            "row_count" => 0,
            "blocked_row_count" => 0,
            "deferred_row_count" => 0,
            "station_pressure_contact_count" => 0,
            "station_pressure_review_contact_count" => 0,
            "capacity_pack_required_capacity_fraction" => 0.0,
            "capacity_pack_selected_required_capacity_fraction" => 0.0,
            "capacity_pack_deferred_required_capacity_fraction" => 0.0,
            "capacity_pack_selected_contact_ids_by_ground_station" => %{
              "equator_prime" => ["selected_contact"]
            },
            "capacity_pack_deferred_contact_ids_by_ground_station" => %{
              "equator_prime" => ["deferred_contact"]
            },
            "deferred_contact_count" => 0,
            "deferred_contact_ids" => ["deferred_contact"],
            "deferred_contact_ids_by_ground_station" => %{
              "equator_prime" => ["deferred_contact"]
            },
            "station_pressure_contact_ids_by_ground_station" => %{
              "polar_prime" => ["station_pressure_contact"]
            },
            "station_pressure_contact_ids_by_availability" => %{
              "reserved" => ["station_pressure_contact"]
            },
            "station_pressure_review_contact_ids" => ["station_pressure_contact"],
            "reservation_conflict_contact_count" => 0,
            "reservation_conflict_contact_ids" => ["reservation_conflict_contact"],
            "invalid_contact_input_count" => 0,
            "invalid_contact_input_ids" => ["invalid_contact"],
            "review_contact_ids" => ["review_contact"],
            "trust_boundary_status" => "declared",
            "trust_boundaries" => ["ops_contact_allocation"]
          }
        }
      }
    }

    summary = CandidateRefresh.contact_allocation_replay_summary(artifact)

    assert summary["blocked_row_count"] == 0
    assert summary["deferred_row_count"] == 0
    assert summary["station_pressure_contact_count"] == 1
    assert summary["station_pressure_review_contact_count"] == 1
    assert summary["reservation_conflict_contact_count"] == 1
    assert summary["invalid_contact_input_count"] == nil

    assert summary["capacity_pack_selected_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["selected_contact"]
           }

    assert summary["capacity_pack_deferred_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["deferred_contact"]
           }

    assert summary["deferred_contact_ids"] == ["deferred_contact"]

    assert summary["station_pressure_contact_ids_by_ground_station"] == %{
             "polar_prime" => ["station_pressure_contact"]
           }

    assert summary["reservation_conflict_contact_ids"] == ["reservation_conflict_contact"]
    assert summary["invalid_contact_input_ids"] == ["invalid_contact"]
    assert summary["review_contact_ids"] == ["review_contact"]
    assert summary["branch_local_contact_allocation_pressure"]
    refute summary["branch_local_blocked_allocation_pressure"]
    assert summary["branch_local_deferred_allocation_pressure"]
    assert summary["branch_local_station_pressure"]
    assert summary["branch_local_capacity_pack_pressure"]
    assert summary["branch_local_reservation_conflict_pressure"]
  end
end
