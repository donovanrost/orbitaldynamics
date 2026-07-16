defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureIdRouting.RoutePairs.PairBuilder do
  @moduledoc false

  alias __MODULE__.PairValues
  alias __MODULE__.RowPairs

  def activity_pairs(rows, key_fun, source_activity_ids_fun)
      when is_function(key_fun, 1) and is_function(source_activity_ids_fun, 1) do
    PairValues.unique_from_rows(
      rows,
      &RowPairs.activity_pairs(&1, key_fun, source_activity_ids_fun)
    )
  end

  def id_pairs(rows, key_fun, ids_fun)
      when is_function(key_fun, 1) and is_function(ids_fun, 1) do
    PairValues.unique_from_rows(rows, &RowPairs.id_pairs(&1, key_fun, ids_fun))
  end
end
