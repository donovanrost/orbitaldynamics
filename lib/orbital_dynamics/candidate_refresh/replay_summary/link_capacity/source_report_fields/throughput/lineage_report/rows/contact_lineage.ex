defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Throughput.LineageReport.Rows.ContactLineage do
  @moduledoc false

  import __MODULE__.Normalization,
    only: [sorted_non_empty_values: 1, stable_id_or_nil: 1, stringify_keys: 1]

  def row_contact_ids(row, fields) do
    fields
    |> Enum.flat_map(fn field -> row |> Map.get(field) |> List.wrap() end)
    |> List.flatten()
    |> Enum.map(&source_contact_id/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def row_source_window_ids(row, fields) do
    fields
    |> Enum.flat_map(fn field -> row |> Map.get(field) |> List.wrap() end)
    |> List.flatten()
    |> Enum.flat_map(&contact_source_window_ids/1)
    |> sorted_non_empty_values()
    |> case do
      nil -> nil
      source_window_ids -> source_window_ids
    end
  end

  def row_station_calendar_entry_ids(row, fields) do
    fields
    |> Enum.flat_map(fn field -> row |> Map.get(field) |> List.wrap() end)
    |> List.flatten()
    |> Enum.flat_map(&contact_station_calendar_entry_ids/1)
    |> sorted_non_empty_values()
    |> case do
      nil -> nil
      station_calendar_entry_ids -> station_calendar_entry_ids
    end
  end

  def row_station_calendar_provider_entry_ids(row, fields) do
    fields
    |> Enum.flat_map(fn field -> row |> Map.get(field) |> List.wrap() end)
    |> List.flatten()
    |> Enum.flat_map(&contact_station_calendar_provider_entry_ids/1)
    |> sorted_non_empty_values()
    |> case do
      nil -> nil
      station_calendar_provider_entry_ids -> station_calendar_provider_entry_ids
    end
  end

  defp source_contact_id(%{} = contact) do
    contact = stringify_keys(contact)

    [
      contact["id"],
      contact["activity_id"],
      contact["contact_id"],
      get_in(contact, ["activity_context", "id"]),
      get_in(contact, ["activity_context", "activity_id"])
    ]
    |> Enum.find_value(&stable_id_or_nil/1)
  end

  defp source_contact_id(value), do: stable_id_or_nil(value)

  defp contact_source_window_ids(%{} = contact) do
    contact = stringify_keys(contact)

    [
      contact["source_window_id"],
      get_in(contact, ["source_window", "id"]),
      get_in(contact, ["activity_context", "source_window_id"])
    ]
    |> List.flatten()
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp contact_source_window_ids(_contact), do: []

  defp contact_station_calendar_entry_ids(%{} = contact) do
    contact = stringify_keys(contact)

    [
      contact["station_calendar_entry_id"],
      get_in(contact, ["station_calendar_entry", "station_calendar_entry_id"]),
      get_in(contact, ["station_calendar_entry", "id"]),
      get_in(contact, ["source_station_calendar_entry", "station_calendar_entry_id"]),
      get_in(contact, ["source_station_calendar_entry", "id"])
    ]
    |> List.flatten()
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp contact_station_calendar_entry_ids(_contact), do: []

  defp contact_station_calendar_provider_entry_ids(%{} = contact) do
    contact = stringify_keys(contact)

    [
      contact["station_calendar_provider_entry_id"],
      contact["provider_entry_id"],
      get_in(contact, ["station_calendar_entry", "station_calendar_provider_entry_id"]),
      get_in(contact, ["station_calendar_entry", "provider_entry_id"]),
      get_in(contact, ["source_station_calendar_entry", "station_calendar_provider_entry_id"]),
      get_in(contact, ["source_station_calendar_entry", "provider_entry_id"])
    ]
    |> List.flatten()
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp contact_station_calendar_provider_entry_ids(_contact), do: []
end
