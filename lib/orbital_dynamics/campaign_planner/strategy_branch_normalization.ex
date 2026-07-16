defmodule OrbitalDynamics.CampaignPlanner.StrategyBranchNormalization do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    BranchEventNormalizer,
    CandidateRefreshNormalization,
    ScalarValues,
    StrategyBranchEventAliases,
    ValueEncoding,
    WhatIfScenario
  }

  def normalize_branches(branches), do: normalize_branches(branches, default_callbacks())

  def normalize_branches(nil, _callbacks), do: []

  def normalize_branches(branches, callbacks) when is_list(branches) do
    branches
    |> Enum.map(&normalize_branch(&1, callbacks))
    |> Enum.sort_by(& &1["id"])
  end

  def normalize_branch(branch), do: normalize_branch(branch, default_callbacks())

  def normalize_branch(%WhatIfScenario{} = branch, callbacks) do
    branch
    |> Map.from_struct()
    |> normalize_branch(callbacks)
  end

  def normalize_branch(branch, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    encode_value = Keyword.fetch!(callbacks, :encode_value)
    normalize_candidate_refresh = Keyword.fetch!(callbacks, :normalize_candidate_refresh)

    normalize_candidate_refresh_request =
      Keyword.fetch!(callbacks, :normalize_candidate_refresh_request)

    branch = stringify_keys.(branch || %{})
    branch_id = encode_value.(Map.fetch!(branch, "id"))

    %{
      "id" => branch_id,
      "label" => Map.get(branch, "label") || branch_id,
      "probability" =>
        normalize_probability(Map.get(branch, "probability", 1.0), branch_id, callbacks),
      "events" => normalize_events(Map.get(branch, "events", []), callbacks),
      "policy_overrides" => Map.get(branch, "policy_overrides", %{}),
      "realized_state_overrides" => Map.get(branch, "realized_state_overrides", %{}),
      "candidate_refresh" =>
        normalize_candidate_refresh.(
          Map.get(branch, "candidate_refresh") || Map.get(branch, "refreshed_candidates")
        ),
      "candidate_refresh_request" =>
        normalize_candidate_refresh_request.(
          Map.get(branch, "candidate_refresh_request") || Map.get(branch, "refresh_request")
        ),
      "metadata" => Map.get(branch, "metadata", %{})
    }
  end

  def normalize_events(events), do: normalize_events(events, default_callbacks())

  def normalize_events(events, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    normalize_branch_event_aliases = Keyword.fetch!(callbacks, :normalize_branch_event_aliases)

    events
    |> Enum.map(stringify_keys)
    |> Enum.map(normalize_branch_event_aliases)
    |> Enum.map(&BranchEventNormalizer.normalize_event/1)
    |> Enum.sort_by(
      &{Map.get(&1, "starts_at_s", 0.0), Map.get(&1, "type", ""), Map.get(&1, "id", "")}
    )
  end

  defp normalize_probability(value, branch_id, callbacks) do
    numeric = Keyword.fetch!(callbacks, :numeric)
    probability = numeric.(value, "branch #{branch_id} probability") * 1.0

    if probability >= 0.0 and probability <= 1.0 do
      probability
    else
      raise ArgumentError, "branch #{branch_id} probability must be between 0.0 and 1.0"
    end
  end

  defp default_callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      encode_value: &ValueEncoding.encode_value/1,
      numeric: &ScalarValues.numeric!/2,
      normalize_candidate_refresh: &CandidateRefreshNormalization.artifact/1,
      normalize_candidate_refresh_request: &CandidateRefreshNormalization.request/1,
      normalize_branch_event_aliases: &StrategyBranchEventAliases.normalize/1
    ]
  end
end
