defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureIdRouting.RoutePairs.PairBuilder.RowPairs.PairValues do
  @moduledoc false

  def from_lists(keys, values) do
    for key <- keys, value <- values, do: {key, value}
  end
end
