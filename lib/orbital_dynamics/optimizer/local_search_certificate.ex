defmodule OrbitalDynamics.Optimizer.LocalSearchCertificate do
  @moduledoc """
  Executable certificates for bounded exact enumeration of one local neighborhood.

  This module does not replace the existing explainable local-search heuristic.
  It is an opt-in wrapper that enumerates the complete finite neighborhood
  described by `OrbitalDynamics.Search.Local`, evaluates candidates in the
  generator's deterministic order up to an explicit budget, and records whether
  exhaustion supports a claim about that finite set.

  Verification is fail closed: callers must provide the original seed, options,
  source-evidence registry, and evaluator so the certificate can be reproduced
  exactly. Source evidence is content-addressed but is not authenticated.
  """

  alias OrbitalDynamics.Schema
  alias OrbitalDynamics.Schema.JsonSafety
  alias OrbitalDynamics.Search.Local

  @schema_contract "local_search_optimization_certificate.v1"
  @model "exact_enumeration_of_deterministic_bounded_axis_step_neighborhood"
  @identity_algorithm "erlang_term_to_binary_deterministic_sha256.v1"
  @source_trust_boundary "caller_supplied_replay_evidence_not_authenticated"
  @max_evaluations 65
  @allowed_options [
    :steps,
    :bounds,
    :id_prefix,
    :evaluation_budget,
    :objective,
    :objective_direction
  ]
  @model_limits [
    "claim_is_limited_to_the_declared_enumerated_finite_search_space",
    "numeric_scalar_parameters_only",
    "single_axis_single_step_moves_only",
    "box_bounds_only",
    "one_neighborhood_generation",
    "at_most_65_evaluated_candidates",
    "score_is_sum_of_caller_supplied_terms",
    "caller_must_supply_a_pure_deterministic_evaluator",
    "caller_supplied_source_evidence_is_content_addressed_not_authenticated",
    "coordinated_certificate_source_evidence_and_evaluator_replacement_is_out_of_scope",
    "no_iterative_convergence_or_coupled_moves",
    "no_external_solver_execution",
    "no_global_optimality_claim",
    "not_calibrated_from_operational_outcomes"
  ]

  @stable_id ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/
  @score_term_name ~r/^[A-Za-z][A-Za-z0-9_.-]*$/
  @max_float 1.7976931348623157e308

  def schema_contract, do: @schema_contract
  def model, do: @model
  def identity_algorithm, do: @identity_algorithm
  def source_trust_boundary, do: @source_trust_boundary
  def max_evaluations, do: @max_evaluations
  def model_limits, do: @model_limits

  def capabilities do
    %{
      mode: :opt_in_exact_finite_neighborhood_enumeration,
      artifact_contract: @schema_contract,
      search_model: @model,
      source_search_generator: Local.capabilities().model,
      max_evaluations: @max_evaluations,
      evaluation_callback: :score_terms_eligibility_and_rejection_reasons,
      verification: :exact_replay_against_caller_supplied_source_evidence,
      source_evidence_trust_boundary: @source_trust_boundary,
      claim_scope: :enumerated_finite_search_space_only,
      global_optimality_claimed: false,
      model_limits: @model_limits
    }
  end

  @doc """
  Enumerates and evaluates a complete bounded local neighborhood.

  `source_evidence` must be a map keyed by every in-bounds alternative ID.
  Every evidence entry must contain stable string `id` and `revision` fields;
  additional JSON-safe evidence is allowed and content-addressed.

  `evaluator_fun` receives `(parameters, source_evidence_entry)` and must return
  a map containing:

    * `score_terms` - a non-empty finite numeric map;
    * `eligible` - a boolean; and
    * `rejection_reasons` - empty for eligible candidates and one or more
      non-empty strings for rejected candidates.

  The required `:steps` option and optional `:bounds` and `:id_prefix` options
  have the same meaning as `Search.Local.neighborhood/2`. `:evaluation_budget`
  defaults to 65 and must be from 1 through 65. A budget smaller than the
  in-bounds candidate count emits a valid incomplete certificate with no
  optimality claim. `:objective_direction` is `:maximize` by default and may be
  `:minimize`.
  """
  def build(seed_parameters, source_evidence, evaluator_fun, opts)

  def build(seed_parameters, source_evidence, evaluator_fun, opts)
      when is_map(seed_parameters) and is_map(source_evidence) and
             is_function(evaluator_fun, 2) and is_list(opts) do
    options = normalize_options!(opts)
    search_space = build_search_space(seed_parameters, options)
    evidence = normalize_source_evidence!(source_evidence, search_space)
    source_registry = source_evidence_registry(evidence, search_space)

    evaluations =
      search_space["candidates"]
      |> Enum.take(options.evaluation_budget)
      |> Enum.map(&evaluate_candidate(&1, evidence, source_registry, evaluator_fun))

    ranked = ranked_eligible(evaluations, options.objective_direction)
    rank_by_id = Map.new(ranked, &{&1["alternative_id"], &1["rank"]})

    evaluations =
      evaluations
      |> add_incumbent_history(options.objective_direction)
      |> Enum.map(&Map.put(&1, "rank", Map.get(rank_by_id, &1["alternative_id"], :null)))

    selected = List.first(ranked)
    evaluated_count = length(evaluations)
    eligible_count = Enum.count(evaluations, & &1["eligible"])
    rejected_count = evaluated_count - eligible_count
    candidate_count = search_space["candidate_count"]
    search_space_exhausted = evaluated_count == candidate_count
    budget_limited = evaluated_count < candidate_count

    core = %{
      "schema_contract" => @schema_contract,
      "model" => @model,
      "objective" => options.objective,
      "objective_direction" => Atom.to_string(options.objective_direction),
      "claim" => claim(search_space_exhausted, selected),
      "global_optimality_claimed" => false,
      "search_space" => search_space,
      "source_evidence_registry" => source_registry,
      "evaluation_budget" => options.evaluation_budget,
      "budget_used" => evaluated_count,
      "budget_remaining" => options.evaluation_budget - evaluated_count,
      "budget_limited" => budget_limited,
      "search_space_exhausted" => search_space_exhausted,
      "termination_reason" =>
        if(search_space_exhausted,
          do: "search_space_exhausted",
          else: "evaluation_budget_exhausted"
        ),
      "evaluated_count" => evaluated_count,
      "eligible_count" => eligible_count,
      "rejected_count" => rejected_count,
      "unevaluated_count" => candidate_count - evaluated_count,
      "selected_alternative_id" => if(selected, do: selected["alternative_id"], else: :null),
      "selected_score" => if(selected, do: selected["score"], else: :null),
      "eligible_ids_by_rank" => Enum.map(ranked, & &1["alternative_id"]),
      "evaluations" => evaluations,
      "deterministic_ordering" => deterministic_ordering(options.objective_direction),
      "incumbent_update_rule" => incumbent_update_rule(options.objective_direction),
      "model_limits" => @model_limits,
      "assumptions" => %{
        "score_rule" => "sum_of_score_terms",
        "evaluator" => "caller_supplied_and_required_to_be_pure_and_deterministic",
        "eligibility_timing" => "during_deterministic_enumeration_before_ranking",
        "source_evidence_trust_boundary" => @source_trust_boundary,
        "external_solver" => false,
        "global_search" => false
      }
    }

    certificate = Map.put(core, "id", certificate_id(core))

    case Schema.validate_artifact(certificate, schema_contract: @schema_contract) do
      {:ok, _report} ->
        certificate

      {:error, report} ->
        raise ArgumentError,
              "generated local-search optimization certificate failed its schema contract: #{inspect(report["errors"])}"
    end
  end

  def build(_seed_parameters, _source_evidence, _evaluator_fun, _opts) do
    raise ArgumentError,
          "seed_parameters and source_evidence must be maps, evaluator_fun must have arity 2, and opts must be a keyword list"
  end

  @doc """
  Replays a certificate from the original trusted inputs and fails closed.

  The caller must provide the same seed, evidence, evaluator, and options used to
  build the certificate. Verification first applies the executable schema, then
  reproduces the full certificate and requires exact equality.
  """
  def verify(certificate, seed_parameters, source_evidence, evaluator_fun, opts)

  def verify(certificate, seed_parameters, source_evidence, evaluator_fun, opts)
      when is_map(certificate) and is_map(seed_parameters) and is_map(source_evidence) and
             is_function(evaluator_fun, 2) and is_list(opts) do
    with {:ok, schema_report} <-
           Schema.validate_artifact(certificate, schema_contract: @schema_contract),
         expected <- build(seed_parameters, source_evidence, evaluator_fun, opts),
         true <- certificate == expected do
      {:ok,
       %{
         "status" => "verified",
         "certificate_id" => certificate["id"],
         "schema_validation_status" => schema_report["status"],
         "search_space_identity" => get_in(certificate, ["search_space", "identity"]),
         "source_evidence_identity" =>
           get_in(certificate, ["source_evidence_registry", "identity"]),
         "claim" => certificate["claim"]
       }}
    else
      {:error, schema_report} ->
        {:error,
         verification_failure(
           certificate,
           "certificate_schema_invalid",
           %{"schema_validation" => schema_report}
         )}

      false ->
        {:error,
         verification_failure(
           certificate,
           "certificate_does_not_match_replayed_source_evidence_and_evaluation",
           %{}
         )}
    end
  rescue
    error ->
      {:error,
       verification_failure(certificate, "replay_input_or_source_evidence_invalid", %{
         "detail" => Exception.message(error)
       })}
  end

  def verify(certificate, _seed_parameters, _source_evidence, _evaluator_fun, _opts) do
    {:error,
     verification_failure(certificate, "invalid_verifier_arguments", %{
       "detail" =>
         "certificate, seed_parameters, and source_evidence must be maps; evaluator_fun must have arity 2; opts must be a keyword list"
     })}
  end

  @doc false
  def content_identity(value) do
    %{"algorithm" => @identity_algorithm, "sha256" => deterministic_digest(value)}
  end

  @doc false
  def certificate_id(core) when is_map(core),
    do: "local_search_optimization_certificate:" <> deterministic_digest(core)

  @doc false
  def search_space_identity(search_space_core) when is_map(search_space_core),
    do: content_identity(search_space_core)

  @doc false
  def source_registry_identity(registry_core) when is_map(registry_core),
    do: content_identity(registry_core)

  defp normalize_options!(opts) do
    unless Keyword.keyword?(opts), do: raise(ArgumentError, "opts must be a keyword list")

    option_keys = Keyword.keys(opts)

    if length(option_keys) != length(Enum.uniq(option_keys)),
      do: raise(ArgumentError, "opts must not contain duplicate keys")

    case Enum.find(option_keys, &(&1 not in @allowed_options)) do
      nil -> :ok
      key -> raise ArgumentError, "unsupported certified local-search option #{inspect(key)}"
    end

    unless Keyword.has_key?(opts, :steps),
      do: raise(ArgumentError, "missing required :steps option")

    evaluation_budget = Keyword.get(opts, :evaluation_budget, @max_evaluations)

    unless is_integer(evaluation_budget) and evaluation_budget >= 1 and
             evaluation_budget <= @max_evaluations do
      raise ArgumentError,
            "evaluation_budget must be an integer from 1 through #{@max_evaluations}"
    end

    objective = Keyword.get(opts, :objective, "sum_of_score_terms")

    unless is_binary(objective) and objective != "" and String.valid?(objective),
      do: raise(ArgumentError, "objective must be a non-empty UTF-8 string")

    %{
      steps: Keyword.fetch!(opts, :steps),
      bounds: Keyword.get(opts, :bounds, %{}),
      id_prefix: stable_id!(Keyword.get(opts, :id_prefix, "local"), "id_prefix"),
      evaluation_budget: evaluation_budget,
      objective: objective,
      objective_direction:
        normalize_objective_direction!(Keyword.get(opts, :objective_direction, :maximize))
    }
  end

  defp normalize_objective_direction!(direction) when direction in [:maximize, "maximize"],
    do: :maximize

  defp normalize_objective_direction!(direction) when direction in [:minimize, "minimize"],
    do: :minimize

  defp normalize_objective_direction!(_direction),
    do: raise(ArgumentError, "objective_direction must be :maximize or :minimize")

  defp build_search_space(seed_parameters, options) do
    neighborhood =
      Local.neighborhood(
        seed_parameters,
        steps: options.steps,
        bounds: options.bounds,
        id_prefix: options.id_prefix,
        max_alternatives: @max_evaluations
      )

    JsonSafety.validate_artifact!(neighborhood, "local search space")

    core = %{
      "generator_model" => neighborhood["model"],
      "seed_id" => neighborhood["seed_id"],
      "seed_parameters" => neighborhood["seed_parameters"],
      "step_parameters" => neighborhood["step_parameters"],
      "steps" => neighborhood["steps"],
      "bounds" => neighborhood["bounds"],
      "ordering" => neighborhood["ordering"],
      "id_prefix" => options.id_prefix,
      "candidate_count" => neighborhood["alternative_count"],
      "generation_attempt_count" => neighborhood["generated_move_count"],
      "generation_rejected_count" => neighborhood["rejected_move_count"],
      "candidates" => neighborhood["alternatives"],
      "generation_rejected_moves" => neighborhood["rejected_moves"]
    }

    Map.put(core, "identity", search_space_identity(core))
  end

  defp normalize_source_evidence!(source_evidence, search_space) do
    source_evidence = JsonSafety.normalize_input!(source_evidence, "source_evidence")
    candidate_ids = Enum.map(search_space["candidates"], & &1["id"])
    evidence_ids = Map.keys(source_evidence) |> Enum.sort()

    unless evidence_ids == Enum.sort(candidate_ids) do
      raise ArgumentError,
            "source_evidence keys must exactly match every in-bounds search-space alternative ID"
    end

    Map.new(source_evidence, fn {alternative_id, entry} ->
      unless is_map(entry),
        do: raise(ArgumentError, "source_evidence.#{alternative_id} must be a map")

      source_id = stable_id!(entry["id"], "source_evidence.#{alternative_id}.id")

      revision =
        stable_id!(entry["revision"], "source_evidence.#{alternative_id}.revision")

      if map_size(entry) < 2,
        do: raise(ArgumentError, "source_evidence.#{alternative_id} must contain id and revision")

      {alternative_id,
       %{
         entry: entry,
         summary: %{
           "alternative_id" => alternative_id,
           "source_id" => source_id,
           "source_revision" => revision,
           "content_identity" => content_identity(entry)
         }
       }}
    end)
  end

  defp source_evidence_registry(evidence, search_space) do
    candidate_ids = Enum.map(search_space["candidates"], & &1["id"])
    entries = Enum.map(candidate_ids, &evidence[&1].summary)

    core = %{
      "trust_boundary" => @source_trust_boundary,
      "entry_count" => length(entries),
      "entries" => entries
    }

    Map.put(core, "identity", source_registry_identity(core))
  end

  defp evaluate_candidate(candidate, evidence, source_registry, evaluator_fun) do
    evidence_row = Map.fetch!(evidence, candidate["id"])

    result =
      candidate["parameters"]
      |> evaluator_fun.(evidence_row.entry)
      |> JsonSafety.normalize_input!("certified local-search evaluator result")

    unless is_map(result) and
             Enum.sort(Map.keys(result)) ==
               ~w(eligible rejection_reasons score_terms) do
      raise ArgumentError,
            "evaluator result must contain exactly eligible, rejection_reasons, and score_terms"
    end

    score_terms = normalize_score_terms!(result["score_terms"])
    eligible = result["eligible"]
    rejection_reasons = normalize_rejection_reasons!(result["rejection_reasons"])

    unless is_boolean(eligible),
      do: raise(ArgumentError, "evaluator eligible must be boolean")

    cond do
      eligible and rejection_reasons != [] ->
        raise ArgumentError, "eligible evaluator results must not contain rejection reasons"

      not eligible and rejection_reasons == [] ->
        raise ArgumentError, "rejected evaluator results must contain rejection reasons"

      true ->
        :ok
    end

    score = Enum.reduce(Map.values(score_terms), 0, &Kernel.+/2)

    unless finite_number?(score),
      do: raise(ArgumentError, "summed score_terms must produce a finite score")

    source_entry =
      Enum.find(source_registry["entries"], &(&1["alternative_id"] == candidate["id"]))

    %{
      "alternative_id" => candidate["id"],
      "generation_index" => candidate["generation_index"],
      "source_evidence_identity" => source_entry["content_identity"],
      "score_terms" => score_terms,
      "score" => score,
      "eligible" => eligible,
      "rejection_reasons" => rejection_reasons
    }
  end

  defp normalize_score_terms!(terms) when is_map(terms) do
    terms = JsonSafety.normalize_input!(terms, "score_terms")

    cond do
      map_size(terms) == 0 ->
        raise ArgumentError, "score_terms must be a non-empty map"

      Enum.any?(terms, fn {name, value} ->
        not Regex.match?(@score_term_name, name) or not finite_number?(value)
      end) ->
        raise ArgumentError,
              "score_terms must use supported names and contain only finite numeric values"

      true ->
        terms
    end
  end

  defp normalize_score_terms!(_terms),
    do: raise(ArgumentError, "score_terms must be a non-empty map")

  defp normalize_rejection_reasons!(reasons) when is_list(reasons) do
    if Enum.all?(reasons, &(is_binary(&1) and &1 != "" and String.valid?(&1))) do
      reasons |> Enum.uniq() |> Enum.sort()
    else
      raise ArgumentError, "rejection_reasons must be a list of non-empty UTF-8 strings"
    end
  end

  defp normalize_rejection_reasons!(_reasons),
    do: raise(ArgumentError, "rejection_reasons must be a list")

  defp ranked_eligible(evaluations, direction) do
    evaluations
    |> Enum.filter(& &1["eligible"])
    |> Enum.sort_by(&evaluation_sort_key(&1, direction))
    |> Enum.with_index(1)
    |> Enum.map(fn {evaluation, rank} -> Map.put(evaluation, "rank", rank) end)
  end

  defp add_incumbent_history(evaluations, direction) do
    {rows, _incumbent} =
      Enum.map_reduce(evaluations, nil, fn evaluation, incumbent ->
        incumbent = better_incumbent(evaluation, incumbent, direction)
        {Map.put(evaluation, "incumbent_after_evaluation_id", incumbent_id(incumbent)), incumbent}
      end)

    rows
  end

  defp better_incumbent(%{"eligible" => false}, incumbent, _direction), do: incumbent
  defp better_incumbent(evaluation, nil, _direction), do: evaluation

  defp better_incumbent(evaluation, incumbent, direction) do
    if evaluation_sort_key(evaluation, direction) < evaluation_sort_key(incumbent, direction),
      do: evaluation,
      else: incumbent
  end

  defp incumbent_id(nil), do: :null
  defp incumbent_id(incumbent), do: incumbent["alternative_id"]

  defp evaluation_sort_key(evaluation, :maximize),
    do: {-evaluation["score"], evaluation["generation_index"], evaluation["alternative_id"]}

  defp evaluation_sort_key(evaluation, :minimize),
    do: {evaluation["score"], evaluation["generation_index"], evaluation["alternative_id"]}

  defp claim(false, _selected) do
    %{
      "status" => "not_supported",
      "type" => "no_optimality_claim",
      "scope" => "enumerated_search_space_only",
      "selected_alternative_id" => :null,
      "reason" => "evaluation_budget_exhausted_before_search_space",
      "global_optimality_claimed" => false
    }
  end

  defp claim(true, nil) do
    %{
      "status" => "supported",
      "type" => "no_eligible_alternative_in_enumerated_finite_neighborhood",
      "scope" => "enumerated_search_space_only",
      "selected_alternative_id" => :null,
      "reason" => "every_candidate_was_evaluated_and_rejected",
      "global_optimality_claimed" => false
    }
  end

  defp claim(true, selected) do
    %{
      "status" => "supported",
      "type" => "best_eligible_alternative_in_enumerated_finite_neighborhood",
      "scope" => "enumerated_search_space_only",
      "selected_alternative_id" => selected["alternative_id"],
      "reason" => "search_space_exhausted_and_incumbent_ordering_applied",
      "global_optimality_claimed" => false
    }
  end

  defp deterministic_ordering(:maximize) do
    [
      "candidate generation: seed then parameter ascending then decrease then increase",
      "evaluation: candidate generation order",
      "ranking: eligible alternatives only",
      "ranking: objective score descending",
      "tie break: generation_index ascending",
      "tie break: alternative id ascending"
    ]
  end

  defp deterministic_ordering(:minimize) do
    [
      "candidate generation: seed then parameter ascending then decrease then increase",
      "evaluation: candidate generation order",
      "ranking: eligible alternatives only",
      "ranking: objective score ascending",
      "tie break: generation_index ascending",
      "tie break: alternative id ascending"
    ]
  end

  defp incumbent_update_rule(:maximize),
    do:
      "replace incumbent only for eligible higher score, then lower generation_index, then lower alternative id"

  defp incumbent_update_rule(:minimize),
    do:
      "replace incumbent only for eligible lower score, then lower generation_index, then lower alternative id"

  defp verification_failure(certificate, reason, details) do
    %{
      "status" => "rejected",
      "reason" => reason,
      "certificate_id" => if(is_map(certificate), do: certificate["id"] || :null, else: :null),
      "details" => details
    }
  end

  defp stable_id!(value, label) when is_binary(value) do
    if Regex.match?(@stable_id, value),
      do: value,
      else: raise(ArgumentError, "#{label} must be a stable identity")
  end

  defp stable_id!(_value, label),
    do: raise(ArgumentError, "#{label} must be a stable identity")

  defp deterministic_digest(value) do
    value
    |> :erlang.term_to_binary([:deterministic])
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp finite_number?(value) when is_integer(value), do: true

  defp finite_number?(value) when is_float(value),
    do: value == value and value <= @max_float and value >= -@max_float

  defp finite_number?(_value), do: false
end
