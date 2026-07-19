defmodule OrbitalDynamics.CadenceImport.ResourceProjectionImport do
  @moduledoc false

  alias OrbitalDynamics.CadenceImport.JsonNormalization
  alias OrbitalDynamics.OperatorReview

  def from_resource_projection_report(report, opts, import) do
    from_review_report(
      report,
      opts,
      import,
      &OperatorReview.from_resource_projection_report/1,
      "resource_projection_report.v1",
      &(&1["id"] || get_in(&1, ["assumptions", "source"])),
      "resource_projection_report"
    )
  end

  def from_resource_projection_flow_summary(summary, opts, import) do
    from_review_report(
      summary,
      opts,
      import,
      &OperatorReview.from_resource_projection_flow_summary/1,
      "resource_projection_flow_summary.v1",
      &(&1["id"] || &1["source"] || get_in(&1, ["assumptions", "source"])),
      "resource_projection_flow_summary"
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
