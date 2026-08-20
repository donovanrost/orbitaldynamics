defmodule OrbitalDynamics.Schema.CampaignPlanSearchContracts do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.LocalSearchSelection
  alias OrbitalDynamics.Optimizer.{HardFeasibility, SourceEvidenceRegistry}
  alias OrbitalDynamics.Schema.{PrimitiveValidation, StableIdValidation}
  alias OrbitalDynamics.Search.Local
  alias OrbitalDynamics.Optimizer

  @trace_contract "campaign_plan_search_trace.v1"
  @selection_contract "v1_outer_local_search_inner_greedy"
  @objective "maximize first ranked timeline aggregate score"
  @score_term "first_ranked_timeline_score"
  @registry_contract "local_search_source_evidence_registry.v1"
  @registry_trust_boundary "caller_supplied_trusted_composition_snapshot"
  @deterministic_ordering [
    "hard-feasibility eligible alternatives only",
    "objective score descending",
    "generation_index ascending",
    "alternative id ascending",
    "infeasible alternatives generation_index then id ascending"
  ]
  @assumptions %{
    "score_rule" => "sum_of_score_terms",
    "score_terms_function" => "caller_supplied_and_expected_pure",
    "hard_feasibility" =>
      "caller_supplied_trusted_composition_registry_and_typed_candidate_evidence",
    "registry_authentication" => "not_provided",
    "feasibility_timing" => "before_ranking",
    "external_solver" => false,
    "iterations" => 1
  }
  @required_fields ~w(
    schema_contract id plan_id status selection_contract objective objective_direction
    base_scoring_policy selected_scoring_policy searched_scoring_policy_keys fixed_constraints
    selected_alternative_id selected_alternative selected_timeline_scenario_id
    selected_timeline_score selected_activity_ids selected_activity_count search_result
  )

  def validate_plan(issues, artifact) do
    case Map.get(artifact, "optimizer_search_trace") do
      nil ->
        validate_absent_handoffs(issues, artifact)

      :null ->
        validate_absent_handoffs(issues, artifact)

      %{} = trace ->
        issues
        |> validate_trace("$.optimizer_search_trace", trace, @required_fields)
        |> validate_plan_binding(artifact, trace)
        |> validate_present_handoffs(artifact, trace)

      _trace ->
        [error("$.optimizer_search_trace", "must be a map") | issues]
    end
  end

  def validate_trace(issues, path, trace, required_fields)
      when is_list(issues) and is_binary(path) and is_map(trace) and is_list(required_fields) do
    issues
    |> PrimitiveValidation.require_fields(path, trace, required_fields)
    |> PrimitiveValidation.expect_equal(path, trace, "schema_contract", @trace_contract)
    |> PrimitiveValidation.expect_equal(path, trace, "selection_contract", @selection_contract)
    |> PrimitiveValidation.expect_equal(path, trace, "objective", @objective)
    |> PrimitiveValidation.expect_equal(path, trace, "objective_direction", "maximize")
    |> PrimitiveValidation.expect_type(path, trace, "id", :binary)
    |> PrimitiveValidation.expect_type(path, trace, "plan_id", :binary)
    |> PrimitiveValidation.expect_type(path, trace, "status", :binary)
    |> PrimitiveValidation.expect_type(path, trace, "base_scoring_policy", :map)
    |> PrimitiveValidation.expect_optional_type(path, trace, "selected_scoring_policy", :map)
    |> PrimitiveValidation.expect_type(path, trace, "searched_scoring_policy_keys", :list)
    |> PrimitiveValidation.expect_type(path, trace, "fixed_constraints", :map)
    |> PrimitiveValidation.expect_optional_type(path, trace, "selected_alternative_id", :binary)
    |> PrimitiveValidation.expect_optional_type(path, trace, "selected_alternative", :map)
    |> PrimitiveValidation.expect_optional_type(
      path,
      trace,
      "selected_timeline_scenario_id",
      :binary
    )
    |> PrimitiveValidation.expect_optional_number(path, trace, "selected_timeline_score")
    |> PrimitiveValidation.expect_type(path, trace, "selected_activity_ids", :list)
    |> PrimitiveValidation.expect_type(path, trace, "selected_activity_count", :integer)
    |> PrimitiveValidation.expect_type(path, trace, "search_result", :map)
    |> StableIdValidation.validate_stable_ids(path, trace, ["id", "plan_id"])
    |> validate_trace_identity(path, trace)
    |> validate_policy_fields(path, trace)
    |> validate_search_result(path, trace)
    |> validate_trace_outcome(path, trace)
  end

  def validate_trace(issues, path, _trace, _required_fields),
    do: [error(path, "must be a map") | issues]

  defp validate_trace_identity(issues, path, trace) do
    expected_id = "campaign_plan_search_trace:#{trace["plan_id"]}"

    issues
    |> ensure(trace["id"] == expected_id, "#{path}.id", "must be bound to plan_id")
    |> ensure(
      trace["status"] in ["selected_plan", "no_selected_plan"],
      "#{path}.status",
      "must be selected_plan or no_selected_plan"
    )
  end

  defp validate_policy_fields(issues, path, trace) do
    base_policy = trace["base_scoring_policy"]
    searched_keys = trace["searched_scoring_policy_keys"]
    supported = LocalSearchSelection.numeric_policy_keys()

    issues =
      if is_map(base_policy) do
        Enum.reduce(supported, issues, fn key, acc ->
          if Map.has_key?(base_policy, key) do
            ensure(
              acc,
              finite_number?(base_policy[key]),
              "#{path}.base_scoring_policy.#{key}",
              "must be a finite number"
            )
          else
            acc
          end
        end)
      else
        issues
      end

    if is_list(searched_keys) do
      issues
      |> ensure(searched_keys != [], "#{path}.searched_scoring_policy_keys", "must not be empty")
      |> ensure(
        searched_keys == searched_keys |> Enum.uniq() |> Enum.sort(),
        "#{path}.searched_scoring_policy_keys",
        "must be unique and sorted"
      )
      |> ensure(
        Enum.all?(searched_keys, &(&1 in supported)),
        "#{path}.searched_scoring_policy_keys",
        "contains unsupported V1 scoring keys"
      )
      |> ensure(
        is_map(base_policy) and Enum.all?(searched_keys, &Map.has_key?(base_policy, &1)),
        "#{path}.searched_scoring_policy_keys",
        "must identify base scoring policy keys"
      )
    else
      issues
    end
  end

  defp validate_search_result(issues, path, %{"search_result" => %{} = result} = trace) do
    alternatives = Map.get(result, "alternatives")
    evaluations = Map.get(result, "candidate_feasibility_evaluations")
    registry = Map.get(result, "source_evidence_registry")

    issues
    |> require_result_fields(path, result)
    |> ensure(
      result["model"] == "deterministic_bounded_axis_step_local_search",
      "#{path}.search_result.model",
      "must retain the existing local-search model"
    )
    |> ensure(
      result["objective"] == @objective,
      "#{path}.search_result.objective",
      "must use the campaign timeline objective"
    )
    |> ensure(
      result["objective_direction"] == "maximize",
      "#{path}.search_result.objective_direction",
      "must maximize"
    )
    |> ensure(
      result["feasibility_mode"] == "hard",
      "#{path}.search_result.feasibility_mode",
      "must use hard feasibility"
    )
    |> ensure(
      result["model_limits"] ==
        HardFeasibility.search_model_limits(Optimizer.local_search_model_limits()),
      "#{path}.search_result.model_limits",
      "must exactly retain current hard-feasibility local-search limits"
    )
    |> ensure(
      result["deterministic_ordering"] == @deterministic_ordering,
      "#{path}.search_result.deterministic_ordering",
      "must retain the existing hard-feasibility ordering"
    )
    |> ensure(
      result["assumptions"] == @assumptions,
      "#{path}.search_result.assumptions",
      "must retain the existing hard-feasibility assumptions and trust boundary"
    )
    |> validate_registry_summary(path, registry)
    |> validate_neighborhood(path, result)
    |> validate_alternatives(path, result, alternatives, evaluations, registry)
    |> validate_result_counts_and_selection(path, result, alternatives)
    |> validate_trace_search_copies(path, trace, result, alternatives)
  end

  defp validate_search_result(issues, _path, _trace), do: issues

  defp require_result_fields(issues, path, result) do
    PrimitiveValidation.require_fields(
      issues,
      "#{path}.search_result",
      result,
      ~w(
        model objective objective_direction seed_id seed_score selected_id selected_score
        improved improvement_from_seed evaluated_count eligible_count infeasible_count
        feasibility_mode source_evidence_registry candidate_feasibility_evaluations
        recommendation_outcome feasibility_transition alternatives rejected_moves neighborhood
        deterministic_ordering model_limits assumptions
      )
    )
  end

  defp validate_registry_summary(issues, path, registry) when is_map(registry) do
    issues
    |> ensure(
      registry["schema_contract"] == @registry_contract,
      "#{path}.search_result.source_evidence_registry.schema_contract",
      "must retain the typed source registry contract"
    )
    |> ensure(
      registry["trust_boundary"] == @registry_trust_boundary,
      "#{path}.search_result.source_evidence_registry.trust_boundary",
      "must retain the trusted routing boundary"
    )
    |> ensure(
      StableIdValidation.valid?(registry["id"]),
      "#{path}.search_result.source_evidence_registry.id",
      "must be a stable registry identity"
    )
  end

  defp validate_registry_summary(issues, path, _registry),
    do: [error("#{path}.search_result.source_evidence_registry", "must be a map") | issues]

  defp validate_neighborhood(issues, path, result) do
    neighborhood = result["neighborhood"]

    with %{} <- neighborhood,
         %{} = seed <- neighborhood["seed_parameters"],
         %{} = steps <- neighborhood["steps"],
         %{} = bounds <- neighborhood["bounds"],
         seed_id when is_binary(seed_id) <- neighborhood["seed_id"],
         true <- String.ends_with?(seed_id, ":seed"),
         max when is_integer(max) <- neighborhood["max_alternatives"],
         {:ok, tuple_bounds} <- tuple_bounds(bounds) do
      prefix = String.trim_trailing(seed_id, ":seed")

      expected =
        Local.neighborhood(seed,
          steps: steps,
          bounds: tuple_bounds,
          id_prefix: prefix,
          max_alternatives: max
        )

      issues
      |> ensure(
        neighborhood == Map.drop(expected, ["alternatives", "rejected_moves"]),
        "#{path}.search_result.neighborhood",
        "must exactly describe the generated bounded neighborhood"
      )
      |> ensure(
        result["rejected_moves"] == expected["rejected_moves"],
        "#{path}.search_result.rejected_moves",
        "must exactly retain bound and alternative-budget rejections"
      )
      |> validate_alternative_skeletons(path, result["alternatives"], expected["alternatives"])
    else
      _invalid ->
        [
          error(
            "#{path}.search_result.neighborhood",
            "must be a reproducible bounded neighborhood"
          )
          | issues
        ]
    end
  rescue
    _error ->
      [
        error("#{path}.search_result.neighborhood", "must be a reproducible bounded neighborhood")
        | issues
      ]
  end

  defp validate_alternative_skeletons(issues, path, alternatives, expected)
       when is_list(alternatives) do
    actual_by_id = Map.new(alternatives, &{&1["id"], &1})

    issues
    |> ensure(
      length(alternatives) == length(expected),
      "#{path}.search_result.alternatives",
      "must contain exactly the generated bounded alternatives"
    )
    |> then(fn issues ->
      Enum.reduce(expected, issues, fn row, acc ->
        actual = actual_by_id[row["id"]]

        ensure(
          acc,
          is_map(actual) and Map.take(actual, ~w(id generation_index parameters move)) == row,
          "#{path}.search_result.alternatives",
          "must retain every generated alternative without mutation"
        )
      end)
    end)
  end

  defp validate_alternative_skeletons(issues, _path, _alternatives, _expected), do: issues

  defp validate_alternatives(issues, path, result, alternatives, evaluations, registry)
       when is_list(alternatives) and is_list(evaluations) do
    alternative_ids = Enum.map(alternatives, & &1["id"])
    evaluation_ids = Enum.map(evaluations, & &1["alternative_id"])
    evaluations_by_id = Map.new(evaluations, &{&1["alternative_id"], &1})
    seed = Enum.find(alternatives, &(&1["id"] == result["seed_id"]))

    issues =
      issues
      |> ensure(
        length(alternative_ids) == length(Enum.uniq(alternative_ids)),
        "#{path}.search_result.alternatives",
        "must have unique alternative IDs"
      )
      |> ensure(
        length(evaluation_ids) == length(Enum.uniq(evaluation_ids)),
        "#{path}.search_result.candidate_feasibility_evaluations",
        "must have unique alternative IDs"
      )
      |> ensure(
        Enum.sort(alternative_ids) == Enum.sort(evaluation_ids),
        "#{path}.search_result.candidate_feasibility_evaluations",
        "must exactly cover evaluated alternatives"
      )
      |> ensure(
        evaluation_ids ==
          alternatives
          |> Enum.sort_by(&{&1["generation_index"], &1["id"]})
          |> Enum.map(& &1["id"]),
        "#{path}.search_result.candidate_feasibility_evaluations",
        "must retain generation order"
      )
      |> ensure(
        is_map(seed),
        "#{path}.search_result.seed_id",
        "must identify one evaluated alternative"
      )

    Enum.reduce(alternatives, issues, fn alternative, acc ->
      evaluation = evaluations_by_id[alternative["id"]]

      acc
      |> validate_alternative(path, alternative, seed, result)
      |> validate_feasibility(path, alternative, evaluation, registry)
    end)
  end

  defp validate_alternatives(issues, path, _result, _alternatives, _evaluations, _registry),
    do: [
      error(
        "#{path}.search_result.alternatives",
        "alternatives and feasibility evaluations must be lists"
      )
      | issues
    ]

  defp validate_alternative(issues, path, alternative, seed, result) when is_map(alternative) do
    score_terms = alternative["score_terms"]
    score = alternative["score"]
    eligibility = get_in(alternative, ["candidate_feasibility", "eligible"])
    selected = alternative["id"] == result["selected_id"]
    expected_explanation = selection_explanation(alternative, result)

    issues
    |> ensure(
      is_map(score_terms) and Map.keys(score_terms) == [@score_term],
      "#{path}.search_result.alternatives",
      "must use only the first ranked timeline score term"
    )
    |> ensure(
      is_map(score_terms) and score_terms[@score_term] == score,
      "#{path}.search_result.alternatives",
      "score must equal the first ranked timeline score term"
    )
    |> ensure(
      alternative["selected"] == selected,
      "#{path}.search_result.alternatives",
      "selected flag must match selected_id"
    )
    |> ensure(
      alternative["selection_explanation"] == expected_explanation,
      "#{path}.search_result.alternatives",
      "selection explanation is stale"
    )
    |> ensure(
      not is_map(seed) or alternative["score_delta_from_seed"] == score - seed["score"],
      "#{path}.search_result.alternatives",
      "score delta from seed is stale"
    )
    |> ensure(
      (eligibility == true and is_integer(alternative["rank"]) and alternative["rank"] > 0) or
        (eligibility == false and nullish?(alternative["rank"])),
      "#{path}.search_result.alternatives",
      "only feasible alternatives may receive a rank"
    )
  end

  defp validate_alternative(issues, path, _alternative, _seed, _result),
    do: [error("#{path}.search_result.alternatives", "must contain maps") | issues]

  defp validate_feasibility(issues, path, alternative, evaluation, registry)
       when is_map(evaluation) do
    nested = alternative["candidate_feasibility"]
    eligible = evaluation["eligible"]
    blockers = evaluation["blockers"]
    blocker_reasons = evaluation["blocker_reasons"]
    bindings = evaluation["evidence_bindings"]
    expected_identity = parameter_identity(alternative["parameters"])

    issues =
      issues
      |> ensure(
        nested == evaluation,
        "#{path}.search_result.alternatives",
        "embedded feasibility must exactly copy the evaluation list"
      )
      |> ensure(
        evaluation["schema_contract"] == "candidate_feasibility.v1",
        "#{path}.search_result.candidate_feasibility_evaluations",
        "must retain candidate_feasibility.v1"
      )
      |> ensure(
        evaluation["mode"] == "hard",
        "#{path}.search_result.candidate_feasibility_evaluations",
        "must retain hard mode"
      )
      |> ensure(
        evaluation["alternative_id"] == alternative["id"],
        "#{path}.search_result.candidate_feasibility_evaluations",
        "must bind to the exact alternative"
      )
      |> ensure(
        evaluation["parameter_content_identity"] == expected_identity,
        "#{path}.search_result.candidate_feasibility_evaluations",
        "parameter content identity is stale"
      )
      |> ensure(
        StableIdValidation.valid?(evaluation["parameter_revision"]),
        "#{path}.search_result.candidate_feasibility_evaluations",
        "parameter revision must be a stable identity"
      )
      |> ensure(
        is_map(registry) and evaluation["source_evidence_registry_id"] == registry["id"],
        "#{path}.search_result.candidate_feasibility_evaluations",
        "source evidence registry ID is stale"
      )
      |> ensure(
        evaluation["model_limits"] == HardFeasibility.model_limits(),
        "#{path}.search_result.candidate_feasibility_evaluations",
        "hard-feasibility limits are stale"
      )
      |> ensure(
        is_boolean(eligible),
        "#{path}.search_result.candidate_feasibility_evaluations",
        "eligible must be boolean"
      )
      |> ensure(
        evaluation["status"] == if(eligible, do: "feasible", else: "infeasible"),
        "#{path}.search_result.candidate_feasibility_evaluations",
        "status must match eligibility"
      )
      |> ensure(
        is_list(blockers) and is_list(blocker_reasons),
        "#{path}.search_result.candidate_feasibility_evaluations",
        "blockers and blocker reasons must be lists"
      )
      |> ensure(
        blocker_reasons == reasons(blockers),
        "#{path}.search_result.candidate_feasibility_evaluations",
        "blocker reasons must exactly summarize blockers"
      )

    if eligible do
      issues
      |> ensure(
        blockers == [],
        "#{path}.search_result.candidate_feasibility_evaluations",
        "feasible alternatives cannot contain blockers"
      )
      |> ensure(
        StableIdValidation.valid?(evaluation["spacecraft_id"]),
        "#{path}.search_result.candidate_feasibility_evaluations",
        "feasible evidence must bind one spacecraft"
      )
      |> ensure(
        Enum.all?(evaluation["threshold_evaluations"] || [], &(&1["status"] == "pass")),
        "#{path}.search_result.candidate_feasibility_evaluations",
        "feasible threshold evaluations must pass"
      )
      |> validate_eligible_bindings(path, bindings)
    else
      ensure(
        issues,
        blockers != [],
        "#{path}.search_result.candidate_feasibility_evaluations",
        "infeasible alternatives must retain blockers"
      )
    end
  end

  defp validate_feasibility(issues, path, _alternative, _evaluation, _registry),
    do: [
      error("#{path}.search_result.candidate_feasibility_evaluations", "must contain maps")
      | issues
    ]

  defp validate_eligible_bindings(issues, path, bindings) when is_map(bindings) do
    Enum.reduce(~w(resource_state_trace downlink_link_budget), issues, fn key, acc ->
      binding = bindings[key]

      acc
      |> ensure(
        is_map(binding),
        "#{path}.search_result.candidate_feasibility_evaluations",
        "eligible evidence binding #{key} must be a map"
      )
      |> ensure(
        is_map(binding) and binding["id"] == binding["expected_id"],
        "#{path}.search_result.candidate_feasibility_evaluations",
        "eligible evidence binding #{key} must match the registry identity"
      )
      |> ensure(
        is_map(binding) and StableIdValidation.valid?(binding["revision"]),
        "#{path}.search_result.candidate_feasibility_evaluations",
        "eligible evidence binding #{key} must retain a revision"
      )
    end)
  end

  defp validate_eligible_bindings(issues, path, _bindings),
    do: [
      error(
        "#{path}.search_result.candidate_feasibility_evaluations",
        "eligible evidence bindings must be a map"
      )
      | issues
    ]

  defp validate_result_counts_and_selection(issues, path, result, alternatives)
       when is_list(alternatives) do
    eligible =
      Enum.filter(alternatives, &(get_in(&1, ["candidate_feasibility", "eligible"]) == true))

    infeasible =
      Enum.reject(alternatives, &(get_in(&1, ["candidate_feasibility", "eligible"]) == true))

    expected_eligible = Enum.sort_by(eligible, &{-&1["score"], &1["generation_index"], &1["id"]})
    expected_infeasible = Enum.sort_by(infeasible, &{&1["generation_index"], &1["id"]})
    expected_order = Enum.map(expected_eligible ++ expected_infeasible, & &1["id"])
    selected = List.first(expected_eligible)
    seed = Enum.find(alternatives, &(&1["id"] == result["seed_id"]))
    seed_eligible = is_map(seed) and get_in(seed, ["candidate_feasibility", "eligible"]) == true
    improvement = if selected && seed_eligible, do: selected["score"] - seed["score"]

    expected_ranks =
      expected_eligible
      |> Enum.with_index(1)
      |> Map.new(fn {alternative, rank} -> {alternative["id"], rank} end)

    ranks_match? =
      Enum.all?(alternatives, fn alternative ->
        alternative["rank"] == Map.get(expected_ranks, alternative["id"])
      end)

    expected_outcome = HardFeasibility.outcome(selected, length(eligible), length(infeasible))

    issues
    |> ensure(
      result["evaluated_count"] == length(alternatives),
      "#{path}.search_result.evaluated_count",
      "must match alternatives"
    )
    |> ensure(
      result["seed_score"] == value(seed, "score"),
      "#{path}.search_result.seed_score",
      "must match the generated seed alternative"
    )
    |> ensure(
      result["eligible_count"] == length(eligible),
      "#{path}.search_result.eligible_count",
      "must match feasible alternatives"
    )
    |> ensure(
      result["infeasible_count"] == length(infeasible),
      "#{path}.search_result.infeasible_count",
      "must match infeasible alternatives"
    )
    |> ensure(
      Enum.map(alternatives, & &1["id"]) == expected_order,
      "#{path}.search_result.alternatives",
      "must rank feasible alternatives before infeasible alternatives"
    )
    |> ensure(
      ranks_match?,
      "#{path}.search_result.alternatives",
      "feasible ranks must be contiguous objective order and infeasible ranks nil"
    )
    |> ensure(
      result["selected_id"] == value(selected, "id"),
      "#{path}.search_result.selected_id",
      "must identify the first feasible ranked alternative"
    )
    |> ensure(
      result["selected_score"] == value(selected, "score"),
      "#{path}.search_result.selected_score",
      "must match the selected alternative"
    )
    |> ensure(
      result["improvement_from_seed"] == improvement,
      "#{path}.search_result.improvement_from_seed",
      "must match the feasible seed comparison"
    )
    |> ensure(
      result["improved"] == (is_number(improvement) and improvement > 0),
      "#{path}.search_result.improved",
      "must match improvement_from_seed"
    )
    |> ensure(
      result["recommendation_outcome"] == expected_outcome,
      "#{path}.search_result.recommendation_outcome",
      "must exactly retain the hard-feasibility outcome"
    )
    |> ensure(
      result["feasibility_transition"] == feasibility_transition(seed, selected),
      "#{path}.search_result.feasibility_transition",
      "must exactly retain the seed feasibility transition"
    )
  end

  defp validate_result_counts_and_selection(issues, path, _result, _alternatives),
    do: [error("#{path}.search_result.alternatives", "must be a list") | issues]

  defp validate_trace_search_copies(issues, path, trace, result, alternatives) do
    alternatives = if is_list(alternatives), do: alternatives, else: []
    selected = Enum.find(alternatives, &(is_map(&1) and &1["id"] == result["selected_id"]))
    base_policy = trace["base_scoring_policy"]

    selected_policy =
      if is_map(selected) and is_map(base_policy) and is_map(selected["parameters"]),
        do: Map.merge(base_policy, selected["parameters"])

    expected_seed =
      if is_map(base_policy),
        do: Map.take(base_policy, LocalSearchSelection.numeric_policy_keys())

    issues
    |> ensure(
      trace["selected_alternative_id"] == result["selected_id"],
      "#{path}.selected_alternative_id",
      "must copy search_result.selected_id"
    )
    |> ensure(
      trace["selected_alternative"] == selected,
      "#{path}.selected_alternative",
      "must exactly copy the selected search alternative"
    )
    |> ensure(
      trace["selected_scoring_policy"] == selected_policy,
      "#{path}.selected_scoring_policy",
      "must apply the selected alternative to the base campaign policy"
    )
    |> ensure(
      trace["selected_timeline_score"] == value(selected, "score"),
      "#{path}.selected_timeline_score",
      "must equal the selected alternative objective score"
    )
    |> ensure(
      trace["searched_scoring_policy_keys"] == get_in(result, ["neighborhood", "step_parameters"]),
      "#{path}.searched_scoring_policy_keys",
      "must copy the bounded neighborhood step keys"
    )
    |> ensure(
      get_in(result, ["neighborhood", "seed_parameters"]) == expected_seed,
      "#{path}.search_result.neighborhood.seed_parameters",
      "must be exactly seeded from supported campaign scoring-policy keys"
    )
  end

  defp validate_trace_outcome(issues, path, trace) do
    case trace["status"] do
      "selected_plan" ->
        issues
        |> ensure(
          not nullish?(trace["selected_alternative_id"]),
          "#{path}.selected_alternative_id",
          "is required for a selected plan"
        )
        |> ensure(
          is_map(trace["selected_alternative"]),
          "#{path}.selected_alternative",
          "is required for a selected plan"
        )
        |> ensure(
          is_map(trace["selected_scoring_policy"]),
          "#{path}.selected_scoring_policy",
          "is required for a selected plan"
        )
        |> ensure(
          StableIdValidation.valid?(trace["selected_timeline_scenario_id"]),
          "#{path}.selected_timeline_scenario_id",
          "must be a stable scenario ID"
        )
        |> ensure(
          is_number(trace["selected_timeline_score"]),
          "#{path}.selected_timeline_score",
          "is required for a selected plan"
        )
        |> ensure(
          is_list(trace["selected_activity_ids"]) and
            trace["selected_activity_count"] == length(trace["selected_activity_ids"]),
          "#{path}.selected_activity_count",
          "must match selected activity IDs"
        )

      "no_selected_plan" ->
        issues
        |> ensure(
          nullish?(trace["selected_alternative_id"]),
          "#{path}.selected_alternative_id",
          "must be null when no plan is selected"
        )
        |> ensure(
          nullish?(trace["selected_alternative"]),
          "#{path}.selected_alternative",
          "must be null when no plan is selected"
        )
        |> ensure(
          nullish?(trace["selected_scoring_policy"]),
          "#{path}.selected_scoring_policy",
          "must be null when no plan is selected"
        )
        |> ensure(
          nullish?(trace["selected_timeline_scenario_id"]),
          "#{path}.selected_timeline_scenario_id",
          "must be null when no plan is selected"
        )
        |> ensure(
          nullish?(trace["selected_timeline_score"]),
          "#{path}.selected_timeline_score",
          "must be null when no plan is selected"
        )
        |> ensure(
          trace["selected_activity_ids"] == [],
          "#{path}.selected_activity_ids",
          "must be empty when no plan is selected"
        )
        |> ensure(
          trace["selected_activity_count"] == 0,
          "#{path}.selected_activity_count",
          "must be zero when no plan is selected"
        )
        |> ensure(
          get_in(trace, ["search_result", "selected_id"]) in [nil, :null],
          "#{path}.search_result.selected_id",
          "must be null when no plan is selected"
        )

      _status ->
        issues
    end
  end

  defp validate_plan_binding(issues, artifact, trace) do
    first_timeline =
      case Map.get(artifact, "ranked_timelines", []) do
        timelines when is_list(timelines) -> List.first(timelines)
        _timelines -> nil
      end

    activity_ids =
      case Map.get(artifact, "activities", []) do
        activities when is_list(activities) ->
          Enum.map(activities, &if(is_map(&1), do: &1["id"]))

        _activities ->
          :invalid
      end

    policy = get_in(artifact, ["optimizer_contract", "scoring_policy"])

    issues
    |> ensure(
      trace["status"] == "selected_plan",
      "$.optimizer_search_trace.status",
      "embedded campaign traces must select a plan"
    )
    |> ensure(
      trace["plan_id"] == artifact["plan_id"],
      "$.optimizer_search_trace.plan_id",
      "must match the enclosing plan"
    )
    |> ensure(
      trace["fixed_constraints"] == get_in(artifact, ["optimizer_contract", "constraints"]),
      "$.optimizer_search_trace.fixed_constraints",
      "must match unchanged V1 constraints"
    )
    |> ensure(
      trace["selected_scoring_policy"] == policy,
      "$.optimizer_search_trace.selected_scoring_policy",
      "must match the effective inner optimizer policy"
    )
    |> ensure(
      trace["selected_scoring_policy"] == get_in(artifact, ["ranking_explanation", "policy"]),
      "$.optimizer_search_trace.selected_scoring_policy",
      "must match the ranking explanation policy"
    )
    |> ensure(
      get_in(artifact, ["optimizer_contract", "optimizer"]) ==
        "per_spacecraft_greedy_non_overlapping",
      "$.optimizer_contract.optimizer",
      "must remain the V1 inner greedy optimizer"
    )
    |> ensure(
      trace["selected_timeline_scenario_id"] == value(first_timeline, "scenario_id"),
      "$.optimizer_search_trace.selected_timeline_scenario_id",
      "must match the first ranked timeline"
    )
    |> ensure(
      trace["selected_timeline_score"] == value(first_timeline, "score"),
      "$.optimizer_search_trace.selected_timeline_score",
      "must match the first ranked timeline"
    )
    |> ensure(
      trace["selected_activity_ids"] == activity_ids,
      "$.optimizer_search_trace.selected_activity_ids",
      "must match the enclosing selected activities"
    )
    |> ensure(
      is_list(activity_ids) and trace["selected_activity_count"] == length(activity_ids),
      "$.optimizer_search_trace.selected_activity_count",
      "must match the enclosing selected activities"
    )
  end

  defp validate_present_handoffs(issues, artifact, trace) do
    review_package = artifact["operator_review_package"]
    cadence_manifest = artifact["cadence_import_manifest"]
    review_rows = local_review_rows(review_package)
    cadence_rows = local_import_rows(cadence_manifest)
    review_row = List.first(review_rows)
    cadence_row = List.first(cadence_rows)

    issues
    |> ensure(
      length(review_rows) == 1,
      "$.operator_review_package.rows",
      "must contain exactly one local_search_review row"
    )
    |> ensure(
      is_map(review_package) and review_package["source_artifact_id"] == artifact["plan_id"],
      "$.operator_review_package.source_artifact_id",
      "must match the selected plan"
    )
    |> ensure(
      is_map(review_package) and review_package["source_artifact_type"] == "campaign_plan.v1",
      "$.operator_review_package.source_artifact_type",
      "must identify campaign_plan.v1"
    )
    |> validate_review_row(trace, review_row)
    |> ensure(
      length(cadence_rows) == 1,
      "$.cadence_import_manifest.rows",
      "must contain exactly one review_local_search row"
    )
    |> ensure(
      is_map(cadence_manifest) and cadence_manifest["source_artifact_id"] == artifact["plan_id"],
      "$.cadence_import_manifest.source_artifact_id",
      "must match the selected plan"
    )
    |> ensure(
      is_map(cadence_manifest) and cadence_manifest["source_artifact_type"] == "campaign_plan.v1",
      "$.cadence_import_manifest.source_artifact_type",
      "must identify campaign_plan.v1"
    )
    |> ensure(
      is_map(cadence_manifest) and
        get_in(cadence_manifest, ["provenance", "source_plan_id"]) == artifact["plan_id"],
      "$.cadence_import_manifest.provenance.source_plan_id",
      "must match the selected plan"
    )
    |> validate_cadence_row(review_row, cadence_row)
  end

  defp validate_review_row(issues, trace, row) when is_map(row) do
    copies = ~w(
      plan_id selection_contract base_scoring_policy selected_scoring_policy
      selected_alternative_id selected_timeline_scenario_id selected_timeline_score
      selected_activity_ids selected_activity_count
    )

    issues =
      Enum.reduce(copies, issues, fn field, acc ->
        ensure(
          acc,
          row[field] == trace[field],
          "$.operator_review_package.rows",
          "local-search #{field} copy is stale"
        )
      end)

    issues
    |> ensure(
      row["source_optimizer_search_trace"] == trace,
      "$.operator_review_package.rows",
      "must contain the entire exact optimizer search trace"
    )
    |> ensure(
      row["subject_id"] == trace["plan_id"] and row["plan_id"] == trace["plan_id"],
      "$.operator_review_package.rows",
      "must bind the selected plan ID"
    )
    |> ensure(
      row["scenario_id"] == trace["selected_timeline_scenario_id"],
      "$.operator_review_package.rows",
      "scenario copy is stale"
    )
    |> ensure(
      row["review_type"] == "local_search_review",
      "$.operator_review_package.rows",
      "must use local_search_review"
    )
    |> ensure(
      row["required_operator_action"] == "review_local_search",
      "$.operator_review_package.rows",
      "must require review_local_search"
    )
  end

  defp validate_review_row(issues, _trace, _row), do: issues

  defp validate_cadence_row(issues, review_row, row) when is_map(row) and is_map(review_row) do
    issues
    |> ensure(
      row["import_action"] == "review_local_search",
      "$.cadence_import_manifest.rows",
      "must route review_local_search"
    )
    |> ensure(
      row["source_review_type"] == "local_search_review",
      "$.cadence_import_manifest.rows",
      "must retain local_search_review"
    )
    |> ensure(
      row["source_review_row_id"] == review_row["id"],
      "$.cadence_import_manifest.rows",
      "must bind the exact review row ID"
    )
    |> ensure(
      row["source_review_row"] == review_row,
      "$.cadence_import_manifest.rows",
      "must contain the entire exact local-search review row"
    )
    |> ensure(
      row["subject_id"] == review_row["subject_id"],
      "$.cadence_import_manifest.rows",
      "must retain the selected plan subject ID"
    )
    |> ensure(
      row["source_review_action"] == "review_local_search",
      "$.cadence_import_manifest.rows",
      "must retain the local-search review action"
    )
  end

  defp validate_cadence_row(issues, _review_row, _row), do: issues

  defp validate_absent_handoffs(issues, artifact) do
    issues
    |> ensure(
      local_review_rows(artifact["operator_review_package"]) == [],
      "$.operator_review_package.rows",
      "cannot retain a stale local_search_review without a trace"
    )
    |> ensure(
      local_import_rows(artifact["cadence_import_manifest"]) == [],
      "$.cadence_import_manifest.rows",
      "cannot retain a stale review_local_search row without a trace"
    )
  end

  defp local_review_rows(%{"rows" => rows}) when is_list(rows),
    do: Enum.filter(rows, &(&1["review_type"] == "local_search_review"))

  defp local_review_rows(_package), do: []

  defp local_import_rows(%{"rows" => rows}) when is_list(rows) do
    Enum.filter(rows, fn row ->
      row["import_action"] == "review_local_search" or
        row["source_review_type"] == "local_search_review"
    end)
  end

  defp local_import_rows(_manifest), do: []

  defp selection_explanation(alternative, result) do
    selected = Enum.find(result["alternatives"] || [], &(&1["id"] == result["selected_id"]))

    cond do
      get_in(alternative, ["candidate_feasibility", "eligible"]) != true ->
        "ineligible_hard_feasibility"

      selected && alternative["id"] == selected["id"] ->
        "selected_best_feasible_score_then_generation_order_then_id"

      selected && alternative["score"] == selected["score"] ->
        "equal_score_later_generation_order_or_id"

      selected ->
        "lower_score"

      true ->
        "no_feasible_alternative"
    end
  end

  defp feasibility_transition(_seed, nil), do: nil

  defp feasibility_transition(%{"candidate_feasibility" => %{"eligible" => true}}, _selected),
    do: nil

  defp feasibility_transition(seed, selected) do
    %{
      "schema_contract" => "local_search_feasibility_transition.v1",
      "status" => "seed_ineligible_selected_feasible",
      "from_alternative_id" => seed["id"],
      "to_alternative_id" => selected["id"],
      "score_improvement_comparable" => false,
      "reason" => "seed_is_not_in_the_ranked_feasible_set"
    }
  end

  defp tuple_bounds(bounds) do
    Enum.reduce_while(bounds, {:ok, %{}}, fn
      {key, %{"minimum" => minimum, "maximum" => maximum}}, {:ok, acc}
      when is_number(minimum) and is_number(maximum) ->
        {:cont, {:ok, Map.put(acc, key, {minimum, maximum})}}

      _entry, _acc ->
        {:halt, :error}
    end)
  end

  defp parameter_identity(parameters) when is_map(parameters) do
    SourceEvidenceRegistry.parameter_content_identity(parameters)
  rescue
    _error -> :invalid
  end

  defp parameter_identity(_parameters), do: :invalid

  defp reasons(blockers) when is_list(blockers) do
    blockers
    |> Enum.map(&if(is_map(&1), do: &1["reason"], else: nil))
    |> Enum.uniq()
  end

  defp reasons(_blockers), do: :invalid

  defp finite_number?(value) when is_integer(value), do: true

  defp finite_number?(value) when is_float(value),
    do: value == value and value <= 1.7976931348623157e308 and value >= -1.7976931348623157e308

  defp finite_number?(_value), do: false
  defp nullish?(value), do: value in [nil, :null]
  defp value(nil, _field), do: nil
  defp value(map, field), do: map[field]

  defp ensure(issues, true, _path, _message), do: issues
  defp ensure(issues, _condition, path, message), do: [error(path, message) | issues]
  defp error(path, message), do: PrimitiveValidation.error(path, message)
end
