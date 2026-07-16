defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureIdRouting.RoutePairs.PairBuilder.PairValues do
  @moduledoc false

  def unique_from_rows(rows, row_pairs_fun) when is_function(row_pairs_fun, 1) do
    rows
    |> Enum.flat_map(row_pairs_fun)
    |> Enum.uniq()
  end
end
