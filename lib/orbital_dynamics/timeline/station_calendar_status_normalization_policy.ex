defmodule OrbitalDynamics.Timeline.StationCalendarStatusNormalizationPolicy do
  @moduledoc false

  def normalize(activity) do
    activity
    |> normalize_status_field("station_availability")
    |> normalize_status_field("station_calendar_status")
    |> normalize_status_field("station_contention_status")
    |> normalize_status_field("station_reservation_status")
    |> normalize_status_field("station_reservation_match_status")
    |> normalize_status_list_field("station_calendar_overlap_availabilities")
    |> normalize_status_list_field("station_calendar_reservation_statuses")
    |> normalize_source_station_calendar_field("source_station_calendar_entry")
    |> normalize_source_station_calendar_field("source_station_calendar_overlaps")
  end

  defp normalize_status_field(activity, field) do
    case Map.fetch(activity, field) do
      {:ok, value} when value in [nil, ""] ->
        activity

      {:ok, value} ->
        Map.put(activity, field, normalize_status_token(value))

      :error ->
        activity
    end
  end

  defp normalize_status_list_field(activity, field) do
    case Map.fetch(activity, field) do
      {:ok, values} when is_list(values) ->
        values =
          values
          |> Enum.map(&normalize_status_token/1)
          |> Enum.reject(&(&1 in [nil, ""]))

        Map.put(activity, field, values)

      {:ok, value} when value not in [nil, ""] ->
        Map.put(activity, field, [normalize_status_token(value)])

      _missing_or_empty ->
        activity
    end
  end

  defp normalize_source_station_calendar_field(activity, field) do
    case Map.fetch(activity, field) do
      {:ok, values} when is_list(values) ->
        Map.put(activity, field, Enum.map(values, &normalize_source_station_calendar/1))

      {:ok, value} ->
        Map.put(activity, field, normalize_source_station_calendar(value))

      :error ->
        activity
    end
  end

  defp normalize_source_station_calendar(%{} = source) do
    source
    |> normalize_status_field("availability")
    |> normalize_status_field("status")
    |> normalize_status_field("station_availability")
    |> normalize_status_field("station_calendar_status")
    |> normalize_status_field("station_contention_status")
    |> normalize_status_field("reservation_status")
    |> normalize_status_field("station_reservation_status")
    |> normalize_status_field("reservation_match_status")
    |> normalize_status_field("station_reservation_match_status")
  end

  defp normalize_source_station_calendar(value), do: value

  defp normalize_status_token(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  defp normalize_status_token(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> normalize_status_token()
  end

  defp normalize_status_token(value), do: value
end
