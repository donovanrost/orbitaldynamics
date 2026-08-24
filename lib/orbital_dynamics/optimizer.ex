defmodule OrbitalDynamics.Optimizer do
  @moduledoc """
  Transparent optimizer contracts and bounded search for mission alternatives.

  These records and results explain the model used to select an alternative.
  They do not introduce an external solver or hide decisions behind opaque
  weights.
  """

  @greedy_optimizer "per_spacecraft_greedy_non_overlapping"
  @local_search_model "deterministic_bounded_axis_step_local_search"
  @ranking_comparison_model "scenario_ranking_pairwise_delta"
  @pareto_frontier_model "objective_vector_pareto_frontier"
  @local_search_model_limits [
    "numeric_scalar_parameters_only",
    "single_axis_single_step_moves_only",
    "box_bounds_only",
    "one_neighborhood_generation",
    "score_is_sum_of_caller_supplied_terms",
    "caller_must_supply_a_pure_deterministic_score_terms_function",
    "no_constraint_or_feasibility_evaluation_beyond_bounds",
    "no_solver_execution",
    "not_calibrated_from_operational_outcomes"
  ]
  @ranking_comparison_model_limits [
    "deterministic_rank_comparison_only",
    "input_order_is_rank_source",
    "no_solver_execution",
    "not_calibrated_from_operational_outcomes"
  ]
  @pareto_frontier_model_limits [
    "deterministic_pareto_summary_only",
    "not_an_optimizer_or_solver",
    "missing_objectives_do_not_dominate",
    "not_calibrated_from_operational_outcomes"
  ]
  @preserved_lineage_fields [
    "id",
    "scenario_id",
    "source_window_id",
    "source_window",
    "score_terms"
  ]

  alias OrbitalDynamics.Optimizer.{HardFeasibility, LocalSearchCertificate}
  alias OrbitalDynamics.Search.Local

  @doc """
  Declares supported optimizer contract models and known limits.
  """
  def capabilities do
    %{
      artifact_contract: "optimizer_contract.v1",
      models: [@greedy_optimizer],
      local_search_models: [@local_search_model],
      comparison_models: [@ranking_comparison_model, @pareto_frontier_model],
      validation_level: :artifact_contract,
      local_search_validation_level: :input_validated,
      local_search_generator: Local.capabilities().model,
      local_search_deterministic_ordering: [
        :objective_score_by_direction,
        :generation_index_ascending,
        :alternative_id_ascending
      ],
      local_search_model_limits: @local_search_model_limits,
      local_search_hard_feasibility: HardFeasibility.capabilities(),
      local_search_optimization_certificate: LocalSearchCertificate.capabilities(),
      public_facades: [
        :explainable_local_search,
        :certified_local_search,
        :verify_local_search_certificate
      ],
      deterministic_ordering: [
        :score_descending,
        :start_time_ascending,
        :id_ascending,
        :scenario_score_descending,
        :scenario_id_ascending
      ],
      preserved_lineage_fields: @preserved_lineage_fields,
      known_limits: [
        :greedy_per_scenario_selection,
        :no_cross_scenario_resource_allocation,
        :no_milp_or_cp_sat_solver,
        :pareto_frontier_summary_not_solver_search,
        :ranking_comparison_not_solver_search,
        :explainable_score_terms_only
      ]
    }
  end

  @doc """
  Returns the declared model limits for ranking comparison reports.
  """
  def ranking_comparison_model_limits, do: @ranking_comparison_model_limits

  @doc """
  Returns the declared model limits for Pareto frontier reports.
  """
  def pareto_frontier_model_limits, do: @pareto_frontier_model_limits

  @doc """
  Returns the declared model limits for bounded explainable local search.
  """
  def local_search_model_limits, do: @local_search_model_limits

  @doc """
  Builds the V1 optimizer contract for ranked campaign timelines.
  """
  def greedy_timeline_contract(candidates, ranked_timelines, opts \\ [])
      when is_list(candidates) and is_list(ranked_timelines) do
    selected_activities =
      ranked_timelines
      |> List.first(%{})
      |> Map.get("activities", [])

    %{
      "schema_contract" => "optimizer_contract.v1",
      "id" => Keyword.get(opts, :id, optimizer_contract_id(Keyword.get(opts, :plan_id))),
      "optimizer" => @greedy_optimizer,
      "objective" => "maximize weighted observation value and contact value",
      "selection_policy" => "highest_scored_non_overlapping_timeline",
      "candidate_count" => length(candidates),
      "ranked_timeline_count" => length(ranked_timelines),
      "selected_activity_count" => length(selected_activities),
      "selected_activity_ids" => activity_ids(selected_activities),
      "candidate_activity_ids" => activity_ids(candidates),
      "ranked_scenario_ids" => ranked_scenario_ids(ranked_timelines),
      "score_term_keys" => score_term_keys(ranked_timelines),
      "deterministic_ordering" => [
        "candidate score descending",
        "candidate starts_at_s ascending",
        "candidate id ascending",
        "timeline score descending",
        "scenario_id ascending"
      ],
      "preserved_lineage_fields" => @preserved_lineage_fields,
      "constraints" => Keyword.get(opts, :constraints, %{}),
      "scoring_policy" => Keyword.get(opts, :scoring_policy, %{}),
      "known_limits" => Enum.map(capabilities().known_limits, &Atom.to_string/1),
      "assumptions" => %{
        "optimizer_family" => "deterministic_greedy_selector",
        "overlap_policy" =>
          "reject candidate when it overlaps a selected activity in the same scenario",
        "selection_scope" => "per_scenario_then_ranked_plan",
        "external_solver" => false
      }
    }
  end

  @doc """
  Generates and evaluates one deterministic, bounded local neighborhood.

  `score_terms_fun` receives each alternative's normalized string-keyed
  parameter map and must return a non-empty map of named numeric score
  contributions. The optimizer sums those contributions, then ranks by score,
  generation order, and alternative ID. Required option `:steps`, plus optional
  `:bounds`, `:id_prefix`, and `:max_alternatives`, are passed to
  `OrbitalDynamics.Search.Local.neighborhood/2`.

  Optional `:hard_feasibility` enables explicit typed feasibility evaluation
  before ranking. Reproducibility requires a pure deterministic
  `score_terms_fun` and identity-bound deterministic evidence.

  This remains one inspectable local step, not an iterative solver.
  """
  def explainable_local_search(seed_parameters, score_terms_fun, opts \\ [])

  def explainable_local_search(seed_parameters, score_terms_fun, opts)
      when is_map(seed_parameters) and is_function(score_terms_fun, 1) and is_list(opts) do
    objective = Keyword.get(opts, :objective, "sum_of_score_terms")

    objective_direction =
      normalize_objective_direction!(Keyword.get(opts, :objective_direction, :maximize))

    if not is_binary(objective) or objective == "" do
      raise ArgumentError, "objective must be a non-empty string"
    end

    neighborhood =
      Local.neighborhood(
        seed_parameters,
        Keyword.take(opts, [:steps, :bounds, :id_prefix, :max_alternatives])
      )

    evaluated =
      Enum.map(neighborhood["alternatives"], fn alternative ->
        score_terms = evaluate_score_terms!(score_terms_fun, alternative)

        alternative
        |> Map.put("score_terms", score_terms)
        |> Map.put("score", sum_score_terms(score_terms))
      end)

    case HardFeasibility.prepare(opts, evaluated) do
      :legacy ->
        legacy_local_search_result(evaluated, neighborhood, objective, objective_direction)

      {:hard, configuration} ->
        hard_local_search_result(
          evaluated,
          neighborhood,
          objective,
          objective_direction,
          configuration
        )
    end
  end

  def explainable_local_search(_seed_parameters, _score_terms_fun, _opts) do
    raise ArgumentError,
          "seed_parameters must be a map, score_terms_fun must have arity 1, and opts must be a keyword list"
  end

  @doc """
  Runs opt-in exact enumeration of the complete bounded local neighborhood.

  The result is a schema-versioned certificate. Its supported claim is limited
  to the declared finite neighborhood and is emitted only when every in-bounds
  candidate was evaluated. See `LocalSearchCertificate.build/4` for the source
  evidence and evaluator contract.
  """
  def certified_local_search(seed_parameters, source_evidence, evaluator_fun, opts) do
    LocalSearchCertificate.build(seed_parameters, source_evidence, evaluator_fun, opts)
  end

  @doc """
  Verifies a local-search optimization certificate by exact replay.
  """
  def verify_local_search_certificate(
        certificate,
        seed_parameters,
        source_evidence,
        evaluator_fun,
        opts
      ) do
    LocalSearchCertificate.verify(
      certificate,
      seed_parameters,
      source_evidence,
      evaluator_fun,
      opts
    )
  end

  defp legacy_local_search_result(evaluated, neighborhood, objective, objective_direction) do
    ranked =
      evaluated
      |> Enum.sort_by(&local_search_sort_key(&1, objective_direction))
      |> Enum.with_index(1)
      |> Enum.map(fn {alternative, rank} -> Map.put(alternative, "rank", rank) end)

    selected = List.first(ranked)
    seed = Enum.find(ranked, &(&1["id"] == neighborhood["seed_id"]))
    improvement_from_seed = improvement_from_seed(selected, seed, objective_direction)

    alternatives =
      Enum.map(ranked, fn alternative ->
        alternative
        |> Map.put("score_delta_from_seed", alternative["score"] - seed["score"])
        |> Map.put("selected", alternative["id"] == selected["id"])
        |> Map.put(
          "selection_explanation",
          local_search_selection_explanation(alternative, selected, objective_direction)
        )
      end)

    %{
      "model" => @local_search_model,
      "objective" => objective,
      "objective_direction" => Atom.to_string(objective_direction),
      "seed_id" => seed["id"],
      "seed_score" => seed["score"],
      "selected_id" => selected["id"],
      "selected_score" => selected["score"],
      "improved" => improvement_from_seed > 0,
      "improvement_from_seed" => improvement_from_seed,
      "evaluated_count" => length(alternatives),
      "alternatives" => alternatives,
      "rejected_moves" => neighborhood["rejected_moves"],
      "neighborhood" => Map.drop(neighborhood, ["alternatives", "rejected_moves"]),
      "deterministic_ordering" => [
        objective_score_order(objective_direction),
        "generation_index ascending",
        "alternative id ascending"
      ],
      "model_limits" => @local_search_model_limits,
      "assumptions" => %{
        "score_rule" => "sum_of_score_terms",
        "score_terms_function" => "caller_supplied_and_expected_pure",
        "external_solver" => false,
        "iterations" => 1
      }
    }
  end

  defp hard_local_search_result(
         evaluated,
         neighborhood,
         objective,
         objective_direction,
         configuration
       ) do
    feasibility_evaluated =
      Enum.map(evaluated, fn alternative ->
        Map.put(
          alternative,
          "candidate_feasibility",
          HardFeasibility.evaluate(alternative, configuration)
        )
      end)

    {eligible, infeasible} =
      Enum.split_with(
        feasibility_evaluated,
        &get_in(&1, ["candidate_feasibility", "eligible"])
      )

    ranked =
      eligible
      |> Enum.sort_by(&local_search_sort_key(&1, objective_direction))
      |> Enum.with_index(1)
      |> Enum.map(fn {alternative, rank} -> Map.put(alternative, "rank", rank) end)

    infeasible =
      infeasible
      |> Enum.sort_by(&{&1["generation_index"], &1["id"]})
      |> Enum.map(&Map.put(&1, "rank", nil))

    selected = List.first(ranked)
    alternatives = ranked ++ infeasible
    seed = Enum.find(alternatives, &(&1["id"] == neighborhood["seed_id"]))
    seed_eligible = get_in(seed, ["candidate_feasibility", "eligible"])

    improvement_from_seed =
      if selected && seed_eligible,
        do: improvement_from_seed(selected, seed, objective_direction),
        else: nil

    alternatives =
      Enum.map(alternatives, fn alternative ->
        alternative
        |> Map.put("score_delta_from_seed", alternative["score"] - seed["score"])
        |> Map.put("selected", not is_nil(selected) and alternative["id"] == selected["id"])
        |> Map.put(
          "selection_explanation",
          hard_local_search_selection_explanation(
            alternative,
            selected,
            objective_direction
          )
        )
      end)

    eligible_count = length(ranked)
    infeasible_count = length(infeasible)

    %{
      "model" => @local_search_model,
      "objective" => objective,
      "objective_direction" => Atom.to_string(objective_direction),
      "seed_id" => seed["id"],
      "seed_score" => seed["score"],
      "selected_id" => if(selected, do: selected["id"], else: nil),
      "selected_score" => if(selected, do: selected["score"], else: nil),
      "improved" => not is_nil(improvement_from_seed) and improvement_from_seed > 0,
      "improvement_from_seed" => improvement_from_seed,
      "evaluated_count" => length(alternatives),
      "eligible_count" => eligible_count,
      "infeasible_count" => infeasible_count,
      "feasibility_mode" => "hard",
      "source_evidence_registry" => HardFeasibility.registry_summary(configuration),
      "candidate_feasibility_evaluations" =>
        Enum.map(feasibility_evaluated, & &1["candidate_feasibility"]),
      "recommendation_outcome" =>
        HardFeasibility.outcome(selected, eligible_count, infeasible_count),
      "feasibility_transition" => feasibility_transition(seed, selected),
      "alternatives" => alternatives,
      "rejected_moves" => neighborhood["rejected_moves"],
      "neighborhood" => Map.drop(neighborhood, ["alternatives", "rejected_moves"]),
      "deterministic_ordering" => [
        "hard-feasibility eligible alternatives only",
        objective_score_order(objective_direction),
        "generation_index ascending",
        "alternative id ascending",
        "infeasible alternatives generation_index then id ascending"
      ],
      "model_limits" => HardFeasibility.search_model_limits(@local_search_model_limits),
      "assumptions" => %{
        "score_rule" => "sum_of_score_terms",
        "score_terms_function" => "caller_supplied_and_expected_pure",
        "hard_feasibility" =>
          "caller_supplied_trusted_composition_registry_and_typed_candidate_evidence",
        "registry_authentication" => "not_provided",
        "feasibility_timing" => "before_ranking",
        "external_solver" => false,
        "iterations" => 1
      }
    }
  end

  @doc """
  Compares two ranked scenario lists using deterministic rank and value deltas.

  Rows may use atom or string keys and must contain a scenario id under
  `:scenario_id` or `"scenario_id"`. The input order is treated as the ranking
  order so the function can compare persisted `scenario_rankings` rows or
  in-memory rows from `OrbitalDynamics.ResultSet.Report.rank/3`.
  """
  def compare_rankings(left_rows, right_rows, opts \\ [])
      when is_list(left_rows) and is_list(right_rows) do
    left = normalize_ranking(left_rows)
    right = normalize_ranking(right_rows)
    left_by_id = Map.new(left, &{&1["scenario_id"], &1})
    right_by_id = Map.new(right, &{&1["scenario_id"], &1})

    scenario_ids =
      (Map.keys(left_by_id) ++ Map.keys(right_by_id))
      |> Enum.uniq()
      |> Enum.sort()

    rows =
      scenario_ids
      |> Enum.map(&comparison_row(&1, left_by_id, right_by_id))
      |> Enum.sort_by(&comparison_sort_key/1)

    %{
      "model" => @ranking_comparison_model,
      "objective" => Keyword.get(opts, :objective, inferred_objective(left, right)),
      "objective_direction" => Keyword.get(opts, :objective_direction),
      "left_label" => Keyword.get(opts, :left_label, "left"),
      "right_label" => Keyword.get(opts, :right_label, "right"),
      "left_count" => length(left),
      "right_count" => length(right),
      "matched_count" => Enum.count(rows, &(&1["status"] == "matched")),
      "left_only_count" => Enum.count(rows, &(&1["status"] == "left_only")),
      "right_only_count" => Enum.count(rows, &(&1["status"] == "right_only")),
      "winner" => winner_summary(List.first(left), List.first(right)),
      "rows" => rows,
      "assumptions" => %{
        "comparison_scope" => "ranked_scenario_rows",
        "rank_source" => "input_order",
        "external_solver" => false
      }
    }
  end

  @doc """
  Builds a schema-versioned ranking comparison report.
  """
  def ranking_comparison_report(left_rows, right_rows, opts \\ [])
      when is_list(left_rows) and is_list(right_rows) do
    comparison = compare_rankings(left_rows, right_rows, opts)

    comparison
    |> Map.put("schema_contract", "ranking_comparison_report.v1")
    |> Map.put("source", Keyword.get(opts, :source, "optimizer.compare_rankings"))
    |> Map.put("model_limits", @ranking_comparison_model_limits)
    |> Map.update!("objective", &(&1 || "unspecified"))
    |> Map.put("row_count", length(comparison["rows"]))
  end

  @doc """
  Builds a deterministic Pareto-frontier summary from scored objective vectors.

  This is an explainability artifact, not a solver. Each row must have an id
  under `:id`, `"id"`, `:scenario_id`, or `"scenario_id"` and objective values
  under `:objectives`, `"objectives"`, `:score_terms`, or `"score_terms"`.
  Directions are supplied as a map of objective key to `"maximize"` or
  `"minimize"`; unspecified objective directions default to `"maximize"`.
  """
  def pareto_frontier_report(rows, opts \\ []) when is_list(rows) do
    alternatives = normalize_objective_vectors(rows)
    directions = objective_directions(alternatives, Keyword.get(opts, :objective_directions, %{}))

    report_rows =
      alternatives
      |> Enum.map(fn alternative ->
        dominated_by_ids =
          alternatives
          |> Enum.reject(&(&1["id"] == alternative["id"]))
          |> Enum.filter(&dominates?(&1, alternative, directions))
          |> Enum.map(& &1["id"])
          |> Enum.sort()

        dominates_ids =
          alternatives
          |> Enum.reject(&(&1["id"] == alternative["id"]))
          |> Enum.filter(&dominates?(alternative, &1, directions))
          |> Enum.map(& &1["id"])
          |> Enum.sort()

        alternative
        |> Map.put("frontier", dominated_by_ids == [])
        |> Map.put("dominated_by_ids", dominated_by_ids)
        |> Map.put("dominates_ids", dominates_ids)
      end)
      |> Enum.sort_by(&pareto_row_sort_key/1)

    frontier_ids =
      report_rows
      |> Enum.filter(& &1["frontier"])
      |> Enum.map(& &1["id"])

    dominated_ids =
      report_rows
      |> Enum.reject(& &1["frontier"])
      |> Enum.map(& &1["id"])

    %{
      "schema_contract" => "pareto_frontier_report.v1",
      "model" => @pareto_frontier_model,
      "source" => Keyword.get(opts, :source, "optimizer.pareto_frontier"),
      "alternative_count" => length(report_rows),
      "objective_count" => map_size(directions),
      "frontier_count" => length(frontier_ids),
      "dominated_count" => length(dominated_ids),
      "frontier_ids" => frontier_ids,
      "dominated_ids" => dominated_ids,
      "objective_directions" => directions,
      "model_limits" => @pareto_frontier_model_limits,
      "rows" => report_rows,
      "assumptions" => %{
        "comparison_scope" => "objective_vectors",
        "dominance_rule" => "no_worse_on_all_objectives_and_better_on_at_least_one",
        "missing_objective_policy" => "alternative_with_missing_objective_cannot_dominate",
        "external_solver" => false,
        "search_performed" => false
      }
    }
  end

  defp optimizer_contract_id(nil), do: "optimizer_contract:v1"
  defp optimizer_contract_id(plan_id), do: "optimizer_contract:#{plan_id}"

  defp activity_ids(activities) do
    activities
    |> Enum.map(&Map.get(&1, "id"))
    |> Enum.reject(&is_nil/1)
  end

  defp ranked_scenario_ids(timelines) do
    timelines
    |> Enum.map(&Map.get(&1, "scenario_id"))
    |> Enum.reject(&is_nil/1)
  end

  defp score_term_keys(timelines) do
    timelines
    |> Enum.flat_map(fn timeline ->
      timeline
      |> Map.get("score_terms", %{})
      |> Map.keys()
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp normalize_objective_direction!(direction) when direction in [:maximize, "maximize"],
    do: :maximize

  defp normalize_objective_direction!(direction) when direction in [:minimize, "minimize"],
    do: :minimize

  defp normalize_objective_direction!(_direction) do
    raise ArgumentError,
          "objective_direction must be :maximize, :minimize, \"maximize\", or \"minimize\""
  end

  defp evaluate_score_terms!(score_terms_fun, alternative) do
    case score_terms_fun.(alternative["parameters"]) do
      score_terms when is_map(score_terms) and map_size(score_terms) > 0 ->
        normalize_score_terms!(score_terms, alternative["id"])

      _invalid ->
        raise ArgumentError,
              "score_terms_fun must return a non-empty numeric map for #{alternative["id"]}"
    end
  end

  defp normalize_score_terms!(score_terms, alternative_id) do
    entries =
      Enum.map(score_terms, fn
        {key, value} when (is_atom(key) or is_binary(key)) and is_number(value) ->
          {normalize_score_term_name!(key, alternative_id), value}

        _entry ->
          raise ArgumentError,
                "score_terms_fun must return named numeric contributions for #{alternative_id}"
      end)

    names = Enum.map(entries, &elem(&1, 0))

    if length(names) != length(Enum.uniq(names)) do
      raise ArgumentError,
            "score_terms_fun returned duplicate names after key normalization for #{alternative_id}"
    end

    Map.new(entries)
  end

  defp normalize_score_term_name!(key, alternative_id) do
    name = to_string(key)

    if Regex.match?(~r/^[A-Za-z][A-Za-z0-9_.-]*$/, name) do
      name
    else
      raise ArgumentError,
            "score_terms_fun returned an invalid contribution name for #{alternative_id}"
    end
  end

  defp sum_score_terms(score_terms) do
    score_terms
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.reduce(0, fn {_name, value}, score -> score + value end)
  end

  defp objective_score_order(:maximize), do: "objective score descending"
  defp objective_score_order(:minimize), do: "objective score ascending"

  defp local_search_sort_key(alternative, :maximize) do
    {-alternative["score"], alternative["generation_index"], alternative["id"]}
  end

  defp local_search_sort_key(alternative, :minimize) do
    {alternative["score"], alternative["generation_index"], alternative["id"]}
  end

  defp improvement_from_seed(selected, seed, :maximize),
    do: selected["score"] - seed["score"]

  defp improvement_from_seed(selected, seed, :minimize),
    do: seed["score"] - selected["score"]

  defp local_search_selection_explanation(alternative, selected, objective_direction) do
    cond do
      alternative["id"] == selected["id"] ->
        "selected_best_score_then_generation_order_then_id"

      alternative["score"] == selected["score"] ->
        "equal_score_later_generation_order_or_id"

      objective_direction == :maximize ->
        "lower_score"

      objective_direction == :minimize ->
        "higher_score"
    end
  end

  defp hard_local_search_selection_explanation(alternative, selected, objective_direction) do
    cond do
      not get_in(alternative, ["candidate_feasibility", "eligible"]) ->
        "ineligible_hard_feasibility"

      alternative["id"] == selected["id"] ->
        "selected_best_feasible_score_then_generation_order_then_id"

      true ->
        local_search_selection_explanation(alternative, selected, objective_direction)
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

  defp normalize_ranking(rows) do
    rows
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {row, rank} ->
      case scenario_id(row) do
        nil ->
          []

        scenario_id ->
          [
            %{
              "scenario_id" => scenario_id,
              "rank" => rank,
              "value" => value(row),
              "objective" => field(row, :objective)
            }
          ]
      end
    end)
  end

  defp comparison_row(scenario_id, left_by_id, right_by_id) do
    left = Map.get(left_by_id, scenario_id)
    right = Map.get(right_by_id, scenario_id)

    %{
      "scenario_id" => scenario_id,
      "status" => comparison_status(left, right),
      "left_rank" => rank(left),
      "right_rank" => rank(right),
      "rank_delta" => rank_delta(left, right),
      "left_value" => value_from_normalized(left),
      "right_value" => value_from_normalized(right),
      "value_delta" => value_delta(left, right)
    }
  end

  defp comparison_sort_key(%{"right_rank" => nil, "left_rank" => nil, "scenario_id" => id}),
    do: {1_000_000, 1_000_000, id}

  defp comparison_sort_key(%{"right_rank" => nil, "left_rank" => left_rank, "scenario_id" => id}),
    do: {1_000_000, left_rank, id}

  defp comparison_sort_key(%{
         "right_rank" => right_rank,
         "left_rank" => left_rank,
         "scenario_id" => id
       }),
       do: {right_rank, left_rank || 1_000_000, id}

  defp winner_summary(nil, nil) do
    %{
      "left_scenario_id" => nil,
      "right_scenario_id" => nil,
      "changed" => false
    }
  end

  defp winner_summary(left, right) do
    left_scenario_id = scenario_id(left)
    right_scenario_id = scenario_id(right)

    %{
      "left_scenario_id" => left_scenario_id,
      "right_scenario_id" => right_scenario_id,
      "changed" => left_scenario_id != right_scenario_id
    }
  end

  defp comparison_status(nil, _right), do: "right_only"
  defp comparison_status(_left, nil), do: "left_only"
  defp comparison_status(_left, _right), do: "matched"

  defp rank(nil), do: nil
  defp rank(row), do: row["rank"]

  defp rank_delta(nil, _right), do: nil
  defp rank_delta(_left, nil), do: nil
  defp rank_delta(left, right), do: left["rank"] - right["rank"]

  defp value_from_normalized(nil), do: nil
  defp value_from_normalized(row), do: row["value"]

  defp value_delta(nil, _right), do: nil
  defp value_delta(_left, nil), do: nil

  defp value_delta(left, right) do
    left_value = left["value"]
    right_value = right["value"]

    if is_number(left_value) and is_number(right_value) do
      right_value - left_value
    end
  end

  defp inferred_objective(left, right) do
    (left ++ right)
    |> Enum.map(& &1["objective"])
    |> Enum.reject(&is_nil/1)
    |> List.first()
  end

  defp normalize_objective_vectors(rows) do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn row ->
      id = Map.get(row, "id") || Map.get(row, "scenario_id")
      objectives = Map.get(row, "objectives") || Map.get(row, "score_terms") || %{}

      cond do
        is_nil(id) ->
          []

        not is_map(objectives) ->
          []

        true ->
          objective_values =
            objectives
            |> stringify_keys()
            |> Enum.flat_map(fn
              {key, value} ->
                case numeric_value(value) do
                  number when is_number(number) -> [{key, number}]
                  nil -> []
                end
            end)
            |> Map.new()

          [
            %{
              "id" => id,
              "scenario_id" => Map.get(row, "scenario_id", id),
              "objective_values" => objective_values,
              "objective_keys" => objective_values |> Map.keys() |> Enum.sort()
            }
          ]
      end
    end)
  end

  defp objective_directions(alternatives, supplied_directions) do
    supplied_directions = stringify_keys(supplied_directions || %{})

    alternatives
    |> Enum.flat_map(& &1["objective_keys"])
    |> Enum.uniq()
    |> Enum.sort()
    |> Map.new(fn key ->
      direction =
        case Map.get(supplied_directions, key, "maximize") do
          direction when direction in [:minimize, "minimize"] -> "minimize"
          _direction -> "maximize"
        end

      {key, direction}
    end)
  end

  defp dominates?(left, right, directions) do
    objective_keys = Map.keys(directions)

    objective_keys != [] and
      Enum.all?(objective_keys, &no_worse?(left, right, &1, Map.fetch!(directions, &1))) and
      Enum.any?(objective_keys, &better?(left, right, &1, Map.fetch!(directions, &1)))
  end

  defp no_worse?(left, right, key, direction) do
    left_value = get_in(left, ["objective_values", key])
    right_value = get_in(right, ["objective_values", key])

    cond do
      not is_number(left_value) or not is_number(right_value) -> false
      direction == "minimize" -> left_value <= right_value
      true -> left_value >= right_value
    end
  end

  defp better?(left, right, key, direction) do
    left_value = get_in(left, ["objective_values", key])
    right_value = get_in(right, ["objective_values", key])

    cond do
      not is_number(left_value) or not is_number(right_value) -> false
      direction == "minimize" -> left_value < right_value
      true -> left_value > right_value
    end
  end

  defp pareto_row_sort_key(row), do: {if(row["frontier"], do: 0, else: 1), row["id"]}

  defp scenario_id(row), do: field(row, :scenario_id)
  defp value(row), do: numeric_value(field(row, :value))

  defp numeric_value(value) when is_number(value), do: value

  defp numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_value(_value), do: nil

  defp field(nil, _key), do: nil

  defp field(%{} = row, key) do
    Map.get(row, key) || Map.get(row, Atom.to_string(key))
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
  end

  defp stringify_keys(_value), do: %{}
end
