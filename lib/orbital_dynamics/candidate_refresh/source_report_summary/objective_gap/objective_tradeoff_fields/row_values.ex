defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveTradeoffFields.RowValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  alias OrbitalDynamics.CandidateRefresh.SourceObjectives.ObjectiveTradeoff,
    as: ObjectiveTradeoffSourceObjectives

  def report_rows(report), do: ObjectiveTradeoffSourceObjectives.report_rows(report)

  def trust_boundary(row), do: ObjectiveTradeoffSourceObjectives.trust_boundary(row)

  def row_count(report), do: report |> report_rows() |> length()

  def rows(report) do
    report
    |> report_rows()
    |> Enum.map(&EncodedValue.stringify_keys/1)
  end
end
