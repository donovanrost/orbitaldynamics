defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report.Rows.RowValues.ContactSources.StationEntries do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report.Rows.RowValues.Normalization
  alias __MODULE__.SourceContacts

  def station_calendar_entry_id(row) do
    source_contact = source_contact_with(row, &(&1["station_calendar_entry_id"] || &1["id"]))

    stable_id_or_nil(row["station_calendar_entry_id"]) ||
      stable_id_or_nil(
        get_in(row, ["source_station_calendar_entry", "station_calendar_entry_id"])
      ) ||
      stable_id_or_nil(get_in(row, ["source_station_calendar_entry", "id"])) ||
      stable_id_or_nil(source_contact && source_contact["station_calendar_entry_id"])
  end

  def station_calendar_provider_entry_id(row) do
    source_contact =
      source_contact_with(
        row,
        &(&1["station_calendar_provider_entry_id"] || &1["provider_entry_id"])
      )

    stable_id_or_nil(row["station_calendar_provider_entry_id"] || row["provider_entry_id"]) ||
      stable_id_or_nil(
        get_in(row, ["station_calendar_entry", "station_calendar_provider_entry_id"])
      ) ||
      stable_id_or_nil(get_in(row, ["station_calendar_entry", "provider_entry_id"])) ||
      stable_id_or_nil(
        get_in(row, ["source_station_calendar_entry", "station_calendar_provider_entry_id"])
      ) ||
      stable_id_or_nil(get_in(row, ["source_station_calendar_entry", "provider_entry_id"])) ||
      stable_id_or_nil(
        source_contact &&
          (source_contact["station_calendar_provider_entry_id"] ||
             source_contact["provider_entry_id"])
      )
  end

  def station_reservation_id(row) do
    source_contact =
      source_contact_with(row, &(&1["station_reservation_id"] || &1["reservation_id"]))

    stable_id_or_nil(row["station_reservation_id"] || row["reservation_id"]) ||
      stable_id_or_nil(get_in(row, ["source_station_calendar_entry", "station_reservation_id"])) ||
      stable_id_or_nil(get_in(row, ["source_station_calendar_entry", "reservation_id"])) ||
      stable_id_or_nil(
        source_contact &&
          (source_contact["station_reservation_id"] || source_contact["reservation_id"])
      )
  end

  def source_contact_values(row) do
    SourceContacts.source_contact_values(row)
  end

  defp source_contact_with(row, selector) do
    row
    |> source_contact_values()
    |> Enum.find(fn contact ->
      stable_id_or_nil(selector.(contact)) not in [nil, ""]
    end)
  end

  defp stable_id_or_nil(value), do: Normalization.stable_id_or_nil(value)
end
