defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.PressureMaps.ReportValues.ActivityDirectionPairs do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.DirectionTokens
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities

  def from_rows(rows) do
    Enum.flat_map(rows, &from_row/1)
  end

  defp from_row(row) do
    direction = DirectionTokens.direction_token(row)

    row
    |> RowIdentities.source_activity_ids()
    |> List.wrap()
    |> Enum.map(&{direction, &1})
  end
end
