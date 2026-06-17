defmodule OrbitalDynamics.Schema.ContactAllocationReportContracts do
  @moduledoc false

  @stable_id_regex ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/

  def validate_row(issues, path, row, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, row, [
      "id",
      "contact_id",
      "allocation_status",
      "effective_allocation_status"
    ])
    |> validate_stable_ids(callbacks, path, row, [
      "id",
      "contact_id",
      "scenario_id",
      "ground_station_id",
      "spacecraft_id",
      "source_window_id",
      "contention_group_id",
      "capacity_pack_group_id",
      "selected_contact_id",
      "station_calendar_entry_id",
      "station_calendar_provider_id",
      "station_calendar_provider_entry_id",
      "station_reservation_id"
    ])
    |> expect_optional_type(callbacks, path, row, "capacity_pack_status", :binary)
    |> expect_optional_probability(callbacks, path, row, "capacity_pack_capacity_fraction")
    |> expect_optional_probability(callbacks, path, row, "capacity_pack_used_fraction")
    |> expect_optional_probability(callbacks, path, row, "required_capacity_fraction")
    |> expect_optional_type(callbacks, path, row, "required_capacity_fraction_source", :binary)
    |> expect_optional_probability(callbacks, path, row, "capacity_fraction")
    |> expect_optional_number(callbacks, path, row, "actual_throughput_mb")
    |> expect_optional_type(callbacks, path, row, "actual_data_rate_throughput_derivation", :map)
    |> validate_optional_actual_data_rate_throughput_derivation(
      callbacks,
      path,
      row,
      "actual_data_rate_throughput_derivation"
    )
    |> expect_optional_probability(callbacks, path, row, "completed_fraction")
    |> expect_optional_non_negative_number(callbacks, path, row, "required_downlink_mb")
    |> expect_optional_non_negative_number(callbacks, path, row, "candidate_downlink_mb")
    |> expect_optional_probability(callbacks, path, row, "downlink_completion_ratio")
    |> expect_optional_non_negative_number(callbacks, path, row, "selected_downlink_shortfall_mb")
    |> expect_optional_type(callbacks, path, row, "downlink_requirement_status", :binary)
    |> expect_optional_type(callbacks, path, row, "downlink_completion_source", :binary)
    |> expect_optional_type(callbacks, path, row, "downlink_completion_sources", :list)
    |> validate_string_list_items(callbacks, path, row, "downlink_completion_sources")
    |> expect_optional_type(callbacks, path, row, "contact_success", :boolean)
    |> expect_optional_type(callbacks, path, row, "contact_result", :binary)
    |> expect_optional_probability(callbacks, path, row, "contact_success_factor")
    |> expect_optional_type(callbacks, path, row, "contact_success_factor_source", :binary)
    |> expect_optional_type(callbacks, path, row, "command_success", :boolean)
    |> expect_optional_type(callbacks, path, row, "command_result", :binary)
    |> expect_optional_probability(callbacks, path, row, "command_success_factor")
    |> expect_optional_type(callbacks, path, row, "command_success_factor_source", :binary)
    |> expect_one_of(callbacks, path, row, "allocation_status", contact_allocation_row_statuses())
    |> expect_one_of(
      callbacks,
      path,
      row,
      "effective_allocation_status",
      contact_allocation_effective_row_statuses()
    )
    |> expect_optional_type(callbacks, path, row, "allocation_reason", :binary)
    |> expect_optional_type(callbacks, path, row, "source_approval_status", :binary)
    |> expect_optional_type(callbacks, path, row, "review_status", :binary)
    |> expect_optional_type(callbacks, path, row, "source_contact_suppression", :map)
    |> expect_optional_type(callbacks, path, row, "source_resource_suppression", :map)
    |> validate_stable_ids(callbacks, path, row, ["provider_counteroffer_id"])
    |> expect_optional_type(callbacks, path, row, "provider_counteroffer_status", :binary)
    |> expect_optional_one_of(
      callbacks,
      path,
      row,
      "provider_counteroffer_negotiation_state",
      provider_counteroffer_negotiation_states()
    )
    |> expect_optional_type(callbacks, path, row, "provider_counteroffer_reason_code", :binary)
    |> expect_optional_number(callbacks, path, row, "provider_counteroffer_cost_delta")
    |> expect_optional_number(callbacks, path, row, "provider_counteroffer_lock_deadline_s")
    |> expect_optional_number(callbacks, path, row, "provider_counteroffer_starts_at_s")
    |> expect_optional_number(callbacks, path, row, "provider_counteroffer_ends_at_s")
    |> expect_optional_number(callbacks, path, row, "provider_counteroffer_start_delta_s")
    |> expect_optional_number(callbacks, path, row, "provider_counteroffer_end_delta_s")
    |> expect_optional_number(callbacks, path, row, "provider_counteroffer_duration_delta_s")
    |> expect_optional_type(callbacks, path, row, "suppressed_reason", :binary)
    |> expect_optional_type(callbacks, path, row, "resource_blocking_dimension", :binary)
    |> expect_optional_type(callbacks, path, row, "resource_source_quality", :binary)
    |> expect_optional_type(callbacks, path, row, "resource_trust_boundary", :binary)
    |> expect_optional_type(callbacks, path, row, "resource_trust_boundary_status", :binary)
    |> expect_optional_type(callbacks, path, row, "resource_provenance", :map)
    |> expect_optional_type(callbacks, path, row, "source_resource_summary", :map)
    |> expect_optional_number(callbacks, path, row, "fuel_margin")
    |> expect_optional_number(callbacks, path, row, "power_margin")
    |> expect_optional_number(callbacks, path, row, "storage_margin")
    |> expect_optional_number(callbacks, path, row, "downlink_margin")
    |> expect_optional_number(callbacks, path, row, "thermal_margin_c")
    |> expect_optional_number(callbacks, path, row, "battery_capacity_wh")
    |> expect_optional_number(callbacks, path, row, "battery_energy_used_wh")
    |> expect_optional_non_negative_number(callbacks, path, row, "battery_energy_generated_wh")
    |> expect_optional_number(callbacks, path, row, "battery_state_of_charge")
    |> expect_optional_type(callbacks, path, row, "spacecraft_available", :boolean)
    |> expect_optional_type(callbacks, path, row, "payload_available", :boolean)
    |> expect_optional_type(callbacks, path, row, "antenna_available", :boolean)
    |> expect_optional_type(callbacks, path, row, "degraded", :boolean)
    |> expect_optional_type(callbacks, path, row, "mode", :binary)
    |> expect_optional_type(callbacks, path, row, "incompatible_activity_types", :list)
    |> validate_string_list_items(callbacks, path, row, "incompatible_activity_types")
    |> expect_optional_type(callbacks, path, row, "suppressed_activity_types", :list)
    |> validate_string_list_items(callbacks, path, row, "suppressed_activity_types")
    |> expect_optional_type(callbacks, path, row, "source_station_calendar_contact", :map)
    |> expect_optional_type(callbacks, path, row, "source_station_calendar_entry", :map)
    |> expect_optional_type(callbacks, path, row, "source_station_calendar_overlaps", :list)
    |> expect_optional_type(callbacks, path, row, "station_availability", :binary)
    |> expect_optional_type(callbacks, path, row, "station_calendar_status", :binary)
    |> expect_optional_integer(callbacks, path, row, "station_calendar_precedence_rank")
    |> expect_field_at_least(callbacks, path, row, "station_calendar_precedence_rank", 0)
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "station_calendar_precedence_availability",
      :binary
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "station_calendar_trust_boundary_status",
      :binary
    )
    |> expect_optional_type(callbacks, path, row, "trust_boundary", :binary)
    |> expect_optional_type(callbacks, path, row, "provenance", :map)
    |> expect_optional_type(callbacks, path, row, "station_calendar_directions", :list)
    |> validate_string_list_items(callbacks, path, row, "station_calendar_directions")
    |> expect_optional_integer(callbacks, path, row, "station_calendar_overlap_count")
    |> expect_optional_type(callbacks, path, row, "station_calendar_overlap_entry_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "station_calendar_overlap_entry_ids"
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "station_calendar_overlap_availabilities",
      :list
    )
    |> validate_string_list_items(callbacks, path, row, "station_calendar_overlap_availabilities")
    |> expect_optional_type(callbacks, path, row, "station_calendar_entry_ambiguous", :boolean)
    |> expect_optional_integer(callbacks, path, row, "station_calendar_ambiguous_entry_count")
    |> expect_field_at_least(callbacks, path, row, "station_calendar_ambiguous_entry_count", 0)
    |> expect_optional_type(callbacks, path, row, "station_calendar_ambiguous_entry_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "station_calendar_ambiguous_entry_ids"
    )
    |> expect_optional_integer(callbacks, path, row, "station_calendar_reservation_overlap_count")
    |> expect_field_at_least(
      callbacks,
      path,
      row,
      "station_calendar_reservation_overlap_count",
      0
    )
    |> expect_optional_type(callbacks, path, row, "station_calendar_reservation_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "station_calendar_reservation_ids")
    |> expect_optional_type(callbacks, path, row, "station_calendar_reserved_by", :list)
    |> validate_string_list_items(callbacks, path, row, "station_calendar_reserved_by")
    |> expect_optional_type(callbacks, path, row, "station_calendar_reservation_statuses", :list)
    |> validate_string_list_items(callbacks, path, row, "station_calendar_reservation_statuses")
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "station_calendar_reservation_expires_at_s",
      :list
    )
    |> validate_number_list_items(
      callbacks,
      path,
      row,
      "station_calendar_reservation_expires_at_s"
    )
    |> expect_optional_type(callbacks, path, row, "station_contention_status", :binary)
    |> expect_optional_number(callbacks, path, row, "station_reservation_expires_at_s")
    |> expect_optional_type(callbacks, path, row, "station_reserved_by", :binary)
    |> expect_optional_type(callbacks, path, row, "station_reservation_status", :binary)
    |> expect_optional_type(callbacks, path, row, "station_reservation_match_status", :binary)
    |> expect_optional_integer(callbacks, path, row, "duplicate_contact_candidate_count")
    |> expect_optional_type(callbacks, path, row, "duplicate_contact_candidate_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".duplicate_contact_candidate_ids",
      Map.get(row, "duplicate_contact_candidate_ids")
    )
    |> expect_optional_number(callbacks, path, row, "selected_priority")
    |> expect_optional_type(callbacks, path, row, "selected_priority_source", :binary)
    |> expect_optional_type(callbacks, path, row, "deferred_contact_priorities", :list)
    |> validate_optional_rows(
      callbacks,
      path <> ".deferred_contact_priorities",
      Map.get(row, "deferred_contact_priorities"),
      fn acc, row_path, deferred_row ->
        validate_contact_contention_deferred_priority(callbacks, acc, row_path, deferred_row)
      end
    )
    |> expect_optional_type(callbacks, path, row, "requested_priority_fields", :list)
    |> validate_string_list_items(callbacks, path, row, "requested_priority_fields")
    |> expect_optional_type(callbacks, path, row, "priority_field_evidence_counts", :map)
    |> validate_priority_field_evidence_counts(
      callbacks,
      path <> ".priority_field_evidence_counts",
      Map.get(row, "priority_field_evidence_counts")
    )
    |> expect_optional_integer(
      callbacks,
      path,
      row,
      "priority_fields_without_numeric_evidence_count"
    )
    |> expect_field_at_least(
      callbacks,
      path,
      row,
      "priority_fields_without_numeric_evidence_count",
      0
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "priority_fields_without_numeric_evidence",
      :list
    )
    |> validate_string_list_items(
      callbacks,
      path,
      row,
      "priority_fields_without_numeric_evidence"
    )
    |> expect_optional_integer(callbacks, path, row, "resolution_priority_override_count")
    |> expect_field_at_least(callbacks, path, row, "resolution_priority_override_count", 0)
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "resolution_priority_override_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "resolution_priority_override_contact_ids"
    )
    |> validate_override_count_matches_ids(
      callbacks,
      path,
      row,
      "resolution_priority_override_count",
      "resolution_priority_override_contact_ids"
    )
    |> validate_station_calendar_contact_counts(callbacks, path, row)
    |> validate_duplicate_evidence(path, row, callbacks)
  end

  def validate_capacity_pack_group(issues, path, group, callbacks) when is_list(callbacks) do
    issues
    |> validate_stable_ids(callbacks, path, group, ["contention_group_id", "ground_station_id"])
    |> expect_optional_probability(callbacks, path, group, "capacity_fraction")
    |> expect_optional_probability(callbacks, path, group, "used_capacity_fraction")
    |> expect_optional_probability(callbacks, path, group, "unused_capacity_fraction")
    |> expect_optional_probability(callbacks, path, group, "default_required_capacity_fraction")
    |> expect_optional_type(callbacks, path, group, "input_contact_ids", :list)
    |> expect_optional_type(callbacks, path, group, "selected_contact_ids", :list)
    |> expect_optional_type(callbacks, path, group, "capacity_packed_contact_ids", :list)
    |> expect_optional_type(callbacks, path, group, "deferred_contact_ids", :list)
    |> expect_optional_type(
      callbacks,
      path,
      group,
      "capacity_pack_contact_ids_by_direction",
      :map
    )
    |> expect_optional_type(
      callbacks,
      path,
      group,
      "capacity_pack_selected_contact_ids_by_direction",
      :map
    )
    |> expect_optional_type(
      callbacks,
      path,
      group,
      "capacity_pack_deferred_contact_ids_by_direction",
      :map
    )
    |> expect_optional_type(
      callbacks,
      path,
      group,
      "capacity_pack_required_capacity_fraction_by_direction",
      :map
    )
    |> expect_optional_type(
      callbacks,
      path,
      group,
      "capacity_pack_selected_required_capacity_fraction_by_direction",
      :map
    )
    |> expect_optional_type(
      callbacks,
      path,
      group,
      "capacity_pack_deferred_required_capacity_fraction_by_direction",
      :map
    )
    |> expect_optional_type(callbacks, path, group, "capacity_requirement_rows", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".input_contact_ids",
      Map.get(group, "input_contact_ids")
    )
    |> validate_stable_id_list(
      callbacks,
      path <> ".selected_contact_ids",
      Map.get(group, "selected_contact_ids")
    )
    |> validate_stable_id_list(
      callbacks,
      path <> ".capacity_packed_contact_ids",
      Map.get(group, "capacity_packed_contact_ids")
    )
    |> validate_stable_id_list(
      callbacks,
      path <> ".deferred_contact_ids",
      Map.get(group, "deferred_contact_ids")
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".capacity_pack_contact_ids_by_direction",
      Map.get(group, "capacity_pack_contact_ids_by_direction")
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".capacity_pack_selected_contact_ids_by_direction",
      Map.get(group, "capacity_pack_selected_contact_ids_by_direction")
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".capacity_pack_deferred_contact_ids_by_direction",
      Map.get(group, "capacity_pack_deferred_contact_ids_by_direction")
    )
    |> validate_non_negative_number_map(
      callbacks,
      path <> ".capacity_pack_required_capacity_fraction_by_direction",
      Map.get(group, "capacity_pack_required_capacity_fraction_by_direction")
    )
    |> validate_non_negative_number_map(
      callbacks,
      path <> ".capacity_pack_selected_required_capacity_fraction_by_direction",
      Map.get(group, "capacity_pack_selected_required_capacity_fraction_by_direction")
    )
    |> validate_non_negative_number_map(
      callbacks,
      path <> ".capacity_pack_deferred_required_capacity_fraction_by_direction",
      Map.get(group, "capacity_pack_deferred_required_capacity_fraction_by_direction")
    )
    |> validate_capacity_pack_group_derived_fields(callbacks, path, group)
    |> validate_optional_rows(
      callbacks,
      path <> ".capacity_requirement_rows",
      Map.get(group, "capacity_requirement_rows"),
      fn acc, row_path, row ->
        validate_capacity_requirement_row(acc, row_path, row, callbacks)
      end
    )
  end

  def validate_counts(issues, path, report, callbacks) when is_list(callbacks) do
    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    station_report = Map.get(report, "station_calendar_report", %{})
    station_pressure_rows = station_pressure_rows(rows)
    reservation_expiration_rows = reservation_expiration_rows(rows)
    resource_blocked_rows = resource_blocked_rows(rows)
    capacity_pack_rows = capacity_pack_rows(rows)
    selected_capacity_pack_rows = selected_capacity_pack_rows(capacity_pack_rows)
    deferred_capacity_pack_rows = deferred_capacity_pack_rows(capacity_pack_rows)

    issues
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".allocation_status_counts",
      Map.get(report, "allocation_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".effective_allocation_status_counts",
      Map.get(report, "effective_allocation_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".allocation_reason_counts",
      Map.get(report, "allocation_reason_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".station_reservation_match_status_counts",
      Map.get(report, "station_reservation_match_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".station_reservation_expiration_status_counts",
      Map.get(report, "station_reservation_expiration_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".resource_blocking_dimension_counts",
      Map.get(report, "resource_blocking_dimension_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".reduced_capacity_pack_status_counts",
      Map.get(report, "reduced_capacity_pack_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".capacity_pack_status_counts",
      Map.get(report, "capacity_pack_status_counts")
    )
    |> validate_non_negative_number_map(
      callbacks,
      path <> ".capacity_pack_required_capacity_fraction_by_status",
      Map.get(report, "capacity_pack_required_capacity_fraction_by_status")
    )
    |> validate_non_negative_number_map(
      callbacks,
      path <> ".capacity_pack_required_capacity_fraction_by_ground_station_id",
      Map.get(report, "capacity_pack_required_capacity_fraction_by_ground_station_id")
    )
    |> validate_non_negative_number_map(
      callbacks,
      path <> ".capacity_pack_selected_required_capacity_fraction_by_ground_station_id",
      Map.get(report, "capacity_pack_selected_required_capacity_fraction_by_ground_station_id")
    )
    |> validate_non_negative_number_map(
      callbacks,
      path <> ".capacity_pack_deferred_required_capacity_fraction_by_ground_station_id",
      Map.get(report, "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id")
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "allocation_status_counts",
      frequency_map(callbacks, rows, "allocation_status"),
      "must equal row-derived allocation_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "effective_allocation_status_counts",
      frequency_map(callbacks, rows, "effective_allocation_status"),
      "must equal row-derived effective_allocation_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "allocation_reason_counts",
      frequency_map(callbacks, rows, "allocation_reason"),
      "must equal row-derived allocation_reason_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "station_reservation_match_status_counts",
      frequency_map(callbacks, rows, "station_reservation_match_status"),
      "must equal row-derived station_reservation_match_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "station_reservation_expiration_status_counts",
      frequency_map(
        callbacks,
        reservation_expiration_rows,
        "station_reservation_expiration_status"
      ),
      "must equal row-derived station_reservation_expiration_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "station_reservation_declared_expiration_contact_count",
      reservation_expiration_count(reservation_expiration_rows, "declared"),
      "must equal row-derived station_reservation_declared_expiration_contact_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "station_reservation_missing_expiration_contact_count",
      reservation_expiration_count(reservation_expiration_rows, "missing"),
      "must equal row-derived station_reservation_missing_expiration_contact_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "resource_blocking_dimension_counts",
      frequency_map(callbacks, resource_blocked_rows, "resource_blocking_dimension"),
      "must equal row-derived resource_blocking_dimension_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "resource_blocked_contact_ids_by_blocking_dimension",
      row_ids_by_field(
        callbacks,
        resource_blocked_rows,
        "resource_blocking_dimension",
        "contact_id"
      ),
      "must equal row-derived resource_blocked_contact_ids_by_blocking_dimension"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "resource_blocked_contact_ids_by_spacecraft_id",
      row_ids_by_field(callbacks, resource_blocked_rows, "spacecraft_id", "contact_id"),
      "must equal row-derived resource_blocked_contact_ids_by_spacecraft_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "reduced_capacity_pack_status_counts",
      frequency_map(
        callbacks,
        Map.get(report, "reduced_capacity_pack_groups", []),
        "pack_status"
      ),
      "must equal reduced-capacity-pack-group-derived reduced_capacity_pack_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "capacity_pack_status_counts",
      frequency_map(callbacks, rows, "capacity_pack_status"),
      "must equal row-derived capacity_pack_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "capacity_pack_contact_ids_by_status",
      row_ids_by_field(callbacks, rows, "capacity_pack_status", "contact_id"),
      "must equal row-derived capacity_pack_contact_ids_by_status"
    )
    |> expect_number_field_equals(
      callbacks,
      path,
      report,
      "capacity_pack_required_capacity_fraction",
      capacity_pack_required_fraction(capacity_pack_rows),
      "must equal row-derived capacity_pack_required_capacity_fraction"
    )
    |> expect_number_field_equals(
      callbacks,
      path,
      report,
      "capacity_pack_selected_required_capacity_fraction",
      capacity_pack_required_fraction(selected_capacity_pack_rows),
      "must equal row-derived capacity_pack_selected_required_capacity_fraction"
    )
    |> expect_number_field_equals(
      callbacks,
      path,
      report,
      "capacity_pack_deferred_required_capacity_fraction",
      capacity_pack_required_fraction(deferred_capacity_pack_rows),
      "must equal row-derived capacity_pack_deferred_required_capacity_fraction"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "capacity_pack_required_capacity_fraction_by_status",
      capacity_pack_required_fraction_by_field(capacity_pack_rows, "capacity_pack_status"),
      "must equal row-derived capacity_pack_required_capacity_fraction_by_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "capacity_pack_required_capacity_fraction_by_ground_station_id",
      capacity_pack_required_fraction_by_field(capacity_pack_rows, "ground_station_id"),
      "must equal row-derived capacity_pack_required_capacity_fraction_by_ground_station_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id",
      capacity_pack_required_fraction_by_field(selected_capacity_pack_rows, "ground_station_id"),
      "must equal row-derived capacity_pack_selected_required_capacity_fraction_by_ground_station_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id",
      capacity_pack_required_fraction_by_field(deferred_capacity_pack_rows, "ground_station_id"),
      "must equal row-derived capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "reduced_capacity_packed_contact_ids",
      row_ids_by_field_value(
        callbacks,
        rows,
        "capacity_pack_status",
        "selected_by_reduced_station_capacity_pack",
        "contact_id"
      ),
      "must equal row-derived reduced_capacity_packed_contact_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "reduced_capacity_deferred_contact_ids",
      row_ids_by_field_value(
        callbacks,
        rows,
        "capacity_pack_status",
        "deferred_by_reduced_station_capacity_pack",
        "contact_id"
      ),
      "must equal row-derived reduced_capacity_deferred_contact_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "required_capacity_fraction_source_counts",
      frequency_map(callbacks, rows, "required_capacity_fraction_source"),
      "must equal row-derived required_capacity_fraction_source_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "required_capacity_fraction_contact_ids_by_source",
      row_ids_by_field(callbacks, rows, "required_capacity_fraction_source", "contact_id"),
      "must equal row-derived required_capacity_fraction_contact_ids_by_source"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "station_pressure_contact_ids_by_ground_station_id",
      row_ids_by_field(callbacks, station_pressure_rows, "ground_station_id", "contact_id"),
      "must equal row-derived station_pressure_contact_ids_by_ground_station_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "station_pressure_contact_counts_by_ground_station_id",
      row_ids_by_field(callbacks, station_pressure_rows, "ground_station_id", "contact_id")
      |> id_array_count_map(callbacks),
      "must equal row-derived station_pressure_contact_counts_by_ground_station_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "station_pressure_contact_ids_by_availability",
      station_pressure_ids_by_availability(station_pressure_rows),
      "must equal row-derived station_pressure_contact_ids_by_availability"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "station_pressure_contact_counts_by_availability",
      station_pressure_rows
      |> station_pressure_ids_by_availability()
      |> id_array_count_map(callbacks),
      "must equal row-derived station_pressure_contact_counts_by_availability"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "station_pressure_contact_ids_by_precedence_availability",
      row_ids_by_field(
        callbacks,
        station_pressure_rows,
        "station_calendar_precedence_availability",
        "contact_id"
      ),
      "must equal row-derived station_pressure_contact_ids_by_precedence_availability"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "station_pressure_contact_counts_by_precedence_availability",
      row_ids_by_field(
        callbacks,
        station_pressure_rows,
        "station_calendar_precedence_availability",
        "contact_id"
      )
      |> id_array_count_map(callbacks),
      "must equal row-derived station_pressure_contact_counts_by_precedence_availability"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "station_pressure_contact_ids_by_precedence_rank",
      row_ids_by_string_field(
        callbacks,
        station_pressure_rows,
        "station_calendar_precedence_rank",
        "contact_id"
      ),
      "must equal row-derived station_pressure_contact_ids_by_precedence_rank"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "station_pressure_contact_counts_by_precedence_rank",
      row_ids_by_string_field(
        callbacks,
        station_pressure_rows,
        "station_calendar_precedence_rank",
        "contact_id"
      )
      |> id_array_count_map(callbacks),
      "must equal row-derived station_pressure_contact_counts_by_precedence_rank"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "station_pressure_contact_ids_by_status",
      row_ids_by_field(callbacks, station_pressure_rows, "station_calendar_status", "contact_id"),
      "must equal row-derived station_pressure_contact_ids_by_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "station_pressure_contact_counts_by_status",
      row_ids_by_field(callbacks, station_pressure_rows, "station_calendar_status", "contact_id")
      |> id_array_count_map(callbacks),
      "must equal row-derived station_pressure_contact_counts_by_status"
    )
    |> expect_optional_field_equals(
      callbacks,
      path,
      report,
      "station_pressure_contact_ids_by_direction_and_ground_station_id",
      row_ids_by_direction_and_ground_station(callbacks, station_pressure_rows, "contact_id"),
      "must equal row-derived station_pressure_contact_ids_by_direction_and_ground_station_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "station_calendar_trust_boundary_status_counts",
      frequency_map(callbacks, rows, "station_calendar_trust_boundary_status"),
      "must equal row-derived station_calendar_trust_boundary_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "calendar_entry_trust_boundary_status_counts",
      Map.get(station_report, "calendar_entry_trust_boundary_status_counts"),
      "must match station_calendar_report.calendar_entry_trust_boundary_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "station_reservation_ids",
      row_unique_values(callbacks, rows, "station_reservation_id"),
      "must equal row-derived station_reservation_ids"
    )
    |> expect_optional_field_equals(
      callbacks,
      path,
      report,
      "earliest_station_reservation_expires_at_s",
      earliest_reservation_expires_at_s(reservation_expiration_rows),
      "must equal row-derived earliest_station_reservation_expires_at_s"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "station_reservation_contact_ids_by_expiration_status",
      row_ids_by_field(
        callbacks,
        reservation_expiration_rows,
        "station_reservation_expiration_status",
        "contact_id"
      ),
      "must equal row-derived station_reservation_contact_ids_by_expiration_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "station_reservation_ids_by_expiration_status",
      reservation_ids_by_expiration_status(reservation_expiration_rows),
      "must equal row-derived station_reservation_ids_by_expiration_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "station_reserved_bys",
      row_unique_values(callbacks, rows, "station_reserved_by"),
      "must equal row-derived station_reserved_bys"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "station_reservation_statuses",
      row_unique_values(callbacks, rows, "station_reservation_status"),
      "must equal row-derived station_reservation_statuses"
    )
    |> validate_ids_match_row_multiset(
      path,
      report,
      "invalid_contact_input_ids",
      invalid_contact_input_ids(rows),
      "must equal row-derived invalid_contact_input_ids"
    )
    |> validate_ids_match_row_multiset(
      path,
      report,
      "status_blocked_contact_ids",
      status_blocked_contact_ids(rows),
      "must equal row-derived status_blocked_contact_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "reduced_capacity_pack_group_count",
      list_count(callbacks, report, "reduced_capacity_pack_groups")
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "duplicate_contact_candidate_count",
      rows
      |> Enum.filter(&(Map.get(&1, "allocation_reason") == "duplicate_contact_id"))
      |> length()
    )
  end

  def validate_duplicate_evidence(issues, path, row, callbacks) when is_list(callbacks) do
    if Map.get(row, "allocation_reason") == "duplicate_contact_id" do
      ids = Map.get(row, "duplicate_contact_candidate_ids")

      issues
      |> require_fields(callbacks, path, row, ["duplicate_contact_candidate_ids"])
      |> expect_field_equals(
        callbacks,
        path,
        row,
        "duplicate_contact_candidate_count",
        if(is_list(ids), do: length(ids), else: nil)
      )
    else
      issues
    end
  end

  def review_row?(row) do
    Map.get(row, "review_status") == "operator_review_required" or
      Map.get(row, "allocation_status") in ["blocked", "deferred"] or
      Map.get(row, "effective_allocation_status") == "policy_blocked"
  end

  def row_contact_ids(rows) do
    rows
    |> Enum.map(&Map.get(&1, "contact_id"))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def invalid_contact_input_ids(rows) do
    rows
    |> Enum.filter(&(&1["invalid_contact_input"] == true))
    |> Enum.map(&Map.get(&1, "contact_id"))
    |> Enum.reject(&is_nil/1)
  end

  def status_blocked_contact_ids(rows) do
    rows
    |> Enum.filter(&status_blocked_row?/1)
    |> Enum.map(&Map.get(&1, "contact_id"))
    |> Enum.reject(&is_nil/1)
  end

  def resource_blocked_rows(rows) do
    Enum.filter(rows, &Map.has_key?(&1, "source_resource_suppression"))
  end

  def capacity_pack_rows(rows) do
    Enum.filter(rows, fn row ->
      is_map(row) and is_binary(row["capacity_pack_status"]) and
        is_number(row["required_capacity_fraction"])
    end)
  end

  def selected_capacity_pack_rows(rows) do
    Enum.filter(rows, fn row ->
      row["capacity_pack_status"] in [
        "selected_by_contention_resolution",
        "selected_by_reduced_station_capacity_pack"
      ]
    end)
  end

  def deferred_capacity_pack_rows(rows) do
    Enum.filter(
      rows,
      &(&1["capacity_pack_status"] == "deferred_by_reduced_station_capacity_pack")
    )
  end

  def capacity_pack_required_fraction(rows) do
    rows
    |> Enum.map(&Map.get(&1, "required_capacity_fraction"))
    |> Enum.filter(&is_number/1)
    |> Enum.sum()
  end

  def capacity_pack_required_fraction_by_field(rows, field) do
    rows
    |> Enum.reduce(%{}, fn row, totals ->
      field_value = Map.get(row, field)
      required_fraction = Map.get(row, "required_capacity_fraction")

      if is_nil(field_value) or not is_number(required_fraction) do
        totals
      else
        Map.update(totals, field_value, required_fraction, &(&1 + required_fraction))
      end
    end)
  end

  def reservation_expiration_rows(rows) do
    rows
    |> Enum.filter(&reservation_expiration_row?/1)
    |> Enum.map(fn row ->
      expires_at_s = reservation_expires_at_s(row)

      row
      |> Map.put("station_reservation_summary_expires_at_s", expires_at_s)
      |> Map.put(
        "station_reservation_expiration_status",
        if(is_number(expires_at_s), do: "declared", else: "missing")
      )
    end)
  end

  def reservation_expiration_rows(rows, now_s) do
    rows
    |> Enum.filter(&reservation_expiration_row?/1)
    |> Enum.map(fn row ->
      expires_at_s = reservation_expires_at_s(row)

      row
      |> Map.put("station_reservation_summary_expires_at_s", expires_at_s)
      |> Map.put(
        "station_reservation_expiration_status",
        reservation_expiration_status(expires_at_s, now_s)
      )
    end)
  end

  def reservation_expiration_count(rows, status) do
    Enum.count(rows, &(&1["station_reservation_expiration_status"] == status))
  end

  def earliest_reservation_expires_at_s(rows) do
    rows
    |> Enum.map(& &1["station_reservation_summary_expires_at_s"])
    |> Enum.reject(&is_nil/1)
    |> Enum.min(fn -> nil end)
  end

  def reservation_ids_by_expiration_status(rows) do
    rows
    |> Enum.flat_map(fn row ->
      row
      |> reservation_ids()
      |> Enum.map(&{row["station_reservation_expiration_status"], &1})
    end)
    |> Enum.group_by(fn {status, _id} -> status end, fn {_status, id} -> id end)
    |> Enum.reject(fn {status, ids} -> is_nil(status) or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {status, ids} -> {status, ids |> Enum.uniq() |> Enum.sort()} end)
  end

  def reservation_row_ids(rows) do
    rows
    |> Enum.map(&Map.get(&1, "station_reservation_id"))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def reservation_expires_at_values(rows) do
    rows
    |> Enum.map(&Map.get(&1, "station_reservation_expires_at_s"))
    |> Enum.filter(&is_number/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def station_pressure_rows(rows) do
    Enum.filter(rows, fn row ->
      pressure_value?(row["station_calendar_overlap_count"]) or
        pressure_value?(row["station_calendar_overlap_availabilities"]) or
        pressure_value?(row["station_calendar_entry_id"]) or
        pressure_value?(row["station_reservation_match_status"]) or
        pressure_value?(row["station_calendar_precedence_rank"]) or
        pressure_value?(row["station_calendar_precedence_availability"]) or
        source_pressure_values(row) != []
    end)
  end

  def station_pressure_ids_by_availability(rows) do
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
      {availability, contact_ids |> Enum.reject(&is_nil/1) |> Enum.uniq() |> Enum.sort()}
    end)
  end

  defp validate_capacity_requirement_row(issues, path, row, callbacks) do
    issues
    |> require_fields(callbacks, path, row, [
      "contact_id",
      "required_capacity_fraction",
      "required_capacity_fraction_source"
    ])
    |> validate_stable_ids(callbacks, path, row, ["contact_id"])
    |> expect_optional_type(callbacks, path, row, "allocation_status", :binary)
    |> expect_optional_type(callbacks, path, row, "allocation_reason", :binary)
    |> expect_optional_type(callbacks, path, row, "capacity_pack_status", :binary)
    |> expect_number(callbacks, path, row, "required_capacity_fraction")
    |> expect_probability_range(callbacks, path, row, "required_capacity_fraction")
    |> expect_type(callbacks, path, row, "required_capacity_fraction_source", :binary)
  end

  defp validate_capacity_pack_group_derived_fields(issues, callbacks, path, group) do
    rows = Map.get(group, "capacity_requirement_rows")

    issues
    |> expect_field_equals(
      callbacks,
      path,
      group,
      "selected_contact_ids",
      capacity_pack_contact_ids(rows, "selected_by_contention_resolution"),
      "must equal capacity requirement rows selected contact IDs"
    )
    |> expect_field_equals(
      callbacks,
      path,
      group,
      "capacity_packed_contact_ids",
      capacity_pack_contact_ids(rows, "selected_by_reduced_station_capacity_pack"),
      "must equal capacity requirement rows packed contact IDs"
    )
    |> expect_field_equals(
      callbacks,
      path,
      group,
      "deferred_contact_ids",
      capacity_pack_contact_ids(rows, "deferred_by_reduced_station_capacity_pack"),
      "must equal capacity requirement rows deferred contact IDs"
    )
    |> expect_number_field_equals(
      callbacks,
      path,
      group,
      "used_capacity_fraction",
      capacity_pack_used_capacity_fraction(rows),
      "must equal capacity requirement rows selected capacity"
    )
    |> expect_number_field_equals(
      callbacks,
      path,
      group,
      "unused_capacity_fraction",
      capacity_pack_unused_capacity_fraction(group, rows),
      "must equal capacity minus selected capacity"
    )
  end

  defp capacity_pack_contact_ids(rows, status) when is_list(rows) do
    rows
    |> Enum.filter(&(Map.get(&1, "capacity_pack_status") == status))
    |> Enum.map(&Map.get(&1, "contact_id"))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp capacity_pack_contact_ids(_rows, _status), do: nil

  defp capacity_pack_used_capacity_fraction(rows) when is_list(rows) do
    rows
    |> Enum.filter(fn row ->
      Map.get(row, "capacity_pack_status") in [
        "selected_by_contention_resolution",
        "selected_by_reduced_station_capacity_pack"
      ]
    end)
    |> Enum.map(&Map.get(&1, "required_capacity_fraction"))
    |> Enum.reduce(0.0, fn
      value, acc when is_number(value) -> acc + value
      _value, acc -> acc
    end)
  end

  defp capacity_pack_used_capacity_fraction(_rows), do: nil

  defp capacity_pack_unused_capacity_fraction(group, rows) when is_list(rows) do
    capacity_fraction = Map.get(group, "capacity_fraction")
    used_fraction = capacity_pack_used_capacity_fraction(rows)

    if is_number(capacity_fraction) and is_number(used_fraction) do
      max(capacity_fraction - used_fraction, 0.0)
    end
  end

  defp capacity_pack_unused_capacity_fraction(_group, _rows), do: nil

  defp validate_ids_match_row_multiset(issues, path, report, field, expected_ids, message) do
    ids = Map.get(report, field)

    if is_list(ids) and Enum.sort(ids) != Enum.sort(expected_ids) do
      [error("#{path}.#{field}", message) | issues]
    else
      issues
    end
  end

  defp status_blocked_row?(row) do
    reason = row["allocation_reason"]

    is_binary(reason) and
      (String.starts_with?(reason, "activity_status_") or
         String.starts_with?(reason, "approval_status_"))
  end

  defp reservation_expiration_status(nil, _now_s), do: "missing"
  defp reservation_expiration_status(_expires_at_s, nil), do: "declared"

  defp reservation_expiration_status(expires_at_s, now_s)
       when is_number(expires_at_s) and is_number(now_s) and expires_at_s <= now_s,
       do: "expired"

  defp reservation_expiration_status(_expires_at_s, _now_s), do: "active"

  def reservation_expiration_row?(row) do
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
      &pressure_value?/1
    )
  end

  defp reservation_expires_at_s(row) do
    [
      row["station_reservation_expires_at_s"],
      row["station_calendar_reservation_expires_at_s"]
    ]
    |> List.flatten()
    |> Enum.find(&is_number/1)
  end

  def reservation_ids(row) do
    [
      row["station_reservation_id"],
      row["station_calendar_reservation_ids"]
    ]
    |> List.flatten()
    |> Enum.filter(&(is_binary(&1) and Regex.match?(@stable_id_regex, &1)))
  end

  def pressure_value?(nil), do: false
  def pressure_value?([]), do: false
  def pressure_value?(value) when is_number(value), do: value > 0
  def pressure_value?(value) when is_binary(value), do: value != ""
  def pressure_value?(_value), do: true

  defp station_pressure_availability_values(row) do
    direct_values =
      row
      |> Map.take(["station_availability", "availability", "station_calendar_status"])
      |> Map.values()

    source_values =
      source_availability_candidates(row["source_station_calendar_entry"]) ++
        source_availability_candidates(row["source_station_calendar_overlaps"])

    (direct_values ++ List.wrap(row["station_calendar_overlap_availabilities"]) ++ source_values)
    |> Enum.map(&status_token/1)
    |> Enum.filter(&station_availability?/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp source_pressure_values(row) do
    (source_availability_candidates(row["source_station_calendar_entry"]) ++
       source_availability_candidates(row["source_station_calendar_overlaps"]))
    |> Enum.map(&status_token/1)
    |> Enum.filter(&pressure_availability?/1)
    |> Enum.uniq()
  end

  defp source_availability_candidates(nil), do: []

  defp source_availability_candidates(entries) when is_list(entries) do
    Enum.flat_map(entries, &source_availability_candidates/1)
  end

  defp source_availability_candidates(%{} = entry) do
    [entry["availability"], entry["status"], entry["station_availability"]]
  end

  defp source_availability_candidates(_entry), do: []

  defp status_token(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> canonical_status_token()
  end

  defp status_token(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> status_token()
  end

  defp status_token(value), do: value

  defp canonical_status_token(value) when value in ["outage", "down", "offline"],
    do: "unavailable"

  defp canonical_status_token(value), do: value

  defp station_availability?(value)
       when value in ["available", "unavailable", "maintenance", "reserved", "reduced_capacity"],
       do: true

  defp station_availability?(_value), do: false

  defp pressure_availability?(value)
       when value in ["unavailable", "maintenance", "reserved", "reduced_capacity"],
       do: true

  defp pressure_availability?(_value), do: false

  defp contact_allocation_capability_value(key),
    do: OrbitalDynamics.Communications.ContactAllocation.capabilities() |> Map.fetch!(key)

  defp contact_allocation_row_statuses, do: contact_allocation_capability_value(:row_statuses)

  defp contact_allocation_effective_row_statuses,
    do: contact_allocation_capability_value(:effective_row_statuses)

  defp provider_counteroffer_negotiation_states do
    OrbitalDynamics.Communications.StationCalendar.capabilities()
    |> Map.fetch!(:provider_counteroffer_negotiation_states)
  end

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :require_fields), [issues, path, map, fields])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(require_callback(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(require_callback(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_optional_one_of(issues, callbacks, path, map, field, allowed),
    do:
      apply(require_callback(callbacks, :expect_optional_one_of), [
        issues,
        path,
        map,
        field,
        allowed
      ])

  defp expect_optional_integer(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_optional_integer), [issues, path, map, field])

  defp expect_optional_number(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_optional_number), [issues, path, map, field])

  defp expect_number(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_number), [issues, path, map, field])

  defp expect_optional_probability(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_probability), [issues, path, map, field])

  defp expect_optional_non_negative_number(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_non_negative_number), [
        issues,
        path,
        map,
        field
      ])

  defp expect_field_at_least(issues, callbacks, path, map, field, minimum),
    do:
      apply(require_callback(callbacks, :expect_field_at_least), [
        issues,
        path,
        map,
        field,
        minimum
      ])

  defp expect_field_equals(issues, callbacks, path, map, field, expected),
    do:
      apply(require_callback(callbacks, :expect_field_equals), [
        issues,
        path,
        map,
        field,
        expected
      ])

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message),
    do:
      apply(require_callback(callbacks, :expect_field_equals_with_message), [
        issues,
        path,
        map,
        field,
        expected,
        message
      ])

  defp expect_number_field_equals(issues, callbacks, path, map, field, expected, message),
    do:
      apply(require_callback(callbacks, :expect_number_field_equals), [
        issues,
        path,
        map,
        field,
        expected,
        message
      ])

  defp expect_probability_range(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_probability_range), [issues, path, map, field])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp validate_stable_id_list(issues, callbacks, path, values),
    do: apply(require_callback(callbacks, :validate_stable_id_list), [issues, path, values])

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_optional_stable_id_list), [
        issues,
        path,
        map,
        field
      ])

  defp validate_stable_id_array_map(issues, callbacks, path, values),
    do: apply(require_callback(callbacks, :validate_stable_id_array_map), [issues, path, values])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_number_list_items(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_number_list_items), [issues, path, map, field])

  defp validate_optional_rows(issues, callbacks, path, rows, validator),
    do:
      apply(require_callback(callbacks, :validate_optional_rows), [issues, path, rows, validator])

  defp validate_non_negative_number_map(issues, callbacks, path, values),
    do:
      apply(require_callback(callbacks, :validate_non_negative_number_map), [
        issues,
        path,
        values
      ])

  defp validate_non_negative_integer_count_map(issues, callbacks, path, values),
    do:
      apply(require_callback(callbacks, :validate_non_negative_integer_count_map), [
        issues,
        path,
        values
      ])

  defp expect_optional_field_equals(issues, callbacks, path, map, field, expected, message),
    do:
      apply(require_callback(callbacks, :expect_optional_field_equals), [
        issues,
        path,
        map,
        field,
        expected,
        message
      ])

  defp frequency_map(callbacks, rows, field),
    do: apply(require_callback(callbacks, :frequency_map), [rows, field])

  defp id_array_count_map(values, callbacks),
    do: apply(require_callback(callbacks, :id_array_count_map), [values])

  defp list_count(callbacks, map, field),
    do: apply(require_callback(callbacks, :list_count), [map, field])

  defp row_ids_by_direction_and_ground_station(callbacks, rows, id_field),
    do:
      apply(require_callback(callbacks, :row_ids_by_direction_and_ground_station), [
        rows,
        id_field
      ])

  defp row_ids_by_field(callbacks, rows, group_field, id_field),
    do: apply(require_callback(callbacks, :row_ids_by_field), [rows, group_field, id_field])

  defp row_ids_by_field_value(callbacks, rows, field, value, id_field),
    do:
      apply(require_callback(callbacks, :row_ids_by_field_value), [rows, field, value, id_field])

  defp row_ids_by_string_field(callbacks, rows, group_field, id_field),
    do:
      apply(require_callback(callbacks, :row_ids_by_string_field), [rows, group_field, id_field])

  defp row_unique_values(callbacks, rows, field),
    do: apply(require_callback(callbacks, :row_unique_values), [rows, field])

  defp validate_optional_actual_data_rate_throughput_derivation(
         issues,
         callbacks,
         path,
         map,
         field
       ),
       do:
         apply(
           require_callback(callbacks, :validate_optional_actual_data_rate_throughput_derivation),
           [issues, path, map, field]
         )

  defp validate_contact_contention_deferred_priority(callbacks, issues, path, row),
    do:
      apply(require_callback(callbacks, :validate_contact_contention_deferred_priority), [
        issues,
        path,
        row
      ])

  defp validate_priority_field_evidence_counts(issues, callbacks, path, counts),
    do:
      apply(require_callback(callbacks, :validate_priority_field_evidence_counts), [
        issues,
        path,
        counts
      ])

  defp validate_override_count_matches_ids(issues, callbacks, path, map, count_field, ids_field),
    do:
      apply(require_callback(callbacks, :validate_override_count_matches_ids), [
        issues,
        path,
        map,
        count_field,
        ids_field
      ])

  defp validate_station_calendar_contact_counts(issues, callbacks, path, row),
    do:
      apply(require_callback(callbacks, :validate_station_calendar_contact_counts), [
        issues,
        path,
        row
      ])

  defp error(path, message) do
    %{"severity" => "error", "path" => path, "message" => message}
  end
end
