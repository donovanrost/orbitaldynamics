defmodule OrbitalDynamics.Schema.StationReservationReportContracts do
  @moduledoc false

  def validate(issues, path, report, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(callbacks, path, report, "schema_contract", "station_reservation_report.v1")
    |> expect_equal(callbacks, path, report, "schema_version", 1)
    |> expect_one_of(
      callbacks,
      path,
      report,
      "model",
      station_reservation_report_models(callbacks)
    )
    |> expect_type(callbacks, path, report, "source", :binary)
    |> expect_non_negative_integer(callbacks, path, report, "affected_contact_reservation_count")
    |> expect_non_negative_integer(
      callbacks,
      path,
      report,
      "provider_calendar_contention_group_count"
    )
    |> expect_non_negative_integer(callbacks, path, report, "reservation_review_count")
    |> expect_one_of(callbacks, path, report, "reservation_review_status", [
      "clear",
      "review_required"
    ])
    |> expect_type(callbacks, path, report, "station_reservation_match_status_counts", :map)
    |> expect_type(callbacks, path, report, "reservation_status_counts", :map)
    |> expect_type(callbacks, path, report, "reservation_ids", :list)
    |> expect_optional_type(callbacks, path, report, "reservation_ids_by_status", :map)
    |> expect_optional_type(callbacks, path, report, "reservation_ids_by_match_status", :map)
    |> validate_stable_id_array_map(
      callbacks,
      "#{path}.reservation_ids_by_status",
      Map.get(report, "reservation_ids_by_status")
    )
    |> validate_stable_id_array_map(
      callbacks,
      "#{path}.reservation_ids_by_match_status",
      Map.get(report, "reservation_ids_by_match_status")
    )
    |> expect_type(callbacks, path, report, "affected_contacts", :list)
    |> expect_type(callbacks, path, report, "provider_calendar_contention_groups", :list)
    |> expect_type(callbacks, path, report, "assumptions", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      "#{path}.station_reservation_match_status_counts",
      Map.get(report, "station_reservation_match_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      "#{path}.reservation_status_counts",
      Map.get(report, "reservation_status_counts")
    )
    |> validate_optional_stable_id_list(callbacks, path, report, "reservation_ids")
    |> validate_rows(
      callbacks,
      "#{path}.affected_contacts",
      Map.get(report, "affected_contacts", []),
      fn acc, row_path, row ->
        validate_station_reservation_contact(callbacks, acc, row_path, row)
      end
    )
    |> validate_rows(
      callbacks,
      "#{path}.provider_calendar_contention_groups",
      Map.get(report, "provider_calendar_contention_groups", []),
      fn acc, row_path, row ->
        validate_station_reservation_provider_contention_group(callbacks, acc, row_path, row)
      end
    )
    |> validate_station_reservation_report_counts(callbacks, path, report)
  end

  defp validate_station_reservation_contact(callbacks, issues, path, contact) do
    issues
    |> validate_stable_ids(callbacks, path, contact, [
      "id",
      "contact_id",
      "ground_station_id",
      "station_calendar_entry_id",
      "station_calendar_provider_id",
      "station_calendar_provider_entry_id",
      "station_reservation_id"
    ])
    |> expect_optional_number(callbacks, path, contact, "starts_at_s")
    |> expect_optional_number(callbacks, path, contact, "ends_at_s")
    |> expect_optional_number(callbacks, path, contact, "overlap_starts_at_s")
    |> expect_optional_number(callbacks, path, contact, "overlap_ends_at_s")
    |> expect_optional_number(callbacks, path, contact, "overlap_duration_s")
    |> expect_optional_type(callbacks, path, contact, "station_contention_status", :binary)
    |> expect_optional_type(callbacks, path, contact, "station_reservation_match_status", :binary)
    |> expect_optional_type(callbacks, path, contact, "station_reserved_by", :binary)
    |> expect_optional_type(callbacks, path, contact, "station_reservation_status", :binary)
    |> expect_optional_number(callbacks, path, contact, "station_reservation_expires_at_s")
    |> expect_optional_integer(
      callbacks,
      path,
      contact,
      "station_calendar_reservation_overlap_count"
    )
    |> expect_field_at_least(
      callbacks,
      path,
      contact,
      "station_calendar_reservation_overlap_count",
      0
    )
    |> expect_optional_type(callbacks, path, contact, "station_calendar_reservation_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      contact,
      "station_calendar_reservation_ids"
    )
    |> expect_optional_type(callbacks, path, contact, "station_calendar_reserved_by", :list)
    |> validate_string_list_items(callbacks, path, contact, "station_calendar_reserved_by")
    |> expect_optional_type(
      callbacks,
      path,
      contact,
      "station_calendar_reservation_statuses",
      :list
    )
    |> validate_string_list_items(
      callbacks,
      path,
      contact,
      "station_calendar_reservation_statuses"
    )
    |> expect_optional_type(
      callbacks,
      path,
      contact,
      "station_calendar_reservation_expires_at_s",
      :list
    )
    |> validate_number_list_items(
      callbacks,
      path,
      contact,
      "station_calendar_reservation_expires_at_s"
    )
    |> expect_optional_type(callbacks, path, contact, "required_operator_action", :binary)
    |> expect_optional_type(callbacks, path, contact, "operator_action_reason", :binary)
    |> expect_optional_one_of(callbacks, path, contact, "approval_status", [
      "auto_approvable",
      "operator_review_required",
      "blocked_by_policy"
    ])
    |> expect_optional_type(callbacks, path, contact, "approval_requirements", :list)
    |> expect_optional_type(callbacks, path, contact, "approval_rule_matches", :list)
  end

  defp validate_station_reservation_provider_contention_group(callbacks, issues, path, group) do
    issues
    |> validate_stable_ids(callbacks, path, group, ["id", "ground_station_id"])
    |> expect_optional_one_of(
      callbacks,
      path,
      group,
      "provider_calendar_contention_status",
      ["provider_calendar_overlap"]
    )
    |> expect_optional_one_of(
      callbacks,
      path,
      group,
      "required_operator_action",
      ["review_station_provider_contention"]
    )
    |> expect_optional_one_of(callbacks, path, group, "approval_status", [
      "auto_approvable",
      "operator_review_required",
      "blocked_by_policy"
    ])
    |> expect_optional_number(callbacks, path, group, "starts_at_s")
    |> expect_optional_number(callbacks, path, group, "ends_at_s")
    |> expect_optional_number(callbacks, path, group, "overlap_duration_s")
    |> expect_optional_non_negative_integer(callbacks, path, group, "entry_count")
    |> expect_optional_type(callbacks, path, group, "entry_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, group, "entry_ids")
    |> expect_optional_type(callbacks, path, group, "provider_ids", :list)
    |> validate_string_list_items(callbacks, path, group, "provider_ids")
    |> expect_optional_type(callbacks, path, group, "provider_entry_ids", :list)
    |> validate_string_list_items(callbacks, path, group, "provider_entry_ids")
    |> expect_optional_type(callbacks, path, group, "availabilities", :list)
    |> validate_string_list_items(callbacks, path, group, "availabilities")
    |> expect_optional_type(callbacks, path, group, "directions", :list)
    |> validate_string_list_items(callbacks, path, group, "directions")
    |> expect_optional_type(callbacks, path, group, "reservation_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, group, "reservation_ids")
    |> expect_optional_type(callbacks, path, group, "reserved_by", :list)
    |> validate_string_list_items(callbacks, path, group, "reserved_by")
    |> expect_optional_type(callbacks, path, group, "reservation_statuses", :list)
    |> validate_string_list_items(callbacks, path, group, "reservation_statuses")
    |> expect_optional_type(callbacks, path, group, "reservation_expires_at_s", :list)
    |> validate_number_list_items(callbacks, path, group, "reservation_expires_at_s")
    |> validate_provider_calendar_contention_entry_count(callbacks, path, group)
  end

  defp validate_station_reservation_report_counts(issues, callbacks, path, report) do
    affected_contacts =
      report
      |> Map.get("affected_contacts", [])
      |> Enum.filter(&is_map/1)

    provider_groups =
      report
      |> Map.get("provider_calendar_contention_groups", [])
      |> Enum.filter(&is_map/1)

    review_count = length(affected_contacts) + length(provider_groups)
    review_status = if(review_count == 0, do: "clear", else: "review_required")

    issues
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "affected_contact_reservation_count",
      length(affected_contacts)
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "provider_calendar_contention_group_count",
      length(provider_groups)
    )
    |> expect_field_equals(callbacks, path, report, "reservation_review_count", review_count)
    |> expect_field_equals(callbacks, path, report, "reservation_review_status", review_status)
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "station_reservation_match_status_counts",
      frequency_map(callbacks, affected_contacts, "station_reservation_match_status"),
      "must equal row-derived station_reservation_match_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "reservation_status_counts",
      station_reservation_status_counts(affected_contacts, provider_groups),
      "must equal row-derived reservation_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "reservation_ids",
      station_reservation_ids(affected_contacts, provider_groups),
      "must equal row-derived reservation_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "reservation_ids_by_status",
      station_reservation_ids_by_status(affected_contacts, provider_groups),
      "must equal row-derived reservation_ids_by_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "reservation_ids_by_match_status",
      station_reservation_ids_by_match_status(affected_contacts),
      "must equal row-derived reservation_ids_by_match_status"
    )
  end

  defp station_reservation_status_counts(affected_contacts, provider_groups) do
    affected_statuses =
      Enum.flat_map(affected_contacts, fn row ->
        [
          Map.get(row, "station_reservation_status")
          | list_or_empty(Map.get(row, "station_calendar_reservation_statuses"))
        ]
      end)

    provider_statuses =
      Enum.flat_map(provider_groups, &list_or_empty(Map.get(&1, "reservation_statuses")))

    (affected_statuses ++ provider_statuses)
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp station_reservation_ids(affected_contacts, provider_groups) do
    affected_ids =
      Enum.flat_map(affected_contacts, fn row ->
        [
          Map.get(row, "station_reservation_id")
          | list_or_empty(Map.get(row, "station_calendar_reservation_ids"))
        ]
      end)

    provider_ids = Enum.flat_map(provider_groups, &list_or_empty(Map.get(&1, "reservation_ids")))

    (affected_ids ++ provider_ids)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp station_reservation_ids_by_status(affected_contacts, provider_groups) do
    affected_pairs =
      Enum.flat_map(affected_contacts, fn row ->
        reservation_id_value_pairs(
          List.wrap(Map.get(row, "station_reservation_id")),
          List.wrap(Map.get(row, "station_reservation_status"))
        ) ++
          reservation_id_value_pairs(
            Map.get(row, "station_calendar_reservation_ids"),
            Map.get(row, "station_calendar_reservation_statuses")
          )
      end)

    provider_pairs =
      Enum.flat_map(provider_groups, fn group ->
        reservation_id_value_pairs(
          Map.get(group, "reservation_ids"),
          Map.get(group, "reservation_statuses")
        )
      end)

    reservation_id_pairs_to_map(affected_pairs ++ provider_pairs)
  end

  defp station_reservation_ids_by_match_status(affected_contacts) do
    affected_contacts
    |> Enum.flat_map(fn row ->
      reservation_id_value_pairs(
        [
          Map.get(row, "station_reservation_id")
          | list_or_empty(Map.get(row, "station_calendar_reservation_ids"))
        ],
        List.wrap(Map.get(row, "station_reservation_match_status"))
      )
    end)
    |> reservation_id_pairs_to_map()
  end

  defp reservation_id_value_pairs(ids, values) do
    ids = List.wrap(ids) |> Enum.reject(&is_nil/1)
    values = List.wrap(values) |> Enum.reject(&is_nil/1)

    cond do
      ids == [] or values == [] ->
        []

      length(values) == 1 ->
        Enum.map(ids, &{List.first(values), &1})

      true ->
        Enum.zip(values, ids)
    end
  end

  defp reservation_id_pairs_to_map(pairs) do
    pairs
    |> Enum.group_by(fn {value, _id} -> to_string(value) end, fn {_value, id} -> id end)
    |> Enum.reject(fn {value, ids} -> value == "" or ids == [] end)
    |> Map.new(fn {value, ids} ->
      {
        value,
        ids
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()
        |> Enum.sort()
      }
    end)
  end

  defp list_or_empty(values) when is_list(values), do: values
  defp list_or_empty(_values), do: []

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp station_reservation_report_models(callbacks),
    do: apply(require_callback(callbacks, :station_reservation_report_models), [])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(require_callback(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(require_callback(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_optional_one_of(issues, callbacks, path, map, field, allowed),
    do:
      apply(require_callback(callbacks, :expect_optional_one_of), [
        issues,
        path,
        map,
        field,
        allowed
      ])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(require_callback(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_non_negative_integer), [issues, path, map, field])

  defp expect_optional_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_optional_number(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_optional_number), [issues, path, map, field])

  defp expect_optional_integer(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_optional_integer), [issues, path, map, field])

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

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp validate_stable_id_array_map(issues, callbacks, path, values),
    do: apply(require_callback(callbacks, :validate_stable_id_array_map), [issues, path, values])

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_optional_stable_id_list), [
        issues,
        path,
        map,
        field
      ])

  defp validate_non_negative_integer_count_map(issues, callbacks, path, values),
    do:
      apply(require_callback(callbacks, :validate_non_negative_integer_count_map), [
        issues,
        path,
        values
      ])

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(require_callback(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_number_list_items(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_number_list_items), [
        issues,
        path,
        map,
        field
      ])

  defp validate_provider_calendar_contention_entry_count(issues, callbacks, path, group),
    do:
      apply(require_callback(callbacks, :validate_provider_calendar_contention_entry_count), [
        issues,
        path,
        group
      ])

  defp frequency_map(callbacks, rows, field),
    do: apply(require_callback(callbacks, :frequency_map), [rows, field])
end
