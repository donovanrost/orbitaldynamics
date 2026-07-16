defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.DirectionRouting.CandidateDirections.PairMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.CandidatePairs

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.DirectionRouting.CandidateDirections.DirectionValues

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.ValueMaps,
    as: ResourceValueMaps

  def direction_candidate_pairs(report) do
    report
    |> candidate_rows()
    |> CandidatePairs.pairs(&DirectionValues.from_row/1)
  end

  def counts_from_pairs(pairs) do
    pairs
    |> ids_from_pairs()
    |> case do
      nil -> nil
      ids_by_key -> Map.new(ids_by_key, fn {key, ids} -> {key, length(ids)} end)
    end
  end

  def ids_from_pairs(pairs) do
    pairs
    |> Enum.reject(fn {key, value} -> key in [nil, ""] or value in [nil, ""] end)
    |> Enum.group_by(fn {key, _value} -> to_string(key) end, fn {_key, value} -> value end)
    |> Map.new(fn {key, values} -> {key, ResourceValueMaps.sorted_non_empty_strings(values)} end)
    |> ResourceValueMaps.non_empty_map()
  end

  defp candidate_rows(report) do
    report
    |> Map.get("suppressed_candidates", [])
    |> Enum.map(&EncodedValue.stringify_keys/1)
  end
end
