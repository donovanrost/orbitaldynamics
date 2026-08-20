defmodule OrbitalDynamics.Schema.LinkCapacityReportContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.ExecutionMetricContracts

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_field_equals: 6,
      expect_field_matches_list_count: 6,
      expect_non_negative_integer: 4,
      expect_number: 4,
      expect_optional_field_equals: 6,
      expect_optional_list_field_equals: 6,
      expect_optional_non_negative_integer: 4,
      expect_optional_number: 4,
      expect_optional_probability: 4,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_non_negative_integer_count_map: 3,
      error: 2,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_optional_stable_id_list: 4,
      validate_stable_id_array_map: 3,
      validate_stable_ids: 4
    ]

  def validate(issues, path, report) do
    issues
    |> expect_equal(path, report, "schema_contract", "link_capacity_report.v1")
    |> expect_equal(path, report, "model", "fixed_rate_downlink_capacity_summary")
    |> expect_type(path, report, "source", :binary)
    |> expect_non_negative_integer(path, report, "contact_count")
    |> expect_non_negative_integer(path, report, "selected_contact_count")
    |> expect_number(path, report, "estimated_throughput_mb")
    |> expect_number(path, report, "selected_estimated_throughput_mb")
    |> expect_optional_number(path, report, "capacity_adjusted_throughput_mb")
    |> expect_optional_number(path, report, "selected_capacity_adjusted_throughput_mb")
    |> expect_optional_number(path, report, "unused_capacity_adjusted_throughput_mb")
    |> expect_optional_probability(
      path,
      report,
      "selected_capacity_utilization_fraction"
    )
    |> expect_optional_type(path, report, "selection_utilization_status", :binary)
    |> expect_optional_non_negative_integer(path, report, "effective_contact_count")
    |> expect_optional_non_negative_integer(path, report, "ignored_contact_count")
    |> expect_optional_type(path, report, "ignored_contact_ids", :list)
    |> validate_optional_stable_id_list(path, report, "ignored_contact_ids")
    |> expect_optional_type(path, report, "ignored_contact_reason_counts", :map)
    |> expect_optional_non_negative_integer(
      path,
      report,
      "ignored_selected_contact_count"
    )
    |> expect_optional_type(path, report, "ignored_selected_contact_ids", :list)
    |> validate_optional_stable_id_list(path, report, "ignored_selected_contact_ids")
    |> expect_optional_type(
      path,
      report,
      "ignored_selected_contact_reason_counts",
      :map
    )
    |> expect_optional_non_negative_integer(
      path,
      report,
      "ambiguous_selected_contact_id_count"
    )
    |> expect_optional_type(path, report, "ambiguous_selected_contact_ids", :list)
    |> validate_optional_stable_id_list(path, report, "ambiguous_selected_contact_ids")
    |> expect_optional_non_negative_integer(
      path,
      report,
      "duplicate_contact_candidate_count"
    )
    |> expect_optional_non_negative_integer(path, report, "duplicate_contact_id_count")
    |> expect_optional_non_negative_integer(
      path,
      report,
      "unmatched_selected_contact_count"
    )
    |> expect_optional_type(path, report, "unmatched_selected_contact_ids", :list)
    |> validate_optional_stable_id_list(path, report, "unmatched_selected_contact_ids")
    |> expect_optional_non_negative_integer(
      path,
      report,
      "invalid_policy_required_downlink_station_count"
    )
    |> expect_optional_type(
      path,
      report,
      "invalid_policy_required_downlink_station_ids",
      :list
    )
    |> validate_string_list_items(
      path,
      report,
      "invalid_policy_required_downlink_station_ids"
    )
    |> expect_optional_number(path, report, "required_downlink_mb")
    |> expect_optional_non_negative_integer(
      path,
      report,
      "required_downlink_contact_count"
    )
    |> expect_optional_type(path, report, "required_downlink_contact_ids", :list)
    |> validate_string_list_items(path, report, "required_downlink_contact_ids")
    |> expect_optional_number(path, report, "selected_downlink_shortfall_mb")
    |> expect_optional_type(path, report, "downlink_requirement_status", :binary)
    |> expect_optional_number(path, report, "actual_throughput_mb")
    |> expect_optional_non_negative_integer(
      path,
      report,
      "actual_throughput_contact_count"
    )
    |> expect_optional_type(path, report, "actual_throughput_contact_ids", :list)
    |> validate_optional_stable_id_list(path, report, "actual_throughput_contact_ids")
    |> expect_optional_non_negative_integer(
      path,
      report,
      "actual_completion_contact_count"
    )
    |> expect_optional_type(path, report, "actual_completion_contact_ids", :list)
    |> validate_optional_stable_id_list(path, report, "actual_completion_contact_ids")
    |> expect_optional_non_negative_integer(
      path,
      report,
      "unmatched_actual_throughput_contact_count"
    )
    |> expect_optional_type(
      path,
      report,
      "unmatched_actual_throughput_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      report,
      "unmatched_actual_throughput_contact_ids"
    )
    |> expect_optional_non_negative_integer(
      path,
      report,
      "ambiguous_actual_throughput_contact_count"
    )
    |> expect_optional_type(
      path,
      report,
      "ambiguous_actual_throughput_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      report,
      "ambiguous_actual_throughput_contact_ids"
    )
    |> expect_optional_non_negative_integer(
      path,
      report,
      "unmatched_actual_completion_contact_count"
    )
    |> expect_optional_type(
      path,
      report,
      "unmatched_actual_completion_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      report,
      "unmatched_actual_completion_contact_ids"
    )
    |> expect_optional_non_negative_integer(
      path,
      report,
      "ambiguous_actual_completion_contact_count"
    )
    |> expect_optional_type(
      path,
      report,
      "ambiguous_actual_completion_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      report,
      "ambiguous_actual_completion_contact_ids"
    )
    |> expect_optional_probability(path, report, "actual_downlink_completion_ratio")
    |> expect_optional_type(
      path,
      report,
      "actual_data_rate_throughput_derivations",
      :list
    )
    |> ExecutionMetricContracts.validate_optional_actual_data_rate_throughput_derivations(
      path,
      report,
      "actual_data_rate_throughput_derivations"
    )
    |> expect_optional_type(path, report, "station_reservation_ids", :list)
    |> validate_optional_stable_id_list(path, report, "station_reservation_ids")
    |> expect_optional_type(
      path,
      report,
      "station_reservation_expiration_status_counts",
      :map
    )
    |> validate_non_negative_integer_count_map(
      path <> ".station_reservation_expiration_status_counts",
      Map.get(report, "station_reservation_expiration_status_counts")
    )
    |> expect_optional_non_negative_integer(
      path,
      report,
      "station_reservation_declared_expiration_contact_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      report,
      "station_reservation_missing_expiration_contact_count"
    )
    |> expect_optional_number(
      path,
      report,
      "earliest_station_reservation_expires_at_s"
    )
    |> validate_optional_stable_id_array_map(
      path,
      report,
      "station_reservation_contact_ids_by_expiration_status"
    )
    |> validate_optional_stable_id_array_map(
      path,
      report,
      "station_reservation_ids_by_expiration_status"
    )
    |> expect_optional_type(path, report, "station_reserved_bys", :list)
    |> validate_string_list_items(path, report, "station_reserved_bys")
    |> expect_optional_type(path, report, "station_reservation_statuses", :list)
    |> validate_string_list_items(path, report, "station_reservation_statuses")
    |> expect_optional_type(
      path,
      report,
      "station_reservation_match_status_counts",
      :map
    )
    |> expect_optional_non_negative_integer(path, report, "downlink_link_budget_count")
    |> expect_optional_type(path, report, "downlink_link_budget_ids", :list)
    |> validate_optional_stable_id_list(path, report, "downlink_link_budget_ids")
    |> expect_optional_type(path, report, "downlink_link_budgets", :list)
    |> validate_optional_link_budgets(path, report)
    |> expect_optional_type(path, report, "model_limits", :list)
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_report_model_limits(path, report)
    |> expect_type(path, report, "rows", :list)
    |> expect_type(path, report, "assumptions", :map)
    |> validate_report_assumptions(path, report)
    |> validate_rows(
      path <> ".rows",
      Map.get(report, "rows", []),
      fn acc, row_path, row -> validate_row(acc, row_path, row) end
    )
    |> validate_report_counts(path, report)
  end

  def validate_assumptions(issues, path, artifact) do
    validate_report_assumptions(issues, path, artifact)
  end

  defp validate_row(issues, path, row) do
    issues
    |> require_fields(path, row, [
      "ground_station_id",
      "contact_count",
      "selected_contact_count",
      "estimated_throughput_mb",
      "selected_estimated_throughput_mb",
      "contact_ids",
      "selected_contact_ids"
    ])
    |> validate_stable_ids(path, row, ["ground_station_id"])
    |> expect_non_negative_integer(path, row, "contact_count")
    |> expect_non_negative_integer(path, row, "selected_contact_count")
    |> expect_number(path, row, "estimated_throughput_mb")
    |> expect_number(path, row, "selected_estimated_throughput_mb")
    |> expect_optional_number(path, row, "capacity_adjusted_throughput_mb")
    |> expect_optional_number(path, row, "selected_capacity_adjusted_throughput_mb")
    |> expect_optional_number(path, row, "unused_capacity_adjusted_throughput_mb")
    |> expect_optional_probability(path, row, "selected_capacity_utilization_fraction")
    |> expect_optional_type(path, row, "selection_utilization_status", :binary)
    |> expect_optional_probability(path, row, "capacity_fraction_min")
    |> expect_optional_probability(path, row, "capacity_fraction_max")
    |> expect_type(path, row, "contact_ids", :list)
    |> expect_type(path, row, "selected_contact_ids", :list)
    |> expect_optional_non_negative_integer(path, row, "effective_contact_count")
    |> expect_optional_non_negative_integer(path, row, "ignored_contact_count")
    |> expect_optional_type(path, row, "ignored_contact_ids", :list)
    |> validate_optional_stable_id_list(path, row, "ignored_contact_ids")
    |> expect_optional_type(path, row, "ignored_contact_reason_counts", :map)
    |> validate_non_negative_integer_count_map(
      "#{path}.ignored_contact_reason_counts",
      Map.get(row, "ignored_contact_reason_counts")
    )
    |> expect_optional_non_negative_integer(
      path,
      row,
      "ignored_selected_contact_count"
    )
    |> expect_optional_type(path, row, "ignored_selected_contact_ids", :list)
    |> validate_optional_stable_id_list(path, row, "ignored_selected_contact_ids")
    |> expect_optional_type(path, row, "ignored_selected_contact_reason_counts", :map)
    |> validate_non_negative_integer_count_map(
      "#{path}.ignored_selected_contact_reason_counts",
      Map.get(row, "ignored_selected_contact_reason_counts")
    )
    |> expect_optional_non_negative_integer(
      path,
      row,
      "ambiguous_selected_contact_id_count"
    )
    |> expect_optional_type(path, row, "ambiguous_selected_contact_ids", :list)
    |> validate_optional_stable_id_list(path, row, "ambiguous_selected_contact_ids")
    |> expect_optional_non_negative_integer(
      path,
      row,
      "duplicate_contact_candidate_count"
    )
    |> expect_optional_type(path, row, "duplicate_contact_ids", :list)
    |> validate_optional_stable_id_list(path, row, "duplicate_contact_ids")
    |> expect_optional_type(path, row, "station_calendar_entry_ids", :list)
    |> validate_optional_stable_id_list(path, row, "station_calendar_entry_ids")
    |> expect_optional_type(path, row, "station_calendar_provider_ids", :list)
    |> validate_optional_stable_id_list(path, row, "station_calendar_provider_ids")
    |> expect_optional_type(path, row, "station_calendar_provider_entry_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      row,
      "station_calendar_provider_entry_ids"
    )
    |> expect_optional_type(path, row, "station_calendar_directions", :list)
    |> validate_string_list_items(path, row, "station_calendar_directions")
    |> expect_optional_type(path, row, "station_reservation_ids", :list)
    |> validate_optional_stable_id_list(path, row, "station_reservation_ids")
    |> expect_optional_type(path, row, "station_reserved_bys", :list)
    |> validate_string_list_items(path, row, "station_reserved_bys")
    |> expect_optional_type(path, row, "station_reservation_statuses", :list)
    |> validate_string_list_items(path, row, "station_reservation_statuses")
    |> expect_optional_type(path, row, "station_reservation_match_statuses", :list)
    |> validate_string_list_items(path, row, "station_reservation_match_statuses")
    |> expect_optional_number(path, row, "actual_throughput_mb")
    |> expect_optional_non_negative_integer(
      path,
      row,
      "actual_throughput_contact_count"
    )
    |> expect_optional_type(path, row, "actual_throughput_contact_ids", :list)
    |> validate_optional_stable_id_list(path, row, "actual_throughput_contact_ids")
    |> expect_optional_non_negative_integer(
      path,
      row,
      "actual_completion_contact_count"
    )
    |> expect_optional_type(path, row, "actual_completion_contact_ids", :list)
    |> validate_optional_stable_id_list(path, row, "actual_completion_contact_ids")
    |> expect_optional_non_negative_integer(
      path,
      row,
      "unmatched_actual_throughput_contact_count"
    )
    |> expect_optional_type(
      path,
      row,
      "unmatched_actual_throughput_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      row,
      "unmatched_actual_throughput_contact_ids"
    )
    |> expect_optional_non_negative_integer(
      path,
      row,
      "ambiguous_actual_throughput_contact_count"
    )
    |> expect_optional_type(
      path,
      row,
      "ambiguous_actual_throughput_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      row,
      "ambiguous_actual_throughput_contact_ids"
    )
    |> expect_optional_non_negative_integer(
      path,
      row,
      "unmatched_actual_completion_contact_count"
    )
    |> expect_optional_type(
      path,
      row,
      "unmatched_actual_completion_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      row,
      "unmatched_actual_completion_contact_ids"
    )
    |> expect_optional_non_negative_integer(
      path,
      row,
      "ambiguous_actual_completion_contact_count"
    )
    |> expect_optional_type(
      path,
      row,
      "ambiguous_actual_completion_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      row,
      "ambiguous_actual_completion_contact_ids"
    )
    |> expect_optional_probability(path, row, "actual_downlink_completion_ratio")
    |> expect_optional_type(
      path,
      row,
      "actual_data_rate_throughput_derivations",
      :list
    )
    |> ExecutionMetricContracts.validate_optional_actual_data_rate_throughput_derivations(
      path,
      row,
      "actual_data_rate_throughput_derivations"
    )
    |> expect_optional_non_negative_integer(path, row, "downlink_link_budget_count")
    |> expect_optional_type(path, row, "downlink_link_budget_ids", :list)
    |> validate_optional_stable_id_list(path, row, "downlink_link_budget_ids")
    |> expect_optional_type(path, row, "downlink_link_budget_contact_ids", :list)
    |> validate_optional_stable_id_list(path, row, "downlink_link_budget_contact_ids")
    |> validate_row_counts(path, row)
  end

  defp validate_row_counts(issues, path, row) do
    issues
    |> expect_field_matches_list_count(
      path,
      row,
      "contact_count",
      "contact_ids",
      "must equal contact_ids count"
    )
    |> expect_field_matches_list_count(
      path,
      row,
      "selected_contact_count",
      "selected_contact_ids",
      "must equal selected_contact_ids count"
    )
    |> expect_field_matches_list_count(
      path,
      row,
      "ignored_contact_count",
      "ignored_contact_ids",
      "must equal ignored_contact_ids count"
    )
    |> expect_field_matches_list_count(
      path,
      row,
      "ignored_selected_contact_count",
      "ignored_selected_contact_ids",
      "must equal ignored_selected_contact_ids count"
    )
    |> expect_field_matches_list_count(
      path,
      row,
      "ambiguous_selected_contact_id_count",
      "ambiguous_selected_contact_ids",
      "must equal ambiguous_selected_contact_ids count"
    )
    |> expect_field_matches_list_count(
      path,
      row,
      "required_downlink_contact_count",
      "required_downlink_contact_ids",
      "must equal required_downlink_contact_ids count"
    )
    |> expect_field_matches_list_count(
      path,
      row,
      "actual_throughput_contact_count",
      "actual_throughput_contact_ids",
      "must equal actual_throughput_contact_ids count"
    )
    |> expect_field_matches_list_count(
      path,
      row,
      "actual_completion_contact_count",
      "actual_completion_contact_ids",
      "must equal actual_completion_contact_ids count"
    )
    |> expect_field_matches_list_count(
      path,
      row,
      "unmatched_actual_throughput_contact_count",
      "unmatched_actual_throughput_contact_ids",
      "must equal unmatched_actual_throughput_contact_ids count"
    )
    |> expect_field_matches_list_count(
      path,
      row,
      "ambiguous_actual_throughput_contact_count",
      "ambiguous_actual_throughput_contact_ids",
      "must equal ambiguous_actual_throughput_contact_ids count"
    )
    |> expect_field_matches_list_count(
      path,
      row,
      "unmatched_actual_completion_contact_count",
      "unmatched_actual_completion_contact_ids",
      "must equal unmatched_actual_completion_contact_ids count"
    )
    |> expect_field_matches_list_count(
      path,
      row,
      "ambiguous_actual_completion_contact_count",
      "ambiguous_actual_completion_contact_ids",
      "must equal ambiguous_actual_completion_contact_ids count"
    )
    |> expect_field_matches_list_count(
      path,
      row,
      "downlink_link_budget_count",
      "downlink_link_budget_ids",
      "must equal downlink_link_budget_ids count"
    )
    |> expect_field_matches_list_count(
      path,
      row,
      "downlink_link_budget_count",
      "downlink_link_budget_contact_ids",
      "must equal downlink_link_budget_contact_ids count"
    )
  end

  defp validate_report_counts(issues, path, report) do
    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    budgets = list_value(report, "downlink_link_budgets")
    budget_ids = budgets |> Enum.filter(&is_map/1) |> Enum.map(& &1["id"])

    issues
    |> expect_field_equals(
      path,
      report,
      "contact_count",
      sum_row_numbers(rows, "contact_count"),
      "must equal row-derived contact_count"
    )
    |> expect_field_equals(
      path,
      report,
      "selected_contact_count",
      sum_row_numbers(rows, "selected_contact_count"),
      "must equal row-derived selected_contact_count"
    )
    |> expect_field_equals(
      path,
      report,
      "estimated_throughput_mb",
      sum_row_numbers(rows, "estimated_throughput_mb"),
      "must equal row-derived estimated_throughput_mb"
    )
    |> expect_field_equals(
      path,
      report,
      "selected_estimated_throughput_mb",
      sum_row_numbers(rows, "selected_estimated_throughput_mb"),
      "must equal row-derived selected_estimated_throughput_mb"
    )
    |> expect_optional_field_equals(
      path,
      report,
      "downlink_link_budget_count",
      length(budgets),
      "must equal downlink_link_budgets count"
    )
    |> expect_optional_field_equals(
      path,
      report,
      "downlink_link_budget_ids",
      budget_ids,
      "must equal ordered downlink_link_budgets IDs"
    )
    |> validate_link_budget_membership(path, report, rows, budgets)
    |> expect_field_equals(
      path,
      report,
      "ignored_contact_ids",
      concat_row_lists(rows, "ignored_contact_ids"),
      "must equal row-derived ignored_contact_ids"
    )
    |> validate_non_negative_integer_count_map(
      "#{path}.ignored_contact_reason_counts",
      Map.get(report, "ignored_contact_reason_counts")
    )
    |> validate_non_negative_integer_count_map(
      "#{path}.ignored_selected_contact_reason_counts",
      Map.get(report, "ignored_selected_contact_reason_counts")
    )
    |> expect_field_equals(
      path,
      report,
      "ignored_contact_reason_counts",
      merge_row_count_maps(rows, "ignored_contact_reason_counts"),
      "must equal row-derived ignored_contact_reason_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "invalid_contact_input_ids",
      invalid_contact_input_ids(report, "invalid_contact_inputs", "contact_id"),
      "must equal row-derived invalid_contact_input_ids"
    )
    |> expect_field_equals(
      path,
      report,
      "required_downlink_contact_ids",
      concat_row_lists(rows, "required_downlink_contact_ids"),
      "must equal row-derived required_downlink_contact_ids"
    )
    |> expect_field_equals(
      path,
      report,
      "required_downlink_contact_count",
      length(concat_row_lists(rows, "required_downlink_contact_ids")),
      "must equal row-derived required_downlink_contact_count"
    )
    |> expect_field_equals(
      path,
      report,
      "actual_throughput_contact_ids",
      concat_row_lists(rows, "actual_throughput_contact_ids"),
      "must equal row-derived actual_throughput_contact_ids"
    )
    |> expect_field_equals(
      path,
      report,
      "actual_throughput_contact_count",
      length(concat_row_lists(rows, "actual_throughput_contact_ids")),
      "must equal row-derived actual_throughput_contact_count"
    )
    |> expect_field_equals(
      path,
      report,
      "actual_completion_contact_ids",
      concat_row_lists(rows, "actual_completion_contact_ids"),
      "must equal row-derived actual_completion_contact_ids"
    )
    |> expect_field_equals(
      path,
      report,
      "actual_completion_contact_count",
      length(concat_row_lists(rows, "actual_completion_contact_ids")),
      "must equal row-derived actual_completion_contact_count"
    )
    |> expect_field_equals(
      path,
      report,
      "unmatched_actual_throughput_contact_ids",
      concat_row_lists(rows, "unmatched_actual_throughput_contact_ids"),
      "must equal row-derived unmatched_actual_throughput_contact_ids"
    )
    |> expect_field_equals(
      path,
      report,
      "unmatched_actual_throughput_contact_count",
      length(concat_row_lists(rows, "unmatched_actual_throughput_contact_ids")),
      "must equal row-derived unmatched_actual_throughput_contact_count"
    )
    |> expect_field_equals(
      path,
      report,
      "ambiguous_actual_throughput_contact_ids",
      concat_row_lists(rows, "ambiguous_actual_throughput_contact_ids"),
      "must equal row-derived ambiguous_actual_throughput_contact_ids"
    )
    |> expect_field_equals(
      path,
      report,
      "ambiguous_actual_throughput_contact_count",
      length(concat_row_lists(rows, "ambiguous_actual_throughput_contact_ids")),
      "must equal row-derived ambiguous_actual_throughput_contact_count"
    )
    |> expect_field_equals(
      path,
      report,
      "unmatched_actual_completion_contact_ids",
      concat_row_lists(rows, "unmatched_actual_completion_contact_ids"),
      "must equal row-derived unmatched_actual_completion_contact_ids"
    )
    |> expect_field_equals(
      path,
      report,
      "unmatched_actual_completion_contact_count",
      length(concat_row_lists(rows, "unmatched_actual_completion_contact_ids")),
      "must equal row-derived unmatched_actual_completion_contact_count"
    )
    |> expect_field_equals(
      path,
      report,
      "ambiguous_actual_completion_contact_ids",
      concat_row_lists(rows, "ambiguous_actual_completion_contact_ids"),
      "must equal row-derived ambiguous_actual_completion_contact_ids"
    )
    |> expect_field_equals(
      path,
      report,
      "ambiguous_actual_completion_contact_count",
      length(concat_row_lists(rows, "ambiguous_actual_completion_contact_ids")),
      "must equal row-derived ambiguous_actual_completion_contact_count"
    )
    |> expect_field_equals(
      path,
      report,
      "actual_data_rate_throughput_derivations",
      concat_optional_row_lists(rows, "actual_data_rate_throughput_derivations"),
      "must equal row-derived actual_data_rate_throughput_derivations"
    )
    |> expect_optional_list_field_equals(
      path,
      report,
      "station_reservation_ids",
      sorted_unique_binary_values(concat_row_lists(rows, "station_reservation_ids")),
      "must equal row-derived station_reservation_ids"
    )
    |> expect_optional_list_field_equals(
      path,
      report,
      "station_reserved_bys",
      sorted_unique_binary_values(concat_row_lists(rows, "station_reserved_bys")),
      "must equal row-derived station_reserved_bys"
    )
    |> expect_optional_list_field_equals(
      path,
      report,
      "station_reservation_statuses",
      sorted_unique_binary_values(concat_row_lists(rows, "station_reservation_statuses")),
      "must equal row-derived station_reservation_statuses"
    )
    |> expect_field_equals(
      path,
      report,
      "ignored_selected_contact_reason_counts",
      merge_row_count_maps(rows, "ignored_selected_contact_reason_counts"),
      "must equal row-derived ignored_selected_contact_reason_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "unmatched_selected_contact_ids",
      optional_sorted_unique_binary_list(report, "unmatched_selected_contact_ids"),
      "must equal deterministic unmatched_selected_contact_ids"
    )
    |> expect_field_equals(
      path,
      report,
      "unmatched_selected_contact_count",
      list_count(report, "unmatched_selected_contact_ids"),
      "must equal unmatched_selected_contact_ids count"
    )
    |> expect_field_equals(
      path,
      report,
      "invalid_policy_required_downlink_station_ids",
      optional_sorted_unique_binary_list(report, "invalid_policy_required_downlink_station_ids"),
      "must equal deterministic invalid_policy_required_downlink_station_ids"
    )
    |> expect_field_equals(
      path,
      report,
      "invalid_policy_required_downlink_station_count",
      list_count(report, "invalid_policy_required_downlink_station_ids"),
      "must equal invalid_policy_required_downlink_station_ids count"
    )
  end

  defp validate_report_assumptions(issues, path, artifact) do
    case Map.get(artifact, "assumptions") do
      %{} = assumptions ->
        issues
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "station_unavailable_aliases",
          station_unavailable_aliases(),
          "must match LinkCapacity station unavailable aliases"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "station_availability_precedence",
          station_availability_precedence(),
          "must match LinkCapacity station availability precedence"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "station_capacity_value_paths",
          station_capacity_value_path_assumptions(),
          "must match LinkCapacity station capacity value paths"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "source_station_capacity_value_paths",
          source_station_capacity_value_path_assumptions(),
          "must match LinkCapacity source station capacity value paths"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "provider_direction_aliases",
          provider_direction_aliases(),
          "must match LinkCapacity provider direction aliases"
        )

      _assumptions ->
        issues
    end
  end

  defp validate_optional_link_budgets(issues, path, report) do
    case Map.get(report, "downlink_link_budgets") do
      budgets when is_list(budgets) ->
        budgets
        |> Enum.with_index()
        |> Enum.reduce(issues, fn {budget, index}, acc ->
          OrbitalDynamics.Schema.DownlinkLinkBudgetContracts.validate(
            acc,
            "#{path}.downlink_link_budgets[#{index}]",
            budget
          )
        end)

      _budgets ->
        issues
    end
  end

  defp validate_report_model_limits(issues, path, report) do
    expected =
      OrbitalDynamics.Communications.LinkCapacity.report_model_limits(
        list_value(report, "downlink_link_budgets")
      )

    if Map.get(report, "model_limits") == expected do
      issues
    else
      [
        error(path <> ".model_limits", "must match link capacity capability model limits")
        | issues
      ]
    end
  end

  defp validate_link_budget_membership(issues, path, report, rows, budgets) do
    budget_context_fields =
      ~w(downlink_link_budget_count downlink_link_budget_ids downlink_link_budgets)

    issues =
      if budgets == [] do
        if Enum.any?(budget_context_fields, &Map.has_key?(report, &1)) do
          [
            error(path <> ".downlink_link_budgets", "empty link-budget context must be omitted")
            | issues
          ]
        else
          issues
        end
      else
        Enum.reduce(budget_context_fields, issues, fn field, acc ->
          if Map.has_key?(report, field),
            do: acc,
            else: [
              error(path <> ".#{field}", "is required for complete link-budget membership") | acc
            ]
        end)
      end

    budgets_by_id =
      budgets
      |> Enum.filter(&is_map/1)
      |> Map.new(&{&1["id"], &1})

    budget_ids =
      Enum.map(budgets, fn budget -> if is_map(budget), do: budget["id"], else: nil end)

    issues =
      if length(Enum.uniq(budget_ids)) == length(budget_ids) do
        issues
      else
        [error(path <> ".downlink_link_budgets", "budget IDs must be unique") | issues]
      end

    {issues, referenced_ids} =
      rows
      |> Enum.with_index()
      |> Enum.reduce({issues, []}, fn {row, row_index}, {acc, referenced} ->
        ids = list_value(row, "downlink_link_budget_ids")
        contact_ids = list_value(row, "downlink_link_budget_contact_ids")

        acc =
          if ids == [] and Map.has_key?(row, "downlink_link_budget_count") do
            [
              error(
                "#{path}.rows[#{row_index}].downlink_link_budget_count",
                "empty station link-budget context must be omitted"
              )
              | acc
            ]
          else
            acc
          end

        acc =
          ids
          |> Enum.with_index()
          |> Enum.reduce(acc, fn {id, budget_index}, inner_acc ->
            case Map.get(budgets_by_id, id) do
              %{} = budget ->
                binding = Map.get(budget, "contact_binding", %{})

                inner_acc
                |> expect_membership_value(
                  "#{path}.rows[#{row_index}].downlink_link_budget_contact_ids[#{budget_index}]",
                  Enum.at(contact_ids, budget_index),
                  binding["contact_id"]
                )
                |> expect_membership_value(
                  "#{path}.rows[#{row_index}].ground_station_id",
                  row["ground_station_id"],
                  binding["ground_station_id"]
                )
                |> expect_membership_in_list(
                  "#{path}.rows[#{row_index}].contact_ids",
                  binding["contact_id"],
                  list_value(row, "contact_ids")
                )
                |> validate_station_budget_direction(path, row, row_index, binding)

              nil ->
                [
                  error(
                    "#{path}.rows[#{row_index}].downlink_link_budget_ids[#{budget_index}]",
                    "must resolve to complete top-level downlink_link_budgets membership"
                  )
                  | inner_acc
                ]
            end
          end)

        {acc, referenced ++ ids}
      end)

    if Enum.sort(referenced_ids) == Enum.sort(budget_ids) do
      issues
    else
      [
        error(
          path <> ".downlink_link_budgets",
          "must equal the complete, single station-row link-budget membership"
        )
        | issues
      ]
    end
  end

  defp expect_membership_value(issues, path, actual, expected) do
    if actual == expected,
      do: issues,
      else: [error(path, "must match top-level downlink_link_budget evidence") | issues]
  end

  defp expect_membership_in_list(issues, path, expected, values) do
    if expected in values,
      do: issues,
      else: [error(path, "must contain each bound link-budget contact ID") | issues]
  end

  defp validate_station_budget_direction(issues, path, row, row_index, binding) do
    case Map.get(row, "station_calendar_directions") do
      directions when is_list(directions) and directions != [] ->
        expect_membership_in_list(
          issues,
          "#{path}.rows[#{row_index}].station_calendar_directions",
          binding["direction"],
          directions
        )

      _directions ->
        issues
    end
  end

  defp list_value(map, field) do
    case Map.get(map, field) do
      values when is_list(values) -> values
      _value -> []
    end
  end

  defp sum_row_numbers(rows, field) do
    Enum.reduce(rows, 0, fn row, total ->
      case Map.get(row, field) do
        value when is_number(value) -> total + value
        _value -> total
      end
    end)
  end

  defp concat_row_lists(rows, field) do
    rows
    |> Enum.flat_map(fn row ->
      case Map.get(row, field) do
        values when is_list(values) -> values
        _value -> []
      end
    end)
  end

  defp concat_optional_row_lists(rows, field) do
    case concat_row_lists(rows, field) do
      [] -> nil
      values -> values
    end
  end

  defp optional_sorted_unique_binary_list(report, field) do
    case Map.get(report, field) do
      values when is_list(values) -> sorted_unique_binary_values(values)
      _values -> nil
    end
  end

  defp sorted_unique_binary_values(values) do
    values
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp invalid_contact_input_ids(report, field, id_field) do
    case Map.get(report, field) do
      rows when is_list(rows) ->
        rows
        |> Enum.filter(&is_map/1)
        |> Enum.map(&Map.get(&1, id_field))

      _rows ->
        []
    end
  end

  defp merge_row_count_maps(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&is_map/1)
    |> Enum.reduce(%{}, fn counts, acc ->
      Enum.reduce(counts, acc, fn {key, value}, inner_acc ->
        if is_number(value), do: Map.update(inner_acc, key, value, &(&1 + value)), else: inner_acc
      end)
    end)
  end

  defp list_count(map, field) do
    case Map.get(map, field) do
      values when is_list(values) -> length(values)
      _value -> nil
    end
  end

  defp capability_value(key),
    do: OrbitalDynamics.Communications.LinkCapacity.capabilities() |> Map.fetch!(key)

  defp station_unavailable_aliases, do: capability_value(:station_unavailable_aliases)
  defp station_availability_precedence, do: capability_value(:station_availability_precedence)
  defp provider_direction_aliases, do: capability_value(:provider_direction_aliases)

  defp station_capacity_value_path_assumptions,
    do: :station_capacity_value_paths |> capability_value() |> capacity_value_path_assumptions()

  defp source_station_capacity_value_path_assumptions,
    do:
      :source_station_capacity_value_paths
      |> capability_value()
      |> capacity_value_path_assumptions()

  defp capacity_value_path_assumptions(paths) do
    Enum.map(paths, fn %{unit: unit, path: path} ->
      %{"unit" => Atom.to_string(unit), "path" => path}
    end)
  end

  defp validate_optional_stable_id_array_map(issues, path, map, field) do
    issues
    |> expect_optional_type(path, map, field, :map)
    |> validate_stable_id_array_map("#{path}.#{field}", Map.get(map, field))
  end
end
