defmodule OrbitalDynamics.Communications.LinkCapacity.ContactFeedback do
  @moduledoc false

  @provider_result_map_value_keys ~w(result results outcome outcomes status state disposition provider_result provider_results provider_outcome provider_outcomes provider_status provider_state provider_code code reason reasons message messages error errors details metadata provider diagnostics)

  def provider_result_map_value_keys, do: @provider_result_map_value_keys

  def context(contacts) do
    %{
      "contact_success" => aggregate_boolean(contacts, "contact_success"),
      "contact_result" => aggregate_string(contacts, "contact_result"),
      "contact_success_factor" => aggregate_factor(contacts, "contact_success_factor"),
      "contact_success_factor_source" =>
        aggregate_factor_source(
          contacts,
          "contact_success_factor",
          "contact_success_factor_source"
        ),
      "command_success" => aggregate_boolean(contacts, "command_success"),
      "command_result" => aggregate_string(contacts, "command_result"),
      "command_success_factor" => aggregate_factor(contacts, "command_success_factor"),
      "command_success_factor_source" =>
        aggregate_factor_source(
          contacts,
          "command_success_factor",
          "command_success_factor_source"
        )
    }
    |> compact_map()
  end

  def value(contact, key) do
    case Map.fetch(contact, key) do
      {:ok, nil} -> get_in(contact, ["metadata", key])
      {:ok, value} -> value
      :error -> get_in(contact, ["metadata", key])
    end
  end

  defp aggregate_boolean(contacts, key) do
    values =
      contacts
      |> Enum.map(&boolean_feedback_value(&1, key))
      |> Enum.reject(&is_nil/1)

    cond do
      Enum.any?(values, &(&1 == false)) -> false
      Enum.any?(values, &(&1 == true)) -> true
      true -> nil
    end
  end

  defp aggregate_factor(contacts, key) do
    contacts
    |> Enum.map(&numeric_value(value(&1, key)))
    |> Enum.reject(&is_nil/1)
    |> Enum.min(fn -> nil end)
  end

  defp aggregate_factor_source(contacts, factor_key, source_key) do
    contacts
    |> Enum.filter(&is_number(numeric_value(value(&1, factor_key))))
    |> Enum.map(&value(&1, source_key))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> case do
      [source] -> source
      [_source | _rest] -> "mixed_feedback_sources"
      [] -> nil
    end
  end

  defp aggregate_string(contacts, key) do
    contacts
    |> Enum.map(&provider_result_artifact_value(value(&1, key)))
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> case do
      [value] -> value
      [_value | _rest] -> "mixed"
      [] -> nil
    end
  end

  defp provider_result_values(values) when is_list(values) do
    values
    |> Enum.flat_map(&provider_result_values/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp provider_result_values(%{} = result) do
    @provider_result_map_value_keys
    |> Enum.flat_map(fn key -> provider_result_values(Map.get(result, key)) end)
    |> Enum.reject(&(&1 == ""))
  end

  defp provider_result_values(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> []
      normalized -> [normalized]
    end
  end

  defp provider_result_values(nil), do: []

  defp provider_result_values(value) when is_atom(value),
    do: provider_result_values(Atom.to_string(value))

  defp provider_result_values(value), do: provider_result_values(to_string(value))

  defp provider_result_artifact_value(value) do
    case provider_result_values(value) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  defp boolean_feedback_value(contact, key) do
    contact
    |> value(key)
    |> boolean_value()
  end

  defp boolean_value(value) when is_boolean(value), do: value

  defp boolean_value(value) when is_number(value) do
    cond do
      value == 1 -> true
      value == 0 -> false
      true -> nil
    end
  end

  defp boolean_value(value) when is_binary(value) do
    case String.downcase(String.trim(value)) do
      "true" -> true
      "1" -> true
      "false" -> false
      "0" -> false
      _value -> nil
    end
  end

  defp boolean_value(_value), do: nil

  defp numeric_value(value) when is_integer(value) or is_float(value), do: value * 1.0

  defp numeric_value(value) when is_binary(value) do
    value = String.trim(value)

    case Float.parse(value) do
      {number, ""} -> number
      _result -> nil
    end
  end

  defp numeric_value(_value), do: nil

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
