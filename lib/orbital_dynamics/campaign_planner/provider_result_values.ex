defmodule OrbitalDynamics.CampaignPlanner.ProviderResultValues do
  @moduledoc false

  @map_value_keys ~w(result results outcome outcomes status state disposition provider_result provider_results provider_outcome provider_outcomes provider_status provider_state provider_code code reason reasons message messages error errors details metadata provider diagnostics)

  def success_value(result) do
    outcomes =
      result
      |> values()
      |> Enum.map(&token_success_value/1)
      |> Enum.reject(&(&1 == :unknown))

    cond do
      Enum.member?(outcomes, :failure) -> :failure
      Enum.member?(outcomes, :success) -> :success
      true -> :unknown
    end
  end

  def values(result) when is_binary(result) do
    result
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  def values(values) when is_list(values), do: Enum.flat_map(values, &values/1)

  def values(%{} = result) do
    Enum.flat_map(@map_value_keys, fn key ->
      result
      |> Map.get(key)
      |> values()
    end)
  end

  def values(nil), do: []

  def values(result) when is_atom(result) do
    result
    |> Atom.to_string()
    |> values()
  end

  def values(_result), do: []

  def artifact_value(nil), do: nil

  def artifact_value(result) when is_binary(result) do
    case String.trim(result) do
      "" -> nil
      _value -> result
    end
  end

  def artifact_value(results) when is_list(results) do
    results
    |> values()
    |> join_or_nil()
  end

  def artifact_value(%{} = result) do
    result
    |> values()
    |> join_or_nil()
  end

  def artifact_value(result) when is_integer(result), do: Integer.to_string(result)
  def artifact_value(result) when is_float(result), do: Float.to_string(result)
  def artifact_value(result) when is_boolean(result), do: Atom.to_string(result)

  def artifact_value(result) when is_atom(result) do
    result
    |> Atom.to_string()
    |> artifact_value()
  end

  def artifact_value(_result), do: nil

  def artifact_string?(value) when is_binary(value), do: String.trim(value) != ""
  def artifact_string?(_value), do: false

  def token_success_value(result) when is_binary(result) do
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

  def token(result) when is_binary(result) do
    result
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  defp join_or_nil([]), do: nil
  defp join_or_nil(values), do: Enum.join(values, ",")
end
