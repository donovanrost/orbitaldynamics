defmodule OrbitalDynamics.Schema.StrategyRecommendationEligibilityContracts do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.StrategyRecommendationEligibility
  alias OrbitalDynamics.Optimizer.{HardFeasibility, SourceEvidenceRegistry}
  alias OrbitalDynamics.Schema.{JsonSafety, StableIdValidation}

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
  @counterfactual_fields @evaluation_fields ++ ~w(review_only importable)
  @registry_fields ~w(schema_contract id trust_boundary entries)
  @registry_entry_fields ~w(
    parameter_revision parameter_content_identity resource_state_trace_id
    downlink_link_budget_id
  )
  @identity_fields ~w(algorithm sha256)
  @hard_fields ~w(
    schema_contract mode alternative_id parameter_revision parameter_content_identity
    source_evidence_registry_id spacecraft_id status eligible evidence_bindings
    threshold_evaluations blocker_reasons blockers model_limits
  )
  @evidence_bindings_fields ~w(resource_state_trace downlink_link_budget)
  @binding_fields ~w(id expected_id revision)
  @threshold_evaluation_fields ~w(
    type source_contract metric operator actual threshold status required_volume_mb
    supported_volume_mb
  )
  @blocker_fields ~w(reason metric actual operator threshold)
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
        "source_evidence_registry" => registry_json_schema(stable_id_pattern),
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
    case JsonSafety.errors(eligibility, "$.recommendation_eligibility") do
      [] -> validate_json_safe_hard(issues, artifact, eligibility)
      json_issues -> json_issues ++ issues
    end
  end

  defp validate_json_safe_hard(issues, artifact, eligibility) do
    branches = proper_map_list(Map.get(artifact, "branches"))
    evaluations = proper_map_list(Map.get(eligibility, "evaluations"))

    issues =
      issues
      |> validate_closed_map(
        "$.recommendation_eligibility",
        eligibility,
        @required_fields
      )
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
        validate_proper_stable_id_list(
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
      |> validate_proper_string_list(
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
      |> validate_registry(eligibility)
      |> validate_counterfactual_type(eligibility)
      |> validate_counterfactual_shape(eligibility)
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
    |> validate_closed_map(path, evaluation, @evaluation_fields)
    |> require_fields(path, evaluation, @evaluation_fields)
    |> expect_type(path, evaluation, "branch_id", :binary)
    |> ensure(is_number(evaluation["score"]), path <> ".score", "must be a number")
    |> expect_type(path, evaluation, "branch_score_term_identity", :map)
    |> validate_content_identity(
      path <> ".branch_score_term_identity",
      evaluation["branch_score_term_identity"]
    )
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
    |> validate_proper_string_list(path, evaluation, "blocker_reasons")
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

    registry_entry =
      registry |> Map.get("entries") |> map_or_empty() |> Map.get(branch["branch_id"])

    expected_identity = parameter_identity(branch["score_terms"])
    blockers = proper_map_list(hard["blockers"])
    threshold_evaluations = proper_map_list(hard["threshold_evaluations"])
    blocker_reasons = if is_list(blockers), do: Enum.map(blockers, & &1["reason"]), else: nil
    eligible = hard["eligible"]

    issues
    |> validate_closed_map(path <> ".hard_feasibility", hard, @hard_fields)
    |> require_fields(path <> ".hard_feasibility", hard, @hard_fields)
    |> validate_hard_content_identity(path, hard)
    |> validate_registry_entry_copy(path, hard, registry_entry)
    |> validate_evidence_bindings(path, hard["evidence_bindings"])
    |> validate_threshold_evaluations(path, threshold_evaluations)
    |> validate_blockers(path, blockers)
    |> validate_nullable_stable_id(
      path <> ".hard_feasibility.parameter_revision",
      hard["parameter_revision"]
    )
    |> validate_nullable_stable_id(
      path <> ".hard_feasibility.spacecraft_id",
      hard["spacecraft_id"]
    )
    |> StableIdValidation.validate_stable_id(
      path <> ".hard_feasibility.source_evidence_registry_id",
      hard["source_evidence_registry_id"]
    )
    |> expect_type(path <> ".hard_feasibility", hard, "blocker_reasons", :list)
    |> validate_proper_string_list(path <> ".hard_feasibility", hard, "blocker_reasons")
    |> expect_type(path <> ".hard_feasibility", hard, "blockers", :list)
    |> expect_type(path <> ".hard_feasibility", hard, "threshold_evaluations", :list)
    |> expect_type(path <> ".hard_feasibility", hard, "evidence_bindings", :map)
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

    review_rows =
      artifact
      |> Map.get("operator_review_package")
      |> map_or_empty()
      |> Map.get("rows")
      |> proper_map_list()

    manifest_rows =
      artifact
      |> Map.get("cadence_import_manifest")
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
    |> validate_counterfactual_projections(
      eligibility,
      comparison_rows,
      review_rows,
      manifest_rows
    )
  end

  defp validate_counterfactual_projections(
         issues,
         eligibility,
         comparison_rows,
         review_rows,
         manifest_rows
       ) do
    case eligibility["counterfactual"] do
      %{"branch_id" => branch_id} ->
        issues
        |> validate_counterfactual_comparison_row(comparison_rows, branch_id)
        |> validate_counterfactual_review_rows(review_rows, branch_id)
        |> validate_counterfactual_manifest_rows(manifest_rows, branch_id)
        |> validate_no_selected_projection(eligibility, review_rows, manifest_rows)

      _counterfactual ->
        validate_no_selected_projection(issues, eligibility, review_rows, manifest_rows)
    end
  end

  defp validate_no_selected_projection(
         issues,
         %{"status" => "no_recommendable_branch"},
         review_rows,
         manifest_rows
       ) do
    recommendation_reviews =
      if is_list(review_rows),
        do: Enum.filter(review_rows, &(&1["review_type"] == "strategy_recommendation")),
        else: []

    selected_imports =
      if is_list(manifest_rows) do
        Enum.filter(manifest_rows, fn row ->
          row["source_review_type"] == "strategy_recommendation" or
            row["import_action"] == "import_strategy_recommendation"
        end)
      else
        []
      end

    issues
    |> ensure(
      recommendation_reviews == [],
      "$.operator_review_package.rows",
      "must not emit a selected recommendation review without a recommendable branch"
    )
    |> ensure(
      selected_imports == [],
      "$.cadence_import_manifest.rows",
      "must not emit a selected recommendation import without a recommendable branch"
    )
  end

  defp validate_no_selected_projection(issues, _eligibility, _review_rows, _manifest_rows),
    do: issues

  defp validate_counterfactual_comparison_row(issues, rows, branch_id) when is_list(rows) do
    case Enum.find(rows, &(&1["branch_id"] == branch_id)) do
      %{} = row ->
        ensure(
          issues,
          row["recommendation_counterfactual"] == true,
          "$.branch_comparison_report.rows",
          "must mark the retained rejected branch as the recommendation counterfactual"
        )

      _row ->
        issues
    end
  end

  defp validate_counterfactual_comparison_row(issues, _rows, _branch_id), do: issues

  defp validate_counterfactual_review_rows(issues, rows, branch_id) when is_list(rows) do
    counterfactual_rows =
      Enum.filter(rows, fn row ->
        row["review_type"] == "strategy_tradeoff" and row["branch_id"] == branch_id and
          row["recommendation_counterfactual"] == true
      end)

    issues
    |> ensure(
      length(counterfactual_rows) == 1,
      "$.operator_review_package.rows",
      "must retain exactly one review-only strategy-tradeoff counterfactual row"
    )
    |> validate_non_importable_rows(
      counterfactual_rows,
      "$.operator_review_package.rows",
      cadence_status?: true,
      import_status?: false
    )
  end

  defp validate_counterfactual_review_rows(issues, _rows, _branch_id), do: issues

  defp validate_counterfactual_manifest_rows(issues, rows, branch_id) when is_list(rows) do
    counterfactual_rows =
      Enum.filter(rows, fn row ->
        row["branch_id"] == branch_id and row["recommendation_counterfactual"] == true and
          row["source_review_type"] in ["strategy_branch_comparison", "strategy_tradeoff"]
      end)

    source_types = Enum.map(counterfactual_rows, & &1["source_review_type"])

    issues
    |> ensure(
      Enum.sort(source_types) == ["strategy_branch_comparison", "strategy_tradeoff"],
      "$.cadence_import_manifest.rows",
      "must retain exactly the branch and strategy-tradeoff counterfactual rows"
    )
    |> validate_non_importable_rows(
      counterfactual_rows,
      "$.cadence_import_manifest.rows",
      cadence_status?: true,
      import_status?: true
    )
  end

  defp validate_counterfactual_manifest_rows(issues, _rows, _branch_id), do: issues

  defp validate_non_importable_rows(issues, rows, path, opts) do
    Enum.reduce(rows, issues, fn row, acc ->
      acc
      |> ensure(row["review_only"] == true, path, "counterfactual rows must be review-only")
      |> ensure(row["importable"] == false, path, "counterfactual rows must be non-importable")
      |> ensure(
        not Keyword.get(opts, :cadence_status?) or
          row["cadence_import_status"] == "not_applicable",
        path,
        "counterfactual rows must have non-importable Cadence status"
      )
      |> ensure(
        row["has_cadence_import"] == false,
        path,
        "counterfactual rows must not claim a Cadence import"
      )
      |> ensure(
        not Keyword.get(opts, :import_status?) or row["import_status"] == "not_applicable",
        path,
        "counterfactual manifest rows must not be ready for import"
      )
    end)
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

  defp validate_registry(issues, eligibility) do
    registry = map_or_empty(eligibility["source_evidence_registry"])
    entries = map_or_empty(registry["entries"])

    issues
    |> validate_closed_map(
      "$.recommendation_eligibility.source_evidence_registry",
      registry,
      @registry_fields
    )
    |> require_fields(
      "$.recommendation_eligibility.source_evidence_registry",
      registry,
      @registry_fields
    )
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
    |> expect_type(
      "$.recommendation_eligibility.source_evidence_registry",
      registry,
      "entries",
      :map
    )
    |> validate_registry_entries(entries)
    |> ensure(
      canonical_registry?(registry),
      "$.recommendation_eligibility.source_evidence_registry.id",
      "must be recomputable from the exact canonical source evidence registry entries"
    )
  end

  defp validate_registry_entries(issues, entries) when is_map(entries) do
    entries
    |> Enum.sort_by(fn {key, _entry} -> safe_sort_key(key) end)
    |> Enum.reduce(issues, fn {branch_id, entry}, acc ->
      path = "$.recommendation_eligibility.source_evidence_registry.entries"

      acc =
        if is_binary(branch_id) do
          StableIdValidation.validate_stable_id(acc, path <> ".#{branch_id}", branch_id)
        else
          [error(path, "entry keys must be stable ID strings") | acc]
        end

      if is_map(entry) do
        entry_path = if is_binary(branch_id), do: path <> ".#{branch_id}", else: path

        acc
        |> validate_closed_map(entry_path, entry, @registry_entry_fields)
        |> require_fields(entry_path, entry, @registry_entry_fields)
        |> validate_content_identity(
          entry_path <> ".parameter_content_identity",
          entry["parameter_content_identity"]
        )
        |> validate_registry_entry_ids(entry_path, entry)
      else
        [error(path, "entries must contain only objects") | acc]
      end
    end)
  end

  defp validate_registry_entry_ids(issues, path, entry) do
    Enum.reduce(
      ~w(parameter_revision resource_state_trace_id downlink_link_budget_id),
      issues,
      fn field, acc ->
        StableIdValidation.validate_stable_id(acc, path <> ".#{field}", entry[field])
      end
    )
  end

  defp canonical_registry?(registry) when is_map(registry) do
    SourceEvidenceRegistry.normalize!(registry) == registry
  rescue
    _error -> false
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

  defp validate_counterfactual_shape(issues, eligibility) do
    case eligibility["counterfactual"] do
      %{} = counterfactual ->
        issues
        |> validate_closed_map(
          "$.recommendation_eligibility.counterfactual",
          counterfactual,
          @counterfactual_fields
        )
        |> require_fields(
          "$.recommendation_eligibility.counterfactual",
          counterfactual,
          @counterfactual_fields
        )
        |> ensure(
          counterfactual["review_only"] == true,
          "$.recommendation_eligibility.counterfactual.review_only",
          "must remain explicitly review-only"
        )
        |> ensure(
          counterfactual["importable"] == false,
          "$.recommendation_eligibility.counterfactual.importable",
          "must remain explicitly non-importable"
        )

      _counterfactual ->
        issues
    end
  end

  defp validate_hard_content_identity(issues, path, hard) do
    case hard["parameter_content_identity"] do
      value when value in [nil, :null] ->
        issues

      identity ->
        validate_content_identity(
          issues,
          path <> ".hard_feasibility.parameter_content_identity",
          identity
        )
    end
  end

  defp validate_content_identity(issues, path, %{} = identity) do
    issues
    |> validate_closed_map(path, identity, @identity_fields)
    |> require_fields(path, identity, @identity_fields)
    |> ensure(
      identity["algorithm"] == SourceEvidenceRegistry.algorithm(),
      path <> ".algorithm",
      "must declare the supported deterministic identity algorithm"
    )
    |> ensure(
      is_binary(identity["sha256"]) and Regex.match?(~r/^[0-9a-f]{64}$/, identity["sha256"]),
      path <> ".sha256",
      "must be a lowercase hexadecimal SHA-256 digest"
    )
  end

  defp validate_content_identity(issues, path, _identity),
    do: [error(path, "must be a content identity object") | issues]

  defp validate_registry_entry_copy(issues, path, hard, %{} = entry) do
    issues
    |> ensure(
      hard["parameter_revision"] == entry["parameter_revision"],
      path <> ".hard_feasibility.parameter_revision",
      "must match the bound source evidence registry entry"
    )
    |> ensure(
      hard["parameter_content_identity"] == entry["parameter_content_identity"],
      path <> ".hard_feasibility.parameter_content_identity",
      "must match the bound source evidence registry entry"
    )
    |> validate_registry_binding_expected_id(
      path,
      hard,
      "resource_state_trace",
      entry["resource_state_trace_id"]
    )
    |> validate_registry_binding_expected_id(
      path,
      hard,
      "downlink_link_budget",
      entry["downlink_link_budget_id"]
    )
  end

  defp validate_registry_entry_copy(issues, path, hard, _entry) do
    issues
    |> ensure(
      nullish?(hard["parameter_revision"]),
      path <> ".hard_feasibility.parameter_revision",
      "must be JSON null without a source evidence registry entry"
    )
    |> ensure(
      nullish?(hard["parameter_content_identity"]),
      path <> ".hard_feasibility.parameter_content_identity",
      "must be JSON null without a source evidence registry entry"
    )
  end

  defp validate_registry_binding_expected_id(issues, path, hard, field, expected_id) do
    case hard |> Map.get("evidence_bindings") |> map_or_empty() |> Map.get(field) do
      %{} = binding ->
        ensure(
          issues,
          binding["expected_id"] == expected_id,
          path <> ".hard_feasibility.evidence_bindings.#{field}.expected_id",
          "must match the bound source evidence registry entry"
        )

      _binding ->
        issues
    end
  end

  defp validate_evidence_bindings(issues, path, %{} = bindings) do
    binding_path = path <> ".hard_feasibility.evidence_bindings"

    issues
    |> validate_closed_map(binding_path, bindings, @evidence_bindings_fields)
    |> require_fields(binding_path, bindings, @evidence_bindings_fields)
    |> validate_evidence_binding(binding_path, "resource_state_trace", bindings)
    |> validate_evidence_binding(binding_path, "downlink_link_budget", bindings)
  end

  defp validate_evidence_bindings(issues, _path, _bindings), do: issues

  defp validate_evidence_binding(issues, path, field, bindings) do
    case bindings[field] do
      value when value in [nil, :null] ->
        issues

      %{} = binding ->
        binding_path = path <> ".#{field}"

        issues
        |> validate_closed_map(binding_path, binding, @binding_fields)
        |> ensure(
          Map.has_key?(binding, "id") and Map.has_key?(binding, "expected_id"),
          binding_path,
          "must retain id and expected_id bindings"
        )
        |> validate_nullable_stable_id(binding_path <> ".id", binding["id"])
        |> validate_nullable_stable_id(binding_path <> ".expected_id", binding["expected_id"])
        |> validate_optional_stable_id(binding_path <> ".revision", binding, "revision")

      _binding ->
        [error(path <> ".#{field}", "must be an object or JSON null") | issues]
    end
  end

  defp validate_threshold_evaluations(issues, path, rows) when is_list(rows) do
    rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {row, index}, acc ->
      row_path = path <> ".hard_feasibility.threshold_evaluations[#{index}]"

      acc
      |> validate_closed_map(row_path, row, @threshold_evaluation_fields)
      |> require_fields(
        row_path,
        row,
        ~w(type source_contract metric operator actual threshold status)
      )
      |> validate_threshold_evaluation_types(row_path, row)
    end)
  end

  defp validate_threshold_evaluations(issues, _path, _rows), do: issues

  defp validate_threshold_evaluation_types(issues, path, row) do
    issues
    |> expect_type(path, row, "type", :binary)
    |> expect_type(path, row, "source_contract", :binary)
    |> expect_type(path, row, "metric", :binary)
    |> expect_type(path, row, "operator", :binary)
    |> ensure(is_number(row["actual"]), path <> ".actual", "must be a number")
    |> ensure(is_number(row["threshold"]), path <> ".threshold", "must be a number")
    |> expect_one_of(path, row, "status", ["pass", "fail"])
    |> validate_optional_number(path, row, "required_volume_mb")
    |> validate_optional_number(path, row, "supported_volume_mb")
  end

  defp validate_optional_number(issues, path, map, field) do
    case Map.fetch(map, field) do
      :error -> issues
      {:ok, value} -> ensure(issues, is_number(value), path <> ".#{field}", "must be a number")
    end
  end

  defp validate_blockers(issues, path, blockers) when is_list(blockers) do
    blockers
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {blocker, index}, acc ->
      blocker_path = path <> ".hard_feasibility.blockers[#{index}]"

      acc
      |> validate_closed_map(blocker_path, blocker, @blocker_fields)
      |> require_fields(blocker_path, blocker, ["reason"])
      |> expect_type(blocker_path, blocker, "reason", :binary)
      |> validate_optional_number(blocker_path, blocker, "actual")
      |> validate_optional_number(blocker_path, blocker, "threshold")
    end)
  end

  defp validate_blockers(issues, _path, _blockers), do: issues

  defp validate_nullable_stable_id(issues, _path, value) when value in [nil, :null], do: issues

  defp validate_nullable_stable_id(issues, path, value),
    do: StableIdValidation.validate_stable_id(issues, path, value)

  defp validate_optional_stable_id(issues, path, map, field) do
    case Map.fetch(map, field) do
      :error -> issues
      {:ok, value} -> validate_nullable_stable_id(issues, path, value)
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
      "branch_score_term_identity" => content_identity_json_schema(),
      "status" => %{"type" => "string", "enum" => @statuses},
      "eligible" => %{"type" => "boolean"},
      "hard_feasibility" => hard_feasibility_json_schema(stable_id_pattern),
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

  defp registry_json_schema(stable_id_pattern) do
    %{
      "type" => "object",
      "additionalProperties" => false,
      "required" => @registry_fields,
      "properties" => %{
        "schema_contract" => %{
          "type" => "string",
          "const" => SourceEvidenceRegistry.schema_contract()
        },
        "id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "trust_boundary" => %{
          "type" => "string",
          "const" => SourceEvidenceRegistry.trust_boundary()
        },
        "entries" => %{
          "type" => "object",
          "propertyNames" => %{"pattern" => stable_id_pattern},
          "additionalProperties" => registry_entry_json_schema(stable_id_pattern)
        }
      }
    }
  end

  defp registry_entry_json_schema(stable_id_pattern) do
    %{
      "type" => "object",
      "additionalProperties" => false,
      "required" => @registry_entry_fields,
      "properties" => %{
        "parameter_revision" => %{"type" => "string", "pattern" => stable_id_pattern},
        "parameter_content_identity" => content_identity_json_schema(),
        "resource_state_trace_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "downlink_link_budget_id" => %{"type" => "string", "pattern" => stable_id_pattern}
      }
    }
  end

  defp content_identity_json_schema do
    %{
      "type" => "object",
      "additionalProperties" => false,
      "required" => @identity_fields,
      "properties" => %{
        "algorithm" => %{
          "type" => "string",
          "const" => SourceEvidenceRegistry.algorithm()
        },
        "sha256" => %{"type" => "string", "pattern" => "^[0-9a-f]{64}$"}
      }
    }
  end

  defp hard_feasibility_json_schema(stable_id_pattern) do
    nullable_stable_id = %{"type" => ["string", "null"], "pattern" => stable_id_pattern}

    %{
      "type" => "object",
      "additionalProperties" => false,
      "required" => @hard_fields,
      "properties" => %{
        "schema_contract" => %{"type" => "string", "const" => "candidate_feasibility.v1"},
        "mode" => %{"type" => "string", "const" => "hard"},
        "alternative_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "parameter_revision" => nullable_stable_id,
        "parameter_content_identity" => %{
          "oneOf" => [%{"type" => "null"}, content_identity_json_schema()]
        },
        "source_evidence_registry_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "spacecraft_id" => nullable_stable_id,
        "status" => %{"type" => "string", "enum" => ["feasible", "infeasible"]},
        "eligible" => %{"type" => "boolean"},
        "evidence_bindings" => evidence_bindings_json_schema(stable_id_pattern),
        "threshold_evaluations" => %{
          "type" => "array",
          "items" => threshold_evaluation_json_schema()
        },
        "blocker_reasons" => %{"type" => "array", "items" => %{"type" => "string"}},
        "blockers" => %{"type" => "array", "items" => blocker_json_schema()},
        "model_limits" => %{
          "type" => "array",
          "items" => %{"type" => "string", "enum" => HardFeasibility.model_limits()}
        }
      }
    }
  end

  defp evidence_bindings_json_schema(stable_id_pattern) do
    %{
      "type" => "object",
      "additionalProperties" => false,
      "required" => @evidence_bindings_fields,
      "properties" =>
        Map.new(@evidence_bindings_fields, fn field ->
          {field,
           %{
             "oneOf" => [
               %{"type" => "null"},
               binding_json_schema(stable_id_pattern)
             ]
           }}
        end)
    }
  end

  defp binding_json_schema(stable_id_pattern) do
    nullable_stable_id = %{"type" => ["string", "null"], "pattern" => stable_id_pattern}

    %{
      "type" => "object",
      "additionalProperties" => false,
      "required" => ~w(id expected_id),
      "properties" => %{
        "id" => nullable_stable_id,
        "expected_id" => nullable_stable_id,
        "revision" => nullable_stable_id
      }
    }
  end

  defp threshold_evaluation_json_schema do
    %{
      "type" => "object",
      "additionalProperties" => false,
      "required" => ~w(type source_contract metric operator actual threshold status),
      "properties" => %{
        "type" => %{"type" => "string"},
        "source_contract" => %{"type" => "string"},
        "metric" => %{"type" => "string"},
        "operator" => %{"type" => "string"},
        "actual" => %{"type" => "number"},
        "threshold" => %{"type" => "number"},
        "status" => %{"type" => "string", "enum" => ["pass", "fail"]},
        "required_volume_mb" => %{"type" => "number"},
        "supported_volume_mb" => %{"type" => "number"}
      }
    }
  end

  defp blocker_json_schema do
    %{
      "type" => "object",
      "additionalProperties" => false,
      "required" => ["reason"],
      "properties" => %{
        "reason" => %{"type" => "string"},
        "metric" => %{"type" => "string"},
        "actual" => %{"type" => "number"},
        "operator" => %{"type" => "string"},
        "threshold" => %{"type" => "number"}
      }
    }
  end

  defp count_schema, do: %{"type" => "integer", "minimum" => 0}

  defp proper_map_list(values) when is_list(values) do
    if proper_list?(values) and Enum.all?(values, &is_map/1), do: values
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

  defp normalize_nulls(values) when is_list(values) do
    if proper_list?(values),
      do: Enum.map(values, &normalize_nulls/1),
      else: :invalid_improper_list
  end

  defp normalize_nulls(value), do: value

  defp validate_proper_stable_id_list(issues, path, values) do
    if proper_list?(values) do
      StableIdValidation.validate_stable_id_list(issues, path, values)
    else
      [error(path, "must be a proper list") | issues]
    end
  end

  defp validate_proper_string_list(issues, path, map, field) do
    if proper_list?(Map.get(map, field)) do
      validate_string_list_items(issues, path, map, field)
    else
      [error(path <> ".#{field}", "must be a proper list") | issues]
    end
  end

  defp proper_list?(values) when is_list(values) do
    _length = length(values)
    true
  rescue
    ArgumentError -> false
  end

  defp proper_list?(_values), do: false

  defp validate_closed_map(issues, path, %{} = map, allowed_fields) do
    map
    |> Map.keys()
    |> Enum.reject(&(&1 in allowed_fields))
    |> Enum.sort_by(&safe_sort_key/1)
    |> Enum.reduce(issues, fn
      field, acc when is_binary(field) ->
        [error(path <> ".#{field}", "is not an allowed field") | acc]

      _field, acc ->
        [error(path, "must contain only declared string keys") | acc]
    end)
  end

  defp validate_closed_map(issues, _path, _map, _allowed_fields), do: issues

  defp safe_sort_key(value) when is_binary(value), do: {0, value}
  defp safe_sort_key(value) when is_atom(value), do: {1, Atom.to_string(value)}
  defp safe_sort_key(_value), do: {2, "non_string_key"}

  defp ensure(issues, true, _path, _message), do: issues
  defp ensure(issues, false, path, message), do: [error(path, message) | issues]
end
