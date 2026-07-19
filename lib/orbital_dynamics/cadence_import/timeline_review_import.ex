defmodule OrbitalDynamics.CadenceImport.TimelineReviewImport do
  @moduledoc false

  alias OrbitalDynamics.CadenceImport.{JsonNormalization, SourceIdentifierPolicy}
  alias OrbitalDynamics.OperatorReview

  def from_timeline_diff_report(report, opts, import) do
    from_review_report(
      report,
      opts,
      import,
      &OperatorReview.from_timeline_diff_report/1,
      "timeline_diff_report.v1",
      &(&1["id"] || &1["source"]),
      "timeline_diff_report"
    )
  end

  def from_timeline_diff_summary(summary, opts, import) do
    from_review_report(
      summary,
      opts,
      import,
      &OperatorReview.from_timeline_diff_summary/1,
      "timeline_diff_summary.v1",
      &(&1["id"] || &1["source"]),
      "timeline_diff_summary"
    )
  end

  def from_timeline_dependency_impact_summary(summary, opts, import) do
    from_review_report(
      summary,
      opts,
      import,
      &OperatorReview.from_timeline_dependency_impact_summary/1,
      "timeline_dependency_impact_summary.v1",
      &(&1["id"] || &1["source"]),
      "timeline_dependency_impact_summary"
    )
  end

  def from_timeline_publication_summary(summary, opts, import) do
    from_review_report(
      summary,
      opts,
      import,
      &OperatorReview.from_timeline_publication_summary/1,
      "timeline_publication_summary.v1",
      &(&1["publication_id"] || &1["source_artifact_id"]),
      "timeline_publication_summary"
    )
  end

  def from_timeline_activity_precondition_summary(summary, opts, import) do
    from_review_report(
      summary,
      opts,
      import,
      &OperatorReview.from_timeline_activity_precondition_summary/1,
      "timeline_activity_precondition_summary.v1",
      &(&1["id"] || &1["source"] || &1["timeline_id"]),
      &(&1["activity_id"] || "timeline_activity_precondition_summary")
    )
  end

  def from_timeline_lifecycle_state_summary(summary, opts, import) do
    from_review_report(
      summary,
      opts,
      import,
      &OperatorReview.from_timeline_lifecycle_state_summary/1,
      "timeline_lifecycle_state_summary.v1",
      &(&1["id"] || &1["source"]),
      "timeline_lifecycle_state_summary"
    )
  end

  def from_timeline_activity_state(state, opts, import) do
    from_timeline_state(
      state,
      opts,
      import,
      &OperatorReview.from_timeline_activity_state/1,
      "timeline_activity_state.v1",
      "timeline_activity_state"
    )
  end

  def from_timeline_activity_status_state(state, opts, import) do
    from_timeline_state(
      state,
      opts,
      import,
      &OperatorReview.from_timeline_activity_status_state/1,
      "timeline_activity_status_state.v1",
      "timeline_activity_status_state"
    )
  end

  def from_timeline_activity_approval_state(state, opts, import) do
    from_timeline_state(
      state,
      opts,
      import,
      &OperatorReview.from_timeline_activity_approval_state/1,
      "timeline_activity_approval_state.v1",
      "timeline_activity_approval_state"
    )
  end

  def from_timeline_activity_lifecycle_state(state, opts, import) do
    from_timeline_state(
      state,
      opts,
      import,
      &OperatorReview.from_timeline_activity_lifecycle_state/1,
      "timeline_activity_lifecycle_state.v1",
      "timeline_activity_lifecycle_state"
    )
  end

  def from_timeline_preservation_report(report, opts, import) do
    from_review_report(
      report,
      opts,
      import,
      &OperatorReview.from_timeline_preservation_report/1,
      "timeline_preservation_report.v1",
      &(&1["id"] || &1["source"]),
      "timeline_preservation_report"
    )
  end

  def from_timeline_preservation_status(status, opts, import) do
    from_timeline_state(
      status,
      opts,
      import,
      &OperatorReview.from_timeline_preservation_status/1,
      "timeline_preservation_status.v1",
      "timeline_preservation_status"
    )
  end

  def from_timeline_integrity_report(report, opts, import) do
    from_review_report(
      report,
      opts,
      import,
      &OperatorReview.from_timeline_integrity_report/1,
      "timeline_integrity_report.v1",
      &(&1["id"] || &1["source"]),
      "timeline_integrity_report"
    )
  end

  def from_timeline_transition_application_summary(summary, opts, import) do
    from_review_report(
      summary,
      opts,
      import,
      &OperatorReview.from_timeline_transition_application_summary(&1,
        approval_policy: option(opts, :approval_policy)
      ),
      "timeline_transition_application_summary.v1",
      &(&1["id"] || &1["source"]),
      "timeline_transition_application_summary"
    )
  end

  def from_timeline_transition_application_report(report, opts, import) do
    from_review_report(
      report,
      opts,
      import,
      &OperatorReview.from_timeline_transition_application_report(&1,
        approval_policy: option(opts, :approval_policy)
      ),
      "timeline_transition_application_report.v1",
      &(&1["id"] || &1["source"]),
      "timeline_transition_application_report"
    )
  end

  defp from_timeline_state(state, opts, import, review, source_type, fallback) do
    state = JsonNormalization.stringify_keys(state)

    source_id =
      SourceIdentifierPolicy.timeline_state(
        state,
        option(opts, :source_artifact_id),
        fallback
      )

    import.(review.(state), opts, source_type, source_id)
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

    selected_source_id =
      option(opts, :source_artifact_id, source_id.(artifact)) ||
        fallback_value(fallback, artifact)

    import.(review.(artifact), opts, source_type, selected_source_id)
  end

  defp fallback_value(fallback, artifact) when is_function(fallback, 1), do: fallback.(artifact)
  defp fallback_value(fallback, _artifact), do: fallback

  defp option(opts, key, default \\ nil), do: Keyword.get(opts, key, default)
end
