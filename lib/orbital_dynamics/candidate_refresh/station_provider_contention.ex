defmodule OrbitalDynamics.CandidateRefresh.StationProviderContention do
  @moduledoc false

  def values(row, field) do
    [
      get_in(row, ["source_station_calendar_provider_contention", field]),
      get_in(row, [
        "source_station_calendar_entry",
        "source_station_calendar_provider_contention",
        field
      ])
    ]
    |> Enum.concat(overlap_values(row, field))
    |> List.flatten()
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      values -> values
    end
  end

  defp overlap_values(%{"source_station_calendar_overlaps" => overlaps}, field)
       when is_list(overlaps) do
    overlaps
    |> Enum.map(fn
      %{} = overlap ->
        overlap_value(overlap, field)

      _overlap ->
        nil
    end)
  end

  defp overlap_values(_row, _field), do: []

  defp overlap_value(overlap, field) do
    contention_value =
      get_in(overlap, [
        "source_station_calendar_entry",
        "source_station_calendar_provider_contention",
        field
      ])

    entry_field =
      case field do
        "reservation_ids" -> "reservation_id"
        "reserved_by" -> "reserved_by"
        "reservation_statuses" -> "reservation_status"
        "reservation_expires_at_s" -> "reservation_expires_at_s"
        _field -> nil
      end

    entry_values =
      overlap
      |> get_in(["source_station_calendar_entry", "source_station_calendar_entries"])
      |> List.wrap()
      |> Enum.filter(&is_map/1)
      |> Enum.map(&Map.get(&1, entry_field))

    [contention_value | entry_values]
  end

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values), do: Enum.map(values, &encode_value/1)
  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
