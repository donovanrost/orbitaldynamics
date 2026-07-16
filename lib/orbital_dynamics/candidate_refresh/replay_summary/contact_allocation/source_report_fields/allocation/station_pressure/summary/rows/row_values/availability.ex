defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.StationPressure.Summary.Rows.RowValues.Availability do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.StationPressure.Summary.Rows.RowValues.Normalization

  def availability_values(row) do
    direct_values =
      row
      |> Map.take(["station_availability", "availability", "station_calendar_status"])
      |> Map.values()
      |> Kernel.++([reason_availability(row["allocation_reason"])])

    source_values =
      source_availability_candidates(row["source_station_calendar_entry"]) ++
        source_availability_candidates(row["source_station_calendar_overlaps"])

    (direct_values ++ List.wrap(row["station_calendar_overlap_availabilities"]) ++ source_values)
    |> Enum.map(&status_token/1)
    |> Enum.filter(&station_availability?/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def station_pressure?(row) do
    pressure_value?(row["station_calendar_overlap_count"]) or
      pressure_value?(row["station_calendar_overlap_availabilities"]) or
      pressure_value?(row["station_calendar_entry_id"]) or
      pressure_value?(row["station_reservation_match_status"]) or
      pressure_value?(row["station_calendar_precedence_rank"]) or
      pressure_value?(row["station_calendar_precedence_availability"]) or
      source_pressure_values(row) != []
  end

  defp source_pressure_values(row) do
    (source_availability_candidates(row["source_station_calendar_entry"]) ++
       source_availability_candidates(row["source_station_calendar_overlaps"]) ++
       [reason_availability(row["allocation_reason"])])
    |> Enum.map(&status_token/1)
    |> Enum.filter(&pressure_availability?/1)
    |> Enum.uniq()
  end

  defp reason_availability(reason) do
    case normalized_token(reason) do
      "ground_station_unavailable" -> "unavailable"
      "ground_station_reserved" -> "reserved"
      "station_reserved" -> "reserved"
      "station_maintenance" -> "maintenance"
      "ground_station_capacity_zero" -> "reduced_capacity"
      _reason -> nil
    end
  end

  defp source_availability_candidates(nil), do: []

  defp source_availability_candidates(entries) when is_list(entries) do
    Enum.flat_map(entries, &source_availability_candidates/1)
  end

  defp source_availability_candidates(%{} = entry) do
    [entry["availability"], entry["status"], entry["station_availability"]]
  end

  defp source_availability_candidates(_entry), do: []

  defp status_token(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> case do
      value when value in ["outage", "down", "offline"] -> "unavailable"
      value -> value
    end
  end

  defp status_token(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> status_token()
  end

  defp status_token(value), do: value

  defp station_availability?(value)
       when value in ["available", "unavailable", "maintenance", "reserved", "reduced_capacity"],
       do: true

  defp station_availability?(_value), do: false

  defp pressure_availability?(value)
       when value in ["unavailable", "maintenance", "reserved", "reduced_capacity"],
       do: true

  defp pressure_availability?(_value), do: false

  defp pressure_value?(nil), do: false
  defp pressure_value?([]), do: false
  defp pressure_value?(value) when is_number(value), do: value > 0
  defp pressure_value?(value) when is_binary(value), do: value != ""
  defp pressure_value?(_value), do: true

  defp normalized_token(value), do: Normalization.normalized_token(value)
end
