defmodule OrbitalDynamics.CandidateRefresh.ContactAllocationCapacityPackDemandReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary aggregates contact allocation capacity-pack demand" do
    refresh = %{
      "source_contact_allocation_report" => %{
        "schema_contract" => "contact_allocation_report.v1",
        "rows" => [
          %{
            "contact_id" => "selected_contact",
            "direction" => "downlink",
            "allocation_status" => "allocated",
            "effective_allocation_status" => "allocated",
            "capacity_pack_status" => "selected_by_reduced_station_capacity_pack",
            "ground_station_id" => "equator_prime",
            "required_capacity_fraction" => 0.25,
            "required_capacity_fraction_source" => "contact_required_capacity_fraction"
          },
          %{
            "contact_id" => "deferred_contact",
            "direction" => "Down Link",
            "allocation_status" => "deferred",
            "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
            "ground_station_id" => "equator_prime",
            "required_capacity_fraction" => 0.35,
            "required_capacity_fraction_source" => "capacity_model"
          },
          %{
            "contact_id" => "station_pressure_contact",
            "direction" => "s-band command",
            "allocation_status" => "allocated",
            "effective_allocation_status" => "allocated",
            "review_status" => "operator_review_required",
            "ground_station_id" => "polar_prime",
            "station_calendar_overlap_count" => 1,
            "station_calendar_overlap_availabilities" => ["reserved"],
            "station_calendar_precedence_availability" => "reduced_capacity",
            "station_calendar_precedence_rank" => 2,
            "station_calendar_status" => "maintenance_window"
          },
          %{
            "contact_id" => "blocked_contact",
            "direction" => "tracking",
            "allocation_status" => "blocked",
            "ground_station_id" => "polar_prime"
          },
          %{
            "contact_id" => "policy_blocked_contact",
            "direction" => "uplink",
            "allocation_status" => "allocated",
            "effective_allocation_status" => "policy_blocked",
            "ground_station_id" => "dss_43"
          }
        ],
        "reduced_capacity_pack_groups" => [
          %{
            "contention_group_id" => "pack_equator_prime",
            "pack_status" => "capacity_limited",
            "used_capacity_fraction" => 0.6,
            "selected_contact_ids" => ["selected_contact"],
            "deferred_contact_ids" => ["deferred_contact"]
          }
        ],
        "capacity_pack_required_capacity_fraction" => 99.0,
        "capacity_pack_selected_required_capacity_fraction" => 99.0,
        "capacity_pack_deferred_required_capacity_fraction" => 99.0,
        "capacity_pack_status_counts" => %{
          "stale_capacity_pack_status" => 99
        },
        "allocation_status_counts" => %{
          "stale_allocation_status" => 99
        },
        "effective_allocation_status_counts" => %{
          "stale_effective_status" => 99
        },
        "capacity_pack_contact_ids_by_status" => %{
          "stale_capacity_pack_status" => ["stale_contact"]
        },
        "capacity_pack_contact_count" => 99,
        "capacity_pack_required_capacity_fraction_by_status" => %{
          "stale_status" => 99.0
        },
        "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" => %{
          "stale_station" => 99.0
        },
        "capacity_pack_required_capacity_fraction_by_direction" => %{
          "stale_direction" => 99.0
        },
        "capacity_pack_selected_required_capacity_fraction_by_direction" => %{
          "stale_direction" => 99.0
        },
        "capacity_pack_deferred_required_capacity_fraction_by_direction" => %{
          "stale_direction" => 99.0
        },
        "capacity_pack_selected_contact_ids_by_ground_station_id" => %{
          "stale_station" => ["stale_selected_contact"]
        },
        "capacity_pack_deferred_contact_ids_by_ground_station_id" => %{
          "stale_station" => ["stale_deferred_contact"]
        },
        "capacity_pack_contact_ids_by_ground_station_id" => %{
          "stale_station" => ["stale_capacity_pack_contact"]
        },
        "capacity_pack_selected_contact_ids_by_direction" => %{
          "stale_direction" => ["stale_selected_contact"]
        },
        "capacity_pack_deferred_contact_ids_by_direction" => %{
          "stale_direction" => ["stale_deferred_contact"]
        },
        "capacity_pack_contact_ids_by_direction" => %{
          "stale_direction" => ["stale_capacity_pack_contact"]
        },
        "required_capacity_fraction_contact_ids_by_source" => %{
          "stale_source" => ["stale_contact"]
        },
        "required_capacity_fraction_source_counts" => %{
          "stale_source" => 99
        },
        "reduced_capacity_packed_contact_ids" => ["stale_packed_contact"],
        "reduced_capacity_deferred_contact_ids" => ["stale_deferred_contact"],
        "allocated_contact_count" => 99,
        "allocated_contact_ids" => ["stale_allocated_contact"],
        "allocated_contact_ids_by_ground_station_id" => %{
          "stale_station" => ["stale_allocated_contact"]
        },
        "returned_allocated_contact_count" => 99,
        "returned_allocated_contact_ids" => ["stale_returned_allocated_contact"],
        "returned_allocated_contact_ids_by_ground_station_id" => %{
          "stale_station" => ["stale_returned_allocated_contact"]
        },
        "deferred_contact_count" => 99,
        "deferred_contact_ids" => ["stale_deferred_contact"],
        "deferred_contact_ids_by_ground_station_id" => %{
          "stale_station" => ["stale_deferred_contact"]
        },
        "blocked_contact_count" => 99,
        "blocked_contact_ids" => ["stale_blocked_contact"],
        "blocked_contact_ids_by_ground_station_id" => %{
          "stale_station" => ["stale_blocked_contact"]
        },
        "policy_blocked_contact_ids" => ["stale_policy_blocked_contact"],
        "policy_blocked_contact_ids_by_ground_station_id" => %{
          "stale_station" => ["stale_policy_blocked_contact"]
        },
        "policy_blocked_allocated_contact_count" => 99,
        "review_contact_ids" => ["stale_review_contact"],
        "station_pressure_contact_ids_by_ground_station_id" => %{
          "stale_station" => ["stale_station_pressure_contact"]
        },
        "station_pressure_contact_ids_by_availability" => %{
          "stale_availability" => ["stale_station_pressure_contact"]
        },
        "station_pressure_contact_ids_by_precedence_availability" => %{
          "stale_precedence_availability" => ["stale_station_pressure_contact"]
        },
        "station_pressure_contact_ids_by_precedence_rank" => %{
          "99" => ["stale_station_pressure_contact"]
        },
        "station_pressure_contact_ids_by_status" => %{
          "stale_status" => ["stale_station_pressure_contact"]
        },
        "station_pressure_review_contact_count" => 99,
        "station_pressure_review_contact_ids" => ["stale_station_pressure_review_contact"],
        "provenance" => %{"trust_boundary" => "ops_contact_allocation"}
      }
    }

    expected_direction_routing = %{
      "command" => %{
        "contact_count" => 1,
        "contact_ids" => ["station_pressure_contact"],
        "station_pressure_contact_count" => 1,
        "station_pressure_contact_ids" => ["station_pressure_contact"],
        "reservation_conflict_contact_ids" => [],
        "provider_reservation_no_request_contact_ids" => [],
        "provider_reservation_request_contact_ids" => [],
        "provider_reservation_review_contact_ids" => []
      },
      "downlink" => %{
        "contact_count" => 2,
        "contact_ids" => ["deferred_contact", "selected_contact"],
        "station_pressure_contact_ids" => [],
        "reservation_conflict_contact_ids" => [],
        "provider_reservation_no_request_contact_ids" => [],
        "provider_reservation_request_contact_ids" => [],
        "provider_reservation_review_contact_ids" => []
      },
      "tracking" => %{
        "contact_count" => 1,
        "contact_ids" => ["blocked_contact"],
        "station_pressure_contact_ids" => [],
        "reservation_conflict_contact_ids" => [],
        "provider_reservation_no_request_contact_ids" => [],
        "provider_reservation_request_contact_ids" => [],
        "provider_reservation_review_contact_ids" => []
      },
      "uplink" => %{
        "contact_count" => 1,
        "contact_ids" => ["policy_blocked_contact"],
        "station_pressure_contact_ids" => [],
        "reservation_conflict_contact_ids" => [],
        "provider_reservation_no_request_contact_ids" => [],
        "provider_reservation_request_contact_ids" => [],
        "provider_reservation_review_contact_ids" => []
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_contact_allocation_contract" => "contact_allocation_report.v1",
             "source_report_contact_allocation_count" => 1,
             "source_report_contact_allocation_row_count" => 5,
             "source_report_contact_allocation_paths" => ["source_contact_allocation_report"],
             "source_report_contact_allocation_blocked_row_count" => 2,
             "source_report_contact_allocation_deferred_row_count" => 1,
             "source_report_contact_allocation_capacity_pack_required_capacity_fraction" => 0.6,
             "source_report_contact_allocation_capacity_pack_selected_required_capacity_fraction" =>
               0.25,
             "source_report_contact_allocation_capacity_pack_deferred_required_capacity_fraction" =>
               0.35,
             "source_report_contact_allocation_capacity_pack_required_capacity_fraction_by_status" =>
               %{
                 "deferred_by_reduced_station_capacity_pack" => 0.35,
                 "selected_by_reduced_station_capacity_pack" => 0.25
               },
             "source_report_contact_allocation_capacity_pack_required_capacity_fraction_by_ground_station" =>
               %{"equator_prime" => 0.6},
             "source_report_contact_allocation_capacity_pack_selected_required_capacity_fraction_by_ground_station" =>
               %{"equator_prime" => 0.25},
             "source_report_contact_allocation_capacity_pack_deferred_required_capacity_fraction_by_ground_station" =>
               %{"equator_prime" => 0.35},
             "source_report_contact_allocation_capacity_pack_required_capacity_fraction_by_direction" =>
               %{"downlink" => 0.6},
             "source_report_contact_allocation_capacity_pack_selected_required_capacity_fraction_by_direction" =>
               %{"downlink" => 0.25},
             "source_report_contact_allocation_capacity_pack_deferred_required_capacity_fraction_by_direction" =>
               %{"downlink" => 0.35},
             "source_report_contact_allocation_capacity_pack_selected_contact_ids_by_ground_station" =>
               %{"equator_prime" => ["selected_contact"]},
             "source_report_contact_allocation_capacity_pack_deferred_contact_ids_by_ground_station" =>
               %{"equator_prime" => ["deferred_contact"]},
             "source_report_contact_allocation_capacity_pack_contact_ids_by_ground_station" => %{
               "equator_prime" => ["deferred_contact", "selected_contact"]
             },
             "source_report_contact_allocation_capacity_pack_selected_contact_ids_by_direction" =>
               %{"downlink" => ["selected_contact"]},
             "source_report_contact_allocation_capacity_pack_deferred_contact_ids_by_direction" =>
               %{"downlink" => ["deferred_contact"]},
             "source_report_contact_allocation_capacity_pack_contact_ids_by_direction" => %{
               "downlink" => ["deferred_contact", "selected_contact"]
             },
             "source_report_contact_allocation_capacity_pack_contact_ids_by_status" => %{
               "deferred_by_reduced_station_capacity_pack" => ["deferred_contact"],
               "selected_by_reduced_station_capacity_pack" => ["selected_contact"]
             },
             "source_report_contact_allocation_capacity_pack_status_counts" => %{
               "deferred_by_reduced_station_capacity_pack" => 1,
               "selected_by_reduced_station_capacity_pack" => 1
             },
             "source_report_contact_allocation_capacity_pack_contact_status_counts" => %{
               "deferred_by_reduced_station_capacity_pack" => 1,
               "selected_by_reduced_station_capacity_pack" => 1
             },
             "source_report_contact_allocation_capacity_pack_contact_count" => 2,
             "source_report_contact_allocation_direction_counts" => %{
               "command" => 1,
               "downlink" => 2,
               "tracking" => 1,
               "uplink" => 1
             },
             "source_report_contact_allocation_contact_ids_by_direction" => %{
               "command" => ["station_pressure_contact"],
               "downlink" => ["deferred_contact", "selected_contact"],
               "tracking" => ["blocked_contact"],
               "uplink" => ["policy_blocked_contact"]
             },
             "source_report_contact_allocation_direction_routing" => ^expected_direction_routing,
             "source_report_contact_allocation_allocation_status_counts" => %{
               "allocated" => 3,
               "blocked" => 1,
               "deferred" => 1
             },
             "source_report_contact_allocation_effective_allocation_status_counts" => %{
               "allocated" => 2,
               "blocked" => 1,
               "deferred" => 1,
               "policy_blocked" => 1
             },
             "source_report_contact_allocation_reduced_capacity_pack_group_count" => 1,
             "source_report_contact_allocation_reduced_capacity_pack_status_counts" => %{
               "capacity_limited" => 1
             },
             "source_report_contact_allocation_capacity_pack_group_ids" => [
               "pack_equator_prime"
             ],
             "source_report_contact_allocation_capacity_pack_group_ids_by_status" => %{
               "capacity_limited" => ["pack_equator_prime"]
             },
             "source_report_contact_allocation_required_capacity_fraction_source_counts" => %{
               "capacity_model" => 1,
               "contact_required_capacity_fraction" => 1
             },
             "source_report_contact_allocation_required_capacity_fraction_contact_ids_by_source" =>
               %{
                 "capacity_model" => ["deferred_contact"],
                 "contact_required_capacity_fraction" => ["selected_contact"]
               },
             "source_report_contact_allocation_reduced_capacity_packed_contact_ids" => [
               "selected_contact"
             ],
             "source_report_contact_allocation_reduced_capacity_deferred_contact_ids" => [
               "deferred_contact"
             ],
             "source_report_contact_allocation_allocated_contact_count" => 3,
             "source_report_contact_allocation_allocated_contact_ids" => [
               "policy_blocked_contact",
               "selected_contact",
               "station_pressure_contact"
             ],
             "source_report_contact_allocation_allocated_contact_ids_by_ground_station" => %{
               "dss_43" => ["policy_blocked_contact"],
               "equator_prime" => ["selected_contact"],
               "polar_prime" => ["station_pressure_contact"]
             },
             "source_report_contact_allocation_returned_allocated_contact_ids" => [
               "selected_contact",
               "station_pressure_contact"
             ],
             "source_report_contact_allocation_returned_allocated_contact_count" => 2,
             "source_report_contact_allocation_returned_allocated_contact_ids_by_ground_station" =>
               %{
                 "equator_prime" => ["selected_contact"],
                 "polar_prime" => ["station_pressure_contact"]
               },
             "source_report_contact_allocation_deferred_contact_count" => 1,
             "source_report_contact_allocation_deferred_contact_ids" => ["deferred_contact"],
             "source_report_contact_allocation_deferred_contact_ids_by_ground_station" => %{
               "equator_prime" => ["deferred_contact"]
             },
             "source_report_contact_allocation_blocked_contact_count" => 1,
             "source_report_contact_allocation_blocked_contact_ids" => ["blocked_contact"],
             "source_report_contact_allocation_blocked_contact_ids_by_ground_station" => %{
               "polar_prime" => ["blocked_contact"]
             },
             "source_report_contact_allocation_policy_blocked_contact_ids" => [
               "policy_blocked_contact"
             ],
             "source_report_contact_allocation_policy_blocked_allocated_contact_count" => 1,
             "source_report_contact_allocation_policy_blocked_contact_ids_by_ground_station" => %{
               "dss_43" => ["policy_blocked_contact"]
             },
             "source_report_contact_allocation_review_contact_ids" => [
               "blocked_contact",
               "deferred_contact",
               "policy_blocked_contact",
               "station_pressure_contact"
             ],
             "source_report_contact_allocation_station_pressure_contact_count" => 1,
             "source_report_contact_allocation_station_pressure_contact_ids" => [
               "station_pressure_contact"
             ],
             "source_report_contact_allocation_station_pressure_ground_station_counts" => %{
               "polar_prime" => 1
             },
             "source_report_contact_allocation_station_pressure_contact_ids_by_ground_station" =>
               %{"polar_prime" => ["station_pressure_contact"]},
             "source_report_contact_allocation_station_pressure_availability_counts" => %{
               "reserved" => 1
             },
             "source_report_contact_allocation_station_pressure_contact_ids_by_availability" => %{
               "reserved" => ["station_pressure_contact"]
             },
             "source_report_contact_allocation_station_pressure_precedence_availability_counts" =>
               %{"reduced_capacity" => 1},
             "source_report_contact_allocation_station_pressure_contact_ids_by_precedence_availability" =>
               %{"reduced_capacity" => ["station_pressure_contact"]},
             "source_report_contact_allocation_station_pressure_precedence_rank_counts" => %{
               "2" => 1
             },
             "source_report_contact_allocation_station_pressure_contact_ids_by_precedence_rank" =>
               %{"2" => ["station_pressure_contact"]},
             "source_report_contact_allocation_station_pressure_status_counts" => %{
               "maintenance_window" => 1
             },
             "source_report_contact_allocation_station_pressure_contact_ids_by_status" => %{
               "maintenance_window" => ["station_pressure_contact"]
             },
             "source_report_contact_allocation_station_pressure_direction_counts" => %{
               "command" => 1
             },
             "source_report_contact_allocation_station_pressure_contact_ids_by_direction" => %{
               "command" => ["station_pressure_contact"]
             },
             "source_report_contact_allocation_station_pressure_contact_ids_by_direction_and_ground_station" =>
               %{
                 "command" => %{"polar_prime" => ["station_pressure_contact"]}
               },
             "source_report_contact_allocation_station_pressure_review_contact_count" => 1,
             "source_report_contact_allocation_station_pressure_review_contact_ids" => [
               "station_pressure_contact"
             ],
             "source_reports" => %{
               "contact_allocation_report" => %{
                 "capacity_pack_required_capacity_fraction" => 0.6,
                 "capacity_pack_selected_required_capacity_fraction" => 0.25,
                 "capacity_pack_deferred_required_capacity_fraction" => 0.35,
                 "capacity_pack_selected_contact_ids_by_ground_station" => %{
                   "equator_prime" => ["selected_contact"]
                 },
                 "capacity_pack_deferred_contact_ids_by_ground_station" => %{
                   "equator_prime" => ["deferred_contact"]
                 },
                 "capacity_pack_contact_ids_by_ground_station" => %{
                   "equator_prime" => ["deferred_contact", "selected_contact"]
                 },
                 "capacity_pack_required_capacity_fraction_by_direction" => %{
                   "downlink" => 0.6
                 },
                 "capacity_pack_selected_required_capacity_fraction_by_direction" => %{
                   "downlink" => 0.25
                 },
                 "capacity_pack_deferred_required_capacity_fraction_by_direction" => %{
                   "downlink" => 0.35
                 },
                 "capacity_pack_selected_contact_ids_by_direction" => %{
                   "downlink" => ["selected_contact"]
                 },
                 "capacity_pack_deferred_contact_ids_by_direction" => %{
                   "downlink" => ["deferred_contact"]
                 },
                 "capacity_pack_contact_ids_by_direction" => %{
                   "downlink" => ["deferred_contact", "selected_contact"]
                 },
                 "capacity_pack_contact_ids_by_status" => %{
                   "deferred_by_reduced_station_capacity_pack" => ["deferred_contact"],
                   "selected_by_reduced_station_capacity_pack" => ["selected_contact"]
                 },
                 "capacity_pack_status_counts" => %{
                   "deferred_by_reduced_station_capacity_pack" => 1,
                   "selected_by_reduced_station_capacity_pack" => 1
                 },
                 "capacity_pack_contact_status_counts" => %{
                   "deferred_by_reduced_station_capacity_pack" => 1,
                   "selected_by_reduced_station_capacity_pack" => 1
                 },
                 "capacity_pack_contact_count" => 2,
                 "direction_counts" => %{
                   "command" => 1,
                   "downlink" => 2,
                   "tracking" => 1,
                   "uplink" => 1
                 },
                 "contact_ids_by_direction" => %{
                   "command" => ["station_pressure_contact"],
                   "downlink" => ["deferred_contact", "selected_contact"],
                   "tracking" => ["blocked_contact"],
                   "uplink" => ["policy_blocked_contact"]
                 },
                 "direction_routing" => ^expected_direction_routing,
                 "allocation_status_counts" => %{
                   "allocated" => 3,
                   "blocked" => 1,
                   "deferred" => 1
                 },
                 "effective_allocation_status_counts" => %{
                   "allocated" => 2,
                   "blocked" => 1,
                   "deferred" => 1,
                   "policy_blocked" => 1
                 },
                 "reduced_capacity_pack_group_count" => 1,
                 "reduced_capacity_pack_status_counts" => %{
                   "capacity_limited" => 1
                 },
                 "capacity_pack_group_ids" => ["pack_equator_prime"],
                 "capacity_pack_group_ids_by_status" => %{
                   "capacity_limited" => ["pack_equator_prime"]
                 },
                 "required_capacity_fraction_source_counts" => %{
                   "capacity_model" => 1,
                   "contact_required_capacity_fraction" => 1
                 },
                 "required_capacity_fraction_contact_ids_by_source" => %{
                   "capacity_model" => ["deferred_contact"],
                   "contact_required_capacity_fraction" => ["selected_contact"]
                 },
                 "reduced_capacity_packed_contact_ids" => ["selected_contact"],
                 "reduced_capacity_deferred_contact_ids" => ["deferred_contact"],
                 "allocated_contact_count" => 3,
                 "allocated_contact_ids" => [
                   "policy_blocked_contact",
                   "selected_contact",
                   "station_pressure_contact"
                 ],
                 "allocated_contact_ids_by_ground_station" => %{
                   "dss_43" => ["policy_blocked_contact"],
                   "equator_prime" => ["selected_contact"],
                   "polar_prime" => ["station_pressure_contact"]
                 },
                 "returned_allocated_contact_ids" => [
                   "selected_contact",
                   "station_pressure_contact"
                 ],
                 "returned_allocated_contact_count" => 2,
                 "returned_allocated_contact_ids_by_ground_station" => %{
                   "equator_prime" => ["selected_contact"],
                   "polar_prime" => ["station_pressure_contact"]
                 },
                 "deferred_contact_count" => 1,
                 "deferred_contact_ids" => ["deferred_contact"],
                 "deferred_contact_ids_by_ground_station" => %{
                   "equator_prime" => ["deferred_contact"]
                 },
                 "blocked_contact_count" => 1,
                 "blocked_contact_ids" => ["blocked_contact"],
                 "blocked_contact_ids_by_ground_station" => %{
                   "polar_prime" => ["blocked_contact"]
                 },
                 "policy_blocked_contact_ids" => ["policy_blocked_contact"],
                 "policy_blocked_allocated_contact_count" => 1,
                 "policy_blocked_contact_ids_by_ground_station" => %{
                   "dss_43" => ["policy_blocked_contact"]
                 },
                 "review_contact_ids" => [
                   "blocked_contact",
                   "deferred_contact",
                   "policy_blocked_contact",
                   "station_pressure_contact"
                 ],
                 "station_pressure_contact_ids_by_ground_station" => %{
                   "polar_prime" => ["station_pressure_contact"]
                 },
                 "station_pressure_contact_ids_by_availability" => %{
                   "reserved" => ["station_pressure_contact"]
                 },
                 "station_pressure_contact_ids_by_precedence_availability" => %{
                   "reduced_capacity" => ["station_pressure_contact"]
                 },
                 "station_pressure_contact_ids_by_precedence_rank" => %{
                   "2" => ["station_pressure_contact"]
                 },
                 "station_pressure_status_counts" => %{
                   "maintenance_window" => 1
                 },
                 "station_pressure_contact_ids_by_status" => %{
                   "maintenance_window" => ["station_pressure_contact"]
                 },
                 "station_pressure_direction_counts" => %{
                   "command" => 1
                 },
                 "station_pressure_contact_ids_by_direction" => %{
                   "command" => ["station_pressure_contact"]
                 },
                 "station_pressure_contact_ids_by_direction_and_ground_station" => %{
                   "command" => %{"polar_prime" => ["station_pressure_contact"]}
                 },
                 "station_pressure_contact_count" => 1,
                 "station_pressure_review_contact_count" => 1,
                 "station_pressure_review_contact_ids" => ["station_pressure_contact"]
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = %{
      "model" => "artifact_only_candidate_refresh_contact_allocation_replay_summary",
      "source" => "candidate_refresh.source_report_provenance.contact_allocation_report",
      "contract" => "contact_allocation_report.v1",
      "source_report_count" => 1,
      "source_report_row_count" => 5,
      "source_report_paths" => ["source_contact_allocation_report"],
      "blocked_row_count" => 2,
      "deferred_row_count" => 1,
      "allocation_status_counts" => %{
        "allocated" => 3,
        "blocked" => 1,
        "deferred" => 1
      },
      "effective_allocation_status_counts" => %{
        "allocated" => 2,
        "blocked" => 1,
        "deferred" => 1,
        "policy_blocked" => 1
      },
      "allocation_reason_counts" => %{},
      "capacity_pack_status_counts" => %{
        "deferred_by_reduced_station_capacity_pack" => 1,
        "selected_by_reduced_station_capacity_pack" => 1
      },
      "capacity_pack_contact_status_counts" => %{
        "deferred_by_reduced_station_capacity_pack" => 1,
        "selected_by_reduced_station_capacity_pack" => 1
      },
      "capacity_pack_required_capacity_fraction" => 0.6,
      "capacity_pack_selected_required_capacity_fraction" => 0.25,
      "capacity_pack_deferred_required_capacity_fraction" => 0.35,
      "capacity_pack_required_capacity_fraction_by_status" => %{
        "deferred_by_reduced_station_capacity_pack" => 0.35,
        "selected_by_reduced_station_capacity_pack" => 0.25
      },
      "capacity_pack_required_capacity_fraction_by_ground_station" => %{
        "equator_prime" => 0.6
      },
      "capacity_pack_selected_required_capacity_fraction_by_ground_station" => %{
        "equator_prime" => 0.25
      },
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station" => %{
        "equator_prime" => 0.35
      },
      "capacity_pack_required_capacity_fraction_by_direction" => %{
        "downlink" => 0.6
      },
      "capacity_pack_selected_required_capacity_fraction_by_direction" => %{
        "downlink" => 0.25
      },
      "capacity_pack_deferred_required_capacity_fraction_by_direction" => %{
        "downlink" => 0.35
      },
      "capacity_pack_selected_contact_ids_by_ground_station" => %{
        "equator_prime" => ["selected_contact"]
      },
      "capacity_pack_deferred_contact_ids_by_ground_station" => %{
        "equator_prime" => ["deferred_contact"]
      },
      "capacity_pack_contact_ids_by_ground_station" => %{
        "equator_prime" => ["deferred_contact", "selected_contact"]
      },
      "capacity_pack_selected_contact_ids_by_direction" => %{
        "downlink" => ["selected_contact"]
      },
      "capacity_pack_deferred_contact_ids_by_direction" => %{
        "downlink" => ["deferred_contact"]
      },
      "capacity_pack_contact_ids_by_direction" => %{
        "downlink" => ["deferred_contact", "selected_contact"]
      },
      "capacity_pack_contact_ids_by_status" => %{
        "deferred_by_reduced_station_capacity_pack" => ["deferred_contact"],
        "selected_by_reduced_station_capacity_pack" => ["selected_contact"]
      },
      "capacity_pack_contact_count" => 2,
      "direction_counts" => %{
        "command" => 1,
        "downlink" => 2,
        "tracking" => 1,
        "uplink" => 1
      },
      "contact_ids_by_direction" => %{
        "command" => ["station_pressure_contact"],
        "downlink" => ["deferred_contact", "selected_contact"],
        "tracking" => ["blocked_contact"],
        "uplink" => ["policy_blocked_contact"]
      },
      "direction_routing" => expected_direction_routing,
      "reduced_capacity_pack_group_count" => 1,
      "reduced_capacity_pack_status_counts" => %{"capacity_limited" => 1},
      "capacity_pack_group_ids" => ["pack_equator_prime"],
      "capacity_pack_group_ids_by_status" => %{
        "capacity_limited" => ["pack_equator_prime"]
      },
      "required_capacity_fraction_source_counts" => %{
        "capacity_model" => 1,
        "contact_required_capacity_fraction" => 1
      },
      "required_capacity_fraction_contact_ids_by_source" => %{
        "capacity_model" => ["deferred_contact"],
        "contact_required_capacity_fraction" => ["selected_contact"]
      },
      "reduced_capacity_packed_contact_ids" => ["selected_contact"],
      "reduced_capacity_deferred_contact_ids" => ["deferred_contact"],
      "allocated_contact_count" => 3,
      "allocated_contact_ids" => [
        "policy_blocked_contact",
        "selected_contact",
        "station_pressure_contact"
      ],
      "allocated_contact_ids_by_ground_station" => %{
        "dss_43" => ["policy_blocked_contact"],
        "equator_prime" => ["selected_contact"],
        "polar_prime" => ["station_pressure_contact"]
      },
      "returned_allocated_contact_count" => 2,
      "returned_allocated_contact_ids" => ["selected_contact", "station_pressure_contact"],
      "returned_allocated_contact_ids_by_ground_station" => %{
        "equator_prime" => ["selected_contact"],
        "polar_prime" => ["station_pressure_contact"]
      },
      "deferred_contact_count" => 1,
      "deferred_contact_ids" => ["deferred_contact"],
      "deferred_contact_ids_by_ground_station" => %{
        "equator_prime" => ["deferred_contact"]
      },
      "blocked_contact_count" => 1,
      "blocked_contact_ids" => ["blocked_contact"],
      "blocked_contact_ids_by_ground_station" => %{
        "polar_prime" => ["blocked_contact"]
      },
      "policy_blocked_allocated_contact_count" => 1,
      "policy_blocked_contact_ids" => ["policy_blocked_contact"],
      "policy_blocked_contact_ids_by_ground_station" => %{
        "dss_43" => ["policy_blocked_contact"]
      },
      "review_contact_ids" => [
        "blocked_contact",
        "deferred_contact",
        "policy_blocked_contact",
        "station_pressure_contact"
      ],
      "station_pressure_contact_count" => 1,
      "station_pressure_contact_ids" => ["station_pressure_contact"],
      "station_pressure_review_contact_count" => 1,
      "station_pressure_review_contact_ids" => ["station_pressure_contact"],
      "station_pressure_ground_station_counts" => %{"polar_prime" => 1},
      "station_pressure_contact_ids_by_ground_station" => %{
        "polar_prime" => ["station_pressure_contact"]
      },
      "station_pressure_availability_counts" => %{"reserved" => 1},
      "station_pressure_contact_ids_by_availability" => %{
        "reserved" => ["station_pressure_contact"]
      },
      "station_pressure_precedence_availability_counts" => %{"reduced_capacity" => 1},
      "station_pressure_contact_ids_by_precedence_availability" => %{
        "reduced_capacity" => ["station_pressure_contact"]
      },
      "station_pressure_precedence_rank_counts" => %{"2" => 1},
      "station_pressure_contact_ids_by_precedence_rank" => %{
        "2" => ["station_pressure_contact"]
      },
      "station_pressure_status_counts" => %{"maintenance_window" => 1},
      "station_pressure_contact_ids_by_status" => %{
        "maintenance_window" => ["station_pressure_contact"]
      },
      "station_pressure_direction_counts" => %{"command" => 1},
      "station_pressure_contact_ids_by_direction" => %{
        "command" => ["station_pressure_contact"]
      },
      "station_pressure_contact_ids_by_direction_and_ground_station" => %{
        "command" => %{"polar_prime" => ["station_pressure_contact"]}
      },
      "trust_boundary_status" => "declared",
      "trust_boundaries" => ["ops_contact_allocation"],
      "branch_local_contact_allocation_pressure" => true,
      "branch_local_blocked_allocation_pressure" => true,
      "branch_local_deferred_allocation_pressure" => true,
      "branch_local_station_pressure" => true,
      "branch_local_capacity_pack_pressure" => true,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => "contact_allocation_source_report_provenance_only",
        "operator_authority" => "not_granted_by_contact_allocation_replay_summary",
        "contact_allocation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_contact_allocation_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }

    assert CandidateRefresh.contact_allocation_replay_summary(refresh) == replay_summary

    assert OrbitalDynamics.candidate_refresh_contact_allocation_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => summary["source_reports"]}
    }

    assert %{
             "source_report_contact_allocation_contract" => "contact_allocation_report.v1",
             "source_report_contact_allocation_count" => 1,
             "source_report_contact_allocation_row_count" => 5,
             "source_report_contact_allocation_paths" => ["source_contact_allocation_report"],
             "source_report_contact_allocation_blocked_row_count" => 2,
             "source_report_contact_allocation_deferred_row_count" => 1,
             "source_report_contact_allocation_capacity_pack_required_capacity_fraction" => 0.6,
             "source_report_contact_allocation_capacity_pack_required_capacity_fraction_by_status" =>
               %{
                 "deferred_by_reduced_station_capacity_pack" => 0.35,
                 "selected_by_reduced_station_capacity_pack" => 0.25
               },
             "source_report_contact_allocation_capacity_pack_required_capacity_fraction_by_direction" =>
               %{"downlink" => 0.6},
             "source_report_contact_allocation_capacity_pack_selected_required_capacity_fraction_by_direction" =>
               %{"downlink" => 0.25},
             "source_report_contact_allocation_capacity_pack_deferred_required_capacity_fraction_by_direction" =>
               %{"downlink" => 0.35},
             "source_report_contact_allocation_capacity_pack_selected_contact_ids_by_ground_station" =>
               %{"equator_prime" => ["selected_contact"]},
             "source_report_contact_allocation_capacity_pack_deferred_contact_ids_by_ground_station" =>
               %{"equator_prime" => ["deferred_contact"]},
             "source_report_contact_allocation_capacity_pack_contact_ids_by_ground_station" => %{
               "equator_prime" => ["deferred_contact", "selected_contact"]
             },
             "source_report_contact_allocation_capacity_pack_selected_contact_ids_by_direction" =>
               %{"downlink" => ["selected_contact"]},
             "source_report_contact_allocation_capacity_pack_deferred_contact_ids_by_direction" =>
               %{"downlink" => ["deferred_contact"]},
             "source_report_contact_allocation_capacity_pack_contact_ids_by_direction" => %{
               "downlink" => ["deferred_contact", "selected_contact"]
             },
             "source_report_contact_allocation_capacity_pack_contact_ids_by_status" => %{
               "deferred_by_reduced_station_capacity_pack" => ["deferred_contact"],
               "selected_by_reduced_station_capacity_pack" => ["selected_contact"]
             },
             "source_report_contact_allocation_capacity_pack_status_counts" => %{
               "deferred_by_reduced_station_capacity_pack" => 1,
               "selected_by_reduced_station_capacity_pack" => 1
             },
             "source_report_contact_allocation_capacity_pack_contact_status_counts" => %{
               "deferred_by_reduced_station_capacity_pack" => 1,
               "selected_by_reduced_station_capacity_pack" => 1
             },
             "source_report_contact_allocation_capacity_pack_contact_count" => 2,
             "source_report_contact_allocation_direction_routing" => ^expected_direction_routing,
             "source_report_contact_allocation_allocation_status_counts" => %{
               "allocated" => 3,
               "blocked" => 1,
               "deferred" => 1
             },
             "source_report_contact_allocation_effective_allocation_status_counts" => %{
               "allocated" => 2,
               "blocked" => 1,
               "deferred" => 1,
               "policy_blocked" => 1
             },
             "source_report_contact_allocation_reduced_capacity_pack_group_count" => 1,
             "source_report_contact_allocation_reduced_capacity_pack_status_counts" => %{
               "capacity_limited" => 1
             },
             "source_report_contact_allocation_capacity_pack_group_ids" => [
               "pack_equator_prime"
             ],
             "source_report_contact_allocation_capacity_pack_group_ids_by_status" => %{
               "capacity_limited" => ["pack_equator_prime"]
             },
             "source_report_contact_allocation_required_capacity_fraction_source_counts" => %{
               "capacity_model" => 1,
               "contact_required_capacity_fraction" => 1
             },
             "source_report_contact_allocation_required_capacity_fraction_contact_ids_by_source" =>
               %{
                 "capacity_model" => ["deferred_contact"],
                 "contact_required_capacity_fraction" => ["selected_contact"]
               },
             "source_report_contact_allocation_reduced_capacity_packed_contact_ids" => [
               "selected_contact"
             ],
             "source_report_contact_allocation_reduced_capacity_deferred_contact_ids" => [
               "deferred_contact"
             ],
             "source_report_contact_allocation_allocated_contact_count" => 3,
             "source_report_contact_allocation_allocated_contact_ids_by_ground_station" => %{
               "dss_43" => ["policy_blocked_contact"],
               "equator_prime" => ["selected_contact"],
               "polar_prime" => ["station_pressure_contact"]
             },
             "source_report_contact_allocation_returned_allocated_contact_ids" => [
               "selected_contact",
               "station_pressure_contact"
             ],
             "source_report_contact_allocation_returned_allocated_contact_count" => 2,
             "source_report_contact_allocation_deferred_contact_count" => 1,
             "source_report_contact_allocation_deferred_contact_ids" => ["deferred_contact"],
             "source_report_contact_allocation_blocked_contact_count" => 1,
             "source_report_contact_allocation_blocked_contact_ids" => ["blocked_contact"],
             "source_report_contact_allocation_policy_blocked_contact_ids" => [
               "policy_blocked_contact"
             ],
             "source_report_contact_allocation_policy_blocked_allocated_contact_count" => 1,
             "source_report_contact_allocation_station_pressure_contact_count" => 1,
             "source_report_contact_allocation_station_pressure_contact_ids" => [
               "station_pressure_contact"
             ],
             "source_report_contact_allocation_review_contact_ids" => [
               "blocked_contact",
               "deferred_contact",
               "policy_blocked_contact",
               "station_pressure_contact"
             ],
             "source_report_contact_allocation_station_pressure_contact_ids_by_ground_station" =>
               %{"polar_prime" => ["station_pressure_contact"]},
             "source_report_contact_allocation_station_pressure_contact_ids_by_availability" => %{
               "reserved" => ["station_pressure_contact"]
             },
             "source_report_contact_allocation_station_pressure_contact_ids_by_precedence_availability" =>
               %{"reduced_capacity" => ["station_pressure_contact"]},
             "source_report_contact_allocation_station_pressure_contact_ids_by_precedence_rank" =>
               %{"2" => ["station_pressure_contact"]},
             "source_report_contact_allocation_station_pressure_contact_ids_by_status" => %{
               "maintenance_window" => ["station_pressure_contact"]
             },
             "source_report_contact_allocation_station_pressure_review_contact_count" => 1,
             "source_report_contact_allocation_station_pressure_review_contact_ids" => [
               "station_pressure_contact"
             ],
             "source_report_contact_allocation_branch_local_contact_allocation_pressure" => true,
             "source_report_contact_allocation_branch_local_blocked_allocation_pressure" => true,
             "source_report_contact_allocation_branch_local_deferred_allocation_pressure" => true,
             "source_report_contact_allocation_branch_local_station_pressure" => true,
             "source_report_contact_allocation_branch_local_capacity_pack_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.contact_allocation_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_contact_allocation_replay_summary(artifact) ==
             replay_summary
  end
end
