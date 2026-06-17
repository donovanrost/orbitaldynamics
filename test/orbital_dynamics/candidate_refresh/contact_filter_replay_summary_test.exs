defmodule OrbitalDynamics.CandidateRefresh.ContactFilterReplaySummaryTest do
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

  test "contact filter replay treats preserved station maps and invalid IDs as pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_filter_report" => %{
            "contract" => "contact_filter_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["source_contact_filter_report"],
            "suppressed_candidate_count" => 0,
            "invalid_contact_input_count" => 0,
            "invalid_contact_input_ids" => ["bad_contact"],
            "suppressed_reason_counts" => %{"ground_station_unavailable" => 1},
            "contact_ids_by_suppressed_reason" => %{
              "ground_station_unavailable" => ["dl_station_block"]
            },
            "direction_counts" => %{"downlink" => 1},
            "contact_ids_by_direction" => %{"downlink" => ["dl_station_block"]},
            "station_suppression_count" => 0,
            "station_suppression_ground_station_counts" => %{"equator_prime" => 1},
            "station_suppression_availability_counts" => %{"unavailable" => 1},
            "station_suppression_status_counts" => %{"unavailable" => 1},
            "station_suppression_contact_ids_by_ground_station" => %{
              "equator_prime" => ["dl_station_block"]
            },
            "station_suppression_contact_ids_by_availability" => %{
              "unavailable" => ["dl_station_block"]
            },
            "station_suppression_contact_ids_by_status" => %{
              "unavailable" => ["dl_station_block"]
            },
            "station_suppression_station_calendar_entry_ids_by_ground_station" => %{
              "equator_prime" => ["entry_station_block"]
            },
            "station_suppression_station_calendar_entry_ids_by_availability" => %{
              "unavailable" => ["entry_station_block"]
            },
            "station_suppression_station_calendar_entry_ids_by_status" => %{
              "unavailable" => ["entry_station_block"]
            },
            "station_suppression_station_calendar_provider_entry_ids_by_ground_station" => %{
              "equator_prime" => ["provider_entry_station_block"]
            },
            "station_suppression_station_calendar_provider_entry_ids_by_availability" => %{
              "unavailable" => ["provider_entry_station_block"]
            },
            "station_suppression_station_calendar_provider_entry_ids_by_status" => %{
              "unavailable" => ["provider_entry_station_block"]
            },
            "station_suppression_station_reservation_ids_by_ground_station" => %{
              "equator_prime" => ["reservation_station_block"]
            },
            "station_suppression_station_reservation_ids_by_availability" => %{
              "unavailable" => ["reservation_station_block"]
            },
            "station_suppression_station_reservation_ids_by_status" => %{
              "unavailable" => ["reservation_station_block"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.contact_filter_replay_summary(artifact)

    assert summary["suppressed_candidate_count"] == 0
    assert summary["invalid_contact_input_count"] == 0
    assert summary["invalid_contact_input_ids"] == ["bad_contact"]
    assert summary["suppressed_reason_counts"] == %{"ground_station_unavailable" => 1}

    assert summary["contact_ids_by_suppressed_reason"] == %{
             "ground_station_unavailable" => ["dl_station_block"]
           }

    assert summary["direction_counts"] == %{"downlink" => 1}
    assert summary["contact_ids_by_direction"] == %{"downlink" => ["dl_station_block"]}
    assert summary["station_suppression_count"] == 0
    assert summary["station_suppression_ground_station_counts"] == %{"equator_prime" => 1}
    assert summary["station_suppression_availability_counts"] == %{"unavailable" => 1}
    assert summary["station_suppression_status_counts"] == %{"unavailable" => 1}

    assert summary["station_suppression_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["dl_station_block"]
           }

    assert summary["station_suppression_contact_ids_by_availability"] == %{
             "unavailable" => ["dl_station_block"]
           }

    assert summary["station_suppression_contact_ids_by_status"] == %{
             "unavailable" => ["dl_station_block"]
           }

    assert summary["station_suppression_station_calendar_entry_ids_by_ground_station"] == %{
             "equator_prime" => ["entry_station_block"]
           }

    assert summary["station_suppression_station_calendar_entry_ids_by_availability"] == %{
             "unavailable" => ["entry_station_block"]
           }

    assert summary["station_suppression_station_calendar_entry_ids_by_status"] == %{
             "unavailable" => ["entry_station_block"]
           }

    assert summary["station_suppression_station_calendar_provider_entry_ids_by_ground_station"] ==
             %{
               "equator_prime" => ["provider_entry_station_block"]
             }

    assert summary["station_suppression_station_calendar_provider_entry_ids_by_availability"] ==
             %{
               "unavailable" => ["provider_entry_station_block"]
             }

    assert summary["station_suppression_station_calendar_provider_entry_ids_by_status"] == %{
             "unavailable" => ["provider_entry_station_block"]
           }

    assert summary["station_suppression_station_reservation_ids_by_ground_station"] == %{
             "equator_prime" => ["reservation_station_block"]
           }

    assert summary["station_suppression_station_reservation_ids_by_availability"] == %{
             "unavailable" => ["reservation_station_block"]
           }

    assert summary["station_suppression_station_reservation_ids_by_status"] == %{
             "unavailable" => ["reservation_station_block"]
           }

    assert summary["branch_local_contact_filter_pressure"]
    assert summary["branch_local_candidate_suppression_pressure"]
    assert summary["branch_local_invalid_contact_input_pressure"]
    assert summary["branch_local_station_suppression_pressure"]
  end

  test "contact filter replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.contact_filter_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_contact_filter_contract")
    refute Map.has_key?(source_summary, "source_report_contact_filter_count")
    refute Map.has_key?(source_summary, "source_report_contact_filter_row_count")
    refute Map.has_key?(source_summary, "source_report_contact_filter_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_contact_filter_pressure"]
  end

  test "contact filter source summary omits missing identity counts for partial family placeholder" do
    partial_summaries = [
      %{"contract" => "contact_filter_report.v1"},
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.contact_filter_report"]},
      %{"count" => nil, "row_count" => nil},
      %{
        "count" => nil,
        "row_count" => nil,
        "paths" => ["provenance.source_reports.contact_filter_report"]
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "contact_filter_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      if Map.has_key?(partial_summary, "contract") do
        assert source_summary["source_report_contact_filter_contract"] ==
                 "contact_filter_report.v1"
      else
        refute Map.has_key?(source_summary, "source_report_contact_filter_contract")
      end

      refute Map.has_key?(source_summary, "source_report_contact_filter_count")
      refute Map.has_key?(source_summary, "source_report_contact_filter_row_count")
      refute Map.has_key?(source_summary, "source_report_contact_filter_paths")
    end
  end

  test "contact filter source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_filter_report" => %{
            "contract" => "contact_filter_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.contact_filter_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_contact_filter_contract"] ==
             "contact_filter_report.v1"

    assert source_summary["source_report_contact_filter_count"] == 0
    assert source_summary["source_report_contact_filter_row_count"] == 0

    assert source_summary["source_report_contact_filter_paths"] == [
             "provenance.source_reports.contact_filter_report"
           ]
  end

  test "contact filter source summary omits missing identity paths after preserving counts" do
    partial_summaries = [
      %{
        "contract" => "contact_filter_report.v1",
        "count" => 1,
        "row_count" => 2
      },
      %{
        "contract" => "contact_filter_report.v1",
        "count" => 1,
        "row_count" => 2,
        "paths" => nil
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "contact_filter_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)
      replay_summary = CandidateRefresh.contact_filter_replay_summary(artifact)

      assert source_summary["source_report_contact_filter_contract"] ==
               "contact_filter_report.v1"

      assert source_summary["source_report_contact_filter_count"] == 1
      assert source_summary["source_report_contact_filter_row_count"] == 2
      refute Map.has_key?(source_summary, "source_report_contact_filter_paths")

      assert replay_summary["contract"] == "contact_filter_report.v1"
      assert replay_summary["source_report_count"] == 1
      assert replay_summary["source_report_row_count"] == 2
      assert replay_summary["source_report_paths"] == []
    end
  end

  test "contact filter source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_filter_report" => %{
            "contract" => "contact_filter_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.contact_filter_replay_summary(artifact)

    assert source_summary["source_report_contact_filter_contract"] ==
             "contact_filter_report.v1"

    assert source_summary["source_report_contact_filter_count"] == 1
    assert source_summary["source_report_contact_filter_row_count"] == 2
    assert Map.has_key?(source_summary, "source_report_contact_filter_paths")
    assert source_summary["source_report_contact_filter_paths"] == []

    assert replay_summary["contract"] == "contact_filter_report.v1"
    assert replay_summary["source_report_count"] == 1
    assert replay_summary["source_report_row_count"] == 2
    assert replay_summary["source_report_paths"] == []
  end

  test "contact filter replay preserves suppression and station maps with partial identity" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_filter_report" => %{
            "contract" => "contact_filter_report.v1",
            "count" => 1,
            "suppressed_reason_counts" => %{"ground_station_unavailable" => 1},
            "contact_ids_by_suppressed_reason" => %{
              "ground_station_unavailable" => ["filtered_contact"]
            },
            "invalid_contact_input_ids" => ["invalid_contact"],
            "direction_counts" => %{"downlink" => 1},
            "directions" => ["downlink"],
            "contact_ids_by_direction" => %{"downlink" => ["filtered_contact"]},
            "direction_routing" => %{
              "downlink" => %{
                "contact_count" => 1,
                "contact_ids" => ["filtered_contact"]
              }
            },
            "station_suppression_ground_station_counts" => %{"equator_prime" => 1},
            "station_suppression_availability_counts" => %{"unavailable" => 1},
            "station_suppression_status_counts" => %{"unavailable" => 1},
            "station_suppression_contact_ids_by_ground_station" => %{
              "equator_prime" => ["filtered_contact"]
            },
            "station_suppression_station_calendar_entry_ids_by_ground_station" => %{
              "equator_prime" => ["station_entry"]
            },
            "station_suppression_station_calendar_provider_entry_ids_by_ground_station" => %{
              "equator_prime" => ["provider_entry"]
            },
            "station_suppression_station_reservation_ids_by_ground_station" => %{
              "equator_prime" => ["reservation"]
            }
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.contact_filter_replay_summary(artifact)

    assert source_summary["source_report_contact_filter_contract"] ==
             "contact_filter_report.v1"

    refute Map.has_key?(source_summary, "source_report_contact_filter_count")
    refute Map.has_key?(source_summary, "source_report_contact_filter_row_count")
    refute Map.has_key?(source_summary, "source_report_contact_filter_paths")

    assert source_summary["source_report_contact_filter_suppressed_reason_counts"] == %{
             "ground_station_unavailable" => 1
           }

    assert source_summary["source_report_contact_filter_contact_ids_by_suppressed_reason"] == %{
             "ground_station_unavailable" => ["filtered_contact"]
           }

    assert source_summary["source_report_contact_filter_invalid_contact_input_ids"] == [
             "invalid_contact"
           ]

    assert source_summary["source_report_contact_filter_direction_counts"] == %{"downlink" => 1}
    assert source_summary["source_report_contact_filter_directions"] == ["downlink"]

    assert source_summary["source_report_contact_filter_contact_ids_by_direction"] == %{
             "downlink" => ["filtered_contact"]
           }

    assert source_summary["source_report_contact_filter_direction_routing"] == %{
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["filtered_contact"]
             }
           }

    assert source_summary[
             "source_report_contact_filter_station_suppression_ground_station_counts"
           ] ==
             %{"equator_prime" => 1}

    assert source_summary["source_report_contact_filter_station_suppression_availability_counts"] ==
             %{"unavailable" => 1}

    assert source_summary["source_report_contact_filter_station_suppression_status_counts"] == %{
             "unavailable" => 1
           }

    assert source_summary[
             "source_report_contact_filter_station_suppression_contact_ids_by_ground_station"
           ] == %{"equator_prime" => ["filtered_contact"]}

    assert source_summary[
             "source_report_contact_filter_station_suppression_station_calendar_entry_ids_by_ground_station"
           ] == %{"equator_prime" => ["station_entry"]}

    assert source_summary[
             "source_report_contact_filter_station_suppression_station_calendar_provider_entry_ids_by_ground_station"
           ] == %{"equator_prime" => ["provider_entry"]}

    assert source_summary[
             "source_report_contact_filter_station_suppression_station_reservation_ids_by_ground_station"
           ] == %{"equator_prime" => ["reservation"]}

    assert replay_summary["contract"] == "contact_filter_report.v1"
    assert replay_summary["source_report_count"] == 1
    assert replay_summary["source_report_row_count"] == 0
    assert replay_summary["source_report_paths"] == []
    assert replay_summary["suppressed_reason_counts"] == %{"ground_station_unavailable" => 1}

    assert replay_summary["contact_ids_by_suppressed_reason"] == %{
             "ground_station_unavailable" => ["filtered_contact"]
           }

    assert replay_summary["invalid_contact_input_ids"] == ["invalid_contact"]
    assert replay_summary["direction_counts"] == %{"downlink" => 1}
    assert replay_summary["directions"] == ["downlink"]
    assert replay_summary["contact_ids_by_direction"] == %{"downlink" => ["filtered_contact"]}

    assert replay_summary["direction_routing"] == %{
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["filtered_contact"]
             }
           }

    assert replay_summary["station_suppression_ground_station_counts"] == %{
             "equator_prime" => 1
           }

    assert replay_summary["station_suppression_availability_counts"] == %{"unavailable" => 1}
    assert replay_summary["station_suppression_status_counts"] == %{"unavailable" => 1}

    assert replay_summary["station_suppression_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["filtered_contact"]
           }

    assert replay_summary[
             "station_suppression_station_calendar_entry_ids_by_ground_station"
           ] == %{"equator_prime" => ["station_entry"]}

    assert replay_summary[
             "station_suppression_station_calendar_provider_entry_ids_by_ground_station"
           ] == %{"equator_prime" => ["provider_entry"]}

    assert replay_summary["station_suppression_station_reservation_ids_by_ground_station"] == %{
             "equator_prime" => ["reservation"]
           }

    assert replay_summary["branch_local_contact_filter_pressure"]
    assert replay_summary["branch_local_candidate_suppression_pressure"]
    assert replay_summary["branch_local_invalid_contact_input_pressure"]
    assert replay_summary["branch_local_station_suppression_pressure"]
  end

  test "contact filter replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "contact_filter_report" => %{
              "contract" => "contact_filter_report.v1",
              "count" => 1,
              "row_count" => 3,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_contact_filter_report"
              ],
              "suppressed_candidate_count" => 2,
              "invalid_contact_input_count" => 1,
              "invalid_contact_input_ids" => ["bad_branch_contact"],
              "suppressed_reason_counts" => %{"ground_station_unavailable" => 2},
              "contact_ids_by_suppressed_reason" => %{
                "ground_station_unavailable" => ["branch_downlink", "branch_tracking"]
              },
              "direction_counts" => %{"downlink" => 1, "tracking" => 1},
              "directions" => ["downlink", "tracking"],
              "contact_ids_by_direction" => %{
                "downlink" => ["branch_downlink"],
                "tracking" => ["branch_tracking"]
              },
              "direction_routing" => %{
                "downlink" => %{
                  "contact_count" => 1,
                  "contact_ids" => ["branch_downlink"]
                }
              },
              "station_suppression_count" => 1,
              "station_suppression_ground_station_counts" => %{"equator_prime" => 1},
              "station_suppression_availability_counts" => %{"unavailable" => 1},
              "station_suppression_status_counts" => %{"unavailable" => 1},
              "station_suppression_contact_ids_by_ground_station" => %{
                "equator_prime" => ["branch_downlink"]
              },
              "station_suppression_contact_ids_by_availability" => %{
                "unavailable" => ["branch_downlink"]
              },
              "station_suppression_contact_ids_by_status" => %{
                "unavailable" => ["branch_downlink"]
              },
              "station_suppression_station_calendar_entry_ids_by_ground_station" => %{
                "equator_prime" => ["entry_branch"]
              },
              "station_suppression_station_calendar_entry_ids_by_availability" => %{
                "unavailable" => ["entry_branch"]
              },
              "station_suppression_station_calendar_entry_ids_by_status" => %{
                "unavailable" => ["entry_branch"]
              },
              "station_suppression_station_calendar_provider_entry_ids_by_ground_station" => %{
                "equator_prime" => ["provider_branch"]
              },
              "station_suppression_station_calendar_provider_entry_ids_by_availability" => %{
                "unavailable" => ["provider_branch"]
              },
              "station_suppression_station_calendar_provider_entry_ids_by_status" => %{
                "unavailable" => ["provider_branch"]
              },
              "station_suppression_station_reservation_ids_by_ground_station" => %{
                "equator_prime" => ["reservation_branch"]
              },
              "station_suppression_station_reservation_ids_by_availability" => %{
                "unavailable" => ["reservation_branch"]
              },
              "station_suppression_station_reservation_ids_by_status" => %{
                "unavailable" => ["reservation_branch"]
              },
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_contact_filter"]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "contact_filter_report" => %{
            "contract" => "contact_filter_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_contact_filter_report"],
            "suppressed_candidate_count" => 99,
            "contact_ids_by_suppressed_reason" => %{
              "provenance_reason" => ["provenance_contact"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.contact_filter_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_filter_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 3

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_contact_filter_report"
           ]

    assert summary["suppressed_candidate_count"] == 2
    assert summary["invalid_contact_input_count"] == 1
    assert summary["invalid_contact_input_ids"] == ["bad_branch_contact"]
    assert summary["suppressed_reason_counts"] == %{"ground_station_unavailable" => 2}

    assert summary["contact_ids_by_suppressed_reason"] == %{
             "ground_station_unavailable" => ["branch_downlink", "branch_tracking"]
           }

    assert summary["direction_counts"] == %{"downlink" => 1, "tracking" => 1}
    assert summary["directions"] == ["downlink", "tracking"]

    assert summary["contact_ids_by_direction"] == %{
             "downlink" => ["branch_downlink"],
             "tracking" => ["branch_tracking"]
           }

    assert summary["direction_routing"] == %{
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["branch_downlink"]
             }
           }

    assert summary["station_suppression_count"] == 1
    assert summary["station_suppression_ground_station_counts"] == %{"equator_prime" => 1}
    assert summary["station_suppression_availability_counts"] == %{"unavailable" => 1}
    assert summary["station_suppression_status_counts"] == %{"unavailable" => 1}

    assert summary["station_suppression_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["branch_downlink"]
           }

    assert summary["station_suppression_contact_ids_by_availability"] == %{
             "unavailable" => ["branch_downlink"]
           }

    assert summary["station_suppression_contact_ids_by_status"] == %{
             "unavailable" => ["branch_downlink"]
           }

    assert summary["station_suppression_station_calendar_entry_ids_by_ground_station"] == %{
             "equator_prime" => ["entry_branch"]
           }

    assert summary["station_suppression_station_calendar_entry_ids_by_availability"] == %{
             "unavailable" => ["entry_branch"]
           }

    assert summary["station_suppression_station_calendar_entry_ids_by_status"] == %{
             "unavailable" => ["entry_branch"]
           }

    assert summary["station_suppression_station_calendar_provider_entry_ids_by_ground_station"] ==
             %{"equator_prime" => ["provider_branch"]}

    assert summary["station_suppression_station_calendar_provider_entry_ids_by_availability"] ==
             %{"unavailable" => ["provider_branch"]}

    assert summary["station_suppression_station_calendar_provider_entry_ids_by_status"] ==
             %{"unavailable" => ["provider_branch"]}

    assert summary["station_suppression_station_reservation_ids_by_ground_station"] == %{
             "equator_prime" => ["reservation_branch"]
           }

    assert summary["station_suppression_station_reservation_ids_by_availability"] == %{
             "unavailable" => ["reservation_branch"]
           }

    assert summary["station_suppression_station_reservation_ids_by_status"] == %{
             "unavailable" => ["reservation_branch"]
           }

    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_contact_filter"]
    assert summary["branch_local_contact_filter_pressure"]
    assert summary["branch_local_candidate_suppression_pressure"]
    assert summary["branch_local_invalid_contact_input_pressure"]
    assert summary["branch_local_station_suppression_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_filter_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_contact_filter_replay_summary(artifact) ==
             summary
  end

  test "contact filter replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "contact_filter_report" => %{
            "contract" => "contact_filter_report.v1",
            "count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_contact_filter_report"
            ],
            "contact_ids_by_direction" => %{
              "downlink" => ["direct_branch_contact"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.contact_filter_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_filter_report"

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_contact_filter_report"
           ]

    assert summary["contact_ids_by_direction"] == %{
             "downlink" => ["direct_branch_contact"]
           }

    assert summary["branch_local_contact_filter_pressure"]
    assert summary["branch_local_candidate_suppression_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_filter_candidate_source_report_summary_only"
  end

  test "contact filter replay falls back when branch summary is empty" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "contact_filter_report" => %{},
            "link_capacity_report" => %{
              "contract" => "link_capacity_report.v1",
              "count" => 1
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "contact_filter_report" => %{
            "contract" => "contact_filter_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_contact_filter_report"],
            "invalid_contact_input_count" => 1,
            "invalid_contact_input_ids" => ["provenance_bad_contact"]
          }
        }
      }
    }

    summary = CandidateRefresh.contact_filter_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.contact_filter_report"

    assert summary["source_report_paths"] == ["source_contact_filter_report"]
    assert summary["invalid_contact_input_count"] == 1
    assert summary["invalid_contact_input_ids"] == ["provenance_bad_contact"]
    assert summary["branch_local_contact_filter_pressure"]
    assert summary["branch_local_invalid_contact_input_pressure"]
    refute summary["branch_local_candidate_suppression_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_filter_source_report_provenance_only"
  end

  test "contact filter replay falls back when branch family is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "link_capacity_report" => %{
              "contract" => "link_capacity_report.v1",
              "count" => 1
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "contact_filter_report" => %{
            "contract" => "contact_filter_report.v1",
            "count" => 1,
            "paths" => ["source_contact_filter_report"],
            "contact_ids_by_direction" => %{
              "downlink" => ["provenance_contact"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.contact_filter_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.contact_filter_report"

    assert summary["source_report_paths"] == ["source_contact_filter_report"]

    assert summary["contact_ids_by_direction"] == %{
             "downlink" => ["provenance_contact"]
           }

    assert summary["branch_local_contact_filter_pressure"]
    assert summary["branch_local_candidate_suppression_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_filter_source_report_provenance_only"
  end

  test "contact filter replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "contact_filter_report" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_contact_filter_report"
              ],
              "station_suppression_contact_ids_by_ground_station" => %{
                "equator_prime" => ["partial_branch_contact"]
              }
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "contact_filter_report" => %{
            "contract" => "contact_filter_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_contact_filter_report"],
            "suppressed_candidate_count" => 9,
            "station_suppression_contact_ids_by_ground_station" => %{
              "dss_43" => ["provenance_contact"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.contact_filter_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_filter_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_contact_filter_report"
           ]

    assert summary["suppressed_candidate_count"] == 0

    assert summary["station_suppression_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["partial_branch_contact"]
           }

    assert summary["branch_local_contact_filter_pressure"]
    refute summary["branch_local_candidate_suppression_pressure"]
    refute summary["branch_local_invalid_contact_input_pressure"]
    assert summary["branch_local_station_suppression_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_filter_candidate_source_report_summary_only"
  end
end
