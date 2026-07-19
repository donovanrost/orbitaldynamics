defmodule OrbitalDynamics.ResourceProjection.ActivityEffectPolicy do
  @moduledoc false

  def evaluate(activity, resource_effect_context, activity_type_aliases) do
    status = activity_status(activity)
    approval_status = activity_approval_status(activity)

    cond do
      resource_effect_context["spacecraft_available"] == false ->
        {"ignored", "spacecraft_unavailable"}

      approval_status == "rejected" ->
        {"ignored", "approval_status_rejected"}

      status in terminal_resource_statuses() ->
        {"ignored", "activity_status_#{status}"}

      reason = contact_allocation_resource_effect_reason(activity) ->
        {"ignored", reason}

      activity_type_suppressed?(
        activity,
        resource_effect_context["suppressed_activity_types"],
        activity_type_aliases
      ) ->
        {"ignored", "activity_type_suppressed_by_resource_summary"}

      activity_type_suppressed?(
        activity,
        resource_effect_context["incompatible_activity_types"],
        activity_type_aliases
      ) ->
        {"ignored", "activity_type_incompatible_with_resource_summary"}

      activity["type"] == "observe" and resource_effect_context["payload_available"] == false ->
        {"ignored", "payload_unavailable"}

      activity["type"] == "observe" and resource_effect_context["degraded"] == true ->
        {"ignored", "spacecraft_degraded_payload_unavailable"}

      antenna_required_activity?(activity) and
          resource_effect_context["antenna_available"] == false ->
        {"ignored", "antenna_unavailable"}

      true ->
        {"projected", "active_planning_activity"}
    end
  end

  defp contact_allocation_resource_effect_reason(activity) do
    effective_status = contact_allocation_status(activity, "effective_allocation_status")
    allocation_status = contact_allocation_status(activity, "allocation_status")

    cond do
      effective_status in [nil, "", "allocated"] and allocation_status in [nil, "", "allocated"] ->
        nil

      effective_status not in [nil, "", "allocated"] ->
        "contact_allocation_#{effective_status}"

      allocation_status not in [nil, "", "allocated"] ->
        "contact_allocation_#{allocation_status}"

      true ->
        nil
    end
  end

  def contact_allocation_status(activity, field) do
    activity
    |> contact_allocation_status_value(field)
    |> status_token()
  end

  defp contact_allocation_status_value(activity, field) do
    Map.get(activity, field) ||
      get_in(activity, ["source_contact_allocation", field]) ||
      get_in(activity, ["source_station_calendar_entry", "source_contact_allocation", field]) ||
      contact_allocation_status_value_from_overlaps(activity, field)
  end

  defp contact_allocation_status_value_from_overlaps(activity, field) do
    activity
    |> Map.get("source_station_calendar_overlaps")
    |> List.wrap()
    |> contact_allocation_source_from_overlaps()
    |> case do
      %{} = source -> Map.get(source, field)
      _source -> nil
    end
  end

  defp contact_allocation_source_from_overlaps(overlaps) do
    sources =
      overlaps
      |> Enum.map(fn
        %{} = overlap -> Map.get(overlap, "source_contact_allocation")
        _overlap -> nil
      end)
      |> Enum.filter(&is_map/1)

    Enum.find(sources, &contact_allocation_blocking_source?/1) || List.first(sources)
  end

  defp contact_allocation_blocking_source?(source) do
    effective_status = source |> Map.get("effective_allocation_status") |> status_token()
    allocation_status = source |> Map.get("allocation_status") |> status_token()

    cond do
      effective_status not in [nil, "", "allocated"] -> true
      allocation_status not in [nil, "", "allocated"] -> true
      true -> false
    end
  end

  defp status_token(value) when value in [nil, ""], do: nil

  defp status_token(value) when is_binary(value) or is_atom(value) or is_integer(value) do
    value
    |> to_string()
    |> String.trim()
    |> String.downcase()
  end

  defp status_token(_value), do: nil

  defp antenna_required_activity?(%{"type" => type})
       when type in ["downlink", "tracking", "uplink", "command", "health_check"],
       do: true

  defp antenna_required_activity?(%{"type" => "planned_contact", "direction" => direction})
       when direction in ["downlink", "tracking", "uplink", "command", "health_check"],
       do: true

  defp antenna_required_activity?(%{
         "direction" => direction,
         "ground_station_id" => station_id
       })
       when direction in ["downlink", "tracking", "uplink", "command", "health_check"] and
              not is_nil(station_id),
       do: true

  defp antenna_required_activity?(activity), do: downlink_activity?(activity)

  defp resource_direction(%{"direction" => direction}) when is_binary(direction), do: direction
  defp resource_direction(%{"type" => "downlink"}), do: "downlink"
  defp resource_direction(%{"type" => "tracking"}), do: "tracking"
  defp resource_direction(%{"type" => "uplink"}), do: "uplink"
  defp resource_direction(%{"type" => "command"}), do: "command"
  defp resource_direction(%{"type" => "health_check"}), do: "health_check"
  defp resource_direction(_activity), do: nil

  defp terminal_resource_statuses,
    do: ~w(canceled cancelled completed executed failed missed partial rejected)

  def activity_status(activity) do
    Map.get(activity, "status") || get_in(activity, ["metadata", "status"]) || "planned"
  end

  def activity_approval_status(activity) do
    Map.get(activity, "approval_status") || get_in(activity, ["metadata", "approval_status"])
  end

  defp resource_activity_type_list(values, aliases) when is_list(values) do
    values
    |> Enum.flat_map(&resource_activity_type_list(&1, aliases))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp resource_activity_type_list(%{} = value, aliases) do
    ["type", "activity_type", "direction"]
    |> Enum.flat_map(&resource_activity_type_list(Map.get(value, &1), aliases))
  end

  defp resource_activity_type_list(value, aliases) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map(&normalize_resource_activity_token(&1, aliases))
    |> Enum.reject(&is_nil/1)
  end

  defp resource_activity_type_list(nil, _aliases), do: []

  defp resource_activity_type_list(value, aliases) when is_atom(value),
    do: value |> Atom.to_string() |> resource_activity_type_list(aliases)

  defp resource_activity_type_list(_value, _aliases), do: []

  defp normalize_resource_activity_token(value, aliases) when is_binary(value) do
    value
    |> normalized_direction_token()
    |> case do
      nil ->
        nil

      token when is_map_key(aliases, token) ->
        Map.fetch!(aliases, token)

      token ->
        token
    end
  end

  def normalized_direction_token(value) do
    value
    |> to_string()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> case do
      "" -> nil
      "nil" -> nil
      token -> token
    end
  end

  defp activity_type_suppressed?(_activity, values, _aliases) when values in [nil, []], do: false

  defp activity_type_suppressed?(activity, values, aliases) when is_list(values) do
    activity
    |> resource_activity_tokens(aliases)
    |> Enum.any?(&(&1 in values))
  end

  defp activity_type_suppressed?(_activity, _values, _aliases), do: false

  defp resource_activity_tokens(activity, aliases) do
    [
      activity["type"],
      activity["direction"],
      resource_direction(activity)
    ]
    |> Enum.flat_map(&resource_activity_type_list(&1, aliases))
    |> Enum.uniq()
  end

  def downlink_activity?(%{"type" => "downlink"}), do: true
  def downlink_activity?(%{"type" => "planned_contact", "direction" => "downlink"}), do: true

  def downlink_activity?(%{"direction" => "downlink", "ground_station_id" => station_id})
      when not is_nil(station_id),
      do: true

  def downlink_activity?(_activity), do: false
end
