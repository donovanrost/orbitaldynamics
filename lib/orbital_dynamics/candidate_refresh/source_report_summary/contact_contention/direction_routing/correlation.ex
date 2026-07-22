defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting.Correlation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StableIds

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting.ConflictGroupDirections.ContactPairs

  def contact_ids_by_direction(direction_counts, contact_ids_by_direction, contact_id_counts) do
    positive_direction_counts = direction_counts(direction_counts)
    allowed_contact_ids = contact_id_counts |> positive_counts() |> Map.keys() |> MapSet.new()
    contact_ids_by_direction = normalize_direction_string_list_map(contact_ids_by_direction)

    positive_direction_counts
    |> Enum.reduce(%{}, fn {direction, _count}, filtered ->
      contact_ids =
        contact_ids_by_direction
        |> Map.get(direction, [])
        |> Enum.filter(&MapSet.member?(allowed_contact_ids, &1))

      case contact_ids do
        [] -> filtered
        contact_ids -> Map.put(filtered, direction, contact_ids)
      end
    end)
    |> non_empty_map()
  end

  def contact_id_counts(direction_counts, contact_ids_by_direction, contact_id_counts) do
    positive_direction_counts = direction_counts(direction_counts)

    allowed_contact_ids =
      direction_counts
      |> contact_ids_by_direction(contact_ids_by_direction, contact_id_counts)
      |> map_or_empty()
      |> Map.values()
      |> List.flatten()
      |> MapSet.new()

    correlated =
      contact_id_counts
      |> positive_counts()
      |> Map.take(MapSet.to_list(allowed_contact_ids))

    if Enum.sum(Map.values(correlated)) <= Enum.sum(Map.values(positive_direction_counts)),
      do: non_empty_map(correlated),
      else: nil
  end

  def positive_counts(%{} = counts) do
    Enum.reduce(counts, %{}, fn {key, count}, positive ->
      if is_integer(count) and count > 0 do
        Map.put(positive, to_string(key), count)
      else
        positive
      end
    end)
  end

  def positive_counts(_counts), do: %{}

  def direction_counts(%{} = counts) do
    Enum.reduce(counts, %{}, fn {direction, count}, normalized ->
      direction = canonical_direction(direction)

      if direction && is_integer(count) && count > 0,
        do: Map.update(normalized, direction, count, &(&1 + count)),
        else: normalized
    end)
  end

  def direction_counts(_counts), do: %{}

  def direction_counts_or_nil(counts) do
    counts
    |> direction_counts()
    |> non_empty_map()
  end

  def map_or_empty(%{} = map), do: map
  def map_or_empty(_map), do: %{}

  defp normalize_direction_string_list_map(%{} = values_by_key) do
    Enum.reduce(values_by_key, %{}, fn {key, values}, normalized ->
      direction = canonical_direction(key)

      values =
        values
        |> list_or_empty()
        |> Enum.reject(&(&1 in [nil, ""]))
        |> Enum.map(&to_string/1)
        |> Enum.uniq()
        |> Enum.sort()

      if is_nil(direction) or values == [],
        do: normalized,
        else:
          Map.update(normalized, direction, values, fn existing ->
            existing |> Kernel.++(values) |> Enum.uniq() |> Enum.sort()
          end)
    end)
  end

  defp normalize_direction_string_list_map(_values_by_key), do: %{}

  defp canonical_direction(direction) do
    direction
    |> ContactPairs.normalize_direction()
    |> case do
      direction when direction in [nil, "", "mixed", "contact"] -> nil
      direction -> StableIds.stable_id_or_nil(direction)
    end
  end

  defp list_or_empty(values) when is_list(values), do: values
  defp list_or_empty(_values), do: []

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
