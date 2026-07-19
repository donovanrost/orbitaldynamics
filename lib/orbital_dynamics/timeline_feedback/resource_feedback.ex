defmodule OrbitalDynamics.TimelineFeedback.ResourceFeedback do
  @moduledoc false

  alias OrbitalDynamics.TimelineFeedback.{
    ArtifactValue,
    ExecutionUncertainty,
    FeedbackAggregation
  }

  def margin_overrides(rows) do
    rows
    |> Enum.reject(&FeedbackAggregation.excluded?/1)
    |> Enum.reduce(%{}, fn row, feedback ->
      spacecraft_id = spacecraft_id(row)
      margins = margin_values(row)

      if spacecraft_id in [nil, ""] or margins == %{} do
        feedback
      else
        Map.update(feedback, spacecraft_id, margins, &merge_margin_feedback(&1, margins))
      end
    end)
    |> sort_nested_feedback_map()
  end

  def margin_trust_value(row) do
    if FeedbackAggregation.excluded?(row) do
      nil
    else
      case margin_values(row) do
        values when map_size(values) > 0 -> values
        _values -> nil
      end
    end
  end

  def availability_overrides(rows) do
    rows
    |> Enum.reject(&FeedbackAggregation.excluded?/1)
    |> Enum.reduce(%{}, fn row, feedback ->
      spacecraft_id = spacecraft_id(row)
      availability = availability_values(row)

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
    |> sort_nested_feedback_map()
  end

  def availability_trust_value(row) do
    if FeedbackAggregation.excluded?(row) do
      nil
    else
      case availability_values(row) do
        values when map_size(values) > 0 -> values
        _values -> nil
      end
    end
  end

  def spacecraft_id(row) do
    [
      row,
      Map.get(row, "realized_activity_context", %{}),
      Map.get(row, "realized_activity", %{})
    ]
    |> Enum.find_value(fn source ->
      [
        Map.get(source, "spacecraft_id"),
        Map.get(source, "scenario_id"),
        Map.get(source, "resource_spacecraft_id"),
        get_in(source, ["metadata", "spacecraft_id"]),
        get_in(source, ["provenance", "spacecraft_id"])
      ]
      |> Enum.find_value(&FeedbackAggregation.stable_identifier/1)
    end)
  end

  defp margin_values(row) do
    %{
      "fuel_margin" => first_resource_number(row, ["fuel_margin"]),
      "power_margin" => first_resource_number(row, ["power_margin"]),
      "storage_margin" => first_resource_number(row, ["storage_margin"]),
      "downlink_margin" =>
        first_resource_number(row, ["downlink_margin", "downlink_capacity_margin"]),
      "thermal_margin_c" => first_resource_number(row, ["thermal_margin_c"]),
      "battery_capacity_wh" => first_resource_number(row, ["battery_capacity_wh"]),
      "battery_energy_used_wh" => first_resource_number(row, ["battery_energy_used_wh"]),
      "battery_energy_generated_wh" =>
        first_resource_number(row, ["battery_energy_generated_wh"]),
      "battery_state_of_charge" => first_resource_number(row, ["battery_state_of_charge"])
    }
    |> Enum.reject(fn {_field, value} -> not is_number(value) end)
    |> Map.new(fn {field, value} -> {field, value * 1.0} end)
  end

  defp merge_margin_feedback(existing, incoming) do
    Map.merge(existing, incoming, fn field, current, candidate ->
      merge_margin_value(field, current, candidate)
    end)
  end

  defp merge_margin_value(field, current, candidate)
       when field in ["battery_energy_used_wh", "battery_energy_generated_wh"],
       do: max(current, candidate)

  defp merge_margin_value(_field, current, candidate), do: min(current, candidate)

  defp availability_values(row) do
    %{
      "payload_available" =>
        first_resource_boolean(row, ["payload_available", "payload_available?"]),
      "antenna_available" =>
        first_resource_boolean(row, ["antenna_available", "antenna_available?"]),
      "degraded" => first_resource_boolean(row, ["degraded", "degraded?"]),
      "spacecraft_available" => first_resource_boolean(row, ["spacecraft_available"]),
      "spacecraft_availability" => first_resource_boolean(row, ["spacecraft_availability"]),
      "mode" => first_resource_value(row, ["mode"]),
      "incompatible_activity_types" => first_resource_value(row, ["incompatible_activity_types"]),
      "suppressed_activity_types" => first_resource_value(row, ["suppressed_activity_types"])
    }
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
        ArtifactValue.truthy?(current) or ArtifactValue.truthy?(candidate)

      field, current, candidate
      when field in ["incompatible_activity_types", "suppressed_activity_types"] ->
        merge_string_lists(current, candidate)

      "mode", current, candidate ->
        degraded_mode_preference(current, candidate)

      _field, _current, candidate ->
        candidate
    end)
  end

  defp first_resource_number(row, fields) do
    case first_resource_value(row, fields) do
      value -> ExecutionUncertainty.numeric_value(value)
    end
  end

  defp first_resource_boolean(row, fields) do
    case first_resource_value(row, fields) |> ArtifactValue.boolean_value() do
      value when is_boolean(value) -> value
      nil -> nil
    end
  end

  defp first_resource_value(row, fields) do
    sources = [
      row,
      Map.get(row, "realized_activity_context", %{}),
      Map.get(row, "realized_activity", %{})
    ]

    Enum.reduce_while(sources, nil, fn source, _value ->
      case first_resource_source_value(source, fields) do
        {:ok, value} -> {:halt, value}
        :error -> {:cont, nil}
      end
    end)
  end

  defp first_resource_source_value(source, fields) do
    Enum.reduce_while(fields, :error, fn field, _value ->
      case resource_value(source, field) do
        nil -> {:cont, :error}
        value -> {:halt, {:ok, value}}
      end
    end)
  end

  defp resource_value(%{} = source, field) when is_list(field), do: get_in(source, field)
  defp resource_value(%{} = source, field), do: Map.get(source, field)
  defp resource_value(_source, _field), do: nil

  defp merge_string_lists(current, candidate) do
    [current, candidate]
    |> List.flatten()
    |> Enum.map(&ArtifactValue.stringify_scalar/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp degraded_mode_preference(current, candidate) do
    Enum.find(
      [current, candidate],
      &(ArtifactValue.stringify_scalar(&1) in ["safe", "degraded", "degraded_mode"])
    ) ||
      candidate ||
      current
  end

  defp sort_nested_feedback_map(feedback) do
    feedback
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Map.new(fn {key, value} ->
      {key,
       value
       |> Enum.sort_by(fn {field, _field_value} -> field end)
       |> Map.new()}
    end)
  end
end
