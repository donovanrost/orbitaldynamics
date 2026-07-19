defmodule OrbitalDynamics.CadenceImport.ContactPlanningImport do
  @moduledoc false

  alias OrbitalDynamics.CadenceImport.JsonNormalization
  alias OrbitalDynamics.OperatorReview

  def from_link_capacity_report(report, opts, import) do
    from_report(
      report,
      opts,
      import,
      &OperatorReview.from_link_capacity_report/1,
      "link_capacity_report.v1",
      "link_capacity_report"
    )
  end

  def from_contact_allocation_report(report, opts, import) do
    from_report(
      report,
      opts,
      import,
      &OperatorReview.from_contact_allocation_report/1,
      "contact_allocation_report.v1",
      "contact_allocation_report"
    )
  end

  def from_contact_allocation_capacity_pack_summary(summary, opts, import) do
    from_report(
      summary,
      opts,
      import,
      &OperatorReview.from_contact_allocation_capacity_pack_summary/1,
      "contact_allocation_capacity_pack_summary.v1",
      "contact_allocation_capacity_pack_summary"
    )
  end

  def from_contact_allocation_reservation_conflict_summary(summary, opts, import) do
    from_report(
      summary,
      opts,
      import,
      &OperatorReview.from_contact_allocation_reservation_conflict_summary/1,
      "contact_allocation_reservation_conflict_summary.v1",
      "contact_allocation_reservation_conflict_summary"
    )
  end

  def from_contact_intent(intent, opts, import) do
    from_review_report(
      intent,
      opts,
      import,
      &OperatorReview.from_contact_intent/1,
      "contact_intent.v1",
      &(&1["id"] || &1["activity_id"]),
      "contact_intent"
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
