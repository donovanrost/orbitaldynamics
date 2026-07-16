defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics.CountFields.ReportValues.LockDeadlineStatus do
  @moduledoc false

  alias __MODULE__.FieldSpecs

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics.Rows

  def counts(report) do
    Map.get(report, FieldSpecs.counts_field()) ||
      Rows.count_by_field(report, FieldSpecs.counts_field(), FieldSpecs.row_field())
  end

  def ids(report) do
    Map.get(report, FieldSpecs.ids_field()) ||
      Rows.ids_by_field(report, FieldSpecs.row_field())
  end
end
