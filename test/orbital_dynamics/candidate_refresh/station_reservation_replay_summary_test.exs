defmodule OrbitalDynamics.CandidateRefresh.StationReservationReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CandidateRefresh, Epoch, ResultSet, Schema}

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

  test "station reservation replay accepts review summaries" do
    summary = %{
      "model" => "artifact_only_station_reservation_review_summary",
      "schema_contract" => "station_reservation_review_summary.v1",
      "source_artifact_type" => "station_reservation_report.v1",
      "source" => "station_calendar_report.reservation_evidence",
      "reservation_count" => 2,
      "affected_contact_reservation_count" => 1,
      "provider_calendar_contention_group_count" => 1,
      "reservation_review_status" => "review_required",
      "reservation_expiration_count" => 1,
      "earliest_reservation_expires_at_s" => 240.0,
      "reservation_expiration_status_counts" => %{"expired" => 1, "missing" => 1},
      "reservation_ids_by_expiration_status" => %{
        "expired" => ["reservation_expired"],
        "missing" => ["reservation_missing"]
      },
      "review_reservation_ids" => ["reservation_expired", "reservation_missing"],
      "review_rows" => [
        %{
          "reservation_review_row_type" => "affected_contact",
          "contact_id" => "dl_source_reserved",
          "direction" => "downlink",
          "station_reservation_match_status" => "overlap",
          "reservation_ids" => ["reservation_expired"],
          "reservation_statuses" => ["held"],
          "reserved_by" => ["ops_calendar"],
          "reservation_expires_at_s" => [240.0],
          "station_reservation_expiration_status" => "expired",
          "required_operator_action" => "review_station_reservation_overlap"
        },
        %{
          "reservation_review_row_type" => "provider_calendar_contention_group",
          "directions" => ["uplink"],
          "provider_calendar_contention_status" => "contention",
          "reservation_ids" => ["reservation_missing"],
          "reservation_statuses" => ["held"],
          "reserved_by" => ["partner_calendar"],
          "station_reservation_expiration_status" => "missing",
          "required_operator_action" => "review_station_provider_contention"
        }
      ],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation",
        "source" => "station_reservation_report.v1",
        "operator_authority" => "not_granted_by_summary",
        "deadline_evaluation" => "relative_to_now_s",
        "now_s" => 300.0
      }
    }

    refresh = %{"source_station_reservation_review_summary" => summary}

    expected_direction_routing = %{
      "downlink" => %{
        "contact_count" => 1,
        "contact_ids" => ["dl_source_reserved"],
        "reservation_hold_ids" => [],
        "reservation_hold_contact_ids" => []
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_count" => 1,
             "source_report_row_count" => 2,
             "source_report_station_reservation_contract" => "station_reservation_report.v1",
             "source_report_station_reservation_count" => 1,
             "source_report_station_reservation_row_count" => 2,
             "source_report_station_reservation_paths" => [
               "source_station_reservation_review_summary"
             ],
             "source_report_station_reservation_reservation_review_count" => 2,
             "source_report_station_reservation_evidence_row_count" => 2,
             "source_report_station_reservation_expiration_evidence_row_count" => 1,
             "source_report_station_reservation_affected_contact_count" => 1,
             "source_report_station_reservation_provider_calendar_contention_group_count" => 1,
             "source_report_station_reservation_source_summary_model_counts" => %{
               "artifact_only_station_reservation_review_summary" => 1
             },
             "source_report_station_reservation_source_summary_schema_contract_counts" => %{
               "station_reservation_review_summary.v1" => 1
             },
             "source_report_station_reservation_source_artifact_type_counts" => %{
               "station_reservation_report.v1" => 1
             },
             "source_report_station_reservation_affected_contact_ids" => [
               "dl_source_reserved"
             ],
             "source_report_station_reservation_contact_ids_by_match_status" => %{
               "overlap" => ["dl_source_reserved"]
             },
             "source_report_station_reservation_contact_ids_by_status" => %{
               "held" => ["dl_source_reserved"]
             },
             "source_report_station_reservation_direction_counts" => %{"downlink" => 1},
             "source_report_station_reservation_contact_ids_by_direction" => %{
               "downlink" => ["dl_source_reserved"]
             },
             "source_report_station_reservation_direction_routing" => ^expected_direction_routing,
             "source_report_station_reservation_expires_at_s" => [240.0],
             "source_report_station_reservation_earliest_expires_at_s" => 240.0,
             "source_report_station_reservation_status_counts" => %{"held" => 2},
             "source_report_station_reservation_ids" => [
               "reservation_expired",
               "reservation_missing"
             ],
             "source_report_station_reservation_ids_by_status" => %{
               "held" => ["reservation_expired", "reservation_missing"]
             },
             "source_report_station_reservation_reserved_by_counts" => %{
               "ops_calendar" => 1,
               "partner_calendar" => 1
             },
             "source_report_station_reservation_contact_ids_by_reserved_by" => %{
               "ops_calendar" => ["dl_source_reserved"]
             },
             "source_report_station_reservation_ids_by_reserved_by" => %{
               "ops_calendar" => ["reservation_expired"],
               "partner_calendar" => ["reservation_missing"]
             },
             "source_reports" => %{
               "station_reservation_report" => %{
                 "paths" => ["source_station_reservation_review_summary"],
                 "contract" => "station_reservation_report.v1",
                 "count" => 1,
                 "row_count" => 2,
                 "source_summary_model_counts" => %{
                   "artifact_only_station_reservation_review_summary" => 1
                 },
                 "source_summary_schema_contract_counts" => %{
                   "station_reservation_review_summary.v1" => 1
                 },
                 "source_artifact_type_counts" => %{
                   "station_reservation_report.v1" => 1
                 },
                 "affected_contact_count" => 1,
                 "provider_calendar_contention_group_count" => 1,
                 "reservation_review_count" => 2,
                 "station_reservation_evidence_row_count" => 2,
                 "station_reservation_expiration_evidence_row_count" => 1,
                 "affected_contact_ids" => ["dl_source_reserved"],
                 "contact_ids_by_match_status" => %{
                   "overlap" => ["dl_source_reserved"]
                 },
                 "contact_ids_by_status" => %{"held" => ["dl_source_reserved"]},
                 "direction_counts" => %{"downlink" => 1},
                 "contact_ids_by_direction" => %{"downlink" => ["dl_source_reserved"]},
                 "direction_routing" => ^expected_direction_routing,
                 "reservation_expires_at_s" => [240.0],
                 "earliest_reservation_expires_at_s" => 240.0,
                 "reservation_status_counts" => %{"held" => 2},
                 "reservation_ids" => ["reservation_expired", "reservation_missing"],
                 "reservation_ids_by_status" => %{
                   "held" => ["reservation_expired", "reservation_missing"]
                 },
                 "reserved_by_counts" => %{
                   "ops_calendar" => 1,
                   "partner_calendar" => 1
                 },
                 "contact_ids_by_reserved_by" => %{
                   "ops_calendar" => ["dl_source_reserved"]
                 },
                 "reservation_ids_by_reserved_by" => %{
                   "ops_calendar" => ["reservation_expired"],
                   "partner_calendar" => ["reservation_missing"]
                 }
               }
             }
           } = source_report_summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "source_report_paths" => ["source_station_reservation_review_summary"],
             "source_summary_model_counts" => %{
               "artifact_only_station_reservation_review_summary" => 1
             },
             "source_summary_schema_contract_counts" => %{
               "station_reservation_review_summary.v1" => 1
             },
             "source_artifact_type_counts" => %{"station_reservation_report.v1" => 1},
             "reservation_review_count" => 2,
             "station_reservation_evidence_row_count" => 2,
             "station_reservation_expiration_evidence_row_count" => 1,
             "affected_contact_count" => 1,
             "provider_calendar_contention_group_count" => 1,
             "affected_contact_ids" => ["dl_source_reserved"],
             "contact_ids_by_status" => %{"held" => ["dl_source_reserved"]},
             "direction_routing" => ^expected_direction_routing,
             "reservation_expires_at_s" => [240.0],
             "earliest_reservation_expires_at_s" => 240.0,
             "reservation_status_counts" => %{"held" => 2},
             "reservation_ids" => ["reservation_expired", "reservation_missing"],
             "reserved_by_counts" => %{
               "ops_calendar" => 1,
               "partner_calendar" => 1
             },
             "branch_local_station_reservation_pressure" => true,
             "branch_local_reservation_review_pressure" => true,
             "branch_local_provider_contention_pressure" => true,
             "branch_local_reservation_expiration_pressure" => true,
             "assumptions" => %{
               "provider_reservation" => "not_performed_by_summary",
               "cadence_write" => "not_performed_by_summary"
             }
           } = replay_summary = CandidateRefresh.station_reservation_replay_summary(refresh)

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_report_summary["source_reports"]}
    }

    assert CandidateRefresh.station_reservation_replay_summary(artifact) == replay_summary

    wrapped_summary =
      CandidateRefresh.source_report_summary(%{
        "source_result_artifact" => [
          %{"source_station_reservation_review_summary" => summary}
        ]
      })

    assert get_in(wrapped_summary, [
             "source_reports",
             "station_reservation_report",
             "paths"
           ]) == [
             "source_result_artifact[0].source_station_reservation_review_summary"
           ]
  end

  test "station reservation replay accepts hold summaries" do
    summary = %{
      "model" => "artifact_only_station_reservation_hold_summary",
      "schema_contract" => "station_reservation_hold_summary.v1",
      "source_artifact_type" => "station_reservation_report.v1",
      "source" => "station_calendar_report.reservation_evidence",
      "reservation_hold_count" => 2,
      "affected_contact_reservation_hold_count" => 1,
      "provider_calendar_contention_hold_count" => 1,
      "reservation_hold_review_status" => "review_required",
      "reservation_hold_expiration_count" => 1,
      "earliest_reservation_hold_expires_at_s" => 240.0,
      "reservation_hold_expiration_status_counts" => %{"expired" => 1, "missing" => 1},
      "reservation_hold_status_counts" => %{"held" => 2},
      "reservation_hold_ids" => ["reservation_expired", "reservation_missing"],
      "reservation_hold_ids_by_expiration_status" => %{
        "expired" => ["reservation_expired"],
        "missing" => ["reservation_missing"]
      },
      "reservation_hold_ids_by_status" => %{
        "held" => ["reservation_expired", "reservation_missing"]
      },
      "reservation_hold_ids_by_reserved_by" => %{
        "ops_calendar" => ["reservation_expired"],
        "partner_calendar" => ["reservation_missing"]
      },
      "reservation_hold_ids_by_row_type" => %{
        "affected_contact" => ["reservation_expired"],
        "provider_calendar_contention_group" => ["reservation_missing"]
      },
      "reservation_hold_contact_ids_by_expiration_status" => %{
        "expired" => ["dl_source_reserved"]
      },
      "review_contact_ids" => ["dl_source_reserved"],
      "review_rows" => [
        %{
          "reservation_review_row_type" => "affected_contact",
          "contact_id" => "dl_source_reserved",
          "direction" => "downlink",
          "reservation_ids" => ["reservation_expired"],
          "reservation_statuses" => ["held"],
          "reserved_by" => ["ops_calendar"],
          "reservation_expires_at_s" => [240.0],
          "station_reservation_expiration_status" => "expired"
        },
        %{
          "reservation_review_row_type" => "provider_calendar_contention_group",
          "directions" => ["uplink"],
          "reservation_ids" => ["reservation_missing"],
          "reservation_statuses" => ["held"],
          "reserved_by" => ["partner_calendar"],
          "station_reservation_expiration_status" => "missing"
        }
      ],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation",
        "source" => "station_reservation_report.v1",
        "operator_authority" => "not_granted_by_summary",
        "deadline_evaluation" => "evaluated_from_now_s",
        "now_s" => 300.0
      }
    }

    refresh = %{"source_station_reservation_hold_summary" => summary}

    expected_direction_routing = %{
      "downlink" => %{
        "contact_count" => 1,
        "contact_ids" => ["dl_source_reserved"],
        "reservation_hold_ids" => ["reservation_expired"],
        "reservation_hold_contact_ids" => ["dl_source_reserved"]
      },
      "uplink" => %{
        "contact_ids" => [],
        "reservation_hold_ids" => ["reservation_missing"],
        "reservation_hold_contact_ids" => []
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_count" => 1,
             "source_report_row_count" => 2,
             "source_report_station_reservation_contract" => "station_reservation_report.v1",
             "source_report_station_reservation_count" => 1,
             "source_report_station_reservation_row_count" => 2,
             "source_report_station_reservation_paths" => [
               "source_station_reservation_hold_summary"
             ],
             "source_report_station_reservation_hold_count" => 2,
             "source_report_station_reservation_affected_contact_hold_count" => 1,
             "source_report_station_reservation_provider_calendar_contention_hold_count" => 1,
             "source_report_station_reservation_hold_review_status_counts" => %{
               "review_required" => 1
             },
             "source_report_station_reservation_hold_expiration_count" => 1,
             "source_report_station_reservation_earliest_hold_expires_at_s" => 240.0,
             "source_report_station_reservation_hold_expiration_status_counts" => %{
               "expired" => 1,
               "missing" => 1
             },
             "source_report_station_reservation_hold_status_counts" => %{"held" => 2},
             "source_report_station_reservation_source_summary_model_counts" => %{
               "artifact_only_station_reservation_hold_summary" => 1
             },
             "source_report_station_reservation_source_summary_schema_contract_counts" => %{
               "station_reservation_hold_summary.v1" => 1
             },
             "source_report_station_reservation_source_artifact_type_counts" => %{
               "station_reservation_report.v1" => 1
             },
             "source_report_station_reservation_hold_ids" => [
               "reservation_expired",
               "reservation_missing"
             ],
             "source_report_station_reservation_hold_ids_by_expiration_status" => %{
               "expired" => ["reservation_expired"],
               "missing" => ["reservation_missing"]
             },
             "source_report_station_reservation_hold_ids_by_status" => %{
               "held" => ["reservation_expired", "reservation_missing"]
             },
             "source_report_station_reservation_hold_ids_by_reserved_by" => %{
               "ops_calendar" => ["reservation_expired"],
               "partner_calendar" => ["reservation_missing"]
             },
             "source_report_station_reservation_hold_ids_by_row_type" => %{
               "affected_contact" => ["reservation_expired"],
               "provider_calendar_contention_group" => ["reservation_missing"]
             },
             "source_report_station_reservation_hold_ids_by_direction" => %{
               "downlink" => ["reservation_expired"],
               "uplink" => ["reservation_missing"]
             },
             "source_report_station_reservation_hold_contact_ids_by_expiration_status" => %{
               "expired" => ["dl_source_reserved"]
             },
             "source_report_station_reservation_hold_contact_ids_by_direction" => %{
               "downlink" => ["dl_source_reserved"]
             },
             "source_report_station_reservation_direction_routing" => ^expected_direction_routing,
             "source_report_station_reservation_hold_review_contact_ids" => [
               "dl_source_reserved"
             ],
             "source_reports" => %{
               "station_reservation_report" => %{
                 "paths" => ["source_station_reservation_hold_summary"],
                 "contract" => "station_reservation_report.v1",
                 "count" => 1,
                 "row_count" => 2,
                 "source_summary_model_counts" => %{
                   "artifact_only_station_reservation_hold_summary" => 1
                 },
                 "source_summary_schema_contract_counts" => %{
                   "station_reservation_hold_summary.v1" => 1
                 },
                 "source_artifact_type_counts" => %{
                   "station_reservation_report.v1" => 1
                 },
                 "affected_contact_count" => 1,
                 "provider_calendar_contention_group_count" => 1,
                 "reservation_hold_count" => 2,
                 "affected_contact_reservation_hold_count" => 1,
                 "provider_calendar_contention_hold_count" => 1,
                 "reservation_hold_review_status_counts" => %{"review_required" => 1},
                 "reservation_hold_expiration_count" => 1,
                 "earliest_reservation_hold_expires_at_s" => 240.0,
                 "reservation_hold_expiration_status_counts" => %{
                   "expired" => 1,
                   "missing" => 1
                 },
                 "reservation_hold_status_counts" => %{"held" => 2},
                 "reservation_hold_ids" => ["reservation_expired", "reservation_missing"],
                 "reservation_hold_ids_by_expiration_status" => %{
                   "expired" => ["reservation_expired"],
                   "missing" => ["reservation_missing"]
                 },
                 "reservation_hold_ids_by_row_type" => %{
                   "affected_contact" => ["reservation_expired"],
                   "provider_calendar_contention_group" => ["reservation_missing"]
                 },
                 "reservation_hold_ids_by_direction" => %{
                   "downlink" => ["reservation_expired"],
                   "uplink" => ["reservation_missing"]
                 },
                 "reservation_hold_contact_ids_by_expiration_status" => %{
                   "expired" => ["dl_source_reserved"]
                 },
                 "reservation_hold_contact_ids_by_direction" => %{
                   "downlink" => ["dl_source_reserved"]
                 },
                 "direction_routing" => ^expected_direction_routing,
                 "reservation_hold_review_contact_ids" => ["dl_source_reserved"]
               }
             }
           } = source_report_summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = CandidateRefresh.station_reservation_replay_summary(refresh)

    assert %{
             "source_report_paths" => ["source_station_reservation_hold_summary"],
             "source_summary_model_counts" => %{
               "artifact_only_station_reservation_hold_summary" => 1
             },
             "source_summary_schema_contract_counts" => %{
               "station_reservation_hold_summary.v1" => 1
             },
             "source_artifact_type_counts" => %{"station_reservation_report.v1" => 1},
             "reservation_hold_count" => 2,
             "affected_contact_reservation_hold_count" => 1,
             "provider_calendar_contention_hold_count" => 1,
             "reservation_hold_review_status_counts" => %{"review_required" => 1},
             "reservation_hold_expiration_count" => 1,
             "earliest_reservation_hold_expires_at_s" => 240.0,
             "reservation_hold_expiration_status_counts" => %{
               "expired" => 1,
               "missing" => 1
             },
             "reservation_hold_status_counts" => %{"held" => 2},
             "reservation_hold_ids" => ["reservation_expired", "reservation_missing"],
             "reservation_hold_ids_by_expiration_status" => %{
               "expired" => ["reservation_expired"],
               "missing" => ["reservation_missing"]
             },
             "reservation_hold_ids_by_status" => %{
               "held" => ["reservation_expired", "reservation_missing"]
             },
             "reservation_hold_ids_by_reserved_by" => %{
               "ops_calendar" => ["reservation_expired"],
               "partner_calendar" => ["reservation_missing"]
             },
             "reservation_hold_ids_by_row_type" => %{
               "affected_contact" => ["reservation_expired"],
               "provider_calendar_contention_group" => ["reservation_missing"]
             },
             "reservation_hold_ids_by_direction" => %{
               "downlink" => ["reservation_expired"],
               "uplink" => ["reservation_missing"]
             },
             "reservation_hold_contact_ids_by_expiration_status" => %{
               "expired" => ["dl_source_reserved"]
             },
             "reservation_hold_contact_ids_by_direction" => %{
               "downlink" => ["dl_source_reserved"]
             },
             "direction_routing" => ^expected_direction_routing,
             "reservation_hold_review_contact_ids" => ["dl_source_reserved"],
             "branch_local_station_reservation_pressure" => true,
             "branch_local_reservation_hold_pressure" => true,
             "branch_local_reservation_hold_import_readiness_pressure" => true,
             "assumptions" => %{
               "provider_reservation" => "not_performed_by_summary",
               "cadence_write" => "not_performed_by_summary"
             }
           } = replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_report_summary["source_reports"]}
    }

    assert CandidateRefresh.station_reservation_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_station_reservation_replay_summary(artifact) ==
             replay_summary
  end

  test "station reservation replay accepts wrapped hold summaries" do
    summary = %{
      "model" => "artifact_only_station_reservation_hold_summary",
      "schema_contract" => "station_reservation_hold_summary.v1",
      "source_artifact_type" => "station_reservation_report.v1",
      "source" => "station_calendar_report.reservation_evidence",
      "reservation_hold_count" => 1,
      "affected_contact_reservation_hold_count" => 1,
      "provider_calendar_contention_hold_count" => 0,
      "reservation_hold_review_status" => "review_required",
      "reservation_hold_expiration_count" => 1,
      "earliest_reservation_hold_expires_at_s" => 240.0,
      "reservation_hold_expiration_status_counts" => %{"expired" => 1},
      "reservation_hold_status_counts" => %{"held" => 1},
      "reservation_hold_ids" => ["reservation_expired"],
      "reservation_hold_ids_by_expiration_status" => %{
        "expired" => ["reservation_expired"]
      },
      "reservation_hold_ids_by_status" => %{"held" => ["reservation_expired"]},
      "reservation_hold_ids_by_reserved_by" => %{"ops_calendar" => ["reservation_expired"]},
      "reservation_hold_ids_by_row_type" => %{
        "affected_contact" => ["reservation_expired"]
      },
      "reservation_hold_contact_ids_by_expiration_status" => %{
        "expired" => ["dl_source_reserved"]
      },
      "review_contact_ids" => ["dl_source_reserved"],
      "review_rows" => [
        %{
          "reservation_review_row_type" => "affected_contact",
          "contact_id" => "dl_source_reserved",
          "direction" => "downlink",
          "reservation_ids" => ["reservation_expired"],
          "reservation_statuses" => ["held"],
          "reserved_by" => ["ops_calendar"],
          "reservation_expires_at_s" => [240.0],
          "station_reservation_expiration_status" => "expired"
        }
      ],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation",
        "source" => "station_reservation_report.v1",
        "operator_authority" => "not_granted_by_summary"
      }
    }

    wrapper = %{
      "schema_contract" => "result_artifact.v1",
      "provenance" => %{"trust_boundary" => "ground_partner_api"},
      "source_station_reservation_hold_summary" => summary
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_result_artifact", [wrapper]),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "paths" => [
               "source_result_artifact[0].source_station_reservation_hold_summary"
             ],
             "contract" => "station_reservation_report.v1",
             "count" => 1,
             "row_count" => 1,
             "source_summary_model_counts" => %{
               "artifact_only_station_reservation_hold_summary" => 1
             },
             "source_summary_schema_contract_counts" => %{
               "station_reservation_hold_summary.v1" => 1
             },
             "source_artifact_type_counts" => %{"station_reservation_report.v1" => 1},
             "reservation_hold_count" => 1,
             "reservation_hold_review_status_counts" => %{"review_required" => 1},
             "reservation_hold_expiration_count" => 1,
             "reservation_hold_expiration_status_counts" => %{"expired" => 1},
             "reservation_hold_ids_by_expiration_status" => %{
               "expired" => ["reservation_expired"]
             },
             "reservation_hold_review_contact_ids" => ["dl_source_reserved"]
           } =
             get_in(artifact, ["provenance", "source_reports", "station_reservation_report"])

    assert %{
             "source_report_paths" => [
               "source_result_artifact[0].source_station_reservation_hold_summary"
             ],
             "source_summary_model_counts" => %{
               "artifact_only_station_reservation_hold_summary" => 1
             },
             "source_summary_schema_contract_counts" => %{
               "station_reservation_hold_summary.v1" => 1
             },
             "reservation_hold_count" => 1,
             "reservation_hold_review_status_counts" => %{"review_required" => 1},
             "reservation_hold_expiration_count" => 1,
             "reservation_hold_contact_ids_by_expiration_status" => %{
               "expired" => ["dl_source_reserved"]
             },
             "branch_local_reservation_hold_pressure" => true,
             "assumptions" => %{
               "provider_reservation" => "not_performed_by_summary",
               "cadence_write" => "not_performed_by_summary"
             }
           } = CandidateRefresh.station_reservation_replay_summary(artifact)

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "station reservation replay accepts hold import-readiness summaries" do
    summary = %{
      "model" => "artifact_only_station_reservation_hold_import_readiness_summary",
      "schema_contract" => "station_reservation_hold_import_readiness_summary.v1",
      "source_artifact_type" => "station_reservation_report.v1",
      "source" => "station_calendar_report.reservation_evidence",
      "reservation_hold_count" => 2,
      "import_readiness_status" => "review_required",
      "import_classification" => "review_only",
      "ready_for_import_count" => 0,
      "review_required_before_import_count" => 2,
      "no_import_required_count" => 0,
      "reservation_hold_import_status_counts" => %{
        "stale_import_status" => 99
      },
      "reservation_hold_status_counts" => %{"held" => 2},
      "reservation_hold_expiration_status_counts" => %{"expired" => 1, "missing" => 1},
      "required_import_action_counts" => %{
        "stale_action" => 99
      },
      "reservation_hold_ids" => ["reservation_expired", "reservation_missing"],
      "reservation_hold_ids_by_import_status" => %{
        "stale_import_status" => ["stale_reservation"]
      },
      "reservation_hold_ids_by_expiration_status" => %{
        "expired" => ["reservation_expired"],
        "missing" => ["reservation_missing"]
      },
      "reservation_hold_ids_by_status" => %{
        "held" => ["reservation_expired", "reservation_missing"]
      },
      "reservation_hold_ids_by_reserved_by" => %{
        "ops_calendar" => ["reservation_expired"],
        "partner_calendar" => ["reservation_missing"]
      },
      "reservation_hold_ids_by_required_import_action" => %{
        "stale_action" => ["stale_reservation"]
      },
      "reservation_hold_ids_by_direction" => %{
        "stale_direction" => ["stale_reservation"]
      },
      "reservation_hold_contact_ids_by_import_status" => %{
        "stale_import_status" => ["stale_contact"]
      },
      "reservation_hold_contact_ids_by_expiration_status" => %{
        "expired" => ["dl_source_reserved"]
      },
      "reservation_hold_contact_ids_by_direction" => %{
        "stale_direction" => ["stale_contact"]
      },
      "review_contact_ids" => ["dl_source_reserved"],
      "import_readiness_rows" => [
        %{
          "reservation_review_row_type" => "affected_contact",
          "contact_id" => "dl_source_reserved",
          "direction" => "downlink",
          "reservation_ids" => ["reservation_expired"],
          "reservation_statuses" => ["held"],
          "reserved_by" => ["ops_calendar"],
          "station_reservation_expiration_status" => "expired",
          "station_reservation_hold_import_status" => "review_required_before_import",
          "required_operator_action" => "review_station_reservation_overlap"
        },
        %{
          "reservation_review_row_type" => "provider_calendar_contention_group",
          "directions" => ["uplink"],
          "reservation_ids" => ["reservation_missing"],
          "reservation_statuses" => ["held"],
          "reserved_by" => ["partner_calendar"],
          "station_reservation_expiration_status" => "missing",
          "station_reservation_hold_import_status" => "review_required_before_import",
          "required_operator_action" => "review_station_provider_contention"
        }
      ],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_or_cadence_writes",
        "provider_write" => "not_performed_by_summary",
        "cadence_write" => "not_performed_by_summary",
        "reservation_acceptance" => "not_performed_by_summary"
      }
    }

    refresh = %{
      "source_station_reservation_hold_import_readiness_summary" => summary
    }

    expected_direction_routing = %{
      "downlink" => %{
        "contact_count" => 1,
        "contact_ids" => ["dl_source_reserved"],
        "reservation_hold_ids" => ["reservation_expired"],
        "reservation_hold_contact_ids" => ["dl_source_reserved"]
      },
      "uplink" => %{
        "contact_ids" => [],
        "reservation_hold_ids" => ["reservation_missing"],
        "reservation_hold_contact_ids" => []
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_count" => 1,
             "source_report_row_count" => 2,
             "source_report_station_reservation_contract" => "station_reservation_report.v1",
             "source_report_station_reservation_count" => 1,
             "source_report_station_reservation_row_count" => 2,
             "source_report_station_reservation_paths" => [
               "source_station_reservation_hold_import_readiness_summary"
             ],
             "source_report_station_reservation_hold_count" => 2,
             "source_report_station_reservation_source_summary_model_counts" => %{
               "artifact_only_station_reservation_hold_import_readiness_summary" => 1
             },
             "source_report_station_reservation_source_summary_schema_contract_counts" => %{
               "station_reservation_hold_import_readiness_summary.v1" => 1
             },
             "source_report_station_reservation_source_artifact_type_counts" => %{
               "station_reservation_report.v1" => 1
             },
             "source_report_station_reservation_hold_import_readiness_status_counts" => %{
               "review_required" => 1
             },
             "source_report_station_reservation_hold_import_classification_counts" => %{
               "review_only" => 1
             },
             "source_report_station_reservation_hold_review_required_before_import_count" => 2,
             "source_report_station_reservation_hold_import_status_counts" => %{
               "review_required_before_import" => 2
             },
             "source_report_station_reservation_hold_required_import_action_counts" => %{
               "review_station_provider_contention" => 1,
               "review_station_reservation_overlap" => 1
             },
             "source_report_station_reservation_hold_ids" => [
               "reservation_expired",
               "reservation_missing"
             ],
             "source_report_station_reservation_hold_ids_by_import_status" => %{
               "review_required_before_import" => [
                 "reservation_expired",
                 "reservation_missing"
               ]
             },
             "source_report_station_reservation_hold_ids_by_required_import_action" => %{
               "review_station_provider_contention" => ["reservation_missing"],
               "review_station_reservation_overlap" => ["reservation_expired"]
             },
             "source_report_station_reservation_hold_ids_by_direction" => %{
               "downlink" => ["reservation_expired"],
               "uplink" => ["reservation_missing"]
             },
             "source_report_station_reservation_hold_contact_ids_by_import_status" => %{
               "review_required_before_import" => ["dl_source_reserved"]
             },
             "source_report_station_reservation_hold_contact_ids_by_direction" => %{
               "downlink" => ["dl_source_reserved"]
             },
             "source_report_station_reservation_direction_routing" => ^expected_direction_routing,
             "source_report_station_reservation_branch_local_station_reservation_pressure" =>
               true,
             "source_report_station_reservation_branch_local_reservation_hold_pressure" => true,
             "source_report_station_reservation_branch_local_provider_contention_pressure" =>
               true,
             "source_report_station_reservation_branch_local_reservation_hold_import_readiness_pressure" =>
               true,
             "source_reports" => %{
               "station_reservation_report" => %{
                 "paths" => ["source_station_reservation_hold_import_readiness_summary"],
                 "contract" => "station_reservation_report.v1",
                 "count" => 1,
                 "row_count" => 2,
                 "source_summary_model_counts" => %{
                   "artifact_only_station_reservation_hold_import_readiness_summary" => 1
                 },
                 "source_summary_schema_contract_counts" => %{
                   "station_reservation_hold_import_readiness_summary.v1" => 1
                 },
                 "source_artifact_type_counts" => %{
                   "station_reservation_report.v1" => 1
                 },
                 "affected_contact_count" => 1,
                 "provider_calendar_contention_group_count" => 1,
                 "reservation_hold_count" => 2,
                 "reservation_hold_import_status_counts" => %{
                   "review_required_before_import" => 2
                 },
                 "required_import_action_counts" => %{
                   "review_station_provider_contention" => 1,
                   "review_station_reservation_overlap" => 1
                 },
                 "reservation_hold_ids" => ["reservation_expired", "reservation_missing"],
                 "reservation_hold_ids_by_direction" => %{
                   "downlink" => ["reservation_expired"],
                   "uplink" => ["reservation_missing"]
                 },
                 "reservation_hold_contact_ids_by_direction" => %{
                   "downlink" => ["dl_source_reserved"]
                 },
                 "direction_routing" => ^expected_direction_routing
               }
             }
           } = source_report_summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = CandidateRefresh.station_reservation_replay_summary(refresh)

    assert %{
             "source_report_paths" => ["source_station_reservation_hold_import_readiness_summary"],
             "source_summary_model_counts" => %{
               "artifact_only_station_reservation_hold_import_readiness_summary" => 1
             },
             "source_summary_schema_contract_counts" => %{
               "station_reservation_hold_import_readiness_summary.v1" => 1
             },
             "source_artifact_type_counts" => %{"station_reservation_report.v1" => 1},
             "reservation_hold_count" => 2,
             "reservation_hold_import_readiness_status_counts" => %{"review_required" => 1},
             "reservation_hold_import_classification_counts" => %{"review_only" => 1},
             "reservation_hold_review_required_before_import_count" => 2,
             "reservation_hold_import_status_counts" => %{
               "review_required_before_import" => 2
             },
             "reservation_hold_required_import_action_counts" => %{
               "review_station_provider_contention" => 1,
               "review_station_reservation_overlap" => 1
             },
             "reservation_hold_ids" => ["reservation_expired", "reservation_missing"],
             "reservation_hold_ids_by_import_status" => %{
               "review_required_before_import" => [
                 "reservation_expired",
                 "reservation_missing"
               ]
             },
             "reservation_hold_contact_ids_by_import_status" => %{
               "review_required_before_import" => ["dl_source_reserved"]
             },
             "reservation_hold_ids_by_direction" => %{
               "downlink" => ["reservation_expired"],
               "uplink" => ["reservation_missing"]
             },
             "reservation_hold_contact_ids_by_direction" => %{
               "downlink" => ["dl_source_reserved"]
             },
             "direction_routing" => ^expected_direction_routing,
             "branch_local_station_reservation_pressure" => true,
             "branch_local_reservation_hold_import_readiness_pressure" => true,
             "assumptions" => %{
               "provider_reservation" => "not_performed_by_summary",
               "cadence_write" => "not_performed_by_summary"
             }
           } = replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_report_summary["source_reports"]}
    }

    assert CandidateRefresh.station_reservation_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_station_reservation_replay_summary(artifact) ==
             replay_summary
  end

  test "station reservation replay accepts wrapped hold import-readiness summaries" do
    summary = %{
      "model" => "artifact_only_station_reservation_hold_import_readiness_summary",
      "schema_contract" => "station_reservation_hold_import_readiness_summary.v1",
      "source_artifact_type" => "station_reservation_report.v1",
      "source" => "station_calendar_report.reservation_evidence",
      "reservation_hold_count" => 2,
      "import_readiness_status" => "review_required",
      "import_classification" => "review_only",
      "ready_for_import_count" => 0,
      "review_required_before_import_count" => 2,
      "no_import_required_count" => 0,
      "reservation_hold_import_status_counts" => %{
        "review_required_before_import" => 2
      },
      "required_import_action_counts" => %{
        "review_station_provider_contention" => 1,
        "review_station_reservation_overlap" => 1
      },
      "reservation_hold_ids" => ["reservation_expired", "reservation_missing"],
      "reservation_hold_ids_by_import_status" => %{
        "review_required_before_import" => ["reservation_expired", "reservation_missing"]
      },
      "reservation_hold_ids_by_required_import_action" => %{
        "review_station_provider_contention" => ["reservation_missing"],
        "review_station_reservation_overlap" => ["reservation_expired"]
      },
      "reservation_hold_contact_ids_by_import_status" => %{
        "review_required_before_import" => ["dl_source_reserved"]
      },
      "import_readiness_rows" => [
        %{
          "reservation_review_row_type" => "affected_contact",
          "contact_id" => "dl_source_reserved",
          "direction" => "downlink",
          "reservation_ids" => ["reservation_expired"],
          "reservation_statuses" => ["held"],
          "reserved_by" => ["ops_calendar"],
          "station_reservation_hold_import_status" => "review_required_before_import",
          "required_operator_action" => "review_station_reservation_overlap"
        },
        %{
          "reservation_review_row_type" => "provider_calendar_contention_group",
          "directions" => ["uplink"],
          "reservation_ids" => ["reservation_missing"],
          "reservation_statuses" => ["held"],
          "reserved_by" => ["partner_calendar"],
          "station_reservation_hold_import_status" => "review_required_before_import",
          "required_operator_action" => "review_station_provider_contention"
        }
      ],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_or_cadence_writes",
        "provider_write" => "not_performed_by_summary",
        "cadence_write" => "not_performed_by_summary",
        "reservation_acceptance" => "not_performed_by_summary"
      }
    }

    wrapper = %{
      "schema_contract" => "result_artifact.v1",
      "provenance" => %{"trust_boundary" => "ground_partner_api"},
      "source_station_reservation_hold_import_readiness_summary" => summary
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_result_artifact", [wrapper]),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "paths" => [
               "source_result_artifact[0].source_station_reservation_hold_import_readiness_summary"
             ],
             "contract" => "station_reservation_report.v1",
             "count" => 1,
             "row_count" => 2,
             "source_summary_model_counts" => %{
               "artifact_only_station_reservation_hold_import_readiness_summary" => 1
             },
             "source_summary_schema_contract_counts" => %{
               "station_reservation_hold_import_readiness_summary.v1" => 1
             },
             "source_artifact_type_counts" => %{"station_reservation_report.v1" => 1},
             "affected_contact_count" => 1,
             "provider_calendar_contention_group_count" => 1,
             "reservation_hold_count" => 2,
             "reservation_hold_import_status_counts" => %{
               "review_required_before_import" => 2
             },
             "required_import_action_counts" => %{
               "review_station_provider_contention" => 1,
               "review_station_reservation_overlap" => 1
             },
             "reservation_hold_ids" => ["reservation_expired", "reservation_missing"],
             "reservation_hold_contact_ids_by_import_status" => %{
               "review_required_before_import" => ["dl_source_reserved"]
             },
             "reservation_hold_ids_by_direction" => %{
               "downlink" => ["reservation_expired"],
               "uplink" => ["reservation_missing"]
             },
             "reservation_hold_contact_ids_by_direction" => %{
               "downlink" => ["dl_source_reserved"]
             }
           } =
             get_in(artifact, ["provenance", "source_reports", "station_reservation_report"])

    assert %{
             "source_report_paths" => [
               "source_result_artifact[0].source_station_reservation_hold_import_readiness_summary"
             ],
             "source_summary_model_counts" => %{
               "artifact_only_station_reservation_hold_import_readiness_summary" => 1
             },
             "source_summary_schema_contract_counts" => %{
               "station_reservation_hold_import_readiness_summary.v1" => 1
             },
             "source_artifact_type_counts" => %{"station_reservation_report.v1" => 1},
             "reservation_hold_count" => 2,
             "reservation_hold_import_readiness_status_counts" => %{"review_required" => 1},
             "reservation_hold_required_import_action_counts" => %{
               "review_station_provider_contention" => 1,
               "review_station_reservation_overlap" => 1
             },
             "reservation_hold_ids_by_direction" => %{
               "downlink" => ["reservation_expired"],
               "uplink" => ["reservation_missing"]
             },
             "reservation_hold_contact_ids_by_direction" => %{
               "downlink" => ["dl_source_reserved"]
             },
             "branch_local_station_reservation_pressure" => true,
             "branch_local_reservation_hold_import_readiness_pressure" => true,
             "assumptions" => %{
               "provider_reservation" => "not_performed_by_summary",
               "cadence_write" => "not_performed_by_summary"
             }
           } = CandidateRefresh.station_reservation_replay_summary(artifact)

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "station reservation replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.station_reservation_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_station_reservation_contract")
    refute Map.has_key?(source_summary, "source_report_station_reservation_count")
    refute Map.has_key?(source_summary, "source_report_station_reservation_row_count")
    refute Map.has_key?(source_summary, "source_report_station_reservation_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_station_reservation_pressure"]
  end

  test "station reservation source summary omits missing identity counts for partial family placeholder" do
    partial_summaries = [
      %{"contract" => "station_reservation_report.v1"},
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.station_reservation_report"]},
      %{"count" => nil, "row_count" => nil},
      %{
        "count" => nil,
        "row_count" => nil,
        "paths" => ["provenance.source_reports.station_reservation_report"]
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "station_reservation_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      if Map.has_key?(partial_summary, "contract") do
        assert source_summary["source_report_station_reservation_contract"] ==
                 "station_reservation_report.v1"
      else
        refute Map.has_key?(source_summary, "source_report_station_reservation_contract")
      end

      refute Map.has_key?(source_summary, "source_report_station_reservation_count")
      refute Map.has_key?(source_summary, "source_report_station_reservation_row_count")
      refute Map.has_key?(source_summary, "source_report_station_reservation_paths")
    end
  end

  test "station reservation source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "station_reservation_report" => %{
            "contract" => "station_reservation_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.station_reservation_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_station_reservation_contract"] ==
             "station_reservation_report.v1"

    assert source_summary["source_report_station_reservation_count"] == 0
    assert source_summary["source_report_station_reservation_row_count"] == 0

    assert source_summary["source_report_station_reservation_paths"] == [
             "provenance.source_reports.station_reservation_report"
           ]
  end

  test "station reservation source summary omits missing identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "station_reservation_report" => %{
            "contract" => "station_reservation_report.v1",
            "count" => 1,
            "row_count" => 2
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_station_reservation_contract"] ==
             "station_reservation_report.v1"

    assert source_summary["source_report_station_reservation_count"] == 1
    assert source_summary["source_report_station_reservation_row_count"] == 2
    refute Map.has_key?(source_summary, "source_report_station_reservation_paths")
  end

  test "station reservation source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "station_reservation_report" => %{
            "contract" => "station_reservation_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_station_reservation_contract"] ==
             "station_reservation_report.v1"

    assert source_summary["source_report_station_reservation_count"] == 1
    assert source_summary["source_report_station_reservation_row_count"] == 2
    assert source_summary["source_report_station_reservation_paths"] == []
  end

  test "station reservation replay treats preserved provider-contention maps as pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "station_reservation_report" => %{
            "contract" => "station_reservation_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["source_station_reservation_report"],
            "affected_contact_count" => 0,
            "provider_calendar_contention_group_count" => 0,
            "provider_calendar_contention_group_ids" => ["reservation_contention_map_only"],
            "provider_calendar_contention_source_entry_ids" => ["provider_source_map_only"],
            "provider_calendar_contention_provider_entry_ids" => ["provider_entry_map_only"],
            "provider_calendar_contention_provider_entry_ids_by_provider" => %{
              "ops_calendar" => ["provider_entry_map_only"]
            },
            "provider_calendar_contention_provider_entry_ids_by_ground_station" => %{
              "equator_prime" => ["provider_entry_map_only"]
            },
            "provider_calendar_contention_provider_entry_ids_by_direction" => %{
              "downlink" => ["provider_entry_map_only"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.station_reservation_replay_summary(artifact)

    assert summary["affected_contact_count"] == 0
    assert summary["provider_calendar_contention_group_count"] == 0

    assert summary["provider_calendar_contention_group_ids"] == [
             "reservation_contention_map_only"
           ]

    assert summary["provider_calendar_contention_source_entry_ids"] == [
             "provider_source_map_only"
           ]

    assert summary["provider_calendar_contention_provider_entry_ids"] == [
             "provider_entry_map_only"
           ]

    assert summary["provider_calendar_contention_provider_entry_ids_by_provider"] == %{
             "ops_calendar" => ["provider_entry_map_only"]
           }

    assert summary["provider_calendar_contention_provider_entry_ids_by_ground_station"] == %{
             "equator_prime" => ["provider_entry_map_only"]
           }

    assert summary["provider_calendar_contention_provider_entry_ids_by_direction"] == %{
             "downlink" => ["provider_entry_map_only"]
           }

    assert summary["branch_local_station_reservation_pressure"]
    assert summary["branch_local_provider_contention_pressure"]
  end

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
               "contact_ids" => ["dl_provenance_reserved"]
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

  test "station reservation replay treats preserved expiration evidence as family pressure" do
    base_summary = %{
      "contract" => "station_reservation_report.v1",
      "count" => 1,
      "row_count" => 0,
      "paths" => ["source_station_reservation_report"],
      "affected_contact_count" => 0,
      "affected_contact_ids" => [],
      "contact_ids_by_match_status" => %{},
      "contact_ids_by_status" => %{},
      "direction_counts" => %{},
      "contact_ids_by_direction" => %{},
      "provider_calendar_contention_group_count" => 0,
      "provider_calendar_contention_provider_counts" => %{},
      "provider_calendar_contention_ground_station_counts" => %{},
      "provider_calendar_contention_group_ids" => [],
      "provider_calendar_contention_source_entry_ids" => [],
      "provider_calendar_contention_provider_entry_ids" => [],
      "provider_calendar_contention_provider_entry_ids_by_provider" => %{},
      "provider_calendar_contention_provider_entry_ids_by_ground_station" => %{},
      "provider_calendar_contention_provider_entry_ids_by_direction" => %{},
      "reservation_review_count" => 0,
      "station_reservation_evidence_row_count" => 0,
      "station_reservation_expiration_evidence_row_count" => 0,
      "reservation_expires_at_s" => [],
      "station_reservation_match_status_counts" => %{},
      "reservation_status_counts" => %{},
      "reservation_ids" => [],
      "reservation_ids_by_match_status" => %{},
      "reservation_ids_by_status" => %{},
      "reserved_by_counts" => %{},
      "contact_ids_by_reserved_by" => %{},
      "reservation_ids_by_reserved_by" => %{}
    }

    cases = [
      {"expiration evidence", %{"station_reservation_expiration_evidence_row_count" => 1}},
      {"expiration timestamps", %{"reservation_expires_at_s" => [360.0]}},
      {"earliest expiration", %{"earliest_reservation_expires_at_s" => 360.0}}
    ]

    for {label, evidence} <- cases do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "station_reservation_report" => Map.merge(base_summary, evidence)
          }
        }
      }

      summary = CandidateRefresh.station_reservation_replay_summary(artifact)

      assert summary["source_report_count"] == 1, label
      assert summary["affected_contact_count"] == 0, label
      assert summary["affected_contact_ids"] == [], label
      assert summary["reservation_review_count"] == 0, label
      assert summary["station_reservation_evidence_row_count"] == 0, label
      assert summary["reservation_ids"] == [], label
      assert summary["reserved_by_counts"] == %{}, label
      assert summary["provider_calendar_contention_group_count"] == 0, label
      refute summary["branch_local_reservation_review_pressure"], label
      refute summary["branch_local_reservation_owner_pressure"], label
      refute summary["branch_local_provider_contention_pressure"], label
      assert summary["branch_local_reservation_expiration_pressure"], label
      assert summary["branch_local_station_reservation_pressure"], label
    end
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
