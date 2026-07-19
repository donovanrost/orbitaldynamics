defmodule OrbitalDynamics.TimelineFeedback.ProviderResult do
  @moduledoc false

  def outcome(result, map_value_keys) do
    outcomes =
      result
      |> values(map_value_keys)
      |> Enum.map(&token_outcome/1)
      |> Enum.reject(&(&1 == :unknown))

    cond do
      Enum.member?(outcomes, :failure) -> :failure
      Enum.member?(outcomes, :success) -> :success
      true -> :unknown
    end
  end

  def artifact_value(nil, _map_value_keys), do: nil

  def artifact_value(result, _map_value_keys) when is_binary(result) do
    case String.trim(result) do
      "" -> nil
      _value -> result
    end
  end

  def artifact_value(results, map_value_keys) when is_list(results) do
    case values(results, map_value_keys) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  def artifact_value(%{} = result, map_value_keys) do
    case values(result, map_value_keys) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  def artifact_value(result, _map_value_keys) when is_integer(result),
    do: Integer.to_string(result)

  def artifact_value(result, _map_value_keys) when is_float(result),
    do: Float.to_string(result)

  def artifact_value(result, _map_value_keys) when is_boolean(result),
    do: Atom.to_string(result)

  def artifact_value(result, map_value_keys) when is_atom(result) do
    result
    |> Atom.to_string()
    |> artifact_value(map_value_keys)
  end

  def artifact_value(_result, _map_value_keys), do: nil

  defp values(result, _map_value_keys) when is_binary(result) do
    result
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp values(values, map_value_keys) when is_list(values) do
    Enum.flat_map(values, &values(&1, map_value_keys))
  end

  defp values(%{} = result, map_value_keys) do
    Enum.flat_map(map_value_keys, fn key ->
      result
      |> Map.get(key)
      |> values(map_value_keys)
    end)
  end

  defp values(nil, _map_value_keys), do: []

  defp values(result, map_value_keys) when is_atom(result) do
    result
    |> Atom.to_string()
    |> values(map_value_keys)
  end

  defp values(_result, _map_value_keys), do: []

  defp token_outcome(result) when is_binary(result) do
    case token(result) do
      value
      when value in [
             "rejected",
             "failed",
             "failure",
             "timeout",
             "timed_out",
             "aborted",
             "error",
             "dropped",
             "lost",
             "missed",
             "canceled",
             "cancelled",
             "no_contact"
           ] ->
        :failure

      value
      when value in [
             "accepted",
             "acknowledged",
             "completed",
             "executed",
             "succeeded",
             "success",
             "ok",
             "acquired",
             "established",
             "delivered"
           ] ->
        :success

      _value ->
        :unknown
    end
  end

  defp token(result) when is_binary(result) do
    result
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end
end
