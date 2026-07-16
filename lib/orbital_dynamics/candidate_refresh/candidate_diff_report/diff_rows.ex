defmodule OrbitalDynamics.CandidateRefresh.CandidateDiffReport.DiffRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.CandidateDiffReport.{
    Rows,
    SemanticChanges
  }

  def retained(candidate, prior_candidate) do
    change_details = SemanticChanges.change_details(prior_candidate, candidate)
    change_reasons = SemanticChanges.change_detail_reasons(change_details)

    %{
      "id" => candidate["id"],
      "type" => candidate["type"],
      "scenario_id" => candidate["scenario_id"],
      "starts_at_s" => candidate["starts_at_s"],
      "ends_at_s" => candidate["ends_at_s"],
      "diff_reason" => reason("retained", prior_candidate, change_reasons),
      "matched_prior_candidate_id" => Rows.candidate_id(prior_candidate),
      "source_window_id" =>
        Map.get(candidate, "source_window_id") || get_in(candidate, ["source_window", "id"])
    }
    |> Map.merge(Rows.context(candidate, prior_candidate))
    |> Rows.maybe_put_nonempty("semantic_change_reasons", change_reasons)
    |> Rows.maybe_put_nonempty("semantic_change_details", change_details)
    |> SemanticChanges.put_changed_fields(change_details)
    |> compact()
  end

  def new(candidate, prior_match) do
    change_details = SemanticChanges.prior_change_details(prior_match, candidate)
    change_reasons = SemanticChanges.change_detail_reasons(change_details)

    %{
      "id" => candidate["id"],
      "type" => candidate["type"],
      "scenario_id" => candidate["scenario_id"],
      "starts_at_s" => candidate["starts_at_s"],
      "ends_at_s" => candidate["ends_at_s"],
      "diff_reason" => reason("new", prior_match, change_reasons),
      "matched_prior_candidate_id" => Rows.candidate_id(prior_match),
      "source_window_id" =>
        Map.get(candidate, "source_window_id") || get_in(candidate, ["source_window", "id"])
    }
    |> Map.merge(Rows.context(candidate, prior_match))
    |> Rows.maybe_put_nonempty("semantic_change_reasons", change_reasons)
    |> Rows.maybe_put_nonempty("semantic_change_details", change_details)
    |> SemanticChanges.put_changed_fields(change_details)
    |> SemanticChanges.put_match_ambiguity(prior_match, "prior")
    |> compact()
  end

  defp reason("retained", _prior_candidate, []),
    do: "present_in_prior_candidate_set"

  defp reason("retained", _prior_candidate, _change_reasons),
    do: "present_in_prior_candidate_set_with_semantic_changes"

  defp reason("new", nil, _change_reasons),
    do: "not_present_in_prior_candidate_set"

  defp reason("new", {:ambiguous, _prior_candidates}, _change_reasons),
    do: "ambiguous_semantic_prior_candidate_match"

  defp reason("new", _prior_candidate, _change_reasons),
    do: "semantically_similar_prior_candidate_changed"

  defp compact(row) do
    row
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
