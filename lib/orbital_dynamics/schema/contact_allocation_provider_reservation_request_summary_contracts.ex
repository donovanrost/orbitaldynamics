defmodule OrbitalDynamics.Schema.ContactAllocationProviderReservationRequestSummaryContracts do
  @moduledoc false

  @request_statuses ["clear", "request_ready", "review_required"]
  @request_ready_match_statuses ["matched", "owner_matched"]

  def validate_summary(issues, path, summary, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(
      callbacks,
      path,
      summary,
      "schema_contract",
      "contact_allocation_provider_reservation_request_summary.v1"
    )
    |> expect_equal(
      callbacks,
      path,
      summary,
      "model",
      "artifact_only_contact_allocation_provider_reservation_request_summary"
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
    |> expect_non_negative_integer(
      callbacks,
      path,
      summary,
      "provider_reservation_candidate_contact_count"
    )
    |> expect_non_negative_integer(
      callbacks,
      path,
      summary,
      "provider_reservation_request_contact_count"
    )
    |> expect_non_negative_integer(
      callbacks,
      path,
      summary,
      "provider_reservation_review_contact_count"
    )
    |> expect_non_negative_integer(
      callbacks,
      path,
      summary,
      "provider_reservation_no_request_contact_count"
    )
    |> expect_one_of(
      callbacks,
      path,
      summary,
      "provider_reservation_request_status",
      @request_statuses
    )
    |> validate_field_types(callbacks, path, summary)
    |> expect_type(callbacks, path, summary, "rows", :list)
    |> validate_rows(
      callbacks,
      path <> ".rows",
      Map.get(summary, "rows", []),
      fn acc, row_path, row -> validate_contact_allocation_row(acc, callbacks, row_path, row) end
    )
    |> expect_type(callbacks, path, summary, "provider_reservation_request_rows", :list)
    |> validate_rows(
      callbacks,
      path <> ".provider_reservation_request_rows",
      Map.get(summary, "provider_reservation_request_rows", []),
      fn acc, row_path, row -> validate_contact_allocation_row(acc, callbacks, row_path, row) end
    )
    |> expect_type(callbacks, path, summary, "provider_reservation_review_rows", :list)
    |> validate_rows(
      callbacks,
      path <> ".provider_reservation_review_rows",
      Map.get(summary, "provider_reservation_review_rows", []),
      fn acc, row_path, row -> validate_contact_allocation_row(acc, callbacks, row_path, row) end
    )
    |> expect_type(callbacks, path, summary, "assumptions", :map)
    |> validate_assumptions(callbacks, path, summary)
    |> validate_counts(callbacks, path, summary)
  end

  defp validate_field_types(issues, callbacks, path, summary) do
    issues
    |> expect_type(callbacks, path, summary, "provider_reservation_request_contact_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".provider_reservation_request_contact_ids",
      Map.get(summary, "provider_reservation_request_contact_ids")
    )
    |> expect_type(callbacks, path, summary, "provider_reservation_review_contact_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".provider_reservation_review_contact_ids",
      Map.get(summary, "provider_reservation_review_contact_ids")
    )
    |> expect_type(callbacks, path, summary, "provider_reservation_no_request_contact_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".provider_reservation_no_request_contact_ids",
      Map.get(summary, "provider_reservation_no_request_contact_ids")
    )
    |> expect_type(
      callbacks,
      path,
      summary,
      "provider_reservation_request_contact_ids_by_ground_station_id",
      :map
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".provider_reservation_request_contact_ids_by_ground_station_id",
      Map.get(summary, "provider_reservation_request_contact_ids_by_ground_station_id")
    )
    |> expect_type(
      callbacks,
      path,
      summary,
      "provider_reservation_review_contact_ids_by_ground_station_id",
      :map
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".provider_reservation_review_contact_ids_by_ground_station_id",
      Map.get(summary, "provider_reservation_review_contact_ids_by_ground_station_id")
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      summary,
      "provider_reservation_no_request_contact_ids_by_direction"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      summary,
      "provider_reservation_request_contact_ids_by_direction"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      summary,
      "provider_reservation_review_contact_ids_by_direction"
    )
    |> validate_nested_stable_id_array_map(
      callbacks,
      path <> ".provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id",
      Map.get(
        summary,
        "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id"
      )
    )
    |> validate_nested_stable_id_array_map(
      callbacks,
      path <> ".provider_reservation_request_contact_ids_by_direction_and_ground_station_id",
      Map.get(
        summary,
        "provider_reservation_request_contact_ids_by_direction_and_ground_station_id"
      )
    )
    |> validate_nested_stable_id_array_map(
      callbacks,
      path <> ".provider_reservation_review_contact_ids_by_direction_and_ground_station_id",
      Map.get(
        summary,
        "provider_reservation_review_contact_ids_by_direction_and_ground_station_id"
      )
    )
    |> expect_type(
      callbacks,
      path,
      summary,
      "provider_reservation_request_contact_ids_by_match_status",
      :map
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".provider_reservation_request_contact_ids_by_match_status",
      Map.get(summary, "provider_reservation_request_contact_ids_by_match_status")
    )
    |> expect_type(
      callbacks,
      path,
      summary,
      "provider_reservation_review_contact_ids_by_match_status",
      :map
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".provider_reservation_review_contact_ids_by_match_status",
      Map.get(summary, "provider_reservation_review_contact_ids_by_match_status")
    )
    |> expect_type(
      callbacks,
      path,
      summary,
      "provider_reservation_request_ids_by_match_status",
      :map
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".provider_reservation_request_ids_by_match_status",
      Map.get(summary, "provider_reservation_request_ids_by_match_status")
    )
    |> expect_type(
      callbacks,
      path,
      summary,
      "provider_reservation_review_ids_by_match_status",
      :map
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".provider_reservation_review_ids_by_match_status",
      Map.get(summary, "provider_reservation_review_ids_by_match_status")
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
          "provider_reservation_execution",
          "not_performed_by_summary"
        )
        |> expect_equal(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "operator_authority",
          "not_granted_by_provider_reservation_request_summary"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "provider_reservation_request_statuses",
          contact_allocation_provider_reservation_request_statuses(callbacks),
          "must match ContactAllocation provider reservation request statuses"
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

    candidate_rows = Enum.filter(rows, &provider_reservation_candidate_row?(callbacks, &1))

    request_rows =
      Enum.filter(candidate_rows, &provider_reservation_request_ready_row?(callbacks, &1))

    review_rows =
      Enum.reject(candidate_rows, &provider_reservation_request_ready_row?(callbacks, &1))

    no_request_rows = Enum.reject(rows, &provider_reservation_candidate_row?(callbacks, &1))

    issues
    |> expect_field_equals(callbacks, path, summary, "input_contact_count", length(rows))
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "provider_reservation_candidate_contact_count",
      length(candidate_rows),
      "must equal row-derived provider_reservation_candidate_contact_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "provider_reservation_request_contact_count",
      length(request_rows),
      "must equal row-derived provider_reservation_request_contact_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "provider_reservation_review_contact_count",
      length(review_rows),
      "must equal row-derived provider_reservation_review_contact_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "provider_reservation_no_request_contact_count",
      length(no_request_rows),
      "must equal row-derived provider_reservation_no_request_contact_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "provider_reservation_request_status",
      provider_reservation_request_status(request_rows, review_rows)
    )
    |> validate_id_fields(
      callbacks,
      path,
      summary,
      request_rows,
      review_rows,
      no_request_rows
    )
  end

  defp validate_id_fields(
         issues,
         callbacks,
         path,
         summary,
         request_rows,
         review_rows,
         no_request_rows
       ) do
    issues
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "provider_reservation_request_contact_ids",
      contact_allocation_row_contact_ids(callbacks, request_rows),
      "must equal row-derived provider_reservation_request_contact_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "provider_reservation_review_contact_ids",
      contact_allocation_row_contact_ids(callbacks, review_rows),
      "must equal row-derived provider_reservation_review_contact_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "provider_reservation_no_request_contact_ids",
      contact_allocation_row_contact_ids(callbacks, no_request_rows),
      "must equal row-derived provider_reservation_no_request_contact_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "provider_reservation_request_contact_ids_by_ground_station_id",
      row_ids_by_field(request_rows, "ground_station_id", "contact_id"),
      "must equal row-derived provider_reservation_request_contact_ids_by_ground_station_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "provider_reservation_review_contact_ids_by_ground_station_id",
      row_ids_by_field(review_rows, "ground_station_id", "contact_id"),
      "must equal row-derived provider_reservation_review_contact_ids_by_ground_station_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "provider_reservation_no_request_contact_ids_by_direction",
      row_ids_by_field(no_request_rows, "direction", "contact_id"),
      "must equal row-derived provider_reservation_no_request_contact_ids_by_direction"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "provider_reservation_request_contact_ids_by_direction",
      row_ids_by_field(request_rows, "direction", "contact_id"),
      "must equal row-derived provider_reservation_request_contact_ids_by_direction"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "provider_reservation_review_contact_ids_by_direction",
      row_ids_by_field(review_rows, "direction", "contact_id"),
      "must equal row-derived provider_reservation_review_contact_ids_by_direction"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id",
      row_ids_by_direction_and_ground_station(no_request_rows, "contact_id"),
      "must equal row-derived provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "provider_reservation_request_contact_ids_by_direction_and_ground_station_id",
      row_ids_by_direction_and_ground_station(request_rows, "contact_id"),
      "must equal row-derived provider_reservation_request_contact_ids_by_direction_and_ground_station_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "provider_reservation_review_contact_ids_by_direction_and_ground_station_id",
      row_ids_by_direction_and_ground_station(review_rows, "contact_id"),
      "must equal row-derived provider_reservation_review_contact_ids_by_direction_and_ground_station_id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "provider_reservation_request_contact_ids_by_match_status",
      row_ids_by_field(request_rows, "station_reservation_match_status", "contact_id"),
      "must equal row-derived provider_reservation_request_contact_ids_by_match_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "provider_reservation_review_contact_ids_by_match_status",
      row_ids_by_field(review_rows, "station_reservation_match_status", "contact_id"),
      "must equal row-derived provider_reservation_review_contact_ids_by_match_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "provider_reservation_request_ids_by_match_status",
      row_ids_by_field(
        request_rows,
        "station_reservation_match_status",
        "station_reservation_id"
      ),
      "must equal row-derived provider_reservation_request_ids_by_match_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "provider_reservation_review_ids_by_match_status",
      row_ids_by_field(review_rows, "station_reservation_match_status", "station_reservation_id"),
      "must equal row-derived provider_reservation_review_ids_by_match_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "provider_reservation_request_rows",
      request_rows,
      "must equal row-derived provider_reservation_request_rows"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "provider_reservation_review_rows",
      review_rows,
      "must equal row-derived provider_reservation_review_rows"
    )
  end

  defp provider_reservation_candidate_row?(callbacks, row) do
    Map.get(row, "allocation_status") == "allocated" and
      Map.get(row, "effective_allocation_status") in [nil, "allocated"] and
      contact_allocation_reservation_expiration_row?(callbacks, row)
  end

  defp provider_reservation_request_ready_row?(callbacks, row) do
    Map.get(row, "station_reservation_match_status") in @request_ready_match_statuses and
      contact_allocation_reservation_ids(callbacks, row) != []
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

  defp validate_optional_stable_id_array_map(issues, callbacks, path, map, field) do
    issues
    |> expect_optional_type(callbacks, path, map, field, :map)
    |> validate_stable_id_array_map(callbacks, path <> ".#{field}", Map.get(map, field))
  end

  defp contact_allocation_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_model_limits), [])

  defp contact_allocation_provider_reservation_request_statuses(callbacks) do
    apply(
      Keyword.fetch!(callbacks, :contact_allocation_provider_reservation_request_statuses),
      []
    )
  end

  defp contact_allocation_station_reservation_match_statuses(callbacks),
    do:
      apply(Keyword.fetch!(callbacks, :contact_allocation_station_reservation_match_statuses), [])

  defp contact_allocation_provider_direction_aliases(callbacks),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_provider_direction_aliases), [])

  defp validate_contact_allocation_row(issues, callbacks, path, row),
    do: apply(Keyword.fetch!(callbacks, :validate_contact_allocation_row), [issues, path, row])

  defp contact_allocation_row_contact_ids(callbacks, rows),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_row_contact_ids), [rows])

  defp contact_allocation_reservation_expiration_row?(callbacks, row),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_reservation_expiration_row?), [row])

  defp contact_allocation_reservation_ids(callbacks, row),
    do: apply(Keyword.fetch!(callbacks, :contact_allocation_reservation_ids), [row])
end
