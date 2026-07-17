defmodule OrbitalDynamics.Schema.ContactAllocationStationPressureSummaryContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.ContactAllocationReportContracts

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_one_of: 5,
      expect_optional_field_equals: 6,
      expect_optional_type: 5,
      expect_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_nested_stable_id_array_map: 3,
      validate_stable_id_array_map: 3,
      validate_stable_id_list: 3
    ]

  def validate_summary(issues, path, summary, row_validator) when is_function(row_validator, 3) do
    issues
    |> expect_equal(
      path,
      summary,
      "schema_contract",
      "contact_allocation_station_pressure_summary.v1"
    )
    |> expect_equal(
      path,
      summary,
      "model",
      "artifact_only_contact_allocation_station_pressure_summary"
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
    |> expect_non_negative_integer(path, summary, "station_pressure_contact_count")
    |> expect_non_negative_integer(
      path,
      summary,
      "station_pressure_review_contact_count"
    )
    |> validate_field_types(path, summary)
    |> expect_type(path, summary, "rows", :list)
    |> validate_rows(
      path <> ".rows",
      Map.get(summary, "rows", []),
      row_validator
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
    |> expect_type(path, summary, "station_pressure_contact_ids", :list)
    |> validate_stable_id_list(
      path <> ".station_pressure_contact_ids",
      Map.get(summary, "station_pressure_contact_ids")
    )
    |> expect_type(path, summary, "station_pressure_review_contact_ids", :list)
    |> validate_stable_id_list(
      path <> ".station_pressure_review_contact_ids",
      Map.get(summary, "station_pressure_review_contact_ids")
    )
    |> expect_type(
      path,
      summary,
      "station_pressure_contact_ids_by_ground_station_id",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".station_pressure_contact_ids_by_ground_station_id",
      Map.get(summary, "station_pressure_contact_ids_by_ground_station_id")
    )
    |> expect_type(
      path,
      summary,
      "station_pressure_contact_counts_by_ground_station_id",
      :map
    )
    |> validate_non_negative_integer_count_map(
      path <> ".station_pressure_contact_counts_by_ground_station_id",
      Map.get(summary, "station_pressure_contact_counts_by_ground_station_id")
    )
    |> expect_type(path, summary, "station_pressure_contact_ids_by_availability", :map)
    |> validate_stable_id_array_map(
      path <> ".station_pressure_contact_ids_by_availability",
      Map.get(summary, "station_pressure_contact_ids_by_availability")
    )
    |> expect_type(
      path,
      summary,
      "station_pressure_contact_counts_by_availability",
      :map
    )
    |> validate_non_negative_integer_count_map(
      path <> ".station_pressure_contact_counts_by_availability",
      Map.get(summary, "station_pressure_contact_counts_by_availability")
    )
    |> expect_type(
      path,
      summary,
      "station_pressure_contact_ids_by_precedence_availability",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".station_pressure_contact_ids_by_precedence_availability",
      Map.get(summary, "station_pressure_contact_ids_by_precedence_availability")
    )
    |> expect_type(
      path,
      summary,
      "station_pressure_contact_counts_by_precedence_availability",
      :map
    )
    |> validate_non_negative_integer_count_map(
      path <> ".station_pressure_contact_counts_by_precedence_availability",
      Map.get(summary, "station_pressure_contact_counts_by_precedence_availability")
    )
    |> expect_type(
      path,
      summary,
      "station_pressure_contact_ids_by_precedence_rank",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".station_pressure_contact_ids_by_precedence_rank",
      Map.get(summary, "station_pressure_contact_ids_by_precedence_rank")
    )
    |> expect_type(
      path,
      summary,
      "station_pressure_contact_counts_by_precedence_rank",
      :map
    )
    |> validate_non_negative_integer_count_map(
      path <> ".station_pressure_contact_counts_by_precedence_rank",
      Map.get(summary, "station_pressure_contact_counts_by_precedence_rank")
    )
    |> expect_optional_type(
      path,
      summary,
      "station_pressure_contact_ids_by_direction_and_ground_station_id",
      :map
    )
    |> validate_nested_stable_id_array_map(
      path <> ".station_pressure_contact_ids_by_direction_and_ground_station_id",
      Map.get(summary, "station_pressure_contact_ids_by_direction_and_ground_station_id")
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
          "not_granted_by_station_pressure_summary"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "station_unavailable_aliases",
          contact_allocation_station_unavailable_aliases(),
          "must match ContactAllocation station unavailable aliases"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "station_blocking_availability",
          contact_allocation_station_blocking_availability(),
          "must match ContactAllocation station blocking availability"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "station_availability_precedence",
          contact_allocation_station_availability_precedence(),
          "must match ContactAllocation station availability precedence"
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

    station_pressure_rows = ContactAllocationReportContracts.station_pressure_rows(rows)

    review_rows =
      Enum.filter(station_pressure_rows, &ContactAllocationReportContracts.review_row?(&1))

    ids_by_ground_station =
      row_ids_by_field(station_pressure_rows, "ground_station_id", "contact_id")

    ids_by_availability =
      ContactAllocationReportContracts.station_pressure_ids_by_availability(station_pressure_rows)

    ids_by_precedence_availability =
      row_ids_by_field(
        station_pressure_rows,
        "station_calendar_precedence_availability",
        "contact_id"
      )

    ids_by_precedence_rank =
      row_ids_by_string_field(
        station_pressure_rows,
        "station_calendar_precedence_rank",
        "contact_id"
      )

    ids_by_status =
      row_ids_by_field(station_pressure_rows, "station_calendar_status", "contact_id")

    issues
    |> expect_field_equals(path, summary, "input_contact_count", length(rows))
    |> expect_field_equals(
      path,
      summary,
      "station_pressure_contact_count",
      length(station_pressure_rows),
      "must equal row-derived station_pressure_contact_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "station_pressure_review_contact_count",
      length(review_rows),
      "must equal row-derived station_pressure_review_contact_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "station_pressure_contact_ids",
      ContactAllocationReportContracts.row_contact_ids(station_pressure_rows),
      "must equal row-derived station_pressure_contact_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "station_pressure_review_contact_ids",
      ContactAllocationReportContracts.row_contact_ids(review_rows),
      "must equal row-derived station_pressure_review_contact_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "station_pressure_contact_ids_by_ground_station_id",
      ids_by_ground_station,
      "must equal row-derived station_pressure_contact_ids_by_ground_station_id"
    )
    |> expect_field_equals(
      path,
      summary,
      "station_pressure_contact_counts_by_ground_station_id",
      id_array_count_map(ids_by_ground_station),
      "must equal row-derived station_pressure_contact_counts_by_ground_station_id"
    )
    |> expect_field_equals(
      path,
      summary,
      "station_pressure_contact_ids_by_availability",
      ids_by_availability,
      "must equal row-derived station_pressure_contact_ids_by_availability"
    )
    |> expect_field_equals(
      path,
      summary,
      "station_pressure_contact_counts_by_availability",
      id_array_count_map(ids_by_availability),
      "must equal row-derived station_pressure_contact_counts_by_availability"
    )
    |> expect_field_equals(
      path,
      summary,
      "station_pressure_contact_ids_by_precedence_availability",
      ids_by_precedence_availability,
      "must equal row-derived station_pressure_contact_ids_by_precedence_availability"
    )
    |> expect_field_equals(
      path,
      summary,
      "station_pressure_contact_counts_by_precedence_availability",
      id_array_count_map(ids_by_precedence_availability),
      "must equal row-derived station_pressure_contact_counts_by_precedence_availability"
    )
    |> expect_field_equals(
      path,
      summary,
      "station_pressure_contact_ids_by_precedence_rank",
      ids_by_precedence_rank,
      "must equal row-derived station_pressure_contact_ids_by_precedence_rank"
    )
    |> expect_field_equals(
      path,
      summary,
      "station_pressure_contact_counts_by_precedence_rank",
      id_array_count_map(ids_by_precedence_rank),
      "must equal row-derived station_pressure_contact_counts_by_precedence_rank"
    )
    |> expect_field_equals(
      path,
      summary,
      "station_pressure_contact_ids_by_status",
      ids_by_status,
      "must equal row-derived station_pressure_contact_ids_by_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "station_pressure_contact_counts_by_status",
      id_array_count_map(ids_by_status),
      "must equal row-derived station_pressure_contact_counts_by_status"
    )
    |> expect_optional_field_equals(
      path,
      summary,
      "station_pressure_contact_ids_by_direction_and_ground_station_id",
      row_ids_by_direction_and_ground_station(station_pressure_rows, "contact_id"),
      "must equal row-derived station_pressure_contact_ids_by_direction_and_ground_station_id"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_rows",
      review_rows,
      "must equal row-derived review_rows"
    )
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

  defp contact_allocation_model_limits do
    contact_allocation_capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp contact_allocation_station_unavailable_aliases,
    do: Map.fetch!(contact_allocation_capabilities(), :station_unavailable_aliases)

  defp contact_allocation_station_blocking_availability,
    do: Map.fetch!(contact_allocation_capabilities(), :station_blocking_availability)

  defp contact_allocation_station_availability_precedence,
    do: Map.fetch!(contact_allocation_capabilities(), :station_availability_precedence)

  defp contact_allocation_provider_direction_aliases,
    do: Map.fetch!(contact_allocation_capabilities(), :provider_direction_aliases)

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")

  defp contact_allocation_capabilities,
    do: OrbitalDynamics.Communications.ContactAllocation.capabilities()
end
