defmodule OrbitalDynamics.CampaignPlanner.ActivityMatching do
  @moduledoc false

  def planned_activities_grouped_by_id(prior_plan) do
    prior_plan
    |> Map.get("activities", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.group_by(& &1["id"])
  end

  def unique_planned_activity_for_realized(realized, planned_by_id, type) do
    unique_matching_activity_for_realized(realized, planned_by_id, [type], &(&1["type"] == type))
  end

  def unique_matching_activity_for_realized(
        realized,
        planned_by_id,
        realized_types,
        match?
      ) do
    realized_type = Map.get(realized, "type") || Map.get(realized, "activity_type")
    matches = Map.get(planned_by_id, realized["id"], [])
    matching_activities = Enum.filter(matches, match?)

    cond do
      realized_type in realized_types ->
        single_planned_activity(matching_activities)

      is_nil(realized_type) ->
        case matches do
          [planned] -> if match?.(planned), do: planned
          _matches -> nil
        end

      true ->
        nil
    end
  end

  defp single_planned_activity([planned]), do: planned
  defp single_planned_activity(_matches), do: nil

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
