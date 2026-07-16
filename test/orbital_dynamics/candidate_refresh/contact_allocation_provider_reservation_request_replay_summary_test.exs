defmodule OrbitalDynamics.CandidateRefresh.ContactAllocationProviderReservationRequestReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary replays contact allocation provider reservation request summaries" do
    refresh = %{
      "source_contact_allocation_provider_reservation_request_summary" => %{
        "schema_contract" => "contact_allocation_provider_reservation_request_summary.v1",
        "model" => "artifact_only_contact_allocation_provider_reservation_request_summary",
        "source_artifact_type" => "contact_allocation_report.v1",
        "source" => "unit_test.provider_reservation_request_summary",
        "provider_reservation_candidate_contact_count" => 2,
        "provider_reservation_request_contact_count" => 1,
        "provider_reservation_review_contact_count" => 1,
        "provider_reservation_no_request_contact_count" => 99,
        "provider_reservation_request_status" => "review_required",
        "provider_reservation_request_contact_ids" => ["dl_reserved_owner"],
        "provider_reservation_review_contact_ids" => ["dl_review_overlap"],
        "provider_reservation_no_request_contact_ids" => ["stale_no_request_contact"],
        "provider_reservation_request_contact_ids_by_ground_station_id" => %{
          "equator_prime" => ["dl_reserved_owner"]
        },
        "provider_reservation_review_contact_ids_by_ground_station_id" => %{
          "equator_prime" => ["dl_review_overlap"]
        },
        "provider_reservation_no_request_contact_ids_by_direction" => %{
          "stale_direction" => ["stale_no_request_contact"]
        },
        "provider_reservation_request_contact_ids_by_direction" => %{
          "downlink" => ["dl_reserved_owner"]
        },
        "provider_reservation_review_contact_ids_by_direction" => %{
          "uplink" => ["dl_review_overlap"]
        },
        "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id" => %{
          "stale_direction" => %{"stale_station" => ["stale_no_request_contact"]}
        },
        "provider_reservation_request_contact_ids_by_direction_and_ground_station_id" => %{
          "downlink" => %{"stale_station" => ["stale_request_contact"]}
        },
        "provider_reservation_review_contact_ids_by_direction_and_ground_station_id" => %{
          "uplink" => %{"stale_station" => ["stale_review_contact"]}
        },
        "provider_reservation_request_contact_ids_by_match_status" => %{
          "matched" => ["dl_reserved_owner"]
        },
        "provider_reservation_review_contact_ids_by_match_status" => %{
          "overlap" => ["dl_review_overlap"]
        },
        "provider_reservation_request_ids_by_match_status" => %{
          "matched" => ["reservation_1"]
        },
        "provider_reservation_review_ids_by_match_status" => %{
          "overlap" => ["reservation_review"]
        },
        "rows" => [
          %{
            "contact_id" => "dl_reserved_owner",
            "allocation_status" => "allocated",
            "ground_station_id" => "equator_prime",
            "direction" => "Down Link",
            "station_reservation_id" => "reservation_1",
            "station_reservation_match_status" => "matched",
            "station_reservation_status" => "confirmed"
          },
          %{
            "contact_id" => "dl_review_overlap",
            "allocation_status" => "allocated",
            "ground_station_id" => "equator_prime",
            "direction" => "uplink",
            "station_reservation_id" => "reservation_review",
            "station_reservation_match_status" => "overlap",
            "station_reservation_status" => "confirmed"
          },
          %{
            "contact_id" => "dl_unreserved",
            "allocation_status" => "blocked",
            "ground_station_id" => "equator_prime",
            "direction" => "Tracking"
          }
        ],
        "provider_reservation_request_rows" => [
          %{
            "contact_id" => "dl_reserved_owner",
            "allocation_status" => "allocated",
            "ground_station_id" => "equator_prime",
            "direction" => "Down Link",
            "station_reservation_id" => "reservation_1",
            "station_reservation_match_status" => "matched",
            "station_reservation_status" => "confirmed"
          }
        ],
        "provider_reservation_review_rows" => [
          %{
            "contact_id" => "dl_review_overlap",
            "allocation_status" => "allocated",
            "ground_station_id" => "equator_prime",
            "direction" => "uplink",
            "station_reservation_id" => "reservation_review",
            "station_reservation_match_status" => "overlap",
            "station_reservation_status" => "confirmed"
          }
        ],
        "assumptions" => %{
          "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
          "provider_reservation_execution" => "not_performed_by_summary"
        }
      }
    }

    expected_provider_direction_routing = %{
      "downlink" => %{
        "contact_count" => 1,
        "contact_ids" => ["dl_reserved_owner"],
        "station_pressure_contact_count" => 1,
        "station_pressure_contact_ids" => ["dl_reserved_owner"],
        "reservation_conflict_contact_ids" => [],
        "provider_reservation_no_request_contact_ids" => [],
        "provider_reservation_request_contact_ids" => ["dl_reserved_owner"],
        "provider_reservation_review_contact_ids" => []
      },
      "tracking" => %{
        "contact_count" => 1,
        "contact_ids" => ["dl_unreserved"],
        "station_pressure_contact_ids" => [],
        "reservation_conflict_contact_ids" => [],
        "provider_reservation_no_request_contact_ids" => ["dl_unreserved"],
        "provider_reservation_request_contact_ids" => [],
        "provider_reservation_review_contact_ids" => []
      },
      "uplink" => %{
        "contact_count" => 1,
        "contact_ids" => ["dl_review_overlap"],
        "station_pressure_contact_count" => 1,
        "station_pressure_contact_ids" => ["dl_review_overlap"],
        "reservation_conflict_contact_count" => 1,
        "reservation_conflict_contact_ids" => ["dl_review_overlap"],
        "provider_reservation_no_request_contact_ids" => [],
        "provider_reservation_request_contact_ids" => [],
        "provider_reservation_review_contact_ids" => ["dl_review_overlap"]
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_count" => 1,
             "source_report_row_count" => 3,
             "source_report_counts_by_family" => %{"contact_allocation_report" => 1},
             "source_report_contact_allocation_provider_reservation_candidate_contact_count" => 2,
             "source_report_contact_allocation_provider_reservation_request_contact_count" => 1,
             "source_report_contact_allocation_provider_reservation_review_contact_count" => 1,
             "source_report_contact_allocation_provider_reservation_no_request_contact_count" =>
               1,
             "source_report_contact_allocation_provider_reservation_request_status_counts" => %{
               "review_required" => 1
             },
             "source_report_contact_allocation_provider_reservation_request_contact_ids" => [
               "dl_reserved_owner"
             ],
             "source_report_contact_allocation_provider_reservation_review_contact_ids" => [
               "dl_review_overlap"
             ],
             "source_report_contact_allocation_provider_reservation_no_request_contact_ids" => [
               "dl_unreserved"
             ],
             "source_report_contact_allocation_provider_reservation_request_contact_ids_by_ground_station" =>
               %{"equator_prime" => ["dl_reserved_owner"]},
             "source_report_contact_allocation_provider_reservation_review_contact_ids_by_ground_station" =>
               %{"equator_prime" => ["dl_review_overlap"]},
             "source_report_contact_allocation_provider_reservation_no_request_contact_ids_by_direction" =>
               %{"tracking" => ["dl_unreserved"]},
             "source_report_contact_allocation_provider_reservation_request_contact_ids_by_direction" =>
               %{"downlink" => ["dl_reserved_owner"]},
             "source_report_contact_allocation_provider_reservation_review_contact_ids_by_direction" =>
               %{"uplink" => ["dl_review_overlap"]},
             "source_report_contact_allocation_provider_reservation_no_request_contact_ids_by_direction_and_ground_station" =>
               %{"tracking" => %{"equator_prime" => ["dl_unreserved"]}},
             "source_report_contact_allocation_provider_reservation_request_contact_ids_by_direction_and_ground_station" =>
               %{"downlink" => %{"equator_prime" => ["dl_reserved_owner"]}},
             "source_report_contact_allocation_provider_reservation_review_contact_ids_by_direction_and_ground_station" =>
               %{"uplink" => %{"equator_prime" => ["dl_review_overlap"]}},
             "source_report_contact_allocation_direction_routing" =>
               ^expected_provider_direction_routing,
             "source_report_contact_allocation_provider_reservation_request_contact_ids_by_match_status" =>
               %{"matched" => ["dl_reserved_owner"]},
             "source_report_contact_allocation_provider_reservation_review_contact_ids_by_match_status" =>
               %{"overlap" => ["dl_review_overlap"]},
             "source_report_contact_allocation_provider_reservation_request_ids_by_match_status" =>
               %{"matched" => ["reservation_1"]},
             "source_report_contact_allocation_provider_reservation_review_ids_by_match_status" =>
               %{"overlap" => ["reservation_review"]},
             "source_report_contact_allocation_branch_local_contact_allocation_pressure" => true,
             "source_report_contact_allocation_branch_local_station_pressure" => true,
             "source_report_contact_allocation_branch_local_reservation_conflict_pressure" =>
               true,
             "source_report_contact_allocation_branch_local_provider_reservation_request_pressure" =>
               true,
             "source_reports" => %{
               "contact_allocation_report" => %{
                 "paths" => [
                   "source_contact_allocation_provider_reservation_request_summary"
                 ],
                 "provider_reservation_request_status_counts" => %{
                   "review_required" => 1
                 },
                 "provider_reservation_no_request_contact_ids_by_direction_and_ground_station" =>
                   %{"tracking" => %{"equator_prime" => ["dl_unreserved"]}},
                 "provider_reservation_request_contact_ids_by_direction_and_ground_station" => %{
                   "downlink" => %{"equator_prime" => ["dl_reserved_owner"]}
                 },
                 "provider_reservation_review_contact_ids_by_direction_and_ground_station" => %{
                   "uplink" => %{"equator_prime" => ["dl_review_overlap"]}
                 },
                 "direction_routing" => ^expected_provider_direction_routing,
                 "provider_reservation_request_summary_schema_contract" =>
                   "contact_allocation_provider_reservation_request_summary.v1"
               }
             }
           } = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "source_report_count" => 1,
             "source_report_row_count" => 3,
             "provider_reservation_candidate_contact_count" => 2,
             "provider_reservation_request_contact_count" => 1,
             "provider_reservation_review_contact_count" => 1,
             "provider_reservation_no_request_contact_count" => 1,
             "provider_reservation_request_status_counts" => %{"review_required" => 1},
             "provider_reservation_request_summary_schema_contract" =>
               "contact_allocation_provider_reservation_request_summary.v1",
             "provider_reservation_request_contact_ids" => ["dl_reserved_owner"],
             "provider_reservation_review_contact_ids" => ["dl_review_overlap"],
             "provider_reservation_no_request_contact_ids" => ["dl_unreserved"],
             "provider_reservation_request_contact_ids_by_ground_station" => %{
               "equator_prime" => ["dl_reserved_owner"]
             },
             "provider_reservation_review_contact_ids_by_ground_station" => %{
               "equator_prime" => ["dl_review_overlap"]
             },
             "provider_reservation_no_request_contact_ids_by_direction" => %{
               "tracking" => ["dl_unreserved"]
             },
             "provider_reservation_request_contact_ids_by_direction" => %{
               "downlink" => ["dl_reserved_owner"]
             },
             "provider_reservation_review_contact_ids_by_direction" => %{
               "uplink" => ["dl_review_overlap"]
             },
             "provider_reservation_no_request_contact_ids_by_direction_and_ground_station" => %{
               "tracking" => %{"equator_prime" => ["dl_unreserved"]}
             },
             "provider_reservation_request_contact_ids_by_direction_and_ground_station" => %{
               "downlink" => %{"equator_prime" => ["dl_reserved_owner"]}
             },
             "provider_reservation_review_contact_ids_by_direction_and_ground_station" => %{
               "uplink" => %{"equator_prime" => ["dl_review_overlap"]}
             },
             "direction_routing" => ^expected_provider_direction_routing,
             "provider_reservation_request_contact_ids_by_match_status" => %{
               "matched" => ["dl_reserved_owner"]
             },
             "provider_reservation_review_contact_ids_by_match_status" => %{
               "overlap" => ["dl_review_overlap"]
             },
             "provider_reservation_request_ids_by_match_status" => %{
               "matched" => ["reservation_1"]
             },
             "provider_reservation_review_ids_by_match_status" => %{
               "overlap" => ["reservation_review"]
             },
             "branch_local_provider_reservation_request_pressure" => true,
             "branch_local_contact_allocation_pressure" => true,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
               "operator_authority" => "not_granted_by_contact_allocation_replay_summary",
               "contact_allocation" => "not_performed_by_summary",
               "candidate_selection" => "not_performed_by_summary"
             }
           } = CandidateRefresh.contact_allocation_replay_summary(refresh)
  end

  test "source report summary derives provider reservation request replay from effective row status" do
    refresh = %{
      "source_contact_allocation_provider_reservation_request_summary" => %{
        "schema_contract" => "contact_allocation_provider_reservation_request_summary.v1",
        "model" => "artifact_only_contact_allocation_provider_reservation_request_summary",
        "source_artifact_type" => "contact_allocation_report.v1",
        "source" => "unit_test.provider_reservation_effective_status_summary",
        "provider_reservation_candidate_contact_count" => 3,
        "provider_reservation_request_contact_count" => 3,
        "provider_reservation_review_contact_count" => 0,
        "provider_reservation_no_request_contact_count" => 0,
        "provider_reservation_request_status" => "request_ready",
        "provider_reservation_request_contact_ids" => [
          "dl_legacy_allocated",
          "dl_policy_blocked",
          "dl_ready"
        ],
        "provider_reservation_no_request_contact_ids" => [],
        "provider_reservation_request_contact_ids_by_match_status" => %{
          "matched" => ["dl_policy_blocked", "dl_ready"],
          "owner_matched" => ["dl_legacy_allocated"]
        },
        "provider_reservation_request_ids_by_match_status" => %{
          "matched" => ["reservation_policy", "reservation_ready"],
          "owner_matched" => ["reservation_legacy"]
        },
        "rows" => [
          %{
            "contact_id" => "dl_ready",
            "allocation_status" => "allocated",
            "effective_allocation_status" => "allocated",
            "ground_station_id" => "equator_prime",
            "direction" => "Down Link",
            "station_reservation_id" => "reservation_ready",
            "station_reservation_match_status" => "matched",
            "station_reservation_status" => "confirmed"
          },
          %{
            "contact_id" => "dl_policy_blocked",
            "allocation_status" => "allocated",
            "approval_status" => "blocked_by_policy",
            "ground_station_id" => "equator_prime",
            "direction" => "Down Link",
            "station_reservation_id" => "reservation_policy",
            "station_reservation_match_status" => "matched",
            "station_reservation_status" => "confirmed"
          },
          %{
            "contact_id" => "dl_legacy_allocated",
            "allocation_status" => "allocated",
            "ground_station_id" => "polar_prime",
            "direction" => "uplink",
            "station_reservation_id" => "reservation_legacy",
            "station_reservation_match_status" => "owner_matched",
            "station_reservation_status" => "confirmed"
          }
        ],
        "assumptions" => %{
          "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
          "provider_reservation_execution" => "not_performed_by_summary"
        }
      }
    }

    assert %{
             "source_report_contact_allocation_provider_reservation_candidate_contact_count" => 2,
             "source_report_contact_allocation_provider_reservation_request_contact_count" => 2,
             "source_report_contact_allocation_provider_reservation_review_contact_count" => 0,
             "source_report_contact_allocation_provider_reservation_no_request_contact_count" =>
               1,
             "source_report_contact_allocation_provider_reservation_request_status_counts" => %{
               "request_ready" => 1
             },
             "source_report_contact_allocation_provider_reservation_request_contact_ids" => [
               "dl_legacy_allocated",
               "dl_ready"
             ],
             "source_report_contact_allocation_provider_reservation_no_request_contact_ids" => [
               "dl_policy_blocked"
             ],
             "source_report_contact_allocation_provider_reservation_request_contact_ids_by_ground_station" =>
               %{
                 "equator_prime" => ["dl_ready"],
                 "polar_prime" => ["dl_legacy_allocated"]
               },
             "source_report_contact_allocation_provider_reservation_no_request_contact_ids_by_direction" =>
               %{"downlink" => ["dl_policy_blocked"]},
             "source_report_contact_allocation_provider_reservation_request_contact_ids_by_direction" =>
               %{"downlink" => ["dl_ready"], "uplink" => ["dl_legacy_allocated"]},
             "source_report_contact_allocation_provider_reservation_no_request_contact_ids_by_direction_and_ground_station" =>
               %{"downlink" => %{"equator_prime" => ["dl_policy_blocked"]}},
             "source_report_contact_allocation_provider_reservation_request_contact_ids_by_direction_and_ground_station" =>
               %{
                 "downlink" => %{"equator_prime" => ["dl_ready"]},
                 "uplink" => %{"polar_prime" => ["dl_legacy_allocated"]}
               },
             "source_report_contact_allocation_provider_reservation_request_contact_ids_by_match_status" =>
               %{"matched" => ["dl_ready"], "owner_matched" => ["dl_legacy_allocated"]},
             "source_report_contact_allocation_provider_reservation_request_ids_by_match_status" =>
               %{"matched" => ["reservation_ready"], "owner_matched" => ["reservation_legacy"]},
             "source_reports" => %{
               "contact_allocation_report" => %{
                 "paths" => ["source_contact_allocation_provider_reservation_request_summary"],
                 "row_count" => 3,
                 "provider_reservation_request_summary_schema_contract" =>
                   "contact_allocation_provider_reservation_request_summary.v1"
               }
             }
           } = CandidateRefresh.source_report_summary(refresh)

    replay_summary = CandidateRefresh.contact_allocation_replay_summary(refresh)

    assert %{
             "provider_reservation_candidate_contact_count" => 2,
             "provider_reservation_request_contact_count" => 2,
             "provider_reservation_no_request_contact_count" => 1,
             "provider_reservation_request_status_counts" => %{"request_ready" => 1},
             "provider_reservation_request_contact_ids" => [
               "dl_legacy_allocated",
               "dl_ready"
             ],
             "provider_reservation_no_request_contact_ids" => ["dl_policy_blocked"],
             "provider_reservation_request_contact_ids_by_match_status" => %{
               "matched" => ["dl_ready"],
               "owner_matched" => ["dl_legacy_allocated"]
             },
             "provider_reservation_request_ids_by_match_status" => %{
               "matched" => ["reservation_ready"],
               "owner_matched" => ["reservation_legacy"]
             },
             "branch_local_provider_reservation_request_pressure" => true,
             "branch_local_contact_allocation_pressure" => true
           } = replay_summary

    assert Map.get(replay_summary, "provider_reservation_review_contact_count", 0) == 0
  end
end
