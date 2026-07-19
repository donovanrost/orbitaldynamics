defmodule OrbitalDynamics.TimelineFeedback.RealizedStatus do
  @moduledoc false

  def supported?(
        activity,
        {terminal_statuses, _feedback_match_statuses, _lifecycle_event_statuses} = policy
      ) do
    value(activity, policy) in terminal_statuses
  end

  def value(activity, {_terminal_statuses, feedback_match_statuses, lifecycle_event_statuses}) do
    do_value(activity, feedback_match_statuses, lifecycle_event_statuses)
  end

  defp do_value(
         %{"status" => status, "realized_status" => realized_status},
         feedback_match_statuses,
         _lifecycle_event_statuses
       ) do
    status = normalize_value(status)
    realized_status = normalize_value(realized_status)

    if status in feedback_match_statuses, do: realized_status, else: status
  end

  defp do_value(
         %{"status" => status, "lifecycle_event" => lifecycle_event},
         feedback_match_statuses,
         lifecycle_event_statuses
       ) do
    status = normalize_value(status)
    lifecycle_status = lifecycle_event_value(lifecycle_event, lifecycle_event_statuses)

    if status in feedback_match_statuses, do: lifecycle_status, else: status
  end

  defp do_value(
         %{"status" => status},
         _feedback_match_statuses,
         _lifecycle_event_statuses
       ),
       do: normalize_value(status)

  defp do_value(
         %{"lifecycle_event" => lifecycle_event},
         _feedback_match_statuses,
         lifecycle_event_statuses
       ),
       do: lifecycle_event_value(lifecycle_event, lifecycle_event_statuses)

  defp do_value(_activity, _feedback_match_statuses, _lifecycle_event_statuses), do: nil

  def feedback_value(
        activity,
        {terminal_statuses, feedback_match_statuses, lifecycle_event_statuses}
      ) do
    do_feedback_value(
      activity,
      terminal_statuses,
      feedback_match_statuses,
      lifecycle_event_statuses
    )
  end

  defp do_feedback_value(
         %{"status" => status, "realized_status" => realized_status},
         terminal_statuses,
         feedback_match_statuses,
         _lifecycle_event_statuses
       ) do
    status = normalize_value(status)
    realized_status = normalize_value(realized_status)

    if status in feedback_match_statuses and realized_status in terminal_statuses, do: status
  end

  defp do_feedback_value(
         %{"status" => status, "lifecycle_event" => lifecycle_event},
         terminal_statuses,
         feedback_match_statuses,
         lifecycle_event_statuses
       ) do
    status = normalize_value(status)
    lifecycle_status = lifecycle_event_value(lifecycle_event, lifecycle_event_statuses)

    if status in feedback_match_statuses and lifecycle_status in terminal_statuses, do: status
  end

  defp do_feedback_value(
         _activity,
         _terminal_statuses,
         _feedback_match_statuses,
         _lifecycle_event_statuses
       ),
       do: nil

  def invalid_reason(activity, policy) do
    case value(activity, policy) do
      nil -> "missing_realized_status"
      _status -> "unsupported_realized_status"
    end
  end

  def unsupported_value(
        activity,
        "unsupported_realized_status",
        policy
      ),
      do: value(activity, policy)

  def unsupported_value(_activity, _reason, _policy),
    do: nil

  defp normalize_value(status) when is_binary(status), do: normalize(status)
  defp normalize_value(status) when is_atom(status), do: status |> Atom.to_string() |> normalize()
  defp normalize_value(_status), do: nil

  defp normalize(status) when is_binary(status) do
    status
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  defp lifecycle_event_value(event, lifecycle_event_statuses) do
    case normalize_value(event) do
      nil -> nil
      event -> Map.get(lifecycle_event_statuses, event, event)
    end
  end
end
