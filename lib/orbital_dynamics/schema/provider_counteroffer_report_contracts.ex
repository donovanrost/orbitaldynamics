defmodule OrbitalDynamics.Schema.ProviderCounterofferReportContracts do
  @moduledoc false

  def validate(issues, path, report, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(callbacks, path, report, "schema_contract", "provider_counteroffer_report.v1")
    |> expect_one_of(
      callbacks,
      path,
      report,
      "model",
      provider_counteroffer_report_models(callbacks)
    )
    |> expect_type(callbacks, path, report, "source", :binary)
    |> expect_one_of(callbacks, path, report, "source_artifact_type", [
      "station_calendar_provider.v1",
      "station_calendar_report.v1"
    ])
    |> validate_stable_ids(callbacks, path, report, ["source_artifact_id"])
    |> expect_non_negative_integer(callbacks, path, report, "counteroffer_count")
    |> expect_non_negative_integer(callbacks, path, report, "reviewable_count")
    |> expect_non_negative_integer(callbacks, path, report, "counteroffer_cost_delta_count")
    |> expect_number(callbacks, path, report, "counteroffer_cost_delta_total")
    |> expect_non_negative_integer(callbacks, path, report, "counteroffer_lock_deadline_count")
    |> expect_optional_number(callbacks, path, report, "earliest_counteroffer_lock_deadline_s")
    |> expect_type(callbacks, path, report, "counteroffer_status_counts", :map)
    |> expect_type(callbacks, path, report, "counteroffer_negotiation_state_counts", :map)
    |> expect_type(callbacks, path, report, "required_operator_action_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".counteroffer_status_counts",
      Map.get(report, "counteroffer_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".counteroffer_negotiation_state_counts",
      Map.get(report, "counteroffer_negotiation_state_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".required_operator_action_counts",
      Map.get(report, "required_operator_action_counts")
    )
    |> expect_optional_type(callbacks, path, report, "model_limits", :list)
    |> expect_type(callbacks, path, report, "rows", :list)
    |> expect_type(callbacks, path, report, "assumptions", :map)
    |> validate_rows(callbacks, path <> ".rows", Map.get(report, "rows", []), fn acc,
                                                                                 row_path,
                                                                                 row ->
      validate_row(acc, row_path, row, callbacks)
    end)
    |> validate_report_counts(callbacks, path, report)
  end

  def validate_row(issues, path, row, callbacks) do
    issues
    |> require_fields(callbacks, path, row, [
      "id",
      "provider_counteroffer_id",
      "provider_counteroffer_status",
      "provider_counteroffer_negotiation_state",
      "reviewable",
      "required_operator_action",
      "source_station_calendar_entry"
    ])
    |> validate_stable_ids(callbacks, path, row, [
      "id",
      "provider_counteroffer_id",
      "ground_station_id",
      "station_calendar_entry_id",
      "station_calendar_provider_id",
      "station_calendar_provider_entry_id"
    ])
    |> expect_type(callbacks, path, row, "provider_counteroffer_status", :binary)
    |> expect_one_of(
      callbacks,
      path,
      row,
      "provider_counteroffer_negotiation_state",
      capabilities().provider_counteroffer_negotiation_states
    )
    |> expect_optional_type(callbacks, path, row, "provider_counteroffer_reason_code", :binary)
    |> expect_optional_number(callbacks, path, row, "provider_counteroffer_cost_delta")
    |> expect_optional_number(callbacks, path, row, "provider_counteroffer_lock_deadline_s")
    |> expect_optional_number(callbacks, path, row, "provider_counteroffer_starts_at_s")
    |> expect_optional_number(callbacks, path, row, "provider_counteroffer_ends_at_s")
    |> expect_optional_number(callbacks, path, row, "provider_counteroffer_start_delta_s")
    |> expect_optional_number(callbacks, path, row, "provider_counteroffer_end_delta_s")
    |> expect_optional_number(callbacks, path, row, "provider_counteroffer_duration_delta_s")
    |> expect_optional_one_of(
      callbacks,
      path,
      row,
      "provider_counteroffer_lock_deadline_status",
      capabilities().provider_counteroffer_lock_deadline_statuses
    )
    |> expect_optional_one_of(
      callbacks,
      path,
      row,
      "provider_counteroffer_import_status",
      capabilities().provider_counteroffer_import_statuses
    )
    |> expect_type(callbacks, path, row, "reviewable", :boolean)
    |> expect_one_of(
      callbacks,
      path,
      row,
      "required_operator_action",
      capabilities().provider_counteroffer_actions
    )
    |> expect_optional_type(callbacks, path, row, "station_availability", :binary)
    |> expect_optional_number(callbacks, path, row, "starts_at_s")
    |> expect_optional_number(callbacks, path, row, "ends_at_s")
    |> expect_type(callbacks, path, row, "source_station_calendar_entry", :map)
  end

  defp validate_report_counts(issues, callbacks, path, report) do
    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    issues
    |> expect_field_equals(callbacks, path, report, "counteroffer_count", length(rows))
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "reviewable_count",
      Enum.count(rows, & &1["reviewable"])
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "counteroffer_cost_delta_count",
      numeric_value_count(callbacks, rows, "provider_counteroffer_cost_delta"),
      "must equal row-derived counteroffer_cost_delta_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "counteroffer_cost_delta_total",
      numeric_value_sum(callbacks, rows, "provider_counteroffer_cost_delta"),
      "must equal row-derived counteroffer_cost_delta_total"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "counteroffer_lock_deadline_count",
      numeric_value_count(callbacks, rows, "provider_counteroffer_lock_deadline_s"),
      "must equal row-derived counteroffer_lock_deadline_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "earliest_counteroffer_lock_deadline_s",
      numeric_value_min(callbacks, rows, "provider_counteroffer_lock_deadline_s"),
      "must equal row-derived earliest_counteroffer_lock_deadline_s"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "counteroffer_status_counts",
      frequency_map(callbacks, rows, "provider_counteroffer_status"),
      "must equal row-derived counteroffer_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "counteroffer_negotiation_state_counts",
      frequency_map(callbacks, rows, "provider_counteroffer_negotiation_state"),
      "must equal row-derived counteroffer_negotiation_state_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "required_operator_action_counts",
      frequency_map(callbacks, rows, "required_operator_action"),
      "must equal row-derived required_operator_action_counts"
    )
  end

  defp capabilities, do: OrbitalDynamics.Communications.StationCalendar.capabilities()

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :require_fields), [issues, path, map, fields])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(Keyword.fetch!(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_optional_one_of(issues, callbacks, path, map, field, allowed),
    do:
      apply(Keyword.fetch!(callbacks, :expect_optional_one_of), [
        issues,
        path,
        map,
        field,
        allowed
      ])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_non_negative_integer(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :expect_non_negative_integer), [issues, path, map, field])
  end

  defp expect_number(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_number), [issues, path, map, field])

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

  defp validate_non_negative_integer_count_map(issues, callbacks, path, values) do
    apply(Keyword.fetch!(callbacks, :validate_non_negative_integer_count_map), [
      issues,
      path,
      values
    ])
  end

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(Keyword.fetch!(callbacks, :validate_rows), [issues, path, rows, validator])

  defp provider_counteroffer_report_models(callbacks),
    do: apply(Keyword.fetch!(callbacks, :provider_counteroffer_report_models), [])

  defp frequency_map(callbacks, rows, field),
    do: apply(Keyword.fetch!(callbacks, :frequency_map), [rows, field])

  defp numeric_value_count(callbacks, rows, field),
    do:
      apply(Keyword.fetch!(callbacks, :provider_counteroffer_numeric_value_count), [rows, field])

  defp numeric_value_sum(callbacks, rows, field),
    do: apply(Keyword.fetch!(callbacks, :provider_counteroffer_numeric_value_sum), [rows, field])

  defp numeric_value_min(callbacks, rows, field),
    do: apply(Keyword.fetch!(callbacks, :provider_counteroffer_numeric_value_min), [rows, field])
end
