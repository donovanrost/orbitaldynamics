defmodule OrbitalDynamics.Schema.TimelineActivityStateContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    ActivityContextContracts,
    LifecycleTransitionContracts,
    ProtectionDecisionContracts,
    TimelineFeedbackRowContracts
  }

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_field_equals: 6,
      expect_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_optional_stable_id_list: 4, validate_stable_ids: 4]

  def validate(issues, path, state, timeline_feedback_report_model_limits, row_callbacks)
      when is_list(timeline_feedback_report_model_limits) and is_list(row_callbacks) do
    rows =
      case Map.get(state, "rows") do
        rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
        _rows -> []
      end

    issues
    |> expect_equal(path, state, "schema_contract", "timeline_activity_state.v1")
    |> expect_equal(path, state, "model", "artifact_only_timeline_activity_state")
    |> expect_equal(path, state, "validation_level", "artifact_contract")
    |> expect_one_of(path, state, "state_status", [
      "empty",
      "review_required" | OrbitalDynamics.TimelineFeedback.capabilities().report_statuses
    ])
    |> validate_stable_ids(path, state, [
      "activity_id",
      "timeline_id",
      "planned_timeline_id",
      "realized_timeline_id"
    ])
    |> expect_optional_type(path, state, "activity_ids", :list)
    |> validate_optional_stable_id_list(path, state, "activity_ids")
    |> expect_type(path, state, "review_required", :boolean)
    |> expect_type(path, state, "review_activity_ids", :list)
    |> validate_optional_stable_id_list(path, state, "review_activity_ids")
    |> expect_type(path, state, "rows", :list)
    |> expect_type(path, state, "assumptions", :map)
    |> expect_type(path, state, "model_limits", :list)
    |> validate_string_list_items(path, state, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      state,
      timeline_feedback_report_model_limits,
      "must match timeline activity state model limits"
    )
    |> validate_timeline_activity_state_assumptions(path, state, [
      "artifact_only",
      "no_schedule_mutation",
      "no_command_execution"
    ])
    |> expect_optional_type(path, state, "status_transition", :map)
    |> expect_optional_type(path, state, "approval_transition", :map)
    |> LifecycleTransitionContracts.validate_optional(path, state, "status_transition")
    |> LifecycleTransitionContracts.validate_optional(path, state, "approval_transition")
    |> expect_optional_type(path, state, "planned_status_category", :binary)
    |> expect_optional_type(path, state, "realized_status_category", :binary)
    |> expect_optional_type(path, state, "planned_approval_status", :binary)
    |> expect_optional_type(path, state, "realized_approval_status", :binary)
    |> expect_optional_type(path, state, "planned_approval_category", :binary)
    |> expect_optional_type(path, state, "realized_approval_category", :binary)
    |> expect_optional_type(path, state, "planned_locked", :boolean)
    |> expect_optional_type(path, state, "realized_locked", :boolean)
    |> expect_optional_type(path, state, "planned_executed", :boolean)
    |> expect_optional_type(path, state, "realized_executed", :boolean)
    |> expect_optional_type(path, state, "source_protection_decision", :map)
    |> expect_optional_type(path, state, "realized_protection_decision", :map)
    |> expect_optional_type(path, state, "realized_provider_counts", :map)
    |> expect_optional_type(path, state, "realized_source_quality_counts", :map)
    |> expect_optional_type(path, state, "realized_trust_boundary_status", :binary)
    |> expect_optional_type(path, state, "realized_trust_boundaries", :list)
    |> validate_string_list_items(path, state, "realized_trust_boundaries")
    |> ProtectionDecisionContracts.validate_optional(path, state, "source_protection_decision")
    |> ProtectionDecisionContracts.validate_optional(path, state, "realized_protection_decision")
    |> expect_optional_type(path, state, "source_activity_context", :map)
    |> expect_optional_type(path, state, "realized_activity_context", :map)
    |> ActivityContextContracts.validate_optional(path, state, "source_activity_context")
    |> ActivityContextContracts.validate_optional(path, state, "realized_activity_context")
    |> validate_count_maps(path, state, rows)
    |> expect_field_equals(
      path,
      state,
      "state_status",
      timeline_activity_state_status(rows),
      "must equal row-derived state_status"
    )
    |> expect_field_equals(
      path,
      state,
      "activity_ids",
      timeline_activity_state_ids(rows),
      "must equal row-derived activity_ids"
    )
    |> expect_field_equals(
      path,
      state,
      "review_required",
      timeline_activity_state_review_required?(rows),
      "must equal row-derived review_required"
    )
    |> expect_field_equals(
      path,
      state,
      "review_activity_ids",
      timeline_activity_state_review_ids(rows),
      "must equal row-derived review_activity_ids"
    )
    |> validate_rows(path <> ".rows", Map.get(state, "rows", []), fn acc, row_path, row ->
      TimelineFeedbackRowContracts.validate(acc, row_path, row, row_callbacks)
    end)
  end

  defp validate_count_maps(issues, path, state, rows) do
    issues
    |> validate_non_negative_integer_count_map(
      path <> ".status_counts",
      Map.get(state, "status_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".feedback_kind_counts",
      Map.get(state, "feedback_kind_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".match_strategy_counts",
      Map.get(state, "match_strategy_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".cadence_import_status_counts",
      Map.get(state, "cadence_import_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".planned_protection_decision_counts",
      Map.get(state, "planned_protection_decision_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".realized_provider_counts",
      Map.get(state, "realized_provider_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".realized_source_quality_counts",
      Map.get(state, "realized_source_quality_counts")
    )
    |> expect_field_equals(path, state, "row_count", length(rows))
    |> expect_field_equals(
      path,
      state,
      "status_counts",
      frequency_map(rows, "status"),
      "must equal row-derived status_counts"
    )
    |> expect_field_equals(
      path,
      state,
      "feedback_kind_counts",
      frequency_map(rows, "feedback_kind"),
      "must equal row-derived feedback_kind_counts"
    )
    |> expect_field_equals(
      path,
      state,
      "match_strategy_counts",
      frequency_map(rows, "match_strategy"),
      "must equal row-derived match_strategy_counts"
    )
    |> expect_field_equals(
      path,
      state,
      "cadence_import_status_counts",
      frequency_map(rows, "cadence_import_status"),
      "must equal row-derived cadence_import_status_counts"
    )
    |> expect_field_equals(
      path,
      state,
      "planned_protection_decision_counts",
      frequency_map(rows, "planned_protection_decision"),
      "must equal row-derived planned_protection_decision_counts"
    )
    |> expect_field_equals(
      path,
      state,
      "realized_provider_counts",
      timeline_activity_state_optional_frequency_map(rows, "realized_provider"),
      "must equal row-derived realized_provider_counts"
    )
    |> expect_field_equals(
      path,
      state,
      "realized_source_quality_counts",
      timeline_activity_state_optional_frequency_map(rows, "realized_source_quality"),
      "must equal row-derived realized_source_quality_counts"
    )
    |> expect_field_equals(
      path,
      state,
      "realized_trust_boundary_status",
      timeline_activity_state_realized_trust_boundary_status(rows),
      "must equal row-derived realized_trust_boundary_status"
    )
    |> expect_field_equals(
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

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")

  defp validate_timeline_activity_state_assumptions(issues, path, state, fields) do
    case Map.get(state, "assumptions") do
      assumptions when is_map(assumptions) ->
        Enum.reduce(fields, issues, fn field, acc ->
          expect_equal(acc, path <> ".assumptions", assumptions, field, true)
        end)

      _assumptions ->
        issues
    end
  end
end
