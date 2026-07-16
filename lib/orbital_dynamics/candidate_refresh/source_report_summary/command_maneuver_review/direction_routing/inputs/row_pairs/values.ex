defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.DirectionRouting.Inputs.RowPairs.Values do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.DirectionRouting.Inputs.RowPairs.{
    PairMaps,
    RowValues
  }

  def direction_counts(report) do
    report
    |> RowValues.direction_identifier_pairs()
    |> from_pairs(
      fn -> PairMaps.direction_counts(Map.get(report, "direction_counts")) end,
      &PairMaps.counts_from_pairs/1
    )
  end

  def activity_ids_by_direction(report) do
    report
    |> RowValues.activity_direction_pairs()
    |> from_pairs(
      fn -> PairMaps.value_lists(Map.get(report, "activity_ids_by_direction")) end,
      &PairMaps.ids_from_pairs/1
    )
  end

  def window_ids_by_direction(report) do
    report
    |> RowValues.window_direction_pairs()
    |> from_pairs(
      fn -> PairMaps.value_lists(Map.get(report, "window_ids_by_direction")) end,
      &PairMaps.ids_from_pairs/1
    )
  end

  defp from_pairs([], fallback_fun, _pairs_fun), do: fallback_fun.()
  defp from_pairs(pairs, _fallback_fun, pairs_fun), do: pairs_fun.(pairs)
end
