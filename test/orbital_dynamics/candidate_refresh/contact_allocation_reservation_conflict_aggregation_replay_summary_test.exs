defmodule OrbitalDynamics.CandidateRefresh.ContactAllocationReservationConflictAggregationReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary aggregates contact allocation reservation conflicts" do
    refresh = %{
      "source_contact_allocation_report" => %{
        "schema_contract" => "contact_allocation_report.v1",
        "rows" => [
          %{
            "contact_id" => "reservation_conflict_contact",
            "allocation_status" => "blocked",
            "ground_station_id" => "polar_prime",
            "direction" => "downlink",
            "station_reservation_match_status" => "overlap",
            "station_reservation_id" => "reservation_polar_prime",
            "station_reservation_status" => "reserved",
            "station_reserved_by" => "ops_team",
            "station_reservation_expires_at_s" => "420.0"
          },
          %{
            "contact_id" => "reservation_missing_expiration_contact",
            "allocation_status" => "blocked",
            "ground_station_id" => "polar_prime",
            "station_reservation_match_status" => "matched",
            "station_reservation_id" => "reservation_missing_expiration",
            "station_reservation_status" => "reserved",
            "station_reserved_by" => "ops_team"
          },
          %{
            "contact_id" => "reservation_expired_contact",
            "allocation_status" => "blocked",
            "ground_station_id" => "polar_prime",
            "station_reservation_match_status" => "matched",
            "station_reservation_id" => "reservation_expired",
            "station_reservation_status" => "reserved",
            "station_reserved_by" => "ops_team",
            "station_reservation_expires_at_s" => 360.0
          }
        ],
        "reservation_conflict_contact_count" => 99,
        "reservation_conflict_contact_ids" => ["stale_reservation_conflict_contact"],
        "reservation_conflict_match_status_counts" => %{"stale_match_status" => 99},
        "reservation_conflict_contact_ids_by_match_status" => %{
          "stale_match_status" => ["stale_reservation_conflict_contact"]
        },
        "reservation_conflict_reservation_ids_by_match_status" => %{
          "stale_match_status" => ["stale_reservation_id"]
        },
        "station_reservation_match_status_counts" => %{"stale_match_status" => 99},
        "station_reservation_contact_ids_by_match_status" => %{
          "stale_match_status" => ["stale_reservation_contact"]
        },
        "station_reservation_ids_by_match_status" => %{
          "stale_match_status" => ["stale_reservation_id"]
        },
        "station_reservation_status_counts" => %{"stale_status" => 99},
        "station_reserved_by_counts" => %{"stale_owner" => 99},
        "station_reservation_ids" => ["stale_reservation_id"],
        "station_reservation_contact_ids_by_status" => %{
          "stale_status" => ["stale_reservation_conflict_contact"]
        },
        "station_reservation_contact_ids_by_reserved_by" => %{
          "stale_owner" => ["stale_reservation_conflict_contact"]
        },
        "station_reservation_ids_by_status" => %{
          "stale_status" => ["stale_reservation_id"]
        },
        "station_reservation_ids_by_reserved_by" => %{
          "stale_owner" => ["stale_reservation_id"]
        },
        "station_reservation_expires_at_s" => [999.0],
        "station_reservation_expiration_status_counts" => %{"stale_expiration" => 99},
        "station_reservation_active_contact_count" => 99,
        "station_reservation_expired_contact_count" => 99,
        "station_reservation_declared_expiration_contact_count" => 99,
        "station_reservation_missing_expiration_contact_count" => 99,
        "earliest_station_reservation_expires_at_s" => 999.0,
        "station_reservation_contact_ids_by_expiration_status" => %{
          "stale_expiration" => ["stale_reservation_conflict_contact"]
        },
        "station_reservation_ids_by_expiration_status" => %{
          "stale_expiration" => ["stale_reservation_id"]
        },
        "station_reservation_expiration_now_s" => 400.0,
        "provenance" => %{"trust_boundary" => "ops_contact_allocation"}
      }
    }

    assert %{
             "source_report_contact_allocation_reservation_conflict_contact_count" => 1,
             "source_report_contact_allocation_reservation_conflict_contact_ids" => [
               "reservation_conflict_contact"
             ],
             "source_report_contact_allocation_reservation_conflict_match_status_counts" => %{
               "overlap" => 1
             },
             "source_report_contact_allocation_reservation_conflict_contact_ids_by_match_status" =>
               %{
                 "overlap" => ["reservation_conflict_contact"]
               },
             "source_report_contact_allocation_reservation_conflict_reservation_ids_by_match_status" =>
               %{
                 "overlap" => ["reservation_polar_prime"]
               },
             "source_report_contact_allocation_reservation_conflict_direction_counts" => %{
               "downlink" => 1
             },
             "source_report_contact_allocation_reservation_conflict_contact_ids_by_direction" =>
               %{
                 "downlink" => ["reservation_conflict_contact"]
               },
             "source_report_contact_allocation_station_reservation_match_status_counts" => %{
               "matched" => 2,
               "overlap" => 1
             },
             "source_report_contact_allocation_station_reservation_contact_ids_by_match_status" =>
               %{
                 "matched" => [
                   "reservation_expired_contact",
                   "reservation_missing_expiration_contact"
                 ],
                 "overlap" => ["reservation_conflict_contact"]
               },
             "source_report_contact_allocation_station_reservation_ids_by_match_status" => %{
               "matched" => ["reservation_expired", "reservation_missing_expiration"],
               "overlap" => ["reservation_polar_prime"]
             },
             "source_report_contact_allocation_station_reservation_status_counts" => %{
               "reserved" => 3
             },
             "source_report_contact_allocation_station_reserved_by_counts" => %{
               "ops_team" => 3
             },
             "source_report_contact_allocation_station_reservation_ids" => [
               "reservation_expired",
               "reservation_missing_expiration",
               "reservation_polar_prime"
             ],
             "source_report_contact_allocation_station_reservation_contact_ids_by_status" => %{
               "reserved" => [
                 "reservation_conflict_contact",
                 "reservation_expired_contact",
                 "reservation_missing_expiration_contact"
               ]
             },
             "source_report_contact_allocation_station_reservation_contact_ids_by_reserved_by" =>
               %{
                 "ops_team" => [
                   "reservation_conflict_contact",
                   "reservation_expired_contact",
                   "reservation_missing_expiration_contact"
                 ]
               },
             "source_report_contact_allocation_station_reservation_ids_by_status" => %{
               "reserved" => [
                 "reservation_expired",
                 "reservation_missing_expiration",
                 "reservation_polar_prime"
               ]
             },
             "source_report_contact_allocation_station_reservation_ids_by_reserved_by" => %{
               "ops_team" => [
                 "reservation_expired",
                 "reservation_missing_expiration",
                 "reservation_polar_prime"
               ]
             },
             "source_report_contact_allocation_station_reservation_expires_at_s" => [
               360.0,
               420.0
             ],
             "source_report_contact_allocation_station_reservation_expiration_now_s" => 400.0,
             "source_report_contact_allocation_station_reservation_expiration_status_counts" => %{
               "active" => 1,
               "expired" => 1,
               "missing" => 1
             },
             "source_report_contact_allocation_station_reservation_active_contact_count" => 1,
             "source_report_contact_allocation_station_reservation_expired_contact_count" => 1,
             "source_report_contact_allocation_station_reservation_declared_expiration_contact_count" =>
               0,
             "source_report_contact_allocation_station_reservation_missing_expiration_contact_count" =>
               1,
             "source_report_contact_allocation_earliest_station_reservation_expires_at_s" =>
               360.0,
             "source_report_contact_allocation_station_reservation_contact_ids_by_expiration_status" =>
               %{
                 "active" => ["reservation_conflict_contact"],
                 "expired" => ["reservation_expired_contact"],
                 "missing" => ["reservation_missing_expiration_contact"]
               },
             "source_report_contact_allocation_station_reservation_ids_by_expiration_status" => %{
               "active" => ["reservation_polar_prime"],
               "expired" => ["reservation_expired"],
               "missing" => ["reservation_missing_expiration"]
             },
             "source_reports" => %{
               "contact_allocation_report" => %{
                 "reservation_conflict_contact_count" => 1,
                 "reservation_conflict_contact_ids" => ["reservation_conflict_contact"],
                 "reservation_conflict_match_status_counts" => %{"overlap" => 1},
                 "reservation_conflict_contact_ids_by_match_status" => %{
                   "overlap" => ["reservation_conflict_contact"]
                 },
                 "reservation_conflict_reservation_ids_by_match_status" => %{
                   "overlap" => ["reservation_polar_prime"]
                 },
                 "reservation_conflict_direction_counts" => %{"downlink" => 1},
                 "reservation_conflict_contact_ids_by_direction" => %{
                   "downlink" => ["reservation_conflict_contact"]
                 },
                 "station_reservation_match_status_counts" => %{
                   "matched" => 2,
                   "overlap" => 1
                 },
                 "station_reservation_contact_ids_by_match_status" => %{
                   "matched" => [
                     "reservation_expired_contact",
                     "reservation_missing_expiration_contact"
                   ],
                   "overlap" => ["reservation_conflict_contact"]
                 },
                 "station_reservation_ids_by_match_status" => %{
                   "matched" => ["reservation_expired", "reservation_missing_expiration"],
                   "overlap" => ["reservation_polar_prime"]
                 },
                 "station_reservation_status_counts" => %{"reserved" => 3},
                 "station_reserved_by_counts" => %{"ops_team" => 3},
                 "station_reservation_ids" => [
                   "reservation_expired",
                   "reservation_missing_expiration",
                   "reservation_polar_prime"
                 ],
                 "station_reservation_contact_ids_by_status" => %{
                   "reserved" => [
                     "reservation_conflict_contact",
                     "reservation_expired_contact",
                     "reservation_missing_expiration_contact"
                   ]
                 },
                 "station_reservation_contact_ids_by_reserved_by" => %{
                   "ops_team" => [
                     "reservation_conflict_contact",
                     "reservation_expired_contact",
                     "reservation_missing_expiration_contact"
                   ]
                 },
                 "station_reservation_ids_by_status" => %{
                   "reserved" => [
                     "reservation_expired",
                     "reservation_missing_expiration",
                     "reservation_polar_prime"
                   ]
                 },
                 "station_reservation_ids_by_reserved_by" => %{
                   "ops_team" => [
                     "reservation_expired",
                     "reservation_missing_expiration",
                     "reservation_polar_prime"
                   ]
                 },
                 "station_reservation_expires_at_s" => [360.0, 420.0],
                 "station_reservation_expiration_now_s" => 400.0,
                 "station_reservation_expiration_status_counts" => %{
                   "active" => 1,
                   "expired" => 1,
                   "missing" => 1
                 },
                 "station_reservation_active_contact_count" => 1,
                 "station_reservation_expired_contact_count" => 1,
                 "station_reservation_declared_expiration_contact_count" => 0,
                 "station_reservation_missing_expiration_contact_count" => 1,
                 "earliest_station_reservation_expires_at_s" => 360.0,
                 "station_reservation_contact_ids_by_expiration_status" => %{
                   "active" => ["reservation_conflict_contact"],
                   "expired" => ["reservation_expired_contact"],
                   "missing" => ["reservation_missing_expiration_contact"]
                 },
                 "station_reservation_ids_by_expiration_status" => %{
                   "active" => ["reservation_polar_prime"],
                   "expired" => ["reservation_expired"],
                   "missing" => ["reservation_missing_expiration"]
                 }
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "reservation_conflict_contact_count" => 1,
             "reservation_conflict_contact_ids" => ["reservation_conflict_contact"],
             "reservation_conflict_match_status_counts" => %{"overlap" => 1},
             "reservation_conflict_contact_ids_by_match_status" => %{
               "overlap" => ["reservation_conflict_contact"]
             },
             "reservation_conflict_reservation_ids_by_match_status" => %{
               "overlap" => ["reservation_polar_prime"]
             },
             "station_reservation_match_status_counts" => %{"matched" => 2, "overlap" => 1},
             "station_reservation_contact_ids_by_match_status" => %{
               "matched" => [
                 "reservation_expired_contact",
                 "reservation_missing_expiration_contact"
               ],
               "overlap" => ["reservation_conflict_contact"]
             },
             "station_reservation_ids_by_match_status" => %{
               "matched" => ["reservation_expired", "reservation_missing_expiration"],
               "overlap" => ["reservation_polar_prime"]
             },
             "station_reservation_status_counts" => %{"reserved" => 3},
             "station_reserved_by_counts" => %{"ops_team" => 3},
             "station_reservation_ids" => [
               "reservation_expired",
               "reservation_missing_expiration",
               "reservation_polar_prime"
             ],
             "station_reservation_contact_ids_by_status" => %{
               "reserved" => [
                 "reservation_conflict_contact",
                 "reservation_expired_contact",
                 "reservation_missing_expiration_contact"
               ]
             },
             "station_reservation_contact_ids_by_reserved_by" => %{
               "ops_team" => [
                 "reservation_conflict_contact",
                 "reservation_expired_contact",
                 "reservation_missing_expiration_contact"
               ]
             },
             "station_reservation_ids_by_status" => %{
               "reserved" => [
                 "reservation_expired",
                 "reservation_missing_expiration",
                 "reservation_polar_prime"
               ]
             },
             "station_reservation_ids_by_reserved_by" => %{
               "ops_team" => [
                 "reservation_expired",
                 "reservation_missing_expiration",
                 "reservation_polar_prime"
               ]
             },
             "station_reservation_expires_at_s" => [360.0, 420.0],
             "station_reservation_expiration_now_s" => 400.0,
             "station_reservation_expiration_status_counts" => %{
               "active" => 1,
               "expired" => 1,
               "missing" => 1
             },
             "station_reservation_active_contact_count" => 1,
             "station_reservation_expired_contact_count" => 1,
             "station_reservation_missing_expiration_contact_count" => 1,
             "earliest_station_reservation_expires_at_s" => 360.0,
             "station_reservation_contact_ids_by_expiration_status" => %{
               "active" => ["reservation_conflict_contact"],
               "expired" => ["reservation_expired_contact"],
               "missing" => ["reservation_missing_expiration_contact"]
             },
             "station_reservation_ids_by_expiration_status" => %{
               "active" => ["reservation_polar_prime"],
               "expired" => ["reservation_expired"],
               "missing" => ["reservation_missing_expiration"]
             },
             "branch_local_reservation_conflict_pressure" => true
           } = replay_summary = CandidateRefresh.contact_allocation_replay_summary(refresh)

    assert replay_summary["branch_local_station_reservation_pressure"]

    assert OrbitalDynamics.candidate_refresh_contact_allocation_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => summary["source_reports"]}
    }

    assert %{
             "source_report_contact_allocation_reservation_conflict_contact_count" => 1,
             "source_report_contact_allocation_reservation_conflict_contact_ids" => [
               "reservation_conflict_contact"
             ],
             "source_report_contact_allocation_reservation_conflict_contact_ids_by_match_status" =>
               %{
                 "overlap" => ["reservation_conflict_contact"]
               },
             "source_report_contact_allocation_reservation_conflict_contact_ids_by_direction" =>
               %{
                 "downlink" => ["reservation_conflict_contact"]
               },
             "source_report_contact_allocation_station_reservation_match_status_counts" => %{
               "matched" => 2,
               "overlap" => 1
             },
             "source_report_contact_allocation_station_reservation_contact_ids_by_match_status" =>
               %{
                 "matched" => [
                   "reservation_expired_contact",
                   "reservation_missing_expiration_contact"
                 ],
                 "overlap" => ["reservation_conflict_contact"]
               },
             "source_report_contact_allocation_station_reservation_ids_by_match_status" => %{
               "matched" => ["reservation_expired", "reservation_missing_expiration"],
               "overlap" => ["reservation_polar_prime"]
             },
             "source_report_contact_allocation_station_reservation_ids_by_reserved_by" => %{
               "ops_team" => [
                 "reservation_expired",
                 "reservation_missing_expiration",
                 "reservation_polar_prime"
               ]
             },
             "source_report_contact_allocation_station_reservation_ids_by_expiration_status" => %{
               "active" => ["reservation_polar_prime"],
               "expired" => ["reservation_expired"],
               "missing" => ["reservation_missing_expiration"]
             }
           } = CandidateRefresh.source_report_summary(artifact)

    assert %{
             "reservation_conflict_contact_count" => 1,
             "reservation_conflict_reservation_ids_by_match_status" => %{
               "overlap" => ["reservation_polar_prime"]
             },
             "reservation_conflict_direction_counts" => %{"downlink" => 1},
             "reservation_conflict_contact_ids_by_direction" => %{
               "downlink" => ["reservation_conflict_contact"]
             },
             "station_reservation_match_status_counts" => %{"matched" => 2, "overlap" => 1},
             "station_reservation_ids_by_match_status" => %{
               "matched" => ["reservation_expired", "reservation_missing_expiration"],
               "overlap" => ["reservation_polar_prime"]
             },
             "station_reservation_ids_by_status" => %{
               "reserved" => [
                 "reservation_expired",
                 "reservation_missing_expiration",
                 "reservation_polar_prime"
               ]
             },
             "station_reservation_ids_by_expiration_status" => %{
               "active" => ["reservation_polar_prime"],
               "expired" => ["reservation_expired"],
               "missing" => ["reservation_missing_expiration"]
             }
           } = CandidateRefresh.contact_allocation_replay_summary(artifact)
  end
end
