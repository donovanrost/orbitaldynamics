defmodule OrbitalDynamics.CampaignPlanner.ContactAllocationPressureFixtures do
  def contact_allocation_capacity_pack_summary_fixture(prefix) do
    primary_row = capacity_pack_row(prefix, "primary", "selected_by_contention_resolution")

    secondary_row =
      capacity_pack_row(prefix, "secondary", "selected_by_reduced_station_capacity_pack")

    overflow_row =
      capacity_pack_row(prefix, "overflow", "deferred_by_reduced_station_capacity_pack")

    pack_group = %{
      "contention_group_id" => "#{prefix}_pack_equator_prime",
      "pack_status" => "capacity_limited",
      "ground_station_id" => "equator_prime",
      "capacity_fraction" => 0.5
    }

    all_contact_ids = capacity_pack_contact_ids(prefix)
    selected_contact_ids = Enum.drop(all_contact_ids, 1)

    %{
      "schema_contract" => "contact_allocation_capacity_pack_summary.v1",
      "model" => "artifact_only_contact_allocation_capacity_pack_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source" => "campaign_planner_test.#{prefix}.contact_allocation_capacity_pack_summary",
      "input_contact_count" => 3,
      "capacity_pack_contact_count" => 3,
      "capacity_pack_review_status" => "review_required",
      "reduced_capacity_pack_group_count" => 1,
      "reduced_capacity_pack_status_counts" => %{"capacity_limited" => 1},
      "capacity_pack_status_counts" => %{
        "deferred_by_reduced_station_capacity_pack" => 1,
        "selected_by_contention_resolution" => 1,
        "selected_by_reduced_station_capacity_pack" => 1
      },
      "capacity_pack_contact_ids_by_status" => %{
        "deferred_by_reduced_station_capacity_pack" => ["#{prefix}_dl_capacity_overflow"],
        "selected_by_contention_resolution" => ["#{prefix}_dl_capacity_primary"],
        "selected_by_reduced_station_capacity_pack" => ["#{prefix}_dl_capacity_secondary"]
      },
      "capacity_pack_contact_ids_by_ground_station_id" => %{
        "equator_prime" => all_contact_ids
      },
      "capacity_pack_selected_contact_ids_by_ground_station_id" => %{
        "equator_prime" => selected_contact_ids
      },
      "capacity_pack_deferred_contact_ids_by_ground_station_id" => %{
        "equator_prime" => ["#{prefix}_dl_capacity_overflow"]
      },
      "capacity_pack_contact_ids_by_direction" => %{"downlink" => all_contact_ids},
      "capacity_pack_selected_contact_ids_by_direction" => %{
        "downlink" => selected_contact_ids
      },
      "capacity_pack_deferred_contact_ids_by_direction" => %{
        "downlink" => ["#{prefix}_dl_capacity_overflow"]
      },
      "capacity_pack_required_capacity_fraction" => 0.75,
      "capacity_pack_selected_required_capacity_fraction" => 0.5,
      "capacity_pack_deferred_required_capacity_fraction" => 0.25,
      "capacity_pack_required_capacity_fraction_by_status" => %{
        "deferred_by_reduced_station_capacity_pack" => 0.25,
        "selected_by_contention_resolution" => 0.25,
        "selected_by_reduced_station_capacity_pack" => 0.25
      },
      "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
        "equator_prime" => 0.75
      },
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" => %{
        "equator_prime" => 0.5
      },
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" => %{
        "equator_prime" => 0.25
      },
      "capacity_pack_required_capacity_fraction_by_direction" => %{"downlink" => 0.75},
      "capacity_pack_selected_required_capacity_fraction_by_direction" => %{
        "downlink" => 0.5
      },
      "capacity_pack_deferred_required_capacity_fraction_by_direction" => %{
        "downlink" => 0.25
      },
      "required_capacity_fraction_source_counts" => %{
        "contact_required_capacity_fraction" => 3
      },
      "required_capacity_fraction_contact_ids_by_source" => %{
        "contact_required_capacity_fraction" => all_contact_ids
      },
      "reduced_capacity_packed_contact_ids" => ["#{prefix}_dl_capacity_secondary"],
      "reduced_capacity_deferred_contact_ids" => ["#{prefix}_dl_capacity_overflow"],
      "capacity_pack_group_ids" => ["#{prefix}_pack_equator_prime"],
      "capacity_pack_group_ids_by_status" => %{
        "capacity_limited" => ["#{prefix}_pack_equator_prime"]
      },
      "rows" => [primary_row, secondary_row, overflow_row],
      "reduced_capacity_pack_groups" => [pack_group],
      "review_rows" => [primary_row, secondary_row, overflow_row],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "source" => "contact_allocation_report.v1",
        "operator_authority" => "not_granted_by_capacity_pack_summary"
      },
      "provenance" => %{"trust_boundary" => "#{prefix}_capacity_pack_fixture"}
    }
  end

  def contact_allocation_station_pressure_summary_fixture(prefix) do
    nominal_row = %{
      "contact_id" => "#{prefix}_dl_nominal",
      "allocation_status" => "allocated",
      "effective_allocation_status" => "allocated",
      "allocation_reason" => "selected_by_contention_resolution",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink"
    }

    station_pressure_row = %{
      "contact_id" => "#{prefix}_dl_station_pressure",
      "allocation_status" => "deferred",
      "effective_allocation_status" => "deferred",
      "allocation_reason" => "same_station_contention",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "station_calendar_entry_id" => "#{prefix}_station_reserved_1",
      "station_calendar_overlap_availabilities" => ["reserved"],
      "station_calendar_precedence_availability" => "reserved",
      "station_calendar_precedence_rank" => 2
    }

    %{
      "schema_contract" => "contact_allocation_station_pressure_summary.v1",
      "model" => "artifact_only_contact_allocation_station_pressure_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source" => "campaign_planner_test.#{prefix}.contact_allocation_station_pressure_summary",
      "input_contact_count" => 2,
      "station_pressure_contact_count" => 1,
      "station_pressure_review_contact_count" => 1,
      "station_pressure_contact_ids" => ["#{prefix}_dl_station_pressure"],
      "station_pressure_review_contact_ids" => ["#{prefix}_dl_station_pressure"],
      "station_pressure_contact_ids_by_ground_station_id" => station_ids(prefix),
      "station_pressure_contact_counts_by_ground_station_id" => %{"equator_prime" => 1},
      "station_pressure_contact_ids_by_availability" => %{"reserved" => pressure_ids(prefix)},
      "station_pressure_contact_counts_by_availability" => %{"reserved" => 1},
      "station_pressure_contact_ids_by_precedence_availability" => %{
        "reserved" => pressure_ids(prefix)
      },
      "station_pressure_contact_counts_by_precedence_availability" => %{"reserved" => 1},
      "station_pressure_contact_ids_by_precedence_rank" => %{"2" => pressure_ids(prefix)},
      "station_pressure_contact_counts_by_precedence_rank" => %{"2" => 1},
      "rows" => [nominal_row, station_pressure_row],
      "review_rows" => [station_pressure_row],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "source" => "contact_allocation_report.v1",
        "operator_authority" => "not_granted_by_station_pressure_summary"
      },
      "provenance" => %{"trust_boundary" => "#{prefix}_station_pressure_fixture"}
    }
  end

  def contact_allocation_reservation_conflict_summary_fixture(prefix) do
    owner_row = reservation_row(prefix, "owner", "allocated", "matched")
    conflict_row = reservation_row(prefix, "intruder", "deferred", "overlap")

    %{
      "schema_contract" => "contact_allocation_reservation_conflict_summary.v1",
      "model" => "artifact_only_contact_allocation_reservation_conflict_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source" =>
        "campaign_planner_test.#{prefix}.contact_allocation_reservation_conflict_summary",
      "input_contact_count" => 2,
      "station_reservation_contact_count" => 2,
      "reservation_conflict_contact_count" => 1,
      "reservation_review_contact_count" => 1,
      "station_reservation_match_status_counts" => %{"matched" => 1, "overlap" => 1},
      "reservation_conflict_match_status_counts" => %{"overlap" => 1},
      "station_reservation_status_counts" => %{"confirmed" => 2},
      "station_reserved_by_counts" => %{"ops_team_b" => 2},
      "station_reservation_ids" => ["#{prefix}_reservation_1"],
      "station_reservation_expires_at_s" => [360.0],
      "station_reservation_expiration_now_s" => 400.0,
      "station_reservation_expiration_status_counts" => %{"expired" => 2},
      "earliest_station_reservation_expires_at_s" => 360.0,
      "reservation_conflict_contact_ids" => ["#{prefix}_dl_reserved_intruder"],
      "reservation_review_contact_ids" => ["#{prefix}_dl_reserved_intruder"],
      "station_reservation_contact_ids_by_match_status" => %{
        "matched" => ["#{prefix}_dl_reserved_owner"],
        "overlap" => ["#{prefix}_dl_reserved_intruder"]
      },
      "reservation_conflict_contact_ids_by_match_status" => %{
        "overlap" => ["#{prefix}_dl_reserved_intruder"]
      },
      "station_reservation_contact_ids_by_status" => %{
        "confirmed" => reserved_contact_ids(prefix)
      },
      "station_reservation_contact_ids_by_reserved_by" => %{
        "ops_team_b" => reserved_contact_ids(prefix)
      },
      "station_reservation_contact_ids_by_expiration_status" => %{
        "expired" => reserved_contact_ids(prefix)
      },
      "station_reservation_ids_by_match_status" => %{
        "matched" => ["#{prefix}_reservation_1"],
        "overlap" => ["#{prefix}_reservation_1"]
      },
      "reservation_conflict_reservation_ids_by_match_status" => %{
        "overlap" => ["#{prefix}_reservation_1"]
      },
      "station_reservation_ids_by_status" => %{"confirmed" => ["#{prefix}_reservation_1"]},
      "station_reservation_ids_by_reserved_by" => %{"ops_team_b" => ["#{prefix}_reservation_1"]},
      "station_reservation_ids_by_expiration_status" => %{
        "expired" => ["#{prefix}_reservation_1"]
      },
      "rows" => [owner_row, conflict_row],
      "reservation_conflict_rows" => [conflict_row],
      "reservation_review_rows" => [conflict_row],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "source" => "contact_allocation_report.v1",
        "operator_authority" => "not_granted_by_reservation_conflict_summary"
      },
      "provenance" => %{"trust_boundary" => "#{prefix}_reservation_conflict_fixture"}
    }
  end

  def contact_allocation_provider_reservation_request_summary_fixture(prefix) do
    request_row = %{
      "contact_id" => "#{prefix}_dl_reserved_owner",
      "allocation_status" => "allocated",
      "effective_allocation_status" => "allocated",
      "allocation_reason" => "selected_by_contention_resolution",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "station_reservation_id" => "#{prefix}_reservation_1",
      "station_reservation_match_status" => "matched",
      "station_reservation_status" => "confirmed"
    }

    review_row = %{
      "contact_id" => "#{prefix}_dl_review_overlap",
      "allocation_status" => "allocated",
      "effective_allocation_status" => "allocated",
      "allocation_reason" => "selected_by_contention_resolution",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "station_reservation_id" => "#{prefix}_reservation_review",
      "station_reservation_match_status" => "overlap",
      "station_reservation_status" => "confirmed"
    }

    %{
      "schema_contract" => "contact_allocation_provider_reservation_request_summary.v1",
      "model" => "artifact_only_contact_allocation_provider_reservation_request_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source" =>
        "campaign_planner_test.#{prefix}.contact_allocation_provider_reservation_request_summary",
      "provider_reservation_candidate_contact_count" => 2,
      "provider_reservation_request_contact_count" => 1,
      "provider_reservation_review_contact_count" => 1,
      "provider_reservation_no_request_contact_count" => 1,
      "provider_reservation_request_status" => "review_required",
      "provider_reservation_request_contact_ids" => ["#{prefix}_dl_reserved_owner"],
      "provider_reservation_review_contact_ids" => ["#{prefix}_dl_review_overlap"],
      "provider_reservation_no_request_contact_ids" => ["#{prefix}_dl_unreserved"],
      "provider_reservation_request_contact_ids_by_ground_station_id" => %{
        "equator_prime" => ["#{prefix}_dl_reserved_owner"]
      },
      "provider_reservation_review_contact_ids_by_ground_station_id" => %{
        "equator_prime" => ["#{prefix}_dl_review_overlap"]
      },
      "provider_reservation_request_contact_ids_by_match_status" => %{
        "matched" => ["#{prefix}_dl_reserved_owner"]
      },
      "provider_reservation_review_contact_ids_by_match_status" => %{
        "overlap" => ["#{prefix}_dl_review_overlap"]
      },
      "provider_reservation_request_ids_by_match_status" => %{
        "matched" => ["#{prefix}_reservation_1"]
      },
      "provider_reservation_review_ids_by_match_status" => %{
        "overlap" => ["#{prefix}_reservation_review"]
      },
      "provider_reservation_request_rows" => [request_row],
      "provider_reservation_review_rows" => [review_row],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "provider_reservation_execution" => "not_performed_by_summary"
      },
      "provenance" => %{"trust_boundary" => "#{prefix}_provider_reservation_request_fixture"}
    }
  end

  defp reservation_row(prefix, suffix, allocation_status, match_status) do
    %{
      "contact_id" => "#{prefix}_dl_reserved_#{suffix}",
      "allocation_status" => allocation_status,
      "effective_allocation_status" => allocation_status,
      "allocation_reason" =>
        if(allocation_status == "allocated",
          do: "selected_by_contention_resolution",
          else: "same_station_contention"
        ),
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "station_reservation_id" => "#{prefix}_reservation_1",
      "station_reservation_match_status" => match_status,
      "station_reservation_status" => "confirmed",
      "station_reserved_by" => "ops_team_b",
      "station_reservation_expires_at_s" => 360.0
    }
  end

  defp reserved_contact_ids(prefix),
    do: ["#{prefix}_dl_reserved_intruder", "#{prefix}_dl_reserved_owner"]

  defp pressure_ids(prefix), do: ["#{prefix}_dl_station_pressure"]
  defp station_ids(prefix), do: %{"equator_prime" => pressure_ids(prefix)}

  defp capacity_pack_row(prefix, suffix, status) do
    allocated? = status != "deferred_by_reduced_station_capacity_pack"
    allocation_status = if allocated?, do: "allocated", else: "deferred"

    %{
      "contact_id" => "#{prefix}_dl_capacity_#{suffix}",
      "allocation_status" => allocation_status,
      "effective_allocation_status" => allocation_status,
      "allocation_reason" => status,
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "capacity_pack_status" => status,
      "required_capacity_fraction" => 0.25,
      "required_capacity_fraction_source" => "contact_required_capacity_fraction"
    }
  end

  defp capacity_pack_contact_ids(prefix) do
    [
      "#{prefix}_dl_capacity_overflow",
      "#{prefix}_dl_capacity_primary",
      "#{prefix}_dl_capacity_secondary"
    ]
  end
end
