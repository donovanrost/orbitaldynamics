defmodule OrbitalDynamics.CandidateRefresh.StationCalendarContactProviderRoutingReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary aggregates station calendar contact and provider routing maps" do
    refresh = %{
      "source_station_calendar_report" => %{
        "schema_contract" => "station_calendar_report.v1",
        "affected_contacts" => [
          %{
            "id" => "station_calendar:dl_unavailable",
            "contact_id" => "dl_unavailable",
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "station_calendar_entry_id" => "station_entry_unavailable",
            "station_calendar_status" => "unavailable"
          },
          %{
            "id" => "station_calendar:dl_reserved",
            "contact_id" => "dl_reserved",
            "ground_station_id" => "dss_43",
            "direction" => "uplink",
            "station_calendar_entry_id" => "station_entry_reserved",
            "station_reservation_id" => "reservation_dss_43",
            "station_reserved_by" => "ops_team_b",
            "station_reservation_expires_at_s" => 1800.0,
            "station_availability" => "reserved",
            "station_calendar_status" => "reserved"
          },
          %{
            "id" => "station_calendar:dl_reduced",
            "contact_id" => "dl_reduced",
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "station_calendar_entry_id" => "station_entry_reduced",
            "capacity_fraction" => 0.4,
            "station_availability" => "reduced_capacity",
            "station_calendar_status" => "reduced_capacity"
          }
        ],
        "provider_calendar_contention_groups" => [
          %{
            "id" => "station_calendar_provider_contention:equator_prime:1",
            "provider_ids" => ["ops_calendar", "partner_calendar"],
            "provider_entry_ids" => ["provider_entry_ops", "provider_entry_partner"],
            "ground_station_id" => "equator_prime",
            "capacity_fraction" => 0.25,
            "directions" => ["Down Link", "Track-ing"],
            "source_station_calendar_entries" => [
              %{"id" => "provider_a", "ground_station_id" => "equator_prime"},
              %{"id" => "provider_b", "ground_station_id" => "dss_43"}
            ]
          }
        ],
        "station_calendar_status_counts" => %{"stale_status" => 99},
        "affected_contact_ground_station_counts" => %{"stale_station" => 99},
        "affected_contact_availability_counts" => %{"stale_availability" => 99},
        "provider_calendar_contention_provider_counts" => %{"stale_provider" => 99},
        "provider_calendar_contention_ground_station_counts" => %{"stale_station" => 99},
        "provider_calendar_contention_provider_entry_ids_by_provider" => %{
          "stale_provider" => ["stale_provider_entry"]
        },
        "provider_calendar_contention_provider_entry_ids_by_ground_station" => %{
          "stale_station" => ["stale_provider_entry"]
        },
        "provider_calendar_contention_provider_entry_ids_by_direction" => %{
          "stale_direction" => ["stale_provider_entry"]
        },
        "provenance" => %{"trust_boundary" => "ops_station_calendar"}
      }
    }

    expected_direction_routing = %{
      "downlink" => %{
        "contact_count" => 2,
        "contact_ids" => ["dl_reduced", "dl_unavailable"],
        "station_calendar_entry_ids" => [
          "station_entry_reduced",
          "station_entry_unavailable"
        ],
        "station_reservation_ids" => [],
        "station_capacity_fractions" => [0.4],
        "provider_contention_group_count" => 1,
        "provider_contention_group_ids" => [
          "station_calendar_provider_contention:equator_prime:1"
        ],
        "provider_contention_source_entry_ids" => ["provider_a", "provider_b"],
        "provider_contention_provider_ids" => ["ops_calendar", "partner_calendar"],
        "provider_contention_provider_entry_ids" => [
          "provider_entry_ops",
          "provider_entry_partner"
        ],
        "provider_contention_capacity_fractions" => [0.25]
      },
      "tracking" => %{
        "contact_ids" => [],
        "station_calendar_entry_ids" => [],
        "station_reservation_ids" => [],
        "station_capacity_fractions" => [],
        "provider_contention_group_count" => 1,
        "provider_contention_group_ids" => [
          "station_calendar_provider_contention:equator_prime:1"
        ],
        "provider_contention_source_entry_ids" => ["provider_a", "provider_b"],
        "provider_contention_provider_ids" => ["ops_calendar", "partner_calendar"],
        "provider_contention_provider_entry_ids" => [
          "provider_entry_ops",
          "provider_entry_partner"
        ],
        "provider_contention_capacity_fractions" => [0.25]
      },
      "uplink" => %{
        "contact_count" => 1,
        "contact_ids" => ["dl_reserved"],
        "station_calendar_entry_ids" => ["station_entry_reserved"],
        "station_reservation_ids" => ["reservation_dss_43"],
        "station_capacity_fractions" => [],
        "provider_contention_group_ids" => [],
        "provider_contention_source_entry_ids" => [],
        "provider_contention_provider_ids" => [],
        "provider_contention_provider_entry_ids" => [],
        "provider_contention_capacity_fractions" => []
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_station_calendar_affected_contact_count" => 3,
             "source_report_station_calendar_provider_calendar_contention_group_count" => 1,
             "source_report_station_calendar_provider_calendar_contention_group_ids" => [
               "station_calendar_provider_contention:equator_prime:1"
             ],
             "source_report_station_calendar_provider_calendar_contention_source_entry_ids" => [
               "provider_a",
               "provider_b"
             ],
             "source_report_station_calendar_provider_calendar_contention_provider_entry_ids" => [
               "provider_entry_ops",
               "provider_entry_partner"
             ],
             "source_report_station_calendar_provider_calendar_contention_capacity_fractions" => [
               0.25
             ],
             "source_report_station_calendar_provider_calendar_contention_minimum_capacity_fraction" =>
               0.25,
             "source_report_station_calendar_provider_calendar_contention_capacity_fractions_by_provider" =>
               %{
                 "ops_calendar" => [0.25],
                 "partner_calendar" => [0.25]
               },
             "source_report_station_calendar_provider_calendar_contention_capacity_fractions_by_ground_station" =>
               %{
                 "dss_43" => [0.25],
                 "equator_prime" => [0.25]
               },
             "source_report_station_calendar_provider_calendar_contention_provider_entry_ids_by_provider" =>
               %{
                 "ops_calendar" => ["provider_entry_ops", "provider_entry_partner"],
                 "partner_calendar" => ["provider_entry_ops", "provider_entry_partner"]
               },
             "source_report_station_calendar_provider_calendar_contention_provider_entry_ids_by_ground_station" =>
               %{
                 "dss_43" => ["provider_entry_ops", "provider_entry_partner"],
                 "equator_prime" => ["provider_entry_ops", "provider_entry_partner"]
               },
             "source_report_station_calendar_provider_calendar_contention_direction_counts" => %{
               "downlink" => 1,
               "tracking" => 1
             },
             "source_report_station_calendar_provider_calendar_contention_group_ids_by_direction" =>
               %{
                 "downlink" => ["station_calendar_provider_contention:equator_prime:1"],
                 "tracking" => ["station_calendar_provider_contention:equator_prime:1"]
               },
             "source_report_station_calendar_provider_calendar_contention_source_entry_ids_by_direction" =>
               %{
                 "downlink" => ["provider_a", "provider_b"],
                 "tracking" => ["provider_a", "provider_b"]
               },
             "source_report_station_calendar_provider_calendar_contention_provider_ids_by_direction" =>
               %{
                 "downlink" => ["ops_calendar", "partner_calendar"],
                 "tracking" => ["ops_calendar", "partner_calendar"]
               },
             "source_report_station_calendar_provider_calendar_contention_provider_entry_ids_by_direction" =>
               %{
                 "downlink" => ["provider_entry_ops", "provider_entry_partner"],
                 "tracking" => ["provider_entry_ops", "provider_entry_partner"]
               },
             "source_report_station_calendar_provider_calendar_contention_capacity_fractions_by_direction" =>
               %{
                 "downlink" => [0.25],
                 "tracking" => [0.25]
               },
             "source_report_station_calendar_affected_contact_ids" => [
               "dl_reduced",
               "dl_reserved",
               "dl_unavailable"
             ],
             "source_report_station_calendar_affected_station_calendar_entry_ids" => [
               "station_entry_reduced",
               "station_entry_reserved",
               "station_entry_unavailable"
             ],
             "source_report_station_calendar_affected_station_reservation_ids" => [
               "reservation_dss_43"
             ],
             "source_report_station_calendar_direction_counts" => %{
               "downlink" => 2,
               "uplink" => 1
             },
             "source_report_station_calendar_contact_ids_by_direction" => %{
               "downlink" => ["dl_reduced", "dl_unavailable"],
               "uplink" => ["dl_reserved"]
             },
             "source_report_station_calendar_entry_ids_by_direction" => %{
               "downlink" => ["station_entry_reduced", "station_entry_unavailable"],
               "uplink" => ["station_entry_reserved"]
             },
             "source_report_station_calendar_reservation_ids_by_direction" => %{
               "uplink" => ["reservation_dss_43"]
             },
             "source_report_station_calendar_capacity_fractions_by_direction" => %{
               "downlink" => [0.4]
             },
             "source_report_station_calendar_direction_routing" => ^expected_direction_routing,
             "source_report_station_calendar_reserved_by_counts" => %{
               "ops_team_b" => 1
             },
             "source_report_station_calendar_contact_ids_by_reserved_by" => %{
               "ops_team_b" => ["dl_reserved"]
             },
             "source_report_station_calendar_entry_ids_by_reserved_by" => %{
               "ops_team_b" => ["station_entry_reserved"]
             },
             "source_report_station_calendar_reservation_ids_by_reserved_by" => %{
               "ops_team_b" => ["reservation_dss_43"]
             },
             "source_report_station_calendar_reservation_expires_at_s" => [1800.0],
             "source_report_station_calendar_earliest_reservation_expires_at_s" => 1800.0,
             "source_report_station_calendar_capacity_fractions" => [0.4],
             "source_report_station_calendar_minimum_capacity_fraction" => 0.4,
             "source_report_station_calendar_capacity_fractions_by_status" => %{
               "reduced_capacity" => [0.4]
             },
             "source_report_station_calendar_capacity_fractions_by_ground_station" => %{
               "equator_prime" => [0.4]
             },
             "source_report_station_calendar_capacity_fractions_by_availability" => %{
               "reduced_capacity" => [0.4]
             },
             "source_report_station_calendar_contact_ids_by_status" => %{
               "reduced_capacity" => ["dl_reduced"],
               "reserved" => ["dl_reserved"],
               "unavailable" => ["dl_unavailable"]
             },
             "source_report_station_calendar_entry_ids_by_status" => %{
               "reduced_capacity" => ["station_entry_reduced"],
               "reserved" => ["station_entry_reserved"],
               "unavailable" => ["station_entry_unavailable"]
             },
             "source_report_station_calendar_reservation_ids_by_status" => %{
               "reserved" => ["reservation_dss_43"]
             },
             "source_report_station_calendar_contact_ids_by_ground_station" => %{
               "dss_43" => ["dl_reserved"],
               "equator_prime" => ["dl_reduced", "dl_unavailable"]
             },
             "source_report_station_calendar_entry_ids_by_ground_station" => %{
               "dss_43" => ["station_entry_reserved"],
               "equator_prime" => ["station_entry_reduced", "station_entry_unavailable"]
             },
             "source_report_station_calendar_reservation_ids_by_ground_station" => %{
               "dss_43" => ["reservation_dss_43"]
             },
             "source_report_station_calendar_contact_ids_by_availability" => %{
               "reduced_capacity" => ["dl_reduced"],
               "reserved" => ["dl_reserved"],
               "unavailable" => ["dl_unavailable"]
             },
             "source_report_station_calendar_entry_ids_by_availability" => %{
               "reduced_capacity" => ["station_entry_reduced"],
               "reserved" => ["station_entry_reserved"],
               "unavailable" => ["station_entry_unavailable"]
             },
             "source_report_station_calendar_reservation_ids_by_availability" => %{
               "reserved" => ["reservation_dss_43"]
             },
             "source_report_station_calendar_provider_calendar_contention_provider_counts" => %{
               "ops_calendar" => 1,
               "partner_calendar" => 1
             },
             "source_report_station_calendar_provider_calendar_contention_ground_station_counts" =>
               %{
                 "dss_43" => 1,
                 "equator_prime" => 1
               },
             "source_report_station_calendar_contract" => "station_calendar_report.v1",
             "source_report_station_calendar_count" => 1,
             "source_report_station_calendar_row_count" => 4,
             "source_report_station_calendar_paths" => ["source_station_calendar_report"],
             "source_report_station_calendar_status_counts" => %{
               "reduced_capacity" => 1,
               "reserved" => 1,
               "unavailable" => 1
             },
             "source_report_station_calendar_affected_contact_ground_station_counts" => %{
               "dss_43" => 1,
               "equator_prime" => 2
             },
             "source_report_station_calendar_affected_contact_availability_counts" => %{
               "reduced_capacity" => 1,
               "reserved" => 1,
               "unavailable" => 1
             },
             "source_report_station_calendar_branch_local_station_calendar_pressure" => true,
             "source_report_station_calendar_branch_local_affected_contact_pressure" => true,
             "source_report_station_calendar_branch_local_provider_contention_pressure" => true,
             "source_report_station_calendar_branch_local_station_availability_pressure" => true,
             "source_reports" => %{
               "station_calendar_report" => %{
                 "affected_contact_count" => 3,
                 "provider_calendar_contention_group_count" => 1,
                 "provider_calendar_contention_group_ids" => [
                   "station_calendar_provider_contention:equator_prime:1"
                 ],
                 "provider_calendar_contention_source_entry_ids" => [
                   "provider_a",
                   "provider_b"
                 ],
                 "provider_calendar_contention_provider_entry_ids" => [
                   "provider_entry_ops",
                   "provider_entry_partner"
                 ],
                 "provider_calendar_contention_capacity_fractions" => [0.25],
                 "provider_calendar_contention_minimum_capacity_fraction" => 0.25,
                 "provider_calendar_contention_capacity_fractions_by_provider" => %{
                   "ops_calendar" => [0.25],
                   "partner_calendar" => [0.25]
                 },
                 "provider_calendar_contention_capacity_fractions_by_ground_station" => %{
                   "dss_43" => [0.25],
                   "equator_prime" => [0.25]
                 },
                 "provider_calendar_contention_provider_entry_ids_by_provider" => %{
                   "ops_calendar" => ["provider_entry_ops", "provider_entry_partner"],
                   "partner_calendar" => ["provider_entry_ops", "provider_entry_partner"]
                 },
                 "provider_calendar_contention_provider_entry_ids_by_ground_station" => %{
                   "dss_43" => ["provider_entry_ops", "provider_entry_partner"],
                   "equator_prime" => ["provider_entry_ops", "provider_entry_partner"]
                 },
                 "provider_calendar_contention_direction_counts" => %{
                   "downlink" => 1,
                   "tracking" => 1
                 },
                 "provider_calendar_contention_group_ids_by_direction" => %{
                   "downlink" => ["station_calendar_provider_contention:equator_prime:1"],
                   "tracking" => ["station_calendar_provider_contention:equator_prime:1"]
                 },
                 "provider_calendar_contention_source_entry_ids_by_direction" => %{
                   "downlink" => ["provider_a", "provider_b"],
                   "tracking" => ["provider_a", "provider_b"]
                 },
                 "provider_calendar_contention_provider_ids_by_direction" => %{
                   "downlink" => ["ops_calendar", "partner_calendar"],
                   "tracking" => ["ops_calendar", "partner_calendar"]
                 },
                 "provider_calendar_contention_provider_entry_ids_by_direction" => %{
                   "downlink" => ["provider_entry_ops", "provider_entry_partner"],
                   "tracking" => ["provider_entry_ops", "provider_entry_partner"]
                 },
                 "provider_calendar_contention_capacity_fractions_by_direction" => %{
                   "downlink" => [0.25],
                   "tracking" => [0.25]
                 },
                 "affected_contact_ground_station_counts" => %{
                   "dss_43" => 1,
                   "equator_prime" => 2
                 },
                 "affected_contact_ids" => [
                   "dl_reduced",
                   "dl_reserved",
                   "dl_unavailable"
                 ],
                 "affected_station_calendar_entry_ids" => [
                   "station_entry_reduced",
                   "station_entry_reserved",
                   "station_entry_unavailable"
                 ],
                 "affected_station_reservation_ids" => [
                   "reservation_dss_43"
                 ],
                 "direction_counts" => %{
                   "downlink" => 2,
                   "uplink" => 1
                 },
                 "contact_ids_by_direction" => %{
                   "downlink" => ["dl_reduced", "dl_unavailable"],
                   "uplink" => ["dl_reserved"]
                 },
                 "station_calendar_entry_ids_by_direction" => %{
                   "downlink" => ["station_entry_reduced", "station_entry_unavailable"],
                   "uplink" => ["station_entry_reserved"]
                 },
                 "station_reservation_ids_by_direction" => %{
                   "uplink" => ["reservation_dss_43"]
                 },
                 "station_capacity_fractions_by_direction" => %{
                   "downlink" => [0.4]
                 },
                 "direction_routing" => ^expected_direction_routing,
                 "reserved_by_counts" => %{
                   "ops_team_b" => 1
                 },
                 "contact_ids_by_reserved_by" => %{
                   "ops_team_b" => ["dl_reserved"]
                 },
                 "station_calendar_entry_ids_by_reserved_by" => %{
                   "ops_team_b" => ["station_entry_reserved"]
                 },
                 "station_reservation_ids_by_reserved_by" => %{
                   "ops_team_b" => ["reservation_dss_43"]
                 },
                 "station_reservation_expires_at_s" => [1800.0],
                 "earliest_station_reservation_expires_at_s" => 1800.0,
                 "station_capacity_fractions" => [0.4],
                 "minimum_station_capacity_fraction" => 0.4,
                 "station_capacity_fractions_by_status" => %{
                   "reduced_capacity" => [0.4]
                 },
                 "station_capacity_fractions_by_ground_station" => %{
                   "equator_prime" => [0.4]
                 },
                 "station_capacity_fractions_by_availability" => %{
                   "reduced_capacity" => [0.4]
                 },
                 "contact_ids_by_status" => %{
                   "reduced_capacity" => ["dl_reduced"],
                   "reserved" => ["dl_reserved"],
                   "unavailable" => ["dl_unavailable"]
                 },
                 "station_calendar_entry_ids_by_status" => %{
                   "reduced_capacity" => ["station_entry_reduced"],
                   "reserved" => ["station_entry_reserved"],
                   "unavailable" => ["station_entry_unavailable"]
                 },
                 "station_reservation_ids_by_status" => %{
                   "reserved" => ["reservation_dss_43"]
                 },
                 "contact_ids_by_ground_station" => %{
                   "dss_43" => ["dl_reserved"],
                   "equator_prime" => ["dl_reduced", "dl_unavailable"]
                 },
                 "station_calendar_entry_ids_by_ground_station" => %{
                   "dss_43" => ["station_entry_reserved"],
                   "equator_prime" => ["station_entry_reduced", "station_entry_unavailable"]
                 },
                 "station_reservation_ids_by_ground_station" => %{
                   "dss_43" => ["reservation_dss_43"]
                 },
                 "contact_ids_by_availability" => %{
                   "reduced_capacity" => ["dl_reduced"],
                   "reserved" => ["dl_reserved"],
                   "unavailable" => ["dl_unavailable"]
                 },
                 "station_calendar_entry_ids_by_availability" => %{
                   "reduced_capacity" => ["station_entry_reduced"],
                   "reserved" => ["station_entry_reserved"],
                   "unavailable" => ["station_entry_unavailable"]
                 },
                 "station_reservation_ids_by_availability" => %{
                   "reserved" => ["reservation_dss_43"]
                 }
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = %{
      "model" => "artifact_only_candidate_refresh_station_calendar_replay_summary",
      "source" => "candidate_refresh.source_report_provenance.station_calendar_report",
      "contract" => "station_calendar_report.v1",
      "source_report_count" => 1,
      "source_report_row_count" => 4,
      "source_report_paths" => ["source_station_calendar_report"],
      "affected_contact_count" => 3,
      "provider_calendar_contention_group_count" => 1,
      "provider_calendar_contention_group_ids" => [
        "station_calendar_provider_contention:equator_prime:1"
      ],
      "provider_calendar_contention_source_entry_ids" => [
        "provider_a",
        "provider_b"
      ],
      "provider_calendar_contention_provider_entry_ids" => [
        "provider_entry_ops",
        "provider_entry_partner"
      ],
      "provider_calendar_contention_capacity_fractions" => [0.25],
      "provider_calendar_contention_minimum_capacity_fraction" => 0.25,
      "provider_calendar_contention_capacity_fractions_by_provider" => %{
        "ops_calendar" => [0.25],
        "partner_calendar" => [0.25]
      },
      "provider_calendar_contention_capacity_fractions_by_ground_station" => %{
        "dss_43" => [0.25],
        "equator_prime" => [0.25]
      },
      "provider_calendar_contention_provider_entry_ids_by_provider" => %{
        "ops_calendar" => ["provider_entry_ops", "provider_entry_partner"],
        "partner_calendar" => ["provider_entry_ops", "provider_entry_partner"]
      },
      "provider_calendar_contention_provider_entry_ids_by_ground_station" => %{
        "dss_43" => ["provider_entry_ops", "provider_entry_partner"],
        "equator_prime" => ["provider_entry_ops", "provider_entry_partner"]
      },
      "provider_calendar_contention_direction_counts" => %{
        "downlink" => 1,
        "tracking" => 1
      },
      "provider_calendar_contention_group_ids_by_direction" => %{
        "downlink" => ["station_calendar_provider_contention:equator_prime:1"],
        "tracking" => ["station_calendar_provider_contention:equator_prime:1"]
      },
      "provider_calendar_contention_source_entry_ids_by_direction" => %{
        "downlink" => ["provider_a", "provider_b"],
        "tracking" => ["provider_a", "provider_b"]
      },
      "provider_calendar_contention_provider_ids_by_direction" => %{
        "downlink" => ["ops_calendar", "partner_calendar"],
        "tracking" => ["ops_calendar", "partner_calendar"]
      },
      "provider_calendar_contention_provider_entry_ids_by_direction" => %{
        "downlink" => ["provider_entry_ops", "provider_entry_partner"],
        "tracking" => ["provider_entry_ops", "provider_entry_partner"]
      },
      "provider_calendar_contention_capacity_fractions_by_direction" => %{
        "downlink" => [0.25],
        "tracking" => [0.25]
      },
      "provider_calendar_contention_provider_counts" => %{
        "ops_calendar" => 1,
        "partner_calendar" => 1
      },
      "provider_calendar_contention_ground_station_counts" => %{
        "dss_43" => 1,
        "equator_prime" => 1
      },
      "affected_contact_ids" => [
        "dl_reduced",
        "dl_reserved",
        "dl_unavailable"
      ],
      "affected_station_calendar_entry_ids" => [
        "station_entry_reduced",
        "station_entry_reserved",
        "station_entry_unavailable"
      ],
      "affected_station_reservation_ids" => [
        "reservation_dss_43"
      ],
      "direction_counts" => %{
        "downlink" => 2,
        "uplink" => 1
      },
      "contact_ids_by_direction" => %{
        "downlink" => ["dl_reduced", "dl_unavailable"],
        "uplink" => ["dl_reserved"]
      },
      "station_calendar_entry_ids_by_direction" => %{
        "downlink" => ["station_entry_reduced", "station_entry_unavailable"],
        "uplink" => ["station_entry_reserved"]
      },
      "station_reservation_ids_by_direction" => %{
        "uplink" => ["reservation_dss_43"]
      },
      "station_capacity_fractions_by_direction" => %{
        "downlink" => [0.4]
      },
      "direction_routing" => expected_direction_routing,
      "reserved_by_counts" => %{
        "ops_team_b" => 1
      },
      "contact_ids_by_reserved_by" => %{
        "ops_team_b" => ["dl_reserved"]
      },
      "station_calendar_entry_ids_by_reserved_by" => %{
        "ops_team_b" => ["station_entry_reserved"]
      },
      "station_reservation_ids_by_reserved_by" => %{
        "ops_team_b" => ["reservation_dss_43"]
      },
      "station_reservation_expires_at_s" => [1800.0],
      "earliest_station_reservation_expires_at_s" => 1800.0,
      "station_capacity_fractions" => [0.4],
      "minimum_station_capacity_fraction" => 0.4,
      "station_capacity_fractions_by_status" => %{
        "reduced_capacity" => [0.4]
      },
      "station_capacity_fractions_by_ground_station" => %{
        "equator_prime" => [0.4]
      },
      "station_capacity_fractions_by_availability" => %{
        "reduced_capacity" => [0.4]
      },
      "contact_ids_by_status" => %{
        "reduced_capacity" => ["dl_reduced"],
        "reserved" => ["dl_reserved"],
        "unavailable" => ["dl_unavailable"]
      },
      "station_calendar_entry_ids_by_status" => %{
        "reduced_capacity" => ["station_entry_reduced"],
        "reserved" => ["station_entry_reserved"],
        "unavailable" => ["station_entry_unavailable"]
      },
      "station_reservation_ids_by_status" => %{
        "reserved" => ["reservation_dss_43"]
      },
      "contact_ids_by_ground_station" => %{
        "dss_43" => ["dl_reserved"],
        "equator_prime" => ["dl_reduced", "dl_unavailable"]
      },
      "station_calendar_entry_ids_by_ground_station" => %{
        "dss_43" => ["station_entry_reserved"],
        "equator_prime" => ["station_entry_reduced", "station_entry_unavailable"]
      },
      "station_reservation_ids_by_ground_station" => %{
        "dss_43" => ["reservation_dss_43"]
      },
      "contact_ids_by_availability" => %{
        "reduced_capacity" => ["dl_reduced"],
        "reserved" => ["dl_reserved"],
        "unavailable" => ["dl_unavailable"]
      },
      "station_calendar_entry_ids_by_availability" => %{
        "reduced_capacity" => ["station_entry_reduced"],
        "reserved" => ["station_entry_reserved"],
        "unavailable" => ["station_entry_unavailable"]
      },
      "station_reservation_ids_by_availability" => %{
        "reserved" => ["reservation_dss_43"]
      },
      "station_calendar_status_counts" => %{
        "reduced_capacity" => 1,
        "reserved" => 1,
        "unavailable" => 1
      },
      "affected_contact_ground_station_counts" => %{
        "dss_43" => 1,
        "equator_prime" => 2
      },
      "affected_contact_availability_counts" => %{
        "reduced_capacity" => 1,
        "reserved" => 1,
        "unavailable" => 1
      },
      "trust_boundary_status" => "declared",
      "trust_boundaries" => ["ops_station_calendar"],
      "branch_local_station_calendar_pressure" => true,
      "branch_local_affected_contact_pressure" => true,
      "branch_local_provider_contention_pressure" => true,
      "branch_local_station_availability_pressure" => true,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => "station_calendar_source_report_provenance_only",
        "operator_authority" => "not_granted_by_station_calendar_replay_summary",
        "station_calendar_mutation" => "not_performed_by_summary",
        "schedule_mutation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_station_calendar_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }

    assert CandidateRefresh.station_calendar_replay_summary(refresh) == replay_summary

    assert OrbitalDynamics.candidate_refresh_station_calendar_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => summary["source_reports"]}
    }

    assert %{
             "source_report_station_calendar_contract" => "station_calendar_report.v1",
             "source_report_station_calendar_count" => 1,
             "source_report_station_calendar_row_count" => 4,
             "source_report_station_calendar_paths" => ["source_station_calendar_report"],
             "source_report_station_calendar_affected_contact_count" => 3,
             "source_report_station_calendar_provider_calendar_contention_provider_counts" => %{
               "ops_calendar" => 1,
               "partner_calendar" => 1
             },
             "source_report_station_calendar_provider_calendar_contention_source_entry_ids" => [
               "provider_a",
               "provider_b"
             ],
             "source_report_station_calendar_provider_calendar_contention_provider_entry_ids" => [
               "provider_entry_ops",
               "provider_entry_partner"
             ],
             "source_report_station_calendar_provider_calendar_contention_minimum_capacity_fraction" =>
               0.25,
             "source_report_station_calendar_provider_calendar_contention_direction_counts" => %{
               "downlink" => 1,
               "tracking" => 1
             },
             "source_report_station_calendar_provider_calendar_contention_provider_ids_by_direction" =>
               %{
                 "downlink" => ["ops_calendar", "partner_calendar"],
                 "tracking" => ["ops_calendar", "partner_calendar"]
               },
             "source_report_station_calendar_contact_ids_by_ground_station" => %{
               "dss_43" => ["dl_reserved"],
               "equator_prime" => ["dl_reduced", "dl_unavailable"]
             },
             "source_report_station_calendar_entry_ids_by_ground_station" => %{
               "dss_43" => ["station_entry_reserved"],
               "equator_prime" => ["station_entry_reduced", "station_entry_unavailable"]
             },
             "source_report_station_calendar_reservation_ids_by_ground_station" => %{
               "dss_43" => ["reservation_dss_43"]
             },
             "source_report_station_calendar_contact_ids_by_reserved_by" => %{
               "ops_team_b" => ["dl_reserved"]
             },
             "source_report_station_calendar_contact_ids_by_direction" => %{
               "downlink" => ["dl_reduced", "dl_unavailable"],
               "uplink" => ["dl_reserved"]
             },
             "source_report_station_calendar_direction_routing" => ^expected_direction_routing,
             "source_report_station_calendar_earliest_reservation_expires_at_s" => 1800.0,
             "source_report_station_calendar_minimum_capacity_fraction" => 0.4,
             "source_report_station_calendar_affected_contact_availability_counts" => %{
               "reduced_capacity" => 1,
               "reserved" => 1,
               "unavailable" => 1
             },
             "source_report_station_calendar_branch_local_station_calendar_pressure" => true,
             "source_report_station_calendar_branch_local_affected_contact_pressure" => true,
             "source_report_station_calendar_branch_local_provider_contention_pressure" => true,
             "source_report_station_calendar_branch_local_station_availability_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.station_calendar_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_station_calendar_replay_summary(artifact) ==
             replay_summary
  end
end
