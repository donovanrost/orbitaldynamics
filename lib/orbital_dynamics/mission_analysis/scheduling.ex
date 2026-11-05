defmodule OrbitalDynamics.MissionAnalysis.Scheduling do
  @moduledoc """
  Search controller over shared opportunity-order evaluators. Opportunity physics
  are generated once by MissionAnalysis. Each bounded trial starts from initial
  budgets/state and retains its own placement and complete feasibility evidence.
  """
  alias OrbitalDynamics.MissionAnalysis.Scheduling.{
    Greedy,
    Policy,
    Reassignment,
    Replacement,
    Commitments
  }

  alias OrbitalDynamics.Schema.JsonSafety

  def run(
        opportunities,
        requests,
        evaluate,
        policy,
        verify \\ fn activities -> {:ok, activities} end
      ) do
    policy = if policy, do: Policy.validate!(policy), else: nil
    requests = Map.new(requests, &{&1.id, &1})

    ordered =
      Enum.sort_by(
        opportunities,
        &{-requests[&1["request_id"]].value, &1["starts_at_s"], &1["asset_id"], &1["id"]}
      )

    with {:ok, _, _, _, _} = baseline <- evaluate.(ordered) do
      if policy == nil do
        append(baseline, nil)
      else
        with :ok <- baseline_commitments(baseline, policy),
             {:ok, baseline, :valid} <- verify_result(baseline, verify) do
          problem = %{
            opportunities: ordered,
            requests: requests,
            protected_request_ids: MapSet.new(policy.protected_activities, & &1["request_id"])
          }

          initial =
            metrics(baseline)
            |> Map.merge(%{
              "trial" => 1,
              "accepted" => true,
              "reason" => "greedy_baseline",
              "request_outcomes" => __MODULE__.Explanation.trial(baseline, Map.keys(requests))
            })

          history = %{
            tried_orders: MapSet.new([Enum.map(ordered, & &1["id"])]),
            trials: [initial]
          }

          loop(
            problem,
            %{order: ordered, result: baseline},
            history,
            nil,
            evaluate,
            verify,
            policy
          )
        else
          {:ok, _, {:invalid, reason}} -> {:error, reason}
          error -> error
        end
      end
    end
  end

  defp loop(problem, incumbent, history, state, evaluate, verify, policy) do
    cond do
      policy.strategy == Greedy ->
        finish(incumbent, history, policy, "greedy_complete")

      length(history.trials) >= policy.max_trials ->
        finish(incumbent, history, policy, "trial_limit_reached")

      true ->
        case policy.strategy.propose(problem, incumbent, history, state) do
          :done ->
            status =
              if policy.strategy in [Reassignment, Replacement],
                do: "neighborhood_exhausted",
                else: "strategy_complete"

            finish(incumbent, history, policy, status)

          {:candidate, order, description, state} ->
            validate_order!(order, problem.opportunities)
            ids = Enum.map(order, & &1["id"])

            if MapSet.member?(history.tried_orders, ids),
              do: raise(ArgumentError, "strategy repeated an evaluated proposal")

            description = JsonSafety.normalize_input!(description, "scheduling proposal")

            with {:ok, _, _, _, _} = result <- evaluate.(order),
                 {:ok, result, eligibility} <- verify_result(result, verify) do
              reason =
                case eligibility do
                  :valid -> acceptance(incumbent.result, result, policy)
                  {:invalid, _} -> "endpoint_ineligible"
                end

              accepted = reason == "value_improved"

              trial =
                metrics(result)
                |> Map.merge(%{
                  "trial" => length(history.trials) + 1,
                  "accepted" => accepted,
                  "reason" => reason,
                  "proposal" => description,
                  "request_outcomes" =>
                    __MODULE__.Explanation.trial(result, Map.keys(problem.requests)),
                  "added_request_ids" =>
                    served(result) |> MapSet.difference(served(incumbent.result)) |> Enum.sort(),
                  "removed_request_ids" =>
                    served(incumbent.result) |> MapSet.difference(served(result)) |> Enum.sort(),
                  "endpoint_eligibility" =>
                    if(eligibility == :valid, do: "supported", else: "ineligible")
                })

              history = %{
                tried_orders: MapSet.put(history.tried_orders, ids),
                trials: history.trials ++ [trial]
              }

              incumbent = if accepted, do: %{order: order, result: result}, else: incumbent
              loop(problem, incumbent, history, state, evaluate, verify, policy)
            else
              {:error, :planning_work_budget_exhausted} ->
                finish(incumbent, history, policy, "work_budget_exhausted")

              error ->
                error
            end
        end
    end
  end

  defp verify_result({:ok, a, d, b, r} = result, verify) do
    case verify.(a) do
      {:ok, checked} -> {:ok, {:ok, checked, d, b, r}, :valid}
      {:invalid, reason} -> {:ok, result, {:invalid, reason}}
      {:error, _} = error -> error
    end
  end

  defp validate_order!(order, original) do
    originals = Map.new(original, &{&1["id"], &1})

    unless is_list(order) and length(order) == length(original) and
             length(Enum.uniq_by(order, & &1["id"])) == length(original) and
             Enum.all?(order, &(originals[&1["id"]] === &1)),
           do:
             raise(
               ArgumentError,
               "scheduling proposal must be a permutation of the original opportunities"
             )
  end

  defp baseline_commitments({:ok, activities, _, _, _}, policy) do
    if Commitments.intact?(activities, policy.protected_activities),
      do: :ok,
      else: {:error, :protected_activity_missing_or_changed}
  end

  defp acceptance(before, candidate, policy) do
    a = metrics(before)
    b = metrics(candidate)

    cond do
      b["feasibility"] not in ["supported", "static_constraints_only"] ->
        "unsupported_candidate"

      not Commitments.intact?(elem(candidate, 1), policy.protected_activities) ->
        "protected_activity_changed"

      policy.retention == :all_served and not MapSet.subset?(served(before), served(candidate)) ->
        "lost_served_request"

      b["fulfilled_value"] <= a["fulfilled_value"] ->
        "no_value_improvement"

      true ->
        "value_improved"
    end
  end

  defp served({:ok, activities, _, _, _}), do: MapSet.new(activities, & &1["request_id"])

  defp metrics({:ok, activities, _, _, attitude}) do
    %{
      "fulfilled_value" => Enum.sum(Enum.map(activities, & &1["value"])),
      "scheduled_count" => length(activities),
      "feasibility" =>
        if(attitude, do: attitude["planning_status"], else: "static_constraints_only"),
      "attitude_model_evaluation_count" =>
        if(attitude, do: attitude["model_evaluation_count"], else: 0),
      "resource_model_evaluation_count" =>
        if(attitude && is_map(attitude["resource_feasibility"]),
          do: attitude["resource_feasibility"]["model_evaluation_count"],
          else: 0
        )
    }
  end

  defp finish(incumbent, history, policy, status) do
    trials = history.trials

    sums =
      for key <- ~w(attitude_model_evaluation_count resource_model_evaluation_count),
          into: %{},
          do: {key, Enum.sum(Enum.map(trials, & &1[key]))}

    evidence = %{
      "strategy" => Atom.to_string(policy.strategy),
      "proposal_encoding" => "opportunity_priority_order",
      "max_trials" => policy.max_trials,
      "trial_count" => length(trials),
      "status" => status,
      "baseline_value" => hd(trials)["fulfilled_value"],
      "final_value" => metrics(incumbent.result)["fulfilled_value"],
      "total_model_evaluation_counts" => sums,
      "trials" => trials,
      "limits" => [
        "each trial uses the configured placement and subsystem evaluation budgets",
        if(policy.retention == :all_served,
          do:
            "strict value improvements retaining every incumbent served request only; no global optimum or exhaustive assignment claim",
          else:
            "strict value improvements retaining exact protected placements; tentative requests may be replaced; no global optimality claim"
        ),
        "static-only evaluation does not establish attitude, path, horizon or battery feasibility"
      ]
    }

    evidence =
      if policy.strategy == Replacement or policy.protected_activities != [] or
           policy.retention != :all_served,
         do:
           Map.merge(evidence, %{
             "retention" => Atom.to_string(policy.retention),
             "protected_activities" => policy.protected_activities
           }),
         else: evidence

    evidence =
      if policy.availability,
        do: Map.put(evidence, "availability", policy.availability),
        else: evidence

    evidence =
      if policy.command_delivery,
        do:
          Map.put(
            evidence,
            "command_delivery",
            OrbitalDynamics.MissionAnalysis.Scheduling.CommandDelivery.allocation(
              policy.command_delivery
            ).report
          ),
        else: evidence

    append(incumbent.result, evidence)
  end

  defp append({:ok, a, d, b, r}, search), do: {:ok, a, d, b, r, search}
end
