defmodule OrbitalDynamics.Schema.CandidateRefreshTimelineChangeContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_optional_non_negative_integer: 4,
      expect_optional_type: 5,
      validate_non_negative_integer_count_map: 3
    ]

  def validate_diff(issues, path, summary) do
    issues =
      validate_integer_fields(issues, path, summary, [
        "duplicate_timeline_identity_count",
        "duplicate_source_timeline_identity_count",
        "duplicate_replacement_timeline_identity_count",
        "removed_downlink_count",
        "removed_observation_count",
        "changed_downlink_shortfall_count",
        "changed_contact_feedback_count",
        "changed_observation_count",
        "changed_observation_quality_feedback_count",
        "changed_command_feedback_count",
        "changed_maneuver_feedback_count"
      ])

    validate_count_maps(issues, path, summary, [
      "diff_status_counts",
      "required_operator_action_counts",
      "duplicate_timeline_identity_scope_counts",
      "source_activity_id_counts",
      "replacement_activity_id_counts"
    ])
  end

  def validate_transition_application(issues, path, summary) do
    issues =
      validate_integer_fields(issues, path, summary, [
        "application_count",
        "selected_activity_count",
        "selected_timeline_integrity_review_count",
        "selected_timeline_integrity_issue_count",
        "review_required_count",
        "preserved_source_count",
        "recorded_replacement_count",
        "withheld_review_count",
        "duplicate_timeline_identity_count",
        "duplicate_source_timeline_identity_count",
        "duplicate_replacement_timeline_identity_count"
      ])

    validate_count_maps(issues, path, summary, [
      "selected_activity_id_counts",
      "review_activity_id_counts",
      "selected_timeline_integrity_issue_type_counts",
      "application_status_counts",
      "transition_decision_counts",
      "required_operator_action_counts",
      "duplicate_timeline_identity_scope_counts"
    ])
  end

  defp validate_integer_fields(issues, path, summary, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      expect_optional_non_negative_integer(acc, path, summary, field)
    end)
  end

  defp validate_count_maps(issues, path, summary, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      acc
      |> expect_optional_type(path, summary, field, :map)
      |> validate_non_negative_integer_count_map(
        path <> ".#{field}",
        Map.get(summary, field)
      )
    end)
  end
end
