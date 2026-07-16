defmodule OrbitalDynamics.CampaignPlanner.RealizedFeedbackContext do
  @moduledoc false

  def enrich(realized_activities, prior_activity_rows) do
    planned_by_feedback_key =
      prior_activity_rows
      |> Enum.flat_map(fn planned ->
        planned
        |> planned_context_keys()
        |> Enum.map(&{&1, planned})
      end)
      |> Enum.group_by(fn {key, _planned} -> key end, fn {_key, planned} -> planned end)
      |> Map.delete(nil)
      |> Map.delete("")

    Enum.map(realized_activities, fn realized ->
      planned = context(realized, planned_by_feedback_key)

      planned
      |> Map.merge(realized)
      |> put_planned_activity_id(planned)
      |> put_target_priority(realized)
    end)
  end

  def planned_context_keys(activity) do
    [
      Map.get(activity, "id"),
      Map.get(activity, "activity_id"),
      Map.get(activity, "planned_activity_id"),
      explicit_timeline_id(activity)
    ]
    |> identity_keys()
  end

  def realized_context_keys(activity) do
    [
      Map.get(activity, "planned_activity_id"),
      Map.get(activity, "activity_id"),
      Map.get(activity, "id"),
      Map.get(activity, "realized_activity_id"),
      explicit_timeline_id(activity)
    ]
    |> identity_keys()
  end

  def activity_id(activity) do
    Map.get(activity, "__planned_feedback_activity_id") ||
      activity
      |> realized_context_keys()
      |> List.first()
  end

  def planned_activity_id(activity) do
    activity
    |> planned_context_keys()
    |> List.first()
  end

  def explicit_timeline_id(activity) do
    Map.get(activity, "timeline_id") || get_in(activity, ["metadata", "timeline_id"])
  end

  def identity_keys(values) do
    values
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp context(realized, planned_by_feedback_key) do
    realized
    |> realized_context_keys()
    |> Enum.find_value(%{}, fn key ->
      planned =
        planned_by_feedback_key
        |> Map.get(key, [])
        |> unique_prior_activity_context()

      if planned == %{}, do: nil, else: planned
    end)
  end

  defp unique_prior_activity_context([planned]), do: planned
  defp unique_prior_activity_context(_matches), do: %{}

  defp put_planned_activity_id(activity, planned) when planned == %{}, do: activity

  defp put_planned_activity_id(activity, planned) do
    case planned_activity_id(planned) do
      nil -> activity
      id -> Map.put(activity, "__planned_feedback_activity_id", id)
    end
  end

  defp put_target_priority(activity, realized) do
    case declared_target_priority(realized) do
      value when is_number(value) -> Map.put(activity, "__realized_target_priority", value)
      _value -> activity
    end
  end

  defp declared_target_priority(activity) do
    [
      Map.get(activity, "realized_target_priority"),
      Map.get(activity, "target_priority"),
      get_in(activity, ["metadata", "target_priority"])
    ]
    |> Enum.find_value(&numeric_or_nil/1)
  end

  defp numeric_or_nil(nil), do: nil
  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

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
