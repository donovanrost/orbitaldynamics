defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.StationPressure.Summary.Rows.Aggregation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common

  alias __MODULE__.FallbackCounts

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.StationPressure.Summary.Rows.RowValues

  import Common, only: [sorted_string_values: 1]

  def contact_id_count(rows) do
    rows
    |> Enum.map(&RowValues.summary_contact_id/1)
    |> sorted_non_empty_values()
    |> case do
      nil -> 0
      contact_ids -> length(contact_ids)
    end
  end

  def fallback_contact_count(report) do
    FallbackCounts.fallback_contact_count(report)
  end

  def fallback_review_contact_count(report) do
    FallbackCounts.fallback_review_contact_count(report)
  end

  def contact_ids_by_direction_and_station_from_rows(rows) do
    rows
    |> Enum.reduce(%{}, fn row, acc ->
      direction = RowValues.summary_direction(row)
      station_id = RowValues.group_key(row, "ground_station_id")
      contact_id = RowValues.summary_contact_id(row)

      if direction in [nil, ""] or station_id in [nil, ""] or contact_id in [nil, ""] do
        acc
      else
        Map.update(acc, direction, %{station_id => [contact_id]}, fn station_map ->
          Map.update(station_map, station_id, [contact_id], fn contact_ids ->
            [contact_id | contact_ids]
          end)
        end)
      end
    end)
    |> Map.new(fn {direction, station_map} ->
      {direction, map_value_lists(station_map)}
    end)
    |> non_empty_map()
  end

  def id_map_counts(%{} = contact_ids_by_key) do
    contact_ids_by_key
    |> Enum.map(fn {key, contact_ids} ->
      {to_string(key), contact_ids |> List.wrap() |> sorted_non_empty_values()}
    end)
    |> Enum.reject(fn {key, contact_ids} -> key in [nil, ""] or contact_ids in [nil, []] end)
    |> Map.new(fn {key, contact_ids} -> {key, length(contact_ids)} end)
    |> non_empty_map()
  end

  def id_map_counts(_contact_ids_by_key), do: nil

  def grouped_contact_counts(pairs) do
    pairs
    |> Enum.reject(fn {key, contact_id} -> key in [nil, ""] or contact_id in [nil, ""] end)
    |> Enum.group_by(fn {key, _contact_id} -> key end, fn {_key, contact_id} -> contact_id end)
    |> Map.new(fn {key, contact_ids} ->
      {key, contact_ids |> sorted_non_empty_values() |> length()}
    end)
    |> non_empty_map()
  end

  def grouped_contact_ids(pairs) do
    pairs
    |> Enum.reject(fn {key, contact_id} -> key in [nil, ""] or contact_id in [nil, ""] end)
    |> Enum.group_by(fn {key, _contact_id} -> key end, fn {_key, contact_id} -> contact_id end)
    |> Map.new(fn {key, contact_ids} -> {key, sorted_non_empty_values(contact_ids)} end)
    |> non_empty_map()
  end

  def merge_string_list_maps(maps) do
    maps
    |> Enum.filter(&is_map/1)
    |> Enum.reduce(%{}, fn map, acc ->
      Map.merge(acc, map_value_lists(map) || %{}, fn _key, left, right ->
        sorted_non_empty_values(List.wrap(left) ++ List.wrap(right))
      end)
    end)
    |> non_empty_map()
  end

  def map_value_lists(%{} = value_map) do
    value_map
    |> Enum.reduce(%{}, fn {key, values}, acc ->
      case sorted_string_values(List.wrap(values)) do
        [] -> acc
        values -> Map.put(acc, to_string(key), values)
      end
    end)
    |> non_empty_map()
  end

  def map_value_lists(_value), do: nil

  def nested_map_value_lists(%{} = value_map) do
    value_map
    |> Enum.reduce(%{}, fn {outer_key, inner_map}, acc ->
      case map_value_lists(inner_map) do
        nil -> acc
        values -> Map.put(acc, to_string(outer_key), values)
      end
    end)
    |> non_empty_map()
  end

  def nested_map_value_lists(_value_map), do: nil

  def sorted_non_empty_values(values) do
    case sorted_string_values(values) do
      [] -> nil
      values -> values
    end
  end

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
