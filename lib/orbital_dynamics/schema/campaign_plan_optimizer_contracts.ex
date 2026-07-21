defmodule OrbitalDynamics.Schema.CampaignPlanOptimizerContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [expect_type: 5]

  alias OrbitalDynamics.Schema.PrimitiveValidation

  def validate(issues, artifact) when is_map(artifact) do
    issues
    |> validate_ranking_explanation(Map.get(artifact, "ranking_explanation"))
    |> validate_optimizer(artifact, Map.get(artifact, "optimizer_contract"))
  end

  defp validate_ranking_explanation(issues, explanation) when is_map(explanation) do
    issues
    |> expect_type("$.ranking_explanation", explanation, "objective", :binary)
    |> expect_type("$.ranking_explanation", explanation, "formula", :binary)
    |> expect_type("$.ranking_explanation", explanation, "policy", :map)
  end

  defp validate_ranking_explanation(issues, _explanation), do: issues

  defp validate_optimizer(issues, _artifact, nil), do: issues
  defp validate_optimizer(issues, _artifact, :null), do: issues

  defp validate_optimizer(issues, artifact, optimizer) when is_map(optimizer) do
    case plan_context(artifact) do
      {:ok, context} -> validate_optimizer_context(issues, optimizer, context)
      :error -> issues
    end
  end

  defp validate_optimizer(issues, _artifact, _optimizer), do: issues

  defp plan_context(artifact) do
    candidates = Map.get(artifact, "candidate_activities")
    activities = Map.get(artifact, "activities")
    timelines = Map.get(artifact, "ranked_timelines")
    assumptions = Map.get(artifact, "assumptions")
    explanation = Map.get(artifact, "ranking_explanation")

    if activity_list?(candidates) and activity_list?(activities) and
         valid_timelines?(timelines) and is_map(assumptions) and is_map(explanation) do
      selected_ids =
        timelines
        |> List.first(%{})
        |> Map.get("activities", [])
        |> activity_ids()

      {:ok,
       %{
         candidate_ids: activity_ids(candidates),
         selected_ids: selected_ids,
         top_level_selected_ids: activity_ids(activities),
         ranked_scenario_ids: Enum.map(timelines, & &1["scenario_id"]),
         score_term_keys: score_term_keys(timelines),
         constraints: Map.get(assumptions, "constraints", %{}),
         scoring_policy: Map.get(assumptions, "scoring_policy", %{}),
         explanation_objective: Map.get(explanation, "objective"),
         explanation_policy: Map.get(explanation, "policy"),
         tradeoff_objective: tradeoff_field(artifact, "objective"),
         tradeoff_policy: tradeoff_field(artifact, "policy"),
         score_report_policy: score_report_policy(artifact)
       }}
    else
      :error
    end
  end

  defp validate_optimizer_context(issues, optimizer, context) do
    issues
    |> validate_equal(
      "$.optimizer_contract.optimizer",
      Map.get(optimizer, "optimizer"),
      "per_spacecraft_greedy_non_overlapping",
      "must identify the V1 campaign optimizer"
    )
    |> validate_equal(
      "$.optimizer_contract.selection_policy",
      Map.get(optimizer, "selection_policy"),
      "highest_scored_non_overlapping_timeline",
      "must identify the V1 campaign selection policy"
    )
    |> validate_equal(
      "$.activities",
      context.top_level_selected_ids,
      context.selected_ids,
      "must match the first ranked timeline activities"
    )
    |> validate_equal(
      "$.optimizer_contract.candidate_count",
      Map.get(optimizer, "candidate_count"),
      length(context.candidate_ids),
      "must equal enclosing candidate activity count"
    )
    |> validate_equal(
      "$.optimizer_contract.candidate_activity_ids",
      Map.get(optimizer, "candidate_activity_ids"),
      context.candidate_ids,
      "must match enclosing candidate activity IDs"
    )
    |> validate_equal(
      "$.optimizer_contract.selected_activity_count",
      Map.get(optimizer, "selected_activity_count"),
      length(context.selected_ids),
      "must equal selected ranked timeline activity count"
    )
    |> validate_equal(
      "$.optimizer_contract.selected_activity_ids",
      Map.get(optimizer, "selected_activity_ids"),
      context.selected_ids,
      "must match selected ranked timeline activity IDs"
    )
    |> validate_equal(
      "$.optimizer_contract.ranked_timeline_count",
      Map.get(optimizer, "ranked_timeline_count"),
      length(context.ranked_scenario_ids),
      "must equal enclosing ranked timeline count"
    )
    |> validate_equal(
      "$.optimizer_contract.ranked_scenario_ids",
      Map.get(optimizer, "ranked_scenario_ids"),
      context.ranked_scenario_ids,
      "must match enclosing ranked scenario IDs"
    )
    |> validate_equal(
      "$.optimizer_contract.score_term_keys",
      Map.get(optimizer, "score_term_keys"),
      context.score_term_keys,
      "must match enclosing ranked timeline score-term keys"
    )
    |> validate_equal(
      "$.optimizer_contract.constraints",
      Map.get(optimizer, "constraints"),
      context.constraints,
      "must match campaign plan constraint assumptions"
    )
    |> validate_equal(
      "$.optimizer_contract.scoring_policy",
      Map.get(optimizer, "scoring_policy"),
      context.scoring_policy,
      "must match campaign plan scoring-policy assumptions"
    )
    |> validate_equal(
      "$.ranking_explanation.policy",
      context.explanation_policy,
      context.scoring_policy,
      "must match campaign plan scoring-policy assumptions"
    )
    |> validate_optional_equal(
      "$.objective_tradeoff_report.policy",
      context.tradeoff_policy,
      context.scoring_policy,
      "must match campaign plan scoring-policy assumptions"
    )
    |> validate_optional_equal(
      "$.score_term_report.assumptions.policy",
      context.score_report_policy,
      context.scoring_policy,
      "must match campaign plan scoring-policy assumptions"
    )
    |> validate_equal(
      "$.optimizer_contract.objective",
      Map.get(optimizer, "objective"),
      context.explanation_objective,
      "must match the ranking explanation objective"
    )
    |> validate_optional_equal(
      "$.objective_tradeoff_report.objective",
      context.tradeoff_objective,
      context.explanation_objective,
      "must match the ranking explanation objective"
    )
  end

  defp activity_list?(activities) when is_list(activities),
    do: Enum.all?(activities, &valid_activity?/1)

  defp activity_list?(_activities), do: false

  defp valid_activity?(%{"id" => id}) when is_binary(id), do: true
  defp valid_activity?(_activity), do: false

  defp valid_timelines?(timelines) when is_list(timelines) do
    Enum.all?(timelines, fn
      %{"scenario_id" => scenario_id, "score_terms" => score_terms, "activities" => activities}
      when is_binary(scenario_id) and is_map(score_terms) ->
        activity_list?(activities)

      _timeline ->
        false
    end)
  end

  defp valid_timelines?(_timelines), do: false

  defp activity_ids(activities), do: Enum.map(activities, & &1["id"])

  defp score_term_keys(timelines) do
    timelines
    |> Enum.flat_map(&Map.keys(&1["score_terms"]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp tradeoff_field(%{"objective_tradeoff_report" => report}, field) when is_map(report),
    do: Map.get(report, field)

  defp tradeoff_field(_artifact, _field), do: nil

  defp score_report_policy(%{"score_term_report" => %{"assumptions" => assumptions}})
       when is_map(assumptions),
       do: Map.get(assumptions, "policy")

  defp score_report_policy(_artifact), do: nil

  defp validate_optional_equal(issues, _path, nil, _expected, _message), do: issues

  defp validate_optional_equal(issues, path, actual, expected, message),
    do: validate_equal(issues, path, actual, expected, message)

  defp validate_equal(issues, _path, actual, expected, _message) when actual == expected,
    do: issues

  defp validate_equal(issues, path, _actual, _expected, message),
    do: [PrimitiveValidation.error(path, message) | issues]
end
