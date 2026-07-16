defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureIdRouting.RoutePairs do
  @moduledoc false

  alias __MODULE__.PairBuilder
  alias __MODULE__.PairValues

  def activity_ids(report, rows_fun, key_fun, source_activity_ids_fun, fallback_field)
      when is_function(rows_fun, 1) and is_function(key_fun, 1) and
             is_function(source_activity_ids_fun, 1) do
    report
    |> rows_fun.()
    |> PairBuilder.activity_pairs(key_fun, source_activity_ids_fun)
    |> PairValues.from_pairs(report, fallback_field)
  end

  def row_ids(report, rows_fun, key_fun, ids_fun, fallback_field)
      when is_function(rows_fun, 1) and is_function(key_fun, 1) and is_function(ids_fun, 1) do
    report
    |> rows_fun.()
    |> PairBuilder.id_pairs(key_fun, ids_fun)
    |> PairValues.from_pairs(report, fallback_field)
  end
end
