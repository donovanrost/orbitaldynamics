defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Recommendation.Rows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Aggregation.Values
  alias __MODULE__.Normalization
  alias __MODULE__.RowValues

  def recommendation_station_contact_pairs(recommendation, status) do
    RowValues.recommendation_station_contact_pairs(recommendation, status)
  end

  def recommendation_required_actions(recommendation) do
    RowValues.recommendation_required_actions(recommendation)
  end

  def direction_contact_pairs(report) do
    RowValues.direction_contact_pairs(report)
  end

  def deferred_contacts(recommendation) do
    RowValues.deferred_contacts(recommendation)
  end

  def count_rows(rows, field) do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(&Map.get(&1, field))
    |> count_values()
  end

  def count_values(values) do
    values
    |> List.flatten()
    |> Enum.map(&normalize_count_token/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> non_empty_map()
  end

  def grouped_ids(pairs) do
    pairs
    |> Enum.reject(fn {key, value} -> key in [nil, ""] or value in [nil, ""] end)
    |> Enum.group_by(fn {key, _value} -> to_string(key) end, fn {_key, value} -> value end)
    |> Map.new(fn {key, values} -> {key, sorted_non_empty_values(values)} end)
    |> non_empty_map()
  end

  def grouped_id_counts(pairs) do
    pairs
    |> grouped_ids()
    |> case do
      nil -> nil
      ids_by_key -> Map.new(ids_by_key, fn {key, ids} -> {key, length(ids)} end)
    end
  end

  def map_value_lists(%{} = value_map) do
    value_map
    |> Enum.reduce(%{}, fn {key, values}, acc ->
      case sorted_non_empty_values(List.wrap(values)) do
        nil -> acc
        values -> Map.put(acc, to_string(key), values)
      end
    end)
    |> non_empty_map()
  end

  def map_value_lists(_value), do: nil

  def normalize_direction_count_map(%{} = counts) do
    counts
    |> Enum.reduce(%{}, fn {direction, count}, acc ->
      case {RowValues.normalize_direction(direction), Values.numeric_value(count)} do
        {nil, _count} -> acc
        {_direction, nil} -> acc
        {direction, count} -> Map.update(acc, direction, trunc(count), &(&1 + trunc(count)))
      end
    end)
    |> non_empty_map()
  end

  def normalize_direction_count_map(_counts), do: nil

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

  def stable_id_or_nil(value), do: RowValues.stable_id_or_nil(value)

  def stringify_keys(value), do: RowValues.stringify_keys(value)

  defp normalize_count_token(value), do: Normalization.normalize_count_token(value)

  defp non_empty_map(value), do: Normalization.non_empty_map(value)
end
