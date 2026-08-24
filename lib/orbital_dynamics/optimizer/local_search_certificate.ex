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
  exactly. Public seed, source-evidence, and evaluator-result maps require valid
  UTF-8 string keys and strict JSON values before hashing or search generation;
  atom-keyed and mixed-key BEAM maps are rejected rather than normalized. The
  keyword `opts` argument is the explicit BEAM configuration constructor and is
  parsed separately without becoming certificate identity content. Identity uses
  recursively key-sorted canonical JSON, so object insertion order does not
  change an identity while distinct BEAM aliases such as string/atom keys or
  `nil`/`:null` are never silently collapsed. Source evidence is content-addressed
  but is not authenticated.
  """

  alias OrbitalDynamics.Schema
  alias OrbitalDynamics.Schema.JsonSafety
  alias OrbitalDynamics.Search.Local

  @schema_contract "local_search_optimization_certificate.v1"
  @model "exact_enumeration_of_deterministic_bounded_axis_step_neighborhood"
  @identity_algorithm "canonical_json_sha256.v1"
  @source_trust_boundary "caller_supplied_replay_evidence_not_authenticated"
  @max_evaluations 65
  @evaluator_supervisor OrbitalDynamics.ScenarioSupervisor
  @evaluator_policy_version 1
  @evaluator_worker_model "task_supervisor_async_nolink_per_candidate.v1"
  @default_evaluator_timeout_ms 1_000
  @max_evaluator_timeout_ms 5_000
  @max_option_entries 7
  @max_step_parameters 32
  @max_input_map_entries 2_048
  @max_input_string_bytes 4_194_304
  @allowed_options [
    :steps,
    :bounds,
    :id_prefix,
    :evaluation_budget,
    :objective,
    :objective_direction,
    :evaluator_timeout_ms
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
    "each_evaluator_invocation_runs_in_a_supervised_unlinked_monitored_worker",
    "evaluator_timeout_policy_is_versioned_bounded_and_certificate_bound",
    "caller_supplied_source_evidence_is_content_addressed_not_authenticated",
    "coordinated_certificate_source_evidence_and_evaluator_replacement_is_out_of_scope",
    "no_iterative_convergence_or_coupled_moves",
    "no_external_solver_execution",
    "no_global_optimality_claim",
    "not_calibrated_from_operational_outcomes"
  ]

  @stable_id ~r/\A[A-Za-z0-9][A-Za-z0-9._:@-]*\z/
  @score_term_name ~r/\A[A-Za-z][A-Za-z0-9_.-]*\z/
  @certificate_id ~r/\Alocal_search_optimization_certificate:[0-9a-f]{64}\z/
  @max_float 1.7976931348623157e308

  def schema_contract, do: @schema_contract
  def model, do: @model
  def identity_algorithm, do: @identity_algorithm
  def source_trust_boundary, do: @source_trust_boundary
  def max_evaluations, do: @max_evaluations
  def evaluator_policy_version, do: @evaluator_policy_version
  def default_evaluator_timeout_ms, do: @default_evaluator_timeout_ms
  def max_evaluator_timeout_ms, do: @max_evaluator_timeout_ms
  def model_limits, do: @model_limits

  @doc false
  def evaluator_execution_policy(timeout_ms) do
    %{
      "policy_version" => @evaluator_policy_version,
      "worker_model" => @evaluator_worker_model,
      "timeout_ms" => timeout_ms,
      "timeout_action" => "brutal_kill_then_demonitor_flush_and_drain",
      "caller_cancellation_action" => "monitor_caller_and_brutal_kill_worker"
    }
  end

  def capabilities do
    %{
      mode: :opt_in_exact_finite_neighborhood_enumeration,
      artifact_contract: @schema_contract,
      search_model: @model,
      source_search_generator: Local.capabilities().model,
      max_evaluations: @max_evaluations,
      evaluator_execution_policy: evaluator_execution_policy(@default_evaluator_timeout_ms),
      max_evaluator_timeout_ms: @max_evaluator_timeout_ms,
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
  additional strict JSON evidence is allowed and content-addressed. Map keys
  must be valid UTF-8 strings; atom keys and values, including `:null`, are
  rejected. Elixir `nil` is the only accepted JSON-null input.

  `seed_parameters`, `:steps`, and `:bounds` parameter names must likewise be
  valid UTF-8 strings. Atom-keyed search data is not a public alias for the
  exported JSON contract.

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
  `:minimize`. `:evaluator_timeout_ms` defaults to
  #{@default_evaluator_timeout_ms} and must be from 1 through
  #{@max_evaluator_timeout_ms}; its versioned policy is embedded in the
  certificate and replay identity.

  Malformed input or evaluator failure returns `{:error, json_total_failure}`;
  this public boundary does not raise, throw, or exit for rejected input.
  """
  def build(seed_parameters, source_evidence, evaluator_fun, opts) do
    with :ok <- validate_evaluator_fun(evaluator_fun),
         {:ok, seed_parameters} <-
           validate_parameter_map(seed_parameters, "$.seed_parameters", false),
         {:ok, source_evidence} <- capture_source_evidence(source_evidence),
         {:ok, options} <- normalize_options(opts),
         :ok <- validate_neighborhood_inputs(seed_parameters, options) do
      do_build(seed_parameters, source_evidence, evaluator_fun, options)
    end
  rescue
    error ->
      {:error, input_failure("builder_input_invalid", "error", safe_exception_message(error))}
  catch
    kind, reason ->
      {:error,
       input_failure(
         "builder_input_invalid",
         Atom.to_string(kind),
         safe_inspect(reason)
       )}
  end

  defp do_build(seed_parameters, source_evidence, evaluator_fun, options) do
    search_space = build_search_space(seed_parameters, options)

    case normalize_source_evidence(source_evidence, search_space) do
      {:ok, evidence} ->
        source_registry = source_evidence_registry(evidence, search_space)

        search_space["candidates"]
        |> Enum.take(options.evaluation_budget)
        |> evaluate_candidates(evidence, source_registry, evaluator_fun, options)
        |> case do
          {:ok, evaluations} ->
            finalize_certificate(evaluations, search_space, source_registry, options)

          {:error, failure} ->
            {:error, failure}
        end

      {:error, failure} ->
        {:error, failure}
    end
  end

  defp finalize_certificate(evaluations, search_space, source_registry, options) do
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
      "evaluator_execution_policy" => evaluator_execution_policy(options.evaluator_timeout_ms),
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
        "evaluator" => "caller_supplied_pure_deterministic_supervised_unlinked_bounded_worker",
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
        {:error,
         %{
           "status" => "rejected",
           "reason" => "generated_certificate_schema_invalid",
           "details" => %{"schema_validation" => report}
         }}
    end
  end

  @doc """
  Replays a certificate from the original trusted inputs and fails closed.

  The caller must provide the same seed, evidence, evaluator, and options used to
  build the certificate. Verification first applies the executable schema, then
  reproduces the full certificate and requires exact equality. Every rejection
  is returned as `{:error, json_total_failure}`.
  """
  def verify(certificate, seed_parameters, source_evidence, evaluator_fun, opts) do
    case Schema.validate_artifact(certificate, schema_contract: @schema_contract) do
      {:ok, schema_report} ->
        if is_map(certificate) do
          verify_replay(
            certificate,
            schema_report,
            seed_parameters,
            source_evidence,
            evaluator_fun,
            opts
          )
        else
          {:error,
           verification_failure(certificate, "invalid_verifier_arguments", %{
             "detail" => "certificate must be a strict JSON map"
           })}
        end

      {:error, schema_report} ->
        {:error,
         verification_failure(
           certificate,
           "certificate_schema_invalid",
           %{"schema_validation" => schema_report}
         )}
    end
  rescue
    error ->
      {:error,
       verification_failure(certificate, "replay_input_or_source_evidence_invalid", %{
         "failure_kind" => "error",
         "detail" => safe_exception_message(error)
       })}
  catch
    kind, reason ->
      {:error,
       verification_failure(certificate, "replay_input_or_source_evidence_invalid", %{
         "failure_kind" => Atom.to_string(kind),
         "detail" => safe_inspect(reason)
       })}
  end

  defp verify_replay(
         certificate,
         schema_report,
         seed_parameters,
         source_evidence,
         evaluator_fun,
         opts
       ) do
    case build(seed_parameters, source_evidence, evaluator_fun, opts) do
      %{} = expected when expected == certificate ->
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

      {:error, %{"reason" => "evaluator_execution_failed"} = evaluator_failure} ->
        {:error,
         verification_failure(certificate, "replay_evaluator_execution_failed", %{
           "evaluator_failure" => evaluator_failure
         })}

      {:error, replay_input_failure} ->
        {:error,
         verification_failure(certificate, "replay_input_or_source_evidence_invalid", %{
           "input_failure" => replay_input_failure
         })}

      %{} ->
        {:error,
         verification_failure(
           certificate,
           "certificate_does_not_match_replayed_source_evidence_and_evaluation",
           %{}
         )}
    end
  end

  @doc false
  def content_identity(value) do
    case deterministic_digest(value) do
      {:ok, digest} -> %{"algorithm" => @identity_algorithm, "sha256" => digest}
      {:error, failure} -> {:error, failure}
    end
  end

  @doc false
  def certificate_id(core) when is_map(core) do
    case deterministic_digest(core) do
      {:ok, digest} -> "local_search_optimization_certificate:" <> digest
      {:error, failure} -> {:error, failure}
    end
  end

  def certificate_id(_core),
    do: {:error, identity_failure("certificate_identity_input_must_be_a_strict_json_object")}

  @doc false
  def search_space_identity(search_space_core) when is_map(search_space_core),
    do: content_identity(search_space_core)

  def search_space_identity(_search_space_core),
    do: {:error, identity_failure("search_space_identity_input_must_be_a_strict_json_object")}

  @doc false
  def source_registry_identity(registry_core) when is_map(registry_core),
    do: content_identity(registry_core)

  def source_registry_identity(_registry_core),
    do: {:error, identity_failure("source_registry_identity_input_must_be_a_strict_json_object")}

  defp normalize_options(opts) do
    with {:ok, entries} <- collect_option_entries(opts, 0, []),
         :ok <- validate_option_keys(entries),
         {:ok, steps} <-
           validate_parameter_map(
             option_value(entries, :steps, :missing),
             "$.options.steps",
             false
           ),
         {:ok, bounds} <- validate_bounds(option_value(entries, :bounds, %{})),
         {:ok, id_prefix} <-
           validate_stable_id(option_value(entries, :id_prefix, "local"), "$.options.id_prefix"),
         {:ok, evaluation_budget} <-
           validate_bounded_integer(
             option_value(entries, :evaluation_budget, @max_evaluations),
             "$.options.evaluation_budget",
             @max_evaluations
           ),
         {:ok, evaluator_timeout_ms} <-
           validate_bounded_integer(
             option_value(entries, :evaluator_timeout_ms, @default_evaluator_timeout_ms),
             "$.options.evaluator_timeout_ms",
             @max_evaluator_timeout_ms
           ),
         {:ok, objective} <-
           validate_non_empty_string(
             option_value(entries, :objective, "sum_of_score_terms"),
             "$.options.objective"
           ),
         {:ok, objective_direction} <-
           normalize_objective_direction(option_value(entries, :objective_direction, :maximize)) do
      {:ok,
       %{
         steps: steps,
         bounds: bounds,
         id_prefix: id_prefix,
         evaluation_budget: evaluation_budget,
         evaluator_timeout_ms: evaluator_timeout_ms,
         objective: objective,
         objective_direction: objective_direction
       }}
    end
  end

  defp collect_option_entries([], _count, entries), do: {:ok, Enum.reverse(entries)}

  defp collect_option_entries([_entry | _tail], count, _entries)
       when count >= @max_option_entries,
       do: builder_error("$.options", "must contain at most #{@max_option_entries} entries")

  defp collect_option_entries([{key, value} | tail], count, entries) when is_atom(key),
    do: collect_option_entries(tail, count + 1, [{key, value} | entries])

  defp collect_option_entries([_entry | _tail], _count, _entries),
    do: builder_error("$.options", "must contain only atom-keyed option pairs")

  defp collect_option_entries(_improper, _count, _entries),
    do: builder_error("$.options", "must be a proper keyword list")

  defp validate_option_keys(entries) do
    keys = Enum.map(entries, &elem(&1, 0))

    cond do
      length(keys) != length(Enum.uniq(keys)) ->
        builder_error("$.options", "must not contain duplicate or conflicting options")

      Enum.any?(keys, &(&1 not in @allowed_options)) ->
        builder_error("$.options", "contains an unsupported certified local-search option")

      :steps not in keys ->
        builder_error("$.options.steps", "is required")

      true ->
        :ok
    end
  end

  defp option_value(entries, key, default) do
    case List.keyfind(entries, key, 0) do
      {^key, value} -> value
      nil -> default
    end
  end

  defp normalize_objective_direction(direction) when direction in [:maximize, "maximize"],
    do: {:ok, :maximize}

  defp normalize_objective_direction(direction) when direction in [:minimize, "minimize"],
    do: {:ok, :minimize}

  defp normalize_objective_direction(_direction),
    do: builder_error("$.options.objective_direction", "must be maximize or minimize")

  defp validate_evaluator_fun(evaluator_fun) do
    if is_function(evaluator_fun, 2),
      do: :ok,
      else: builder_error("$.evaluator", "must be a function with arity 2")
  end

  defp validate_parameter_map(parameters, path, allow_empty?)
       when is_map(parameters) and map_size(parameters) <= @max_input_map_entries do
    cond do
      map_size(parameters) == 0 and not allow_empty? ->
        builder_error(path, "must be a non-empty map")

      Enum.any?(parameters, fn {name, _value} -> not valid_parameter_name?(name) end) ->
        builder_error(path, "must use valid UTF-8 string parameter names only")

      Enum.any?(parameters, fn {_name, value} -> not finite_number?(value) end) ->
        builder_error(path, "must contain only finite numeric values")

      true ->
        {:ok, parameters}
    end
  end

  defp validate_parameter_map(parameters, path, _allow_empty?) when is_map(parameters),
    do: builder_error(path, "exceeds the bounded input map size")

  defp validate_parameter_map(_parameters, path, _allow_empty?),
    do: builder_error(path, "must be a string-keyed finite numeric map")

  defp validate_bounds(bounds)
       when is_map(bounds) and map_size(bounds) <= @max_step_parameters do
    bounds
    |> Enum.reduce_while({:ok, %{}}, fn
      {name, {minimum, maximum}}, {:ok, validated}
      when is_binary(name) ->
        cond do
          not valid_parameter_name?(name) ->
            {:halt,
             builder_error("$.options.bounds", "must use valid UTF-8 string parameter names only")}

          not finite_number?(minimum) or not finite_number?(maximum) ->
            {:halt,
             builder_error("$.options.bounds.#{name}", "must contain finite numeric bounds")}

          minimum > maximum ->
            {:halt, builder_error("$.options.bounds.#{name}", "minimum must not exceed maximum")}

          true ->
            {:cont, {:ok, Map.put(validated, name, {minimum, maximum})}}
        end

      {_name, _bound}, _acc ->
        {:halt,
         builder_error(
           "$.options.bounds",
           "must contain string-keyed numeric {minimum, maximum} tuples"
         )}
    end)
  end

  defp validate_bounds(bounds) when is_map(bounds),
    do: builder_error("$.options.bounds", "may contain at most #{@max_step_parameters} entries")

  defp validate_bounds(_bounds),
    do: builder_error("$.options.bounds", "must be a map of numeric bound tuples")

  defp validate_stable_id(value, path)
       when is_binary(value) and byte_size(value) <= @max_input_string_bytes do
    if String.valid?(value) and Regex.match?(@stable_id, value),
      do: {:ok, value},
      else: builder_error(path, "must be a stable identity")
  end

  defp validate_stable_id(_value, path), do: builder_error(path, "must be a stable identity")

  defp validate_bounded_integer(value, path, maximum) do
    if is_integer(value) and value >= 1 and value <= maximum,
      do: {:ok, value},
      else: builder_error(path, "must be an integer from 1 through #{maximum}")
  end

  defp validate_non_empty_string(value, path)
       when is_binary(value) and value != "" and byte_size(value) <= @max_input_string_bytes do
    if String.valid?(value),
      do: {:ok, value},
      else: builder_error(path, "must be a non-empty UTF-8 string")
  end

  defp validate_non_empty_string(_value, path),
    do: builder_error(path, "must be a non-empty UTF-8 string")

  defp capture_source_evidence(source_evidence) when is_map(source_evidence) do
    try do
      {:ok, JsonSafety.capture_json!(source_evidence, "source_evidence")}
    rescue
      error -> builder_error("$.source_evidence", safe_exception_message(error))
    catch
      _kind, _reason -> builder_error("$.source_evidence", "must be strict JSON")
    end
  end

  defp capture_source_evidence(_source_evidence),
    do: builder_error("$.source_evidence", "must be a strict JSON object")

  defp validate_neighborhood_inputs(seed_parameters, options) do
    seed_names = MapSet.new(Map.keys(seed_parameters))
    step_names = MapSet.new(Map.keys(options.steps))
    bound_names = MapSet.new(Map.keys(options.bounds))

    cond do
      map_size(options.steps) > @max_step_parameters ->
        builder_error(
          "$.options.steps",
          "may contain at most #{@max_step_parameters} step parameters"
        )

      Enum.any?(options.steps, fn {_name, step} -> step <= 0 end) ->
        builder_error("$.options.steps", "must contain only positive finite values")

      not MapSet.subset?(step_names, seed_names) ->
        builder_error("$.options.steps", "keys must identify seed parameters")

      not MapSet.subset?(bound_names, seed_names) ->
        builder_error("$.options.bounds", "keys must identify seed parameters")

      Enum.any?(options.bounds, fn {name, {minimum, maximum}} ->
        value = Map.fetch!(seed_parameters, name)
        value < minimum or value > maximum
      end) ->
        builder_error("$.options.bounds", "seed parameters must be within declared bounds")

      Enum.any?(options.steps, fn {name, step} ->
        value = Map.fetch!(seed_parameters, name)
        safe_finite_add(value, step) == :error or safe_finite_add(value, -step) == :error
      end) ->
        builder_error("$.options.steps", "finite neighborhood arithmetic must not overflow")

      true ->
        :ok
    end
  end

  defp valid_parameter_name?(name) when is_binary(name) do
    String.valid?(name) and Regex.match?(@score_term_name, name)
  end

  defp valid_parameter_name?(_name), do: false

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

  defp normalize_source_evidence(source_evidence, search_space) do
    candidate_ids = Enum.map(search_space["candidates"], & &1["id"])
    evidence_ids = Map.keys(source_evidence) |> Enum.sort()

    if evidence_ids == Enum.sort(candidate_ids) do
      candidate_ids
      |> Enum.reduce_while({:ok, %{}}, fn alternative_id, {:ok, evidence} ->
        entry = Map.fetch!(source_evidence, alternative_id)

        with :ok <- validate_source_entry(entry, alternative_id),
             {:ok, source_id} <-
               validate_stable_id(
                 entry["id"],
                 "$.source_evidence.#{alternative_id}.id"
               ),
             {:ok, revision} <-
               validate_stable_id(
                 entry["revision"],
                 "$.source_evidence.#{alternative_id}.revision"
               ) do
          row = %{
            entry: entry,
            summary: %{
              "alternative_id" => alternative_id,
              "source_id" => source_id,
              "source_revision" => revision,
              "content_identity" => content_identity(entry)
            }
          }

          {:cont, {:ok, Map.put(evidence, alternative_id, row)}}
        else
          {:error, failure} -> {:halt, {:error, failure}}
        end
      end)
    else
      builder_error(
        "$.source_evidence",
        "keys must exactly match every in-bounds search-space alternative ID"
      )
    end
  end

  defp validate_source_entry(entry, alternative_id) when is_map(entry) do
    if Map.has_key?(entry, "id") and Map.has_key?(entry, "revision"),
      do: :ok,
      else:
        builder_error(
          "$.source_evidence.#{alternative_id}",
          "must contain id and revision"
        )
  end

  defp validate_source_entry(_entry, alternative_id),
    do: builder_error("$.source_evidence.#{alternative_id}", "must be a strict JSON object")

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

  defp evaluate_candidates(candidates, evidence, source_registry, evaluator_fun, options) do
    candidates
    |> Enum.reduce_while({:ok, []}, fn candidate, {:ok, evaluations} ->
      case evaluate_candidate(candidate, evidence, source_registry, evaluator_fun, options) do
        {:ok, evaluation} -> {:cont, {:ok, [evaluation | evaluations]}}
        {:error, failure} -> {:halt, {:error, failure}}
      end
    end)
    |> case do
      {:ok, evaluations} -> {:ok, Enum.reverse(evaluations)}
      {:error, failure} -> {:error, failure}
    end
  end

  defp evaluate_candidate(candidate, evidence, source_registry, evaluator_fun, options) do
    evidence_row = Map.fetch!(evidence, candidate["id"])

    case invoke_evaluator(
           candidate["parameters"],
           evidence_row.entry,
           evaluator_fun,
           options.evaluator_timeout_ms
         ) do
      {:ok, result} ->
        normalize_evaluator_result(
          candidate,
          source_registry,
          result,
          options.evaluator_timeout_ms
        )

      {:error, details} ->
        {:error, evaluator_failure(candidate, options.evaluator_timeout_ms, details)}
    end
  end

  defp normalize_evaluator_result(candidate, source_registry, result, timeout_ms) do
    try do
      {:ok, build_evaluation(candidate, source_registry, result)}
    rescue
      error ->
        {:error,
         evaluator_failure(candidate, timeout_ms, %{
           "failure_kind" => "invalid_result",
           "detail" => safe_exception_message(error)
         })}
    catch
      kind, reason ->
        {:error,
         evaluator_failure(candidate, timeout_ms, %{
           "failure_kind" => "invalid_result_#{kind}",
           "detail" => safe_inspect(reason)
         })}
    end
  end

  defp build_evaluation(candidate, source_registry, result) do
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

    score = finite_sum!(Map.values(score_terms), "summed score_terms must produce a finite score")

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

  defp invoke_evaluator(parameters, source_evidence, evaluator_fun, timeout_ms) do
    caller = self()

    task =
      Task.Supervisor.async_nolink(@evaluator_supervisor, fn ->
        evaluator_worker(caller, parameters, source_evidence, evaluator_fun)
      end)

    await_evaluator_task(task, timeout_ms)
  rescue
    error ->
      {:error,
       %{
         "failure_kind" => "worker_start_error",
         "detail" => safe_exception_message(error)
       }}
  catch
    kind, reason ->
      {:error,
       %{
         "failure_kind" => "worker_start_#{kind}",
         "detail" => safe_inspect(reason)
       }}
  end

  defp evaluator_worker(caller, parameters, source_evidence, evaluator_fun) do
    worker = self()
    guard = spawn(fn -> evaluator_caller_guard(caller, worker) end)

    try do
      result = evaluator_fun.(parameters, source_evidence)
      {:ok, JsonSafety.capture_json!(result, "certified local-search evaluator result")}
    rescue
      error ->
        {:error,
         %{
           "failure_kind" => "error",
           "detail" => safe_exception_message(error)
         }}
    catch
      kind, reason ->
        {:error,
         %{
           "failure_kind" => Atom.to_string(kind),
           "detail" => safe_inspect(reason)
         }}
    after
      send(guard, {:worker_finished, worker})
    end
  end

  defp evaluator_caller_guard(caller, worker) do
    caller_ref = Process.monitor(caller)
    worker_ref = Process.monitor(worker)

    receive do
      {:worker_finished, ^worker} ->
        :ok

      {:DOWN, ^caller_ref, :process, ^caller, _reason} ->
        Process.exit(worker, :kill)
        await_worker_down(worker_ref, worker)

      {:DOWN, ^worker_ref, :process, ^worker, _reason} ->
        :ok
    end

    Process.demonitor(caller_ref, [:flush])
    Process.demonitor(worker_ref, [:flush])
  end

  defp await_worker_down(worker_ref, worker) do
    receive do
      {:DOWN, ^worker_ref, :process, ^worker, _reason} -> :ok
    after
      1_000 -> :ok
    end
  end

  defp await_evaluator_task(task, timeout_ms) do
    result =
      case Task.yield(task, timeout_ms) do
        {:ok, {:ok, captured}} ->
          {:ok, captured}

        {:ok, {:error, details}} ->
          {:error, details}

        {:exit, reason} ->
          {:error,
           %{
             "failure_kind" => "worker_exit",
             "detail" => safe_inspect(reason)
           }}

        nil ->
          Task.shutdown(task, :brutal_kill)

          {:error,
           %{
             "failure_kind" => "timeout",
             "timeout_ms" => timeout_ms,
             "detail" => "evaluator exceeded the bounded timeout"
           }}
      end

    cleanup_evaluator_task(task)
    result
  end

  defp cleanup_evaluator_task(%Task{ref: ref}) do
    Process.demonitor(ref, [:flush])
    drain_evaluator_task_messages(ref)
  end

  defp drain_evaluator_task_messages(ref) do
    receive do
      {^ref, _reply} -> drain_evaluator_task_messages(ref)
      {:DOWN, ^ref, :process, _pid, _reason} -> drain_evaluator_task_messages(ref)
    after
      0 -> :ok
    end
  end

  defp evaluator_failure(candidate, timeout_ms, details) do
    %{
      "status" => "rejected",
      "reason" => "evaluator_execution_failed",
      "alternative_id" => candidate["id"],
      "generation_index" => candidate["generation_index"],
      "evaluator_execution_policy" => evaluator_execution_policy(timeout_ms),
      "details" => details
    }
  end

  defp normalize_score_terms!(terms) when is_map(terms) do
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
      "certificate_id" => certificate_id_for_report(certificate),
      "details" => details
    }
  end

  defp certificate_id_for_report(%{"id" => id})
       when is_binary(id) and byte_size(id) <= 128 do
    if String.valid?(id) and Regex.match?(@certificate_id, id), do: id, else: :null
  end

  defp certificate_id_for_report(_certificate), do: :null

  defp safe_exception_message(error) do
    error
    |> Exception.message()
    |> truncate_detail()
  rescue
    _error -> "evaluator or replay raised an unreportable error"
  catch
    _kind, _reason -> "evaluator or replay raised an unreportable error"
  end

  defp safe_inspect(term) do
    term
    |> inspect(limit: 20, printable_limit: 512, width: 80)
    |> truncate_detail()
  rescue
    _error -> "unreportable caught value"
  catch
    _kind, _reason -> "unreportable caught value"
  end

  defp truncate_detail(detail) do
    detail = if String.valid?(detail), do: detail, else: inspect(detail)
    String.slice(detail, 0, 1_024)
  end

  defp deterministic_digest(value) do
    case JsonSafety.errors(value) do
      [] ->
        try do
          digest =
            value
            |> canonical_json_iodata()
            |> IO.iodata_to_binary()
            |> then(&:crypto.hash(:sha256, &1))
            |> Base.encode16(case: :lower)

          {:ok, digest}
        rescue
          _error -> {:error, identity_failure("identity_encoding_failed")}
        catch
          _kind, _reason -> {:error, identity_failure("identity_encoding_failed")}
        end

      issues ->
        {:error, identity_failure("identity_input_not_strict_json", issues)}
    end
  end

  defp canonical_json_iodata(:null), do: "null"
  defp canonical_json_iodata(nil), do: "null"

  defp canonical_json_iodata(value)
       when is_boolean(value) or is_binary(value) or is_number(value),
       do: :json.encode(value)

  defp canonical_json_iodata(values) when is_list(values) do
    encoded = values |> Enum.map(&canonical_json_iodata/1) |> Enum.intersperse(",")
    ["[", encoded, "]"]
  end

  defp canonical_json_iodata(%{} = map) do
    encoded =
      map
      |> Enum.sort_by(fn {key, _value} -> key end)
      |> Enum.map(fn {key, value} ->
        [:json.encode(key), ":", canonical_json_iodata(value)]
      end)
      |> Enum.intersperse(",")

    ["{", encoded, "}"]
  end

  defp finite_number?(value) when is_integer(value), do: true

  defp finite_number?(value) when is_float(value),
    do: value == value and value <= @max_float and value >= -@max_float

  defp finite_number?(_value), do: false

  defp finite_sum!(values, message) do
    case Enum.reduce_while(values, {:ok, 0}, fn value, {:ok, sum} ->
           case safe_finite_add(sum, value) do
             {:ok, next_sum} -> {:cont, {:ok, next_sum}}
             :error -> {:halt, :error}
           end
         end) do
      {:ok, sum} -> sum
      :error -> raise ArgumentError, message
    end
  end

  defp safe_finite_add(left, right) do
    sum = left + right
    if finite_number?(sum), do: {:ok, sum}, else: :error
  rescue
    ArithmeticError -> :error
  end

  defp builder_error(path, message) do
    {:error,
     %{
       "status" => "rejected",
       "reason" => "builder_input_invalid",
       "details" => %{
         "errors" => [
           %{
             "severity" => "error",
             "path" => path,
             "message" => message
           }
         ]
       }
     }}
  end

  defp input_failure(reason, failure_kind, detail) do
    %{
      "status" => "rejected",
      "reason" => reason,
      "details" => %{
        "failure_kind" => failure_kind,
        "detail" => detail
      }
    }
  end

  defp identity_failure(reason, issues \\ []) do
    %{
      "status" => "rejected",
      "reason" => reason,
      "details" => %{"errors" => issues}
    }
  end
end
