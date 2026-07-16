defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.TrustBoundaries.RowValues do
  @moduledoc false

  alias __MODULE__.ReportRows
  alias __MODULE__.SingleRowValues

  def values(%{} = report) do
    report
    |> ReportRows.values()
    |> Enum.flat_map(&SingleRowValues.values/1)
  end
end
