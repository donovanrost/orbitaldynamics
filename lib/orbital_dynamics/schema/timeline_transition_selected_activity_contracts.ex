defmodule OrbitalDynamics.Schema.TimelineTransitionSelectedActivityContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_one_of: 5,
      expect_optional_non_negative_integer: 4,
      expect_optional_number: 4,
      expect_optional_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_interval: 3,
      validate_string_list_allowed: 5
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  def validate(
        issues,
        path,
        activity,
        activity_context_validator,
        timeline_integrity_evidence_validator
      )
      when is_function(activity_context_validator, 4) and
             is_function(timeline_integrity_evidence_validator, 3) do
    issues
    |> require_fields(path, activity, [
      "activity_id",
      "timeline_id",
      "activity_type",
      "status",
      "approval_status",
      "locked",
      "has_source_window",
      "has_cadence_import",
      "timeline_identity"
    ])
    |> validate_stable_ids(path, activity, ["activity_id", "timeline_id"])
    |> validate_stable_ids(path, activity, ["target_id"])
    |> expect_type(path, activity, "activity_type", :binary)
    |> expect_one_of(path, activity, "status", timeline_capability().activity_statuses)
    |> expect_one_of(
      path,
      activity,
      "approval_status",
      timeline_capability().approval_statuses
    )
    |> expect_type(path, activity, "locked", :boolean)
    |> expect_optional_type(path, activity, "allow_overlap", :boolean)
    |> expect_optional_one_of(
      path,
      activity,
      "operational_kind",
      timeline_capability().operational_kinds
    )
    |> expect_optional_one_of(
      path,
      activity,
      "required_operator_action",
      timeline_capability().required_operator_actions
    )
    |> expect_optional_type(path, activity, "operator_action_reason", :binary)
    |> expect_optional_one_of(
      path,
      activity,
      "execution_boundary",
      timeline_capability().execution_boundaries
    )
    |> expect_optional_one_of(
      path,
      activity,
      "cadence_import_status",
      timeline_capability().cadence_import_statuses
    )
    |> expect_optional_number(path, activity, "starts_at_s")
    |> expect_optional_number(path, activity, "ends_at_s")
    |> expect_optional_type(path, activity, "target_id", :binary)
    |> expect_optional_type(path, activity, "command_window_id", :binary)
    |> expect_optional_type(path, activity, "command_window_type", :binary)
    |> expect_optional_type(path, activity, "approved", :boolean)
    |> expect_type(path, activity, "has_source_window", :boolean)
    |> expect_type(path, activity, "has_cadence_import", :boolean)
    |> expect_type(path, activity, "timeline_identity", :map)
    |> expect_optional_type(path, activity, "activity_context", :map)
    |> validate_optional_activity_context(
      path,
      activity,
      "activity_context",
      activity_context_validator
    )
    |> expect_optional_type(path, activity, "protection_decision", :binary)
    |> expect_optional_type(path, activity, "protection_category", :binary)
    |> expect_optional_type(path, activity, "protection_reason", :binary)
    |> expect_optional_type(path, activity, "timeline_integrity_status", :binary)
    |> expect_optional_non_negative_integer(
      path,
      activity,
      "timeline_integrity_issue_count"
    )
    |> expect_optional_type(path, activity, "timeline_integrity_issue_types", :list)
    |> validate_string_list_allowed(
      path,
      activity,
      "timeline_integrity_issue_types",
      timeline_capability().timeline_integrity_issue_types
    )
    |> expect_optional_type(path, activity, "timeline_integrity_issues", :list)
    |> validate_timeline_integrity_evidence(
      path,
      activity,
      timeline_integrity_evidence_validator
    )
    |> validate_interval(path, activity)
  end

  defp timeline_capability, do: OrbitalDynamics.Timeline.capabilities()

  defp validate_optional_activity_context(issues, path, activity, field, validator),
    do: validator.(issues, path, activity, field)

  defp validate_timeline_integrity_evidence(issues, path, activity, validator),
    do: validator.(issues, path, activity)
end
