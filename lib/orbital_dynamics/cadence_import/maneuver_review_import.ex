defmodule OrbitalDynamics.CadenceImport.ManeuverReviewImport do
  @moduledoc false

  alias OrbitalDynamics.CadenceImport.JsonNormalization
  alias OrbitalDynamics.OperatorReview

  def from_maneuver_recommendation(recommendation, opts, import) do
    from_review_report(
      recommendation,
      opts,
      import,
      &OperatorReview.from_maneuver_recommendation/1,
      "maneuver_recommendation.v1",
      &(&1["id"] || &1["maneuver_id"]),
      "maneuver_recommendation"
    )
  end

  def from_maneuver_execution_delta(delta, opts, import) do
    from_review_report(
      delta,
      opts,
      import,
      &OperatorReview.from_maneuver_execution_delta/1,
      "maneuver_execution_delta.v1",
      &(&1["id"] || &1["activity_id"]),
      "maneuver_execution_delta"
    )
  end

  def from_maneuver_review_report(report, opts, import) do
    from_review_report(
      report,
      opts,
      import,
      &OperatorReview.from_maneuver_review_report/1,
      "maneuver_review_report.v1",
      &(&1["id"] || &1["source_artifact_id"] || &1["source"]),
      "maneuver_review_report"
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
