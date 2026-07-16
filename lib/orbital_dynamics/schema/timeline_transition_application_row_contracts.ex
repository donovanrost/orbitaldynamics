defmodule OrbitalDynamics.Schema.TimelineTransitionApplicationRowContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_number: 4,
      expect_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  def validate(
        issues,
        path,
        row,
        lifecycle_transition_validator,
        protection_decision_validator,
        timeline_identity_collision_validator,
        selected_timeline_integrity_validator,
        timeline_diff_row_validator
      )
      when is_function(lifecycle_transition_validator, 4) and
             is_function(protection_decision_validator, 4) and
             is_function(timeline_identity_collision_validator, 3) and
             is_function(selected_timeline_integrity_validator, 3) and
             is_function(timeline_diff_row_validator, 3) do
    issues
    |> require_fields(path, row, [
      "id",
      "rank",
      "timeline_id",
      "diff_status",
      "transition_decision",
      "requires_operator_review",
      "required_operator_action",
      "reason",
      "changed_fields",
      "application_status",
      "source_timeline_diff"
    ])
    |> validate_stable_ids(path, row, [
      "id",
      "timeline_id",
      "source_activity_id",
      "replacement_activity_id"
    ])
    |> expect_number(path, row, "rank")
    |> expect_one_of(
      path,
      row,
      "diff_status",
      timeline_capability().timeline_diff_statuses
    )
    |> expect_type(path, row, "transition_decision", :binary)
    |> expect_one_of(
      path,
      row,
      "transition_decision",
      timeline_capability().transition_decisions
    )
    |> expect_type(path, row, "requires_operator_review", :boolean)
    |> expect_one_of(
      path,
      row,
      "required_operator_action",
      timeline_capability().timeline_diff_required_operator_actions
    )
    |> expect_type(path, row, "reason", :binary)
    |> expect_optional_type(path, row, "operator_action_reason", :binary)
    |> expect_type(path, row, "changed_fields", :list)
    |> expect_optional_type(path, row, "status_transition", :map)
    |> expect_optional_type(path, row, "approval_transition", :map)
    |> validate_optional_lifecycle_transition(
      path,
      row,
      "status_transition",
      lifecycle_transition_validator
    )
    |> validate_optional_lifecycle_transition(
      path,
      row,
      "approval_transition",
      lifecycle_transition_validator
    )
    |> expect_type(path, row, "application_status", :binary)
    |> expect_optional_type(path, row, "source_activity_type", :binary)
    |> expect_optional_type(path, row, "replacement_activity_type", :binary)
    |> expect_optional_type(path, row, "source_protection_decision", :map)
    |> expect_optional_type(path, row, "replacement_protection_decision", :map)
    |> validate_optional_protection_decision(
      path,
      row,
      "source_protection_decision",
      protection_decision_validator
    )
    |> validate_optional_protection_decision(
      path,
      row,
      "replacement_protection_decision",
      protection_decision_validator
    )
    |> validate_timeline_identity_collision_fields(
      path,
      row,
      timeline_identity_collision_validator
    )
    |> validate_selected_timeline_integrity_fields(
      path,
      row,
      selected_timeline_integrity_validator
    )
    |> expect_type(path, row, "source_timeline_diff", :map)
    |> validate_timeline_diff_row(
      path <> ".source_timeline_diff",
      Map.get(row, "source_timeline_diff", %{}),
      timeline_diff_row_validator
    )
  end

  defp timeline_capability, do: OrbitalDynamics.Timeline.capabilities()

  defp validate_optional_lifecycle_transition(issues, path, row, field, validator),
    do: validator.(issues, path, row, field)

  defp validate_optional_protection_decision(issues, path, row, field, validator),
    do: validator.(issues, path, row, field)

  defp validate_timeline_identity_collision_fields(issues, path, row, validator),
    do: validator.(issues, path, row)

  defp validate_selected_timeline_integrity_fields(issues, path, row, validator),
    do: validator.(issues, path, row)

  defp validate_timeline_diff_row(issues, path, row, validator),
    do: validator.(issues, path, row)
end
