defmodule OrbitalDynamics.Communications.ContactFilter.ProviderCounterofferContext do
  @moduledoc false

  alias OrbitalDynamics.Communications.ContactFilter.ContactNormalization

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

  def put(row, candidate, station_state) do
    if context_present?(candidate) or context_present?(station_state) do
      @fields
      |> Enum.reduce(row, fn field, row ->
        maybe_put(row, field, value(field, candidate, station_state))
      end)
      |> maybe_put(
        "provider_counteroffer_start_delta_s",
        start_delta(candidate, station_state)
      )
      |> maybe_put(
        "provider_counteroffer_end_delta_s",
        end_delta(candidate, station_state)
      )
      |> maybe_put(
        "provider_counteroffer_duration_delta_s",
        duration_delta(candidate, station_state)
      )
    else
      row
    end
  end

  def source_value(source, field), do: source_value(source, field, 0)

  defp context_present?(source) when is_map(source) do
    source["required_operator_action"] == "review_provider_counteroffer" or
      Enum.any?(@fields, fn field ->
        context_value_present?(field, source_value(source, field))
      end)
  end

  defp context_present?(_source), do: false

  defp context_value_present?("provider_counteroffer_negotiation_state", value) do
    present?(value) and ContactNormalization.stringify_keys(value) != "unknown"
  end

  defp context_value_present?(_field, value), do: present?(value)

  defp value(field, candidate, station_state) do
    [source_value(candidate, field), source_value(station_state, field)]
    |> Enum.find(&present?/1)
  end

  defp source_value(source, field, depth) when is_map(source) and depth < 4 do
    [
      source[field],
      source_value(source["source_station_calendar_entry"], field, depth + 1)
      | overlap_values(source, field, depth + 1)
    ]
    |> Enum.find(&present?/1)
  end

  defp source_value(_source, _field, _depth), do: nil

  defp overlap_values(
         %{"source_station_calendar_overlaps" => overlaps},
         field,
         depth
       )
       when is_list(overlaps),
       do: Enum.map(overlaps, &source_value(&1, field, depth))

  defp overlap_values(
         %{"source_station_calendar_overlaps" => overlap},
         field,
         depth
       ),
       do: [source_value(overlap, field, depth)]

  defp overlap_values(_source, _field, _depth), do: []

  defp start_delta(candidate, station_state) do
    value("provider_counteroffer_start_delta_s", candidate, station_state) ||
      numeric_delta(
        value("provider_counteroffer_starts_at_s", candidate, station_state),
        candidate["starts_at_s"]
      )
  end

  defp end_delta(candidate, station_state) do
    value("provider_counteroffer_end_delta_s", candidate, station_state) ||
      numeric_delta(
        value("provider_counteroffer_ends_at_s", candidate, station_state),
        candidate["ends_at_s"]
      )
  end

  defp duration_delta(candidate, station_state) do
    value("provider_counteroffer_duration_delta_s", candidate, station_state) ||
      derived_duration_delta(candidate, station_state)
  end

  defp derived_duration_delta(candidate, station_state) do
    with start when is_number(start) <-
           ContactNormalization.numeric_or_nil(candidate["starts_at_s"]),
         finish when is_number(finish) <-
           ContactNormalization.numeric_or_nil(candidate["ends_at_s"]),
         counter_start when is_number(counter_start) <-
           ContactNormalization.numeric_or_nil(
             value("provider_counteroffer_starts_at_s", candidate, station_state)
           ),
         counter_finish when is_number(counter_finish) <-
           ContactNormalization.numeric_or_nil(
             value("provider_counteroffer_ends_at_s", candidate, station_state)
           ) do
      counter_finish - counter_start - (finish - start)
    else
      _value -> nil
    end
  end

  defp numeric_delta(value, base_value) do
    with value when is_number(value) <- ContactNormalization.numeric_or_nil(value),
         base_value when is_number(base_value) <-
           ContactNormalization.numeric_or_nil(base_value) do
      value - base_value
    else
      _value -> nil
    end
  end

  defp present?(value), do: value not in [nil, "", [], %{}]

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
