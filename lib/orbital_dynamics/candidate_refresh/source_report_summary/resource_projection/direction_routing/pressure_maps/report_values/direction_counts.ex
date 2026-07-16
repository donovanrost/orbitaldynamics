defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.PressureMaps.ReportValues.DirectionCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.DirectionTokens

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_source_report_values: 1]

  def from_rows(rows) do
    rows
    |> Enum.map(&DirectionTokens.direction_token/1)
    |> count_source_report_values()
  end
end
