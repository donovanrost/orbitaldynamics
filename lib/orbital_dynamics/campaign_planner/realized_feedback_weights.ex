defmodule OrbitalDynamics.CampaignPlanner.RealizedFeedbackWeights do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.FeedbackNumericValues

  @weight_fields [
    "feedback_weight",
    "feedback_sample_weight",
    "sample_weight",
    "confidence_weight"
  ]

  @weight_source_fields [
    "feedback_weight_source",
    "feedback_sample_weight_source",
    "sample_weight_source",
    "confidence_weight_source"
  ]

  def weighted_row_count(realized_activities) do
    Enum.count(realized_activities, fn activity ->
      activity
      |> stringify_keys()
      |> weight()
      |> is_number()
    end)
  end

  def sources(realized_activities) do
    realized_activities
    |> Enum.flat_map(fn activity ->
      activity = stringify_keys(activity)

      if is_number(weight(activity)) do
        activity
        |> source()
        |> List.wrap()
      else
        []
      end
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def weight(%{} = activity) do
    Enum.find_value(@weight_fields, fn key ->
      case numeric_or_nil(Map.get(activity, key)) do
        weight when is_number(weight) and weight > 0.0 -> weight * 1.0
        _weight -> nil
      end
    end)
  end

  def weight(_activity), do: nil

  def default_weight(activity) do
    case declared(activity) do
      {:ok, weight} -> weight
      :missing -> 1.0
    end
  end

  def declared(activity) do
    @weight_fields
    |> Enum.find_value(:missing, fn field ->
      case nonnegative_number_status(Map.get(activity, field)) do
        {:ok, weight} -> {:ok, weight}
        _status -> false
      end
    end)
  end

  def usable(activity) do
    if invalid?(activity) do
      nil
    else
      default_weight(activity)
    end
  end

  def invalid?(activity) do
    @weight_fields
    |> Enum.any?(fn field ->
      case nonnegative_number_status(Map.get(activity, field)) do
        {:invalid_number, _number} -> true
        {:invalid_shape, _shape} -> true
        _status -> false
      end
    end)
  end

  def weighted_value(activity, value_fun) do
    case {value_fun.(activity), usable(activity)} do
      {value, weight} when is_number(value) and is_number(weight) and weight > 0.0 ->
        {value, weight}

      _value ->
        nil
    end
  end

  def average_unit_interval([]), do: nil

  def average_unit_interval(weighted_values) do
    weighted_values
    |> weighted_average()
    |> FeedbackNumericValues.clamp_unit_interval()
  end

  def average_nonnegative([]), do: nil

  def average_nonnegative(weighted_values) do
    weighted_values
    |> weighted_average()
    |> max(0.0)
  end

  def fields, do: @weight_fields

  defp weighted_average(weighted_values) do
    {weighted_sum, total_weight} =
      Enum.reduce(weighted_values, {0.0, 0.0}, fn {value, weight}, {sum, total} ->
        {sum + value * weight, total + weight}
      end)

    weighted_sum / total_weight
  end

  defp nonnegative_number_status(value) do
    FeedbackNumericValues.nonnegative_number_status(value, feedback_numeric_callbacks())
  end

  defp feedback_numeric_callbacks,
    do: [
      numeric_or_nil: &numeric_or_nil/1,
      feedback_value_missing?: &feedback_value_missing?/1
    ]

  defp source(%{} = activity) do
    Enum.find_value(@weight_source_fields, fn key ->
      case Map.get(activity, key) do
        source when is_binary(source) and source != "" -> source
        _source -> nil
      end
    end)
  end

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
    Enum.map(values, &encode_value/1)
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value

  defp numeric_or_nil(nil), do: nil
  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {number, _rest} -> number
      :error -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp feedback_value_missing?(nil), do: true
  defp feedback_value_missing?(""), do: true
  defp feedback_value_missing?(_value), do: false
end
