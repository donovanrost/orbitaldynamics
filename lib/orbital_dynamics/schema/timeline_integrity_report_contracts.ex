defmodule OrbitalDynamics.Schema.TimelineIntegrityReportContracts do
  @moduledoc false

  def validate(issues, path, report, callbacks) when is_list(callbacks) do
    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    issues
    |> expect_equal(callbacks, path, report, "schema_contract", "timeline_integrity_report.v1")
    |> expect_equal(callbacks, path, report, "model", "artifact_only_timeline_integrity_summary")
    |> expect_equal(callbacks, path, report, "validation_level", "artifact_contract")
    |> expect_type(callbacks, path, report, "source", :binary)
    |> expect_one_of(callbacks, path, report, "timeline_integrity_status", [
      "clear",
      "review_required"
    ])
    |> validate_count_fields(callbacks, path, report)
    |> validate_id_fields(callbacks, path, report)
    |> expect_type(callbacks, path, report, "timeline_integrity_issue_types", :list)
    |> validate_string_list_allowed(
      callbacks,
      path,
      report,
      "timeline_integrity_issue_types",
      OrbitalDynamics.Timeline.capabilities().timeline_integrity_issue_types
    )
    |> expect_type(callbacks, path, report, "rows", :list)
    |> expect_type(callbacks, path, report, "assumptions", :map)
    |> expect_type(callbacks, path, report, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      report,
      timeline_report_model_limits(callbacks),
      "must match timeline report model limits"
    )
    |> validate_row_derived_fields(callbacks, path, report, rows)
    |> validate_rows(
      callbacks,
      path <> ".rows",
      Map.get(report, "rows", []),
      fn acc, row_path, row -> validate_row(acc, row_path, row, callbacks) end
    )
  end

  def validate_row(issues, path, row, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, row, [
      "activity_id",
      "timeline_id",
      "required_operator_action",
      "operator_action_reason",
      "timeline_integrity_status",
      "timeline_integrity_issue_count",
      "timeline_integrity_issue_types"
    ])
    |> validate_stable_ids(callbacks, path, row, ["activity_id", "timeline_id"])
    |> expect_equal(callbacks, path, row, "timeline_integrity_status", "review_required")
    |> expect_one_of(
      callbacks,
      path,
      row,
      "required_operator_action",
      OrbitalDynamics.Timeline.capabilities().required_operator_actions
    )
    |> expect_non_negative_integer(callbacks, path, row, "timeline_integrity_issue_count")
    |> expect_type(callbacks, path, row, "timeline_integrity_issue_types", :list)
    |> validate_string_list_allowed(
      callbacks,
      path,
      row,
      "timeline_integrity_issue_types",
      OrbitalDynamics.Timeline.capabilities().timeline_integrity_issue_types
    )
    |> expect_optional_type(callbacks, path, row, "timeline_integrity_issues", :list)
    |> validate_row_issues(callbacks, path, row)
    |> validate_row_id_lists(callbacks, path, row)
    |> expect_field_equals(
      callbacks,
      path,
      row,
      "timeline_integrity_issue_count",
      length(timeline_integrity_report_row_issues(row)),
      "must equal row-derived timeline_integrity_issue_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      row,
      "timeline_integrity_issue_types",
      timeline_integrity_report_row_issue_types(row),
      "must equal row-derived timeline_integrity_issue_types"
    )
  end

  defp validate_count_fields(issues, callbacks, path, report) do
    issues
    |> expect_non_negative_integer(callbacks, path, report, "activity_count")
    |> expect_non_negative_integer(callbacks, path, report, "valid_activity_count")
    |> expect_non_negative_integer(callbacks, path, report, "invalid_activity_input_count")
    |> expect_non_negative_integer(callbacks, path, report, "timeline_integrity_review_count")
    |> expect_non_negative_integer(callbacks, path, report, "timeline_integrity_issue_count")
    |> expect_non_negative_integer(callbacks, path, report, "dependency_issue_count")
    |> expect_non_negative_integer(callbacks, path, report, "exclusivity_issue_count")
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".timeline_integrity_issue_type_counts",
      Map.get(report, "timeline_integrity_issue_type_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".required_operator_action_counts",
      Map.get(report, "required_operator_action_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".operator_action_reason_counts",
      Map.get(report, "operator_action_reason_counts")
    )
  end

  defp validate_id_fields(issues, callbacks, path, report) do
    id_fields = [
      "review_activity_ids",
      "review_timeline_ids",
      "dependency_review_activity_ids",
      "dependency_review_timeline_ids",
      "exclusivity_review_activity_ids",
      "exclusivity_review_timeline_ids",
      "invalid_activity_input_ids",
      "missing_dependency_activity_ids",
      "missing_dependency_timeline_ids",
      "self_dependency_activity_ids",
      "self_dependency_timeline_ids",
      "duplicate_dependency_activity_ids",
      "duplicate_dependency_timeline_ids",
      "duplicate_exclusivity_activity_ids",
      "duplicate_exclusivity_timeline_ids",
      "dependency_cycle_activity_ids",
      "dependency_cycle_timeline_ids",
      "dependency_order_violation_activity_ids",
      "dependency_order_violation_timeline_ids",
      "exclusivity_violation_activity_ids",
      "exclusivity_violation_timeline_ids"
    ]

    map_fields = [
      "review_activity_ids_by_issue_type",
      "review_timeline_ids_by_issue_type",
      "review_activity_ids_by_required_operator_action",
      "review_timeline_ids_by_required_operator_action",
      "review_activity_ids_by_operator_action_reason",
      "review_timeline_ids_by_operator_action_reason"
    ]

    issues =
      Enum.reduce(id_fields, issues, fn field, acc ->
        acc
        |> expect_type(callbacks, path, report, field, :list)
        |> validate_optional_stable_id_list(callbacks, path, report, field)
      end)

    Enum.reduce(map_fields, issues, fn field, acc ->
      validate_optional_stable_id_array_map(acc, callbacks, path, report, field)
    end)
  end

  defp validate_row_derived_fields(issues, callbacks, path, report, rows) do
    issues
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "timeline_integrity_review_count",
      length(rows),
      "must equal row-derived timeline_integrity_review_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "timeline_integrity_status",
      if(rows == [], do: "clear", else: "review_required"),
      "must equal row-derived timeline_integrity_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "timeline_integrity_issue_count",
      timeline_integrity_report_issue_count(rows),
      "must equal row-derived timeline_integrity_issue_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "timeline_integrity_issue_types",
      timeline_integrity_report_issue_types(rows),
      "must equal row-derived timeline_integrity_issue_types"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "timeline_integrity_issue_type_counts",
      timeline_integrity_report_issue_type_counts(rows),
      "must equal row-derived timeline_integrity_issue_type_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "required_operator_action_counts",
      frequency_map(rows, "required_operator_action"),
      "must equal row-derived required_operator_action_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "operator_action_reason_counts",
      frequency_map(rows, "operator_action_reason"),
      "must equal row-derived operator_action_reason_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "dependency_issue_count",
      timeline_integrity_report_dependency_issue_count(rows),
      "must equal row-derived dependency_issue_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "exclusivity_issue_count",
      timeline_integrity_report_exclusivity_issue_count(rows),
      "must equal row-derived exclusivity_issue_count"
    )
    |> validate_row_derived_ids(callbacks, path, report, rows)
  end

  defp validate_row_derived_ids(issues, callbacks, path, report, rows) do
    issues
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "review_activity_ids",
      timeline_integrity_report_row_ids(rows, "activity_id"),
      "must equal row-derived review_activity_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "review_timeline_ids",
      timeline_integrity_report_row_ids(rows, "timeline_id"),
      "must equal row-derived review_timeline_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "review_activity_ids_by_issue_type",
      timeline_integrity_report_ids_by_issue_type(rows, "activity_id"),
      "must equal row-derived review_activity_ids_by_issue_type"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "review_timeline_ids_by_issue_type",
      timeline_integrity_report_ids_by_issue_type(rows, "timeline_id"),
      "must equal row-derived review_timeline_ids_by_issue_type"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "review_activity_ids_by_required_operator_action",
      timeline_integrity_report_ids_by_field(rows, "required_operator_action", "activity_id"),
      "must equal row-derived review_activity_ids_by_required_operator_action"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "review_timeline_ids_by_required_operator_action",
      timeline_integrity_report_ids_by_field(rows, "required_operator_action", "timeline_id"),
      "must equal row-derived review_timeline_ids_by_required_operator_action"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "review_activity_ids_by_operator_action_reason",
      timeline_integrity_report_ids_by_field(rows, "operator_action_reason", "activity_id"),
      "must equal row-derived review_activity_ids_by_operator_action_reason"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "review_timeline_ids_by_operator_action_reason",
      timeline_integrity_report_ids_by_field(rows, "operator_action_reason", "timeline_id"),
      "must equal row-derived review_timeline_ids_by_operator_action_reason"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "dependency_review_activity_ids",
      timeline_integrity_report_scope_ids(rows, "dependency", "activity_id"),
      "must equal row-derived dependency_review_activity_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "dependency_review_timeline_ids",
      timeline_integrity_report_scope_ids(rows, "dependency", "timeline_id"),
      "must equal row-derived dependency_review_timeline_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "exclusivity_review_activity_ids",
      timeline_integrity_report_scope_ids(rows, "exclusivity", "activity_id"),
      "must equal row-derived exclusivity_review_activity_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "exclusivity_review_timeline_ids",
      timeline_integrity_report_scope_ids(rows, "exclusivity", "timeline_id"),
      "must equal row-derived exclusivity_review_timeline_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "invalid_activity_input_ids",
      timeline_integrity_report_scope_ids(rows, "invalid_activity_input", "activity_id"),
      "must equal row-derived invalid_activity_input_ids"
    )
    |> validate_flat_id_fields(callbacks, path, report, rows)
  end

  defp validate_flat_id_fields(issues, callbacks, path, report, rows) do
    [
      "missing_dependency_activity_ids",
      "missing_dependency_timeline_ids",
      "self_dependency_activity_ids",
      "self_dependency_timeline_ids",
      "duplicate_dependency_activity_ids",
      "duplicate_dependency_timeline_ids",
      "duplicate_exclusivity_activity_ids",
      "duplicate_exclusivity_timeline_ids",
      "dependency_cycle_activity_ids",
      "dependency_cycle_timeline_ids",
      "dependency_order_violation_activity_ids",
      "dependency_order_violation_timeline_ids",
      "exclusivity_violation_activity_ids",
      "exclusivity_violation_timeline_ids"
    ]
    |> Enum.reduce(issues, fn field, acc ->
      expect_field_equals(
        acc,
        callbacks,
        path,
        report,
        field,
        timeline_integrity_report_row_list_ids(rows, field),
        "must equal row-derived #{field}"
      )
    end)
  end

  defp validate_row_issues(issues, callbacks, path, row) do
    row
    |> timeline_integrity_report_row_issues()
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {issue, index}, acc ->
      issue_path = "#{path}.timeline_integrity_issues[#{index}]"

      acc
      |> expect_type(callbacks, issue_path, issue, "type", :binary)
      |> expect_optional_type(callbacks, issue_path, issue, "reason", :binary)
      |> expect_optional_type(callbacks, issue_path, issue, "group", :binary)
      |> expect_optional_type(callbacks, issue_path, issue, "activity_ids", :list)
      |> validate_optional_stable_id_list(callbacks, issue_path, issue, "activity_ids")
      |> expect_optional_type(callbacks, issue_path, issue, "timeline_ids", :list)
      |> validate_optional_stable_id_list(callbacks, issue_path, issue, "timeline_ids")
    end)
  end

  defp validate_row_id_lists(issues, callbacks, path, row) do
    [
      "dependency_activity_ids",
      "dependency_timeline_ids",
      "exclusive_with_activity_ids",
      "exclusive_with_timeline_ids",
      "missing_dependency_activity_ids",
      "missing_dependency_timeline_ids",
      "self_dependency_activity_ids",
      "self_dependency_timeline_ids",
      "duplicate_dependency_activity_ids",
      "duplicate_dependency_timeline_ids",
      "duplicate_exclusivity_activity_ids",
      "duplicate_exclusivity_timeline_ids",
      "dependency_cycle_activity_ids",
      "dependency_cycle_timeline_ids",
      "dependency_order_violation_activity_ids",
      "dependency_order_violation_timeline_ids",
      "exclusivity_violation_activity_ids",
      "exclusivity_violation_timeline_ids"
    ]
    |> Enum.reduce(issues, fn field, acc ->
      acc
      |> expect_optional_type(callbacks, path, row, field, :list)
      |> validate_optional_stable_id_list(callbacks, path, row, field)
    end)
  end

  defp timeline_integrity_report_issue_count(rows) do
    rows
    |> Enum.map(&Map.get(&1, "timeline_integrity_issue_count", 0))
    |> Enum.filter(&(is_integer(&1) and &1 >= 0))
    |> Enum.sum()
  end

  defp timeline_integrity_report_issue_types(rows) do
    rows
    |> Enum.flat_map(&list_value(&1, "timeline_integrity_issue_types"))
    |> sorted_unique_binary_values()
  end

  defp timeline_integrity_report_row_issue_types(row) do
    row
    |> timeline_integrity_report_row_issues()
    |> Enum.map(&Map.get(&1, "type"))
    |> sorted_unique_binary_values()
  end

  defp timeline_integrity_report_issue_type_counts(rows) do
    rows
    |> Enum.flat_map(&timeline_integrity_report_row_issues/1)
    |> Enum.map(&Map.get(&1, "type"))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp timeline_integrity_report_dependency_issue_count(rows) do
    timeline_integrity_report_issue_count_by_fragment(rows, "dependency")
  end

  defp timeline_integrity_report_exclusivity_issue_count(rows) do
    timeline_integrity_report_issue_count_by_fragment(rows, "exclusivity")
  end

  defp timeline_integrity_report_issue_count_by_fragment(rows, fragment) do
    rows
    |> Enum.flat_map(&timeline_integrity_report_row_issues/1)
    |> Enum.count(fn issue ->
      issue
      |> Map.get("type")
      |> case do
        type when is_binary(type) -> String.contains?(type, fragment)
        _type -> false
      end
    end)
  end

  defp timeline_integrity_report_row_ids(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> sorted_unique_binary_values()
  end

  defp timeline_integrity_report_scope_ids(rows, issue_type_fragment, field) do
    rows
    |> Enum.filter(fn row ->
      row
      |> list_value("timeline_integrity_issue_types")
      |> Enum.any?(&String.contains?(&1, issue_type_fragment))
    end)
    |> timeline_integrity_report_row_ids(field)
  end

  defp timeline_integrity_report_ids_by_issue_type(rows, id_field) do
    rows
    |> Enum.flat_map(fn row ->
      row
      |> list_value("timeline_integrity_issue_types")
      |> Enum.map(&{&1, Map.get(row, id_field)})
    end)
    |> stable_values_by_key()
  end

  defp timeline_integrity_report_ids_by_field(rows, group_field, id_field) do
    rows
    |> Enum.map(&{Map.get(&1, group_field), Map.get(&1, id_field)})
    |> stable_values_by_key()
  end

  defp timeline_integrity_report_row_list_ids(rows, field) do
    rows
    |> Enum.flat_map(&list_value(&1, field))
    |> sorted_unique_binary_values()
  end

  defp timeline_integrity_report_row_issues(row) do
    row
    |> Map.get("timeline_integrity_issues", [])
    |> Enum.filter(&is_map/1)
  end

  defp frequency_map(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp list_value(map, key) when is_map(map), do: Map.get(map, key) || []
  defp list_value(_map, _key), do: []

  defp sorted_unique_binary_values(values) do
    values
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp stable_values_by_key(pairs) do
    pairs
    |> Enum.reject(fn {key, value} -> key in [nil, ""] or value in [nil, ""] end)
    |> Enum.group_by(fn {key, _value} -> key end, fn {_key, value} -> value end)
    |> Map.new(fn {key, values} -> {key, sorted_stable_values(values)} end)
  end

  defp sorted_stable_values(values) do
    values
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp timeline_report_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :timeline_report_model_limits), [])

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :require_fields), [issues, path, map, fields])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(Keyword.fetch!(callbacks, :expect_one_of), [issues, path, map, field, allowed])

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

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_ids), [issues, path, map, fields])

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

  defp validate_optional_stable_id_list(issues, callbacks, path, report, field),
    do:
      apply(Keyword.fetch!(callbacks, :validate_optional_stable_id_list), [
        issues,
        path,
        report,
        field
      ])

  defp validate_optional_stable_id_array_map(issues, callbacks, path, report, field),
    do:
      apply(Keyword.fetch!(callbacks, :validate_optional_stable_id_array_map), [
        issues,
        path,
        report,
        field
      ])

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(Keyword.fetch!(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_string_list_allowed(issues, callbacks, path, map, field, allowed),
    do:
      apply(Keyword.fetch!(callbacks, :validate_string_list_allowed), [
        issues,
        path,
        map,
        field,
        allowed
      ])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])
end
