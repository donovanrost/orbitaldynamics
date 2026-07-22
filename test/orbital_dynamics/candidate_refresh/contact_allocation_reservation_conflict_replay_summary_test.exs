defmodule OrbitalDynamics.CandidateRefresh.ContactAllocationReservationConflictReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary replays contact allocation reservation-conflict summaries" do
    refresh = %{
      "source_contact_allocation_reservation_conflict_summary" =>
        contact_allocation_reservation_conflict_summary_fixture()
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_count" => 1,
             "source_report_row_count" => 2,
             "source_report_counts_by_family" => %{"contact_allocation_report" => 1},
             "source_report_contact_allocation_reservation_conflict_contact_count" => 1,
             "source_report_contact_allocation_reservation_conflict_contact_ids" => [
               "dl_reserved_intruder"
             ],
             "source_report_contact_allocation_reservation_conflict_contact_ids_by_direction_and_ground_station" =>
               %{
                 "downlink" => %{"equator_prime" => ["dl_reserved_intruder"]}
               },
             "source_report_contact_allocation_reservation_conflict_match_status_counts" => %{
               "overlap" => 1
             },
             "source_report_contact_allocation_station_reservation_match_status_counts" => %{
               "matched" => 1,
               "overlap" => 1
             },
             "source_report_contact_allocation_branch_local_reservation_conflict_pressure" =>
               true,
             "source_report_contact_allocation_branch_local_station_reservation_pressure" => true,
             "source_reports" => %{
               "contact_allocation_report" => %{
                 "paths" => ["source_contact_allocation_reservation_conflict_summary"],
                 "reservation_conflict_summary_schema_contract" =>
                   "contact_allocation_reservation_conflict_summary.v1"
               }
             }
           } = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "source_report_count" => 1,
             "source_report_row_count" => 2,
             "reservation_conflict_contact_count" => 1,
             "reservation_conflict_contact_ids" => ["dl_reserved_intruder"],
             "reservation_conflict_match_status_counts" => %{"overlap" => 1},
             "reservation_conflict_contact_ids_by_match_status" => %{
               "overlap" => ["dl_reserved_intruder"]
             },
             "reservation_conflict_contact_ids_by_direction_and_ground_station" => %{
               "downlink" => %{"equator_prime" => ["dl_reserved_intruder"]}
             },
             "reservation_conflict_reservation_ids_by_match_status" => %{
               "overlap" => ["reservation_1"]
             },
             "station_reservation_match_status_counts" => %{"matched" => 1, "overlap" => 1},
             "station_reservation_expiration_status_counts" => %{"expired" => 2},
             "reservation_conflict_summary_schema_contract" =>
               "contact_allocation_reservation_conflict_summary.v1",
             "branch_local_contact_allocation_pressure" => true,
             "branch_local_reservation_conflict_pressure" => true,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
               "contact_allocation" => "not_performed_by_summary",
               "candidate_selection" => "not_performed_by_summary"
             }
           } = CandidateRefresh.contact_allocation_replay_summary(refresh)
  end

  test "source report summary preserves reservation-conflict direction maps without rows" do
    summary =
      contact_allocation_reservation_conflict_summary_fixture()
      |> Map.put("rows", [])
      |> Map.put("reservation_conflict_rows", [])
      |> Map.put("reservation_review_rows", [])
      |> Map.put("reservation_conflict_contact_count", 99)

    refresh = %{"source_contact_allocation_reservation_conflict_summary" => summary}

    assert %{
             "source_report_contact_allocation_reservation_conflict_contact_count" => 1,
             "source_report_contact_allocation_reservation_conflict_direction_counts" => %{
               "downlink" => 1
             },
             "source_report_contact_allocation_reservation_conflict_contact_ids_by_direction" =>
               %{
                 "downlink" => ["dl_reserved_intruder"]
               },
             "source_report_contact_allocation_reservation_conflict_contact_ids_by_direction_and_ground_station" =>
               %{
                 "downlink" => %{"equator_prime" => ["dl_reserved_intruder"]}
               },
             "source_reports" => %{
               "contact_allocation_report" => %{
                 "reservation_conflict_contact_ids_by_direction" => %{
                   "downlink" => ["dl_reserved_intruder"]
                 },
                 "reservation_conflict_contact_ids_by_direction_and_ground_station" => %{
                   "downlink" => %{"equator_prime" => ["dl_reserved_intruder"]}
                 }
               }
             }
           } = source_summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "reservation_conflict_contact_count" => 1,
             "reservation_conflict_direction_counts" => %{"downlink" => 1},
             "reservation_conflict_contact_ids_by_direction" => %{
               "downlink" => ["dl_reserved_intruder"]
             },
             "reservation_conflict_contact_ids_by_direction_and_ground_station" => %{
               "downlink" => %{"equator_prime" => ["dl_reserved_intruder"]}
             },
             "branch_local_reservation_conflict_pressure" => true
           } = CandidateRefresh.contact_allocation_replay_summary(refresh)

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_summary["source_reports"]}
    }

    assert CandidateRefresh.contact_allocation_replay_summary(artifact) ==
             CandidateRefresh.contact_allocation_replay_summary(refresh)
  end

  test "source report summary zeros empty reservation-conflict maps before stale scalar counts" do
    summary =
      contact_allocation_reservation_conflict_summary_fixture()
      |> Map.put("rows", [])
      |> Map.put("reservation_conflict_rows", [])
      |> Map.put("reservation_review_rows", [])
      |> Map.put("reservation_conflict_contact_count", 99)
      |> Map.put("reservation_conflict_contact_ids", [])
      |> Map.put("reservation_conflict_match_status_counts", %{})
      |> Map.put("reservation_conflict_contact_ids_by_match_status", %{})
      |> Map.put("reservation_conflict_reservation_ids_by_match_status", %{})
      |> Map.put("reservation_conflict_direction_counts", %{})
      |> Map.put("reservation_conflict_contact_ids_by_direction", %{})
      |> Map.put("reservation_conflict_contact_ids_by_direction_and_ground_station", %{})
      |> Map.delete("reservation_conflict_contact_ids_by_direction_and_ground_station_id")

    refresh = %{"source_contact_allocation_reservation_conflict_summary" => summary}
    source_summary = CandidateRefresh.source_report_summary(refresh)
    replay_summary = CandidateRefresh.contact_allocation_replay_summary(refresh)

    assert source_summary[
             "source_report_contact_allocation_reservation_conflict_contact_count"
           ] == 0

    assert source_summary[
             "source_report_contact_allocation_reservation_conflict_contact_ids"
           ] == nil

    assert source_summary[
             "source_report_contact_allocation_reservation_conflict_contact_ids_by_match_status"
           ] == nil

    assert source_summary[
             "source_report_contact_allocation_reservation_conflict_contact_ids_by_direction"
           ] == nil

    assert source_summary[
             "source_report_contact_allocation_reservation_conflict_contact_ids_by_direction_and_ground_station"
           ] == nil

    assert replay_summary["reservation_conflict_contact_count"] == nil
    assert replay_summary["reservation_conflict_contact_ids"] == nil
    assert replay_summary["reservation_conflict_contact_ids_by_match_status"] == nil
    assert replay_summary["reservation_conflict_contact_ids_by_direction"] == nil

    assert replay_summary[
             "reservation_conflict_contact_ids_by_direction_and_ground_station"
           ] == nil

    refute replay_summary["branch_local_reservation_conflict_pressure"]
  end

  test "source report summary rederives direct no-row reservation-conflict counts from maps" do
    refresh = %{
      "source_contact_allocation_report" => %{
        "schema_contract" => "contact_allocation_report.v1",
        "rows" => [],
        "reservation_conflict_contact_count" => 99,
        "reservation_conflict_contact_ids" => [],
        "reservation_conflict_contact_ids_by_match_status" => %{
          "overlap" => ["match_status_conflict"]
        },
        "reservation_conflict_contact_ids_by_direction" => %{
          "downlink" => ["direction_conflict"]
        },
        "reservation_conflict_contact_ids_by_direction_and_ground_station" => %{
          "downlink" => %{"equator_prime" => ["nested_conflict"]}
        },
        "reservation_conflict_contact_ids_by_direction_and_ground_station_id" => %{
          "downlink" => %{"polar_prime" => ["nested_id_conflict"]}
        },
        "provenance" => %{"trust_boundary" => "ops_contact_allocation"}
      }
    }

    assert %{
             "source_report_contact_allocation_reservation_conflict_contact_count" => 4,
             "source_report_contact_allocation_reservation_conflict_contact_ids_by_match_status" =>
               %{"overlap" => ["match_status_conflict"]},
             "source_report_contact_allocation_reservation_conflict_contact_ids_by_direction" =>
               %{"downlink" => ["direction_conflict"]},
             "source_report_contact_allocation_reservation_conflict_contact_ids_by_direction_and_ground_station" =>
               %{
                 "downlink" => %{
                   "equator_prime" => ["nested_conflict"],
                   "polar_prime" => ["nested_id_conflict"]
                 }
               },
             "source_reports" => %{
               "contact_allocation_report" => %{
                 "reservation_conflict_contact_count" => 4,
                 "reservation_conflict_contact_ids_by_direction_and_ground_station" => %{
                   "downlink" => %{
                     "equator_prime" => ["nested_conflict"],
                     "polar_prime" => ["nested_id_conflict"]
                   }
                 }
               }
             }
           } = source_summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "reservation_conflict_contact_count" => 4,
             "reservation_conflict_contact_ids_by_match_status" => %{
               "overlap" => ["match_status_conflict"]
             },
             "reservation_conflict_contact_ids_by_direction" => %{
               "downlink" => ["direction_conflict"]
             },
             "reservation_conflict_contact_ids_by_direction_and_ground_station" => %{
               "downlink" => %{
                 "equator_prime" => ["nested_conflict"],
                 "polar_prime" => ["nested_id_conflict"]
               }
             },
             "branch_local_reservation_conflict_pressure" => true
           } = CandidateRefresh.contact_allocation_replay_summary(refresh)

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_summary["source_reports"]}
    }

    assert CandidateRefresh.contact_allocation_replay_summary(artifact) ==
             CandidateRefresh.contact_allocation_replay_summary(refresh)
  end

  test "contact allocation replay preserves raw provenance reservation-conflict station-id aliases" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 1,
            "row_count" => 0,
            "reservation_conflict_contact_count" => 0,
            "reservation_conflict_contact_ids_by_direction_and_ground_station_id" => %{
              "downlink" => %{"polar_prime" => ["raw_alias_conflict"]}
            }
          }
        }
      }
    }

    assert %{
             "source_report_contact_allocation_reservation_conflict_contact_count" => 1,
             "source_report_contact_allocation_reservation_conflict_contact_ids_by_direction_and_ground_station" =>
               %{
                 "downlink" => %{"polar_prime" => ["raw_alias_conflict"]}
               }
           } = CandidateRefresh.source_report_summary(artifact)

    assert %{
             "reservation_conflict_contact_count" => 1,
             "reservation_conflict_contact_ids_by_direction_and_ground_station" => %{
               "downlink" => %{"polar_prime" => ["raw_alias_conflict"]}
             },
             "branch_local_reservation_conflict_pressure" => true
           } = CandidateRefresh.contact_allocation_replay_summary(artifact)
  end

  test "reservation-conflict local counts cannot suppress stronger routed identity" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 1,
            "row_count" => 0,
            "reservation_conflict_contact_count" => 99,
            "reservation_conflict_match_status_counts" => %{
              "overlap" => 1,
              "count_only" => 2
            },
            "reservation_conflict_contact_ids_by_match_status" => %{
              "overlap" => ["match_a", "match_b"],
              "route_only" => ["match_route_only"]
            },
            "reservation_conflict_reservation_ids_by_match_status" => %{
              "overlap" => ["reservation_a", "reservation_b", "reservation_c"]
            },
            "reservation_conflict_direction_counts" => %{
              "command" => 1,
              "tracking" => 2
            },
            "reservation_conflict_contact_ids_by_direction" => %{
              "command" => ["command_a"],
              "uplink" => ["direction_route_only"]
            },
            "reservation_conflict_contact_ids_by_direction_and_ground_station" => %{
              "command" => %{"equator_prime" => ["command_b"]}
            }
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.contact_allocation_replay_summary(artifact)

    assert source_summary[
             "source_report_contact_allocation_reservation_conflict_match_status_counts"
           ] == %{"count_only" => 2}

    assert source_summary[
             "source_report_contact_allocation_reservation_conflict_contact_ids_by_match_status"
           ] == %{
             "overlap" => ["match_a", "match_b"],
             "route_only" => ["match_route_only"]
           }

    assert source_summary[
             "source_report_contact_allocation_reservation_conflict_direction_counts"
           ] == %{"tracking" => 2}

    assert source_summary[
             "source_report_contact_allocation_reservation_conflict_contact_ids_by_direction"
           ] == %{
             "command" => ["command_a"],
             "uplink" => ["direction_route_only"]
           }

    assert source_summary[
             "source_report_contact_allocation_reservation_conflict_contact_ids_by_direction_and_ground_station"
           ] == %{"command" => %{"equator_prime" => ["command_b"]}}

    assert replay_summary["reservation_conflict_match_status_counts"] == %{"count_only" => 2}
    assert replay_summary["reservation_conflict_direction_counts"] == %{"tracking" => 2}

    assert replay_summary["reservation_conflict_contact_ids"] == [
             "command_a",
             "command_b",
             "direction_route_only",
             "match_a",
             "match_b",
             "match_route_only"
           ]

    assert replay_summary["reservation_conflict_contact_count"] == 6
    assert replay_summary["branch_local_reservation_conflict_pressure"]
  end

  test "source report summary replays contact allocation reservation-conflict summaries from result artifact wrappers" do
    refresh = %{
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "source_contact_allocation_reservation_conflict_summary" =>
          contact_allocation_reservation_conflict_summary_fixture()
          |> Map.delete("provenance"),
        "provenance" => %{"trust_boundary" => "ground_partner_api"}
      }
    }

    assert %{
             "source_report_count" => 1,
             "source_report_row_count" => 2,
             "source_reports" => %{
               "contact_allocation_report" => %{
                 "paths" => [
                   "source_result_artifact.source_contact_allocation_reservation_conflict_summary"
                 ],
                 "reservation_conflict_summary_schema_contract" =>
                   "contact_allocation_reservation_conflict_summary.v1",
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => ["ground_partner_api"]
               }
             }
           } = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "source_report_paths" => [
               "source_result_artifact.source_contact_allocation_reservation_conflict_summary"
             ],
             "reservation_conflict_summary_schema_contract" =>
               "contact_allocation_reservation_conflict_summary.v1",
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["ground_partner_api"],
             "branch_local_reservation_conflict_pressure" => true,
             "assumptions" => %{
               "contact_allocation" => "not_performed_by_summary",
               "candidate_selection" => "not_performed_by_summary"
             }
           } = CandidateRefresh.contact_allocation_replay_summary(refresh)
  end

  defp contact_allocation_reservation_conflict_summary_fixture do
    owner_row = %{
      "contact_id" => "dl_reserved_owner",
      "allocation_status" => "allocated",
      "effective_allocation_status" => "allocated",
      "allocation_reason" => "selected_by_contention_resolution",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "station_reservation_id" => "reservation_1",
      "station_reservation_match_status" => "matched",
      "station_reservation_status" => "confirmed",
      "station_reserved_by" => "ops_team_b",
      "station_reservation_expires_at_s" => 360.0
    }

    conflict_row = %{
      "contact_id" => "dl_reserved_intruder",
      "allocation_status" => "deferred",
      "effective_allocation_status" => "deferred",
      "allocation_reason" => "same_station_contention",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "station_reservation_id" => "reservation_1",
      "station_reservation_match_status" => "overlap",
      "station_reservation_status" => "confirmed",
      "station_reserved_by" => "ops_team_b",
      "station_reservation_expires_at_s" => 360.0
    }

    %{
      "schema_contract" => "contact_allocation_reservation_conflict_summary.v1",
      "model" => "artifact_only_contact_allocation_reservation_conflict_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source" => "unit_test.contact_allocation_reservation_conflict_summary",
      "input_contact_count" => 2,
      "station_reservation_contact_count" => 2,
      "reservation_conflict_contact_count" => 1,
      "reservation_review_contact_count" => 1,
      "station_reservation_match_status_counts" => %{"matched" => 1, "overlap" => 1},
      "reservation_conflict_match_status_counts" => %{"overlap" => 1},
      "station_reservation_status_counts" => %{"confirmed" => 2},
      "station_reserved_by_counts" => %{"ops_team_b" => 2},
      "station_reservation_ids" => ["reservation_1"],
      "station_reservation_expires_at_s" => [360.0],
      "station_reservation_expiration_now_s" => 400.0,
      "station_reservation_expiration_status_counts" => %{"expired" => 2},
      "earliest_station_reservation_expires_at_s" => 360.0,
      "reservation_conflict_contact_ids" => ["dl_reserved_intruder"],
      "reservation_review_contact_ids" => ["dl_reserved_intruder"],
      "station_reservation_contact_ids_by_match_status" => %{
        "matched" => ["dl_reserved_owner"],
        "overlap" => ["dl_reserved_intruder"]
      },
      "reservation_conflict_contact_ids_by_match_status" => %{
        "overlap" => ["dl_reserved_intruder"]
      },
      "reservation_conflict_contact_ids_by_direction" => %{
        "downlink" => ["dl_reserved_intruder"]
      },
      "reservation_conflict_contact_ids_by_direction_and_ground_station_id" => %{
        "downlink" => %{"equator_prime" => ["dl_reserved_intruder"]}
      },
      "station_reservation_contact_ids_by_status" => %{
        "confirmed" => ["dl_reserved_intruder", "dl_reserved_owner"]
      },
      "station_reservation_contact_ids_by_reserved_by" => %{
        "ops_team_b" => ["dl_reserved_intruder", "dl_reserved_owner"]
      },
      "station_reservation_contact_ids_by_expiration_status" => %{
        "expired" => ["dl_reserved_intruder", "dl_reserved_owner"]
      },
      "station_reservation_ids_by_match_status" => %{
        "matched" => ["reservation_1"],
        "overlap" => ["reservation_1"]
      },
      "reservation_conflict_reservation_ids_by_match_status" => %{
        "overlap" => ["reservation_1"]
      },
      "station_reservation_ids_by_status" => %{"confirmed" => ["reservation_1"]},
      "station_reservation_ids_by_reserved_by" => %{"ops_team_b" => ["reservation_1"]},
      "station_reservation_ids_by_expiration_status" => %{"expired" => ["reservation_1"]},
      "rows" => [owner_row, conflict_row],
      "reservation_conflict_rows" => [conflict_row],
      "reservation_review_rows" => [conflict_row],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "source" => "contact_allocation_report.v1",
        "operator_authority" => "not_granted_by_reservation_conflict_summary"
      },
      "provenance" => %{"trust_boundary" => "reservation_conflict_fixture"}
    }
  end
end
