defmodule OrbitalDynamics.Schema.StationCalendarReportContracts do
  @moduledoc false

  def validate_optional_report(issues, _path, nil, _callbacks), do: issues

  def validate_optional_report(issues, path, %{} = report, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, report, [
      "schema_contract",
      "model",
      "input_contact_count",
      "calendar_entry_count",
      "affected_contact_count",
      "affected_contacts"
    ])
    |> expect_equal(callbacks, path, report, "schema_contract", "station_calendar_report.v1")
    |> expect_equal(callbacks, path, report, "model", station_calendar_report_model(callbacks))
    |> expect_non_negative_integer(callbacks, path, report, "input_contact_count")
    |> expect_non_negative_integer(callbacks, path, report, "calendar_entry_count")
    |> expect_non_negative_integer(callbacks, path, report, "affected_contact_count")
    |> expect_optional_number(callbacks, path, report, "affected_duration_s")
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "calendar_entry_trust_boundary_status_counts",
      :map
    )
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "affected_contact_ground_station_counts",
      :map
    )
    |> expect_optional_type(callbacks, path, report, "affected_contact_availability_counts", :map)
    |> expect_optional_type(callbacks, path, report, "direction_counts", :map)
    |> expect_optional_type(callbacks, path, report, "station_calendar_status_counts", :map)
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "provider_counteroffer_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "duplicate_affected_contact_id_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "duplicate_affected_contact_row_count"
    )
    |> expect_optional_type(callbacks, path, report, "model_limits", :list)
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "provider_calendar_contention_group_count"
    )
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "station_calendar_trust_boundary_status_counts",
      :map
    )
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "station_reservation_match_status_counts",
      :map
    )
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "affected_contact_ids_by_reservation_match_status",
      :map
    )
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "affected_contact_ids_by_station_calendar_trust_boundary_status",
      :map
    )
    |> expect_type(callbacks, path, report, "affected_contacts", :list)
    |> expect_optional_type(callbacks, path, report, "provider_calendar_contention_groups", :list)
    |> expect_optional_type(callbacks, path, report, "assumptions", :map)
    |> validate_string_list_items(callbacks, path, report, "model_limits")
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      report,
      "affected_contact_ids_by_reservation_match_status"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      report,
      "affected_contact_ids_by_station_calendar_trust_boundary_status"
    )
    |> validate_station_calendar_report_model_limits(callbacks, path, report)
    |> validate_rows(
      callbacks,
      "#{path}.affected_contacts",
      Map.get(report, "affected_contacts", []),
      fn acc, row_path, row ->
        validate_station_calendar_contact(callbacks, acc, row_path, row)
      end
    )
    |> validate_optional_rows(
      callbacks,
      "#{path}.provider_calendar_contention_groups",
      Map.get(report, "provider_calendar_contention_groups"),
      fn acc, row_path, row ->
        validate_station_calendar_provider_contention_group(callbacks, acc, row_path, row)
      end
    )
    |> validate_provider_calendar_contention_group_count(callbacks, path, report)
    |> validate_station_calendar_report_count_maps(callbacks, path, report)
    |> validate_station_calendar_report_duplicate_counts(callbacks, path, report)
  end

  def validate_optional_report(issues, path, _report, callbacks) when is_list(callbacks) do
    [error(callbacks, path, "must be an object") | issues]
  end

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :require_fields), [issues, path, map, fields])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(require_callback(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(require_callback(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_one_of(issues, callbacks, path, map, field, values),
    do: apply(require_callback(callbacks, :expect_one_of), [issues, path, map, field, values])

  defp expect_optional_one_of(issues, callbacks, path, map, field, values),
    do:
      apply(require_callback(callbacks, :expect_optional_one_of), [
        issues,
        path,
        map,
        field,
        values
      ])

  defp expect_number(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_number), [issues, path, map, field])

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

  defp expect_optional_probability(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_probability), [
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

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_optional_stable_id_list), [
        issues,
        path,
        map,
        field
      ])

  defp validate_optional_string_lists(issues, callbacks, path, map, fields),
    do:
      apply(require_callback(callbacks, :validate_optional_string_lists), [
        issues,
        path,
        map,
        fields
      ])

  defp validate_number_list_items(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_number_list_items), [
        issues,
        path,
        map,
        field
      ])

  defp validate_string_list_allowed(issues, callbacks, path, map, field, values),
    do:
      apply(require_callback(callbacks, :validate_string_list_allowed), [
        issues,
        path,
        map,
        field,
        values
      ])

  defp validate_optional_stable_id_array_map(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_optional_stable_id_array_map), [
        issues,
        path,
        map,
        field
      ])

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(require_callback(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_optional_rows(issues, callbacks, path, rows, validator),
    do:
      apply(require_callback(callbacks, :validate_optional_rows), [issues, path, rows, validator])

  defp station_calendar_report_model(callbacks),
    do: apply(require_callback(callbacks, :station_calendar_report_model), [])

  defp station_calendar_report_model_limits(callbacks),
    do: apply(require_callback(callbacks, :station_calendar_report_model_limits), [])

  defp validate_station_calendar_report_model_limits(issues, callbacks, path, report) do
    case Map.get(report, "model_limits") do
      nil ->
        issues

      :null ->
        issues

      limits when is_list(limits) ->
        if limits == station_calendar_report_model_limits(callbacks) do
          issues
        else
          [
            error(
              callbacks,
              "#{path}.model_limits",
              "must match station calendar report model limits"
            )
            | issues
          ]
        end

      _value ->
        issues
    end
  end

  defp validate_station_calendar_contact(callbacks, issues, path, contact) do
    issues
    |> require_fields(callbacks, path, contact, [
      "id",
      "contact_id",
      "scenario_id",
      "ground_station_id",
      "station_calendar_entry_id",
      "status",
      "station_availability"
    ])
    |> validate_stable_ids(callbacks, path, contact, [
      "id",
      "contact_id",
      "scenario_id",
      "ground_station_id",
      "station_calendar_entry_id",
      "station_reservation_id"
    ])
    |> validate_stable_ids(callbacks, path, contact, [
      "station_calendar_provider_id",
      "station_calendar_provider_entry_id"
    ])
    |> expect_optional_number(callbacks, path, contact, "overlap_starts_at_s")
    |> expect_optional_number(callbacks, path, contact, "overlap_ends_at_s")
    |> expect_optional_number(callbacks, path, contact, "overlap_duration_s")
    |> expect_optional_probability(callbacks, path, contact, "capacity_fraction")
    |> expect_optional_type(callbacks, path, contact, "contact_type", :binary)
    |> expect_optional_type(callbacks, path, contact, "direction", :binary)
    |> expect_optional_type(callbacks, path, contact, "station_calendar_directions", :list)
    |> validate_string_list_items(callbacks, path, contact, "station_calendar_directions")
    |> expect_optional_integer(callbacks, path, contact, "station_calendar_precedence_rank")
    |> expect_field_at_least(callbacks, path, contact, "station_calendar_precedence_rank", 0)
    |> expect_optional_type(
      callbacks,
      path,
      contact,
      "station_calendar_precedence_availability",
      :binary
    )
    |> expect_optional_type(callbacks, path, contact, "contact_success", :boolean)
    |> expect_optional_type(callbacks, path, contact, "contact_result", :binary)
    |> expect_optional_probability(callbacks, path, contact, "contact_success_factor")
    |> expect_optional_type(callbacks, path, contact, "contact_success_factor_source", :binary)
    |> expect_optional_type(callbacks, path, contact, "command_success", :boolean)
    |> expect_optional_type(callbacks, path, contact, "command_result", :binary)
    |> expect_optional_probability(callbacks, path, contact, "command_success_factor")
    |> expect_optional_type(callbacks, path, contact, "command_success_factor_source", :binary)
    |> expect_optional_integer(callbacks, path, contact, "station_calendar_overlap_count")
    |> expect_field_at_least(callbacks, path, contact, "station_calendar_overlap_count", 0)
    |> expect_optional_type(callbacks, path, contact, "station_calendar_overlap_entry_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      contact,
      "station_calendar_overlap_entry_ids"
    )
    |> expect_optional_type(
      callbacks,
      path,
      contact,
      "station_calendar_overlap_availabilities",
      :list
    )
    |> validate_string_list_items(
      callbacks,
      path,
      contact,
      "station_calendar_overlap_availabilities"
    )
    |> expect_optional_type(
      callbacks,
      path,
      contact,
      "station_calendar_entry_ambiguous",
      :boolean
    )
    |> expect_optional_integer(callbacks, path, contact, "station_calendar_ambiguous_entry_count")
    |> expect_field_at_least(
      callbacks,
      path,
      contact,
      "station_calendar_ambiguous_entry_count",
      0
    )
    |> expect_optional_type(
      callbacks,
      path,
      contact,
      "station_calendar_ambiguous_entry_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      contact,
      "station_calendar_ambiguous_entry_ids"
    )
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
    |> validate_stable_ids(callbacks, path, contact, ["provider_counteroffer_id"])
    |> expect_optional_type(callbacks, path, contact, "provider_counteroffer_status", :binary)
    |> expect_optional_one_of(
      callbacks,
      path,
      contact,
      "provider_counteroffer_negotiation_state",
      provider_counteroffer_negotiation_states()
    )
    |> expect_optional_type(
      callbacks,
      path,
      contact,
      "provider_counteroffer_reason_code",
      :binary
    )
    |> expect_optional_number(callbacks, path, contact, "provider_counteroffer_cost_delta")
    |> expect_optional_number(callbacks, path, contact, "provider_counteroffer_lock_deadline_s")
    |> expect_optional_number(callbacks, path, contact, "provider_counteroffer_starts_at_s")
    |> expect_optional_number(callbacks, path, contact, "provider_counteroffer_ends_at_s")
    |> expect_optional_number(callbacks, path, contact, "provider_counteroffer_start_delta_s")
    |> expect_optional_number(callbacks, path, contact, "provider_counteroffer_end_delta_s")
    |> expect_optional_number(callbacks, path, contact, "provider_counteroffer_duration_delta_s")
    |> expect_optional_one_of(
      callbacks,
      path,
      contact,
      "station_calendar_trust_boundary_status",
      [
        "declared",
        "missing"
      ]
    )
    |> expect_optional_integer(callbacks, path, contact, "duplicate_station_calendar_row_index")
    |> expect_optional_integer(callbacks, path, contact, "duplicate_station_calendar_row_count")
    |> validate_station_calendar_duplicate_evidence(callbacks, path, contact)
    |> expect_optional_type(callbacks, path, contact, "station_contention_status", :binary)
    |> expect_optional_number(callbacks, path, contact, "station_reservation_expires_at_s")
    |> expect_optional_type(callbacks, path, contact, "station_reserved_by", :binary)
    |> expect_optional_type(callbacks, path, contact, "station_reservation_status", :binary)
    |> expect_optional_type(callbacks, path, contact, "station_reservation_match_status", :binary)
    |> expect_optional_type(callbacks, path, contact, "trust_boundary", :binary)
    |> expect_optional_type(callbacks, path, contact, "provenance", :map)
    |> expect_optional_type(callbacks, path, contact, "required_operator_action", :binary)
    |> expect_optional_type(callbacks, path, contact, "operator_action_reason", :binary)
    |> expect_optional_one_of(callbacks, path, contact, "approval_status", [
      "auto_approvable",
      "operator_review_required",
      "blocked_by_policy"
    ])
    |> expect_optional_type(callbacks, path, contact, "approval_requirements", :list)
    |> expect_optional_type(callbacks, path, contact, "approval_rule_matches", :list)
    |> validate_station_calendar_contact_source_entry(callbacks, path, contact)
    |> validate_optional_rows(
      callbacks,
      "#{path}.source_station_calendar_overlaps",
      Map.get(contact, "source_station_calendar_overlaps"),
      fn acc, row_path, entry ->
        validate_station_calendar_report_source_entry(callbacks, acc, row_path, entry)
      end
    )
    |> validate_station_calendar_contact_counts(callbacks, path, contact)
  end

  defp validate_station_calendar_contact_source_entry(issues, callbacks, path, contact) do
    case Map.get(contact, "source_station_calendar_entry") do
      nil ->
        issues

      entry when is_map(entry) ->
        validate_station_calendar_report_source_entry(
          callbacks,
          issues,
          "#{path}.source_station_calendar_entry",
          entry
        )

      _entry ->
        [error(callbacks, "#{path}.source_station_calendar_entry", "must be an object") | issues]
    end
  end

  defp validate_station_calendar_contact_counts(issues, callbacks, path, contact) do
    OrbitalDynamics.Schema.StationCalendarContactCountContracts.validate(
      issues,
      path,
      contact,
      callbacks
    )
  end

  defp validate_station_calendar_report_source_entry(callbacks, issues, path, entry) do
    issues
    |> validate_stable_ids(callbacks, path, entry, [
      "id",
      "ground_station_id",
      "provider_id",
      "provider_entry_id",
      "reservation_id"
    ])
    |> expect_optional_one_of(callbacks, path, entry, "availability", [
      "available",
      "unavailable",
      "reduced_capacity",
      "maintenance",
      "reserved"
    ])
    |> expect_optional_one_of(callbacks, path, entry, "status", [
      "available",
      "unavailable",
      "reduced_capacity",
      "maintenance",
      "reserved",
      "ambiguous"
    ])
    |> expect_optional_probability(callbacks, path, entry, "capacity_fraction")
    |> expect_optional_type(callbacks, path, entry, "reserved_by", :binary)
    |> expect_optional_type(callbacks, path, entry, "reservation_status", :binary)
    |> expect_optional_number(callbacks, path, entry, "reservation_expires_at_s")
    |> validate_stable_ids(callbacks, path, entry, ["provider_counteroffer_id"])
    |> expect_optional_type(callbacks, path, entry, "provider_counteroffer_status", :binary)
    |> expect_optional_one_of(
      callbacks,
      path,
      entry,
      "provider_counteroffer_negotiation_state",
      provider_counteroffer_negotiation_states()
    )
    |> expect_optional_type(callbacks, path, entry, "provider_counteroffer_reason_code", :binary)
    |> expect_optional_number(callbacks, path, entry, "provider_counteroffer_cost_delta")
    |> expect_optional_number(callbacks, path, entry, "provider_counteroffer_lock_deadline_s")
    |> expect_optional_number(callbacks, path, entry, "provider_counteroffer_starts_at_s")
    |> expect_optional_number(callbacks, path, entry, "provider_counteroffer_ends_at_s")
    |> expect_optional_number(callbacks, path, entry, "provider_counteroffer_start_delta_s")
    |> expect_optional_number(callbacks, path, entry, "provider_counteroffer_end_delta_s")
    |> expect_optional_number(callbacks, path, entry, "provider_counteroffer_duration_delta_s")
    |> expect_optional_type(callbacks, path, entry, "directions", :list)
    |> validate_string_list_items(callbacks, path, entry, "directions")
    |> expect_optional_number(callbacks, path, entry, "starts_at_s")
    |> expect_optional_number(callbacks, path, entry, "ends_at_s")
    |> expect_optional_type(callbacks, path, entry, "station_calendar_entry_ambiguous", :boolean)
    |> expect_optional_integer(callbacks, path, entry, "station_calendar_ambiguous_entry_count")
    |> expect_field_at_least(callbacks, path, entry, "station_calendar_ambiguous_entry_count", 0)
    |> expect_optional_type(callbacks, path, entry, "station_calendar_ambiguous_entry_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      entry,
      "station_calendar_ambiguous_entry_ids"
    )
    |> expect_optional_type(callbacks, path, entry, "trust_boundary", :binary)
    |> expect_optional_type(callbacks, path, entry, "provenance", :map)
    |> expect_field_equals(
      callbacks,
      path,
      entry,
      "station_calendar_ambiguous_entry_count",
      list_count(callbacks, entry, "station_calendar_ambiguous_entry_ids")
    )
  end

  defp validate_station_calendar_duplicate_evidence(issues, callbacks, path, contact) do
    if Map.get(contact, "duplicate_station_calendar_row_id_collision") == true and
         not Map.has_key?(contact, "base_station_calendar_row_id") do
      [error(callbacks, path <> ".base_station_calendar_row_id", "is required") | issues]
    else
      issues
    end
  end

  defp validate_station_calendar_provider_contention_group(callbacks, issues, path, group) do
    issues
    |> require_fields(callbacks, path, group, [
      "id",
      "provider_calendar_contention_status",
      "required_operator_action",
      "approval_status",
      "ground_station_id",
      "entry_count",
      "entry_ids",
      "overlap_pairs"
    ])
    |> validate_stable_ids(callbacks, path, group, ["id", "ground_station_id"])
    |> expect_one_of(
      callbacks,
      path,
      group,
      "provider_calendar_contention_status",
      ["provider_calendar_overlap"]
    )
    |> expect_one_of(callbacks, path, group, "required_operator_action", [
      "review_station_provider_contention"
    ])
    |> expect_one_of(callbacks, path, group, "approval_status", [
      "auto_approvable",
      "operator_review_required",
      "blocked_by_policy"
    ])
    |> expect_optional_type(callbacks, path, group, "approval_requirements", :list)
    |> expect_optional_type(callbacks, path, group, "approval_rule_matches", :list)
    |> expect_non_negative_integer(callbacks, path, group, "entry_count")
    |> expect_type(callbacks, path, group, "entry_ids", :list)
    |> expect_type(callbacks, path, group, "overlap_pairs", :list)
    |> expect_optional_number(callbacks, path, group, "starts_at_s")
    |> expect_optional_number(callbacks, path, group, "ends_at_s")
    |> expect_optional_number(callbacks, path, group, "overlap_duration_s")
    |> validate_optional_stable_id_list(callbacks, path, group, "entry_ids")
    |> validate_optional_string_lists(callbacks, path, group, [
      "provider_ids",
      "provider_entry_ids",
      "availabilities",
      "directions",
      "reservation_ids",
      "reserved_by",
      "reservation_statuses",
      "trust_boundary_statuses"
    ])
    |> expect_optional_type(callbacks, path, group, "reservation_expires_at_s", :list)
    |> validate_number_list_items(callbacks, path, group, "reservation_expires_at_s")
    |> validate_string_list_allowed(callbacks, path, group, "trust_boundary_statuses", [
      "declared",
      "missing"
    ])
    |> validate_rows(
      callbacks,
      "#{path}.overlap_pairs",
      Map.get(group, "overlap_pairs", []),
      fn acc, row_path, pair ->
        validate_station_calendar_provider_contention_pair(callbacks, acc, row_path, pair)
      end
    )
    |> validate_optional_rows(
      callbacks,
      "#{path}.source_station_calendar_entries",
      Map.get(group, "source_station_calendar_entries"),
      fn acc, row_path, entry ->
        validate_station_calendar_provider_contention_source_entry(
          callbacks,
          acc,
          row_path,
          entry
        )
      end
    )
    |> validate_provider_calendar_contention_entry_count(callbacks, path, group)
  end

  defp validate_provider_calendar_contention_group_count(issues, callbacks, path, report) do
    expected =
      report
      |> Map.get("provider_calendar_contention_groups", [])
      |> case do
        groups when is_list(groups) -> length(groups)
        _groups -> nil
      end

    case {Map.get(report, "provider_calendar_contention_group_count"), expected} do
      {count, expected} when is_integer(count) and is_integer(expected) and count != expected ->
        [
          error(
            callbacks,
            "#{path}.provider_calendar_contention_group_count",
            "must equal #{expected}"
          )
          | issues
        ]

      _value ->
        issues
    end
  end

  defp validate_station_calendar_provider_contention_pair(callbacks, issues, path, pair) do
    issues
    |> require_fields(callbacks, path, pair, [
      "left_entry_id",
      "right_entry_id",
      "overlap_starts_at_s",
      "overlap_ends_at_s",
      "overlap_duration_s"
    ])
    |> validate_stable_ids(callbacks, path, pair, ["left_entry_id", "right_entry_id"])
    |> expect_number(callbacks, path, pair, "overlap_starts_at_s")
    |> expect_number(callbacks, path, pair, "overlap_ends_at_s")
    |> expect_number(callbacks, path, pair, "overlap_duration_s")
  end

  defp validate_station_calendar_provider_contention_source_entry(
         callbacks,
         issues,
         path,
         entry
       ) do
    issues
    |> validate_stable_ids(callbacks, path, entry, ["id", "ground_station_id"])
    |> expect_optional_number(callbacks, path, entry, "starts_at_s")
    |> expect_optional_number(callbacks, path, entry, "ends_at_s")
  end

  defp validate_station_calendar_report_count_maps(issues, callbacks, path, report) do
    rows =
      report
      |> Map.get("affected_contacts", [])
      |> Enum.filter(&is_map/1)

    issues
    |> validate_branch_event_trust_boundary_status_count_map(
      callbacks,
      "#{path}.calendar_entry_trust_boundary_status_counts",
      Map.get(report, "calendar_entry_trust_boundary_status_counts")
    )
    |> validate_branch_event_trust_boundary_status_count_map(
      callbacks,
      "#{path}.station_calendar_trust_boundary_status_counts",
      Map.get(report, "station_calendar_trust_boundary_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      "#{path}.affected_contact_ground_station_counts",
      Map.get(report, "affected_contact_ground_station_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      "#{path}.affected_contact_availability_counts",
      Map.get(report, "affected_contact_availability_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      "#{path}.direction_counts",
      Map.get(report, "direction_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      "#{path}.station_calendar_status_counts",
      Map.get(report, "station_calendar_status_counts")
    )
    |> validate_station_calendar_entry_count_total(callbacks, path, report)
    |> expect_field_equals(callbacks, path, report, "affected_contact_count", length(rows))
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "affected_contact_ground_station_counts",
      frequency_map(callbacks, rows, "ground_station_id"),
      "must equal row-derived affected_contact_ground_station_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "affected_contact_availability_counts",
      frequency_map(callbacks, rows, "station_availability"),
      "must equal row-derived affected_contact_availability_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "direction_counts",
      frequency_map(callbacks, rows, "direction"),
      "must equal row-derived direction_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "station_calendar_status_counts",
      frequency_map(callbacks, rows, "station_calendar_status"),
      "must equal row-derived station_calendar_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "station_calendar_trust_boundary_status_counts",
      trust_boundary_status_counts(rows),
      "must equal row-derived station_calendar_trust_boundary_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "affected_contact_ids_by_station_calendar_trust_boundary_status",
      affected_contact_ids_by_trust_boundary_status(rows),
      "must equal row-derived affected_contact_ids_by_station_calendar_trust_boundary_status"
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
      "affected_contact_ids_by_reservation_match_status",
      row_ids_by_field(callbacks, rows, "station_reservation_match_status", "contact_id"),
      "must equal row-derived affected_contact_ids_by_reservation_match_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "provider_counteroffer_count",
      provider_counteroffer_count(rows),
      "must equal row-derived provider_counteroffer_count"
    )
    |> validate_affected_duration(callbacks, path, report, rows)
    |> validate_affected_duplicate_counts(callbacks, path, report, rows)
  end

  defp validate_affected_duration(issues, callbacks, path, report, rows) do
    expected_duration =
      rows
      |> Enum.map(&Map.get(&1, "overlap_duration_s"))
      |> Enum.filter(&is_number/1)
      |> Enum.sum()

    case Map.get(report, "affected_duration_s") do
      duration when is_number(duration) and abs(duration - expected_duration) > 1.0e-9 ->
        [
          error(
            callbacks,
            "#{path}.affected_duration_s",
            "must equal row-derived affected duration"
          )
          | issues
        ]

      _value ->
        issues
    end
  end

  defp validate_station_calendar_entry_count_total(issues, callbacks, path, report) do
    counts = Map.get(report, "calendar_entry_trust_boundary_status_counts")
    count = Map.get(report, "calendar_entry_count")

    if is_map(counts) and is_integer(count) do
      count_total =
        counts
        |> Map.values()
        |> Enum.filter(&is_integer/1)
        |> Enum.sum()

      if count_total == count do
        issues
      else
        [
          error(
            callbacks,
            "#{path}.calendar_entry_trust_boundary_status_counts",
            "must add up to calendar_entry_count"
          )
          | issues
        ]
      end
    else
      issues
    end
  end

  defp validate_affected_duplicate_counts(issues, callbacks, path, report, rows) do
    duplicate_groups = duplicate_affected_contact_id_groups(rows)

    issues
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "duplicate_affected_contact_id_count",
      length(duplicate_groups),
      "must equal row-derived duplicate affected contact ID group count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "duplicate_affected_contact_row_count",
      duplicate_affected_contact_row_count(duplicate_groups),
      "must equal row-derived duplicate affected contact row count"
    )
  end

  defp duplicate_affected_contact_id_groups(rows) do
    rows
    |> Enum.group_by(&Map.get(&1, "base_station_calendar_row_id", Map.get(&1, "id")))
    |> Enum.reject(fn {row_id, rows} -> is_nil(row_id) or length(rows) <= 1 end)
    |> Enum.sort_by(fn {row_id, _rows} -> row_id end)
  end

  defp duplicate_affected_contact_row_count(duplicate_groups) do
    duplicate_groups
    |> Enum.map(fn {_row_id, rows} -> length(rows) end)
    |> Enum.sum()
  end

  defp trust_boundary_status_counts(rows) do
    rows
    |> Enum.map(&Map.get(&1, "station_calendar_trust_boundary_status", "missing"))
    |> Enum.frequencies()
  end

  defp affected_contact_ids_by_trust_boundary_status(rows) do
    rows
    |> Enum.map(fn row ->
      {Map.get(row, "station_calendar_trust_boundary_status", "missing"),
       Map.get(row, "contact_id")}
    end)
    |> Enum.reject(fn {status, contact_id} -> is_nil(status) or is_nil(contact_id) end)
    |> Enum.group_by(fn {status, _contact_id} -> status end, fn {_status, contact_id} ->
      contact_id
    end)
    |> Map.new(fn {status, contact_ids} ->
      {status, contact_ids |> Enum.uniq() |> Enum.sort()}
    end)
  end

  defp provider_counteroffer_count(rows) do
    Enum.count(rows, fn row ->
      value_present?(Map.get(row, "provider_counteroffer_id")) or
        value_present?(Map.get(row, "provider_counteroffer_status"))
    end)
  end

  defp validate_station_calendar_report_duplicate_counts(issues, callbacks, path, report) do
    rows =
      report
      |> Map.get("affected_contacts", [])
      |> Enum.filter(&is_map/1)

    rows
    |> Enum.filter(&(Map.get(&1, "duplicate_station_calendar_row_id_collision") == true))
    |> Enum.group_by(&Map.get(&1, "base_station_calendar_row_id"))
    |> Enum.reduce(issues, fn {_base_id, group}, acc ->
      expected = length(group)

      indexes =
        group |> Enum.map(&Map.get(&1, "duplicate_station_calendar_row_index")) |> Enum.sort()

      expected_indexes = Enum.to_list(1..expected)

      acc =
        Enum.reduce(group, acc, fn row, row_acc ->
          index = Enum.find_index(rows, &(&1 == row)) || 0

          expect_field_equals(
            row_acc,
            callbacks,
            "#{path}.affected_contacts[#{index}]",
            row,
            "duplicate_station_calendar_row_count",
            expected
          )
        end)

      if indexes == expected_indexes do
        acc
      else
        [
          error(
            callbacks,
            "#{path}.affected_contacts",
            "duplicate_station_calendar_row_index values must cover 1..#{expected}"
          )
          | acc
        ]
      end
    end)
  end

  defp value_present?(value), do: value not in [nil, ""]

  defp validate_branch_event_trust_boundary_status_count_map(issues, callbacks, path, counts),
    do:
      apply(require_callback(callbacks, :validate_branch_event_trust_boundary_status_count_map), [
        issues,
        path,
        counts
      ])

  defp validate_non_negative_integer_count_map(issues, callbacks, path, counts),
    do:
      apply(require_callback(callbacks, :validate_non_negative_integer_count_map), [
        issues,
        path,
        counts
      ])

  defp expect_field_equals(issues, callbacks, path, report, field, expected),
    do:
      apply(require_callback(callbacks, :expect_field_equals), [
        issues,
        path,
        report,
        field,
        expected
      ])

  defp expect_field_equals(issues, callbacks, path, report, field, expected, message),
    do:
      apply(require_callback(callbacks, :expect_field_equals_with_message), [
        issues,
        path,
        report,
        field,
        expected,
        message
      ])

  defp frequency_map(callbacks, rows, field),
    do: apply(require_callback(callbacks, :frequency_map), [rows, field])

  defp row_ids_by_field(callbacks, rows, group_field, id_field),
    do: apply(require_callback(callbacks, :row_ids_by_field), [rows, group_field, id_field])

  defp list_count(callbacks, map, field),
    do: apply(require_callback(callbacks, :list_count), [map, field])

  defp validate_provider_calendar_contention_entry_count(issues, _callbacks, path, group),
    do:
      OrbitalDynamics.Schema.StationCalendarProviderContentionContracts.validate_entry_count(
        issues,
        path,
        group
      )

  defp provider_counteroffer_negotiation_states do
    OrbitalDynamics.Communications.StationCalendar.capabilities().provider_counteroffer_negotiation_states
  end

  defp error(callbacks, path, message),
    do: apply(require_callback(callbacks, :error), [path, message])
end
