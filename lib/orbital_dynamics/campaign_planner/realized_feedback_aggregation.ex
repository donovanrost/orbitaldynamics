defmodule OrbitalDynamics.CampaignPlanner.RealizedFeedbackAggregation do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.RealizedFeedbackContext
  alias OrbitalDynamics.CampaignPlanner.RealizedFeedbackWeights

  def station_average(activities, value_fun) do
    activities
    |> Enum.group_by(&(Map.get(&1, "ground_station_id") || Map.get(&1, "station_id")))
    |> Enum.reject(fn {station_id, _activities} -> station_id in [nil, ""] end)
    |> Map.new(fn {station_id, station_activities} ->
      {station_id, average_value(station_activities, value_fun)}
    end)
    |> reject_nil_values()
  end

  def target_average(activities, value_fun) do
    activities
    |> Enum.group_by(&Map.get(&1, "target_id"))
    |> Enum.reject(fn {target_id, _activities} -> target_id in [nil, ""] end)
    |> Map.new(fn {target_id, target_activities} ->
      {target_id, average_value(target_activities, value_fun)}
    end)
    |> reject_nil_values()
  end

  def target_text(activities, value_fun) do
    activities
    |> Enum.group_by(&Map.get(&1, "target_id"))
    |> Enum.reject(fn {target_id, _activities} -> target_id in [nil, ""] end)
    |> Map.new(fn {target_id, target_activities} ->
      value =
        target_activities
        |> Enum.map(value_fun)
        |> Enum.map(&encode_value/1)
        |> Enum.reject(&(&1 in [nil, ""]))
        |> Enum.uniq()
        |> Enum.sort()
        |> List.first()

      {target_id, value}
    end)
    |> reject_nil_values()
  end

  def target_priority_average(activities) do
    activities
    |> Enum.group_by(&Map.get(&1, "target_id"))
    |> Enum.reject(fn {target_id, _activities} -> target_id in [nil, ""] end)
    |> Map.new(fn {target_id, target_activities} ->
      values =
        target_activities
        |> Enum.map(
          &RealizedFeedbackWeights.weighted_value(
            &1,
            fn activity -> target_priority_override_value(activity) end
          )
        )
        |> Enum.reject(&is_nil/1)

      {target_id, RealizedFeedbackWeights.average_nonnegative(values)}
    end)
    |> reject_nil_values()
  end

  def activity_average(activities, value_fun) do
    activities
    |> Enum.group_by(&RealizedFeedbackContext.activity_id/1)
    |> Enum.reject(fn {activity_id, _activities} -> activity_id in [nil, ""] end)
    |> Map.new(fn {activity_id, activity_rows} ->
      {activity_id, average_value(activity_rows, value_fun)}
    end)
    |> reject_nil_values()
  end

  defp average_value(activities, value_fun) do
    activities
    |> Enum.map(&RealizedFeedbackWeights.weighted_value(&1, value_fun))
    |> Enum.reject(&is_nil/1)
    |> RealizedFeedbackWeights.average_unit_interval()
  end

  defp reject_nil_values(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp target_priority_override_value(%{"__realized_target_priority" => value})
       when is_number(value),
       do: max(value, 0.0)

  defp target_priority_override_value(_activity), do: nil

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    Enum.map(values, &encode_value/1)
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
