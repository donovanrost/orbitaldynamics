defmodule OrbitalDynamics.Schema.TimelineDiffRowContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    ActivityContextContracts,
    LifecycleTransitionContracts,
    ProtectionDecisionContracts,
    TimelineIdentityCollisionContracts,
    TimelineIdentityContracts
  }

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_number: 4,
      expect_one_of: 5,
      expect_optional_number: 4,
      expect_optional_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  def validate(issues, path, row) do
    issues
    |> require_fields(path, row, [
      "id",
      "rank",
      "timeline_id",
      "diff_status",
      "changed_fields",
      "requires_operator_review",
      "required_operator_action",
      "reason"
    ])
    |> validate_stable_ids(path, row, [
      "id",
      "timeline_id",
      "source_activity_id",
      "replacement_activity_id",
      "scenario_id",
      "source_spacecraft_id",
      "replacement_spacecraft_id",
      "source_ground_station_id",
      "replacement_ground_station_id",
      "source_target_id",
      "replacement_target_id",
      "source_source_window_id",
      "replacement_source_window_id"
    ])
    |> expect_type(path, row, "diff_status", :binary)
    |> expect_one_of(
      path,
      row,
      "diff_status",
      timeline_capability().timeline_diff_statuses
    )
    |> expect_optional_one_of(
      path,
      row,
      "transition_decision",
      timeline_capability().transition_decisions
    )
    |> expect_optional_type(path, row, "transition_decision_reason", :binary)
    |> expect_number(path, row, "rank")
    |> expect_type(path, row, "changed_fields", :list)
    |> expect_type(path, row, "requires_operator_review", :boolean)
    |> expect_type(path, row, "required_operator_action", :binary)
    |> expect_one_of(
      path,
      row,
      "required_operator_action",
      timeline_capability().timeline_diff_required_operator_actions
    )
    |> expect_optional_type(path, row, "operator_action_reason", :binary)
    |> expect_type(path, row, "reason", :binary)
    |> expect_optional_number(path, row, "source_starts_at_s")
    |> expect_optional_number(path, row, "source_ends_at_s")
    |> expect_optional_number(path, row, "replacement_starts_at_s")
    |> expect_optional_number(path, row, "replacement_ends_at_s")
    |> expect_optional_number(path, row, "start_delta_s")
    |> expect_optional_number(path, row, "end_delta_s")
    |> expect_optional_type(path, row, "source_allow_overlap", :boolean)
    |> expect_optional_type(path, row, "replacement_allow_overlap", :boolean)
    |> expect_optional_type(path, row, "status_transition", :map)
    |> expect_optional_type(path, row, "approval_transition", :map)
    |> LifecycleTransitionContracts.validate_optional(path, row, "status_transition")
    |> LifecycleTransitionContracts.validate_optional(path, row, "approval_transition")
    |> expect_optional_type(path, row, "source_timeline_identity", :map)
    |> expect_optional_type(path, row, "replacement_timeline_identity", :map)
    |> TimelineIdentityContracts.validate_optional_identity(path, row, "source_timeline_identity")
    |> TimelineIdentityContracts.validate_optional_identity(
      path,
      row,
      "replacement_timeline_identity"
    )
    |> expect_optional_type(path, row, "source_activity_context", :map)
    |> expect_optional_type(path, row, "replacement_activity_context", :map)
    |> ActivityContextContracts.validate_optional(path, row, "source_activity_context")
    |> ActivityContextContracts.validate_optional(path, row, "replacement_activity_context")
    |> expect_optional_type(path, row, "source_protection_category", :binary)
    |> expect_optional_type(path, row, "replacement_protection_category", :binary)
    |> expect_optional_type(path, row, "source_protection_decision", :map)
    |> expect_optional_type(path, row, "replacement_protection_decision", :map)
    |> ProtectionDecisionContracts.validate_optional(path, row, "source_protection_decision")
    |> ProtectionDecisionContracts.validate_optional(
      path,
      row,
      "replacement_protection_decision"
    )
    |> expect_optional_type(path, row, "source_protection_reason", :binary)
    |> expect_optional_type(path, row, "replacement_protection_reason", :binary)
    |> TimelineIdentityCollisionContracts.validate_fields(path, row)
  end

  defp timeline_capability, do: OrbitalDynamics.Timeline.capabilities()
end
