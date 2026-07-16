defmodule OrbitalDynamics.Schema.TimelineSelectedIntegrityContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_field_equals: 6,
      expect_optional_non_negative_integer: 4,
      expect_optional_type: 5,
      validate_string_list_allowed: 5
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_optional_stable_id_list: 4]

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

  def validate(issues, path, row) do
    issues
    |> expect_optional_type(path, row, "selected_activity_source", :binary)
    |> expect_optional_type(path, row, "selected_activity", :map)
    |> expect_optional_type(path, row, "selected_timeline_integrity_status", :binary)
    |> expect_optional_non_negative_integer(
      path,
      row,
      "selected_timeline_integrity_issue_count"
    )
    |> expect_optional_type(
      path,
      row,
      "selected_timeline_integrity_issue_types",
      :list
    )
    |> validate_string_list_allowed(
      path,
      row,
      "selected_timeline_integrity_issue_types",
      timeline_capability().timeline_integrity_issue_types
    )
    |> expect_optional_type(path, row, "selected_timeline_integrity_issues", :list)
    |> expect_optional_type(
      path,
      row,
      "selected_missing_dependency_activity_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      row,
      "selected_missing_dependency_activity_ids"
    )
    |> expect_optional_type(
      path,
      row,
      "selected_missing_dependency_timeline_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      row,
      "selected_missing_dependency_timeline_ids"
    )
    |> expect_optional_type(path, row, "selected_self_dependency_activity_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      row,
      "selected_self_dependency_activity_ids"
    )
    |> expect_optional_type(path, row, "selected_self_dependency_timeline_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      row,
      "selected_self_dependency_timeline_ids"
    )
    |> expect_optional_type(
      path,
      row,
      "selected_duplicate_dependency_activity_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      row,
      "selected_duplicate_dependency_activity_ids"
    )
    |> expect_optional_type(
      path,
      row,
      "selected_duplicate_dependency_timeline_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      row,
      "selected_duplicate_dependency_timeline_ids"
    )
    |> expect_optional_type(
      path,
      row,
      "selected_duplicate_exclusivity_activity_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      row,
      "selected_duplicate_exclusivity_activity_ids"
    )
    |> expect_optional_type(
      path,
      row,
      "selected_duplicate_exclusivity_timeline_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      row,
      "selected_duplicate_exclusivity_timeline_ids"
    )
    |> expect_optional_type(path, row, "selected_dependency_cycle_activity_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      row,
      "selected_dependency_cycle_activity_ids"
    )
    |> expect_optional_type(path, row, "selected_dependency_cycle_timeline_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      row,
      "selected_dependency_cycle_timeline_ids"
    )
    |> expect_optional_type(
      path,
      row,
      "selected_dependency_order_violation_activity_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      row,
      "selected_dependency_order_violation_activity_ids"
    )
    |> expect_optional_type(
      path,
      row,
      "selected_dependency_order_violation_timeline_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      row,
      "selected_dependency_order_violation_timeline_ids"
    )
    |> expect_optional_type(
      path,
      row,
      "selected_exclusivity_violation_activity_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      row,
      "selected_exclusivity_violation_activity_ids"
    )
    |> expect_optional_type(
      path,
      row,
      "selected_exclusivity_violation_timeline_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      row,
      "selected_exclusivity_violation_timeline_ids"
    )
    |> expect_optional_type(path, row, "selected_exclusivity_violation_group", :binary)
    |> validate_handoff_matches_activity(path, row)
  end

  defp validate_handoff_matches_activity(issues, path, row) do
    case Map.get(row, "selected_activity") do
      %{} = selected_activity ->
        Enum.reduce(@selected_activity_match_fields, issues, fn {field, selected_activity_field},
                                                                acc ->
          expect_field_equals(
            acc,
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
end
