defmodule OrbitalDynamics.Schema.TimelineLifecycleStateSummaryContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_number: 4,
      expect_one_of: 5,
      expect_optional_non_negative_integer: 4,
      expect_optional_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_non_negative_integer_count_map: 3,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_optional_stable_id_list: 4,
      validate_stable_id_array_map: 3,
      validate_stable_ids: 4
    ]

  alias OrbitalDynamics.Schema.{
    ActivityContextContracts,
    CollectionValidation,
    LifecycleTransitionContracts,
    ProtectionDecisionContracts
  }

  def validate(issues, path, summary, model_limits) when is_list(model_limits) do
    issues
    |> expect_equal(
      path,
      summary,
      "schema_contract",
      "timeline_lifecycle_state_summary.v1"
    )
    |> expect_type(path, summary, "model", :binary)
    |> expect_equal(
      path,
      summary,
      "model",
      "artifact_only_timeline_lifecycle_state_summary"
    )
    |> expect_type(path, summary, "source", :binary)
    |> expect_equal(path, summary, "validation_level", "artifact_contract")
    |> expect_type(path, summary, "model_limits", :list)
    |> validate_string_list_items(path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      summary,
      model_limits,
      "must match timeline report model limits"
    )
    |> expect_non_negative_integer(path, summary, "planned_activity_count")
    |> expect_non_negative_integer(path, summary, "realized_activity_count")
    |> expect_non_negative_integer(path, summary, "row_count")
    |> expect_non_negative_integer(path, summary, "recordable_count")
    |> expect_non_negative_integer(path, summary, "preserved_count")
    |> expect_non_negative_integer(path, summary, "review_required_count")
    |> expect_non_negative_integer(path, summary, "duplicate_timeline_identity_count")
    |> expect_non_negative_integer(path, summary, "invalid_activity_input_count")
    |> expect_type(path, summary, "transition_decision_counts", :map)
    |> expect_type(path, summary, "required_operator_action_counts", :map)
    |> expect_type(path, summary, "import_action_counts", :map)
    |> expect_optional_type(path, summary, "operator_action_reason_counts", :map)
    |> expect_optional_type(path, summary, "planned_status_category_counts", :map)
    |> expect_optional_type(path, summary, "realized_status_category_counts", :map)
    |> expect_optional_type(path, summary, "planned_approval_category_counts", :map)
    |> expect_optional_type(path, summary, "realized_approval_category_counts", :map)
    |> expect_optional_type(path, summary, "status_transition_category_counts", :map)
    |> expect_optional_type(path, summary, "approval_transition_category_counts", :map)
    |> expect_optional_type(path, summary, "recordable_timeline_ids", :list)
    |> expect_optional_type(path, summary, "preserved_timeline_ids", :list)
    |> expect_optional_type(path, summary, "review_timeline_ids", :list)
    |> expect_optional_type(path, summary, "review_activity_ids", :list)
    |> expect_optional_type(path, summary, "invalid_activity_input_ids", :list)
    |> validate_optional_stable_id_list(path, summary, "recordable_timeline_ids")
    |> validate_optional_stable_id_list(path, summary, "preserved_timeline_ids")
    |> validate_optional_stable_id_list(path, summary, "review_timeline_ids")
    |> validate_optional_stable_id_list(path, summary, "review_activity_ids")
    |> validate_optional_stable_id_list(path, summary, "invalid_activity_input_ids")
    |> expect_optional_type(
      path,
      summary,
      "review_timeline_ids_by_required_operator_action",
      :map
    )
    |> expect_optional_type(
      path,
      summary,
      "review_timeline_ids_by_operator_action_reason",
      :map
    )
    |> expect_optional_type(
      path,
      summary,
      "review_timeline_ids_by_status_transition_category",
      :map
    )
    |> expect_optional_type(
      path,
      summary,
      "review_timeline_ids_by_approval_transition_category",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".review_timeline_ids_by_required_operator_action",
      Map.get(summary, "review_timeline_ids_by_required_operator_action")
    )
    |> validate_stable_id_array_map(
      path <> ".review_timeline_ids_by_operator_action_reason",
      Map.get(summary, "review_timeline_ids_by_operator_action_reason")
    )
    |> validate_stable_id_array_map(
      path <> ".review_timeline_ids_by_status_transition_category",
      Map.get(summary, "review_timeline_ids_by_status_transition_category")
    )
    |> validate_stable_id_array_map(
      path <> ".review_timeline_ids_by_approval_transition_category",
      Map.get(summary, "review_timeline_ids_by_approval_transition_category")
    )
    |> expect_type(path, summary, "rows", :list)
    |> expect_type(path, summary, "review_rows", :list)
    |> expect_type(path, summary, "assumptions", :map)
    |> validate_counts(path, summary)
    |> CollectionValidation.validate_rows(
      path <> ".rows",
      Map.get(summary, "rows", []),
      &validate_row(&1, &2, &3)
    )
    |> CollectionValidation.validate_rows(
      path <> ".review_rows",
      Map.get(summary, "review_rows", []),
      &validate_row(&1, &2, &3)
    )
  end

  defp validate_counts(issues, path, summary) do
    rows =
      summary
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    review_rows = Enum.filter(rows, &(&1["review_required"] == true))

    issues
    |> validate_non_negative_integer_count_map(
      path <> ".transition_decision_counts",
      Map.get(summary, "transition_decision_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".required_operator_action_counts",
      Map.get(summary, "required_operator_action_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".operator_action_reason_counts",
      Map.get(summary, "operator_action_reason_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".import_action_counts",
      Map.get(summary, "import_action_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".planned_status_category_counts",
      Map.get(summary, "planned_status_category_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".realized_status_category_counts",
      Map.get(summary, "realized_status_category_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".planned_approval_category_counts",
      Map.get(summary, "planned_approval_category_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".realized_approval_category_counts",
      Map.get(summary, "realized_approval_category_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".status_transition_category_counts",
      Map.get(summary, "status_transition_category_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".approval_transition_category_counts",
      Map.get(summary, "approval_transition_category_counts")
    )
    |> expect_field_equals(path, summary, "row_count", length(rows))
    |> expect_field_equals(
      path,
      summary,
      "recordable_count",
      Enum.count(rows, &(&1["transition_decision"] == "record"))
    )
    |> expect_field_equals(
      path,
      summary,
      "preserved_count",
      Enum.count(rows, &(&1["transition_decision"] == "none"))
    )
    |> expect_field_equals(path, summary, "review_required_count", length(review_rows))
    |> expect_field_equals(
      path,
      summary,
      "duplicate_timeline_identity_count",
      Enum.count(rows, &(&1["timeline_identity_collision"] == true))
    )
    |> expect_field_equals(
      path,
      summary,
      "invalid_activity_input_count",
      Enum.count(rows, &(&1["invalid_activity_input"] == true))
    )
    |> expect_field_equals(
      path,
      summary,
      "transition_decision_counts",
      frequency_map(rows, "transition_decision"),
      "must equal row-derived transition_decision_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "required_operator_action_counts",
      frequency_map(rows, "required_operator_action"),
      "must equal row-derived required_operator_action_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "operator_action_reason_counts",
      operator_action_reason_counts(rows),
      "must equal row-derived operator_action_reason_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "import_action_counts",
      frequency_map(rows, "import_action"),
      "must equal row-derived import_action_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "planned_status_category_counts",
      frequency_map(rows, "planned_status_category"),
      "must equal row-derived planned_status_category_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "realized_status_category_counts",
      frequency_map(rows, "realized_status_category"),
      "must equal row-derived realized_status_category_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "planned_approval_category_counts",
      frequency_map(rows, "planned_approval_category"),
      "must equal row-derived planned_approval_category_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "realized_approval_category_counts",
      frequency_map(rows, "realized_approval_category"),
      "must equal row-derived realized_approval_category_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "status_transition_category_counts",
      nested_frequency_map(rows, "status_transition", "transition_category"),
      "must equal row-derived status_transition_category_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "approval_transition_category_counts",
      nested_frequency_map(rows, "approval_transition", "transition_category"),
      "must equal row-derived approval_transition_category_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "recordable_timeline_ids",
      timeline_ids(rows, &(&1["transition_decision"] == "record")),
      "must equal row-derived recordable_timeline_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "preserved_timeline_ids",
      timeline_ids(rows, &(&1["transition_decision"] == "none")),
      "must equal row-derived preserved_timeline_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_timeline_ids",
      timeline_ids(review_rows, fn _row -> true end),
      "must equal row-derived review_timeline_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_activity_ids",
      activity_ids(review_rows),
      "must equal row-derived review_activity_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "invalid_activity_input_ids",
      rows
      |> Enum.filter(&(&1["invalid_activity_input"] == true))
      |> activity_ids(),
      "must equal row-derived invalid_activity_input_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_rows",
      review_rows,
      "must equal row-derived review rows"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_timeline_ids_by_required_operator_action",
      timeline_ids_by(review_rows, & &1["required_operator_action"]),
      "must equal row-derived review_timeline_ids_by_required_operator_action"
    )
    |> expect_field_equals(
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

  defp validate_row(issues, path, row) do
    issues
    |> require_fields(path, row, [
      "rank",
      "timeline_id",
      "transition_decision",
      "review_required",
      "required_operator_action",
      "import_action"
    ])
    |> validate_stable_ids(path, row, [
      "timeline_id",
      "activity_id",
      "planned_activity_id",
      "realized_activity_id"
    ])
    |> expect_number(path, row, "rank")
    |> expect_one_of(
      path,
      row,
      "transition_decision",
      OrbitalDynamics.Timeline.capabilities().transition_decisions
    )
    |> expect_optional_one_of(
      path,
      row,
      "status_transition_decision",
      OrbitalDynamics.Timeline.capabilities().transition_decisions
    )
    |> expect_optional_one_of(
      path,
      row,
      "approval_transition_decision",
      OrbitalDynamics.Timeline.capabilities().transition_decisions
    )
    |> expect_type(path, row, "review_required", :boolean)
    |> expect_type(path, row, "required_operator_action", :binary)
    |> expect_type(path, row, "import_action", :binary)
    |> expect_optional_type(path, row, "required_operator_actions", :list)
    |> expect_optional_type(path, row, "operator_action_reasons", :list)
    |> expect_optional_type(path, row, "planned_activity_ids", :list)
    |> expect_optional_type(path, row, "realized_activity_ids", :list)
    |> CollectionValidation.validate_optional_string_list(path, row, "required_operator_actions")
    |> CollectionValidation.validate_optional_string_list(path, row, "operator_action_reasons")
    |> validate_optional_stable_id_list(path, row, "planned_activity_ids")
    |> validate_optional_stable_id_list(path, row, "realized_activity_ids")
    |> expect_optional_type(path, row, "status_transition", :map)
    |> expect_optional_type(path, row, "approval_transition", :map)
    |> LifecycleTransitionContracts.validate_optional(path, row, "status_transition")
    |> LifecycleTransitionContracts.validate_optional(path, row, "approval_transition")
    |> expect_optional_type(path, row, "planned_activity_context", :map)
    |> expect_optional_type(path, row, "realized_activity_context", :map)
    |> ActivityContextContracts.validate_optional(path, row, "planned_activity_context")
    |> ActivityContextContracts.validate_optional(path, row, "realized_activity_context")
    |> validate_optional_lifecycle_state_source_protection_decision(
      path,
      row,
      "planned_protection_decision"
    )
    |> validate_optional_lifecycle_state_source_protection_decision(
      path,
      row,
      "realized_protection_decision"
    )
    |> expect_optional_type(path, row, "planned_locked", :boolean)
    |> expect_optional_type(path, row, "realized_locked", :boolean)
    |> expect_optional_type(path, row, "planned_executed", :boolean)
    |> expect_optional_type(path, row, "realized_executed", :boolean)
    |> expect_optional_type(path, row, "timeline_identity_collision", :boolean)
    |> expect_optional_type(path, row, "invalid_activity_input", :boolean)
    |> expect_optional_non_negative_integer(
      path,
      row,
      "invalid_activity_input_count"
    )
    |> expect_optional_type(path, row, "invalid_activity_input_reasons", :list)
    |> CollectionValidation.validate_optional_string_list(
      path,
      row,
      "invalid_activity_input_reasons"
    )
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

  defp validate_optional_lifecycle_state_source_protection_decision(
         issues,
         path,
         row,
         field
       ) do
    case Map.get(row, field) do
      nil -> issues
      %{} -> ProtectionDecisionContracts.validate_optional(issues, path, row, field)
      value when is_binary(value) -> issues
      _value -> [error("#{path}.#{field}", "must be a map or string") | issues]
    end
  end
end
