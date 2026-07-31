defmodule OrbitalDynamics.CampaignPlanner.StrategyReport do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    PlanBranch,
    StrategyRecommendation,
    StrategyPolicyNormalization,
    StrategicScoringPolicy
  }

  def score_term_report(
        branches,
        %StrategyRecommendation{} = recommendation,
        %StrategicScoringPolicy{} = policy,
        model_limits
      ) do
    score_term_report_from_artifact(
      Enum.map(branches, fn %PlanBranch{} = branch ->
        %{
          "branch_id" => branch.id,
          "score" => branch.score,
          "score_terms" => branch.score_terms
        }
      end),
      recommendation.recommended_branch_id,
      strategy_policy_to_map(policy),
      model_limits
    )
  end

  def score_term_report_from_artifact(
        branches,
        recommended_branch_id,
        policy,
        model_limits
      )
      when is_list(branches) and is_binary(recommended_branch_id) and is_map(policy) do
    rows =
      branches
      |> Enum.with_index(1)
      |> Enum.flat_map(fn {branch, rank} ->
        strategy_score_term_rows(branch, rank, recommended_branch_id)
      end)
      |> Enum.sort_by(&{&1["rank"], &1["branch_id"], &1["term_key"]})

    %{
      "schema_contract" => "score_term_report.v1",
      "model" => "strategy_branch_score_terms",
      "source" => "campaign_strategy.branches.score_terms",
      "row_count" => length(rows),
      "score_term_keys" => strategy_score_term_keys(branches),
      "model_limits" => model_limits,
      "rows" => rows,
      "assumptions" => %{
        "score_term_source" => "campaign_strategy.branches.score_terms",
        "scenario_id_represents" => "branch_id",
        "policy" => policy
      }
    }
  end

  def objective_tradeoff_report(
        branches,
        %StrategyRecommendation{} = recommendation,
        %StrategicScoringPolicy{} = policy,
        model_limits,
        activity_id_fun,
        downlink_activity_fun
      ) do
    objective_tradeoff_report_from_artifact(
      Enum.map(branches, fn %PlanBranch{} = branch ->
        %{
          "branch_id" => branch.id,
          "score" => branch.score,
          "score_terms" => branch.score_terms,
          "repair_result" => branch.repair_result
        }
      end),
      recommendation.recommended_branch_id,
      strategy_policy_to_map(policy),
      model_limits,
      activity_id_fun,
      downlink_activity_fun
    )
  end

  def objective_tradeoff_report_from_artifact(
        branches,
        recommended_branch_id,
        policy,
        model_limits,
        activity_id_fun,
        downlink_activity_fun
      )
      when is_list(branches) and is_binary(recommended_branch_id) and is_map(policy) and
             is_function(activity_id_fun, 1) and is_function(downlink_activity_fun, 1) do
    selected_score =
      branches
      |> Enum.find(&(&1["branch_id"] == recommended_branch_id))
      |> case do
        nil -> 0.0
        branch -> branch["score"]
      end

    tradeoffs =
      branches
      |> Enum.with_index(1)
      |> Enum.map(fn {branch, rank} ->
        strategy_objective_tradeoff_row(
          branch,
          rank,
          selected_score,
          recommended_branch_id,
          activity_id_fun,
          downlink_activity_fun
        )
      end)

    %{
      "schema_contract" => "objective_tradeoff_report.v1",
      "model" => "strategy_branch_score_term_tradeoffs",
      "objective" => "compare strategy branch scores and score-term contributions",
      "ranking_count" => length(tradeoffs),
      "score_term_keys" => strategy_score_term_keys(branches),
      "policy" => policy,
      "model_limits" => model_limits,
      "tradeoffs" => tradeoffs,
      "assumptions" => %{
        "source" => "campaign_strategy.branches.score_terms",
        "scenario_id_represents" => "branch_id",
        "score_delta_from_selected" => "branch_score_minus_recommended_branch_score"
      }
    }
  end

  defp strategy_score_term_rows(
         %{
           "branch_id" => branch_id,
           "score" => score,
           "score_terms" => score_terms
         },
         rank,
         recommended_branch_id
       ) do
    score_terms
    |> Enum.map(fn {term_key, value} ->
      %{
        "id" => score_term_row_id(branch_id, rank, term_key),
        "rank" => rank,
        "scenario_id" => branch_id,
        "branch_id" => branch_id,
        "term_key" => term_key,
        "value" => value,
        "timeline_score" => score,
        "selected" => branch_id == recommended_branch_id
      }
    end)
  end

  defp strategy_score_term_keys(branches) do
    branches
    |> Enum.flat_map(fn
      %PlanBranch{} = branch -> Map.keys(branch.score_terms)
      %{"score_terms" => score_terms} -> Map.keys(score_terms)
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp strategy_objective_tradeoff_row(
         %{
           "branch_id" => branch_id,
           "score" => score,
           "score_terms" => score_terms,
           "repair_result" => repair_result
         },
         rank,
         selected_score,
         recommended_branch_id,
         activity_id_fun,
         downlink_activity_fun
       ) do
    activities = get_in(repair_result, ["activities"]) || []

    %{
      "rank" => rank,
      "scenario_id" => branch_id,
      "branch_id" => branch_id,
      "score" => score,
      "score_delta_from_selected" => score - selected_score,
      "activity_count" => length(activities),
      "selected_observation_count" => Enum.count(activities, &(&1["type"] == "observation")),
      "selected_contact_count" => Enum.count(activities, downlink_activity_fun),
      "score_terms" => score_terms,
      "activity_ids" => Enum.map(activities, activity_id_fun),
      "selected" => branch_id == recommended_branch_id
    }
  end

  defp strategy_policy_to_map(%StrategicScoringPolicy{} = policy) do
    StrategyPolicyNormalization.strategy_to_map(policy)
  end

  defp score_term_row_id(scenario_id, rank, term_key) do
    ["score_term", scenario_id, rank, term_key]
    |> Enum.map(&encode_value/1)
    |> Enum.join(":")
  end

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
