defmodule OrbitalDynamics.Schema.TimelineDependencyImpactSummaryContracts do
  @moduledoc false

  def validate(issues, path, summary, callbacks) when is_list(callbacks) do
    rows =
      summary
      |> Map.get("dependency_impact_rows", [])
      |> Enum.filter(&is_map/1)

    issues
    |> expect_equal(
      callbacks,
      path,
      summary,
      "schema_contract",
      "timeline_dependency_impact_summary.v1"
    )
    |> expect_equal(
      callbacks,
      path,
      summary,
      "model",
      "artifact_only_timeline_dependency_impact_summary"
    )
    |> expect_equal(callbacks, path, summary, "validation_level", "artifact_contract")
    |> expect_equal(callbacks, path, summary, "source", "timeline_diff_report.v1")
    |> validate_count_fields(callbacks, path, summary)
    |> validate_id_fields(callbacks, path, summary)
    |> expect_one_of(callbacks, path, summary, "dependency_impact_status", [
      "clear",
      "review_required"
    ])
    |> expect_type(callbacks, path, summary, "dependency_impact_rows", :list)
    |> expect_type(callbacks, path, summary, "assumptions", :map)
    |> expect_type(callbacks, path, summary, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      summary,
      timeline_report_model_limits(callbacks),
      "must match timeline report model limits"
    )
    |> validate_row_derived_fields(callbacks, path, summary, rows)
    |> validate_rows(
      callbacks,
      path <> ".dependency_impact_rows",
      Map.get(summary, "dependency_impact_rows", []),
      fn acc, row_path, row -> validate_row(acc, row_path, row, callbacks) end
    )
  end

  def validate_row(issues, path, row, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, row, [
      "id",
      "scope",
      "dependency_impact_status",
      "required_operator_action",
      "operator_action_reason",
      "activity_id",
      "timeline_id",
      "activity_type"
    ])
    |> validate_stable_ids(callbacks, path, row, ["id", "activity_id", "timeline_id"])
    |> expect_one_of(callbacks, path, row, "scope", ["source", "replacement"])
    |> expect_equal(callbacks, path, row, "dependency_impact_status", "review_required")
    |> expect_one_of(
      callbacks,
      path,
      row,
      "required_operator_action",
      OrbitalDynamics.Timeline.capabilities().required_operator_actions
    )
    |> expect_one_of(
      callbacks,
      path,
      row,
      "operator_action_reason",
      [
        "dependency_changed_or_removed_source_activity",
        "exclusivity_changed_or_removed_source_activity",
        "dependency_and_exclusivity_changed_or_removed_source_activity"
      ]
    )
    |> expect_type(callbacks, path, row, "activity_type", :binary)
    |> expect_optional_type(callbacks, path, row, "status", :binary)
    |> expect_optional_type(callbacks, path, row, "approval_status", :binary)
    |> validate_row_id_lists(callbacks, path, row)
  end

  defp validate_count_fields(issues, callbacks, path, summary) do
    [
      "source_activity_count",
      "replacement_activity_count",
      "changed_source_activity_count",
      "changed_source_timeline_count",
      "dependent_activity_count",
      "source_dependent_activity_count",
      "replacement_dependent_activity_count"
    ]
    |> Enum.reduce(issues, fn field, acc ->
      expect_non_negative_integer(acc, callbacks, path, summary, field)
    end)
  end

  defp validate_id_fields(issues, callbacks, path, summary) do
    [
      "impacted_source_activity_ids",
      "impacted_source_timeline_ids",
      "dependent_activity_ids",
      "dependent_timeline_ids",
      "source_dependent_activity_ids",
      "source_dependent_timeline_ids",
      "replacement_dependent_activity_ids",
      "replacement_dependent_timeline_ids",
      "impacted_dependency_activity_ids",
      "impacted_dependency_timeline_ids",
      "impacted_exclusive_with_activity_ids",
      "impacted_exclusive_with_timeline_ids"
    ]
    |> Enum.reduce(issues, fn field, acc ->
      acc
      |> expect_type(callbacks, path, summary, field, :list)
      |> validate_optional_stable_id_list(callbacks, path, summary, field)
    end)
  end

  defp validate_row_derived_fields(issues, callbacks, path, summary, rows) do
    expected_status = if rows == [], do: "clear", else: "review_required"

    issues
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "dependency_impact_status",
      expected_status,
      "must equal row-derived dependency_impact_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "changed_source_activity_count",
      length(sorted_unique_binary_values(Map.get(summary, "impacted_source_activity_ids", []))),
      "must equal impacted_source_activity_ids count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "changed_source_timeline_count",
      length(sorted_unique_binary_values(Map.get(summary, "impacted_source_timeline_ids", []))),
      "must equal impacted_source_timeline_ids count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "dependent_activity_count",
      length(rows),
      "must equal row-derived dependent_activity_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "source_dependent_activity_count",
      Enum.count(rows, &(&1["scope"] == "source")),
      "must equal row-derived source_dependent_activity_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "replacement_dependent_activity_count",
      Enum.count(rows, &(&1["scope"] == "replacement")),
      "must equal row-derived replacement_dependent_activity_count"
    )
    |> validate_row_id_fields(callbacks, path, summary, rows)
  end

  defp validate_row_id_fields(issues, callbacks, path, summary, rows) do
    issues
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "dependent_activity_ids",
      timeline_dependency_impact_row_ids(rows, "activity_id"),
      "must equal row-derived dependent_activity_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "dependent_timeline_ids",
      timeline_dependency_impact_row_ids(rows, "timeline_id"),
      "must equal row-derived dependent_timeline_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "source_dependent_activity_ids",
      timeline_dependency_impact_row_ids_by_scope(rows, "source", "activity_id"),
      "must equal row-derived source_dependent_activity_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "source_dependent_timeline_ids",
      timeline_dependency_impact_row_ids_by_scope(rows, "source", "timeline_id"),
      "must equal row-derived source_dependent_timeline_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "replacement_dependent_activity_ids",
      timeline_dependency_impact_row_ids_by_scope(rows, "replacement", "activity_id"),
      "must equal row-derived replacement_dependent_activity_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "replacement_dependent_timeline_ids",
      timeline_dependency_impact_row_ids_by_scope(rows, "replacement", "timeline_id"),
      "must equal row-derived replacement_dependent_timeline_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "impacted_dependency_activity_ids",
      timeline_dependency_impact_row_list_ids(rows, "impacted_dependency_activity_ids"),
      "must equal row-derived impacted_dependency_activity_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "impacted_dependency_timeline_ids",
      timeline_dependency_impact_row_list_ids(rows, "impacted_dependency_timeline_ids"),
      "must equal row-derived impacted_dependency_timeline_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "impacted_exclusive_with_activity_ids",
      timeline_dependency_impact_row_list_ids(rows, "impacted_exclusive_with_activity_ids"),
      "must equal row-derived impacted_exclusive_with_activity_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "impacted_exclusive_with_timeline_ids",
      timeline_dependency_impact_row_list_ids(rows, "impacted_exclusive_with_timeline_ids"),
      "must equal row-derived impacted_exclusive_with_timeline_ids"
    )
  end

  defp validate_row_id_lists(issues, callbacks, path, row) do
    [
      "dependency_activity_ids",
      "dependency_timeline_ids",
      "exclusive_with_activity_ids",
      "exclusive_with_timeline_ids",
      "impacted_dependency_activity_ids",
      "impacted_dependency_timeline_ids",
      "impacted_exclusive_with_activity_ids",
      "impacted_exclusive_with_timeline_ids"
    ]
    |> Enum.reduce(issues, fn field, acc ->
      acc
      |> expect_optional_type(callbacks, path, row, field, :list)
      |> validate_optional_stable_id_list(callbacks, path, row, field)
    end)
  end

  defp timeline_dependency_impact_row_ids(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> sorted_unique_binary_values()
  end

  defp timeline_dependency_impact_row_ids_by_scope(rows, scope, field) do
    rows
    |> Enum.filter(&(&1["scope"] == scope))
    |> timeline_dependency_impact_row_ids(field)
  end

  defp timeline_dependency_impact_row_list_ids(rows, field) do
    rows
    |> Enum.flat_map(&list_value(&1, field))
    |> sorted_unique_binary_values()
  end

  defp list_value(map, key) when is_map(map), do: Map.get(map, key) || []
  defp list_value(_map, _key), do: []

  defp sorted_unique_binary_values(values) do
    values
    |> Enum.filter(&is_binary/1)
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

  defp validate_optional_exact_model_limits(issues, callbacks, path, summary, expected, message),
    do:
      apply(Keyword.fetch!(callbacks, :validate_optional_exact_model_limits), [
        issues,
        path,
        summary,
        expected,
        message
      ])

  defp validate_optional_stable_id_list(issues, callbacks, path, summary, field),
    do:
      apply(Keyword.fetch!(callbacks, :validate_optional_stable_id_list), [
        issues,
        path,
        summary,
        field
      ])

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(Keyword.fetch!(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])
end
