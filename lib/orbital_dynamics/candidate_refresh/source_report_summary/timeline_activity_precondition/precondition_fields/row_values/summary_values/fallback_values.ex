defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityPrecondition.PreconditionFields.RowValues.SummaryValues.FallbackValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityPrecondition.PreconditionFields.RowValues.SummaryValues.FallbackFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [numeric_report_count: 2]

  def precondition_count(summary, status) do
    numeric_report_count(summary, FallbackFields.count_field(status))
  end

  def precondition_status(summary) do
    Map.get(summary, "precondition_status")
  end

  def precondition_types(summary, field) do
    Map.get(summary, field, [])
  end

  def type_status(field), do: FallbackFields.type_status(field)
end
