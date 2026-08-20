defmodule OrbitalDynamics.Schema.TimelineTransitionApplicationSummaryContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_optional_exact_model_limits: 5,
      validate_string_list_allowed: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_optional_stable_id_list: 4, validate_stable_id_array_map: 3]

  def validate(issues, path, summary, timeline_report_model_limits, row_validator)
      when is_list(timeline_report_model_limits) and is_function(row_validator, 3) do
    review_applications =
      summary
      |> Map.get("review_applications", [])
      |> Enum.filter(&is_map/1)

    issues
    |> expect_equal(
      path,
      summary,
      "schema_contract",
      "timeline_transition_application_summary.v1"
    )
    |> expect_equal(
      path,
      summary,
      "model",
      "artifact_only_timeline_transition_application_summary"
    )
    |> expect_equal(path, summary, "validation_level", "artifact_contract")
    |> expect_equal(
      path,
      summary,
      "source_artifact_type",
      "timeline_transition_application_report.v1"
    )
    |> expect_type(path, summary, "source", :binary)
    |> validate_count_fields(path, summary)
    |> validate_id_fields(path, summary)
    |> expect_type(path, summary, "selected_timeline_integrity_issue_types", :list)
    |> validate_string_list_allowed(
      path,
      summary,
      "selected_timeline_integrity_issue_types",
      OrbitalDynamics.Timeline.capabilities().timeline_integrity_issue_types
    )
    |> expect_type(path, summary, "review_applications", :list)
    |> expect_type(path, summary, "assumptions", :map)
    |> expect_type(path, summary, "model_limits", :list)
    |> OrbitalDynamics.Schema.PrimitiveValidation.expect_optional_type(
      path,
      summary,
      "timeline_revision",
      :map
    )
    |> OrbitalDynamics.Schema.TimelineRevisionContracts.validate_optional(
      path <> ".timeline_revision",
      Map.get(summary, "timeline_revision")
    )
    |> validate_string_list_items(path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      summary,
      timeline_report_model_limits,
      "must match timeline report model limits"
    )
    |> validate_row_derived_fields(path, summary, review_applications)
    |> validate_rows(
      path <> ".review_applications",
      Map.get(summary, "review_applications", []),
      row_validator
    )
    |> OrbitalDynamics.Schema.TimelineRevisionContracts.validate_row_copies(
      path,
      summary,
      "review_applications"
    )
  end

  defp validate_count_fields(issues, path, summary) do
    count_fields = [
      "source_activity_count",
      "replacement_activity_count",
      "application_count",
      "selected_activity_count",
      "review_required_count",
      "preserved_source_count",
      "recorded_replacement_count",
      "withheld_review_count",
      "selected_timeline_integrity_review_count",
      "selected_timeline_integrity_issue_count"
    ]

    count_map_fields = [
      "application_status_counts",
      "transition_decision_counts",
      "required_operator_action_counts",
      "status_transition_category_counts",
      "approval_transition_category_counts"
    ]

    issues =
      Enum.reduce(count_fields, issues, fn field, acc ->
        expect_non_negative_integer(acc, path, summary, field)
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
      "selected_activity_ids",
      "selected_timeline_ids",
      "review_timeline_ids",
      "review_activity_ids",
      "preserved_source_timeline_ids",
      "recorded_replacement_timeline_ids",
      "withheld_review_timeline_ids"
    ]

    map_fields = [
      "review_timeline_ids_by_required_operator_action",
      "review_timeline_ids_by_status_transition_category",
      "review_timeline_ids_by_approval_transition_category"
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

  defp validate_row_derived_fields(issues, path, summary, review_applications) do
    issues
    |> expect_field_equals(
      path,
      summary,
      "review_required_count",
      length(review_applications),
      "must equal review-application-derived review_required_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_timeline_ids",
      row_ids(review_applications, fn _row -> true end),
      "must equal review-application-derived review_timeline_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_activity_ids",
      activity_ids(review_applications),
      "must equal review-application-derived review_activity_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_timeline_ids_by_required_operator_action",
      ids_by_field(review_applications, "required_operator_action"),
      "must equal review-application-derived review_timeline_ids_by_required_operator_action"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_timeline_ids_by_status_transition_category",
      ids_by_nested_field(review_applications, "status_transition", "transition_category"),
      "must equal review-application-derived review_timeline_ids_by_status_transition_category"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_timeline_ids_by_approval_transition_category",
      ids_by_nested_field(review_applications, "approval_transition", "transition_category"),
      "must equal review-application-derived review_timeline_ids_by_approval_transition_category"
    )
    |> expect_field_equals(
      path,
      summary,
      "withheld_review_timeline_ids",
      row_ids(
        review_applications,
        &(&1["application_status"] == "operator_review_required")
      ),
      "must equal review-application-derived withheld_review_timeline_ids"
    )
  end

  defp row_ids(rows, predicate) do
    rows
    |> Enum.filter(predicate)
    |> Enum.map(&Map.get(&1, "timeline_id"))
    |> sorted_unique_binary_values()
  end

  defp activity_ids(rows) do
    rows
    |> Enum.flat_map(&[Map.get(&1, "source_activity_id"), Map.get(&1, "replacement_activity_id")])
    |> sorted_unique_binary_values()
  end

  defp ids_by_field(rows, field) do
    rows
    |> Enum.group_by(&Map.get(&1, field), &Map.get(&1, "timeline_id"))
    |> id_map()
  end

  defp ids_by_nested_field(rows, field, nested_field) do
    rows
    |> Enum.group_by(&get_in(&1, [field, nested_field]), &Map.get(&1, "timeline_id"))
    |> id_map()
  end

  defp id_map(grouped_ids) do
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
