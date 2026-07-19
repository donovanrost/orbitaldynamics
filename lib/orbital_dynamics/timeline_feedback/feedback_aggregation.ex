defmodule OrbitalDynamics.TimelineFeedback.FeedbackAggregation do
  @moduledoc false

  alias OrbitalDynamics.TimelineFeedback.{ArtifactValue, OutcomeValue, RealizedIdentity}

  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/
  @identity_fields ~w(activity_id ground_station_id target_id spacecraft_id resource_id)

  def excluded?(%{"operational_feedback_excluded" => true}), do: true
  def excluded?(%{} = row), do: invalid_identity?(row)
  def excluded?(_row), do: false

  def stable_identifier(value) do
    value
    |> ArtifactValue.stringify_scalar()
    |> RealizedIdentity.stable_value(@stable_id_pattern)
  end

  def average_by(rows, key_fun, value_fun) do
    rows
    |> Enum.reject(&excluded?/1)
    |> Enum.reduce(%{}, fn row, grouped ->
      key = stable_identifier(key_fun.(row))
      value = value_fun.(row)
      weight = OutcomeValue.average_weight(row)

      if is_binary(key) and key != "" and is_number(value) and is_number(weight) and
           weight > 0.0 do
        Map.update(grouped, key, [{value, weight}], &[{value, weight} | &1])
      else
        grouped
      end
    end)
    |> Enum.map(fn {key, weighted_values} ->
      average =
        weighted_values
        |> OutcomeValue.weighted_average()
        |> clamp_unit_interval()

      {key, average}
    end)
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Map.new()
  end

  def text_by(rows, key_fun, value_fun) do
    rows
    |> Enum.reject(&excluded?/1)
    |> Enum.reduce(%{}, fn row, grouped ->
      key = stable_identifier(key_fun.(row))
      value = value_fun.(row)

      if is_binary(key) and key != "" and is_binary(value) and value != "" do
        Map.update(grouped, key, [value], &[value | &1])
      else
        grouped
      end
    end)
    |> Enum.map(fn {key, values} ->
      value =
        values
        |> Enum.uniq()
        |> Enum.sort()
        |> List.first()

      {key, value}
    end)
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Map.new()
  end

  defp invalid_identity?(row) do
    Enum.any?(@identity_fields, fn field ->
      case Map.get(row, field) do
        value when value in [nil, ""] -> false
        value -> is_nil(stable_identifier(value))
      end
    end)
  end

  defp clamp_unit_interval(value) when is_number(value) do
    value
    |> max(0.0)
    |> min(1.0)
  end
end
