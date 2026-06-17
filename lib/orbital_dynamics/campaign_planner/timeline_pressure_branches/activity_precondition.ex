defmodule OrbitalDynamics.CampaignPlanner.TimelinePressureBranches.ActivityPrecondition do
  @moduledoc false

  def pressure_branch(summary, source_path, index, callbacks) do
    summary =
      summary
      |> callbacks.stringify_keys.()
      |> put_row_derived_timeline_activity_precondition_pressure(callbacks)

    case timeline_activity_precondition_pressure_event(summary, source_path, callbacks) do
      nil ->
        []

      event ->
        identity =
          summary["activity_id"] || summary["timeline_id"] || event["feedback_key"] || index

        [
          %{
            "id" =>
              "derived_timeline_activity_precondition_pressure_#{callbacks.branch_id_fragment.(identity)}",
            "label" => "Derived timeline activity precondition pressure #{identity}",
            "events" => [event],
            "metadata" =>
              %{
                "derived_source" => source_path,
                "activity_id" => summary["activity_id"],
                "timeline_id" => summary["timeline_id"],
                "precondition_status" => summary["precondition_status"],
                "blocked_precondition_count" => summary["blocked_precondition_count"],
                "review_precondition_count" => summary["review_precondition_count"]
              }
              |> callbacks.compact_map.()
          }
        ]
    end
  end

  defp timeline_activity_precondition_pressure_event(summary, source_path, callbacks) do
    summary =
      summary
      |> callbacks.stringify_keys.()
      |> put_row_derived_timeline_activity_precondition_pressure(callbacks)

    context = timeline_activity_precondition_pressure_context(summary, callbacks)
    activity_id = summary["activity_id"] || get_in(summary, ["timeline_identity", "activity_id"])
    timeline_id = summary["timeline_id"] || get_in(summary, ["timeline_identity", "timeline_id"])

    if context == %{} or not timeline_activity_precondition_pressure?(summary, callbacks) do
      nil
    else
      %{
        "type" => "timeline_activity_precondition_pressure",
        "activity_id" => activity_id,
        "timeline_id" => timeline_id,
        "activity_type" => summary["activity_type"],
        "precondition_status" => summary["precondition_status"],
        "blocked_precondition_count" => summary["blocked_precondition_count"],
        "review_precondition_count" => summary["review_precondition_count"],
        "blocked_precondition_types" => summary["blocked_precondition_types"],
        "review_precondition_types" => summary["review_precondition_types"],
        "preconditions" => summary["preconditions"],
        "dependency_activity_ids" => summary["dependency_activity_ids"],
        "dependency_timeline_ids" => summary["dependency_timeline_ids"],
        "exclusive_with_activity_ids" => summary["exclusive_with_activity_ids"],
        "exclusive_with_timeline_ids" => summary["exclusive_with_timeline_ids"],
        "duplicate_dependency_activity_ids" => summary["duplicate_dependency_activity_ids"],
        "duplicate_dependency_timeline_ids" => summary["duplicate_dependency_timeline_ids"],
        "duplicate_exclusivity_activity_ids" => summary["duplicate_exclusivity_activity_ids"],
        "duplicate_exclusivity_timeline_ids" => summary["duplicate_exclusivity_timeline_ids"],
        "allow_overlap" => summary["allow_overlap"],
        "invalid_activity_input" => summary["invalid_activity_input"],
        "invalid_activity_input_reason" => summary["invalid_activity_input_reason"],
        "feedback_source" => source_path,
        "feedback_scope" => "timeline_activity_precondition",
        "feedback_key" => activity_id || timeline_id,
        "trust_boundary" => callbacks.operator_review_trust_boundary.(summary),
        "requires_operator_review" =>
          summary["precondition_status"] in ["blocked", "review_required"] or
            summary["invalid_activity_input"] == true,
        "required_operator_action" => timeline_activity_precondition_required_action(summary),
        "derivation_reasons" => ["timeline_activity_precondition_summary_pressure"],
        "assumptions" => %{
          "activity_precondition_evaluation" => "not_performed_by_strategy_branch",
          "timeline_mutation" => "not_performed_by_strategy_branch",
          "operator_authority" => "not_granted_by_strategy_branch",
          "resource_authority" => "not_reserved_by_strategy_branch",
          "cadence_import" => "not_performed_by_strategy_branch",
          "command_execution" => "not_performed_by_strategy_branch"
        }
      }
      |> Map.merge(context)
      |> callbacks.compact_map.()
    end
  end

  defp put_row_derived_timeline_activity_precondition_pressure(summary, callbacks) do
    rows = timeline_activity_precondition_summary_rows(summary, callbacks)

    if rows == [] do
      summary
    else
      blocked_count =
        timeline_activity_precondition_rows_pressure_count(
          rows,
          "blocked"
        )

      review_count =
        timeline_activity_precondition_rows_pressure_count(
          rows,
          "review_required"
        )

      summary
      |> Map.put(
        "precondition_status",
        timeline_activity_precondition_rows_status(summary, blocked_count, review_count)
      )
      |> Map.put("blocked_precondition_count", blocked_count)
      |> Map.put("review_precondition_count", review_count)
      |> Map.put(
        "blocked_precondition_types",
        timeline_activity_precondition_rows_pressure_types(rows, "blocked", callbacks)
      )
      |> Map.put(
        "review_precondition_types",
        timeline_activity_precondition_rows_pressure_types(rows, "review_required", callbacks)
      )
    end
  end

  defp timeline_activity_precondition_summary_rows(%{"preconditions" => rows}, callbacks)
       when is_list(rows) do
    timeline_activity_precondition_rows(rows, callbacks)
  end

  defp timeline_activity_precondition_summary_rows(%{"rows" => rows}, callbacks)
       when is_list(rows) do
    rows = timeline_activity_precondition_rows(rows, callbacks)

    precondition_rows =
      rows
      |> Enum.flat_map(&List.wrap(&1["preconditions"]))
      |> timeline_activity_precondition_rows(callbacks)

    if precondition_rows == [], do: rows, else: precondition_rows
  end

  defp timeline_activity_precondition_summary_rows(_summary, _callbacks), do: []

  defp timeline_activity_precondition_rows(rows, callbacks) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.map(&callbacks.stringify_keys.(&1))
  end

  defp timeline_activity_precondition_rows_pressure_count(rows, status) do
    rows
    |> Enum.count(&(timeline_activity_precondition_row_status(&1) == status))
  end

  defp timeline_activity_precondition_rows_pressure_types(rows, status, callbacks) do
    rows
    |> Enum.filter(&(timeline_activity_precondition_row_status(&1) == status))
    |> Enum.map(& &1["type"])
    |> Enum.map(&callbacks.encode_value.(&1))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp timeline_activity_precondition_row_status(row),
    do: row["status"] || row["precondition_status"]

  defp timeline_activity_precondition_rows_status(summary, blocked_count, review_count) do
    cond do
      blocked_count > 0 -> "blocked"
      review_count > 0 or summary["invalid_activity_input"] == true -> "review_required"
      true -> "clear"
    end
  end

  defp timeline_activity_precondition_pressure?(summary, callbacks) do
    summary["precondition_status"] in ["blocked", "review_required"] or
      positive_count?(summary["blocked_precondition_count"], callbacks) or
      positive_count?(summary["review_precondition_count"], callbacks) or
      summary["invalid_activity_input"] == true or
      nonempty_pressure_value?(summary["blocked_precondition_types"]) or
      nonempty_pressure_value?(summary["review_precondition_types"]) or
      nonempty_pressure_value?(summary["dependency_activity_ids"]) or
      nonempty_pressure_value?(summary["dependency_timeline_ids"]) or
      nonempty_pressure_value?(summary["exclusive_with_activity_ids"]) or
      nonempty_pressure_value?(summary["exclusive_with_timeline_ids"]) or
      nonempty_pressure_value?(summary["duplicate_dependency_activity_ids"]) or
      nonempty_pressure_value?(summary["duplicate_dependency_timeline_ids"]) or
      nonempty_pressure_value?(summary["duplicate_exclusivity_activity_ids"]) or
      nonempty_pressure_value?(summary["duplicate_exclusivity_timeline_ids"]) or
      summary["allow_overlap"] == true
  end

  defp timeline_activity_precondition_required_action(%{
         "invalid_activity_input" => true
       }),
       do: "review_invalid_activity_input"

  defp timeline_activity_precondition_required_action(%{"precondition_status" => "blocked"}),
    do: "review_blocked_activity_precondition"

  defp timeline_activity_precondition_required_action(%{
         "precondition_status" => "review_required"
       }),
       do: "review_activity_precondition"

  defp timeline_activity_precondition_required_action(_summary),
    do: "record_activity_precondition"

  defp timeline_activity_precondition_pressure_context(summary, callbacks) do
    %{
      "timeline_identity" => summary["timeline_identity"],
      "activity_context" => summary["activity_context"],
      "preconditions" => summary["preconditions"],
      "dependency_activity_ids" => summary["dependency_activity_ids"],
      "dependency_timeline_ids" => summary["dependency_timeline_ids"],
      "exclusive_with_activity_ids" => summary["exclusive_with_activity_ids"],
      "exclusive_with_timeline_ids" => summary["exclusive_with_timeline_ids"],
      "duplicate_dependency_activity_ids" => summary["duplicate_dependency_activity_ids"],
      "duplicate_dependency_timeline_ids" => summary["duplicate_dependency_timeline_ids"],
      "duplicate_exclusivity_activity_ids" => summary["duplicate_exclusivity_activity_ids"],
      "duplicate_exclusivity_timeline_ids" => summary["duplicate_exclusivity_timeline_ids"],
      "allow_overlap" => summary["allow_overlap"],
      "source_activity" => summary["source_activity"]
    }
    |> callbacks.reject_empty_values.()
  end

  defp positive_count?(value, callbacks) do
    case callbacks.numeric_or_nil.(value) do
      count when is_number(count) -> count > 0
      _count -> false
    end
  end

  defp nonempty_pressure_value?(value) when is_list(value), do: value != []
  defp nonempty_pressure_value?(%{} = value), do: map_size(value) > 0
  defp nonempty_pressure_value?(_value), do: false
end
