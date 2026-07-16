defmodule OrbitalDynamics.Schema.TimelineIntegrityReportContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_non_negative_integer_count_map: 3,
      validate_optional_exact_model_limits: 5,
      validate_string_list_allowed: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_optional_stable_id_list: 4,
      validate_stable_id_array_map: 3,
      validate_stable_ids: 4
    ]

  def validate(issues, path, report, timeline_report_model_limits)
      when is_list(timeline_report_model_limits) do
    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    issues
    |> expect_equal(path, report, "schema_contract", "timeline_integrity_report.v1")
    |> expect_equal(path, report, "model", "artifact_only_timeline_integrity_summary")
    |> expect_equal(path, report, "validation_level", "artifact_contract")
    |> expect_type(path, report, "source", :binary)
    |> expect_one_of(path, report, "timeline_integrity_status", [
      "clear",
      "review_required"
    ])
    |> validate_count_fields(path, report)
    |> validate_id_fields(path, report)
    |> expect_type(path, report, "timeline_integrity_issue_types", :list)
    |> validate_string_list_allowed(
      path,
      report,
      "timeline_integrity_issue_types",
      OrbitalDynamics.Timeline.capabilities().timeline_integrity_issue_types
    )
    |> expect_type(path, report, "rows", :list)
    |> expect_type(path, report, "assumptions", :map)
    |> expect_type(path, report, "model_limits", :list)
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      report,
      timeline_report_model_limits,
      "must match timeline report model limits"
    )
    |> validate_row_derived_fields(path, report, rows)
    |> validate_rows(
      path <> ".rows",
      Map.get(report, "rows", []),
      &validate_row/3
    )
  end

  def validate_row(issues, path, row) do
    issues
    |> require_fields(path, row, [
      "activity_id",
      "timeline_id",
      "required_operator_action",
      "operator_action_reason",
      "timeline_integrity_status",
      "timeline_integrity_issue_count",
      "timeline_integrity_issue_types"
    ])
    |> validate_stable_ids(path, row, ["activity_id", "timeline_id"])
    |> expect_equal(path, row, "timeline_integrity_status", "review_required")
    |> expect_one_of(
      path,
      row,
      "required_operator_action",
      OrbitalDynamics.Timeline.capabilities().required_operator_actions
    )
    |> expect_non_negative_integer(path, row, "timeline_integrity_issue_count")
    |> expect_type(path, row, "timeline_integrity_issue_types", :list)
    |> validate_string_list_allowed(
      path,
      row,
      "timeline_integrity_issue_types",
      OrbitalDynamics.Timeline.capabilities().timeline_integrity_issue_types
    )
    |> expect_optional_type(path, row, "timeline_integrity_issues", :list)
    |> validate_row_issues(path, row)
    |> validate_row_id_lists(path, row)
    |> expect_field_equals(
      path,
      row,
      "timeline_integrity_issue_count",
      length(timeline_integrity_report_row_issues(row)),
      "must equal row-derived timeline_integrity_issue_count"
    )
    |> expect_field_equals(
      path,
      row,
      "timeline_integrity_issue_types",
      timeline_integrity_report_row_issue_types(row),
      "must equal row-derived timeline_integrity_issue_types"
    )
  end

  defp validate_count_fields(issues, path, report) do
    issues
    |> expect_non_negative_integer(path, report, "activity_count")
    |> expect_non_negative_integer(path, report, "valid_activity_count")
    |> expect_non_negative_integer(path, report, "invalid_activity_input_count")
    |> expect_non_negative_integer(path, report, "timeline_integrity_review_count")
    |> expect_non_negative_integer(path, report, "timeline_integrity_issue_count")
    |> expect_non_negative_integer(path, report, "dependency_issue_count")
    |> expect_non_negative_integer(path, report, "exclusivity_issue_count")
    |> validate_non_negative_integer_count_map(
      path <> ".timeline_integrity_issue_type_counts",
      Map.get(report, "timeline_integrity_issue_type_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".required_operator_action_counts",
      Map.get(report, "required_operator_action_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".operator_action_reason_counts",
      Map.get(report, "operator_action_reason_counts")
    )
  end

  defp validate_id_fields(issues, path, report) do
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
        |> expect_type(path, report, field, :list)
        |> validate_optional_stable_id_list(path, report, field)
      end)

    Enum.reduce(map_fields, issues, fn field, acc ->
      validate_optional_stable_id_array_map(acc, path, report, field)
    end)
  end

  defp validate_row_derived_fields(issues, path, report, rows) do
    issues
    |> expect_field_equals(
      path,
      report,
      "timeline_integrity_review_count",
      length(rows),
      "must equal row-derived timeline_integrity_review_count"
    )
    |> expect_field_equals(
      path,
      report,
      "timeline_integrity_status",
      if(rows == [], do: "clear", else: "review_required"),
      "must equal row-derived timeline_integrity_status"
    )
    |> expect_field_equals(
      path,
      report,
      "timeline_integrity_issue_count",
      timeline_integrity_report_issue_count(rows),
      "must equal row-derived timeline_integrity_issue_count"
    )
    |> expect_field_equals(
      path,
      report,
      "timeline_integrity_issue_types",
      timeline_integrity_report_issue_types(rows),
      "must equal row-derived timeline_integrity_issue_types"
    )
    |> expect_field_equals(
      path,
      report,
      "timeline_integrity_issue_type_counts",
      timeline_integrity_report_issue_type_counts(rows),
      "must equal row-derived timeline_integrity_issue_type_counts"
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
      "operator_action_reason_counts",
      frequency_map(rows, "operator_action_reason"),
      "must equal row-derived operator_action_reason_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "dependency_issue_count",
      timeline_integrity_report_dependency_issue_count(rows),
      "must equal row-derived dependency_issue_count"
    )
    |> expect_field_equals(
      path,
      report,
      "exclusivity_issue_count",
      timeline_integrity_report_exclusivity_issue_count(rows),
      "must equal row-derived exclusivity_issue_count"
    )
    |> validate_row_derived_ids(path, report, rows)
  end

  defp validate_row_derived_ids(issues, path, report, rows) do
    issues
    |> expect_field_equals(
      path,
      report,
      "review_activity_ids",
      timeline_integrity_report_row_ids(rows, "activity_id"),
      "must equal row-derived review_activity_ids"
    )
    |> expect_field_equals(
      path,
      report,
      "review_timeline_ids",
      timeline_integrity_report_row_ids(rows, "timeline_id"),
      "must equal row-derived review_timeline_ids"
    )
    |> expect_field_equals(
      path,
      report,
      "review_activity_ids_by_issue_type",
      timeline_integrity_report_ids_by_issue_type(rows, "activity_id"),
      "must equal row-derived review_activity_ids_by_issue_type"
    )
    |> expect_field_equals(
      path,
      report,
      "review_timeline_ids_by_issue_type",
      timeline_integrity_report_ids_by_issue_type(rows, "timeline_id"),
      "must equal row-derived review_timeline_ids_by_issue_type"
    )
    |> expect_field_equals(
      path,
      report,
      "review_activity_ids_by_required_operator_action",
      timeline_integrity_report_ids_by_field(rows, "required_operator_action", "activity_id"),
      "must equal row-derived review_activity_ids_by_required_operator_action"
    )
    |> expect_field_equals(
      path,
      report,
      "review_timeline_ids_by_required_operator_action",
      timeline_integrity_report_ids_by_field(rows, "required_operator_action", "timeline_id"),
      "must equal row-derived review_timeline_ids_by_required_operator_action"
    )
    |> expect_field_equals(
      path,
      report,
      "review_activity_ids_by_operator_action_reason",
      timeline_integrity_report_ids_by_field(rows, "operator_action_reason", "activity_id"),
      "must equal row-derived review_activity_ids_by_operator_action_reason"
    )
    |> expect_field_equals(
      path,
      report,
      "review_timeline_ids_by_operator_action_reason",
      timeline_integrity_report_ids_by_field(rows, "operator_action_reason", "timeline_id"),
      "must equal row-derived review_timeline_ids_by_operator_action_reason"
    )
    |> expect_field_equals(
      path,
      report,
      "dependency_review_activity_ids",
      timeline_integrity_report_scope_ids(rows, "dependency", "activity_id"),
      "must equal row-derived dependency_review_activity_ids"
    )
    |> expect_field_equals(
      path,
      report,
      "dependency_review_timeline_ids",
      timeline_integrity_report_scope_ids(rows, "dependency", "timeline_id"),
      "must equal row-derived dependency_review_timeline_ids"
    )
    |> expect_field_equals(
      path,
      report,
      "exclusivity_review_activity_ids",
      timeline_integrity_report_scope_ids(rows, "exclusivity", "activity_id"),
      "must equal row-derived exclusivity_review_activity_ids"
    )
    |> expect_field_equals(
      path,
      report,
      "exclusivity_review_timeline_ids",
      timeline_integrity_report_scope_ids(rows, "exclusivity", "timeline_id"),
      "must equal row-derived exclusivity_review_timeline_ids"
    )
    |> expect_field_equals(
      path,
      report,
      "invalid_activity_input_ids",
      timeline_integrity_report_scope_ids(rows, "invalid_activity_input", "activity_id"),
      "must equal row-derived invalid_activity_input_ids"
    )
    |> validate_flat_id_fields(path, report, rows)
  end

  defp validate_flat_id_fields(issues, path, report, rows) do
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
        path,
        report,
        field,
        timeline_integrity_report_row_list_ids(rows, field),
        "must equal row-derived #{field}"
      )
    end)
  end

  defp validate_row_issues(issues, path, row) do
    row
    |> timeline_integrity_report_row_issues()
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {issue, index}, acc ->
      issue_path = "#{path}.timeline_integrity_issues[#{index}]"

      acc
      |> expect_type(issue_path, issue, "type", :binary)
      |> expect_optional_type(issue_path, issue, "reason", :binary)
      |> expect_optional_type(issue_path, issue, "group", :binary)
      |> expect_optional_type(issue_path, issue, "activity_ids", :list)
      |> validate_optional_stable_id_list(issue_path, issue, "activity_ids")
      |> expect_optional_type(issue_path, issue, "timeline_ids", :list)
      |> validate_optional_stable_id_list(issue_path, issue, "timeline_ids")
    end)
  end

  defp validate_row_id_lists(issues, path, row) do
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
      |> expect_optional_type(path, row, field, :list)
      |> validate_optional_stable_id_list(path, row, field)
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

  defp validate_optional_stable_id_array_map(issues, path, report, field) do
    issues
    |> expect_optional_type(path, report, field, :map)
    |> validate_stable_id_array_map(path <> ".#{field}", Map.get(report, field))
  end
end
