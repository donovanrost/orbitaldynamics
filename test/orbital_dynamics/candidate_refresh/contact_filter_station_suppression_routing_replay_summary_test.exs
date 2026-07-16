defmodule OrbitalDynamics.CandidateRefresh.ContactFilterStationSuppressionRoutingReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary aggregates contact filter station suppression routing maps" do
    refresh = %{
      "source_contact_filter_report" => %{
        "schema_contract" => "contact_filter_report.v1",
        "suppressed_candidates" => [
          %{
            "id" => "dl_station_unavailable",
            "direction" => "Down Link",
            "ground_station_id" => "equator_prime",
            "station_calendar_entry_id" => "entry_unavailable",
            "station_calendar_provider_entry_id" => "provider_entry_unavailable",
            "suppressed_reason" => "ground_station_unavailable"
          },
          %{
            "id" => "dl_station_reserved",
            "direction" => "s-band command",
            "ground_station_id" => "dss_43",
            "station_calendar_entry_id" => "entry_reserved",
            "station_calendar_provider_entry_id" => "provider_entry_reserved",
            "station_reservation_id" => "reservation_dss_43",
            "suppressed_reason" => "ground_station_reserved"
          },
          %{
            "id" => "dl_station_capacity_zero",
            "direction" => "tracking_pass",
            "ground_station_id" => "dss_43",
            "station_calendar_entry_id" => "entry_capacity_zero",
            "station_calendar_provider_entry_id" => "provider_entry_capacity_zero",
            "suppressed_reason" => "ground_station_capacity_zero"
          },
          %{
            "id" => "invalid_contact",
            "direction" => "health-check",
            "suppressed_reason" => "invalid_contact_input",
            "required_operator_action" => "review_invalid_contact_filter_input"
          }
        ],
        "suppressed_reason_counts" => %{"stale_reason" => 99},
        "direction_counts" => %{"stale_direction" => 99},
        "contact_ids_by_direction" => %{"stale_direction" => ["stale_contact"]},
        "station_suppression_ground_station_counts" => %{"stale_station" => 99},
        "station_suppression_availability_counts" => %{"stale_availability" => 99},
        "station_suppression_status_counts" => %{"stale_status" => 99},
        "station_suppression_station_calendar_provider_entry_ids_by_ground_station" => %{
          "stale_station" => ["stale_provider_entry"]
        },
        "station_suppression_station_calendar_provider_entry_ids_by_availability" => %{
          "stale_availability" => ["stale_provider_entry"]
        },
        "station_suppression_station_calendar_provider_entry_ids_by_status" => %{
          "stale_status" => ["stale_provider_entry"]
        },
        "provenance" => %{"trust_boundary" => "ops_contact_filter"}
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_contact_filter_contract" => "contact_filter_report.v1",
             "source_report_contact_filter_count" => 1,
             "source_report_contact_filter_row_count" => 4,
             "source_report_contact_filter_paths" => ["source_contact_filter_report"],
             "source_report_contact_filter_suppressed_candidate_count" => 4,
             "source_report_contact_filter_invalid_contact_input_count" => 1,
             "source_report_contact_filter_invalid_contact_input_ids" => [
               "invalid_contact"
             ],
             "source_report_contact_filter_suppressed_reason_counts" => %{
               "ground_station_capacity_zero" => 1,
               "ground_station_reserved" => 1,
               "ground_station_unavailable" => 1,
               "invalid_contact_input" => 1
             },
             "source_report_contact_filter_contact_ids_by_suppressed_reason" => %{
               "ground_station_capacity_zero" => ["dl_station_capacity_zero"],
               "ground_station_reserved" => ["dl_station_reserved"],
               "ground_station_unavailable" => ["dl_station_unavailable"],
               "invalid_contact_input" => ["invalid_contact"]
             },
             "source_report_contact_filter_direction_counts" => %{
               "command" => 1,
               "downlink" => 1,
               "health_check" => 1,
               "tracking" => 1
             },
             "source_report_contact_filter_directions" => [
               "command",
               "downlink",
               "health_check",
               "tracking"
             ],
             "source_report_contact_filter_contact_ids_by_direction" => %{
               "command" => ["dl_station_reserved"],
               "downlink" => ["dl_station_unavailable"],
               "health_check" => ["invalid_contact"],
               "tracking" => ["dl_station_capacity_zero"]
             },
             "source_report_contact_filter_direction_routing" => %{
               "command" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["dl_station_reserved"]
               },
               "downlink" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["dl_station_unavailable"]
               },
               "health_check" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["invalid_contact"]
               },
               "tracking" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["dl_station_capacity_zero"]
               }
             },
             "source_report_contact_filter_station_suppression_count" => 3,
             "source_report_contact_filter_station_suppression_ground_station_counts" => %{
               "dss_43" => 2,
               "equator_prime" => 1
             },
             "source_report_contact_filter_station_suppression_availability_counts" => %{
               "reduced_capacity" => 1,
               "reserved" => 1,
               "unavailable" => 1
             },
             "source_report_contact_filter_station_suppression_status_counts" => %{
               "reserved" => 1,
               "unavailable" => 1
             },
             "source_report_contact_filter_station_suppression_contact_ids_by_ground_station" =>
               %{
                 "dss_43" => ["dl_station_capacity_zero", "dl_station_reserved"],
                 "equator_prime" => ["dl_station_unavailable"]
               },
             "source_report_contact_filter_station_suppression_contact_ids_by_availability" => %{
               "reduced_capacity" => ["dl_station_capacity_zero"],
               "reserved" => ["dl_station_reserved"],
               "unavailable" => ["dl_station_unavailable"]
             },
             "source_report_contact_filter_station_suppression_contact_ids_by_status" => %{
               "reserved" => ["dl_station_reserved"],
               "unavailable" => ["dl_station_unavailable"]
             },
             "source_report_contact_filter_station_suppression_station_calendar_entry_ids_by_ground_station" =>
               %{
                 "dss_43" => ["entry_capacity_zero", "entry_reserved"],
                 "equator_prime" => ["entry_unavailable"]
               },
             "source_report_contact_filter_station_suppression_station_calendar_entry_ids_by_availability" =>
               %{
                 "reduced_capacity" => ["entry_capacity_zero"],
                 "reserved" => ["entry_reserved"],
                 "unavailable" => ["entry_unavailable"]
               },
             "source_report_contact_filter_station_suppression_station_calendar_entry_ids_by_status" =>
               %{
                 "reserved" => ["entry_reserved"],
                 "unavailable" => ["entry_unavailable"]
               },
             "source_report_contact_filter_station_suppression_station_calendar_provider_entry_ids_by_ground_station" =>
               %{
                 "dss_43" => ["provider_entry_capacity_zero", "provider_entry_reserved"],
                 "equator_prime" => ["provider_entry_unavailable"]
               },
             "source_report_contact_filter_station_suppression_station_calendar_provider_entry_ids_by_availability" =>
               %{
                 "reduced_capacity" => ["provider_entry_capacity_zero"],
                 "reserved" => ["provider_entry_reserved"],
                 "unavailable" => ["provider_entry_unavailable"]
               },
             "source_report_contact_filter_station_suppression_station_calendar_provider_entry_ids_by_status" =>
               %{
                 "reserved" => ["provider_entry_reserved"],
                 "unavailable" => ["provider_entry_unavailable"]
               },
             "source_report_contact_filter_station_suppression_station_reservation_ids_by_ground_station" =>
               %{
                 "dss_43" => ["reservation_dss_43"]
               },
             "source_report_contact_filter_station_suppression_station_reservation_ids_by_availability" =>
               %{
                 "reserved" => ["reservation_dss_43"]
               },
             "source_report_contact_filter_station_suppression_station_reservation_ids_by_status" =>
               %{
                 "reserved" => ["reservation_dss_43"]
               },
             "source_report_contact_filter_branch_local_contact_filter_pressure" => true,
             "source_report_contact_filter_branch_local_candidate_suppression_pressure" => true,
             "source_report_contact_filter_branch_local_invalid_contact_input_pressure" => true,
             "source_report_contact_filter_branch_local_station_suppression_pressure" => true,
             "source_reports" => %{
               "contact_filter_report" => %{
                 "suppressed_candidate_count" => 4,
                 "invalid_contact_input_count" => 1,
                 "invalid_contact_input_ids" => ["invalid_contact"],
                 "contact_ids_by_suppressed_reason" => %{
                   "ground_station_capacity_zero" => ["dl_station_capacity_zero"],
                   "ground_station_reserved" => ["dl_station_reserved"],
                   "ground_station_unavailable" => ["dl_station_unavailable"],
                   "invalid_contact_input" => ["invalid_contact"]
                 },
                 "station_suppression_count" => 3,
                 "station_suppression_ground_station_counts" => %{
                   "dss_43" => 2,
                   "equator_prime" => 1
                 },
                 "station_suppression_contact_ids_by_ground_station" => %{
                   "dss_43" => ["dl_station_capacity_zero", "dl_station_reserved"],
                   "equator_prime" => ["dl_station_unavailable"]
                 },
                 "station_suppression_contact_ids_by_availability" => %{
                   "reduced_capacity" => ["dl_station_capacity_zero"],
                   "reserved" => ["dl_station_reserved"],
                   "unavailable" => ["dl_station_unavailable"]
                 },
                 "station_suppression_contact_ids_by_status" => %{
                   "reserved" => ["dl_station_reserved"],
                   "unavailable" => ["dl_station_unavailable"]
                 },
                 "station_suppression_station_calendar_entry_ids_by_ground_station" => %{
                   "dss_43" => ["entry_capacity_zero", "entry_reserved"],
                   "equator_prime" => ["entry_unavailable"]
                 },
                 "station_suppression_station_calendar_entry_ids_by_availability" => %{
                   "reduced_capacity" => ["entry_capacity_zero"],
                   "reserved" => ["entry_reserved"],
                   "unavailable" => ["entry_unavailable"]
                 },
                 "station_suppression_station_calendar_entry_ids_by_status" => %{
                   "reserved" => ["entry_reserved"],
                   "unavailable" => ["entry_unavailable"]
                 },
                 "station_suppression_station_calendar_provider_entry_ids_by_ground_station" => %{
                   "dss_43" => ["provider_entry_capacity_zero", "provider_entry_reserved"],
                   "equator_prime" => ["provider_entry_unavailable"]
                 },
                 "station_suppression_station_calendar_provider_entry_ids_by_availability" => %{
                   "reduced_capacity" => ["provider_entry_capacity_zero"],
                   "reserved" => ["provider_entry_reserved"],
                   "unavailable" => ["provider_entry_unavailable"]
                 },
                 "station_suppression_station_calendar_provider_entry_ids_by_status" => %{
                   "reserved" => ["provider_entry_reserved"],
                   "unavailable" => ["provider_entry_unavailable"]
                 },
                 "station_suppression_station_reservation_ids_by_ground_station" => %{
                   "dss_43" => ["reservation_dss_43"]
                 },
                 "station_suppression_station_reservation_ids_by_availability" => %{
                   "reserved" => ["reservation_dss_43"]
                 },
                 "station_suppression_station_reservation_ids_by_status" => %{
                   "reserved" => ["reservation_dss_43"]
                 },
                 "direction_counts" => %{
                   "command" => 1,
                   "downlink" => 1,
                   "health_check" => 1,
                   "tracking" => 1
                 },
                 "directions" => ["command", "downlink", "health_check", "tracking"],
                 "contact_ids_by_direction" => %{
                   "command" => ["dl_station_reserved"],
                   "downlink" => ["dl_station_unavailable"],
                   "health_check" => ["invalid_contact"],
                   "tracking" => ["dl_station_capacity_zero"]
                 },
                 "direction_routing" => %{
                   "command" => %{
                     "contact_count" => 1,
                     "contact_ids" => ["dl_station_reserved"]
                   },
                   "downlink" => %{
                     "contact_count" => 1,
                     "contact_ids" => ["dl_station_unavailable"]
                   },
                   "health_check" => %{
                     "contact_count" => 1,
                     "contact_ids" => ["invalid_contact"]
                   },
                   "tracking" => %{
                     "contact_count" => 1,
                     "contact_ids" => ["dl_station_capacity_zero"]
                   }
                 }
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = %{
      "model" => "artifact_only_candidate_refresh_contact_filter_replay_summary",
      "source" => "candidate_refresh.source_report_provenance.contact_filter_report",
      "contract" => "contact_filter_report.v1",
      "source_report_count" => 1,
      "source_report_row_count" => 4,
      "source_report_paths" => ["source_contact_filter_report"],
      "suppressed_candidate_count" => 4,
      "invalid_contact_input_count" => 1,
      "invalid_contact_input_ids" => ["invalid_contact"],
      "suppressed_reason_counts" => %{
        "ground_station_capacity_zero" => 1,
        "ground_station_reserved" => 1,
        "ground_station_unavailable" => 1,
        "invalid_contact_input" => 1
      },
      "contact_ids_by_suppressed_reason" => %{
        "ground_station_capacity_zero" => ["dl_station_capacity_zero"],
        "ground_station_reserved" => ["dl_station_reserved"],
        "ground_station_unavailable" => ["dl_station_unavailable"],
        "invalid_contact_input" => ["invalid_contact"]
      },
      "direction_counts" => %{
        "command" => 1,
        "downlink" => 1,
        "health_check" => 1,
        "tracking" => 1
      },
      "directions" => ["command", "downlink", "health_check", "tracking"],
      "contact_ids_by_direction" => %{
        "command" => ["dl_station_reserved"],
        "downlink" => ["dl_station_unavailable"],
        "health_check" => ["invalid_contact"],
        "tracking" => ["dl_station_capacity_zero"]
      },
      "direction_routing" => %{
        "command" => %{
          "contact_count" => 1,
          "contact_ids" => ["dl_station_reserved"]
        },
        "downlink" => %{
          "contact_count" => 1,
          "contact_ids" => ["dl_station_unavailable"]
        },
        "health_check" => %{
          "contact_count" => 1,
          "contact_ids" => ["invalid_contact"]
        },
        "tracking" => %{
          "contact_count" => 1,
          "contact_ids" => ["dl_station_capacity_zero"]
        }
      },
      "station_suppression_count" => 3,
      "station_suppression_ground_station_counts" => %{
        "dss_43" => 2,
        "equator_prime" => 1
      },
      "station_suppression_availability_counts" => %{
        "reduced_capacity" => 1,
        "reserved" => 1,
        "unavailable" => 1
      },
      "station_suppression_status_counts" => %{
        "reserved" => 1,
        "unavailable" => 1
      },
      "station_suppression_contact_ids_by_ground_station" => %{
        "dss_43" => ["dl_station_capacity_zero", "dl_station_reserved"],
        "equator_prime" => ["dl_station_unavailable"]
      },
      "station_suppression_contact_ids_by_availability" => %{
        "reduced_capacity" => ["dl_station_capacity_zero"],
        "reserved" => ["dl_station_reserved"],
        "unavailable" => ["dl_station_unavailable"]
      },
      "station_suppression_contact_ids_by_status" => %{
        "reserved" => ["dl_station_reserved"],
        "unavailable" => ["dl_station_unavailable"]
      },
      "station_suppression_station_calendar_entry_ids_by_ground_station" => %{
        "dss_43" => ["entry_capacity_zero", "entry_reserved"],
        "equator_prime" => ["entry_unavailable"]
      },
      "station_suppression_station_calendar_entry_ids_by_availability" => %{
        "reduced_capacity" => ["entry_capacity_zero"],
        "reserved" => ["entry_reserved"],
        "unavailable" => ["entry_unavailable"]
      },
      "station_suppression_station_calendar_entry_ids_by_status" => %{
        "reserved" => ["entry_reserved"],
        "unavailable" => ["entry_unavailable"]
      },
      "station_suppression_station_calendar_provider_entry_ids_by_ground_station" => %{
        "dss_43" => ["provider_entry_capacity_zero", "provider_entry_reserved"],
        "equator_prime" => ["provider_entry_unavailable"]
      },
      "station_suppression_station_calendar_provider_entry_ids_by_availability" => %{
        "reduced_capacity" => ["provider_entry_capacity_zero"],
        "reserved" => ["provider_entry_reserved"],
        "unavailable" => ["provider_entry_unavailable"]
      },
      "station_suppression_station_calendar_provider_entry_ids_by_status" => %{
        "reserved" => ["provider_entry_reserved"],
        "unavailable" => ["provider_entry_unavailable"]
      },
      "station_suppression_station_reservation_ids_by_ground_station" => %{
        "dss_43" => ["reservation_dss_43"]
      },
      "station_suppression_station_reservation_ids_by_availability" => %{
        "reserved" => ["reservation_dss_43"]
      },
      "station_suppression_station_reservation_ids_by_status" => %{
        "reserved" => ["reservation_dss_43"]
      },
      "trust_boundary_status" => "declared",
      "trust_boundaries" => ["ops_contact_filter"],
      "branch_local_contact_filter_pressure" => true,
      "branch_local_candidate_suppression_pressure" => true,
      "branch_local_invalid_contact_input_pressure" => true,
      "branch_local_station_suppression_pressure" => true,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => "contact_filter_source_report_provenance_only",
        "operator_authority" => "not_granted_by_contact_filter_replay_summary",
        "contact_allocation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_contact_filter_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }

    assert CandidateRefresh.contact_filter_replay_summary(refresh) == replay_summary

    assert OrbitalDynamics.candidate_refresh_contact_filter_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => summary["source_reports"]}
    }

    assert %{
             "source_report_contact_filter_contract" => "contact_filter_report.v1",
             "source_report_contact_filter_count" => 1,
             "source_report_contact_filter_row_count" => 4,
             "source_report_contact_filter_paths" => ["source_contact_filter_report"],
             "source_report_contact_filter_contact_ids_by_suppressed_reason" => %{
               "ground_station_capacity_zero" => ["dl_station_capacity_zero"],
               "ground_station_reserved" => ["dl_station_reserved"],
               "ground_station_unavailable" => ["dl_station_unavailable"],
               "invalid_contact_input" => ["invalid_contact"]
             },
             "source_report_contact_filter_station_suppression_count" => 3,
             "source_report_contact_filter_station_suppression_ground_station_counts" => %{
               "dss_43" => 2,
               "equator_prime" => 1
             },
             "source_report_contact_filter_station_suppression_availability_counts" => %{
               "reduced_capacity" => 1,
               "reserved" => 1,
               "unavailable" => 1
             },
             "source_report_contact_filter_station_suppression_contact_ids_by_ground_station" =>
               %{
                 "dss_43" => ["dl_station_capacity_zero", "dl_station_reserved"],
                 "equator_prime" => ["dl_station_unavailable"]
               },
             "source_report_contact_filter_station_suppression_contact_ids_by_availability" => %{
               "reduced_capacity" => ["dl_station_capacity_zero"],
               "reserved" => ["dl_station_reserved"],
               "unavailable" => ["dl_station_unavailable"]
             },
             "source_report_contact_filter_station_suppression_contact_ids_by_status" => %{
               "reserved" => ["dl_station_reserved"],
               "unavailable" => ["dl_station_unavailable"]
             },
             "source_report_contact_filter_station_suppression_station_calendar_entry_ids_by_ground_station" =>
               %{
                 "dss_43" => ["entry_capacity_zero", "entry_reserved"],
                 "equator_prime" => ["entry_unavailable"]
               },
             "source_report_contact_filter_station_suppression_station_calendar_entry_ids_by_availability" =>
               %{
                 "reduced_capacity" => ["entry_capacity_zero"],
                 "reserved" => ["entry_reserved"],
                 "unavailable" => ["entry_unavailable"]
               },
             "source_report_contact_filter_station_suppression_station_calendar_entry_ids_by_status" =>
               %{
                 "reserved" => ["entry_reserved"],
                 "unavailable" => ["entry_unavailable"]
               },
             "source_report_contact_filter_station_suppression_station_calendar_provider_entry_ids_by_ground_station" =>
               %{
                 "dss_43" => ["provider_entry_capacity_zero", "provider_entry_reserved"],
                 "equator_prime" => ["provider_entry_unavailable"]
               },
             "source_report_contact_filter_station_suppression_station_calendar_provider_entry_ids_by_availability" =>
               %{
                 "reduced_capacity" => ["provider_entry_capacity_zero"],
                 "reserved" => ["provider_entry_reserved"],
                 "unavailable" => ["provider_entry_unavailable"]
               },
             "source_report_contact_filter_station_suppression_station_calendar_provider_entry_ids_by_status" =>
               %{
                 "reserved" => ["provider_entry_reserved"],
                 "unavailable" => ["provider_entry_unavailable"]
               },
             "source_report_contact_filter_station_suppression_station_reservation_ids_by_ground_station" =>
               %{
                 "dss_43" => ["reservation_dss_43"]
               },
             "source_report_contact_filter_station_suppression_station_reservation_ids_by_availability" =>
               %{
                 "reserved" => ["reservation_dss_43"]
               },
             "source_report_contact_filter_station_suppression_station_reservation_ids_by_status" =>
               %{
                 "reserved" => ["reservation_dss_43"]
               },
             "source_report_contact_filter_direction_counts" => %{
               "command" => 1,
               "downlink" => 1,
               "health_check" => 1,
               "tracking" => 1
             },
             "source_report_contact_filter_directions" => [
               "command",
               "downlink",
               "health_check",
               "tracking"
             ],
             "source_report_contact_filter_contact_ids_by_direction" => %{
               "command" => ["dl_station_reserved"],
               "downlink" => ["dl_station_unavailable"],
               "health_check" => ["invalid_contact"],
               "tracking" => ["dl_station_capacity_zero"]
             },
             "source_report_contact_filter_direction_routing" => %{
               "command" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["dl_station_reserved"]
               },
               "downlink" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["dl_station_unavailable"]
               },
               "health_check" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["invalid_contact"]
               },
               "tracking" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["dl_station_capacity_zero"]
               }
             },
             "source_report_contact_filter_branch_local_contact_filter_pressure" => true,
             "source_report_contact_filter_branch_local_candidate_suppression_pressure" => true,
             "source_report_contact_filter_branch_local_invalid_contact_input_pressure" => true,
             "source_report_contact_filter_branch_local_station_suppression_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.contact_filter_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_contact_filter_replay_summary(artifact) ==
             replay_summary
  end
end
