defmodule OrbitalDynamics.Schema.TimelineTransitionApplicationSummaryContracts do
  @moduledoc false

  def validate(issues, path, summary, callbacks) when is_list(callbacks) do
    review_applications =
      summary
      |> Map.get("review_applications", [])
      |> Enum.filter(&is_map/1)

    issues
    |> expect_equal(
      callbacks,
      path,
      summary,
      "schema_contract",
      "timeline_transition_application_summary.v1"
    )
    |> expect_equal(
      callbacks,
      path,
      summary,
      "model",
      "artifact_only_timeline_transition_application_summary"
    )
    |> expect_equal(callbacks, path, summary, "validation_level", "artifact_contract")
    |> expect_equal(
      callbacks,
      path,
      summary,
      "source_artifact_type",
      "timeline_transition_application_report.v1"
    )
    |> expect_type(callbacks, path, summary, "source", :binary)
    |> validate_count_fields(callbacks, path, summary)
    |> validate_id_fields(callbacks, path, summary)
    |> expect_type(callbacks, path, summary, "selected_timeline_integrity_issue_types", :list)
    |> validate_string_list_allowed(
      callbacks,
      path,
      summary,
      "selected_timeline_integrity_issue_types",
      OrbitalDynamics.Timeline.capabilities().timeline_integrity_issue_types
    )
    |> expect_type(callbacks, path, summary, "review_applications", :list)
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
    |> validate_row_derived_fields(callbacks, path, summary, review_applications)
    |> validate_rows(
      callbacks,
      path <> ".review_applications",
      Map.get(summary, "review_applications", []),
      &validate_timeline_transition_application_row(&1, callbacks, &2, &3)
    )
  end

  defp validate_count_fields(issues, callbacks, path, summary) do
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
        expect_non_negative_integer(acc, callbacks, path, summary, field)
      end)

    Enum.reduce(count_map_fields, issues, fn field, acc ->
      acc
      |> expect_type(callbacks, path, summary, field, :map)
      |> validate_non_negative_integer_count_map(
        callbacks,
        path <> ".#{field}",
        Map.get(summary, field)
      )
    end)
  end

  defp validate_id_fields(issues, callbacks, path, summary) do
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
        |> expect_type(callbacks, path, summary, field, :list)
        |> validate_optional_stable_id_list(callbacks, path, summary, field)
      end)

    Enum.reduce(map_fields, issues, fn field, acc ->
      acc
      |> expect_type(callbacks, path, summary, field, :map)
      |> validate_stable_id_array_map(callbacks, path <> ".#{field}", Map.get(summary, field))
    end)
  end

  defp validate_row_derived_fields(issues, callbacks, path, summary, review_applications) do
    issues
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_required_count",
      length(review_applications),
      "must equal review-application-derived review_required_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_timeline_ids",
      row_ids(review_applications, fn _row -> true end),
      "must equal review-application-derived review_timeline_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_activity_ids",
      activity_ids(review_applications),
      "must equal review-application-derived review_activity_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_timeline_ids_by_required_operator_action",
      ids_by_field(review_applications, "required_operator_action"),
      "must equal review-application-derived review_timeline_ids_by_required_operator_action"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_timeline_ids_by_status_transition_category",
      ids_by_nested_field(review_applications, "status_transition", "transition_category"),
      "must equal review-application-derived review_timeline_ids_by_status_transition_category"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_timeline_ids_by_approval_transition_category",
      ids_by_nested_field(review_applications, "approval_transition", "transition_category"),
      "must equal review-application-derived review_timeline_ids_by_approval_transition_category"
    )
    |> expect_field_equals(
      callbacks,
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

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_non_negative_integer(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :expect_non_negative_integer), [issues, path, map, field])
  end

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message) do
    apply(Keyword.fetch!(callbacks, :expect_field_equals_with_message), [
      issues,
      path,
      map,
      field,
      expected,
      message
    ])
  end

  defp validate_non_negative_integer_count_map(issues, callbacks, path, counts) do
    apply(Keyword.fetch!(callbacks, :validate_non_negative_integer_count_map), [
      issues,
      path,
      counts
    ])
  end

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :validate_optional_stable_id_list), [
      issues,
      path,
      map,
      field
    ])
  end

  defp validate_stable_id_array_map(issues, callbacks, path, values),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_array_map), [issues, path, values])

  defp validate_string_list_allowed(issues, callbacks, path, map, field, allowed) do
    apply(Keyword.fetch!(callbacks, :validate_string_list_allowed), [
      issues,
      path,
      map,
      field,
      allowed
    ])
  end

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_optional_exact_model_limits(issues, callbacks, path, artifact, expected, message) do
    apply(Keyword.fetch!(callbacks, :validate_optional_exact_model_limits), [
      issues,
      path,
      artifact,
      expected,
      message
    ])
  end

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(Keyword.fetch!(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_timeline_transition_application_row(issues, callbacks, path, row) do
    apply(Keyword.fetch!(callbacks, :validate_timeline_transition_application_row), [
      issues,
      path,
      row
    ])
  end

  defp timeline_report_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :timeline_report_model_limits), [])
end
