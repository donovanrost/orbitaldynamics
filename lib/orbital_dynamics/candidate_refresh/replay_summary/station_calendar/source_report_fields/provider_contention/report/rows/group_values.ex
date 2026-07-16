defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.ProviderContention.Report.Rows.GroupValues do
  @moduledoc false

  alias __MODULE__.{Normalization, SourceEntries}

  def ground_station_ids(%{} = group) do
    group = stringify_keys(group)

    group_station_id =
      stable_id_or_nil(group["ground_station_id"] || SourceEntries.nested_station_id(group))

    source_station_ids =
      group
      |> source_entries()
      |> Enum.map(fn entry ->
        stable_id_or_nil(entry["ground_station_id"] || SourceEntries.nested_station_id(entry))
      end)

    [group_station_id | source_station_ids]
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  def ground_station_ids(_group), do: []

  def group_capacity_fractions(group) do
    group
    |> stringify_keys()
    |> SourceEntries.capacity_fraction()
    |> List.wrap()
    |> normalize_number_list()
    |> case do
      nil -> []
      capacity_fractions -> capacity_fractions
    end
  end

  def group_source_entry_ids(group) do
    SourceEntries.source_entry_ids(group)
  end

  def group_provider_entry_ids(group) do
    group = stringify_keys(group)

    [
      group["provider_entry_ids"],
      group["station_calendar_provider_entry_ids"],
      group["provider_calendar_contention_provider_entry_ids"],
      group
      |> SourceEntries.provider_entry_ids()
    ]
    |> List.flatten()
    |> Normalization.sorted_string_values()
  end

  def source_entries(%{} = group) do
    SourceEntries.source_entries(group)
  end

  def source_entries(_group), do: []

  def provider_ids(values) do
    values
    |> group_values()
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
  end

  def normalize_number_list(value), do: Normalization.normalize_number_list(value)
  def stable_id_or_nil(value), do: Normalization.stable_id_or_nil(value)
  def stringify_keys(value), do: Normalization.stringify_keys(value)

  def directions(group) do
    [
      group["directions"],
      group["provider_calendar_contention_directions"],
      group["direction"],
      group["station_calendar_directions"],
      group
      |> source_entries()
      |> Enum.flat_map(&SourceEntries.station_directions/1)
    ]
    |> List.flatten()
    |> Enum.map(&Normalization.encode_value/1)
    |> Enum.map(&Normalization.normalize_direction/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      directions -> directions
    end
  end

  defp group_values(values) do
    values
    |> List.wrap()
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&Normalization.encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
  end
end
