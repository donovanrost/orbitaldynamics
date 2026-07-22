defmodule OrbitalDynamics.Schema.ContactAllocationProviderReservationRequestSummaryContracts do
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
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_nested_stable_id_array_map: 3,
      validate_stable_id_array_map: 3,
      validate_stable_id_list: 3
    ]

  @request_statuses ["clear", "request_ready", "review_required"]
  @request_ready_match_statuses ["matched", "owner_matched"]

  def validate_summary(issues, path, summary, row_validator) when is_function(row_validator, 3) do
    issues
    |> expect_equal(
      path,
      summary,
      "schema_contract",
      "contact_allocation_provider_reservation_request_summary.v1"
    )
    |> expect_equal(
      path,
      summary,
      "model",
      "artifact_only_contact_allocation_provider_reservation_request_summary"
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
    |> expect_non_negative_integer(
      path,
      summary,
      "provider_reservation_candidate_contact_count"
    )
    |> expect_non_negative_integer(
      path,
      summary,
      "provider_reservation_request_contact_count"
    )
    |> expect_non_negative_integer(
      path,
      summary,
      "provider_reservation_review_contact_count"
    )
    |> expect_non_negative_integer(
      path,
      summary,
      "provider_reservation_no_request_contact_count"
    )
    |> expect_one_of(
      path,
      summary,
      "provider_reservation_request_status",
      @request_statuses
    )
    |> validate_field_types(path, summary)
    |> expect_type(path, summary, "rows", :list)
    |> validate_rows(
      path <> ".rows",
      Map.get(summary, "rows", []),
      row_validator
    )
    |> expect_type(path, summary, "provider_reservation_request_rows", :list)
    |> validate_rows(
      path <> ".provider_reservation_request_rows",
      Map.get(summary, "provider_reservation_request_rows", []),
      row_validator
    )
    |> expect_type(path, summary, "provider_reservation_review_rows", :list)
    |> validate_rows(
      path <> ".provider_reservation_review_rows",
      Map.get(summary, "provider_reservation_review_rows", []),
      row_validator
    )
    |> expect_type(path, summary, "assumptions", :map)
    |> validate_assumptions(path, summary)
    |> validate_counts(path, summary)
  end

  defp validate_field_types(issues, path, summary) do
    issues
    |> expect_type(path, summary, "provider_reservation_request_contact_ids", :list)
    |> validate_stable_id_list(
      path <> ".provider_reservation_request_contact_ids",
      Map.get(summary, "provider_reservation_request_contact_ids")
    )
    |> expect_type(path, summary, "provider_reservation_review_contact_ids", :list)
    |> validate_stable_id_list(
      path <> ".provider_reservation_review_contact_ids",
      Map.get(summary, "provider_reservation_review_contact_ids")
    )
    |> expect_type(path, summary, "provider_reservation_no_request_contact_ids", :list)
    |> validate_stable_id_list(
      path <> ".provider_reservation_no_request_contact_ids",
      Map.get(summary, "provider_reservation_no_request_contact_ids")
    )
    |> expect_type(
      path,
      summary,
      "provider_reservation_request_contact_ids_by_ground_station_id",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".provider_reservation_request_contact_ids_by_ground_station_id",
      Map.get(summary, "provider_reservation_request_contact_ids_by_ground_station_id")
    )
    |> expect_type(
      path,
      summary,
      "provider_reservation_review_contact_ids_by_ground_station_id",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".provider_reservation_review_contact_ids_by_ground_station_id",
      Map.get(summary, "provider_reservation_review_contact_ids_by_ground_station_id")
    )
    |> validate_optional_stable_id_array_map(
      path,
      summary,
      "provider_reservation_no_request_contact_ids_by_direction"
    )
    |> validate_optional_stable_id_array_map(
      path,
      summary,
      "provider_reservation_request_contact_ids_by_direction"
    )
    |> validate_optional_stable_id_array_map(
      path,
      summary,
      "provider_reservation_review_contact_ids_by_direction"
    )
    |> validate_nested_stable_id_array_map(
      path <> ".provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id",
      Map.get(
        summary,
        "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id"
      )
    )
    |> validate_nested_stable_id_array_map(
      path <> ".provider_reservation_request_contact_ids_by_direction_and_ground_station_id",
      Map.get(
        summary,
        "provider_reservation_request_contact_ids_by_direction_and_ground_station_id"
      )
    )
    |> validate_nested_stable_id_array_map(
      path <> ".provider_reservation_review_contact_ids_by_direction_and_ground_station_id",
      Map.get(
        summary,
        "provider_reservation_review_contact_ids_by_direction_and_ground_station_id"
      )
    )
    |> expect_type(
      path,
      summary,
      "provider_reservation_request_contact_ids_by_match_status",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".provider_reservation_request_contact_ids_by_match_status",
      Map.get(summary, "provider_reservation_request_contact_ids_by_match_status")
    )
    |> expect_type(
      path,
      summary,
      "provider_reservation_review_contact_ids_by_match_status",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".provider_reservation_review_contact_ids_by_match_status",
      Map.get(summary, "provider_reservation_review_contact_ids_by_match_status")
    )
    |> expect_type(
      path,
      summary,
      "provider_reservation_request_ids_by_match_status",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".provider_reservation_request_ids_by_match_status",
      Map.get(summary, "provider_reservation_request_ids_by_match_status")
    )
    |> expect_type(
      path,
      summary,
      "provider_reservation_review_ids_by_match_status",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".provider_reservation_review_ids_by_match_status",
      Map.get(summary, "provider_reservation_review_ids_by_match_status")
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
          "provider_reservation_execution",
          "not_performed_by_summary"
        )
        |> expect_equal(
          path <> ".assumptions",
          assumptions,
          "operator_authority",
          "not_granted_by_provider_reservation_request_summary"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "provider_reservation_request_statuses",
          contact_allocation_provider_reservation_request_statuses(),
          "must match ContactAllocation provider reservation request statuses"
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

    candidate_rows = Enum.filter(rows, &provider_reservation_candidate_row?(&1))

    request_rows =
      Enum.filter(candidate_rows, &provider_reservation_request_ready_row?(&1))

    review_rows =
      Enum.reject(candidate_rows, &provider_reservation_request_ready_row?(&1))

    no_request_rows = Enum.reject(rows, &provider_reservation_candidate_row?(&1))

    issues
    |> expect_field_equals(path, summary, "input_contact_count", length(rows))
    |> expect_field_equals(
      path,
      summary,
      "provider_reservation_candidate_contact_count",
      length(candidate_rows),
      "must equal row-derived provider_reservation_candidate_contact_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "provider_reservation_request_contact_count",
      length(request_rows),
      "must equal row-derived provider_reservation_request_contact_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "provider_reservation_review_contact_count",
      length(review_rows),
      "must equal row-derived provider_reservation_review_contact_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "provider_reservation_no_request_contact_count",
      length(no_request_rows),
      "must equal row-derived provider_reservation_no_request_contact_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "provider_reservation_request_status",
      provider_reservation_request_status(request_rows, review_rows)
    )
    |> validate_id_fields(
      path,
      summary,
      request_rows,
      review_rows,
      no_request_rows
    )
  end

  defp validate_id_fields(
         issues,
         path,
         summary,
         request_rows,
         review_rows,
         no_request_rows
       ) do
    issues
    |> expect_field_equals(
      path,
      summary,
      "provider_reservation_request_contact_ids",
      ContactAllocationReportContracts.row_contact_ids(request_rows),
      "must equal row-derived provider_reservation_request_contact_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "provider_reservation_review_contact_ids",
      ContactAllocationReportContracts.row_contact_ids(review_rows),
      "must equal row-derived provider_reservation_review_contact_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "provider_reservation_no_request_contact_ids",
      ContactAllocationReportContracts.row_contact_ids(no_request_rows),
      "must equal row-derived provider_reservation_no_request_contact_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "provider_reservation_request_contact_ids_by_ground_station_id",
      row_ids_by_field(request_rows, "ground_station_id", "contact_id"),
      "must equal row-derived provider_reservation_request_contact_ids_by_ground_station_id"
    )
    |> expect_field_equals(
      path,
      summary,
      "provider_reservation_review_contact_ids_by_ground_station_id",
      row_ids_by_field(review_rows, "ground_station_id", "contact_id"),
      "must equal row-derived provider_reservation_review_contact_ids_by_ground_station_id"
    )
    |> expect_field_equals(
      path,
      summary,
      "provider_reservation_no_request_contact_ids_by_direction",
      row_ids_by_field(no_request_rows, "direction", "contact_id"),
      "must equal row-derived provider_reservation_no_request_contact_ids_by_direction"
    )
    |> expect_field_equals(
      path,
      summary,
      "provider_reservation_request_contact_ids_by_direction",
      row_ids_by_field(request_rows, "direction", "contact_id"),
      "must equal row-derived provider_reservation_request_contact_ids_by_direction"
    )
    |> expect_field_equals(
      path,
      summary,
      "provider_reservation_review_contact_ids_by_direction",
      row_ids_by_field(review_rows, "direction", "contact_id"),
      "must equal row-derived provider_reservation_review_contact_ids_by_direction"
    )
    |> expect_field_equals(
      path,
      summary,
      "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id",
      row_ids_by_direction_and_ground_station(no_request_rows, "contact_id"),
      "must equal row-derived provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id"
    )
    |> expect_field_equals(
      path,
      summary,
      "provider_reservation_request_contact_ids_by_direction_and_ground_station_id",
      row_ids_by_direction_and_ground_station(request_rows, "contact_id"),
      "must equal row-derived provider_reservation_request_contact_ids_by_direction_and_ground_station_id"
    )
    |> expect_field_equals(
      path,
      summary,
      "provider_reservation_review_contact_ids_by_direction_and_ground_station_id",
      row_ids_by_direction_and_ground_station(review_rows, "contact_id"),
      "must equal row-derived provider_reservation_review_contact_ids_by_direction_and_ground_station_id"
    )
    |> expect_field_equals(
      path,
      summary,
      "provider_reservation_request_contact_ids_by_match_status",
      row_ids_by_field(request_rows, "station_reservation_match_status", "contact_id"),
      "must equal row-derived provider_reservation_request_contact_ids_by_match_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "provider_reservation_review_contact_ids_by_match_status",
      row_ids_by_field(review_rows, "station_reservation_match_status", "contact_id"),
      "must equal row-derived provider_reservation_review_contact_ids_by_match_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "provider_reservation_request_ids_by_match_status",
      row_reservation_ids_by_match_status(request_rows),
      "must equal row-derived provider_reservation_request_ids_by_match_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "provider_reservation_review_ids_by_match_status",
      row_reservation_ids_by_match_status(review_rows),
      "must equal row-derived provider_reservation_review_ids_by_match_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "provider_reservation_request_rows",
      request_rows,
      "must equal row-derived provider_reservation_request_rows"
    )
    |> expect_field_equals(
      path,
      summary,
      "provider_reservation_review_rows",
      review_rows,
      "must equal row-derived provider_reservation_review_rows"
    )
  end

  defp provider_reservation_candidate_row?(row) do
    Map.get(row, "allocation_status") == "allocated" and
      Map.get(row, "effective_allocation_status") in [nil, "allocated"] and
      ContactAllocationReportContracts.reservation_expiration_row?(row)
  end

  defp provider_reservation_request_ready_row?(row) do
    Map.get(row, "station_reservation_match_status") in @request_ready_match_statuses and
      ContactAllocationReportContracts.reservation_ids(row) != []
  end

  defp provider_reservation_request_status(_request_rows, review_rows) when review_rows != [],
    do: "review_required"

  defp provider_reservation_request_status(request_rows, _review_rows) when request_rows != [],
    do: "request_ready"

  defp provider_reservation_request_status(_request_rows, _review_rows), do: "clear"

  defp row_ids_by_field(rows, group_field, id_field) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.group_by(&Map.get(&1, group_field), &Map.get(&1, id_field))
    |> Enum.reject(fn {group, ids} -> is_nil(group) or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {group, ids} ->
      {group, ids |> Enum.reject(&is_nil/1) |> Enum.uniq() |> Enum.sort()}
    end)
  end

  defp row_reservation_ids_by_match_status(rows) do
    Enum.reduce(rows, %{}, fn row, acc ->
      match_status = Map.get(row, "station_reservation_match_status")

      reservation_ids =
        [Map.get(row, "station_reservation_id"), Map.get(row, "station_calendar_reservation_ids")]
        |> List.flatten()
        |> Enum.filter(&(is_binary(&1) and &1 != ""))
        |> Enum.uniq()
        |> Enum.sort()

      if is_binary(match_status) and match_status != "" and reservation_ids != [] do
        Map.update(acc, match_status, reservation_ids, fn current ->
          (current ++ reservation_ids) |> Enum.uniq() |> Enum.sort()
        end)
      else
        acc
      end
    end)
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

  defp contact_allocation_provider_reservation_request_statuses,
    do: Map.fetch!(contact_allocation_capabilities(), :provider_reservation_request_statuses)

  defp contact_allocation_station_reservation_match_statuses,
    do: Map.fetch!(contact_allocation_capabilities(), :station_reservation_match_statuses)

  defp contact_allocation_provider_direction_aliases,
    do: Map.fetch!(contact_allocation_capabilities(), :provider_direction_aliases)

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")

  defp contact_allocation_capabilities,
    do: OrbitalDynamics.Communications.ContactAllocation.capabilities()
end
