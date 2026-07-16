defmodule OrbitalDynamics.CampaignPlanner.RealizedDownlinkEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ActivityMatching

  def events(mission_state, prior_plan, callbacks) do
    downlink_activity? = Keyword.fetch!(callbacks, :downlink_activity?)

    planned_by_id = ActivityMatching.planned_activities_grouped_by_id(prior_plan)

    mission_state
    |> Map.get("realized_activities", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(fn realized ->
      planned = unique_planned_downlink_activity(realized, planned_by_id, callbacks) || %{}

      realized =
        planned
        |> Map.merge(realized)
        |> normalize_event_status(callbacks)

      if downlink_activity?.(realized) and gap_feedback?(realized, callbacks) do
        realized
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp normalize_event_status(%{} = realized, callbacks) do
    normalize_realized_status_value = Keyword.fetch!(callbacks, :normalize_realized_status_value)

    normalize_realized_activity_status =
      Keyword.fetch!(callbacks, :normalize_realized_activity_status)

    status =
      realized
      |> Map.get("status")
      |> encode_value()
      |> normalize_realized_status_value.()

    raw_realized_status =
      realized
      |> Map.get("realized_status")
      |> encode_value()
      |> normalize_realized_status_value.()

    {status, feedback_status, realized_status} =
      normalize_realized_activity_status.(status, raw_realized_status)

    realized
    |> put_if_present("status", status)
    |> put_if_present("feedback_status", feedback_status)
    |> put_if_present("realized_status", realized_status)
  end

  defp gap_feedback?(%{"contact_result" => result} = realized, callbacks) do
    provider_result_success_value = Keyword.fetch!(callbacks, :provider_result_success_value)

    case provider_result_success_value.(result) do
      :failure -> true
      :success -> false
      :unknown -> realized |> Map.delete("contact_result") |> gap_feedback?(callbacks)
    end
  end

  defp gap_feedback?(%{"realized_status" => status} = realized, callbacks) do
    failure_statuses = Keyword.fetch!(callbacks, :realized_failure_statuses)
    completion_statuses = Keyword.fetch!(callbacks, :realized_completion_statuses)

    cond do
      status in failure_statuses -> true
      status in completion_statuses -> false
      true -> realized |> Map.delete("realized_status") |> gap_feedback?(callbacks)
    end
  end

  defp gap_feedback?(%{"status" => status}, callbacks) do
    status in Keyword.fetch!(callbacks, :realized_failure_statuses)
  end

  defp gap_feedback?(_realized, _callbacks), do: false

  defp unique_planned_downlink_activity(realized, planned_by_id, callbacks) do
    downlink_activity? = Keyword.fetch!(callbacks, :downlink_activity?)

    ActivityMatching.unique_matching_activity_for_realized(
      realized,
      planned_by_id,
      ["downlink", "planned_contact", "contact"],
      downlink_activity?
    )
  end

  defp put_if_present(map, _key, nil), do: map
  defp put_if_present(map, key, value), do: Map.put(map, key, value)

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
