defmodule OrbitalDynamics.CampaignPlanner.CandidateSourceTimelineReplayRisk do
  @moduledoc false

  def lifecycle(%{"branch_local_lifecycle_review_pressure" => true} = replay_summary) do
    [
      %{
        "type" => "timeline_lifecycle_state_review",
        "severity" => "high",
        "reason" =>
          "candidate source timeline lifecycle replay reports review, duplicate identity, or invalid activity pressure",
        "source_report_count" => Map.get(replay_summary, "source_report_count"),
        "source_report_row_count" => Map.get(replay_summary, "source_report_row_count"),
        "source_report_paths" => Map.get(replay_summary, "source_report_paths"),
        "review_required_count" => Map.get(replay_summary, "review_required_count"),
        "duplicate_timeline_identity_count" =>
          Map.get(replay_summary, "duplicate_timeline_identity_count"),
        "invalid_activity_input_count" => Map.get(replay_summary, "invalid_activity_input_count"),
        "review_timeline_ids" => Map.get(replay_summary, "review_timeline_ids"),
        "review_activity_ids" => Map.get(replay_summary, "review_activity_ids"),
        "invalid_activity_input_ids" => Map.get(replay_summary, "invalid_activity_input_ids"),
        "required_operator_action_counts" =>
          Map.get(replay_summary, "required_operator_action_counts"),
        "import_action_counts" => Map.get(replay_summary, "import_action_counts"),
        "feedback_source" => "candidate_source.timeline_lifecycle_state_replay_summary",
        "feedback_scope" => "timeline_lifecycle_state",
        "trust_boundaries" => Map.get(replay_summary, "trust_boundaries")
      }
      |> compact_map()
    ]
  end

  def lifecycle(_replay_summary), do: []

  def activity_state(%{} = replay_summary) do
    if activity_state_scoring_pressure?(replay_summary) do
      activity_state_review_risk(replay_summary)
    else
      []
    end
  end

  def activity_state(_replay_summary), do: []

  def dependency_impact(
        %{"branch_local_timeline_dependency_impact_pressure" => true} = replay_summary
      ) do
    required_operator_actions =
      replay_summary
      |> Map.get("required_operator_action_counts", %{})
      |> map_keys()

    impacted_source_activity_ids =
      replay_summary
      |> Map.get("impacted_source_activity_id_counts", %{})
      |> map_keys()

    impacted_source_timeline_ids =
      replay_summary
      |> Map.get("impacted_source_timeline_id_counts", %{})
      |> map_keys()

    dependent_activity_ids =
      replay_summary
      |> Map.get("dependent_activity_id_counts", %{})
      |> map_keys()

    dependent_timeline_ids =
      replay_summary
      |> Map.get("dependent_timeline_id_counts", %{})
      |> map_keys()

    [
      %{
        "type" => "timeline_dependency_impact",
        "severity" => "high",
        "reason" =>
          "candidate source timeline dependency-impact replay reports changed-source, dependency, exclusivity, or operator-review pressure",
        "source_report_row_count" => Map.get(replay_summary, "source_report_row_count"),
        "changed_source_activity_count" =>
          Map.get(replay_summary, "changed_source_activity_count"),
        "changed_source_timeline_count" =>
          Map.get(replay_summary, "changed_source_timeline_count"),
        "dependency_impact_status_counts" =>
          Map.get(replay_summary, "dependency_impact_status_counts"),
        "dependency_impact_scope_counts" =>
          Map.get(replay_summary, "dependency_impact_scope_counts"),
        "required_operator_action_counts" =>
          Map.get(replay_summary, "required_operator_action_counts"),
        "required_operator_actions" => required_operator_actions,
        "impacted_source_activity_ids" => impacted_source_activity_ids,
        "impacted_source_timeline_ids" => impacted_source_timeline_ids,
        "impacted_dependency_activity_ids" =>
          replay_summary
          |> Map.get("impacted_dependency_activity_id_counts", %{})
          |> map_keys(),
        "impacted_dependency_timeline_ids" =>
          replay_summary
          |> Map.get("impacted_dependency_timeline_id_counts", %{})
          |> map_keys(),
        "impacted_exclusive_with_activity_ids" =>
          replay_summary
          |> Map.get("impacted_exclusive_activity_id_counts", %{})
          |> map_keys(),
        "impacted_exclusive_with_timeline_ids" =>
          replay_summary
          |> Map.get("impacted_exclusive_timeline_id_counts", %{})
          |> map_keys(),
        "dependent_activity_ids" => dependent_activity_ids,
        "dependent_timeline_ids" => dependent_timeline_ids,
        "feedback_source" => "candidate_source.timeline_dependency_impact_replay_summary",
        "feedback_scope" => "timeline_dependency_impact",
        "trust_boundaries" => Map.get(replay_summary, "trust_boundaries")
      }
      |> compact_map()
    ]
  end

  def dependency_impact(_replay_summary), do: []

  def integrity(%{"branch_local_timeline_integrity_pressure" => true} = replay_summary) do
    timeline_integrity_issue_types =
      replay_summary
      |> Map.get("timeline_integrity_issue_type_counts", %{})
      |> map_keys()

    required_operator_actions =
      replay_summary
      |> Map.get("required_operator_action_counts", %{})
      |> map_keys()

    [
      %{
        "type" => "timeline_integrity_issue",
        "severity" => "high",
        "reason" =>
          "candidate source timeline-integrity replay reports dependency, exclusivity, or operator-review pressure",
        "source_report_count" => Map.get(replay_summary, "source_report_count"),
        "source_report_row_count" => Map.get(replay_summary, "source_report_row_count"),
        "source_report_paths" => Map.get(replay_summary, "source_report_paths"),
        "timeline_integrity_issue_count" =>
          Map.get(replay_summary, "timeline_integrity_issue_count"),
        "timeline_integrity_review_count" =>
          Map.get(replay_summary, "timeline_integrity_review_count"),
        "dependency_issue_count" => Map.get(replay_summary, "dependency_issue_count"),
        "exclusivity_issue_count" => Map.get(replay_summary, "exclusivity_issue_count"),
        "timeline_integrity_status_counts" =>
          Map.get(replay_summary, "timeline_integrity_status_counts"),
        "timeline_integrity_issue_type_counts" =>
          Map.get(replay_summary, "timeline_integrity_issue_type_counts"),
        "timeline_integrity_issue_types" => timeline_integrity_issue_types,
        "required_operator_action_counts" =>
          Map.get(replay_summary, "required_operator_action_counts"),
        "required_operator_actions" => required_operator_actions,
        "operator_action_reason_counts" =>
          Map.get(replay_summary, "operator_action_reason_counts"),
        "review_activity_ids" =>
          replay_summary
          |> Map.get("review_activity_id_counts", %{})
          |> map_keys(),
        "review_timeline_ids" =>
          replay_summary
          |> Map.get("review_timeline_id_counts", %{})
          |> map_keys(),
        "missing_dependency_activity_ids" =>
          replay_summary
          |> Map.get("missing_dependency_activity_id_counts", %{})
          |> map_keys(),
        "missing_dependency_timeline_ids" =>
          replay_summary
          |> Map.get("missing_dependency_timeline_id_counts", %{})
          |> map_keys(),
        "self_dependency_activity_ids" =>
          replay_summary
          |> Map.get("self_dependency_activity_id_counts", %{})
          |> map_keys(),
        "self_dependency_timeline_ids" =>
          replay_summary
          |> Map.get("self_dependency_timeline_id_counts", %{})
          |> map_keys(),
        "dependency_cycle_activity_ids" =>
          replay_summary
          |> Map.get("dependency_cycle_activity_id_counts", %{})
          |> map_keys(),
        "dependency_cycle_timeline_ids" =>
          replay_summary
          |> Map.get("dependency_cycle_timeline_id_counts", %{})
          |> map_keys(),
        "dependency_order_violation_activity_ids" =>
          replay_summary
          |> Map.get("dependency_order_violation_activity_id_counts", %{})
          |> map_keys(),
        "dependency_order_violation_timeline_ids" =>
          replay_summary
          |> Map.get("dependency_order_violation_timeline_id_counts", %{})
          |> map_keys(),
        "exclusivity_violation_activity_ids" =>
          replay_summary
          |> Map.get("exclusivity_violation_activity_id_counts", %{})
          |> map_keys(),
        "exclusivity_violation_timeline_ids" =>
          replay_summary
          |> Map.get("exclusivity_violation_timeline_id_counts", %{})
          |> map_keys(),
        "exclusivity_violation_groups" =>
          replay_summary
          |> Map.get("exclusivity_violation_group_counts", %{})
          |> map_keys(),
        "branch_local_timeline_integrity_review_pressure" =>
          Map.get(replay_summary, "branch_local_timeline_integrity_review_pressure"),
        "branch_local_dependency_integrity_pressure" =>
          Map.get(replay_summary, "branch_local_dependency_integrity_pressure"),
        "branch_local_exclusivity_integrity_pressure" =>
          Map.get(replay_summary, "branch_local_exclusivity_integrity_pressure"),
        "feedback_source" => "candidate_source.timeline_integrity_replay_summary",
        "feedback_scope" => "timeline_integrity",
        "trust_boundaries" => Map.get(replay_summary, "trust_boundaries")
      }
      |> compact_map()
    ]
  end

  def integrity(_replay_summary), do: []

  def precondition(
        %{"branch_local_timeline_activity_precondition_pressure" => true} = replay_summary
      ) do
    blocked_precondition_types =
      replay_summary
      |> Map.get("blocked_precondition_type_counts", %{})
      |> map_keys()

    review_precondition_types =
      replay_summary
      |> Map.get("review_precondition_type_counts", %{})
      |> map_keys()

    invalid_activity_input_reasons =
      replay_summary
      |> Map.get("invalid_activity_input_reason_counts", %{})
      |> map_keys()

    [
      %{
        "type" => "timeline_activity_precondition_review",
        "severity" => "high",
        "reason" =>
          "candidate source timeline activity-precondition replay reports blocked, review, dependency, exclusivity, or invalid-input pressure",
        "source_report_count" => Map.get(replay_summary, "source_report_count"),
        "source_report_row_count" => Map.get(replay_summary, "source_report_row_count"),
        "source_report_paths" => Map.get(replay_summary, "source_report_paths"),
        "precondition_status_counts" => Map.get(replay_summary, "precondition_status_counts"),
        "blocked_precondition_count" => Map.get(replay_summary, "blocked_precondition_count"),
        "review_precondition_count" => Map.get(replay_summary, "review_precondition_count"),
        "blocked_precondition_type_counts" =>
          Map.get(replay_summary, "blocked_precondition_type_counts"),
        "blocked_precondition_types" => blocked_precondition_types,
        "review_precondition_type_counts" =>
          Map.get(replay_summary, "review_precondition_type_counts"),
        "review_precondition_types" => review_precondition_types,
        "invalid_activity_input_count" => Map.get(replay_summary, "invalid_activity_input_count"),
        "invalid_activity_input_reason_counts" =>
          Map.get(replay_summary, "invalid_activity_input_reason_counts"),
        "invalid_activity_input_reasons" => invalid_activity_input_reasons,
        "activity_ids" =>
          replay_summary
          |> Map.get("activity_id_counts", %{})
          |> map_keys(),
        "timeline_ids" =>
          replay_summary
          |> Map.get("timeline_id_counts", %{})
          |> map_keys(),
        "dependency_activity_ids" =>
          replay_summary
          |> Map.get("dependency_activity_id_counts", %{})
          |> map_keys(),
        "dependency_timeline_ids" =>
          replay_summary
          |> Map.get("dependency_timeline_id_counts", %{})
          |> map_keys(),
        "exclusive_with_activity_ids" =>
          replay_summary
          |> Map.get("exclusive_with_activity_id_counts", %{})
          |> map_keys(),
        "exclusive_with_timeline_ids" =>
          replay_summary
          |> Map.get("exclusive_with_timeline_id_counts", %{})
          |> map_keys(),
        "duplicate_dependency_activity_ids" =>
          replay_summary
          |> Map.get("duplicate_dependency_activity_id_counts", %{})
          |> map_keys(),
        "duplicate_dependency_timeline_ids" =>
          replay_summary
          |> Map.get("duplicate_dependency_timeline_id_counts", %{})
          |> map_keys(),
        "duplicate_exclusivity_activity_ids" =>
          replay_summary
          |> Map.get("duplicate_exclusivity_activity_id_counts", %{})
          |> map_keys(),
        "duplicate_exclusivity_timeline_ids" =>
          replay_summary
          |> Map.get("duplicate_exclusivity_timeline_id_counts", %{})
          |> map_keys(),
        "allow_overlap_values" =>
          replay_summary
          |> Map.get("allow_overlap_counts", %{})
          |> map_keys(),
        "branch_local_activity_precondition_review_pressure" =>
          Map.get(replay_summary, "branch_local_activity_precondition_review_pressure"),
        "branch_local_activity_precondition_dependency_pressure" =>
          Map.get(replay_summary, "branch_local_activity_precondition_dependency_pressure"),
        "branch_local_activity_precondition_exclusivity_pressure" =>
          Map.get(replay_summary, "branch_local_activity_precondition_exclusivity_pressure"),
        "branch_local_activity_precondition_invalid_input_pressure" =>
          Map.get(replay_summary, "branch_local_activity_precondition_invalid_input_pressure"),
        "branch_local_activity_precondition_routing_pressure" =>
          Map.get(replay_summary, "branch_local_activity_precondition_routing_pressure"),
        "feedback_source" => "candidate_source.timeline_activity_precondition_replay_summary",
        "feedback_scope" => "timeline_activity_precondition",
        "trust_boundaries" => Map.get(replay_summary, "trust_boundaries")
      }
      |> compact_map()
    ]
  end

  def precondition(_replay_summary), do: []

  def publication(%{"branch_local_timeline_publication_pressure" => true} = replay_summary) do
    [
      %{
        "type" => "timeline_publication_pressure",
        "severity" => "high",
        "reason" =>
          "candidate source timeline publication replay reports downstream invalidation, dependency, changed-field, or review pressure",
        "publication_status_counts" => Map.get(replay_summary, "publication_status_counts"),
        "downstream_invalidation_status_counts" =>
          Map.get(replay_summary, "downstream_invalidation_status_counts"),
        "dependency_impact_status_counts" =>
          Map.get(replay_summary, "dependency_impact_status_counts"),
        "publication_ids" => Map.get(replay_summary, "publication_ids"),
        "source_artifact_ids" => Map.get(replay_summary, "source_artifact_ids"),
        "supersedes_artifact_ids" => Map.get(replay_summary, "supersedes_artifact_ids"),
        "downstream_product_ids" => Map.get(replay_summary, "downstream_product_ids"),
        "invalidated_downstream_product_ids" =>
          Map.get(replay_summary, "invalidated_downstream_product_ids"),
        "downstream_invalidation_reason_counts" =>
          Map.get(replay_summary, "downstream_invalidation_reason_counts"),
        "downstream_invalidation_reasons" =>
          replay_summary
          |> Map.get("downstream_invalidation_reason_counts")
          |> Kernel.||(%{})
          |> Map.keys(),
        "dependency_impact_row_count" => Map.get(replay_summary, "dependency_impact_row_count"),
        "impacted_source_activity_ids" => Map.get(replay_summary, "impacted_source_activity_ids"),
        "impacted_source_timeline_ids" => Map.get(replay_summary, "impacted_source_timeline_ids"),
        "dependent_activity_ids" => Map.get(replay_summary, "dependent_activity_ids"),
        "dependent_timeline_ids" => Map.get(replay_summary, "dependent_timeline_ids"),
        "changed_field_counts" => Map.get(replay_summary, "changed_field_counts"),
        "changed_fields" =>
          replay_summary
          |> Map.get("changed_field_counts")
          |> Kernel.||(%{})
          |> Map.keys(),
        "changed_timeline_ids" => publication_changed_timeline_ids(replay_summary),
        "review_timeline_ids" => Map.get(replay_summary, "review_timeline_ids"),
        "feedback_source" => "candidate_source.timeline_publication_replay_summary",
        "feedback_scope" => "timeline_publication",
        "trust_boundaries" => Map.get(replay_summary, "trust_boundaries")
      }
      |> compact_map()
    ]
  end

  def publication(_replay_summary), do: []

  def transition_application(
        %{"branch_local_timeline_transition_application_pressure" => true} = replay_summary
      ) do
    selected_activity_ids =
      replay_summary
      |> Map.get("selected_activity_id_counts", %{})
      |> map_keys()

    review_activity_ids =
      replay_summary
      |> Map.get("review_activity_id_counts", %{})
      |> map_keys()

    required_operator_actions =
      replay_summary
      |> Map.get("required_operator_action_counts", %{})
      |> Map.delete("none")
      |> map_keys()

    [
      %{
        "type" => "timeline_transition_application_pressure",
        "severity" => "high",
        "reason" =>
          "candidate source timeline transition-application replay reports selected, review, withhold, preserved, or duplicate-identity pressure",
        "source_report_count" => Map.get(replay_summary, "source_report_count"),
        "source_application_count" => Map.get(replay_summary, "source_application_count"),
        "selected_activity_count" => Map.get(replay_summary, "selected_activity_count"),
        "selected_activity_ids" => selected_activity_ids,
        "review_activity_ids" => review_activity_ids,
        "review_required_count" => Map.get(replay_summary, "review_required_count"),
        "preserved_source_count" => Map.get(replay_summary, "preserved_source_count"),
        "recorded_replacement_count" => Map.get(replay_summary, "recorded_replacement_count"),
        "withheld_review_count" => Map.get(replay_summary, "withheld_review_count"),
        "duplicate_timeline_identity_count" =>
          Map.get(replay_summary, "duplicate_timeline_identity_count"),
        "duplicate_source_timeline_identity_count" =>
          Map.get(replay_summary, "duplicate_source_timeline_identity_count"),
        "duplicate_replacement_timeline_identity_count" =>
          Map.get(replay_summary, "duplicate_replacement_timeline_identity_count"),
        "application_status_counts" => Map.get(replay_summary, "application_status_counts"),
        "transition_decision_counts" => Map.get(replay_summary, "transition_decision_counts"),
        "required_operator_action_counts" =>
          Map.get(replay_summary, "required_operator_action_counts"),
        "required_operator_actions" => required_operator_actions,
        "duplicate_timeline_identity_scope_counts" =>
          Map.get(replay_summary, "duplicate_timeline_identity_scope_counts"),
        "feedback_source" => "candidate_source.timeline_transition_application_replay_summary",
        "feedback_scope" => "timeline_transition_application",
        "trust_boundaries" => Map.get(replay_summary, "trust_boundaries")
      }
      |> compact_map()
    ]
  end

  def transition_application(_replay_summary), do: []

  defp activity_state_scoring_pressure?(replay_summary) do
    Map.get(replay_summary, "branch_local_activity_state_review_pressure") == true or
      Map.get(replay_summary, "branch_local_activity_state_action_pressure") == true or
      map_size(Map.get(replay_summary, "transition_decision_counts", %{})) > 0 or
      map_size(Map.get(replay_summary, "required_operator_action_counts", %{})) > 0 or
      map_size(Map.get(replay_summary, "import_action_counts", %{})) > 0
  end

  defp activity_state_review_risk(replay_summary) do
    activity_ids =
      replay_summary
      |> Map.get("activity_id_counts", %{})
      |> map_keys()

    timeline_ids =
      replay_summary
      |> Map.get("timeline_id_counts", %{})
      |> map_keys()

    required_operator_actions =
      replay_summary
      |> Map.get("required_operator_action_counts", %{})
      |> map_keys()

    import_actions =
      replay_summary
      |> Map.get("import_action_counts", %{})
      |> map_keys()

    transition_decisions =
      replay_summary
      |> Map.get("transition_decision_counts", %{})
      |> map_keys()

    [
      %{
        "type" => "timeline_activity_lifecycle_state_review",
        "severity" => "high",
        "reason" =>
          "candidate source timeline activity-state replay reports review, action, routing, or state-transition pressure",
        "source_report_row_count" => Map.get(replay_summary, "source_report_row_count"),
        "review_required_count" => Map.get(replay_summary, "review_required_count"),
        "state_status_counts" => Map.get(replay_summary, "state_status_counts"),
        "transition_decision_counts" => Map.get(replay_summary, "transition_decision_counts"),
        "transition_decisions" => transition_decisions,
        "required_operator_action_counts" =>
          Map.get(replay_summary, "required_operator_action_counts"),
        "required_operator_actions" => required_operator_actions,
        "import_action_counts" => Map.get(replay_summary, "import_action_counts"),
        "import_actions" => import_actions,
        "activity_ids" => activity_ids,
        "timeline_ids" => timeline_ids,
        "review_activity_ids" =>
          replay_summary
          |> Map.get("review_activity_id_counts", %{})
          |> map_keys(),
        "action_routing_activity_ids" =>
          activity_state_action_routing_values(replay_summary, "activity_ids"),
        "action_routing_timeline_ids" =>
          activity_state_action_routing_values(replay_summary, "timeline_ids"),
        "status_transition_categories" =>
          activity_state_action_routing_values(replay_summary, "status_transition_categories"),
        "approval_transition_categories" =>
          activity_state_action_routing_values(replay_summary, "approval_transition_categories"),
        "feedback_source" => "candidate_source.timeline_activity_state_replay_summary",
        "feedback_scope" => "timeline_activity_state",
        "trust_boundaries" => Map.get(replay_summary, "trust_boundaries")
      }
      |> compact_map()
    ]
  end

  defp activity_state_action_routing_values(replay_summary, field) do
    replay_summary
    |> Map.get("action_routing", %{})
    |> Map.values()
    |> Enum.flat_map(fn
      %{} = route -> List.wrap(Map.get(route, field))
      _route -> []
    end)
    |> sorted_encoded_values()
  end

  defp publication_changed_timeline_ids(replay_summary) do
    case Map.get(replay_summary, "changed_timeline_ids") do
      values when is_list(values) and values != [] ->
        values

      _values ->
        replay_summary
        |> Map.get("timeline_ids_by_changed_field", %{})
        |> Map.values()
        |> List.flatten()
        |> Enum.uniq()
        |> Enum.sort()
    end
  end

  defp map_keys(%{} = map), do: map |> Map.keys() |> sorted_encoded_values()
  defp map_keys(_map), do: []

  defp sorted_encoded_values(values) do
    values
    |> List.wrap()
    |> List.flatten()
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
