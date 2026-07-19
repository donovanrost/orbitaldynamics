defmodule OrbitalDynamics.Communications.ContactIntent.ProviderResult do
  @moduledoc false

  @map_value_keys ~w(result results outcome outcomes status state disposition provider_result provider_results provider_outcome provider_outcomes provider_status provider_state provider_code code reason reasons message messages error errors details metadata provider diagnostics)

  def map_value_keys, do: @map_value_keys

  def artifact_value(nil), do: nil

  def artifact_value(result) when is_binary(result) do
    case String.trim(result) do
      "" -> nil
      _value -> result
    end
  end

  def artifact_value(results) when is_list(results) do
    case values(results) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  def artifact_value(%{} = result) do
    case values(result) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
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

  defp values(result) when is_binary(result) do
    result
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp values(values) when is_list(values) do
    Enum.flat_map(values, &values/1)
  end

  defp values(%{} = result) do
    Enum.flat_map(@map_value_keys, fn key ->
      result
      |> Map.get(key)
      |> values()
    end)
  end

  defp values(nil), do: []

  defp values(result) when is_atom(result) do
    result
    |> Atom.to_string()
    |> values()
  end

  defp values(result) when is_integer(result) or is_float(result) or is_boolean(result) do
    result
    |> to_string()
    |> values()
  end

  defp values(_result), do: []
end
