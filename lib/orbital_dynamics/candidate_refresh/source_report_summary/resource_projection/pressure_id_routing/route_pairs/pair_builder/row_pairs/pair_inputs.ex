defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureIdRouting.RoutePairs.PairBuilder.RowPairs.PairInputs do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureIdRouting.RoutePairs.PairBuilder.RowPairs.ValueLists

  def keys(row, key_fun) do
    row
    |> key_fun.()
    |> ValueLists.non_blank()
  end

  def activity_ids(row, source_activity_ids_fun) do
    row
    |> source_activity_ids_fun.()
    |> ValueLists.wrap()
  end

  def ids(row, ids_fun) do
    row
    |> ids_fun.()
    |> ValueLists.non_blank()
  end
end
