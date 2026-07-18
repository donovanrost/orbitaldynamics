defmodule OrbitalDynamics.Timeline.LifecycleStateNormalizationPolicy do
  @moduledoc false

  def lifecycle_event!(event, lifecycle_events, encode_value) do
    normalized = normalize_lifecycle_value(event, encode_value)

    cond do
      aliased_event = Map.get(lifecycle_event_aliases(), normalized) ->
        aliased_event

      normalized in lifecycle_events ->
        normalized

      true ->
        raise ArgumentError, "lifecycle event must be one of #{inspect(lifecycle_events)}"
    end
  end

  def maybe_put_status_unless_preserved(
        activity,
        status,
        executed_statuses,
        terminal_exception_statuses,
        encode_value
      ) do
    if activity_status(activity, encode_value) in (executed_statuses ++
                                                     terminal_exception_statuses) do
      activity
    else
      Map.put(activity, "status", status)
    end
  end

  def activity_status(activity, encode_value) do
    activity
    |> Map.get("status", get_in(activity, ["metadata", "status"]) || "planned")
    |> normalize_activity_status_value(encode_value)
  end

  def activity_approval_status(activity, encode_value) do
    activity
    |> Map.get(
      "approval_status",
      get_in(activity, ["metadata", "approval_status"]) || "not_evaluated"
    )
    |> normalize_approval_status_value(encode_value)
  end

  def normalize_lifecycle_value(value, _encode_value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  def normalize_lifecycle_value(value, encode_value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> normalize_lifecycle_value(encode_value)
  end

  def normalize_lifecycle_value(value, encode_value), do: encode_value.(value)

  defp lifecycle_event_aliases do
    OrbitalDynamics.MissionPlan.Activity.capabilities().lifecycle_event_aliases
    |> Map.new(fn {alias_value, event} -> {alias_value, Atom.to_string(event)} end)
  end

  defp normalize_activity_status_value(value, encode_value) do
    normalized = normalize_lifecycle_value(value, encode_value)
    Map.get(activity_status_aliases(), normalized, normalized)
  end

  def activity_status_aliases do
    OrbitalDynamics.MissionPlan.Activity.capabilities().activity_status_aliases
    |> Map.new(fn {alias_value, status} -> {alias_value, Atom.to_string(status)} end)
  end

  defp normalize_approval_status_value(value, encode_value) do
    normalized = normalize_lifecycle_value(value, encode_value)
    Map.get(approval_status_aliases(), normalized, normalized)
  end

  def approval_status_aliases do
    OrbitalDynamics.MissionPlan.Activity.capabilities().approval_status_aliases
    |> Map.new(fn {alias_value, status} -> {alias_value, Atom.to_string(status)} end)
  end
end
