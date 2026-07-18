defmodule OrbitalDynamics.Timeline.TransitionDecisionIntegrityPolicy do
  @moduledoc false

  def gate(
        %{"transition_decision" => decision} = transition_decision,
        source_activity,
        replacement_activity,
        opts,
        transition_application_activity,
        transition_application_selection,
        annotate_transition_selected_activities,
        timeline_integrity_review?,
        list_value,
        selected_integrity_reason,
        selected_integrity_context,
        compact_map
      ) do
    source = transition_application_activity.(source_activity, opts)
    replacement = transition_application_activity.(replacement_activity, opts)

    decision
    |> transition_application_selection.(source, replacement)
    |> Map.get("selected_activity")
    |> case do
      %{} = selected_activity ->
        selected_activity
        |> List.wrap()
        |> annotate_transition_selected_activities.(opts)
        |> case do
          [%{} = selected_with_integrity] ->
            gate_decision(
              transition_decision,
              selected_with_integrity,
              timeline_integrity_review?,
              list_value,
              selected_integrity_reason,
              selected_integrity_context,
              compact_map
            )

          _other ->
            transition_decision
        end

      _other ->
        transition_decision
    end
  end

  def gate(
        transition_decision,
        _source_activity,
        _replacement_activity,
        _opts,
        _transition_application_activity,
        _transition_application_selection,
        _annotate_transition_selected_activities,
        _timeline_integrity_review?,
        _list_value,
        _selected_integrity_reason,
        _selected_integrity_context,
        _compact_map
      ),
      do: transition_decision

  defp gate_decision(
         transition_decision,
         selected_activity,
         timeline_integrity_review?,
         list_value,
         selected_integrity_reason,
         selected_integrity_context,
         compact_map
       ) do
    if timeline_integrity_review?.(selected_activity) do
      issue_types = list_value.(selected_activity, "timeline_integrity_issue_types")
      reason = selected_integrity_reason.(issue_types)

      transition_decision
      |> Map.put("transition_decision", "review")
      |> Map.put("transition_decision_reason", reason)
      |> Map.put("requires_operator_review", true)
      |> Map.put("required_operator_action", "review_timeline_integrity")
      |> Map.merge(selected_integrity_context.(selected_activity))
      |> Map.update("reason", reason, fn current_reason ->
        if current_reason in [nil, "no_timeline_change"], do: reason, else: current_reason
      end)
      |> compact_map.()
    else
      transition_decision
    end
  end
end
