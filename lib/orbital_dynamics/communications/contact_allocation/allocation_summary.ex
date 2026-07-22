defmodule OrbitalDynamics.Communications.ContactAllocation.AllocationSummary do
  @moduledoc false

  @summary_schema_contract "contact_allocation_summary.v1"
  @schema_contract "contact_allocation_report.v1"
  @station_pressure_summary_schema_contract "contact_allocation_station_pressure_summary.v1"
  @capacity_pack_summary_schema_contract "contact_allocation_capacity_pack_summary.v1"
  @reservation_conflict_summary_schema_contract "contact_allocation_reservation_conflict_summary.v1"
  @provider_reservation_request_summary_schema_contract "contact_allocation_provider_reservation_request_summary.v1"
  @unavailable_aliases ["outage", "down", "offline"]
  @provider_direction_aliases %{
    "cmd" => "command",
    "commanding" => "command",
    "commands" => "command",
    "sband_command" => "command",
    "s_band_command" => "command",
    "up" => "uplink",
    "up_link" => "uplink",
    "dl" => "downlink",
    "down" => "downlink",
    "downlinking" => "downlink",
    "down_link" => "downlink",
    "track" => "tracking",
    "track_ing" => "tracking",
    "tracking_pass" => "tracking",
    "health" => "health_check",
    "healthcheck" => "health_check",
    "health_check_window" => "health_check"
  }

  def build(report, opts, model_limits, capability_assumptions) do
    report = stringify_keys(report)
    now_s = Keyword.get(opts, :now_s)

    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)
      |> Enum.map(&normalize_station_calendar_status_fields/1)
      |> Enum.map(&ensure_effective_allocation_status/1)

    review_rows = Enum.filter(rows, &allocation_summary_review_row?/1)
    station_pressure_rows = station_pressure_summary_rows(rows)

    station_pressure_contact_ids_by_ground_station_id =
      contact_ids_by_field(station_pressure_rows, "ground_station_id")

    station_pressure_contact_ids_by_availability =
      station_pressure_contact_ids_by_availability(station_pressure_rows)

    station_pressure_contact_ids_by_precedence_availability =
      contact_ids_by_field(station_pressure_rows, "station_calendar_precedence_availability")

    station_pressure_contact_ids_by_precedence_rank =
      contact_ids_by_string_field(station_pressure_rows, "station_calendar_precedence_rank")

    station_pressure_contact_ids_by_status =
      contact_ids_by_field(station_pressure_rows, "station_calendar_status")

    station_pressure_contact_ids_by_direction_and_ground_station_id =
      contact_ids_by_direction_and_ground_station_id(station_pressure_rows)

    capacity_pack_rows = capacity_pack_summary_rows(rows)
    selected_capacity_pack_rows = selected_capacity_pack_summary_rows(capacity_pack_rows)
    deferred_capacity_pack_rows = deferred_capacity_pack_summary_rows(capacity_pack_rows)
    reservation_expiration_rows = station_reservation_expiration_summary_rows(rows, now_s)

    %{
      "schema_contract" => @summary_schema_contract,
      "model" => "artifact_only_contact_allocation_summary",
      "source_artifact_type" => Map.get(report, "schema_contract", @schema_contract),
      "source" => report["source"],
      "input_contact_count" => length(rows),
      "allocated_contact_count" =>
        allocation_summary_count(rows, "allocation_status", "allocated"),
      "returned_allocated_contact_count" =>
        allocation_summary_count(rows, "effective_allocation_status", "allocated"),
      "policy_blocked_allocated_contact_count" =>
        allocation_summary_count(rows, "effective_allocation_status", "policy_blocked"),
      "deferred_contact_count" => allocation_summary_count(rows, "allocation_status", "deferred"),
      "blocked_contact_count" => allocation_summary_count(rows, "allocation_status", "blocked"),
      "invalid_contact_input_count" => invalid_allocation_input_count(rows),
      "status_blocked_contact_count" => status_blocked_allocation_count(rows),
      "resource_blocked_contact_count" => resource_blocked_contact_count(rows),
      "duplicate_contact_id_count" => duplicate_contact_group_count(rows),
      "reduced_capacity_pack_group_count" => length(report["reduced_capacity_pack_groups"] || []),
      "reduced_capacity_pack_status_counts" =>
        count_by(report["reduced_capacity_pack_groups"] || [], "pack_status"),
      "allocation_status_counts" => count_by(rows, "allocation_status"),
      "effective_allocation_status_counts" => count_by(rows, "effective_allocation_status"),
      "allocation_reason_counts" => count_by(rows, "allocation_reason"),
      "contact_ids_by_allocation_reason" => contact_ids_by_field(rows, "allocation_reason"),
      "capacity_pack_status_counts" => count_by(rows, "capacity_pack_status"),
      "capacity_pack_required_capacity_fraction" =>
        capacity_pack_required_fraction(capacity_pack_rows),
      "capacity_pack_selected_required_capacity_fraction" =>
        capacity_pack_required_fraction(selected_capacity_pack_rows),
      "capacity_pack_deferred_required_capacity_fraction" =>
        capacity_pack_required_fraction(deferred_capacity_pack_rows),
      "capacity_pack_required_capacity_fraction_by_status" =>
        capacity_pack_required_fraction_by_field(capacity_pack_rows, "capacity_pack_status"),
      "required_capacity_fraction_source_counts" =>
        count_by(rows, "required_capacity_fraction_source"),
      "station_reservation_match_status_counts" =>
        count_by(rows, "station_reservation_match_status"),
      "station_reservation_status_counts" => count_by(rows, "station_reservation_status"),
      "station_reserved_by_counts" => count_by(rows, "station_reserved_by"),
      "station_reservation_ids" => row_values(rows, "station_reservation_id"),
      "station_reservation_expires_at_s" => row_values(rows, "station_reservation_expires_at_s"),
      "station_reservation_expiration_now_s" => now_s,
      "station_reservation_expiration_status_counts" =>
        station_reservation_expiration_status_counts(reservation_expiration_rows),
      "station_reservation_active_contact_count" =>
        station_reservation_expiration_count(reservation_expiration_rows, "active"),
      "station_reservation_expired_contact_count" =>
        station_reservation_expiration_count(reservation_expiration_rows, "expired"),
      "station_reservation_missing_expiration_contact_count" =>
        station_reservation_expiration_count(reservation_expiration_rows, "missing"),
      "station_reservation_declared_expiration_contact_count" =>
        station_reservation_expiration_count(reservation_expiration_rows, "declared"),
      "earliest_station_reservation_expires_at_s" =>
        earliest_station_reservation_expires_at_s(reservation_expiration_rows),
      "station_calendar_trust_boundary_status_counts" =>
        station_calendar_trust_boundary_status_counts(rows) || %{},
      "calendar_entry_trust_boundary_status_counts" =>
        report["calendar_entry_trust_boundary_status_counts"] || %{},
      "resource_blocking_dimension_counts" =>
        contact_id_count_map(resource_blocked_summary_rows(rows), "resource_blocking_dimension"),
      "allocated_contact_ids" =>
        allocation_summary_contact_ids(rows, "allocation_status", "allocated"),
      "allocated_contact_ids_by_ground_station_id" =>
        allocation_summary_contact_ids_by_station(rows, "allocation_status", "allocated"),
      "returned_allocated_contact_ids" =>
        rows
        |> Enum.filter(&(&1["effective_allocation_status"] == "allocated"))
        |> row_contact_ids(),
      "returned_allocated_contact_ids_by_ground_station_id" =>
        allocation_summary_contact_ids_by_station(
          rows,
          "effective_allocation_status",
          "allocated"
        ),
      "deferred_contact_ids" =>
        allocation_summary_contact_ids(rows, "allocation_status", "deferred"),
      "deferred_contact_ids_by_ground_station_id" =>
        allocation_summary_contact_ids_by_station(rows, "allocation_status", "deferred"),
      "blocked_contact_ids" =>
        allocation_summary_contact_ids(rows, "allocation_status", "blocked"),
      "blocked_contact_ids_by_ground_station_id" =>
        allocation_summary_contact_ids_by_station(rows, "allocation_status", "blocked"),
      "policy_blocked_contact_ids" =>
        allocation_summary_contact_ids(rows, "effective_allocation_status", "policy_blocked"),
      "policy_blocked_contact_ids_by_ground_station_id" =>
        allocation_summary_contact_ids_by_station(
          rows,
          "effective_allocation_status",
          "policy_blocked"
        ),
      "invalid_contact_input_ids" => invalid_allocation_input_ids(rows),
      "status_blocked_contact_ids" => status_blocked_allocation_ids(rows),
      "resource_blocked_contact_ids" => resource_blocked_summary_rows(rows) |> row_contact_ids(),
      "resource_blocked_contact_ids_by_blocking_dimension" =>
        contact_ids_by_field(resource_blocked_summary_rows(rows), "resource_blocking_dimension"),
      "resource_blocked_contact_ids_by_spacecraft_id" =>
        contact_ids_by_field(resource_blocked_summary_rows(rows), "spacecraft_id"),
      "station_pressure_contact_ids_by_ground_station_id" =>
        station_pressure_contact_ids_by_ground_station_id,
      "station_pressure_contact_counts_by_ground_station_id" =>
        id_set_count_map(station_pressure_contact_ids_by_ground_station_id),
      "station_pressure_contact_ids_by_availability" =>
        station_pressure_contact_ids_by_availability,
      "station_pressure_contact_counts_by_availability" =>
        id_set_count_map(station_pressure_contact_ids_by_availability),
      "station_pressure_contact_ids_by_precedence_availability" =>
        station_pressure_contact_ids_by_precedence_availability,
      "station_pressure_contact_counts_by_precedence_availability" =>
        id_set_count_map(station_pressure_contact_ids_by_precedence_availability),
      "station_pressure_contact_ids_by_precedence_rank" =>
        station_pressure_contact_ids_by_precedence_rank,
      "station_pressure_contact_counts_by_precedence_rank" =>
        id_set_count_map(station_pressure_contact_ids_by_precedence_rank),
      "station_pressure_contact_ids_by_status" => station_pressure_contact_ids_by_status,
      "station_pressure_contact_counts_by_status" =>
        id_set_count_map(station_pressure_contact_ids_by_status),
      "station_pressure_contact_ids_by_direction_and_ground_station_id" =>
        station_pressure_contact_ids_by_direction_and_ground_station_id,
      "station_reservation_contact_ids_by_match_status" =>
        contact_ids_by_field(rows, "station_reservation_match_status"),
      "station_reservation_contact_ids_by_status" =>
        contact_ids_by_field(rows, "station_reservation_status"),
      "station_reservation_contact_ids_by_reserved_by" =>
        contact_ids_by_field(rows, "station_reserved_by"),
      "station_reservation_ids_by_match_status" =>
        ids_by_field(rows, "station_reservation_match_status", "station_reservation_id"),
      "station_reservation_ids_by_status" =>
        ids_by_field(rows, "station_reservation_status", "station_reservation_id"),
      "station_reservation_ids_by_reserved_by" =>
        ids_by_field(rows, "station_reserved_by", "station_reservation_id"),
      "station_reservation_contact_ids_by_expiration_status" =>
        station_reservation_contact_ids_by_expiration_status(reservation_expiration_rows),
      "station_reservation_ids_by_expiration_status" =>
        station_reservation_ids_by_expiration_status(reservation_expiration_rows),
      "capacity_pack_contact_ids_by_status" => contact_ids_by_field(rows, "capacity_pack_status"),
      "capacity_pack_contact_ids_by_ground_station_id" =>
        contact_ids_by_field(capacity_pack_rows, "ground_station_id"),
      "capacity_pack_selected_contact_ids_by_ground_station_id" =>
        contact_ids_by_field(selected_capacity_pack_rows, "ground_station_id"),
      "capacity_pack_deferred_contact_ids_by_ground_station_id" =>
        contact_ids_by_field(deferred_capacity_pack_rows, "ground_station_id"),
      "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
        capacity_pack_required_fraction_by_field(capacity_pack_rows, "ground_station_id"),
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" =>
        capacity_pack_required_fraction_by_field(selected_capacity_pack_rows, "ground_station_id"),
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" =>
        capacity_pack_required_fraction_by_field(deferred_capacity_pack_rows, "ground_station_id"),
      "required_capacity_fraction_contact_ids_by_source" =>
        contact_ids_by_field(rows, "required_capacity_fraction_source"),
      "reduced_capacity_packed_contact_ids" =>
        allocation_summary_contact_ids(
          rows,
          "capacity_pack_status",
          "selected_by_reduced_station_capacity_pack"
        ),
      "reduced_capacity_deferred_contact_ids" =>
        allocation_summary_contact_ids(
          rows,
          "capacity_pack_status",
          "deferred_by_reduced_station_capacity_pack"
        ),
      "rows" => rows,
      "review_contact_ids" => row_contact_ids(review_rows),
      "review_row_count" => length(review_rows),
      "review_rows" => review_rows,
      "reduced_capacity_pack_groups" => report["reduced_capacity_pack_groups"] || [],
      "model_limits" => model_limits,
      "assumptions" =>
        Map.merge(
          %{
            "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
            "source" => "contact_allocation_report.v1",
            "operator_authority" => "not_granted_by_summary"
          },
          capability_assumptions
        )
    }
    |> compact_map()
  end

  def report_fields(allocation_rows, reduced_capacity_pack_groups) do
    station_pressure_rows = station_pressure_summary_rows(allocation_rows)

    station_pressure_contact_ids_by_ground_station_id =
      contact_ids_by_field(station_pressure_rows, "ground_station_id")

    station_pressure_contact_ids_by_availability =
      station_pressure_contact_ids_by_availability(station_pressure_rows)

    station_pressure_contact_ids_by_precedence_availability =
      contact_ids_by_field(station_pressure_rows, "station_calendar_precedence_availability")

    station_pressure_contact_ids_by_precedence_rank =
      contact_ids_by_string_field(station_pressure_rows, "station_calendar_precedence_rank")

    station_pressure_contact_ids_by_status =
      contact_ids_by_field(station_pressure_rows, "station_calendar_status")

    station_pressure_contact_ids_by_direction_and_ground_station_id =
      contact_ids_by_direction_and_ground_station_id(station_pressure_rows)

    reservation_expiration_rows =
      station_reservation_expiration_summary_rows(allocation_rows, nil)

    capacity_pack_rows = capacity_pack_summary_rows(allocation_rows)
    selected_capacity_pack_rows = selected_capacity_pack_summary_rows(capacity_pack_rows)
    deferred_capacity_pack_rows = deferred_capacity_pack_summary_rows(capacity_pack_rows)

    %{
      "allocated_contact_count" =>
        allocation_summary_count(allocation_rows, "allocation_status", "allocated"),
      "returned_allocated_contact_count" =>
        allocation_summary_count(allocation_rows, "effective_allocation_status", "allocated"),
      "policy_blocked_allocated_contact_count" =>
        allocation_summary_count(
          allocation_rows,
          "effective_allocation_status",
          "policy_blocked"
        ),
      "deferred_contact_count" =>
        allocation_summary_count(allocation_rows, "allocation_status", "deferred"),
      "blocked_contact_count" =>
        allocation_summary_count(allocation_rows, "allocation_status", "blocked"),
      "allocation_status_counts" => count_by(allocation_rows, "allocation_status"),
      "effective_allocation_status_counts" =>
        count_by(allocation_rows, "effective_allocation_status"),
      "allocation_reason_counts" => count_by(allocation_rows, "allocation_reason"),
      "station_reservation_match_status_counts" =>
        count_by(allocation_rows, "station_reservation_match_status"),
      "station_reservation_ids" => row_values(allocation_rows, "station_reservation_id"),
      "station_reservation_expires_at_s" =>
        row_values(allocation_rows, "station_reservation_expires_at_s"),
      "station_reservation_expiration_status_counts" =>
        station_reservation_expiration_status_counts(reservation_expiration_rows),
      "station_reservation_declared_expiration_contact_count" =>
        station_reservation_expiration_count(reservation_expiration_rows, "declared"),
      "station_reservation_missing_expiration_contact_count" =>
        station_reservation_expiration_count(reservation_expiration_rows, "missing"),
      "earliest_station_reservation_expires_at_s" =>
        earliest_station_reservation_expires_at_s(reservation_expiration_rows),
      "station_reservation_contact_ids_by_expiration_status" =>
        station_reservation_contact_ids_by_expiration_status(reservation_expiration_rows),
      "station_reservation_ids_by_expiration_status" =>
        station_reservation_ids_by_expiration_status(reservation_expiration_rows),
      "station_reserved_bys" => row_values(allocation_rows, "station_reserved_by"),
      "station_reservation_statuses" => row_values(allocation_rows, "station_reservation_status"),
      "station_calendar_trust_boundary_status_counts" =>
        station_calendar_trust_boundary_status_counts(allocation_rows),
      "station_pressure_contact_ids_by_ground_station_id" =>
        station_pressure_contact_ids_by_ground_station_id,
      "station_pressure_contact_counts_by_ground_station_id" =>
        id_set_count_map(station_pressure_contact_ids_by_ground_station_id),
      "station_pressure_contact_ids_by_availability" =>
        station_pressure_contact_ids_by_availability,
      "station_pressure_contact_counts_by_availability" =>
        id_set_count_map(station_pressure_contact_ids_by_availability),
      "station_pressure_contact_ids_by_precedence_availability" =>
        station_pressure_contact_ids_by_precedence_availability,
      "station_pressure_contact_counts_by_precedence_availability" =>
        id_set_count_map(station_pressure_contact_ids_by_precedence_availability),
      "station_pressure_contact_ids_by_precedence_rank" =>
        station_pressure_contact_ids_by_precedence_rank,
      "station_pressure_contact_counts_by_precedence_rank" =>
        id_set_count_map(station_pressure_contact_ids_by_precedence_rank),
      "station_pressure_contact_ids_by_status" => station_pressure_contact_ids_by_status,
      "station_pressure_contact_counts_by_status" =>
        id_set_count_map(station_pressure_contact_ids_by_status),
      "station_pressure_contact_ids_by_direction_and_ground_station_id" =>
        station_pressure_contact_ids_by_direction_and_ground_station_id,
      "status_blocked_contact_count" => status_blocked_allocation_count(allocation_rows),
      "status_blocked_contact_ids" => status_blocked_allocation_ids(allocation_rows),
      "resource_blocked_contact_count" => resource_blocked_contact_count(allocation_rows),
      "resource_blocked_contact_ids" =>
        allocation_rows |> resource_blocked_summary_rows() |> row_contact_ids(),
      "resource_blocking_dimension_counts" =>
        contact_id_count_map(
          resource_blocked_summary_rows(allocation_rows),
          "resource_blocking_dimension"
        ),
      "resource_blocked_contact_ids_by_blocking_dimension" =>
        contact_ids_by_field(
          resource_blocked_summary_rows(allocation_rows),
          "resource_blocking_dimension"
        ),
      "resource_blocked_contact_ids_by_spacecraft_id" =>
        contact_ids_by_field(resource_blocked_summary_rows(allocation_rows), "spacecraft_id"),
      "reduced_capacity_pack_group_count" => length(reduced_capacity_pack_groups),
      "reduced_capacity_pack_groups" => reduced_capacity_pack_groups,
      "reduced_capacity_pack_status_counts" =>
        count_by(reduced_capacity_pack_groups, "pack_status"),
      "capacity_pack_status_counts" => count_by(allocation_rows, "capacity_pack_status"),
      "capacity_pack_required_capacity_fraction" =>
        capacity_pack_required_fraction(capacity_pack_rows),
      "capacity_pack_selected_required_capacity_fraction" =>
        capacity_pack_required_fraction(selected_capacity_pack_rows),
      "capacity_pack_deferred_required_capacity_fraction" =>
        capacity_pack_required_fraction(deferred_capacity_pack_rows),
      "capacity_pack_required_capacity_fraction_by_status" =>
        capacity_pack_required_fraction_by_field(capacity_pack_rows, "capacity_pack_status"),
      "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
        capacity_pack_required_fraction_by_field(capacity_pack_rows, "ground_station_id"),
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" =>
        capacity_pack_required_fraction_by_field(
          selected_capacity_pack_rows,
          "ground_station_id"
        ),
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" =>
        capacity_pack_required_fraction_by_field(
          deferred_capacity_pack_rows,
          "ground_station_id"
        ),
      "capacity_pack_contact_ids_by_status" =>
        contact_ids_by_field(allocation_rows, "capacity_pack_status"),
      "required_capacity_fraction_source_counts" =>
        count_by(allocation_rows, "required_capacity_fraction_source"),
      "required_capacity_fraction_contact_ids_by_source" =>
        contact_ids_by_field(allocation_rows, "required_capacity_fraction_source"),
      "reduced_capacity_packed_contact_ids" =>
        allocation_summary_contact_ids(
          allocation_rows,
          "capacity_pack_status",
          "selected_by_reduced_station_capacity_pack"
        ),
      "reduced_capacity_deferred_contact_ids" =>
        allocation_summary_contact_ids(
          allocation_rows,
          "capacity_pack_status",
          "deferred_by_reduced_station_capacity_pack"
        )
    }
  end

  def build_station_pressure(report, model_limits, capability_assumptions) do
    report = stringify_keys(report)

    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)
      |> Enum.map(&normalize_station_calendar_status_fields/1)

    station_pressure_rows = station_pressure_summary_rows(rows)

    contact_ids_by_ground_station_id =
      contact_ids_by_field(station_pressure_rows, "ground_station_id")

    contact_ids_by_availability =
      station_pressure_contact_ids_by_availability(station_pressure_rows)

    contact_ids_by_precedence_availability =
      contact_ids_by_field(station_pressure_rows, "station_calendar_precedence_availability")

    contact_ids_by_precedence_rank =
      contact_ids_by_string_field(station_pressure_rows, "station_calendar_precedence_rank")

    contact_ids_by_status =
      contact_ids_by_field(station_pressure_rows, "station_calendar_status")

    contact_ids_by_direction_and_ground_station_id =
      contact_ids_by_direction_and_ground_station_id(station_pressure_rows)

    review_rows = Enum.filter(station_pressure_rows, &allocation_summary_review_row?/1)

    %{
      "schema_contract" => @station_pressure_summary_schema_contract,
      "model" => "artifact_only_contact_allocation_station_pressure_summary",
      "source_artifact_type" => Map.get(report, "schema_contract", @schema_contract),
      "source" => report["source"],
      "input_contact_count" => length(rows),
      "station_pressure_contact_count" => length(station_pressure_rows),
      "station_pressure_review_contact_count" => length(review_rows),
      "station_pressure_contact_ids" => row_contact_ids(station_pressure_rows),
      "station_pressure_review_contact_ids" => row_contact_ids(review_rows),
      "station_pressure_contact_ids_by_ground_station_id" => contact_ids_by_ground_station_id,
      "station_pressure_contact_counts_by_ground_station_id" =>
        id_set_count_map(contact_ids_by_ground_station_id),
      "station_pressure_contact_ids_by_availability" => contact_ids_by_availability,
      "station_pressure_contact_counts_by_availability" =>
        id_set_count_map(contact_ids_by_availability),
      "station_pressure_contact_ids_by_precedence_availability" =>
        contact_ids_by_precedence_availability,
      "station_pressure_contact_counts_by_precedence_availability" =>
        id_set_count_map(contact_ids_by_precedence_availability),
      "station_pressure_contact_ids_by_precedence_rank" => contact_ids_by_precedence_rank,
      "station_pressure_contact_counts_by_precedence_rank" =>
        id_set_count_map(contact_ids_by_precedence_rank),
      "station_pressure_contact_ids_by_status" => contact_ids_by_status,
      "station_pressure_contact_counts_by_status" => id_set_count_map(contact_ids_by_status),
      "station_pressure_contact_ids_by_direction_and_ground_station_id" =>
        contact_ids_by_direction_and_ground_station_id,
      "rows" => rows,
      "review_rows" => review_rows,
      "model_limits" => model_limits,
      "assumptions" =>
        Map.merge(
          %{
            "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
            "source" => "contact_allocation_report.v1",
            "operator_authority" => "not_granted_by_station_pressure_summary"
          },
          capability_assumptions
        )
    }
    |> compact_map()
  end

  def build_capacity_pack(report, model_limits, capability_assumptions) do
    report = stringify_keys(report)

    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)
      |> Enum.map(&normalize_station_calendar_status_fields/1)

    capacity_pack_rows = capacity_pack_summary_rows(rows)
    selected_capacity_pack_rows = selected_capacity_pack_summary_rows(capacity_pack_rows)
    deferred_capacity_pack_rows = deferred_capacity_pack_summary_rows(capacity_pack_rows)
    pack_groups = report["reduced_capacity_pack_groups"] || []

    %{
      "schema_contract" => @capacity_pack_summary_schema_contract,
      "model" => "artifact_only_contact_allocation_capacity_pack_summary",
      "source_artifact_type" => Map.get(report, "schema_contract", @schema_contract),
      "source" => report["source"],
      "input_contact_count" => length(rows),
      "capacity_pack_contact_count" => length(capacity_pack_rows),
      "capacity_pack_review_status" =>
        if(capacity_pack_rows == [] and pack_groups == [], do: "clear", else: "review_required"),
      "reduced_capacity_pack_group_count" => length(pack_groups),
      "reduced_capacity_pack_status_counts" => count_by(pack_groups, "pack_status"),
      "capacity_pack_status_counts" => count_by(capacity_pack_rows, "capacity_pack_status"),
      "capacity_pack_contact_ids_by_status" =>
        contact_ids_by_field(capacity_pack_rows, "capacity_pack_status"),
      "capacity_pack_contact_ids_by_ground_station_id" =>
        contact_ids_by_field(capacity_pack_rows, "ground_station_id"),
      "capacity_pack_selected_contact_ids_by_ground_station_id" =>
        contact_ids_by_field(selected_capacity_pack_rows, "ground_station_id"),
      "capacity_pack_deferred_contact_ids_by_ground_station_id" =>
        contact_ids_by_field(deferred_capacity_pack_rows, "ground_station_id"),
      "capacity_pack_required_capacity_fraction" =>
        capacity_pack_required_fraction(capacity_pack_rows),
      "capacity_pack_selected_required_capacity_fraction" =>
        capacity_pack_required_fraction(selected_capacity_pack_rows),
      "capacity_pack_deferred_required_capacity_fraction" =>
        capacity_pack_required_fraction(deferred_capacity_pack_rows),
      "capacity_pack_required_capacity_fraction_by_status" =>
        capacity_pack_required_fraction_by_field(capacity_pack_rows, "capacity_pack_status"),
      "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
        capacity_pack_required_fraction_by_field(capacity_pack_rows, "ground_station_id"),
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" =>
        capacity_pack_required_fraction_by_field(selected_capacity_pack_rows, "ground_station_id"),
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" =>
        capacity_pack_required_fraction_by_field(deferred_capacity_pack_rows, "ground_station_id"),
      "capacity_pack_required_capacity_fraction_by_direction" =>
        capacity_pack_required_fraction_by_field(capacity_pack_rows, "direction"),
      "capacity_pack_selected_required_capacity_fraction_by_direction" =>
        capacity_pack_required_fraction_by_field(selected_capacity_pack_rows, "direction"),
      "capacity_pack_deferred_required_capacity_fraction_by_direction" =>
        capacity_pack_required_fraction_by_field(deferred_capacity_pack_rows, "direction"),
      "required_capacity_fraction_source_counts" =>
        count_by(capacity_pack_rows, "required_capacity_fraction_source"),
      "required_capacity_fraction_contact_ids_by_source" =>
        contact_ids_by_field(capacity_pack_rows, "required_capacity_fraction_source"),
      "capacity_pack_contact_ids_by_direction" =>
        contact_ids_by_field(capacity_pack_rows, "direction"),
      "capacity_pack_selected_contact_ids_by_direction" =>
        contact_ids_by_field(selected_capacity_pack_rows, "direction"),
      "capacity_pack_deferred_contact_ids_by_direction" =>
        contact_ids_by_field(deferred_capacity_pack_rows, "direction"),
      "reduced_capacity_packed_contact_ids" =>
        allocation_summary_contact_ids(
          capacity_pack_rows,
          "capacity_pack_status",
          "selected_by_reduced_station_capacity_pack"
        ),
      "reduced_capacity_deferred_contact_ids" =>
        allocation_summary_contact_ids(
          capacity_pack_rows,
          "capacity_pack_status",
          "deferred_by_reduced_station_capacity_pack"
        ),
      "capacity_pack_group_ids" => row_values(pack_groups, "contention_group_id"),
      "capacity_pack_group_ids_by_status" =>
        ids_by_field(pack_groups, "pack_status", "contention_group_id"),
      "rows" => rows,
      "reduced_capacity_pack_groups" => pack_groups,
      "review_rows" => capacity_pack_rows,
      "model_limits" => model_limits,
      "assumptions" =>
        Map.merge(
          %{
            "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
            "source" => "contact_allocation_report.v1",
            "operator_authority" => "not_granted_by_capacity_pack_summary"
          },
          capability_assumptions
        )
    }
    |> compact_map()
  end

  def build_reservation_conflict(report, opts, model_limits, capability_assumptions) do
    report = stringify_keys(report)
    now_s = Keyword.get(opts, :now_s)

    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)
      |> Enum.map(&normalize_station_calendar_status_fields/1)

    reservation_rows = Enum.filter(rows, &station_reservation_summary_row?/1)
    conflict_rows = Enum.filter(reservation_rows, &reservation_conflict_row?/1)
    review_rows = Enum.filter(reservation_rows, &allocation_summary_review_row?/1)
    expiration_rows = station_reservation_expiration_summary_rows(reservation_rows, now_s)

    conflict_contact_ids_by_direction_and_ground_station_id =
      contact_ids_by_direction_and_ground_station_id(conflict_rows)

    %{
      "schema_contract" => @reservation_conflict_summary_schema_contract,
      "model" => "artifact_only_contact_allocation_reservation_conflict_summary",
      "model_limits" => model_limits,
      "source_artifact_type" => Map.get(report, "schema_contract", @schema_contract),
      "source" => report["source"],
      "input_contact_count" => length(rows),
      "station_reservation_contact_count" => length(reservation_rows),
      "reservation_conflict_contact_count" => length(conflict_rows),
      "reservation_review_contact_count" => length(review_rows),
      "station_reservation_match_status_counts" =>
        count_by(reservation_rows, "station_reservation_match_status"),
      "reservation_conflict_match_status_counts" =>
        count_by(conflict_rows, "station_reservation_match_status"),
      "station_reservation_status_counts" =>
        count_by(reservation_rows, "station_reservation_status"),
      "station_reserved_by_counts" => count_by(reservation_rows, "station_reserved_by"),
      "station_reservation_ids" => row_values(reservation_rows, "station_reservation_id"),
      "station_reservation_expires_at_s" =>
        row_values(reservation_rows, "station_reservation_expires_at_s"),
      "station_reservation_expiration_now_s" => now_s,
      "station_reservation_expiration_status_counts" =>
        station_reservation_expiration_status_counts(expiration_rows),
      "earliest_station_reservation_expires_at_s" =>
        earliest_station_reservation_expires_at_s(expiration_rows),
      "reservation_conflict_contact_ids" => row_contact_ids(conflict_rows),
      "reservation_review_contact_ids" => row_contact_ids(review_rows),
      "station_reservation_contact_ids_by_match_status" =>
        contact_ids_by_field(reservation_rows, "station_reservation_match_status"),
      "reservation_conflict_contact_ids_by_match_status" =>
        contact_ids_by_field(conflict_rows, "station_reservation_match_status"),
      "reservation_conflict_contact_ids_by_direction" => contact_ids_by_direction(conflict_rows),
      "reservation_conflict_contact_ids_by_direction_and_ground_station_id" =>
        conflict_contact_ids_by_direction_and_ground_station_id,
      "station_reservation_contact_ids_by_status" =>
        contact_ids_by_field(reservation_rows, "station_reservation_status"),
      "station_reservation_contact_ids_by_reserved_by" =>
        contact_ids_by_field(reservation_rows, "station_reserved_by"),
      "station_reservation_contact_ids_by_expiration_status" =>
        station_reservation_contact_ids_by_expiration_status(expiration_rows),
      "station_reservation_ids_by_match_status" =>
        ids_by_field(
          reservation_rows,
          "station_reservation_match_status",
          "station_reservation_id"
        ),
      "reservation_conflict_reservation_ids_by_match_status" =>
        ids_by_field(conflict_rows, "station_reservation_match_status", "station_reservation_id"),
      "station_reservation_ids_by_status" =>
        ids_by_field(reservation_rows, "station_reservation_status", "station_reservation_id"),
      "station_reservation_ids_by_reserved_by" =>
        ids_by_field(reservation_rows, "station_reserved_by", "station_reservation_id"),
      "station_reservation_ids_by_expiration_status" =>
        station_reservation_ids_by_expiration_status(expiration_rows),
      "rows" => rows,
      "reservation_conflict_rows" => conflict_rows,
      "reservation_review_rows" => review_rows,
      "assumptions" =>
        Map.merge(
          %{
            "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
            "source" => "contact_allocation_report.v1",
            "operator_authority" => "not_granted_by_reservation_conflict_summary"
          },
          capability_assumptions
        )
    }
    |> compact_map()
  end

  def build_provider_reservation_request(report, model_limits, capability_assumptions) do
    report = stringify_keys(report)

    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)
      |> Enum.map(&normalize_station_calendar_status_fields/1)
      |> Enum.map(&ensure_effective_allocation_status/1)

    reservation_candidate_rows =
      Enum.filter(rows, &provider_reservation_request_candidate_row?/1)

    request_rows =
      Enum.filter(reservation_candidate_rows, &provider_reservation_request_ready_row?/1)

    review_rows = reservation_candidate_rows -- request_rows

    no_request_rows =
      Enum.reject(rows, &provider_reservation_request_candidate_row?/1)

    %{
      "schema_contract" => @provider_reservation_request_summary_schema_contract,
      "model" => "artifact_only_contact_allocation_provider_reservation_request_summary",
      "model_limits" => model_limits,
      "source_artifact_type" => Map.get(report, "schema_contract", @schema_contract),
      "source" => report["source"],
      "input_contact_count" => length(rows),
      "provider_reservation_candidate_contact_count" => length(reservation_candidate_rows),
      "provider_reservation_request_contact_count" => length(request_rows),
      "provider_reservation_review_contact_count" => length(review_rows),
      "provider_reservation_no_request_contact_count" =>
        length(rows) - length(reservation_candidate_rows),
      "provider_reservation_request_status" =>
        provider_reservation_request_status(request_rows, review_rows),
      "provider_reservation_request_contact_ids" => row_contact_ids(request_rows),
      "provider_reservation_review_contact_ids" => row_contact_ids(review_rows),
      "provider_reservation_no_request_contact_ids" => row_contact_ids(no_request_rows),
      "provider_reservation_request_contact_ids_by_ground_station_id" =>
        contact_ids_by_field(request_rows, "ground_station_id"),
      "provider_reservation_review_contact_ids_by_ground_station_id" =>
        contact_ids_by_field(review_rows, "ground_station_id"),
      "provider_reservation_no_request_contact_ids_by_direction" =>
        contact_ids_by_field(no_request_rows, "direction"),
      "provider_reservation_request_contact_ids_by_direction" =>
        contact_ids_by_field(request_rows, "direction"),
      "provider_reservation_review_contact_ids_by_direction" =>
        contact_ids_by_field(review_rows, "direction"),
      "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id" =>
        contact_ids_by_direction_and_ground_station_id(no_request_rows),
      "provider_reservation_request_contact_ids_by_direction_and_ground_station_id" =>
        contact_ids_by_direction_and_ground_station_id(request_rows),
      "provider_reservation_review_contact_ids_by_direction_and_ground_station_id" =>
        contact_ids_by_direction_and_ground_station_id(review_rows),
      "provider_reservation_request_contact_ids_by_match_status" =>
        contact_ids_by_field(request_rows, "station_reservation_match_status"),
      "provider_reservation_review_contact_ids_by_match_status" =>
        contact_ids_by_field(review_rows, "station_reservation_match_status"),
      "provider_reservation_request_ids_by_match_status" =>
        reservation_ids_by_match_status(request_rows),
      "provider_reservation_review_ids_by_match_status" =>
        reservation_ids_by_match_status(review_rows),
      "rows" => rows,
      "provider_reservation_request_rows" => request_rows,
      "provider_reservation_review_rows" => review_rows,
      "assumptions" =>
        Map.merge(
          %{
            "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
            "source" => "contact_allocation_report.v1",
            "provider_reservation_execution" => "not_performed_by_summary",
            "operator_authority" => "not_granted_by_provider_reservation_request_summary"
          },
          capability_assumptions
        )
    }
    |> compact_map()
  end

  defp provider_reservation_request_status(_request_rows, review_rows) when review_rows != [],
    do: "review_required"

  defp provider_reservation_request_status(request_rows, _review_rows) when request_rows != [],
    do: "request_ready"

  defp provider_reservation_request_status(_request_rows, _review_rows), do: "clear"

  defp reservation_conflict_row?(row) do
    station_pressure_value?(row["station_reservation_match_status"]) and
      row["station_reservation_match_status"] not in ["matched", "owner_matched"]
  end

  defp provider_reservation_request_ready_row?(row) do
    row["station_reservation_match_status"] in ["matched", "owner_matched"] and
      station_reservation_summary_ids(row) != []
  end

  defp provider_reservation_request_candidate_row?(row) do
    row["allocation_status"] == "allocated" and
      row["effective_allocation_status"] in [nil, "allocated"] and
      station_reservation_summary_row?(row)
  end

  defp station_reservation_summary_row?(row) do
    station_reservation_expiration_summary_row?(row)
  end

  defp ensure_effective_allocation_status(%{"effective_allocation_status" => status} = row)
       when is_binary(status),
       do: row

  defp ensure_effective_allocation_status(row), do: put_effective_allocation_status(row)

  defp resource_blocked_summary_rows(rows) do
    Enum.filter(rows, &Map.has_key?(&1, "source_resource_suppression"))
  end

  defp capacity_pack_summary_rows(rows) do
    Enum.filter(rows, fn row ->
      is_binary(row["capacity_pack_status"]) and is_number(row["required_capacity_fraction"])
    end)
  end

  defp selected_capacity_pack_summary_rows(rows) do
    Enum.filter(rows, fn row ->
      row["capacity_pack_status"] in [
        "selected_by_contention_resolution",
        "selected_by_reduced_station_capacity_pack"
      ]
    end)
  end

  defp deferred_capacity_pack_summary_rows(rows) do
    Enum.filter(
      rows,
      &(&1["capacity_pack_status"] == "deferred_by_reduced_station_capacity_pack")
    )
  end

  defp capacity_pack_required_fraction(rows) do
    rows
    |> Enum.map(&numeric_or_nil(&1["required_capacity_fraction"]))
    |> Enum.filter(&is_number/1)
    |> Enum.sum()
  end

  defp capacity_pack_required_fraction_by_field(rows, field) do
    rows
    |> Enum.reduce(%{}, fn row, totals ->
      field_value = stable_id_or_nil(row[field]) || normalized_status_token(row[field])
      required_fraction = numeric_or_nil(row["required_capacity_fraction"])

      if is_nil(field_value) or is_nil(required_fraction) do
        totals
      else
        Map.update(totals, field_value, required_fraction, &(&1 + required_fraction))
      end
    end)
  end

  defp allocation_summary_count(rows, field, value) do
    Enum.count(rows, &(Map.get(&1, field) == value))
  end

  defp invalid_allocation_input_count(rows) do
    Enum.count(rows, &(&1["invalid_contact_input"] == true))
  end

  defp invalid_allocation_input_ids(rows) do
    rows
    |> Enum.filter(&(&1["invalid_contact_input"] == true))
    |> row_contact_ids()
  end

  defp status_blocked_allocation_count(rows) do
    Enum.count(rows, &status_blocked_allocation_row?/1)
  end

  defp status_blocked_allocation_ids(rows) do
    rows
    |> Enum.filter(&status_blocked_allocation_row?/1)
    |> row_contact_ids()
  end

  defp status_blocked_allocation_row?(row) do
    reason = row["allocation_reason"]

    is_binary(reason) and
      (String.starts_with?(reason, "activity_status_") or
         String.starts_with?(reason, "approval_status_"))
  end

  defp duplicate_contact_group_count(rows) do
    rows
    |> Enum.filter(&(&1["duplicate_contact_id_collision"] == true))
    |> Enum.map(& &1["contact_id"])
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> length()
  end

  defp station_pressure_summary_rows(rows) do
    Enum.filter(rows, fn row ->
      station_pressure_value?(row["station_calendar_overlap_count"]) or
        station_pressure_value?(row["station_calendar_overlap_availabilities"]) or
        station_pressure_value?(row["station_calendar_entry_id"]) or
        station_pressure_value?(row["station_reservation_match_status"]) or
        station_pressure_value?(row["station_calendar_precedence_rank"]) or
        station_pressure_value?(row["station_calendar_precedence_availability"]) or
        source_station_calendar_pressure_values(row) != []
    end)
  end

  defp station_pressure_value?(nil), do: false
  defp station_pressure_value?([]), do: false
  defp station_pressure_value?(value) when is_number(value), do: value > 0
  defp station_pressure_value?(value) when is_binary(value), do: value != ""
  defp station_pressure_value?(_value), do: true

  defp allocation_summary_contact_ids(rows, field, value) do
    rows
    |> Enum.filter(&(Map.get(&1, field) == value))
    |> row_contact_ids()
  end

  defp row_contact_ids(rows) do
    rows
    |> Enum.map(& &1["contact_id"])
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp station_pressure_contact_ids_by_availability(rows) do
    rows
    |> Enum.flat_map(fn row ->
      row
      |> station_pressure_availability_values()
      |> Enum.map(&{&1, row["contact_id"]})
    end)
    |> Enum.group_by(fn {availability, _contact_id} -> availability end, fn {_availability,
                                                                             contact_id} ->
      contact_id
    end)
    |> Enum.reject(fn {availability, contact_ids} ->
      is_nil(availability) or Enum.all?(contact_ids, &is_nil/1)
    end)
    |> Map.new(fn {availability, contact_ids} ->
      {availability, sorted_stable_ids(contact_ids)}
    end)
  end

  defp station_pressure_availability_values(row) do
    direct_values =
      row
      |> Map.take(["station_availability", "availability", "station_calendar_status"])
      |> Map.values()

    source_values =
      source_station_calendar_availability_candidates(row["source_station_calendar_entry"]) ++
        source_station_calendar_availability_candidates(row["source_station_calendar_overlaps"])

    (direct_values ++ List.wrap(row["station_calendar_overlap_availabilities"]) ++ source_values)
    |> Enum.map(&normalized_status_token/1)
    |> Enum.filter(&station_availability_value?/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp source_station_calendar_pressure_values(row) do
    (source_station_calendar_availability_candidates(row["source_station_calendar_entry"]) ++
       source_station_calendar_availability_candidates(row["source_station_calendar_overlaps"]))
    |> Enum.map(&normalized_status_token/1)
    |> Enum.filter(&station_pressure_availability_value?/1)
    |> Enum.uniq()
  end

  defp station_pressure_availability_value?(value)
       when value in ["unavailable", "maintenance", "reserved", "reduced_capacity"],
       do: true

  defp station_pressure_availability_value?(_value), do: false

  defp contact_ids_by_field(rows, field) do
    ids_by_field(rows, field, "contact_id")
  end

  defp contact_ids_by_string_field(rows, field) do
    rows
    |> contact_ids_by_field(field)
    |> Map.new(fn {field_value, contact_ids} -> {to_string(field_value), contact_ids} end)
  end

  defp contact_ids_by_direction(rows) do
    rows
    |> Enum.reduce(%{}, fn row, acc ->
      direction = normalize_direction(row["direction"] || row["type"])
      contact_id = row["contact_id"]

      if direction in [nil, ""] or contact_id in [nil, ""] do
        acc
      else
        Map.update(acc, direction, [contact_id], fn contact_ids -> [contact_id | contact_ids] end)
      end
    end)
    |> Map.new(fn {direction, contact_ids} -> {direction, sorted_stable_ids(contact_ids)} end)
  end

  defp allocation_summary_contact_ids_by_station(rows, status_field, status) do
    rows
    |> Enum.filter(&(&1[status_field] == status))
    |> contact_ids_by_field("ground_station_id")
  end

  defp ids_by_field(rows, field, id_field) do
    rows
    |> Enum.group_by(&Map.get(&1, field), & &1[id_field])
    |> Enum.reject(fn {field_value, ids} ->
      is_nil(field_value) or Enum.all?(ids, &is_nil/1)
    end)
    |> Map.new(fn {field_value, ids} -> {field_value, sorted_stable_ids(ids)} end)
  end

  defp reservation_ids_by_match_status(rows) do
    Enum.reduce(rows, %{}, fn row, acc ->
      match_status = row["station_reservation_match_status"]
      reservation_ids = station_reservation_summary_ids(row)

      if station_pressure_value?(match_status) and reservation_ids != [] do
        Map.update(acc, match_status, sorted_stable_ids(reservation_ids), fn current ->
          sorted_stable_ids(current ++ reservation_ids)
        end)
      else
        acc
      end
    end)
  end

  defp contact_ids_by_direction_and_ground_station_id(rows) do
    rows
    |> Enum.reduce(%{}, fn row, acc ->
      direction = normalize_direction(row["direction"] || row["type"])
      ground_station_id = row["ground_station_id"]
      contact_id = row["contact_id"]

      if direction in [nil, ""] or ground_station_id in [nil, ""] or contact_id in [nil, ""] do
        acc
      else
        Map.update(acc, direction, %{ground_station_id => [contact_id]}, fn station_map ->
          Map.update(station_map, ground_station_id, [contact_id], fn contact_ids ->
            [contact_id | contact_ids]
          end)
        end)
      end
    end)
    |> Map.new(fn {direction, station_map} ->
      {direction,
       Map.new(station_map, fn {station_id, contact_ids} ->
         {station_id, sorted_stable_ids(contact_ids)}
       end)}
    end)
  end

  defp contact_id_count_map(rows, field) do
    rows
    |> contact_ids_by_field(field)
    |> Map.new(fn {field_value, contact_ids} -> {field_value, length(contact_ids)} end)
  end

  defp id_set_count_map(id_sets) do
    Map.new(id_sets, fn {field_value, ids} -> {field_value, length(ids)} end)
  end

  defp sorted_stable_ids(values) do
    values
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp station_reservation_expiration_summary_rows(rows, now_s) do
    now_s = numeric_or_nil(now_s)

    rows
    |> Enum.filter(&station_reservation_expiration_summary_row?/1)
    |> Enum.map(fn row ->
      expires_at_s = station_reservation_summary_expires_at_s(row)

      row
      |> Map.put("station_reservation_summary_expires_at_s", expires_at_s)
      |> Map.put(
        "station_reservation_expiration_status",
        station_reservation_expiration_status(expires_at_s, now_s)
      )
    end)
  end

  defp station_reservation_expiration_summary_row?(row) do
    Enum.any?(
      [
        row["station_reservation_id"],
        row["station_reservation_status"],
        row["station_reserved_by"],
        row["station_reservation_match_status"],
        row["station_reservation_expires_at_s"],
        row["station_calendar_reservation_ids"],
        row["station_calendar_reservation_statuses"],
        row["station_calendar_reserved_by"],
        row["station_calendar_reservation_expires_at_s"]
      ],
      &station_pressure_value?/1
    )
  end

  defp station_reservation_summary_expires_at_s(row) do
    [
      row["station_reservation_expires_at_s"],
      row["station_calendar_reservation_expires_at_s"]
    ]
    |> List.flatten()
    |> Enum.find_value(&numeric_or_nil/1)
  end

  defp station_reservation_expiration_status(nil, _now_s), do: "missing"
  defp station_reservation_expiration_status(_expires_at_s, nil), do: "declared"

  defp station_reservation_expiration_status(expires_at_s, now_s)
       when expires_at_s <= now_s,
       do: "expired"

  defp station_reservation_expiration_status(_expires_at_s, _now_s), do: "active"

  defp station_reservation_expiration_status_counts(rows) do
    count_by(rows, "station_reservation_expiration_status")
  end

  defp station_reservation_expiration_count(rows, status) do
    rows
    |> Enum.count(&(&1["station_reservation_expiration_status"] == status))
  end

  defp earliest_station_reservation_expires_at_s(rows) do
    rows
    |> Enum.map(& &1["station_reservation_summary_expires_at_s"])
    |> Enum.reject(&is_nil/1)
    |> Enum.min(fn -> nil end)
  end

  defp station_reservation_contact_ids_by_expiration_status(rows) do
    contact_ids_by_field(rows, "station_reservation_expiration_status")
  end

  defp station_reservation_ids_by_expiration_status(rows) do
    rows
    |> Enum.flat_map(fn row ->
      row
      |> station_reservation_summary_ids()
      |> Enum.map(&{row["station_reservation_expiration_status"], &1})
    end)
    |> Enum.group_by(fn {status, _id} -> status end, fn {_status, id} -> id end)
    |> Enum.reject(fn {status, ids} ->
      is_nil(status) or Enum.all?(ids, &is_nil/1)
    end)
    |> Map.new(fn {status, ids} -> {status, sorted_stable_ids(ids)} end)
  end

  defp station_reservation_summary_ids(row) do
    [
      row["station_reservation_id"],
      row["station_calendar_reservation_ids"]
    ]
    |> List.flatten()
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
  end

  defp allocation_summary_review_row?(row) do
    row["review_status"] == "operator_review_required" or
      row["allocation_status"] in ["blocked", "deferred"] or
      row["effective_allocation_status"] == "policy_blocked"
  end

  defp resource_blocked_contact_count(rows) do
    Enum.count(rows, &Map.has_key?(&1, "source_resource_suppression"))
  end

  defp put_effective_allocation_status(%{"allocation_status" => "allocated"} = row) do
    effective_status =
      if row["approval_status"] == "blocked_by_policy",
        do: "policy_blocked",
        else: "allocated"

    Map.put(row, "effective_allocation_status", effective_status)
  end

  defp put_effective_allocation_status(%{"allocation_status" => status} = row),
    do: Map.put(row, "effective_allocation_status", status)

  defp station_calendar_trust_boundary_status_counts(rows) do
    counts =
      rows
      |> Enum.map(& &1["station_calendar_trust_boundary_status"])
      |> Enum.reject(&is_nil/1)
      |> Enum.frequencies()

    if counts == %{}, do: nil, else: counts
  end

  defp count_by(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> Enum.sort_by(fn {key, _count} -> key end)
    |> Map.new()
  end

  defp row_values(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp source_station_calendar_availability_candidates(sources) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_calendar_availability_candidates/1)

  defp source_station_calendar_availability_candidates(%{} = source) do
    [
      source["station_availability"],
      source["availability"],
      source["station_calendar_status"],
      source["status"]
    ]
  end

  defp source_station_calendar_availability_candidates(_source), do: []

  defp station_availability_value?(value)
       when value in ["available", "unavailable", "maintenance", "reserved", "reduced_capacity"],
       do: true

  defp station_availability_value?(_value), do: false

  defp stable_id_or_nil(value),
    do: OrbitalDynamics.Communications.ContactAllocation.ContactIdentity.stable_id_or_nil(value)

  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value * 1.0

  defp numeric_or_nil(value) when is_binary(value) do
    value = String.trim(value)

    case Float.parse(value) do
      {number, ""} -> number
      _result -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp normalize_station_calendar_status_fields(row) do
    OrbitalDynamics.Communications.ContactAllocation.ContactNormalization.normalize_station_calendar_status_fields(
      row,
      @unavailable_aliases
    )
  end

  defp normalized_status_token(value) do
    OrbitalDynamics.Communications.ContactAllocation.ContactNormalization.normalized_status_token(
      value,
      @unavailable_aliases
    )
  end

  defp normalize_direction(direction) do
    OrbitalDynamics.Communications.ContactAllocation.ContactNormalization.normalize_direction(
      direction,
      @provider_direction_aliases
    )
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value) when is_boolean(value), do: value
  defp stringify_keys(nil), do: nil
  defp stringify_keys(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_keys(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key
end
