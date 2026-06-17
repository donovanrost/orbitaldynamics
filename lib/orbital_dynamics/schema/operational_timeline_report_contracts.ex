defmodule OrbitalDynamics.Schema.OperationalTimelineReportContracts do
  @moduledoc false

  def validate(issues, path, report, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(callbacks, path, report, "schema_contract", "operational_timeline_report.v1")
    |> expect_equal(
      callbacks,
      path,
      report,
      "model",
      "selected_activity_operational_context_summary"
    )
    |> expect_type(callbacks, path, report, "source", :binary)
    |> expect_non_negative_integer(callbacks, path, report, "activity_count")
    |> expect_non_negative_integer(callbacks, path, report, "row_count")
    |> expect_non_negative_integer(callbacks, path, report, "contact_count")
    |> expect_non_negative_integer(callbacks, path, report, "command_count")
    |> expect_non_negative_integer(callbacks, path, report, "locked_count")
    |> expect_non_negative_integer(callbacks, path, report, "approved_count")
    |> expect_non_negative_integer(callbacks, path, report, "executed_count")
    |> expect_non_negative_integer(callbacks, path, report, "source_window_lineage_count")
    |> expect_optional_non_negative_integer(callbacks, path, report, "valid_activity_count")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "invalid_activity_input_count"
    )
    |> expect_optional_type(callbacks, path, report, "invalid_activity_input_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, report, "invalid_activity_input_ids")
    |> expect_optional_non_negative_integer(callbacks, path, report, "terminal_exception_count")
    |> expect_optional_type(callbacks, path, report, "activity_status_counts", :map)
    |> expect_optional_type(callbacks, path, report, "approval_status_counts", :map)
    |> expect_optional_type(callbacks, path, report, "required_operator_action_counts", :map)
    |> expect_optional_type(callbacks, path, report, "cadence_import_status_counts", :map)
    |> expect_optional_type(callbacks, path, report, "operational_kind_counts", :map)
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "execution_uncertainty_declared_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "execution_uncertainty_missing_count"
    )
    |> expect_optional_non_negative_integer(callbacks, path, report, "dependency_count")
    |> expect_optional_non_negative_integer(callbacks, path, report, "dependency_issue_count")
    |> expect_optional_non_negative_integer(callbacks, path, report, "exclusivity_count")
    |> expect_optional_non_negative_integer(callbacks, path, report, "exclusivity_issue_count")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "timeline_integrity_review_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "timeline_integrity_issue_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "duplicate_timeline_identity_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "duplicate_timeline_identity_activity_count"
    )
    |> expect_optional_type(callbacks, path, report, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      report,
      timeline_report_model_limits(callbacks),
      "must match timeline model limits"
    )
    |> expect_type(callbacks, path, report, "rows", :list)
    |> expect_type(callbacks, path, report, "assumptions", :map)
    |> validate_rows(
      callbacks,
      path <> ".rows",
      Map.get(report, "rows", []),
      fn acc, row_path, row ->
        validate_operational_timeline_row(callbacks, acc, row_path, row)
      end
    )
    |> validate_counts(callbacks, path, report)
  end

  defp validate_counts(issues, callbacks, path, report) do
    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    issues
    |> expect_field_equals(callbacks, path, report, "row_count", length(rows))
    |> expect_field_equals(callbacks, path, report, "activity_count", length(rows))
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "contact_count",
      Enum.count(rows, &operational_contact_row?/1)
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "command_count",
      Enum.count(rows, &operational_command_row?/1)
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "locked_count",
      Enum.count(rows, & &1["locked"])
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "approved_count",
      Enum.count(rows, &operational_approved_row?/1)
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "executed_count",
      Enum.count(rows, &operational_executed_row?/1)
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "terminal_exception_count",
      Enum.count(rows, &operational_terminal_exception_row?/1)
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "activity_status_counts",
      frequency_map(callbacks, rows, "status"),
      "must equal row-derived activity_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "approval_status_counts",
      frequency_map(callbacks, rows, "approval_status"),
      "must equal row-derived approval_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "required_operator_action_counts",
      frequency_map(callbacks, rows, "required_operator_action"),
      "must equal row-derived required_operator_action_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "cadence_import_status_counts",
      frequency_map(callbacks, rows, "cadence_import_status"),
      "must equal row-derived cadence_import_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "operational_kind_counts",
      frequency_map(callbacks, rows, "operational_kind"),
      "must equal row-derived operational_kind_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "execution_uncertainty_declared_count",
      Enum.count(rows, &(&1["execution_uncertainty_status"] == "declared"))
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "execution_uncertainty_missing_count",
      Enum.count(rows, &(&1["execution_uncertainty_status"] == "missing"))
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "dependency_count",
      Enum.count(rows, &operational_dependency_row?/1)
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "exclusivity_count",
      Enum.count(rows, &operational_exclusivity_row?/1)
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "timeline_integrity_review_count",
      Enum.count(rows, &(&1["timeline_integrity_status"] == "review_required"))
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "timeline_integrity_issue_count",
      sum_row_numbers(callbacks, rows, "timeline_integrity_issue_count")
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "dependency_issue_count",
      operational_dependency_issue_count(rows)
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "exclusivity_issue_count",
      operational_exclusivity_issue_count(rows)
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "duplicate_timeline_identity_count",
      operational_duplicate_timeline_group_count(rows)
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "duplicate_timeline_identity_activity_count",
      operational_duplicate_timeline_activity_count(rows)
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "invalid_activity_input_ids",
      operational_invalid_activity_ids(rows),
      "must equal row-derived invalid_activity_input_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "invalid_activity_input_count",
      Enum.count(rows, &(&1["invalid_activity_input"] == true))
    )
    |> expect_field_equals(
      callbacks,
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

  defp timeline_report_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :timeline_report_model_limits), [])

  defp frequency_map(callbacks, rows, field),
    do: apply(Keyword.fetch!(callbacks, :frequency_map), [rows, field])

  defp sum_row_numbers(callbacks, rows, field),
    do: apply(Keyword.fetch!(callbacks, :sum_row_numbers), [rows, field])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(Keyword.fetch!(callbacks, :expect_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_optional_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(Keyword.fetch!(callbacks, :expect_optional_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_field_equals(issues, callbacks, path, map, field, expected),
    do:
      apply(Keyword.fetch!(callbacks, :expect_field_equals), [issues, path, map, field, expected])

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message),
    do:
      apply(Keyword.fetch!(callbacks, :expect_field_equals_with_message), [
        issues,
        path,
        map,
        field,
        expected,
        message
      ])

  defp validate_optional_exact_model_limits(issues, callbacks, path, report, expected, message),
    do:
      apply(Keyword.fetch!(callbacks, :validate_optional_exact_model_limits), [
        issues,
        path,
        report,
        expected,
        message
      ])

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field),
    do:
      apply(Keyword.fetch!(callbacks, :validate_optional_stable_id_list), [
        issues,
        path,
        map,
        field
      ])

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(Keyword.fetch!(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_operational_timeline_row(callbacks, issues, path, row),
    do: apply(Keyword.fetch!(callbacks, :validate_operational_timeline_row), [issues, path, row])
end
