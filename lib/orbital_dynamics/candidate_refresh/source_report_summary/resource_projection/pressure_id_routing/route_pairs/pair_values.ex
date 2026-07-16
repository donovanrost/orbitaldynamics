defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureIdRouting.RoutePairs.PairValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.ValueListMaps

  def from_pairs([], report, fallback_field) do
    report
    |> Map.get(fallback_field)
    |> ValueListMaps.map_value_lists()
  end

  def from_pairs(pairs, _report, _fallback_field), do: ValueListMaps.from_pairs(pairs)
end
