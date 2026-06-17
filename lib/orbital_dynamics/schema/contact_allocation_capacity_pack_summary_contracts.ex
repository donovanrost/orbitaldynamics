defmodule OrbitalDynamics.Schema.ContactAllocationCapacityPackSummaryContracts do
  @moduledoc false

  def validate_summary(issues, path, summary, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(
      callbacks,
      path,
      summary,
      "schema_contract",
      "contact_allocation_capacity_pack_summary.v1"
    )
    |> expect_equal(
      callbacks,
      path,
      summary,
      "model",
      "artifact_only_contact_allocation_capacity_pack_summary"
    )
    |> expect_optional_type(callbacks, path, summary, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      summary,
      contact_allocation_model_limits(callbacks),
      "must match contact allocation model limits"
    )
    |> expect_one_of(callbacks, path, summary, "source_artifact_type", [
      "contact_allocation_report.v1"
    ])
    |> expect_optional_type(callbacks, path, summary, "source", :binary)
    |> expect_non_negative_integer(callbacks, path, summary, "input_contact_count")
    |> expect_non_negative_integer(callbacks, path, summary, "capacity_pack_contact_count")
    |> expect_one_of(callbacks, path, summary, "capacity_pack_review_status", [
      "clear",
      "review_required"
    ])
    |> expect_non_negative_integer(callbacks, path, summary, "reduced_capacity_pack_group_count")
    |> validate_field_types(callbacks, path, summary)
    |> expect_type(callbacks, path, summary, "rows", :list)
    |> validate_rows(
      callbacks,
      path <> ".rows",
      Map.get(summary, "rows", []),
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
    |> expect_type(callbacks, path, summary, "review_rows", :list)
    |> validate_rows(
      callbacks,
      path <> ".review_rows",
      Map.get(summary, "review_rows", []),
      fn acc, row_path, row -> validate_contact_allocation_row(acc, callbacks, row_path, row) end
    )
    |> expect_type(callbacks, path, summary, "assumptions", :map)
    |> validate_assumptions(callbacks, path, summary)
    |> validate_counts(callbacks, path, summary)
  end

  defp validate_field_types(issues, callbacks, path, summary) do
    issues
    |> expect_type(callbacks, path, summary, "reduced_capacity_pack_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".reduced_capacity_pack_status_counts",
      Map.get(summary, "reduced_capacity_pack_status_counts")
    )
    |> expect_type(callbacks, path, summary, "capacity_pack_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".capacity_pack_status_counts",
      Map.get(summary, "capacity_pack_status_counts")
    )
    |> expect_type(callbacks, path, summary, "capacity_pack_contact_ids_by_status", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".capacity_pack_contact_ids_by_status",
      Map.get(summary, "capacity_pack_contact_ids_by_status")
    )
    |> expect_type(
      callbacks,
      path,
      summary,
      "capacity_pack_contact_ids_by_ground_station_id",
      :map
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".capacity_pack_contact_ids_by_ground_station_id",
      Map.get(summary, "capacity_pack_contact_ids_by_ground_station_id")
    )
    |> expect_type(
      callbacks,
      path,
      summary,
      "capacity_pack_selected_contact_ids_by_ground_station_id",
      :map
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".capacity_pack_selected_contact_ids_by_ground_station_id",
      Map.get(summary, "capacity_pack_selected_contact_ids_by_ground_station_id")
    )
    |> expect_type(
      callbacks,
      path,
      summary,
      "capacity_pack_deferred_contact_ids_by_ground_station_id",
      :map
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".capacity_pack_deferred_contact_ids_by_ground_station_id",
      Map.get(summary, "capacity_pack_deferred_contact_ids_by_ground_station_id")
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      summary,
      "capacity_pack_contact_ids_by_direction"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      summary,
      "capacity_pack_selected_contact_ids_by_direction"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      summary,
      "capacity_pack_deferred_contact_ids_by_direction"
    )
    |> expect_optional_non_negative_number(
      callbacks,
      path,
      summary,
      "capacity_pack_required_capacity_fraction"
    )
    |> expect_optional_non_negative_number(
      callbacks,
      path,
      summary,
      "capacity_pack_selected_required_capacity_fraction"
    )
    |> expect_optional_non_negative_number(
      callbacks,
      path,
      summary,
      "capacity_pack_deferred_required_capacity_fraction"
    )
    |> expect_type(
      callbacks,
      path,
      summary,
      "capacity_pack_required_capacity_fraction_by_status",
      :map
    )
    |> validate_non_negative_number_map(
      callbacks,
      path <> ".capacity_pack_required_capacity_fraction_by_status",
      Map.get(summary, "capacity_pack_required_capacity_fraction_by_status")
    )
    |> expect_type(
      callbacks,
      path,
      summary,
      "capacity_pack_required_capacity_fraction_by_ground_station_id",
      :map
    )
    |> validate_non_negative_number_map(
      callbacks,
      path <> ".capacity_pack_required_capacity_fraction_by_ground_station_id",
      Map.get(summary, "capacity_pack_required_capacity_fraction_by_ground_station_id")
    )
    |> expect_type(
      callbacks,
      path,
      summary,
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id",
      :map
    )
    |> validate_non_negative_number_map(
      callbacks,
      path <> ".capacity_pack_selected_required_capacity_fraction_by_ground_station_id",
      Map.get(summary, "capacity_pack_selected_required_capacity_fraction_by_ground_station_id")
    )
    |> expect_type(
      callbacks,
      path,
      summary,
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id",
      :map
    )
    |> validate_non_negative_number_map(
      callbacks,
      path <> ".capacity_pack_deferred_required_capacity_fraction_by_ground_station_id",
      Map.get(summary, "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id")
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "capacity_pack_required_capacity_fraction_by_direction",
      :map
    )
    |> validate_non_negative_number_map(
      callbacks,
      path <> ".capacity_pack_required_capacity_fraction_by_direction",
      Map.get(summary, "capacity_pack_required_capacity_fraction_by_direction")
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "capacity_pack_selected_required_capacity_fraction_by_direction",
      :map
    )
    |> validate_non_negative_number_map(
      callbacks,
      path <> ".capacity_pack_selected_required_capacity_fraction_by_direction",
      Map.get(summary, "capacity_pack_selected_required_capacity_fraction_by_direction")
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "capacity_pack_deferred_required_capacity_fraction_by_direction",
      :map
    )
    |> validate_non_negative_number_map(
      callbacks,
      path <> ".capacity_pack_deferred_required_capacity_fraction_by_direction",
      Map.get(summary, "capacity_pack_deferred_required_capacity_fraction_by_direction")
    )
    |> expect_type(callbacks, path, summary, "required_capacity_fraction_source_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".required_capacity_fraction_source_counts",
      Map.get(summary, "required_capacity_fraction_source_counts")
    )
    |> expect_type(
      callbacks,
      path,
      summary,
      "required_capacity_fraction_contact_ids_by_source",
      :map
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".required_capacity_fraction_contact_ids_by_source",
      Map.get(summary, "required_capacity_fraction_contact_ids_by_source")
    )
    |> expect_type(callbacks, path, summary, "reduced_capacity_packed_contact_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".reduced_capacity_packed_contact_ids",
      Map.get(summary, "reduced_capacity_packed_contact_ids")
    )
    |> expect_type(callbacks, path, summary, "reduced_capacity_deferred_contact_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".reduced_capacity_deferred_contact_ids",
      Map.get(summary, "reduced_capacity_deferred_contact_ids")
    )
    |> expect_type(callbacks, path, summary, "capacity_pack_group_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".capacity_pack_group_ids",
      Map.get(summary, "capacity_pack_group_ids")
    )
    |> expect_type(callbacks, path, summary, "capacity_pack_group_ids_by_status", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".capacity_pack_group_ids_by_status",
      Map.get(summary, "capacity_pack_group_ids_by_status")
    )
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
          "not_granted_by_capacity_pack_summary"
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
          "required_capacity_fraction_source_values",
          contact_allocation_required_capacity_fraction_source_values(callbacks),
          "must match ContactAllocation required capacity source values"
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

      _assumptions ->
        issues
    end
  end

  defp validate_counts(issues, callbacks, path, summary) do
    rows =
      summary
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    capacity_pack_rows = contact_allocation_capacity_pack_rows(callbacks, rows)

    selected_capacity_pack_rows =
      contact_allocation_selected_capacity_pack_rows(callbacks, capacity_pack_rows)

    deferred_capacity_pack_rows =
      contact_allocation_deferred_capacity_pack_rows(callbacks, capacity_pack_rows)

    pack_groups =
      summary
      |> Map.get("reduced_capacity_pack_groups", [])
      |> Enum.filter(&is_map/1)

    issues
    |> expect_field_equals(callbacks, path, summary, "input_contact_count", length(rows))
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_contact_count",
      length(capacity_pack_rows),
      "must equal row-derived capacity_pack_contact_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_review_status",
      if(capacity_pack_rows == [] and pack_groups == [], do: "clear", else: "review_required")
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
      "capacity_pack_status_counts",
      frequency_map(capacity_pack_rows, "capacity_pack_status"),
      "must equal row-derived capacity_pack_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_contact_ids_by_status",
      row_ids_by_field(capacity_pack_rows, "capacity_pack_status", "contact_id"),
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
    |> expect_optional_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_contact_ids_by_direction",
      row_ids_by_field(capacity_pack_rows, "direction", "contact_id"),
      "must equal row-derived capacity_pack_contact_ids_by_direction"
    )
    |> expect_optional_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_selected_contact_ids_by_direction",
      row_ids_by_field(selected_capacity_pack_rows, "direction", "contact_id"),
      "must equal row-derived capacity_pack_selected_contact_ids_by_direction"
    )
    |> expect_optional_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_deferred_contact_ids_by_direction",
      row_ids_by_field(deferred_capacity_pack_rows, "direction", "contact_id"),
      "must equal row-derived capacity_pack_deferred_contact_ids_by_direction"
    )
    |> validate_fraction_totals(
      callbacks,
      path,
      summary,
      capacity_pack_rows,
      selected_capacity_pack_rows,
      deferred_capacity_pack_rows
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "required_capacity_fraction_source_counts",
      frequency_map(capacity_pack_rows, "required_capacity_fraction_source"),
      "must equal row-derived required_capacity_fraction_source_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "required_capacity_fraction_contact_ids_by_source",
      row_ids_by_field(capacity_pack_rows, "required_capacity_fraction_source", "contact_id"),
      "must equal row-derived required_capacity_fraction_contact_ids_by_source"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "reduced_capacity_packed_contact_ids",
      row_ids_by_field_value(
        capacity_pack_rows,
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
        capacity_pack_rows,
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
      "capacity_pack_group_ids",
      row_unique_values(pack_groups, "contention_group_id"),
      "must equal reduced-capacity-pack-group-derived capacity_pack_group_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_group_ids_by_status",
      row_ids_by_field(pack_groups, "pack_status", "contention_group_id"),
      "must equal reduced-capacity-pack-group-derived capacity_pack_group_ids_by_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_rows",
      capacity_pack_rows,
      "must equal row-derived review_rows"
    )
  end

  defp validate_fraction_totals(
         issues,
         callbacks,
         path,
         summary,
         capacity_pack_rows,
         selected_capacity_pack_rows,
         deferred_capacity_pack_rows
       ) do
    issues
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
    |> expect_optional_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_required_capacity_fraction_by_direction",
      contact_allocation_capacity_pack_required_fraction_by_field(
        callbacks,
        capacity_pack_rows,
        "direction"
      ),
      "must equal row-derived capacity_pack_required_capacity_fraction_by_direction"
    )
    |> expect_optional_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_selected_required_capacity_fraction_by_direction",
      contact_allocation_capacity_pack_required_fraction_by_field(
        callbacks,
        selected_capacity_pack_rows,
        "direction"
      ),
      "must equal row-derived capacity_pack_selected_required_capacity_fraction_by_direction"
    )
    |> expect_optional_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_deferred_required_capacity_fraction_by_direction",
      contact_allocation_capacity_pack_required_fraction_by_field(
        callbacks,
        deferred_capacity_pack_rows,
        "direction"
      ),
      "must equal row-derived capacity_pack_deferred_required_capacity_fraction_by_direction"
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

  defp validate_stable_id_array_map(issues, callbacks, path, values),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_array_map), [issues, path, values])

  defp validate_stable_id_list(issues, callbacks, path, values),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_list), [issues, path, values])

  defp validate_optional_stable_id_array_map(issues, callbacks, path, map, field) do
    issues
    |> expect_optional_type(callbacks, path, map, field, :map)
    |> validate_stable_id_array_map(callbacks, path <> ".#{field}", Map.get(map, field))
  end

  defp contact_allocation_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_model_limits), [])

  defp contact_allocation_capacity_pack_statuses(callbacks),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_capacity_pack_statuses), [])

  defp contact_allocation_reduced_capacity_pack_statuses(callbacks),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_reduced_capacity_pack_statuses), [])

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

  defp contact_allocation_capacity_pack_rows(callbacks, rows),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_capacity_pack_rows), [rows])

  defp contact_allocation_selected_capacity_pack_rows(callbacks, rows),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_selected_capacity_pack_rows), [rows])

  defp contact_allocation_deferred_capacity_pack_rows(callbacks, rows),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_deferred_capacity_pack_rows), [rows])

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
end
