defmodule OrbitalDynamics.CadenceImport.OperationalTimelineImport do
  @moduledoc false

  alias OrbitalDynamics.CadenceImport.JsonNormalization
  alias OrbitalDynamics.OperatorReview

  def from_timeline_feedback_report(report, opts, import) do
    from_review_report(
      report,
      opts,
      import,
      &(Map.get(&1, "operator_review_package") ||
          OperatorReview.from_timeline_feedback_report(&1)),
      "timeline_feedback_report.v1",
      &(&1["id"] || "timeline_feedback_report")
    )
  end

  def from_operational_timeline_report(report, opts, import) do
    from_review_report(
      report,
      opts,
      import,
      &OperatorReview.from_operational_timeline_report/1,
      "operational_timeline_report.v1",
      &(&1["id"] || &1["source"] || "operational_timeline_report")
    )
  end

  defp from_review_report(report, opts, import, review_package, source_type, source_id) do
    report = JsonNormalization.stringify_keys(report)
    selected_source_id = Keyword.get(opts, :source_artifact_id, source_id.(report))

    import.(review_package.(report), opts, source_type, selected_source_id)
  end
end
