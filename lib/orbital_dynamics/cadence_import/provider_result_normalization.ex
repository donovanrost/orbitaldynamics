defmodule OrbitalDynamics.CadenceImport.ProviderResultNormalization do
  @moduledoc false

  @provider_result_fields ~w(contact_result command_result observation_result maneuver_result)
  @provider_result_map_value_keys ~w(result results outcome outcomes status state disposition provider_result provider_results provider_outcome provider_outcomes provider_status provider_state provider_code code reason reasons message messages error errors details metadata provider diagnostics)

  def map_value_keys, do: @provider_result_map_value_keys

  def normalize_artifact_fields(%{} = map) do
    Enum.reduce(@provider_result_fields, map, fn field, acc ->
      case Map.fetch(acc, field) do
        {:ok, value} ->
          case artifact_value(value) do
            nil -> Map.delete(acc, field)
            normalized -> Map.put(acc, field, normalized)
          end

        :error ->
          acc
      end
    end)
  end

  def normalize_artifact_fields(value), do: value

  def artifact_value(nil), do: nil

  def artifact_value(result) when is_binary(result) do
    case String.trim(result) do
      "" -> nil
      _value -> result
    end
  end

  def artifact_value(results) when is_list(results) do
    case result_values(results) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  def artifact_value(%{} = result) do
    case result_values(result) do
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

  defp result_values(result) when is_binary(result) do
    result
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp result_values(values) when is_list(values) do
    Enum.flat_map(values, &result_values/1)
  end

  defp result_values(%{} = result) do
    Enum.flat_map(@provider_result_map_value_keys, fn key ->
      result
      |> Map.get(key)
      |> result_values()
    end)
  end

  defp result_values(nil), do: []

  defp result_values(result) when is_atom(result) do
    result
    |> Atom.to_string()
    |> result_values()
  end

  defp result_values(result)
       when is_integer(result) or is_float(result) or is_boolean(result) do
    result
    |> to_string()
    |> result_values()
  end

  defp result_values(_result), do: []
end
