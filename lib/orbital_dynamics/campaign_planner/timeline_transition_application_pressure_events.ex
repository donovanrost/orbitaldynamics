defmodule OrbitalDynamics.CampaignPlanner.TimelineTransitionApplicationPressureEvents do
  @moduledoc false

  def timeline_transition_application_pressure_events(row, source_path, callbacks) do
    if timeline_transition_application_pressure_row?(row, callbacks) do
      activity_id =
        row["activity_id"] || row["source_activity_id"] || row["replacement_activity_id"] ||
          get_in(row, ["selected_activity", "activity_id"])

      [
        %{
          "type" => "timeline_transition_application_pressure",
          "activity_id" => activity_id,
          "timeline_id" => row["timeline_id"],
          "application_status" => row["application_status"],
          "transition_decision" => row["transition_decision"],
          "required_operator_action" => row["required_operator_action"],
          "operator_action_reason" => row["operator_action_reason"],
          "feedback_source" => source_path,
          "feedback_scope" => "timeline_transition_application",
          "feedback_key" => activity_id || row["timeline_id"],
          "trust_boundary" => callback!(callbacks, :operator_review_trust_boundary).(row),
          "derivation_reasons" => ["timeline_transition_application_pressure"]
        }
      ]
    else
      []
    end
  end

  defp timeline_transition_application_pressure_row?(row, callbacks) do
    is_map(row["source_timeline_application"]) and
      (row["application_status"] in [
         "operator_review_required",
         "source_preserved_pending_review",
         "withheld_review"
       ] or
         row["transition_decision"] in ["review", "preserve_source", "withhold"] or
         row["required_operator_action"] not in [nil, "", "none"] or
         row["timeline_identity_collision"] == true or
         positive_count?(row["source_duplicate_activity_count"], callbacks) or
         positive_count?(row["replacement_duplicate_activity_count"], callbacks) or
         nonempty_pressure_value?(row["source_duplicate_activity_ids"]) or
         nonempty_pressure_value?(row["replacement_duplicate_activity_ids"]))
  end

  defp positive_count?(value, callbacks) do
    case callback!(callbacks, :numeric_or_nil).(value) do
      count when is_number(count) -> count > 0
      _count -> false
    end
  end

  defp nonempty_pressure_value?(value) when is_list(value), do: value != []
  defp nonempty_pressure_value?(%{} = value), do: map_size(value) > 0
  defp nonempty_pressure_value?(_value), do: false

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
