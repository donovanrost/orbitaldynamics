defmodule OrbitalDynamics.Timeline.TransitionDecisionPolicy do
  @moduledoc false

  def build(source_activity, replacement_activity, opts, diff_report, compact_map) do
    source_activities = if is_nil(source_activity), do: [], else: [source_activity]
    replacement_activities = if is_nil(replacement_activity), do: [], else: [replacement_activity]

    source_activities
    |> transition_decision_report(replacement_activities, opts, diff_report)
    |> summarize_transition_decision_rows(compact_map)
  end

  defp transition_decision_report([], [], _opts, _diff_report) do
    %{"rows" => []}
  end

  defp transition_decision_report(source_activities, replacement_activities, opts, diff_report) do
    diff_report.(source_activities, replacement_activities, opts)
  end

  defp summarize_transition_decision_rows(%{"rows" => []}, _compact_map) do
    %{
      "transition_decision" => "none",
      "transition_decision_reason" => "no_source_or_replacement_activity",
      "diff_status" => "unchanged",
      "requires_operator_review" => false,
      "changed_fields" => []
    }
  end

  defp summarize_transition_decision_rows(%{"rows" => [row]}, compact_map) do
    row
    |> Map.take([
      "timeline_id",
      "diff_status",
      "transition_decision",
      "transition_decision_reason",
      "requires_operator_review",
      "required_operator_action",
      "reason",
      "changed_fields",
      "status_transition",
      "approval_transition",
      "source_activity_id",
      "replacement_activity_id",
      "source_activity_type",
      "replacement_activity_type",
      "source_status",
      "replacement_status",
      "source_approval_status",
      "replacement_approval_status",
      "source_locked",
      "replacement_locked",
      "source_protection_decision",
      "replacement_protection_decision",
      "source_timeline_identity",
      "replacement_timeline_identity"
    ])
    |> compact_map.()
  end

  defp summarize_transition_decision_rows(%{"rows" => rows}, compact_map)
       when is_list(rows) do
    %{
      "transition_decision" => "review",
      "transition_decision_reason" => "activity_transition_changes_timeline_identity",
      "diff_status" => "changed",
      "requires_operator_review" => true,
      "required_operator_action" => "review_activity_transition",
      "changed_fields" => ["timeline_identity"],
      "transition_row_count" => length(rows),
      "transition_rows" =>
        Enum.map(rows, &summarize_transition_decision_rows(%{"rows" => [&1]}, compact_map))
    }
  end
end
