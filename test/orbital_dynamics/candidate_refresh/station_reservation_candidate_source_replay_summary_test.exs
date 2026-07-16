defmodule OrbitalDynamics.CandidateRefresh.StationReservationCandidateSourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "station reservation replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "station_reservation_report" => %{
              "contract" => "station_reservation_report.v1",
              "count" => 1,
              "row_count" => 2,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_station_reservation_report"
              ],
              "affected_contact_count" => 1,
              "provider_calendar_contention_group_count" => 1,
              "provider_calendar_contention_group_ids" => ["branch_contention_group"],
              "provider_calendar_contention_source_entry_ids" => ["branch_source_entry"],
              "provider_calendar_contention_provider_entry_ids" => ["branch_provider_entry"],
              "provider_calendar_contention_provider_entry_ids_by_provider" => %{
                "ops_calendar" => ["branch_provider_entry"]
              },
              "provider_calendar_contention_provider_entry_ids_by_ground_station" => %{
                "equator_prime" => ["branch_provider_entry"]
              },
              "provider_calendar_contention_provider_entry_ids_by_direction" => %{
                "downlink" => ["branch_provider_entry"]
              },
              "reservation_review_count" => 1,
              "station_reservation_evidence_row_count" => 2,
              "station_reservation_expiration_evidence_row_count" => 1,
              "affected_contact_ids" => ["dl_branch_reserved"],
              "contact_ids_by_match_status" => %{"overlap" => ["dl_branch_reserved"]},
              "contact_ids_by_status" => %{"held" => ["dl_branch_reserved"]},
              "direction_counts" => %{"downlink" => 1},
              "contact_ids_by_direction" => %{"downlink" => ["dl_branch_reserved"]},
              "direction_routing" => %{
                "downlink" => %{
                  "contact_count" => 1,
                  "contact_ids" => ["dl_branch_reserved"],
                  "reservation_hold_ids" => ["hold_branch"],
                  "reservation_hold_contact_ids" => ["dl_branch_reserved"]
                }
              },
              "reservation_expires_at_s" => [600.0],
              "earliest_reservation_expires_at_s" => 600.0,
              "station_reservation_match_status_counts" => %{"overlap" => 1},
              "reservation_status_counts" => %{"held" => 1},
              "reservation_ids" => ["hold_branch"],
              "reservation_ids_by_match_status" => %{"overlap" => ["hold_branch"]},
              "reservation_ids_by_status" => %{"held" => ["hold_branch"]},
              "reserved_by_counts" => %{"ops_calendar" => 1},
              "contact_ids_by_reserved_by" => %{"ops_calendar" => ["dl_branch_reserved"]},
              "reservation_ids_by_reserved_by" => %{"ops_calendar" => ["hold_branch"]},
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_station_reservation"]
            }
          }
        }
      },
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.station_reservation_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.station_reservation_report"

    assert summary["contract"] == "station_reservation_report.v1"
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 2

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_station_reservation_report"
           ]

    assert summary["affected_contact_count"] == 1
    assert summary["provider_calendar_contention_group_count"] == 1
    assert summary["provider_calendar_contention_group_ids"] == ["branch_contention_group"]
    assert summary["provider_calendar_contention_source_entry_ids"] == ["branch_source_entry"]
    assert summary["provider_calendar_contention_provider_entry_ids"] == ["branch_provider_entry"]

    assert summary["provider_calendar_contention_provider_entry_ids_by_direction"] == %{
             "downlink" => ["branch_provider_entry"]
           }

    assert summary["reservation_review_count"] == 1
    assert summary["station_reservation_evidence_row_count"] == 2
    assert summary["station_reservation_expiration_evidence_row_count"] == 1
    assert summary["affected_contact_ids"] == ["dl_branch_reserved"]
    assert summary["direction_counts"] == %{"downlink" => 1}
    assert summary["contact_ids_by_direction"] == %{"downlink" => ["dl_branch_reserved"]}

    assert summary["direction_routing"] == %{
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["dl_branch_reserved"],
               "reservation_hold_ids" => ["hold_branch"],
               "reservation_hold_contact_ids" => ["dl_branch_reserved"]
             }
           }

    assert summary["reservation_expires_at_s"] == [600.0]
    assert summary["earliest_reservation_expires_at_s"] == 600.0
    assert summary["station_reservation_match_status_counts"] == %{"overlap" => 1}
    assert summary["reservation_status_counts"] == %{"held" => 1}
    assert summary["reservation_ids"] == ["hold_branch"]
    assert summary["reserved_by_counts"] == %{"ops_calendar" => 1}
    assert summary["trust_boundaries"] == ["branch_station_reservation"]
    assert summary["branch_local_station_reservation_pressure"]
    assert summary["branch_local_reservation_review_pressure"]
    assert summary["branch_local_reservation_expiration_pressure"]
    assert summary["branch_local_reservation_owner_pressure"]
    assert summary["branch_local_provider_contention_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "station_reservation_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_station_reservation_replay_summary(artifact) ==
             summary
  end

  test "station reservation replay falls back to provenance when branch summary lacks usable family" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{"station_reservation_report" => %{}}
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "station_reservation_report" => %{
            "contract" => "station_reservation_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["source_station_reservation_report"],
            "affected_contact_count" => 0,
            "reservation_review_count" => 1,
            "affected_contact_ids" => ["dl_provenance_reserved"],
            "direction_counts" => %{"downlink" => 1},
            "contact_ids_by_direction" => %{"downlink" => ["dl_provenance_reserved"]},
            "direction_routing" => %{
              "downlink" => %{
                "contact_count" => 1,
                "contact_ids" => ["dl_provenance_reserved"]
              }
            }
          }
        }
      }
    }

    summary = CandidateRefresh.station_reservation_replay_summary(artifact)

    assert summary["source_report_paths"] == ["source_station_reservation_report"]
    assert summary["reservation_review_count"] == 1
    assert summary["affected_contact_ids"] == ["dl_provenance_reserved"]
    assert summary["direction_counts"] == %{"downlink" => 1}
    assert summary["contact_ids_by_direction"] == %{"downlink" => ["dl_provenance_reserved"]}

    assert summary["direction_routing"] == %{
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["dl_provenance_reserved"],
               "reservation_hold_contact_ids" => [],
               "reservation_hold_ids" => []
             }
           }

    assert summary["branch_local_station_reservation_pressure"]
    assert summary["branch_local_reservation_review_pressure"]
  end

  test "station reservation replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "station_reservation_report" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_station_reservation_report"
              ],
              "reservation_ids" => ["hold_branch"],
              "direction_counts" => %{"downlink" => 1}
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "station_reservation_report" => %{
            "contract" => "station_reservation_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_station_reservation_report"],
            "reservation_review_count" => 9,
            "affected_contact_ids" => ["dl_provenance_reserved"],
            "reservation_ids" => ["hold_provenance"],
            "direction_counts" => %{"uplink" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.station_reservation_replay_summary(artifact)

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_station_reservation_report"
           ]

    assert summary["reservation_review_count"] == 0
    assert summary["affected_contact_ids"] == []
    assert summary["reservation_ids"] == ["hold_branch"]
    assert summary["direction_counts"] == %{"downlink" => 1}
    assert summary["branch_local_station_reservation_pressure"]
  end
end
