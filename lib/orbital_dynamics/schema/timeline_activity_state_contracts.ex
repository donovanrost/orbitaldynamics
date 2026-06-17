defmodule OrbitalDynamics.Schema.TimelineActivityStateContracts do
  @moduledoc false

  def validate(issues, path, state, callbacks) when is_list(callbacks) do
    rows =
      case Map.get(state, "rows") do
        rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
        _rows -> []
      end

    issues
    |> expect_equal(callbacks, path, state, "schema_contract", "timeline_activity_state.v1")
    |> expect_equal(callbacks, path, state, "model", "artifact_only_timeline_activity_state")
    |> expect_equal(callbacks, path, state, "validation_level", "artifact_contract")
    |> expect_one_of(
      callbacks,
      path,
      state,
      "state_status",
      [
        "empty",
        "review_required" | OrbitalDynamics.TimelineFeedback.capabilities().report_statuses
      ]
    )
    |> validate_stable_ids(callbacks, path, state, [
      "activity_id",
      "timeline_id",
      "planned_timeline_id",
      "realized_timeline_id"
    ])
    |> expect_optional_type(callbacks, path, state, "activity_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, state, "activity_ids")
    |> expect_type(callbacks, path, state, "review_required", :boolean)
    |> expect_type(callbacks, path, state, "review_activity_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, state, "review_activity_ids")
    |> expect_type(callbacks, path, state, "rows", :list)
    |> expect_type(callbacks, path, state, "assumptions", :map)
    |> expect_type(callbacks, path, state, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, state, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      state,
      timeline_feedback_report_model_limits(callbacks),
      "must match timeline activity state model limits"
    )
    |> validate_timeline_activity_state_assumptions(callbacks, path, state, [
      "artifact_only",
      "no_schedule_mutation",
      "no_command_execution"
    ])
    |> expect_optional_type(callbacks, path, state, "status_transition", :map)
    |> expect_optional_type(callbacks, path, state, "approval_transition", :map)
    |> validate_optional_lifecycle_transition(callbacks, path, state, "status_transition")
    |> validate_optional_lifecycle_transition(callbacks, path, state, "approval_transition")
    |> expect_optional_type(callbacks, path, state, "planned_status_category", :binary)
    |> expect_optional_type(callbacks, path, state, "realized_status_category", :binary)
    |> expect_optional_type(callbacks, path, state, "planned_approval_status", :binary)
    |> expect_optional_type(callbacks, path, state, "realized_approval_status", :binary)
    |> expect_optional_type(callbacks, path, state, "planned_approval_category", :binary)
    |> expect_optional_type(callbacks, path, state, "realized_approval_category", :binary)
    |> expect_optional_type(callbacks, path, state, "planned_locked", :boolean)
    |> expect_optional_type(callbacks, path, state, "realized_locked", :boolean)
    |> expect_optional_type(callbacks, path, state, "planned_executed", :boolean)
    |> expect_optional_type(callbacks, path, state, "realized_executed", :boolean)
    |> expect_optional_type(callbacks, path, state, "source_protection_decision", :map)
    |> expect_optional_type(callbacks, path, state, "realized_protection_decision", :map)
    |> expect_optional_type(callbacks, path, state, "realized_provider_counts", :map)
    |> expect_optional_type(callbacks, path, state, "realized_source_quality_counts", :map)
    |> expect_optional_type(callbacks, path, state, "realized_trust_boundary_status", :binary)
    |> expect_optional_type(callbacks, path, state, "realized_trust_boundaries", :list)
    |> validate_string_list_items(callbacks, path, state, "realized_trust_boundaries")
    |> validate_optional_protection_decision(callbacks, path, state, "source_protection_decision")
    |> validate_optional_protection_decision(
      callbacks,
      path,
      state,
      "realized_protection_decision"
    )
    |> expect_optional_type(callbacks, path, state, "source_activity_context", :map)
    |> expect_optional_type(callbacks, path, state, "realized_activity_context", :map)
    |> validate_optional_activity_context(callbacks, path, state, "source_activity_context")
    |> validate_optional_activity_context(callbacks, path, state, "realized_activity_context")
    |> validate_count_maps(callbacks, path, state, rows)
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "state_status",
      timeline_activity_state_status(rows),
      "must equal row-derived state_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "activity_ids",
      timeline_activity_state_ids(rows),
      "must equal row-derived activity_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "review_required",
      timeline_activity_state_review_required?(rows),
      "must equal row-derived review_required"
    )
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "review_activity_ids",
      timeline_activity_state_review_ids(rows),
      "must equal row-derived review_activity_ids"
    )
    |> validate_rows(
      callbacks,
      path <> ".rows",
      Map.get(state, "rows", []),
      fn acc, row_path, row -> validate_timeline_feedback_row(callbacks, acc, row_path, row) end
    )
  end

  defp validate_count_maps(issues, callbacks, path, state, rows) do
    issues
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".status_counts",
      Map.get(state, "status_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".feedback_kind_counts",
      Map.get(state, "feedback_kind_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".match_strategy_counts",
      Map.get(state, "match_strategy_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".cadence_import_status_counts",
      Map.get(state, "cadence_import_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".planned_protection_decision_counts",
      Map.get(state, "planned_protection_decision_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".realized_provider_counts",
      Map.get(state, "realized_provider_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".realized_source_quality_counts",
      Map.get(state, "realized_source_quality_counts")
    )
    |> expect_field_equals(callbacks, path, state, "row_count", length(rows))
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "status_counts",
      frequency_map(rows, "status"),
      "must equal row-derived status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "feedback_kind_counts",
      frequency_map(rows, "feedback_kind"),
      "must equal row-derived feedback_kind_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "match_strategy_counts",
      frequency_map(rows, "match_strategy"),
      "must equal row-derived match_strategy_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "cadence_import_status_counts",
      frequency_map(rows, "cadence_import_status"),
      "must equal row-derived cadence_import_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "planned_protection_decision_counts",
      frequency_map(rows, "planned_protection_decision"),
      "must equal row-derived planned_protection_decision_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "realized_provider_counts",
      timeline_activity_state_optional_frequency_map(rows, "realized_provider"),
      "must equal row-derived realized_provider_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "realized_source_quality_counts",
      timeline_activity_state_optional_frequency_map(rows, "realized_source_quality"),
      "must equal row-derived realized_source_quality_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "realized_trust_boundary_status",
      timeline_activity_state_realized_trust_boundary_status(rows),
      "must equal row-derived realized_trust_boundary_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "realized_trust_boundaries",
      timeline_activity_state_realized_trust_boundaries(rows),
      "must equal row-derived realized_trust_boundaries"
    )
  end

  defp timeline_activity_state_optional_frequency_map(rows, field) do
    case frequency_map(rows, field) do
      counts when map_size(counts) == 0 -> nil
      counts -> counts
    end
  end

  defp timeline_activity_state_realized_trust_boundary_status(rows) do
    if timeline_activity_state_realized_row_count(rows) == 0 do
      nil
    else
      case timeline_activity_state_realized_trust_boundary_values(rows) do
        [] -> "missing"
        _boundaries -> "declared"
      end
    end
  end

  defp timeline_activity_state_realized_trust_boundaries(rows) do
    case timeline_activity_state_realized_trust_boundary_values(rows) do
      [] -> nil
      boundaries -> boundaries
    end
  end

  defp timeline_activity_state_realized_trust_boundary_values(rows) do
    rows
    |> Enum.map(&Map.get(&1, "realized_trust_boundary"))
    |> Enum.filter(&present_string?/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp timeline_activity_state_realized_row_count(rows) do
    Enum.count(rows, fn row ->
      Map.get(row, "status") in ["matched", "realized_only"] or
        present_string?(Map.get(row, "realized_activity_id")) or
        present_string?(Map.get(row, "realized_status"))
    end)
  end

  defp timeline_activity_state_status([]), do: "empty"
  defp timeline_activity_state_status([%{"status" => status}]), do: status

  defp timeline_activity_state_status(rows) do
    if Enum.any?(rows, &(&1["status"] == "matched")) do
      "matched"
    else
      "review_required"
    end
  end

  defp timeline_activity_state_ids(rows) do
    rows
    |> Enum.map(&Map.get(&1, "activity_id"))
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp timeline_activity_state_review_required?(rows) do
    Enum.any?(rows, fn row ->
      Map.get(row, "status") != "matched" or
        Map.get(row, "planned_protection_decision") == "review_change" or
        present_timeline_activity_state_review_action?(Map.get(row, "required_operator_action")) or
        present_timeline_activity_state_review_action?(
          get_in(row, ["status_transition", "required_operator_action"])
        )
    end)
  end

  defp timeline_activity_state_review_ids(rows) do
    rows
    |> Enum.filter(&timeline_activity_state_review_required?([&1]))
    |> timeline_activity_state_ids()
  end

  defp present_timeline_activity_state_review_action?(action) when action in [nil, "", "none"],
    do: false

  defp present_timeline_activity_state_review_action?(_action), do: true

  defp frequency_map(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp present_string?(value), do: is_binary(value) and String.trim(value) != ""

  defp timeline_feedback_report_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :timeline_feedback_report_model_limits), [])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(Keyword.fetch!(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

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

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp validate_non_negative_integer_count_map(issues, callbacks, path, counts),
    do:
      apply(Keyword.fetch!(callbacks, :validate_non_negative_integer_count_map), [
        issues,
        path,
        counts
      ])

  defp validate_optional_exact_model_limits(issues, callbacks, path, state, expected, message),
    do:
      apply(Keyword.fetch!(callbacks, :validate_optional_exact_model_limits), [
        issues,
        path,
        state,
        expected,
        message
      ])

  defp validate_optional_stable_id_list(issues, callbacks, path, state, field),
    do:
      apply(Keyword.fetch!(callbacks, :validate_optional_stable_id_list), [
        issues,
        path,
        state,
        field
      ])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_timeline_activity_state_assumptions(issues, callbacks, path, state, fields),
    do:
      apply(Keyword.fetch!(callbacks, :validate_timeline_activity_state_assumptions), [
        issues,
        path,
        state,
        fields
      ])

  defp validate_optional_lifecycle_transition(issues, callbacks, path, state, field),
    do:
      apply(Keyword.fetch!(callbacks, :validate_optional_lifecycle_transition), [
        issues,
        path,
        state,
        field
      ])

  defp validate_optional_protection_decision(issues, callbacks, path, state, field),
    do:
      apply(Keyword.fetch!(callbacks, :validate_optional_protection_decision), [
        issues,
        path,
        state,
        field
      ])

  defp validate_optional_activity_context(issues, callbacks, path, state, field),
    do:
      apply(Keyword.fetch!(callbacks, :validate_optional_activity_context), [
        issues,
        path,
        state,
        field
      ])

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(Keyword.fetch!(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_timeline_feedback_row(callbacks, issues, path, row),
    do: apply(Keyword.fetch!(callbacks, :validate_timeline_feedback_row), [issues, path, row])
end
