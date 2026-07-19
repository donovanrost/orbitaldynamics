defmodule OrbitalDynamics.CadenceImport.ConstraintObjectiveImport do
  @moduledoc false

  alias OrbitalDynamics.CadenceImport.JsonNormalization
  alias OrbitalDynamics.OperatorReview

  def from_constraint_report(report, opts, import) do
    from_review_report(
      report,
      opts,
      import,
      &OperatorReview.from_constraint_report/1,
      "constraint_report.v1",
      &(&1["id"] || get_in(&1, ["assumptions", "source"])),
      "constraint_report"
    )
  end

  def from_objective_satisfaction_report(report, opts, import) do
    from_review_report(
      report,
      opts,
      import,
      &OperatorReview.from_objective_satisfaction_report/1,
      "objective_satisfaction_report.v1",
      &(&1["id"] || &1["source"]),
      "objective_satisfaction_report"
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
