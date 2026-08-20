defmodule OrbitalDynamics.CampaignPlanner.StrategyRecommendationEligibility do
  @moduledoc false

  alias OrbitalDynamics.Optimizer.HardFeasibility
  alias OrbitalDynamics.Schema.JsonSafety

  @schema_contract "strategy_recommendation_eligibility.v1"
  @ordering "eligible score descending then branch_id ascending"
  @model_limits [
    "hard_feasibility_binds_exact_computed_branch_score_terms",
    "authority_and_policy_status_comes_from_branch_policy_decision",
    "rejected_counterfactual_is_review_only_and_not_importable"
  ]
  @comparison_json_fields ~w(
    score_delta_from_recommended
    recommendation_eligibility_rank
    recommendation_hard_feasibility
    recommendation_policy_blocker
  )

  def normalize_request_option(request) when is_map(request) do
    atom_value = Map.fetch(request, :recommendation_eligibility)
    string_value = Map.fetch(request, "recommendation_eligibility")

    case {atom_value, string_value} do
      {:error, :error} ->
        :legacy

      {{:ok, value}, :error} ->
        normalize!(value)

      {:error, {:ok, value}} ->
        normalize!(value)

      {{:ok, _atom_value}, {:ok, _string_value}} ->
        raise ArgumentError,
              "recommendation_eligibility must not use both atom and string aliases"
    end
  end

  def model_limits, do: HardFeasibility.model_limits() ++ @model_limits

  def evaluate(branches, :legacy) when is_list(branches), do: :legacy

  def evaluate(branches, %{} = setting) when is_list(branches) do
    alternatives = Enum.map(branches, &alternative/1)
    {:hard, configuration} = HardFeasibility.prepare([hard_feasibility: setting], alternatives)

    evaluations =
      branches
      |> Enum.map(fn branch ->
        branch
        |> evaluation(configuration)
        |> JsonSafety.normalize_input!("strategy recommendation eligibility evaluation")
      end)
      |> Enum.sort_by(&{-&1["score"], &1["branch_id"]})

    eligible = Enum.filter(evaluations, & &1["eligible"])
    rejected = Enum.reject(evaluations, & &1["eligible"])
    selected = List.first(eligible)
    counterfactual = counterfactual(List.first(rejected))

    %{
      "schema_contract" => @schema_contract,
      "mode" => "hard",
      "status" => if(selected, do: "recommendable", else: "no_recommendable_branch"),
      "selected_branch_id" => if(selected, do: selected["branch_id"], else: :null),
      "eligible_ranked_branch_ids" => Enum.map(eligible, & &1["branch_id"]),
      "branch_count" => length(evaluations),
      "eligible_count" => length(eligible),
      "rejected_count" => length(rejected),
      "source_evidence_registry" => HardFeasibility.registry_summary(configuration),
      "evaluations" => evaluations,
      "counterfactual" => counterfactual,
      "deterministic_ordering" => @ordering,
      "model_limits" => model_limits()
    }
    |> JsonSafety.normalize_input!("strategy recommendation eligibility")
  end

  def evaluation_for(%{"evaluations" => evaluations}, branch_id) when is_list(evaluations) do
    Enum.find(evaluations, &(&1["branch_id"] == branch_id))
  end

  def normalize_comparison_row_json_values(
        %{"recommendation_eligibility_status" => _status} = row
      ) do
    Enum.reduce(@comparison_json_fields, row, fn field, acc ->
      case Map.fetch(acc, field) do
        {:ok, value} ->
          Map.put(
            acc,
            field,
            JsonSafety.normalize_input!(value, "strategy comparison #{field}")
          )

        :error ->
          acc
      end
    end)
  end

  def normalize_comparison_row_json_values(row), do: row

  def normalize_recommendation_json_values(%{"status" => status} = recommendation)
      when status in ["recommendable", "no_recommendable_branch"] do
    Enum.reduce(~w(recommended_branch_id counterfactual), recommendation, fn field, acc ->
      case Map.fetch(acc, field) do
        {:ok, value} ->
          Map.put(
            acc,
            field,
            JsonSafety.normalize_input!(value, "strategy recommendation #{field}")
          )

        :error ->
          acc
      end
    end)
  end

  def normalize_recommendation_json_values(recommendation), do: recommendation

  def normalize_review_row_json_values(row) when is_map(row) do
    row
    |> normalize_comparison_row_json_values()
    |> normalize_review_delta()
    |> normalize_nested_comparison("source_tradeoff")
    |> normalize_nested_comparison("source_branch_comparison")
    |> normalize_nested_recommendation("source_recommendation")
  end

  defp normalize_review_delta(%{"recommendation_eligibility_status" => _status} = row) do
    case Map.fetch(row, "delta") do
      {:ok, value} ->
        Map.put(
          row,
          "delta",
          JsonSafety.normalize_input!(value, "strategy recommendation review delta")
        )

      :error ->
        row
    end
  end

  defp normalize_review_delta(row), do: row

  defp normalize!(value) do
    normalized = JsonSafety.normalize_input!(value, "recommendation_eligibility")

    unless is_map(normalized) do
      raise ArgumentError, "recommendation_eligibility must be a JSON-safe map"
    end

    normalized
  end

  defp normalize_nested_comparison(row, field) do
    case Map.fetch(row, field) do
      {:ok, %{} = source} ->
        Map.put(row, field, normalize_comparison_row_json_values(source))

      _source ->
        row
    end
  end

  defp normalize_nested_recommendation(row, field) do
    case Map.fetch(row, field) do
      {:ok, %{} = source} ->
        Map.put(row, field, normalize_recommendation_json_values(source))

      _source ->
        row
    end
  end

  defp alternative(branch) do
    %{
      "id" => branch.id,
      "parameters" => branch.score_terms
    }
  end

  defp evaluation(branch, configuration) do
    hard_feasibility = HardFeasibility.evaluate(alternative(branch), configuration)
    policy_decision = branch.policy_decision
    policy_blocked? = policy_blocked?(policy_decision)
    hard_feasible? = hard_feasibility["eligible"] == true
    eligible? = hard_feasible? and not policy_blocked?

    %{
      "branch_id" => branch.id,
      "score" => branch.score,
      "branch_score_term_identity" =>
        HardFeasibility.parameter_content_identity(branch.score_terms),
      "status" => status(hard_feasible?, policy_blocked?),
      "eligible" => eligible?,
      "hard_feasibility" => hard_feasibility,
      "policy_blocker" => if(policy_blocked?, do: policy_decision, else: :null),
      "blocker_reasons" => blocker_reasons(hard_feasibility, policy_decision, policy_blocked?)
    }
  end

  defp policy_blocked?(%{"classification" => "blocked_by_policy"}), do: true
  defp policy_blocked?(_decision), do: false

  defp status(true, false), do: "eligible"
  defp status(false, false), do: "infeasible"
  defp status(true, true), do: "policy_blocked"
  defp status(false, true), do: "infeasible_and_policy_blocked"

  defp blocker_reasons(hard_feasibility, policy_decision, policy_blocked?) do
    hard_reasons = Map.get(hard_feasibility, "blocker_reasons", [])

    policy_reasons =
      if policy_blocked? do
        rule_reasons =
          policy_decision
          |> Map.get("rule_matches", [])
          |> Enum.filter(&(&1["classification"] == "blocked_by_policy"))
          |> Enum.map(&(&1["reason"] || &1["rule_id"]))
          |> Enum.filter(&is_binary/1)

        authority_reason =
          get_in(policy_decision, ["authority_context_evaluation", "reason_code"])

        ["blocked_by_policy", authority_reason | rule_reasons]
      else
        []
      end

    (hard_reasons ++ policy_reasons)
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp counterfactual(nil), do: :null

  defp counterfactual(evaluation) do
    evaluation
    |> Map.put("review_only", true)
    |> Map.put("importable", false)
  end
end
