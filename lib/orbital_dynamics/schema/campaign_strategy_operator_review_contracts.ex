defmodule OrbitalDynamics.Schema.CampaignStrategyOperatorReviewContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  @top_level_sources [
    {"campaign_strategy.recommendation", ["recommendation"], "source_recommendation"},
    {"campaign_strategy.recommendation.tradeoffs", ["recommendation", "tradeoffs"],
     "source_tradeoff"},
    {"campaign_strategy.branch_comparison_report.rows", ["branch_comparison_report", "rows"],
     "source_branch_comparison"},
    {"campaign_strategy.ranking_comparison_report.rows", ["ranking_comparison_report", "rows"],
     "source_ranking_comparison"},
    {"campaign_strategy.pareto_frontier_report.rows", ["pareto_frontier_report", "rows"],
     "source_pareto_frontier"},
    {"campaign_strategy.score_term_report.rows", ["score_term_report", "rows"],
     "source_score_term"},
    {"campaign_strategy.objective_tradeoff_report.tradeoffs",
     ["objective_tradeoff_report", "tradeoffs"], "source_objective_tradeoff"},
    {"campaign_strategy.recommendation.requires_approval",
     ["recommendation", "requires_approval"], "source_requirement"},
    {"campaign_strategy.policy_decision", ["policy_decision", "escalations"],
     "source_policy_escalation"},
    {"campaign_strategy.recommendation.risks_remaining", ["recommendation", "risks_remaining"],
     "source_risk"}
  ]

  @branch_sources [
    {"campaign_strategy.branches.repair_result.operational_timeline_report.rows",
     ["repair_result", "operational_timeline_report", "rows"], "source_operational_timeline"},
    {"campaign_strategy.branches.resource_projection_report.projected_resources",
     ["resource_projection_report", "projected_resources"], "source_resource_projection"},
    {"campaign_strategy.branches.repair_result.source_candidate_diff_report.invalidated_candidates",
     ["repair_result", "source_candidate_diff_report", "invalidated_candidates"],
     "source_candidate_diff"},
    {"campaign_strategy.branches.repair_result.source_candidate_diff_report.retained_candidates",
     ["repair_result", "source_candidate_diff_report", "retained_candidates"],
     "source_candidate_diff"},
    {"campaign_strategy.branches.repair_result.score_term_report.rows",
     ["repair_result", "score_term_report", "rows"], "source_score_term"},
    {"campaign_strategy.branches.repair_result.objective_tradeoff_report.tradeoffs",
     ["repair_result", "objective_tradeoff_report", "tradeoffs"], "source_objective_tradeoff"},
    {"campaign_strategy.branches.repair_result.source_contact_allocation_report.rows",
     ["repair_result", "source_contact_allocation_report", "rows"], "source_contact_allocation"},
    {"campaign_strategy.branches.repair_result.source_contact_intents",
     ["repair_result", "source_contact_intents"], "source_contact_intent"},
    {"campaign_strategy.branches.repair_result.source_resource_filter_report.suppressed_candidates",
     ["repair_result", "source_resource_filter_report", "suppressed_candidates"],
     "source_resource_suppression"},
    {"campaign_strategy.branches.warnings", ["warnings"], "reason"}
  ]

  def validate(
        issues,
        %{"operator_review_package" => %{"rows" => rows} = package} = artifact
      )
      when is_list(rows) do
    if Enum.all?(rows, &is_map/1) do
      issues
      |> validate_package_fields(package, artifact)
      |> validate_source_groups(rows, artifact, @top_level_sources)
      |> validate_recommendation_feedback_provenance(rows, artifact)
      |> validate_branch_source_groups(rows, Map.get(artifact, "branches", []))
    else
      issues
    end
  end

  def validate(issues, _artifact), do: issues

  defp validate_package_fields(issues, package, artifact) do
    issues
    |> validate_equal(
      "$.operator_review_package.source_artifact_type",
      package["source_artifact_type"],
      "campaign_strategy.v3",
      "must identify the enclosing CampaignStrategy artifact type"
    )
    |> validate_equal(
      "$.operator_review_package.source_artifact_id",
      package["source_artifact_id"],
      get_in(artifact, ["strategy_metadata", "strategy_id"]),
      "must match the enclosing CampaignStrategy strategy ID"
    )
    |> validate_equal(
      "$.operator_review_package.provenance",
      package["provenance"],
      artifact["provenance"],
      "must match the enclosing CampaignStrategy provenance"
    )
  end

  defp validate_source_groups(issues, rows, artifact, specs) do
    Enum.reduce(specs, issues, fn {source, source_path, source_field}, acc ->
      case get_in(artifact, source_path) do
        nil ->
          acc

        source_value ->
          validate_equal(
            acc,
            "$.operator_review_package.rows",
            source_values(rows, source, source_field),
            list_wrap(source_value),
            "must preserve the complete ordered #{source} source rows"
          )
      end
    end)
  end

  defp validate_recommendation_feedback_provenance(issues, _rows, artifact)
       when not is_map_key(artifact, "operational_feedback_provenance"),
       do: issues

  defp validate_recommendation_feedback_provenance(issues, rows, artifact) do
    recommendation_rows =
      Enum.filter(rows, &(Map.get(&1, "source") == "campaign_strategy.recommendation"))

    validate_equal(
      issues,
      "$.operator_review_package.rows",
      Enum.map(recommendation_rows, &Map.get(&1, "source_operational_feedback_provenance")),
      List.duplicate(
        Map.get(artifact, "operational_feedback_provenance"),
        length(recommendation_rows)
      ),
      "must preserve the CampaignStrategy operational feedback provenance"
    )
  end

  defp validate_branch_source_groups(issues, rows, branches) when is_list(branches) do
    Enum.reduce(branches, issues, fn
      %{"branch_id" => branch_id} = branch, acc ->
        branch_rows = Enum.filter(rows, &(Map.get(&1, "branch_id") == branch_id))
        validate_source_groups(acc, branch_rows, branch, @branch_sources)

      _branch, acc ->
        acc
    end)
  end

  defp validate_branch_source_groups(issues, _rows, _branches), do: issues

  defp source_values(rows, source, source_field) do
    rows
    |> Enum.filter(&(Map.get(&1, "source") == source))
    |> Enum.map(&Map.get(&1, source_field))
  end

  defp list_wrap(values) when is_list(values), do: values
  defp list_wrap(value), do: [value]

  defp validate_equal(issues, path, actual, expected, message) do
    if values_equal?(actual, expected) do
      issues
    else
      [error(path, message) | issues]
    end
  end

  defp values_equal?(actual, expected) when actual == expected, do: true

  defp values_equal?(actual, expected) do
    normalize_nulls(actual) == normalize_nulls(expected)
  end

  defp normalize_nulls(:null), do: nil

  defp normalize_nulls(%{} = value) do
    Map.new(value, fn {key, nested} -> {key, normalize_nulls(nested)} end)
  end

  defp normalize_nulls([]), do: []

  defp normalize_nulls([head | tail]),
    do: [normalize_nulls(head) | normalize_nulls(tail)]

  defp normalize_nulls(value), do: value
end
