defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.ProviderReservation.RequestSummary.Rows.RowValues.ContactMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.ProviderReservation.RequestSummary.Rows.RowValues.Normalization

  import Common, only: [sorted_string_values: 1]

  def contact_ids_by_direction_and_station(rows) do
    rows
    |> Enum.reduce(%{}, fn row, acc ->
      direction = summary_direction(row)
      station_id = group_key(row, "ground_station_id")
      contact_id = summary_contact_id(row)

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
    |> Map.new(fn {direction, station_map} -> {direction, map_value_lists(station_map)} end)
    |> non_empty_map()
  end

  def group_key(row, "direction"), do: summary_direction(row)
  def group_key(row, field), do: stable_id_or_nil(row[field]) || normalized_token(row[field])

  def summary_contact_id(row) do
    stable_id_or_nil(row["contact_id"]) ||
      stable_id_or_nil(row["id"]) ||
      stable_id_or_nil(get_in(row, ["activity_context", "activity_id"]))
  end

  def summary_direction(row) do
    [
      row["direction"],
      get_in(row, ["activity_context", "direction"]),
      get_in(row, ["source_contact_candidate", "direction"]),
      get_in(row, ["source_contact_candidate", "activity_context", "direction"]),
      get_in(row, ["source_contention_recommendation", "direction"]),
      row["type"],
      get_in(row, ["source_contact_candidate", "type"])
    ]
    |> Enum.map(&normalize_direction/1)
    |> Enum.find(&(&1 not in [nil, ""]))
  end

  def grouped_contact_ids(pairs) do
    pairs
    |> Enum.reject(fn {key, contact_id} -> key in [nil, ""] or contact_id in [nil, ""] end)
    |> Enum.group_by(fn {key, _contact_id} -> key end, fn {_key, contact_id} -> contact_id end)
    |> Map.new(fn {key, contact_ids} -> {key, sorted_non_empty_values(contact_ids)} end)
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
    values
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      values -> values
    end
  end

  defp non_empty_map(map), do: Normalization.non_empty_map(map)
  defp stable_id_or_nil(value), do: Normalization.stable_id_or_nil(value)
  defp normalize_direction(direction), do: Normalization.normalize_direction(direction)
  defp normalized_token(value), do: Normalization.normalized_token(value)
end
