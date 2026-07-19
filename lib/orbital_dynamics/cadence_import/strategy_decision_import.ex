defmodule OrbitalDynamics.CadenceImport.StrategyDecisionImport do
  @moduledoc false

  alias OrbitalDynamics.CadenceImport.JsonNormalization
  alias OrbitalDynamics.OperatorReview

  def from_approval_requirement(requirement, opts, import) do
    from_review_report(
      requirement,
      opts,
      import,
      &OperatorReview.from_approval_requirement/1,
      "approval_requirement.v1",
      &(&1["id"] || &1["activity_id"]),
      "approval_requirement"
    )
  end

  def from_policy_decision(decision, opts, import) do
    from_review_report(
      decision,
      opts,
      import,
      &OperatorReview.from_policy_decision/1,
      "policy_decision.v1",
      &(&1["id"] || &1["policy_bundle_id"]),
      "policy_decision"
    )
  end

  def from_branch_comparison_report(report, opts, import) do
    from_report(
      report,
      opts,
      import,
      &OperatorReview.from_branch_comparison_report/1,
      "branch_comparison_report.v1",
      "branch_comparison_report"
    )
  end

  def from_ranking_comparison_report(report, opts, import) do
    from_report(
      report,
      opts,
      import,
      &OperatorReview.from_ranking_comparison_report/1,
      "ranking_comparison_report.v1",
      "ranking_comparison_report"
    )
  end

  def from_score_term_report(report, opts, import) do
    from_report(
      report,
      opts,
      import,
      &OperatorReview.from_score_term_report/1,
      "score_term_report.v1",
      "score_term_report"
    )
  end

  def from_objective_tradeoff_report(report, opts, import) do
    from_report(
      report,
      opts,
      import,
      &OperatorReview.from_objective_tradeoff_report/1,
      "objective_tradeoff_report.v1",
      "objective_tradeoff_report"
    )
  end

  def from_pareto_frontier_report(report, opts, import) do
    from_report(
      report,
      opts,
      import,
      &OperatorReview.from_pareto_frontier_report/1,
      "pareto_frontier_report.v1",
      "pareto_frontier_report"
    )
  end

  defp from_report(report, opts, import, review, source_type, fallback) do
    from_review_report(
      report,
      opts,
      import,
      review,
      source_type,
      &(&1["id"] || &1["source"]),
      fallback
    )
  end

  defp from_review_report(
         artifact,
         opts,
         import,
         review,
         source_type,
         source_id,
         fallback
       ) do
    artifact = JsonNormalization.stringify_keys(artifact)
    selected_source_id = Keyword.get(opts, :source_artifact_id, source_id.(artifact))

    import.(review.(artifact), opts, source_type, selected_source_id || fallback)
  end
end
