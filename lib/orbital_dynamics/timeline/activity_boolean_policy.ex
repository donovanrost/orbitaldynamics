defmodule OrbitalDynamics.Timeline.ActivityBooleanPolicy do
  @moduledoc false

  def locked?(activity) do
    truthy?(activity["locked"]) || truthy?(get_in(activity, ["metadata", "locked"]))
  end

  def allow_overlap(activity) do
    activity
    |> first_present_boolean_value(["allow_overlap", "allow_overlap?"])
    |> boolean_value()
  end

  def approved?(activity, activity_approval_status, protected_approval_statuses) do
    approval_status = activity_approval_status.(activity)

    truthy?(activity["approved"]) ||
      truthy?(get_in(activity, ["metadata", "approved"])) ||
      approval_status in protected_approval_statuses
  end

  def first_boolean(activity, keys) do
    Enum.reduce_while(keys, nil, fn key, _acc ->
      cond do
        Map.has_key?(activity, key) and is_boolean(boolean_value(Map.get(activity, key))) ->
          {:halt, boolean_value(Map.get(activity, key))}

        is_map(Map.get(activity, "metadata")) and
          Map.has_key?(Map.get(activity, "metadata"), key) and
            is_boolean(boolean_value(get_in(activity, ["metadata", key]))) ->
          {:halt, boolean_value(get_in(activity, ["metadata", key]))}

        true ->
          {:cont, nil}
      end
    end)
  end

  def boolean_value(value) when is_boolean(value), do: value

  def boolean_value(value) when is_number(value) do
    cond do
      value == 1 -> true
      value == 0 -> false
      true -> nil
    end
  end

  def boolean_value(value) when is_binary(value) do
    case String.downcase(String.trim(value)) do
      "true" -> true
      "1" -> true
      "false" -> false
      "0" -> false
      _value -> nil
    end
  end

  def boolean_value(_value), do: nil

  defp truthy?(value) when is_boolean(value), do: value
  defp truthy?(value) when is_number(value), do: value == 1

  defp truthy?(value) when is_binary(value) do
    String.downcase(String.trim(value)) in ["true", "1"]
  end

  defp truthy?(_value), do: false

  defp first_present_boolean_value(activity, keys) do
    Enum.find_value(keys, fn key ->
      cond do
        Map.has_key?(activity, key) ->
          {:value, Map.get(activity, key)}

        is_map(Map.get(activity, "metadata")) and Map.has_key?(activity["metadata"], key) ->
          {:value, get_in(activity, ["metadata", key])}

        true ->
          nil
      end
    end)
    |> case do
      {:value, value} -> value
      nil -> nil
    end
  end
end
