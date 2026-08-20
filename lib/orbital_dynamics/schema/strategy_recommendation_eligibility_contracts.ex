defmodule OrbitalDynamics.Schema.StrategyRecommendationEligibilityContracts do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.StrategyRecommendationEligibility
  alias OrbitalDynamics.Optimizer.{HardFeasibility, SourceEvidenceRegistry}
  alias OrbitalDynamics.Schema.StableIdValidation

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_non_negative_integer: 4,
      expect_one_of: 5,
      expect_type: 5,
      require_fields: 4,
      validate_string_list_items: 4
    ]

  @required_fields ~w(
    schema_contract mode status selected_branch_id eligible_ranked_branch_ids
    branch_count eligible_count rejected_count source_evidence_registry evaluations
    counterfactual deterministic_ordering model_limits
  )
  @evaluation_fields ~w(
    branch_id score branch_score_term_identity status eligible hard_feasibility
    policy_blocker blocker_reasons
  )
  @statuses ~w(eligible infeasible policy_blocked infeasible_and_policy_blocked)

  def validate(issues, artifact) do
    case Map.get(artifact, "recommendation_eligibility") do
      nil ->
        issues

      %{} = eligibility ->
        validate_hard(issues, artifact, eligibility)

      _eligibility ->
        [error("$.recommendation_eligibility", "must be an object") | issues]
    end
  end

  def json_schema(stable_id_pattern) do
    nullable_id = %{"type" => ["string", "null"], "pattern" => stable_id_pattern}

    %{
      "type" => "object",
      "additionalProperties" => false,
      "required" => @required_fields,
      "properties" => %{
        "schema_contract" => %{
          "type" => "string",
          "const" => "strategy_recommendation_eligibility.v1"
        },
        "mode" => %{"type" => "string", "const" => "hard"},
        "status" => %{
          "type" => "string",
          "enum" => ["recommendable", "no_recommendable_branch"]
        },
        "selected_branch_id" => nullable_id,
        "eligible_ranked_branch_ids" => %{
          "type" => "array",
          "items" => %{"type" => "string", "pattern" => stable_id_pattern}
        },
        "branch_count" => count_schema(),
        "eligible_count" => count_schema(),
        "rejected_count" => count_schema(),
        "source_evidence_registry" => %{"type" => "object"},
        "evaluations" => %{
          "type" => "array",
          "items" => evaluation_json_schema(stable_id_pattern)
        },
        "counterfactual" => %{
          "oneOf" => [
            %{"type" => "null"},
            evaluation_json_schema(stable_id_pattern, counterfactual?: true)
          ]
        },
        "deterministic_ordering" => %{
          "type" => "string",
          "const" => "eligible score descending then branch_id ascending"
        },
        "model_limits" => %{"type" => "array", "items" => %{"type" => "string"}}
      }
    }
  end

  def counterfactual_json_schema(stable_id_pattern) do
    evaluation_json_schema(stable_id_pattern, counterfactual?: true)
  end

  def evaluation_json_schema(stable_id_pattern) do
    evaluation_json_schema(stable_id_pattern, [])
  end

  defp validate_hard(issues, artifact, eligibility) do
    branches = proper_map_list(Map.get(artifact, "branches"))
    evaluations = proper_map_list(Map.get(eligibility, "evaluations"))

    issues =
      issues
      |> require_fields("$.recommendation_eligibility", eligibility, @required_fields)
      |> expect_equal(
        "$.recommendation_eligibility",
        eligibility,
        "schema_contract",
        "strategy_recommendation_eligibility.v1"
      )
      |> expect_equal("$.recommendation_eligibility", eligibility, "mode", "hard")
      |> expect_one_of("$.recommendation_eligibility", eligibility, "status", [
        "recommendable",
        "no_recommendable_branch"
      ])
      |> expect_type(
        "$.recommendation_eligibility",
        eligibility,
        "eligible_ranked_branch_ids",
        :list
      )
      |> then(fn acc ->
        StableIdValidation.validate_stable_id_list(
          acc,
          "$.recommendation_eligibility.eligible_ranked_branch_ids",
          eligibility["eligible_ranked_branch_ids"]
        )
      end)
      |> expect_type(
        "$.recommendation_eligibility",
        eligibility,
        "source_evidence_registry",
        :map
      )
      |> expect_type("$.recommendation_eligibility", eligibility, "evaluations", :list)
      |> ensure(
        is_list(evaluations),
        "$.recommendation_eligibility.evaluations",
        "must contain only objects"
      )
      |> ensure(
        is_list(branches),
        "$.branches",
        "must contain only objects when hard recommendation eligibility is enabled"
      )
      |> expect_type("$.recommendation_eligibility", eligibility, "model_limits", :list)
      |> validate_string_list_items(
        "$.recommendation_eligibility",
        eligibility,
        "model_limits"
      )
      |> ensure(
        eligibility["model_limits"] == StrategyRecommendationEligibility.model_limits(),
        "$.recommendation_eligibility.model_limits",
        "must retain exact hard recommendation eligibility limits"
      )
      |> expect_non_negative_integer("$.recommendation_eligibility", eligibility, "branch_count")
      |> expect_non_negative_integer(
        "$.recommendation_eligibility",
        eligibility,
        "eligible_count"
      )
      |> expect_non_negative_integer(
        "$.recommendation_eligibility",
        eligibility,
        "rejected_count"
      )
      |> expect_equal(
        "$.recommendation_eligibility",
        eligibility,
        "deterministic_ordering",
        "eligible score descending then branch_id ascending"
      )
      |> validate_registry_summary(eligibility)
      |> validate_counterfactual_type(eligibility)
      |> validate_selected_id(eligibility)
      |> validate_evaluations(branches, evaluations, eligibility)

    validate_artifact_bindings(issues, artifact, eligibility, evaluations)
  end

  defp validate_evaluations(issues, branches, evaluations, eligibility) do
    if is_list(branches) and is_list(evaluations) do
      expected_branch_ids = Enum.map(branches, & &1["branch_id"])
      evaluation_branch_ids = Enum.map(evaluations, & &1["branch_id"])

      issues
      |> ensure(
        eligibility["branch_count"] == length(branches),
        "$.recommendation_eligibility.branch_count",
        "must match enclosing branch count"
      )
      |> ensure(
        evaluation_branch_ids == expected_branch_ids,
        "$.recommendation_eligibility.evaluations",
        "must match enclosing score-ordered branches exactly"
      )
      |> then(fn acc ->
        branches
        |> Enum.zip(evaluations)
        |> Enum.with_index()
        |> Enum.reduce(acc, fn {{branch, evaluation}, index}, nested_acc ->
          validate_evaluation(nested_acc, branch, evaluation, eligibility, index)
        end)
      end)
      |> validate_eligibility_summary(evaluations, eligibility)
    else
      issues
    end
  end

  defp validate_evaluation(issues, branch, evaluation, eligibility, index) do
    path = "$.recommendation_eligibility.evaluations[#{index}]"
    policy_decision = map_or_empty(branch["policy_decision"])
    policy_blocked? = policy_decision["classification"] == "blocked_by_policy"
    hard = map_or_empty(evaluation["hard_feasibility"])
    hard_eligible? = hard["eligible"] == true
    expected_status = evaluation_status(hard_eligible?, policy_blocked?)
    expected_eligible = hard_eligible? and not policy_blocked?
    expected_policy_blocker = if(policy_blocked?, do: policy_decision, else: :null)
    expected_reasons = blocker_reasons(hard, policy_decision, policy_blocked?)

    issues
    |> ensure(
      is_map(branch["policy_decision"]),
      "$.branches[#{index}].policy_decision",
      "must be an object when hard recommendation eligibility is enabled"
    )
    |> require_fields(path, evaluation, @evaluation_fields)
    |> ensure(
      evaluation["branch_id"] == branch["branch_id"],
      path <> ".branch_id",
      "must match the enclosing branch"
    )
    |> ensure(
      numbers_equal?(evaluation["score"], branch["score"]),
      path <> ".score",
      "must match the enclosing branch score"
    )
    |> ensure(
      evaluation["branch_score_term_identity"] == parameter_identity(branch["score_terms"]),
      path <> ".branch_score_term_identity",
      "must bind the exact computed branch score terms"
    )
    |> expect_one_of(path, evaluation, "status", @statuses)
    |> expect_type(path, evaluation, "eligible", :boolean)
    |> expect_type(path, evaluation, "hard_feasibility", :map)
    |> expect_type(path, evaluation, "blocker_reasons", :list)
    |> validate_string_list_items(path, evaluation, "blocker_reasons")
    |> ensure(
      evaluation["status"] == expected_status,
      path <> ".status",
      "must derive from hard feasibility and branch policy decision"
    )
    |> ensure(
      evaluation["eligible"] == expected_eligible,
      path <> ".eligible",
      "must require both hard feasibility and a non-blocked policy decision"
    )
    |> ensure(
      values_equal?(evaluation["policy_blocker"], expected_policy_blocker),
      path <> ".policy_blocker",
      "must exactly copy the authority-derived enclosing branch policy decision when blocked"
    )
    |> ensure(
      evaluation["blocker_reasons"] == expected_reasons,
      path <> ".blocker_reasons",
      "must exactly summarize hard-feasibility and authority/policy blockers"
    )
    |> validate_hard_feasibility(path, branch, hard, eligibility)
  end

  defp validate_hard_feasibility(issues, path, branch, hard, eligibility) do
    registry = map_or_empty(eligibility["source_evidence_registry"])
    expected_identity = parameter_identity(branch["score_terms"])
    blockers = proper_map_list(hard["blockers"])
    blocker_reasons = if is_list(blockers), do: Enum.map(blockers, & &1["reason"]), else: nil
    eligible = hard["eligible"]

    issues
    |> ensure(
      hard["schema_contract"] == "candidate_feasibility.v1",
      path <> ".hard_feasibility.schema_contract",
      "must retain candidate_feasibility.v1"
    )
    |> ensure(
      hard["mode"] == "hard",
      path <> ".hard_feasibility.mode",
      "must retain hard mode"
    )
    |> ensure(
      hard["alternative_id"] == branch["branch_id"],
      path <> ".hard_feasibility.alternative_id",
      "must bind to the exact branch"
    )
    |> ensure(
      hard_parameter_identity_valid?(hard, expected_identity),
      path <> ".hard_feasibility.parameter_content_identity",
      "must match the branch score terms or retain the typed missing/mismatch blocker"
    )
    |> ensure(
      hard["source_evidence_registry_id"] == registry["id"],
      path <> ".hard_feasibility.source_evidence_registry_id",
      "must match the declared source evidence registry"
    )
    |> ensure(
      hard["model_limits"] == HardFeasibility.model_limits(),
      path <> ".hard_feasibility.model_limits",
      "must retain typed hard-feasibility limits"
    )
    |> ensure(
      is_boolean(eligible) and
        hard["status"] == if(eligible, do: "feasible", else: "infeasible"),
      path <> ".hard_feasibility.status",
      "must match hard-feasibility eligibility"
    )
    |> ensure(
      is_list(blockers) and blocker_reasons == hard["blocker_reasons"],
      path <> ".hard_feasibility.blocker_reasons",
      "must exactly summarize retained blockers"
    )
    |> ensure(
      (eligible == true and blockers == []) or
        (eligible == false and is_list(blockers) and blockers != []),
      path <> ".hard_feasibility.blockers",
      "must retain blockers exactly when infeasible"
    )
  end

  defp validate_eligibility_summary(issues, evaluations, eligibility) do
    eligible = Enum.filter(evaluations, &(&1["eligible"] == true))
    rejected = Enum.reject(evaluations, &(&1["eligible"] == true))
    eligible_ids = Enum.map(eligible, & &1["branch_id"])
    selected_id = eligible_ids |> List.first() |> null()
    status = if eligible == [], do: "no_recommendable_branch", else: "recommendable"
    expected_counterfactual = rejected |> List.first() |> counterfactual()

    issues
    |> ensure(
      eligibility["eligible_count"] == length(eligible),
      "$.recommendation_eligibility.eligible_count",
      "must match eligible evaluations"
    )
    |> ensure(
      eligibility["rejected_count"] == length(rejected),
      "$.recommendation_eligibility.rejected_count",
      "must match rejected evaluations"
    )
    |> ensure(
      eligibility["eligible_ranked_branch_ids"] == eligible_ids,
      "$.recommendation_eligibility.eligible_ranked_branch_ids",
      "must rank only eligible branches by score descending then branch_id ascending"
    )
    |> ensure(
      values_equal?(eligibility["selected_branch_id"], selected_id),
      "$.recommendation_eligibility.selected_branch_id",
      "must identify the first eligible branch or JSON null"
    )
    |> ensure(
      eligibility["status"] == status,
      "$.recommendation_eligibility.status",
      "must match whether an eligible branch exists"
    )
    |> ensure(
      values_equal?(eligibility["counterfactual"], expected_counterfactual),
      "$.recommendation_eligibility.counterfactual",
      "must retain the highest-scoring rejected branch as review-only evidence"
    )
  end

  defp validate_artifact_bindings(issues, artifact, eligibility, evaluations) do
    recommendation = map_or_empty(artifact["recommendation"])

    comparison_rows =
      artifact
      |> Map.get("branch_comparison_report")
      |> map_or_empty()
      |> Map.get("rows")
      |> proper_map_list()

    issues
    |> ensure(
      is_map(artifact["branch_comparison_report"]),
      "$.branch_comparison_report",
      "must be an object when hard recommendation eligibility is enabled"
    )
    |> ensure(
      values_equal?(recommendation["recommended_branch_id"], eligibility["selected_branch_id"]),
      "$.recommendation.recommended_branch_id",
      "must match recommendation eligibility selection"
    )
    |> ensure(
      recommendation["ranked_branch_ids"] == eligibility["eligible_ranked_branch_ids"],
      "$.recommendation.ranked_branch_ids",
      "must match the eligible branch ranking"
    )
    |> ensure(
      recommendation_counterfactual(recommendation) == eligibility["counterfactual"],
      "$.recommendation.counterfactual",
      "must match recommendation eligibility counterfactual evidence"
    )
    |> validate_comparison_bindings(comparison_rows, evaluations)
  end

  defp validate_comparison_bindings(issues, rows, evaluations)
       when is_list(rows) and is_list(evaluations) and length(rows) == length(evaluations) do
    rows
    |> Enum.zip(evaluations)
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {{row, evaluation}, index}, acc ->
      path = "$.branch_comparison_report.rows[#{index}]"

      acc
      |> ensure(
        row["recommendation_eligibility_status"] == evaluation["status"],
        path <> ".recommendation_eligibility_status",
        "must match recommendation eligibility evaluation"
      )
      |> ensure(
        row["recommendation_eligible"] == evaluation["eligible"],
        path <> ".recommendation_eligible",
        "must match recommendation eligibility evaluation"
      )
      |> ensure(
        row["recommendation_hard_feasibility"] == evaluation["hard_feasibility"],
        path <> ".recommendation_hard_feasibility",
        "must retain exact typed hard-feasibility evidence"
      )
      |> ensure(
        values_equal?(row["recommendation_policy_blocker"], evaluation["policy_blocker"]),
        path <> ".recommendation_policy_blocker",
        "must retain exact authority-derived policy blocker evidence"
      )
      |> ensure(
        row["recommendation_blocker_reasons"] == evaluation["blocker_reasons"],
        path <> ".recommendation_blocker_reasons",
        "must retain exact blocker reasons"
      )
    end)
  end

  defp validate_comparison_bindings(issues, _rows, _evaluations), do: issues

  defp validate_selected_id(issues, eligibility) do
    case eligibility["selected_branch_id"] do
      value when value in [nil, :null] ->
        issues

      value when is_binary(value) ->
        StableIdValidation.validate_stable_id(
          issues,
          "$.recommendation_eligibility.selected_branch_id",
          value
        )

      _value ->
        [
          error(
            "$.recommendation_eligibility.selected_branch_id",
            "must be a stable ID string or JSON null"
          )
          | issues
        ]
    end
  end

  defp validate_registry_summary(issues, eligibility) do
    registry = map_or_empty(eligibility["source_evidence_registry"])

    issues
    |> ensure(
      registry["schema_contract"] == SourceEvidenceRegistry.schema_contract(),
      "$.recommendation_eligibility.source_evidence_registry.schema_contract",
      "must retain the typed source evidence registry contract"
    )
    |> ensure(
      registry["trust_boundary"] == SourceEvidenceRegistry.trust_boundary(),
      "$.recommendation_eligibility.source_evidence_registry.trust_boundary",
      "must retain the source evidence registry trust boundary"
    )
    |> StableIdValidation.validate_stable_id(
      "$.recommendation_eligibility.source_evidence_registry.id",
      registry["id"]
    )
  end

  defp validate_counterfactual_type(issues, eligibility) do
    case eligibility["counterfactual"] do
      value when value in [nil, :null] ->
        issues

      %{} ->
        issues

      _value ->
        [
          error(
            "$.recommendation_eligibility.counterfactual",
            "must be an object or JSON null"
          )
          | issues
        ]
    end
  end

  defp evaluation_status(true, false), do: "eligible"
  defp evaluation_status(false, false), do: "infeasible"
  defp evaluation_status(true, true), do: "policy_blocked"
  defp evaluation_status(false, true), do: "infeasible_and_policy_blocked"

  defp blocker_reasons(hard, policy_decision, policy_blocked?) do
    hard_reasons = if is_list(hard["blocker_reasons"]), do: hard["blocker_reasons"], else: []

    policy_reasons =
      if policy_blocked? do
        rule_reasons =
          policy_decision
          |> Map.get("rule_matches", [])
          |> proper_map_list()
          |> case do
            rows when is_list(rows) ->
              rows
              |> Enum.filter(&(&1["classification"] == "blocked_by_policy"))
              |> Enum.map(&(&1["reason"] || &1["rule_id"]))

            _rows ->
              []
          end

        [
          "blocked_by_policy",
          policy_decision
          |> Map.get("authority_context_evaluation")
          |> map_or_empty()
          |> Map.get("reason_code")
          | rule_reasons
        ]
      else
        []
      end

    (hard_reasons ++ policy_reasons)
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp parameter_identity(score_terms) when is_map(score_terms) do
    SourceEvidenceRegistry.parameter_content_identity(score_terms)
  rescue
    _error -> :invalid
  end

  defp parameter_identity(_score_terms), do: :invalid

  defp recommendation_counterfactual(%{"counterfactual" => counterfactual}), do: counterfactual
  defp recommendation_counterfactual(_recommendation), do: :null

  defp counterfactual(nil), do: :null

  defp counterfactual(evaluation) do
    evaluation
    |> Map.put("review_only", true)
    |> Map.put("importable", false)
  end

  defp alternative_properties(stable_id_pattern) do
    %{
      "branch_id" => %{"type" => "string", "pattern" => stable_id_pattern},
      "score" => %{"type" => "number"},
      "branch_score_term_identity" => %{"type" => "object"},
      "status" => %{"type" => "string", "enum" => @statuses},
      "eligible" => %{"type" => "boolean"},
      "hard_feasibility" => %{"type" => "object"},
      "policy_blocker" => %{"type" => ["object", "null"]},
      "blocker_reasons" => %{"type" => "array", "items" => %{"type" => "string"}}
    }
  end

  defp evaluation_json_schema(stable_id_pattern, opts) do
    counterfactual? = Keyword.get(opts, :counterfactual?, false)
    required = @evaluation_fields ++ if(counterfactual?, do: ~w(review_only importable), else: [])

    properties =
      alternative_properties(stable_id_pattern)
      |> maybe_put_counterfactual_properties(counterfactual?)

    %{
      "type" => "object",
      "additionalProperties" => false,
      "required" => required,
      "properties" => properties
    }
  end

  defp maybe_put_counterfactual_properties(properties, false), do: properties

  defp maybe_put_counterfactual_properties(properties, true) do
    properties
    |> Map.put("review_only", %{"type" => "boolean", "const" => true})
    |> Map.put("importable", %{"type" => "boolean", "const" => false})
  end

  defp count_schema, do: %{"type" => "integer", "minimum" => 0}

  defp proper_map_list(values) when is_list(values) do
    if Enum.all?(values, &is_map/1), do: values
  end

  defp proper_map_list(_values), do: nil

  defp map_or_empty(%{} = map), do: map
  defp map_or_empty(_value), do: %{}

  defp null(nil), do: :null
  defp null(value), do: value
  defp nullish?(value), do: value in [nil, :null]

  defp hard_parameter_identity_valid?(hard, expected_identity) do
    reasons = if is_list(hard["blocker_reasons"]), do: hard["blocker_reasons"], else: []

    values_equal?(hard["parameter_content_identity"], expected_identity) or
      (nullish?(hard["parameter_content_identity"]) and
         "missing_source_evidence_registry_entry" in reasons) or
      "parameter_content_identity_registry_mismatch" in reasons
  end

  defp numbers_equal?(left, right) when is_number(left) and is_number(right),
    do: abs(left - right) <= 1.0e-9

  defp numbers_equal?(_left, _right), do: false

  defp values_equal?(left, right), do: normalize_nulls(left) == normalize_nulls(right)
  defp normalize_nulls(:null), do: nil

  defp normalize_nulls(%{} = map),
    do: Map.new(map, fn {key, value} -> {key, normalize_nulls(value)} end)

  defp normalize_nulls(values) when is_list(values), do: Enum.map(values, &normalize_nulls/1)
  defp normalize_nulls(value), do: value

  defp ensure(issues, true, _path, _message), do: issues
  defp ensure(issues, false, path, message), do: [error(path, message) | issues]
end
