defmodule OrbitalDynamics.Timeline.ProviderResult do
  @moduledoc false

  def execution_failure_reason(activity, "contact", map_value_keys) do
    cond do
      failure?(Map.get(activity, "contact_result"), map_value_keys) ->
        "contact_result_#{failure_token(activity["contact_result"], map_value_keys)}_requires_review"

      Map.get(activity, "contact_success") == false ->
        "contact_success_false_requires_review"

      true ->
        nil
    end
  end

  def execution_failure_reason(activity, kind, map_value_keys)
      when kind in ["command", "health_check"] do
    cond do
      failure?(Map.get(activity, "command_result"), map_value_keys) ->
        "command_result_#{failure_token(activity["command_result"], map_value_keys)}_requires_review"

      Map.get(activity, "command_success") == false ->
        "command_success_false_requires_review"

      failure?(Map.get(activity, "contact_result"), map_value_keys) ->
        "contact_result_#{failure_token(activity["contact_result"], map_value_keys)}_requires_review"

      Map.get(activity, "contact_success") == false ->
        "contact_success_false_requires_review"

      true ->
        nil
    end
  end

  def execution_failure_reason(_activity, _kind, _map_value_keys), do: nil

  def failure?(result, map_value_keys) do
    result
    |> outcomes(map_value_keys)
    |> Enum.member?(:failure)
  end

  def artifact_value(result, map_value_keys)

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

  defp failure_token(result, map_value_keys) do
    result
    |> values(map_value_keys)
    |> Enum.find_value(fn token ->
      normalized = token(token)
      if token_outcome(normalized) == :failure, do: normalized
    end) || "failure"
  end

  defp outcomes(result, map_value_keys) do
    result
    |> values(map_value_keys)
    |> Enum.map(&token/1)
    |> Enum.map(&token_outcome/1)
    |> Enum.reject(&(&1 == :unknown))
  end

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

  defp token(token) when is_binary(token) do
    token
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  defp token_outcome(value)
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
            ],
       do: :failure

  defp token_outcome(value)
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
            ],
       do: :success

  defp token_outcome(_value), do: :unknown
end
