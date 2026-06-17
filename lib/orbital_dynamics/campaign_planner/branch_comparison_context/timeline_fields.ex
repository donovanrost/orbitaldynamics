defmodule OrbitalDynamics.CampaignPlanner.BranchComparisonContext.TimelineFields do
  @moduledoc false

  import OrbitalDynamics.CampaignPlanner.BranchComparisonContext.FieldValues

  def fields(events) do
    %{
      "branch_timeline_integrity_activity_ids" =>
        timeline_integrity_unique_values(events, "activity_id"),
      "branch_timeline_integrity_timeline_ids" =>
        timeline_integrity_unique_values(events, "timeline_id"),
      "branch_missing_dependency_activity_ids" =>
        timeline_integrity_unique_values(events, "missing_dependency_activity_ids"),
      "branch_missing_dependency_timeline_ids" =>
        timeline_integrity_unique_values(events, "missing_dependency_timeline_ids"),
      "branch_dependency_cycle_activity_ids" =>
        timeline_integrity_unique_values(events, "dependency_cycle_activity_ids"),
      "branch_dependency_cycle_timeline_ids" =>
        timeline_integrity_unique_values(events, "dependency_cycle_timeline_ids"),
      "branch_dependency_order_violation_activity_ids" =>
        timeline_integrity_unique_values(events, "dependency_order_violation_activity_ids"),
      "branch_dependency_order_violation_timeline_ids" =>
        timeline_integrity_unique_values(events, "dependency_order_violation_timeline_ids"),
      "branch_exclusivity_violation_activity_ids" =>
        timeline_integrity_unique_values(events, "exclusivity_violation_activity_ids"),
      "branch_exclusivity_violation_timeline_ids" =>
        timeline_integrity_unique_values(events, "exclusivity_violation_timeline_ids"),
      "branch_exclusivity_violation_groups" =>
        timeline_integrity_unique_values(events, "exclusivity_violation_group"),
      "branch_timeline_dependency_impact_activity_ids" =>
        timeline_dependency_impact_unique_values(events, "activity_id"),
      "branch_timeline_dependency_impact_timeline_ids" =>
        timeline_dependency_impact_unique_values(events, "timeline_id"),
      "branch_timeline_dependency_impact_scopes" =>
        timeline_dependency_impact_unique_values(events, "dependency_impact_scope"),
      "branch_impacted_dependency_activity_ids" =>
        timeline_dependency_impact_unique_values(events, "impacted_dependency_activity_ids"),
      "branch_impacted_dependency_timeline_ids" =>
        timeline_dependency_impact_unique_values(events, "impacted_dependency_timeline_ids"),
      "branch_impacted_exclusive_with_activity_ids" =>
        timeline_dependency_impact_unique_values(events, "impacted_exclusive_with_activity_ids"),
      "branch_impacted_exclusive_with_timeline_ids" =>
        timeline_dependency_impact_unique_values(events, "impacted_exclusive_with_timeline_ids"),
      "branch_timeline_publication_ids" =>
        timeline_publication_unique_values(events, "publication_id"),
      "branch_timeline_publication_statuses" =>
        timeline_publication_unique_values(events, "publication_status"),
      "branch_timeline_publication_source_artifact_ids" =>
        timeline_publication_unique_values(events, "source_artifact_id"),
      "branch_timeline_publication_source_artifact_types" =>
        timeline_publication_unique_values(events, "source_artifact_type"),
      "branch_timeline_publication_downstream_invalidation_statuses" =>
        timeline_publication_unique_values(events, "downstream_invalidation_status"),
      "branch_timeline_publication_invalidated_downstream_product_ids" =>
        timeline_publication_unique_values(events, "invalidated_downstream_product_ids"),
      "branch_timeline_publication_downstream_invalidation_reasons" =>
        timeline_publication_unique_values(events, "downstream_invalidation_reasons"),
      "branch_timeline_publication_dependency_impact_statuses" =>
        timeline_publication_unique_values(events, "dependency_impact_status"),
      "branch_timeline_publication_impacted_source_activity_ids" =>
        timeline_publication_unique_values(events, "impacted_source_activity_ids"),
      "branch_timeline_publication_impacted_source_timeline_ids" =>
        timeline_publication_unique_values(events, "impacted_source_timeline_ids"),
      "branch_timeline_publication_dependent_activity_ids" =>
        timeline_publication_unique_values(events, "dependent_activity_ids"),
      "branch_timeline_publication_dependent_timeline_ids" =>
        timeline_publication_unique_values(events, "dependent_timeline_ids"),
      "branch_timeline_publication_changed_fields" =>
        timeline_publication_unique_values(events, "changed_fields"),
      "branch_timeline_publication_changed_timeline_ids" =>
        timeline_publication_unique_values(events, "changed_timeline_ids"),
      "branch_timeline_publication_review_timeline_ids" =>
        timeline_publication_unique_values(events, "review_timeline_ids"),
      "branch_timeline_lifecycle_state_statuses" =>
        timeline_lifecycle_state_unique_values(events, "timeline_lifecycle_state_status"),
      "branch_timeline_lifecycle_state_review_timeline_ids" =>
        timeline_lifecycle_state_unique_values(events, "review_timeline_ids"),
      "branch_timeline_lifecycle_state_review_activity_ids" =>
        timeline_lifecycle_state_unique_values(events, "review_activity_ids"),
      "branch_timeline_lifecycle_state_invalid_activity_input_ids" =>
        timeline_lifecycle_state_unique_values(events, "invalid_activity_input_ids"),
      "branch_timeline_lifecycle_state_required_operator_actions" =>
        timeline_lifecycle_state_required_operator_actions(events),
      "branch_timeline_lifecycle_state_import_actions" =>
        timeline_lifecycle_state_import_actions(events),
      "branch_timeline_activity_lifecycle_state_activity_ids" =>
        timeline_activity_lifecycle_state_unique_values(events, "activity_id"),
      "branch_timeline_activity_lifecycle_state_timeline_ids" =>
        timeline_activity_lifecycle_state_unique_values(events, "timeline_id"),
      "branch_timeline_activity_lifecycle_state_transition_decisions" =>
        timeline_activity_lifecycle_state_unique_values(events, "transition_decision"),
      "branch_timeline_activity_lifecycle_state_required_operator_actions" =>
        timeline_activity_lifecycle_state_unique_values(events, [
          "required_operator_action",
          "required_operator_actions"
        ]),
      "branch_timeline_activity_lifecycle_state_import_actions" =>
        timeline_activity_lifecycle_state_unique_values(events, "import_action"),
      "branch_timeline_activity_lifecycle_state_invalid_activity_input_reasons" =>
        timeline_activity_lifecycle_state_unique_values(events, "invalid_activity_input_reasons"),
      "branch_timeline_activity_precondition_activity_ids" =>
        timeline_activity_precondition_unique_values(events, "activity_id"),
      "branch_timeline_activity_precondition_timeline_ids" =>
        timeline_activity_precondition_unique_values(events, "timeline_id"),
      "branch_timeline_activity_precondition_statuses" =>
        timeline_activity_precondition_unique_values(events, "precondition_status"),
      "branch_timeline_activity_precondition_blocked_types" =>
        timeline_activity_precondition_unique_values(events, "blocked_precondition_types"),
      "branch_timeline_activity_precondition_review_types" =>
        timeline_activity_precondition_unique_values(events, "review_precondition_types"),
      "branch_timeline_activity_precondition_dependency_activity_ids" =>
        timeline_activity_precondition_unique_values(events, "dependency_activity_ids"),
      "branch_timeline_activity_precondition_dependency_timeline_ids" =>
        timeline_activity_precondition_unique_values(events, "dependency_timeline_ids"),
      "branch_timeline_activity_precondition_exclusive_with_activity_ids" =>
        timeline_activity_precondition_unique_values(events, "exclusive_with_activity_ids"),
      "branch_timeline_activity_precondition_exclusive_with_timeline_ids" =>
        timeline_activity_precondition_unique_values(events, "exclusive_with_timeline_ids"),
      "branch_timeline_activity_precondition_duplicate_dependency_activity_ids" =>
        timeline_activity_precondition_unique_values(events, "duplicate_dependency_activity_ids"),
      "branch_timeline_activity_precondition_duplicate_dependency_timeline_ids" =>
        timeline_activity_precondition_unique_values(events, "duplicate_dependency_timeline_ids"),
      "branch_timeline_activity_precondition_duplicate_exclusivity_activity_ids" =>
        timeline_activity_precondition_unique_values(
          events,
          "duplicate_exclusivity_activity_ids"
        ),
      "branch_timeline_activity_precondition_duplicate_exclusivity_timeline_ids" =>
        timeline_activity_precondition_unique_values(
          events,
          "duplicate_exclusivity_timeline_ids"
        ),
      "branch_timeline_activity_precondition_invalid_activity_input_reasons" =>
        timeline_activity_precondition_unique_values(events, "invalid_activity_input_reason"),
      "branch_timeline_preservation_activity_ids" =>
        timeline_preservation_unique_values(events, "activity_id"),
      "branch_timeline_preservation_timeline_ids" =>
        timeline_preservation_unique_values(events, "timeline_id"),
      "branch_timeline_preservation_statuses" =>
        timeline_preservation_unique_values(events, "timeline_preservation_status"),
      "branch_timeline_preservation_protection_decisions" =>
        timeline_preservation_unique_values(events, "protection_decision"),
      "branch_timeline_preservation_protection_categories" =>
        timeline_preservation_unique_values(events, "protection_category"),
      "branch_timeline_preservation_protection_reasons" =>
        timeline_preservation_unique_values(events, "protection_reason"),
      "branch_timeline_preservation_preserve_activity_ids" =>
        timeline_preservation_unique_values(events, "preserve_activity_ids"),
      "branch_timeline_preservation_preserve_timeline_ids" =>
        timeline_preservation_unique_values(events, "preserve_timeline_ids"),
      "branch_timeline_preservation_review_change_activity_ids" =>
        timeline_preservation_unique_values(events, "review_change_activity_ids"),
      "branch_timeline_preservation_review_change_timeline_ids" =>
        timeline_preservation_unique_values(events, "review_change_timeline_ids"),
      "branch_timeline_preservation_invalid_activity_input_reasons" =>
        timeline_preservation_unique_values(events, "invalid_activity_input_reason")
    }
  end

  defp timeline_integrity_unique_values(events, fields) do
    events
    |> Enum.filter(&(&1["type"] == "timeline_integrity_feedback"))
    |> branch_event_unique_values(fields)
  end

  defp timeline_dependency_impact_unique_values(events, fields) do
    events
    |> Enum.filter(&(&1["type"] == "timeline_dependency_impact_pressure"))
    |> branch_event_unique_values(fields)
  end

  defp timeline_publication_unique_values(events, fields) do
    events
    |> Enum.filter(&(&1["type"] == "timeline_publication_pressure"))
    |> branch_event_unique_values(fields)
  end

  defp timeline_lifecycle_state_unique_values(events, fields) do
    events
    |> Enum.filter(&(&1["type"] == "timeline_lifecycle_state_pressure"))
    |> branch_event_unique_values(fields)
  end

  defp timeline_lifecycle_state_required_operator_actions(events) do
    events
    |> Enum.filter(&(&1["type"] == "timeline_lifecycle_state_pressure"))
    |> Enum.flat_map(fn event ->
      event
      |> Map.get("required_operator_action_counts", %{})
      |> case do
        %{} = counts -> Map.keys(counts)
        _counts -> []
      end
    end)
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, "", "none"]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp timeline_lifecycle_state_import_actions(events) do
    events
    |> Enum.filter(&(&1["type"] == "timeline_lifecycle_state_pressure"))
    |> Enum.flat_map(fn event ->
      event
      |> Map.get("import_action_counts", %{})
      |> case do
        %{} = counts -> Map.keys(counts)
        _counts -> []
      end
    end)
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp timeline_activity_lifecycle_state_unique_values(events, fields) do
    events
    |> Enum.filter(&(&1["type"] == "timeline_activity_lifecycle_state_pressure"))
    |> branch_event_unique_values(fields)
  end

  defp timeline_activity_precondition_unique_values(events, fields) do
    events
    |> Enum.filter(&(&1["type"] == "timeline_activity_precondition_pressure"))
    |> branch_event_unique_values(fields)
  end

  defp timeline_preservation_unique_values(events, fields) do
    events
    |> Enum.filter(&(&1["type"] == "timeline_preservation_pressure"))
    |> branch_event_unique_values(fields)
  end
end
