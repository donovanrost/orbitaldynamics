defmodule OrbitalDynamics.CandidateRefresh.CandidateDiffReport do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.{
    ModelLimits,
    SourceWindowLineage
  }

  alias __MODULE__.{DiffRows, Invalidation, PriorCandidates, Rows, SemanticChanges}

  def prior_candidate_optional_stable_identity_fields,
    do: PriorCandidates.optional_stable_identity_fields()

  def station_calendar_id_list_fields, do: PriorCandidates.station_calendar_id_list_fields()

  def station_calendar_number_list_fields,
    do: PriorCandidates.station_calendar_number_list_fields()

  def prior_candidate_activities(refresh), do: PriorCandidates.activities(refresh)

  def valid_prior_candidate_activities(refresh), do: PriorCandidates.valid_activities(refresh)

  def invalidated_candidates(refresh, refreshed_candidates, dropped_candidates) do
    Invalidation.build(refresh, refreshed_candidates, dropped_candidates)
  end

  def report(refresh, refreshed_candidates, invalidated_candidates) do
    prior_candidates = prior_candidate_activities(refresh)

    {invalid_prior_candidates, valid_prior_candidates} =
      Enum.split_with(prior_candidates, &invalid_prior_candidate_input?/1)

    prior_by_semantic_key = SemanticChanges.candidate_groups(valid_prior_candidates)

    {refreshed_matches, _unmatched_prior_candidates} =
      Rows.match_by_id_occurrence(valid_prior_candidates, refreshed_candidates)

    retained =
      refreshed_matches
      |> Enum.filter(fn {_candidate, prior_candidate} -> not is_nil(prior_candidate) end)
      |> Enum.map(fn {candidate, prior_candidate} ->
        DiffRows.retained(candidate, prior_candidate)
      end)
      |> Rows.sort()

    added =
      refreshed_matches
      |> Enum.filter(fn {_candidate, prior_candidate} -> is_nil(prior_candidate) end)
      |> Enum.map(fn {candidate, _prior_candidate} ->
        DiffRows.new(
          candidate,
          SemanticChanges.candidate_match(prior_by_semantic_key, candidate)
        )
      end)
      |> Rows.sort()

    %{
      "schema_contract" => "candidate_diff_report.v1",
      "model" => "candidate_id_set_diff_with_semantic_change_reasons",
      "model_limits" => ModelLimits.strings(),
      "prior_candidate_count" => length(prior_candidates),
      "valid_prior_candidate_count" => length(valid_prior_candidates),
      "invalid_prior_candidate_input_count" => length(invalid_prior_candidates),
      "invalid_prior_candidate_input_ids" => Enum.map(invalid_prior_candidates, & &1["id"]),
      "refreshed_candidate_count" => length(refreshed_candidates),
      "retained_candidate_count" => length(retained),
      "new_candidate_count" => length(added),
      "invalidated_candidate_count" => length(invalidated_candidates),
      "retained_candidates" => retained,
      "new_candidates" => added,
      "invalidated_candidates" => invalidated_candidates,
      "source_window_lineage" => SourceWindowLineage.build(refreshed_candidates)
    }
  end

  def mark_dropped_candidates(candidates, reason) do
    Enum.map(candidates, &Map.put(&1, "__candidate_drop_reason__", reason))
  end

  defp invalid_prior_candidate_input?(candidate), do: PriorCandidates.invalid_input?(candidate)
end
