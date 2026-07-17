defmodule OrbitalDynamics.Schema.ContactAllocationCapacityPackSummaryContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.ContactAllocationReportContracts

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_number_field_equals: 6,
      expect_one_of: 5,
      expect_optional_field_equals: 6,
      expect_optional_non_negative_number: 4,
      expect_optional_type: 5,
      expect_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_non_negative_number_map: 3,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_stable_id_array_map: 3, validate_stable_id_list: 3]

  def validate_summary(issues, path, summary, row_validator, group_validator)
      when is_function(row_validator, 3) and is_function(group_validator, 3) do
    issues
    |> expect_equal(
      path,
      summary,
      "schema_contract",
      "contact_allocation_capacity_pack_summary.v1"
    )
    |> expect_equal(
      path,
      summary,
      "model",
      "artifact_only_contact_allocation_capacity_pack_summary"
    )
    |> expect_optional_type(path, summary, "model_limits", :list)
    |> validate_string_list_items(path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      summary,
      contact_allocation_model_limits(),
      "must match contact allocation model limits"
    )
    |> expect_one_of(path, summary, "source_artifact_type", [
      "contact_allocation_report.v1"
    ])
    |> expect_optional_type(path, summary, "source", :binary)
    |> expect_non_negative_integer(path, summary, "input_contact_count")
    |> expect_non_negative_integer(path, summary, "capacity_pack_contact_count")
    |> expect_one_of(path, summary, "capacity_pack_review_status", [
      "clear",
      "review_required"
    ])
    |> expect_non_negative_integer(path, summary, "reduced_capacity_pack_group_count")
    |> validate_field_types(path, summary)
    |> expect_type(path, summary, "rows", :list)
    |> validate_rows(
      path <> ".rows",
      Map.get(summary, "rows", []),
      row_validator
    )
    |> expect_type(path, summary, "reduced_capacity_pack_groups", :list)
    |> validate_rows(
      path <> ".reduced_capacity_pack_groups",
      Map.get(summary, "reduced_capacity_pack_groups", []),
      group_validator
    )
    |> expect_type(path, summary, "review_rows", :list)
    |> validate_rows(
      path <> ".review_rows",
      Map.get(summary, "review_rows", []),
      row_validator
    )
    |> expect_type(path, summary, "assumptions", :map)
    |> validate_assumptions(path, summary)
    |> validate_counts(path, summary)
  end

  defp validate_field_types(issues, path, summary) do
    issues
    |> expect_type(path, summary, "reduced_capacity_pack_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".reduced_capacity_pack_status_counts",
      Map.get(summary, "reduced_capacity_pack_status_counts")
    )
    |> expect_type(path, summary, "capacity_pack_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".capacity_pack_status_counts",
      Map.get(summary, "capacity_pack_status_counts")
    )
    |> expect_type(path, summary, "capacity_pack_contact_ids_by_status", :map)
    |> validate_stable_id_array_map(
      path <> ".capacity_pack_contact_ids_by_status",
      Map.get(summary, "capacity_pack_contact_ids_by_status")
    )
    |> expect_type(
      path,
      summary,
      "capacity_pack_contact_ids_by_ground_station_id",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".capacity_pack_contact_ids_by_ground_station_id",
      Map.get(summary, "capacity_pack_contact_ids_by_ground_station_id")
    )
    |> expect_type(
      path,
      summary,
      "capacity_pack_selected_contact_ids_by_ground_station_id",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".capacity_pack_selected_contact_ids_by_ground_station_id",
      Map.get(summary, "capacity_pack_selected_contact_ids_by_ground_station_id")
    )
    |> expect_type(
      path,
      summary,
      "capacity_pack_deferred_contact_ids_by_ground_station_id",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".capacity_pack_deferred_contact_ids_by_ground_station_id",
      Map.get(summary, "capacity_pack_deferred_contact_ids_by_ground_station_id")
    )
    |> validate_optional_stable_id_array_map(
      path,
      summary,
      "capacity_pack_contact_ids_by_direction"
    )
    |> validate_optional_stable_id_array_map(
      path,
      summary,
      "capacity_pack_selected_contact_ids_by_direction"
    )
    |> validate_optional_stable_id_array_map(
      path,
      summary,
      "capacity_pack_deferred_contact_ids_by_direction"
    )
    |> expect_optional_non_negative_number(
      path,
      summary,
      "capacity_pack_required_capacity_fraction"
    )
    |> expect_optional_non_negative_number(
      path,
      summary,
      "capacity_pack_selected_required_capacity_fraction"
    )
    |> expect_optional_non_negative_number(
      path,
      summary,
      "capacity_pack_deferred_required_capacity_fraction"
    )
    |> expect_type(
      path,
      summary,
      "capacity_pack_required_capacity_fraction_by_status",
      :map
    )
    |> validate_non_negative_number_map(
      path <> ".capacity_pack_required_capacity_fraction_by_status",
      Map.get(summary, "capacity_pack_required_capacity_fraction_by_status")
    )
    |> expect_type(
      path,
      summary,
      "capacity_pack_required_capacity_fraction_by_ground_station_id",
      :map
    )
    |> validate_non_negative_number_map(
      path <> ".capacity_pack_required_capacity_fraction_by_ground_station_id",
      Map.get(summary, "capacity_pack_required_capacity_fraction_by_ground_station_id")
    )
    |> expect_type(
      path,
      summary,
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id",
      :map
    )
    |> validate_non_negative_number_map(
      path <> ".capacity_pack_selected_required_capacity_fraction_by_ground_station_id",
      Map.get(summary, "capacity_pack_selected_required_capacity_fraction_by_ground_station_id")
    )
    |> expect_type(
      path,
      summary,
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id",
      :map
    )
    |> validate_non_negative_number_map(
      path <> ".capacity_pack_deferred_required_capacity_fraction_by_ground_station_id",
      Map.get(summary, "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id")
    )
    |> expect_optional_type(
      path,
      summary,
      "capacity_pack_required_capacity_fraction_by_direction",
      :map
    )
    |> validate_non_negative_number_map(
      path <> ".capacity_pack_required_capacity_fraction_by_direction",
      Map.get(summary, "capacity_pack_required_capacity_fraction_by_direction")
    )
    |> expect_optional_type(
      path,
      summary,
      "capacity_pack_selected_required_capacity_fraction_by_direction",
      :map
    )
    |> validate_non_negative_number_map(
      path <> ".capacity_pack_selected_required_capacity_fraction_by_direction",
      Map.get(summary, "capacity_pack_selected_required_capacity_fraction_by_direction")
    )
    |> expect_optional_type(
      path,
      summary,
      "capacity_pack_deferred_required_capacity_fraction_by_direction",
      :map
    )
    |> validate_non_negative_number_map(
      path <> ".capacity_pack_deferred_required_capacity_fraction_by_direction",
      Map.get(summary, "capacity_pack_deferred_required_capacity_fraction_by_direction")
    )
    |> expect_type(path, summary, "required_capacity_fraction_source_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".required_capacity_fraction_source_counts",
      Map.get(summary, "required_capacity_fraction_source_counts")
    )
    |> expect_type(
      path,
      summary,
      "required_capacity_fraction_contact_ids_by_source",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".required_capacity_fraction_contact_ids_by_source",
      Map.get(summary, "required_capacity_fraction_contact_ids_by_source")
    )
    |> expect_type(path, summary, "reduced_capacity_packed_contact_ids", :list)
    |> validate_stable_id_list(
      path <> ".reduced_capacity_packed_contact_ids",
      Map.get(summary, "reduced_capacity_packed_contact_ids")
    )
    |> expect_type(path, summary, "reduced_capacity_deferred_contact_ids", :list)
    |> validate_stable_id_list(
      path <> ".reduced_capacity_deferred_contact_ids",
      Map.get(summary, "reduced_capacity_deferred_contact_ids")
    )
    |> expect_type(path, summary, "capacity_pack_group_ids", :list)
    |> validate_stable_id_list(
      path <> ".capacity_pack_group_ids",
      Map.get(summary, "capacity_pack_group_ids")
    )
    |> expect_type(path, summary, "capacity_pack_group_ids_by_status", :map)
    |> validate_stable_id_array_map(
      path <> ".capacity_pack_group_ids_by_status",
      Map.get(summary, "capacity_pack_group_ids_by_status")
    )
  end

  defp validate_assumptions(issues, path, summary) do
    case Map.get(summary, "assumptions") do
      %{} = assumptions ->
        issues
        |> expect_equal(
          path <> ".assumptions",
          assumptions,
          "execution_boundary",
          "artifact_only_no_provider_reservation_or_schedule_mutation"
        )
        |> expect_equal(
          path <> ".assumptions",
          assumptions,
          "source",
          "contact_allocation_report.v1"
        )
        |> expect_equal(
          path <> ".assumptions",
          assumptions,
          "operator_authority",
          "not_granted_by_capacity_pack_summary"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "capacity_pack_statuses",
          contact_allocation_capacity_pack_statuses(),
          "must match ContactAllocation capacity pack statuses"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "reduced_capacity_pack_statuses",
          contact_allocation_reduced_capacity_pack_statuses(),
          "must match ContactAllocation reduced capacity pack statuses"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "required_capacity_fraction_source_values",
          contact_allocation_required_capacity_fraction_source_values(),
          "must match ContactAllocation required capacity source values"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "required_capacity_value_paths",
          contact_allocation_required_capacity_value_path_assumptions(),
          "must match ContactAllocation required capacity value paths"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "default_required_capacity_value_paths",
          contact_allocation_default_required_capacity_value_path_assumptions(),
          "must match ContactAllocation default required capacity value paths"
        )

      _assumptions ->
        issues
    end
  end

  defp validate_counts(issues, path, summary) do
    rows =
      summary
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    capacity_pack_rows = ContactAllocationReportContracts.capacity_pack_rows(rows)

    selected_capacity_pack_rows =
      ContactAllocationReportContracts.selected_capacity_pack_rows(capacity_pack_rows)

    deferred_capacity_pack_rows =
      ContactAllocationReportContracts.deferred_capacity_pack_rows(capacity_pack_rows)

    pack_groups =
      summary
      |> Map.get("reduced_capacity_pack_groups", [])
      |> Enum.filter(&is_map/1)

    issues
    |> expect_field_equals(path, summary, "input_contact_count", length(rows))
    |> expect_field_equals(
      path,
      summary,
      "capacity_pack_contact_count",
      length(capacity_pack_rows),
      "must equal row-derived capacity_pack_contact_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "capacity_pack_review_status",
      if(capacity_pack_rows == [] and pack_groups == [], do: "clear", else: "review_required")
    )
    |> expect_field_equals(
      path,
      summary,
      "reduced_capacity_pack_group_count",
      length(pack_groups),
      "must equal reduced-capacity-pack-group count"
    )
    |> expect_field_equals(
      path,
      summary,
      "reduced_capacity_pack_status_counts",
      frequency_map(pack_groups, "pack_status"),
      "must equal reduced-capacity-pack-group-derived reduced_capacity_pack_status_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "capacity_pack_status_counts",
      frequency_map(capacity_pack_rows, "capacity_pack_status"),
      "must equal row-derived capacity_pack_status_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "capacity_pack_contact_ids_by_status",
      row_ids_by_field(capacity_pack_rows, "capacity_pack_status", "contact_id"),
      "must equal row-derived capacity_pack_contact_ids_by_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "capacity_pack_contact_ids_by_ground_station_id",
      row_ids_by_field(capacity_pack_rows, "ground_station_id", "contact_id"),
      "must equal row-derived capacity_pack_contact_ids_by_ground_station_id"
    )
    |> expect_field_equals(
      path,
      summary,
      "capacity_pack_selected_contact_ids_by_ground_station_id",
      row_ids_by_field(selected_capacity_pack_rows, "ground_station_id", "contact_id"),
      "must equal row-derived capacity_pack_selected_contact_ids_by_ground_station_id"
    )
    |> expect_field_equals(
      path,
      summary,
      "capacity_pack_deferred_contact_ids_by_ground_station_id",
      row_ids_by_field(deferred_capacity_pack_rows, "ground_station_id", "contact_id"),
      "must equal row-derived capacity_pack_deferred_contact_ids_by_ground_station_id"
    )
    |> expect_optional_field_equals(
      path,
      summary,
      "capacity_pack_contact_ids_by_direction",
      row_ids_by_field(capacity_pack_rows, "direction", "contact_id"),
      "must equal row-derived capacity_pack_contact_ids_by_direction"
    )
    |> expect_optional_field_equals(
      path,
      summary,
      "capacity_pack_selected_contact_ids_by_direction",
      row_ids_by_field(selected_capacity_pack_rows, "direction", "contact_id"),
      "must equal row-derived capacity_pack_selected_contact_ids_by_direction"
    )
    |> expect_optional_field_equals(
      path,
      summary,
      "capacity_pack_deferred_contact_ids_by_direction",
      row_ids_by_field(deferred_capacity_pack_rows, "direction", "contact_id"),
      "must equal row-derived capacity_pack_deferred_contact_ids_by_direction"
    )
    |> validate_fraction_totals(
      path,
      summary,
      capacity_pack_rows,
      selected_capacity_pack_rows,
      deferred_capacity_pack_rows
    )
    |> expect_field_equals(
      path,
      summary,
      "required_capacity_fraction_source_counts",
      frequency_map(capacity_pack_rows, "required_capacity_fraction_source"),
      "must equal row-derived required_capacity_fraction_source_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "required_capacity_fraction_contact_ids_by_source",
      row_ids_by_field(capacity_pack_rows, "required_capacity_fraction_source", "contact_id"),
      "must equal row-derived required_capacity_fraction_contact_ids_by_source"
    )
    |> expect_field_equals(
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
      path,
      summary,
      "capacity_pack_group_ids",
      row_unique_values(pack_groups, "contention_group_id"),
      "must equal reduced-capacity-pack-group-derived capacity_pack_group_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "capacity_pack_group_ids_by_status",
      row_ids_by_field(pack_groups, "pack_status", "contention_group_id"),
      "must equal reduced-capacity-pack-group-derived capacity_pack_group_ids_by_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_rows",
      capacity_pack_rows,
      "must equal row-derived review_rows"
    )
  end

  defp validate_fraction_totals(
         issues,
         path,
         summary,
         capacity_pack_rows,
         selected_capacity_pack_rows,
         deferred_capacity_pack_rows
       ) do
    issues
    |> expect_number_field_equals(
      path,
      summary,
      "capacity_pack_required_capacity_fraction",
      ContactAllocationReportContracts.capacity_pack_required_fraction(capacity_pack_rows),
      "must equal row-derived capacity_pack_required_capacity_fraction"
    )
    |> expect_number_field_equals(
      path,
      summary,
      "capacity_pack_selected_required_capacity_fraction",
      ContactAllocationReportContracts.capacity_pack_required_fraction(
        selected_capacity_pack_rows
      ),
      "must equal row-derived capacity_pack_selected_required_capacity_fraction"
    )
    |> expect_number_field_equals(
      path,
      summary,
      "capacity_pack_deferred_required_capacity_fraction",
      ContactAllocationReportContracts.capacity_pack_required_fraction(
        deferred_capacity_pack_rows
      ),
      "must equal row-derived capacity_pack_deferred_required_capacity_fraction"
    )
    |> expect_field_equals(
      path,
      summary,
      "capacity_pack_required_capacity_fraction_by_status",
      ContactAllocationReportContracts.capacity_pack_required_fraction_by_field(
        capacity_pack_rows,
        "capacity_pack_status"
      ),
      "must equal row-derived capacity_pack_required_capacity_fraction_by_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "capacity_pack_required_capacity_fraction_by_ground_station_id",
      ContactAllocationReportContracts.capacity_pack_required_fraction_by_field(
        capacity_pack_rows,
        "ground_station_id"
      ),
      "must equal row-derived capacity_pack_required_capacity_fraction_by_ground_station_id"
    )
    |> expect_field_equals(
      path,
      summary,
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id",
      ContactAllocationReportContracts.capacity_pack_required_fraction_by_field(
        selected_capacity_pack_rows,
        "ground_station_id"
      ),
      "must equal row-derived capacity_pack_selected_required_capacity_fraction_by_ground_station_id"
    )
    |> expect_field_equals(
      path,
      summary,
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id",
      ContactAllocationReportContracts.capacity_pack_required_fraction_by_field(
        deferred_capacity_pack_rows,
        "ground_station_id"
      ),
      "must equal row-derived capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"
    )
    |> expect_optional_field_equals(
      path,
      summary,
      "capacity_pack_required_capacity_fraction_by_direction",
      ContactAllocationReportContracts.capacity_pack_required_fraction_by_field(
        capacity_pack_rows,
        "direction"
      ),
      "must equal row-derived capacity_pack_required_capacity_fraction_by_direction"
    )
    |> expect_optional_field_equals(
      path,
      summary,
      "capacity_pack_selected_required_capacity_fraction_by_direction",
      ContactAllocationReportContracts.capacity_pack_required_fraction_by_field(
        selected_capacity_pack_rows,
        "direction"
      ),
      "must equal row-derived capacity_pack_selected_required_capacity_fraction_by_direction"
    )
    |> expect_optional_field_equals(
      path,
      summary,
      "capacity_pack_deferred_required_capacity_fraction_by_direction",
      ContactAllocationReportContracts.capacity_pack_required_fraction_by_field(
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

  defp validate_optional_stable_id_array_map(issues, path, map, field) do
    issues
    |> expect_optional_type(path, map, field, :map)
    |> validate_stable_id_array_map(path <> ".#{field}", Map.get(map, field))
  end

  defp contact_allocation_model_limits do
    contact_allocation_capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp contact_allocation_capacity_pack_statuses,
    do: Map.fetch!(contact_allocation_capabilities(), :capacity_pack_statuses)

  defp contact_allocation_reduced_capacity_pack_statuses,
    do: Map.fetch!(contact_allocation_capabilities(), :reduced_capacity_pack_statuses)

  defp contact_allocation_required_capacity_fraction_source_values,
    do: Map.fetch!(contact_allocation_capabilities(), :required_capacity_fraction_source_values)

  defp contact_allocation_required_capacity_value_path_assumptions do
    contact_allocation_capabilities()
    |> Map.fetch!(:required_capacity_value_paths)
    |> contact_allocation_capacity_value_path_assumptions()
  end

  defp contact_allocation_default_required_capacity_value_path_assumptions do
    contact_allocation_capabilities()
    |> Map.fetch!(:default_required_capacity_value_paths)
    |> contact_allocation_capacity_value_path_assumptions()
  end

  defp contact_allocation_capacity_value_path_assumptions(paths) do
    Enum.map(paths, fn %{unit: unit, path: path} ->
      %{"unit" => Atom.to_string(unit), "path" => path}
    end)
  end

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")

  defp contact_allocation_capabilities,
    do: OrbitalDynamics.Communications.ContactAllocation.capabilities()
end
