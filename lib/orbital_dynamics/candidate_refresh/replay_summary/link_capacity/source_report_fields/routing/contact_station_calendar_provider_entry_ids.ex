defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.ContactStationCalendarProviderEntryIds do
  @moduledoc false

  def contact_station_calendar_provider_entry_ids(contact, normalization) do
    contact = normalization.stringify_keys(contact)

    [
      contact["station_calendar_provider_entry_id"],
      contact["provider_entry_id"],
      get_in(contact, ["station_calendar_entry", "station_calendar_provider_entry_id"]),
      get_in(contact, ["station_calendar_entry", "provider_entry_id"]),
      get_in(contact, ["source_station_calendar_entry", "station_calendar_provider_entry_id"]),
      get_in(contact, ["source_station_calendar_entry", "provider_entry_id"])
    ]
    |> List.flatten()
    |> Enum.map(&normalization.stable_id_or_nil/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end
end
