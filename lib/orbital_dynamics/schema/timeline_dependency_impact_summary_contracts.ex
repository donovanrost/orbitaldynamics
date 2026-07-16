defmodule OrbitalDynamics.Schema.TimelineDependencyImpactSummaryContracts do
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
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_optional_stable_id_list: 4, validate_stable_ids: 4]

  def validate(issues, path, summary, timeline_report_model_limits)
      when is_list(timeline_report_model_limits) do
    rows =
      summary
      |> Map.get("dependency_impact_rows", [])
      |> Enum.filter(&is_map/1)

    issues
    |> expect_equal(
      path,
      summary,
      "schema_contract",
      "timeline_dependency_impact_summary.v1"
    )
    |> expect_equal(
      path,
      summary,
      "model",
      "artifact_only_timeline_dependency_impact_summary"
    )
    |> expect_equal(path, summary, "validation_level", "artifact_contract")
    |> expect_equal(path, summary, "source", "timeline_diff_report.v1")
    |> validate_count_fields(path, summary)
    |> validate_id_fields(path, summary)
    |> expect_one_of(path, summary, "dependency_impact_status", [
      "clear",
      "review_required"
    ])
    |> expect_type(path, summary, "dependency_impact_rows", :list)
    |> expect_type(path, summary, "assumptions", :map)
    |> expect_type(path, summary, "model_limits", :list)
    |> validate_string_list_items(path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      summary,
      timeline_report_model_limits,
      "must match timeline report model limits"
    )
    |> validate_row_derived_fields(path, summary, rows)
    |> validate_rows(
      path <> ".dependency_impact_rows",
      Map.get(summary, "dependency_impact_rows", []),
      &validate_row/3
    )
  end

  def validate_row(issues, path, row) do
    issues
    |> require_fields(path, row, [
      "id",
      "scope",
      "dependency_impact_status",
      "required_operator_action",
      "operator_action_reason",
      "activity_id",
      "timeline_id",
      "activity_type"
    ])
    |> validate_stable_ids(path, row, ["id", "activity_id", "timeline_id"])
    |> expect_one_of(path, row, "scope", ["source", "replacement"])
    |> expect_equal(path, row, "dependency_impact_status", "review_required")
    |> expect_one_of(
      path,
      row,
      "required_operator_action",
      OrbitalDynamics.Timeline.capabilities().required_operator_actions
    )
    |> expect_one_of(
      path,
      row,
      "operator_action_reason",
      [
        "dependency_changed_or_removed_source_activity",
        "exclusivity_changed_or_removed_source_activity",
        "dependency_and_exclusivity_changed_or_removed_source_activity"
      ]
    )
    |> expect_type(path, row, "activity_type", :binary)
    |> expect_optional_type(path, row, "status", :binary)
    |> expect_optional_type(path, row, "approval_status", :binary)
    |> validate_row_id_lists(path, row)
  end

  defp validate_count_fields(issues, path, summary) do
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
      expect_non_negative_integer(acc, path, summary, field)
    end)
  end

  defp validate_id_fields(issues, path, summary) do
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
      |> expect_type(path, summary, field, :list)
      |> validate_optional_stable_id_list(path, summary, field)
    end)
  end

  defp validate_row_derived_fields(issues, path, summary, rows) do
    expected_status = if rows == [], do: "clear", else: "review_required"

    issues
    |> expect_field_equals(
      path,
      summary,
      "dependency_impact_status",
      expected_status,
      "must equal row-derived dependency_impact_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "changed_source_activity_count",
      length(sorted_unique_binary_values(Map.get(summary, "impacted_source_activity_ids", []))),
      "must equal impacted_source_activity_ids count"
    )
    |> expect_field_equals(
      path,
      summary,
      "changed_source_timeline_count",
      length(sorted_unique_binary_values(Map.get(summary, "impacted_source_timeline_ids", []))),
      "must equal impacted_source_timeline_ids count"
    )
    |> expect_field_equals(
      path,
      summary,
      "dependent_activity_count",
      length(rows),
      "must equal row-derived dependent_activity_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "source_dependent_activity_count",
      Enum.count(rows, &(&1["scope"] == "source")),
      "must equal row-derived source_dependent_activity_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "replacement_dependent_activity_count",
      Enum.count(rows, &(&1["scope"] == "replacement")),
      "must equal row-derived replacement_dependent_activity_count"
    )
    |> validate_row_id_fields(path, summary, rows)
  end

  defp validate_row_id_fields(issues, path, summary, rows) do
    issues
    |> expect_field_equals(
      path,
      summary,
      "dependent_activity_ids",
      timeline_dependency_impact_row_ids(rows, "activity_id"),
      "must equal row-derived dependent_activity_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "dependent_timeline_ids",
      timeline_dependency_impact_row_ids(rows, "timeline_id"),
      "must equal row-derived dependent_timeline_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "source_dependent_activity_ids",
      timeline_dependency_impact_row_ids_by_scope(rows, "source", "activity_id"),
      "must equal row-derived source_dependent_activity_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "source_dependent_timeline_ids",
      timeline_dependency_impact_row_ids_by_scope(rows, "source", "timeline_id"),
      "must equal row-derived source_dependent_timeline_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "replacement_dependent_activity_ids",
      timeline_dependency_impact_row_ids_by_scope(rows, "replacement", "activity_id"),
      "must equal row-derived replacement_dependent_activity_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "replacement_dependent_timeline_ids",
      timeline_dependency_impact_row_ids_by_scope(rows, "replacement", "timeline_id"),
      "must equal row-derived replacement_dependent_timeline_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "impacted_dependency_activity_ids",
      timeline_dependency_impact_row_list_ids(rows, "impacted_dependency_activity_ids"),
      "must equal row-derived impacted_dependency_activity_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "impacted_dependency_timeline_ids",
      timeline_dependency_impact_row_list_ids(rows, "impacted_dependency_timeline_ids"),
      "must equal row-derived impacted_dependency_timeline_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "impacted_exclusive_with_activity_ids",
      timeline_dependency_impact_row_list_ids(rows, "impacted_exclusive_with_activity_ids"),
      "must equal row-derived impacted_exclusive_with_activity_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "impacted_exclusive_with_timeline_ids",
      timeline_dependency_impact_row_list_ids(rows, "impacted_exclusive_with_timeline_ids"),
      "must equal row-derived impacted_exclusive_with_timeline_ids"
    )
  end

  defp validate_row_id_lists(issues, path, row) do
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
      |> expect_optional_type(path, row, field, :list)
      |> validate_optional_stable_id_list(path, row, field)
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
end
