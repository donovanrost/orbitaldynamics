defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.ProviderContention.Report.Rows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Counts
  alias __MODULE__.GroupValues

  def ground_station_ids(%{} = group) do
    GroupValues.ground_station_ids(group)
  end

  def ground_station_ids(_group), do: []

  def provider_entry_ids_by_values(groups, key_fun) do
    groups
    |> Enum.reduce(%{}, fn group, acc ->
      provider_entry_ids = group_provider_entry_ids(group)
      keys = key_fun.(group)

      if provider_entry_ids == [] or keys == [] do
        acc
      else
        Enum.reduce(keys, acc, fn key, acc ->
          Map.update(acc, key, provider_entry_ids, fn current ->
            (current ++ provider_entry_ids)
            |> Enum.uniq()
            |> Enum.sort()
          end)
        end)
      end
    end)
    |> non_empty_map()
  end

  def capacity_fractions_by_values(groups, key_fun) do
    groups
    |> Enum.reduce(%{}, fn group, acc ->
      capacity_fractions = group_capacity_fractions(group)
      keys = key_fun.(group)

      if capacity_fractions == [] or keys == [] do
        acc
      else
        Enum.reduce(keys, acc, fn key, acc ->
          Map.update(acc, key, capacity_fractions, fn current ->
            (current ++ capacity_fractions)
            |> Enum.uniq()
            |> Enum.sort()
          end)
        end)
      end
    end)
    |> non_empty_map()
  end

  def group_capacity_fractions(group) do
    GroupValues.group_capacity_fractions(group)
  end

  def values_by_direction(groups, value_fun) do
    groups
    |> Enum.reduce(%{}, fn group, acc ->
      directions = directions(group) || []
      values = value_fun.(group)

      if directions == [] or values == [] do
        acc
      else
        Enum.reduce(directions, acc, fn direction, acc ->
          Map.update(acc, direction, values, fn current ->
            (current ++ values)
            |> Enum.uniq()
            |> Enum.sort()
          end)
        end)
      end
    end)
    |> non_empty_map()
  end

  def numeric_values_by_direction(groups, value_fun) do
    groups
    |> Enum.reduce(%{}, fn group, acc ->
      directions = directions(group) || []
      values = value_fun.(group)

      if directions == [] or values == [] do
        acc
      else
        Enum.reduce(directions, acc, fn direction, acc ->
          Map.update(acc, direction, values, fn current ->
            (current ++ values)
            |> Enum.uniq()
            |> Enum.sort()
          end)
        end)
      end
    end)
    |> non_empty_map()
  end

  def group_source_entry_ids(group) do
    GroupValues.group_source_entry_ids(group)
  end

  def group_provider_entry_ids(group) do
    GroupValues.group_provider_entry_ids(group)
  end

  def source_entries(%{} = group) do
    GroupValues.source_entries(group)
  end

  def source_entries(_group), do: []

  def provider_ids(values) do
    GroupValues.provider_ids(values)
  end

  def count_values(values), do: Counts.encoded_values(values)

  def normalize_number_list(value), do: GroupValues.normalize_number_list(value)

  def stable_id_or_nil(value), do: GroupValues.stable_id_or_nil(value)

  def stringify_keys(value), do: GroupValues.stringify_keys(value)

  def directions(group) do
    GroupValues.directions(group)
  end

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
