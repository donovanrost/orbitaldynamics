defmodule OrbitalDynamics.Communications.ContactAllocation.ProviderCounteroffer do
  @moduledoc false

  @fields ~w(
    provider_counteroffer_id
    provider_counteroffer_status
    provider_counteroffer_negotiation_state
    provider_counteroffer_reason_code
    provider_counteroffer_cost_delta
    provider_counteroffer_lock_deadline_s
    provider_counteroffer_starts_at_s
    provider_counteroffer_ends_at_s
    provider_counteroffer_start_delta_s
    provider_counteroffer_end_delta_s
    provider_counteroffer_duration_delta_s
  )

  def fields, do: @fields

  def context(row) do
    if context_present?(row) do
      @fields
      |> Enum.reduce(%{}, fn field, context ->
        put_value(context, field, value(row, field))
      end)
      |> put_value("provider_counteroffer_start_delta_s", start_delta(row))
      |> put_value("provider_counteroffer_end_delta_s", end_delta(row))
      |> put_value("provider_counteroffer_duration_delta_s", duration_delta(row))
      |> compact_map()
    else
      %{}
    end
  end

  defp context_present?(row) do
    row["required_operator_action"] == "review_provider_counteroffer" or
      Enum.any?(@fields, fn field ->
        context_value_present?(field, value(row, field))
      end)
  end

  defp value(row, field), do: source_value(row, field)
  defp source_value(source, field), do: source_value(source, field, 0)

  defp source_value(source, field, depth) when is_map(source) and depth < 4 do
    [
      source[field],
      source_value(source["source_station_calendar_entry"], field, depth + 1)
      | source_station_calendar_overlap_values(source, field, depth + 1)
    ]
    |> Enum.find(&value_present?/1)
  end

  defp source_value(_source, _field, _depth), do: nil

  defp source_station_calendar_overlap_values(
         %{"source_station_calendar_overlaps" => overlaps},
         field,
         depth
       )
       when is_list(overlaps),
       do: Enum.map(overlaps, &source_value(&1, field, depth))

  defp source_station_calendar_overlap_values(
         %{"source_station_calendar_overlaps" => overlap},
         field,
         depth
       ),
       do: [source_value(overlap, field, depth)]

  defp source_station_calendar_overlap_values(_row, _field, _depth), do: []

  defp start_delta(row) do
    value(row, "provider_counteroffer_start_delta_s") ||
      numeric_delta(value(row, "provider_counteroffer_starts_at_s"), row["starts_at_s"])
  end

  defp end_delta(row) do
    value(row, "provider_counteroffer_end_delta_s") ||
      numeric_delta(value(row, "provider_counteroffer_ends_at_s"), row["ends_at_s"])
  end

  defp duration_delta(row) do
    value(row, "provider_counteroffer_duration_delta_s") ||
      derived_duration_delta(row)
  end

  defp derived_duration_delta(row) do
    with start when is_number(start) <- numeric_or_nil(row["starts_at_s"]),
         finish when is_number(finish) <- numeric_or_nil(row["ends_at_s"]),
         counter_start when is_number(counter_start) <-
           numeric_or_nil(value(row, "provider_counteroffer_starts_at_s")),
         counter_finish when is_number(counter_finish) <-
           numeric_or_nil(value(row, "provider_counteroffer_ends_at_s")) do
      counter_finish - counter_start - (finish - start)
    else
      _value -> nil
    end
  end

  defp numeric_delta(value, base_value) do
    with value when is_number(value) <- numeric_or_nil(value),
         base_value when is_number(base_value) <- numeric_or_nil(base_value) do
      value - base_value
    else
      _value -> nil
    end
  end

  defp put_value(context, _field, value) when value in [nil, "", [], %{}], do: context
  defp put_value(context, field, value), do: Map.put(context, field, value)

  defp value_present?(value), do: value not in [nil, "", [], %{}]

  defp context_value_present?("provider_counteroffer_negotiation_state", value),
    do: value_present?(value) and stringify(value) != "unknown"

  defp context_value_present?(_field, value), do: value_present?(value)

  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value * 1.0

  defp numeric_or_nil(value) when is_binary(value) do
    value = String.trim(value)

    case Float.parse(value) do
      {number, ""} -> number
      _result -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp stringify(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
