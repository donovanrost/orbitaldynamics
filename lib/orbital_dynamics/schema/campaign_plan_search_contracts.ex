defmodule OrbitalDynamics.Schema.CampaignPlanSearchContracts do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.LocalSearchSelection
  alias OrbitalDynamics.Optimizer.{HardFeasibility, SourceEvidenceRegistry}
  alias OrbitalDynamics.Schema.{JsonSafety, PrimitiveValidation, StableIdValidation}
  alias OrbitalDynamics.Search.Local
  alias OrbitalDynamics.{CadenceImport, OperationalReadiness, OperatorReview, Optimizer}

  @trace_contract "campaign_plan_search_trace.v1"
  @selection_contract "v1_outer_local_search_inner_greedy"
  @objective "maximize first ranked timeline aggregate score"
  @score_term "first_ranked_timeline_score"
  @registry_contract "local_search_source_evidence_registry.v1"
  @registry_trust_boundary "caller_supplied_trusted_composition_snapshot"
  @identity_algorithm "erlang_term_to_binary_deterministic_sha256.v1"
  @sha256 ~r/^[0-9a-f]{64}$/
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
    selected_timeline_score selected_activity_ids selected_activity_count search_root search_result
  )

  def validate_plan(issues, artifact) do
    case Map.get(artifact, "optimizer_search_trace") do
      nil ->
        validate_absent_handoffs(issues, artifact)

      :null ->
        validate_absent_handoffs(issues, artifact)

      %{} = trace ->
        issues =
          validate_trace(issues, "$.optimizer_search_trace", trace, @required_fields)

        if JsonSafety.errors(trace, "$.optimizer_search_trace") == [] and
             trace_structure_valid?(trace) and
             search_result_structure_valid?(trace["search_result"]) do
          issues
          |> validate_plan_binding(artifact, trace)
          |> validate_present_handoffs(artifact, trace)
        else
          issues
        end

      _trace ->
        [error("$.optimizer_search_trace", "must be a map") | issues]
    end
  end

  def validate_trace(issues, path, trace, required_fields)
      when is_list(issues) and is_binary(path) and is_map(trace) and is_list(required_fields) do
    json_issues = JsonSafety.errors(trace, path)

    issues =
      issues
      |> prepend_issues(json_issues)
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
      |> PrimitiveValidation.expect_type(path, trace, "search_root", :map)
      |> PrimitiveValidation.expect_type(path, trace, "search_result", :map)
      |> validate_trace_structure_fields(path, trace)

    if json_issues == [] and trace_structure_valid?(trace) do
      issues
      |> StableIdValidation.validate_stable_ids(path, trace, ["id", "plan_id"])
      |> validate_trace_identity(path, trace)
      |> validate_policy_fields(path, trace)
      |> validate_search_result(path, trace)
      |> validate_trace_outcome(path, trace)
    else
      issues
    end
  end

  def validate_trace(issues, path, _trace, _required_fields),
    do: [error(path, "must be a map") | issues]

  defp validate_trace_structure_fields(issues, path, trace) do
    issues
    |> ensure(
      string_list?(trace["searched_scoring_policy_keys"]),
      "#{path}.searched_scoring_policy_keys",
      "must be a proper list of strings"
    )
    |> ensure(
      string_list?(trace["selected_activity_ids"]),
      "#{path}.selected_activity_ids",
      "must be a proper list of strings"
    )
    |> ensure(
      is_integer(trace["selected_activity_count"]) and trace["selected_activity_count"] >= 0,
      "#{path}.selected_activity_count",
      "must be a non-negative integer"
    )
    |> ensure(
      nullable_finite_number?(trace["selected_timeline_score"]),
      "#{path}.selected_timeline_score",
      "must be a finite number or canonical null"
    )
  end

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

    if proper_list?(searched_keys) do
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

    issues =
      issues
      |> require_result_fields(path, result)
      |> validate_result_structure(path, result)
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

    if search_result_structure_valid?(result) do
      issues
      |> validate_registry_summary(path, registry)
      |> validate_neighborhood(path, result)
      |> validate_alternatives(path, result, alternatives, evaluations, registry)
      |> validate_result_counts_and_selection(path, result, alternatives)
      |> validate_trace_search_copies(path, trace, result, alternatives)
      |> validate_search_root(path, trace, result)
    else
      issues
    end
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

  defp validate_result_structure(issues, path, result) do
    result_path = "#{path}.search_result"

    issues
    |> ensure(is_binary(result["model"]), "#{result_path}.model", "must be a string")
    |> ensure(is_binary(result["objective"]), "#{result_path}.objective", "must be a string")
    |> ensure(
      is_binary(result["objective_direction"]),
      "#{result_path}.objective_direction",
      "must be a string"
    )
    |> ensure(is_binary(result["seed_id"]), "#{result_path}.seed_id", "must be a string")
    |> ensure(
      finite_number?(result["seed_score"]),
      "#{result_path}.seed_score",
      "must be a finite number"
    )
    |> ensure(
      nullable_binary?(result["selected_id"]),
      "#{result_path}.selected_id",
      "must be a string or canonical null"
    )
    |> ensure(
      nullable_finite_number?(result["selected_score"]),
      "#{result_path}.selected_score",
      "must be a finite number or canonical null"
    )
    |> ensure(is_boolean(result["improved"]), "#{result_path}.improved", "must be boolean")
    |> ensure(
      nullable_finite_number?(result["improvement_from_seed"]),
      "#{result_path}.improvement_from_seed",
      "must be a finite number or canonical null"
    )
    |> validate_non_negative_counts(
      result_path,
      result,
      ~w(evaluated_count eligible_count infeasible_count)
    )
    |> ensure(
      is_binary(result["feasibility_mode"]),
      "#{result_path}.feasibility_mode",
      "must be a string"
    )
    |> ensure(
      is_map(result["source_evidence_registry"]),
      "#{result_path}.source_evidence_registry",
      "must be a map"
    )
    |> ensure(
      proper_list?(result["candidate_feasibility_evaluations"]),
      "#{result_path}.candidate_feasibility_evaluations",
      "must be a proper list"
    )
    |> ensure(
      is_map(result["recommendation_outcome"]),
      "#{result_path}.recommendation_outcome",
      "must be a map"
    )
    |> ensure(
      nullable_map?(result["feasibility_transition"]),
      "#{result_path}.feasibility_transition",
      "must be a map or canonical null"
    )
    |> ensure(
      proper_list?(result["alternatives"]),
      "#{result_path}.alternatives",
      "must be a proper list"
    )
    |> ensure(
      proper_list?(result["rejected_moves"]),
      "#{result_path}.rejected_moves",
      "must be a proper list"
    )
    |> ensure(is_map(result["neighborhood"]), "#{result_path}.neighborhood", "must be a map")
    |> ensure(
      string_list?(result["deterministic_ordering"]),
      "#{result_path}.deterministic_ordering",
      "must be a proper list of strings"
    )
    |> ensure(
      string_list?(result["model_limits"]),
      "#{result_path}.model_limits",
      "must be a proper list of strings"
    )
    |> ensure(is_map(result["assumptions"]), "#{result_path}.assumptions", "must be a map")
    |> validate_alternative_structures(result_path, result["alternatives"])
    |> validate_evaluation_structures(
      result_path,
      result["candidate_feasibility_evaluations"]
    )
    |> validate_neighborhood_structure(result_path, result["neighborhood"])
  end

  defp validate_non_negative_counts(issues, path, map, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      ensure(
        acc,
        is_integer(map[field]) and map[field] >= 0,
        "#{path}.#{field}",
        "must be a non-negative integer"
      )
    end)
  end

  defp validate_alternative_structures(issues, path, alternatives) when is_list(alternatives) do
    alternatives
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {alternative, index}, acc ->
      alternative_path = "#{path}.alternatives[#{index}]"

      if is_map(alternative) do
        acc
        |> ensure(is_binary(alternative["id"]), "#{alternative_path}.id", "must be a string")
        |> ensure(
          is_integer(alternative["generation_index"]) and alternative["generation_index"] >= 0,
          "#{alternative_path}.generation_index",
          "must be a non-negative integer"
        )
        |> ensure(
          finite_numeric_map?(alternative["parameters"]),
          "#{alternative_path}.parameters",
          "must be a non-empty finite numeric map"
        )
        |> ensure(is_map(alternative["move"]), "#{alternative_path}.move", "must be a map")
        |> ensure(
          finite_numeric_map?(alternative["score_terms"]),
          "#{alternative_path}.score_terms",
          "must be a non-empty finite numeric map"
        )
        |> ensure(
          finite_number?(alternative["score"]),
          "#{alternative_path}.score",
          "must be a finite number"
        )
        |> ensure(
          nullable_positive_integer?(alternative["rank"]),
          "#{alternative_path}.rank",
          "must be a positive integer or canonical null"
        )
        |> ensure(
          finite_number?(alternative["score_delta_from_seed"]),
          "#{alternative_path}.score_delta_from_seed",
          "must be a finite number"
        )
        |> ensure(
          is_boolean(alternative["selected"]),
          "#{alternative_path}.selected",
          "must be boolean"
        )
        |> ensure(
          is_binary(alternative["selection_explanation"]),
          "#{alternative_path}.selection_explanation",
          "must be a string"
        )
        |> validate_feasibility_structure(
          "#{alternative_path}.candidate_feasibility",
          alternative["candidate_feasibility"]
        )
      else
        [error(alternative_path, "must be a map") | acc]
      end
    end)
  end

  defp validate_alternative_structures(issues, _path, _alternatives), do: issues

  defp validate_evaluation_structures(issues, path, evaluations) when is_list(evaluations) do
    evaluations
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {evaluation, index}, acc ->
      validate_feasibility_structure(
        acc,
        "#{path}.candidate_feasibility_evaluations[#{index}]",
        evaluation
      )
    end)
  end

  defp validate_evaluation_structures(issues, _path, _evaluations), do: issues

  defp validate_feasibility_structure(issues, path, evaluation) when is_map(evaluation) do
    issues
    |> ensure(
      is_binary(evaluation["schema_contract"]),
      "#{path}.schema_contract",
      "must be a string"
    )
    |> ensure(is_binary(evaluation["mode"]), "#{path}.mode", "must be a string")
    |> ensure(
      is_binary(evaluation["alternative_id"]),
      "#{path}.alternative_id",
      "must be a string"
    )
    |> ensure(
      nullable_binary?(evaluation["parameter_revision"]),
      "#{path}.parameter_revision",
      "must be a string or canonical null"
    )
    |> ensure(
      nullable_map?(evaluation["parameter_content_identity"]),
      "#{path}.parameter_content_identity",
      "must be a map or canonical null"
    )
    |> ensure(
      is_binary(evaluation["source_evidence_registry_id"]),
      "#{path}.source_evidence_registry_id",
      "must be a string"
    )
    |> ensure(
      nullable_binary?(evaluation["spacecraft_id"]),
      "#{path}.spacecraft_id",
      "must be a string or canonical null"
    )
    |> ensure(is_binary(evaluation["status"]), "#{path}.status", "must be a string")
    |> ensure(is_boolean(evaluation["eligible"]), "#{path}.eligible", "must be boolean")
    |> ensure(
      is_map(evaluation["evidence_bindings"]),
      "#{path}.evidence_bindings",
      "must be a map"
    )
    |> ensure(
      map_list?(evaluation["threshold_evaluations"]),
      "#{path}.threshold_evaluations",
      "must be a proper list of maps"
    )
    |> ensure(
      string_list?(evaluation["blocker_reasons"]),
      "#{path}.blocker_reasons",
      "must be a proper list of strings"
    )
    |> ensure(
      blocker_list?(evaluation["blockers"]),
      "#{path}.blockers",
      "must be a proper list of reason maps"
    )
    |> ensure(
      string_list?(evaluation["model_limits"]),
      "#{path}.model_limits",
      "must be a proper list of strings"
    )
  end

  defp validate_feasibility_structure(issues, path, _evaluation),
    do: [error(path, "must be a map") | issues]

  defp validate_neighborhood_structure(issues, path, neighborhood) when is_map(neighborhood) do
    neighborhood_path = "#{path}.neighborhood"

    issues
    |> ensure(
      finite_numeric_map?(neighborhood["seed_parameters"]),
      "#{neighborhood_path}.seed_parameters",
      "must be a non-empty finite numeric map"
    )
    |> ensure(
      finite_numeric_map?(neighborhood["steps"]),
      "#{neighborhood_path}.steps",
      "must be a non-empty finite numeric map"
    )
    |> ensure(
      bounds_map?(neighborhood["bounds"]),
      "#{neighborhood_path}.bounds",
      "must contain finite minimum/maximum maps"
    )
    |> ensure(
      is_binary(neighborhood["seed_id"]),
      "#{neighborhood_path}.seed_id",
      "must be a string"
    )
    |> ensure(
      is_integer(neighborhood["max_alternatives"]),
      "#{neighborhood_path}.max_alternatives",
      "must be an integer"
    )
    |> ensure(
      string_list?(neighborhood["step_parameters"]),
      "#{neighborhood_path}.step_parameters",
      "must be a proper list of strings"
    )
  end

  defp validate_neighborhood_structure(issues, _path, _neighborhood), do: issues

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
        evaluation["parameter_content_identity"] == expected_identity or
          (eligible == false and nullish?(evaluation["parameter_content_identity"])),
        "#{path}.search_result.candidate_feasibility_evaluations",
        "parameter content identity is stale"
      )
      |> ensure(
        StableIdValidation.valid?(evaluation["parameter_revision"]) or
          (eligible == false and nullish?(evaluation["parameter_revision"])),
        "#{path}.search_result.candidate_feasibility_evaluations",
        "parameter revision must be a stable identity or canonical null for missing evidence"
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
        proper_list?(blockers) and proper_list?(blocker_reasons),
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
        alternative["rank"] ==
          canonical_nullable(Map.get(expected_ranks, alternative["id"]))
      end)

    expected_outcome =
      selected
      |> HardFeasibility.outcome(length(eligible), length(infeasible))
      |> canonical_term()

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
      result["selected_id"] == canonical_nullable(value(selected, "id")),
      "#{path}.search_result.selected_id",
      "must identify the first feasible ranked alternative"
    )
    |> ensure(
      result["selected_score"] == canonical_nullable(value(selected, "score")),
      "#{path}.search_result.selected_score",
      "must match the selected alternative"
    )
    |> ensure(
      result["improvement_from_seed"] == canonical_nullable(improvement),
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
      result["feasibility_transition"] ==
        canonical_nullable(feasibility_transition(seed, selected)),
      "#{path}.search_result.feasibility_transition",
      "must exactly retain the seed feasibility transition"
    )
  end

  defp validate_result_counts_and_selection(issues, path, _result, _alternatives),
    do: [error("#{path}.search_result.alternatives", "must be a list") | issues]

  defp validate_trace_search_copies(issues, path, trace, result, alternatives) do
    alternatives = if proper_list?(alternatives), do: alternatives, else: []
    selected = Enum.find(alternatives, &(is_map(&1) and &1["id"] == result["selected_id"]))
    base_policy = trace["base_scoring_policy"]

    selected_policy =
      if is_map(selected) and is_map(base_policy) and is_map(selected["parameters"]),
        do: Map.merge(base_policy, selected["parameters"]),
        else: :null

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
      trace["selected_alternative"] == canonical_nullable(selected),
      "#{path}.selected_alternative",
      "must exactly copy the selected search alternative"
    )
    |> ensure(
      trace["selected_scoring_policy"] == selected_policy,
      "#{path}.selected_scoring_policy",
      "must apply the selected alternative to the base campaign policy"
    )
    |> ensure(
      trace["selected_timeline_score"] == canonical_nullable(value(selected, "score")),
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

  defp validate_search_root(issues, path, trace, result) do
    root = trace["search_root"]
    root_path = "#{path}.search_root"
    issues = validate_search_root_structure(issues, root_path, root)

    if search_root_structure_valid?(root) do
      rebuilt_registry = rebuild_registry(root["source_evidence_registry_entries"])
      alternatives = result["alternatives"]

      issues
      |> ensure(
        root["binding_contract"] == "campaign_plan_search_root.v1",
        "#{root_path}.binding_contract",
        "must retain campaign_plan_search_root.v1"
      )
      |> ensure(
        root["id"] == expected_search_root_id(root),
        "#{root_path}.id",
        "must match the immutable search-root content identity"
      )
      |> ensure(
        root["plan_id"] == trace["plan_id"],
        "#{root_path}.plan_id",
        "must match the trace plan ID"
      )
      |> ensure(
        root["base_scoring_policy"] == trace["base_scoring_policy"],
        "#{root_path}.base_scoring_policy",
        "must exactly copy the base scoring policy"
      )
      |> ensure(
        root["fixed_constraints"] == trace["fixed_constraints"],
        "#{root_path}.fixed_constraints",
        "must exactly copy the fixed constraints"
      )
      |> ensure(
        rebuilt_registry != :invalid and
          root["source_evidence_registry"] == rebuilt_registry,
        "#{root_path}.source_evidence_registry",
        "must exactly match the registry rebuilt from complete sorted entries"
      )
      |> ensure(
        root["source_evidence_registry_entries"] ==
          sorted_registry_entries(root["source_evidence_registry"]),
        "#{root_path}.source_evidence_registry_entries",
        "must be the complete sorted typed registry entries"
      )
      |> validate_root_candidate_order(root_path, root)
      |> validate_root_feasibility(root_path, root, result, rebuilt_registry)
      |> validate_root_plan_bindings(root_path, root, trace, alternatives)
    else
      issues
    end
  end

  defp validate_search_root_structure(issues, path, root) when is_map(root) do
    required = ~w(
      binding_contract id plan_id base_scoring_policy fixed_constraints
      source_evidence_registry source_evidence_registry_entries
      source_candidate_evidence alternative_plan_bindings
    )

    issues
    |> PrimitiveValidation.require_fields(path, root, required)
    |> ensure(is_binary(root["binding_contract"]), "#{path}.binding_contract", "must be a string")
    |> ensure(is_binary(root["id"]), "#{path}.id", "must be a string")
    |> ensure(is_binary(root["plan_id"]), "#{path}.plan_id", "must be a string")
    |> ensure(is_map(root["base_scoring_policy"]), "#{path}.base_scoring_policy", "must be a map")
    |> ensure(is_map(root["fixed_constraints"]), "#{path}.fixed_constraints", "must be a map")
    |> ensure(
      is_map(root["source_evidence_registry"]),
      "#{path}.source_evidence_registry",
      "must be a map"
    )
    |> ensure(
      map_list?(root["source_evidence_registry_entries"]),
      "#{path}.source_evidence_registry_entries",
      "must be a proper list of maps"
    )
    |> ensure(
      map_list?(root["source_candidate_evidence"]),
      "#{path}.source_candidate_evidence",
      "must be a proper list of maps"
    )
    |> ensure(
      map_list?(root["alternative_plan_bindings"]),
      "#{path}.alternative_plan_bindings",
      "must be a proper list of maps"
    )
    |> validate_registry_entry_structures(path, root["source_evidence_registry_entries"])
    |> validate_candidate_evidence_structures(path, root["source_candidate_evidence"])
    |> validate_plan_binding_structures(path, root["alternative_plan_bindings"])
  end

  defp validate_search_root_structure(issues, path, _root),
    do: [error(path, "must be a map") | issues]

  defp validate_registry_entry_structures(issues, path, entries) when is_list(entries) do
    entries
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {entry, index}, acc ->
      entry_path = "#{path}.source_evidence_registry_entries[#{index}]"

      if is_map(entry) do
        acc
        |> ensure(
          is_binary(entry["alternative_id"]),
          "#{entry_path}.alternative_id",
          "must be a string"
        )
        |> ensure(
          is_binary(entry["parameter_revision"]),
          "#{entry_path}.parameter_revision",
          "must be a string"
        )
        |> ensure(
          is_map(entry["parameter_content_identity"]),
          "#{entry_path}.parameter_content_identity",
          "must be a map"
        )
        |> ensure(
          is_binary(entry["resource_state_trace_id"]),
          "#{entry_path}.resource_state_trace_id",
          "must be a string"
        )
        |> ensure(
          is_binary(entry["downlink_link_budget_id"]),
          "#{entry_path}.downlink_link_budget_id",
          "must be a string"
        )
      else
        [error(entry_path, "must be a map") | acc]
      end
    end)
  end

  defp validate_registry_entry_structures(issues, _path, _entries), do: issues

  defp validate_candidate_evidence_structures(issues, path, rows) when is_list(rows) do
    rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {row, index}, acc ->
      row_path = "#{path}.source_candidate_evidence[#{index}]"

      if is_map(row) do
        ensure(
          acc,
          is_binary(row["alternative_id"]),
          "#{row_path}.alternative_id",
          "must be a string"
        )
      else
        [error(row_path, "must be a map") | acc]
      end
    end)
  end

  defp validate_candidate_evidence_structures(issues, _path, _rows), do: issues

  defp validate_plan_binding_structures(issues, path, rows) when is_list(rows) do
    rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {row, index}, acc ->
      row_path = "#{path}.alternative_plan_bindings[#{index}]"

      if is_map(row) do
        acc
        |> ensure(
          is_binary(row["alternative_id"]),
          "#{row_path}.alternative_id",
          "must be a string"
        )
        |> ensure(
          is_integer(row["generation_index"]) and row["generation_index"] >= 0,
          "#{row_path}.generation_index",
          "must be a non-negative integer"
        )
        |> ensure(
          finite_numeric_map?(row["parameters"]),
          "#{row_path}.parameters",
          "must be a non-empty finite numeric map"
        )
        |> ensure(
          is_map(row["parameter_content_identity"]),
          "#{row_path}.parameter_content_identity",
          "must be a map"
        )
        |> ensure(
          is_map(row["effective_scoring_policy"]),
          "#{row_path}.effective_scoring_policy",
          "must be a map"
        )
        |> ensure(is_binary(row["plan_id"]), "#{row_path}.plan_id", "must be a string")
        |> ensure(
          is_map(row["plan_content_identity"]),
          "#{row_path}.plan_content_identity",
          "must be a map"
        )
        |> ensure(is_binary(row["optimizer"]), "#{row_path}.optimizer", "must be a string")
        |> ensure(
          is_map(row["fixed_constraints"]),
          "#{row_path}.fixed_constraints",
          "must be a map"
        )
        |> ensure(
          nullable_binary?(row["first_ranked_timeline_scenario_id"]),
          "#{row_path}.first_ranked_timeline_scenario_id",
          "must be a string or canonical null"
        )
        |> ensure(
          finite_number?(row["first_ranked_timeline_score"]),
          "#{row_path}.first_ranked_timeline_score",
          "must be a finite number"
        )
        |> ensure(
          string_list?(row["selected_activity_ids"]),
          "#{row_path}.selected_activity_ids",
          "must be a proper list of strings"
        )
        |> ensure(
          is_integer(row["selected_activity_count"]) and row["selected_activity_count"] >= 0,
          "#{row_path}.selected_activity_count",
          "must be a non-negative integer"
        )
      else
        [error(row_path, "must be a map") | acc]
      end
    end)
  end

  defp validate_plan_binding_structures(issues, _path, _rows), do: issues

  defp validate_root_candidate_order(issues, path, root) do
    ids = Enum.map(root["source_candidate_evidence"], & &1["alternative_id"])

    issues
    |> ensure(
      ids == Enum.sort(ids),
      "#{path}.source_candidate_evidence",
      "must be sorted by alternative ID"
    )
    |> ensure(
      length(ids) == length(Enum.uniq(ids)),
      "#{path}.source_candidate_evidence",
      "must contain one row per alternative ID"
    )
  end

  defp validate_root_feasibility(issues, path, root, result, rebuilt_registry) do
    if is_map(rebuilt_registry) do
      alternatives =
        result["alternatives"]
        |> Enum.sort_by(&{&1["generation_index"], &1["id"]})

      hard_config = %{
        "mode" => "hard",
        "evidence_registry" => rebuilt_registry,
        "candidates" => root["source_candidate_evidence"]
      }

      case prepare_root_feasibility(hard_config, alternatives) do
        {:ok, configuration} ->
          actual_evaluations =
            result["candidate_feasibility_evaluations"]
            |> Map.new(&{&1["alternative_id"], &1})

          issues =
            ensure(
              issues,
              result["source_evidence_registry"] ==
                HardFeasibility.registry_summary(configuration),
              "#{path}.source_evidence_registry",
              "must exactly summarize the registry rebuilt from the immutable search root"
            )

          Enum.reduce(alternatives, issues, fn alternative, acc ->
            expected =
              alternative
              |> HardFeasibility.evaluate(configuration)
              |> canonical_term()

            actual = actual_evaluations[alternative["id"]]

            acc
            |> ensure(
              actual == expected,
              "#{path}.source_candidate_evidence",
              "must recompute the exact feasibility evaluation for #{alternative["id"]}"
            )
            |> ensure(
              alternative["candidate_feasibility"] == expected,
              "#{path}.source_candidate_evidence",
              "must bind the exact embedded feasibility copy for #{alternative["id"]}"
            )
          end)

        :error ->
          [
            error(
              "#{path}.source_candidate_evidence",
              "must be valid typed hard-feasibility source evidence"
            )
            | issues
          ]
      end
    else
      issues
    end
  rescue
    _error ->
      [
        error(
          "#{path}.source_candidate_evidence",
          "must be valid typed hard-feasibility source evidence"
        )
        | issues
      ]
  catch
    _kind, _reason ->
      [
        error(
          "#{path}.source_candidate_evidence",
          "must be valid typed hard-feasibility source evidence"
        )
        | issues
      ]
  end

  defp validate_root_plan_bindings(issues, path, root, trace, alternatives) do
    generated = Enum.sort_by(alternatives, &{&1["generation_index"], &1["id"]})
    rows = root["alternative_plan_bindings"]
    rows_by_id = Map.new(rows, &{&1["alternative_id"], &1})

    issues =
      issues
      |> ensure(
        Enum.map(rows, & &1["alternative_id"]) == Enum.map(generated, & &1["id"]),
        "#{path}.alternative_plan_bindings",
        "must retain generation order and exactly cover evaluated alternatives"
      )

    Enum.reduce(generated, issues, fn alternative, acc ->
      row = rows_by_id[alternative["id"]]
      expected_policy = Map.merge(trace["base_scoring_policy"], alternative["parameters"])

      acc
      |> ensure(
        is_map(row),
        "#{path}.alternative_plan_bindings",
        "must bind #{alternative["id"]}"
      )
      |> ensure(
        is_map(row) and row["generation_index"] == alternative["generation_index"],
        "#{path}.alternative_plan_bindings",
        "generation index is stale for #{alternative["id"]}"
      )
      |> ensure(
        is_map(row) and row["parameters"] == alternative["parameters"],
        "#{path}.alternative_plan_bindings",
        "parameters are stale for #{alternative["id"]}"
      )
      |> ensure(
        is_map(row) and
          row["parameter_content_identity"] == parameter_identity(alternative["parameters"]),
        "#{path}.alternative_plan_bindings",
        "parameter content identity is stale for #{alternative["id"]}"
      )
      |> ensure(
        is_map(row) and row["effective_scoring_policy"] == expected_policy,
        "#{path}.alternative_plan_bindings",
        "effective scoring policy is stale for #{alternative["id"]}"
      )
      |> ensure(
        is_map(row) and row["plan_id"] == trace["plan_id"],
        "#{path}.alternative_plan_bindings",
        "plan ID is stale for #{alternative["id"]}"
      )
      |> ensure(
        is_map(row) and row["optimizer"] == "per_spacecraft_greedy_non_overlapping",
        "#{path}.alternative_plan_bindings",
        "must retain the V1 inner greedy optimizer for #{alternative["id"]}"
      )
      |> ensure(
        is_map(row) and row["fixed_constraints"] == trace["fixed_constraints"],
        "#{path}.alternative_plan_bindings",
        "constraints are stale for #{alternative["id"]}"
      )
      |> ensure(
        is_map(row) and row["first_ranked_timeline_score"] == alternative["score"],
        "#{path}.alternative_plan_bindings",
        "objective score is stale for #{alternative["id"]}"
      )
      |> ensure(
        is_map(row) and valid_content_identity?(row["plan_content_identity"]),
        "#{path}.alternative_plan_bindings",
        "plan content identity is malformed for #{alternative["id"]}"
      )
      |> ensure(
        is_map(row) and row["selected_activity_count"] == length(row["selected_activity_ids"]),
        "#{path}.alternative_plan_bindings",
        "selected activity count is stale for #{alternative["id"]}"
      )
    end)
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
          proper_list?(trace["selected_activity_ids"]) and
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
        timelines when is_list(timelines) ->
          if proper_list?(timelines), do: List.first(timelines), else: nil

        _timelines ->
          nil
      end

    activity_ids =
      case Map.get(artifact, "activities", []) do
        activities when is_list(activities) ->
          if proper_list?(activities),
            do: Enum.map(activities, &if(is_map(&1), do: &1["id"])),
            else: :invalid

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
      proper_list?(activity_ids) and trace["selected_activity_count"] == length(activity_ids),
      "$.optimizer_search_trace.selected_activity_count",
      "must match the enclosing selected activities"
    )
    |> validate_selected_plan_root_binding(artifact, trace)
  end

  defp validate_selected_plan_root_binding(issues, artifact, trace) do
    selected_id = trace["selected_alternative_id"]

    binding =
      trace["search_root"]["alternative_plan_bindings"]
      |> Enum.find(&(&1["alternative_id"] == selected_id))

    issues
    |> ensure(
      is_map(binding),
      "$.optimizer_search_trace.search_root.alternative_plan_bindings",
      "must contain the selected evaluated plan binding"
    )
    |> ensure(
      is_map(binding) and
        binding["plan_content_identity"] ==
          LocalSearchSelection.evaluated_plan_content_identity(artifact),
      "$.optimizer_search_trace.search_root.alternative_plan_bindings",
      "selected evaluated plan content identity must match the enclosing rebuilt plan"
    )
    |> ensure(
      is_map(binding) and binding["effective_scoring_policy"] == trace["selected_scoring_policy"],
      "$.optimizer_search_trace.search_root.alternative_plan_bindings",
      "selected plan policy copy is stale"
    )
    |> ensure(
      is_map(binding) and
        binding["first_ranked_timeline_scenario_id"] == trace["selected_timeline_scenario_id"],
      "$.optimizer_search_trace.search_root.alternative_plan_bindings",
      "selected timeline scenario copy is stale"
    )
    |> ensure(
      is_map(binding) and
        binding["first_ranked_timeline_score"] == trace["selected_timeline_score"],
      "$.optimizer_search_trace.search_root.alternative_plan_bindings",
      "selected timeline score copy is stale"
    )
    |> ensure(
      is_map(binding) and binding["selected_activity_ids"] == trace["selected_activity_ids"],
      "$.optimizer_search_trace.search_root.alternative_plan_bindings",
      "selected activity IDs copy is stale"
    )
  end

  defp validate_present_handoffs(issues, artifact, trace) do
    review_package = artifact["operator_review_package"]
    cadence_manifest = artifact["cadence_import_manifest"]

    {expected_review_package, expected_cadence_manifest, expected_readiness,
     expected_quality_gate} = expected_handoffs(artifact)

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
    |> ensure(
      review_package == expected_review_package,
      "$.operator_review_package",
      "must exactly recompute rows, ordering, authority state, and all counts from campaign trace evidence"
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
    |> ensure(
      cadence_manifest == expected_cadence_manifest,
      "$.cadence_import_manifest",
      "must exactly recompute rows, ordering, review-required authority state, and all counts from campaign trace evidence"
    )
    |> validate_cadence_row(review_row, cadence_row)
    |> ensure(
      artifact["operational_readiness_report"] == expected_readiness,
      "$.operational_readiness_report",
      "must exactly recompute readiness from trace-authoritative review and import evidence"
    )
    |> ensure(
      artifact["quality_gate_report"] == expected_quality_gate,
      "$.quality_gate_report",
      "must exactly recompute the quality gate from trace-authoritative readiness"
    )
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
    |> ensure(
      row["action"] == "review_local_search",
      "$.operator_review_package.rows",
      "must retain the local-search review action"
    )
    |> ensure(
      row["approval_status"] == "operator_review_required",
      "$.operator_review_package.rows",
      "local-search evidence always requires operator review"
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
    |> ensure(
      row["required_operator_action"] == "review_local_search",
      "$.cadence_import_manifest.rows",
      "must require review_local_search"
    )
    |> ensure(
      row["approval_status"] == "operator_review_required",
      "$.cadence_import_manifest.rows",
      "local-search import evidence always requires operator review"
    )
    |> ensure(
      row["import_status"] == "review_required_before_import",
      "$.cadence_import_manifest.rows",
      "local-search evidence cannot be ready for import before review"
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

  defp local_review_rows(%{"rows" => rows}) when is_list(rows) do
    if proper_list?(rows),
      do: Enum.filter(rows, &(is_map(&1) and &1["review_type"] == "local_search_review")),
      else: []
  end

  defp local_review_rows(_package), do: []

  defp local_import_rows(%{"rows" => rows}) when is_list(rows) do
    if proper_list?(rows) do
      Enum.filter(rows, fn row ->
        is_map(row) and
          (row["import_action"] == "review_local_search" or
             row["source_review_type"] == "local_search_review")
      end)
    else
      []
    end
  end

  defp local_import_rows(_manifest), do: []

  defp expected_handoffs(artifact) do
    source =
      Map.drop(artifact, [
        "operator_review_package",
        "cadence_import_manifest",
        "operational_readiness_report",
        "quality_gate_report"
      ])

    review_package = OperatorReview.from_campaign_artifact(source)
    cadence_manifest = CadenceImport.from_campaign_artifact(source)

    readiness_source =
      source
      |> Map.put("operator_review_package", review_package)
      |> Map.put("cadence_import_manifest", cadence_manifest)

    readiness = OperationalReadiness.report(readiness_source)
    quality_gate = OperationalReadiness.quality_gate_report(readiness)
    {review_package, cadence_manifest, readiness, quality_gate}
  rescue
    _error -> {:invalid, :invalid, :invalid, :invalid}
  catch
    _kind, _reason -> {:invalid, :invalid, :invalid, :invalid}
  end

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
    if proper_list?(blockers) do
      blockers
      |> Enum.map(&if(is_map(&1), do: &1["reason"], else: nil))
      |> Enum.uniq()
    else
      :invalid
    end
  end

  defp reasons(_blockers), do: :invalid

  defp prepend_issues(issues, new_issues), do: Enum.reverse(new_issues) ++ issues

  defp trace_structure_valid?(trace) do
    is_binary(trace["id"]) and
      is_binary(trace["plan_id"]) and
      is_binary(trace["status"]) and
      is_map(trace["base_scoring_policy"]) and
      nullable_map?(trace["selected_scoring_policy"]) and
      string_list?(trace["searched_scoring_policy_keys"]) and
      is_map(trace["fixed_constraints"]) and
      nullable_binary?(trace["selected_alternative_id"]) and
      nullable_map?(trace["selected_alternative"]) and
      nullable_binary?(trace["selected_timeline_scenario_id"]) and
      nullable_finite_number?(trace["selected_timeline_score"]) and
      string_list?(trace["selected_activity_ids"]) and
      is_integer(trace["selected_activity_count"]) and
      trace["selected_activity_count"] >= 0 and
      is_map(trace["search_root"]) and
      is_map(trace["search_result"])
  end

  defp search_result_structure_valid?(result) when is_map(result),
    do: validate_result_structure([], "$", result) == []

  defp search_result_structure_valid?(_result), do: false

  defp search_root_structure_valid?(root) when is_map(root) do
    registry = root["source_evidence_registry"]

    validate_search_root_structure([], "$", root) == [] and
      is_map(registry) and is_map(registry["entries"]) and
      Enum.all?(registry["entries"], fn {id, entry} -> is_binary(id) and is_map(entry) end)
  end

  defp search_root_structure_valid?(_root), do: false

  defp rebuild_registry(entries) do
    entries =
      Map.new(entries, fn row ->
        {Map.fetch!(row, "alternative_id"), Map.delete(row, "alternative_id")}
      end)

    SourceEvidenceRegistry.build(entries)
  rescue
    _error -> :invalid
  catch
    _kind, _reason -> :invalid
  end

  defp sorted_registry_entries(registry) when is_map(registry) do
    registry
    |> Map.get("entries", %{})
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map(fn {alternative_id, entry} ->
      Map.put(entry, "alternative_id", alternative_id)
    end)
  end

  defp sorted_registry_entries(_registry), do: :invalid

  defp prepare_root_feasibility(hard_config, alternatives) do
    case HardFeasibility.prepare([hard_feasibility: hard_config], alternatives) do
      {:hard, configuration} -> {:ok, configuration}
      _mode -> :error
    end
  rescue
    _error -> :error
  catch
    _kind, _reason -> :error
  end

  defp expected_search_root_id(root) do
    digest =
      root
      |> Map.delete("id")
      |> LocalSearchSelection.content_identity()
      |> Map.fetch!("sha256")

    "campaign_plan_search_root:#{digest}"
  rescue
    _error -> :invalid
  end

  defp canonical_term(value), do: JsonSafety.normalize_input!(value, "campaign search contract")
  defp canonical_nullable(nil), do: :null
  defp canonical_nullable(value), do: value

  defp nullable_binary?(value), do: value == :null or is_binary(value)
  defp nullable_map?(value), do: value == :null or is_map(value)
  defp nullable_finite_number?(value), do: value == :null or finite_number?(value)

  defp nullable_positive_integer?(value),
    do: value == :null or (is_integer(value) and value > 0)

  defp proper_list?([]), do: true
  defp proper_list?([_head | tail]), do: proper_list?(tail)
  defp proper_list?(_value), do: false

  defp string_list?(value),
    do: proper_list?(value) and Enum.all?(value, &is_binary/1)

  defp map_list?(value),
    do: proper_list?(value) and Enum.all?(value, &is_map/1)

  defp blocker_list?(value) do
    proper_list?(value) and
      Enum.all?(value, &(is_map(&1) and is_binary(&1["reason"])))
  end

  defp finite_numeric_map?(value) do
    is_map(value) and map_size(value) > 0 and
      Enum.all?(value, fn {key, number} -> is_binary(key) and finite_number?(number) end)
  end

  defp bounds_map?(value) do
    is_map(value) and
      Enum.all?(value, fn
        {key, %{"minimum" => minimum, "maximum" => maximum}} ->
          is_binary(key) and finite_number?(minimum) and finite_number?(maximum)

        _entry ->
          false
      end)
  end

  defp valid_content_identity?(%{
         "algorithm" => @identity_algorithm,
         "sha256" => digest
       })
       when is_binary(digest),
       do: Regex.match?(@sha256, digest)

  defp valid_content_identity?(_identity), do: false

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
