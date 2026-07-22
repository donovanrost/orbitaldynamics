defmodule OrbitalDynamics.OperatorReview.ContactAllocationEmbeddedSummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "lifts embedded contact-allocation summary fields from wrapper artifacts" do
    campaign_summary =
      contact_allocation_summary(%{"declared" => 1}, %{
        "station_reservation_ids" => ["reservation_campaign"],
        "station_reserved_bys" => ["ops_campaign"],
        "station_reservation_statuses" => ["confirmed"],
        "station_reservation_match_status_counts" => %{"matched" => 1},
        "station_reservation_expiration_status_counts" => %{"declared" => 1},
        "station_reservation_declared_expiration_contact_count" => 1,
        "station_reservation_missing_expiration_contact_count" => 0,
        "earliest_station_reservation_expires_at_s" => 410.0,
        "station_reservation_contact_ids_by_expiration_status" => %{
          "declared" => ["dl_campaign"]
        },
        "station_reservation_ids_by_expiration_status" => %{
          "declared" => ["reservation_campaign"]
        },
        "reservation_conflict_contact_ids_by_direction" => %{
          "downlink" => ["dl_campaign_conflict"]
        },
        "reservation_conflict_contact_ids_by_direction_and_ground_station_id" => %{
          "downlink" => %{"gs_campaign" => ["dl_campaign_conflict"]}
        },
        "resource_blocking_dimension_counts" => %{"antenna" => 1},
        "resource_blocked_contact_ids_by_blocking_dimension" => %{
          "antenna" => ["dl_campaign_resource"]
        },
        "resource_blocked_contact_ids_by_spacecraft_id" => %{
          "sat_campaign" => ["dl_campaign_resource"]
        },
        "station_pressure_contact_count" => 1,
        "station_pressure_contact_ids" => ["dl_campaign_station"],
        "station_pressure_review_contact_count" => 1,
        "station_pressure_review_contact_ids" => ["dl_campaign_station"],
        "station_pressure_contact_counts_by_ground_station_id" => %{"gs_campaign" => 1},
        "station_pressure_contact_ids_by_ground_station_id" => %{
          "gs_campaign" => ["dl_campaign_station"]
        },
        "station_pressure_contact_counts_by_availability" => %{"unavailable" => 1},
        "station_pressure_contact_ids_by_availability" => %{
          "unavailable" => ["dl_campaign_station"]
        },
        "station_pressure_contact_counts_by_precedence_availability" => %{"unavailable" => 1},
        "station_pressure_contact_ids_by_precedence_availability" => %{
          "unavailable" => ["dl_campaign_station"]
        },
        "station_pressure_contact_counts_by_precedence_rank" => %{"0" => 1},
        "station_pressure_contact_ids_by_precedence_rank" => %{
          "0" => ["dl_campaign_station"]
        },
        "station_pressure_contact_counts_by_status" => %{"maintenance_window" => 1},
        "station_pressure_contact_ids_by_status" => %{
          "maintenance_window" => ["dl_campaign_station"]
        },
        "station_pressure_contact_ids_by_direction" => %{
          "downlink" => ["dl_campaign_station"]
        },
        "station_pressure_contact_ids_by_direction_and_ground_station_id" => %{
          "downlink" => %{"gs_campaign" => ["dl_campaign_station"]}
        },
        "capacity_pack_required_capacity_fraction" => 0.25,
        "capacity_pack_selected_required_capacity_fraction" => 0.25,
        "capacity_pack_deferred_required_capacity_fraction" => 0.0,
        "capacity_pack_required_capacity_fraction_by_status" => %{
          "selected_by_reduced_station_capacity_pack" => 0.25
        },
        "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
          "gs_campaign" => 0.25
        },
        "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" => %{
          "gs_campaign" => 0.25
        },
        "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" => %{},
        "capacity_pack_contact_ids_by_status" => %{
          "selected_by_reduced_station_capacity_pack" => ["dl_campaign_pack"]
        },
        "capacity_pack_contact_ids_by_direction" => %{
          "downlink" => ["dl_campaign_pack"]
        },
        "capacity_pack_selected_contact_ids_by_direction" => %{
          "downlink" => ["dl_campaign_pack"]
        },
        "capacity_pack_deferred_contact_ids_by_direction" => %{},
        "required_capacity_fraction_source_counts" => %{"contact_required_capacity_fraction" => 1},
        "required_capacity_fraction_contact_ids_by_source" => %{
          "contact_required_capacity_fraction" => ["dl_campaign_pack"]
        },
        "capacity_pack_contact_ids_by_ground_station_id" => %{
          "gs_campaign" => ["dl_campaign_pack"]
        },
        "capacity_pack_selected_contact_ids_by_ground_station_id" => %{
          "gs_campaign" => ["dl_campaign_pack"]
        },
        "reduced_capacity_pack_group_count" => 1,
        "reduced_capacity_pack_status_counts" => %{"all_fit" => 1},
        "capacity_pack_group_ids" => ["pack_campaign"],
        "capacity_pack_group_ids_by_status" => %{"all_fit" => ["pack_campaign"]},
        "reduced_capacity_packed_contact_ids" => ["dl_campaign_pack"],
        "reduced_capacity_deferred_contact_ids" => []
      })

    refresh_summary =
      contact_allocation_summary(%{"missing" => 2}, %{
        "station_reservation_ids" => ["reservation_refresh"],
        "station_reserved_bys" => ["ops_refresh"],
        "station_reservation_statuses" => ["tentative"],
        "station_reservation_match_status_counts" => %{"overlap" => 2},
        "station_reservation_expiration_status_counts" => %{"missing" => 2},
        "station_reservation_declared_expiration_contact_count" => 0,
        "station_reservation_missing_expiration_contact_count" => 2,
        "station_reservation_contact_ids_by_expiration_status" => %{
          "missing" => ["dl_refresh_a", "dl_refresh_b"]
        },
        "station_reservation_ids_by_expiration_status" => %{
          "missing" => ["reservation_refresh"]
        },
        "reservation_conflict_contact_ids_by_direction" => %{
          "downlink" => ["dl_refresh_conflict_a", "dl_refresh_conflict_b"]
        },
        "reservation_conflict_contact_ids_by_direction_and_ground_station_id" => %{
          "downlink" => %{
            "gs_refresh" => ["dl_refresh_conflict_a", "dl_refresh_conflict_b"]
          }
        },
        "resource_blocking_dimension_counts" => %{"thermal" => 2},
        "resource_blocked_contact_ids_by_blocking_dimension" => %{
          "thermal" => ["dl_refresh_resource_a", "dl_refresh_resource_b"]
        },
        "resource_blocked_contact_ids_by_spacecraft_id" => %{
          "sat_refresh" => ["dl_refresh_resource_a", "dl_refresh_resource_b"]
        },
        "station_pressure_contact_count" => 2,
        "station_pressure_contact_ids" => ["dl_refresh_station_a", "dl_refresh_station_b"],
        "station_pressure_review_contact_count" => 1,
        "station_pressure_review_contact_ids" => ["dl_refresh_station_a"],
        "station_pressure_contact_counts_by_ground_station_id" => %{"gs_refresh" => 2},
        "station_pressure_contact_ids_by_ground_station_id" => %{
          "gs_refresh" => ["dl_refresh_station_a", "dl_refresh_station_b"]
        },
        "station_pressure_contact_counts_by_availability" => %{"reserved" => 2},
        "station_pressure_contact_ids_by_availability" => %{
          "reserved" => ["dl_refresh_station_a", "dl_refresh_station_b"]
        },
        "station_pressure_contact_counts_by_precedence_availability" => %{"reserved" => 1},
        "station_pressure_contact_ids_by_precedence_availability" => %{
          "reserved" => ["dl_refresh_station_a"]
        },
        "station_pressure_contact_counts_by_precedence_rank" => %{"1" => 1},
        "station_pressure_contact_ids_by_precedence_rank" => %{
          "1" => ["dl_refresh_station_a"]
        },
        "station_pressure_contact_counts_by_status" => %{"reservation_hold" => 2},
        "station_pressure_contact_ids_by_status" => %{
          "reservation_hold" => ["dl_refresh_station_a", "dl_refresh_station_b"]
        },
        "station_pressure_contact_ids_by_direction" => %{
          "downlink" => ["dl_refresh_station_a", "dl_refresh_station_b"]
        },
        "station_pressure_contact_ids_by_direction_and_ground_station_id" => %{
          "downlink" => %{"gs_refresh" => ["dl_refresh_station_a", "dl_refresh_station_b"]}
        },
        "capacity_pack_required_capacity_fraction" => 0.5,
        "capacity_pack_selected_required_capacity_fraction" => 0.25,
        "capacity_pack_deferred_required_capacity_fraction" => 0.25,
        "capacity_pack_required_capacity_fraction_by_status" => %{
          "selected_by_reduced_station_capacity_pack" => 0.25,
          "deferred_by_reduced_station_capacity_pack" => 0.25
        },
        "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
          "gs_refresh" => 0.5
        },
        "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" => %{
          "gs_refresh" => 0.25
        },
        "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" => %{
          "gs_refresh" => 0.25
        },
        "capacity_pack_contact_ids_by_status" => %{
          "selected_by_reduced_station_capacity_pack" => ["dl_refresh_pack"],
          "deferred_by_reduced_station_capacity_pack" => ["dl_refresh_deferred"]
        },
        "capacity_pack_contact_ids_by_direction" => %{
          "downlink" => ["dl_refresh_pack", "dl_refresh_deferred"]
        },
        "capacity_pack_selected_contact_ids_by_direction" => %{
          "downlink" => ["dl_refresh_pack"]
        },
        "capacity_pack_deferred_contact_ids_by_direction" => %{
          "downlink" => ["dl_refresh_deferred"]
        },
        "required_capacity_fraction_source_counts" => %{
          "contact_required_capacity_fraction" => 1,
          "default_reduced_capacity_policy" => 1
        },
        "required_capacity_fraction_contact_ids_by_source" => %{
          "contact_required_capacity_fraction" => ["dl_refresh_pack"],
          "default_reduced_capacity_policy" => ["dl_refresh_deferred"]
        },
        "capacity_pack_contact_ids_by_ground_station_id" => %{
          "gs_refresh" => ["dl_refresh_pack", "dl_refresh_deferred"]
        },
        "capacity_pack_selected_contact_ids_by_ground_station_id" => %{
          "gs_refresh" => ["dl_refresh_pack"]
        },
        "capacity_pack_deferred_contact_ids_by_ground_station_id" => %{
          "gs_refresh" => ["dl_refresh_deferred"]
        },
        "reduced_capacity_pack_group_count" => 2,
        "reduced_capacity_pack_status_counts" => %{"capacity_limited" => 2},
        "capacity_pack_group_ids" => ["pack_refresh_a", "pack_refresh_b"],
        "capacity_pack_group_ids_by_status" => %{
          "capacity_limited" => ["pack_refresh_a", "pack_refresh_b"]
        },
        "reduced_capacity_packed_contact_ids" => ["dl_refresh_pack"],
        "reduced_capacity_deferred_contact_ids" => ["dl_refresh_deferred"]
      })

    source_summary =
      contact_allocation_summary(%{"missing" => 1}, %{
        "station_reservation_ids" => ["reservation_source"],
        "station_reserved_bys" => ["ops_source"],
        "station_reservation_statuses" => ["confirmed"],
        "station_reservation_match_status_counts" => %{"overlap" => 1},
        "station_reservation_expiration_status_counts" => %{"missing" => 1},
        "station_reservation_declared_expiration_contact_count" => 0,
        "station_reservation_missing_expiration_contact_count" => 1,
        "station_reservation_contact_ids_by_expiration_status" => %{
          "missing" => ["dl_source"]
        },
        "station_reservation_ids_by_expiration_status" => %{
          "missing" => ["reservation_source"]
        },
        "station_reservation_contact_ids_by_match_status" => %{
          "overlap" => ["dl_source"]
        },
        "station_reservation_contact_ids_by_status" => %{
          "confirmed" => ["dl_source"]
        },
        "station_reservation_contact_ids_by_reserved_by" => %{
          "ops_source" => ["dl_source"]
        },
        "station_reservation_ids_by_match_status" => %{
          "overlap" => ["reservation_source"]
        },
        "station_reservation_ids_by_status" => %{
          "confirmed" => ["reservation_source"]
        },
        "station_reservation_ids_by_reserved_by" => %{
          "ops_source" => ["reservation_source"]
        },
        "reservation_conflict_contact_ids_by_direction" => %{
          "downlink" => ["dl_source_conflict"]
        },
        "reservation_conflict_contact_ids_by_direction_and_ground_station_id" => %{
          "downlink" => %{"gs_source" => ["dl_source_conflict"]}
        },
        "resource_blocking_dimension_counts" => %{"antenna" => 1},
        "resource_blocked_contact_ids_by_blocking_dimension" => %{
          "antenna" => ["dl_source_resource"]
        },
        "resource_blocked_contact_ids_by_spacecraft_id" => %{
          "sat_source" => ["dl_source_resource"]
        },
        "station_pressure_contact_count" => 1,
        "station_pressure_contact_ids" => ["dl_source_station", "dl_source_station"],
        "station_pressure_review_contact_count" => 1,
        "station_pressure_review_contact_ids" => ["dl_source_station"],
        "station_pressure_contact_counts_by_ground_station_id" => %{"gs_source" => 1},
        "station_pressure_contact_ids_by_ground_station_id" => %{
          "gs_source" => ["dl_source_station"]
        },
        "station_pressure_contact_counts_by_availability" => %{"unavailable" => 1},
        "station_pressure_contact_ids_by_availability" => %{
          "unavailable" => ["dl_source_station"]
        },
        "station_pressure_contact_counts_by_precedence_availability" => %{},
        "station_pressure_contact_ids_by_precedence_availability" => %{},
        "station_pressure_contact_counts_by_precedence_rank" => %{},
        "station_pressure_contact_ids_by_precedence_rank" => %{},
        "station_pressure_contact_ids_by_direction" => %{
          "downlink" => ["dl_source_station"]
        },
        "capacity_pack_required_capacity_fraction" => 0.35,
        "capacity_pack_selected_required_capacity_fraction" => 0.0,
        "capacity_pack_deferred_required_capacity_fraction" => 0.35,
        "capacity_pack_required_capacity_fraction_by_status" => %{
          "deferred_by_reduced_station_capacity_pack" => 0.35
        },
        "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
          "gs_source" => 0.35
        },
        "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" => %{},
        "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" => %{
          "gs_source" => 0.35
        },
        "capacity_pack_contact_ids_by_status" => %{
          "deferred_by_reduced_station_capacity_pack" => ["dl_source_deferred"]
        },
        "capacity_pack_contact_ids_by_direction" => %{
          "downlink" => ["dl_source_deferred"]
        },
        "capacity_pack_selected_contact_ids_by_direction" => %{},
        "capacity_pack_deferred_contact_ids_by_direction" => %{
          "downlink" => ["dl_source_deferred"]
        },
        "required_capacity_fraction_source_counts" => %{"capacity_model" => 1},
        "required_capacity_fraction_contact_ids_by_source" => %{
          "capacity_model" => ["dl_source_deferred"]
        },
        "capacity_pack_contact_ids_by_ground_station_id" => %{
          "gs_source" => ["dl_source_deferred"]
        },
        "capacity_pack_deferred_contact_ids_by_ground_station_id" => %{
          "gs_source" => ["dl_source_deferred"]
        },
        "reduced_capacity_pack_group_count" => 1,
        "reduced_capacity_pack_status_counts" => %{"capacity_limited" => 1},
        "capacity_pack_group_ids" => ["pack_source"],
        "capacity_pack_group_ids_by_status" => %{"capacity_limited" => ["pack_source"]},
        "reduced_capacity_packed_contact_ids" => [],
        "reduced_capacity_deferred_contact_ids" => ["dl_source_deferred"]
      })

    result_summary =
      contact_allocation_summary(%{"declared" => 2}, %{
        "station_reservation_ids" => ["reservation_result"],
        "station_reserved_bys" => ["ops_result"],
        "station_reservation_statuses" => ["released"],
        "station_reservation_match_status_counts" => %{"matched" => 2},
        "station_reservation_expiration_status_counts" => %{"declared" => 2},
        "station_reservation_declared_expiration_contact_count" => 2,
        "station_reservation_missing_expiration_contact_count" => 0,
        "earliest_station_reservation_expires_at_s" => 520.0,
        "station_reservation_contact_ids_by_expiration_status" => %{
          "declared" => ["dl_result_a", "dl_result_b"]
        },
        "station_reservation_ids_by_expiration_status" => %{
          "declared" => ["reservation_result"]
        },
        "station_reservation_contact_ids_by_match_status" => %{
          "matched" => ["dl_result_a", "dl_result_b"]
        },
        "station_reservation_contact_ids_by_status" => %{
          "released" => ["dl_result_a", "dl_result_b"]
        },
        "station_reservation_contact_ids_by_reserved_by" => %{
          "ops_result" => ["dl_result_a", "dl_result_b"]
        },
        "station_reservation_ids_by_match_status" => %{
          "matched" => ["reservation_result"]
        },
        "station_reservation_ids_by_status" => %{
          "released" => ["reservation_result"]
        },
        "station_reservation_ids_by_reserved_by" => %{
          "ops_result" => ["reservation_result"]
        },
        "reservation_conflict_contact_ids_by_direction" => %{
          "downlink" => ["dl_result_conflict_a", "dl_result_conflict_b"]
        },
        "reservation_conflict_contact_ids_by_direction_and_ground_station_id" => %{
          "downlink" => %{"gs_result" => ["dl_result_conflict_a", "dl_result_conflict_b"]}
        },
        "resource_blocking_dimension_counts" => %{"activity_type" => 2},
        "resource_blocked_contact_ids_by_blocking_dimension" => %{
          "activity_type" => ["dl_result_resource_a", "dl_result_resource_b"]
        },
        "resource_blocked_contact_ids_by_spacecraft_id" => %{
          "sat_result" => ["dl_result_resource_a", "dl_result_resource_b"]
        },
        "station_pressure_contact_count" => 2,
        "station_pressure_contact_ids" => ["dl_result_station_b", "dl_result_station_a"],
        "station_pressure_review_contact_count" => 0,
        "station_pressure_review_contact_ids" => [],
        "station_pressure_contact_counts_by_ground_station_id" => %{"gs_result" => 2},
        "station_pressure_contact_ids_by_ground_station_id" => %{
          "gs_result" => ["dl_result_station_a", "dl_result_station_b"]
        },
        "station_pressure_contact_counts_by_availability" => %{"reserved" => 2},
        "station_pressure_contact_ids_by_availability" => %{
          "reserved" => ["dl_result_station_a", "dl_result_station_b"]
        },
        "station_pressure_contact_counts_by_precedence_availability" => %{"reserved" => 2},
        "station_pressure_contact_ids_by_precedence_availability" => %{
          "reserved" => ["dl_result_station_a", "dl_result_station_b"]
        },
        "station_pressure_contact_counts_by_precedence_rank" => %{"2" => 2},
        "station_pressure_contact_ids_by_precedence_rank" => %{
          "2" => ["dl_result_station_a", "dl_result_station_b"]
        },
        "station_pressure_contact_ids_by_direction" => %{
          "downlink" => ["dl_result_station_a", "dl_result_station_b"]
        },
        "capacity_pack_required_capacity_fraction" => 0.6,
        "capacity_pack_selected_required_capacity_fraction" => 0.4,
        "capacity_pack_deferred_required_capacity_fraction" => 0.2,
        "capacity_pack_required_capacity_fraction_by_status" => %{
          "selected_by_reduced_station_capacity_pack" => 0.4,
          "deferred_by_reduced_station_capacity_pack" => 0.2
        },
        "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
          "gs_result" => 0.6
        },
        "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" => %{
          "gs_result" => 0.4
        },
        "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" => %{
          "gs_result" => 0.2
        },
        "capacity_pack_contact_ids_by_status" => %{
          "selected_by_reduced_station_capacity_pack" => ["dl_result_pack"],
          "deferred_by_reduced_station_capacity_pack" => ["dl_result_deferred"]
        },
        "capacity_pack_contact_ids_by_direction" => %{
          "downlink" => ["dl_result_pack", "dl_result_deferred"]
        },
        "capacity_pack_selected_contact_ids_by_direction" => %{
          "downlink" => ["dl_result_pack"]
        },
        "capacity_pack_deferred_contact_ids_by_direction" => %{
          "downlink" => ["dl_result_deferred"]
        },
        "required_capacity_fraction_source_counts" => %{
          "activity_context" => 1,
          "throughput_model" => 1
        },
        "required_capacity_fraction_contact_ids_by_source" => %{
          "activity_context" => ["dl_result_deferred"],
          "throughput_model" => ["dl_result_pack"]
        },
        "capacity_pack_contact_ids_by_ground_station_id" => %{
          "gs_result" => ["dl_result_pack", "dl_result_deferred"]
        },
        "capacity_pack_selected_contact_ids_by_ground_station_id" => %{
          "gs_result" => ["dl_result_pack"]
        },
        "capacity_pack_deferred_contact_ids_by_ground_station_id" => %{
          "gs_result" => ["dl_result_deferred"]
        },
        "reduced_capacity_pack_group_count" => 2,
        "reduced_capacity_pack_status_counts" => %{"all_fit" => 2},
        "capacity_pack_group_ids" => ["pack_result_a", "pack_result_b"],
        "capacity_pack_group_ids_by_status" => %{
          "all_fit" => ["pack_result_a", "pack_result_b"]
        },
        "reduced_capacity_packed_contact_ids" => ["dl_result_pack"],
        "reduced_capacity_deferred_contact_ids" => ["dl_result_deferred"]
      })

    campaign =
      OperatorReview.from_campaign_artifact(%{
        "plan_id" => "plan:calendar_counts",
        "contact_allocation_report" => campaign_summary
      })

    refresh =
      OperatorReview.from_candidate_refresh_artifact(%{
        "refresh_id" => "refresh:calendar_counts",
        "contact_allocation_report" => refresh_summary
      })

    repair =
      OperatorReview.from_repair_artifact(%{
        "repair_metadata" => %{"repair_id" => "repair:calendar_counts"},
        "source_contact_allocation_report" => source_summary,
        "contact_allocation_report" => result_summary
      })

    strategy =
      OperatorReview.from_strategy_artifact(%{
        "strategy_metadata" => %{"strategy_id" => "strategy:calendar_counts"},
        "branches" => [
          %{
            "branch_id" => "branch_calendar_counts",
            "repair_result" => %{
              "source_contact_allocation_report" => source_summary,
              "contact_allocation_report" => result_summary
            }
          }
        ]
      })

    assert campaign["calendar_entry_trust_boundary_status_counts"] == %{"declared" => 1}
    assert refresh["calendar_entry_trust_boundary_status_counts"] == %{"missing" => 2}

    assert repair["calendar_entry_trust_boundary_status_counts"] == %{
             "declared" => 2,
             "missing" => 1
           }

    assert strategy["calendar_entry_trust_boundary_status_counts"] == %{
             "declared" => 2,
             "missing" => 1
           }

    assert campaign["station_reservation_ids"] == ["reservation_campaign"]
    assert campaign["station_reserved_bys"] == ["ops_campaign"]
    assert campaign["station_reservation_statuses"] == ["confirmed"]
    assert campaign["station_reservation_match_status_counts"] == %{"matched" => 1}
    assert campaign["station_reservation_expiration_status_counts"] == %{"declared" => 1}
    assert campaign["station_reservation_declared_expiration_contact_count"] == 1
    assert campaign["station_reservation_missing_expiration_contact_count"] == 0
    assert campaign["earliest_station_reservation_expires_at_s"] == 410.0

    assert campaign["station_reservation_contact_ids_by_expiration_status"] == %{
             "declared" => ["dl_campaign"]
           }

    assert campaign["station_reservation_ids_by_expiration_status"] == %{
             "declared" => ["reservation_campaign"]
           }

    assert campaign["reservation_conflict_contact_ids_by_direction"] == %{
             "downlink" => ["dl_campaign_conflict"]
           }

    assert campaign["reservation_conflict_contact_ids_by_direction_and_ground_station_id"] == %{
             "downlink" => %{"gs_campaign" => ["dl_campaign_conflict"]}
           }

    assert campaign["resource_blocking_dimension_counts"] == %{"antenna" => 1}

    assert campaign["resource_blocked_contact_ids_by_blocking_dimension"] == %{
             "antenna" => ["dl_campaign_resource"]
           }

    assert campaign["resource_blocked_contact_ids_by_spacecraft_id"] == %{
             "sat_campaign" => ["dl_campaign_resource"]
           }

    assert campaign["station_pressure_contact_count"] == 1
    assert campaign["station_pressure_contact_ids"] == ["dl_campaign_station"]
    assert campaign["station_pressure_review_contact_count"] == 1
    assert campaign["station_pressure_review_contact_ids"] == ["dl_campaign_station"]

    assert campaign["station_pressure_contact_counts_by_ground_station_id"] == %{
             "gs_campaign" => 1
           }

    assert campaign["station_pressure_contact_ids_by_ground_station_id"] == %{
             "gs_campaign" => ["dl_campaign_station"]
           }

    assert campaign["station_pressure_contact_counts_by_availability"] == %{
             "unavailable" => 1
           }

    assert campaign["station_pressure_contact_ids_by_availability"] == %{
             "unavailable" => ["dl_campaign_station"]
           }

    assert campaign["station_pressure_contact_counts_by_precedence_availability"] == %{
             "unavailable" => 1
           }

    assert campaign["station_pressure_contact_ids_by_precedence_availability"] == %{
             "unavailable" => ["dl_campaign_station"]
           }

    assert campaign["station_pressure_contact_counts_by_precedence_rank"] == %{"0" => 1}

    assert campaign["station_pressure_contact_ids_by_precedence_rank"] == %{
             "0" => ["dl_campaign_station"]
           }

    assert campaign["station_pressure_contact_counts_by_status"] == %{
             "maintenance_window" => 1
           }

    assert campaign["station_pressure_contact_ids_by_status"] == %{
             "maintenance_window" => ["dl_campaign_station"]
           }

    assert campaign["station_pressure_contact_ids_by_direction"] == %{
             "downlink" => ["dl_campaign_station"]
           }

    assert campaign["station_pressure_contact_ids_by_direction_and_ground_station_id"] == %{
             "downlink" => %{"gs_campaign" => ["dl_campaign_station"]}
           }

    assert campaign["capacity_pack_required_capacity_fraction"] == 0.25
    assert campaign["capacity_pack_selected_required_capacity_fraction"] == 0.25
    assert campaign["capacity_pack_deferred_required_capacity_fraction"] == 0.0

    assert campaign["capacity_pack_required_capacity_fraction_by_status"] == %{
             "selected_by_reduced_station_capacity_pack" => 0.25
           }

    assert campaign["capacity_pack_required_capacity_fraction_by_ground_station_id"] == %{
             "gs_campaign" => 0.25
           }

    assert campaign["capacity_pack_selected_required_capacity_fraction_by_ground_station_id"] ==
             %{
               "gs_campaign" => 0.25
             }

    refute Map.has_key?(
             campaign,
             "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"
           )

    assert campaign["capacity_pack_contact_ids_by_status"] == %{
             "selected_by_reduced_station_capacity_pack" => ["dl_campaign_pack"]
           }

    assert campaign["capacity_pack_contact_ids_by_direction"] == %{
             "downlink" => ["dl_campaign_pack"]
           }

    assert campaign["capacity_pack_selected_contact_ids_by_direction"] == %{
             "downlink" => ["dl_campaign_pack"]
           }

    refute Map.has_key?(campaign, "capacity_pack_deferred_contact_ids_by_direction")

    assert campaign["required_capacity_fraction_source_counts"] == %{
             "contact_required_capacity_fraction" => 1
           }

    assert campaign["required_capacity_fraction_contact_ids_by_source"] == %{
             "contact_required_capacity_fraction" => ["dl_campaign_pack"]
           }

    assert campaign["capacity_pack_contact_ids_by_ground_station_id"] == %{
             "gs_campaign" => ["dl_campaign_pack"]
           }

    assert campaign["capacity_pack_selected_contact_ids_by_ground_station_id"] == %{
             "gs_campaign" => ["dl_campaign_pack"]
           }

    refute Map.has_key?(campaign, "capacity_pack_deferred_contact_ids_by_ground_station_id")

    assert campaign["reduced_capacity_pack_group_count"] == 1
    assert campaign["reduced_capacity_pack_status_counts"] == %{"all_fit" => 1}
    assert campaign["capacity_pack_group_ids"] == ["pack_campaign"]
    assert campaign["capacity_pack_group_ids_by_status"] == %{"all_fit" => ["pack_campaign"]}

    assert campaign["reduced_capacity_packed_contact_ids"] == ["dl_campaign_pack"]
    refute Map.has_key?(campaign, "reduced_capacity_deferred_contact_ids")

    assert refresh["station_reservation_ids"] == ["reservation_refresh"]
    assert refresh["station_reserved_bys"] == ["ops_refresh"]
    assert refresh["station_reservation_statuses"] == ["tentative"]
    assert refresh["station_reservation_match_status_counts"] == %{"overlap" => 2}
    assert refresh["station_reservation_expiration_status_counts"] == %{"missing" => 2}
    assert refresh["station_reservation_declared_expiration_contact_count"] == 0
    assert refresh["station_reservation_missing_expiration_contact_count"] == 2

    assert refresh["reservation_conflict_contact_ids_by_direction"] == %{
             "downlink" => ["dl_refresh_conflict_a", "dl_refresh_conflict_b"]
           }

    assert refresh["reservation_conflict_contact_ids_by_direction_and_ground_station_id"] == %{
             "downlink" => %{
               "gs_refresh" => ["dl_refresh_conflict_a", "dl_refresh_conflict_b"]
             }
           }

    assert refresh["resource_blocking_dimension_counts"] == %{"thermal" => 2}

    assert refresh["resource_blocked_contact_ids_by_blocking_dimension"] == %{
             "thermal" => ["dl_refresh_resource_a", "dl_refresh_resource_b"]
           }

    assert refresh["resource_blocked_contact_ids_by_spacecraft_id"] == %{
             "sat_refresh" => ["dl_refresh_resource_a", "dl_refresh_resource_b"]
           }

    assert refresh["station_pressure_contact_count"] == 2

    assert refresh["station_pressure_contact_ids"] == [
             "dl_refresh_station_a",
             "dl_refresh_station_b"
           ]

    assert refresh["station_pressure_review_contact_count"] == 1
    assert refresh["station_pressure_review_contact_ids"] == ["dl_refresh_station_a"]

    assert refresh["station_pressure_contact_counts_by_ground_station_id"] == %{
             "gs_refresh" => 2
           }

    assert refresh["station_pressure_contact_ids_by_ground_station_id"] == %{
             "gs_refresh" => ["dl_refresh_station_a", "dl_refresh_station_b"]
           }

    assert refresh["station_pressure_contact_counts_by_availability"] == %{"reserved" => 2}

    assert refresh["station_pressure_contact_ids_by_availability"] == %{
             "reserved" => ["dl_refresh_station_a", "dl_refresh_station_b"]
           }

    assert refresh["station_pressure_contact_counts_by_precedence_availability"] == %{
             "reserved" => 1
           }

    assert refresh["station_pressure_contact_ids_by_precedence_availability"] == %{
             "reserved" => ["dl_refresh_station_a"]
           }

    assert refresh["station_pressure_contact_counts_by_precedence_rank"] == %{"1" => 1}

    assert refresh["station_pressure_contact_ids_by_precedence_rank"] == %{
             "1" => ["dl_refresh_station_a"]
           }

    assert refresh["station_pressure_contact_counts_by_status"] == %{
             "reservation_hold" => 2
           }

    assert refresh["station_pressure_contact_ids_by_status"] == %{
             "reservation_hold" => ["dl_refresh_station_a", "dl_refresh_station_b"]
           }

    assert refresh["station_pressure_contact_ids_by_direction"] == %{
             "downlink" => ["dl_refresh_station_a", "dl_refresh_station_b"]
           }

    assert refresh["station_pressure_contact_ids_by_direction_and_ground_station_id"] == %{
             "downlink" => %{
               "gs_refresh" => ["dl_refresh_station_a", "dl_refresh_station_b"]
             }
           }

    assert refresh["capacity_pack_required_capacity_fraction"] == 0.5
    assert refresh["capacity_pack_selected_required_capacity_fraction"] == 0.25
    assert refresh["capacity_pack_deferred_required_capacity_fraction"] == 0.25

    assert refresh["capacity_pack_required_capacity_fraction_by_status"] == %{
             "selected_by_reduced_station_capacity_pack" => 0.25,
             "deferred_by_reduced_station_capacity_pack" => 0.25
           }

    assert refresh["capacity_pack_required_capacity_fraction_by_ground_station_id"] == %{
             "gs_refresh" => 0.5
           }

    assert refresh["capacity_pack_selected_required_capacity_fraction_by_ground_station_id"] == %{
             "gs_refresh" => 0.25
           }

    assert refresh["capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"] == %{
             "gs_refresh" => 0.25
           }

    assert refresh["capacity_pack_contact_ids_by_status"] == %{
             "selected_by_reduced_station_capacity_pack" => ["dl_refresh_pack"],
             "deferred_by_reduced_station_capacity_pack" => ["dl_refresh_deferred"]
           }

    assert refresh["capacity_pack_contact_ids_by_direction"] == %{
             "downlink" => ["dl_refresh_pack", "dl_refresh_deferred"]
           }

    assert refresh["capacity_pack_selected_contact_ids_by_direction"] == %{
             "downlink" => ["dl_refresh_pack"]
           }

    assert refresh["capacity_pack_deferred_contact_ids_by_direction"] == %{
             "downlink" => ["dl_refresh_deferred"]
           }

    assert refresh["required_capacity_fraction_source_counts"] == %{
             "contact_required_capacity_fraction" => 1,
             "default_reduced_capacity_policy" => 1
           }

    assert refresh["required_capacity_fraction_contact_ids_by_source"] == %{
             "contact_required_capacity_fraction" => ["dl_refresh_pack"],
             "default_reduced_capacity_policy" => ["dl_refresh_deferred"]
           }

    assert refresh["capacity_pack_contact_ids_by_ground_station_id"] == %{
             "gs_refresh" => ["dl_refresh_pack", "dl_refresh_deferred"]
           }

    assert refresh["capacity_pack_selected_contact_ids_by_ground_station_id"] == %{
             "gs_refresh" => ["dl_refresh_pack"]
           }

    assert refresh["capacity_pack_deferred_contact_ids_by_ground_station_id"] == %{
             "gs_refresh" => ["dl_refresh_deferred"]
           }

    assert refresh["reduced_capacity_pack_group_count"] == 2
    assert refresh["reduced_capacity_pack_status_counts"] == %{"capacity_limited" => 2}
    assert refresh["capacity_pack_group_ids"] == ["pack_refresh_a", "pack_refresh_b"]

    assert refresh["capacity_pack_group_ids_by_status"] == %{
             "capacity_limited" => ["pack_refresh_a", "pack_refresh_b"]
           }

    assert refresh["reduced_capacity_packed_contact_ids"] == ["dl_refresh_pack"]
    assert refresh["reduced_capacity_deferred_contact_ids"] == ["dl_refresh_deferred"]

    assert repair["station_reservation_ids"] == ["reservation_source", "reservation_result"]
    assert repair["station_reserved_bys"] == ["ops_source", "ops_result"]
    assert repair["station_reservation_statuses"] == ["confirmed", "released"]
    assert repair["station_reservation_match_status_counts"] == %{"matched" => 2, "overlap" => 1}

    assert repair["station_reservation_expiration_status_counts"] == %{
             "declared" => 2,
             "missing" => 1
           }

    assert repair["station_reservation_declared_expiration_contact_count"] == 2
    assert repair["station_reservation_missing_expiration_contact_count"] == 1
    assert repair["earliest_station_reservation_expires_at_s"] == 520.0

    assert repair["station_reservation_contact_ids_by_expiration_status"] == %{
             "declared" => ["dl_result_a", "dl_result_b"],
             "missing" => ["dl_source"]
           }

    assert repair["station_reservation_ids_by_expiration_status"] == %{
             "declared" => ["reservation_result"],
             "missing" => ["reservation_source"]
           }

    assert repair["station_reservation_contact_ids_by_match_status"] == %{
             "matched" => ["dl_result_a", "dl_result_b"],
             "overlap" => ["dl_source"]
           }

    assert repair["station_reservation_contact_ids_by_status"] == %{
             "confirmed" => ["dl_source"],
             "released" => ["dl_result_a", "dl_result_b"]
           }

    assert repair["station_reservation_contact_ids_by_reserved_by"] == %{
             "ops_result" => ["dl_result_a", "dl_result_b"],
             "ops_source" => ["dl_source"]
           }

    assert repair["station_reservation_ids_by_match_status"] == %{
             "matched" => ["reservation_result"],
             "overlap" => ["reservation_source"]
           }

    assert repair["station_reservation_ids_by_status"] == %{
             "confirmed" => ["reservation_source"],
             "released" => ["reservation_result"]
           }

    assert repair["station_reservation_ids_by_reserved_by"] == %{
             "ops_result" => ["reservation_result"],
             "ops_source" => ["reservation_source"]
           }

    assert repair["reservation_conflict_contact_ids_by_direction"] == %{
             "downlink" => [
               "dl_result_conflict_a",
               "dl_result_conflict_b",
               "dl_source_conflict"
             ]
           }

    assert repair["reservation_conflict_contact_ids_by_direction_and_ground_station_id"] == %{
             "downlink" => %{
               "gs_result" => ["dl_result_conflict_a", "dl_result_conflict_b"],
               "gs_source" => ["dl_source_conflict"]
             }
           }

    assert repair["resource_blocking_dimension_counts"] == %{"activity_type" => 2, "antenna" => 1}

    assert repair["resource_blocked_contact_ids_by_blocking_dimension"] == %{
             "activity_type" => ["dl_result_resource_a", "dl_result_resource_b"],
             "antenna" => ["dl_source_resource"]
           }

    assert repair["resource_blocked_contact_ids_by_spacecraft_id"] == %{
             "sat_result" => ["dl_result_resource_a", "dl_result_resource_b"],
             "sat_source" => ["dl_source_resource"]
           }

    assert repair["station_pressure_contact_count"] == 3

    assert repair["station_pressure_contact_ids"] == [
             "dl_result_station_a",
             "dl_result_station_b",
             "dl_source_station"
           ]

    assert repair["station_pressure_review_contact_count"] == 1
    assert repair["station_pressure_review_contact_ids"] == ["dl_source_station"]

    assert repair["station_pressure_contact_counts_by_ground_station_id"] == %{
             "gs_result" => 2,
             "gs_source" => 1
           }

    assert repair["station_pressure_contact_ids_by_ground_station_id"] == %{
             "gs_result" => ["dl_result_station_a", "dl_result_station_b"],
             "gs_source" => ["dl_source_station"]
           }

    assert repair["station_pressure_contact_counts_by_availability"] == %{
             "reserved" => 2,
             "unavailable" => 1
           }

    assert repair["station_pressure_contact_ids_by_availability"] == %{
             "reserved" => ["dl_result_station_a", "dl_result_station_b"],
             "unavailable" => ["dl_source_station"]
           }

    assert repair["station_pressure_contact_counts_by_precedence_availability"] == %{
             "reserved" => 2
           }

    assert repair["station_pressure_contact_ids_by_precedence_availability"] == %{
             "reserved" => ["dl_result_station_a", "dl_result_station_b"]
           }

    assert repair["station_pressure_contact_counts_by_precedence_rank"] == %{"2" => 2}

    assert repair["station_pressure_contact_ids_by_precedence_rank"] == %{
             "2" => ["dl_result_station_a", "dl_result_station_b"]
           }

    assert repair["station_pressure_contact_ids_by_direction"] == %{
             "downlink" => [
               "dl_result_station_a",
               "dl_result_station_b",
               "dl_source_station"
             ]
           }

    assert_in_delta repair["capacity_pack_required_capacity_fraction"], 0.95, 1.0e-9
    assert repair["capacity_pack_selected_required_capacity_fraction"] == 0.4
    assert_in_delta repair["capacity_pack_deferred_required_capacity_fraction"], 0.55, 1.0e-9

    assert repair["capacity_pack_required_capacity_fraction_by_status"][
             "selected_by_reduced_station_capacity_pack"
           ] == 0.4

    assert_in_delta repair["capacity_pack_required_capacity_fraction_by_status"][
                      "deferred_by_reduced_station_capacity_pack"
                    ],
                    0.55,
                    1.0e-9

    assert repair["capacity_pack_required_capacity_fraction_by_ground_station_id"][
             "gs_result"
           ] == 0.6

    assert repair["capacity_pack_required_capacity_fraction_by_ground_station_id"][
             "gs_source"
           ] == 0.35

    assert repair["capacity_pack_selected_required_capacity_fraction_by_ground_station_id"] == %{
             "gs_result" => 0.4
           }

    assert repair["capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"][
             "gs_result"
           ] == 0.2

    assert repair["capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"][
             "gs_source"
           ] == 0.35

    assert repair["capacity_pack_contact_ids_by_status"] == %{
             "selected_by_reduced_station_capacity_pack" => ["dl_result_pack"],
             "deferred_by_reduced_station_capacity_pack" => [
               "dl_result_deferred",
               "dl_source_deferred"
             ]
           }

    assert repair["capacity_pack_contact_ids_by_direction"] == %{
             "downlink" => ["dl_result_deferred", "dl_result_pack", "dl_source_deferred"]
           }

    assert repair["capacity_pack_selected_contact_ids_by_direction"] == %{
             "downlink" => ["dl_result_pack"]
           }

    assert repair["capacity_pack_deferred_contact_ids_by_direction"] == %{
             "downlink" => ["dl_result_deferred", "dl_source_deferred"]
           }

    assert repair["required_capacity_fraction_source_counts"] == %{
             "activity_context" => 1,
             "capacity_model" => 1,
             "throughput_model" => 1
           }

    assert repair["required_capacity_fraction_contact_ids_by_source"] == %{
             "activity_context" => ["dl_result_deferred"],
             "capacity_model" => ["dl_source_deferred"],
             "throughput_model" => ["dl_result_pack"]
           }

    assert repair["capacity_pack_contact_ids_by_ground_station_id"] == %{
             "gs_result" => ["dl_result_pack", "dl_result_deferred"],
             "gs_source" => ["dl_source_deferred"]
           }

    assert repair["capacity_pack_selected_contact_ids_by_ground_station_id"] == %{
             "gs_result" => ["dl_result_pack"]
           }

    assert repair["capacity_pack_deferred_contact_ids_by_ground_station_id"] == %{
             "gs_result" => ["dl_result_deferred"],
             "gs_source" => ["dl_source_deferred"]
           }

    assert repair["reduced_capacity_pack_group_count"] == 3

    assert repair["reduced_capacity_pack_status_counts"] == %{
             "all_fit" => 2,
             "capacity_limited" => 1
           }

    assert repair["capacity_pack_group_ids"] == [
             "pack_source",
             "pack_result_a",
             "pack_result_b"
           ]

    assert repair["capacity_pack_group_ids_by_status"] == %{
             "all_fit" => ["pack_result_a", "pack_result_b"],
             "capacity_limited" => ["pack_source"]
           }

    assert repair["reduced_capacity_packed_contact_ids"] == ["dl_result_pack"]

    assert repair["reduced_capacity_deferred_contact_ids"] == [
             "dl_source_deferred",
             "dl_result_deferred"
           ]

    assert strategy["station_reservation_ids"] == ["reservation_source", "reservation_result"]
    assert strategy["station_reserved_bys"] == ["ops_source", "ops_result"]
    assert strategy["station_reservation_statuses"] == ["confirmed", "released"]

    assert strategy["station_reservation_match_status_counts"] == %{
             "matched" => 2,
             "overlap" => 1
           }

    assert strategy["station_reservation_expiration_status_counts"] == %{
             "declared" => 2,
             "missing" => 1
           }

    assert strategy["station_reservation_declared_expiration_contact_count"] == 2
    assert strategy["station_reservation_missing_expiration_contact_count"] == 1
    assert strategy["earliest_station_reservation_expires_at_s"] == 520.0

    assert strategy["station_reservation_contact_ids_by_match_status"] == %{
             "matched" => ["dl_result_a", "dl_result_b"],
             "overlap" => ["dl_source"]
           }

    assert strategy["station_reservation_contact_ids_by_status"] == %{
             "confirmed" => ["dl_source"],
             "released" => ["dl_result_a", "dl_result_b"]
           }

    assert strategy["station_reservation_contact_ids_by_reserved_by"] == %{
             "ops_result" => ["dl_result_a", "dl_result_b"],
             "ops_source" => ["dl_source"]
           }

    assert strategy["station_reservation_ids_by_match_status"] == %{
             "matched" => ["reservation_result"],
             "overlap" => ["reservation_source"]
           }

    assert strategy["station_reservation_ids_by_status"] == %{
             "confirmed" => ["reservation_source"],
             "released" => ["reservation_result"]
           }

    assert strategy["station_reservation_ids_by_reserved_by"] == %{
             "ops_result" => ["reservation_result"],
             "ops_source" => ["reservation_source"]
           }

    assert strategy["reservation_conflict_contact_ids_by_direction"] == %{
             "downlink" => [
               "dl_result_conflict_a",
               "dl_result_conflict_b",
               "dl_source_conflict"
             ]
           }

    assert strategy["reservation_conflict_contact_ids_by_direction_and_ground_station_id"] == %{
             "downlink" => %{
               "gs_result" => ["dl_result_conflict_a", "dl_result_conflict_b"],
               "gs_source" => ["dl_source_conflict"]
             }
           }

    assert strategy["resource_blocking_dimension_counts"] == %{
             "activity_type" => 2,
             "antenna" => 1
           }

    assert strategy["resource_blocked_contact_ids_by_blocking_dimension"] == %{
             "activity_type" => ["dl_result_resource_a", "dl_result_resource_b"],
             "antenna" => ["dl_source_resource"]
           }

    assert strategy["resource_blocked_contact_ids_by_spacecraft_id"] == %{
             "sat_result" => ["dl_result_resource_a", "dl_result_resource_b"],
             "sat_source" => ["dl_source_resource"]
           }

    assert strategy["station_pressure_contact_count"] == 3

    assert strategy["station_pressure_contact_ids"] == [
             "dl_result_station_a",
             "dl_result_station_b",
             "dl_source_station"
           ]

    assert strategy["station_pressure_review_contact_count"] == 1
    assert strategy["station_pressure_review_contact_ids"] == ["dl_source_station"]

    assert strategy["station_pressure_contact_counts_by_ground_station_id"] == %{
             "gs_result" => 2,
             "gs_source" => 1
           }

    assert strategy["station_pressure_contact_ids_by_ground_station_id"] == %{
             "gs_result" => ["dl_result_station_a", "dl_result_station_b"],
             "gs_source" => ["dl_source_station"]
           }

    assert strategy["station_pressure_contact_counts_by_availability"] == %{
             "reserved" => 2,
             "unavailable" => 1
           }

    assert strategy["station_pressure_contact_ids_by_availability"] == %{
             "reserved" => ["dl_result_station_a", "dl_result_station_b"],
             "unavailable" => ["dl_source_station"]
           }

    assert strategy["station_pressure_contact_counts_by_precedence_availability"] ==
             %{"reserved" => 2}

    assert strategy["station_pressure_contact_ids_by_precedence_availability"] == %{
             "reserved" => ["dl_result_station_a", "dl_result_station_b"]
           }

    assert strategy["station_pressure_contact_counts_by_precedence_rank"] == %{"2" => 2}

    assert strategy["station_pressure_contact_ids_by_precedence_rank"] == %{
             "2" => ["dl_result_station_a", "dl_result_station_b"]
           }

    assert strategy["station_pressure_contact_ids_by_direction"] == %{
             "downlink" => [
               "dl_result_station_a",
               "dl_result_station_b",
               "dl_source_station"
             ]
           }

    assert_in_delta strategy["capacity_pack_required_capacity_fraction"], 0.95, 1.0e-9
    assert strategy["capacity_pack_selected_required_capacity_fraction"] == 0.4
    assert_in_delta strategy["capacity_pack_deferred_required_capacity_fraction"], 0.55, 1.0e-9

    assert strategy["capacity_pack_required_capacity_fraction_by_status"][
             "selected_by_reduced_station_capacity_pack"
           ] == 0.4

    assert_in_delta strategy["capacity_pack_required_capacity_fraction_by_status"][
                      "deferred_by_reduced_station_capacity_pack"
                    ],
                    0.55,
                    1.0e-9

    assert strategy["capacity_pack_required_capacity_fraction_by_ground_station_id"][
             "gs_result"
           ] == 0.6

    assert strategy["capacity_pack_required_capacity_fraction_by_ground_station_id"][
             "gs_source"
           ] == 0.35

    assert strategy["capacity_pack_selected_required_capacity_fraction_by_ground_station_id"] ==
             %{"gs_result" => 0.4}

    assert strategy["capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"][
             "gs_result"
           ] == 0.2

    assert strategy["capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"][
             "gs_source"
           ] == 0.35

    assert strategy["capacity_pack_contact_ids_by_status"] == %{
             "selected_by_reduced_station_capacity_pack" => ["dl_result_pack"],
             "deferred_by_reduced_station_capacity_pack" => [
               "dl_result_deferred",
               "dl_source_deferred"
             ]
           }

    assert strategy["capacity_pack_contact_ids_by_direction"] == %{
             "downlink" => ["dl_result_deferred", "dl_result_pack", "dl_source_deferred"]
           }

    assert strategy["capacity_pack_selected_contact_ids_by_direction"] ==
             %{"downlink" => ["dl_result_pack"]}

    assert strategy["capacity_pack_deferred_contact_ids_by_direction"] == %{
             "downlink" => ["dl_result_deferred", "dl_source_deferred"]
           }

    assert strategy["required_capacity_fraction_source_counts"] == %{
             "activity_context" => 1,
             "capacity_model" => 1,
             "throughput_model" => 1
           }

    assert strategy["required_capacity_fraction_contact_ids_by_source"] == %{
             "activity_context" => ["dl_result_deferred"],
             "capacity_model" => ["dl_source_deferred"],
             "throughput_model" => ["dl_result_pack"]
           }

    assert strategy["capacity_pack_contact_ids_by_ground_station_id"] == %{
             "gs_result" => ["dl_result_pack", "dl_result_deferred"],
             "gs_source" => ["dl_source_deferred"]
           }

    assert strategy["capacity_pack_selected_contact_ids_by_ground_station_id"] ==
             %{"gs_result" => ["dl_result_pack"]}

    assert strategy["capacity_pack_deferred_contact_ids_by_ground_station_id"] == %{
             "gs_result" => ["dl_result_deferred"],
             "gs_source" => ["dl_source_deferred"]
           }

    assert strategy["reduced_capacity_pack_group_count"] == 3

    assert strategy["reduced_capacity_pack_status_counts"] == %{
             "all_fit" => 2,
             "capacity_limited" => 1
           }

    assert strategy["capacity_pack_group_ids"] == [
             "pack_source",
             "pack_result_a",
             "pack_result_b"
           ]

    assert strategy["capacity_pack_group_ids_by_status"] == %{
             "all_fit" => ["pack_result_a", "pack_result_b"],
             "capacity_limited" => ["pack_source"]
           }

    assert strategy["reduced_capacity_packed_contact_ids"] == ["dl_result_pack"]

    assert strategy["reduced_capacity_deferred_contact_ids"] == [
             "dl_source_deferred",
             "dl_result_deferred"
           ]

    for package <- [campaign, refresh, repair, strategy] do
      assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
               Schema.validate_artifact(package)
    end
  end

  test "correlates station-pressure identity across overlapping embedded summaries" do
    repair =
      OperatorReview.from_repair_artifact(%{
        "repair_metadata" => %{"repair_id" => "repair:station_pressure_overlap"},
        "source_contact_allocation_report" => %{
          "station_pressure_contact_count" => 2,
          "station_pressure_contact_ids" => ["contact_source", "contact_shared"],
          "station_pressure_contact_counts_by_ground_station_id" => %{"gs_shared" => 2},
          "station_pressure_contact_ids_by_ground_station_id" => %{
            "gs_shared" => ["contact_source", "contact_shared"]
          },
          "station_pressure_contact_counts_by_availability" => %{"reserved" => 2},
          "station_pressure_contact_ids_by_availability" => %{
            "reserved" => ["contact_source", "contact_shared"]
          },
          "station_pressure_contact_counts_by_precedence_availability" => %{"reserved" => 2},
          "station_pressure_contact_ids_by_precedence_availability" => %{
            "reserved" => ["contact_source", "contact_shared"]
          },
          "station_pressure_contact_counts_by_precedence_rank" => %{"1" => 2},
          "station_pressure_contact_ids_by_precedence_rank" => %{
            "1" => ["contact_source", "contact_shared"]
          },
          "station_pressure_contact_counts_by_status" => %{"reservation_hold" => 2},
          "station_pressure_contact_ids_by_status" => %{
            "reservation_hold" => ["contact_source", "contact_shared"]
          }
        },
        "contact_allocation_report" => %{
          "station_pressure_contact_count" => 2,
          "station_pressure_contact_ids" => ["contact_shared", "contact_result"],
          "station_pressure_contact_counts_by_ground_station_id" => %{"gs_shared" => 2},
          "station_pressure_contact_ids_by_ground_station_id" => %{
            "gs_shared" => ["contact_shared", "contact_result"]
          },
          "station_pressure_contact_counts_by_availability" => %{"reserved" => 2},
          "station_pressure_contact_ids_by_availability" => %{
            "reserved" => ["contact_shared", "contact_result"]
          },
          "station_pressure_contact_counts_by_precedence_availability" => %{"reserved" => 2},
          "station_pressure_contact_ids_by_precedence_availability" => %{
            "reserved" => ["contact_shared", "contact_result"]
          },
          "station_pressure_contact_counts_by_precedence_rank" => %{"1" => 2},
          "station_pressure_contact_ids_by_precedence_rank" => %{
            "1" => ["contact_shared", "contact_result"]
          },
          "station_pressure_contact_counts_by_status" => %{"reservation_hold" => 2},
          "station_pressure_contact_ids_by_status" => %{
            "reservation_hold" => ["contact_shared", "contact_result"]
          }
        }
      })

    explicit_empty =
      OperatorReview.from_campaign_artifact(%{
        "plan_id" => "plan:station_pressure_empty",
        "contact_allocation_report" => %{
          "station_pressure_contact_count" => 9,
          "station_pressure_contact_ids" => [],
          "station_pressure_contact_counts_by_ground_station_id" => %{"gs_empty" => 9},
          "station_pressure_contact_ids_by_ground_station_id" => %{"gs_empty" => []}
        }
      })

    scalar_only =
      OperatorReview.from_campaign_artifact(%{
        "plan_id" => "plan:station_pressure_scalar",
        "contact_allocation_report" => %{
          "station_pressure_contact_count" => 2,
          "station_pressure_contact_counts_by_ground_station_id" => %{"gs_scalar" => 2}
        }
      })

    assert repair["station_pressure_contact_count"] == 3

    assert repair["station_pressure_contact_ids"] == [
             "contact_result",
             "contact_shared",
             "contact_source"
           ]

    expected_group_ids = ["contact_result", "contact_shared", "contact_source"]

    for {count_field, id_field, key} <- [
          {"station_pressure_contact_counts_by_ground_station_id",
           "station_pressure_contact_ids_by_ground_station_id", "gs_shared"},
          {"station_pressure_contact_counts_by_availability",
           "station_pressure_contact_ids_by_availability", "reserved"},
          {"station_pressure_contact_counts_by_precedence_availability",
           "station_pressure_contact_ids_by_precedence_availability", "reserved"},
          {"station_pressure_contact_counts_by_precedence_rank",
           "station_pressure_contact_ids_by_precedence_rank", "1"},
          {"station_pressure_contact_counts_by_status", "station_pressure_contact_ids_by_status",
           "reservation_hold"}
        ] do
      assert repair[count_field] == %{key => 3}
      assert repair[id_field] == %{key => expected_group_ids}
    end

    assert explicit_empty["station_pressure_contact_count"] == 0
    assert explicit_empty["station_pressure_contact_ids"] == []

    assert explicit_empty["station_pressure_contact_counts_by_ground_station_id"] == %{
             "gs_empty" => 0
           }

    assert explicit_empty["station_pressure_contact_ids_by_ground_station_id"] == %{
             "gs_empty" => []
           }

    assert scalar_only["station_pressure_contact_count"] == 2

    assert scalar_only["station_pressure_contact_counts_by_ground_station_id"] == %{
             "gs_scalar" => 2
           }

    refute Map.has_key?(scalar_only, "station_pressure_contact_ids")
    refute Map.has_key?(scalar_only, "station_pressure_contact_ids_by_ground_station_id")

    for package <- [repair, explicit_empty, scalar_only] do
      assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
               Schema.validate_artifact(package)
    end
  end

  defp contact_allocation_summary(counts, summary) do
    %{
      "schema_contract" => "contact_allocation_report.v1",
      "calendar_entry_trust_boundary_status_counts" => counts,
      "rows" => []
    }
    |> Map.merge(summary)
  end
end
