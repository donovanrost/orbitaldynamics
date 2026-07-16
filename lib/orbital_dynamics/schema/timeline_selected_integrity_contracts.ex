defmodule OrbitalDynamics.Schema.TimelineSelectedIntegrityContracts do
  @moduledoc false

  @selected_activity_match_fields [
    {"selected_timeline_integrity_status", "timeline_integrity_status"},
    {"selected_timeline_integrity_issue_count", "timeline_integrity_issue_count"},
    {"selected_timeline_integrity_issue_types", "timeline_integrity_issue_types"},
    {"selected_timeline_integrity_issues", "timeline_integrity_issues"},
    {"selected_missing_dependency_activity_ids", "missing_dependency_activity_ids"},
    {"selected_missing_dependency_timeline_ids", "missing_dependency_timeline_ids"},
    {"selected_self_dependency_activity_ids", "self_dependency_activity_ids"},
    {"selected_self_dependency_timeline_ids", "self_dependency_timeline_ids"},
    {"selected_duplicate_dependency_activity_ids", "duplicate_dependency_activity_ids"},
    {"selected_duplicate_dependency_timeline_ids", "duplicate_dependency_timeline_ids"},
    {"selected_duplicate_exclusivity_activity_ids", "duplicate_exclusivity_activity_ids"},
    {"selected_duplicate_exclusivity_timeline_ids", "duplicate_exclusivity_timeline_ids"},
    {"selected_dependency_cycle_activity_ids", "dependency_cycle_activity_ids"},
    {"selected_dependency_cycle_timeline_ids", "dependency_cycle_timeline_ids"},
    {"selected_dependency_order_violation_activity_ids",
     "dependency_order_violation_activity_ids"},
    {"selected_dependency_order_violation_timeline_ids",
     "dependency_order_violation_timeline_ids"},
    {"selected_exclusivity_violation_activity_ids", "exclusivity_violation_activity_ids"},
    {"selected_exclusivity_violation_timeline_ids", "exclusivity_violation_timeline_ids"},
    {"selected_exclusivity_violation_group", "exclusivity_violation_group"}
  ]

  def validate(issues, path, row, callbacks) when is_list(callbacks) do
    issues
    |> expect_optional_type(callbacks, path, row, "selected_activity_source", :binary)
    |> expect_optional_type(callbacks, path, row, "selected_activity", :map)
    |> expect_optional_type(callbacks, path, row, "selected_timeline_integrity_status", :binary)
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      row,
      "selected_timeline_integrity_issue_count"
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "selected_timeline_integrity_issue_types",
      :list
    )
    |> validate_string_list_allowed(
      callbacks,
      path,
      row,
      "selected_timeline_integrity_issue_types",
      timeline_capability().timeline_integrity_issue_types
    )
    |> expect_optional_type(callbacks, path, row, "selected_timeline_integrity_issues", :list)
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "selected_missing_dependency_activity_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "selected_missing_dependency_activity_ids"
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "selected_missing_dependency_timeline_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "selected_missing_dependency_timeline_ids"
    )
    |> expect_optional_type(callbacks, path, row, "selected_self_dependency_activity_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "selected_self_dependency_activity_ids"
    )
    |> expect_optional_type(callbacks, path, row, "selected_self_dependency_timeline_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "selected_self_dependency_timeline_ids"
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "selected_duplicate_dependency_activity_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "selected_duplicate_dependency_activity_ids"
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "selected_duplicate_dependency_timeline_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "selected_duplicate_dependency_timeline_ids"
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "selected_duplicate_exclusivity_activity_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "selected_duplicate_exclusivity_activity_ids"
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "selected_duplicate_exclusivity_timeline_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "selected_duplicate_exclusivity_timeline_ids"
    )
    |> expect_optional_type(callbacks, path, row, "selected_dependency_cycle_activity_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "selected_dependency_cycle_activity_ids"
    )
    |> expect_optional_type(callbacks, path, row, "selected_dependency_cycle_timeline_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "selected_dependency_cycle_timeline_ids"
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "selected_dependency_order_violation_activity_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "selected_dependency_order_violation_activity_ids"
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "selected_dependency_order_violation_timeline_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "selected_dependency_order_violation_timeline_ids"
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "selected_exclusivity_violation_activity_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "selected_exclusivity_violation_activity_ids"
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "selected_exclusivity_violation_timeline_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "selected_exclusivity_violation_timeline_ids"
    )
    |> expect_optional_type(callbacks, path, row, "selected_exclusivity_violation_group", :binary)
    |> validate_handoff_matches_activity(callbacks, path, row)
  end

  defp validate_handoff_matches_activity(issues, callbacks, path, row) do
    case Map.get(row, "selected_activity") do
      %{} = selected_activity ->
        Enum.reduce(@selected_activity_match_fields, issues, fn {field, selected_activity_field},
                                                                acc ->
          expect_field_equals(
            acc,
            callbacks,
            path,
            row,
            field,
            Map.get(selected_activity, selected_activity_field),
            "must match selected_activity #{selected_activity_field} values"
          )
        end)

      _selected_activity ->
        issues
    end
  end

  defp timeline_capability, do: OrbitalDynamics.Timeline.capabilities()

  defp expect_field_equals(issues, callbacks, path, row, field, expected, message) do
    callback!(callbacks, :expect_field_equals).(issues, path, row, field, expected, message)
  end

  defp expect_optional_non_negative_integer(issues, callbacks, path, row, field) do
    callback!(callbacks, :expect_optional_non_negative_integer).(issues, path, row, field)
  end

  defp expect_optional_type(issues, callbacks, path, row, field, type) do
    callback!(callbacks, :expect_optional_type).(issues, path, row, field, type)
  end

  defp validate_optional_stable_id_list(issues, callbacks, path, row, field) do
    callback!(callbacks, :validate_optional_stable_id_list).(issues, path, row, field)
  end

  defp validate_string_list_allowed(issues, callbacks, path, row, field, values) do
    callback!(callbacks, :validate_string_list_allowed).(issues, path, row, field, values)
  end

  defp callback!(callbacks, name), do: Keyword.fetch!(callbacks, name)
end
