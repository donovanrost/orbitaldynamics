defmodule OrbitalDynamics.CadenceImport.ContactContentionImport do
  @moduledoc false

  alias OrbitalDynamics.CadenceImport.JsonNormalization
  alias OrbitalDynamics.OperatorReview

  def from_contact_contention_report(report, opts, import) do
    from_review_report(
      report,
      opts,
      import,
      &(Map.get(&1, "operator_review_package") ||
          OperatorReview.from_contact_contention_report(&1)),
      "contact_contention_report.v1",
      "contact_contention_report"
    )
  end

  def from_contact_contention_resolution_report(report, opts, import) do
    from_review_report(
      report,
      opts,
      import,
      &(Map.get(&1, "operator_review_package") ||
          OperatorReview.from_contact_contention_resolution_report(&1)),
      "contact_contention_resolution_report.v1",
      "contact_contention_resolution_report"
    )
  end

  defp from_review_report(report, opts, import, review_package, source_type, fallback) do
    report = JsonNormalization.stringify_keys(report)
    source_id = Keyword.get(opts, :source_artifact_id, report["id"] || fallback)

    import.(review_package.(report), opts, source_type, source_id)
  end
end
