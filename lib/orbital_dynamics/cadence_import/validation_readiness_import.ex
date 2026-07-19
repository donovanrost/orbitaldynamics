defmodule OrbitalDynamics.CadenceImport.ValidationReadinessImport do
  @moduledoc false

  alias OrbitalDynamics.CadenceImport.{JsonNormalization, SourceIdentifierPolicy}
  alias OrbitalDynamics.OperatorReview

  def from_schema_validation_report(report, opts, import) do
    from_review_report(
      report,
      opts,
      import,
      &OperatorReview.from_schema_validation_report/1,
      "schema_validation_report.v1",
      &SourceIdentifierPolicy.schema_validation_report/1
    )
  end

  def from_schema_validation_batch_report(report, opts, import) do
    from_review_report(
      report,
      opts,
      import,
      &OperatorReview.from_schema_validation_batch_report/1,
      "schema_validation_batch_report.v1",
      &SourceIdentifierPolicy.schema_validation_batch_report/1
    )
  end

  def from_execution_report(report, opts, import) do
    from_review_report(
      report,
      opts,
      import,
      &OperatorReview.from_execution_report/1,
      "execution_report.v1",
      &SourceIdentifierPolicy.execution_report/1
    )
  end

  def from_operational_readiness_report(report, opts, import) do
    from_review_report(
      report,
      opts,
      import,
      &OperatorReview.from_operational_readiness_report/1,
      "operational_readiness_report.v1",
      &(&1["report_id"] || "operational_readiness_report")
    )
  end

  def from_quality_gate_report(report, opts, import) do
    from_review_report(
      report,
      opts,
      import,
      &OperatorReview.from_quality_gate_report/1,
      "quality_gate_report.v1",
      &(&1["report_id"] || "quality_gate_report")
    )
  end

  defp from_review_report(report, opts, import, review, source_type, source_id) do
    report = JsonNormalization.stringify_keys(report)
    selected_source_id = Keyword.get(opts, :source_artifact_id, source_id.(report))

    import.(review.(report), opts, source_type, selected_source_id)
  end
end
