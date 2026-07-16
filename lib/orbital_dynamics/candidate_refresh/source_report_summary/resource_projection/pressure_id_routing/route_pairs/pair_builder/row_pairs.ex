defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureIdRouting.RoutePairs.PairBuilder.RowPairs do
  @moduledoc false

  alias __MODULE__.PairInputs
  alias __MODULE__.PairValues

  def activity_pairs(row, key_fun, source_activity_ids_fun)
      when is_function(key_fun, 1) and is_function(source_activity_ids_fun, 1) do
    keys = PairInputs.keys(row, key_fun)
    activity_ids = PairInputs.activity_ids(row, source_activity_ids_fun)

    PairValues.from_lists(keys, activity_ids)
  end

  def id_pairs(row, key_fun, ids_fun)
      when is_function(key_fun, 1) and is_function(ids_fun, 1) do
    keys = PairInputs.keys(row, key_fun)
    ids = PairInputs.ids(row, ids_fun)

    PairValues.from_lists(keys, ids)
  end
end
