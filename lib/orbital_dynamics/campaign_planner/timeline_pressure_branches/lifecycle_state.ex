defmodule OrbitalDynamics.CampaignPlanner.TimelinePressureBranches.LifecycleState do
  @moduledoc false

  def pressure_branch(summary, source_path, index, callbacks) do
    case timeline_lifecycle_state_pressure_event(summary, source_path, callbacks) do
      nil ->
        []

      event ->
        identity =
          summary["source"] || List.first(List.wrap(summary["review_timeline_ids"])) ||
            event["feedback_key"] || index

        [
          %{
            "id" =>
              "derived_timeline_lifecycle_state_pressure_#{callbacks.branch_id_fragment.(identity)}",
            "label" => "Derived timeline lifecycle-state pressure #{identity}",
            "events" => [event],
            "metadata" =>
              %{
                "derived_source" => source_path,
                "timeline_lifecycle_state_status" => event["timeline_lifecycle_state_status"],
                "review_required_count" => summary["review_required_count"],
                "duplicate_timeline_identity_count" =>
                  summary["duplicate_timeline_identity_count"],
                "invalid_activity_input_count" => summary["invalid_activity_input_count"]
              }
              |> callbacks.compact_map.()
          }
        ]
    end
  end

  defp timeline_lifecycle_state_pressure_event(summary, source_path, callbacks) do
    summary = callbacks.stringify_keys.(summary)
    summary = put_row_derived_timeline_lifecycle_state_pressure(summary, callbacks)
    context = timeline_lifecycle_state_pressure_context(summary, callbacks)

    if context == %{} or not timeline_lifecycle_state_pressure?(summary, callbacks) do
      nil
    else
      %{
        "type" => "timeline_lifecycle_state_pressure",
        "timeline_lifecycle_state_status" => timeline_lifecycle_state_status(summary, callbacks),
        "planned_activity_count" => summary["planned_activity_count"],
        "realized_activity_count" => summary["realized_activity_count"],
        "row_count" => summary["row_count"],
        "recordable_count" => summary["recordable_count"],
        "preserved_count" => summary["preserved_count"],
        "review_required_count" => summary["review_required_count"],
        "duplicate_timeline_identity_count" => summary["duplicate_timeline_identity_count"],
        "invalid_activity_input_count" => summary["invalid_activity_input_count"],
        "feedback_source" => source_path,
        "feedback_scope" => "timeline_lifecycle_state",
        "feedback_key" =>
          summary["source"] || List.first(List.wrap(summary["review_timeline_ids"])),
        "trust_boundary" => callbacks.operator_review_trust_boundary.(summary),
        "requires_operator_review" =>
          positive_count?(summary["review_required_count"], callbacks),
        "required_operator_action" => "review_timeline_lifecycle_state",
        "derivation_reasons" => ["timeline_lifecycle_state_summary_pressure"],
        "assumptions" => %{
          "timeline_lifecycle_application" => "not_performed_by_strategy_branch",
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

  defp timeline_lifecycle_state_pressure?(summary, callbacks) do
    positive_count?(summary["review_required_count"], callbacks) or
      positive_count?(summary["recordable_count"], callbacks) or
      positive_count?(summary["duplicate_timeline_identity_count"], callbacks) or
      positive_count?(summary["invalid_activity_input_count"], callbacks) or
      pressure_count_map?(summary["required_operator_action_counts"], ["none"], callbacks) or
      pressure_count_map?(
        summary["import_action_counts"],
        ["record_preserved_activity"],
        callbacks
      )
  end

  defp timeline_lifecycle_state_status(summary, callbacks) do
    cond do
      positive_count?(summary["review_required_count"], callbacks) ->
        "review_required"

      positive_count?(summary["invalid_activity_input_count"], callbacks) ->
        "invalid_activity_input"

      positive_count?(summary["duplicate_timeline_identity_count"], callbacks) ->
        "duplicate_identity"

      positive_count?(summary["recordable_count"], callbacks) ->
        "recordable"

      positive_count?(summary["preserved_count"], callbacks) ->
        "preserved"

      true ->
        "nominal"
    end
  end

  defp put_row_derived_timeline_lifecycle_state_pressure(summary, callbacks) do
    rows = timeline_lifecycle_state_summary_rows(summary, callbacks)

    if rows == [] do
      summary
    else
      review_rows = Enum.filter(rows, &(&1["review_required"] == true))

      summary
      |> Map.put("row_count", length(rows))
      |> Map.put("recordable_count", Enum.count(rows, &(&1["transition_decision"] == "record")))
      |> Map.put("preserved_count", Enum.count(rows, &(&1["transition_decision"] == "none")))
      |> Map.put("review_required_count", length(review_rows))
      |> Map.put(
        "duplicate_timeline_identity_count",
        Enum.count(rows, &(&1["timeline_identity_collision"] == true))
      )
      |> Map.put(
        "invalid_activity_input_count",
        Enum.count(rows, &(&1["invalid_activity_input"] == true))
      )
      |> Map.put(
        "transition_decision_counts",
        timeline_lifecycle_count_by(rows, "transition_decision")
      )
      |> Map.put(
        "required_operator_action_counts",
        timeline_lifecycle_count_by(rows, "required_operator_action")
      )
      |> Map.put(
        "operator_action_reason_counts",
        timeline_lifecycle_count_each(rows, "operator_action_reasons")
      )
      |> Map.put("import_action_counts", timeline_lifecycle_count_by(rows, "import_action"))
      |> Map.put(
        "planned_status_category_counts",
        timeline_lifecycle_count_by(rows, "planned_status_category")
      )
      |> Map.put(
        "realized_status_category_counts",
        timeline_lifecycle_count_by(rows, "realized_status_category")
      )
      |> Map.put(
        "planned_approval_category_counts",
        timeline_lifecycle_count_by(rows, "planned_approval_category")
      )
      |> Map.put(
        "realized_approval_category_counts",
        timeline_lifecycle_count_by(rows, "realized_approval_category")
      )
      |> Map.put(
        "recordable_timeline_ids",
        timeline_lifecycle_timeline_ids(rows, &(&1["transition_decision"] == "record"))
      )
      |> Map.put(
        "preserved_timeline_ids",
        timeline_lifecycle_timeline_ids(rows, &(&1["transition_decision"] == "none"))
      )
      |> Map.put(
        "review_timeline_ids",
        timeline_lifecycle_timeline_ids(review_rows, fn _row -> true end)
      )
      |> Map.put("review_activity_ids", timeline_lifecycle_activity_ids(review_rows))
      |> Map.put(
        "invalid_activity_input_ids",
        rows
        |> Enum.filter(&(&1["invalid_activity_input"] == true))
        |> timeline_lifecycle_activity_ids()
      )
    end
  end

  defp timeline_lifecycle_state_summary_rows(%{"rows" => rows}, callbacks) when is_list(rows) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.map(&callbacks.stringify_keys.(&1))
  end

  defp timeline_lifecycle_state_summary_rows(_summary, _callbacks), do: []

  defp timeline_lifecycle_count_by(rows, field) do
    rows
    |> Enum.map(& &1[field])
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
  end

  defp timeline_lifecycle_count_each(rows, field) do
    rows
    |> Enum.flat_map(&List.wrap(&1[field]))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
  end

  defp timeline_lifecycle_timeline_ids(rows, predicate) do
    rows
    |> Enum.filter(predicate)
    |> Enum.map(& &1["timeline_id"])
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp timeline_lifecycle_activity_ids(rows) do
    rows
    |> Enum.flat_map(fn row ->
      [
        row["activity_ids"],
        row["planned_activity_ids"],
        row["realized_activity_ids"],
        row["activity_id"],
        row["planned_activity_id"],
        row["realized_activity_id"]
      ]
      |> List.flatten()
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp timeline_lifecycle_state_pressure_context(summary, callbacks) do
    %{
      "transition_decision_counts" =>
        callbacks.stringify_keys.(summary["transition_decision_counts"] || %{}),
      "required_operator_action_counts" =>
        callbacks.stringify_keys.(summary["required_operator_action_counts"] || %{}),
      "operator_action_reason_counts" =>
        callbacks.stringify_keys.(summary["operator_action_reason_counts"] || %{}),
      "import_action_counts" => callbacks.stringify_keys.(summary["import_action_counts"] || %{}),
      "planned_status_category_counts" =>
        callbacks.stringify_keys.(summary["planned_status_category_counts"] || %{}),
      "realized_status_category_counts" =>
        callbacks.stringify_keys.(summary["realized_status_category_counts"] || %{}),
      "status_transition_category_counts" =>
        callbacks.stringify_keys.(summary["status_transition_category_counts"] || %{}),
      "approval_transition_category_counts" =>
        callbacks.stringify_keys.(summary["approval_transition_category_counts"] || %{}),
      "recordable_timeline_ids" => summary["recordable_timeline_ids"],
      "preserved_timeline_ids" => summary["preserved_timeline_ids"],
      "review_timeline_ids" => summary["review_timeline_ids"],
      "review_activity_ids" => summary["review_activity_ids"],
      "invalid_activity_input_ids" => summary["invalid_activity_input_ids"],
      "review_timeline_ids_by_required_operator_action" =>
        summary["review_timeline_ids_by_required_operator_action"],
      "review_timeline_ids_by_operator_action_reason" =>
        summary["review_timeline_ids_by_operator_action_reason"],
      "review_timeline_ids_by_status_transition_category" =>
        summary["review_timeline_ids_by_status_transition_category"],
      "review_timeline_ids_by_approval_transition_category" =>
        summary["review_timeline_ids_by_approval_transition_category"]
    }
    |> callbacks.reject_empty_values.()
  end

  defp positive_count?(value, callbacks) do
    case callbacks.numeric_or_nil.(value) do
      count when is_number(count) -> count > 0
      _count -> false
    end
  end

  defp pressure_count_map?(counts, ignored_keys, callbacks) do
    (counts || %{})
    |> callbacks.stringify_keys.()
    |> Enum.any?(fn {key, value} ->
      key not in ignored_keys and positive_count?(value, callbacks)
    end)
  end
end
