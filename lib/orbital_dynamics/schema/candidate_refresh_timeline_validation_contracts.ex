defmodule OrbitalDynamics.Schema.CandidateRefreshTimelineValidationContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_optional_non_negative_integer: 4,
      expect_optional_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_string_list_items: 4
    ]

  def validate_activity_precondition(issues, path, summary) do
    issues =
      validate_integer_fields(issues, path, summary, [
        "blocked_precondition_count",
        "review_precondition_count",
        "invalid_activity_input_count"
      ])

    issues =
      validate_count_maps(issues, path, summary, [
        "source_summary_model_counts",
        "source_summary_schema_contract_counts",
        "precondition_status_counts",
        "blocked_precondition_type_counts",
        "review_precondition_type_counts",
        "invalid_activity_input_reason_counts",
        "activity_id_counts",
        "timeline_id_counts",
        "dependency_activity_id_counts",
        "dependency_timeline_id_counts",
        "exclusive_with_activity_id_counts",
        "exclusive_with_timeline_id_counts",
        "duplicate_dependency_activity_id_counts",
        "duplicate_dependency_timeline_id_counts",
        "duplicate_exclusivity_activity_id_counts",
        "duplicate_exclusivity_timeline_id_counts",
        "allow_overlap_counts"
      ])

    validate_string_list_items(issues, path, summary, "invalid_activity_input_reasons")
  end

  def validate_integrity(issues, path, summary) do
    issues =
      validate_integer_fields(issues, path, summary, [
        "timeline_integrity_issue_count",
        "timeline_integrity_review_count",
        "dependency_issue_count",
        "exclusivity_issue_count"
      ])

    validate_count_maps(issues, path, summary, [
      "timeline_integrity_status_counts",
      "timeline_integrity_issue_type_counts",
      "required_operator_action_counts",
      "operator_action_reason_counts",
      "review_activity_id_counts",
      "review_timeline_id_counts",
      "missing_dependency_activity_id_counts",
      "missing_dependency_timeline_id_counts",
      "self_dependency_activity_id_counts",
      "self_dependency_timeline_id_counts",
      "dependency_cycle_activity_id_counts",
      "dependency_cycle_timeline_id_counts",
      "dependency_order_violation_activity_id_counts",
      "dependency_order_violation_timeline_id_counts",
      "exclusivity_violation_activity_id_counts",
      "exclusivity_violation_timeline_id_counts",
      "exclusivity_violation_group_counts"
    ])
  end

  def validate_dependency_impact(issues, path, summary) do
    issues =
      validate_integer_fields(issues, path, summary, [
        "source_activity_count",
        "replacement_activity_count",
        "changed_source_activity_count",
        "changed_source_timeline_count",
        "dependent_activity_count",
        "source_dependent_activity_count",
        "replacement_dependent_activity_count"
      ])

    validate_count_maps(issues, path, summary, [
      "dependency_impact_status_counts",
      "dependency_impact_scope_counts",
      "required_operator_action_counts",
      "impacted_source_activity_id_counts",
      "impacted_source_timeline_id_counts",
      "impacted_dependency_activity_id_counts",
      "impacted_dependency_timeline_id_counts",
      "impacted_exclusive_activity_id_counts",
      "impacted_exclusive_timeline_id_counts",
      "dependent_activity_id_counts",
      "dependent_timeline_id_counts"
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
      |> validate_non_negative_integer_count_map(path <> ".#{field}", Map.get(summary, field))
    end)
  end
end
