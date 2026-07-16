defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.ValueListMaps.PairMaps.PairValues do
  @moduledoc false

  alias __MODULE__.ValueLists

  def from_pairs(pairs) do
    pairs
    |> Enum.reject(&empty_pair?/1)
    |> Enum.group_by(&pair_key/1, &pair_value/1)
    |> Map.new(fn {key, values} -> {key, ValueLists.sorted_non_empty(values)} end)
  end

  defp empty_pair?({key, value}), do: key in [nil, ""] or value in [nil, ""]

  defp pair_key({key, _value}), do: to_string(key)

  defp pair_value({_key, value}), do: value
end
