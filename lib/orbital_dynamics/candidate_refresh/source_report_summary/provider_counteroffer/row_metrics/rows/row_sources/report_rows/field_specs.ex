defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics.Rows.RowSources.ReportRows.FieldSpecs do
  @moduledoc false

  @row_fields ~w(
    rows
    import_readiness_rows
    plan_impact_rows
    review_rows
  )

  def row_fields, do: @row_fields
end
