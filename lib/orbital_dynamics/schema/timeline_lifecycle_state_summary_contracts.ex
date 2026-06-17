defmodule OrbitalDynamics.Schema.TimelineLifecycleStateSummaryContracts do
  @moduledoc false

  def validate(issues, path, summary, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(
      callbacks,
      path,
      summary,
      "schema_contract",
      "timeline_lifecycle_state_summary.v1"
    )
    |> expect_type(callbacks, path, summary, "model", :binary)
    |> expect_equal(
      callbacks,
      path,
      summary,
      "model",
      "artifact_only_timeline_lifecycle_state_summary"
    )
    |> expect_type(callbacks, path, summary, "source", :binary)
    |> expect_equal(callbacks, path, summary, "validation_level", "artifact_contract")
    |> expect_type(callbacks, path, summary, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      summary,
      timeline_report_model_limits(callbacks),
      "must match timeline report model limits"
    )
    |> expect_non_negative_integer(callbacks, path, summary, "planned_activity_count")
    |> expect_non_negative_integer(callbacks, path, summary, "realized_activity_count")
    |> expect_non_negative_integer(callbacks, path, summary, "row_count")
    |> expect_non_negative_integer(callbacks, path, summary, "recordable_count")
    |> expect_non_negative_integer(callbacks, path, summary, "preserved_count")
    |> expect_non_negative_integer(callbacks, path, summary, "review_required_count")
    |> expect_non_negative_integer(callbacks, path, summary, "duplicate_timeline_identity_count")
    |> expect_non_negative_integer(callbacks, path, summary, "invalid_activity_input_count")
    |> expect_type(callbacks, path, summary, "transition_decision_counts", :map)
    |> expect_type(callbacks, path, summary, "required_operator_action_counts", :map)
    |> expect_type(callbacks, path, summary, "import_action_counts", :map)
    |> expect_optional_type(callbacks, path, summary, "operator_action_reason_counts", :map)
    |> expect_optional_type(callbacks, path, summary, "planned_status_category_counts", :map)
    |> expect_optional_type(callbacks, path, summary, "realized_status_category_counts", :map)
    |> expect_optional_type(callbacks, path, summary, "planned_approval_category_counts", :map)
    |> expect_optional_type(callbacks, path, summary, "realized_approval_category_counts", :map)
    |> expect_optional_type(callbacks, path, summary, "status_transition_category_counts", :map)
    |> expect_optional_type(callbacks, path, summary, "approval_transition_category_counts", :map)
    |> expect_optional_type(callbacks, path, summary, "recordable_timeline_ids", :list)
    |> expect_optional_type(callbacks, path, summary, "preserved_timeline_ids", :list)
    |> expect_optional_type(callbacks, path, summary, "review_timeline_ids", :list)
    |> expect_optional_type(callbacks, path, summary, "review_activity_ids", :list)
    |> expect_optional_type(callbacks, path, summary, "invalid_activity_input_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, summary, "recordable_timeline_ids")
    |> validate_optional_stable_id_list(callbacks, path, summary, "preserved_timeline_ids")
    |> validate_optional_stable_id_list(callbacks, path, summary, "review_timeline_ids")
    |> validate_optional_stable_id_list(callbacks, path, summary, "review_activity_ids")
    |> validate_optional_stable_id_list(callbacks, path, summary, "invalid_activity_input_ids")
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "review_timeline_ids_by_required_operator_action",
      :map
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "review_timeline_ids_by_operator_action_reason",
      :map
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "review_timeline_ids_by_status_transition_category",
      :map
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "review_timeline_ids_by_approval_transition_category",
      :map
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".review_timeline_ids_by_required_operator_action",
      Map.get(summary, "review_timeline_ids_by_required_operator_action")
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".review_timeline_ids_by_operator_action_reason",
      Map.get(summary, "review_timeline_ids_by_operator_action_reason")
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".review_timeline_ids_by_status_transition_category",
      Map.get(summary, "review_timeline_ids_by_status_transition_category")
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".review_timeline_ids_by_approval_transition_category",
      Map.get(summary, "review_timeline_ids_by_approval_transition_category")
    )
    |> expect_type(callbacks, path, summary, "rows", :list)
    |> expect_type(callbacks, path, summary, "review_rows", :list)
    |> expect_type(callbacks, path, summary, "assumptions", :map)
    |> validate_counts(callbacks, path, summary)
    |> validate_rows(
      callbacks,
      path <> ".rows",
      Map.get(summary, "rows", []),
      &validate_row(&1, callbacks, &2, &3)
    )
    |> validate_rows(
      callbacks,
      path <> ".review_rows",
      Map.get(summary, "review_rows", []),
      &validate_row(&1, callbacks, &2, &3)
    )
  end

  defp validate_counts(issues, callbacks, path, summary) do
    rows =
      summary
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    review_rows = Enum.filter(rows, &(&1["review_required"] == true))

    issues
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".transition_decision_counts",
      Map.get(summary, "transition_decision_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".required_operator_action_counts",
      Map.get(summary, "required_operator_action_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".operator_action_reason_counts",
      Map.get(summary, "operator_action_reason_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".import_action_counts",
      Map.get(summary, "import_action_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".planned_status_category_counts",
      Map.get(summary, "planned_status_category_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".realized_status_category_counts",
      Map.get(summary, "realized_status_category_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".planned_approval_category_counts",
      Map.get(summary, "planned_approval_category_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".realized_approval_category_counts",
      Map.get(summary, "realized_approval_category_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".status_transition_category_counts",
      Map.get(summary, "status_transition_category_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".approval_transition_category_counts",
      Map.get(summary, "approval_transition_category_counts")
    )
    |> expect_field_equals(callbacks, path, summary, "row_count", length(rows))
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "recordable_count",
      Enum.count(rows, &(&1["transition_decision"] == "record"))
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "preserved_count",
      Enum.count(rows, &(&1["transition_decision"] == "none"))
    )
    |> expect_field_equals(callbacks, path, summary, "review_required_count", length(review_rows))
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "duplicate_timeline_identity_count",
      Enum.count(rows, &(&1["timeline_identity_collision"] == true))
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "invalid_activity_input_count",
      Enum.count(rows, &(&1["invalid_activity_input"] == true))
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "transition_decision_counts",
      frequency_map(rows, "transition_decision"),
      "must equal row-derived transition_decision_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "required_operator_action_counts",
      frequency_map(rows, "required_operator_action"),
      "must equal row-derived required_operator_action_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "operator_action_reason_counts",
      operator_action_reason_counts(rows),
      "must equal row-derived operator_action_reason_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "import_action_counts",
      frequency_map(rows, "import_action"),
      "must equal row-derived import_action_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "planned_status_category_counts",
      frequency_map(rows, "planned_status_category"),
      "must equal row-derived planned_status_category_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "realized_status_category_counts",
      frequency_map(rows, "realized_status_category"),
      "must equal row-derived realized_status_category_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "planned_approval_category_counts",
      frequency_map(rows, "planned_approval_category"),
      "must equal row-derived planned_approval_category_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "realized_approval_category_counts",
      frequency_map(rows, "realized_approval_category"),
      "must equal row-derived realized_approval_category_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "status_transition_category_counts",
      nested_frequency_map(rows, "status_transition", "transition_category"),
      "must equal row-derived status_transition_category_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "approval_transition_category_counts",
      nested_frequency_map(rows, "approval_transition", "transition_category"),
      "must equal row-derived approval_transition_category_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "recordable_timeline_ids",
      timeline_ids(rows, &(&1["transition_decision"] == "record")),
      "must equal row-derived recordable_timeline_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "preserved_timeline_ids",
      timeline_ids(rows, &(&1["transition_decision"] == "none")),
      "must equal row-derived preserved_timeline_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_timeline_ids",
      timeline_ids(review_rows, fn _row -> true end),
      "must equal row-derived review_timeline_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_activity_ids",
      activity_ids(review_rows),
      "must equal row-derived review_activity_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "invalid_activity_input_ids",
      rows
      |> Enum.filter(&(&1["invalid_activity_input"] == true))
      |> activity_ids(),
      "must equal row-derived invalid_activity_input_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_rows",
      review_rows,
      "must equal row-derived review rows"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_timeline_ids_by_required_operator_action",
      timeline_ids_by(review_rows, & &1["required_operator_action"]),
      "must equal row-derived review_timeline_ids_by_required_operator_action"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_timeline_ids_by_operator_action_reason",
      timeline_ids_by_each(
        review_rows,
        &list_value(&1, "operator_action_reasons")
      ),
      "must equal row-derived review_timeline_ids_by_operator_action_reason"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_timeline_ids_by_status_transition_category",
      timeline_ids_by(
        review_rows,
        &get_in(&1, ["status_transition", "transition_category"])
      ),
      "must equal row-derived review_timeline_ids_by_status_transition_category"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_timeline_ids_by_approval_transition_category",
      timeline_ids_by(
        review_rows,
        &get_in(&1, ["approval_transition", "transition_category"])
      ),
      "must equal row-derived review_timeline_ids_by_approval_transition_category"
    )
  end

  defp validate_row(issues, callbacks, path, row) do
    issues
    |> require_fields(callbacks, path, row, [
      "rank",
      "timeline_id",
      "transition_decision",
      "review_required",
      "required_operator_action",
      "import_action"
    ])
    |> validate_stable_ids(callbacks, path, row, [
      "timeline_id",
      "activity_id",
      "planned_activity_id",
      "realized_activity_id"
    ])
    |> expect_number(callbacks, path, row, "rank")
    |> expect_one_of(
      callbacks,
      path,
      row,
      "transition_decision",
      OrbitalDynamics.Timeline.capabilities().transition_decisions
    )
    |> expect_optional_one_of(
      callbacks,
      path,
      row,
      "status_transition_decision",
      OrbitalDynamics.Timeline.capabilities().transition_decisions
    )
    |> expect_optional_one_of(
      callbacks,
      path,
      row,
      "approval_transition_decision",
      OrbitalDynamics.Timeline.capabilities().transition_decisions
    )
    |> expect_type(callbacks, path, row, "review_required", :boolean)
    |> expect_type(callbacks, path, row, "required_operator_action", :binary)
    |> expect_type(callbacks, path, row, "import_action", :binary)
    |> expect_optional_type(callbacks, path, row, "required_operator_actions", :list)
    |> expect_optional_type(callbacks, path, row, "operator_action_reasons", :list)
    |> expect_optional_type(callbacks, path, row, "planned_activity_ids", :list)
    |> expect_optional_type(callbacks, path, row, "realized_activity_ids", :list)
    |> validate_optional_string_list(callbacks, path, row, "required_operator_actions")
    |> validate_optional_string_list(callbacks, path, row, "operator_action_reasons")
    |> validate_optional_stable_id_list(callbacks, path, row, "planned_activity_ids")
    |> validate_optional_stable_id_list(callbacks, path, row, "realized_activity_ids")
    |> expect_optional_type(callbacks, path, row, "status_transition", :map)
    |> expect_optional_type(callbacks, path, row, "approval_transition", :map)
    |> validate_optional_lifecycle_transition(callbacks, path, row, "status_transition")
    |> validate_optional_lifecycle_transition(callbacks, path, row, "approval_transition")
    |> expect_optional_type(callbacks, path, row, "planned_activity_context", :map)
    |> expect_optional_type(callbacks, path, row, "realized_activity_context", :map)
    |> validate_optional_activity_context(callbacks, path, row, "planned_activity_context")
    |> validate_optional_activity_context(callbacks, path, row, "realized_activity_context")
    |> validate_optional_lifecycle_state_source_protection_decision(
      callbacks,
      path,
      row,
      "planned_protection_decision"
    )
    |> validate_optional_lifecycle_state_source_protection_decision(
      callbacks,
      path,
      row,
      "realized_protection_decision"
    )
    |> expect_optional_type(callbacks, path, row, "planned_locked", :boolean)
    |> expect_optional_type(callbacks, path, row, "realized_locked", :boolean)
    |> expect_optional_type(callbacks, path, row, "planned_executed", :boolean)
    |> expect_optional_type(callbacks, path, row, "realized_executed", :boolean)
    |> expect_optional_type(callbacks, path, row, "timeline_identity_collision", :boolean)
    |> expect_optional_type(callbacks, path, row, "invalid_activity_input", :boolean)
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      row,
      "invalid_activity_input_count"
    )
    |> expect_optional_type(callbacks, path, row, "invalid_activity_input_reasons", :list)
    |> validate_optional_string_list(callbacks, path, row, "invalid_activity_input_reasons")
  end

  defp timeline_ids(rows, predicate) do
    rows
    |> Enum.filter(predicate)
    |> Enum.map(&Map.get(&1, "timeline_id"))
    |> sorted_unique_binary_values()
  end

  defp activity_ids(rows) do
    rows
    |> Enum.flat_map(fn row ->
      [
        row["activity_id"],
        row["planned_activity_id"],
        row["realized_activity_id"]
        | list_value(row, "planned_activity_ids") ++ list_value(row, "realized_activity_ids")
      ]
    end)
    |> sorted_unique_binary_values()
  end

  defp timeline_ids_by(rows, key_fun) do
    rows
    |> Enum.reduce(%{}, fn row, acc ->
      key = key_fun.(row)
      timeline_id = Map.get(row, "timeline_id")

      if is_binary(key) and is_binary(timeline_id) do
        Map.update(acc, key, [timeline_id], &[timeline_id | &1])
      else
        acc
      end
    end)
    |> Map.new(fn {key, ids} -> {key, sorted_unique_binary_values(ids)} end)
  end

  defp timeline_ids_by_each(rows, values_fun) do
    rows
    |> Enum.reduce(%{}, fn row, acc ->
      timeline_id = Map.get(row, "timeline_id")

      if is_binary(timeline_id) do
        row
        |> values_fun.()
        |> List.wrap()
        |> Enum.reject(&(&1 in [nil, ""]))
        |> Enum.reduce(acc, fn key, inner_acc ->
          Map.update(inner_acc, key, [timeline_id], &[timeline_id | &1])
        end)
      else
        acc
      end
    end)
    |> Map.new(fn {key, ids} -> {key, sorted_unique_binary_values(ids)} end)
  end

  defp operator_action_reason_counts(rows) do
    rows
    |> Enum.flat_map(&list_value(&1, "operator_action_reasons"))
    |> Enum.frequencies()
  end

  defp frequency_map(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
  end

  defp nested_frequency_map(rows, field, nested_field) do
    rows
    |> Enum.map(&get_in(&1, [field, nested_field]))
    |> Enum.reject(&(&1 in [nil, ""]))
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

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :require_fields), [issues, path, map, fields])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_one_of(issues, callbacks, path, map, field, values),
    do: apply(Keyword.fetch!(callbacks, :expect_one_of), [issues, path, map, field, values])

  defp expect_optional_one_of(issues, callbacks, path, map, field, values) do
    apply(Keyword.fetch!(callbacks, :expect_optional_one_of), [
      issues,
      path,
      map,
      field,
      values
    ])
  end

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_number(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_number), [issues, path, map, field])

  defp expect_non_negative_integer(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :expect_non_negative_integer), [issues, path, map, field])
  end

  defp expect_optional_non_negative_integer(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :expect_optional_non_negative_integer), [
      issues,
      path,
      map,
      field
    ])
  end

  defp expect_field_equals(issues, callbacks, path, map, field, expected),
    do:
      apply(Keyword.fetch!(callbacks, :expect_field_equals), [issues, path, map, field, expected])

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

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(Keyword.fetch!(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp validate_optional_string_list(issues, callbacks, path, map, field),
    do:
      apply(Keyword.fetch!(callbacks, :validate_optional_string_list), [issues, path, map, field])

  defp validate_optional_lifecycle_transition(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :validate_optional_lifecycle_transition), [
      issues,
      path,
      map,
      field
    ])
  end

  defp validate_optional_activity_context(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :validate_optional_activity_context), [
      issues,
      path,
      map,
      field
    ])
  end

  defp validate_optional_lifecycle_state_source_protection_decision(
         issues,
         callbacks,
         path,
         row,
         field
       ) do
    apply(
      Keyword.fetch!(callbacks, :validate_optional_lifecycle_state_source_protection_decision),
      [
        issues,
        path,
        row,
        field
      ]
    )
  end

  defp timeline_report_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :timeline_report_model_limits), [])
end
