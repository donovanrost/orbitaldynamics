defmodule OrbitalDynamics.Schema.ContactAllocationSummaryContracts do
  @moduledoc false

  def validate_summary(issues, path, summary, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(callbacks, path, summary, "schema_contract", "contact_allocation_summary.v1")
    |> expect_equal(callbacks, path, summary, "model", "artifact_only_contact_allocation_summary")
    |> expect_one_of(callbacks, path, summary, "source_artifact_type", [
      "contact_allocation_report.v1"
    ])
    |> expect_optional_type(callbacks, path, summary, "source", :binary)
    |> expect_optional_type(callbacks, path, summary, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      summary,
      contact_allocation_model_limits(callbacks),
      "must match contact allocation model limits"
    )
    |> validate_field_types(callbacks, path, summary)
    |> expect_type(callbacks, path, summary, "rows", :list)
    |> validate_rows(
      callbacks,
      path <> ".rows",
      Map.get(summary, "rows", []),
      fn acc, row_path, row -> validate_contact_allocation_row(acc, callbacks, row_path, row) end
    )
    |> expect_type(callbacks, path, summary, "review_rows", :list)
    |> validate_rows(
      callbacks,
      path <> ".review_rows",
      Map.get(summary, "review_rows", []),
      fn acc, row_path, row -> validate_contact_allocation_row(acc, callbacks, row_path, row) end
    )
    |> expect_type(callbacks, path, summary, "reduced_capacity_pack_groups", :list)
    |> validate_rows(
      callbacks,
      path <> ".reduced_capacity_pack_groups",
      Map.get(summary, "reduced_capacity_pack_groups", []),
      fn acc, row_path, row ->
        validate_contact_allocation_capacity_pack_group(acc, callbacks, row_path, row)
      end
    )
    |> expect_type(callbacks, path, summary, "assumptions", :map)
    |> validate_assumptions(callbacks, path, summary)
    |> validate_counts(callbacks, path, summary)
  end

  defp validate_field_types(issues, callbacks, path, summary) do
    issues =
      Enum.reduce(count_fields(), issues, fn field, acc ->
        expect_non_negative_integer(acc, callbacks, path, summary, field)
      end)

    issues =
      Enum.reduce(count_map_fields(), issues, fn field, acc ->
        acc
        |> expect_type(callbacks, path, summary, field, :map)
        |> validate_non_negative_integer_count_map(
          callbacks,
          path <> ".#{field}",
          Map.get(summary, field)
        )
      end)

    issues =
      Enum.reduce(number_fields(), issues, fn field, acc ->
        expect_optional_non_negative_number(acc, callbacks, path, summary, field)
      end)

    issues =
      Enum.reduce(number_map_fields(), issues, fn field, acc ->
        acc
        |> expect_type(callbacks, path, summary, field, :map)
        |> validate_non_negative_number_map(
          callbacks,
          path <> ".#{field}",
          Map.get(summary, field)
        )
      end)

    issues =
      Enum.reduce(stable_id_list_fields(), issues, fn field, acc ->
        acc
        |> expect_type(callbacks, path, summary, field, :list)
        |> validate_stable_id_list(callbacks, path <> ".#{field}", Map.get(summary, field))
      end)

    issues =
      Enum.reduce(stable_id_array_map_fields(), issues, fn field, acc ->
        acc
        |> expect_type(callbacks, path, summary, field, :map)
        |> validate_stable_id_array_map(callbacks, path <> ".#{field}", Map.get(summary, field))
      end)

    issues
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "station_pressure_contact_ids_by_direction_and_ground_station_id",
      :map
    )
    |> validate_nested_stable_id_array_map(
      callbacks,
      path <> ".station_pressure_contact_ids_by_direction_and_ground_station_id",
      Map.get(summary, "station_pressure_contact_ids_by_direction_and_ground_station_id")
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "station_pressure_contact_ids_by_status",
      :map
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".station_pressure_contact_ids_by_status",
      Map.get(summary, "station_pressure_contact_ids_by_status")
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "station_pressure_contact_counts_by_status",
      :map
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".station_pressure_contact_counts_by_status",
      Map.get(summary, "station_pressure_contact_counts_by_status")
    )
    |> expect_type(callbacks, path, summary, "station_reservation_expires_at_s", :list)
    |> validate_number_list_items(callbacks, path, summary, "station_reservation_expires_at_s")
    |> expect_optional_number(callbacks, path, summary, "station_reservation_expiration_now_s")
    |> expect_optional_number(
      callbacks,
      path,
      summary,
      "earliest_station_reservation_expires_at_s"
    )
  end

  defp count_fields do
    [
      "input_contact_count",
      "allocated_contact_count",
      "returned_allocated_contact_count",
      "policy_blocked_allocated_contact_count",
      "deferred_contact_count",
      "blocked_contact_count",
      "invalid_contact_input_count",
      "status_blocked_contact_count",
      "resource_blocked_contact_count",
      "duplicate_contact_id_count",
      "reduced_capacity_pack_group_count",
      "station_reservation_active_contact_count",
      "station_reservation_expired_contact_count",
      "station_reservation_missing_expiration_contact_count",
      "station_reservation_declared_expiration_contact_count",
      "review_row_count"
    ]
  end

  defp count_map_fields do
    [
      "reduced_capacity_pack_status_counts",
      "allocation_status_counts",
      "effective_allocation_status_counts",
      "allocation_reason_counts",
      "capacity_pack_status_counts",
      "required_capacity_fraction_source_counts",
      "station_reservation_match_status_counts",
      "station_reservation_status_counts",
      "station_reserved_by_counts",
      "station_reservation_expiration_status_counts",
      "station_calendar_trust_boundary_status_counts",
      "calendar_entry_trust_boundary_status_counts",
      "resource_blocking_dimension_counts",
      "station_pressure_contact_counts_by_ground_station_id",
      "station_pressure_contact_counts_by_availability",
      "station_pressure_contact_counts_by_precedence_availability",
      "station_pressure_contact_counts_by_precedence_rank"
    ]
  end

  defp number_fields do
    [
      "capacity_pack_required_capacity_fraction",
      "capacity_pack_selected_required_capacity_fraction",
      "capacity_pack_deferred_required_capacity_fraction"
    ]
  end

  defp number_map_fields do
    [
      "capacity_pack_required_capacity_fraction_by_status",
      "capacity_pack_required_capacity_fraction_by_ground_station_id",
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id",
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"
    ]
  end

  defp stable_id_list_fields do
    [
      "allocated_contact_ids",
      "returned_allocated_contact_ids",
      "deferred_contact_ids",
      "blocked_contact_ids",
      "policy_blocked_contact_ids",
      "invalid_contact_input_ids",
      "status_blocked_contact_ids",
      "resource_blocked_contact_ids",
      "station_reservation_ids",
      "reduced_capacity_packed_contact_ids",
      "reduced_capacity_deferred_contact_ids",
      "review_contact_ids"
    ]
  end

  defp stable_id_array_map_fields do
    [
      "contact_ids_by_allocation_reason",
      "allocated_contact_ids_by_ground_station_id",
      "returned_allocated_contact_ids_by_ground_station_id",
      "deferred_contact_ids_by_ground_station_id",
      "blocked_contact_ids_by_ground_station_id",
      "policy_blocked_contact_ids_by_ground_station_id",
      "resource_blocked_contact_ids_by_blocking_dimension",
      "resource_blocked_contact_ids_by_spacecraft_id",
      "station_pressure_contact_ids_by_ground_station_id",
      "station_pressure_contact_ids_by_availability",
      "station_pressure_contact_ids_by_precedence_availability",
      "station_pressure_contact_ids_by_precedence_rank",
      "station_reservation_contact_ids_by_match_status",
      "station_reservation_contact_ids_by_status",
      "station_reservation_contact_ids_by_reserved_by",
      "station_reservation_ids_by_match_status",
      "station_reservation_ids_by_status",
      "station_reservation_ids_by_reserved_by",
      "station_reservation_contact_ids_by_expiration_status",
      "station_reservation_ids_by_expiration_status",
      "capacity_pack_contact_ids_by_status",
      "capacity_pack_contact_ids_by_ground_station_id",
      "capacity_pack_selected_contact_ids_by_ground_station_id",
      "capacity_pack_deferred_contact_ids_by_ground_station_id",
      "required_capacity_fraction_contact_ids_by_source"
    ]
  end

  defp validate_assumptions(issues, callbacks, path, summary) do
    case Map.get(summary, "assumptions") do
      %{} = assumptions ->
        issues
        |> expect_equal(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "execution_boundary",
          "artifact_only_no_provider_reservation_or_schedule_mutation"
        )
        |> expect_equal(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "source",
          "contact_allocation_report.v1"
        )
        |> expect_equal(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "operator_authority",
          "not_granted_by_summary"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "row_statuses",
          contact_allocation_row_statuses(callbacks),
          "must match ContactAllocation row statuses"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "effective_row_statuses",
          contact_allocation_effective_row_statuses(callbacks),
          "must match ContactAllocation effective row statuses"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "station_unavailable_aliases",
          contact_allocation_station_unavailable_aliases(callbacks),
          "must match ContactAllocation station unavailable aliases"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "station_blocking_availability",
          contact_allocation_station_blocking_availability(callbacks),
          "must match ContactAllocation station blocking availability"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "station_availability_precedence",
          contact_allocation_station_availability_precedence(callbacks),
          "must match ContactAllocation station availability precedence"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "capacity_pack_statuses",
          contact_allocation_capacity_pack_statuses(callbacks),
          "must match ContactAllocation capacity pack statuses"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "reduced_capacity_pack_statuses",
          contact_allocation_reduced_capacity_pack_statuses(callbacks),
          "must match ContactAllocation reduced capacity pack statuses"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "station_reservation_match_statuses",
          contact_allocation_station_reservation_match_statuses(callbacks),
          "must match ContactAllocation station reservation match statuses"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "station_reservation_expiration_statuses",
          contact_allocation_station_reservation_expiration_statuses(callbacks),
          "must match ContactAllocation station reservation expiration statuses"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "required_capacity_fraction_source_values",
          contact_allocation_required_capacity_fraction_source_values(callbacks),
          "must match ContactAllocation required capacity fraction source values"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "required_capacity_value_paths",
          contact_allocation_required_capacity_value_path_assumptions(callbacks),
          "must match ContactAllocation required capacity value paths"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "default_required_capacity_value_paths",
          contact_allocation_default_required_capacity_value_path_assumptions(callbacks),
          "must match ContactAllocation default required capacity value paths"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "provider_direction_aliases",
          contact_allocation_provider_direction_aliases(callbacks),
          "must match ContactAllocation provider direction aliases"
        )

      _assumptions ->
        issues
    end
  end

  defp validate_counts(issues, callbacks, path, summary) do
    rows =
      summary
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    review_rows = Enum.filter(rows, &contact_allocation_review_row?(callbacks, &1))
    station_pressure_rows = contact_allocation_station_pressure_rows(callbacks, rows)
    resource_blocked_rows = contact_allocation_resource_blocked_rows(callbacks, rows)
    capacity_pack_rows = contact_allocation_capacity_pack_rows(callbacks, rows)

    selected_capacity_pack_rows =
      contact_allocation_selected_capacity_pack_rows(callbacks, capacity_pack_rows)

    deferred_capacity_pack_rows =
      contact_allocation_deferred_capacity_pack_rows(callbacks, capacity_pack_rows)

    pack_groups = summary |> Map.get("reduced_capacity_pack_groups", []) |> Enum.filter(&is_map/1)

    reservation_expiration_rows =
      contact_allocation_reservation_expiration_rows(
        callbacks,
        rows,
        Map.get(summary, "station_reservation_expiration_now_s")
      )

    issues
    |> expect_field_equals(callbacks, path, summary, "input_contact_count", length(rows))
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "allocated_contact_count",
      row_count_by(rows, "allocation_status", "allocated")
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "returned_allocated_contact_count",
      row_count_by(rows, "effective_allocation_status", "allocated")
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "policy_blocked_allocated_contact_count",
      row_count_by(rows, "effective_allocation_status", "policy_blocked")
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "deferred_contact_count",
      row_count_by(rows, "allocation_status", "deferred")
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "blocked_contact_count",
      row_count_by(rows, "allocation_status", "blocked")
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "invalid_contact_input_count",
      length(contact_allocation_invalid_contact_input_ids(callbacks, rows)),
      "must equal row-derived invalid_contact_input_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "status_blocked_contact_count",
      length(contact_allocation_status_blocked_contact_ids(callbacks, rows)),
      "must equal row-derived status_blocked_contact_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "resource_blocked_contact_count",
      length(contact_allocation_row_contact_ids(callbacks, resource_blocked_rows)),
      "must equal row-derived resource_blocked_contact_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "duplicate_contact_id_count",
      duplicate_contact_group_count(rows),
      "must equal row-derived duplicate_contact_id_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "reduced_capacity_pack_group_count",
      length(pack_groups),
      "must equal reduced-capacity-pack-group count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "reduced_capacity_pack_status_counts",
      frequency_map(pack_groups, "pack_status"),
      "must equal reduced-capacity-pack-group-derived reduced_capacity_pack_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "allocation_status_counts",
      frequency_map(rows, "allocation_status"),
      "must equal row-derived allocation_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "effective_allocation_status_counts",
      frequency_map(rows, "effective_allocation_status"),
      "must equal row-derived effective_allocation_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "allocation_reason_counts",
      frequency_map(rows, "allocation_reason"),
      "must equal row-derived allocation_reason_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "contact_ids_by_allocation_reason",
      row_ids_by_field(rows, "allocation_reason", "contact_id"),
      "must equal row-derived contact_ids_by_allocation_reason"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_status_counts",
      frequency_map(rows, "capacity_pack_status"),
      "must equal row-derived capacity_pack_status_counts"
    )
    |> expect_number_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_required_capacity_fraction",
      contact_allocation_capacity_pack_required_fraction(callbacks, capacity_pack_rows),
      "must equal row-derived capacity_pack_required_capacity_fraction"
    )
    |> expect_number_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_selected_required_capacity_fraction",
      contact_allocation_capacity_pack_required_fraction(callbacks, selected_capacity_pack_rows),
      "must equal row-derived capacity_pack_selected_required_capacity_fraction"
    )
    |> expect_number_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_deferred_required_capacity_fraction",
      contact_allocation_capacity_pack_required_fraction(callbacks, deferred_capacity_pack_rows),
      "must equal row-derived capacity_pack_deferred_required_capacity_fraction"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_required_capacity_fraction_by_status",
      contact_allocation_capacity_pack_required_fraction_by_field(
        callbacks,
        capacity_pack_rows,
        "capacity_pack_status"
      ),
      "must equal row-derived capacity_pack_required_capacity_fraction_by_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "required_capacity_fraction_source_counts",
      frequency_map(rows, "required_capacity_fraction_source"),
      "must equal row-derived required_capacity_fraction_source_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_reservation_match_status_counts",
      frequency_map(rows, "station_reservation_match_status"),
      "must equal row-derived station_reservation_match_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_reservation_status_counts",
      frequency_map(rows, "station_reservation_status"),
      "must equal row-derived station_reservation_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_reserved_by_counts",
      frequency_map(rows, "station_reserved_by"),
      "must equal row-derived station_reserved_by_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_reservation_ids",
      row_unique_values(rows, "station_reservation_id"),
      "must equal row-derived station_reservation_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_reservation_expires_at_s",
      contact_allocation_reservation_expires_at_values(callbacks, rows),
      "must equal row-derived station_reservation_expires_at_s"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_reservation_expiration_status_counts",
      frequency_map(reservation_expiration_rows, "station_reservation_expiration_status"),
      "must equal row-derived station_reservation_expiration_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_reservation_active_contact_count",
      contact_allocation_reservation_expiration_count(
        callbacks,
        reservation_expiration_rows,
        "active"
      ),
      "must equal row-derived station_reservation_active_contact_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_reservation_expired_contact_count",
      contact_allocation_reservation_expiration_count(
        callbacks,
        reservation_expiration_rows,
        "expired"
      ),
      "must equal row-derived station_reservation_expired_contact_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_reservation_missing_expiration_contact_count",
      contact_allocation_reservation_expiration_count(
        callbacks,
        reservation_expiration_rows,
        "missing"
      ),
      "must equal row-derived station_reservation_missing_expiration_contact_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_reservation_declared_expiration_contact_count",
      contact_allocation_reservation_expiration_count(
        callbacks,
        reservation_expiration_rows,
        "declared"
      ),
      "must equal row-derived station_reservation_declared_expiration_contact_count"
    )
    |> expect_optional_field_equals(
      callbacks,
      path,
      summary,
      "earliest_station_reservation_expires_at_s",
      contact_allocation_earliest_reservation_expires_at_s(
        callbacks,
        reservation_expiration_rows
      ),
      "must equal row-derived earliest_station_reservation_expires_at_s"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_calendar_trust_boundary_status_counts",
      frequency_map(rows, "station_calendar_trust_boundary_status"),
      "must equal row-derived station_calendar_trust_boundary_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "resource_blocking_dimension_counts",
      frequency_map(resource_blocked_rows, "resource_blocking_dimension"),
      "must equal row-derived resource_blocking_dimension_counts"
    )
    |> validate_id_fields(
      callbacks,
      path,
      summary,
      rows,
      review_rows,
      station_pressure_rows,
      resource_blocked_rows,
      capacity_pack_rows,
      selected_capacity_pack_rows,
      deferred_capacity_pack_rows,
      reservation_expiration_rows
    )
  end

  defp row_count_by(rows, field, value), do: Enum.count(rows, &(Map.get(&1, field) == value))

  defp duplicate_contact_group_count(rows) do
    rows
    |> Enum.filter(&(Map.get(&1, "allocation_reason") == "duplicate_contact_id"))
    |> length()
  end

  defp validate_id_fields(
         issues,
         callbacks,
         path,
         summary,
         rows,
         review_rows,
         station_pressure_rows,
         resource_blocked_rows,
         capacity_pack_rows,
         selected_capacity_pack_rows,
         deferred_capacity_pack_rows,
         reservation_expiration_rows
       ) do
    issues
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "allocated_contact_ids",
      row_ids_by_field_value(rows, "allocation_status", "allocated", "contact_id"),
      "must equal row-derived allocated_contact_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "allocated_contact_ids_by_ground_station_id",
      row_ids_by_field(
        Enum.filter(rows, &(Map.get(&1, "allocation_status") == "allocated")),
        "ground_station_id",
        "contact_id"
      ),
      "must equal row-derived allocated_contact_ids_by_ground_station_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "returned_allocated_contact_ids",
      row_ids_by_field_value(rows, "effective_allocation_status", "allocated", "contact_id"),
      "must equal row-derived returned_allocated_contact_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "returned_allocated_contact_ids_by_ground_station_id",
      row_ids_by_field(
        Enum.filter(rows, &(Map.get(&1, "effective_allocation_status") == "allocated")),
        "ground_station_id",
        "contact_id"
      ),
      "must equal row-derived returned_allocated_contact_ids_by_ground_station_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "deferred_contact_ids",
      row_ids_by_field_value(rows, "allocation_status", "deferred", "contact_id"),
      "must equal row-derived deferred_contact_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "deferred_contact_ids_by_ground_station_id",
      row_ids_by_field(
        Enum.filter(rows, &(Map.get(&1, "allocation_status") == "deferred")),
        "ground_station_id",
        "contact_id"
      ),
      "must equal row-derived deferred_contact_ids_by_ground_station_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "blocked_contact_ids",
      row_ids_by_field_value(rows, "allocation_status", "blocked", "contact_id"),
      "must equal row-derived blocked_contact_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "blocked_contact_ids_by_ground_station_id",
      row_ids_by_field(
        Enum.filter(rows, &(Map.get(&1, "allocation_status") == "blocked")),
        "ground_station_id",
        "contact_id"
      ),
      "must equal row-derived blocked_contact_ids_by_ground_station_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "policy_blocked_contact_ids",
      row_ids_by_field_value(rows, "effective_allocation_status", "policy_blocked", "contact_id"),
      "must equal row-derived policy_blocked_contact_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "policy_blocked_contact_ids_by_ground_station_id",
      row_ids_by_field(
        Enum.filter(rows, &(Map.get(&1, "effective_allocation_status") == "policy_blocked")),
        "ground_station_id",
        "contact_id"
      ),
      "must equal row-derived policy_blocked_contact_ids_by_ground_station_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "invalid_contact_input_ids",
      contact_allocation_invalid_contact_input_ids(callbacks, rows),
      "must equal row-derived invalid_contact_input_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "status_blocked_contact_ids",
      contact_allocation_status_blocked_contact_ids(callbacks, rows),
      "must equal row-derived status_blocked_contact_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "resource_blocked_contact_ids",
      contact_allocation_row_contact_ids(callbacks, resource_blocked_rows),
      "must equal row-derived resource_blocked_contact_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "resource_blocked_contact_ids_by_blocking_dimension",
      row_ids_by_field(resource_blocked_rows, "resource_blocking_dimension", "contact_id"),
      "must equal row-derived resource_blocked_contact_ids_by_blocking_dimension"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "resource_blocked_contact_ids_by_spacecraft_id",
      row_ids_by_field(resource_blocked_rows, "spacecraft_id", "contact_id"),
      "must equal row-derived resource_blocked_contact_ids_by_spacecraft_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_pressure_contact_ids_by_ground_station_id",
      row_ids_by_field(station_pressure_rows, "ground_station_id", "contact_id"),
      "must equal row-derived station_pressure_contact_ids_by_ground_station_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_pressure_contact_counts_by_ground_station_id",
      station_pressure_rows
      |> row_ids_by_field("ground_station_id", "contact_id")
      |> id_array_count_map(),
      "must equal row-derived station_pressure_contact_counts_by_ground_station_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_pressure_contact_ids_by_availability",
      contact_allocation_station_pressure_ids_by_availability(callbacks, station_pressure_rows),
      "must equal row-derived station_pressure_contact_ids_by_availability"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_pressure_contact_counts_by_availability",
      callbacks
      |> contact_allocation_station_pressure_ids_by_availability(station_pressure_rows)
      |> id_array_count_map(),
      "must equal row-derived station_pressure_contact_counts_by_availability"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_pressure_contact_ids_by_precedence_availability",
      row_ids_by_field(
        station_pressure_rows,
        "station_calendar_precedence_availability",
        "contact_id"
      ),
      "must equal row-derived station_pressure_contact_ids_by_precedence_availability"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_pressure_contact_counts_by_precedence_availability",
      station_pressure_rows
      |> row_ids_by_field("station_calendar_precedence_availability", "contact_id")
      |> id_array_count_map(),
      "must equal row-derived station_pressure_contact_counts_by_precedence_availability"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_pressure_contact_ids_by_precedence_rank",
      row_ids_by_string_field(
        station_pressure_rows,
        "station_calendar_precedence_rank",
        "contact_id"
      ),
      "must equal row-derived station_pressure_contact_ids_by_precedence_rank"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_pressure_contact_counts_by_precedence_rank",
      station_pressure_rows
      |> row_ids_by_string_field("station_calendar_precedence_rank", "contact_id")
      |> id_array_count_map(),
      "must equal row-derived station_pressure_contact_counts_by_precedence_rank"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_pressure_contact_ids_by_status",
      row_ids_by_field(station_pressure_rows, "station_calendar_status", "contact_id"),
      "must equal row-derived station_pressure_contact_ids_by_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_pressure_contact_counts_by_status",
      station_pressure_rows
      |> row_ids_by_field("station_calendar_status", "contact_id")
      |> id_array_count_map(),
      "must equal row-derived station_pressure_contact_counts_by_status"
    )
    |> expect_optional_field_equals(
      callbacks,
      path,
      summary,
      "station_pressure_contact_ids_by_direction_and_ground_station_id",
      row_ids_by_direction_and_ground_station(station_pressure_rows, "contact_id"),
      "must equal row-derived station_pressure_contact_ids_by_direction_and_ground_station_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_reservation_contact_ids_by_match_status",
      row_ids_by_field(rows, "station_reservation_match_status", "contact_id"),
      "must equal row-derived station_reservation_contact_ids_by_match_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_reservation_contact_ids_by_status",
      row_ids_by_field(rows, "station_reservation_status", "contact_id"),
      "must equal row-derived station_reservation_contact_ids_by_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_reservation_contact_ids_by_reserved_by",
      row_ids_by_field(rows, "station_reserved_by", "contact_id"),
      "must equal row-derived station_reservation_contact_ids_by_reserved_by"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_reservation_ids_by_match_status",
      row_ids_by_field(rows, "station_reservation_match_status", "station_reservation_id"),
      "must equal row-derived station_reservation_ids_by_match_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_reservation_ids_by_status",
      row_ids_by_field(rows, "station_reservation_status", "station_reservation_id"),
      "must equal row-derived station_reservation_ids_by_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_reservation_ids_by_reserved_by",
      row_ids_by_field(rows, "station_reserved_by", "station_reservation_id"),
      "must equal row-derived station_reservation_ids_by_reserved_by"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_reservation_contact_ids_by_expiration_status",
      row_ids_by_field(
        reservation_expiration_rows,
        "station_reservation_expiration_status",
        "contact_id"
      ),
      "must equal row-derived station_reservation_contact_ids_by_expiration_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_reservation_ids_by_expiration_status",
      contact_allocation_reservation_ids_by_expiration_status(
        callbacks,
        reservation_expiration_rows
      ),
      "must equal row-derived station_reservation_ids_by_expiration_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_contact_ids_by_status",
      row_ids_by_field(rows, "capacity_pack_status", "contact_id"),
      "must equal row-derived capacity_pack_contact_ids_by_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_contact_ids_by_ground_station_id",
      row_ids_by_field(capacity_pack_rows, "ground_station_id", "contact_id"),
      "must equal row-derived capacity_pack_contact_ids_by_ground_station_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_selected_contact_ids_by_ground_station_id",
      row_ids_by_field(selected_capacity_pack_rows, "ground_station_id", "contact_id"),
      "must equal row-derived capacity_pack_selected_contact_ids_by_ground_station_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_deferred_contact_ids_by_ground_station_id",
      row_ids_by_field(deferred_capacity_pack_rows, "ground_station_id", "contact_id"),
      "must equal row-derived capacity_pack_deferred_contact_ids_by_ground_station_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_required_capacity_fraction_by_ground_station_id",
      contact_allocation_capacity_pack_required_fraction_by_field(
        callbacks,
        capacity_pack_rows,
        "ground_station_id"
      ),
      "must equal row-derived capacity_pack_required_capacity_fraction_by_ground_station_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id",
      contact_allocation_capacity_pack_required_fraction_by_field(
        callbacks,
        selected_capacity_pack_rows,
        "ground_station_id"
      ),
      "must equal row-derived capacity_pack_selected_required_capacity_fraction_by_ground_station_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id",
      contact_allocation_capacity_pack_required_fraction_by_field(
        callbacks,
        deferred_capacity_pack_rows,
        "ground_station_id"
      ),
      "must equal row-derived capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "required_capacity_fraction_contact_ids_by_source",
      row_ids_by_field(rows, "required_capacity_fraction_source", "contact_id"),
      "must equal row-derived required_capacity_fraction_contact_ids_by_source"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "reduced_capacity_packed_contact_ids",
      row_ids_by_field_value(
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
      summary,
      "reduced_capacity_deferred_contact_ids",
      row_ids_by_field_value(
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
      summary,
      "review_contact_ids",
      contact_allocation_row_contact_ids(callbacks, review_rows),
      "must equal row-derived review_contact_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_row_count",
      length(review_rows),
      "must equal row-derived review_row_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_rows",
      review_rows,
      "must equal row-derived review_rows"
    )
  end

  defp row_unique_values(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp row_ids_by_field(rows, group_field, id_field) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.group_by(&Map.get(&1, group_field), &Map.get(&1, id_field))
    |> Enum.reject(fn {group, ids} -> is_nil(group) or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {group, ids} ->
      {group, ids |> Enum.reject(&is_nil/1) |> Enum.uniq() |> Enum.sort()}
    end)
  end

  defp row_ids_by_field_value(rows, field, value, id_field) do
    rows
    |> Enum.filter(&(is_map(&1) and Map.get(&1, field) == value))
    |> Enum.map(&Map.get(&1, id_field))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp row_ids_by_string_field(rows, group_field, id_field) do
    rows
    |> row_ids_by_field(group_field, id_field)
    |> Map.new(fn {group, ids} -> {to_string(group), ids} end)
  end

  defp row_ids_by_direction_and_ground_station(rows, id_field) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.reduce(%{}, fn row, acc ->
      direction = Map.get(row, "direction")
      ground_station_id = Map.get(row, "ground_station_id")
      id = Map.get(row, id_field)

      if direction in [nil, ""] or ground_station_id in [nil, ""] or id in [nil, ""] do
        acc
      else
        Map.update(acc, direction, %{ground_station_id => [id]}, fn station_map ->
          Map.update(station_map, ground_station_id, [id], fn ids -> [id | ids] end)
        end)
      end
    end)
    |> Map.new(fn {direction, station_map} ->
      {direction,
       Map.new(station_map, fn {ground_station_id, ids} ->
         {ground_station_id, ids |> Enum.uniq() |> Enum.sort()}
       end)}
    end)
  end

  defp id_array_count_map(id_arrays) when is_map(id_arrays) do
    Map.new(id_arrays, fn {group, ids} ->
      {group, length(Enum.filter(ids, &is_binary/1))}
    end)
  end

  defp frequency_map(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> Map.new()
  end

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(Keyword.fetch!(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_non_negative_integer(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_non_negative_integer), [issues, path, map, field])

  defp expect_optional_non_negative_number(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :expect_optional_non_negative_number), [
      issues,
      path,
      map,
      field
    ])
  end

  defp expect_optional_number(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_number), [issues, path, map, field])

  defp expect_field_equals(issues, callbacks, path, map, field, expected),
    do:
      apply(Keyword.fetch!(callbacks, :expect_field_equals), [issues, path, map, field, expected])

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message) do
    apply(Keyword.fetch!(callbacks, :expect_field_equals_with_message), [
      issues,
      path,
      map,
      field,
      expected,
      message
    ])
  end

  defp expect_optional_field_equals(issues, callbacks, path, map, field, expected, message) do
    apply(Keyword.fetch!(callbacks, :expect_optional_field_equals), [
      issues,
      path,
      map,
      field,
      expected,
      message
    ])
  end

  defp expect_number_field_equals(issues, callbacks, path, map, field, expected, message) do
    apply(Keyword.fetch!(callbacks, :expect_number_field_equals), [
      issues,
      path,
      map,
      field,
      expected,
      message
    ])
  end

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(Keyword.fetch!(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_optional_exact_model_limits(issues, callbacks, path, artifact, expected, message) do
    apply(Keyword.fetch!(callbacks, :validate_optional_exact_model_limits), [
      issues,
      path,
      artifact,
      expected,
      message
    ])
  end

  defp validate_non_negative_integer_count_map(issues, callbacks, path, counts) do
    apply(Keyword.fetch!(callbacks, :validate_non_negative_integer_count_map), [
      issues,
      path,
      counts
    ])
  end

  defp validate_non_negative_number_map(issues, callbacks, path, values),
    do:
      apply(Keyword.fetch!(callbacks, :validate_non_negative_number_map), [issues, path, values])

  defp validate_stable_id_list(issues, callbacks, path, values),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_list), [issues, path, values])

  defp validate_stable_id_array_map(issues, callbacks, path, values),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_array_map), [issues, path, values])

  defp validate_nested_stable_id_array_map(issues, callbacks, path, values) do
    apply(Keyword.fetch!(callbacks, :validate_nested_stable_id_array_map), [
      issues,
      path,
      values
    ])
  end

  defp validate_number_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_number_list_items), [issues, path, map, field])

  defp contact_allocation_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_model_limits), [])

  defp contact_allocation_capacity_pack_statuses(callbacks),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_capacity_pack_statuses), [])

  defp contact_allocation_reduced_capacity_pack_statuses(callbacks),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_reduced_capacity_pack_statuses), [])

  defp contact_allocation_station_reservation_match_statuses(callbacks),
    do:
      apply(Keyword.fetch!(callbacks, :contact_allocation_station_reservation_match_statuses), [])

  defp contact_allocation_station_reservation_expiration_statuses(callbacks) do
    apply(
      Keyword.fetch!(callbacks, :contact_allocation_station_reservation_expiration_statuses),
      []
    )
  end

  defp contact_allocation_row_statuses(callbacks),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_row_statuses), [])

  defp contact_allocation_effective_row_statuses(callbacks),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_effective_row_statuses), [])

  defp contact_allocation_station_unavailable_aliases(callbacks),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_station_unavailable_aliases), [])

  defp contact_allocation_station_blocking_availability(callbacks),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_station_blocking_availability), [])

  defp contact_allocation_station_availability_precedence(callbacks),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_station_availability_precedence), [])

  defp contact_allocation_provider_direction_aliases(callbacks),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_provider_direction_aliases), [])

  defp contact_allocation_required_capacity_fraction_source_values(callbacks) do
    apply(
      Keyword.fetch!(callbacks, :contact_allocation_required_capacity_fraction_source_values),
      []
    )
  end

  defp contact_allocation_required_capacity_value_path_assumptions(callbacks) do
    apply(
      Keyword.fetch!(callbacks, :contact_allocation_required_capacity_value_path_assumptions),
      []
    )
  end

  defp contact_allocation_default_required_capacity_value_path_assumptions(callbacks) do
    apply(
      Keyword.fetch!(
        callbacks,
        :contact_allocation_default_required_capacity_value_path_assumptions
      ),
      []
    )
  end

  defp validate_contact_allocation_row(issues, callbacks, path, row),
    do: apply(Keyword.fetch!(callbacks, :validate_contact_allocation_row), [issues, path, row])

  defp validate_contact_allocation_capacity_pack_group(issues, callbacks, path, group) do
    apply(Keyword.fetch!(callbacks, :validate_contact_allocation_capacity_pack_group), [
      issues,
      path,
      group
    ])
  end

  defp contact_allocation_review_row?(callbacks, row),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_review_row?), [row])

  defp contact_allocation_station_pressure_rows(callbacks, rows),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_station_pressure_rows), [rows])

  defp contact_allocation_resource_blocked_rows(callbacks, rows),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_resource_blocked_rows), [rows])

  defp contact_allocation_capacity_pack_rows(callbacks, rows),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_capacity_pack_rows), [rows])

  defp contact_allocation_selected_capacity_pack_rows(callbacks, rows),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_selected_capacity_pack_rows), [rows])

  defp contact_allocation_deferred_capacity_pack_rows(callbacks, rows),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_deferred_capacity_pack_rows), [rows])

  defp contact_allocation_reservation_expiration_rows(callbacks, rows, now_s) do
    apply(Keyword.fetch!(callbacks, :contact_allocation_reservation_expiration_rows), [
      rows,
      now_s
    ])
  end

  defp contact_allocation_invalid_contact_input_ids(callbacks, rows),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_invalid_contact_input_ids), [rows])

  defp contact_allocation_status_blocked_contact_ids(callbacks, rows),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_status_blocked_contact_ids), [rows])

  defp contact_allocation_row_contact_ids(callbacks, rows),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_row_contact_ids), [rows])

  defp contact_allocation_capacity_pack_required_fraction(callbacks, rows) do
    apply(Keyword.fetch!(callbacks, :contact_allocation_capacity_pack_required_fraction), [rows])
  end

  defp contact_allocation_capacity_pack_required_fraction_by_field(callbacks, rows, field) do
    apply(
      Keyword.fetch!(callbacks, :contact_allocation_capacity_pack_required_fraction_by_field),
      [
        rows,
        field
      ]
    )
  end

  defp contact_allocation_reservation_expires_at_values(callbacks, rows),
    do:
      apply(Keyword.fetch!(callbacks, :contact_allocation_reservation_expires_at_values), [rows])

  defp contact_allocation_reservation_expiration_count(callbacks, rows, status) do
    apply(Keyword.fetch!(callbacks, :contact_allocation_reservation_expiration_count), [
      rows,
      status
    ])
  end

  defp contact_allocation_earliest_reservation_expires_at_s(callbacks, rows) do
    apply(Keyword.fetch!(callbacks, :contact_allocation_earliest_reservation_expires_at_s), [rows])
  end

  defp contact_allocation_station_pressure_ids_by_availability(callbacks, rows) do
    apply(Keyword.fetch!(callbacks, :contact_allocation_station_pressure_ids_by_availability), [
      rows
    ])
  end

  defp contact_allocation_reservation_ids_by_expiration_status(callbacks, rows) do
    apply(Keyword.fetch!(callbacks, :contact_allocation_reservation_ids_by_expiration_status), [
      rows
    ])
  end
end
