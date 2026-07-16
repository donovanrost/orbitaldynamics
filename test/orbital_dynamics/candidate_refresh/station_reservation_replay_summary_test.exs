defmodule OrbitalDynamics.CandidateRefresh.StationReservationReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary preserves station reservation report provenance" do
    refresh = %{
      "source_station_reservation_report" => %{
        "schema_contract" => "station_reservation_report.v1",
        "source" => "station_calendar_report.reservation_evidence",
        "affected_contacts" => [
          %{
            "contact_id" => "dl_reserved_intruder",
            "direction" => "Down Link",
            "station_reservation_match_status" => "overlap",
            "station_calendar_reservation_ids" => ["reservation_partner"],
            "station_calendar_reservation_statuses" => ["confirmed"],
            "station_calendar_reservation_expires_at_s" => [360.0],
            "station_reserved_by" => "partner_ops",
            "required_operator_action" => "review_station_reservation_overlap",
            "trust_boundary" => "reservation_report_rows"
          },
          %{
            "contact_id" => "cmd_reserved_intruder",
            "contact_direction" => "s-band command",
            "station_reservation_match_status" => "matched",
            "station_reservation_id" => "reservation_ops",
            "station_reservation_status" => "hold",
            "station_reservation_expires_at_s" => 720.0,
            "reserved_by" => "ops",
            "required_operator_action" => "review_station_reservation_overlap",
            "trust_boundary" => "reservation_report_rows"
          }
        ],
        "provider_calendar_contention_groups" => [
          %{
            "id" => "reservation_provider_contention:equator_prime:1",
            "provider_calendar_contention_status" => "provider_calendar_overlap",
            "provider_ids" => ["ops_calendar", "partner_calendar"],
            "provider_entry_ids" => ["provider_entry_ops", "provider_entry_partner"],
            "ground_station_id" => "equator_prime",
            "directions" => ["Down Link"],
            "source_station_calendar_entries" => [
              %{"id" => "provider_a", "ground_station_id" => "equator_prime"},
              %{"id" => "provider_b", "ground_station_id" => "dss_43"}
            ],
            "reservation_ids" => ["reservation_partner"],
            "reservation_statuses" => ["confirmed"],
            "reserved_by" => ["partner_ops"],
            "required_operator_action" => "review_station_provider_contention",
            "trust_boundary" => "reservation_provider_groups"
          }
        ],
        "station_reservation_match_status_counts" => %{"stale" => 99},
        "reservation_status_counts" => %{"stale" => 99},
        "direction_counts" => %{"stale_direction" => 99},
        "contact_ids_by_direction" => %{"stale_direction" => ["stale_contact"]},
        "provider_calendar_contention_provider_entry_ids_by_provider" => %{
          "stale_provider" => ["stale_provider_entry"]
        },
        "provider_calendar_contention_provider_entry_ids_by_ground_station" => %{
          "stale_station" => ["stale_provider_entry"]
        },
        "provider_calendar_contention_provider_entry_ids_by_direction" => %{
          "stale_direction" => ["stale_provider_entry"]
        },
        "trust_boundary" => "reservation_report"
      }
    }

    expected_direction_routing = %{
      "command" => %{
        "contact_count" => 1,
        "contact_ids" => ["cmd_reserved_intruder"],
        "reservation_hold_ids" => [],
        "reservation_hold_contact_ids" => []
      },
      "downlink" => %{
        "contact_count" => 1,
        "contact_ids" => ["dl_reserved_intruder"],
        "reservation_hold_ids" => [],
        "reservation_hold_contact_ids" => []
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_count" => 1,
             "source_report_row_count" => 3,
             "source_report_station_reservation_evidence_row_count" => 3,
             "source_report_station_reservation_expiration_evidence_row_count" => 2,
             "source_report_counts_by_family" => %{"station_reservation_report" => 1},
             "source_report_row_counts_by_family" => %{"station_reservation_report" => 3},
             "source_report_counts_by_contract" => %{"station_reservation_report.v1" => 1},
             "source_report_paths_by_family" => %{
               "station_reservation_report" => ["source_station_reservation_report"]
             },
             "source_report_station_reservation_contract" => "station_reservation_report.v1",
             "source_report_station_reservation_count" => 1,
             "source_report_station_reservation_row_count" => 3,
             "source_report_station_reservation_paths" => ["source_station_reservation_report"],
             "source_report_station_reservation_evidence_row_counts_by_family" => %{
               "station_reservation_report" => 3
             },
             "source_report_station_reservation_expiration_evidence_row_counts_by_family" => %{
               "station_reservation_report" => 2
             },
             "source_report_station_reservation_affected_contact_count" => 2,
             "source_report_station_reservation_provider_calendar_contention_group_count" => 1,
             "source_report_station_reservation_provider_calendar_contention_group_ids" => [
               "reservation_provider_contention:equator_prime:1"
             ],
             "source_report_station_reservation_provider_calendar_contention_source_entry_ids" =>
               [
                 "provider_a",
                 "provider_b"
               ],
             "source_report_station_reservation_provider_calendar_contention_provider_entry_ids" =>
               [
                 "provider_entry_ops",
                 "provider_entry_partner"
               ],
             "source_report_station_reservation_reservation_review_count" => 3,
             "source_report_station_reservation_affected_contact_ids" => [
               "cmd_reserved_intruder",
               "dl_reserved_intruder"
             ],
             "source_report_station_reservation_contact_ids_by_match_status" => %{
               "matched" => ["cmd_reserved_intruder"],
               "overlap" => ["dl_reserved_intruder"]
             },
             "source_report_station_reservation_contact_ids_by_status" => %{
               "confirmed" => ["dl_reserved_intruder"],
               "hold" => ["cmd_reserved_intruder"]
             },
             "source_report_station_reservation_direction_counts" => %{
               "command" => 1,
               "downlink" => 1
             },
             "source_report_station_reservation_contact_ids_by_direction" => %{
               "command" => ["cmd_reserved_intruder"],
               "downlink" => ["dl_reserved_intruder"]
             },
             "source_report_station_reservation_direction_routing" => ^expected_direction_routing,
             "source_report_station_reservation_expires_at_s" => [360.0, 720.0],
             "source_report_station_reservation_earliest_expires_at_s" => 360.0,
             "source_report_station_reservation_provider_calendar_contention_provider_counts" =>
               %{
                 "ops_calendar" => 1,
                 "partner_calendar" => 1
               },
             "source_report_station_reservation_provider_calendar_contention_ground_station_counts" =>
               %{
                 "dss_43" => 1,
                 "equator_prime" => 1
               },
             "source_report_station_reservation_provider_calendar_contention_provider_entry_ids_by_provider" =>
               %{
                 "ops_calendar" => ["provider_entry_ops", "provider_entry_partner"],
                 "partner_calendar" => ["provider_entry_ops", "provider_entry_partner"]
               },
             "source_report_station_reservation_provider_calendar_contention_provider_entry_ids_by_ground_station" =>
               %{
                 "dss_43" => ["provider_entry_ops", "provider_entry_partner"],
                 "equator_prime" => ["provider_entry_ops", "provider_entry_partner"]
               },
             "source_report_station_reservation_provider_calendar_contention_provider_entry_ids_by_direction" =>
               %{
                 "downlink" => ["provider_entry_ops", "provider_entry_partner"]
               },
             "source_report_station_reservation_match_status_counts" => %{
               "matched" => 1,
               "overlap" => 1
             },
             "source_report_station_reservation_status_counts" => %{
               "confirmed" => 2,
               "hold" => 1
             },
             "source_report_station_reservation_ids" => [
               "reservation_ops",
               "reservation_partner"
             ],
             "source_report_station_reservation_ids_by_match_status" => %{
               "matched" => ["reservation_ops"],
               "overlap" => ["reservation_partner"]
             },
             "source_report_station_reservation_ids_by_status" => %{
               "confirmed" => ["reservation_partner"],
               "hold" => ["reservation_ops"]
             },
             "source_report_station_reservation_reserved_by_counts" => %{
               "ops" => 1,
               "partner_ops" => 2
             },
             "source_report_station_reservation_contact_ids_by_reserved_by" => %{
               "ops" => ["cmd_reserved_intruder"],
               "partner_ops" => ["dl_reserved_intruder"]
             },
             "source_report_station_reservation_ids_by_reserved_by" => %{
               "ops" => ["reservation_ops"],
               "partner_ops" => ["reservation_partner"]
             },
             "source_report_station_reservation_branch_local_station_reservation_pressure" =>
               true,
             "source_report_station_reservation_branch_local_reservation_review_pressure" => true,
             "source_report_station_reservation_branch_local_reservation_owner_pressure" => true,
             "source_report_station_reservation_branch_local_reservation_expiration_pressure" =>
               true,
             "source_report_station_reservation_branch_local_provider_contention_pressure" =>
               true,
             "source_reports" => %{
               "station_reservation_report" => %{
                 "paths" => ["source_station_reservation_report"],
                 "contract" => "station_reservation_report.v1",
                 "count" => 1,
                 "row_count" => 3,
                 "affected_contact_count" => 2,
                 "provider_calendar_contention_group_count" => 1,
                 "provider_calendar_contention_provider_counts" => %{
                   "ops_calendar" => 1,
                   "partner_calendar" => 1
                 },
                 "provider_calendar_contention_ground_station_counts" => %{
                   "dss_43" => 1,
                   "equator_prime" => 1
                 },
                 "provider_calendar_contention_group_ids" => [
                   "reservation_provider_contention:equator_prime:1"
                 ],
                 "provider_calendar_contention_source_entry_ids" => [
                   "provider_a",
                   "provider_b"
                 ],
                 "provider_calendar_contention_provider_entry_ids" => [
                   "provider_entry_ops",
                   "provider_entry_partner"
                 ],
                 "provider_calendar_contention_provider_entry_ids_by_provider" => %{
                   "ops_calendar" => ["provider_entry_ops", "provider_entry_partner"],
                   "partner_calendar" => ["provider_entry_ops", "provider_entry_partner"]
                 },
                 "provider_calendar_contention_provider_entry_ids_by_ground_station" => %{
                   "dss_43" => ["provider_entry_ops", "provider_entry_partner"],
                   "equator_prime" => ["provider_entry_ops", "provider_entry_partner"]
                 },
                 "provider_calendar_contention_provider_entry_ids_by_direction" => %{
                   "downlink" => ["provider_entry_ops", "provider_entry_partner"]
                 },
                 "reservation_review_count" => 3,
                 "station_reservation_evidence_row_count" => 3,
                 "station_reservation_expiration_evidence_row_count" => 2,
                 "affected_contact_ids" => ["cmd_reserved_intruder", "dl_reserved_intruder"],
                 "contact_ids_by_match_status" => %{
                   "matched" => ["cmd_reserved_intruder"],
                   "overlap" => ["dl_reserved_intruder"]
                 },
                 "contact_ids_by_status" => %{
                   "confirmed" => ["dl_reserved_intruder"],
                   "hold" => ["cmd_reserved_intruder"]
                 },
                 "direction_counts" => %{
                   "command" => 1,
                   "downlink" => 1
                 },
                 "contact_ids_by_direction" => %{
                   "command" => ["cmd_reserved_intruder"],
                   "downlink" => ["dl_reserved_intruder"]
                 },
                 "direction_routing" => ^expected_direction_routing,
                 "reservation_expires_at_s" => [360.0, 720.0],
                 "earliest_reservation_expires_at_s" => 360.0,
                 "station_reservation_match_status_counts" => %{"matched" => 1, "overlap" => 1},
                 "reservation_status_counts" => %{"confirmed" => 2, "hold" => 1},
                 "reservation_ids" => ["reservation_ops", "reservation_partner"],
                 "reservation_ids_by_match_status" => %{
                   "matched" => ["reservation_ops"],
                   "overlap" => ["reservation_partner"]
                 },
                 "reservation_ids_by_status" => %{
                   "confirmed" => ["reservation_partner"],
                   "hold" => ["reservation_ops"]
                 },
                 "reserved_by_counts" => %{
                   "ops" => 1,
                   "partner_ops" => 2
                 },
                 "contact_ids_by_reserved_by" => %{
                   "ops" => ["cmd_reserved_intruder"],
                   "partner_ops" => ["dl_reserved_intruder"]
                 },
                 "reservation_ids_by_reserved_by" => %{
                   "ops" => ["reservation_ops"],
                   "partner_ops" => ["reservation_partner"]
                 },
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => [
                   "reservation_provider_groups",
                   "reservation_report",
                   "reservation_report_rows"
                 ]
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = %{
      "model" => "artifact_only_candidate_refresh_station_reservation_replay_summary",
      "source" => "candidate_refresh.source_report_provenance.station_reservation_report",
      "contract" => "station_reservation_report.v1",
      "source_report_count" => 1,
      "source_report_row_count" => 3,
      "source_report_paths" => ["source_station_reservation_report"],
      "affected_contact_count" => 2,
      "provider_calendar_contention_group_count" => 1,
      "provider_calendar_contention_provider_counts" => %{
        "ops_calendar" => 1,
        "partner_calendar" => 1
      },
      "provider_calendar_contention_ground_station_counts" => %{
        "dss_43" => 1,
        "equator_prime" => 1
      },
      "provider_calendar_contention_group_ids" => [
        "reservation_provider_contention:equator_prime:1"
      ],
      "provider_calendar_contention_source_entry_ids" => [
        "provider_a",
        "provider_b"
      ],
      "provider_calendar_contention_provider_entry_ids" => [
        "provider_entry_ops",
        "provider_entry_partner"
      ],
      "provider_calendar_contention_provider_entry_ids_by_provider" => %{
        "ops_calendar" => ["provider_entry_ops", "provider_entry_partner"],
        "partner_calendar" => ["provider_entry_ops", "provider_entry_partner"]
      },
      "provider_calendar_contention_provider_entry_ids_by_ground_station" => %{
        "dss_43" => ["provider_entry_ops", "provider_entry_partner"],
        "equator_prime" => ["provider_entry_ops", "provider_entry_partner"]
      },
      "provider_calendar_contention_provider_entry_ids_by_direction" => %{
        "downlink" => ["provider_entry_ops", "provider_entry_partner"]
      },
      "reservation_review_count" => 3,
      "station_reservation_evidence_row_count" => 3,
      "station_reservation_expiration_evidence_row_count" => 2,
      "affected_contact_ids" => ["cmd_reserved_intruder", "dl_reserved_intruder"],
      "contact_ids_by_match_status" => %{
        "matched" => ["cmd_reserved_intruder"],
        "overlap" => ["dl_reserved_intruder"]
      },
      "contact_ids_by_status" => %{
        "confirmed" => ["dl_reserved_intruder"],
        "hold" => ["cmd_reserved_intruder"]
      },
      "direction_counts" => %{
        "command" => 1,
        "downlink" => 1
      },
      "contact_ids_by_direction" => %{
        "command" => ["cmd_reserved_intruder"],
        "downlink" => ["dl_reserved_intruder"]
      },
      "direction_routing" => expected_direction_routing,
      "reservation_expires_at_s" => [360.0, 720.0],
      "earliest_reservation_expires_at_s" => 360.0,
      "station_reservation_match_status_counts" => %{"matched" => 1, "overlap" => 1},
      "reservation_status_counts" => %{"confirmed" => 2, "hold" => 1},
      "reservation_ids" => ["reservation_ops", "reservation_partner"],
      "reservation_ids_by_match_status" => %{
        "matched" => ["reservation_ops"],
        "overlap" => ["reservation_partner"]
      },
      "reservation_ids_by_status" => %{
        "confirmed" => ["reservation_partner"],
        "hold" => ["reservation_ops"]
      },
      "reserved_by_counts" => %{
        "ops" => 1,
        "partner_ops" => 2
      },
      "contact_ids_by_reserved_by" => %{
        "ops" => ["cmd_reserved_intruder"],
        "partner_ops" => ["dl_reserved_intruder"]
      },
      "reservation_ids_by_reserved_by" => %{
        "ops" => ["reservation_ops"],
        "partner_ops" => ["reservation_partner"]
      },
      "trust_boundary_status" => "declared",
      "trust_boundaries" => [
        "reservation_provider_groups",
        "reservation_report",
        "reservation_report_rows"
      ],
      "branch_local_station_reservation_pressure" => true,
      "branch_local_reservation_review_pressure" => true,
      "branch_local_reservation_expiration_pressure" => true,
      "branch_local_reservation_owner_pressure" => true,
      "branch_local_provider_contention_pressure" => true,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => "station_reservation_source_report_provenance_only",
        "operator_authority" => "not_granted_by_station_reservation_replay_summary",
        "provider_reservation" => "not_performed_by_summary",
        "station_calendar_mutation" => "not_performed_by_summary",
        "schedule_mutation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_station_reservation_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }

    assert CandidateRefresh.station_reservation_replay_summary(refresh) == replay_summary

    assert OrbitalDynamics.candidate_refresh_station_reservation_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => summary["source_reports"]}
    }

    assert CandidateRefresh.station_reservation_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_station_reservation_replay_summary(artifact) ==
             replay_summary
  end
end
