defmodule OrbitalDynamics.CampaignPlanner.TimelinePressureBranches.Preservation do
  @moduledoc false

  def pressure_branch(row, source_path, index, callbacks) do
    case timeline_preservation_pressure_event(row, source_path, callbacks) do
      nil ->
        []

      event ->
        identity = row["activity_id"] || row["timeline_id"] || event["feedback_key"] || index

        [
          %{
            "id" =>
              "derived_timeline_preservation_pressure_#{callbacks.branch_id_fragment.(identity)}",
            "label" => "Derived timeline preservation pressure #{identity}",
            "events" => [event],
            "metadata" =>
              %{
                "derived_source" => source_path,
                "activity_id" => event["activity_id"],
                "timeline_id" => event["timeline_id"],
                "timeline_preservation_status" => event["timeline_preservation_status"],
                "protection_decision" => event["protection_decision"],
                "protection_category" => event["protection_category"],
                "protection_reason" => event["protection_reason"]
              }
              |> callbacks.compact_map.()
          }
        ]
    end
  end

  defp timeline_preservation_pressure_event(row, source_path, callbacks) do
    row = callbacks.stringify_keys.(row)
    context = timeline_preservation_pressure_context(row, callbacks)
    activity_id = row["activity_id"] || get_in(row, ["timeline_identity", "activity_id"])
    timeline_id = row["timeline_id"] || get_in(row, ["timeline_identity", "timeline_id"])
    timeline_preservation_status = timeline_preservation_effective_status(row)

    requires_preservation =
      timeline_preservation_requires_preservation?(row, timeline_preservation_status)

    requires_operator_review =
      timeline_preservation_requires_operator_review?(row, timeline_preservation_status)

    if context == %{} or not timeline_preservation_pressure?(row, callbacks) do
      nil
    else
      %{
        "type" => "timeline_preservation_pressure",
        "activity_id" => activity_id,
        "timeline_id" => timeline_id,
        "timeline_preservation_status" => timeline_preservation_status,
        "requires_preservation" => requires_preservation,
        "requires_operator_review" => requires_operator_review,
        "status" => row["status"],
        "approval_status" => row["approval_status"],
        "locked" => row["locked"],
        "approved" => row["approved"],
        "protection_decision" => row["protection_decision"],
        "protection_category" => row["protection_category"],
        "protection_reason" => row["protection_reason"] || row["reason"],
        "activity_count" => row["activity_count"],
        "preserve_activity_count" => row["preserve_activity_count"],
        "review_change_activity_count" => row["review_change_activity_count"],
        "preservation_sensitive_activity_count" => row["preservation_sensitive_activity_count"],
        "preserve_activity_ids" => row["preserve_activity_ids"],
        "preserve_timeline_ids" => row["preserve_timeline_ids"],
        "review_change_activity_ids" => row["review_change_activity_ids"],
        "review_change_timeline_ids" => row["review_change_timeline_ids"],
        "preservation_sensitive_activity_ids" => row["preservation_sensitive_activity_ids"],
        "preservation_sensitive_timeline_ids" => row["preservation_sensitive_timeline_ids"],
        "invalid_activity_input" => row["invalid_activity_input"],
        "invalid_activity_input_reason" => row["invalid_activity_input_reason"],
        "feedback_source" => source_path,
        "feedback_scope" => "timeline_preservation",
        "feedback_key" => activity_id || timeline_id || row["source"],
        "trust_boundary" => callbacks.operator_review_trust_boundary.(row),
        "required_operator_action" =>
          timeline_preservation_required_action(
            Map.merge(row, %{
              "timeline_preservation_status" => timeline_preservation_status,
              "requires_preservation" => requires_preservation,
              "requires_operator_review" => requires_operator_review
            })
          ),
        "derivation_reasons" => ["timeline_preservation_pressure"],
        "assumptions" => %{
          "timeline_preservation_application" => "not_performed_by_strategy_branch",
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

  defp timeline_preservation_effective_status(%{"invalid_activity_input" => true}),
    do: "review_required"

  defp timeline_preservation_effective_status(%{"requires_operator_review" => true}),
    do: "review_required"

  defp timeline_preservation_effective_status(%{"protection_decision" => "review_change"}),
    do: "review_required"

  defp timeline_preservation_effective_status(%{
         "timeline_preservation_status" => status
       })
       when status in ["review_required", "preservation_required"],
       do: status

  defp timeline_preservation_effective_status(%{"requires_preservation" => true}),
    do: "preservation_required"

  defp timeline_preservation_effective_status(%{"protection_decision" => "preserve"}),
    do: "preservation_required"

  defp timeline_preservation_effective_status(%{"timeline_preservation_status" => status}),
    do: status

  defp timeline_preservation_effective_status(_row), do: nil

  defp timeline_preservation_requires_preservation?(row, timeline_preservation_status) do
    row["requires_preservation"] == true or
      timeline_preservation_status == "preservation_required"
  end

  defp timeline_preservation_requires_operator_review?(row, timeline_preservation_status) do
    row["requires_operator_review"] == true or
      timeline_preservation_status == "review_required" or
      row["protection_decision"] == "review_change" or
      row["invalid_activity_input"] == true
  end

  defp timeline_preservation_pressure?(row, callbacks) do
    row["timeline_preservation_status"] in ["review_required", "preservation_required"] or
      row["requires_preservation"] == true or
      row["requires_operator_review"] == true or
      row["protection_decision"] in ["preserve", "review_change"] or
      row["invalid_activity_input"] == true or
      positive_count?(row["preserve_activity_count"], callbacks) or
      positive_count?(row["review_change_activity_count"], callbacks) or
      positive_count?(row["preservation_sensitive_activity_count"], callbacks) or
      pressure_count_map?(row["protection_decision_counts"], ["mutable"], callbacks) or
      nonempty_pressure_value?(row["preserve_activity_ids"]) or
      nonempty_pressure_value?(row["preserve_timeline_ids"]) or
      nonempty_pressure_value?(row["review_change_activity_ids"]) or
      nonempty_pressure_value?(row["review_change_timeline_ids"]) or
      nonempty_pressure_value?(row["preservation_sensitive_activity_ids"]) or
      nonempty_pressure_value?(row["preservation_sensitive_timeline_ids"])
  end

  defp timeline_preservation_required_action(%{"invalid_activity_input" => true}),
    do: "review_invalid_activity_input"

  defp timeline_preservation_required_action(%{"requires_operator_review" => true}),
    do: "review_timeline_preservation"

  defp timeline_preservation_required_action(%{
         "timeline_preservation_status" => "review_required"
       }),
       do: "review_timeline_preservation"

  defp timeline_preservation_required_action(%{"protection_decision" => "review_change"}),
    do: "review_timeline_preservation"

  defp timeline_preservation_required_action(_row), do: "record_timeline_preservation"

  defp timeline_preservation_pressure_context(row, callbacks) do
    %{
      "timeline_identity" => row["timeline_identity"],
      "protection_decision_counts" =>
        callbacks.stringify_keys.(row["protection_decision_counts"] || %{}),
      "protection_category_counts" =>
        callbacks.stringify_keys.(row["protection_category_counts"] || %{}),
      "protection_reason_counts" =>
        callbacks.stringify_keys.(row["protection_reason_counts"] || %{}),
      "activity_id_sets_by_protection_decision" => row["activity_id_sets_by_protection_decision"],
      "timeline_id_sets_by_protection_decision" => row["timeline_id_sets_by_protection_decision"],
      "activity_id_sets_by_protection_category" => row["activity_id_sets_by_protection_category"],
      "timeline_id_sets_by_protection_category" => row["timeline_id_sets_by_protection_category"],
      "activity_id_sets_by_protection_reason" => row["activity_id_sets_by_protection_reason"],
      "timeline_id_sets_by_protection_reason" => row["timeline_id_sets_by_protection_reason"],
      "assumptions" => row["assumptions"],
      "source" => row["source"]
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

  defp nonempty_pressure_value?(value) when is_list(value), do: value != []
  defp nonempty_pressure_value?(%{} = value), do: map_size(value) > 0
  defp nonempty_pressure_value?(_value), do: false
end
