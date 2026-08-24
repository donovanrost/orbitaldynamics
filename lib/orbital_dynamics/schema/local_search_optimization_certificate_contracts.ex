defmodule OrbitalDynamics.Schema.LocalSearchOptimizationCertificateContracts do
  @moduledoc false

  alias OrbitalDynamics.Optimizer.LocalSearchCertificate
  alias OrbitalDynamics.Schema.{JsonSafety, PrimitiveValidation}
  alias OrbitalDynamics.Search.Local

  @contract "local_search_optimization_certificate.v1"
  @identity_algorithm "canonical_json_sha256.v1"
  @sha256 ~r/\A[0-9a-f]{64}\z/
  @stable_id ~r/\A[A-Za-z0-9][A-Za-z0-9._:@-]*\z/
  @score_term_name ~r/\A[A-Za-z][A-Za-z0-9_.-]*\z/
  @certificate_id ~r/\Alocal_search_optimization_certificate:[0-9a-f]{64}\z/
  @max_float 1.7976931348623157e308

  @root_fields OrbitalDynamics.Schema.OptimizationRegistryContracts.contracts()
               |> Map.fetch!(@contract)
               |> Map.fetch!("required_fields")

  @search_space_fields ~w(
    generator_model seed_id seed_parameters step_parameters steps bounds ordering
    candidate_count generation_attempt_count generation_rejected_count candidates
    generation_rejected_moves identity id_prefix
  )
  @bound_fields ~w(minimum maximum)
  @candidate_fields ~w(id generation_index parameters move)
  @registry_fields ~w(trust_boundary entry_count entries identity)
  @registry_entry_fields ~w(
    alternative_id source_id source_revision content_identity
  )
  @evaluation_fields ~w(
    alternative_id generation_index source_evidence_identity score_terms score eligible
    rejection_reasons incumbent_after_evaluation_id rank
  )
  @claim_fields ~w(
    status type scope selected_alternative_id reason global_optimality_claimed
  )
  @evaluator_policy_fields ~w(
    policy_version worker_model timeout_ms timeout_action caller_cancellation_action
  )
  @assumptions %{
    "score_rule" => "sum_of_score_terms",
    "evaluator" => "caller_supplied_pure_deterministic_supervised_unlinked_bounded_worker",
    "eligibility_timing" => "during_deterministic_enumeration_before_ranking",
    "source_evidence_trust_boundary" => LocalSearchCertificate.source_trust_boundary(),
    "external_solver" => false,
    "global_search" => false
  }

  def validate(issues, path, certificate) when is_list(issues) and is_map(certificate) do
    case JsonSafety.errors(certificate, path) do
      [] ->
        validate_json_safe(issues, path, certificate)

      json_issues ->
        validate_unencodable_certificate_identity(json_issues ++ issues, path, certificate)
    end
  rescue
    _error -> [error(path, "must be safely validatable as a local-search certificate") | issues]
  catch
    _kind, _reason ->
      [error(path, "must be safely validatable as a local-search certificate") | issues]
  end

  def validate(issues, path, _certificate),
    do: [error(path, "must be a map") | issues]

  defp validate_json_safe(issues, path, certificate) do
    issues =
      issues
      |> PrimitiveValidation.require_fields(path, certificate, @root_fields)
      |> exact_fields(path, certificate, @root_fields)
      |> expect_equal(path, certificate, "schema_contract", @contract)
      |> expect_equal(path, certificate, "model", LocalSearchCertificate.model())
      |> expect_non_empty_string(path, certificate, "id")
      |> expect_non_empty_string(path, certificate, "objective")
      |> expect_one_of(path, certificate, "objective_direction", ["maximize", "minimize"])
      |> expect_type(path, certificate, "evaluator_execution_policy", :map)
      |> expect_type(path, certificate, "claim", :map)
      |> expect_equal(path, certificate, "global_optimality_claimed", false)
      |> expect_type(path, certificate, "search_space", :map)
      |> expect_type(path, certificate, "source_evidence_registry", :map)
      |> expect_positive_bounded_integer(
        path,
        certificate,
        "evaluation_budget",
        LocalSearchCertificate.max_evaluations()
      )
      |> expect_non_negative_integer(path, certificate, "budget_used")
      |> expect_non_negative_integer(path, certificate, "budget_remaining")
      |> expect_type(path, certificate, "budget_limited", :boolean)
      |> expect_type(path, certificate, "search_space_exhausted", :boolean)
      |> expect_one_of(path, certificate, "termination_reason", [
        "search_space_exhausted",
        "evaluation_budget_exhausted"
      ])
      |> expect_non_negative_integer(path, certificate, "evaluated_count")
      |> expect_non_negative_integer(path, certificate, "eligible_count")
      |> expect_non_negative_integer(path, certificate, "rejected_count")
      |> expect_non_negative_integer(path, certificate, "unevaluated_count")
      |> expect_nullable_stable_id(path, certificate, "selected_alternative_id")
      |> expect_nullable_finite_number(path, certificate, "selected_score")
      |> expect_string_list(path, certificate, "eligible_ids_by_rank")
      |> expect_type(path, certificate, "evaluations", :list)
      |> expect_string_list(path, certificate, "deterministic_ordering")
      |> expect_non_empty_string(path, certificate, "incumbent_update_rule")
      |> expect_string_list(path, certificate, "model_limits")
      |> expect_equal(
        path,
        certificate,
        "model_limits",
        LocalSearchCertificate.model_limits()
      )
      |> expect_equal(path, certificate, "assumptions", @assumptions)

    validate_semantics(issues, path, certificate)
  end

  defp evaluation_structure_valid?(evaluation) do
    is_map(evaluation) and is_binary(evaluation["alternative_id"]) and
      is_integer(evaluation["generation_index"]) and
      is_map(evaluation["source_evidence_identity"]) and
      finite_numeric_map?(evaluation["score_terms"]) and
      finite_number?(evaluation["score"]) and is_boolean(evaluation["eligible"]) and
      proper_list?(evaluation["rejection_reasons"])
  end

  defp validate_semantics(issues, path, certificate) do
    issues
    |> validate_certificate_identity(path, certificate)
    |> validate_evaluator_execution_policy(path, certificate["evaluator_execution_policy"])
    |> validate_claim_shape(path, certificate["claim"])
    |> validate_search_space(path, certificate["search_space"])
    |> validate_registry(path, certificate)
    |> validate_evaluations(path, certificate)
    |> validate_termination_and_claim(path, certificate)
  end

  defp validate_certificate_identity(issues, path, certificate) do
    core = Map.delete(certificate, "id")

    case LocalSearchCertificate.certificate_id(core) do
      expected_id when is_binary(expected_id) ->
        issues
        |> ensure(
          is_binary(certificate["id"]) and Regex.match?(@certificate_id, certificate["id"]),
          "#{path}.id",
          "must exactly match local_search_optimization_certificate:<64 lowercase hex>"
        )
        |> ensure(
          certificate["id"] == expected_id,
          "#{path}.id",
          "must be the content identity of the complete certificate"
        )

      {:error, _failure} ->
        [
          error("#{path}.id", "cannot verify identity until certificate content is strict JSON")
          | issues
        ]
    end
  end

  defp validate_unencodable_certificate_identity(issues, path, certificate) do
    certificate_id = Map.get(certificate, "id")

    issues
    |> ensure(
      is_binary(certificate_id) and Regex.match?(@certificate_id, certificate_id),
      "#{path}.id",
      "must exactly match local_search_optimization_certificate:<64 lowercase hex>"
    )
    |> then(fn issues ->
      [
        error("#{path}.id", "cannot verify identity until certificate content is strict JSON")
        | issues
      ]
    end)
  end

  defp validate_evaluator_execution_policy(issues, path, policy) when is_map(policy) do
    policy_path = "#{path}.evaluator_execution_policy"
    timeout_ms = policy["timeout_ms"]

    issues =
      issues
      |> exact_fields(policy_path, policy, @evaluator_policy_fields)
      |> expect_positive_bounded_integer(
        policy_path,
        policy,
        "timeout_ms",
        LocalSearchCertificate.max_evaluator_timeout_ms()
      )

    if is_integer(timeout_ms) and timeout_ms >= 1 and
         timeout_ms <= LocalSearchCertificate.max_evaluator_timeout_ms() do
      ensure(
        issues,
        policy == LocalSearchCertificate.evaluator_execution_policy(timeout_ms),
        policy_path,
        "must exactly declare the supported evaluator worker and timeout lifecycle"
      )
    else
      issues
    end
  end

  defp validate_evaluator_execution_policy(issues, _path, _policy), do: issues

  defp validate_claim_shape(issues, path, claim) when is_map(claim) do
    claim_path = "#{path}.claim"

    issues
    |> exact_fields(claim_path, claim, @claim_fields)
    |> expect_one_of(claim_path, claim, "status", ["supported", "not_supported"])
    |> expect_one_of(claim_path, claim, "type", [
      "best_eligible_alternative_in_enumerated_finite_neighborhood",
      "no_eligible_alternative_in_enumerated_finite_neighborhood",
      "no_optimality_claim"
    ])
    |> expect_equal(claim_path, claim, "scope", "enumerated_search_space_only")
    |> expect_nullable_stable_id(claim_path, claim, "selected_alternative_id")
    |> expect_non_empty_string(claim_path, claim, "reason")
    |> expect_equal(claim_path, claim, "global_optimality_claimed", false)
  end

  defp validate_claim_shape(issues, _path, _claim), do: issues

  defp validate_search_space(issues, path, search_space) when is_map(search_space) do
    search_path = "#{path}.search_space"

    issues =
      issues
      |> exact_fields(search_path, search_space, @search_space_fields)
      |> expect_non_empty_string(search_path, search_space, "generator_model")
      |> expect_stable_id(search_path, search_space, "seed_id")
      |> expect_finite_numeric_map(search_path, search_space, "seed_parameters")
      |> expect_string_list(search_path, search_space, "step_parameters")
      |> expect_finite_numeric_map(search_path, search_space, "steps")
      |> expect_type(search_path, search_space, "bounds", :map)
      |> expect_non_empty_string(search_path, search_space, "ordering")
      |> expect_stable_id(search_path, search_space, "id_prefix")
      |> expect_non_negative_integer(search_path, search_space, "candidate_count")
      |> expect_non_negative_integer(search_path, search_space, "generation_attempt_count")
      |> expect_non_negative_integer(search_path, search_space, "generation_rejected_count")
      |> expect_type(search_path, search_space, "candidates", :list)
      |> expect_type(search_path, search_space, "generation_rejected_moves", :list)
      |> validate_identity("#{search_path}.identity", search_space["identity"])
      |> validate_bounds("#{search_path}.bounds", search_space["bounds"])
      |> validate_candidate_rows("#{search_path}.candidates", search_space["candidates"])
      |> validate_map_rows(
        "#{search_path}.generation_rejected_moves",
        search_space["generation_rejected_moves"]
      )

    if search_space_structure_valid?(search_space) do
      expected = regenerate_search_space(search_space)

      ensure(
        issues,
        search_space == expected,
        search_path,
        "must exactly match the declared deterministic local-neighborhood generation"
      )
    else
      issues
    end
  rescue
    _error ->
      [
        error(
          "#{path}.search_space",
          "must be a valid reproducible deterministic local-neighborhood description"
        )
        | issues
      ]
  end

  defp validate_search_space(issues, _path, _search_space), do: issues

  defp validate_bounds(issues, path, bounds) when is_map(bounds) do
    Enum.reduce(bounds, issues, fn {name, bound}, acc ->
      bound_path = "#{path}.#{name}"

      if is_map(bound) do
        acc
        |> exact_fields(bound_path, bound, @bound_fields)
        |> expect_finite_number(bound_path, bound, "minimum")
        |> expect_finite_number(bound_path, bound, "maximum")
        |> ensure(
          finite_number?(bound["minimum"]) and finite_number?(bound["maximum"]) and
            bound["minimum"] <= bound["maximum"],
          bound_path,
          "minimum must be less than or equal to maximum"
        )
      else
        [error(bound_path, "must be a map") | acc]
      end
    end)
  end

  defp validate_bounds(issues, _path, _bounds), do: issues

  defp validate_candidate_rows(issues, path, candidates) do
    if proper_list?(candidates) do
      candidates
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {candidate, index}, acc ->
        validate_candidate_row(acc, "#{path}[#{index}]", candidate)
      end)
    else
      issues
    end
  end

  defp validate_candidate_row(issues, path, candidate) when is_map(candidate) do
    issues
    |> exact_fields(path, candidate, @candidate_fields)
    |> expect_stable_id(path, candidate, "id")
    |> expect_non_negative_integer(path, candidate, "generation_index")
    |> expect_finite_numeric_map(path, candidate, "parameters")
    |> expect_type(path, candidate, "move", :map)
  end

  defp validate_candidate_row(issues, path, _candidate),
    do: [error(path, "must be a map") | issues]

  defp validate_map_rows(issues, path, rows) do
    if proper_list?(rows) do
      rows
      |> Enum.with_index()
      |> Enum.reduce(issues, fn
        {row, _index}, acc when is_map(row) -> acc
        {_row, index}, acc -> [error("#{path}[#{index}]", "must be a map") | acc]
      end)
    else
      issues
    end
  end

  defp search_space_structure_valid?(search_space) do
    is_map(search_space) and finite_score_terms_map?(search_space["seed_parameters"]) and
      proper_list?(search_space["step_parameters"]) and
      Enum.all?(search_space["step_parameters"], &is_binary/1) and
      finite_score_terms_map?(search_space["steps"]) and valid_bounds?(search_space["bounds"]) and
      proper_list?(search_space["candidates"]) and
      Enum.all?(search_space["candidates"], &is_map/1) and
      proper_list?(search_space["generation_rejected_moves"]) and
      Enum.all?(search_space["generation_rejected_moves"], &is_map/1) and
      stable_id?(search_space["id_prefix"])
  end

  defp valid_bounds?(bounds) when is_map(bounds) do
    Enum.all?(bounds, fn
      {_name, %{"minimum" => minimum, "maximum" => maximum} = bound} ->
        map_size(bound) == 2 and finite_number?(minimum) and finite_number?(maximum) and
          minimum <= maximum

      _entry ->
        false
    end)
  end

  defp valid_bounds?(_bounds), do: false

  defp regenerate_search_space(search_space) do
    bounds =
      Map.new(search_space["bounds"], fn {name, bound} ->
        {name, {Map.fetch!(bound, "minimum"), Map.fetch!(bound, "maximum")}}
      end)

    neighborhood =
      Local.neighborhood(
        search_space["seed_parameters"],
        steps: search_space["steps"],
        bounds: bounds,
        id_prefix: search_space["id_prefix"],
        max_alternatives: LocalSearchCertificate.max_evaluations()
      )

    core = %{
      "generator_model" => neighborhood["model"],
      "seed_id" => neighborhood["seed_id"],
      "seed_parameters" => neighborhood["seed_parameters"],
      "step_parameters" => neighborhood["step_parameters"],
      "steps" => neighborhood["steps"],
      "bounds" => neighborhood["bounds"],
      "ordering" => neighborhood["ordering"],
      "candidate_count" => neighborhood["alternative_count"],
      "generation_attempt_count" => neighborhood["generated_move_count"],
      "generation_rejected_count" => neighborhood["rejected_move_count"],
      "candidates" => neighborhood["alternatives"],
      "generation_rejected_moves" => neighborhood["rejected_moves"],
      "id_prefix" => search_space["id_prefix"]
    }

    Map.put(core, "identity", LocalSearchCertificate.search_space_identity(core))
  end

  defp validate_registry(
         issues,
         path,
         %{"source_evidence_registry" => registry} = certificate
       )
       when is_map(registry) do
    registry_path = "#{path}.source_evidence_registry"

    issues =
      issues
      |> exact_fields(registry_path, registry, @registry_fields)
      |> expect_equal(
        registry_path,
        registry,
        "trust_boundary",
        LocalSearchCertificate.source_trust_boundary()
      )
      |> expect_non_negative_integer(registry_path, registry, "entry_count")
      |> expect_type(registry_path, registry, "entries", :list)
      |> validate_identity("#{registry_path}.identity", registry["identity"])

    issues = validate_registry_entries(issues, registry_path, registry["entries"])

    issues =
      if proper_list?(registry["entries"]) do
        ensure(
          issues,
          registry["entry_count"] == length(registry["entries"]),
          "#{registry_path}.entry_count",
          "must equal entries count"
        )
      else
        issues
      end

    core = Map.delete(registry, "identity")

    issues =
      ensure(
        issues,
        registry["identity"] == LocalSearchCertificate.source_registry_identity(core),
        "#{registry_path}.identity",
        "must be the content identity of the source-evidence registry summary"
      )

    if registry_relations_valid?(certificate) do
      entries = registry["entries"]
      candidate_ids = Enum.map(certificate["search_space"]["candidates"], & &1["id"])
      entry_ids = Enum.map(entries, & &1["alternative_id"])

      ensure(
        issues,
        entry_ids == candidate_ids,
        "#{registry_path}.entries",
        "must contain exactly one entry for every candidate in generation order"
      )
    else
      issues
    end
  end

  defp validate_registry(issues, _path, _certificate), do: issues

  defp validate_registry_entries(issues, path, entries) do
    if proper_list?(entries) do
      entries
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {entry, index}, acc ->
        validate_registry_entry(acc, "#{path}.entries[#{index}]", entry)
      end)
    else
      issues
    end
  end

  defp validate_registry_entry(issues, path, entry) when is_map(entry) do
    issues
    |> exact_fields(path, entry, @registry_entry_fields)
    |> expect_stable_id(path, entry, "alternative_id")
    |> expect_stable_id(path, entry, "source_id")
    |> expect_stable_id(path, entry, "source_revision")
    |> validate_identity("#{path}.content_identity", entry["content_identity"])
  end

  defp validate_registry_entry(issues, path, _entry),
    do: [error(path, "must be a map") | issues]

  defp registry_relations_valid?(certificate) do
    registry = certificate["source_evidence_registry"]
    search_space = certificate["search_space"]

    is_map(registry) and proper_map_list?(registry["entries"]) and
      is_map(search_space) and proper_map_list?(search_space["candidates"])
  end

  defp validate_evaluations(issues, path, certificate) do
    evaluation_path = "#{path}.evaluations"
    evaluations = certificate["evaluations"]

    issues =
      if proper_list?(evaluations) do
        evaluations
        |> Enum.with_index()
        |> Enum.reduce(issues, fn {evaluation, index}, acc ->
          validate_evaluation(acc, "#{evaluation_path}[#{index}]", evaluation)
        end)
      else
        issues
      end

    if evaluation_relations_valid?(certificate),
      do: validate_evaluation_relations(issues, path, certificate),
      else: issues
  end

  defp validate_evaluation(issues, path, evaluation) when is_map(evaluation) do
    issues
    |> exact_fields(path, evaluation, @evaluation_fields)
    |> expect_stable_id(path, evaluation, "alternative_id")
    |> expect_non_negative_integer(path, evaluation, "generation_index")
    |> validate_identity(
      "#{path}.source_evidence_identity",
      evaluation["source_evidence_identity"]
    )
    |> expect_finite_score_terms_map(path, evaluation, "score_terms")
    |> expect_finite_number(path, evaluation, "score")
    |> expect_type(path, evaluation, "eligible", :boolean)
    |> expect_string_list(path, evaluation, "rejection_reasons")
    |> expect_nullable_stable_id(path, evaluation, "incumbent_after_evaluation_id")
    |> expect_nullable_positive_integer(path, evaluation, "rank")
    |> validate_evaluation_row(path, evaluation)
  end

  defp validate_evaluation(issues, path, _evaluation),
    do: [error(path, "must be a map") | issues]

  defp evaluation_relations_valid?(certificate) do
    evaluations = certificate["evaluations"]
    search_space = certificate["search_space"]
    registry = certificate["source_evidence_registry"]

    proper_list?(evaluations) and Enum.all?(evaluations, &evaluation_structure_valid?/1) and
      is_map(search_space) and proper_list?(search_space["candidates"]) and
      Enum.all?(search_space["candidates"], &candidate_relation_structure_valid?/1) and
      is_map(registry) and proper_list?(registry["entries"]) and
      Enum.all?(registry["entries"], &registry_entry_relation_structure_valid?/1) and
      certificate["objective_direction"] in ["maximize", "minimize"]
  end

  defp candidate_relation_structure_valid?(candidate) do
    is_map(candidate) and is_binary(candidate["id"]) and
      is_integer(candidate["generation_index"])
  end

  defp registry_entry_relation_structure_valid?(entry) do
    is_map(entry) and is_binary(entry["alternative_id"]) and
      is_map(entry["content_identity"])
  end

  defp proper_map_list?(value),
    do: proper_list?(value) and Enum.all?(value, &is_map/1)

  defp validate_evaluation_row(issues, path, evaluation) do
    terms = evaluation["score_terms"]
    reasons = evaluation["rejection_reasons"]

    issues =
      if finite_score_terms_map?(terms) do
        case safe_finite_sum(Map.values(terms)) do
          {:ok, score} ->
            ensure(
              issues,
              score == evaluation["score"],
              "#{path}.score",
              "must equal the finite sum of score_terms"
            )

          :error ->
            ensure(
              issues,
              false,
              "#{path}.score",
              "score_terms sum must remain finite"
            )
        end
      else
        issues
      end

    if proper_list?(reasons) do
      issues
      |> ensure(
        reasons == reasons |> Enum.uniq() |> Enum.sort(),
        "#{path}.rejection_reasons",
        "must be unique and sorted"
      )
      |> ensure(
        (evaluation["eligible"] == true and reasons == []) or
          (evaluation["eligible"] == false and reasons != []),
        "#{path}.rejection_reasons",
        "must be empty only for eligible candidates and non-empty for rejected candidates"
      )
    else
      issues
    end
  end

  defp validate_evaluation_relations(issues, path, certificate) do
    evaluations = certificate["evaluations"]
    candidates = certificate["search_space"]["candidates"]
    registry_entries = certificate["source_evidence_registry"]["entries"]
    direction = certificate["objective_direction"]
    expected_candidates = Enum.take(candidates, length(evaluations))

    expected_evaluation_pairs =
      Enum.map(expected_candidates, &{&1["id"], &1["generation_index"]})

    actual_evaluation_pairs =
      Enum.map(evaluations, &{&1["alternative_id"], &1["generation_index"]})

    registry_identity_by_id =
      Map.new(registry_entries, &{&1["alternative_id"], &1["content_identity"]})

    source_identities_match =
      Enum.all?(evaluations, fn evaluation ->
        evaluation["source_evidence_identity"] ==
          registry_identity_by_id[evaluation["alternative_id"]]
      end)

    ranked = expected_ranked(evaluations, direction)
    eligible_rank_by_id = Map.new(ranked, &{&1["alternative_id"], &1["rank"]})

    rank_by_id =
      Map.new(evaluations, fn evaluation ->
        {evaluation["alternative_id"],
         Map.get(eligible_rank_by_id, evaluation["alternative_id"], :null)}
      end)

    actual_ranks = Map.new(evaluations, &{&1["alternative_id"], &1["rank"]})
    expected_history = expected_incumbent_history(evaluations, direction)
    actual_history = Enum.map(evaluations, & &1["incumbent_after_evaluation_id"])

    issues
    |> ensure(
      actual_evaluation_pairs == expected_evaluation_pairs,
      "#{path}.evaluations",
      "must be the generation-order prefix of the exact search space"
    )
    |> ensure(
      source_identities_match,
      "#{path}.evaluations",
      "must retain the matching source-evidence content identity"
    )
    |> ensure(
      actual_ranks == rank_by_id,
      "#{path}.evaluations",
      "ranks must follow eligible score and declared tie-break ordering"
    )
    |> ensure(
      actual_history == expected_history,
      "#{path}.evaluations",
      "incumbent history must follow deterministic evaluation and replacement ordering"
    )
    |> ensure(
      certificate["eligible_ids_by_rank"] == Enum.map(ranked, & &1["alternative_id"]),
      "#{path}.eligible_ids_by_rank",
      "must equal eligible evaluation IDs in rank order"
    )
  end

  defp validate_termination_and_claim(issues, path, certificate) do
    if termination_relations_valid?(certificate),
      do: do_validate_termination_and_claim(issues, path, certificate),
      else: issues
  end

  defp termination_relations_valid?(certificate) do
    search_space = certificate["search_space"]

    evaluation_relations_valid?(certificate) and is_map(search_space) and
      is_integer(search_space["candidate_count"]) and
      is_integer(certificate["evaluation_budget"])
  end

  defp do_validate_termination_and_claim(issues, path, certificate) do
    evaluations = certificate["evaluations"]
    evaluated_count = length(evaluations)
    eligible_count = Enum.count(evaluations, &(&1["eligible"] == true))
    rejected_count = evaluated_count - eligible_count
    candidate_count = certificate["search_space"]["candidate_count"]
    budget = certificate["evaluation_budget"]
    exhausted = evaluated_count == candidate_count
    budget_limited = evaluated_count < candidate_count
    ranked = expected_ranked(evaluations, certificate["objective_direction"])
    selected = List.first(ranked)
    expected_selected_id = if(selected, do: selected["alternative_id"], else: nil)
    expected_selected_score = if(selected, do: selected["score"], else: nil)
    expected_claim = expected_claim(exhausted, selected)
    expected_ordering = expected_ordering(certificate["objective_direction"])

    issues
    |> ensure(
      evaluated_count <= budget,
      "#{path}.evaluated_count",
      "must not exceed evaluation_budget"
    )
    |> ensure(
      certificate["budget_used"] == evaluated_count and
        certificate["evaluated_count"] == evaluated_count,
      "#{path}.budget_used",
      "budget_used and evaluated_count must equal evaluations count"
    )
    |> ensure(
      is_integer(budget) and certificate["budget_remaining"] == budget - evaluated_count,
      "#{path}.budget_remaining",
      "must equal evaluation_budget minus evaluated_count"
    )
    |> ensure(
      certificate["eligible_count"] == eligible_count,
      "#{path}.eligible_count",
      "must equal eligible evaluation count"
    )
    |> ensure(
      certificate["rejected_count"] == rejected_count,
      "#{path}.rejected_count",
      "must equal rejected evaluation count"
    )
    |> ensure(
      certificate["unevaluated_count"] == candidate_count - evaluated_count,
      "#{path}.unevaluated_count",
      "must equal candidate_count minus evaluated_count"
    )
    |> ensure(
      certificate["search_space_exhausted"] == exhausted,
      "#{path}.search_space_exhausted",
      "must reflect complete candidate evaluation"
    )
    |> ensure(
      certificate["budget_limited"] == budget_limited,
      "#{path}.budget_limited",
      "must reflect whether the budget stopped enumeration"
    )
    |> ensure(
      certificate["termination_reason"] ==
        if(exhausted, do: "search_space_exhausted", else: "evaluation_budget_exhausted"),
      "#{path}.termination_reason",
      "must match exhaustion state"
    )
    |> ensure(
      nullable_equal?(certificate["selected_alternative_id"], expected_selected_id),
      "#{path}.selected_alternative_id",
      "must equal the best evaluated eligible alternative"
    )
    |> ensure(
      nullable_equal?(certificate["selected_score"], expected_selected_score),
      "#{path}.selected_score",
      "must equal the selected alternative score"
    )
    |> validate_claim(path, certificate["claim"], expected_claim)
    |> ensure(
      certificate["deterministic_ordering"] == expected_ordering,
      "#{path}.deterministic_ordering",
      "must exactly declare evaluation, ranking, and tie-break ordering"
    )
    |> ensure(
      certificate["incumbent_update_rule"] ==
        expected_incumbent_update_rule(certificate["objective_direction"]),
      "#{path}.incumbent_update_rule",
      "must exactly declare incumbent replacement ordering"
    )
  end

  defp validate_claim(issues, path, claim, expected) when is_map(claim) do
    issues
    |> exact_fields("#{path}.claim", claim, @claim_fields)
    |> ensure(claim == expected, "#{path}.claim", "must match exhaustion and selected incumbent")
  end

  defp validate_claim(issues, _path, _claim, _expected), do: issues

  defp expected_ranked(evaluations, "maximize") do
    evaluations
    |> Enum.filter(&(&1["eligible"] == true))
    |> Enum.sort_by(&{-&1["score"], &1["generation_index"], &1["alternative_id"]})
    |> Enum.with_index(1)
    |> Enum.map(fn {row, rank} -> Map.put(row, "rank", rank) end)
  end

  defp expected_ranked(evaluations, "minimize") do
    evaluations
    |> Enum.filter(&(&1["eligible"] == true))
    |> Enum.sort_by(&{&1["score"], &1["generation_index"], &1["alternative_id"]})
    |> Enum.with_index(1)
    |> Enum.map(fn {row, rank} -> Map.put(row, "rank", rank) end)
  end

  defp expected_incumbent_history(evaluations, direction) do
    {history, _incumbent} =
      Enum.map_reduce(evaluations, nil, fn evaluation, incumbent ->
        incumbent = expected_incumbent(evaluation, incumbent, direction)
        {if(incumbent, do: incumbent["alternative_id"], else: :null), incumbent}
      end)

    history
  end

  defp expected_incumbent(%{"eligible" => false}, incumbent, _direction), do: incumbent
  defp expected_incumbent(evaluation, nil, _direction), do: evaluation

  defp expected_incumbent(evaluation, incumbent, "maximize") do
    if {-evaluation["score"], evaluation["generation_index"], evaluation["alternative_id"]} <
         {-incumbent["score"], incumbent["generation_index"], incumbent["alternative_id"]},
       do: evaluation,
       else: incumbent
  end

  defp expected_incumbent(evaluation, incumbent, "minimize") do
    if {evaluation["score"], evaluation["generation_index"], evaluation["alternative_id"]} <
         {incumbent["score"], incumbent["generation_index"], incumbent["alternative_id"]},
       do: evaluation,
       else: incumbent
  end

  defp expected_claim(false, _selected) do
    %{
      "status" => "not_supported",
      "type" => "no_optimality_claim",
      "scope" => "enumerated_search_space_only",
      "selected_alternative_id" => :null,
      "reason" => "evaluation_budget_exhausted_before_search_space",
      "global_optimality_claimed" => false
    }
  end

  defp expected_claim(true, nil) do
    %{
      "status" => "supported",
      "type" => "no_eligible_alternative_in_enumerated_finite_neighborhood",
      "scope" => "enumerated_search_space_only",
      "selected_alternative_id" => :null,
      "reason" => "every_candidate_was_evaluated_and_rejected",
      "global_optimality_claimed" => false
    }
  end

  defp expected_claim(true, selected) do
    %{
      "status" => "supported",
      "type" => "best_eligible_alternative_in_enumerated_finite_neighborhood",
      "scope" => "enumerated_search_space_only",
      "selected_alternative_id" => selected["alternative_id"],
      "reason" => "search_space_exhausted_and_incumbent_ordering_applied",
      "global_optimality_claimed" => false
    }
  end

  defp expected_ordering("maximize") do
    [
      "candidate generation: seed then parameter ascending then decrease then increase",
      "evaluation: candidate generation order",
      "ranking: eligible alternatives only",
      "ranking: objective score descending",
      "tie break: generation_index ascending",
      "tie break: alternative id ascending"
    ]
  end

  defp expected_ordering("minimize") do
    [
      "candidate generation: seed then parameter ascending then decrease then increase",
      "evaluation: candidate generation order",
      "ranking: eligible alternatives only",
      "ranking: objective score ascending",
      "tie break: generation_index ascending",
      "tie break: alternative id ascending"
    ]
  end

  defp expected_incumbent_update_rule("maximize"),
    do:
      "replace incumbent only for eligible higher score, then lower generation_index, then lower alternative id"

  defp expected_incumbent_update_rule("minimize"),
    do:
      "replace incumbent only for eligible lower score, then lower generation_index, then lower alternative id"

  defp validate_identity(
         issues,
         path,
         %{
           "algorithm" => @identity_algorithm,
           "sha256" => digest
         } = identity
       )
       when map_size(identity) == 2 and is_binary(digest) do
    ensure(
      issues,
      Regex.match?(@sha256, digest),
      "#{path}.sha256",
      "must be lowercase hexadecimal SHA-256"
    )
  end

  defp validate_identity(issues, path, _identity),
    do: [error(path, "must declare the supported content identity") | issues]

  defp exact_fields(issues, path, map, expected) when is_map(map) do
    ensure(
      issues,
      Enum.sort(Map.keys(map)) == Enum.sort(expected),
      path,
      "must contain exactly the registered fields"
    )
  end

  defp expect_equal(issues, path, map, field, expected) do
    ensure(issues, map[field] == expected, "#{path}.#{field}", "must equal #{inspect(expected)}")
  end

  defp expect_one_of(issues, path, map, field, allowed) do
    ensure(
      issues,
      map[field] in allowed,
      "#{path}.#{field}",
      "must be one of #{inspect(allowed)}"
    )
  end

  defp expect_type(issues, path, map, field, type) do
    ensure(issues, type?(map[field], type), "#{path}.#{field}", "must be a #{type}")
  end

  defp expect_non_empty_string(issues, path, map, field) do
    ensure(
      issues,
      is_binary(map[field]) and map[field] != "" and String.valid?(map[field]),
      "#{path}.#{field}",
      "must be a non-empty UTF-8 string"
    )
  end

  defp expect_stable_id(issues, path, map, field) do
    ensure(issues, stable_id?(map[field]), "#{path}.#{field}", "must be a stable identity")
  end

  defp expect_nullable_stable_id(issues, path, map, field) do
    ensure(
      issues,
      map[field] in [nil, :null] or stable_id?(map[field]),
      "#{path}.#{field}",
      "must be a stable identity or null"
    )
  end

  defp expect_non_negative_integer(issues, path, map, field) do
    ensure(
      issues,
      is_integer(map[field]) and map[field] >= 0,
      "#{path}.#{field}",
      "must be a non-negative integer"
    )
  end

  defp expect_positive_bounded_integer(issues, path, map, field, maximum) do
    ensure(
      issues,
      is_integer(map[field]) and map[field] >= 1 and map[field] <= maximum,
      "#{path}.#{field}",
      "must be an integer from 1 through #{maximum}"
    )
  end

  defp expect_nullable_positive_integer(issues, path, map, field) do
    ensure(
      issues,
      map[field] in [nil, :null] or (is_integer(map[field]) and map[field] >= 1),
      "#{path}.#{field}",
      "must be a positive integer or null"
    )
  end

  defp expect_finite_number(issues, path, map, field) do
    ensure(issues, finite_number?(map[field]), "#{path}.#{field}", "must be a finite number")
  end

  defp expect_nullable_finite_number(issues, path, map, field) do
    ensure(
      issues,
      map[field] in [nil, :null] or finite_number?(map[field]),
      "#{path}.#{field}",
      "must be a finite number or null"
    )
  end

  defp expect_string_list(issues, path, map, field) do
    ensure(
      issues,
      proper_list?(map[field]) and Enum.all?(map[field], &is_binary/1),
      "#{path}.#{field}",
      "must be a proper list of strings"
    )
  end

  defp expect_finite_numeric_map(issues, path, map, field) do
    ensure(
      issues,
      finite_numeric_map?(map[field]),
      "#{path}.#{field}",
      "must be a non-empty finite numeric map with supported parameter names"
    )
  end

  defp expect_finite_score_terms_map(issues, path, map, field) do
    ensure(
      issues,
      finite_score_terms_map?(map[field]),
      "#{path}.#{field}",
      "must be a non-empty finite numeric map with supported score-term names"
    )
  end

  defp finite_numeric_map?(map) when is_map(map) and map_size(map) > 0 do
    Enum.all?(map, fn {key, value} ->
      is_binary(key) and Regex.match?(@score_term_name, key) and finite_number?(value)
    end)
  end

  defp finite_numeric_map?(_map), do: false

  defp finite_score_terms_map?(map), do: finite_numeric_map?(map)

  defp finite_number?(value) when is_integer(value), do: true

  defp finite_number?(value) when is_float(value),
    do: value == value and value <= @max_float and value >= -@max_float

  defp finite_number?(_value), do: false

  defp safe_finite_sum(values) do
    Enum.reduce_while(values, {:ok, 0}, fn value, {:ok, sum} ->
      case safe_finite_add(sum, value) do
        {:ok, next_sum} -> {:cont, {:ok, next_sum}}
        :error -> {:halt, :error}
      end
    end)
  end

  defp safe_finite_add(left, right) do
    sum = left + right
    if finite_number?(sum), do: {:ok, sum}, else: :error
  rescue
    ArithmeticError -> :error
  end

  defp stable_id?(value) when is_binary(value), do: Regex.match?(@stable_id, value)
  defp stable_id?(_value), do: false

  defp nullable_equal?(actual, nil), do: actual in [nil, :null]
  defp nullable_equal?(actual, expected), do: actual == expected

  defp type?(value, :map), do: is_map(value)
  defp type?(value, :list), do: proper_list?(value)
  defp type?(value, :boolean), do: is_boolean(value)

  defp proper_list?([]), do: true
  defp proper_list?([_head | tail]), do: proper_list?(tail)
  defp proper_list?(_value), do: false

  defp ensure(issues, true, _path, _message), do: issues
  defp ensure(issues, false, path, message), do: [error(path, message) | issues]

  defp error(path, message), do: PrimitiveValidation.error(path, message)
end
