defmodule OrbitalDynamics.Schema.OperationalTimelineReportContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionAggregation,
    only: [frequency_map: 2, sum_row_numbers: 2]

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_optional_non_negative_integer: 4,
      expect_optional_type: 5,
      expect_type: 5,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_optional_stable_id_list: 4]

  def validate(issues, path, report, timeline_report_model_limits, row_validator)
      when is_list(timeline_report_model_limits) and is_function(row_validator, 3) do
    issues
    |> expect_equal(path, report, "schema_contract", "operational_timeline_report.v1")
    |> expect_equal(
      path,
      report,
      "model",
      "selected_activity_operational_context_summary"
    )
    |> expect_type(path, report, "source", :binary)
    |> expect_non_negative_integer(path, report, "activity_count")
    |> expect_non_negative_integer(path, report, "row_count")
    |> expect_non_negative_integer(path, report, "contact_count")
    |> expect_non_negative_integer(path, report, "command_count")
    |> expect_non_negative_integer(path, report, "locked_count")
    |> expect_non_negative_integer(path, report, "approved_count")
    |> expect_non_negative_integer(path, report, "executed_count")
    |> expect_non_negative_integer(path, report, "source_window_lineage_count")
    |> expect_optional_non_negative_integer(path, report, "valid_activity_count")
    |> expect_optional_non_negative_integer(
      path,
      report,
      "invalid_activity_input_count"
    )
    |> expect_optional_type(path, report, "invalid_activity_input_ids", :list)
    |> validate_optional_stable_id_list(path, report, "invalid_activity_input_ids")
    |> expect_optional_non_negative_integer(path, report, "terminal_exception_count")
    |> expect_optional_type(path, report, "activity_status_counts", :map)
    |> expect_optional_type(path, report, "approval_status_counts", :map)
    |> expect_optional_type(path, report, "required_operator_action_counts", :map)
    |> expect_optional_type(path, report, "cadence_import_status_counts", :map)
    |> expect_optional_type(path, report, "operational_kind_counts", :map)
    |> expect_optional_non_negative_integer(
      path,
      report,
      "execution_uncertainty_declared_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      report,
      "execution_uncertainty_missing_count"
    )
    |> expect_optional_non_negative_integer(path, report, "dependency_count")
    |> expect_optional_non_negative_integer(path, report, "dependency_issue_count")
    |> expect_optional_non_negative_integer(path, report, "exclusivity_count")
    |> expect_optional_non_negative_integer(path, report, "exclusivity_issue_count")
    |> expect_optional_non_negative_integer(
      path,
      report,
      "timeline_integrity_review_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      report,
      "timeline_integrity_issue_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      report,
      "duplicate_timeline_identity_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      report,
      "duplicate_timeline_identity_activity_count"
    )
    |> expect_optional_type(path, report, "model_limits", :list)
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      report,
      timeline_report_model_limits,
      "must match timeline model limits"
    )
    |> expect_type(path, report, "rows", :list)
    |> expect_type(path, report, "assumptions", :map)
    |> validate_rows(
      path <> ".rows",
      Map.get(report, "rows", []),
      row_validator
    )
    |> validate_counts(path, report)
  end

  defp validate_counts(issues, path, report) do
    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    issues
    |> expect_field_equals(path, report, "row_count", length(rows))
    |> expect_field_equals(path, report, "activity_count", length(rows))
    |> expect_field_equals(
      path,
      report,
      "contact_count",
      Enum.count(rows, &operational_contact_row?/1)
    )
    |> expect_field_equals(
      path,
      report,
      "command_count",
      Enum.count(rows, &operational_command_row?/1)
    )
    |> expect_field_equals(
      path,
      report,
      "locked_count",
      Enum.count(rows, & &1["locked"])
    )
    |> expect_field_equals(
      path,
      report,
      "approved_count",
      Enum.count(rows, &operational_approved_row?/1)
    )
    |> expect_field_equals(
      path,
      report,
      "executed_count",
      Enum.count(rows, &operational_executed_row?/1)
    )
    |> expect_field_equals(
      path,
      report,
      "terminal_exception_count",
      Enum.count(rows, &operational_terminal_exception_row?/1)
    )
    |> expect_field_equals(
      path,
      report,
      "activity_status_counts",
      frequency_map(rows, "status"),
      "must equal row-derived activity_status_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "approval_status_counts",
      frequency_map(rows, "approval_status"),
      "must equal row-derived approval_status_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "required_operator_action_counts",
      frequency_map(rows, "required_operator_action"),
      "must equal row-derived required_operator_action_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "cadence_import_status_counts",
      frequency_map(rows, "cadence_import_status"),
      "must equal row-derived cadence_import_status_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "operational_kind_counts",
      frequency_map(rows, "operational_kind"),
      "must equal row-derived operational_kind_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "execution_uncertainty_declared_count",
      Enum.count(rows, &(&1["execution_uncertainty_status"] == "declared"))
    )
    |> expect_field_equals(
      path,
      report,
      "execution_uncertainty_missing_count",
      Enum.count(rows, &(&1["execution_uncertainty_status"] == "missing"))
    )
    |> expect_field_equals(
      path,
      report,
      "dependency_count",
      Enum.count(rows, &operational_dependency_row?/1)
    )
    |> expect_field_equals(
      path,
      report,
      "exclusivity_count",
      Enum.count(rows, &operational_exclusivity_row?/1)
    )
    |> expect_field_equals(
      path,
      report,
      "timeline_integrity_review_count",
      Enum.count(rows, &(&1["timeline_integrity_status"] == "review_required"))
    )
    |> expect_field_equals(
      path,
      report,
      "timeline_integrity_issue_count",
      sum_row_numbers(rows, "timeline_integrity_issue_count")
    )
    |> expect_field_equals(
      path,
      report,
      "dependency_issue_count",
      operational_dependency_issue_count(rows)
    )
    |> expect_field_equals(
      path,
      report,
      "exclusivity_issue_count",
      operational_exclusivity_issue_count(rows)
    )
    |> expect_field_equals(
      path,
      report,
      "duplicate_timeline_identity_count",
      operational_duplicate_timeline_group_count(rows)
    )
    |> expect_field_equals(
      path,
      report,
      "duplicate_timeline_identity_activity_count",
      operational_duplicate_timeline_activity_count(rows)
    )
    |> expect_field_equals(
      path,
      report,
      "invalid_activity_input_ids",
      operational_invalid_activity_ids(rows),
      "must equal row-derived invalid_activity_input_ids"
    )
    |> expect_field_equals(
      path,
      report,
      "invalid_activity_input_count",
      Enum.count(rows, &(&1["invalid_activity_input"] == true))
    )
    |> expect_field_equals(
      path,
      report,
      "valid_activity_count",
      Enum.count(rows, &(&1["invalid_activity_input"] != true))
    )
  end

  defp operational_contact_row?(row), do: OrbitalDynamics.Timeline.contact_timeline_row?(row)
  defp operational_command_row?(row), do: OrbitalDynamics.Timeline.command_timeline_row?(row)

  defp operational_approved_row?(row),
    do: row["approval_status"] in ["approved", "auto_approvable"]

  defp operational_executed_row?(row), do: row["status"] in ["completed", "partial", "executed"]

  defp operational_terminal_exception_row?(row) do
    row["status"] in ["missed", "failed", "canceled", "cancelled", "rejected"] or
      row["operator_action_reason"] in [
        "contact_success_false_requires_review",
        "command_success_false_requires_review"
      ] or operational_provider_result_failure?(row["contact_result"]) or
      operational_provider_result_failure?(row["command_result"])
  end

  defp operational_provider_result_failure?(result) when is_binary(result) do
    result
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.downcase/1)
    |> Enum.map(&String.replace(&1, ~r/[\s-]+/, "_"))
    |> Enum.any?(
      &(&1 in [
          "rejected",
          "failed",
          "failure",
          "timeout",
          "timed_out",
          "aborted",
          "error",
          "dropped",
          "lost",
          "missed",
          "canceled",
          "cancelled",
          "no_contact"
        ])
    )
  end

  defp operational_provider_result_failure?(_result), do: false

  defp operational_dependency_row?(row) do
    non_empty_list?(row["dependency_activity_ids"]) or
      non_empty_list?(row["dependency_timeline_ids"])
  end

  defp operational_exclusivity_row?(row) do
    non_empty_list?(row["exclusive_with_activity_ids"]) or
      non_empty_list?(row["exclusive_with_timeline_ids"])
  end

  defp operational_dependency_issue_count(rows) do
    rows
    |> Enum.flat_map(&list_value(&1, "timeline_integrity_issues"))
    |> Enum.count(fn issue ->
      is_map(issue) and dependency_issue_type?(Map.get(issue, "type"))
    end)
  end

  defp operational_exclusivity_issue_count(rows) do
    rows
    |> Enum.flat_map(&list_value(&1, "timeline_integrity_issues"))
    |> Enum.count(fn issue ->
      is_map(issue) and exclusivity_issue_type?(Map.get(issue, "type"))
    end)
  end

  defp dependency_issue_type?(type) when is_binary(type), do: String.contains?(type, "dependency")
  defp dependency_issue_type?(_type), do: false

  defp exclusivity_issue_type?(type) when is_binary(type),
    do: String.contains?(type, "exclusivity")

  defp exclusivity_issue_type?(_type), do: false

  defp operational_duplicate_timeline_group_count(rows) do
    rows
    |> operational_rows_by_timeline_id()
    |> Enum.count(fn {_timeline_id, grouped_rows} -> length(grouped_rows) > 1 end)
  end

  defp operational_duplicate_timeline_activity_count(rows) do
    rows
    |> operational_rows_by_timeline_id()
    |> Enum.filter(fn {_timeline_id, grouped_rows} -> length(grouped_rows) > 1 end)
    |> Enum.reduce(0, fn {_timeline_id, grouped_rows}, total -> total + length(grouped_rows) end)
  end

  defp operational_rows_by_timeline_id(rows) do
    rows
    |> Enum.group_by(&Map.get(&1, "timeline_id"))
    |> Enum.reject(fn {timeline_id, _rows} -> is_nil(timeline_id) end)
  end

  defp operational_invalid_activity_ids(rows) do
    rows
    |> Enum.filter(&(&1["invalid_activity_input"] == true))
    |> Enum.map(&Map.get(&1, "activity_id"))
    |> Enum.reject(&is_nil/1)
  end

  defp non_empty_list?(value), do: is_list(value) and value != []
  defp list_value(map, key) when is_map(map), do: Map.get(map, key) || []
  defp list_value(_map, _key), do: []

  defp expect_field_equals(issues, path, map, field, nil),
    do: expect_field_equals(issues, path, map, field, nil, nil)

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")
end
