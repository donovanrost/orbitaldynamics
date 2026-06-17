defmodule OrbitalDynamics.Schema.LinkCapacityReportContracts do
  @moduledoc false

  def validate(issues, path, report, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(callbacks, path, report, "schema_contract", "link_capacity_report.v1")
    |> expect_equal(callbacks, path, report, "model", "fixed_rate_downlink_capacity_summary")
    |> expect_type(callbacks, path, report, "source", :binary)
    |> expect_non_negative_integer(callbacks, path, report, "contact_count")
    |> expect_non_negative_integer(callbacks, path, report, "selected_contact_count")
    |> expect_number(callbacks, path, report, "estimated_throughput_mb")
    |> expect_number(callbacks, path, report, "selected_estimated_throughput_mb")
    |> expect_optional_number(callbacks, path, report, "capacity_adjusted_throughput_mb")
    |> expect_optional_number(callbacks, path, report, "selected_capacity_adjusted_throughput_mb")
    |> expect_optional_number(callbacks, path, report, "unused_capacity_adjusted_throughput_mb")
    |> expect_optional_probability(
      callbacks,
      path,
      report,
      "selected_capacity_utilization_fraction"
    )
    |> expect_optional_type(callbacks, path, report, "selection_utilization_status", :binary)
    |> expect_optional_non_negative_integer(callbacks, path, report, "effective_contact_count")
    |> expect_optional_non_negative_integer(callbacks, path, report, "ignored_contact_count")
    |> expect_optional_type(callbacks, path, report, "ignored_contact_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, report, "ignored_contact_ids")
    |> expect_optional_type(callbacks, path, report, "ignored_contact_reason_counts", :map)
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "ignored_selected_contact_count"
    )
    |> expect_optional_type(callbacks, path, report, "ignored_selected_contact_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, report, "ignored_selected_contact_ids")
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "ignored_selected_contact_reason_counts",
      :map
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "ambiguous_selected_contact_id_count"
    )
    |> expect_optional_type(callbacks, path, report, "ambiguous_selected_contact_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, report, "ambiguous_selected_contact_ids")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "duplicate_contact_candidate_count"
    )
    |> expect_optional_non_negative_integer(callbacks, path, report, "duplicate_contact_id_count")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "unmatched_selected_contact_count"
    )
    |> expect_optional_type(callbacks, path, report, "unmatched_selected_contact_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, report, "unmatched_selected_contact_ids")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "invalid_policy_required_downlink_station_count"
    )
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "invalid_policy_required_downlink_station_ids",
      :list
    )
    |> validate_string_list_items(
      callbacks,
      path,
      report,
      "invalid_policy_required_downlink_station_ids"
    )
    |> expect_optional_number(callbacks, path, report, "required_downlink_mb")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "required_downlink_contact_count"
    )
    |> expect_optional_type(callbacks, path, report, "required_downlink_contact_ids", :list)
    |> validate_string_list_items(callbacks, path, report, "required_downlink_contact_ids")
    |> expect_optional_number(callbacks, path, report, "selected_downlink_shortfall_mb")
    |> expect_optional_type(callbacks, path, report, "downlink_requirement_status", :binary)
    |> expect_optional_number(callbacks, path, report, "actual_throughput_mb")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "actual_throughput_contact_count"
    )
    |> expect_optional_type(callbacks, path, report, "actual_throughput_contact_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, report, "actual_throughput_contact_ids")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "actual_completion_contact_count"
    )
    |> expect_optional_type(callbacks, path, report, "actual_completion_contact_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, report, "actual_completion_contact_ids")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "unmatched_actual_throughput_contact_count"
    )
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "unmatched_actual_throughput_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      report,
      "unmatched_actual_throughput_contact_ids"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "ambiguous_actual_throughput_contact_count"
    )
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "ambiguous_actual_throughput_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      report,
      "ambiguous_actual_throughput_contact_ids"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "unmatched_actual_completion_contact_count"
    )
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "unmatched_actual_completion_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      report,
      "unmatched_actual_completion_contact_ids"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "ambiguous_actual_completion_contact_count"
    )
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "ambiguous_actual_completion_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      report,
      "ambiguous_actual_completion_contact_ids"
    )
    |> expect_optional_probability(callbacks, path, report, "actual_downlink_completion_ratio")
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "actual_data_rate_throughput_derivations",
      :list
    )
    |> validate_optional_actual_data_rate_throughput_derivations(
      callbacks,
      path,
      report,
      "actual_data_rate_throughput_derivations"
    )
    |> expect_optional_type(callbacks, path, report, "station_reservation_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, report, "station_reservation_ids")
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "station_reservation_expiration_status_counts",
      :map
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".station_reservation_expiration_status_counts",
      Map.get(report, "station_reservation_expiration_status_counts")
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "station_reservation_declared_expiration_contact_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "station_reservation_missing_expiration_contact_count"
    )
    |> expect_optional_number(
      callbacks,
      path,
      report,
      "earliest_station_reservation_expires_at_s"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      report,
      "station_reservation_contact_ids_by_expiration_status"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      report,
      "station_reservation_ids_by_expiration_status"
    )
    |> expect_optional_type(callbacks, path, report, "station_reserved_bys", :list)
    |> validate_string_list_items(callbacks, path, report, "station_reserved_bys")
    |> expect_optional_type(callbacks, path, report, "station_reservation_statuses", :list)
    |> validate_string_list_items(callbacks, path, report, "station_reservation_statuses")
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "station_reservation_match_status_counts",
      :map
    )
    |> expect_optional_type(callbacks, path, report, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      report,
      model_limits(),
      "must match link capacity capability model limits"
    )
    |> expect_type(callbacks, path, report, "rows", :list)
    |> expect_type(callbacks, path, report, "assumptions", :map)
    |> validate_report_assumptions(callbacks, path, report)
    |> validate_rows(
      callbacks,
      path <> ".rows",
      Map.get(report, "rows", []),
      fn acc, row_path, row -> validate_row(acc, row_path, row, callbacks) end
    )
    |> validate_report_counts(callbacks, path, report)
  end

  def validate_assumptions(issues, path, artifact, callbacks) when is_list(callbacks) do
    validate_report_assumptions(issues, callbacks, path, artifact)
  end

  defp validate_row(issues, path, row, callbacks) do
    issues
    |> require_fields(callbacks, path, row, [
      "ground_station_id",
      "contact_count",
      "selected_contact_count",
      "estimated_throughput_mb",
      "selected_estimated_throughput_mb",
      "contact_ids",
      "selected_contact_ids"
    ])
    |> validate_stable_ids(callbacks, path, row, ["ground_station_id"])
    |> expect_non_negative_integer(callbacks, path, row, "contact_count")
    |> expect_non_negative_integer(callbacks, path, row, "selected_contact_count")
    |> expect_number(callbacks, path, row, "estimated_throughput_mb")
    |> expect_number(callbacks, path, row, "selected_estimated_throughput_mb")
    |> expect_optional_number(callbacks, path, row, "capacity_adjusted_throughput_mb")
    |> expect_optional_number(callbacks, path, row, "selected_capacity_adjusted_throughput_mb")
    |> expect_optional_number(callbacks, path, row, "unused_capacity_adjusted_throughput_mb")
    |> expect_optional_probability(callbacks, path, row, "selected_capacity_utilization_fraction")
    |> expect_optional_type(callbacks, path, row, "selection_utilization_status", :binary)
    |> expect_optional_probability(callbacks, path, row, "capacity_fraction_min")
    |> expect_optional_probability(callbacks, path, row, "capacity_fraction_max")
    |> expect_type(callbacks, path, row, "contact_ids", :list)
    |> expect_type(callbacks, path, row, "selected_contact_ids", :list)
    |> expect_optional_non_negative_integer(callbacks, path, row, "effective_contact_count")
    |> expect_optional_non_negative_integer(callbacks, path, row, "ignored_contact_count")
    |> expect_optional_type(callbacks, path, row, "ignored_contact_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "ignored_contact_ids")
    |> expect_optional_type(callbacks, path, row, "ignored_contact_reason_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      "#{path}.ignored_contact_reason_counts",
      Map.get(row, "ignored_contact_reason_counts")
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      row,
      "ignored_selected_contact_count"
    )
    |> expect_optional_type(callbacks, path, row, "ignored_selected_contact_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "ignored_selected_contact_ids")
    |> expect_optional_type(callbacks, path, row, "ignored_selected_contact_reason_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      "#{path}.ignored_selected_contact_reason_counts",
      Map.get(row, "ignored_selected_contact_reason_counts")
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      row,
      "ambiguous_selected_contact_id_count"
    )
    |> expect_optional_type(callbacks, path, row, "ambiguous_selected_contact_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "ambiguous_selected_contact_ids")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      row,
      "duplicate_contact_candidate_count"
    )
    |> expect_optional_type(callbacks, path, row, "duplicate_contact_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "duplicate_contact_ids")
    |> expect_optional_type(callbacks, path, row, "station_calendar_entry_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "station_calendar_entry_ids")
    |> expect_optional_type(callbacks, path, row, "station_calendar_provider_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "station_calendar_provider_ids")
    |> expect_optional_type(callbacks, path, row, "station_calendar_provider_entry_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "station_calendar_provider_entry_ids"
    )
    |> expect_optional_type(callbacks, path, row, "station_calendar_directions", :list)
    |> validate_string_list_items(callbacks, path, row, "station_calendar_directions")
    |> expect_optional_type(callbacks, path, row, "station_reservation_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "station_reservation_ids")
    |> expect_optional_type(callbacks, path, row, "station_reserved_bys", :list)
    |> validate_string_list_items(callbacks, path, row, "station_reserved_bys")
    |> expect_optional_type(callbacks, path, row, "station_reservation_statuses", :list)
    |> validate_string_list_items(callbacks, path, row, "station_reservation_statuses")
    |> expect_optional_type(callbacks, path, row, "station_reservation_match_statuses", :list)
    |> validate_string_list_items(callbacks, path, row, "station_reservation_match_statuses")
    |> expect_optional_number(callbacks, path, row, "actual_throughput_mb")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      row,
      "actual_throughput_contact_count"
    )
    |> expect_optional_type(callbacks, path, row, "actual_throughput_contact_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "actual_throughput_contact_ids")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      row,
      "actual_completion_contact_count"
    )
    |> expect_optional_type(callbacks, path, row, "actual_completion_contact_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "actual_completion_contact_ids")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      row,
      "unmatched_actual_throughput_contact_count"
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "unmatched_actual_throughput_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "unmatched_actual_throughput_contact_ids"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      row,
      "ambiguous_actual_throughput_contact_count"
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "ambiguous_actual_throughput_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "ambiguous_actual_throughput_contact_ids"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      row,
      "unmatched_actual_completion_contact_count"
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "unmatched_actual_completion_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "unmatched_actual_completion_contact_ids"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      row,
      "ambiguous_actual_completion_contact_count"
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "ambiguous_actual_completion_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "ambiguous_actual_completion_contact_ids"
    )
    |> expect_optional_probability(callbacks, path, row, "actual_downlink_completion_ratio")
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "actual_data_rate_throughput_derivations",
      :list
    )
    |> validate_optional_actual_data_rate_throughput_derivations(
      callbacks,
      path,
      row,
      "actual_data_rate_throughput_derivations"
    )
    |> validate_row_counts(callbacks, path, row)
  end

  defp validate_row_counts(issues, callbacks, path, row) do
    issues
    |> expect_field_matches_list_count(
      callbacks,
      path,
      row,
      "contact_count",
      "contact_ids",
      "must equal contact_ids count"
    )
    |> expect_field_matches_list_count(
      callbacks,
      path,
      row,
      "selected_contact_count",
      "selected_contact_ids",
      "must equal selected_contact_ids count"
    )
    |> expect_field_matches_list_count(
      callbacks,
      path,
      row,
      "ignored_contact_count",
      "ignored_contact_ids",
      "must equal ignored_contact_ids count"
    )
    |> expect_field_matches_list_count(
      callbacks,
      path,
      row,
      "ignored_selected_contact_count",
      "ignored_selected_contact_ids",
      "must equal ignored_selected_contact_ids count"
    )
    |> expect_field_matches_list_count(
      callbacks,
      path,
      row,
      "ambiguous_selected_contact_id_count",
      "ambiguous_selected_contact_ids",
      "must equal ambiguous_selected_contact_ids count"
    )
    |> expect_field_matches_list_count(
      callbacks,
      path,
      row,
      "required_downlink_contact_count",
      "required_downlink_contact_ids",
      "must equal required_downlink_contact_ids count"
    )
    |> expect_field_matches_list_count(
      callbacks,
      path,
      row,
      "actual_throughput_contact_count",
      "actual_throughput_contact_ids",
      "must equal actual_throughput_contact_ids count"
    )
    |> expect_field_matches_list_count(
      callbacks,
      path,
      row,
      "actual_completion_contact_count",
      "actual_completion_contact_ids",
      "must equal actual_completion_contact_ids count"
    )
    |> expect_field_matches_list_count(
      callbacks,
      path,
      row,
      "unmatched_actual_throughput_contact_count",
      "unmatched_actual_throughput_contact_ids",
      "must equal unmatched_actual_throughput_contact_ids count"
    )
    |> expect_field_matches_list_count(
      callbacks,
      path,
      row,
      "ambiguous_actual_throughput_contact_count",
      "ambiguous_actual_throughput_contact_ids",
      "must equal ambiguous_actual_throughput_contact_ids count"
    )
    |> expect_field_matches_list_count(
      callbacks,
      path,
      row,
      "unmatched_actual_completion_contact_count",
      "unmatched_actual_completion_contact_ids",
      "must equal unmatched_actual_completion_contact_ids count"
    )
    |> expect_field_matches_list_count(
      callbacks,
      path,
      row,
      "ambiguous_actual_completion_contact_count",
      "ambiguous_actual_completion_contact_ids",
      "must equal ambiguous_actual_completion_contact_ids count"
    )
  end

  defp validate_report_counts(issues, callbacks, path, report) do
    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    issues
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "contact_count",
      sum_row_numbers(rows, "contact_count"),
      "must equal row-derived contact_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "selected_contact_count",
      sum_row_numbers(rows, "selected_contact_count"),
      "must equal row-derived selected_contact_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "estimated_throughput_mb",
      sum_row_numbers(rows, "estimated_throughput_mb"),
      "must equal row-derived estimated_throughput_mb"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "selected_estimated_throughput_mb",
      sum_row_numbers(rows, "selected_estimated_throughput_mb"),
      "must equal row-derived selected_estimated_throughput_mb"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "ignored_contact_ids",
      concat_row_lists(rows, "ignored_contact_ids"),
      "must equal row-derived ignored_contact_ids"
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      "#{path}.ignored_contact_reason_counts",
      Map.get(report, "ignored_contact_reason_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      "#{path}.ignored_selected_contact_reason_counts",
      Map.get(report, "ignored_selected_contact_reason_counts")
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "ignored_contact_reason_counts",
      merge_row_count_maps(rows, "ignored_contact_reason_counts"),
      "must equal row-derived ignored_contact_reason_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "invalid_contact_input_ids",
      invalid_contact_input_ids(report, "invalid_contact_inputs", "contact_id"),
      "must equal row-derived invalid_contact_input_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "required_downlink_contact_ids",
      concat_row_lists(rows, "required_downlink_contact_ids"),
      "must equal row-derived required_downlink_contact_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "required_downlink_contact_count",
      length(concat_row_lists(rows, "required_downlink_contact_ids")),
      "must equal row-derived required_downlink_contact_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "actual_throughput_contact_ids",
      concat_row_lists(rows, "actual_throughput_contact_ids"),
      "must equal row-derived actual_throughput_contact_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "actual_throughput_contact_count",
      length(concat_row_lists(rows, "actual_throughput_contact_ids")),
      "must equal row-derived actual_throughput_contact_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "actual_completion_contact_ids",
      concat_row_lists(rows, "actual_completion_contact_ids"),
      "must equal row-derived actual_completion_contact_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "actual_completion_contact_count",
      length(concat_row_lists(rows, "actual_completion_contact_ids")),
      "must equal row-derived actual_completion_contact_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "unmatched_actual_throughput_contact_ids",
      concat_row_lists(rows, "unmatched_actual_throughput_contact_ids"),
      "must equal row-derived unmatched_actual_throughput_contact_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "unmatched_actual_throughput_contact_count",
      length(concat_row_lists(rows, "unmatched_actual_throughput_contact_ids")),
      "must equal row-derived unmatched_actual_throughput_contact_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "ambiguous_actual_throughput_contact_ids",
      concat_row_lists(rows, "ambiguous_actual_throughput_contact_ids"),
      "must equal row-derived ambiguous_actual_throughput_contact_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "ambiguous_actual_throughput_contact_count",
      length(concat_row_lists(rows, "ambiguous_actual_throughput_contact_ids")),
      "must equal row-derived ambiguous_actual_throughput_contact_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "unmatched_actual_completion_contact_ids",
      concat_row_lists(rows, "unmatched_actual_completion_contact_ids"),
      "must equal row-derived unmatched_actual_completion_contact_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "unmatched_actual_completion_contact_count",
      length(concat_row_lists(rows, "unmatched_actual_completion_contact_ids")),
      "must equal row-derived unmatched_actual_completion_contact_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "ambiguous_actual_completion_contact_ids",
      concat_row_lists(rows, "ambiguous_actual_completion_contact_ids"),
      "must equal row-derived ambiguous_actual_completion_contact_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "ambiguous_actual_completion_contact_count",
      length(concat_row_lists(rows, "ambiguous_actual_completion_contact_ids")),
      "must equal row-derived ambiguous_actual_completion_contact_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "actual_data_rate_throughput_derivations",
      concat_optional_row_lists(rows, "actual_data_rate_throughput_derivations"),
      "must equal row-derived actual_data_rate_throughput_derivations"
    )
    |> expect_optional_list_field_equals(
      callbacks,
      path,
      report,
      "station_reservation_ids",
      sorted_unique_binary_values(concat_row_lists(rows, "station_reservation_ids")),
      "must equal row-derived station_reservation_ids"
    )
    |> expect_optional_list_field_equals(
      callbacks,
      path,
      report,
      "station_reserved_bys",
      sorted_unique_binary_values(concat_row_lists(rows, "station_reserved_bys")),
      "must equal row-derived station_reserved_bys"
    )
    |> expect_optional_list_field_equals(
      callbacks,
      path,
      report,
      "station_reservation_statuses",
      sorted_unique_binary_values(concat_row_lists(rows, "station_reservation_statuses")),
      "must equal row-derived station_reservation_statuses"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "ignored_selected_contact_reason_counts",
      merge_row_count_maps(rows, "ignored_selected_contact_reason_counts"),
      "must equal row-derived ignored_selected_contact_reason_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "unmatched_selected_contact_ids",
      optional_sorted_unique_binary_list(report, "unmatched_selected_contact_ids"),
      "must equal deterministic unmatched_selected_contact_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "unmatched_selected_contact_count",
      list_count(report, "unmatched_selected_contact_ids"),
      "must equal unmatched_selected_contact_ids count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "invalid_policy_required_downlink_station_ids",
      optional_sorted_unique_binary_list(report, "invalid_policy_required_downlink_station_ids"),
      "must equal deterministic invalid_policy_required_downlink_station_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "invalid_policy_required_downlink_station_count",
      list_count(report, "invalid_policy_required_downlink_station_ids"),
      "must equal invalid_policy_required_downlink_station_ids count"
    )
  end

  defp validate_report_assumptions(issues, callbacks, path, artifact) do
    case Map.get(artifact, "assumptions") do
      %{} = assumptions ->
        issues
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "station_unavailable_aliases",
          station_unavailable_aliases(),
          "must match LinkCapacity station unavailable aliases"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "station_availability_precedence",
          station_availability_precedence(),
          "must match LinkCapacity station availability precedence"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "station_capacity_value_paths",
          station_capacity_value_path_assumptions(),
          "must match LinkCapacity station capacity value paths"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "source_station_capacity_value_paths",
          source_station_capacity_value_path_assumptions(),
          "must match LinkCapacity source station capacity value paths"
        )
        |> expect_optional_field_equals(
          callbacks,
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

  defp model_limits, do: :known_limits |> capability_value() |> Enum.map(&Atom.to_string/1)
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

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :require_fields), [issues, path, map, fields])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(require_callback(callbacks, :expect_equal), [issues, path, map, field, expected])

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

  defp expect_number(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_number), [issues, path, map, field])

  defp expect_optional_number(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_optional_number), [issues, path, map, field])

  defp expect_optional_probability(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_probability), [issues, path, map, field])

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

  defp expect_optional_field_equals(issues, callbacks, path, map, field, expected, message),
    do:
      apply(require_callback(callbacks, :expect_optional_field_equals), [
        issues,
        path,
        map,
        field,
        expected,
        message
      ])

  defp expect_field_matches_list_count(
         issues,
         callbacks,
         path,
         map,
         count_field,
         list_field,
         message
       ),
       do:
         apply(require_callback(callbacks, :expect_field_matches_list_count), [
           issues,
           path,
           map,
           count_field,
           list_field,
           message
         ])

  defp expect_optional_list_field_equals(issues, callbacks, path, map, field, expected, message),
    do:
      apply(require_callback(callbacks, :expect_optional_list_field_equals), [
        issues,
        path,
        map,
        field,
        expected,
        message
      ])

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_optional_stable_id_list), [
        issues,
        path,
        map,
        field
      ])

  defp validate_optional_stable_id_array_map(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_optional_stable_id_array_map), [
        issues,
        path,
        map,
        field
      ])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_non_negative_integer_count_map(issues, callbacks, path, counts),
    do:
      apply(require_callback(callbacks, :validate_non_negative_integer_count_map), [
        issues,
        path,
        counts
      ])

  defp validate_optional_exact_model_limits(issues, callbacks, path, map, limits, message),
    do:
      apply(require_callback(callbacks, :validate_optional_exact_model_limits), [
        issues,
        path,
        map,
        limits,
        message
      ])

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(require_callback(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_optional_actual_data_rate_throughput_derivations(
         issues,
         callbacks,
         path,
         map,
         field
       ),
       do:
         apply(
           require_callback(
             callbacks,
             :validate_optional_actual_data_rate_throughput_derivations
           ),
           [
             issues,
             path,
             map,
             field
           ]
         )
end
