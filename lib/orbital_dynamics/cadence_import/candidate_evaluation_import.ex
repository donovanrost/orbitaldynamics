defmodule OrbitalDynamics.CadenceImport.CandidateEvaluationImport do
  @moduledoc false

  alias OrbitalDynamics.CadenceImport.JsonNormalization
  alias OrbitalDynamics.OperatorReview

  def from_contact_filter_report(report, opts, import) do
    from_report(
      report,
      opts,
      import,
      &OperatorReview.from_contact_filter_report/1,
      "contact_filter_report.v1",
      "contact_filter_report"
    )
  end

  def from_candidate_diff_report(report, opts, import) do
    from_report(
      report,
      opts,
      import,
      &OperatorReview.from_candidate_diff_report/1,
      "candidate_diff_report.v1",
      "candidate_diff_report"
    )
  end

  def from_candidate_rejection_report(report, opts, import) do
    from_report(
      report,
      opts,
      import,
      &OperatorReview.from_candidate_rejection_report/1,
      "candidate_rejection_report.v1",
      "candidate_rejection_report"
    )
  end

  def from_provider_counteroffer_report(report, opts, import) do
    from_report(
      report,
      opts,
      import,
      &OperatorReview.from_provider_counteroffer_report/1,
      "provider_counteroffer_report.v1",
      "provider_counteroffer_report"
    )
  end

  def from_invalidated_candidate(candidate, opts, import) do
    from_review_report(
      candidate,
      opts,
      import,
      &OperatorReview.from_invalidated_candidate/1,
      "invalidated_candidate.v1",
      &(&1["id"] || &1["invalidated_candidate_id"]),
      "invalidated_candidate"
    )
  end

  def from_resource_filter_report(report, opts, import) do
    from_report(
      report,
      opts,
      import,
      &OperatorReview.from_resource_filter_report/1,
      "resource_filter_report.v1",
      "resource_filter_report"
    )
  end

  def from_freshness_report(report, opts, import) do
    from_report(
      report,
      opts,
      import,
      &OperatorReview.from_freshness_report/1,
      "freshness_report.v1",
      "freshness_report"
    )
  end

  def from_refresh_budget_report(report, opts, import) do
    from_report(
      report,
      opts,
      import,
      &OperatorReview.from_refresh_budget_report/1,
      "refresh_budget_report.v1",
      "refresh_budget_report"
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
