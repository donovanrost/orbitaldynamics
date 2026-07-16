defmodule OrbitalDynamics.CampaignPlanner.PriorActivityContext do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.BranchRefreshSourceInputs
  alias OrbitalDynamics.CampaignPlanner.CollectionLatencyMaps
  alias OrbitalDynamics.CampaignPlanner.RealizedFeedbackContext
  alias OrbitalDynamics.CampaignPlanner.StrategyPriorPlanCandidates

  def enrich(realized_activities, prior_plan) do
    RealizedFeedbackContext.enrich(realized_activities, rows(prior_plan))
  end

  def rows(prior_plan) do
    [
      activities(prior_plan),
      candidate_activities(prior_plan),
      proposed_contacts(prior_plan)
    ]
    |> List.flatten()
    |> Enum.map(&CollectionLatencyMaps.stringify_keys/1)
  end

  def activities(activities) when is_list(activities), do: activities

  def activities(%{} = prior_plan) do
    prior_plan = CollectionLatencyMaps.stringify_keys(prior_plan)

    case activity_rows(Map.get(prior_plan, "activities")) do
      [] -> result_artifact_activity_rows(prior_plan)
      rows -> normalize_rows(rows)
    end
  end

  def activities(_prior_plan), do: []

  def candidate_activities(prior_plan) do
    StrategyPriorPlanCandidates.candidate_activities(
      prior_plan,
      strategy_prior_plan_candidate_callbacks()
    )
  end

  def proposed_contacts(%{} = prior_plan) do
    prior_plan = CollectionLatencyMaps.stringify_keys(prior_plan)

    case proposed_contact_rows(Map.get(prior_plan, "proposed_contacts")) do
      [] -> result_artifact_proposed_contact_rows(prior_plan)
      rows -> normalize_rows(rows)
    end
  end

  def proposed_contacts(_prior_plan), do: []

  defp strategy_prior_plan_candidate_callbacks,
    do: [
      result_artifacts_with_source: &result_artifacts_with_source/1,
      put_inherited_trust_boundary:
        &BranchRefreshSourceInputs.put_inherited_result_artifact_trust_boundary/2
    ]

  defp result_artifact_activity_rows(prior_plan) do
    prior_plan
    |> result_artifacts_with_source()
    |> Enum.flat_map(fn {artifact, _source_path} ->
      artifact
      |> Map.get("activities")
      |> activity_rows()
      |> normalize_rows()
      |> Enum.map(
        &BranchRefreshSourceInputs.put_inherited_result_artifact_trust_boundary(&1, artifact)
      )
    end)
  end

  defp result_artifact_proposed_contact_rows(prior_plan) do
    prior_plan
    |> result_artifacts_with_source()
    |> Enum.flat_map(fn {artifact, _source_path} ->
      artifact
      |> Map.get("proposed_contacts")
      |> proposed_contact_rows()
      |> normalize_rows()
      |> Enum.map(
        &BranchRefreshSourceInputs.put_inherited_result_artifact_trust_boundary(&1, artifact)
      )
    end)
  end

  defp result_artifacts_with_source(prior_plan) do
    BranchRefreshSourceInputs.result_artifacts_with_source(prior_plan, "prior_plan")
  end

  defp activity_rows(rows) when is_list(rows), do: rows
  defp activity_rows(_rows), do: []

  defp proposed_contact_rows(rows) when is_list(rows), do: rows
  defp proposed_contact_rows(_rows), do: []

  defp normalize_rows(rows), do: Enum.map(rows, &CollectionLatencyMaps.stringify_keys/1)
end
