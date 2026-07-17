defmodule OrbitalDynamics.Schema.ContactAllocationReservationConflictSummaryContracts do
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
      expect_optional_number: 4,
      expect_optional_type: 5,
      expect_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_number_list_items: 4,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_nested_stable_id_array_map: 3,
      validate_stable_id_array_map: 3,
      validate_stable_id_list: 3
    ]

  @non_conflict_match_statuses ["matched", "owner_matched"]

  def validate_summary(issues, path, summary, row_validator) when is_function(row_validator, 3) do
    issues
    |> expect_equal(
      path,
      summary,
      "schema_contract",
      "contact_allocation_reservation_conflict_summary.v1"
    )
    |> expect_equal(
      path,
      summary,
      "model",
      "artifact_only_contact_allocation_reservation_conflict_summary"
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
    |> expect_non_negative_integer(path, summary, "station_reservation_contact_count")
    |> expect_non_negative_integer(path, summary, "reservation_conflict_contact_count")
    |> expect_non_negative_integer(path, summary, "reservation_review_contact_count")
    |> validate_field_types(path, summary)
    |> expect_type(path, summary, "rows", :list)
    |> validate_rows(
      path <> ".rows",
      Map.get(summary, "rows", []),
      row_validator
    )
    |> expect_type(path, summary, "reservation_conflict_rows", :list)
    |> validate_rows(
      path <> ".reservation_conflict_rows",
      Map.get(summary, "reservation_conflict_rows", []),
      row_validator
    )
    |> expect_type(path, summary, "reservation_review_rows", :list)
    |> validate_rows(
      path <> ".reservation_review_rows",
      Map.get(summary, "reservation_review_rows", []),
      row_validator
    )
    |> expect_type(path, summary, "assumptions", :map)
    |> validate_assumptions(path, summary)
    |> validate_counts(path, summary)
  end

  defp validate_field_types(issues, path, summary) do
    issues
    |> expect_type(path, summary, "station_reservation_match_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".station_reservation_match_status_counts",
      Map.get(summary, "station_reservation_match_status_counts")
    )
    |> expect_type(path, summary, "reservation_conflict_match_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".reservation_conflict_match_status_counts",
      Map.get(summary, "reservation_conflict_match_status_counts")
    )
    |> expect_type(path, summary, "station_reservation_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".station_reservation_status_counts",
      Map.get(summary, "station_reservation_status_counts")
    )
    |> expect_type(path, summary, "station_reserved_by_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".station_reserved_by_counts",
      Map.get(summary, "station_reserved_by_counts")
    )
    |> expect_type(path, summary, "station_reservation_ids", :list)
    |> validate_stable_id_list(
      path <> ".station_reservation_ids",
      Map.get(summary, "station_reservation_ids")
    )
    |> expect_type(path, summary, "station_reservation_expires_at_s", :list)
    |> validate_number_list_items(path, summary, "station_reservation_expires_at_s")
    |> expect_optional_number(path, summary, "station_reservation_expiration_now_s")
    |> expect_type(path, summary, "station_reservation_expiration_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".station_reservation_expiration_status_counts",
      Map.get(summary, "station_reservation_expiration_status_counts")
    )
    |> expect_optional_number(
      path,
      summary,
      "earliest_station_reservation_expires_at_s"
    )
    |> expect_type(path, summary, "reservation_conflict_contact_ids", :list)
    |> validate_stable_id_list(
      path <> ".reservation_conflict_contact_ids",
      Map.get(summary, "reservation_conflict_contact_ids")
    )
    |> expect_type(path, summary, "reservation_review_contact_ids", :list)
    |> validate_stable_id_list(
      path <> ".reservation_review_contact_ids",
      Map.get(summary, "reservation_review_contact_ids")
    )
    |> expect_type(
      path,
      summary,
      "station_reservation_contact_ids_by_match_status",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".station_reservation_contact_ids_by_match_status",
      Map.get(summary, "station_reservation_contact_ids_by_match_status")
    )
    |> expect_type(
      path,
      summary,
      "reservation_conflict_contact_ids_by_match_status",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".reservation_conflict_contact_ids_by_match_status",
      Map.get(summary, "reservation_conflict_contact_ids_by_match_status")
    )
    |> validate_optional_stable_id_array_map(
      path,
      summary,
      "reservation_conflict_contact_ids_by_direction"
    )
    |> expect_optional_type(
      path,
      summary,
      "reservation_conflict_contact_ids_by_direction_and_ground_station_id",
      :map
    )
    |> validate_nested_stable_id_array_map(
      path <> ".reservation_conflict_contact_ids_by_direction_and_ground_station_id",
      Map.get(summary, "reservation_conflict_contact_ids_by_direction_and_ground_station_id")
    )
    |> expect_type(path, summary, "station_reservation_contact_ids_by_status", :map)
    |> validate_stable_id_array_map(
      path <> ".station_reservation_contact_ids_by_status",
      Map.get(summary, "station_reservation_contact_ids_by_status")
    )
    |> expect_type(
      path,
      summary,
      "station_reservation_contact_ids_by_reserved_by",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".station_reservation_contact_ids_by_reserved_by",
      Map.get(summary, "station_reservation_contact_ids_by_reserved_by")
    )
    |> expect_type(
      path,
      summary,
      "station_reservation_contact_ids_by_expiration_status",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".station_reservation_contact_ids_by_expiration_status",
      Map.get(summary, "station_reservation_contact_ids_by_expiration_status")
    )
    |> expect_type(path, summary, "station_reservation_ids_by_match_status", :map)
    |> validate_stable_id_array_map(
      path <> ".station_reservation_ids_by_match_status",
      Map.get(summary, "station_reservation_ids_by_match_status")
    )
    |> expect_type(
      path,
      summary,
      "reservation_conflict_reservation_ids_by_match_status",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".reservation_conflict_reservation_ids_by_match_status",
      Map.get(summary, "reservation_conflict_reservation_ids_by_match_status")
    )
    |> expect_type(path, summary, "station_reservation_ids_by_status", :map)
    |> validate_stable_id_array_map(
      path <> ".station_reservation_ids_by_status",
      Map.get(summary, "station_reservation_ids_by_status")
    )
    |> expect_type(path, summary, "station_reservation_ids_by_reserved_by", :map)
    |> validate_stable_id_array_map(
      path <> ".station_reservation_ids_by_reserved_by",
      Map.get(summary, "station_reservation_ids_by_reserved_by")
    )
    |> expect_type(path, summary, "station_reservation_ids_by_expiration_status", :map)
    |> validate_stable_id_array_map(
      path <> ".station_reservation_ids_by_expiration_status",
      Map.get(summary, "station_reservation_ids_by_expiration_status")
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
          "not_granted_by_reservation_conflict_summary"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "station_reservation_match_statuses",
          contact_allocation_station_reservation_match_statuses(),
          "must match ContactAllocation station reservation match statuses"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "reservation_conflict_match_statuses",
          contact_allocation_reservation_conflict_match_statuses(),
          "must match ContactAllocation reservation conflict match statuses"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "station_reservation_expiration_statuses",
          contact_allocation_station_reservation_expiration_statuses(),
          "must match ContactAllocation station reservation expiration statuses"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "provider_direction_aliases",
          contact_allocation_provider_direction_aliases(),
          "must match ContactAllocation provider direction aliases"
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

    now_s = Map.get(summary, "station_reservation_expiration_now_s")

    reservation_rows =
      Enum.filter(rows, &ContactAllocationReportContracts.reservation_expiration_row?(&1))

    conflict_rows = Enum.filter(reservation_rows, &reservation_conflict_row?(&1))
    review_rows = Enum.filter(reservation_rows, &ContactAllocationReportContracts.review_row?(&1))

    expiration_rows =
      ContactAllocationReportContracts.reservation_expiration_rows(reservation_rows, now_s)

    issues
    |> expect_field_equals(path, summary, "input_contact_count", length(rows))
    |> expect_field_equals(
      path,
      summary,
      "station_reservation_contact_count",
      length(reservation_rows),
      "must equal row-derived station_reservation_contact_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_conflict_contact_count",
      length(conflict_rows),
      "must equal row-derived reservation_conflict_contact_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_review_contact_count",
      length(review_rows),
      "must equal row-derived reservation_review_contact_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "station_reservation_match_status_counts",
      frequency_map(reservation_rows, "station_reservation_match_status"),
      "must equal row-derived station_reservation_match_status_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_conflict_match_status_counts",
      frequency_map(conflict_rows, "station_reservation_match_status"),
      "must equal row-derived reservation_conflict_match_status_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "station_reservation_status_counts",
      frequency_map(reservation_rows, "station_reservation_status"),
      "must equal row-derived station_reservation_status_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "station_reserved_by_counts",
      frequency_map(reservation_rows, "station_reserved_by"),
      "must equal row-derived station_reserved_by_counts"
    )
    |> validate_reservation_id_fields(
      path,
      summary,
      reservation_rows,
      conflict_rows,
      review_rows,
      expiration_rows
    )
  end

  defp validate_reservation_id_fields(
         issues,
         path,
         summary,
         reservation_rows,
         conflict_rows,
         review_rows,
         expiration_rows
       ) do
    issues
    |> expect_field_equals(
      path,
      summary,
      "station_reservation_ids",
      ContactAllocationReportContracts.reservation_row_ids(reservation_rows),
      "must equal row-derived station_reservation_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "station_reservation_expires_at_s",
      ContactAllocationReportContracts.reservation_expires_at_values(reservation_rows),
      "must equal row-derived station_reservation_expires_at_s"
    )
    |> expect_field_equals(
      path,
      summary,
      "station_reservation_expiration_status_counts",
      frequency_map(expiration_rows, "station_reservation_expiration_status"),
      "must equal row-derived station_reservation_expiration_status_counts"
    )
    |> expect_number_field_equals(
      path,
      summary,
      "earliest_station_reservation_expires_at_s",
      ContactAllocationReportContracts.earliest_reservation_expires_at_s(expiration_rows),
      "must equal row-derived earliest_station_reservation_expires_at_s"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_conflict_contact_ids",
      ContactAllocationReportContracts.row_contact_ids(conflict_rows),
      "must equal row-derived reservation_conflict_contact_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_review_contact_ids",
      ContactAllocationReportContracts.row_contact_ids(review_rows),
      "must equal row-derived reservation_review_contact_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "station_reservation_contact_ids_by_match_status",
      row_ids_by_field(reservation_rows, "station_reservation_match_status", "contact_id"),
      "must equal row-derived station_reservation_contact_ids_by_match_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_conflict_contact_ids_by_match_status",
      row_ids_by_field(conflict_rows, "station_reservation_match_status", "contact_id"),
      "must equal row-derived reservation_conflict_contact_ids_by_match_status"
    )
    |> expect_optional_field_equals(
      path,
      summary,
      "reservation_conflict_contact_ids_by_direction",
      row_ids_by_direction(conflict_rows, "contact_id"),
      "must equal row-derived reservation_conflict_contact_ids_by_direction"
    )
    |> expect_optional_field_equals(
      path,
      summary,
      "reservation_conflict_contact_ids_by_direction_and_ground_station_id",
      row_ids_by_direction_and_ground_station(conflict_rows, "contact_id"),
      "must equal row-derived reservation_conflict_contact_ids_by_direction_and_ground_station_id"
    )
    |> expect_field_equals(
      path,
      summary,
      "station_reservation_contact_ids_by_status",
      row_ids_by_field(reservation_rows, "station_reservation_status", "contact_id"),
      "must equal row-derived station_reservation_contact_ids_by_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "station_reservation_contact_ids_by_reserved_by",
      row_ids_by_field(reservation_rows, "station_reserved_by", "contact_id"),
      "must equal row-derived station_reservation_contact_ids_by_reserved_by"
    )
    |> expect_field_equals(
      path,
      summary,
      "station_reservation_contact_ids_by_expiration_status",
      row_ids_by_field(expiration_rows, "station_reservation_expiration_status", "contact_id"),
      "must equal row-derived station_reservation_contact_ids_by_expiration_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "station_reservation_ids_by_match_status",
      row_ids_by_field(
        reservation_rows,
        "station_reservation_match_status",
        "station_reservation_id"
      ),
      "must equal row-derived station_reservation_ids_by_match_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_conflict_reservation_ids_by_match_status",
      row_ids_by_field(
        conflict_rows,
        "station_reservation_match_status",
        "station_reservation_id"
      ),
      "must equal row-derived reservation_conflict_reservation_ids_by_match_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "station_reservation_ids_by_status",
      row_ids_by_field(reservation_rows, "station_reservation_status", "station_reservation_id"),
      "must equal row-derived station_reservation_ids_by_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "station_reservation_ids_by_reserved_by",
      row_ids_by_field(reservation_rows, "station_reserved_by", "station_reservation_id"),
      "must equal row-derived station_reservation_ids_by_reserved_by"
    )
    |> expect_field_equals(
      path,
      summary,
      "station_reservation_ids_by_expiration_status",
      ContactAllocationReportContracts.reservation_ids_by_expiration_status(expiration_rows),
      "must equal row-derived station_reservation_ids_by_expiration_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_conflict_rows",
      conflict_rows,
      "must equal row-derived reservation_conflict_rows"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_review_rows",
      review_rows,
      "must equal row-derived reservation_review_rows"
    )
  end

  defp reservation_conflict_row?(row) do
    ContactAllocationReportContracts.pressure_value?(row["station_reservation_match_status"]) and
      row["station_reservation_match_status"] not in @non_conflict_match_statuses
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

  defp row_ids_by_direction(rows, id_field) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.reduce(%{}, fn row, acc ->
      direction = Map.get(row, "direction")
      id = Map.get(row, id_field)

      if direction in [nil, ""] or id in [nil, ""] do
        acc
      else
        Map.update(acc, direction, [id], fn ids -> [id | ids] end)
      end
    end)
    |> Map.new(fn {direction, ids} -> {direction, ids |> Enum.uniq() |> Enum.sort()} end)
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

  defp contact_allocation_station_reservation_match_statuses,
    do: Map.fetch!(contact_allocation_capabilities(), :station_reservation_match_statuses)

  defp contact_allocation_reservation_conflict_match_statuses,
    do: Map.fetch!(contact_allocation_capabilities(), :reservation_conflict_match_statuses)

  defp contact_allocation_station_reservation_expiration_statuses,
    do: Map.fetch!(contact_allocation_capabilities(), :station_reservation_expiration_statuses)

  defp contact_allocation_provider_direction_aliases,
    do: Map.fetch!(contact_allocation_capabilities(), :provider_direction_aliases)

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")

  defp contact_allocation_capabilities,
    do: OrbitalDynamics.Communications.ContactAllocation.capabilities()
end
