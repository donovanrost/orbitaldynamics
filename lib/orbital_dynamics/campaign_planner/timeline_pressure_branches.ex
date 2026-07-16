defmodule OrbitalDynamics.CampaignPlanner.TimelinePressureBranches do
  @moduledoc false

  alias __MODULE__.ActivityPrecondition
  alias __MODULE__.LifecycleState
  alias __MODULE__.Preservation

  alias OrbitalDynamics.CampaignPlanner.{
    OperationalTimelinePressureEvents,
    RealizedFeedbackContext,
    ScalarValues,
    ValueEncoding
  }

  def timeline_integrity_pressure_branch(row, source_path, index, opts \\ default_callbacks()) do
    callbacks = callbacks!(opts)

    case timeline_integrity_pressure_event(row, source_path, callbacks) do
      nil ->
        []

      event ->
        identity = row["activity_id"] || row["timeline_id"] || event["feedback_key"] || index

        [
          %{
            "id" =>
              "derived_timeline_integrity_pressure_#{callbacks.branch_id_fragment.(identity)}",
            "label" => "Derived timeline integrity pressure #{identity}",
            "events" => [event],
            "metadata" =>
              %{
                "derived_source" => source_path,
                "timeline_id" => row["timeline_id"],
                "timeline_integrity_status" => row["timeline_integrity_status"],
                "timeline_integrity_issue_types" => row["timeline_integrity_issue_types"]
              }
              |> callbacks.compact_map.()
          }
        ]
    end
  end

  def timeline_dependency_impact_pressure_branch(
        row,
        source_path,
        index,
        opts \\ default_callbacks()
      ) do
    callbacks = callbacks!(opts)

    case timeline_dependency_impact_pressure_event(row, source_path, callbacks) do
      nil ->
        []

      event ->
        identity = row["activity_id"] || row["timeline_id"] || event["feedback_key"] || index

        [
          %{
            "id" =>
              "derived_timeline_dependency_impact_pressure_#{callbacks.branch_id_fragment.(identity)}",
            "label" => "Derived timeline dependency impact pressure #{identity}",
            "events" => [event],
            "metadata" =>
              %{
                "derived_source" => source_path,
                "timeline_id" => row["timeline_id"],
                "dependency_impact_scope" => row["scope"] || row["dependency_impact_scope"],
                "dependency_impact_status" => row["dependency_impact_status"]
              }
              |> callbacks.compact_map.()
          }
        ]
    end
  end

  def timeline_publication_pressure_branch(
        summary,
        source_path,
        index,
        opts \\ default_callbacks()
      ) do
    callbacks = callbacks!(opts)

    case timeline_publication_pressure_event(summary, source_path, callbacks) do
      nil ->
        []

      event ->
        identity =
          summary["publication_id"] || summary["source_artifact_id"] || event["feedback_key"] ||
            index

        [
          %{
            "id" =>
              "derived_timeline_publication_pressure_#{callbacks.branch_id_fragment.(identity)}",
            "label" => "Derived timeline publication pressure #{identity}",
            "events" => [event],
            "metadata" =>
              %{
                "derived_source" => source_path,
                "publication_id" => summary["publication_id"],
                "publication_status" => summary["publication_status"],
                "downstream_invalidation_status" => summary["downstream_invalidation_status"],
                "dependency_impact_status" => summary["dependency_impact_status"]
              }
              |> callbacks.compact_map.()
          }
        ]
    end
  end

  def timeline_lifecycle_state_pressure_branch(
        summary,
        source_path,
        index,
        opts \\ default_callbacks()
      ) do
    LifecycleState.pressure_branch(summary, source_path, index, callbacks!(opts))
  end

  def timeline_activity_lifecycle_state_pressure_branch(
        state,
        source_path,
        index,
        opts \\ default_callbacks()
      ) do
    callbacks = callbacks!(opts)

    case timeline_activity_lifecycle_state_pressure_event(state, source_path, callbacks) do
      nil ->
        []

      event ->
        identity = state["activity_id"] || state["timeline_id"] || event["feedback_key"] || index

        [
          %{
            "id" =>
              "derived_timeline_activity_lifecycle_state_pressure_#{callbacks.branch_id_fragment.(identity)}",
            "label" => "Derived timeline activity lifecycle-state pressure #{identity}",
            "events" => [event],
            "metadata" =>
              %{
                "derived_source" => source_path,
                "activity_id" => state["activity_id"],
                "timeline_id" => state["timeline_id"],
                "transition_decision" => state["transition_decision"],
                "required_operator_action" => state["required_operator_action"]
              }
              |> callbacks.compact_map.()
          }
        ]
    end
  end

  def timeline_activity_precondition_pressure_branch(
        summary,
        source_path,
        index,
        opts \\ default_callbacks()
      ) do
    ActivityPrecondition.pressure_branch(summary, source_path, index, callbacks!(opts))
  end

  def timeline_preservation_pressure_branch(row, source_path, index, opts \\ default_callbacks()) do
    Preservation.pressure_branch(row, source_path, index, callbacks!(opts))
  end

  defp timeline_integrity_pressure_event(row, source_path, callbacks) do
    row = callbacks.stringify_keys.(row)
    issue_context = callbacks.operational_timeline_integrity_issue_context.(row)
    activity_id = callbacks.realized_feedback_activity_id.(row)
    timeline_id = callbacks.explicit_timeline_id.(row)

    if issue_context == %{} or (activity_id in [nil, ""] and timeline_id in [nil, ""]) do
      nil
    else
      %{
        "type" => "timeline_integrity_feedback",
        "activity_id" => activity_id,
        "timeline_id" => timeline_id,
        "timeline_integrity_status" => row["timeline_integrity_status"],
        "timeline_integrity_issue_types" => row["timeline_integrity_issue_types"],
        "timeline_integrity_issue_count" => row["timeline_integrity_issue_count"],
        "required_operator_action" =>
          row["required_operator_action"] || "review_timeline_integrity",
        "feedback_source" => source_path,
        "feedback_scope" => "timeline_integrity",
        "feedback_key" => activity_id || timeline_id,
        "trust_boundary" => callbacks.operator_review_trust_boundary.(row),
        "derivation_reasons" => ["timeline_integrity_report_pressure"]
      }
      |> Map.merge(callbacks.operational_timeline_activity_integrity_context.(row))
      |> callbacks.compact_map.()
    end
  end

  defp timeline_dependency_impact_pressure_event(row, source_path, callbacks) do
    row = callbacks.stringify_keys.(row)
    issue_context = timeline_dependency_impact_context(row, callbacks)
    activity_id = callbacks.realized_feedback_activity_id.(row)
    timeline_id = callbacks.explicit_timeline_id.(row)

    if issue_context == %{} or (activity_id in [nil, ""] and timeline_id in [nil, ""]) do
      nil
    else
      %{
        "type" => "timeline_dependency_impact_pressure",
        "activity_id" => activity_id,
        "timeline_id" => timeline_id,
        "dependency_impact_scope" => row["scope"] || row["dependency_impact_scope"],
        "dependency_impact_status" => row["dependency_impact_status"],
        "operator_action_reason" => row["operator_action_reason"],
        "required_operator_action" =>
          row["required_operator_action"] || "review_timeline_integrity",
        "feedback_source" => source_path,
        "feedback_scope" => "timeline_dependency_impact",
        "feedback_key" => activity_id || timeline_id,
        "trust_boundary" => callbacks.operator_review_trust_boundary.(row),
        "derivation_reasons" => ["timeline_dependency_impact_summary_pressure"]
      }
      |> Map.merge(issue_context)
      |> callbacks.compact_map.()
    end
  end

  defp timeline_dependency_impact_context(row, callbacks) do
    %{
      "dependency_activity_ids" => row["dependency_activity_ids"],
      "dependency_timeline_ids" => row["dependency_timeline_ids"],
      "exclusive_with_activity_ids" => row["exclusive_with_activity_ids"],
      "exclusive_with_timeline_ids" => row["exclusive_with_timeline_ids"],
      "impacted_dependency_activity_ids" => row["impacted_dependency_activity_ids"],
      "impacted_dependency_timeline_ids" => row["impacted_dependency_timeline_ids"],
      "impacted_exclusive_with_activity_ids" => row["impacted_exclusive_with_activity_ids"],
      "impacted_exclusive_with_timeline_ids" => row["impacted_exclusive_with_timeline_ids"]
    }
    |> callbacks.reject_empty_values.()
  end

  defp timeline_activity_lifecycle_state_pressure_event(state, source_path, callbacks) do
    state = callbacks.stringify_keys.(state)
    context = timeline_activity_lifecycle_state_pressure_context(state, callbacks)

    activity_id =
      state["activity_id"] || state["planned_activity_id"] || state["realized_activity_id"]

    timeline_id =
      state["timeline_id"] || state["planned_timeline_id"] || state["realized_timeline_id"]

    if context == %{} or not timeline_activity_lifecycle_state_pressure?(state, callbacks) do
      nil
    else
      %{
        "type" => "timeline_activity_lifecycle_state_pressure",
        "activity_id" => activity_id,
        "timeline_id" => timeline_id,
        "planned_activity_id" => state["planned_activity_id"],
        "realized_activity_id" => state["realized_activity_id"],
        "planned_timeline_id" => state["planned_timeline_id"],
        "realized_timeline_id" => state["realized_timeline_id"],
        "transition_decision" => state["transition_decision"],
        "status_transition_decision" => state["status_transition_decision"],
        "approval_transition_decision" => state["approval_transition_decision"],
        "review_required" => state["review_required"],
        "requires_operator_review" => state["review_required"],
        "required_operator_action" => state["required_operator_action"],
        "required_operator_actions" => state["required_operator_actions"],
        "operator_action_reasons" => state["operator_action_reasons"],
        "import_action" => state["import_action"],
        "invalid_activity_input" => state["invalid_activity_input"],
        "invalid_activity_input_count" => state["invalid_activity_input_count"],
        "invalid_activity_input_reasons" => state["invalid_activity_input_reasons"],
        "feedback_source" => source_path,
        "feedback_scope" => "timeline_activity_lifecycle_state",
        "feedback_key" => activity_id || timeline_id,
        "trust_boundary" => callbacks.operator_review_trust_boundary.(state),
        "derivation_reasons" => ["timeline_activity_lifecycle_state_pressure"],
        "assumptions" => %{
          "activity_lifecycle_application" => "not_performed_by_strategy_branch",
          "timeline_mutation" => "not_performed_by_strategy_branch",
          "operator_authority" => "not_granted_by_strategy_branch",
          "cadence_import" => "not_performed_by_strategy_branch",
          "command_execution" => "not_performed_by_strategy_branch"
        }
      }
      |> Map.merge(context)
      |> callbacks.compact_map.()
    end
  end

  defp timeline_activity_lifecycle_state_pressure?(state, callbacks) do
    state["review_required"] == true or
      state["transition_decision"] not in [nil, "", "none"] or
      positive_count?(state["invalid_activity_input_count"], callbacks) or
      nonempty_pressure_actions?(state["required_operator_actions"], ["none"], callbacks) or
      state["required_operator_action"] not in [nil, "", "none"] or
      state["import_action"] not in [nil, "", "record_preserved_activity"]
  end

  defp timeline_activity_lifecycle_state_pressure_context(state, callbacks) do
    %{
      "planned_status" => state["planned_status"],
      "realized_status" => state["realized_status"],
      "planned_status_category" => state["planned_status_category"],
      "realized_status_category" => state["realized_status_category"],
      "planned_approval_status" => state["planned_approval_status"],
      "realized_approval_status" => state["realized_approval_status"],
      "planned_approval_category" => state["planned_approval_category"],
      "realized_approval_category" => state["realized_approval_category"],
      "planned_locked" => state["planned_locked"],
      "realized_locked" => state["realized_locked"],
      "planned_executed" => state["planned_executed"],
      "realized_executed" => state["realized_executed"],
      "status_transition" => state["status_transition"],
      "approval_transition" => state["approval_transition"],
      "planned_protection_decision" => state["planned_protection_decision"],
      "realized_protection_decision" => state["realized_protection_decision"]
    }
    |> callbacks.reject_empty_values.()
  end

  defp timeline_publication_pressure_event(summary, source_path, callbacks) do
    summary = callbacks.stringify_keys.(summary)
    context = timeline_publication_pressure_context(summary, callbacks)
    publication_id = summary["publication_id"]
    source_artifact_id = summary["source_artifact_id"]

    if context == %{} or not timeline_publication_pressure?(summary, callbacks) do
      nil
    else
      %{
        "type" => "timeline_publication_pressure",
        "publication_id" => publication_id,
        "publication_sequence" => summary["publication_sequence"],
        "publication_status" => summary["publication_status"],
        "downstream_invalidation_status" => summary["downstream_invalidation_status"],
        "dependency_impact_status" => summary["dependency_impact_status"],
        "source_artifact_id" => source_artifact_id,
        "source_artifact_type" => summary["source_artifact_type"],
        "publication_authority" => summary["publication_authority"],
        "feedback_source" => source_path,
        "feedback_scope" => "timeline_publication",
        "feedback_key" => publication_id || source_artifact_id,
        "trust_boundary" => callbacks.operator_review_trust_boundary.(summary),
        "derivation_reasons" => ["timeline_publication_summary_pressure"],
        "assumptions" => %{
          "publication_execution" => "not_performed_by_strategy_branch",
          "notification_delivery" => "not_performed_by_strategy_branch",
          "operator_authority" => "not_granted_by_strategy_branch",
          "import_approval" => "not_granted_by_strategy_branch"
        }
      }
      |> Map.merge(context)
      |> callbacks.compact_map.()
    end
  end

  defp timeline_publication_pressure?(summary, callbacks) do
    summary["publication_status"] in [
      "review_required",
      "published_with_downstream_invalidations"
    ] or
      summary["downstream_invalidation_status"] == "invalidated" or
      summary["dependency_impact_status"] == "review_required" or
      positive_count?(summary["dependency_impact_row_count"], callbacks) or
      positive_count?(summary["timeline_diff_review_required_count"], callbacks) or
      nonempty_pressure_value?(summary["invalidated_downstream_product_ids"]) or
      nonempty_pressure_value?(summary["downstream_invalidation_reason_counts"]) or
      nonempty_pressure_value?(summary["changed_field_counts"]) or
      nonempty_pressure_value?(summary["changed_timeline_ids"]) or
      nonempty_pressure_value?(summary["review_timeline_ids"])
  end

  defp timeline_publication_pressure_context(summary, callbacks) do
    downstream_invalidation_reason_counts =
      callbacks.stringify_keys.(Map.get(summary, "downstream_invalidation_reason_counts", %{}))

    changed_field_counts =
      callbacks.stringify_keys.(Map.get(summary, "changed_field_counts", %{}))

    %{
      "supersedes_artifact_ids" => summary["supersedes_artifact_ids"],
      "downstream_product_ids" => summary["downstream_product_ids"],
      "invalidated_downstream_product_ids" => summary["invalidated_downstream_product_ids"],
      "downstream_invalidation_reason_counts" => downstream_invalidation_reason_counts,
      "downstream_invalidation_reasons" => Map.keys(downstream_invalidation_reason_counts),
      "invalidated_downstream_product_ids_by_reason" =>
        summary["invalidated_downstream_product_ids_by_reason"],
      "dependency_impact_row_count" => summary["dependency_impact_row_count"],
      "impacted_source_activity_ids" => summary["impacted_source_activity_ids"],
      "impacted_source_timeline_ids" => summary["impacted_source_timeline_ids"],
      "dependent_activity_ids" => summary["dependent_activity_ids"],
      "dependent_timeline_ids" => summary["dependent_timeline_ids"],
      "source_dependent_activity_ids" => summary["source_dependent_activity_ids"],
      "source_dependent_timeline_ids" => summary["source_dependent_timeline_ids"],
      "replacement_dependent_activity_ids" => summary["replacement_dependent_activity_ids"],
      "replacement_dependent_timeline_ids" => summary["replacement_dependent_timeline_ids"],
      "impacted_dependency_activity_ids" => summary["impacted_dependency_activity_ids"],
      "impacted_dependency_timeline_ids" => summary["impacted_dependency_timeline_ids"],
      "impacted_exclusive_with_activity_ids" => summary["impacted_exclusive_with_activity_ids"],
      "impacted_exclusive_with_timeline_ids" => summary["impacted_exclusive_with_timeline_ids"],
      "timeline_diff_row_count" => summary["timeline_diff_row_count"],
      "timeline_diff_changed_count" => summary["timeline_diff_changed_count"],
      "timeline_diff_review_required_count" => summary["timeline_diff_review_required_count"],
      "changed_field_counts" => changed_field_counts,
      "changed_fields" => Map.keys(changed_field_counts),
      "changed_timeline_ids" => summary["changed_timeline_ids"],
      "review_timeline_ids" => summary["review_timeline_ids"],
      "timeline_ids_by_changed_field" => summary["timeline_ids_by_changed_field"]
    }
    |> callbacks.reject_empty_values.()
  end

  defp positive_count?(value, callbacks) do
    case callbacks.numeric_or_nil.(value) do
      count when is_number(count) -> count > 0
      _count -> false
    end
  end

  defp nonempty_pressure_actions?(actions, ignored_actions, callbacks) do
    actions
    |> List.wrap()
    |> Enum.map(&callbacks.encode_value.(&1))
    |> Enum.any?(&(is_binary(&1) and &1 != "" and &1 not in ignored_actions))
  end

  defp nonempty_pressure_value?(value) when is_list(value), do: value != []
  defp nonempty_pressure_value?(%{} = value), do: map_size(value) > 0
  defp nonempty_pressure_value?(_value), do: false

  defp default_callbacks do
    [
      branch_id_fragment: &ValueEncoding.branch_id_fragment/1,
      compact_map: &ValueEncoding.compact_map/1,
      stringify_keys: &ValueEncoding.stringify_keys/1,
      reject_empty_values: &ValueEncoding.reject_empty_values/1,
      operational_timeline_integrity_issue_context:
        &OperationalTimelinePressureEvents.integrity_issue_context/1,
      operational_timeline_activity_integrity_context:
        &OperationalTimelinePressureEvents.activity_integrity_context/1,
      realized_feedback_activity_id: &RealizedFeedbackContext.activity_id/1,
      explicit_timeline_id: &RealizedFeedbackContext.explicit_timeline_id/1,
      operator_review_trust_boundary: &operator_review_trust_boundary/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      encode_value: &ValueEncoding.encode_value/1
    ]
  end

  defp operator_review_trust_boundary(row) do
    Map.get(row, "trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end

  defp callbacks!(opts) do
    %{
      branch_id_fragment: Keyword.fetch!(opts, :branch_id_fragment),
      compact_map: Keyword.fetch!(opts, :compact_map),
      stringify_keys: Keyword.fetch!(opts, :stringify_keys),
      reject_empty_values: Keyword.fetch!(opts, :reject_empty_values),
      operational_timeline_integrity_issue_context:
        Keyword.fetch!(opts, :operational_timeline_integrity_issue_context),
      operational_timeline_activity_integrity_context:
        Keyword.fetch!(opts, :operational_timeline_activity_integrity_context),
      realized_feedback_activity_id: Keyword.fetch!(opts, :realized_feedback_activity_id),
      explicit_timeline_id: Keyword.fetch!(opts, :explicit_timeline_id),
      operator_review_trust_boundary: Keyword.fetch!(opts, :operator_review_trust_boundary),
      numeric_or_nil: Keyword.fetch!(opts, :numeric_or_nil),
      encode_value: Keyword.fetch!(opts, :encode_value)
    }
  end
end
