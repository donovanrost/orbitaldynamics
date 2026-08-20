defmodule OrbitalDynamics.CampaignPlanner.StrategyArtifact do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{PlanBranch, StrategyRecommendation}

  def base_artifact(request, source_plan_id, reports, policy_maps, schema_version) do
    branch_maps = Map.fetch!(reports, :branch_maps)
    recommendation = Map.fetch!(reports, :recommendation)

    %{
      "schema_version" => schema_version,
      "generated_at" => DateTime.to_iso8601(request.generated_at),
      "planner" => "OrbitalDynamics.CampaignPlanner.V3",
      "source_plan_id" => source_plan_id,
      "source_repair_id" => get_in(request.prior_plan, ["repair_metadata", "repair_id"]),
      "mission_state_snapshot" => request.mission_state,
      "branches" => branch_maps,
      "recommendation" => recommendation_map(recommendation),
      "branch_comparison_report" => Map.fetch!(reports, :branch_comparison),
      "score_term_report" => Map.fetch!(reports, :score_term),
      "objective_tradeoff_report" => Map.fetch!(reports, :objective_tradeoff),
      "ranking_comparison_report" => Map.fetch!(reports, :ranking_comparison),
      "pareto_frontier_report" => Map.fetch!(reports, :pareto_frontier),
      "strategy_policy" => Map.fetch!(policy_maps, :strategy),
      "approval_policy" => Map.fetch!(policy_maps, :approval),
      "operational_feedback" => request.operational_feedback,
      "operational_feedback_provenance" => request.operational_feedback_provenance,
      "assumptions" => assumptions(request),
      "provenance" => provenance(request.prior_plan, source_plan_id),
      "strategy_metadata" => metadata(request, branch_maps, source_plan_id)
    }
    |> maybe_put("eligibility_status", recommendation.eligibility_status)
    |> maybe_put("authority_context", recommendation.authority_context)
    |> maybe_put("authority_context_evaluation", recommendation.authority_context_evaluation)
  end

  def branch_map(%PlanBranch{} = branch) do
    branch_map = %{
      "branch_id" => branch.id,
      "label" => branch.label,
      "probability" => branch.probability,
      "events" => branch.events,
      "candidate_plan" => branch.candidate_plan,
      "repair_result" => branch.repair_result,
      "score" => branch.score,
      "score_terms" => branch.score_terms,
      "warnings" => branch.warnings,
      "risk_indicators" => branch.risk_indicators,
      "approval_status" => branch.approval_status,
      "approval_requirements" => branch.approval_requirements,
      "approval_rule_matches" => branch.approval_rule_matches,
      "policy_decision" => branch.policy_decision,
      "derived_source" => branch.derived_source,
      "resource_impacts" => branch.resource_impacts,
      "feedback_adjustments" => branch.feedback_adjustments,
      "objective_satisfaction" => branch.objective_satisfaction,
      "feasibility_summary" => branch.feasibility_summary,
      "assumptions" => branch.assumptions,
      "provenance" => branch.provenance,
      "tradeoffs" => branch.tradeoffs
    }

    case branch.resource_projection_report do
      nil -> branch_map
      report -> Map.put(branch_map, "resource_projection_report", report)
    end
  end

  def recommendation_map(%StrategyRecommendation{} = recommendation) do
    %{
      "schema_contract" => "strategy_recommendation.v1",
      "status" => "pass",
      "recommended_branch_id" => recommendation.recommended_branch_id,
      "approval_status" => recommendation.approval_status,
      "reason" => recommendation.reason,
      "ranked_branch_ids" => recommendation.ranked_branch_ids,
      "tradeoffs" => recommendation.tradeoffs,
      "explanation" => recommendation.explanation,
      "risks_remaining" => recommendation.risks_remaining,
      "requires_approval" => recommendation.requires_approval
    }
    |> maybe_put("eligibility_status", recommendation.eligibility_status)
    |> maybe_put("authority_context", recommendation.authority_context)
    |> maybe_put("authority_context_evaluation", recommendation.authority_context_evaluation)
  end

  def assumptions(request) do
    %{
      "strategy_model" => "explicit_what_if_branch_comparison_over_v2_repair",
      "branch_evaluator" => "deterministic_event_overlay_then_repair",
      "candidate_plan_model" => "v2_repaired_plan_plus_strategic_additions",
      "branch_generation_policy" => request.branch_generation_policy,
      "resource_model" => "thin_mission_state_resource_summary",
      "feedback_model" => "deterministic_success_rate_and_throughput_adjustment",
      "mission_state_assumptions" => Map.get(request.mission_state, "assumptions", %{}),
      "approval_boundary" => "recommendations_only_no_command_execution",
      "cadence_integration" => "future_source_of_realized_operations_no_api_or_database_writes"
    }
  end

  def provenance(prior_plan, source_plan_id) do
    %{
      "source_plan_id" => source_plan_id,
      "source_planner" => Map.get(prior_plan, "planner"),
      "source_plan_generated_at" => Map.get(prior_plan, "generated_at"),
      "source_provenance" => Map.get(prior_plan, "provenance", %{})
    }
  end

  def metadata(request, branch_maps, source_plan_id) do
    %{
      "strategy_id" => strategy_id(request, branch_maps, source_plan_id),
      "branch_count" => length(branch_maps),
      "baseline_branch_id" => baseline_branch_id(branch_maps),
      "cadence_integration" => "artifact_only_no_api_or_database_writes"
    }
  end

  defp strategy_id(request, branch_maps, source_plan_id) do
    stable_input =
      {
        source_plan_id,
        strip_realized_snapshot_model_limits(request.mission_state),
        request.strategy_policy,
        request.approval_policy,
        strip_realized_snapshot_model_limits(branch_maps)
      }
      |> encode_value()
      |> canonical_hash_term()

    :crypto.hash(
      :sha256,
      :erlang.term_to_binary(stable_input)
    )
    |> Base.encode16(case: :lower)
  end

  defp canonical_hash_term(%{} = map) do
    map
    |> Enum.map(fn {key, value} -> {to_string(key), canonical_hash_term(value)} end)
    |> Enum.sort_by(fn {key, _value} -> key end)
  end

  defp canonical_hash_term(values) when is_list(values),
    do: Enum.map(values, &canonical_hash_term/1)

  defp canonical_hash_term(value), do: value

  defp strip_realized_snapshot_model_limits(
         %{"schema_contract" => "realized_state_snapshot.v1"} = snapshot
       ) do
    snapshot
    |> Map.delete("model_limits")
    |> Map.new(fn {key, value} -> {key, strip_realized_snapshot_model_limits(value)} end)
  end

  defp strip_realized_snapshot_model_limits(value) when is_map(value) do
    value
    |> Map.new(fn {key, nested_value} ->
      {key, strip_realized_snapshot_model_limits(nested_value)}
    end)
  end

  defp strip_realized_snapshot_model_limits(values) when is_list(values) do
    Enum.map(values, &strip_realized_snapshot_model_limits/1)
  end

  defp strip_realized_snapshot_model_limits(value), do: value

  defp baseline_branch_id(branch_maps) do
    case Enum.find(branch_maps, &(&1["branch_id"] == "baseline")) do
      nil -> nil
      branch -> branch["branch_id"]
    end
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

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
