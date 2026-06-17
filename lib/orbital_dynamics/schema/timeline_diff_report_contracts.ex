defmodule OrbitalDynamics.Schema.TimelineDiffReportContracts do
  @moduledoc false

  def validate(issues, path, report, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(callbacks, path, report, "schema_contract", "timeline_diff_report.v1")
    |> expect_equal(callbacks, path, report, "model", "timeline_identity_activity_diff")
    |> expect_type(callbacks, path, report, "source", :binary)
    |> expect_non_negative_integer(callbacks, path, report, "source_activity_count")
    |> expect_non_negative_integer(callbacks, path, report, "replacement_activity_count")
    |> expect_non_negative_integer(callbacks, path, report, "row_count")
    |> expect_non_negative_integer(callbacks, path, report, "added_count")
    |> expect_non_negative_integer(callbacks, path, report, "removed_count")
    |> expect_non_negative_integer(callbacks, path, report, "changed_count")
    |> expect_non_negative_integer(callbacks, path, report, "unchanged_count")
    |> expect_non_negative_integer(callbacks, path, report, "review_required_count")
    |> expect_optional_type(callbacks, path, report, "diff_status_counts", :map)
    |> expect_optional_type(callbacks, path, report, "required_operator_action_counts", :map)
    |> expect_optional_type(callbacks, path, report, "transition_decision_counts", :map)
    |> expect_optional_type(callbacks, path, report, "changed_field_counts", :map)
    |> expect_optional_type(callbacks, path, report, "status_transition_counts", :map)
    |> expect_optional_type(callbacks, path, report, "approval_transition_counts", :map)
    |> expect_optional_type(callbacks, path, report, "status_transition_category_counts", :map)
    |> expect_optional_type(callbacks, path, report, "approval_transition_category_counts", :map)
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
      "duplicate_source_timeline_identity_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "duplicate_replacement_timeline_identity_count"
    )
    |> expect_optional_type(callbacks, path, report, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      report,
      timeline_report_model_limits(callbacks),
      "must match timeline report model limits"
    )
    |> expect_type(callbacks, path, report, "rows", :list)
    |> expect_type(callbacks, path, report, "assumptions", :map)
    |> validate_counts(callbacks, path, report)
    |> validate_rows(
      callbacks,
      path <> ".rows",
      Map.get(report, "rows", []),
      fn acc, row_path, row -> validate_timeline_diff_row(callbacks, acc, row_path, row) end
    )
  end

  defp validate_counts(issues, callbacks, path, report) do
    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    issues
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".diff_status_counts",
      Map.get(report, "diff_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".required_operator_action_counts",
      Map.get(report, "required_operator_action_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".transition_decision_counts",
      Map.get(report, "transition_decision_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".changed_field_counts",
      Map.get(report, "changed_field_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".status_transition_counts",
      Map.get(report, "status_transition_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".approval_transition_counts",
      Map.get(report, "approval_transition_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".status_transition_category_counts",
      Map.get(report, "status_transition_category_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".approval_transition_category_counts",
      Map.get(report, "approval_transition_category_counts")
    )
    |> expect_field_equals(callbacks, path, report, "row_count", length(rows))
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "added_count",
      Enum.count(rows, &(&1["diff_status"] == "added"))
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "removed_count",
      Enum.count(rows, &(&1["diff_status"] == "removed"))
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "changed_count",
      Enum.count(rows, &(&1["diff_status"] == "changed"))
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "unchanged_count",
      Enum.count(rows, &(&1["diff_status"] == "unchanged"))
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "review_required_count",
      Enum.count(rows, &(&1["requires_operator_review"] == true))
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "diff_status_counts",
      frequency_map(callbacks, rows, "diff_status"),
      "must equal row-derived diff_status_counts"
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
      "transition_decision_counts",
      frequency_map(callbacks, rows, "transition_decision"),
      "must equal row-derived transition_decision_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "changed_field_counts",
      changed_field_frequency_map(callbacks, rows),
      "must equal row-derived changed_field_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "status_transition_counts",
      nested_frequency_map(callbacks, rows, "status_transition", "transition_type"),
      "must equal row-derived status_transition_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "approval_transition_counts",
      nested_frequency_map(callbacks, rows, "approval_transition", "transition_type"),
      "must equal row-derived approval_transition_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "status_transition_category_counts",
      nested_frequency_map(callbacks, rows, "status_transition", "transition_category"),
      "must equal row-derived status_transition_category_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "approval_transition_category_counts",
      nested_frequency_map(callbacks, rows, "approval_transition", "transition_category"),
      "must equal row-derived approval_transition_category_counts"
    )
  end

  defp timeline_report_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :timeline_report_model_limits), [])

  defp frequency_map(callbacks, rows, field),
    do: apply(Keyword.fetch!(callbacks, :frequency_map), [rows, field])

  defp nested_frequency_map(callbacks, rows, field, nested_field),
    do: apply(Keyword.fetch!(callbacks, :nested_frequency_map), [rows, field, nested_field])

  defp changed_field_frequency_map(callbacks, rows),
    do: apply(Keyword.fetch!(callbacks, :changed_field_frequency_map), [rows])

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

  defp validate_non_negative_integer_count_map(issues, callbacks, path, counts),
    do:
      apply(Keyword.fetch!(callbacks, :validate_non_negative_integer_count_map), [
        issues,
        path,
        counts
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

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(Keyword.fetch!(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_timeline_diff_row(callbacks, issues, path, row),
    do: apply(Keyword.fetch!(callbacks, :validate_timeline_diff_row), [issues, path, row])
end
