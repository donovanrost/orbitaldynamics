defmodule OrbitalDynamics.Timeline.InvalidActivityRow do
  @moduledoc false

  def build(source_activity, sequence, reason, stable_activity_id?, issue, compact_map) do
    activity_id = invalid_activity_id(source_activity, sequence, reason, stable_activity_id?)
    timeline_id = "timeline:invalid_activity_input:#{activity_id}"

    timeline_identity = %{
      "timeline_id" => timeline_id,
      "activity_id" => activity_id,
      "activity_type" => "invalid_activity_input"
    }

    %{
      "id" => "timeline_row:#{sequence}:#{activity_id}",
      "activity_id" => activity_id,
      "timeline_id" => timeline_id,
      "activity_type" => "invalid_activity_input",
      "status" => "invalid",
      "approval_status" => "operator_review_required",
      "locked" => false,
      "operational_kind" => "activity",
      "required_operator_action" => "review_invalid_activity_input",
      "operator_action_reason" => reason,
      "execution_boundary" => "planned_not_commanded",
      "cadence_import_status" => "not_applicable",
      "has_source_window" => false,
      "has_cadence_import" => false,
      "timeline_identity" => timeline_identity,
      "activity_context" => %{"timeline_identity" => timeline_identity},
      "timeline_integrity_status" => "review_required",
      "timeline_integrity_issue_count" => 1,
      "timeline_integrity_issue_types" => ["invalid_activity_input"],
      "timeline_integrity_issues" => [
        issue.("invalid_activity_input", %{"invalid_activity_input_reason" => reason})
      ],
      "invalid_activity_input" => true,
      "invalid_activity_input_reason" => reason,
      "source_activity" => source_activity
    }
    |> compact_map.()
  end

  defp invalid_activity_id(activity, sequence, reason, stable_activity_id?)
       when is_map(activity) do
    case activity["id"] do
      value when is_binary(value) and value != "" ->
        if stable_activity_id?.(value), do: value, else: "#{reason}:#{sequence}"

      value when is_atom(value) and not is_nil(value) ->
        Atom.to_string(value)

      _value ->
        "#{reason}:#{sequence}"
    end
  end

  defp invalid_activity_id(_activity, sequence, reason, _stable_activity_id?),
    do: "#{reason}:#{sequence}"
end
