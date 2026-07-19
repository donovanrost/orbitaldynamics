defmodule OrbitalDynamics.Communications.ContactContention.FeedbackContext do
  @moduledoc false

  alias OrbitalDynamics.Communications.ContactContention.ContactNormalization

  def build(contacts, provider_result_map_value_keys, contact_id) do
    %{
      "contact_success" => aggregate_boolean_feedback(contacts, "contact_success"),
      "contact_result" =>
        aggregate_string_feedback(contacts, "contact_result", provider_result_map_value_keys),
      "contact_success_factor" => aggregate_factor_feedback(contacts, "contact_success_factor"),
      "contact_success_factor_source" =>
        aggregate_factor_source(
          contacts,
          "contact_success_factor",
          "contact_success_factor_source"
        ),
      "command_success" => aggregate_boolean_feedback(contacts, "command_success"),
      "command_result" =>
        aggregate_string_feedback(contacts, "command_result", provider_result_map_value_keys),
      "command_success_factor" => aggregate_factor_feedback(contacts, "command_success_factor"),
      "command_success_factor_source" =>
        aggregate_factor_source(
          contacts,
          "command_success_factor",
          "command_success_factor_source"
        ),
      "actual_throughput_mb" => aggregate_actual_throughput_mb(contacts),
      "actual_data_rate_throughput_derivations" =>
        aggregate_actual_data_rate_throughput_derivations(contacts, contact_id)
    }
    |> ContactNormalization.compact_map()
  end

  def fields do
    [
      "contact_success",
      "contact_result",
      "contact_success_factor",
      "contact_success_factor_source",
      "command_success",
      "command_result",
      "command_success_factor",
      "command_success_factor_source",
      "actual_throughput_mb",
      "actual_data_rate_throughput_derivations"
    ]
  end

  def actual_throughput_value(contact) do
    explicit_actual_throughput_value(contact) || actual_data_rate_derived_throughput_mb(contact)
  end

  defp actual_data_rate_throughput_derivation(contact) do
    duration_s = actual_duration_s(contact)

    cond do
      is_number(explicit_actual_throughput_value(contact)) ->
        nil

      not is_number(duration_s) or duration_s <= 0.0 ->
        nil

      rate_mb_s = actual_data_rate_mb_s(contact) ->
        normalized_rate_mb_s = max(rate_mb_s, 0.0)

        %{
          "derivation" => "actual_data_rate_mb_s * duration_s",
          "rate_unit" => "MB/s",
          "actual_data_rate_mb_s" => normalized_rate_mb_s,
          "duration_s" => duration_s,
          "actual_throughput_mb" => normalized_rate_mb_s * duration_s
        }

      rate_mbps = actual_data_rate_mbps(contact) ->
        normalized_rate_mbps = max(rate_mbps, 0.0)

        %{
          "derivation" => "actual_data_rate_mbps * duration_s / 8",
          "rate_unit" => "Mbps",
          "actual_data_rate_mbps" => normalized_rate_mbps,
          "duration_s" => duration_s,
          "actual_throughput_mb" => normalized_rate_mbps * duration_s / 8.0
        }

      true ->
        nil
    end
  end

  defp aggregate_boolean_feedback(contacts, key) do
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

  defp aggregate_factor_feedback(contacts, key) do
    contacts
    |> Enum.map(&numeric_or_nil(contact_value(&1, key)))
    |> Enum.reject(&is_nil/1)
    |> Enum.min(fn -> nil end)
  end

  defp aggregate_factor_source(contacts, factor_key, source_key) do
    contacts
    |> Enum.filter(&is_number(numeric_or_nil(contact_value(&1, factor_key))))
    |> Enum.map(&contact_value(&1, source_key))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> case do
      [source] -> source
      [_source | _rest] -> "mixed_feedback_sources"
      [] -> nil
    end
  end

  defp aggregate_string_feedback(contacts, key, provider_result_map_value_keys) do
    contacts
    |> Enum.map(
      &provider_result_artifact_value(
        contact_value(&1, key),
        provider_result_map_value_keys
      )
    )
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> case do
      [value] -> value
      [_value | _rest] -> "mixed"
      [] -> nil
    end
  end

  defp provider_result_values(values, provider_result_map_value_keys) when is_list(values) do
    values
    |> Enum.flat_map(&provider_result_values(&1, provider_result_map_value_keys))
    |> Enum.reject(&(&1 == ""))
  end

  defp provider_result_values(%{} = result, provider_result_map_value_keys) do
    provider_result_map_value_keys
    |> Enum.flat_map(fn key ->
      provider_result_values(Map.get(result, key), provider_result_map_value_keys)
    end)
    |> Enum.reject(&(&1 == ""))
  end

  defp provider_result_values(value, _provider_result_map_value_keys)
       when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> []
      normalized -> [normalized]
    end
  end

  defp provider_result_values(nil, _provider_result_map_value_keys), do: []

  defp provider_result_values(value, provider_result_map_value_keys) when is_atom(value),
    do: provider_result_values(Atom.to_string(value), provider_result_map_value_keys)

  defp provider_result_values(value, provider_result_map_value_keys),
    do: provider_result_values(to_string(value), provider_result_map_value_keys)

  defp provider_result_artifact_value(value, provider_result_map_value_keys) do
    case provider_result_values(value, provider_result_map_value_keys) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  defp aggregate_actual_throughput_mb(contacts) do
    contacts
    |> Enum.map(&actual_throughput_value/1)
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> nil
      values -> Enum.sum(values)
    end
  end

  defp aggregate_actual_data_rate_throughput_derivations(contacts, contact_id) do
    contacts
    |> Enum.map(fn contact ->
      case actual_data_rate_throughput_derivation(contact) do
        %{} = derivation ->
          derivation
          |> Map.put("contact_id", contact_id.(contact))

        _derivation ->
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> nil
      derivations -> derivations
    end
  end

  defp contact_value(contact, key) do
    case Map.fetch(contact, key) do
      {:ok, nil} -> get_in(contact, ["metadata", key])
      {:ok, value} -> value
      :error -> get_in(contact, ["metadata", key])
    end
  end

  defp boolean_feedback_value(contact, key) do
    contact
    |> contact_value(key)
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

  defp explicit_actual_throughput_value(contact) do
    first_number([
      contact["actual_throughput_mb"],
      contact["actual_downlink_mb"],
      contact["actual_data_volume_mb"],
      contact["delivered_data_mb"],
      contact["received_data_mb"],
      get_in(contact, ["throughput_model", "actual_throughput_mb"]),
      get_in(contact, ["throughput_model", "actual_downlink_mb"]),
      get_in(contact, ["throughput_model", "actual_data_volume_mb"]),
      get_in(contact, ["throughput_model", "delivered_data_mb"]),
      get_in(contact, ["throughput_model", "received_data_mb"])
    ])
  end

  defp actual_data_rate_derived_throughput_mb(contact) do
    case actual_data_rate_throughput_derivation(contact) do
      %{"actual_throughput_mb" => actual_throughput_mb} when is_number(actual_throughput_mb) ->
        actual_throughput_mb

      _derivation ->
        nil
    end
  end

  defp actual_data_rate_mb_s(contact) do
    first_number([
      contact["actual_data_rate_mb_s"],
      contact["actual_downlink_rate_mb_s"],
      contact["delivered_rate_mb_s"],
      contact["received_rate_mb_s"],
      get_in(contact, ["throughput_model", "actual_data_rate_mb_s"]),
      get_in(contact, ["throughput_model", "actual_downlink_rate_mb_s"]),
      get_in(contact, ["throughput_model", "delivered_rate_mb_s"]),
      get_in(contact, ["throughput_model", "received_rate_mb_s"])
    ])
  end

  defp actual_data_rate_mbps(contact) do
    first_number([
      contact["actual_data_rate_mbps"],
      contact["actual_downlink_rate_mbps"],
      contact["delivered_rate_mbps"],
      contact["received_rate_mbps"],
      get_in(contact, ["throughput_model", "actual_data_rate_mbps"]),
      get_in(contact, ["throughput_model", "actual_downlink_rate_mbps"]),
      get_in(contact, ["throughput_model", "delivered_rate_mbps"]),
      get_in(contact, ["throughput_model", "received_rate_mbps"])
    ])
  end

  defp actual_duration_s(contact) do
    first_number([
      contact["actual_duration_s"],
      contact["actual_contact_duration_s"],
      get_in(contact, ["throughput_model", "actual_duration_s"]),
      get_in(contact, ["throughput_model", "actual_contact_duration_s"])
    ]) || contact_duration_s(contact)
  end

  defp contact_duration_s(contact) do
    first_number([
      contact["duration_s"],
      contact["contact_duration_s"],
      contact["scheduled_duration_s"],
      get_in(contact, ["throughput_model", "duration_s"]),
      get_in(contact, ["throughput_model", "contact_duration_s"]),
      get_in(contact, ["throughput_model", "scheduled_duration_s"])
    ]) || interval_duration_s(contact)
  end

  defp interval_duration_s(contact) do
    starts_at_s = numeric_or_nil(contact["starts_at_s"])
    ends_at_s = numeric_or_nil(contact["ends_at_s"])

    if is_number(starts_at_s) and is_number(ends_at_s) do
      ends_at_s - starts_at_s
    end
  end

  defp first_number(values), do: ContactNormalization.first_number(values)
  defp numeric_or_nil(value), do: ContactNormalization.numeric_or_nil(value)
end
