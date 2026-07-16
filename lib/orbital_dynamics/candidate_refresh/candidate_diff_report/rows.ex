defmodule OrbitalDynamics.CandidateRefresh.CandidateDiffReport.Rows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.{
    SourceReportSummary.Common,
    SourceWindowLineage
  }

  def match_by_id_occurrence(prior_candidates, refreshed_candidates) do
    indexed_prior_candidates = Enum.with_index(prior_candidates)

    {refreshed_matches, matched_prior_indexes} =
      Enum.map_reduce(refreshed_candidates, MapSet.new(), fn candidate, matched_indexes ->
        case first_unmatched_prior_candidate(indexed_prior_candidates, candidate, matched_indexes) do
          nil ->
            {{candidate, nil}, matched_indexes}

          {prior_candidate, prior_index} ->
            {{candidate, prior_candidate}, MapSet.put(matched_indexes, prior_index)}
        end
      end)

    unmatched_prior_candidates =
      indexed_prior_candidates
      |> Enum.reject(fn {_candidate, index} -> MapSet.member?(matched_prior_indexes, index) end)
      |> Enum.map(fn {candidate, _index} -> candidate end)

    {refreshed_matches, unmatched_prior_candidates}
  end

  def candidate_id(nil), do: nil
  def candidate_id({:unique, candidate}), do: Map.get(candidate, "id")
  def candidate_id({:ambiguous, _candidates}), do: nil
  def candidate_id(candidate), do: Map.get(candidate, "id")

  def context(candidate), do: context(candidate, nil)

  def context(candidate, fallback_match) do
    fallback_match
    |> candidate_from_match()
    |> context_map()
    |> Map.merge(context_map(candidate))
  end

  def maybe_put_nonempty(map, _key, []), do: map
  def maybe_put_nonempty(map, key, values), do: Map.put(map, key, values)

  def sort(rows) do
    Enum.sort_by(rows, &{&1["scenario_id"] || "", &1["starts_at_s"] || 0.0, &1["id"] || ""})
  end

  defp first_unmatched_prior_candidate(indexed_prior_candidates, candidate, matched_indexes) do
    Enum.find(indexed_prior_candidates, fn {prior_candidate, index} ->
      prior_candidate["id"] == candidate["id"] and not MapSet.member?(matched_indexes, index)
    end)
  end

  defp candidate_from_match({:unique, candidate}), do: candidate
  defp candidate_from_match(%{} = candidate), do: candidate
  defp candidate_from_match(_match), do: nil

  defp context_map(%{} = candidate) do
    %{
      "target_id" => candidate["target_id"],
      "ground_station_id" => candidate["ground_station_id"],
      "direction" => candidate["direction"],
      "source_target_id" => candidate["source_target_id"],
      "source_target" => candidate["source_target"],
      "target_latitude_deg" => candidate["target_latitude_deg"],
      "target_longitude_deg" => candidate["target_longitude_deg"],
      "target_minimum_elevation_deg" => candidate["target_minimum_elevation_deg"],
      "target_priority" => candidate["target_priority"],
      "target_priority_source" => candidate["target_priority_source"],
      "target_priority_objective_ids" => candidate["target_priority_objective_ids"],
      "target_priority_objective_type" => candidate["target_priority_objective_type"]
    }
    |> Map.merge(SourceWindowLineage.context(candidate))
    |> Common.compact_map()
  end

  defp context_map(_candidate), do: %{}
end
