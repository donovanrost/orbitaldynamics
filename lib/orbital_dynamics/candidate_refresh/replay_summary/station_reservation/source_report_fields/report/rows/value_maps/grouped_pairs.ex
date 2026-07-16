defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows.ValueMaps.GroupedPairs do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows.ValueMaps.Normalization

  def grouped_ids(pairs) do
    pairs
    |> Enum.reject(fn {key, value} -> key in [nil, ""] or value in [nil, ""] end)
    |> Enum.group_by(fn {key, _value} -> to_string(key) end, fn {_key, value} -> value end)
    |> Map.new(fn {key, values} -> {key, sorted_string_values(values)} end)
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

  defp sorted_string_values(values) when is_list(values) do
    values
    |> Enum.map(&Normalization.encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp sorted_string_values(_values), do: []

  defp non_empty_map(map), do: Normalization.non_empty_map(map)
end
