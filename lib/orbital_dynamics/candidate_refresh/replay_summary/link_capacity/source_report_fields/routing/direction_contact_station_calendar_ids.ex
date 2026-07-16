defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.DirectionContactStationCalendarIds do
  @moduledoc false

  def contact_station_calendar_entry_ids(contact, normalization) do
    [
      contact["station_calendar_entry_id"],
      contact["station_calendar_entry_ids"],
      get_in(contact, ["station_calendar_entry", "station_calendar_entry_id"]),
      get_in(contact, ["station_calendar_entry", "id"]),
      get_in(contact, ["source_station_calendar_entry", "station_calendar_entry_id"]),
      get_in(contact, ["source_station_calendar_entry", "id"])
    ]
    |> contact_ids(normalization)
  end

  def contact_station_calendar_provider_entry_ids(contact, normalization) do
    [
      contact["station_calendar_provider_entry_id"],
      contact["station_calendar_provider_entry_ids"],
      contact["provider_entry_id"],
      contact["provider_entry_ids"],
      get_in(contact, ["station_calendar_entry", "station_calendar_provider_entry_id"]),
      get_in(contact, ["station_calendar_entry", "provider_entry_id"]),
      get_in(contact, ["source_station_calendar_entry", "station_calendar_provider_entry_id"]),
      get_in(contact, ["source_station_calendar_entry", "provider_entry_id"])
    ]
    |> contact_ids(normalization)
  end

  defp contact_ids(values, normalization) do
    values
    |> List.flatten()
    |> Enum.map(&normalization.stable_id_or_nil/1)
    |> Enum.reject(&(&1 in [nil, ""]))
  end
end
