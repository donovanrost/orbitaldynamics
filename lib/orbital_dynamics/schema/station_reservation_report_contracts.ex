defmodule OrbitalDynamics.Schema.StationReservationReportContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionAggregation, only: [frequency_map: 2]
  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_field_at_least: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_one_of: 5,
      expect_optional_integer: 4,
      expect_optional_non_negative_integer: 4,
      expect_optional_number: 4,
      expect_optional_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_number_list_items: 4,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_optional_stable_id_list: 4,
      validate_stable_id_array_map: 3,
      validate_stable_ids: 4
    ]

  def validate(issues, path, report, report_models) do
    issues
    |> expect_equal(path, report, "schema_contract", "station_reservation_report.v1")
    |> expect_equal(path, report, "schema_version", 1)
    |> expect_one_of(
      path,
      report,
      "model",
      report_models
    )
    |> expect_type(path, report, "source", :binary)
    |> expect_non_negative_integer(path, report, "affected_contact_reservation_count")
    |> expect_non_negative_integer(
      path,
      report,
      "provider_calendar_contention_group_count"
    )
    |> expect_non_negative_integer(path, report, "reservation_review_count")
    |> expect_one_of(path, report, "reservation_review_status", [
      "clear",
      "review_required"
    ])
    |> expect_type(path, report, "station_reservation_match_status_counts", :map)
    |> expect_type(path, report, "reservation_status_counts", :map)
    |> expect_type(path, report, "reservation_ids", :list)
    |> expect_optional_type(path, report, "reservation_ids_by_status", :map)
    |> expect_optional_type(path, report, "reservation_ids_by_match_status", :map)
    |> validate_stable_id_array_map(
      "#{path}.reservation_ids_by_status",
      Map.get(report, "reservation_ids_by_status")
    )
    |> validate_stable_id_array_map(
      "#{path}.reservation_ids_by_match_status",
      Map.get(report, "reservation_ids_by_match_status")
    )
    |> expect_type(path, report, "affected_contacts", :list)
    |> expect_type(path, report, "provider_calendar_contention_groups", :list)
    |> expect_type(path, report, "assumptions", :map)
    |> validate_non_negative_integer_count_map(
      "#{path}.station_reservation_match_status_counts",
      Map.get(report, "station_reservation_match_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      "#{path}.reservation_status_counts",
      Map.get(report, "reservation_status_counts")
    )
    |> validate_optional_stable_id_list(path, report, "reservation_ids")
    |> validate_rows(
      "#{path}.affected_contacts",
      Map.get(report, "affected_contacts", []),
      fn acc, row_path, row ->
        validate_station_reservation_contact(acc, row_path, row)
      end
    )
    |> validate_rows(
      "#{path}.provider_calendar_contention_groups",
      Map.get(report, "provider_calendar_contention_groups", []),
      fn acc, row_path, row ->
        validate_station_reservation_provider_contention_group(acc, row_path, row)
      end
    )
    |> validate_station_reservation_report_counts(path, report)
  end

  defp validate_station_reservation_contact(issues, path, contact) do
    issues
    |> validate_stable_ids(path, contact, [
      "id",
      "contact_id",
      "ground_station_id",
      "station_calendar_entry_id",
      "station_calendar_provider_id",
      "station_calendar_provider_entry_id",
      "station_reservation_id"
    ])
    |> expect_optional_number(path, contact, "starts_at_s")
    |> expect_optional_number(path, contact, "ends_at_s")
    |> expect_optional_number(path, contact, "overlap_starts_at_s")
    |> expect_optional_number(path, contact, "overlap_ends_at_s")
    |> expect_optional_number(path, contact, "overlap_duration_s")
    |> expect_optional_type(path, contact, "station_contention_status", :binary)
    |> expect_optional_type(path, contact, "station_reservation_match_status", :binary)
    |> expect_optional_type(path, contact, "station_reserved_by", :binary)
    |> expect_optional_type(path, contact, "station_reservation_status", :binary)
    |> expect_optional_number(path, contact, "station_reservation_expires_at_s")
    |> expect_optional_integer(
      path,
      contact,
      "station_calendar_reservation_overlap_count"
    )
    |> expect_field_at_least(
      path,
      contact,
      "station_calendar_reservation_overlap_count",
      0
    )
    |> expect_optional_type(path, contact, "station_calendar_reservation_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      contact,
      "station_calendar_reservation_ids"
    )
    |> expect_optional_type(path, contact, "station_calendar_reserved_by", :list)
    |> validate_string_list_items(path, contact, "station_calendar_reserved_by")
    |> expect_optional_type(
      path,
      contact,
      "station_calendar_reservation_statuses",
      :list
    )
    |> validate_string_list_items(
      path,
      contact,
      "station_calendar_reservation_statuses"
    )
    |> expect_optional_type(
      path,
      contact,
      "station_calendar_reservation_expires_at_s",
      :list
    )
    |> validate_number_list_items(
      path,
      contact,
      "station_calendar_reservation_expires_at_s"
    )
    |> expect_optional_type(path, contact, "required_operator_action", :binary)
    |> expect_optional_type(path, contact, "operator_action_reason", :binary)
    |> expect_optional_one_of(path, contact, "approval_status", [
      "auto_approvable",
      "operator_review_required",
      "blocked_by_policy"
    ])
    |> expect_optional_type(path, contact, "approval_requirements", :list)
    |> expect_optional_type(path, contact, "approval_rule_matches", :list)
  end

  defp validate_station_reservation_provider_contention_group(issues, path, group) do
    issues
    |> validate_stable_ids(path, group, ["id", "ground_station_id"])
    |> expect_optional_one_of(
      path,
      group,
      "provider_calendar_contention_status",
      ["provider_calendar_overlap"]
    )
    |> expect_optional_one_of(
      path,
      group,
      "required_operator_action",
      ["review_station_provider_contention"]
    )
    |> expect_optional_one_of(path, group, "approval_status", [
      "auto_approvable",
      "operator_review_required",
      "blocked_by_policy"
    ])
    |> expect_optional_number(path, group, "starts_at_s")
    |> expect_optional_number(path, group, "ends_at_s")
    |> expect_optional_number(path, group, "overlap_duration_s")
    |> expect_optional_non_negative_integer(path, group, "entry_count")
    |> expect_optional_type(path, group, "entry_ids", :list)
    |> validate_optional_stable_id_list(path, group, "entry_ids")
    |> expect_optional_type(path, group, "provider_ids", :list)
    |> validate_string_list_items(path, group, "provider_ids")
    |> expect_optional_type(path, group, "provider_entry_ids", :list)
    |> validate_string_list_items(path, group, "provider_entry_ids")
    |> expect_optional_type(path, group, "availabilities", :list)
    |> validate_string_list_items(path, group, "availabilities")
    |> expect_optional_type(path, group, "directions", :list)
    |> validate_string_list_items(path, group, "directions")
    |> expect_optional_type(path, group, "reservation_ids", :list)
    |> validate_optional_stable_id_list(path, group, "reservation_ids")
    |> expect_optional_type(path, group, "reserved_by", :list)
    |> validate_string_list_items(path, group, "reserved_by")
    |> expect_optional_type(path, group, "reservation_statuses", :list)
    |> validate_string_list_items(path, group, "reservation_statuses")
    |> expect_optional_type(path, group, "reservation_expires_at_s", :list)
    |> validate_number_list_items(path, group, "reservation_expires_at_s")
    |> validate_provider_calendar_contention_entry_count(path, group)
  end

  defp validate_station_reservation_report_counts(issues, path, report) do
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
      path,
      report,
      "affected_contact_reservation_count",
      length(affected_contacts)
    )
    |> expect_field_equals(
      path,
      report,
      "provider_calendar_contention_group_count",
      length(provider_groups)
    )
    |> expect_field_equals(path, report, "reservation_review_count", review_count)
    |> expect_field_equals(path, report, "reservation_review_status", review_status)
    |> expect_field_equals(
      path,
      report,
      "station_reservation_match_status_counts",
      frequency_map(affected_contacts, "station_reservation_match_status"),
      "must equal row-derived station_reservation_match_status_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "reservation_status_counts",
      station_reservation_status_counts(affected_contacts, provider_groups),
      "must equal row-derived reservation_status_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "reservation_ids",
      station_reservation_ids(affected_contacts, provider_groups),
      "must equal row-derived reservation_ids"
    )
    |> expect_field_equals(
      path,
      report,
      "reservation_ids_by_status",
      station_reservation_ids_by_status(affected_contacts, provider_groups),
      "must equal row-derived reservation_ids_by_status"
    )
    |> expect_field_equals(
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

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")

  defp validate_provider_calendar_contention_entry_count(issues, path, group),
    do:
      OrbitalDynamics.Schema.StationCalendarProviderContentionContracts.validate_entry_count(
        issues,
        path,
        group
      )
end
