defmodule OrbitalDynamics.Schema.ProviderCounterofferReportContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionAggregation, only: [frequency_map: 2]
  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_number: 4,
      expect_one_of: 5,
      expect_optional_number: 4,
      expect_optional_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_non_negative_integer_count_map: 3
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  @report_models [
    "artifact_only_provider_counteroffer_review",
    "preserved_provider_counteroffer_rows",
    "preserved_provider_counteroffer_plan_impact_summary",
    "preserved_provider_counteroffer_import_readiness_summary"
  ]

  def validate(issues, path, report) do
    issues
    |> expect_equal(path, report, "schema_contract", "provider_counteroffer_report.v1")
    |> expect_one_of(path, report, "model", @report_models)
    |> expect_type(path, report, "source", :binary)
    |> expect_one_of(path, report, "source_artifact_type", [
      "station_calendar_provider.v1",
      "station_calendar_report.v1"
    ])
    |> validate_stable_ids(path, report, ["source_artifact_id"])
    |> expect_non_negative_integer(path, report, "counteroffer_count")
    |> expect_non_negative_integer(path, report, "reviewable_count")
    |> expect_non_negative_integer(path, report, "counteroffer_cost_delta_count")
    |> expect_number(path, report, "counteroffer_cost_delta_total")
    |> expect_non_negative_integer(path, report, "counteroffer_lock_deadline_count")
    |> expect_optional_number(path, report, "earliest_counteroffer_lock_deadline_s")
    |> expect_type(path, report, "counteroffer_status_counts", :map)
    |> expect_type(path, report, "counteroffer_negotiation_state_counts", :map)
    |> expect_type(path, report, "required_operator_action_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".counteroffer_status_counts",
      Map.get(report, "counteroffer_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".counteroffer_negotiation_state_counts",
      Map.get(report, "counteroffer_negotiation_state_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".required_operator_action_counts",
      Map.get(report, "required_operator_action_counts")
    )
    |> expect_optional_type(path, report, "model_limits", :list)
    |> expect_type(path, report, "rows", :list)
    |> expect_type(path, report, "assumptions", :map)
    |> validate_rows(path <> ".rows", Map.get(report, "rows", []), &validate_row/3)
    |> validate_report_counts(path, report)
  end

  def validate_row(issues, path, row) do
    issues
    |> require_fields(path, row, [
      "id",
      "provider_counteroffer_id",
      "provider_counteroffer_status",
      "provider_counteroffer_negotiation_state",
      "reviewable",
      "required_operator_action",
      "source_station_calendar_entry"
    ])
    |> validate_stable_ids(path, row, [
      "id",
      "provider_counteroffer_id",
      "ground_station_id",
      "station_calendar_entry_id",
      "station_calendar_provider_id",
      "station_calendar_provider_entry_id"
    ])
    |> expect_type(path, row, "provider_counteroffer_status", :binary)
    |> expect_one_of(
      path,
      row,
      "provider_counteroffer_negotiation_state",
      capabilities().provider_counteroffer_negotiation_states
    )
    |> expect_optional_type(path, row, "provider_counteroffer_reason_code", :binary)
    |> expect_optional_number(path, row, "provider_counteroffer_cost_delta")
    |> expect_optional_number(path, row, "provider_counteroffer_lock_deadline_s")
    |> expect_optional_number(path, row, "provider_counteroffer_starts_at_s")
    |> expect_optional_number(path, row, "provider_counteroffer_ends_at_s")
    |> expect_optional_number(path, row, "provider_counteroffer_start_delta_s")
    |> expect_optional_number(path, row, "provider_counteroffer_end_delta_s")
    |> expect_optional_number(path, row, "provider_counteroffer_duration_delta_s")
    |> expect_optional_one_of(
      path,
      row,
      "provider_counteroffer_lock_deadline_status",
      capabilities().provider_counteroffer_lock_deadline_statuses
    )
    |> expect_optional_one_of(
      path,
      row,
      "provider_counteroffer_import_status",
      capabilities().provider_counteroffer_import_statuses
    )
    |> expect_type(path, row, "reviewable", :boolean)
    |> expect_one_of(
      path,
      row,
      "required_operator_action",
      capabilities().provider_counteroffer_actions
    )
    |> expect_optional_type(path, row, "station_availability", :binary)
    |> expect_optional_number(path, row, "starts_at_s")
    |> expect_optional_number(path, row, "ends_at_s")
    |> expect_type(path, row, "source_station_calendar_entry", :map)
  end

  defp validate_report_counts(issues, path, report) do
    rows = report |> Map.get("rows", []) |> Enum.filter(&is_map/1)

    issues
    |> expect_field_equals(path, report, "counteroffer_count", length(rows))
    |> expect_field_equals(
      path,
      report,
      "reviewable_count",
      Enum.count(rows, & &1["reviewable"])
    )
    |> expect_field_equals(
      path,
      report,
      "counteroffer_cost_delta_count",
      numeric_value_count(rows, "provider_counteroffer_cost_delta"),
      "must equal row-derived counteroffer_cost_delta_count"
    )
    |> expect_field_equals(
      path,
      report,
      "counteroffer_cost_delta_total",
      numeric_value_sum(rows, "provider_counteroffer_cost_delta"),
      "must equal row-derived counteroffer_cost_delta_total"
    )
    |> expect_field_equals(
      path,
      report,
      "counteroffer_lock_deadline_count",
      numeric_value_count(rows, "provider_counteroffer_lock_deadline_s"),
      "must equal row-derived counteroffer_lock_deadline_count"
    )
    |> expect_field_equals(
      path,
      report,
      "earliest_counteroffer_lock_deadline_s",
      numeric_value_min(rows, "provider_counteroffer_lock_deadline_s"),
      "must equal row-derived earliest_counteroffer_lock_deadline_s"
    )
    |> expect_field_equals(
      path,
      report,
      "counteroffer_status_counts",
      frequency_map(rows, "provider_counteroffer_status"),
      "must equal row-derived counteroffer_status_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "counteroffer_negotiation_state_counts",
      frequency_map(rows, "provider_counteroffer_negotiation_state"),
      "must equal row-derived counteroffer_negotiation_state_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "required_operator_action_counts",
      frequency_map(rows, "required_operator_action"),
      "must equal row-derived required_operator_action_counts"
    )
  end

  defp capabilities, do: OrbitalDynamics.Communications.StationCalendar.capabilities()

  defp numeric_value_count(rows, field), do: length(numeric_values(rows, field))
  defp numeric_value_sum(rows, field), do: rows |> numeric_values(field) |> Enum.sum()

  defp numeric_value_min(rows, field),
    do: rows |> numeric_values(field) |> Enum.min(fn -> nil end)

  defp numeric_values(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&is_number/1)
  end

  defp expect_field_equals(issues, path, map, field, nil),
    do: expect_field_equals(issues, path, map, field, nil, nil)

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")
end
