defmodule OrbitalDynamics.CampaignPlanner.RealizedResourceFeedback do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.OperationalFeedbackNormalization

  @resource_availability_true_tokens ~w(true 1 yes y available nominal operational enabled)
  @resource_availability_false_tokens ~w(false 0 no n unavailable offline down outage maintenance disabled)

  def margin_feedback(realized_activities) do
    realized_activities
    |> Enum.reduce(%{}, fn activity, feedback ->
      spacecraft_id = spacecraft_id(activity)
      margins = activity_resource_margins(activity)

      if spacecraft_id in [nil, ""] or margins == %{} do
        feedback
      else
        Map.update(feedback, spacecraft_id, margins, &merge_margin_feedback(&1, margins))
      end
    end)
  end

  def availability_feedback(realized_activities) do
    realized_activities
    |> Enum.reduce(%{}, fn activity, feedback ->
      spacecraft_id = spacecraft_id(activity)
      availability = activity_resource_availability(activity)

      if spacecraft_id in [nil, ""] or availability == %{} do
        feedback
      else
        Map.update(
          feedback,
          spacecraft_id,
          availability,
          &merge_availability_feedback(&1, availability)
        )
      end
    end)
  end

  def activity_resource_margins(activity) do
    activity
    |> normalize_resource_margin_aliases()
    |> Map.take([
      "fuel_margin",
      "power_margin",
      "storage_margin",
      "downlink_margin",
      "thermal_margin_c",
      "battery_capacity_wh",
      "battery_energy_used_wh",
      "battery_state_of_charge"
    ])
    |> Enum.filter(fn {_field, value} -> is_number(value) end)
    |> Map.new(fn {field, value} -> {field, value * 1.0} end)
  end

  defp merge_margin_feedback(existing, incoming) do
    Map.merge(existing, incoming, fn field, current, candidate ->
      merge_margin_value(field, current, candidate)
    end)
  end

  defp merge_margin_value("battery_energy_used_wh", current, candidate),
    do: max(current, candidate)

  defp merge_margin_value(_field, current, candidate), do: min(current, candidate)

  def activity_resource_availability(activity) do
    activity
    |> normalize_resource_availability_aliases()
    |> Map.take([
      "payload_available",
      "antenna_available",
      "degraded",
      "spacecraft_available",
      "spacecraft_availability",
      "mode",
      "incompatible_activity_types",
      "suppressed_activity_types"
    ])
    |> Enum.reject(fn
      {_field, nil} -> true
      {_field, ""} -> true
      {_field, []} -> true
      {_field, _value} -> false
    end)
    |> Map.new()
  end

  defp merge_availability_feedback(existing, incoming) do
    Map.merge(existing, incoming, fn
      field, current, candidate when field in ["payload_available", "antenna_available"] ->
        current != false and candidate != false

      field, current, candidate
      when field in ["spacecraft_available", "spacecraft_availability"] ->
        current != false and candidate != false

      "degraded", current, candidate ->
        truthy?(current) or truthy?(candidate)

      field, current, candidate
      when field in ["incompatible_activity_types", "suppressed_activity_types"] ->
        merge_string_lists(current, candidate)

      "mode", current, candidate ->
        degraded_mode_preference(current, candidate)

      _field, _current, candidate ->
        candidate
    end)
  end

  defp merge_string_lists(current, candidate) do
    [current, candidate]
    |> List.flatten()
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp degraded_mode_preference(current, candidate) do
    Enum.find([current, candidate], &(encode_value(&1) in ["safe", "degraded", "degraded_mode"])) ||
      candidate ||
      current
  end

  def spacecraft_id(activity) do
    [
      Map.get(activity, "spacecraft_id"),
      Map.get(activity, "scenario_id"),
      Map.get(activity, "resource_id"),
      get_in(activity, ["metadata", "spacecraft_id"]),
      get_in(activity, ["provenance", "spacecraft_id"])
    ]
    |> Enum.map(&encode_value/1)
    |> Enum.find(&(&1 not in [nil, ""]))
  end

  defp normalize_resource_margin_aliases(value) do
    OperationalFeedbackNormalization.normalize_resource_margin_aliases(
      value,
      operational_feedback_normalization_callbacks()
    )
  end

  defp normalize_resource_availability_aliases(value) do
    OperationalFeedbackNormalization.normalize_resource_availability_aliases(
      value,
      operational_feedback_normalization_callbacks()
    )
  end

  defp operational_feedback_normalization_callbacks,
    do: [
      stringify_keys: &stringify_keys/1,
      numeric_or_nil: &numeric_or_nil/1,
      resource_availability_true_tokens: @resource_availability_true_tokens,
      resource_availability_false_tokens: @resource_availability_false_tokens
    ]

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} ->
      {encode_value(key), stringify_keys(value)}
    end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value

  defp truthy?(value),
    do:
      OperationalFeedbackNormalization.resource_availability_boolean_value(
        value,
        operational_feedback_normalization_callbacks()
      ) == true

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

  defp encode_value(values) when is_list(values), do: Enum.map(values, &encode_value/1)
  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
