defmodule OrbitalDynamics.Timeline.TransitionHelperIntegrityPolicy do
  @moduledoc false

  def validate(
        activity,
        opts,
        annotate_transition_selected_activities,
        timeline_integrity_review?,
        selected_integrity_reason,
        list_value,
        selected_integrity_context,
        compact_map
      ) do
    if Keyword.get(opts, :validate_selected_integrity?, false) do
      activity
      |> List.wrap()
      |> annotate_transition_selected_activities.(opts)
      |> case do
        [%{} = selected_with_integrity] ->
          if timeline_integrity_review?.(selected_with_integrity) do
            {:error,
             selected_integrity_error(
               selected_with_integrity,
               selected_integrity_reason,
               list_value,
               selected_integrity_context,
               compact_map
             )}
          else
            {:ok, selected_with_integrity}
          end

        _other ->
          {:ok, activity}
      end
    else
      {:ok, activity}
    end
  end

  def raise_status_error!(%{"field" => "timeline_integrity"} = transition) do
    raise ArgumentError,
          "unsafe timeline activity selected integrity: #{transition["operator_action_reason"]}"
  end

  def raise_status_error!(transition) do
    raise ArgumentError,
          "unsafe timeline activity status transition #{transition["from"]} -> #{transition["to"]}: #{transition["operator_action_reason"]}"
  end

  def raise_approval_status_error!(%{"field" => "timeline_integrity"} = transition) do
    raise ArgumentError,
          "unsafe timeline activity selected integrity: #{transition["operator_action_reason"]}"
  end

  def raise_approval_status_error!(transition) do
    raise ArgumentError,
          "unsafe timeline activity approval transition #{transition["from"]} -> #{transition["to"]}: #{transition["operator_action_reason"]}"
  end

  def raise_lifecycle_event_error!(%{"field" => "timeline_integrity"} = transition) do
    raise ArgumentError,
          "unsafe timeline activity selected integrity: #{transition["operator_action_reason"]}"
  end

  def raise_lifecycle_event_error!(transition) do
    raise ArgumentError,
          "unsafe timeline activity lifecycle event #{transition["field"]} transition #{transition["from"]} -> #{transition["to"]}: #{transition["operator_action_reason"]}"
  end

  defp selected_integrity_error(
         selected_activity,
         selected_integrity_reason,
         list_value,
         selected_integrity_context,
         compact_map
       ) do
    %{
      "field" => "timeline_integrity",
      "transition_category" => "selected_timeline_integrity_review_required",
      "requires_operator_review" => true,
      "required_operator_action" => "review_timeline_integrity",
      "operator_action_reason" =>
        selected_integrity_reason.(
          list_value.(selected_activity, "timeline_integrity_issue_types")
        )
    }
    |> Map.merge(selected_integrity_context.(selected_activity))
    |> compact_map.()
  end
end
