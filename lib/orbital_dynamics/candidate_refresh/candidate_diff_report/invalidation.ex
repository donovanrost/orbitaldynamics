defmodule OrbitalDynamics.CandidateRefresh.CandidateDiffReport.Invalidation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.CandidateDiffReport.{
    PriorCandidates,
    Rows,
    SemanticChanges
  }

  def build(refresh, refreshed_candidates, dropped_candidates) do
    {invalid_prior_candidates, prior_candidates} =
      refresh
      |> PriorCandidates.activities()
      |> Enum.split_with(&PriorCandidates.invalid_input?/1)

    {_refreshed_matches, unmatched_prior_candidates} =
      Rows.match_by_id_occurrence(prior_candidates, refreshed_candidates)

    refreshed_by_semantic_key = SemanticChanges.candidate_groups(refreshed_candidates)
    dropped_by_semantic_key = SemanticChanges.candidate_groups(dropped_candidates)

    (invalid_prior_candidates ++ unmatched_prior_candidates)
    |> Enum.map(fn candidate ->
      if PriorCandidates.invalid_input?(candidate) do
        invalid_prior_candidate_row(candidate)
      else
        invalidated_candidate_row(
          candidate,
          refreshed_by_semantic_key,
          dropped_candidates,
          dropped_by_semantic_key
        )
      end
    end)
    |> Rows.sort()
  end

  defp invalidated_candidate_row(
         candidate,
         refreshed_by_semantic_key,
         dropped_candidates,
         dropped_by_semantic_key
       ) do
    refreshed_match = SemanticChanges.candidate_match(refreshed_by_semantic_key, candidate)
    dropped_match = dropped_candidate_match(dropped_candidates, candidate)

    dropped_semantic_match =
      SemanticChanges.candidate_match(dropped_by_semantic_key, candidate)

    invalidation_match =
      dropped_match || refreshed_match || dropped_semantic_match

    change_details = SemanticChanges.replacement_change_details(candidate, invalidation_match)
    change_reasons = SemanticChanges.change_detail_reasons(change_details)
    drop_reason_match = dropped_match || dropped_semantic_match

    row =
      %{
        "id" => Map.get(candidate, "id"),
        "type" => Map.get(candidate, "type"),
        "scenario_id" => Map.get(candidate, "scenario_id"),
        "starts_at_s" => Map.get(candidate, "starts_at_s"),
        "ends_at_s" => Map.get(candidate, "ends_at_s"),
        "invalidated_reason" =>
          invalidated_reason(
            if(dropped_match, do: nil, else: refreshed_match),
            drop_reason_match
          ),
        "replacement_candidate_id" => Rows.candidate_id(invalidation_match),
        "source_window_id" =>
          Map.get(candidate, "source_window_id") || get_in(candidate, ["source_window", "id"])
      }
      |> Map.merge(Rows.context(candidate, invalidation_match))

    row
    |> Rows.maybe_put_nonempty("semantic_change_reasons", change_reasons)
    |> Rows.maybe_put_nonempty("semantic_change_details", change_details)
    |> SemanticChanges.put_changed_fields(change_details)
    |> SemanticChanges.put_match_ambiguity(invalidation_match, "replacement")
    |> put_budget_dropped_match_context(drop_reason_match)
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp invalid_prior_candidate_row(candidate) do
    %{
      "id" => candidate["id"],
      "type" => candidate["type"],
      "scenario_id" => candidate["scenario_id"],
      "spacecraft_id" => candidate["spacecraft_id"],
      "ground_station_id" => candidate["ground_station_id"],
      "target_id" => candidate["target_id"],
      "source_window_id" => candidate["source_window_id"],
      "station_calendar_entry_id" => candidate["station_calendar_entry_id"],
      "station_calendar_overlap_entry_ids" => candidate["station_calendar_overlap_entry_ids"],
      "station_calendar_ambiguous_entry_ids" => candidate["station_calendar_ambiguous_entry_ids"],
      "station_calendar_reservation_ids" => candidate["station_calendar_reservation_ids"],
      "station_reservation_id" => candidate["station_reservation_id"],
      "starts_at_s" => candidate["starts_at_s"],
      "ends_at_s" => candidate["ends_at_s"],
      "invalidated_reason" => "invalid_prior_candidate_input",
      "invalid_prior_candidate_input" => true,
      "invalid_prior_candidate_input_reason" => candidate["invalid_prior_candidate_input_reason"],
      "source_candidate" => candidate["source_candidate"]
    }
    |> Map.merge(Rows.context(candidate))
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp invalidated_reason(nil, nil), do: "not_present_in_refreshed_candidate_set"

  defp invalidated_reason(nil, {:ambiguous, candidates}) do
    if Enum.all?(candidates, &(candidate_drop_reason(&1) == "dropped_by_candidate_budget")) do
      "ambiguous_budget_dropped_replacement_candidate"
    else
      "ambiguous_dropped_replacement_candidate"
    end
  end

  defp invalidated_reason(nil, {:unique, candidate}), do: candidate_drop_reason(candidate)

  defp invalidated_reason({:ambiguous, _refreshed_candidates}, _dropped_match),
    do: "ambiguous_semantic_replacement_candidate"

  defp invalidated_reason(_refreshed_match, _dropped_match),
    do: "replaced_by_semantically_similar_candidate"

  defp dropped_candidate_match(dropped_candidates, prior_candidate) do
    case Enum.filter(dropped_candidates, &(&1["id"] == prior_candidate["id"])) do
      [] -> nil
      [candidate] -> {:unique, candidate}
      candidates -> {:ambiguous, candidates}
    end
  end

  defp candidate_drop_reason(candidate) do
    Map.get(candidate, "__candidate_drop_reason__", "dropped_by_candidate_budget")
  end

  defp put_budget_dropped_match_context(row, nil), do: row

  defp put_budget_dropped_match_context(row, {:unique, candidate}) do
    if candidate_drop_reason(candidate) == "dropped_by_candidate_budget" do
      row
      |> Map.put("candidate_budget_match_status", "budget_dropped_replacement_candidate")
      |> Map.put("candidate_budget_match_count", 1)
      |> Map.put("budget_dropped_candidate_ids", [candidate["id"]])
    else
      row
    end
  end

  defp put_budget_dropped_match_context(row, {:ambiguous, candidates}) do
    if Enum.all?(candidates, &(candidate_drop_reason(&1) == "dropped_by_candidate_budget")) do
      row
      |> Map.put(
        "candidate_budget_match_status",
        "ambiguous_budget_dropped_replacement_candidate"
      )
      |> Map.put("candidate_budget_match_count", length(candidates))
      |> Map.put("budget_dropped_candidate_ids", Enum.map(candidates, &Map.get(&1, "id")))
    else
      row
    end
  end
end
