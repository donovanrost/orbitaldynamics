defmodule OrbitalDynamics.Schema.TimelineDiffSummaryContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.TimelineDiffRowContracts

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_optional_non_negative_integer: 4,
      expect_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_optional_stable_id_list: 4, validate_stable_id_array_map: 3]

  def validate(issues, path, summary, timeline_report_model_limits)
      when is_list(timeline_report_model_limits) do
    review_rows =
      summary
      |> Map.get("review_rows", [])
      |> Enum.filter(&is_map/1)

    issues
    |> expect_equal(path, summary, "schema_contract", "timeline_diff_summary.v1")
    |> expect_equal(path, summary, "model", "artifact_only_timeline_diff_summary")
    |> expect_equal(path, summary, "validation_level", "artifact_contract")
    |> expect_equal(path, summary, "source_artifact_type", "timeline_diff_report.v1")
    |> expect_type(path, summary, "source", :binary)
    |> validate_count_fields(path, summary)
    |> validate_id_fields(path, summary)
    |> expect_type(path, summary, "review_rows", :list)
    |> expect_type(path, summary, "assumptions", :map)
    |> expect_type(path, summary, "model_limits", :list)
    |> validate_string_list_items(path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      summary,
      timeline_report_model_limits,
      "must match timeline report model limits"
    )
    |> validate_row_derived_fields(path, summary, review_rows)
    |> validate_rows(
      path <> ".review_rows",
      Map.get(summary, "review_rows", []),
      fn acc, row_path, row -> TimelineDiffRowContracts.validate(acc, row_path, row) end
    )
  end

  defp validate_count_fields(issues, path, summary) do
    count_fields = [
      "source_activity_count",
      "replacement_activity_count",
      "row_count",
      "added_count",
      "removed_count",
      "changed_count",
      "unchanged_count",
      "review_required_count"
    ]

    optional_count_fields = [
      "duplicate_timeline_identity_count",
      "invalid_source_activity_input_count",
      "invalid_replacement_activity_input_count"
    ]

    count_map_fields = [
      "diff_status_counts",
      "transition_decision_counts",
      "required_operator_action_counts",
      "changed_field_counts",
      "status_transition_category_counts",
      "approval_transition_category_counts"
    ]

    issues =
      Enum.reduce(count_fields, issues, fn field, acc ->
        expect_non_negative_integer(acc, path, summary, field)
      end)

    issues =
      Enum.reduce(optional_count_fields, issues, fn field, acc ->
        expect_optional_non_negative_integer(acc, path, summary, field)
      end)

    Enum.reduce(count_map_fields, issues, fn field, acc ->
      acc
      |> expect_type(path, summary, field, :map)
      |> validate_non_negative_integer_count_map(
        path <> ".#{field}",
        Map.get(summary, field)
      )
    end)
  end

  defp validate_id_fields(issues, path, summary) do
    id_fields = [
      "added_timeline_ids",
      "removed_timeline_ids",
      "changed_timeline_ids",
      "unchanged_timeline_ids",
      "duplicate_timeline_identity_ids",
      "invalid_source_activity_input_ids",
      "invalid_replacement_activity_input_ids",
      "review_timeline_ids"
    ]

    map_fields = [
      "review_timeline_ids_by_required_operator_action",
      "review_timeline_ids_by_status_transition_category",
      "review_timeline_ids_by_approval_transition_category",
      "timeline_ids_by_changed_field"
    ]

    issues =
      Enum.reduce(id_fields, issues, fn field, acc ->
        acc
        |> expect_type(path, summary, field, :list)
        |> validate_optional_stable_id_list(path, summary, field)
      end)

    Enum.reduce(map_fields, issues, fn field, acc ->
      acc
      |> expect_type(path, summary, field, :map)
      |> validate_stable_id_array_map(path <> ".#{field}", Map.get(summary, field))
    end)
  end

  defp validate_row_derived_fields(issues, path, summary, review_rows) do
    issues
    |> expect_field_equals(
      path,
      summary,
      "review_required_count",
      length(review_rows),
      "must equal row-derived review_required_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_timeline_ids",
      timeline_diff_summary_row_ids(review_rows, "timeline_id"),
      "must equal row-derived review_timeline_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_timeline_ids_by_required_operator_action",
      timeline_diff_summary_ids_by_field(review_rows, "required_operator_action"),
      "must equal row-derived review_timeline_ids_by_required_operator_action"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_timeline_ids_by_status_transition_category",
      timeline_diff_summary_ids_by_nested_field(
        review_rows,
        "status_transition",
        "transition_category"
      ),
      "must equal row-derived review_timeline_ids_by_status_transition_category"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_timeline_ids_by_approval_transition_category",
      timeline_diff_summary_ids_by_nested_field(
        review_rows,
        "approval_transition",
        "transition_category"
      ),
      "must equal row-derived review_timeline_ids_by_approval_transition_category"
    )
  end

  defp timeline_diff_summary_row_ids(rows, id_field) do
    rows
    |> Enum.map(&Map.get(&1, id_field))
    |> sorted_unique_binary_values()
  end

  defp timeline_diff_summary_ids_by_field(rows, field) do
    rows
    |> Enum.group_by(&Map.get(&1, field), &Map.get(&1, "timeline_id"))
    |> timeline_diff_summary_id_map()
  end

  defp timeline_diff_summary_ids_by_nested_field(rows, field, nested_field) do
    rows
    |> Enum.group_by(&get_in(&1, [field, nested_field]), &Map.get(&1, "timeline_id"))
    |> timeline_diff_summary_id_map()
  end

  defp timeline_diff_summary_id_map(grouped_ids) do
    grouped_ids
    |> Enum.reject(fn {group, ids} -> group in [nil, ""] or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {group, ids} -> {group, sorted_unique_binary_values(ids)} end)
  end

  defp sorted_unique_binary_values(values) do
    values
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.sort()
  end
end
