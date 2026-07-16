defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.LineageIds.StationCalendarIds.IdLists do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  alias __MODULE__.NormalizedValues

  def values(row, source_fun) do
    row
    |> EncodedValue.stringify_keys()
    |> source_fun.()
    |> NormalizedValues.ids()
  end
end
