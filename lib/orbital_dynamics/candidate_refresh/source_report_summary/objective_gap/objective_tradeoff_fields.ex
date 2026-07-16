defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveTradeoffFields do
  @moduledoc false

  alias __MODULE__.CountFields
  alias __MODULE__.RowValues

  def fields(reports) do
    CountFields.fields(reports)
  end

  def report_rows(report) do
    RowValues.report_rows(report)
  end

  def trust_boundary(row) do
    RowValues.trust_boundary(row)
  end
end
