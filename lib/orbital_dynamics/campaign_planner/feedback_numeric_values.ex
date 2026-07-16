defmodule OrbitalDynamics.CampaignPlanner.FeedbackNumericValues do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ScalarValues

  def completed_fraction_success_value(activity, default, callbacks) do
    case unit_interval_number_status(Map.get(activity, "completed_fraction"), callbacks) do
      {:ok, value} -> value
      :missing -> default
      _invalid -> nil
    end
  end

  def unit_interval_number_or_nil(value), do: unit_interval_number_or_nil(value, callbacks())

  def unit_interval_number_or_nil(value, callbacks) do
    case unit_interval_number_status(value, callbacks) do
      {:ok, number} -> number
      _value -> nil
    end
  end

  def unit_interval_number_status(value), do: unit_interval_number_status(value, callbacks())

  def unit_interval_number_status(value, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    case numeric_or_nil.(value) do
      number when is_number(number) and number >= 0.0 and number <= 1.0 ->
        {:ok, number * 1.0}

      number when is_number(number) ->
        {:invalid_number, number}

      _value ->
        missing_status(value, callbacks, {:invalid_shape, value})
    end
  end

  def nonnegative_number_status(value, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    case numeric_or_nil.(value) do
      number when is_number(number) and number >= 0.0 ->
        {:ok, number * 1.0}

      number when is_number(number) ->
        {:invalid_number, number}

      _value ->
        missing_status(value, callbacks, {:invalid_shape, value})
    end
  end

  def first_numeric_activity_value(activity, keys, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    Enum.find_value(keys, fn key ->
      value = activity_value(activity, key)

      case numeric_or_nil.(value) do
        value when is_number(value) -> value
        _value -> nil
      end
    end)
  end

  def first_unit_interval_activity_value(activity, keys, callbacks) do
    Enum.find_value(keys, fn key ->
      activity
      |> activity_value(key)
      |> unit_interval_number_or_nil(callbacks)
    end)
  end

  def low_feedback_factor?(factor, threshold) when is_number(factor) and is_number(threshold),
    do: factor < threshold

  def low_feedback_factor?(_factor, _threshold), do: false

  def clamp_unit_interval(value), do: value |> max(0.0) |> min(1.0)

  defp callbacks,
    do: [
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      feedback_value_missing?: &feedback_value_missing?/1
    ]

  defp feedback_value_missing?(nil), do: true
  defp feedback_value_missing?(""), do: true
  defp feedback_value_missing?(_value), do: false

  defp missing_status(value, callbacks, invalid_status) do
    feedback_value_missing? = Keyword.fetch!(callbacks, :feedback_value_missing?)

    if feedback_value_missing?.(value), do: :missing, else: invalid_status
  end

  defp activity_value(activity, path) when is_list(path), do: get_in(activity, path)
  defp activity_value(activity, key), do: Map.get(activity, key)
end
